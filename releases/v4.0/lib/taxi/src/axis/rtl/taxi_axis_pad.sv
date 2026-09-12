// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025-2026 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream padding logic
 */
module taxi_axis_pad #(
    parameter logic ID_PAD_REG_EN = 1'b1,
    parameter logic DEST_PAD_REG_EN = 1'b1,
    parameter logic USER_PAD_REG_EN = 1'b1,
    parameter MIN_LEN_W = 8,
    parameter logic UNDERFLOW_DROP_EN = 1'b0
)
(
    input  wire logic                  clk,
    input  wire logic                  rst,

    /*
     * AXI4-Stream input (sink)
     */
    taxi_axis_if.snk                   s_axis,

    /*
     * AXI4-Stream output (source)
     */
    taxi_axis_if.src                   m_axis,

    /*
     * Configuration
     */
    input  wire logic                  cfg_pad_en = 1'b1,
    input  wire logic [MIN_LEN_W-1:0]  cfg_min_pkt_len,

    /*
     * Status
     */
    output wire logic                  stat_pad_frame,
    output wire logic                  stat_err_user,
    output wire logic                  stat_err_underflow
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

localparam KEEP_W_INT = KEEP_EN ? KEEP_W : 1;
localparam BYTE_LANES = KEEP_W_INT;
localparam BYTE_SIZE = DATA_W/BYTE_LANES;

localparam PAD_LANE_W = KEEP_EN && KEEP_W > 1 ? $clog2(BYTE_LANES) : 1;
localparam PAD_CYC_W = KEEP_EN && KEEP_W > 1 ? MIN_LEN_W-PAD_LANE_W : MIN_LEN_W;

// check configuration
if (m_axis.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (KEEP_EN && m_axis.KEEP_W != KEEP_W)
    $fatal(0, "Error: Interface KEEP_W parameter mismatch (instance %m)");

if (BYTE_SIZE * BYTE_LANES != DATA_W)
    $fatal(0, "Error: input data width not evenly divisible (instance %m)");

if (2**$clog2(BYTE_LANES) != BYTE_LANES)
    $fatal(0, "Error: byte lane count be even power of two (instance %m)");

if (!LAST_EN)
    $fatal(0, "Error: LAST_EN must be set (instance %m)");

wire [PAD_LANE_W-1:0] min_pkt_len_lanes;
wire [PAD_CYC_W-1:0] min_pkt_len_cycles;

if (KEEP_EN && KEEP_W > 1) begin
    assign {min_pkt_len_cycles, min_pkt_len_lanes} = cfg_min_pkt_len;
end else begin
    assign min_pkt_len_lanes = '0;
    assign min_pkt_len_cycles = cfg_min_pkt_len;
end

logic frame_in_reg = 1'b0, frame_in_next;
logic frame_out_reg = 1'b0, frame_out_next;
logic drop_frame_reg = 1'b0, drop_frame_next;
logic drop_pad_reg = 1'b0, drop_pad_next;

logic [PAD_CYC_W-1:0] pad_cyc_reg = '0, pad_cyc_next;
logic pad_reg = 1'b0, pad_next;
logic extend_reg = 1'b0, extend_next;
logic pad_done_reg = 1'b0, pad_done_next;
logic [KEEP_W-1:0] pad_mask_reg = '1, pad_mask_next;
logic [ID_W-1:0] pad_id_reg = '0, pad_id_next;
logic [DEST_W-1:0] pad_dest_reg = '0, pad_dest_next;
logic [USER_W-1:0] pad_user_reg = '0, pad_user_next;

logic stat_pad_frame_reg = 1'b0, stat_pad_frame_next;
logic stat_err_user_reg = 1'b0, stat_err_user_next;
logic stat_err_underflow_reg = 1'b0, stat_err_underflow_next;

// Mask input data
for (genvar n = 0; n < BYTE_LANES; n = n + 1) begin
    assign m_axis.tdata[n*BYTE_SIZE +: BYTE_SIZE] = (s_axis.tkeep[n] && !extend_reg) ? s_axis.tdata[n*BYTE_SIZE +: BYTE_SIZE] : '0;
end

if (KEEP_EN) begin
    assign m_axis.tkeep = (extend_reg ? '0 : (UNDERFLOW_DROP_EN && !s_axis.tvalid ? '1 : s_axis.tkeep)) | pad_mask_reg;
end else begin
    assign m_axis.tkeep = '1;
end
assign m_axis.tstrb = m_axis.tkeep;
assign m_axis.tvalid = UNDERFLOW_DROP_EN ? ((s_axis.tvalid && !drop_frame_reg) || frame_out_reg) : s_axis.tvalid || extend_reg;
assign m_axis.tlast = (pad_reg || (UNDERFLOW_DROP_EN && !s_axis.tvalid)) ? pad_done_reg : (s_axis.tlast || (UNDERFLOW_DROP_EN && drop_pad_reg));
if (ID_EN) begin
    assign m_axis.tid = ((extend_reg || (UNDERFLOW_DROP_EN && !s_axis.tvalid)) && ID_PAD_REG_EN) ? pad_id_reg : s_axis.tid;
end else begin
    assign m_axis.tid = '0;
end
if (DEST_EN) begin
    assign m_axis.tdest = ((extend_reg || (UNDERFLOW_DROP_EN && !s_axis.tvalid)) && DEST_PAD_REG_EN) ? pad_dest_reg : s_axis.tdest;
end else begin
    assign m_axis.tdest = '0;
end
if (USER_EN) begin
    assign m_axis.tuser = (((extend_reg || (UNDERFLOW_DROP_EN && !s_axis.tvalid)) && USER_PAD_REG_EN) ? pad_user_reg : s_axis.tuser) | USER_W'(UNDERFLOW_DROP_EN && (drop_pad_reg || (!s_axis.tvalid && !extend_reg)));
end else begin
    assign m_axis.tuser = '0;
end

assign s_axis.tready = (m_axis.tready && !extend_reg) || (UNDERFLOW_DROP_EN && drop_frame_reg);

assign stat_pad_frame = stat_pad_frame_reg;
assign stat_err_user = stat_err_user_reg;
assign stat_err_underflow = UNDERFLOW_DROP_EN ? stat_err_underflow_reg : 1'b0;

always_comb begin
    frame_in_next = frame_in_reg;
    frame_out_next = frame_out_reg;
    drop_frame_next = drop_frame_reg;
    drop_pad_next = drop_pad_reg;

    pad_cyc_next = pad_cyc_reg;
    pad_next = pad_reg;
    extend_next = extend_reg;
    pad_done_next = pad_done_reg;
    pad_mask_next = pad_mask_reg;
    pad_id_next = pad_id_reg;
    pad_dest_next = pad_dest_reg;
    pad_user_next = pad_user_reg;

    stat_pad_frame_next = 1'b0;
    stat_err_user_next = s_axis.tvalid && s_axis.tready && s_axis.tlast && s_axis.tuser[0];
    stat_err_underflow_next = 1'b0;

    if (UNDERFLOW_DROP_EN && frame_in_reg && s_axis.tready && !s_axis.tvalid && !drop_frame_reg) begin
        // underflow
        drop_frame_next = 1'b1;
        drop_pad_next = 1'b1;
        if (pad_reg && !pad_done_reg) begin
            // inside minimum frame length
            extend_next = 1'b1;
        end
    end

    if (s_axis.tvalid && s_axis.tready) begin
        frame_in_next = !s_axis.tlast;
        if (s_axis.tlast) begin
            drop_frame_next = 1'b0;
            stat_err_underflow_next = drop_frame_reg;
        end
    end

    if (m_axis.tvalid && m_axis.tready) begin
        frame_out_next = !m_axis.tlast;
        if (m_axis.tlast) begin
            drop_pad_next = 1'b0;
        end
    end

    if (s_axis.tvalid && s_axis.tready) begin
        if (!extend_reg && !drop_frame_reg && !drop_pad_reg) begin
            pad_id_next = s_axis.tid;
            pad_dest_next = s_axis.tdest;
            pad_user_next = s_axis.tuser;

            if (s_axis.tlast) begin
                if (pad_reg && !pad_done_reg) begin
                    // inside minimum frame length
                    extend_next = 1'b1;
                end
            end
        end
    end

    if (m_axis.tvalid && m_axis.tready) begin
        if ((pad_cyc_reg >> 1) != 0) begin
            pad_cyc_next = pad_cyc_reg - 1;
            pad_next = 1'b1;
            pad_done_next = 1'b0;
            pad_mask_next = '1;
        end else begin
            pad_next = extend_reg || s_axis.tlast;
            pad_done_next = 1'b1;
            pad_mask_next = {KEEP_W{1'b1}} >> PAD_LANE_W'(KEEP_W-1-min_pkt_len_lanes);
        end

        if (pad_done_reg) begin
            pad_next = 1'b0;
            pad_mask_next = '0;
            extend_next = 1'b0;
            drop_pad_next = 1'b0;
            if (s_axis.tlast) begin
                // padding within final cycle
                stat_pad_frame_next = (~s_axis.tkeep & pad_mask_reg) != 0;
            end
            if (extend_reg || drop_pad_reg) begin
                // padding started in a previous cycle
                stat_pad_frame_next = 1'b1;
            end
            if (extend_reg || drop_pad_reg || s_axis.tlast) begin
                if (cfg_pad_en) begin
                    pad_cyc_next = min_pkt_len_cycles;
                    pad_next = min_pkt_len_cycles != 0;
                    pad_done_next = min_pkt_len_cycles == 0;
                    pad_mask_next = min_pkt_len_cycles == 0 ? {KEEP_W{1'b1}} >> PAD_LANE_W'(KEEP_W-1-min_pkt_len_lanes) : '1;
                end else begin
                    pad_cyc_next = '0;
                    pad_next = 1'b0;
                    pad_done_next = 1'b1;
                    pad_mask_next = '0;
                end
                pad_user_next = '0;
            end
        end
    end else if (!frame_in_reg && !extend_reg && !drop_pad_reg) begin
        if (cfg_pad_en) begin
            pad_cyc_next = min_pkt_len_cycles;
            pad_next = min_pkt_len_cycles != 0;
            pad_done_next = min_pkt_len_cycles == 0;
            pad_mask_next = min_pkt_len_cycles == 0 ? {KEEP_W{1'b1}} >> PAD_LANE_W'(KEEP_W-1-min_pkt_len_lanes) : '1;
        end else begin
            pad_cyc_next = '0;
            pad_next = 1'b0;
            pad_done_next = 1'b1;
            pad_mask_next = '0;
        end
        pad_user_next = '0;
    end
end

always_ff @(posedge clk) begin
    frame_in_reg <= frame_in_next;
    frame_out_reg <= frame_out_next;
    drop_frame_reg <= drop_frame_next;
    drop_pad_reg <= drop_pad_next;
    pad_cyc_reg <= pad_cyc_next;
    pad_reg <= pad_next;
    extend_reg <= extend_next;
    pad_done_reg <= pad_done_next;
    pad_mask_reg <= pad_mask_next;
    pad_id_reg <= pad_id_next;
    pad_dest_reg <= pad_dest_next;
    pad_user_reg <= pad_user_next;
    stat_pad_frame_reg <= stat_pad_frame_next;
    stat_err_user_reg <= stat_err_user_next;
    stat_err_underflow_reg <= stat_err_underflow_next;

    if (rst) begin
        frame_in_reg <= 1'b0;
        frame_out_reg <= 1'b0;
        drop_frame_reg <= 1'b0;
        pad_cyc_reg <= min_pkt_len_cycles;
        pad_reg <= min_pkt_len_cycles != 0;
        extend_reg <= 1'b0;
        pad_done_reg <= min_pkt_len_cycles == 0;
        pad_mask_reg <= min_pkt_len_cycles == 0 ? {KEEP_W{1'b1}} >> PAD_LANE_W'(KEEP_W-1-min_pkt_len_lanes) : '1;
        pad_user_reg <= '0;
        stat_pad_frame_reg <= 1'b0;
        stat_err_user_reg <= 1'b0;
        stat_err_underflow_reg <= 1'b0;
    end
end

endmodule

`resetall
