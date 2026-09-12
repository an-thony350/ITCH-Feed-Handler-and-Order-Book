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
 * AXI4 Central DMA testbench
 */
module test_taxi_axi_cdma #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter AXI_DATA_W = 32,
    parameter AXI_ADDR_W = 16,
    parameter AXI_STRB_W = AXI_DATA_W / 8,
    parameter AXI_ID_W = 8,
    parameter AXI_MAX_BURST_LEN = 16,
    parameter LEN_W = 20,
    parameter TAG_W = 8,
    parameter logic UNALIGNED_EN = 1'b1
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_dma_desc_if #(
    .SRC_ADDR_W(AXI_ADDR_W),
    .SRC_SEL_EN(1'b0),
    .SRC_ASID_EN(1'b0),
    .DST_ADDR_W(AXI_ADDR_W),
    .DST_SEL_EN(1'b0),
    .DST_ASID_EN(1'b0),
    .IMM_EN(1'b0),
    .LEN_W(LEN_W),
    .TAG_W(TAG_W),
    .ID_EN(1'b0),
    .DEST_EN(1'b0),
    .USER_EN(1'b0)
) dma_desc();

taxi_axi_if #(
    .DATA_W(AXI_DATA_W),
    .ADDR_W(AXI_ADDR_W),
    .STRB_W(AXI_STRB_W),
    .ID_W(AXI_ID_W),
    .AWUSER_EN(1'b0),
    .WUSER_EN(1'b0),
    .BUSER_EN(1'b0),
    .ARUSER_EN(1'b0),
    .RUSER_EN(1'b0),
    .MAX_BURST_LEN(AXI_MAX_BURST_LEN)
) m_axi();

logic enable;

taxi_axi_cdma #(
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .UNALIGNED_EN(UNALIGNED_EN)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * DMA descriptor
     */
    .desc_req(dma_desc),
    .desc_sts(dma_desc),

    /*
     * AXI4 master interface
     */
    .m_axi_wr(m_axi),
    .m_axi_rd(m_axi),

    /*
     * Configuration
     */
    .enable(enable)
);

endmodule

`resetall
