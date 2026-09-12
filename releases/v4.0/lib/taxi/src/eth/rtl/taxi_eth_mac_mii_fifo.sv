// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2019-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * 10M/100M Ethernet MAC with MII interface and TX and RX FIFOs
 */
module taxi_eth_mac_mii_fifo #
(
    parameter logic SIM = 1'b0,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "virtex7",
    parameter logic PADDING_EN = 1'b1,
    parameter MIN_FRAME_LEN = 64,
    parameter logic STAT_EN = 1'b0,
    parameter STAT_TX_LEVEL = 1,
    parameter STAT_RX_LEVEL = STAT_TX_LEVEL,
    parameter STAT_ID_BASE = 0,
    parameter STAT_UPDATE_PERIOD = 1024,
    parameter logic STAT_STR_EN = 1'b0,
    parameter logic [8*8-1:0] STAT_PREFIX_STR = "MAC",
    parameter TX_FIFO_DEPTH = 4096,
    parameter TX_FIFO_RAM_PIPELINE = 1,
    parameter logic TX_FRAME_FIFO = 1'b1,
    parameter logic TX_DROP_OVERSIZE_FRAME = TX_FRAME_FIFO,
    parameter logic TX_DROP_BAD_FRAME = TX_DROP_OVERSIZE_FRAME,
    parameter logic TX_DROP_WHEN_FULL = 1'b0,
    parameter TX_CPL_FIFO_DEPTH = 64,
    parameter RX_FIFO_DEPTH = 4096,
    parameter RX_FIFO_RAM_PIPELINE = 1,
    parameter logic RX_FRAME_FIFO = 1'b1,
    parameter logic RX_DROP_OVERSIZE_FRAME = RX_FRAME_FIFO,
    parameter logic RX_DROP_BAD_FRAME = RX_DROP_OVERSIZE_FRAME,
    parameter logic RX_DROP_WHEN_FULL = RX_DROP_OVERSIZE_FRAME
)
(
    input  wire                       rst,
    input  wire                       logic_clk,
    input  wire                       logic_rst,

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
     * MII interface
     */
    input  wire                       mii_rx_clk,
    input  wire [3:0]                 mii_rxd,
    input  wire                       mii_rx_dv,
    input  wire                       mii_rx_er,
    input  wire                       mii_tx_clk,
    output wire [3:0]                 mii_txd,
    output wire                       mii_tx_en,
    output wire                       mii_tx_er,

    /*
     * Statistics
     */
    input  wire logic                 stat_clk,
    input  wire logic                 stat_rst,
    taxi_axis_if.src                  m_axis_stat,

    /*
     * Status
     */
    output wire logic                 tx_error_underflow,
    output wire logic                 tx_fifo_overflow,
    output wire logic                 tx_fifo_bad_frame,
    output wire logic                 tx_fifo_good_frame,
    output wire logic                 rx_error_bad_frame,
    output wire logic                 rx_error_bad_fcs,
    output wire logic                 rx_fifo_overflow,
    output wire logic                 rx_fifo_bad_frame,
    output wire logic                 rx_fifo_good_frame,

    /*
     * Configuration
     */
    input  wire logic                 cfg_tx_pad_en = 1'b1,
    input  wire logic [7:0]           cfg_tx_min_pkt_len = 8'd60-1,
    input  wire logic [15:0]          cfg_tx_max_pkt_len = 16'd1518-1,
    input  wire logic [7:0]           cfg_tx_ifg = 8'd12,
    input  wire logic                 cfg_tx_enable = 1'b1,
    input  wire logic [15:0]          cfg_rx_max_pkt_len = 16'd1518-1,
    input  wire logic                 cfg_rx_enable = 1'b1
);

localparam PTP_TS_EN = 1'b0;
localparam PTP_TS_W = 96;

localparam TX_USER_W = 1;
localparam RX_USER_W = (PTP_TS_EN ? PTP_TS_W : 0) + 1;
localparam TX_TAG_W = s_axis_tx.ID_W;

wire tx_clk;
wire rx_clk;
wire tx_rst;
wire rx_rst;

taxi_axis_if #(.DATA_W(8), .USER_EN(1), .USER_W(TX_USER_W), .ID_EN(1), .ID_W(TX_TAG_W)) axis_tx_int();
taxi_axis_if #(.DATA_W(PTP_TS_W), .KEEP_W(1), .ID_EN(1), .ID_W(TX_TAG_W)) axis_tx_cpl_int();
taxi_axis_if #(.DATA_W(8), .USER_EN(1), .USER_W(RX_USER_W)) axis_rx_int();

// synchronize MAC status signals into logic clock domain
wire tx_error_underflow_int;

logic [0:0] tx_sync_reg_1 = '0;
logic [0:0] tx_sync_reg_2 = '0;
logic [0:0] tx_sync_reg_3 = '0;
logic [0:0] tx_sync_reg_4 = '0;

assign tx_error_underflow = tx_sync_reg_3[0] ^ tx_sync_reg_4[0];

always_ff @(posedge tx_clk or posedge tx_rst) begin
    if (tx_rst) begin
        tx_sync_reg_1 <= '0;
    end else begin
        tx_sync_reg_1 <= tx_sync_reg_1 ^ {tx_error_underflow_int};
    end
end

always_ff @(posedge logic_clk or posedge logic_rst) begin
    if (logic_rst) begin
        tx_sync_reg_2 <= '0;
        tx_sync_reg_3 <= '0;
        tx_sync_reg_4 <= '0;
    end else begin
        tx_sync_reg_2 <= tx_sync_reg_1;
        tx_sync_reg_3 <= tx_sync_reg_2;
        tx_sync_reg_4 <= tx_sync_reg_3;
    end
end

wire rx_error_bad_frame_int;
wire rx_error_bad_fcs_int;

logic [1:0] rx_sync_reg_1 = '0;
logic [1:0] rx_sync_reg_2 = '0;
logic [1:0] rx_sync_reg_3 = '0;
logic [1:0] rx_sync_reg_4 = '0;

assign rx_error_bad_frame = rx_sync_reg_3[0] ^ rx_sync_reg_4[0];
assign rx_error_bad_fcs = rx_sync_reg_3[1] ^ rx_sync_reg_4[1];

always_ff @(posedge rx_clk or posedge rx_rst) begin
    if (rx_rst) begin
        rx_sync_reg_1 <= '0;
    end else begin
        rx_sync_reg_1 <= rx_sync_reg_1 ^ {rx_error_bad_fcs_int, rx_error_bad_frame_int};
    end
end

always_ff @(posedge logic_clk or posedge logic_rst) begin
    if (logic_rst) begin
        rx_sync_reg_2 <= '0;
        rx_sync_reg_3 <= '0;
        rx_sync_reg_4 <= '0;
    end else begin
        rx_sync_reg_2 <= rx_sync_reg_1;
        rx_sync_reg_3 <= rx_sync_reg_2;
        rx_sync_reg_4 <= rx_sync_reg_3;
    end
end

wire stat_rx_fifo_drop;

taxi_eth_mac_mii #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .PTP_TS_EN(1'b0),
    .PFC_EN(1'b0),
    .PAUSE_EN(1'b0),
    .STAT_EN(STAT_EN),
    .STAT_TX_LEVEL(STAT_TX_LEVEL),
    .STAT_RX_LEVEL(STAT_RX_LEVEL),
    .STAT_ID_BASE(STAT_ID_BASE),
    .STAT_UPDATE_PERIOD(STAT_UPDATE_PERIOD),
    .STAT_STR_EN(STAT_STR_EN),
    .STAT_PREFIX_STR(STAT_PREFIX_STR)
)
eth_mac_mii_inst (
    .rst(rst),
    .tx_clk(tx_clk),
    .tx_rst(tx_rst),
    .rx_clk(rx_clk),
    .rx_rst(rx_rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_tx_int),
    .m_axis_tx_cpl(axis_tx_cpl_int),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_rx_int),

    /*
     * MII interface
     */
    .mii_rx_clk(mii_rx_clk),
    .mii_rxd(mii_rxd),
    .mii_rx_dv(mii_rx_dv),
    .mii_rx_er(mii_rx_er),
    .mii_tx_clk(mii_tx_clk),
    .mii_txd(mii_txd),
    .mii_tx_en(mii_tx_en),
    .mii_tx_er(mii_tx_er),

    /*
     * PTP
     */
    .tx_ptp_ts(0),
    .rx_ptp_ts(0),

    /*
     * Link-level Flow Control (LFC) (IEEE 802.3 annex 31B PAUSE)
     */
    .tx_lfc_req(0),
    .tx_lfc_resend(0),
    .rx_lfc_en(0),
    .rx_lfc_req(),
    .rx_lfc_ack(0),

    /*
     * Priority Flow Control (PFC) (IEEE 802.3 annex 31D PFC)
     */
    .tx_pfc_req(0),
    .tx_pfc_resend(0),
    .rx_pfc_en(0),
    .rx_pfc_req(),
    .rx_pfc_ack(0),

    /*
     * Pause interface
     */
    .tx_lfc_pause_en(0),
    .tx_pause_req(0),
    .tx_pause_ack(),

    /*
     * Statistics
     */
    .stat_clk(stat_clk),
    .stat_rst(stat_rst),
    .m_axis_stat(m_axis_stat),

    /*
     * Status
     */
    // .rx_error_bad_frame(rx_error_bad_frame_int),
    .tx_start_packet(),
    .stat_tx_byte(),
    .stat_tx_pkt_len(),
    .stat_tx_pkt_ucast(),
    .stat_tx_pkt_mcast(),
    .stat_tx_pkt_bcast(),
    .stat_tx_pkt_vlan(),
    .stat_tx_pkt_good(),
    .stat_tx_pkt_bad(),
    .stat_tx_pad_frame(),
    .stat_tx_err_oversize(),
    .stat_tx_err_user(),
    .stat_tx_err_underflow(tx_error_underflow_int),
    .rx_start_packet(),
    .stat_rx_byte(),
    .stat_rx_pkt_len(),
    .stat_rx_pkt_fragment(),
    .stat_rx_pkt_jabber(),
    .stat_rx_pkt_ucast(),
    .stat_rx_pkt_mcast(),
    .stat_rx_pkt_bcast(),
    .stat_rx_pkt_vlan(),
    .stat_rx_pkt_good(),
    .stat_rx_pkt_bad(),
    .stat_rx_err_oversize(),
    .stat_rx_err_bad_fcs(rx_error_bad_fcs_int),
    .stat_rx_err_bad_block(),
    .stat_rx_err_framing(),
    .stat_rx_err_preamble(),
    .stat_rx_fifo_drop(stat_rx_fifo_drop),
    .stat_tx_mcf(),
    .stat_rx_mcf(),
    .stat_tx_lfc_pkt(),
    .stat_tx_lfc_xon(),
    .stat_tx_lfc_xoff(),
    .stat_tx_lfc_paused(),
    .stat_tx_pfc_pkt(),
    .stat_tx_pfc_xon(),
    .stat_tx_pfc_xoff(),
    .stat_tx_pfc_paused(),
    .stat_rx_lfc_pkt(),
    .stat_rx_lfc_xon(),
    .stat_rx_lfc_xoff(),
    .stat_rx_lfc_paused(),
    .stat_rx_pfc_pkt(),
    .stat_rx_pfc_xon(),
    .stat_rx_pfc_xoff(),
    .stat_rx_pfc_paused(),

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
    .cfg_mcf_rx_eth_dst_mcast('0),
    .cfg_mcf_rx_check_eth_dst_mcast('0),
    .cfg_mcf_rx_eth_dst_ucast('0),
    .cfg_mcf_rx_check_eth_dst_ucast('0),
    .cfg_mcf_rx_eth_src('0),
    .cfg_mcf_rx_check_eth_src('0),
    .cfg_mcf_rx_eth_type('0),
    .cfg_mcf_rx_opcode_lfc('0),
    .cfg_mcf_rx_check_opcode_lfc('0),
    .cfg_mcf_rx_opcode_pfc('0),
    .cfg_mcf_rx_check_opcode_pfc('0),
    .cfg_mcf_rx_forward('0),
    .cfg_mcf_rx_enable('0),
    .cfg_tx_lfc_eth_dst('0),
    .cfg_tx_lfc_eth_src('0),
    .cfg_tx_lfc_eth_type('0),
    .cfg_tx_lfc_opcode('0),
    .cfg_tx_lfc_en('0),
    .cfg_tx_lfc_quanta('0),
    .cfg_tx_lfc_refresh('0),
    .cfg_tx_pfc_eth_dst('0),
    .cfg_tx_pfc_eth_src('0),
    .cfg_tx_pfc_eth_type('0),
    .cfg_tx_pfc_opcode('0),
    .cfg_tx_pfc_en('0),
    .cfg_tx_pfc_quanta('{8{'0}}),
    .cfg_tx_pfc_refresh('{8{'0}}),
    .cfg_rx_lfc_opcode('0),
    .cfg_rx_lfc_en('0),
    .cfg_rx_pfc_opcode('0),
    .cfg_rx_pfc_en('0)
);

taxi_axis_async_fifo_adapter #(
    .DEPTH(TX_FIFO_DEPTH),
    .RAM_PIPELINE(TX_FIFO_RAM_PIPELINE),
    .FRAME_FIFO(TX_FRAME_FIFO),
    .USER_BAD_FRAME_VALUE(1'b1),
    .USER_BAD_FRAME_MASK(1'b1),
    .DROP_OVERSIZE_FRAME(TX_DROP_OVERSIZE_FRAME),
    .DROP_BAD_FRAME(TX_DROP_BAD_FRAME),
    .DROP_WHEN_FULL(TX_DROP_WHEN_FULL)
)
tx_fifo (
    /*
     * AXI4-Stream input (sink)
     */
    .s_clk(logic_clk),
    .s_rst(logic_rst),
    .s_axis(s_axis_tx),

    /*
     * AXI4-Stream output (source)
     */
    .m_clk(tx_clk),
    .m_rst(tx_rst),
    .m_axis(axis_tx_int),

    /*
     * Pause
     */
    .s_pause_req(1'b0),
    .s_pause_ack(),
    .m_pause_req(1'b0),
    .m_pause_ack(),

    /*
     * Status
     */
    .s_status_depth(),
    .s_status_depth_commit(),
    .s_status_overflow(tx_fifo_overflow),
    .s_status_bad_frame(tx_fifo_bad_frame),
    .s_status_good_frame(tx_fifo_good_frame),
    .m_status_depth(),
    .m_status_depth_commit(),
    .m_status_overflow(),
    .m_status_bad_frame(),
    .m_status_good_frame()
);

taxi_axis_async_fifo #(
    .DEPTH(TX_CPL_FIFO_DEPTH),
    .FRAME_FIFO(1'b0)
)
tx_cpl_fifo (
    /*
     * AXI4-Stream input (sink)
     */
    .s_clk(tx_clk),
    .s_rst(tx_rst),
    .s_axis(axis_tx_cpl_int),

    /*
     * AXI4-Stream output (source)
     */
    .m_clk(logic_clk),
    .m_rst(logic_rst),
    .m_axis(m_axis_tx_cpl),

    /*
     * Pause
     */
    .s_pause_req(1'b0),
    .s_pause_ack(),
    .m_pause_req(1'b0),
    .m_pause_ack(),

    /*
     * Status
     */
    .s_status_depth(),
    .s_status_depth_commit(),
    .s_status_overflow(),
    .s_status_bad_frame(),
    .s_status_good_frame(),
    .m_status_depth(),
    .m_status_depth_commit(),
    .m_status_overflow(),
    .m_status_bad_frame(),
    .m_status_good_frame()
);

taxi_axis_async_fifo_adapter #(
    .DEPTH(RX_FIFO_DEPTH),
    .RAM_PIPELINE(RX_FIFO_RAM_PIPELINE),
    .FRAME_FIFO(RX_FRAME_FIFO),
    .USER_BAD_FRAME_VALUE(1'b1),
    .USER_BAD_FRAME_MASK(1'b1),
    .DROP_OVERSIZE_FRAME(RX_DROP_OVERSIZE_FRAME),
    .DROP_BAD_FRAME(RX_DROP_BAD_FRAME),
    .DROP_WHEN_FULL(RX_DROP_WHEN_FULL)
)
rx_fifo (
    /*
     * AXI4-Stream input (sink)
     */
    .s_clk(rx_clk),
    .s_rst(rx_rst),
    .s_axis(axis_rx_int),

    /*
     * AXI4-Stream output (source)
     */
    .m_clk(logic_clk),
    .m_rst(logic_rst),
    .m_axis(m_axis_rx),

    /*
     * Pause
     */
    .s_pause_req(1'b0),
    .s_pause_ack(),
    .m_pause_req(1'b0),
    .m_pause_ack(),

    /*
     * Status
     */
    .s_status_depth(),
    .s_status_depth_commit(),
    .s_status_overflow(stat_rx_fifo_drop),
    .s_status_bad_frame(),
    .s_status_good_frame(),
    .m_status_depth(),
    .m_status_depth_commit(),
    .m_status_overflow(rx_fifo_overflow),
    .m_status_bad_frame(rx_fifo_bad_frame),
    .m_status_good_frame(rx_fifo_good_frame)
);

endmodule

`resetall
