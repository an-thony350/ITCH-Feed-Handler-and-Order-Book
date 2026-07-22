
`timescale 1 ns / 1 ps
import hdl_header::*;

	module data_handler_v2_0 #
	(
		// Users to add parameters here
        ORN_W    = 64,
        PRICE_W  = 32,
        SHARES_W = 32,
        PACKET_W = 32,
        STOCK_W  = 16,
        MSG_W    = 8,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here

        // input from Order Book
        input  wire                                                    ready_i,

        // output to Order Book
        output data_t                                                  rdata_o,
        output wire                                                    valid_o,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid
	);
// Instantiation of Axi Bus Interface S00_AXIS
	data_handler_v2_0_S00_AXIS # (
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
	) data_handler_v2_0_S00_AXIS_inst (
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid),
		.ready_i(ready_i),
		.rdata_o(rdata_o),
		.valid_o(valid_o)

	);

	// Add user logic here

	// User logic ends

	endmodule
