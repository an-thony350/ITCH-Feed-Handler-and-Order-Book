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
 * AXI4 DMA testbench
 */
module test_taxi_axi_dma #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter AXI_DATA_W = 32,
    parameter AXI_ADDR_W = 16,
    parameter AXI_STRB_W = AXI_DATA_W / 8,
    parameter AXI_ID_W = 8,
    parameter AXI_MAX_BURST_LEN = 16,
    parameter AXIS_DATA_W = AXI_DATA_W,
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
    .ID_EN(AXIS_ID_EN),
    .ID_W(AXIS_ID_W),
    .DEST_EN(AXIS_DEST_EN),
    .DEST_W(AXIS_DEST_W),
    .USER_EN(AXIS_USER_EN),
    .USER_W(AXIS_USER_W)
) rd_desc(), wr_desc();

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
) s_axis_wr_data(), m_axis_rd_data();

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

logic read_enable;
logic write_enable;
logic write_abort;

taxi_axi_dma #(
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .UNALIGNED_EN(UNALIGNED_EN)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * DMA read descriptor
     */
    .rd_desc_req(rd_desc),
    .rd_desc_sts(rd_desc),

    /*
     * DMA write descriptor
     */
    .wr_desc_req(wr_desc),
    .wr_desc_sts(wr_desc),

    /*
     * AXI stream read data output
     */
    .m_axis_rd_data(m_axis_rd_data),

    /*
     * AXI stream write data input
     */
    .s_axis_wr_data(s_axis_wr_data),

    /*
     * AXI4 master interface
     */
    .m_axi_wr(m_axi),
    .m_axi_rd(m_axi),

    /*
     * Configuration
     */
    .read_enable(read_enable),
    .write_enable(write_enable),
    .write_abort(write_abort)
);

endmodule

`resetall
