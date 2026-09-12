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
 * Zircon IP stack - RX ingress module
 */
module zircon_ip_rx_ingress #
(
    parameter logic IPV6_EN = 1'b1,
    parameter logic HASH_EN = 1'b1,
    parameter MAC_RX_FIFO_DEPTH = 32,
    parameter logic MAC_RX_FIFO_EB_MODE = 1'b1
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * MAC interfaces
     */
    input  wire logic  mac_rx_clk,
    input  wire logic  mac_rx_rst,
    taxi_axis_if.snk   s_axis_mac_rx,

    /*
     * Internal interfaces
     */
    taxi_axis_if.src   m_axis_pkt,
    taxi_axis_if.src   m_axis_meta_hdr,
    taxi_axis_if.src   m_axis_meta_len
);

localparam MAC_DATA_W = s_axis_mac_rx.DATA_W;
localparam RX_USER_W = s_axis_mac_rx.USER_W;
localparam DATA_W = m_axis_pkt.DATA_W;
localparam META_DATA_W = m_axis_meta_hdr.DATA_W;

taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(RX_USER_W)) mac_rx_int();
taxi_axis_if #(.DATA_W(32), .USER_EN(1), .USER_W(RX_USER_W)) rx_pkt_hdr();
taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(RX_USER_W)) rx_bcast_int[2]();

taxi_axis_async_fifo_adapter #(
    .DEPTH(MAC_RX_FIFO_EB_MODE ? (MAC_DATA_W > DATA_W ? MAC_DATA_W : DATA_W)/8*MAC_RX_FIFO_DEPTH : MAC_RX_FIFO_DEPTH),
    .RAM_PIPELINE(1),
    .OUTPUT_FIFO_EN(1'b0),
    .FRAME_FIFO(!MAC_RX_FIFO_EB_MODE),
    .USER_BAD_FRAME_VALUE(1'b1),
    .USER_BAD_FRAME_MASK(1'b1),
    .DROP_OVERSIZE_FRAME(!MAC_RX_FIFO_EB_MODE),
    .DROP_BAD_FRAME(!MAC_RX_FIFO_EB_MODE),
    .DROP_WHEN_FULL(!MAC_RX_FIFO_EB_MODE),
    .MARK_WHEN_FULL(MAC_RX_FIFO_EB_MODE),
    .PAUSE_EN(1'b0)
)
rx_fifo_inst (
    /*
     * AXI4-Stream input (sink)
     */
    .s_clk(mac_rx_clk),
    .s_rst(mac_rx_rst),
    .s_axis(s_axis_mac_rx),

    /*
     * AXI4-Stream output (source)
     */
    .m_clk(clk),
    .m_rst(rst),
    .m_axis(mac_rx_int),

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

taxi_axis_broadcast #(
    .M_COUNT($size(rx_bcast_int))
)
rx_broadcast_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(mac_rx_int),

    /*
     * AXI4-Stream outputs (sources)
     */
    .m_axis(rx_bcast_int)
);

zircon_ip_len_cksum #(
    .START_OFFSET(14)
)
rx_len_cksum_inst (
    .clk(clk),
    .rst(rst),

    /*
     * Packet passthrough
     */
    .s_axis_pkt(rx_bcast_int[0]),
    .m_axis_pkt(m_axis_pkt),

    /*
     * Packet metadata output
     */
    .m_axis_meta(m_axis_meta_len)
);

taxi_axis_adapter
hdr_adapter_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(rx_bcast_int[1]),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(rx_pkt_hdr)
);

zircon_ip_rx_parse #(
    .IPV6_EN(IPV6_EN),
    .HASH_EN(HASH_EN)
)
rx_parse_inst (
    .clk(clk),
    .rst(rst),

    /*
     * Packet header input
     */
    .s_axis_pkt(rx_pkt_hdr),

    /*
     * Packet metadata output
     */
    .m_axis_meta(m_axis_meta_hdr)
);

endmodule

`resetall
