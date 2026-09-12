// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2015-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * 1G Ethernet MAC with GMII interface
 */
module taxi_eth_mac_1g_gmii #
(
    parameter logic SIM = 1'b0,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "virtex7",
    parameter logic PTP_TS_EN = 1'b0,
    parameter PTP_TS_W = 96,
    parameter logic PFC_EN = 1'b0,
    parameter logic PAUSE_EN = PFC_EN,
    parameter logic STAT_EN = 1'b0,
    parameter STAT_TX_LEVEL = 1,
    parameter STAT_RX_LEVEL = STAT_TX_LEVEL,
    parameter STAT_ID_BASE = 0,
    parameter STAT_UPDATE_PERIOD = 1024,
    parameter logic STAT_STR_EN = 1'b0,
    parameter logic [8*8-1:0] STAT_PREFIX_STR = "MAC"
)
(
    input  wire logic                 gtx_clk,
    input  wire logic                 gtx_rst,
    output wire logic                 rx_clk,
    output wire logic                 rx_rst,
    output wire logic                 tx_clk,
    output wire logic                 tx_rst,

    /*
     * Transmit interface (AXI stream)
     */
    taxi_axis_if.snk                  s_axis_tx,
    taxi_axis_if.src                  m_axis_tx_cpl,

    /*
     * Receive interface (AXI stream)
     */
    taxi_axis_if.src                  m_axis_rx,

    /*
     * GMII interface
     */
    input  wire logic                 gmii_rx_clk,
    input  wire logic [7:0]           gmii_rxd,
    input  wire logic                 gmii_rx_dv,
    input  wire logic                 gmii_rx_er,
    input  wire logic                 mii_tx_clk,
    output wire logic                 gmii_tx_clk,
    output wire logic [7:0]           gmii_txd,
    output wire logic                 gmii_tx_en,
    output wire logic                 gmii_tx_er,

    /*
     * PTP
     */
    input  wire logic [PTP_TS_W-1:0]  tx_ptp_ts = '0,
    input  wire logic [PTP_TS_W-1:0]  rx_ptp_ts = '0,

    /*
     * Link-level Flow Control (LFC) (IEEE 802.3 annex 31B PAUSE)
     */
    input  wire logic                 tx_lfc_req = 1'b0,
    input  wire logic                 tx_lfc_resend = 1'b0,
    input  wire logic                 rx_lfc_en = 1'b0,
    output wire logic                 rx_lfc_req,
    input  wire logic                 rx_lfc_ack = 1'b0,

    /*
     * Priority Flow Control (PFC) (IEEE 802.3 annex 31D PFC)
     */
    input  wire logic [7:0]           tx_pfc_req = '0,
    input  wire logic                 tx_pfc_resend = 1'b0,
    input  wire logic [7:0]           rx_pfc_en = '0,
    output wire logic [7:0]           rx_pfc_req,
    input  wire logic [7:0]           rx_pfc_ack = '0,

    /*
     * Pause interface
     */
    input  wire logic                 tx_lfc_pause_en = 1'b0,
    input  wire logic                 tx_pause_req = 1'b0,
    output wire logic                 tx_pause_ack,

    /*
     * Statistics
     */
    input  wire logic                 stat_clk,
    input  wire logic                 stat_rst,
    taxi_axis_if.src                  m_axis_stat,

    /*
     * Status
     */
    output wire logic                 tx_start_packet,
    output wire logic                 stat_tx_byte,
    output wire logic [15:0]          stat_tx_pkt_len,
    output wire logic                 stat_tx_pkt_ucast,
    output wire logic                 stat_tx_pkt_mcast,
    output wire logic                 stat_tx_pkt_bcast,
    output wire logic                 stat_tx_pkt_vlan,
    output wire logic                 stat_tx_pkt_good,
    output wire logic                 stat_tx_pkt_bad,
    output wire logic                 stat_tx_pad_frame,
    output wire logic                 stat_tx_err_oversize,
    output wire logic                 stat_tx_err_user,
    output wire logic                 stat_tx_err_underflow,
    output wire logic                 rx_start_packet,
    output wire logic                 stat_rx_byte,
    output wire logic [15:0]          stat_rx_pkt_len,
    output wire logic                 stat_rx_pkt_fragment,
    output wire logic                 stat_rx_pkt_jabber,
    output wire logic                 stat_rx_pkt_ucast,
    output wire logic                 stat_rx_pkt_mcast,
    output wire logic                 stat_rx_pkt_bcast,
    output wire logic                 stat_rx_pkt_vlan,
    output wire logic                 stat_rx_pkt_good,
    output wire logic                 stat_rx_pkt_bad,
    output wire logic                 stat_rx_err_oversize,
    output wire logic                 stat_rx_err_bad_fcs,
    output wire logic                 stat_rx_err_bad_block,
    output wire logic                 stat_rx_err_framing,
    output wire logic                 stat_rx_err_preamble,
    input  wire logic                 stat_rx_fifo_drop = 1'b0,
    output wire logic [1:0]           link_speed,
    output wire logic                 stat_tx_mcf,
    output wire logic                 stat_rx_mcf,
    output wire logic                 stat_tx_lfc_pkt,
    output wire logic                 stat_tx_lfc_xon,
    output wire logic                 stat_tx_lfc_xoff,
    output wire logic                 stat_tx_lfc_paused,
    output wire logic                 stat_tx_pfc_pkt,
    output wire logic [7:0]           stat_tx_pfc_xon,
    output wire logic [7:0]           stat_tx_pfc_xoff,
    output wire logic [7:0]           stat_tx_pfc_paused,
    output wire logic                 stat_rx_lfc_pkt,
    output wire logic                 stat_rx_lfc_xon,
    output wire logic                 stat_rx_lfc_xoff,
    output wire logic                 stat_rx_lfc_paused,
    output wire logic                 stat_rx_pfc_pkt,
    output wire logic [7:0]           stat_rx_pfc_xon,
    output wire logic [7:0]           stat_rx_pfc_xoff,
    output wire logic [7:0]           stat_rx_pfc_paused,

    /*
     * Configuration
     */
    input  wire logic                 cfg_tx_pad_en = 1'b1,
    input  wire logic [7:0]           cfg_tx_min_pkt_len = 8'd60-1,
    input  wire logic [15:0]          cfg_tx_max_pkt_len = 16'd1518-1,
    input  wire logic [7:0]           cfg_tx_ifg = 8'd12,
    input  wire logic                 cfg_tx_enable = 1'b1,
    input  wire logic [15:0]          cfg_rx_max_pkt_len = 16'd1518-1,
    input  wire logic                 cfg_rx_enable = 1'b1,
    input  wire logic [47:0]          cfg_mcf_rx_eth_dst_mcast = 48'h01_80_C2_00_00_01,
    input  wire logic                 cfg_mcf_rx_check_eth_dst_mcast = 1'b1,
    input  wire logic [47:0]          cfg_mcf_rx_eth_dst_ucast = 48'd0,
    input  wire logic                 cfg_mcf_rx_check_eth_dst_ucast = 1'b0,
    input  wire logic [47:0]          cfg_mcf_rx_eth_src = 48'd0,
    input  wire logic                 cfg_mcf_rx_check_eth_src = 1'b0,
    input  wire logic [15:0]          cfg_mcf_rx_eth_type = 16'h8808,
    input  wire logic [15:0]          cfg_mcf_rx_opcode_lfc = 16'h0001,
    input  wire logic                 cfg_mcf_rx_check_opcode_lfc = 1'b1,
    input  wire logic [15:0]          cfg_mcf_rx_opcode_pfc = 16'h0101,
    input  wire logic                 cfg_mcf_rx_check_opcode_pfc = 1'b1,
    input  wire logic                 cfg_mcf_rx_forward = 1'b0,
    input  wire logic                 cfg_mcf_rx_enable = 1'b0,
    input  wire logic [47:0]          cfg_tx_lfc_eth_dst = 48'h01_80_C2_00_00_01,
    input  wire logic [47:0]          cfg_tx_lfc_eth_src = 48'h80_23_31_43_54_4C,
    input  wire logic [15:0]          cfg_tx_lfc_eth_type = 16'h8808,
    input  wire logic [15:0]          cfg_tx_lfc_opcode = 16'h0001,
    input  wire logic                 cfg_tx_lfc_en = 1'b0,
    input  wire logic [15:0]          cfg_tx_lfc_quanta = 16'hffff,
    input  wire logic [15:0]          cfg_tx_lfc_refresh = 16'h7fff,
    input  wire logic [47:0]          cfg_tx_pfc_eth_dst = 48'h01_80_C2_00_00_01,
    input  wire logic [47:0]          cfg_tx_pfc_eth_src = 48'h80_23_31_43_54_4C,
    input  wire logic [15:0]          cfg_tx_pfc_eth_type = 16'h8808,
    input  wire logic [15:0]          cfg_tx_pfc_opcode = 16'h0101,
    input  wire logic                 cfg_tx_pfc_en = 1'b0,
    input  wire logic [15:0]          cfg_tx_pfc_quanta[8] = '{8{16'hffff}},
    input  wire logic [15:0]          cfg_tx_pfc_refresh[8] = '{8{16'h7fff}},
    input  wire logic [15:0]          cfg_rx_lfc_opcode = 16'h0001,
    input  wire logic                 cfg_rx_lfc_en = 1'b0,
    input  wire logic [15:0]          cfg_rx_pfc_opcode = 16'h0101,
    input  wire logic                 cfg_rx_pfc_en = 1'b0
);

wire tx_mii_select_sync;

taxi_sync_signal #(
    .WIDTH(1),
    .N(2)
)
tx_mii_select_sync_inst (
    .clk(tx_clk),
    .in(!link_speed[1]),
    .out(tx_mii_select_sync)
);

wire rx_mii_select_sync;

taxi_sync_signal #(
    .WIDTH(1),
    .N(2)
)
rx_mii_select_sync_inst (
    .clk(rx_clk),
    .in(!link_speed[1]),
    .out(rx_mii_select_sync)
);

wire [7:0]  mac_gmii_rxd;
wire        mac_gmii_rx_dv;
wire        mac_gmii_rx_er;
wire [7:0]  mac_gmii_txd;
wire        mac_gmii_tx_en;
wire        mac_gmii_tx_er;

taxi_gmii_phy_if #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY)
)
gmii_phy_if_inst (
    .gtx_clk(gtx_clk),
    .gtx_rst(gtx_rst),

    /*
     * GMII interface to MAC
     */
    .mac_gmii_rx_clk(rx_clk),
    .mac_gmii_rx_rst(rx_rst),
    .mac_gmii_rxd(mac_gmii_rxd),
    .mac_gmii_rx_dv(mac_gmii_rx_dv),
    .mac_gmii_rx_er(mac_gmii_rx_er),
    .mac_gmii_tx_clk(tx_clk),
    .mac_gmii_tx_rst(tx_rst),
    .mac_gmii_txd(mac_gmii_txd),
    .mac_gmii_tx_en(mac_gmii_tx_en),
    .mac_gmii_tx_er(mac_gmii_tx_er),

    /*
     * GMII interface to PHY
     */
    .phy_gmii_rx_clk(gmii_rx_clk),
    .phy_gmii_rxd(gmii_rxd),
    .phy_gmii_rx_dv(gmii_rx_dv),
    .phy_gmii_rx_er(gmii_rx_er),
    .phy_mii_tx_clk(mii_tx_clk),
    .phy_gmii_tx_clk(gmii_tx_clk),
    .phy_gmii_txd(gmii_txd),
    .phy_gmii_tx_en(gmii_tx_en),
    .phy_gmii_tx_er(gmii_tx_er),

    .link_speed(link_speed)
);

taxi_eth_mac_1g #(
    .DATA_W(8),
    .PTP_TS_EN(PTP_TS_EN),
    .PTP_TS_W(PTP_TS_W),
    .PFC_EN(PFC_EN),
    .PAUSE_EN(PAUSE_EN),
    .STAT_EN(STAT_EN),
    .STAT_TX_LEVEL(STAT_TX_LEVEL),
    .STAT_RX_LEVEL(STAT_RX_LEVEL),
    .STAT_ID_BASE(STAT_ID_BASE),
    .STAT_UPDATE_PERIOD(STAT_UPDATE_PERIOD),
    .STAT_STR_EN(STAT_STR_EN),
    .STAT_PREFIX_STR(STAT_PREFIX_STR)
)
eth_mac_1g_inst (
    .tx_clk(tx_clk),
    .tx_rst(tx_rst),
    .rx_clk(rx_clk),
    .rx_rst(rx_rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(s_axis_tx),
    .m_axis_tx_cpl(m_axis_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(m_axis_rx),

    /*
     * GMII interface
     */
    .gmii_rxd(mac_gmii_rxd),
    .gmii_rx_dv(mac_gmii_rx_dv),
    .gmii_rx_er(mac_gmii_rx_er),
    .gmii_txd(mac_gmii_txd),
    .gmii_tx_en(mac_gmii_tx_en),
    .gmii_tx_er(mac_gmii_tx_er),

    /*
     * PTP
     */
    .tx_ptp_ts(tx_ptp_ts),
    .rx_ptp_ts(rx_ptp_ts),

    /*
     * Link-level Flow Control (LFC) (IEEE 802.3 annex 31B PAUSE)
     */
    .tx_lfc_req(tx_lfc_req),
    .tx_lfc_resend(tx_lfc_resend),
    .rx_lfc_en(rx_lfc_en),
    .rx_lfc_req(rx_lfc_req),
    .rx_lfc_ack(rx_lfc_ack),

    /*
     * Priority Flow Control (PFC) (IEEE 802.3 annex 31D PFC)
     */
    .tx_pfc_req(tx_pfc_req),
    .tx_pfc_resend(tx_pfc_resend),
    .rx_pfc_en(rx_pfc_en),
    .rx_pfc_req(rx_pfc_req),
    .rx_pfc_ack(rx_pfc_ack),

    /*
     * Pause interface
     */
    .tx_lfc_pause_en(tx_lfc_pause_en),
    .tx_pause_req(tx_pause_req),
    .tx_pause_ack(tx_pause_ack),

    /*
     * Control
     */
    .rx_clk_enable(1'b1),
    .tx_clk_enable(1'b1),
    .rx_mii_select(rx_mii_select_sync),
    .tx_mii_select(tx_mii_select_sync),

    /*
     * Statistics
     */
    .stat_clk(stat_clk),
    .stat_rst(stat_rst),
    .m_axis_stat(m_axis_stat),

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
    .stat_tx_pad_frame(stat_tx_pad_frame),
    .stat_tx_err_oversize(stat_tx_err_oversize),
    .stat_tx_err_user(stat_tx_err_user),
    .stat_tx_err_underflow(stat_tx_err_underflow),
    .rx_start_packet(rx_start_packet),
    .stat_rx_byte(stat_rx_byte),
    .stat_rx_pkt_len(stat_rx_pkt_len),
    .stat_rx_pkt_fragment(stat_rx_pkt_fragment),
    .stat_rx_pkt_jabber(stat_rx_pkt_jabber),
    .stat_rx_pkt_ucast(stat_rx_pkt_ucast),
    .stat_rx_pkt_mcast(stat_rx_pkt_mcast),
    .stat_rx_pkt_bcast(stat_rx_pkt_bcast),
    .stat_rx_pkt_vlan(stat_rx_pkt_vlan),
    .stat_rx_pkt_good(stat_rx_pkt_good),
    .stat_rx_pkt_bad(stat_rx_pkt_bad),
    .stat_rx_err_oversize(stat_rx_err_oversize),
    .stat_rx_err_bad_fcs(stat_rx_err_bad_fcs),
    .stat_rx_err_bad_block(stat_rx_err_bad_block),
    .stat_rx_err_framing(stat_rx_err_framing),
    .stat_rx_err_preamble(stat_rx_err_preamble),
    .stat_rx_fifo_drop(stat_rx_fifo_drop),
    .stat_tx_mcf(stat_tx_mcf),
    .stat_rx_mcf(stat_rx_mcf),
    .stat_tx_lfc_pkt(stat_tx_lfc_pkt),
    .stat_tx_lfc_xon(stat_tx_lfc_xon),
    .stat_tx_lfc_xoff(stat_tx_lfc_xoff),
    .stat_tx_lfc_paused(stat_tx_lfc_paused),
    .stat_tx_pfc_pkt(stat_tx_pfc_pkt),
    .stat_tx_pfc_xon(stat_tx_pfc_xon),
    .stat_tx_pfc_xoff(stat_tx_pfc_xoff),
    .stat_tx_pfc_paused(stat_tx_pfc_paused),
    .stat_rx_lfc_pkt(stat_rx_lfc_pkt),
    .stat_rx_lfc_xon(stat_rx_lfc_xon),
    .stat_rx_lfc_xoff(stat_rx_lfc_xoff),
    .stat_rx_lfc_paused(stat_rx_lfc_paused),
    .stat_rx_pfc_pkt(stat_rx_pfc_pkt),
    .stat_rx_pfc_xon(stat_rx_pfc_xon),
    .stat_rx_pfc_xoff(stat_rx_pfc_xoff),
    .stat_rx_pfc_paused(stat_rx_pfc_paused),

    /*
     * Configuration
     */
    .cfg_tx_pad_en(cfg_tx_pad_en),
    .cfg_tx_min_pkt_len(cfg_tx_min_pkt_len),
    .cfg_tx_max_pkt_len(cfg_tx_max_pkt_len),
    .cfg_tx_ifg(cfg_tx_ifg),
    .cfg_tx_enable(cfg_tx_enable),
    .cfg_rx_max_pkt_len(cfg_rx_max_pkt_len),
    .cfg_rx_enable(cfg_rx_enable),
    .cfg_mcf_rx_eth_dst_mcast(cfg_mcf_rx_eth_dst_mcast),
    .cfg_mcf_rx_check_eth_dst_mcast(cfg_mcf_rx_check_eth_dst_mcast),
    .cfg_mcf_rx_eth_dst_ucast(cfg_mcf_rx_eth_dst_ucast),
    .cfg_mcf_rx_check_eth_dst_ucast(cfg_mcf_rx_check_eth_dst_ucast),
    .cfg_mcf_rx_eth_src(cfg_mcf_rx_eth_src),
    .cfg_mcf_rx_check_eth_src(cfg_mcf_rx_check_eth_src),
    .cfg_mcf_rx_eth_type(cfg_mcf_rx_eth_type),
    .cfg_mcf_rx_opcode_lfc(cfg_mcf_rx_opcode_lfc),
    .cfg_mcf_rx_check_opcode_lfc(cfg_mcf_rx_check_opcode_lfc),
    .cfg_mcf_rx_opcode_pfc(cfg_mcf_rx_opcode_pfc),
    .cfg_mcf_rx_check_opcode_pfc(cfg_mcf_rx_check_opcode_pfc),
    .cfg_mcf_rx_forward(cfg_mcf_rx_forward),
    .cfg_mcf_rx_enable(cfg_mcf_rx_enable),
    .cfg_tx_lfc_eth_dst(cfg_tx_lfc_eth_dst),
    .cfg_tx_lfc_eth_src(cfg_tx_lfc_eth_src),
    .cfg_tx_lfc_eth_type(cfg_tx_lfc_eth_type),
    .cfg_tx_lfc_opcode(cfg_tx_lfc_opcode),
    .cfg_tx_lfc_en(cfg_tx_lfc_en),
    .cfg_tx_lfc_quanta(cfg_tx_lfc_quanta),
    .cfg_tx_lfc_refresh(cfg_tx_lfc_refresh),
    .cfg_tx_pfc_eth_dst(cfg_tx_pfc_eth_dst),
    .cfg_tx_pfc_eth_src(cfg_tx_pfc_eth_src),
    .cfg_tx_pfc_eth_type(cfg_tx_pfc_eth_type),
    .cfg_tx_pfc_opcode(cfg_tx_pfc_opcode),
    .cfg_tx_pfc_en(cfg_tx_pfc_en),
    .cfg_tx_pfc_quanta(cfg_tx_pfc_quanta),
    .cfg_tx_pfc_refresh(cfg_tx_pfc_refresh),
    .cfg_rx_lfc_opcode(cfg_rx_lfc_opcode),
    .cfg_rx_lfc_en(cfg_rx_lfc_en),
    .cfg_rx_pfc_opcode(cfg_rx_pfc_opcode),
    .cfg_rx_pfc_en(cfg_rx_pfc_en)
);

endmodule

`resetall
