
module altshift (
	aclr,
	clken,
	clock,
	shiftin,
	shiftout,
	taps);	

	input		aclr;
	input		clken;
	input		clock;
	input	[7:0]	shiftin;
	output	[7:0]	shiftout;
	output	[15:0]	taps;
endmodule
