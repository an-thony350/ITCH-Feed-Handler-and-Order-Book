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
 * DMA parallel simple dual port RAM testbench
 */
module test_taxi_dma_psdpram #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter SIZE = 4096,
    parameter SEGS = 2,
    parameter SEG_DATA_W = 128,
    parameter SEG_BE_W = SEG_DATA_W/8,
    parameter SEG_ADDR_W = $clog2(SIZE/(SEGS*SEG_BE_W)),
    parameter PIPELINE = 2
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_dma_ram_if #(
    .SEGS(SEGS),
    .SEG_ADDR_W(SEG_ADDR_W),
    .SEG_DATA_W(SEG_DATA_W),
    .SEG_BE_W(SEG_BE_W)
) dma_ram();

taxi_dma_psdpram #(
    .SIZE(SIZE),
    .PIPELINE(PIPELINE)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * Write port
     */
    .dma_ram_wr(dma_ram),

    /*
     * Read port
     */
    .dma_ram_rd(dma_ram)
);

endmodule

`resetall
