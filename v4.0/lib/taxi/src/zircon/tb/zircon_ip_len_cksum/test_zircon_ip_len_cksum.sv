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
module test_zircon_ip_len_cksum #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 32,
    parameter META_W = 32,
    parameter START_OFFSET = 14
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(1)) s_axis_pkt();
taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(1)) m_axis_pkt();
taxi_axis_if #(.DATA_W(META_W), .USER_EN(1), .USER_W(1)) m_axis_meta();

zircon_ip_len_cksum #(
    .START_OFFSET(START_OFFSET)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * Packet header input
     */
    .s_axis_pkt(s_axis_pkt),
    .m_axis_pkt(m_axis_pkt),

    /*
     * Packet metadata output
     */
    .m_axis_meta(m_axis_meta)
);

endmodule

`resetall
