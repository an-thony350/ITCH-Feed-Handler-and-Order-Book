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
 * AXI4 lite dual-port RAM testbench
 */
module test_taxi_axil_dp_ram #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 32,
    parameter ADDR_W = 16,
    parameter STRB_W = (DATA_W/8),
    parameter PIPELINE_OUTPUT = 0
    /* verilator lint_on WIDTHTRUNC */
)
();

logic a_clk;
logic a_rst;
logic b_clk;
logic b_rst;

taxi_axil_if #(
    .DATA_W(DATA_W),
    .ADDR_W(ADDR_W+16),
    .STRB_W(STRB_W)
) s_axil_a(), s_axil_b();

taxi_axil_dp_ram #(
    .ADDR_W(ADDR_W),
    .PIPELINE_OUTPUT(PIPELINE_OUTPUT)
)
uut (
    /*
     * Port A
     */
    .a_clk(a_clk),
    .a_rst(a_rst),
    .s_axil_wr_a(s_axil_a),
    .s_axil_rd_a(s_axil_a),

    /*
     * Port B
     */
    .b_clk(b_clk),
    .b_rst(b_rst),
    .s_axil_wr_b(s_axil_b),
    .s_axil_rd_b(s_axil_b)
);

endmodule

`resetall
