// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Zircon IP stack - TX packet buffer
 */
module zircon_ip_tx_buffer #
(
    parameter N_UI = 4,
    parameter TX_RAM_SIZE = 32768
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * Packet data input
     */
    taxi_axis_if.snk   s_axis_pkt_ui[N_UI],

    /*
     * Metadata output
     */
    taxi_axis_if.src   m_axis_meta_len,

    /*
     * Transfer command input and packet data output
     */
    taxi_axis_if.src   m_axis_pkt
);

localparam DATA_W = m_axis_pkt.DATA_W;
localparam TX_USER_W = m_axis_pkt.USER_W;
localparam TX_TAG_W = m_axis_pkt.ID_W;
localparam TX_DEST_W = s_axis_pkt_ui[0].DEST_W;

taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(TX_USER_W), .ID_EN(1), .ID_W(TX_TAG_W), .DEST_EN(1), .DEST_W(TX_DEST_W)) axis_pkt_1();
taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(TX_USER_W), .ID_EN(1), .ID_W(TX_TAG_W)) axis_pkt_2();

taxi_axis_arb_mux #(
    .S_COUNT(N_UI),
    .UPDATE_TID(1'b0),
    .ARB_ROUND_ROBIN(1'b1),
    .ARB_LSB_HIGH_PRIO(1'b1)
)
mux_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream inputs (sink)
     */
    .s_axis(s_axis_pkt_ui),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(axis_pkt_1)
);

zircon_ip_len_cksum #(
    .START_OFFSET(0)
)
tx_len_cksum_inst (
    .clk(clk),
    .rst(rst),

    /*
     * Packet passthrough
     */
    .s_axis_pkt(axis_pkt_1),
    .m_axis_pkt(axis_pkt_2),

    /*
     * Packet metadata output
     */
    .m_axis_meta(m_axis_meta_len)
);

taxi_axis_fifo #(
    .DEPTH(TX_RAM_SIZE),
    .RAM_PIPELINE(1),
    .OUTPUT_FIFO_EN(1'b0),
    .FRAME_FIFO(1'b0),
    .USER_BAD_FRAME_VALUE(1'b1),
    .USER_BAD_FRAME_MASK(1'b1),
    .DROP_OVERSIZE_FRAME(1'b0),
    .DROP_BAD_FRAME(1'b0),
    .DROP_WHEN_FULL(1'b0),
    .MARK_WHEN_FULL(1'b0),
    .PAUSE_EN(1'b0)
)
tx_fifo_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(axis_pkt_2),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(m_axis_pkt),

    /*
     * Pause
     */
    .pause_req(1'b0),
    .pause_ack(),

    /*
     * Status
     */
    .status_depth(),
    .status_depth_commit(),
    .status_overflow(),
    .status_bad_frame(),
    .status_good_frame()
);

endmodule

`resetall
