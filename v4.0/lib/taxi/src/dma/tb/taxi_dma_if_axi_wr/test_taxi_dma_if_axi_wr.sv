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
 * AXI DMA interface testbench
 */
module test_taxi_dma_if_axi_wr #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter AXI_DATA_W = 64,
    parameter AXI_ADDR_W = 16,
    parameter AXI_STRB_W = AXI_DATA_W / 8,
    parameter AXI_ID_W = 8,
    parameter AXI_MAX_BURST_LEN = 256,
    parameter RAM_SEL_W = 2,
    parameter RAM_ADDR_W = 16,
    parameter RAM_SEGS = 2,
    parameter logic IMM_EN = 1,
    parameter IMM_W = AXI_DATA_W,
    parameter LEN_W = 16,
    parameter TAG_W = 8,
    parameter OP_TBL_SIZE = 2**AXI_ID_W,
    parameter logic USE_AXI_ID = 1'b1
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam RAM_DATA_W = AXI_DATA_W*2;
localparam RAM_SEG_DATA_W = RAM_DATA_W / RAM_SEGS;
localparam RAM_SEG_BE_W = RAM_SEG_DATA_W / 8;
localparam RAM_SEG_ADDR_W = RAM_ADDR_W - $clog2(RAM_SEGS*RAM_SEG_BE_W);

logic clk;
logic rst;

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

taxi_dma_desc_if #(
    .SRC_ADDR_W(RAM_ADDR_W),
    .SRC_SEL_EN(1'b1),
    .SRC_SEL_W(RAM_SEL_W),
    .SRC_ASID_EN(1'b0),
    .DST_ADDR_W(AXI_ADDR_W),
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

logic enable;

logic status_busy;

logic [$clog2(OP_TBL_SIZE)-1:0]  stat_wr_op_start_tag;
logic                            stat_wr_op_start_valid;
logic [$clog2(OP_TBL_SIZE)-1:0]  stat_wr_op_finish_tag;
logic [3:0]                      stat_wr_op_finish_status;
logic                            stat_wr_op_finish_valid;
logic [$clog2(OP_TBL_SIZE)-1:0]  stat_wr_req_start_tag;
logic [12:0]                     stat_wr_req_start_len;
logic                            stat_wr_req_start_valid;
logic [$clog2(OP_TBL_SIZE)-1:0]  stat_wr_req_finish_tag;
logic [3:0]                      stat_wr_req_finish_status;
logic                            stat_wr_req_finish_valid;
logic                            stat_wr_op_tbl_full;
logic                            stat_wr_tx_stall;

taxi_dma_if_axi_wr #(
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .OP_TBL_SIZE(OP_TBL_SIZE),
    .USE_AXI_ID(USE_AXI_ID)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI master interface
     */
    .m_axi_wr(m_axi),

    /*
     * Write descriptor
     */
    .wr_desc_req(wr_desc),
    .wr_desc_sts(wr_desc),

    /*
     * RAM interface
     */
    .dma_ram_rd(dma_ram),

    /*
     * Configuration
     */
    .enable(enable),

    /*
     * Status
     */
    .status_busy(status_busy),

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
