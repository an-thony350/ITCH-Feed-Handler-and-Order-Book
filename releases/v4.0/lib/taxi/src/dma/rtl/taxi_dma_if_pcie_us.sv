// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2019-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * UltraScale PCIe DMA interface
 */
module taxi_dma_if_pcie_us #
(
    // RQ sequence number width
    parameter RQ_SEQ_NUM_W = 6,
    // RQ sequence number tracking enable
    parameter logic RQ_SEQ_NUM_EN = 1'b0,
    // PCIe tag count
    parameter PCIE_TAG_CNT = 64,
    // Operation table size (read)
    parameter RD_OP_TBL_SIZE = PCIE_TAG_CNT,
    // In-flight transmit limit (read)
    parameter RD_TX_LIMIT = 2**(RQ_SEQ_NUM_W-1),
    // Transmit flow control (read)
    parameter logic RD_TX_FC_EN = 1'b0,
    // Completion header flow control credit limit (read)
    parameter RD_CPLH_FC_LIMIT = 0,
    // Completion data flow control credit limit (read)
    parameter RD_CPLD_FC_LIMIT = RD_CPLH_FC_LIMIT*4,
    // Operation table size (write)
    parameter WR_OP_TBL_SIZE = 2**(RQ_SEQ_NUM_W-1),
    // In-flight transmit limit (write)
    parameter WR_TX_LIMIT = 2**(RQ_SEQ_NUM_W-1),
    // Transmit flow control (write)
    parameter logic WR_TX_FC_EN = 1'b0
)
(
    input  wire logic                               clk,
    input  wire logic                               rst,

    /*
     * UltraScale PCIe interface
     */
    taxi_axis_if.src                                m_axis_rq,
    taxi_axis_if.snk                                s_axis_rc,

    /*
     * Transmit sequence number input
     */
    input  wire logic [RQ_SEQ_NUM_W-1:0]            s_axis_rq_seq_num_0,
    input  wire logic                               s_axis_rq_seq_num_valid_0,
    input  wire logic [RQ_SEQ_NUM_W-1:0]            s_axis_rq_seq_num_1,
    input  wire logic                               s_axis_rq_seq_num_valid_1,

    /*
     * Transmit flow control
     */
    input  wire logic [7:0]                         pcie_tx_fc_nph_av,
    input  wire logic [7:0]                         pcie_tx_fc_ph_av,
    input  wire logic [11:0]                        pcie_tx_fc_pd_av,

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
    input  wire logic                               ext_tag_en,
    input  wire logic                               rcb_128b,
    input  wire logic [15:0]                        requester_id,
    input  wire logic                               requester_id_en,
    input  wire logic [2:0]                         max_rd_req_size,
    input  wire logic [2:0]                         max_payload_size,

    /*
     * Status
     */
    output wire logic                               stat_rd_busy,
    output wire logic                               stat_wr_busy,
    output wire logic                               stat_err_cor,
    output wire logic                               stat_err_uncor,

    /*
     * Statistics
     */
    output wire logic [$clog2(RD_OP_TBL_SIZE)-1:0]  stat_rd_op_start_tag,
    output wire logic                               stat_rd_op_start_valid,
    output wire logic [$clog2(RD_OP_TBL_SIZE)-1:0]  stat_rd_op_finish_tag,
    output wire logic [3:0]                         stat_rd_op_finish_status,
    output wire logic                               stat_rd_op_finish_valid,
    output wire logic [$clog2(PCIE_TAG_CNT)-1:0]    stat_rd_req_start_tag,
    output wire logic [12:0]                        stat_rd_req_start_len,
    output wire logic                               stat_rd_req_start_valid,
    output wire logic [$clog2(PCIE_TAG_CNT)-1:0]    stat_rd_req_finish_tag,
    output wire logic [3:0]                         stat_rd_req_finish_status,
    output wire logic                               stat_rd_req_finish_valid,
    output wire logic                               stat_rd_req_timeout,
    output wire logic                               stat_rd_op_tbl_full,
    output wire logic                               stat_rd_no_tags,
    output wire logic                               stat_rd_tx_limit,
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
    output wire logic                               stat_wr_tx_limit,
    output wire logic                               stat_wr_tx_stall
);

taxi_axis_if #(
    .DATA_W(m_axis_rq.DATA_W),
    .KEEP_EN(1),
    .KEEP_W(m_axis_rq.KEEP_W),
    .USER_EN(1),
    .USER_W(m_axis_rq.USER_W)
) axis_rq_int();

taxi_dma_if_pcie_us_rd #(
    .RQ_SEQ_NUM_W(RQ_SEQ_NUM_W),
    .RQ_SEQ_NUM_EN(RQ_SEQ_NUM_EN),
    .PCIE_TAG_CNT(PCIE_TAG_CNT),
    .OP_TBL_SIZE(RD_OP_TBL_SIZE),
    .TX_LIMIT(RD_TX_LIMIT),
    .TX_FC_EN(RD_TX_FC_EN),
    .CPLH_FC_LIMIT(RD_CPLH_FC_LIMIT),
    .CPLD_FC_LIMIT(RD_CPLD_FC_LIMIT)
)
rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * UltraScale PCIe interface
     */
    .m_axis_rq(axis_rq_int),
    .s_axis_rc(s_axis_rc),

    /*
     * Transmit sequence number input
     */
    .s_axis_rq_seq_num_0(s_axis_rq_seq_num_0),
    .s_axis_rq_seq_num_valid_0(s_axis_rq_seq_num_valid_0),
    .s_axis_rq_seq_num_1(s_axis_rq_seq_num_1),
    .s_axis_rq_seq_num_valid_1(s_axis_rq_seq_num_valid_1),

    /*
     * Transmit flow control
     */
    .pcie_tx_fc_nph_av(pcie_tx_fc_nph_av),

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
    .ext_tag_en(ext_tag_en),
    .rcb_128b(rcb_128b),
    .requester_id(requester_id),
    .requester_id_en(requester_id_en),
    .max_rd_req_size(max_rd_req_size),

    /*
     * Status
     */
    .stat_busy(stat_rd_busy),
    .stat_err_cor(stat_err_cor),
    .stat_err_uncor(stat_err_uncor),

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
    .stat_rd_req_timeout(stat_rd_req_timeout),
    .stat_rd_op_tbl_full(stat_rd_op_tbl_full),
    .stat_rd_no_tags(stat_rd_no_tags),
    .stat_rd_tx_limit(stat_rd_tx_limit),
    .stat_rd_tx_stall(stat_rd_tx_stall)
);

taxi_dma_if_pcie_us_wr #(
    .RQ_SEQ_NUM_W(RQ_SEQ_NUM_W),
    .RQ_SEQ_NUM_EN(RQ_SEQ_NUM_EN),
    .OP_TBL_SIZE(WR_OP_TBL_SIZE),
    .TX_LIMIT(WR_TX_LIMIT),
    .TX_FC_EN(WR_TX_FC_EN)
)
wr_inst (
    .clk(clk),
    .rst(rst),

    /*
     * UltraScale PCIe interface
     */
    .s_axis_rq(axis_rq_int),
    .m_axis_rq(m_axis_rq),

    /*
     * Transmit sequence number input
     */
    .s_axis_rq_seq_num_0(s_axis_rq_seq_num_0),
    .s_axis_rq_seq_num_valid_0(s_axis_rq_seq_num_valid_0),
    .s_axis_rq_seq_num_1(s_axis_rq_seq_num_1),
    .s_axis_rq_seq_num_valid_1(s_axis_rq_seq_num_valid_1),

    /*
     * Transmit flow control
     */
    .pcie_tx_fc_ph_av(pcie_tx_fc_ph_av),
    .pcie_tx_fc_pd_av(pcie_tx_fc_pd_av),

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
    .requester_id(requester_id),
    .requester_id_en(requester_id_en),
    .max_payload_size(max_payload_size),

    /*
     * Status
     */
    .stat_busy(stat_wr_busy),

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
    .stat_wr_tx_limit(stat_wr_tx_limit),
    .stat_wr_tx_stall(stat_wr_tx_stall)
);

endmodule

`resetall
