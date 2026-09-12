// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2021-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Statistics counter
 */
module taxi_stats_counter #
(
    // Statistics counter (bits)
    parameter STAT_COUNT_W = 32,
    // Pipeline length
    parameter PIPELINE = 2
)
(
    input  wire logic    clk,
    input  wire logic    rst,

    /*
     * Statistics increment input
     */
    taxi_axis_if.snk     s_axis_stat,

    /*
     * AXI Lite register interface
     */
    taxi_axil_if.wr_slv  s_axil_wr,
    taxi_axil_if.rd_slv  s_axil_rd
);

localparam STAT_INC_W = s_axis_stat.DATA_W;
localparam STAT_ID_W = s_axis_stat.ID_W;

localparam AXIL_ADDR_W = s_axil_rd.ADDR_W;
localparam AXIL_DATA_W = s_axil_rd.DATA_W;

localparam ID_SHIFT = $clog2(((AXIL_DATA_W > STAT_COUNT_W ? AXIL_DATA_W : STAT_COUNT_W)+7)/8);
localparam WORD_SELECT_SHIFT = $clog2(AXIL_DATA_W/8);
localparam WORD_SELECT_W = STAT_COUNT_W > AXIL_DATA_W ? $clog2((STAT_COUNT_W+7)/8) - $clog2(AXIL_DATA_W/8) : 1;

// check configuration
if (AXIL_ADDR_W < STAT_ID_W+ID_SHIFT)
    $fatal(0, "Error: AXI lite address width too narrow (instance %m)");

if (PIPELINE < 2)
    $fatal(0, "Error: PIPELINE must be at least 2 (instance %m)");

logic init_reg = 1'b1, init_next;
logic [STAT_ID_W-1:0] init_ptr_reg = 0, init_ptr_next;

logic op_acc_pipe_hazard;
logic stage_active;

logic [PIPELINE-1:0] op_axil_read_pipe_reg = 0, op_axil_read_pipe_next;
logic [PIPELINE-1:0] op_acc_pipe_reg = 0, op_acc_pipe_next;

logic [STAT_ID_W-1:0] mem_addr_pipeline_reg[PIPELINE] = '{default: '0}, mem_addr_pipeline_next[PIPELINE];
logic [WORD_SELECT_W-1:0] axil_shift_pipeline_reg[PIPELINE] = '{default: '0}, axil_shift_pipeline_next[PIPELINE];
logic [STAT_INC_W-1:0] stat_inc_pipeline_reg[PIPELINE] = '{default: '0}, stat_inc_pipeline_next[PIPELINE];

logic s_axis_stat_tready_reg = 1'b0, s_axis_stat_tready_next;

logic s_axil_awready_reg = 0, s_axil_awready_next;
logic s_axil_wready_reg = 0, s_axil_wready_next;
logic s_axil_bvalid_reg = 0, s_axil_bvalid_next;
logic s_axil_arready_reg = 0, s_axil_arready_next;
logic [AXIL_DATA_W-1:0] s_axil_rdata_reg = 0, s_axil_rdata_next;
logic s_axil_rvalid_reg = 0, s_axil_rvalid_next;

(* ramstyle = "no_rw_check" *)
logic [STAT_COUNT_W-1:0] mem[2**STAT_ID_W] = '{default: '0};

logic [STAT_ID_W-1:0] mem_rd_addr;
logic [STAT_ID_W-1:0] mem_wr_addr;
logic [STAT_COUNT_W-1:0] mem_wr_data;
logic mem_wr_en;
logic [STAT_COUNT_W-1:0] mem_read_data_reg = 0;
logic [STAT_COUNT_W-1:0] mem_read_data_pipeline_reg[PIPELINE-1:1] = '{default: '0};

assign s_axis_stat.tready = s_axis_stat_tready_reg;

assign s_axil_wr.awready = s_axil_awready_reg;
assign s_axil_wr.wready = s_axil_wready_reg;
assign s_axil_wr.bresp = 2'b00;
assign s_axil_wr.bvalid = s_axil_bvalid_reg;

assign s_axil_rd.arready = s_axil_arready_reg;
assign s_axil_rd.rdata = s_axil_rdata_reg;
assign s_axil_rd.rresp = 2'b00;
assign s_axil_rd.rvalid = s_axil_rvalid_reg;

wire [STAT_ID_W-1:0] s_axil_araddr_id = STAT_ID_W'(s_axil_rd.araddr >> ID_SHIFT);
wire [WORD_SELECT_W-1:0] s_axil_araddr_shift = WORD_SELECT_W'(s_axil_rd.araddr >> WORD_SELECT_SHIFT);

always_comb begin
    init_next = init_reg;
    init_ptr_next = init_ptr_reg;

    op_axil_read_pipe_next = PIPELINE'({op_axil_read_pipe_reg, 1'b0});
    op_acc_pipe_next = PIPELINE'({op_acc_pipe_reg, 1'b0});

    mem_addr_pipeline_next[0] = 0;
    axil_shift_pipeline_next[0] = 0;
    stat_inc_pipeline_next[0] = 0;
    for (integer j = 1; j < PIPELINE; j = j + 1) begin
        mem_addr_pipeline_next[j] = mem_addr_pipeline_reg[j-1];
        axil_shift_pipeline_next[j] = axil_shift_pipeline_reg[j-1];
        stat_inc_pipeline_next[j] = stat_inc_pipeline_reg[j-1];
    end

    s_axis_stat_tready_next = 1'b0;

    s_axil_awready_next = 1'b0;
    s_axil_wready_next = 1'b0;
    s_axil_bvalid_next = s_axil_bvalid_reg && !s_axil_wr.bready;

    s_axil_arready_next = 1'b0;
    s_axil_rdata_next = s_axil_rdata_reg;
    s_axil_rvalid_next = s_axil_rvalid_reg && !s_axil_rd.rready;

    mem_rd_addr = 0;
    mem_wr_addr = mem_addr_pipeline_reg[PIPELINE-1];
    mem_wr_data = mem_read_data_pipeline_reg[PIPELINE-1] + STAT_COUNT_W'(stat_inc_pipeline_reg[PIPELINE-1]);
    mem_wr_en = 0;

    op_acc_pipe_hazard = 1'b0;
    stage_active = 1'b0;

    for (integer j = 0; j < PIPELINE; j = j + 1) begin
        stage_active = op_axil_read_pipe_reg[j] || op_acc_pipe_reg[j];
        op_acc_pipe_hazard = op_acc_pipe_hazard || (stage_active && mem_addr_pipeline_reg[j] == s_axis_stat.tid);
    end

    // discard writes
    if (s_axil_wr.awvalid && s_axil_wr.wvalid && (!s_axil_wr.bvalid || s_axil_wr.bready) && (!s_axil_wr.awready && !s_axil_wr.wready)) begin
        s_axil_awready_next = 1'b1;
        s_axil_wready_next = 1'b1;
        s_axil_bvalid_next = 1'b1;
    end

    // pipeline stage 0 - accept request
    if (init_reg) begin
        // zero all counters
        init_ptr_next = init_ptr_reg + 1;

        mem_wr_addr = init_ptr_reg;
        mem_wr_data = 0;
        mem_wr_en = 1'b1;

        if (&init_ptr_reg) begin
            init_next = 1'b0;
        end
    end else if (s_axil_rd.arvalid && (!s_axil_rd.rvalid || s_axil_rd.rready) && op_axil_read_pipe_reg == 0) begin
        // AXIL read
        op_axil_read_pipe_next[0] = 1'b1;

        s_axil_arready_next = 1'b1;

        mem_rd_addr = s_axil_araddr_id;
        mem_addr_pipeline_next[0] = s_axil_araddr_id;
        axil_shift_pipeline_next[0] = s_axil_araddr_shift;
    end else if (s_axis_stat.tvalid && !s_axis_stat.tready && !op_acc_pipe_hazard) begin
        // accumulate
        op_acc_pipe_next[0] = !s_axis_stat.USER_EN || !s_axis_stat.tuser;

        s_axis_stat_tready_next = 1'b1;

        stat_inc_pipeline_next[0] = s_axis_stat.tdata;

        mem_rd_addr = s_axis_stat.tid;
        mem_addr_pipeline_next[0] = s_axis_stat.tid;
    end

    // read complete, perform operation
    if (op_acc_pipe_reg[PIPELINE-1]) begin
        // accumulate
        mem_wr_addr = mem_addr_pipeline_reg[PIPELINE-1];
        mem_wr_data = mem_read_data_pipeline_reg[PIPELINE-1] + STAT_COUNT_W'(stat_inc_pipeline_reg[PIPELINE-1]);
        mem_wr_en = 1'b1;
    end else if (op_axil_read_pipe_reg[PIPELINE-1]) begin
        // AXIL read
        s_axil_rvalid_next = 1'b1;
        s_axil_rdata_next = 0;

        if (STAT_COUNT_W > AXIL_DATA_W) begin
            s_axil_rdata_next = AXIL_DATA_W'(mem_read_data_pipeline_reg[PIPELINE-1] >> axil_shift_pipeline_reg[PIPELINE-1]*AXIL_DATA_W);
        end else begin
            s_axil_rdata_next = AXIL_DATA_W'(mem_read_data_pipeline_reg[PIPELINE-1]);
        end
    end
end

always_ff @(posedge clk) begin
    init_reg <= init_next;
    init_ptr_reg <= init_ptr_next;

    op_axil_read_pipe_reg <= op_axil_read_pipe_next;
    op_acc_pipe_reg <= op_acc_pipe_next;

    s_axis_stat_tready_reg <= s_axis_stat_tready_next;

    s_axil_awready_reg <= s_axil_awready_next;
    s_axil_wready_reg <= s_axil_wready_next;
    s_axil_bvalid_reg <= s_axil_bvalid_next;
    s_axil_arready_reg <= s_axil_arready_next;
    s_axil_rdata_reg <= s_axil_rdata_next;
    s_axil_rvalid_reg <= s_axil_rvalid_next;

    for (integer i = 0; i < PIPELINE; i = i + 1) begin
        mem_addr_pipeline_reg[i] <= mem_addr_pipeline_next[i];
        axil_shift_pipeline_reg[i] <= axil_shift_pipeline_next[i];
        stat_inc_pipeline_reg[i] <= stat_inc_pipeline_next[i];
    end

    if (mem_wr_en) begin
        mem[mem_wr_addr] <= mem_wr_data;
    end
    mem_read_data_reg <= mem[mem_rd_addr];
    mem_read_data_pipeline_reg[1] <= mem_read_data_reg;
    for (integer i = 2; i < PIPELINE; i = i + 1) begin
        mem_read_data_pipeline_reg[i] <= mem_read_data_pipeline_reg[i-1];
    end

    if (rst) begin
        init_reg <= 1'b1;
        init_ptr_reg <= 0;

        op_axil_read_pipe_reg <= 0;
        op_acc_pipe_reg <= 0;

        s_axis_stat_tready_reg <= 1'b0;

        s_axil_awready_reg <= 1'b0;
        s_axil_wready_reg <= 1'b0;
        s_axil_bvalid_reg <= 1'b0;
        s_axil_arready_reg <= 1'b0;
        s_axil_rvalid_reg <= 1'b0;
    end
end

endmodule

`resetall
