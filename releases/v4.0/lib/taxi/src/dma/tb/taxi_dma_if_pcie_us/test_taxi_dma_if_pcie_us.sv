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
 * UltraScale PCIe DMA interface testbench
 */
module test_taxi_dma_if_pcie_us #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter AXIS_PCIE_DATA_W = 64,
    parameter AXIS_PCIE_KEEP_W = AXIS_PCIE_DATA_W / 32,
    parameter AXIS_PCIE_RQ_USER_W = AXIS_PCIE_DATA_W < 512 ? 62 : 137,
    parameter AXIS_PCIE_RC_USER_W = AXIS_PCIE_DATA_W < 512 ? 75 : 161,
    parameter RQ_SEQ_NUM_W = AXIS_PCIE_RQ_USER_W == 60 ? 4 : 6,
    parameter logic RQ_SEQ_NUM_EN = 1'b1,
    parameter RAM_SEL_W = 2,
    parameter RAM_ADDR_W = 16,
    parameter RAM_SEGS = AXIS_PCIE_DATA_W > 256 ? AXIS_PCIE_DATA_W / 128 : 2,
    parameter PCIE_TAG_CNT = AXIS_PCIE_RQ_USER_W == 60 ? 64 : 256,
    parameter logic IMM_EN = 1,
    parameter IMM_W = AXIS_PCIE_DATA_W,
    parameter LEN_W = 20,
    parameter TAG_W = 8,
    parameter RD_OP_TBL_SIZE = PCIE_TAG_CNT,
    parameter RD_TX_LIMIT = 2**(RQ_SEQ_NUM_W-1),
    parameter logic RD_TX_FC_EN = 1'b1,
    parameter RD_CPLH_FC_LIMIT = 512,
    parameter RD_CPLD_FC_LIMIT = RD_CPLH_FC_LIMIT*4,
    parameter WR_OP_TBL_SIZE = 2**(RQ_SEQ_NUM_W-1),
    parameter WR_TX_LIMIT = 2**(RQ_SEQ_NUM_W-1),
    parameter logic WR_TX_FC_EN = 1'b1
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam PCIE_ADDR_W = 64;

localparam RAM_DATA_W = AXIS_PCIE_DATA_W*2;
localparam RAM_SEG_DATA_W = RAM_DATA_W / RAM_SEGS;
localparam RAM_SEG_BE_W = RAM_SEG_DATA_W / 8;
localparam RAM_SEG_ADDR_W = RAM_ADDR_W - $clog2(RAM_SEGS*RAM_SEG_BE_W);

logic clk;
logic rst;

taxi_axis_if #(
    .DATA_W(AXIS_PCIE_DATA_W),
    .KEEP_EN(1'b1),
    .KEEP_W(AXIS_PCIE_KEEP_W),
    .LAST_EN(1'b1),
    .ID_EN(1'b0),
    .DEST_EN(1'b0),
    .USER_EN(1'b1),
    .USER_W(AXIS_PCIE_RQ_USER_W)
) m_axis_rq();

taxi_axis_if #(
    .DATA_W(AXIS_PCIE_DATA_W),
    .KEEP_EN(1'b1),
    .KEEP_W(AXIS_PCIE_KEEP_W),
    .LAST_EN(1'b1),
    .ID_EN(1'b0),
    .DEST_EN(1'b0),
    .USER_EN(1'b1),
    .USER_W(AXIS_PCIE_RC_USER_W)
) s_axis_rc();

logic [RQ_SEQ_NUM_W-1:0] s_axis_rq_seq_num_0;
logic                    s_axis_rq_seq_num_valid_0;
logic [RQ_SEQ_NUM_W-1:0] s_axis_rq_seq_num_1;
logic                    s_axis_rq_seq_num_valid_1;

logic [7:0] pcie_tx_fc_nph_av;
logic [7:0] pcie_tx_fc_ph_av;
logic [11:0] pcie_tx_fc_pd_av;

taxi_dma_desc_if #(
    .SRC_ADDR_W(PCIE_ADDR_W),
    .SRC_SEL_EN(1'b0),
    .SRC_ASID_EN(1'b0),
    .DST_ADDR_W(RAM_ADDR_W),
    .DST_SEL_EN(1'b1),
    .DST_SEL_W(RAM_SEL_W),
    .DST_ASID_EN(1'b0),
    .IMM_EN(1'b0),
    .LEN_W(LEN_W),
    .TAG_W(TAG_W),
    .ID_EN(1'b0),
    .DEST_EN(1'b0),
    .USER_EN(1'b0)
) rd_desc();

taxi_dma_desc_if #(
    .SRC_ADDR_W(RAM_ADDR_W),
    .SRC_SEL_EN(1'b1),
    .SRC_SEL_W(RAM_SEL_W),
    .SRC_ASID_EN(1'b0),
    .DST_ADDR_W(PCIE_ADDR_W),
    .DST_SEL_EN(1'b0),
    .DST_ASID_EN(1'b0),
    .IMM_EN(IMM_EN),
    .IMM_W(IMM_W),
    .LEN_W(LEN_W),
    .TAG_W(TAG_W),
    .ID_EN(1'b0),
    .DEST_EN(1'b0),
    .USER_EN(1'b0)
) wr_desc();

taxi_dma_ram_if #(
    .SEGS(RAM_SEGS),
    .SEG_ADDR_W(RAM_SEG_ADDR_W),
    .SEG_DATA_W(RAM_SEG_DATA_W),
    .SEG_BE_W(RAM_SEG_BE_W)
) dma_ram();

logic        read_enable;
logic        write_enable;
logic        ext_tag_en;
logic        rcb_128b;
logic [15:0] requester_id;
logic        requester_id_en;
logic [2:0]  max_rd_req_size;
logic [2:0]  max_payload_size;

logic stat_rd_busy;
logic stat_wr_busy;
logic stat_err_cor;
logic stat_err_uncor;

logic [$clog2(RD_OP_TBL_SIZE)-1:0]  stat_rd_op_start_tag;
logic                               stat_rd_op_start_valid;
logic [$clog2(RD_OP_TBL_SIZE)-1:0]  stat_rd_op_finish_tag;
logic [3:0]                         stat_rd_op_finish_status;
logic                               stat_rd_op_finish_valid;
logic [$clog2(PCIE_TAG_CNT)-1:0]    stat_rd_req_start_tag;
logic [12:0]                        stat_rd_req_start_len;
logic                               stat_rd_req_start_valid;
logic [$clog2(PCIE_TAG_CNT)-1:0]    stat_rd_req_finish_tag;
logic [3:0]                         stat_rd_req_finish_status;
logic                               stat_rd_req_finish_valid;
logic                               stat_rd_req_timeout;
logic                               stat_rd_op_tbl_full;
logic                               stat_rd_no_tags;
logic                               stat_rd_tx_limit;
logic                               stat_rd_tx_stall;
logic [$clog2(WR_OP_TBL_SIZE)-1:0]  stat_wr_op_start_tag;
logic                               stat_wr_op_start_valid;
logic [$clog2(WR_OP_TBL_SIZE)-1:0]  stat_wr_op_finish_tag;
logic [3:0]                         stat_wr_op_finish_status;
logic                               stat_wr_op_finish_valid;
logic [$clog2(WR_OP_TBL_SIZE)-1:0]  stat_wr_req_start_tag;
logic [12:0]                        stat_wr_req_start_len;
logic                               stat_wr_req_start_valid;
logic [$clog2(WR_OP_TBL_SIZE)-1:0]  stat_wr_req_finish_tag;
logic [3:0]                         stat_wr_req_finish_status;
logic                               stat_wr_req_finish_valid;
logic                               stat_wr_op_tbl_full;
logic                               stat_wr_tx_limit;
logic                               stat_wr_tx_stall;

taxi_dma_if_pcie_us #(
    .RQ_SEQ_NUM_W(RQ_SEQ_NUM_W),
    .RQ_SEQ_NUM_EN(RQ_SEQ_NUM_EN),
    .PCIE_TAG_CNT(PCIE_TAG_CNT),
    .RD_OP_TBL_SIZE(RD_OP_TBL_SIZE),
    .RD_TX_LIMIT(RD_TX_LIMIT),
    .RD_TX_FC_EN(RD_TX_FC_EN),
    .RD_CPLH_FC_LIMIT(RD_CPLH_FC_LIMIT),
    .RD_CPLD_FC_LIMIT(RD_CPLD_FC_LIMIT),
    .WR_OP_TBL_SIZE(WR_OP_TBL_SIZE),
    .WR_TX_LIMIT(WR_TX_LIMIT),
    .WR_TX_FC_EN(WR_TX_FC_EN)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * UltraScale PCIe interface
     */
    .m_axis_rq(m_axis_rq),
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
    .pcie_tx_fc_ph_av(pcie_tx_fc_ph_av),
    .pcie_tx_fc_pd_av(pcie_tx_fc_pd_av),

    /*
     * Read descriptor
     */
    .rd_desc_req(rd_desc),
    .rd_desc_sts(rd_desc),

    /*
     * Write descriptor
     */
    .wr_desc_req(wr_desc),
    .wr_desc_sts(wr_desc),

    /*
     * RAM interface
     */
    .dma_ram_wr(dma_ram),
    .dma_ram_rd(dma_ram),

    /*
     * Configuration
     */
    .read_enable(read_enable),
    .write_enable(write_enable),
    .ext_tag_en(ext_tag_en),
    .rcb_128b(rcb_128b),
    .requester_id(requester_id),
    .requester_id_en(requester_id_en),
    .max_rd_req_size(max_rd_req_size),
    .max_payload_size(max_payload_size),

    /*
     * Status
     */
    .stat_rd_busy(stat_rd_busy),
    .stat_wr_busy(stat_wr_busy),
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
    .stat_rd_tx_stall(stat_rd_tx_stall),
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
