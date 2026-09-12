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
 * Statistics counter testbench
 */
module test_taxi_stats_counter #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter STAT_COUNT_W = 32,
    parameter PIPELINE = 2,
    parameter STAT_INC_W = 16,
    parameter STAT_ID_W = 8,
    parameter AXIL_DATA_W = 32,
    parameter AXIL_ADDR_W = STAT_ID_W + $clog2((STAT_COUNT_W+7)/8)
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(
    .DATA_W(STAT_INC_W),
    .KEEP_EN(0),
    .KEEP_W(1),
    .ID_EN(1),
    .ID_W(STAT_ID_W)
) s_axis_stat();

taxi_axil_if #(
    .DATA_W(AXIL_DATA_W),
    .ADDR_W(AXIL_ADDR_W)
) s_axil();

taxi_stats_counter #(
    .STAT_COUNT_W(STAT_COUNT_W),
    .PIPELINE(PIPELINE)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * Statistics increment input
     */
    .s_axis_stat(s_axis_stat),

    /*
     * AXI Lite register interface
     */
    .s_axil_wr(s_axil),
    .s_axil_rd(s_axil)
);

endmodule

`resetall
