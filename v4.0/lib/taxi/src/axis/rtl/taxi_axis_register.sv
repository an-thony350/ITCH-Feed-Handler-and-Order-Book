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
 * AXI4-Stream register
 */
module taxi_axis_register #
(
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter REG_TYPE = 2
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

if (REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic              s_axis_tready_reg = 1'b0;

    logic [DATA_W-1:0] m_axis_tdata_reg  = '0;
    logic [KEEP_W-1:0] m_axis_tkeep_reg  = '0;
    logic [KEEP_W-1:0] m_axis_tstrb_reg  = '0;
    logic              m_axis_tvalid_reg = 1'b0, m_axis_tvalid_next;
    logic              m_axis_tlast_reg  = 1'b0;
    logic [ID_W-1:0]   m_axis_tid_reg    = '0;
    logic [DEST_W-1:0] m_axis_tdest_reg  = '0;
    logic [USER_W-1:0] m_axis_tuser_reg  = '0;

    logic [DATA_W-1:0] temp_m_axis_tdata_reg  = '0;
    logic [KEEP_W-1:0] temp_m_axis_tkeep_reg  = '0;
    logic [KEEP_W-1:0] temp_m_axis_tstrb_reg  = '0;
    logic              temp_m_axis_tvalid_reg = 1'b0, temp_m_axis_tvalid_next;
    logic              temp_m_axis_tlast_reg  = 1'b0;
    logic [ID_W-1:0]   temp_m_axis_tid_reg    = '0;
    logic [DEST_W-1:0] temp_m_axis_tdest_reg  = '0;
    logic [USER_W-1:0] temp_m_axis_tuser_reg  = '0;

    // datapath control
    logic store_axis_input_to_output;
    logic store_axis_input_to_temp;
    logic store_axis_temp_to_output;

    assign s_axis.tready = s_axis_tready_reg;

    assign m_axis.tdata  = m_axis_tdata_reg;
    assign m_axis.tkeep  = KEEP_EN ? m_axis_tkeep_reg : '1;
    assign m_axis.tstrb  = STRB_EN ? m_axis_tstrb_reg : s_axis.tkeep;
    assign m_axis.tvalid = m_axis_tvalid_reg;
    assign m_axis.tlast  = LAST_EN ? m_axis_tlast_reg : 1'b1;
    assign m_axis.tid    = ID_EN   ? m_axis_tid_reg   : '0;
    assign m_axis.tdest  = DEST_EN ? m_axis_tdest_reg : '0;
    assign m_axis.tuser  = USER_EN ? m_axis_tuser_reg : '0;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire s_axis_tready_early = m_axis.tready || (!temp_m_axis_tvalid_reg && (!m_axis_tvalid_reg || !s_axis.tvalid));

    always_comb begin
        // transfer sink ready state to source
        m_axis_tvalid_next = m_axis_tvalid_reg;
        temp_m_axis_tvalid_next = temp_m_axis_tvalid_reg;

        store_axis_input_to_output = 1'b0;
        store_axis_input_to_temp = 1'b0;
        store_axis_temp_to_output = 1'b0;

        if (s_axis_tready_reg) begin
            // input is ready
            if (m_axis.tready || !m_axis_tvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                m_axis_tvalid_next = s_axis.tvalid;
                store_axis_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_m_axis_tvalid_next = s_axis.tvalid;
                store_axis_input_to_temp = 1'b1;
            end
        end else if (m_axis.tready) begin
            // input is not ready, but output is ready
            m_axis_tvalid_next = temp_m_axis_tvalid_reg;
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
            m_axis_tvalid_reg <= 1'b0;
            temp_m_axis_tvalid_reg <= 1'b0;
        end
    end

end else if (REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic              s_axis_tready_reg = 1'b0;

    logic [DATA_W-1:0] m_axis_tdata_reg  = '0;
    logic [KEEP_W-1:0] m_axis_tkeep_reg  = '0;
    logic [KEEP_W-1:0] m_axis_tstrb_reg  = '0;
    logic              m_axis_tvalid_reg = 1'b0, m_axis_tvalid_next;
    logic              m_axis_tlast_reg  = 1'b0;
    logic [ID_W-1:0]   m_axis_tid_reg    = '0;
    logic [DEST_W-1:0] m_axis_tdest_reg  = '0;
    logic [USER_W-1:0] m_axis_tuser_reg  = '0;

    // datapath control
    logic store_axis_input_to_output;

    assign s_axis.tready = s_axis_tready_reg;

    assign m_axis.tdata  = m_axis_tdata_reg;
    assign m_axis.tkeep  = KEEP_EN ? m_axis_tkeep_reg : '1;
    assign m_axis.tstrb  = STRB_EN ? s_axis.tstrb : s_axis.tkeep;
    assign m_axis.tvalid = m_axis_tvalid_reg;
    assign m_axis.tlast  = LAST_EN ? m_axis_tlast_reg : 1'b1;
    assign m_axis.tid    = ID_EN   ? m_axis_tid_reg   : '0;
    assign m_axis.tdest  = DEST_EN ? m_axis_tdest_reg : '0;
    assign m_axis.tuser  = USER_EN ? m_axis_tuser_reg : '0;

    // enable ready input next cycle if output buffer will be empty
    wire s_axis_tready_early = !m_axis_tvalid_next;

    always_comb begin
        // transfer sink ready state to source
        m_axis_tvalid_next = m_axis_tvalid_reg;

        store_axis_input_to_output = 1'b0;

        if (s_axis_tready_reg) begin
            m_axis_tvalid_next = s_axis.tvalid;
            store_axis_input_to_output = 1'b1;
        end else if (m_axis.tready) begin
            m_axis_tvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        s_axis_tready_reg <= s_axis_tready_early;
        m_axis_tvalid_reg <= m_axis_tvalid_next;

        // datapath
        if (store_axis_input_to_output) begin
            m_axis_tdata_reg <= s_axis.tdata;
            m_axis_tkeep_reg <= s_axis.tkeep;
            m_axis_tstrb_reg <= s_axis.tstrb;
            m_axis_tlast_reg <= s_axis.tlast;
            m_axis_tid_reg   <= s_axis.tid;
            m_axis_tdest_reg <= s_axis.tdest;
            m_axis_tuser_reg <= s_axis.tuser;
        end

        if (rst) begin
            s_axis_tready_reg <= 1'b0;
            m_axis_tvalid_reg <= 1'b0;
        end
    end

end else begin
    // bypass

    assign m_axis.tdata  = s_axis.tdata;
    assign m_axis.tkeep  = KEEP_EN ? s_axis.tkeep : '1;
    assign m_axis.tstrb  = STRB_EN ? s_axis.tstrb : s_axis.tkeep;
    assign m_axis.tvalid = s_axis.tvalid;
    assign m_axis.tlast  = LAST_EN ? s_axis.tlast : 1'b1;
    assign m_axis.tid    = ID_EN   ? s_axis.tid   : '0;
    assign m_axis.tdest  = DEST_EN ? s_axis.tdest : '0;
    assign m_axis.tuser  = USER_EN ? s_axis.tuser : '0;

    assign s_axis.tready = m_axis.tready;

end

endmodule

`resetall
