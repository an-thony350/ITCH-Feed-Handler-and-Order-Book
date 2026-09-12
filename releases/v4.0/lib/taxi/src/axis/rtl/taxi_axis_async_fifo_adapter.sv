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
 * AXI4-Stream asynchronous FIFO with width converter
 */
module taxi_axis_async_fifo_adapter #
(
    // FIFO depth in words
    // KEEP_W words per cycle if KEEP_EN set
    // Rounded up to nearest power of 2 cycles
    parameter DEPTH = 4096,
    // number of RAM pipeline registers in FIFO
    parameter RAM_PIPELINE = 1,
    // use output FIFO
    // When set, the RAM read enable and pipeline clock enables are removed
    parameter logic OUTPUT_FIFO_EN = 1'b0,
    // Frame FIFO mode - operate on frames instead of cycles
    // When set, m_axis_tvalid will not be deasserted within a frame
    // Requires LAST_EN set
    parameter logic FRAME_FIFO = 1'b0,
    // tuser value for bad frame marker
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    // tuser mask for bad frame marker
    parameter USER_BAD_FRAME_MASK = 1'b1,
    // Drop frames larger than FIFO
    // Requires FRAME_FIFO set
    parameter logic DROP_OVERSIZE_FRAME = FRAME_FIFO,
    // Drop frames marked bad
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    parameter logic DROP_BAD_FRAME = 1'b0,
    // Drop incoming frames when full
    // When set, s_axis_tready is always asserted
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    parameter logic DROP_WHEN_FULL = 1'b0,
    // Mark incoming frames as bad frames when full
    // When set, s_axis_tready is always asserted
    // Requires FRAME_FIFO to be clear
    parameter logic MARK_WHEN_FULL = 1'b0,
    // Enable pause request input
    parameter logic PAUSE_EN = 1'b0,
    // Pause between frames
    parameter logic FRAME_PAUSE = FRAME_FIFO
)
(
    /*
     * AXI4-Stream input (sink)
     */
    input  wire logic                    s_clk,
    input  wire logic                    s_rst,
    taxi_axis_if.snk                     s_axis,

    /*
     * AXI4-Stream output (source)
     */
    input  wire logic                    m_clk,
    input  wire logic                    m_rst,
    taxi_axis_if.src                     m_axis,

    /*
     * Pause
     */
    input  wire logic                    s_pause_req = 1'b0,
    output wire logic                    s_pause_ack,
    input  wire logic                    m_pause_req = 1'b0,
    output wire logic                    m_pause_ack,

    /*
     * Status
     */
    output wire logic [$clog2(DEPTH):0]  s_status_depth,
    output wire logic [$clog2(DEPTH):0]  s_status_depth_commit,
    output wire logic                    s_status_overflow,
    output wire logic                    s_status_bad_frame,
    output wire logic                    s_status_good_frame,
    output wire logic [$clog2(DEPTH):0]  m_status_depth,
    output wire logic [$clog2(DEPTH):0]  m_status_depth_commit,
    output wire logic                    m_status_overflow,
    output wire logic                    m_status_bad_frame,
    output wire logic                    m_status_good_frame
);

// extract parameters
localparam S_DATA_W = s_axis.DATA_W;
localparam logic S_KEEP_EN = s_axis.KEEP_EN;
localparam S_KEEP_W = s_axis.KEEP_W;
localparam logic S_STRB_EN = s_axis.STRB_EN;

localparam M_DATA_W = m_axis.DATA_W;
localparam logic M_KEEP_EN = m_axis.KEEP_EN;
localparam M_KEEP_W = m_axis.KEEP_W;
localparam logic M_STRB_EN = m_axis.STRB_EN;

// force keep width to 1 when disabled
localparam S_BYTE_LANES = S_KEEP_EN ? S_KEEP_W : 1;
localparam M_BYTE_LANES = M_KEEP_EN ? M_KEEP_W : 1;

// bus byte sizes (must be identical)
localparam S_BYTE_SIZE = S_DATA_W / S_BYTE_LANES;
localparam M_BYTE_SIZE = M_DATA_W / M_BYTE_LANES;
// output bus is wider
localparam EXPAND_BUS = M_BYTE_LANES > S_BYTE_LANES;
// total data and keep widths
localparam DATA_W = EXPAND_BUS ? M_DATA_W : S_DATA_W;
localparam KEEP_W = EXPAND_BUS ? M_BYTE_LANES : S_BYTE_LANES;
localparam KEEP_EN = EXPAND_BUS ? M_KEEP_EN : S_KEEP_EN;
localparam STRB_EN = M_STRB_EN && S_STRB_EN;

// check configuration
if (S_BYTE_SIZE * S_BYTE_LANES != S_DATA_W)
    $fatal(0, "Error: input data width not evenly divisible (instance %m)");

if (M_BYTE_SIZE * M_BYTE_LANES != M_DATA_W)
    $fatal(0, "Error: output data width not evenly divisible (instance %m)");

if (S_BYTE_SIZE != M_BYTE_SIZE)
    $fatal(0, "Error: byte size mismatch (instance %m)");

taxi_axis_if #(
    .DATA_W(DATA_W),
    .KEEP_EN(KEEP_EN),
    .KEEP_W(KEEP_W),
    .STRB_EN(s_axis.STRB_EN),
    .LAST_EN(s_axis.LAST_EN),
    .ID_EN(s_axis.ID_EN),
    .ID_W(s_axis.ID_W),
    .DEST_EN(s_axis.DEST_EN),
    .DEST_W(s_axis.DEST_W),
    .USER_EN(s_axis.USER_EN),
    .USER_W(s_axis.USER_W)
) axis_pre_fifo();

taxi_axis_if #(
    .DATA_W(DATA_W),
    .KEEP_EN(KEEP_EN),
    .KEEP_W(KEEP_W),
    .STRB_EN(m_axis.STRB_EN),
    .LAST_EN(m_axis.LAST_EN),
    .ID_EN(m_axis.ID_EN),
    .ID_W(m_axis.ID_W),
    .DEST_EN(m_axis.DEST_EN),
    .DEST_W(m_axis.DEST_W),
    .USER_EN(m_axis.USER_EN),
    .USER_W(m_axis.USER_W)
) axis_post_fifo();

taxi_axis_adapter
pre_fifo_adapter_inst (
    .clk(s_clk),
    .rst(s_rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(s_axis),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(axis_pre_fifo)
);

taxi_axis_async_fifo #(
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
fifo_inst (
    /*
     * AXI4-Stream input (sink)
     */
    .s_clk(s_clk),
    .s_rst(s_rst),
    .s_axis(axis_pre_fifo),

    /*
     * AXI4-Stream output (source)
     */
    .m_clk(m_clk),
    .m_rst(m_rst),
    .m_axis(axis_post_fifo),

    /*
     * Pause
     */
    .s_pause_req(s_pause_req),
    .s_pause_ack(s_pause_ack),
    .m_pause_req(m_pause_req),
    .m_pause_ack(m_pause_ack),

    /*
     * Status
     */
    .s_status_depth(s_status_depth),
    .s_status_depth_commit(s_status_depth_commit),
    .s_status_overflow(s_status_overflow),
    .s_status_bad_frame(s_status_bad_frame),
    .s_status_good_frame(s_status_good_frame),
    .m_status_depth(m_status_depth),
    .m_status_depth_commit(m_status_depth_commit),
    .m_status_overflow(m_status_overflow),
    .m_status_bad_frame(m_status_bad_frame),
    .m_status_good_frame(m_status_good_frame)
);

taxi_axis_adapter
post_fifo_adapter_inst (
    .clk(m_clk),
    .rst(m_rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(axis_post_fifo),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(m_axis)
);

endmodule

`resetall
