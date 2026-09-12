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
 * Zircon IP stack - TX ingress module
 */
module zircon_ip_tx_ingress #
(
    parameter N_UI = 4,
    parameter UI_TX_FIFO_DEPTH = 32,
    parameter logic UI_TX_FIFO_EB_MODE = 1'b1
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * Client user interface
     */
    input  wire logic  ui_clk,
    input  wire logic  ui_rst,
    taxi_axis_if.snk   s_axis_ui_tx,
    taxi_axis_if.src   m_axis_ui_tx_cpl,

    /*
     * Internal interfaces
     */
    taxi_axis_if.src   m_axis_pkt
);

localparam UI_DATA_W = s_axis_ui_tx.DATA_W;
localparam DATA_W = m_axis_pkt.DATA_W;

// TX FIFO
taxi_axis_async_fifo #(
    .DEPTH(UI_TX_FIFO_EB_MODE ? (UI_DATA_W > DATA_W ? UI_DATA_W : DATA_W)/8*UI_TX_FIFO_DEPTH : UI_TX_FIFO_DEPTH),
    .RAM_PIPELINE(1),
    .OUTPUT_FIFO_EN(1'b0),
    .FRAME_FIFO(1'b0),
    .USER_BAD_FRAME_VALUE(1'b1),
    .USER_BAD_FRAME_MASK(1'b1),
    .DROP_OVERSIZE_FRAME(!UI_TX_FIFO_EB_MODE),
    .DROP_BAD_FRAME(!UI_TX_FIFO_EB_MODE),
    .DROP_WHEN_FULL(1'b0),
    .MARK_WHEN_FULL(1'b0),
    .PAUSE_EN(1'b0)
)
tx_fifo_inst (
    /*
     * AXI4-Stream input (sink)
     */
    .s_clk(ui_clk),
    .s_rst(ui_rst),
    .s_axis(s_axis_ui_tx),

    /*
     * AXI4-Stream output (source)
     */
    .m_clk(clk),
    .m_rst(rst),
    .m_axis(m_axis_pkt),

    /*
     * Pause
     */
    .s_pause_req(1'b0),
    .s_pause_ack(),
    .m_pause_req(1'b0),
    .m_pause_ack(),

    /*
     * Status
     */
    .s_status_depth(),
    .s_status_depth_commit(),
    .s_status_overflow(),
    .s_status_bad_frame(),
    .s_status_good_frame(),
    .m_status_depth(),
    .m_status_depth_commit(),
    .m_status_overflow(),
    .m_status_bad_frame(),
    .m_status_good_frame()
);

endmodule

`resetall
