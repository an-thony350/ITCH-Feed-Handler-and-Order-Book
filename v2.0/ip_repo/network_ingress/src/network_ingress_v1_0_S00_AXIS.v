`timescale 1 ns / 1 ps
`default_nettype none

module network_ingress_v1_0_S00_AXIS #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // AXI4Stream sink: Data Width
    parameter integer C_S_AXIS_TDATA_WIDTH = 32
)
(
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line

    // AXI4Stream sink: Clock
    input  wire                                    S_AXIS_ACLK,
    // AXI4Stream sink: Reset
    input  wire                                    S_AXIS_ARESETN,
    // Ready to accept data in
    output wire                                    S_AXIS_TREADY,
    // Data in
    input  wire [C_S_AXIS_TDATA_WIDTH-1 : 0]       S_AXIS_TDATA,
    // Byte qualifier
    input  wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0]   S_AXIS_TSTRB,
    // Indicates boundary of last packet
    input  wire                                    S_AXIS_TLAST,
    // Data is in valid
    input  wire                                    S_AXIS_TVALID
);

    // This module is intentionally unused.
    //
    // The generated Vivado S00_AXIS example buffered a fixed number of words.
    // That is not what we want for this IP: the real sink-side backpressure is
    // produced by ingress_top/frame_crack/mold_deframe/realign in the top file.

    assign S_AXIS_TREADY = 1'b0;

endmodule

`default_nettype wire
