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
 * AXI stream sink DMA client testbench
 */
module test_taxi_dma_client_axis_sink #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter RAM_DATA_W = 128,
    parameter RAM_ADDR_W = 16,
    parameter RAM_SEGS = RAM_DATA_W > 256 ? RAM_DATA_W / 128 : 2,
    parameter AXIS_DATA_W = 64,
    parameter logic AXIS_KEEP_EN = AXIS_DATA_W > 8,
    parameter AXIS_KEEP_W = AXIS_DATA_W / 8,
    parameter logic AXIS_LAST_EN = 1'b1,
    parameter logic AXIS_ID_EN = 1'b1,
    parameter AXIS_ID_W = 8,
    parameter logic AXIS_DEST_EN = 1'b1,
    parameter AXIS_DEST_W = 8,
    parameter logic AXIS_USER_EN = 1'b1,
    parameter AXIS_USER_W = 8,
    parameter LEN_W = 20,
    parameter TAG_W = 8
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam RAM_SEG_DATA_W = RAM_DATA_W / RAM_SEGS;
localparam RAM_SEG_BE_W = RAM_SEG_DATA_W / 8;
localparam RAM_SEG_ADDR_W = RAM_ADDR_W - $clog2(RAM_SEGS*RAM_SEG_BE_W);

logic clk;
logic rst;

taxi_dma_desc_if #(
    .SRC_ADDR_W(RAM_ADDR_W),
    .SRC_SEL_EN(1'b0),
    .SRC_ASID_EN(1'b0),
    .DST_ADDR_W(RAM_ADDR_W),
    .DST_SEL_EN(1'b0),
    .DST_ASID_EN(1'b0),
    .IMM_EN(1'b0),
    .LEN_W(LEN_W),
    .TAG_W(TAG_W),
    .ID_EN(AXIS_ID_EN),
    .ID_W(AXIS_ID_W),
    .DEST_EN(AXIS_DEST_EN),
    .DEST_W(AXIS_DEST_W),
    .USER_EN(AXIS_USER_EN),
    .USER_W(AXIS_USER_W)
) dma_desc();

taxi_dma_ram_if #(
    .SEGS(RAM_SEGS),
    .SEG_ADDR_W(RAM_SEG_ADDR_W),
    .SEG_DATA_W(RAM_SEG_DATA_W),
    .SEG_BE_W(RAM_SEG_BE_W)
) dma_ram();

taxi_axis_if #(
    .DATA_W(AXIS_DATA_W),
    .KEEP_EN(AXIS_KEEP_EN),
    .KEEP_W(AXIS_KEEP_W),
    .LAST_EN(AXIS_LAST_EN),
    .ID_EN(AXIS_ID_EN),
    .ID_W(AXIS_ID_W),
    .DEST_EN(AXIS_DEST_EN),
    .DEST_W(AXIS_DEST_W),
    .USER_EN(AXIS_USER_EN),
    .USER_W(AXIS_USER_W)
) s_axis_wr_data();

logic enable;
logic abort;

taxi_dma_client_axis_sink
uut (
    .clk(clk),
    .rst(rst),

    /*
     * DMA descriptor
     */
    .desc_req(dma_desc),
    .desc_sts(dma_desc),

    /*
     * AXI stream write data input
     */
    .s_axis_wr_data(s_axis_wr_data),

    /*
     * RAM interface
     */
    .dma_ram_wr(dma_ram),

    /*
     * Configuration
     */
    .enable(enable),
    .abort(abort)
);

endmodule

`resetall
