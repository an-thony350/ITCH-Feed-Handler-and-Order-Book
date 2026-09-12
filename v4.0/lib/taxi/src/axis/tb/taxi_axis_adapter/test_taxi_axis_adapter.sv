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
module test_taxi_axis_adapter #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter S_DATA_W = 8,
    parameter logic S_KEEP_EN = (S_DATA_W>8),
    parameter S_KEEP_W = ((S_DATA_W+7)/8),
    parameter logic S_STRB_EN = 0,
    parameter M_DATA_W = 8,
    parameter logic M_KEEP_EN = (M_DATA_W>8),
    parameter M_KEEP_W = ((M_DATA_W+7)/8),
    parameter logic M_STRB_EN = 0,
    parameter logic ID_EN = 0,
    parameter ID_W = 8,
    parameter logic DEST_EN = 0,
    parameter DEST_W = 8,
    parameter logic USER_EN = 1,
    parameter USER_W = 1
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(
    .DATA_W(S_DATA_W),
    .KEEP_EN(S_KEEP_EN),
    .KEEP_W(S_KEEP_W),
    .STRB_EN(S_STRB_EN),
    .LAST_EN(1'b1),
    .ID_EN(ID_EN),
    .ID_W(ID_W),
    .DEST_EN(DEST_EN),
    .DEST_W(DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) s_axis();

taxi_axis_if #(
    .DATA_W(M_DATA_W),
    .KEEP_EN(M_KEEP_EN),
    .KEEP_W(M_KEEP_W),
    .STRB_EN(M_STRB_EN),
    .LAST_EN(1'b1),
    .ID_EN(ID_EN),
    .ID_W(ID_W),
    .DEST_EN(DEST_EN),
    .DEST_W(DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) m_axis();

taxi_axis_adapter
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
