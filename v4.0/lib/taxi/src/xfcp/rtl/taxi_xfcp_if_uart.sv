// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2017-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * XFCP Interface (UART)
 */
module taxi_xfcp_if_uart #(
    parameter PRE_W = 16,
    parameter TX_FIFO_DEPTH = 512,
    parameter RX_FIFO_DEPTH = 512
)
(
    input  wire logic              clk,
    input  wire logic              rst,

    /*
     * UART interface
     */
    input  wire logic              uart_rxd,
    output wire logic              uart_txd,

    /*
     * XFCP downstream port
     */
    taxi_axis_if.src               xfcp_dsp_ds,
    taxi_axis_if.snk               xfcp_dsp_us,

    /*
     * Configuration
     */
    input  wire logic [PRE_W-1:0]  prescale
);

taxi_axis_if #(.DATA_W(8), .LAST_EN(0)) uart_tx(), uart_rx();
taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) fifo_tx(), fifo_rx();

taxi_uart #(
    .PRE_W(PRE_W)
)
uart_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis_tx(uart_tx),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis_rx(uart_rx),

    /*
     * UART interface
     */
    .rxd(uart_rxd),
    .txd(uart_txd),

    /*
     * Status
     */
    .tx_busy(),
    .rx_busy(),
    .rx_overrun_error(),
    .rx_frame_error(),

    /*
     * Configuration
     */
    .prescale(prescale)
);

taxi_axis_cobs_encode #(
    .APPEND_ZERO(1)
)
cobs_encode_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(fifo_tx),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(uart_tx)
);

taxi_axis_cobs_decode
cobs_decode_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(uart_rx),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(fifo_rx)
);

taxi_axis_fifo #(
    .DEPTH(TX_FIFO_DEPTH),
    .FRAME_FIFO(1),
    .DROP_BAD_FRAME(1),
    .DROP_WHEN_FULL(0)
)
tx_fifo_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(xfcp_dsp_us),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(fifo_tx),

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

taxi_axis_fifo #(
    .DEPTH(RX_FIFO_DEPTH),
    .FRAME_FIFO(1),
    .DROP_BAD_FRAME(1),
    .DROP_WHEN_FULL(1)
)
rx_fifo_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(fifo_rx),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(xfcp_dsp_ds),

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
