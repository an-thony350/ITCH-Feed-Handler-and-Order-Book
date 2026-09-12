// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2021-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI DMA interface
 */
module taxi_dma_if_axi #
(
    // Maximum AXI burst length to generate
    parameter AXI_MAX_BURST_LEN = 256,
    // Operation table size (read)
    parameter RD_OP_TBL_SIZE = 32,
    // Operation table size (write)
    parameter WR_OP_TBL_SIZE = 32,
    // Use AXI ID signals (read)
    parameter RD_USE_AXI_ID = 0,
    // Use AXI ID signals (write)
    parameter WR_USE_AXI_ID = 1
)
(
    input  wire logic                               clk,
    input  wire logic                               rst,

    /*
     * AXI master interface
     */
    taxi_axi_if.wr_mst                              m_axi_wr,
    taxi_axi_if.rd_mst                              m_axi_rd,

    /*
     * Read descriptor
     */
    taxi_dma_desc_if.req_snk                        rd_desc_req,
    taxi_dma_desc_if.sts_src                        rd_desc_sts,

    /*
     * Write descriptor
     */
    taxi_dma_desc_if.req_snk                        wr_desc_req,
    taxi_dma_desc_if.sts_src                        wr_desc_sts,

    /*
     * RAM interface
     */
    taxi_dma_ram_if.wr_mst                          dma_ram_wr,
    taxi_dma_ram_if.rd_mst                          dma_ram_rd,

    /*
     * Configuration
     */
    input  wire logic                               read_enable,
    input  wire logic                               write_enable,

    /*
     * Status
     */
    output wire logic                               status_rd_busy,
    output wire logic                               status_wr_busy,

    /*
     * Statistics
     */
    output wire logic [$clog2(RD_OP_TBL_SIZE)-1:0]  stat_rd_op_start_tag,
    output wire logic                               stat_rd_op_start_valid,
    output wire logic [$clog2(RD_OP_TBL_SIZE)-1:0]  stat_rd_op_finish_tag,
    output wire logic [3:0]                         stat_rd_op_finish_status,
    output wire logic                               stat_rd_op_finish_valid,
    output wire logic [$clog2(RD_OP_TBL_SIZE)-1:0]  stat_rd_req_start_tag,
    output wire logic [12:0]                        stat_rd_req_start_len,
    output wire logic                               stat_rd_req_start_valid,
    output wire logic [$clog2(RD_OP_TBL_SIZE)-1:0]  stat_rd_req_finish_tag,
    output wire logic [3:0]                         stat_rd_req_finish_status,
    output wire logic                               stat_rd_req_finish_valid,
    output wire logic                               stat_rd_op_tbl_full,
    output wire logic                               stat_rd_tx_stall,
    output wire logic [$clog2(WR_OP_TBL_SIZE)-1:0]  stat_wr_op_start_tag,
    output wire logic                               stat_wr_op_start_valid,
    output wire logic [$clog2(WR_OP_TBL_SIZE)-1:0]  stat_wr_op_finish_tag,
    output wire logic [3:0]                         stat_wr_op_finish_status,
    output wire logic                               stat_wr_op_finish_valid,
    output wire logic [$clog2(WR_OP_TBL_SIZE)-1:0]  stat_wr_req_start_tag,
    output wire logic [12:0]                        stat_wr_req_start_len,
    output wire logic                               stat_wr_req_start_valid,
    output wire logic [$clog2(WR_OP_TBL_SIZE)-1:0]  stat_wr_req_finish_tag,
    output wire logic [3:0]                         stat_wr_req_finish_status,
    output wire logic                               stat_wr_req_finish_valid,
    output wire logic                               stat_wr_op_tbl_full,
    output wire logic                               stat_wr_tx_stall
);

taxi_dma_if_axi_rd #(
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .OP_TBL_SIZE(RD_OP_TBL_SIZE),
    .USE_AXI_ID(RD_USE_AXI_ID)
)
dma_rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI master interface
     */
    .m_axi_rd(m_axi_rd),

    /*
     * Read descriptor
     */
    .rd_desc_req(rd_desc_req),
    .rd_desc_sts(rd_desc_sts),

    /*
     * RAM interface
     */
    .dma_ram_wr(dma_ram_wr),

    /*
     * Configuration
     */
    .enable(read_enable),

    /*
     * Status
     */
    .status_busy(status_rd_busy),

    /*
     * Statistics
     */
    .stat_rd_op_start_tag(stat_rd_op_start_tag),
    .stat_rd_op_start_valid(stat_rd_op_start_valid),
    .stat_rd_op_finish_tag(stat_rd_op_finish_tag),
    .stat_rd_op_finish_status(stat_rd_op_finish_status),
    .stat_rd_op_finish_valid(stat_rd_op_finish_valid),
    .stat_rd_req_start_tag(stat_rd_req_start_tag),
    .stat_rd_req_start_len(stat_rd_req_start_len),
    .stat_rd_req_start_valid(stat_rd_req_start_valid),
    .stat_rd_req_finish_tag(stat_rd_req_finish_tag),
    .stat_rd_req_finish_status(stat_rd_req_finish_status),
    .stat_rd_req_finish_valid(stat_rd_req_finish_valid),
    .stat_rd_op_tbl_full(stat_rd_op_tbl_full),
    .stat_rd_tx_stall(stat_rd_tx_stall)
);

taxi_dma_if_axi_wr #(
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .OP_TBL_SIZE(WR_OP_TBL_SIZE),
    .USE_AXI_ID(WR_USE_AXI_ID)
)
dma_wr_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI master interface
     */
    .m_axi_wr(m_axi_wr),

    /*
     * Write descriptor
     */
    .wr_desc_req(wr_desc_req),
    .wr_desc_sts(wr_desc_sts),

    /*
     * RAM interface
     */
    .dma_ram_rd(dma_ram_rd),

    /*
     * Configuration
     */
    .enable(write_enable),

    /*
     * Status
     */
    .status_busy(status_wr_busy),

    /*
     * Statistics
     */
    .stat_wr_op_start_tag(stat_wr_op_start_tag),
    .stat_wr_op_start_valid(stat_wr_op_start_valid),
    .stat_wr_op_finish_tag(stat_wr_op_finish_tag),
    .stat_wr_op_finish_status(stat_wr_op_finish_status),
    .stat_wr_op_finish_valid(stat_wr_op_finish_valid),
    .stat_wr_req_start_tag(stat_wr_req_start_tag),
    .stat_wr_req_start_len(stat_wr_req_start_len),
    .stat_wr_req_start_valid(stat_wr_req_start_valid),
    .stat_wr_req_finish_tag(stat_wr_req_finish_tag),
    .stat_wr_req_finish_status(stat_wr_req_finish_status),
    .stat_wr_req_finish_valid(stat_wr_req_finish_valid),
    .stat_wr_op_tbl_full(stat_wr_op_tbl_full),
    .stat_wr_tx_stall(stat_wr_tx_stall)
);

endmodule

`resetall
