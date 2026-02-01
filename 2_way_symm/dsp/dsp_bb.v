
module dsp (
	ay,
	by,
	ax,
	bx,
	resulta,
	resultb,
	clk,
	ena,
	aclr);	

	input	[17:0]	ay;
	input	[17:0]	by;
	input	[17:0]	ax;
	input	[17:0]	bx;
	output	[36:0]	resulta;
	output	[36:0]	resultb;
	input	[2:0]	clk;
	input	[2:0]	ena;
	input	[1:0]	aclr;
endmodule
