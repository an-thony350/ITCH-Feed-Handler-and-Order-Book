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
 * MT19937/MT19937-64 Mersenne Twister PRNG testbench
 */
module test_taxi_mt19937 #(
    /* verilator lint_off WIDTHTRUNC */
    /* verilator lint_off WIDTHEXPAND */
    parameter integer MT_W = 32,
    parameter logic [MT_W-1:0] INIT_SEED = 5489
    /* verilator lint_on WIDTHTRUNC */
    /* verilator lint_on WIDTHEXPAND */
)
();

logic clk;
logic rst;

taxi_axis_if #(
    .DATA_W(MT_W),
    .KEEP_W(1)
) m_axis();

wire busy;

logic [MT_W-1:0] seed_val;
logic seed_start;

taxi_mt19937 #(
    .MT_W(MT_W),
    .INIT_SEED(INIT_SEED)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI output (source)
     */
    .m_axis(m_axis),

    /*
        * Status
        */
    .busy(busy),

    /*
        * Configuration
        */
    .seed_val(seed_val),
    .seed_start(seed_start)
);

endmodule

`resetall
