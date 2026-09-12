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
 * AXI4-Stream bus width adapter
 */
module taxi_axis_adapter
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
localparam S_DATA_W = s_axis.DATA_W;
localparam logic S_KEEP_EN = s_axis.KEEP_EN;
localparam S_KEEP_W = s_axis.KEEP_W;
localparam logic STRB_EN = s_axis.STRB_EN && m_axis.STRB_EN;
localparam logic LAST_EN = s_axis.LAST_EN;
localparam logic ID_EN = s_axis.ID_EN && m_axis.ID_EN;
localparam ID_W = s_axis.ID_W;
localparam logic DEST_EN = s_axis.DEST_EN && m_axis.DEST_EN;
localparam DEST_W = s_axis.DEST_W;
localparam logic USER_EN = s_axis.USER_EN && m_axis.USER_EN;
localparam USER_W = s_axis.USER_W;

localparam M_DATA_W = m_axis.DATA_W;
localparam logic M_KEEP_EN = m_axis.KEEP_EN;
localparam M_KEEP_W = m_axis.KEEP_W;

// force keep width to 1 when disabled
localparam S_BYTE_LANES = S_KEEP_EN ? S_KEEP_W : 1;
localparam M_BYTE_LANES = M_KEEP_EN ? M_KEEP_W : 1;

// bus byte sizes (must be identical)
localparam S_BYTE_SIZE = S_DATA_W / S_BYTE_LANES;
localparam M_BYTE_SIZE = M_DATA_W / M_BYTE_LANES;

// check configuration
if (S_BYTE_SIZE * S_BYTE_LANES != S_DATA_W)
    $fatal(0, "Error: input data width not evenly divisible (instance %m)");

if (M_BYTE_SIZE * M_BYTE_LANES != M_DATA_W)
    $fatal(0, "Error: output data width not evenly divisible (instance %m)");

if (S_BYTE_SIZE != M_BYTE_SIZE)
    $fatal(0, "Error: byte size mismatch (instance %m)");

wire [S_KEEP_W-1:0] s_axis_tkeep_int = S_KEEP_EN ? s_axis.tkeep : '1;

if (M_BYTE_LANES == S_BYTE_LANES) begin : bypass
    // same width; bypass

    assign s_axis.tready = m_axis.tready;

    assign m_axis.tdata  = s_axis.tdata;
    assign m_axis.tkeep  = (M_KEEP_EN && S_KEEP_EN) ? s_axis.tkeep : '1;
    assign m_axis.tstrb  = STRB_EN ? s_axis.tstrb : m_axis.tkeep;
    assign m_axis.tvalid = s_axis.tvalid;
    assign m_axis.tlast  = LAST_EN ? s_axis.tlast : 1'b1;
    assign m_axis.tid    = ID_EN   ? s_axis.tid   : '0;
    assign m_axis.tdest  = DEST_EN ? s_axis.tdest : '0;
    assign m_axis.tuser  = USER_EN ? s_axis.tuser : '0;

end else if (M_BYTE_LANES > S_BYTE_LANES) begin : upsize
    // output is wider; upsize

    // required number of segments in wider bus
    localparam SEG_COUNT = M_BYTE_LANES / S_BYTE_LANES;
    // data width and keep width per segment
    localparam SEG_DATA_W = M_DATA_W / SEG_COUNT;
    localparam SEG_KEEP_W = M_BYTE_LANES / SEG_COUNT;

    localparam CL_SEG_COUNT = $clog2(SEG_COUNT);

    logic [CL_SEG_COUNT-1:0] seg_reg = '0;

    logic [S_DATA_W-1:0] s_axis_tdata_reg = '0;
    logic [S_KEEP_W-1:0] s_axis_tkeep_reg = '0;
    logic [S_KEEP_W-1:0] s_axis_tstrb_reg = '0;
    logic s_axis_tvalid_reg = 1'b0;
    logic s_axis_tlast_reg = 1'b0;
    logic [ID_W-1:0] s_axis_tid_reg = '0;
    logic [DEST_W-1:0] s_axis_tdest_reg = '0;
    logic [USER_W-1:0] s_axis_tuser_reg = '0;

    logic [M_DATA_W-1:0] m_axis_tdata_reg = '0;
    logic [M_KEEP_W-1:0] m_axis_tkeep_reg = '0;
    logic [M_KEEP_W-1:0] m_axis_tstrb_reg = '0;
    logic m_axis_tvalid_reg = 1'b0;
    logic m_axis_tlast_reg = 1'b0;
    logic [ID_W-1:0] m_axis_tid_reg = '0;
    logic [DEST_W-1:0] m_axis_tdest_reg = '0;
    logic [USER_W-1:0] m_axis_tuser_reg = '0;

    assign s_axis.tready = !s_axis_tvalid_reg;

    assign m_axis.tdata  = m_axis_tdata_reg;
    assign m_axis.tkeep  = M_KEEP_EN ? m_axis_tkeep_reg : '1;
    assign m_axis.tstrb  = STRB_EN ? m_axis_tstrb_reg : m_axis.tkeep;
    assign m_axis.tvalid = m_axis_tvalid_reg;
    assign m_axis.tlast  = LAST_EN ? m_axis_tlast_reg : 1'b1;
    assign m_axis.tid    = ID_EN   ? m_axis_tid_reg   : '0;
    assign m_axis.tdest  = DEST_EN ? m_axis_tdest_reg : '0;
    assign m_axis.tuser  = USER_EN ? m_axis_tuser_reg : '0;

    always_ff @(posedge clk) begin
        m_axis_tvalid_reg <= m_axis_tvalid_reg && !m_axis.tready;

        if (!m_axis_tvalid_reg || m_axis.tready) begin
            // output register empty

            if (seg_reg == 0) begin
                m_axis_tdata_reg[seg_reg*SEG_DATA_W +: SEG_DATA_W] <= s_axis_tvalid_reg ? s_axis_tdata_reg : s_axis.tdata;
                m_axis_tkeep_reg <= M_KEEP_W'(s_axis_tvalid_reg ? s_axis_tkeep_reg : s_axis_tkeep_int);
                m_axis_tstrb_reg <= M_KEEP_W'(s_axis_tvalid_reg ? s_axis_tstrb_reg : s_axis.tstrb);
            end else begin
                m_axis_tdata_reg[seg_reg*SEG_DATA_W +: SEG_DATA_W] <= s_axis.tdata;
                m_axis_tkeep_reg[seg_reg*SEG_KEEP_W +: SEG_KEEP_W] <= s_axis_tkeep_int;
                m_axis_tstrb_reg[seg_reg*SEG_KEEP_W +: SEG_KEEP_W] <= s_axis.tstrb;
            end
            m_axis_tlast_reg <= s_axis_tvalid_reg ? s_axis_tlast_reg : s_axis.tlast;
            m_axis_tid_reg <= s_axis_tvalid_reg ? s_axis_tid_reg : s_axis.tid;
            m_axis_tdest_reg <= s_axis_tvalid_reg ? s_axis_tdest_reg : s_axis.tdest;
            m_axis_tuser_reg <= s_axis_tvalid_reg ? s_axis_tuser_reg : s_axis.tuser;

            if (s_axis_tvalid_reg) begin
                // consume data from buffer
                s_axis_tvalid_reg <= 1'b0;

                if ((LAST_EN && s_axis_tlast_reg) || seg_reg == CL_SEG_COUNT'(SEG_COUNT-1)) begin
                    seg_reg <= '0;
                    m_axis_tvalid_reg <= 1'b1;
                end else begin
                    seg_reg <= seg_reg + 1;
                end
            end else if (s_axis.tvalid) begin
                // data direct from input
                if ((LAST_EN && s_axis.tlast) || seg_reg == CL_SEG_COUNT'(SEG_COUNT-1)) begin
                    seg_reg <= '0;
                    m_axis_tvalid_reg <= 1'b1;
                end else begin
                    seg_reg <= seg_reg + 1;
                end
            end
        end else if (s_axis.tvalid && s_axis.tready) begin
            // store input data in skid buffer
            s_axis_tdata_reg <= s_axis.tdata;
            s_axis_tkeep_reg <= s_axis_tkeep_int;
            s_axis_tstrb_reg <= s_axis.tstrb;
            s_axis_tvalid_reg <= 1'b1;
            s_axis_tlast_reg <= s_axis.tlast;
            s_axis_tid_reg <= s_axis.tid;
            s_axis_tdest_reg <= s_axis.tdest;
            s_axis_tuser_reg <= s_axis.tuser;
        end

        if (rst) begin
            seg_reg <= '0;
            s_axis_tvalid_reg <= 1'b0;
            m_axis_tvalid_reg <= 1'b0;
        end
    end

end else begin : downsize
    // output is narrower; downsize

    // required number of segments in wider bus
    localparam SEG_COUNT = S_BYTE_LANES / M_BYTE_LANES;
    // data width and keep width per segment
    localparam SEG_DATA_W = S_DATA_W / SEG_COUNT;
    localparam SEG_KEEP_W = S_BYTE_LANES / SEG_COUNT;

    logic [S_DATA_W-1:0] s_axis_tdata_reg = '0;
    logic [S_KEEP_W-1:0] s_axis_tkeep_reg = '0;
    logic [S_KEEP_W-1:0] s_axis_tstrb_reg = '0;
    logic s_axis_tvalid_reg = 1'b0;
    logic s_axis_tlast_reg = 1'b0;
    logic [ID_W-1:0] s_axis_tid_reg = '0;
    logic [DEST_W-1:0] s_axis_tdest_reg = '0;
    logic [USER_W-1:0] s_axis_tuser_reg = '0;

    logic [M_DATA_W-1:0] m_axis_tdata_reg = '0;
    logic [M_KEEP_W-1:0] m_axis_tkeep_reg = '0;
    logic [M_KEEP_W-1:0] m_axis_tstrb_reg = '0;
    logic m_axis_tvalid_reg = 1'b0;
    logic m_axis_tlast_reg = 1'b0;
    logic [ID_W-1:0] m_axis_tid_reg = '0;
    logic [DEST_W-1:0] m_axis_tdest_reg = '0;
    logic [USER_W-1:0] m_axis_tuser_reg = '0;

    assign s_axis.tready = !s_axis_tvalid_reg;

    assign m_axis.tdata  = m_axis_tdata_reg;
    assign m_axis.tkeep  = M_KEEP_EN ? m_axis_tkeep_reg : '1;
    assign m_axis.tstrb  = STRB_EN ? m_axis_tstrb_reg : m_axis.tkeep;
    assign m_axis.tvalid = m_axis_tvalid_reg;
    assign m_axis.tlast  = m_axis_tlast_reg;
    assign m_axis.tid    = ID_EN   ? m_axis_tid_reg   : '0;
    assign m_axis.tdest  = DEST_EN ? m_axis_tdest_reg : '0;
    assign m_axis.tuser  = USER_EN ? m_axis_tuser_reg : '0;

    always_ff @(posedge clk) begin
        m_axis_tvalid_reg <= m_axis_tvalid_reg && !m_axis.tready;

        if (!m_axis_tvalid_reg || m_axis.tready) begin
            // output register empty

            m_axis_tdata_reg <= M_DATA_W'(s_axis_tvalid_reg ? s_axis_tdata_reg : s_axis.tdata);
            m_axis_tkeep_reg <= M_KEEP_W'(s_axis_tvalid_reg ? s_axis_tkeep_reg : s_axis_tkeep_int);
            m_axis_tstrb_reg <= M_KEEP_W'(s_axis_tvalid_reg ? s_axis_tstrb_reg : s_axis.tstrb);
            m_axis_tlast_reg <= 1'b0;
            m_axis_tid_reg <= s_axis_tvalid_reg ? s_axis_tid_reg : s_axis.tid;
            m_axis_tdest_reg <= s_axis_tvalid_reg ? s_axis_tdest_reg : s_axis.tdest;
            m_axis_tuser_reg <= s_axis_tvalid_reg ? s_axis_tuser_reg : s_axis.tuser;

            if (s_axis_tvalid_reg) begin
                // buffer has data; shift out from buffer
                s_axis_tdata_reg <= s_axis_tdata_reg >> SEG_DATA_W;
                s_axis_tkeep_reg <= s_axis_tkeep_reg >> SEG_KEEP_W;
                s_axis_tstrb_reg <= s_axis_tstrb_reg >> SEG_KEEP_W;

                m_axis_tvalid_reg <= 1'b1;

                if ((s_axis_tkeep_reg >> SEG_KEEP_W) == 0) begin
                    s_axis_tvalid_reg <= 1'b0;
                    m_axis_tlast_reg <= s_axis_tlast_reg;
                end
            end else if (s_axis.tvalid && s_axis.tready) begin
                // buffer is empty; store from input
                s_axis_tdata_reg <= s_axis.tdata >> SEG_DATA_W;
                s_axis_tkeep_reg <= s_axis_tkeep_int >> SEG_KEEP_W;
                s_axis_tstrb_reg <= s_axis.tstrb >> SEG_KEEP_W;
                s_axis_tlast_reg <= s_axis.tlast;
                s_axis_tid_reg <= s_axis.tid;
                s_axis_tdest_reg <= s_axis.tdest;
                s_axis_tuser_reg <= s_axis.tuser;

                m_axis_tvalid_reg <= 1'b1;

                if (S_KEEP_EN && (s_axis_tkeep_int >> SEG_KEEP_W) == 0) begin
                    s_axis_tvalid_reg <= 1'b0;
                    m_axis_tlast_reg <= s_axis.tlast;
                end else begin
                    s_axis_tvalid_reg <= 1'b1;
                end
            end
        end else if (s_axis.tvalid && s_axis.tready) begin
            // store input data
            s_axis_tdata_reg <= s_axis.tdata;
            s_axis_tkeep_reg <= s_axis_tkeep_int;
            s_axis_tstrb_reg <= s_axis.tstrb;
            s_axis_tvalid_reg <= 1'b1;
            s_axis_tlast_reg <= s_axis.tlast;
            s_axis_tid_reg <= s_axis.tid;
            s_axis_tdest_reg <= s_axis.tdest;
            s_axis_tuser_reg <= s_axis.tuser;
        end

        if (rst) begin
            s_axis_tvalid_reg <= 1'b0;
            m_axis_tvalid_reg <= 1'b0;
        end
    end

end

endmodule

`resetall
