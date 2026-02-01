module symm_conv#(
	parameter int IMG_W = 512
)(
	input  logic clk,			// Operating clock
	input  logic reset,			// Active-high reset signal (reset when set to 1)
	input  logic [71:0] i_f,		// Nine 8-bit signed convolution filter coefficients in row-major format (i.e. i_f[7:0] is f[0][0], i_f[15:8] is f[0][1], etc.)
	input  logic i_valid,			// Set to 1 if input pixel is valid
	input  logic i_ready,			// Set to 1 if consumer block is ready to receive a new pixel
	input  logic [7:0] i_x,		// Input pixel value (8-bit unsigned value between 0 and 255)
	output logic o_valid,			// Set to 1 if output pixel is valid
	output logic o_ready,			// Set to 1 if this block is ready to receive a new pixel
	output logic [7:0] o_y		// Output pixel value (8-bit unsigned value between 0 and 255)
);

localparam int PAD = 1;
localparam STREAM_W = IMG_W + 2*PAD;
localparam COLW = $clog2(STREAM_W);
localparam int FILL_N = 2*STREAM_W + 2;
localparam int FILL_W = $clog2(FILL_N + 1);
localparam int DSP_LAT = 1;

//output regs
logic out_valid_q;
logic[7:0] out_data_q;
assign o_valid = out_valid_q;
assign o_y = out_data_q;

wire advance = (~out_valid_q) || i_ready;
assign o_ready = advance;
wire fire = i_valid && advance;

wire signed[7:0] k00 = $signed(i_f[71:64]); //corners
wire signed[7:0] k01 = $signed(i_f[63:56]); //edges
wire signed[7:0] k11 = $signed(i_f[39:32]); //center
wire signed[7:0] a = k00; 
wire signed[7:0] b = k01; 
wire signed[7:0] c = k11; 

logic [COLW-1:0] col_q;
always_ff@(posedge clk) begin
	if(reset) col_q <= '0;
	else if (fire) begin
		if(col_q == STREAM_W-1) col_q <= '0;
	else col_q <= col_q + 1'b1;
	end
end

wire eol = fire  && (col_q == STREAM_W-1);

logic[FILL_W-1:0] fill_q;

always_ff@(posedge clk) begin
	if(reset) fill_q <= '0;
	else if(fire && (fill_q != FILL_N[FILL_W-1:0])) fill_q <= fill_q + 1'b1;
end
wire win_ok = (fill_q == FILL_N[FILL_W-1:0]);

//alshift initialization
logic[15:0] taps_bus;
wire[7:0] px0_u = i_x;
wire[7:0] px1_u = taps_bus[7:0];
wire[7:0] px2_u = taps_bus[15:8];

altshift u_rows (
  .aclr     (reset),
  .clken    (fire),
  .clock    (clk),
  .shiftin  (px0_u),
  .taps     (taps_bus),
  .shiftout ()
);

logic[7:0] r0_1, r0_2;
logic[7:0] r1_1, r1_2;
logic[7:0] r2_1, r2_2;

//stage a: capture window pixels
logic va;
logic[7:0] a_c_val, a_n, a_s, a_w, a_e, a_nw, a_ne, a_sw, a_se;
logic signed[7:0] a_a, a_b, a_c;
logic a_eq, a_a0, a_b0;

//stage b
logic vb;
logic signed[10:0] b_ns, b_we, b_nwne, b_swse;
logic signed[8:0] b_center;
logic signed[7:0] b_a, b_b, b_c;
logic b_eq, b_a0, b_b0;

//stage c
logic vc;
logic signed[11:0] c_cross;
logic signed[11:0] c_diag;
logic signed[8:0] c_center;
logic signed[7:0] c_a, c_b, c_c;
logic c_eq, c_a0, c_b0;

//stage d
logic vd;
logic signed[12:0] d_neigh_sum;
logic signed[8:0] d_center;
logic signed[7:0] d_neigh_k, d_center_k;

//stage e
logic ve;
logic signed[37:0] e_mac;

//row counter
logic[31:0] row_q;
always_ff@(posedge clk) begin
	if(reset) row_q <= 32'd0;
	else if(fire && (col_q == STREAM_W-1)) row_q <= row_q + 32'd1;
end

wire center_col_ok = (col_q >=2) && (col_q <= (IMG_W+1));
wire center_row_ok = (row_q >=2) && (row_q <= (IMG_W+1));
wire center_ok = win_ok && center_col_ok && center_row_ok;

function automatic logic[7:0] sat_u8(input logic signed[37:0] x);
	if(x < 0) sat_u8 = 8'd0;
	else if(x > 255) sat_u8 = 8'd255;
	else sat_u8 = x[7:0];
endfunction

//dsp operands
logic[17:0] ax_u, bx_u;
logic[17:0] ay_s, by_s;

//dsp outputs
wire[36:0] dsp_resulta;
wire[36:0] dsp_resultb;

//alignment by defining DSP latency
logic[DSP_LAT:0] vd_pipe;

//registering the products and then add in ALMs
logic vp;
logic signed[36:0] proda_q, prodb_q;

dsp u_dsp (
  .aclr    ({2{reset}}),
  .ax      (ax_u),
  .ay      (ay_s),
  .bx      (bx_u),
  .by      (by_s),
  .clk     ({3{clk}}),
  .ena     ({3{advance}}),   //dsp stalled
  .resulta (dsp_resulta),
  .resultb (dsp_resultb)
);

logic [7:0] px0_d;
logic       fire_d, eol_d, center_ok_d;

integer index;
always_ff@(posedge clk) begin
	if(reset) begin
		    px0_d       <= '0;
    fire_d      <= 1'b0;
    eol_d       <= 1'b0;
    center_ok_d <= 1'b0;
		r0_1 <= '0; r0_2 <= '0;
      r1_1 <= '0; r1_2 <= '0;
      r2_1 <= '0; r2_2 <= '0;
		
		va <= 1'b0; vb <= 1'b0; vc <= 1'b0; vd <= 1'b0; vp <= 1'b0; ve <= 1'b0;
		for(index = 0; index <= DSP_LAT; index++) vd_pipe[index] <= 1'b0;
		out_valid_q <= 1'b0;
		out_data_q <= 8'd0;
		
		ax_u <= '0; ay_s <= '0; bx_u <= '0; by_s <= '0;
		proda_q <= '0; prodb_q <= '0;
		e_mac <= '0;
	end else if(advance) begin
	    fire_d      <= fire;
    eol_d       <= eol;
    center_ok_d <= center_ok;
		out_valid_q <= ve;
      out_data_q  <= sat_u8(e_mac);
		ve <= vp;
		e_mac <= $signed({proda_q[36], proda_q}) + $signed({prodb_q[36], prodb_q});
		vp <= vd_pipe[DSP_LAT];
		proda_q <= $signed(dsp_resulta);
		prodb_q <= $signed(dsp_resultb);
		
		vd_pipe[0] <= vd;
		for(index = 1; index <= DSP_LAT; index++) vd_pipe[index] <= vd_pipe[index-1];
		vd <= vc;
		
		d_center <= c_center;
		d_center_k <= c_c;
		
		if (fire) px0_d <= px0_u;
		
		if(c_eq) begin
			d_neigh_sum <= $signed({1'b0, c_cross}) + $signed({1'b0, c_diag});
			d_neigh_k <= c_a;
		end else if(c_a0) begin
			d_neigh_sum <= $signed({1'b0, c_cross});
			d_neigh_k <= c_b;
		end else if(c_b0) begin
			d_neigh_sum <= $signed({1'b0,c_diag});
			d_neigh_k <= c_a;
		end else begin
			d_neigh_sum <= $signed({1'b0, c_cross});
			d_neigh_k <= c_b;
		end
		
		//driving dsp operands for stage d regs
		ax_u <= {9'd0, d_center[8:0]};
		bx_u <= {5'd0, d_neigh_sum[12:0]};
		
		ay_s <= {{10{d_center_k[7]}}, d_center_k};
		by_s <= {{10{d_neigh_k[7]}}, d_neigh_k};
		
		//stage c, building cross and diagnonal sums
		vc <= vb;
		c_cross <= $signed({1'b0, b_ns}) + $signed({1'b0, b_we});
		c_diag <= $signed({1'b0, b_nwne}) + $signed({1'b0, b_swse});
		c_center <= b_center;
		c_a <= b_a; c_b <= b_b; c_c <= b_c;
		c_eq <= b_eq; c_a0 <= b_a0; c_b0 <= b_b0;
		
		//stage b, 2-input sums
		vb <= va;
		b_center <= $signed({1'b0, a_c_val});
		b_ns <= $signed({1'b0, a_n}) + $signed({1'b0, a_s});
		b_we <= $signed({1'b0, a_w}) + $signed({1'b0, a_e});
		b_nwne <= $signed({1'b0, a_nw}) + $signed({1'b0, a_ne});
		b_swse <= $signed({1'b0, a_sw}) + $signed({1'b0, a_se});
		
		b_a <= a_a; b_b <= a_b; b_c <= a_c;
      b_eq <= a_eq; b_a0 <= a_a0; b_b0 <= a_b0;
	
		//stage a, capture window cells
		va <= 1'b0;
		if(fire) begin
			a_c_val <= r1_1; a_n <= r2_1; a_s <= r0_1; a_w <= r1_2; a_e <= px1_u;
			a_nw <= r2_2; a_ne <= px2_u; a_sw <= r0_2; a_se <= px0_d;
			a_a <= a; a_b <= b; a_c <= c;
			a_eq <= (a==b); a_a0 <= (a==0); a_b0 <= (b==0);
			//only asserting valid for true image centers to prevent slants
			va <= center_ok_d;
			if(eol) begin
				r0_1 <= '0; r0_2 <= '0;
				r1_1 <= '0; r1_2 <= '0;
				r2_1 <= '0; r2_2 <= '0;
			end else begin
				r0_2 <= r0_1;  r0_1 <= px0_d;
				r1_2 <= r1_1;  r1_1 <= px1_u;
				r2_2 <= r2_1;  r2_1 <= px2_u;
			end
		end
	end
end
endmodule

