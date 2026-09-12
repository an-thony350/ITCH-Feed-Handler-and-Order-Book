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
 * AXI4-Stream broadcaster
 */
module taxi_axis_broadcast #
(
    // Number of AXI stream outputs
    parameter M_COUNT = 4
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * AXI4-Stream input (sink)
     */
    taxi_axis_if.snk   s_axis,

    /*
     * AXI4-Stream outputs (sources)
     */
    taxi_axis_if.src   m_axis[M_COUNT]
);

// extract parameters
localparam DATA_W = s_axis.DATA_W;
localparam logic KEEP_EN = s_axis.KEEP_EN && m_axis[0].KEEP_EN;
localparam KEEP_W = s_axis.KEEP_W;
localparam logic STRB_EN = s_axis.STRB_EN && m_axis[0].STRB_EN;
localparam logic LAST_EN = s_axis.LAST_EN && m_axis[0].LAST_EN;
localparam logic ID_EN = s_axis.ID_EN && m_axis[0].ID_EN;
localparam ID_W = s_axis.ID_W;
localparam logic DEST_EN = s_axis.DEST_EN && m_axis[0].DEST_EN;
localparam DEST_W = s_axis.DEST_W;
localparam logic USER_EN = s_axis.USER_EN && m_axis[0].USER_EN;
localparam USER_W = s_axis.USER_W;

// check configuration
if (m_axis[0].DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (KEEP_EN && m_axis[0].KEEP_W != KEEP_W)
    $fatal(0, "Error: Interface KEEP_W parameter mismatch (instance %m)");

// datapath registers
logic s_axis_tready_reg = 1'b0, s_axis_tready_next;

logic [DATA_W-1:0]   m_axis_tdata_reg  = '0;
logic [KEEP_W-1:0]   m_axis_tkeep_reg  = '0;
logic [KEEP_W-1:0]   m_axis_tstrb_reg  = '0;
logic [M_COUNT-1:0]  m_axis_tvalid_reg = '0, m_axis_tvalid_next;
logic                m_axis_tlast_reg  = 1'b0;
logic [ID_W-1:0]     m_axis_tid_reg    = '0;
logic [DEST_W-1:0]   m_axis_tdest_reg  = '0;
logic [USER_W-1:0]   m_axis_tuser_reg  = '0;

logic [DATA_W-1:0]  temp_m_axis_tdata_reg  = '0;
logic [KEEP_W-1:0]  temp_m_axis_tkeep_reg  = '0;
logic [KEEP_W-1:0]  temp_m_axis_tstrb_reg  = '0;
logic               temp_m_axis_tvalid_reg = 1'b0, temp_m_axis_tvalid_next;
logic               temp_m_axis_tlast_reg  = 1'b0;
logic [ID_W-1:0]    temp_m_axis_tid_reg    = '0;
logic [DEST_W-1:0]  temp_m_axis_tdest_reg  = '0;
logic [USER_W-1:0]  temp_m_axis_tuser_reg  = '0;

// // datapath control
logic store_axis_input_to_output;
logic store_axis_input_to_temp;
logic store_axis_temp_to_output;

assign s_axis.tready = s_axis_tready_reg;

wire [M_COUNT-1:0] m_axis_tready;
wire [M_COUNT-1:0] m_axis_tvalid;

for (genvar n = 0; n < M_COUNT; n = n + 1) begin

    assign m_axis[n].tdata  = m_axis_tdata_reg;
    assign m_axis[n].tkeep  = KEEP_EN ? m_axis_tkeep_reg : '1;
    assign m_axis[n].tstrb  = STRB_EN ? m_axis_tstrb_reg : m_axis[n].tkeep;
    assign m_axis[n].tvalid = m_axis_tvalid_reg[n];
    assign m_axis[n].tlast  = LAST_EN ? m_axis_tlast_reg : 1'b1;
    assign m_axis[n].tid    = ID_EN   ? m_axis_tid_reg   : '0;
    assign m_axis[n].tdest  = DEST_EN ? m_axis_tdest_reg : '0;
    assign m_axis[n].tuser  = USER_EN ? m_axis_tuser_reg : '0;

    assign m_axis_tready[n] = m_axis[n].tready;
    assign m_axis_tvalid[n] = m_axis[n].tvalid;

end

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
wire s_axis_tready_early = ((m_axis_tready & m_axis_tvalid) == m_axis_tvalid) || (!temp_m_axis_tvalid_reg && (m_axis_tvalid == 0 || !s_axis.tvalid));

always_comb begin
    // transfer sink ready state to source
    m_axis_tvalid_next = m_axis_tvalid_reg & ~m_axis_tready;
    temp_m_axis_tvalid_next = temp_m_axis_tvalid_reg;

    store_axis_input_to_output = 1'b0;
    store_axis_input_to_temp = 1'b0;
    store_axis_temp_to_output = 1'b0;

    if (s_axis_tready_reg) begin
        // input is ready
        if (((m_axis_tready & m_axis_tvalid) == m_axis_tvalid) || m_axis_tvalid == 0) begin
            // output is ready or currently not valid, transfer data to output
            m_axis_tvalid_next = {M_COUNT{s_axis.tvalid}};
            store_axis_input_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_axis_tvalid_next = s_axis.tvalid;
            store_axis_input_to_temp = 1'b1;
        end
    end else if ((m_axis_tready & m_axis_tvalid) == m_axis_tvalid) begin
        // input is not ready, but output is ready
        m_axis_tvalid_next = {M_COUNT{temp_m_axis_tvalid_reg}};
        temp_m_axis_tvalid_next = 1'b0;
        store_axis_temp_to_output = 1'b1;
    end
end

always_ff @(posedge clk) begin
    s_axis_tready_reg <= s_axis_tready_early;
    m_axis_tvalid_reg <= m_axis_tvalid_next;
    temp_m_axis_tvalid_reg <= temp_m_axis_tvalid_next;

    // datapath
    if (store_axis_input_to_output) begin
        m_axis_tdata_reg <= s_axis.tdata;
        m_axis_tkeep_reg <= s_axis.tkeep;
        m_axis_tstrb_reg <= s_axis.tstrb;
        m_axis_tlast_reg <= s_axis.tlast;
        m_axis_tid_reg   <= s_axis.tid;
        m_axis_tdest_reg <= s_axis.tdest;
        m_axis_tuser_reg <= s_axis.tuser;
    end else if (store_axis_temp_to_output) begin
        m_axis_tdata_reg <= temp_m_axis_tdata_reg;
        m_axis_tkeep_reg <= temp_m_axis_tkeep_reg;
        m_axis_tstrb_reg <= temp_m_axis_tstrb_reg;
        m_axis_tlast_reg <= temp_m_axis_tlast_reg;
        m_axis_tid_reg   <= temp_m_axis_tid_reg;
        m_axis_tdest_reg <= temp_m_axis_tdest_reg;
        m_axis_tuser_reg <= temp_m_axis_tuser_reg;
    end

    if (store_axis_input_to_temp) begin
        temp_m_axis_tdata_reg <= s_axis.tdata;
        temp_m_axis_tkeep_reg <= s_axis.tkeep;
        temp_m_axis_tstrb_reg <= s_axis.tstrb;
        temp_m_axis_tlast_reg <= s_axis.tlast;
        temp_m_axis_tid_reg   <= s_axis.tid;
        temp_m_axis_tdest_reg <= s_axis.tdest;
        temp_m_axis_tuser_reg <= s_axis.tuser;
    end

    if (rst) begin
        s_axis_tready_reg <= 1'b0;
        m_axis_tvalid_reg <= '0;
        temp_m_axis_tvalid_reg <= '0;
    end
end

endmodule

`resetall
