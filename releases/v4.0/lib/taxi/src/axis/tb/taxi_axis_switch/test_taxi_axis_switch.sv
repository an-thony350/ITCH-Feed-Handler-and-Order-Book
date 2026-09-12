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
 * AXI4-Stream switch testbench
 */
module test_taxi_axis_switch #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_W = 8,
    parameter logic KEEP_EN = (DATA_W>8),
    parameter KEEP_W = ((DATA_W+7)/8),
    parameter logic STRB_EN = 1'b0,
    parameter logic LAST_EN = 1'b1,
    parameter logic ID_EN = 1'b0,
    parameter S_ID_W = 8,
    parameter M_ID_W = S_ID_W+$clog2(S_COUNT),
    parameter logic DEST_EN = 1'b0,
    parameter M_DEST_W = 1,
    parameter S_DEST_W = M_DEST_W+$clog2(M_COUNT),
    parameter logic USER_EN = 1'b1,
    parameter USER_W = 1,
    parameter M_BASE[M_COUNT] = '{M_COUNT{'0}},
    parameter M_TOP[M_COUNT] = '{M_COUNT{'0}},
    parameter logic AUTO_ADDR = 1'b1,
    parameter logic M_CONNECT[M_COUNT][S_COUNT] = '{M_COUNT{'{S_COUNT{1'b1}}}},
    parameter logic UPDATE_TID = 1'b0,
    parameter S_REG_TYPE = 0,
    parameter M_REG_TYPE = 2,
    parameter logic ARB_ROUND_ROBIN = 1'b1,
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
    .DEST_W(S_DEST_W),
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
    .DEST_W(M_DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) m_axis[M_COUNT]();

taxi_axis_switch #(
    .S_COUNT(S_COUNT),
    .M_COUNT(M_COUNT),
    .M_BASE(M_BASE),
    .M_TOP(M_TOP),
    .AUTO_ADDR(AUTO_ADDR),
    .M_CONNECT(M_CONNECT),
    .UPDATE_TID(UPDATE_TID),
    .S_REG_TYPE(S_REG_TYPE),
    .M_REG_TYPE(M_REG_TYPE),
    .ARB_ROUND_ROBIN(ARB_ROUND_ROBIN),
    .ARB_LSB_HIGH_PRIO(ARB_LSB_HIGH_PRIO)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream inputs (sink)
     */
    .s_axis(s_axis),

    /*
     * AXI4-Stream outputs (source)
     */
    .m_axis(m_axis)
);

endmodule

`resetall
