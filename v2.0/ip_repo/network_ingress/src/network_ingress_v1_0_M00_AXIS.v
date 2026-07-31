`timescale 1 ns / 1 ps
`default_nettype none

module network_ingress_v1_0_M00_AXIS #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of M_AXIS data bus.
    parameter integer C_M_AXIS_TDATA_WIDTH = 32,
    // Kept only for compatibility with the Vivado-generated wrapper.
    parameter integer C_M_START_COUNT = 32
)
(
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line

    // Global ports
    input  wire                                    M_AXIS_ACLK,
    input  wire                                    M_AXIS_ARESETN,

    // Master Stream Ports.
    output wire                                    M_AXIS_TVALID,
    output wire [C_M_AXIS_TDATA_WIDTH-1 : 0]       M_AXIS_TDATA,
    output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0]   M_AXIS_TSTRB,
    output wire                                    M_AXIS_TLAST,
    input  wire                                    M_AXIS_TREADY
);

    // This module is intentionally unused.
    //
    // The generated Vivado M00_AXIS example is a standalone counter stream
    // generator. That would fight the real ingress output, so the top-level
    // wrapper bypasses it and drives M00_AXIS directly from ingress_top.

    assign M_AXIS_TVALID = 1'b0;
    assign M_AXIS_TDATA  = {C_M_AXIS_TDATA_WIDTH{1'b0}};
    assign M_AXIS_TSTRB  = {(C_M_AXIS_TDATA_WIDTH/8){1'b0}};
    assign M_AXIS_TLAST  = 1'b0;

endmodule

`default_nettype wire
