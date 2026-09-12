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
 * PTP time distribution ToD timestamp reconstruction module testbench
 */
module test_taxi_ptp_td_rel2tod #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter TS_FNS_W = 16,
    parameter TS_REL_NS_W = 32,
    parameter TS_TOD_S_W = 48,
    parameter TD_SDI_PIPELINE = 2,
    parameter logic ID_EN = 1'b0,
    parameter ID_W = 8,
    parameter logic DEST_EN = 1'b0,
    parameter DEST_W = 8,
    parameter logic USER_EN = 1'b1,
    parameter USER_W = 1
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam TS_REL_W = TS_REL_NS_W + TS_FNS_W;
localparam TS_TOD_W = TS_TOD_S_W + 32 + TS_FNS_W;

logic clk;
logic rst;

logic ptp_clk;
logic ptp_rst;
logic ptp_td_sdi;

taxi_axis_if #(
    .DATA_W(TS_REL_W),
    .KEEP_EN(0),
    .KEEP_W(1),
    .STRB_EN(0),
    .LAST_EN(0),
    .ID_EN(ID_EN),
    .ID_W(ID_W),
    .DEST_EN(DEST_EN),
    .DEST_W(DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) s_axis_ts_rel();

taxi_axis_if #(
    .DATA_W(TS_TOD_W),
    .KEEP_EN(0),
    .KEEP_W(1),
    .STRB_EN(0),
    .LAST_EN(0),
    .ID_EN(ID_EN),
    .ID_W(ID_W),
    .DEST_EN(DEST_EN),
    .DEST_W(DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) m_axis_ts_tod();

taxi_ptp_td_rel2tod #(
    .TS_FNS_W(TS_FNS_W),
    .TS_REL_NS_W(TS_REL_NS_W),
    .TS_TOD_S_W(TS_TOD_S_W),
    .TS_REL_W(TS_REL_W),
    .TS_TOD_W(TS_TOD_W),
    .TD_SDI_PIPELINE(TD_SDI_PIPELINE)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * PTP clock interface
     */
    .ptp_clk(ptp_clk),
    .ptp_rst(ptp_rst),
    .ptp_td_sdi(ptp_td_sdi),

    /*
     * Timestamp conversion
     */
    .s_axis_ts_rel(s_axis_ts_rel),
    .m_axis_ts_tod(m_axis_ts_tod)
);

endmodule

`resetall
