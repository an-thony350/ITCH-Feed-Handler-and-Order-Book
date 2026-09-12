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
 * AXI4-Stream arbitrated multiplexer testbench
 */
module test_taxi_axis_arb_mux #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter S_COUNT = 4,
    parameter DATA_W = 8,
    parameter logic KEEP_EN = (DATA_W>8),
    parameter KEEP_W = ((DATA_W+7)/8),
    parameter logic STRB_EN = 1'b0,
    parameter logic LAST_EN = 1'b1,
    parameter logic ID_EN = 1'b0,
    parameter S_ID_W = 8,
    parameter M_ID_W = S_ID_W+$clog2(S_COUNT),
    parameter logic DEST_EN = 1'b0,
    parameter DEST_W = 8,
    parameter logic USER_EN = 1'b1,
    parameter USER_W = 1,
    parameter logic UPDATE_TID = 1'b0,
    parameter logic ARB_ROUND_ROBIN = 1'b0,
    parameter logic ARB_LSB_HIGH_PRIO = 1'b1
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(
    .DATA_W(DATA_W),
    .KEEP_EN(KEEP_EN),
    .KEEP_W(KEEP_W),
    .STRB_EN(STRB_EN),
    .LAST_EN(LAST_EN),
    .ID_EN(ID_EN),
    .ID_W(S_ID_W),
    .DEST_EN(DEST_EN),
    .DEST_W(DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) s_axis[S_COUNT]();

taxi_axis_if #(
    .DATA_W(DATA_W),
    .KEEP_EN(KEEP_EN),
    .KEEP_W(KEEP_W),
    .STRB_EN(STRB_EN),
    .LAST_EN(LAST_EN),
    .ID_EN(ID_EN),
    .ID_W(M_ID_W),
    .DEST_EN(DEST_EN),
    .DEST_W(DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) m_axis();

taxi_axis_arb_mux #(
    .S_COUNT(S_COUNT),
    .UPDATE_TID(UPDATE_TID),
    .ARB_ROUND_ROBIN(ARB_ROUND_ROBIN),
    .ARB_LSB_HIGH_PRIO(ARB_LSB_HIGH_PRIO)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(s_axis),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(m_axis)
);

endmodule

`resetall
