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
 * DMA parallel simple dual port RAM (asynchronous) testbench
 */
module test_taxi_dma_psdpram_async #
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

logic clk_wr;
logic rst_wr;

logic clk_rd;
logic rst_rd;

taxi_dma_ram_if #(
    .SEGS(SEGS),
    .SEG_ADDR_W(SEG_ADDR_W),
    .SEG_DATA_W(SEG_DATA_W),
    .SEG_BE_W(SEG_BE_W)
) dma_ram();

taxi_dma_psdpram_async #(
    .SIZE(SIZE),
    .PIPELINE(PIPELINE)
)
uut (
    /*
     * Write port
     */
    .clk_wr(clk_wr),
    .rst_wr(rst_wr),
    .dma_ram_wr(dma_ram),

    /*
     * Read port
     */
    .clk_rd(clk_rd),
    .rst_rd(rst_rd),
    .dma_ram_rd(dma_ram)
);

endmodule

`resetall
