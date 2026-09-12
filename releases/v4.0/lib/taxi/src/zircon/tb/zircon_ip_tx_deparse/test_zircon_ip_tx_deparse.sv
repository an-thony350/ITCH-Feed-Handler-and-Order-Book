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
 * testbench
 */
module test_zircon_ip_tx_deparse #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 32,
    parameter META_W = 64,
    parameter logic IPV6_EN = 1'b1
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(META_W), .USER_EN(1), .USER_W(1)) s_axis_meta();
taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(1)) m_axis_pkt();

zircon_ip_tx_deparse #(
    .IPV6_EN(IPV6_EN)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * Packet metadata input
     */
    .s_axis_meta(s_axis_meta),

    /*
     * Packet header output
     */
    .m_axis_pkt(m_axis_pkt)
);

endmodule

`resetall
