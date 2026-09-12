// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2013-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream FIFO
 */
module taxi_axis_fifo #
(
    // FIFO depth in words
    // KEEP_W words per cycle if KEEP_EN set
    // Rounded up to nearest power of 2 cycles
    parameter DEPTH = 4096,
    // number of RAM pipeline registers
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
    // When set, s_axis.tready is always asserted
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    parameter logic DROP_WHEN_FULL = 1'b0,
    // Mark incoming frames as bad frames when full
    // When set, s_axis.tready is always asserted
    // Requires FRAME_FIFO to be clear
    parameter logic MARK_WHEN_FULL = 1'b0,
    // Enable pause request input
    parameter logic PAUSE_EN = 1'b0,
    // Pause between frames
    parameter logic FRAME_PAUSE = FRAME_FIFO
)
(
    input  wire logic                    clk,
    input  wire logic                    rst,

    /*
     * AXI4-Stream input (sink)
     */
    taxi_axis_if.snk                     s_axis,

    /*
     * AXI4-Stream output (source)
     */
    taxi_axis_if.src                     m_axis,

    /*
     * Pause
     */
    input  wire logic                    pause_req = 1'b0,
    output wire logic                    pause_ack,

    /*
     * Status
     */
    output wire logic [$clog2(DEPTH):0]  status_depth,
    output wire logic [$clog2(DEPTH):0]  status_depth_commit,
    output wire logic                    status_overflow,
    output wire logic                    status_bad_frame,
    output wire logic                    status_good_frame
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

logic [FIFO_AW:0] wr_ptr_reg = '0;
logic [FIFO_AW:0] wr_ptr_commit_reg = '0;
logic [FIFO_AW:0] rd_ptr_reg = '0;

(* ramstyle = "no_rw_check" *)
logic [WIDTH-1:0] mem[2**FIFO_AW];

(* shreg_extract = "no" *)
logic [WIDTH-1:0] mem_rd_data_pipe_reg[RAM_PIPELINE+1-1:0];
logic [RAM_PIPELINE+1-1:0] mem_rd_valid_pipe_reg = '0;

// full when first MSB differs but the rest match
wire full = wr_ptr_reg == (rd_ptr_reg ^ {1'b1, {FIFO_AW{1'b0}}});
// empty when pointers match exactly
wire empty = wr_ptr_commit_reg == rd_ptr_reg;
// overflow within packet, same as full but based on write commit
wire full_wr = wr_ptr_reg == (wr_ptr_commit_reg ^ {1'b1, {FIFO_AW{1'b0}}});

logic s_frame_reg = 1'b0;

logic drop_frame_reg = 1'b0;
logic mark_frame_reg = 1'b0;
logic send_frame_reg = 1'b0;
logic [FIFO_AW:0] depth_reg = '0;
logic [FIFO_AW:0] depth_commit_reg = '0;
logic overflow_reg = 1'b0;
logic bad_frame_reg = 1'b0;
logic good_frame_reg = 1'b0;

assign s_axis.tready = FRAME_FIFO ? (!full || (full_wr && DROP_OVERSIZE_FRAME) || DROP_WHEN_FULL) : (!full || MARK_WHEN_FULL);

wire [WIDTH-1:0] mem_wr_data;

assign mem_wr_data[DATA_W-1:0] = s_axis.tdata;
if (KEEP_EN) assign mem_wr_data[KEEP_OFFSET +: KEEP_W] = s_axis.tkeep;
if (STRB_EN) assign mem_wr_data[STRB_OFFSET +: KEEP_W] = s_axis.tkeep;
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
    assign m_axis_tlast_pipe  = mem_rd_data[LAST_OFFSET];
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
    assign m_axis_tuser_pipe  = mem_rd_data[USER_OFFSET +: USER_W];
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

assign status_depth = (KEEP_EN && KEEP_W > 1) ? {depth_reg, {CL_KEEP_W{1'b0}}} : (CL_DEPTH+1)'(depth_reg);
assign status_depth_commit = (KEEP_EN && KEEP_W > 1) ? {depth_commit_reg, {CL_KEEP_W{1'b0}}} : (CL_DEPTH+1)'(depth_commit_reg);
assign status_overflow = overflow_reg;
assign status_bad_frame = bad_frame_reg;
assign status_good_frame = good_frame_reg;

// Write logic
always_ff @(posedge clk) begin
    overflow_reg <= 1'b0;
    bad_frame_reg <= 1'b0;
    good_frame_reg <= 1'b0;

    if (s_axis.tready && s_axis.tvalid && LAST_EN) begin
        // track input frame status
        s_frame_reg <= !s_axis.tlast;
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
                    wr_ptr_reg <= wr_ptr_commit_reg;
                    drop_frame_reg <= 1'b0;
                    overflow_reg <= 1'b1;
                end
            end else begin
                // store it
                mem[wr_ptr_reg[FIFO_AW-1:0]] <= mem_wr_data;
                wr_ptr_reg <= wr_ptr_reg + 1;
                if (s_axis.tlast || (!DROP_OVERSIZE_FRAME && (full_wr || send_frame_reg))) begin
                    // end of frame or send frame
                    send_frame_reg <= !s_axis.tlast;
                    if (s_axis.tlast && DROP_BAD_FRAME && (USER_W'(USER_BAD_FRAME_MASK) & ~(s_axis.tuser ^ USER_W'(USER_BAD_FRAME_VALUE))) != 0) begin
                        // bad packet, reset write pointer
                        wr_ptr_reg <= wr_ptr_commit_reg;
                        bad_frame_reg <= 1'b1;
                    end else begin
                        // good packet or packet overflow, update write pointer
                        wr_ptr_commit_reg <= wr_ptr_reg + 1;
                        good_frame_reg <= s_axis.tlast;
                    end
                end
            end
        end else if (s_axis.tvalid && full_wr && !DROP_OVERSIZE_FRAME) begin
            // data valid with packet overflow
            // update write pointer
            send_frame_reg <= 1'b1;
            wr_ptr_commit_reg <= wr_ptr_reg;
        end
    end else begin
        // normal FIFO mode
        if (s_axis.tready && s_axis.tvalid) begin
            if (drop_frame_reg && MARK_WHEN_FULL) begin
                // currently dropping frame
                if (s_axis.tlast) begin
                    // end of frame
                    if (!full && mark_frame_reg) begin
                        // terminate marked frame
                        mark_frame_reg <= 1'b0;
                        mem[wr_ptr_reg[FIFO_AW-1:0]] <= mem_wr_data;
                        wr_ptr_reg <= wr_ptr_reg + 1;
                        wr_ptr_commit_reg <= wr_ptr_reg + 1;
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
                wr_ptr_reg <= wr_ptr_reg + 1;
                wr_ptr_commit_reg <= wr_ptr_reg + 1;
            end
        end else if ((!full && !drop_frame_reg && mark_frame_reg) && MARK_WHEN_FULL) begin
            // terminate marked frame
            mark_frame_reg <= 1'b0;
            mem[wr_ptr_reg[FIFO_AW-1:0]] <= mem_wr_data;
            wr_ptr_reg <= wr_ptr_reg + 1;
            wr_ptr_commit_reg <= wr_ptr_reg + 1;
        end
    end

    if (rst) begin
        wr_ptr_reg <= '0;
        wr_ptr_commit_reg <= '0;

        s_frame_reg <= 1'b0;

        drop_frame_reg <= 1'b0;
        mark_frame_reg <= 1'b0;
        send_frame_reg <= 1'b0;
        overflow_reg <= 1'b0;
        bad_frame_reg <= 1'b0;
        good_frame_reg <= 1'b0;
    end
end

// Status
always_ff @(posedge clk) begin
    depth_reg <= wr_ptr_reg - rd_ptr_reg;
    depth_commit_reg <= wr_ptr_commit_reg - rd_ptr_reg;
end

// Read logic
always_ff @(posedge clk) begin
    if (m_axis_tready_pipe) begin
        // output ready; invalidate stage
        mem_rd_valid_pipe_reg[RAM_PIPELINE+1-1] <= 1'b0;
    end

    for (integer j = RAM_PIPELINE+1-1; j > 0; j = j - 1) begin
        if (m_axis_tready_pipe || ((RAM_PIPELINE+1)'(~mem_rd_valid_pipe_reg) >> j) != 0) begin
        // if (m_axis_tready_pipe || &mem_rd_valid_pipe_reg[1:1] == 0) begin
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
        if (!empty && pipe_ready) begin
            // not empty, increment pointer
            mem_rd_valid_pipe_reg[0] <= 1'b1;
            rd_ptr_reg <= rd_ptr_reg + 1;
        end
    end

    if (rst) begin
        rd_ptr_reg <= '0;
        mem_rd_valid_pipe_reg <= '0;
    end
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

    logic [OUTPUT_FIFO_AW+1-1:0] out_fifo_wr_ptr_reg = '0;
    logic [OUTPUT_FIFO_AW+1-1:0] out_fifo_rd_ptr_reg = '0;
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
    assign m_axis_tstrb_out  = STRB_EN ? m_axis_tstrb_reg : m_axis_tkeep_out;
    assign m_axis_tvalid_out = m_axis_tvalid_reg;
    assign m_axis_tlast_out  = LAST_EN ? m_axis_tlast_reg : 1'b1;
    assign m_axis_tid_out    = ID_EN   ? m_axis_tid_reg   : '0;
    assign m_axis_tdest_out  = DEST_EN ? m_axis_tdest_reg : '0;
    assign m_axis_tuser_out  = USER_EN ? m_axis_tuser_reg : '0;

    always_ff @(posedge clk) begin
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

        if (rst) begin
            out_fifo_wr_ptr_reg <= '0;
            out_fifo_rd_ptr_reg <= '0;
            m_axis_tvalid_reg <= 1'b0;
        end
    end

end

if (PAUSE_EN) begin : pause

    // Pause logic
    logic pause_reg = 1'b0;
    logic pause_frame_reg = 1'b0;

    assign m_axis_tready_out = m_axis.tready && !pause_reg;
    assign m_axis.tvalid = m_axis_tvalid_out && !pause_reg;

    assign m_axis.tdata = m_axis_tdata_out;
    assign m_axis.tkeep = m_axis_tkeep_out;
    assign m_axis.tstrb = m_axis_tstrb_out;
    assign m_axis.tlast = m_axis_tlast_out;
    assign m_axis.tid   = m_axis_tid_out;
    assign m_axis.tdest = m_axis_tdest_out;
    assign m_axis.tuser = m_axis_tuser_out;

    assign pause_ack = pause_reg;

    always_ff @(posedge clk) begin
        if (FRAME_PAUSE) begin
            if (pause_reg) begin
                // paused; update pause status
                pause_reg <= pause_req;
            end else if (m_axis_tvalid_out) begin
                // frame transfer; set frame bit
                pause_frame_reg <= 1'b1;
                if (m_axis.tready && m_axis.tlast) begin
                    // end of frame; clear frame bit and update pause status
                    pause_frame_reg <= 1'b0;
                    pause_reg <= pause_req;
                end
            end else if (!pause_frame_reg) begin
                // idle; update pause status
                pause_reg <= pause_req;
            end
        end else begin
            pause_reg <= pause_req;
        end

        if (rst) begin
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

    assign pause_ack = 1'b0;

end

endmodule

`resetall
