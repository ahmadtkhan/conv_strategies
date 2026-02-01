module coef_conv#(
	parameter IMG_W = 512
)(
	input logic 			clk, 
	input logic 			reset, 
	input logic 			i_valid,
	input logic 			i_ready,
	input logic [7:0] 	i_x,
	output logic 			o_valid,
	output logic 			o_ready,
	output logic [7:0] 	o_y
);

localparam int PADDING = 1;
localparam int STREAM_W = IMG_W + 2*PADDING;
localparam int COL_W = $clog2(STREAM_W);

//Outputs regs
logic out_valid_q;
logic [7:0] out_data_q;
assign o_valid = out_valid_q;
assign o_y = out_data_q;

//stalling the pipeline if downstream is not ready when we have a valid output
wire advance = (~out_valid_q) || i_ready;
assign o_ready = advance;
wire fire_in = i_valid && o_ready;

logic[COL_W-1:0] col_index;
logic [31:0] rows_completed;

//Vertical delays using RAM-based shift regs
wire [15:0] taps_bus;
wire [7:0] tap1_raw, tap2_raw;
assign {tap2_raw, tap1_raw} = taps_bus;

altshift u_lines(
	.aclr(reset),
	.clock(clk),
	.clken(fire_in),
	.shiftin(i_x),
	.taps(taps_bus),
	.shiftout()
);

wire [7:0] p0 = i_x;
wire [7:0] p1 = (rows_completed >= 32'd1) ? tap1_raw : 8'd0; // row-1
wire [7:0] p2 = (rows_completed >= 32'd2) ? tap2_raw : 8'd0; // row-2

logic [7:0] sr0[0:2], sr1[0:2], sr2[0:2];

wire have_three_rows = (rows_completed >= 32'd2);
wire have_three_cols = (col_index >= 2);
wire window_ok = have_three_rows && have_three_cols;

function automatic logic [7:0] sat_u8(input logic signed [15:0] v);
		if(v < 16'sd0) sat_u8 = 8'd0;
		else if (v > 16'sd255) sat_u8 = 8'hFF;
		else sat_u8 = v[7:0];
endfunction

//Pipelined accumulator tree
//Fire-in regs
logic signed [15:0] fiveC_0, NS_0, WE_0;
logic v0;
//tree regs
logic signed [15:0] fiveC_1, sum_1;
logic v1;
//final diff regs
logic signed [15:0] diff_2;
logic v2;
//pipeline regs
logic signed [15:0] C_r, N_r, S_r, W_r, E_r;
logic vcap;

always_ff @(posedge clk) begin
	if(reset) begin
		sr0 <= '{default: '0}; sr1 <= '{default: '0}; sr2 <= '{default: '0}; 
		col_index <= '0; rows_completed <= 32'd0;
		v0 <= 1'b0; v1<= 1'b0; v2 <= 1'b0;
		fiveC_0 <= '0; NS_0 <= '0; WE_0 <= '0;
		fiveC_1 <= '0; sum_1 <= '0; diff_2 <= '0;
		C_r <= '0; N_r <= '0; S_r <= '0; W_r <= '0; E_r <= '0; vcap <= 1'b0;
		out_valid_q <= 1'b0; out_data_q <= 8'd0;
	end else begin
		if(advance) begin
			//output stage
			out_valid_q <= v2;
			out_data_q <= sat_u8(diff_2);
			
			//subtraction stage
			v2 <= v1;
			diff_2 <= fiveC_1 - sum_1;
			
			//adder tree
			v1 <= v0;
			fiveC_1 <= fiveC_0;
			sum_1 <= NS_0 + WE_0;
			
			//additional stage from captured taps to increase f_max
			v0 <= vcap;
			fiveC_0 <= ((C_r <<< 2) + C_r);
			NS_0 <= (N_r + S_r);
			WE_0 <= (W_r + E_r);
			
			//default bubble
			vcap <= 1'b0;
			if(fire_in) begin
				vcap <= window_ok;
				C_r <= $signed({1'b0, sr1[2]});
				N_r <= $signed({1'b0, sr0[2]});
				S_r <= $signed({1'b0, sr2[2]});
				W_r <= $signed({1'b0, sr1[1]});
				E_r <= $signed({1'b0, p1});
				
				//horizontal shifting
				sr0[0] <= sr0[1]; sr0[1] <= sr0[2]; sr0[2] <= p2;
				sr1[0] <= sr1[1]; sr1[1] <= sr1[2]; sr1[2] <= p1;
				sr2[0] <= sr2[1]; sr2[1] <= sr2[2]; sr2[2] <= p0;
				
				//counters
				if(col_index == STREAM_W-1) begin
					col_index <= '0;
					rows_completed <= rows_completed + 32'd1;
					sr0 <= '{default: '0}; sr1 <= '{default: '0}; sr2 <= '{default: '0};
				end else begin
					col_index <= col_index + 1'b1;
				end
			end
		end 
	end 
end
endmodule 