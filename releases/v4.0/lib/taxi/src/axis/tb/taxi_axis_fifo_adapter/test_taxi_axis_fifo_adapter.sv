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
 * AXI4-Stream FIFO with width converter testbench
 */
module test_taxi_axis_fifo_adapter #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DEPTH = 4096,
    parameter S_DATA_W = 8,
    parameter logic S_KEEP_EN = (S_DATA_W>8),
    parameter S_KEEP_W = ((S_DATA_W+7)/8),
    parameter logic S_STRB_EN = 0,
    parameter M_DATA_W = 8,
    parameter logic M_KEEP_EN = (M_DATA_W>8),
    parameter M_KEEP_W = ((M_DATA_W+7)/8),
    parameter logic M_STRB_EN = 0,
    parameter logic ID_EN = 1'b0,
    parameter ID_W = 8,
    parameter logic DEST_EN = 1'b0,
    parameter DEST_W = 8,
    parameter logic USER_EN = 1'b1,
    parameter USER_W = 1,
    parameter RAM_PIPELINE = 1,
    parameter logic OUTPUT_FIFO_EN = 1'b0,
    parameter logic FRAME_FIFO = 1'b0,
    parameter logic [USER_W-1:0] USER_BAD_FRAME_VALUE = 1'b1,
    parameter logic [USER_W-1:0] USER_BAD_FRAME_MASK = 1'b1,
    parameter logic DROP_OVERSIZE_FRAME = FRAME_FIFO,
    parameter logic DROP_BAD_FRAME = 1'b0,
    parameter logic DROP_WHEN_FULL = 1'b0,
    parameter logic MARK_WHEN_FULL = 1'b0,
    parameter logic PAUSE_EN = 1'b0,
    parameter logic FRAME_PAUSE = FRAME_FIFO
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(
    .DATA_W(S_DATA_W),
    .KEEP_EN(S_KEEP_EN),
    .KEEP_W(S_KEEP_W),
    .STRB_EN(S_STRB_EN),
    .LAST_EN(1'b1),
    .ID_EN(ID_EN),
    .ID_W(ID_W),
    .DEST_EN(DEST_EN),
    .DEST_W(DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) s_axis();

taxi_axis_if #(
    .DATA_W(M_DATA_W),
    .KEEP_EN(M_KEEP_EN),
    .KEEP_W(M_KEEP_W),
    .STRB_EN(M_STRB_EN),
    .LAST_EN(1'b1),
    .ID_EN(ID_EN),
    .ID_W(ID_W),
    .DEST_EN(DEST_EN),
    .DEST_W(DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) m_axis();

logic pause_req;
logic pause_ack;

logic [$clog2(DEPTH):0] status_depth;
logic [$clog2(DEPTH):0] status_depth_commit;
logic status_overflow;
logic status_bad_frame;
logic status_good_frame;

taxi_axis_fifo_adapter #(
    .DEPTH(DEPTH),
    .RAM_PIPELINE(RAM_PIPELINE),
    .OUTPUT_FIFO_EN(OUTPUT_FIFO_EN),
    .FRAME_FIFO(FRAME_FIFO),
    .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
    .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
    .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
    .DROP_BAD_FRAME(DROP_BAD_FRAME),
    .DROP_WHEN_FULL(DROP_WHEN_FULL),
    .MARK_WHEN_FULL(MARK_WHEN_FULL),
    .PAUSE_EN(PAUSE_EN),
    .FRAME_PAUSE(FRAME_PAUSE)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(s_axis),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(m_axis),

    /*
     * Pause
     */
    .pause_req(pause_req),
    .pause_ack(pause_ack),

    /*
     * Status
     */
    .status_depth(status_depth),
    .status_depth_commit(status_depth_commit),
    .status_overflow(status_overflow),
    .status_bad_frame(status_bad_frame),
    .status_good_frame(status_good_frame)
);

endmodule

`resetall
