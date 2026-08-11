`timescale 1 ns / 1 ps
`default_nettype none

import hdl_header::*;

module data_handler_v2_0 #
(
    // AXI4-Stream input width. The current ITCH parser is specialised to 32-bit
    // words, matching network_ingress M00_AXIS.
    parameter integer C_S00_AXIS_TDATA_WIDTH = 32
)
(
    // Ports of AXI4-Stream Slave Bus Interface S00_AXIS
    input  wire                                      s00_axis_aclk,
    input  wire                                      s00_axis_aresetn,
    output wire                                      s00_axis_tready,
    input  wire [C_S00_AXIS_TDATA_WIDTH-1 : 0]       s00_axis_tdata,
    input  wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0]   s00_axis_tstrb,
    input  wire                                      s00_axis_tlast,
    input  wire                                      s00_axis_tvalid,

    // Handshake to the order-book stage
    input  wire                                      ready_i,

    // Flattened data_t output for Vivado IP Integrator
    output wire [216:0]                              rdata_o,
    output wire                                      valid_o
);

    // The packaged-IP boundary is deliberately flat. data_handler itself still
    // uses the shared packed struct contract internally.
    data_t rdata_internal;

    // This wrapper is only intended for the current 32-bit parser contract.
    initial begin
        if (C_S00_AXIS_TDATA_WIDTH != AXIS_DATA_W) begin
            $error("data_handler_v2_0 requires C_S00_AXIS_TDATA_WIDTH == AXIS_DATA_W (%0d)",
                   AXIS_DATA_W);
        end
        if (DATA_T_W != 217 || $bits(rdata_internal) != 217) begin
            $error("data_handler_v2_0 expects data_t to remain 217 bits");
        end
    end

    // S00_AXIS_TSTRB is intentionally not consumed by data_handler. The
    // upstream network_ingress emits only complete 32-bit ITCH words and drives
    // TSTRB to 4'b1111, so retaining TSTRB at this wrapper boundary keeps the
    // AXI4-Stream interfaces structurally compatible without adding logic.
    data_handler #(
        .PACKET_W (C_S00_AXIS_TDATA_WIDTH)
    ) data_handler_inst (
        .clk        (s00_axis_aclk),
        .rst_n      (s00_axis_aresetn),

        .s_tdata_i  (s00_axis_tdata),
        .s_tvalid_i (s00_axis_tvalid),
        .s_tlast_i  (s00_axis_tlast),
        .s_tready_o (s00_axis_tready),

        .ready_i    (ready_i),
        .rdata_o    (rdata_internal),
        .valid_o    (valid_o)
    );

    // Packed structs map directly to a flat vector with no registers or
    // additional pipeline stage.
    assign rdata_o = rdata_internal;

endmodule

`default_nettype wire
