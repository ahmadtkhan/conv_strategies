// (C) 2001-2020 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.



// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module  altshift_altshift_taps_201_as43lbi  (
	aclr,
	clken,
	clock,
	shiftin,
	shiftout,
	taps);

	input	  aclr;
	input	  clken;
	input	  clock;
	input	[7:0]  shiftin;
	output	[7:0]  shiftout;
	output	[15:0]  taps;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  aclr;
	tri1	  clken;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

    wire [7:0] sub_wire0;
    wire [15:0] sub_wire1;
    wire [7:0] shiftout = sub_wire0[7:0];
    wire [15:0] taps = sub_wire1[15:0];

    altshift_taps  ALTSHIFT_TAPS_component (
                .aclr (aclr),
                .clken (clken),
                .clock (clock),
                .shiftin (shiftin),
                .shiftout (sub_wire0),
                .taps (sub_wire1));
    defparam
        ALTSHIFT_TAPS_component.intended_device_family  = "Arria 10",
        ALTSHIFT_TAPS_component.lpm_hint  = "RAM_BLOCK_TYPE=M20K",
        ALTSHIFT_TAPS_component.lpm_type  = "altshift_taps",
        ALTSHIFT_TAPS_component.number_of_taps  = 2,
        ALTSHIFT_TAPS_component.tap_distance  = 514,
        ALTSHIFT_TAPS_component.width  = 8;


endmodule


