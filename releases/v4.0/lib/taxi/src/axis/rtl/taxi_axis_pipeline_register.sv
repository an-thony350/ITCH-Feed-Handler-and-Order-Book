// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2018-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream pipeline register
 */
module taxi_axis_pipeline_register #
(
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter REG_TYPE = 2,
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

taxi_axis_if #(
    .DATA_W(DATA_W),
    .KEEP_EN(KEEP_EN),
    .KEEP_W(KEEP_W),
    .STRB_EN(STRB_EN),
    .LAST_EN(LAST_EN),
    .ID_EN(ID_EN),
    .ID_W(ID_W),
    .DEST_EN(DEST_EN),
    .DEST_W(DEST_W),
    .USER_EN(USER_EN),
    .USER_W(USER_W)
) axis_pipe[LENGTH+1]();

assign axis_pipe[0].tdata = s_axis.tdata;
assign axis_pipe[0].tkeep = s_axis.tkeep;
assign axis_pipe[0].tstrb = s_axis.tstrb;
assign axis_pipe[0].tvalid = s_axis.tvalid;
assign s_axis.tready = axis_pipe[0].tready;
assign axis_pipe[0].tlast = s_axis.tlast;
assign axis_pipe[0].tid = s_axis.tid;
assign axis_pipe[0].tdest = s_axis.tdest;
assign axis_pipe[0].tuser = s_axis.tuser;

assign m_axis.tdata = axis_pipe[LENGTH].tdata;
assign m_axis.tkeep = axis_pipe[LENGTH].tkeep;
assign m_axis.tstrb = axis_pipe[LENGTH].tstrb;
assign m_axis.tvalid = axis_pipe[LENGTH].tvalid;
assign axis_pipe[LENGTH].tready = m_axis.tready;
assign m_axis.tlast = axis_pipe[LENGTH].tlast;
assign m_axis.tid = axis_pipe[LENGTH].tid;
assign m_axis.tdest = axis_pipe[LENGTH].tdest;
assign m_axis.tuser = axis_pipe[LENGTH].tuser;

for (genvar i = 0; i < LENGTH; i = i + 1) begin : pipe_reg

    taxi_axis_register #(
        .REG_TYPE(REG_TYPE)
    )
    reg_inst (
        .clk(clk),
        .rst(rst),

        /*
         * AXI4-Stream input (sink)
         */
        .s_axis(axis_pipe[i]),

        /*
         * AXI4-Stream output (source)
         */
        .m_axis(axis_pipe[i+1])
    );

end

endmodule

`resetall
