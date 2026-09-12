// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2024-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1fs
`default_nettype none

/*
 * PTP time distribution ToD timestamp reconstruction module
 */
module taxi_ptp_td_rel2tod #
(
    parameter TS_FNS_W = 16,
    parameter TS_REL_NS_W = 32,
    parameter TS_TOD_S_W = 48,
    parameter TS_REL_W = TS_REL_NS_W + TS_FNS_W,
    parameter TS_TOD_W = TS_TOD_S_W + 32 + TS_FNS_W,
    parameter TD_SDI_PIPELINE = 2
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * PTP clock interface
     */
    input  wire logic  ptp_clk,
    input  wire logic  ptp_rst,
    input  wire logic  ptp_td_sdi,

    /*
     * Timestamp conversion
     */
    taxi_axis_if.snk   s_axis_ts_rel,
    taxi_axis_if.src   m_axis_ts_tod
);

localparam TS_ID_W = s_axis_ts_rel.ID_W;
localparam TS_DEST_W = s_axis_ts_rel.DEST_W;
localparam TS_USER_W = s_axis_ts_rel.USER_W;

localparam TS_TOD_NS_W = 30;
localparam TS_NS_W = TS_TOD_NS_W+1;

localparam [30:0] NS_PER_S = 31'd1_000_000_000;

// pipeline to facilitate long input path
wire ptp_td_sdi_pipe[0:TD_SDI_PIPELINE];

assign ptp_td_sdi_pipe[0] = ptp_td_sdi;

for (genvar n = 0; n < TD_SDI_PIPELINE; n = n + 1) begin : pipe_stage

    (* shreg_extract = "no" *)
    logic ptp_td_sdi_reg = 0;

    assign ptp_td_sdi_pipe[n+1] = ptp_td_sdi_reg;

    always_ff @(posedge ptp_clk) begin
        ptp_td_sdi_reg <= ptp_td_sdi_pipe[n];
    end

end

// deserialize data
logic [15:0] td_shift_reg = '0;
logic [4:0] bit_cnt_reg = '0;
logic td_valid_reg = 1'b0;
logic [3:0] td_index_reg = '0;
logic [3:0] td_msg_reg = '0;

logic [15:0] td_tdata_reg = '0;
logic td_tvalid_reg = 1'b0;
logic td_tlast_reg = 1'b0;
logic [7:0] td_tid_reg = '0;
logic td_sync_reg = 1'b0;

always_ff @(posedge ptp_clk) begin
    td_shift_reg <= {ptp_td_sdi_pipe[TD_SDI_PIPELINE], td_shift_reg[15:1]};

    td_tvalid_reg <= 1'b0;

    if (bit_cnt_reg != 0) begin
        bit_cnt_reg <= bit_cnt_reg - 1;
    end else begin
        td_valid_reg <= 1'b0;
        if (td_valid_reg) begin
            td_tdata_reg <= td_shift_reg;
            td_tvalid_reg <= 1'b1;
            td_tlast_reg <= ptp_td_sdi_pipe[TD_SDI_PIPELINE];
            td_tid_reg <= {td_msg_reg, td_index_reg};
            if (td_index_reg == 0) begin
                td_msg_reg <= td_shift_reg[3:0];
                td_tid_reg[7:4] <= td_shift_reg[3:0];
            end
            td_index_reg <= td_index_reg + 1;
            td_sync_reg = !td_sync_reg;
        end
        if (ptp_td_sdi_pipe[TD_SDI_PIPELINE] == 0) begin
            bit_cnt_reg <= 16;
            td_valid_reg <= 1'b1;
        end else begin
            td_index_reg <= 0;
        end
    end

    if (ptp_rst) begin
        bit_cnt_reg <= 0;
        td_valid_reg <= 1'b0;

        td_tvalid_reg <= 1'b0;
    end
end

// sync TD data
logic [15:0] dst_td_tdata_reg = '0;
logic dst_td_tvalid_reg = 1'b0;
logic [7:0] dst_td_tid_reg = '0;

(* shreg_extract = "no" *)
logic td_sync_sync1_reg = 1'b0;
(* shreg_extract = "no" *)
logic td_sync_sync2_reg = 1'b0;
(* shreg_extract = "no" *)
logic td_sync_sync3_reg = 1'b0;

always_ff @(posedge clk) begin
    td_sync_sync1_reg <= td_sync_reg;
    td_sync_sync2_reg <= td_sync_sync1_reg;
    td_sync_sync3_reg <= td_sync_sync2_reg;
end

always_ff @(posedge clk) begin
    dst_td_tvalid_reg <= 1'b0;

    if (td_sync_sync3_reg ^ td_sync_sync2_reg) begin
        dst_td_tdata_reg <= td_tdata_reg;
        dst_td_tvalid_reg <= 1'b1;
        dst_td_tid_reg <= td_tid_reg;
    end

    if (rst) begin
        dst_td_tvalid_reg <= 1'b0;
    end
end

logic ts_sel_reg = 1'b0;

logic [47:0] ts_tod_s_0_reg = '0;
logic [31:0] ts_tod_offset_ns_0_reg = '0;
logic [47:0] ts_tod_s_1_reg = '0;
logic [31:0] ts_tod_offset_ns_1_reg = '0;

logic [TS_TOD_S_W-1:0] output_ts_tod_s_reg = '0, output_ts_tod_s_next;
logic [TS_TOD_NS_W-1:0] output_ts_tod_ns_reg = '0, output_ts_tod_ns_next;
logic [TS_FNS_W-1:0] output_ts_fns_reg = '0, output_ts_fns_next;
logic [TS_ID_W-1:0] output_ts_id_reg = '0, output_ts_id_next;
logic [TS_DEST_W-1:0] output_ts_dest_reg = '0, output_ts_dest_next;
logic [TS_USER_W-1:0] output_ts_user_reg = '0, output_ts_user_next;
logic output_ts_valid_reg = 1'b0, output_ts_valid_next;

logic [TS_NS_W-1:0] ts_tod_ns_0;
logic [TS_NS_W-1:0] ts_tod_ns_1;

assign s_axis_ts_rel.tready = 1'b1;

assign m_axis_ts_tod.tdata = {output_ts_tod_s_reg, 2'b00, output_ts_tod_ns_reg, output_ts_fns_reg};
assign m_axis_ts_tod.tkeep = '1;
assign m_axis_ts_tod.tstrb = m_axis_ts_tod.tkeep;
assign m_axis_ts_tod.tlast = 1'b1;
assign m_axis_ts_tod.tid = output_ts_id_reg;
assign m_axis_ts_tod.tdest = output_ts_dest_reg;
assign m_axis_ts_tod.tuser = output_ts_user_reg;
assign m_axis_ts_tod.tvalid = output_ts_valid_reg;

always_comb begin
    // reconstruct timestamp
    // apply both offsets
    ts_tod_ns_0 = TS_NS_W'(s_axis_ts_rel.tdata[TS_FNS_W +: TS_REL_NS_W] + ts_tod_offset_ns_0_reg);
    ts_tod_ns_1 = TS_NS_W'(s_axis_ts_rel.tdata[TS_FNS_W +: TS_REL_NS_W] + ts_tod_offset_ns_1_reg);

    // pick the correct result
    // 2 MSB clear = lower half of range (0-536,870,911)
    // 1 MSB clear = upper half of range, but could also be over 1 billion (536,870,912-1,073,741,823)
    // 1 MSB set = overflow or underflow
    // prefer 2 MSB clear over 1 MSB clear if neither result was overflow or underflow
    if (ts_tod_ns_0[30:29] == 0 || (ts_tod_ns_0[30] == 0 && ts_tod_ns_1[30:29] != 0)) begin
        output_ts_tod_s_next = ts_tod_s_0_reg;
        output_ts_tod_ns_next = ts_tod_ns_0[TS_TOD_NS_W-1:0];
    end else begin
        output_ts_tod_s_next = ts_tod_s_1_reg;
        output_ts_tod_ns_next = ts_tod_ns_1[TS_TOD_NS_W-1:0];
    end
    output_ts_fns_next = s_axis_ts_rel.tdata[TS_FNS_W-1:0];
    output_ts_id_next = s_axis_ts_rel.tid;
    output_ts_dest_next = s_axis_ts_rel.tdest;
    output_ts_user_next = s_axis_ts_rel.tuser;
    output_ts_valid_next = s_axis_ts_rel.tvalid;
end

always_ff @(posedge clk) begin
    // extract data
    if (dst_td_tvalid_reg) begin
        if (dst_td_tid_reg[3:0] == 4'd0) begin
            ts_sel_reg <= dst_td_tdata_reg[9];
        end
        // current
        if (dst_td_tid_reg == {4'd1, 4'd1}) begin
            if (ts_sel_reg) begin
                ts_tod_offset_ns_1_reg[15:0] <= dst_td_tdata_reg;
            end else begin
                ts_tod_offset_ns_0_reg[15:0] <= dst_td_tdata_reg;
            end
        end
        if (dst_td_tid_reg == {4'd1, 4'd2}) begin
            if (ts_sel_reg) begin
                ts_tod_offset_ns_1_reg[31:16] <= dst_td_tdata_reg;
            end else begin
                ts_tod_offset_ns_0_reg[31:16] <= dst_td_tdata_reg;
            end
        end
        if (dst_td_tid_reg == {4'd0, 4'd3}) begin
            if (ts_sel_reg) begin
                ts_tod_s_1_reg[15:0] <= dst_td_tdata_reg;
            end else begin
                ts_tod_s_0_reg[15:0] <= dst_td_tdata_reg;
            end
        end
        if (dst_td_tid_reg == {4'd0, 4'd4}) begin
            if (ts_sel_reg) begin
                ts_tod_s_1_reg[31:16] <= dst_td_tdata_reg;
            end else begin
                ts_tod_s_0_reg[31:16] <= dst_td_tdata_reg;
            end
        end
        if (dst_td_tid_reg == {4'd0, 4'd5}) begin
            if (ts_sel_reg) begin
                ts_tod_s_1_reg[47:32] <= dst_td_tdata_reg;
            end else begin
                ts_tod_s_0_reg[47:32] <= dst_td_tdata_reg;
            end
        end
        // alternate
        if (dst_td_tid_reg == {4'd2, 4'd1}) begin
            if (ts_sel_reg) begin
                ts_tod_offset_ns_0_reg[15:0] <= dst_td_tdata_reg;
            end else begin
                ts_tod_offset_ns_1_reg[15:0] <= dst_td_tdata_reg;
            end
        end
        if (dst_td_tid_reg == {4'd2, 4'd2}) begin
            if (ts_sel_reg) begin
                ts_tod_offset_ns_0_reg[31:16] <= dst_td_tdata_reg;
            end else begin
                ts_tod_offset_ns_1_reg[31:16] <= dst_td_tdata_reg;
            end
        end
        if (dst_td_tid_reg == {4'd2, 4'd3}) begin
            if (ts_sel_reg) begin
                ts_tod_s_0_reg[15:0] <= dst_td_tdata_reg;
            end else begin
                ts_tod_s_1_reg[15:0] <= dst_td_tdata_reg;
            end
        end
        if (dst_td_tid_reg == {4'd2, 4'd4}) begin
            if (ts_sel_reg) begin
                ts_tod_s_0_reg[31:16] <= dst_td_tdata_reg;
            end else begin
                ts_tod_s_1_reg[31:16] <= dst_td_tdata_reg;
            end
        end
        if (dst_td_tid_reg == {4'd2, 4'd5}) begin
            if (ts_sel_reg) begin
                ts_tod_s_0_reg[47:32] <= dst_td_tdata_reg;
            end else begin
                ts_tod_s_1_reg[47:32] <= dst_td_tdata_reg;
            end
        end
    end

    output_ts_tod_s_reg <= output_ts_tod_s_next;
    output_ts_tod_ns_reg <= output_ts_tod_ns_next;
    output_ts_fns_reg <= output_ts_fns_next;
    output_ts_id_reg <= output_ts_id_next;
    output_ts_dest_reg <= output_ts_dest_next;
    output_ts_user_reg <= output_ts_user_next;
    output_ts_valid_reg <= output_ts_valid_next;

    if (rst) begin
        output_ts_valid_reg <= 1'b0;
    end
end

endmodule

`resetall
