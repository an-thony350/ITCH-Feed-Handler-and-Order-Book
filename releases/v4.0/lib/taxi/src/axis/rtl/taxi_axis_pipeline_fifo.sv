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
 * AXI4-Stream pipeline FIFO
 */
module taxi_axis_pipeline_fifo #
(
    // Number of registers in pipeline
    parameter LENGTH = 2
)
(
    input  wire logic  clk,
    input  wire logic  rst,


    /*
     * AXI4-Stream input (sink)
     */
    taxi_axis_if.snk   s_axis,

    /*
     * AXI4-Stream output (source)
     */
    taxi_axis_if.src   m_axis
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

// check configuration
if (m_axis.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (KEEP_EN && m_axis.KEEP_W != KEEP_W)
    $fatal(0, "Error: Interface KEEP_W parameter mismatch (instance %m)");

localparam FIFO_AW = LENGTH < 2 ? 3 : $clog2(LENGTH*4+1);

taxi_axis_if #(.DATA_W(DATA_W), .KEEP_W(KEEP_W), .ID_W(ID_W), .DEST_W(DEST_W), .USER_W(USER_W)) axis_pipe[LENGTH+1]();

for (genvar n = 0; n < LENGTH; n = n + 1) begin : stage

    (* shreg_extract = "no" *)
    logic [DATA_W-1:0]  axis_tdata_reg = 0;
    (* shreg_extract = "no" *)
    logic [KEEP_W-1:0]  axis_tkeep_reg = 0;
    (* shreg_extract = "no" *)
    logic [KEEP_W-1:0]  axis_tstrb_reg = 0;
    (* shreg_extract = "no" *)
    logic               axis_tvalid_reg = 0;
    (* shreg_extract = "no" *)
    logic               axis_tready_reg = 0;
    (* shreg_extract = "no" *)
    logic               axis_tlast_reg = 0;
    (* shreg_extract = "no" *)
    logic [ID_W-1:0]    axis_tid_reg = 0;
    (* shreg_extract = "no" *)
    logic [DEST_W-1:0]  axis_tdest_reg = 0;
    (* shreg_extract = "no" *)
    logic [USER_W-1:0]  axis_tuser_reg = 0;

    assign axis_pipe[n+1].tdata = axis_tdata_reg;
    assign axis_pipe[n+1].tkeep = axis_tkeep_reg;
    assign axis_pipe[n+1].tstrb = axis_tstrb_reg;
    assign axis_pipe[n+1].tvalid = axis_tvalid_reg;
    assign axis_pipe[n+1].tlast = axis_tlast_reg;
    assign axis_pipe[n+1].tid = axis_tid_reg;
    assign axis_pipe[n+1].tdest = axis_tdest_reg;
    assign axis_pipe[n+1].tuser = axis_tuser_reg;

    assign axis_pipe[n].tready = axis_tready_reg;

    always_ff @(posedge clk) begin
        axis_tdata_reg <= axis_pipe[n].tdata;
        axis_tkeep_reg <= axis_pipe[n].tkeep;
        axis_tstrb_reg <= axis_pipe[n].tstrb;
        axis_tvalid_reg <= axis_pipe[n].tvalid;
        axis_tlast_reg <= axis_pipe[n].tlast;
        axis_tid_reg <= axis_pipe[n].tid;
        axis_tdest_reg <= axis_pipe[n].tdest;
        axis_tuser_reg <= axis_pipe[n].tuser;

        axis_tready_reg <= axis_pipe[n+1].tready;

        if (rst) begin
            axis_tvalid_reg <= 1'b0;
            axis_tready_reg <= 1'b0;
        end
    end

end

if (LENGTH > 0) begin : fifo

    assign axis_pipe[0].tdata = s_axis.tdata;
    assign axis_pipe[0].tkeep = s_axis.tkeep;
    assign axis_pipe[0].tstrb = s_axis.tstrb;
    assign axis_pipe[0].tvalid = s_axis.tvalid & s_axis.tready;
    assign axis_pipe[0].tlast = s_axis.tlast;
    assign axis_pipe[0].tid = s_axis.tid;
    assign axis_pipe[0].tdest = s_axis.tdest;
    assign axis_pipe[0].tuser = s_axis.tuser;
    assign s_axis.tready = axis_pipe[0].tready;

    wire [DATA_W-1:0] m_axis_tdata_int = axis_pipe[LENGTH].tdata;
    wire [KEEP_W-1:0] m_axis_tkeep_int = axis_pipe[LENGTH].tkeep;
    wire [KEEP_W-1:0] m_axis_tstrb_int = axis_pipe[LENGTH].tstrb;
    wire              m_axis_tvalid_int = axis_pipe[LENGTH].tvalid;
    wire              m_axis_tready_int;
    wire              m_axis_tlast_int = axis_pipe[LENGTH].tlast;
    wire [ID_W-1:0]   m_axis_tid_int = axis_pipe[LENGTH].tid;
    wire [DEST_W-1:0] m_axis_tdest_int = axis_pipe[LENGTH].tdest;
    wire [USER_W-1:0] m_axis_tuser_int = axis_pipe[LENGTH].tuser;

    assign axis_pipe[LENGTH].tready = m_axis_tready_int;

    // output datapath logic
    logic [DATA_W-1:0] m_axis_tdata_reg  = '0;
    logic [KEEP_W-1:0] m_axis_tkeep_reg  = '0;
    logic [KEEP_W-1:0] m_axis_tstrb_reg  = '0;
    logic              m_axis_tvalid_reg = 1'b0;
    logic              m_axis_tlast_reg  = 1'b0;
    logic [ID_W-1:0]   m_axis_tid_reg    = '0;
    logic [DEST_W-1:0] m_axis_tdest_reg  = '0;
    logic [USER_W-1:0] m_axis_tuser_reg  = '0;

    logic [FIFO_AW+1-1:0] out_fifo_wr_ptr_reg = 0;
    logic [FIFO_AW+1-1:0] out_fifo_rd_ptr_reg = 0;
    logic out_fifo_half_full_reg = 1'b0;

    wire out_fifo_full = out_fifo_wr_ptr_reg == (out_fifo_rd_ptr_reg ^ {1'b1, {FIFO_AW{1'b0}}});
    wire out_fifo_empty = out_fifo_wr_ptr_reg == out_fifo_rd_ptr_reg;

    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [DATA_W-1:0] out_fifo_tdata[2**FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [KEEP_W-1:0] out_fifo_tkeep[2**FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [KEEP_W-1:0] out_fifo_tstrb[2**FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic              out_fifo_tlast[2**FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [ID_W-1:0]   out_fifo_tid[2**FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [DEST_W-1:0] out_fifo_tdest[2**FIFO_AW];
    (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
    logic [USER_W-1:0] out_fifo_tuser[2**FIFO_AW];

    assign m_axis_tready_int = !out_fifo_half_full_reg;

    assign m_axis.tdata  = m_axis_tdata_reg;
    assign m_axis.tkeep  = KEEP_EN ? m_axis_tkeep_reg : '1;
    assign m_axis.tstrb  = STRB_EN ? m_axis_tstrb_reg : m_axis.tkeep;
    assign m_axis.tvalid = m_axis_tvalid_reg;
    assign m_axis.tlast  = LAST_EN ? m_axis_tlast_reg : 1'b1;
    assign m_axis.tid    = ID_EN   ? m_axis_tid_reg   : '0;
    assign m_axis.tdest  = DEST_EN ? m_axis_tdest_reg : '0;
    assign m_axis.tuser  = USER_EN ? m_axis_tuser_reg : '0;

    always_ff @(posedge clk) begin
        m_axis_tvalid_reg <= m_axis_tvalid_reg && !m_axis.tready;

        out_fifo_half_full_reg <= $unsigned(out_fifo_wr_ptr_reg - out_fifo_rd_ptr_reg) >= 2**(FIFO_AW-1);

        if (!out_fifo_full && m_axis_tvalid_int) begin
            out_fifo_tdata[out_fifo_wr_ptr_reg[FIFO_AW-1:0]] <= m_axis_tdata_int;
            out_fifo_tkeep[out_fifo_wr_ptr_reg[FIFO_AW-1:0]] <= m_axis_tkeep_int;
            out_fifo_tstrb[out_fifo_wr_ptr_reg[FIFO_AW-1:0]] <= m_axis_tstrb_int;
            out_fifo_tlast[out_fifo_wr_ptr_reg[FIFO_AW-1:0]] <= m_axis_tlast_int;
            out_fifo_tid[out_fifo_wr_ptr_reg[FIFO_AW-1:0]] <= m_axis_tid_int;
            out_fifo_tdest[out_fifo_wr_ptr_reg[FIFO_AW-1:0]] <= m_axis_tdest_int;
            out_fifo_tuser[out_fifo_wr_ptr_reg[FIFO_AW-1:0]] <= m_axis_tuser_int;
            out_fifo_wr_ptr_reg <= out_fifo_wr_ptr_reg + 1;
        end

        if (!out_fifo_empty && (!m_axis_tvalid_reg || m_axis.tready)) begin
            m_axis_tdata_reg <= out_fifo_tdata[out_fifo_rd_ptr_reg[FIFO_AW-1:0]];
            m_axis_tkeep_reg <= out_fifo_tkeep[out_fifo_rd_ptr_reg[FIFO_AW-1:0]];
            m_axis_tstrb_reg <= out_fifo_tstrb[out_fifo_rd_ptr_reg[FIFO_AW-1:0]];
            m_axis_tvalid_reg <= 1'b1;
            m_axis_tlast_reg <= out_fifo_tlast[out_fifo_rd_ptr_reg[FIFO_AW-1:0]];
            m_axis_tid_reg <= out_fifo_tid[out_fifo_rd_ptr_reg[FIFO_AW-1:0]];
            m_axis_tdest_reg <= out_fifo_tdest[out_fifo_rd_ptr_reg[FIFO_AW-1:0]];
            m_axis_tuser_reg <= out_fifo_tuser[out_fifo_rd_ptr_reg[FIFO_AW-1:0]];
            out_fifo_rd_ptr_reg <= out_fifo_rd_ptr_reg + 1;
        end

        if (rst) begin
            out_fifo_wr_ptr_reg <= 0;
            out_fifo_rd_ptr_reg <= 0;
            m_axis_tvalid_reg <= 1'b0;
        end
    end

end else begin
    // bypass

    assign m_axis.tdata  = s_axis.tdata;
    assign m_axis.tkeep  = KEEP_EN ? s_axis.tkeep : '1;
    assign m_axis.tstrb  = STRB_EN ? s_axis.tstrb : m_axis.tkeep;
    assign m_axis.tvalid = s_axis.tvalid;
    assign m_axis.tlast  = LAST_EN ? s_axis.tlast : 1'b1;
    assign m_axis.tid    = ID_EN   ? s_axis.tid   : '0;
    assign m_axis.tdest  = DEST_EN ? s_axis.tdest : '0;
    assign m_axis.tuser  = USER_EN ? s_axis.tuser : '0;

    assign s_axis.tready = m_axis.tready;

end

endmodule

`resetall
