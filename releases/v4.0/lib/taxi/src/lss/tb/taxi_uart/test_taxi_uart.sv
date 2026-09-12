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
 * AXI4-Stream FIFO testbench
 */
module test_taxi_uart #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter PRE_W = 16,
    parameter DATA_W = 8
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(DATA_W)) s_axis_tx();
taxi_axis_if #(.DATA_W(DATA_W)) m_axis_rx();

logic rxd;
logic txd;

logic tx_busy;
logic rx_busy;
logic rx_overrun_error;
logic rx_frame_error;

logic [PRE_W-1:0] prescale;

taxi_uart #(
    .PRE_W(PRE_W)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis_tx(s_axis_tx),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis_rx(m_axis_rx),

    /*
     * UART interface
     */
    .rxd(rxd),
    .txd(txd),

    /*
     * Status
     */
    .tx_busy(tx_busy),
    .rx_busy(rx_busy),
    .rx_overrun_error(rx_overrun_error),
    .rx_frame_error(rx_frame_error),

    /*
     * Configuration
     */
    .prescale(prescale)
);

endmodule

`resetall
