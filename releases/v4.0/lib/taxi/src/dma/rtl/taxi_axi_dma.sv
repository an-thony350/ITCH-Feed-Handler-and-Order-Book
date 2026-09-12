// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2018-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4 DMA
 */
module taxi_axi_dma #
(
    // Maximum AXI burst length to generate
    parameter AXI_MAX_BURST_LEN = 16,
    // Enable support for unaligned transfers
    parameter logic UNALIGNED_EN = 1'b1
)
(
    input  wire logic         clk,
    input  wire logic         rst,

    /*
     * DMA read descriptor
     */
    taxi_dma_desc_if.req_snk  rd_desc_req,
    taxi_dma_desc_if.sts_src  rd_desc_sts,

    /*
     * DMA write descriptor
     */
    taxi_dma_desc_if.req_snk  wr_desc_req,
    taxi_dma_desc_if.sts_src  wr_desc_sts,

    /*
     * AXI stream read data output
     */
    taxi_axis_if.src          m_axis_rd_data,

    /*
     * AXI stream write data input
     */
    taxi_axis_if.snk          s_axis_wr_data,

    /*
     * AXI4 master interface
     */
    taxi_axi_if.wr_mst        m_axi_wr,
    taxi_axi_if.rd_mst        m_axi_rd,

    /*
     * Configuration
     */
    input  wire logic         read_enable,
    input  wire logic         write_enable,
    input  wire logic         write_abort
);

taxi_axi_dma_rd #(
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .UNALIGNED_EN(UNALIGNED_EN)
)
axi_dma_rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * DMA read descriptor
     */
    .rd_desc_req(rd_desc_req),
    .rd_desc_sts(rd_desc_sts),

    /*
     * AXI stream read data output
     */
    .m_axis_rd_data(m_axis_rd_data),

    /*
     * AXI4 master interface
     */
    .m_axi_rd(m_axi_rd),

    /*
     * Configuration
     */
    .enable(read_enable)
);

taxi_axi_dma_wr #(
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .UNALIGNED_EN(UNALIGNED_EN)
)
axi_dma_wr_inst (
    .clk(clk),
    .rst(rst),

    /*
        * DMA write descriptor
        */
    .wr_desc_req(wr_desc_req),
    .wr_desc_sts(wr_desc_sts),

    /*
     * AXI stream write data input
     */
    .s_axis_wr_data(s_axis_wr_data),

    /*
     * AXI4 master interface
     */
    .m_axi_wr(m_axi_wr),

    /*
     * Configuration
     */
    .enable(write_enable),
    .abort(write_abort)
);

endmodule

`resetall
