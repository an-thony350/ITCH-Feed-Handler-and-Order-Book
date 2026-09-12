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
 * AXI4-Stream GMII frame transmitter testbench
 */
module test_taxi_axis_gmii_tx #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 8,
    parameter logic PADDING_EN = 1'b1,
    parameter MIN_FRAME_LEN = 64,
    parameter logic PTP_TS_EN = 1'b0,
    parameter PTP_TS_W = 96,
    parameter TX_TAG_W = 16,
    parameter logic TX_CPL_CTRL_IN_TUSER = 1'b0
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam USER_W = TX_CPL_CTRL_IN_TUSER ? 2 : 1;

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(USER_W), .ID_EN(1), .ID_W(TX_TAG_W)) s_axis_tx();
taxi_axis_if #(.DATA_W(PTP_TS_W), .KEEP_W(1), .ID_EN(1), .ID_W(TX_TAG_W)) m_axis_tx_cpl();

logic [DATA_W-1:0] gmii_txd;
logic gmii_tx_en;
logic gmii_tx_er;

logic [PTP_TS_W-1:0] ptp_ts;

logic clk_enable;
logic mii_select;

logic [15:0] cfg_tx_max_pkt_len;
logic [7:0] cfg_tx_ifg;
logic cfg_tx_enable;

logic tx_start_packet;
logic stat_tx_byte;
logic [15:0] stat_tx_pkt_len;
logic stat_tx_pkt_ucast;
logic stat_tx_pkt_mcast;
logic stat_tx_pkt_bcast;
logic stat_tx_pkt_vlan;
logic stat_tx_pkt_good;
logic stat_tx_pkt_bad;
logic stat_tx_err_oversize;
logic stat_tx_err_user;
logic stat_tx_err_underflow;

taxi_axis_gmii_tx #(
    .DATA_W(DATA_W),
    .PADDING_EN(PADDING_EN),
    .MIN_FRAME_LEN(MIN_FRAME_LEN),
    .PTP_TS_EN(PTP_TS_EN),
    .PTP_TS_W(PTP_TS_W),
    .TX_CPL_CTRL_IN_TUSER(TX_CPL_CTRL_IN_TUSER)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis_tx(s_axis_tx),
    .m_axis_tx_cpl(m_axis_tx_cpl),

    /*
     * GMII output
     */
    .gmii_txd(gmii_txd),
    .gmii_tx_en(gmii_tx_en),
    .gmii_tx_er(gmii_tx_er),

    /*
     * PTP
     */
    .ptp_ts(ptp_ts),

    /*
     * Control
     */
    .clk_enable(clk_enable),
    .mii_select(mii_select),

    /*
     * Configuration
     */
    .cfg_tx_max_pkt_len(cfg_tx_max_pkt_len),
    .cfg_tx_ifg(cfg_tx_ifg),
    .cfg_tx_enable(cfg_tx_enable),

    /*
     * Status
     */
    .tx_start_packet(tx_start_packet),
    .stat_tx_byte(stat_tx_byte),
    .stat_tx_pkt_len(stat_tx_pkt_len),
    .stat_tx_pkt_ucast(stat_tx_pkt_ucast),
    .stat_tx_pkt_mcast(stat_tx_pkt_mcast),
    .stat_tx_pkt_bcast(stat_tx_pkt_bcast),
    .stat_tx_pkt_vlan(stat_tx_pkt_vlan),
    .stat_tx_pkt_good(stat_tx_pkt_good),
    .stat_tx_pkt_bad(stat_tx_pkt_bad),
    .stat_tx_err_oversize(stat_tx_err_oversize),
    .stat_tx_err_user(stat_tx_err_user),
    .stat_tx_err_underflow(stat_tx_err_underflow)
);

endmodule

`resetall
