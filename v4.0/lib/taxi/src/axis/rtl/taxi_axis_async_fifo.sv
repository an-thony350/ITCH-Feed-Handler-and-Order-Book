// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2014-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream asynchronous FIFO
 */
module taxi_axis_async_fifo #
(
    // FIFO depth in words
    // KEEP_W words per cycle if KEEP_EN set
    // Rounded up to nearest power of 2 cycles
    parameter DEPTH = 4096,
    // FIFO ramstyle attribute
    parameter FIFO_RAMSTYLE = "auto",
    // number of RAM pipeline registers
    parameter RAM_PIPELINE = 1,
    // use output FIFO
    // When set, the RAM read enable and pipeline clock enables are removed
    parameter logic OUTPUT_FIFO_EN = 1'b0,
    // output FIFO ramstyle attribute
    parameter OUTPUT_FIFO_RAMSTYLE = "distributed",
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
localparam DATA_W = s_axis.DATA_W;
localparam logic KEEP_EN = s_axis.KEEP_EN && m_axis.KEEP_EN;
localparam KEEP_W = s_axis.KEEP_W;
localparam logic STRB_EN = s_axis.STRB_EN && m_axis.STRB_EN;
localparam logic LAST_EN = s_axis.LAST_EN && m_axis.LAST_EN;
localparam logic ID_EN = s_axis.ID_EN && m_axis.ID_EN;
localparam ID_W = s_axis.ID_W;
localparam logic DEST_EN = s_axis.DEST_EN && m_axis.DEST_EN;
localparam DEST_W = s_axis.DEST_W;
localparam logic USER_EN = s_axis.USER_EN && m_axis.USER_EN;
localparam USER_W = s_axis.USER_W;

localparam CL_DEPTH = $clog2(DEPTH);
localparam CL_KEEP_W = $clog2(KEEP_W);
localparam FIFO_AW = (KEEP_EN && KEEP_W > 1) ? $clog2(DEPTH/KEEP_W) : CL_DEPTH;

localparam OUTPUT_FIFO_AW = RAM_PIPELINE < 2 ? 3 : $clog2(RAM_PIPELINE*2+7);

// check configuration
if (FRAME_FIFO && !LAST_EN)
    $fatal(0, "Error: FRAME_FIFO set requires LAST_EN set (instance %m)");

if (DROP_OVERSIZE_FRAME && !FRAME_FIFO)
    $fatal(0, "Error: DROP_OVERSIZE_FRAME set requires FRAME_FIFO set (instance %m)");

if (DROP_BAD_FRAME && !(FRAME_FIFO && DROP_OVERSIZE_FRAME))
    $fatal(0, "Error: DROP_BAD_FRAME set requires FRAME_FIFO and DROP_OVERSIZE_FRAME set (instance %m)");

if (DROP_WHEN_FULL && !(FRAME_FIFO && DROP_OVERSIZE_FRAME))
    $fatal(0, "Error: DROP_WHEN_FULL set requires FRAME_FIFO and DROP_OVERSIZE_FRAME set (instance %m)");

if ((DROP_BAD_FRAME || MARK_WHEN_FULL) && (USER_W'(USER_BAD_FRAME_MASK) & {USER_W{1'b1}}) == 0)
    $fatal(0, "Error: Invalid USER_BAD_FRAME_MASK value (instance %m)");

if (MARK_WHEN_FULL && FRAME_FIFO)
    $fatal(0, "Error: MARK_WHEN_FULL is not compatible with FRAME_FIFO (instance %m)");

if (MARK_WHEN_FULL && !LAST_EN)
    $fatal(0, "Error: MARK_WHEN_FULL set requires LAST_EN set (instance %m)");

if (m_axis.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (KEEP_EN && m_axis.KEEP_W != KEEP_W)
    $fatal(0, "Error: Interface KEEP_W parameter mismatch (instance %m)");

if (DROP_BAD_FRAME && !s_axis.USER_EN)
    $fatal(0, "Error: DROP_BAD_FRAME set requires s_axis.USER_EN (instance %m)");

if (MARK_WHEN_FULL && !m_axis.USER_EN)
    $fatal(0, "Error: MARK_WHEN_FULL set requires m_axis.USER_EN (instance %m)");

localparam KEEP_OFFSET = DATA_W;
localparam STRB_OFFSET = KEEP_OFFSET + (KEEP_EN ? KEEP_W : 0);
localparam LAST_OFFSET = STRB_OFFSET + (STRB_EN ? KEEP_W : 0);
localparam ID_OFFSET   = LAST_OFFSET + (LAST_EN ? 1      : 0);
localparam DEST_OFFSET = ID_OFFSET   + (ID_EN   ? ID_W   : 0);
localparam USER_OFFSET = DEST_OFFSET + (DEST_EN ? DEST_W : 0);
localparam WIDTH       = USER_OFFSET + (USER_EN ? USER_W : 0);

function [FIFO_AW:0] bin2gray(input [FIFO_AW:0] b);
    bin2gray = b ^ (b >> 1);
endfunction

function [FIFO_AW:0] gray2bin(input [FIFO_AW:0] g);
    for (integer i = 0; i <= FIFO_AW; i = i + 1) begin
        gray2bin[i] = ^(g >> i);
    end
endfunction

logic [FIFO_AW:0] wr_ptr_reg = '0;
logic [FIFO_AW:0] wr_ptr_commit_reg = '0;
logic [FIFO_AW:0] wr_ptr_gray_reg = '0;
logic [FIFO_AW:0] wr_ptr_sync_commit_reg = '0;
logic [FIFO_AW:0] rd_ptr_reg = '0;
logic [FIFO_AW:0] rd_ptr_gray_reg = '0;
logic [FIFO_AW:0] wr_ptr_conv_reg = '0;
logic [FIFO_AW:0] rd_ptr_conv_reg = '0;

logic [FIFO_AW:0] wr_ptr_temp;
logic [FIFO_AW:0] rd_ptr_temp;

(* SHREG_EXTRACT = "NO" *)
logic [FIFO_AW:0] wr_ptr_gray_sync1_reg = '0;
(* SHREG_EXTRACT = "NO" *)
logic [FIFO_AW:0] wr_ptr_gray_sync2_reg = '0;
(* SHREG_EXTRACT = "NO" *)
logic [FIFO_AW:0] wr_ptr_commit_sync_reg = '0;
(* SHREG_EXTRACT = "NO" *)
logic [FIFO_AW:0] rd_ptr_gray_sync1_reg = '0;
(* SHREG_EXTRACT = "NO" *)
logic [FIFO_AW:0] rd_ptr_gray_sync2_reg = '0;

logic wr_ptr_update_valid_reg = 1'b0;
logic wr_ptr_update_reg = 1'b0;
(* SHREG_EXTRACT = "NO" *)
logic wr_ptr_update_sync1_reg = 1'b0;
(* SHREG_EXTRACT = "NO" *)
logic wr_ptr_update_sync2_reg = 1'b0;
(* SHREG_EXTRACT = "NO" *)
logic wr_ptr_update_sync3_reg = 1'b0;
(* SHREG_EXTRACT = "NO" *)
logic wr_ptr_update_ack_sync1_reg = 1'b0;
(* SHREG_EXTRACT = "NO" *)
logic wr_ptr_update_ack_sync2_reg = 1'b0;

wire s_rst_sync;
wire m_rst_sync;

(* ramstyle = "no_rw_check" *)
logic [WIDTH-1:0] mem[2**FIFO_AW];
logic mem_read_data_valid_reg = 1'b0;

(* shreg_extract = "no" *)
logic [WIDTH-1:0] mem_rd_data_pipe_reg[RAM_PIPELINE+1-1:0];
logic [RAM_PIPELINE+1-1:0] mem_rd_valid_pipe_reg = 0;

// full when first TWO MSBs do NOT match, but rest matches
// (gray code equivalent of first MSB different but rest same)
wire full = wr_ptr_gray_reg == (rd_ptr_gray_sync2_reg ^ {2'b11, {FIFO_AW-1{1'b0}}});
// empty when pointers match exactly
wire empty = FRAME_FIFO ? (rd_ptr_reg == wr_ptr_commit_sync_reg) : (rd_ptr_gray_reg == wr_ptr_gray_sync2_reg);
// overflow within packet
wire full_wr = wr_ptr_reg == (wr_ptr_commit_reg ^ {1'b1, {FIFO_AW{1'b0}}});

// control signals
logic write;
logic read;
logic store_output;

logic s_frame_reg = 1'b0;
logic m_frame_reg = 1'b0;

logic drop_frame_reg = 1'b0;
logic mark_frame_reg = 1'b0;
logic send_frame_reg = 1'b0;
logic overflow_reg = 1'b0;
logic bad_frame_reg = 1'b0;
logic good_frame_reg = 1'b0;

logic m_empty_pipe_reg = 1'b0;
logic m_terminate_frame_reg = 1'b0;

logic [FIFO_AW:0] s_depth_reg = '0;
logic [FIFO_AW:0] s_depth_commit_reg = '0;
logic [FIFO_AW:0] m_depth_reg = '0;
logic [FIFO_AW:0] m_depth_commit_reg = '0;

logic overflow_sync1_reg = 1'b0;
logic overflow_sync2_reg = 1'b0;
logic overflow_sync3_reg = 1'b0;
logic overflow_sync4_reg = 1'b0;
logic bad_frame_sync1_reg = 1'b0;
logic bad_frame_sync2_reg = 1'b0;
logic bad_frame_sync3_reg = 1'b0;
logic bad_frame_sync4_reg = 1'b0;
logic good_frame_sync1_reg = 1'b0;
logic good_frame_sync2_reg = 1'b0;
logic good_frame_sync3_reg = 1'b0;
logic good_frame_sync4_reg = 1'b0;

assign s_axis.tready = (FRAME_FIFO ? (!full || (full_wr && DROP_OVERSIZE_FRAME) || DROP_WHEN_FULL) : (!full || MARK_WHEN_FULL)) && !s_rst_sync;

wire [WIDTH-1:0] mem_wr_data;

assign mem_wr_data[DATA_W-1:0] = s_axis.tdata;
if (KEEP_EN) assign mem_wr_data[KEEP_OFFSET +: KEEP_W] = s_axis.tkeep;
if (STRB_EN) assign mem_wr_data[STRB_OFFSET +: KEEP_W] = s_axis.tstrb;
if (LAST_EN) assign mem_wr_data[LAST_OFFSET]           = s_axis.tlast | mark_frame_reg;
if (ID_EN)   assign mem_wr_data[ID_OFFSET   +: ID_W]   = s_axis.tid;
if (DEST_EN) assign mem_wr_data[DEST_OFFSET +: DEST_W] = s_axis.tdest;
if (USER_EN) assign mem_wr_data[USER_OFFSET +: USER_W] = mark_frame_reg ? USER_W'(USER_BAD_FRAME_VALUE) : s_axis.tuser;

wire [WIDTH-1:0] mem_rd_data = mem_rd_data_pipe_reg[RAM_PIPELINE+1-1];

wire               m_axis_tready_pipe;
wire               m_axis_tvalid_pipe = mem_rd_valid_pipe_reg[RAM_PIPELINE+1-1];

wire [DATA_W-1:0]  m_axis_tdata_pipe  = mem_rd_data[DATA_W-1:0];
wire [KEEP_W-1:0]  m_axis_tkeep_pipe;
wire [KEEP_W-1:0]  m_axis_tstrb_pipe;
wire               m_axis_tlast_pipe;
wire [ID_W-1:0]    m_axis_tid_pipe;
wire [DEST_W-1:0]  m_axis_tdest_pipe;
wire [USER_W-1:0]  m_axis_tuser_pipe;

if (KEEP_EN) begin
    assign m_axis_tkeep_pipe  = mem_rd_data[KEEP_OFFSET +: KEEP_W];
end else begin
    assign m_axis_tkeep_pipe  = '1;
end

if (STRB_EN) begin
    assign m_axis_tstrb_pipe  = mem_rd_data[STRB_OFFSET +: KEEP_W];
end else begin
    assign m_axis_tstrb_pipe  = m_axis_tkeep_pipe;
end

if (LAST_EN) begin
    assign m_axis_tlast_pipe  = mem_rd_data[LAST_OFFSET] | m_terminate_frame_reg;
end else begin
    assign m_axis_tlast_pipe  = 1'b1;
end

if (ID_EN) begin
    assign m_axis_tid_pipe    = mem_rd_data[ID_OFFSET +: ID_W];
end else begin
    assign m_axis_tid_pipe    = '0;
end

if (DEST_EN) begin
    assign m_axis_tdest_pipe  = mem_rd_data[DEST_OFFSET +: DEST_W];
end else begin
    assign m_axis_tdest_pipe  = '0;
end

if (USER_EN) begin
    assign m_axis_tuser_pipe  = m_terminate_frame_reg ? USER_W'(USER_BAD_FRAME_VALUE) : mem_rd_data[USER_OFFSET +: USER_W];
end else begin
    assign m_axis_tuser_pipe  = '0;
end

wire               m_axis_tready_out;
wire               m_axis_tvalid_out;

wire [DATA_W-1:0]  m_axis_tdata_out;
wire [KEEP_W-1:0]  m_axis_tkeep_out;
wire [KEEP_W-1:0]  m_axis_tstrb_out;
wire               m_axis_tlast_out;
wire [ID_W-1:0]    m_axis_tid_out;
wire [DEST_W-1:0]  m_axis_tdest_out;
wire [USER_W-1:0]  m_axis_tuser_out;

wire pipe_ready;

assign s_status_depth = (KEEP_EN && KEEP_W > 1) ? {s_depth_reg, {CL_KEEP_W{1'b0}}} : (CL_DEPTH+1)'(s_depth_reg);
assign s_status_depth_commit = (KEEP_EN && KEEP_W > 1) ? {s_depth_commit_reg, {CL_KEEP_W{1'b0}}} : (CL_DEPTH+1)'(s_depth_commit_reg);
assign s_status_overflow = overflow_reg;
assign s_status_bad_frame = bad_frame_reg;
assign s_status_good_frame = good_frame_reg;

assign m_status_depth = (KEEP_EN && KEEP_W > 1) ? {m_depth_reg, {CL_KEEP_W{1'b0}}} : (CL_DEPTH+1)'(m_depth_reg);
assign m_status_depth_commit = (KEEP_EN && KEEP_W > 1) ? {m_depth_commit_reg, {CL_KEEP_W{1'b0}}} : (CL_DEPTH+1)'(m_depth_commit_reg);
assign m_status_overflow = overflow_sync3_reg ^ overflow_sync4_reg;
assign m_status_bad_frame = bad_frame_sync3_reg ^ bad_frame_sync4_reg;
assign m_status_good_frame = good_frame_sync3_reg ^ good_frame_sync4_reg;

// reset synchronization
taxi_sync_reset #(
    .N(4)
)
s_reset_sync_inst (
    .clk(s_clk),
    .rst(m_rst),
    .out(s_rst_sync)
);

taxi_sync_reset #(
    .N(4)
)
m_reset_sync_inst (
    .clk(m_clk),
    .rst(s_rst),
    .out(m_rst_sync)
);

// Write logic
always_ff @(posedge s_clk) begin
    overflow_reg <= 1'b0;
    bad_frame_reg <= 1'b0;
    good_frame_reg <= 1'b0;

    if (FRAME_FIFO && wr_ptr_update_valid_reg) begin
        // have updated pointer to sync
        if (wr_ptr_update_reg == wr_ptr_update_ack_sync2_reg) begin
            // no sync in progress; sync update
            wr_ptr_update_valid_reg <= 1'b0;
            wr_ptr_sync_commit_reg <= wr_ptr_commit_reg;
            wr_ptr_update_reg <= !wr_ptr_update_ack_sync2_reg;
        end
    end

    if (s_axis.tready && s_axis.tvalid && LAST_EN) begin
        // track input frame status
        s_frame_reg <= !s_axis.tlast;
    end

    if (s_rst_sync && LAST_EN) begin
        // if sink side is reset during transfer, drop partial frame
        if (s_frame_reg && !(s_axis.tready && s_axis.tvalid && s_axis.tlast)) begin
            drop_frame_reg <= 1'b1;
        end
        if (s_axis.tready && s_axis.tvalid && !s_axis.tlast) begin
            drop_frame_reg <= 1'b1;
        end
    end

    if (FRAME_FIFO) begin
        // frame FIFO mode
        if (s_axis.tready && s_axis.tvalid) begin
            // transfer in
            if ((full && DROP_WHEN_FULL) || (full_wr && DROP_OVERSIZE_FRAME) || drop_frame_reg) begin
                // full, packet overflow, or currently dropping frame
                // drop frame
                drop_frame_reg <= 1'b1;
                if (s_axis.tlast) begin
                    // end of frame, reset write pointer
                    wr_ptr_temp = wr_ptr_commit_reg;
                    wr_ptr_reg <= wr_ptr_temp;
                    wr_ptr_gray_reg <= bin2gray(wr_ptr_temp);
                    drop_frame_reg <= 1'b0;
                    overflow_reg <= 1'b1;
                end
            end else begin
                mem[wr_ptr_reg[FIFO_AW-1:0]] <= mem_wr_data;
                wr_ptr_temp = wr_ptr_reg + 1;
                wr_ptr_reg <= wr_ptr_temp;
                wr_ptr_gray_reg <= bin2gray(wr_ptr_temp);
                if (s_axis.tlast || (!DROP_OVERSIZE_FRAME && (full_wr || send_frame_reg))) begin
                    // end of frame or send frame
                    send_frame_reg <= !s_axis.tlast;
                    if (s_axis.tlast && DROP_BAD_FRAME && (USER_W'(USER_BAD_FRAME_MASK) & ~(s_axis.tuser ^ USER_W'(USER_BAD_FRAME_VALUE))) != 0) begin
                        // bad packet, reset write pointer
                        wr_ptr_temp = wr_ptr_commit_reg;
                        wr_ptr_reg <= wr_ptr_temp;
                        wr_ptr_gray_reg <= bin2gray(wr_ptr_temp);
                        bad_frame_reg <= 1'b1;
                    end else begin
                        // good packet or packet overflow, update write pointer
                        wr_ptr_temp = wr_ptr_reg + 1;
                        wr_ptr_reg <= wr_ptr_temp;
                        wr_ptr_commit_reg <= wr_ptr_temp;
                        wr_ptr_gray_reg <= bin2gray(wr_ptr_temp);

                        if (wr_ptr_update_reg == wr_ptr_update_ack_sync2_reg) begin
                            // no sync in progress; sync update
                            wr_ptr_update_valid_reg <= 1'b0;
                            wr_ptr_sync_commit_reg <= wr_ptr_temp;
                            wr_ptr_update_reg <= !wr_ptr_update_ack_sync2_reg;
                        end else begin
                            // sync in progress; flag it for later
                            wr_ptr_update_valid_reg <= 1'b1;
                        end

                        good_frame_reg <= s_axis.tlast;
                    end
                end
            end
        end else if (s_axis.tvalid && full_wr && FRAME_FIFO && !DROP_OVERSIZE_FRAME) begin
            // data valid with packet overflow
            // update write pointer
            send_frame_reg <= 1'b1;
            wr_ptr_temp = wr_ptr_reg;
            wr_ptr_reg <= wr_ptr_temp;
            wr_ptr_commit_reg <= wr_ptr_temp;
            wr_ptr_gray_reg <= bin2gray(wr_ptr_temp);

            if (wr_ptr_update_reg == wr_ptr_update_ack_sync2_reg) begin
                // no sync in progress; sync update
                wr_ptr_update_valid_reg <= 1'b0;
                wr_ptr_sync_commit_reg <= wr_ptr_temp;
                wr_ptr_update_reg <= !wr_ptr_update_ack_sync2_reg;
            end else begin
                // sync in progress; flag it for later
                wr_ptr_update_valid_reg <= 1'b1;
            end
        end
    end else begin
        // normal FIFO mode
        if (s_axis.tready && s_axis.tvalid) begin
            if (drop_frame_reg && LAST_EN) begin
                // currently dropping frame
                if (s_axis.tlast) begin
                    // end of frame
                    if (!full && mark_frame_reg && MARK_WHEN_FULL) begin
                        // terminate marked frame
                        mark_frame_reg <= 1'b0;
                        mem[wr_ptr_reg[FIFO_AW-1:0]] <= mem_wr_data;
                        wr_ptr_temp = wr_ptr_reg + 1;
                        wr_ptr_reg <= wr_ptr_temp;
                        wr_ptr_commit_reg <= wr_ptr_temp;
                        wr_ptr_gray_reg <= bin2gray(wr_ptr_temp);
                    end
                    // end of frame, clear drop flag
                    drop_frame_reg <= 1'b0;
                    overflow_reg <= 1'b1;
                end
            end else if ((full || mark_frame_reg) && MARK_WHEN_FULL) begin
                // full or marking frame
                // drop frame; mark if this isn't the first cycle
                drop_frame_reg <= 1'b1;
                mark_frame_reg <= mark_frame_reg || s_frame_reg;
                if (s_axis.tlast) begin
                    drop_frame_reg <= 1'b0;
                    overflow_reg <= 1'b1;
                end
            end else begin
                // transfer in
                mem[wr_ptr_reg[FIFO_AW-1:0]] <= mem_wr_data;
                wr_ptr_temp = wr_ptr_reg + 1;
                wr_ptr_reg <= wr_ptr_temp;
                wr_ptr_commit_reg <= wr_ptr_temp;
                wr_ptr_gray_reg <= bin2gray(wr_ptr_temp);
            end
        end else if ((!full && !drop_frame_reg && mark_frame_reg) && MARK_WHEN_FULL) begin
            // terminate marked frame
            mark_frame_reg <= 1'b0;
            mem[wr_ptr_reg[FIFO_AW-1:0]] <= mem_wr_data;
            wr_ptr_temp = wr_ptr_reg + 1;
            wr_ptr_reg <= wr_ptr_temp;
            wr_ptr_commit_reg <= wr_ptr_temp;
            wr_ptr_gray_reg <= bin2gray(wr_ptr_temp);
        end
    end

    if (s_rst_sync) begin
        wr_ptr_reg <= '0;
        wr_ptr_commit_reg <= '0;
        wr_ptr_gray_reg <= '0;
        wr_ptr_sync_commit_reg <= '0;

        wr_ptr_update_valid_reg <= 1'b0;
        wr_ptr_update_reg <= 1'b0;
    end

    if (s_rst) begin
        wr_ptr_reg <= '0;
        wr_ptr_commit_reg <= '0;
        wr_ptr_gray_reg <= '0;
        wr_ptr_sync_commit_reg <= '0;

        wr_ptr_update_valid_reg <= 1'b0;
        wr_ptr_update_reg <= 1'b0;

        s_frame_reg <= 1'b0;

        drop_frame_reg <= 1'b0;
        mark_frame_reg <= 1'b0;
        send_frame_reg <= 1'b0;
        overflow_reg <= 1'b0;
        bad_frame_reg <= 1'b0;
        good_frame_reg <= 1'b0;
    end
end

// Write-side status
always_ff @(posedge s_clk) begin
    rd_ptr_conv_reg <= gray2bin(rd_ptr_gray_sync2_reg);
    s_depth_reg <= wr_ptr_reg - rd_ptr_conv_reg;
    s_depth_commit_reg <= wr_ptr_commit_reg - rd_ptr_conv_reg;
end

// pointer synchronization
always_ff @(posedge s_clk) begin
    rd_ptr_gray_sync1_reg <= rd_ptr_gray_reg;
    rd_ptr_gray_sync2_reg <= rd_ptr_gray_sync1_reg;
    wr_ptr_update_ack_sync1_reg <= wr_ptr_update_sync3_reg;
    wr_ptr_update_ack_sync2_reg <= wr_ptr_update_ack_sync1_reg;

    if (s_rst) begin
        rd_ptr_gray_sync1_reg <= '0;
        rd_ptr_gray_sync2_reg <= '0;
        wr_ptr_update_ack_sync1_reg <= 1'b0;
        wr_ptr_update_ack_sync2_reg <= 1'b0;
    end
end

always_ff @(posedge m_clk) begin
    wr_ptr_gray_sync1_reg <= wr_ptr_gray_reg;
    wr_ptr_gray_sync2_reg <= wr_ptr_gray_sync1_reg;
    if (FRAME_FIFO && wr_ptr_update_sync2_reg ^ wr_ptr_update_sync3_reg) begin
        wr_ptr_commit_sync_reg <= wr_ptr_sync_commit_reg;
    end
    wr_ptr_update_sync1_reg <= wr_ptr_update_reg;
    wr_ptr_update_sync2_reg <= wr_ptr_update_sync1_reg;
    wr_ptr_update_sync3_reg <= wr_ptr_update_sync2_reg;

    if (FRAME_FIFO && m_rst_sync) begin
        wr_ptr_gray_sync1_reg <= '0;
    end

    if (m_rst) begin
        wr_ptr_gray_sync1_reg <= '0;
        wr_ptr_gray_sync2_reg <= '0;
        wr_ptr_commit_sync_reg <= '0;
        wr_ptr_update_sync1_reg <= 1'b0;
        wr_ptr_update_sync2_reg <= 1'b0;
        wr_ptr_update_sync3_reg <= 1'b0;
    end
end

// status synchronization
always_ff @(posedge s_clk) begin
    overflow_sync1_reg <= overflow_sync1_reg ^ overflow_reg;
    bad_frame_sync1_reg <= bad_frame_sync1_reg ^ bad_frame_reg;
    good_frame_sync1_reg <= good_frame_sync1_reg ^ good_frame_reg;

    if (s_rst) begin
        overflow_sync1_reg <= 1'b0;
        bad_frame_sync1_reg <= 1'b0;
        good_frame_sync1_reg <= 1'b0;
    end
end

always_ff @(posedge m_clk) begin
    overflow_sync2_reg <= overflow_sync1_reg;
    overflow_sync3_reg <= overflow_sync2_reg;
    overflow_sync4_reg <= overflow_sync3_reg;
    bad_frame_sync2_reg <= bad_frame_sync1_reg;
    bad_frame_sync3_reg <= bad_frame_sync2_reg;
    bad_frame_sync4_reg <= bad_frame_sync3_reg;
    good_frame_sync2_reg <= good_frame_sync1_reg;
    good_frame_sync3_reg <= good_frame_sync2_reg;
    good_frame_sync4_reg <= good_frame_sync3_reg;

    if (m_rst) begin
        overflow_sync2_reg <= 1'b0;
        overflow_sync3_reg <= 1'b0;
        overflow_sync4_reg <= 1'b0;
        bad_frame_sync2_reg <= 1'b0;
        bad_frame_sync3_reg <= 1'b0;
        bad_frame_sync4_reg <= 1'b0;
        good_frame_sync2_reg <= 1'b0;
        good_frame_sync3_reg <= 1'b0;
        good_frame_sync4_reg <= 1'b0;
    end
end

// Read logic
always_ff @(posedge m_clk) begin
    if (m_axis_tready_pipe) begin
        // output ready; invalidate stage
        mem_rd_valid_pipe_reg[RAM_PIPELINE+1-1] <= 1'b0;
        m_terminate_frame_reg <= 1'b0;
    end

    for (integer j = RAM_PIPELINE+1-1; j > 0; j = j - 1) begin
        // if (m_axis_tready_pipe || ((~mem_rd_valid_pipe_reg) >> j)) begin
        if (m_axis_tready_pipe || ((RAM_PIPELINE+1)'(~mem_rd_valid_pipe_reg) >> j) != 0) begin
            // output ready or bubble in pipeline; transfer down pipeline
            mem_rd_valid_pipe_reg[j] <= mem_rd_valid_pipe_reg[j-1];
            mem_rd_data_pipe_reg[j] <= mem_rd_data_pipe_reg[j-1];
            mem_rd_valid_pipe_reg[j-1] <= 1'b0;
        end
    end

    if (m_axis_tready_pipe || &mem_rd_valid_pipe_reg == 0) begin
        // output ready or bubble in pipeline; read new data from FIFO
        mem_rd_valid_pipe_reg[0] <= 1'b0;
        mem_rd_data_pipe_reg[0] <= mem[rd_ptr_reg[FIFO_AW-1:0]];
        if (!empty && !m_rst_sync && !m_empty_pipe_reg && pipe_ready) begin
            // not empty, increment pointer
            mem_rd_valid_pipe_reg[0] <= 1'b1;
            rd_ptr_temp = rd_ptr_reg + 1;
            rd_ptr_reg <= rd_ptr_temp;
            rd_ptr_gray_reg <= bin2gray(rd_ptr_temp);;
        end
    end

    if (m_axis_tvalid_pipe && LAST_EN) begin
        // track output frame status
        if (m_axis_tlast_pipe && m_axis_tready_pipe) begin
            m_frame_reg <= 1'b0;
        end else begin
            m_frame_reg <= 1'b1;
        end
    end

    if (m_empty_pipe_reg && mem_rd_valid_pipe_reg == 0 && LAST_EN) begin
        // terminate frame
        // (only for frame transfers interrupted by source reset)
        if (m_frame_reg) begin
            mem_rd_valid_pipe_reg[RAM_PIPELINE+1-1] <= 1'b1;
            m_terminate_frame_reg <= 1'b1;
        end
        m_empty_pipe_reg <= 1'b0;
    end

    if (m_rst_sync && LAST_EN) begin
        // if source side is reset during transfer, drop partial frame
        m_empty_pipe_reg <= 1'b1;
    end

    if (m_rst_sync) begin
        rd_ptr_reg <= '0;
        rd_ptr_gray_reg <= '0;
    end

    if (m_rst) begin
        rd_ptr_reg <= '0;
        rd_ptr_gray_reg <= '0;
        mem_rd_valid_pipe_reg <= '0;
        m_frame_reg <= 1'b0;
        m_empty_pipe_reg <= 1'b0;
        m_terminate_frame_reg <= 1'b0;
    end
end

// Read-side status
always_ff @(posedge m_clk) begin
    wr_ptr_conv_reg <= gray2bin(wr_ptr_gray_sync2_reg);
    m_depth_reg <= wr_ptr_conv_reg - rd_ptr_reg;
    m_depth_commit_reg <= FRAME_FIFO ? wr_ptr_commit_sync_reg - rd_ptr_reg : wr_ptr_conv_reg - rd_ptr_reg;
end

if (!OUTPUT_FIFO_EN) begin

    assign pipe_ready = 1'b1;

    assign m_axis_tready_pipe = m_axis_tready_out;
    assign m_axis_tvalid_out = m_axis_tvalid_pipe;

    assign m_axis_tdata_out = m_axis_tdata_pipe;
    assign m_axis_tkeep_out = m_axis_tkeep_pipe;
    assign m_axis_tstrb_out = m_axis_tstrb_pipe;
    assign m_axis_tlast_out = m_axis_tlast_pipe;
    assign m_axis_tid_out   = m_axis_tid_pipe;
    assign m_axis_tdest_out = m_axis_tdest_pipe;
    assign m_axis_tuser_out = m_axis_tuser_pipe;

end else begin : output_fifo

    // output datapath logic
    logic [DATA_W-1:0] m_axis_tdata_reg  = '0;
    logic [KEEP_W-1:0] m_axis_tkeep_reg  = '0;
    logic [KEEP_W-1:0] m_axis_tstrb_reg  = '0;
    logic              m_axis_tvalid_reg = 1'b0;
    logic              m_axis_tlast_reg  = 1'b0;
    logic [ID_W-1:0]   m_axis_tid_reg    = '0;
    logic [DEST_W-1:0] m_axis_tdest_reg  = '0;
    logic [USER_W-1:0] m_axis_tuser_reg  = '0;

    logic [OUTPUT_FIFO_AW+1-1:0] out_fifo_wr_ptr_reg = 0;
    logic [OUTPUT_FIFO_AW+1-1:0] out_fifo_rd_ptr_reg = 0;
    logic out_fifo_half_full_reg = 1'b0;

    wire out_fifo_full = out_fifo_wr_ptr_reg == (out_fifo_rd_ptr_reg ^ {1'b1, {OUTPUT_FIFO_AW{1'b0}}});
    wire out_fifo_empty = out_fifo_wr_ptr_reg == out_fifo_rd_ptr_reg;

    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [DATA_W-1:0] out_fifo_tdata[2**OUTPUT_FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [KEEP_W-1:0] out_fifo_tkeep[2**OUTPUT_FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [KEEP_W-1:0] out_fifo_tstrb[2**OUTPUT_FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic              out_fifo_tlast[2**OUTPUT_FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [ID_W-1:0]   out_fifo_tid[2**OUTPUT_FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [DEST_W-1:0] out_fifo_tdest[2**OUTPUT_FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [USER_W-1:0] out_fifo_tuser[2**OUTPUT_FIFO_AW];

    assign pipe_ready = !out_fifo_half_full_reg;

    assign m_axis_tready_pipe = 1'b1;

    assign m_axis_tdata_out  = m_axis_tdata_reg;
    assign m_axis_tkeep_out  = KEEP_EN ? m_axis_tkeep_reg : '1;
    assign m_axis_tstrb_out  = STRB_EN ? m_axis_tkeep_reg : m_axis_tkeep_out;
    assign m_axis_tvalid_out = m_axis_tvalid_reg;
    assign m_axis_tlast_out  = LAST_EN ? m_axis_tlast_reg : 1'b1;
    assign m_axis_tid_out    = ID_EN   ? m_axis_tid_reg   : '0;
    assign m_axis_tdest_out  = DEST_EN ? m_axis_tdest_reg : '0;
    assign m_axis_tuser_out  = USER_EN ? m_axis_tuser_reg : '0;

    always_ff @(posedge m_clk) begin
        m_axis_tvalid_reg <= m_axis_tvalid_reg && !m_axis_tready_out;

        out_fifo_half_full_reg <= $unsigned(out_fifo_wr_ptr_reg - out_fifo_rd_ptr_reg) >= 2**(OUTPUT_FIFO_AW-1);

        if (!out_fifo_full && m_axis_tvalid_pipe) begin
            out_fifo_tdata[out_fifo_wr_ptr_reg[OUTPUT_FIFO_AW-1:0]] <= m_axis_tdata_pipe;
            out_fifo_tkeep[out_fifo_wr_ptr_reg[OUTPUT_FIFO_AW-1:0]] <= m_axis_tkeep_pipe;
            out_fifo_tstrb[out_fifo_wr_ptr_reg[OUTPUT_FIFO_AW-1:0]] <= m_axis_tstrb_pipe;
            out_fifo_tlast[out_fifo_wr_ptr_reg[OUTPUT_FIFO_AW-1:0]] <= m_axis_tlast_pipe;
            out_fifo_tid[out_fifo_wr_ptr_reg[OUTPUT_FIFO_AW-1:0]] <= m_axis_tid_pipe;
            out_fifo_tdest[out_fifo_wr_ptr_reg[OUTPUT_FIFO_AW-1:0]] <= m_axis_tdest_pipe;
            out_fifo_tuser[out_fifo_wr_ptr_reg[OUTPUT_FIFO_AW-1:0]] <= m_axis_tuser_pipe;
            out_fifo_wr_ptr_reg <= out_fifo_wr_ptr_reg + 1;
        end

        if (!out_fifo_empty && (!m_axis_tvalid_reg || m_axis_tready_out)) begin
            m_axis_tdata_reg <= out_fifo_tdata[out_fifo_rd_ptr_reg[OUTPUT_FIFO_AW-1:0]];
            m_axis_tkeep_reg <= out_fifo_tkeep[out_fifo_rd_ptr_reg[OUTPUT_FIFO_AW-1:0]];
            m_axis_tstrb_reg <= out_fifo_tstrb[out_fifo_rd_ptr_reg[OUTPUT_FIFO_AW-1:0]];
            m_axis_tvalid_reg <= 1'b1;
            m_axis_tlast_reg <= out_fifo_tlast[out_fifo_rd_ptr_reg[OUTPUT_FIFO_AW-1:0]];
            m_axis_tid_reg <= out_fifo_tid[out_fifo_rd_ptr_reg[OUTPUT_FIFO_AW-1:0]];
            m_axis_tdest_reg <= out_fifo_tdest[out_fifo_rd_ptr_reg[OUTPUT_FIFO_AW-1:0]];
            m_axis_tuser_reg <= out_fifo_tuser[out_fifo_rd_ptr_reg[OUTPUT_FIFO_AW-1:0]];
            out_fifo_rd_ptr_reg <= out_fifo_rd_ptr_reg + 1;
        end

        if (m_rst) begin
            out_fifo_wr_ptr_reg <= 0;
            out_fifo_rd_ptr_reg <= 0;
            m_axis_tvalid_reg <= 1'b0;
        end
    end

end

if (PAUSE_EN) begin : pause

    // Pause logic
    logic pause_reg = 1'b0;
    logic pause_frame_reg = 1'b0;

    wire s_pause_req_sync;

    taxi_sync_signal #(
        .WIDTH(1),
        .N(2)
    )
    pause_req_sync_inst (
        .clk(m_clk),
        .in(s_pause_req),
        .out(s_pause_req_sync)
    );

    taxi_sync_signal #(
        .WIDTH(1),
        .N(2)
    )
    pause_ack_sync_inst (
        .clk(s_clk),
        .in(pause_reg),
        .out(s_pause_ack)
    );

    assign m_axis_tready_out = m_axis.tready && !pause_reg;
    assign m_axis.tvalid = m_axis_tvalid_out && !pause_reg;

    assign m_axis.tdata = m_axis_tdata_out;
    assign m_axis.tkeep = m_axis_tkeep_out;
    assign m_axis.tstrb = m_axis_tstrb_out;
    assign m_axis.tlast = m_axis_tlast_out;
    assign m_axis.tid   = m_axis_tid_out;
    assign m_axis.tdest = m_axis_tdest_out;
    assign m_axis.tuser = m_axis_tuser_out;

    assign m_pause_ack = pause_reg;

    always_ff @(posedge m_clk) begin
        if (FRAME_PAUSE) begin
            if (pause_reg) begin
                // paused; update pause status
                pause_reg <= m_pause_req || s_pause_req_sync;
            end else if (m_axis_tvalid_out) begin
                // frame transfer; set frame bit
                pause_frame_reg <= 1'b1;
                if (m_axis.tready && m_axis.tlast) begin
                    // end of frame; clear frame bit and update pause status
                    pause_frame_reg <= 1'b0;
                    pause_reg <= m_pause_req || s_pause_req_sync;
                end
            end else if (!pause_frame_reg) begin
                // idle; update pause status
                pause_reg <= m_pause_req || s_pause_req_sync;
            end
        end else begin
            pause_reg <= m_pause_req || s_pause_req_sync;
        end

        if (m_rst) begin
            pause_frame_reg <= 1'b0;
            pause_reg <= 1'b0;
        end
    end

end else begin

    assign m_axis_tready_out = m_axis.tready;
    assign m_axis.tvalid = m_axis_tvalid_out;

    assign m_axis.tdata = m_axis_tdata_out;
    assign m_axis.tkeep = m_axis_tkeep_out;
    assign m_axis.tstrb = m_axis_tstrb_out;
    assign m_axis.tlast = m_axis_tlast_out;
    assign m_axis.tid   = m_axis_tid_out;
    assign m_axis.tdest = m_axis_tdest_out;
    assign m_axis.tuser = m_axis_tuser_out;

    assign s_pause_ack = 1'b0;
    assign m_pause_ack = 1'b0;

end

endmodule

`resetall
