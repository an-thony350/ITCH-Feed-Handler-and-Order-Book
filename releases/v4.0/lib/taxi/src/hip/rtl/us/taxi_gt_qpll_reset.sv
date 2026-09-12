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
 * GT QPLL reset controller for UltraScale/UltraScale+ GTH/GTY
 */
module taxi_gt_qpll_reset #
(
    parameter logic QPLL_PD = 1'b0,
    parameter CNT_W = 8
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * GT
     */
    output wire logic  gt_qpll_reset_out,
    output wire logic  gt_qpll_pd_out,
    input  wire logic  gt_qpll_lock_in,

    /*
     * Control/status
     */
    input  wire logic  qpll_reset_in = 1'b0,
    input  wire logic  qpll_pd_in = QPLL_PD,
    output wire logic  qpll_lock_out
);

logic qpll_reset_reg = 1'b1;
logic qpll_pd_reg = QPLL_PD;

logic [CNT_W-1:0] qpll_reset_cnt_reg = '0;

assign gt_qpll_reset_out = qpll_reset_reg;
assign gt_qpll_pd_out = qpll_pd_reg;

always_ff @(posedge clk) begin
    qpll_pd_reg <= qpll_pd_in;

    if (&qpll_reset_cnt_reg) begin
        qpll_reset_reg <= 1'b0;
    end else begin
        qpll_reset_cnt_reg <= qpll_reset_cnt_reg + 1;
        qpll_reset_reg <= 1'b1;
    end

    if (qpll_reset_in || qpll_pd_reg) begin
        qpll_reset_cnt_reg <= 0;
    end

    if (rst) begin
        qpll_reset_reg <= 1'b1;
        qpll_pd_reg <= QPLL_PD;
        qpll_reset_cnt_reg <= '0;
    end
end

taxi_sync_signal #(
    .WIDTH(1),
    .N(2)
)
qpll_lock_sync_inst (
    .clk(clk),
    .in(gt_qpll_lock_in),
    .out(qpll_lock_out)
);

endmodule

`resetall
