// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025-2026 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream padding logic testbench
 */
module test_taxi_axis_pad #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 8,
    parameter logic KEEP_EN = (DATA_W>8),
    parameter KEEP_W = ((DATA_W+7)/8),
    parameter logic STRB_EN = 1'b0,
    parameter logic LAST_EN = 1'b1,
    parameter logic ID_EN = 1'b0,
    parameter ID_W = 8,
    parameter logic DEST_EN = 1'b0,
    parameter DEST_W = 8,
    parameter logic USER_EN = 1'b1,
    parameter USER_W = 1,
    parameter logic ID_PAD_REG_EN = 1'b1,
    parameter logic DEST_PAD_REG_EN = 1'b1,
    parameter logic USER_PAD_REG_EN = 1'b1,
    parameter MIN_LEN_W = 8,
    parameter logic UNDERFLOW_DROP_EN = 1'b0
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
    .ID_W(ID_W),
    .DEST_EN(DEST_EN),
    .DEST_W(DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) s_axis(), m_axis();

logic cfg_pad_en = '0;
logic [MIN_LEN_W-1:0] cfg_min_pkt_len = 'd60-1;

logic stat_pad_frame;
logic stat_err_user;
logic stat_err_underflow;

taxi_axis_pad #(
    .ID_PAD_REG_EN(ID_PAD_REG_EN),
    .DEST_PAD_REG_EN(DEST_PAD_REG_EN),
    .USER_PAD_REG_EN(USER_PAD_REG_EN),
    .MIN_LEN_W(MIN_LEN_W),
    .UNDERFLOW_DROP_EN(UNDERFLOW_DROP_EN)
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
    .m_axis(m_axis),

    /*
     * Configuration
     */
    .cfg_pad_en(cfg_pad_en),
    .cfg_min_pkt_len(cfg_min_pkt_len),

    /*
     * Status
     */
    .stat_pad_frame(stat_pad_frame),
    .stat_err_user(stat_err_user),
    .stat_err_underflow(stat_err_underflow)
);

endmodule

`resetall
