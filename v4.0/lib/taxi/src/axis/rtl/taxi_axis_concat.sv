// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream frame concatenator
 */
module taxi_axis_concat #
(
    // Number of AXI stream inputs
    parameter S_COUNT = 4
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * AXI4-Stream inputs (sinks)
     */
    taxi_axis_if.snk   s_axis[S_COUNT],

    /*
     * AXI4-Stream output (source)
     */
    taxi_axis_if.src   m_axis
);

// extract parameters
localparam DATA_W = s_axis[0].DATA_W;
localparam logic KEEP_EN = s_axis[0].KEEP_EN && m_axis.KEEP_EN;
localparam KEEP_W = s_axis[0].KEEP_W;
localparam logic STRB_EN = s_axis[0].STRB_EN && m_axis.STRB_EN;
localparam logic LAST_EN = s_axis[0].LAST_EN && m_axis.LAST_EN;
localparam logic ID_EN = s_axis[0].ID_EN && m_axis.ID_EN;
localparam ID_W = s_axis[0].ID_W;
localparam logic DEST_EN = s_axis[0].DEST_EN && m_axis.DEST_EN;
localparam DEST_W = s_axis[0].DEST_W;
localparam logic USER_EN = s_axis[0].USER_EN && m_axis.USER_EN;
localparam USER_W = s_axis[0].USER_W;

localparam BYTE_LANES = KEEP_EN ? KEEP_W : 1;
localparam BYTE_SIZE = DATA_W / BYTE_LANES;

localparam CL_S_COUNT = $clog2(S_COUNT);
localparam CL_BYTE_LANES = $clog2(BYTE_LANES);

// check configuration
if (m_axis.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (KEEP_EN && m_axis.KEEP_W != KEEP_W)
    $fatal(0, "Error: Interface KEEP_W parameter mismatch (instance %m)");

if (BYTE_SIZE * BYTE_LANES != DATA_W)
    $fatal(0, "Error: input data width not evenly divisible (instance %m)");

// internal datapath
logic [DATA_W-1:0]  m_axis_tdata_int;
logic [KEEP_W-1:0]  m_axis_tkeep_int;
logic [KEEP_W-1:0]  m_axis_tstrb_int;
logic               m_axis_tvalid_int;
logic               m_axis_tready_int_reg = 1'b0;
logic               m_axis_tlast_int;
logic [ID_W-1:0]    m_axis_tid_int;
logic [DEST_W-1:0]  m_axis_tdest_int;
logic [USER_W-1:0]  m_axis_tuser_int;
wire                m_axis_tready_int_early;

if (S_COUNT == 1) begin
    // degenerate case

    assign s_axis[0].tready = m_axis_tready_int_reg;

    always_comb begin
        // pass through selected packet data
        m_axis_tdata_int  = s_axis[0].tdata;
        m_axis_tkeep_int  = s_axis[0].tkeep;
        m_axis_tstrb_int  = s_axis[0].tstrb;
        m_axis_tvalid_int = s_axis[0].tvalid && m_axis_tready_int_reg;
        m_axis_tlast_int  = s_axis[0].tlast;
        m_axis_tid_int    = s_axis[0].tid;
        m_axis_tdest_int  = s_axis[0].tdest;
        m_axis_tuser_int  = s_axis[0].tuser;
    end

end else begin

    logic output_ready;

    // unpack interface array
    wire [DATA_W-1:0]   s_axis_tdata[S_COUNT];
    wire [KEEP_W-1:0]   s_axis_tkeep[S_COUNT];
    wire [KEEP_W-1:0]   s_axis_tstrb[S_COUNT];
    wire [S_COUNT-1:0]  s_axis_tvalid;
    wire [S_COUNT-1:0]  s_axis_tready;
    wire [S_COUNT-1:0]  s_axis_tlast;
    wire [ID_W-1:0]     s_axis_tid[S_COUNT];
    wire [DEST_W-1:0]   s_axis_tdest[S_COUNT];
    wire [USER_W-1:0]   s_axis_tuser[S_COUNT];

    for (genvar n = 0; n < S_COUNT; n = n + 1) begin
        assign s_axis_tdata[n] = s_axis[n].tdata;
        assign s_axis_tkeep[n] = s_axis[n].tkeep;
        assign s_axis_tstrb[n] = s_axis[n].tstrb;
        assign s_axis_tvalid[n] = s_axis[n].tvalid;
        assign s_axis[n].tready = s_axis_tready[n];
        assign s_axis_tlast[n] = s_axis[n].tlast;
        assign s_axis_tid[n] = s_axis[n].tid;
        assign s_axis_tdest[n] = s_axis[n].tdest;
        assign s_axis_tuser[n] = s_axis[n].tuser;
    end

    // destripe
    logic [CL_S_COUNT-1:0] select_reg = '0, select_next;

    logic [S_COUNT-1:0] s_axis_tready_reg = 0, s_axis_tready_next;

    assign s_axis_tready = s_axis_tready_reg;

    // mux for incoming packet
    wire [DATA_W-1:0]  current_s_tdata  = s_axis_tdata[select_reg];
    wire [KEEP_W-1:0]  current_s_tkeep  = s_axis_tkeep[select_reg];
    wire [KEEP_W-1:0]  current_s_tstrb  = s_axis_tstrb[select_reg];
    wire               current_s_tvalid = s_axis_tvalid[select_reg];
    wire               current_s_tready = s_axis_tready != 0;
    wire               current_s_tlast  = s_axis_tlast[select_reg];
    wire [ID_W-1:0]    current_s_tid    = s_axis_tid[select_reg];
    wire [DEST_W-1:0]  current_s_tdest  = s_axis_tdest[select_reg];
    wire [USER_W-1:0]  current_s_tuser  = s_axis_tuser[select_reg];

    always_comb begin
        select_next = select_reg;

        s_axis_tready_next = '0;

        if (current_s_tvalid && current_s_tready) begin
            // move to next piece at end of frame
            if (current_s_tlast) begin
                if (select_reg < CL_S_COUNT'(S_COUNT-1)) begin
                    select_next = select_reg + 1;
                end else begin
                    select_next = '0;
                end
            end
        end

        // generate ready signal on selected port
        s_axis_tready_next[select_next] = m_axis_tready_int_early && output_ready;
    end

    always_ff @(posedge clk) begin
        select_reg <= select_next;
        s_axis_tready_reg <= s_axis_tready_next;

        if (rst) begin
            select_reg <= '0;
            s_axis_tready_reg <= '0;
        end
    end

    if (!KEEP_EN || BYTE_LANES == 1) begin
        // degenerate case

        assign output_ready = 1'b1;

        always_comb begin
            m_axis_tdata_int  = current_s_tdata;
            m_axis_tkeep_int  = current_s_tkeep;
            m_axis_tstrb_int  = current_s_tstrb;
            m_axis_tvalid_int = current_s_tvalid && current_s_tready;
            m_axis_tlast_int  = current_s_tlast && select_reg == CL_S_COUNT'(S_COUNT-1);
            m_axis_tid_int    = current_s_tid;
            m_axis_tdest_int  = current_s_tdest;
            m_axis_tuser_int  = current_s_tuser;
        end
    end else begin
        // repack

        logic [2*DATA_W-1:0]  tdata_reg = '0, tdata_next;
        logic [2*KEEP_W-1:0]  tkeep_reg = '0, tkeep_next;
        logic [2*KEEP_W-1:0]  tstrb_reg = '0, tstrb_next;
        logic [1:0]           tvalid_reg = '0, tvalid_next;
        logic [1:0]           tlast_reg = '0, tlast_next;
        logic [ID_W-1:0]      tid_reg = '0, tid_next;
        logic [DEST_W-1:0]    tdest_reg = '0, tdest_next;
        logic [USER_W-1:0]    tuser_reg = '0, tuser_next;

        logic [CL_BYTE_LANES-1:0] offset_reg = '0, offset_next;

        logic [CL_BYTE_LANES+1-1:0] current_byte_count;

        always_comb begin
            current_byte_count = '0;
            for (integer k = 0; k < KEEP_W; k = k + 1) begin
                if (current_s_tkeep[k]) begin
                    current_byte_count = (CL_BYTE_LANES+1)'(k+1);
                end
            end
        end

        always_comb begin
            tdata_next = tdata_reg;
            tkeep_next = tkeep_reg;
            tstrb_next = tstrb_reg;
            tvalid_next = tvalid_reg;
            tlast_next = tlast_reg;
            tid_next = tid_reg;
            tdest_next = tdest_reg;
            tuser_next = tuser_reg;

            offset_next = offset_reg;

            m_axis_tdata_int  = tdata_reg[0 +: DATA_W];
            m_axis_tkeep_int  = tkeep_reg[0 +: KEEP_W];
            m_axis_tstrb_int  = tstrb_reg[0 +: KEEP_W];
            m_axis_tvalid_int = 1'b0;
            m_axis_tlast_int  = tlast_reg[0];
            m_axis_tid_int    = tid_reg;
            m_axis_tdest_int  = tdest_reg;
            m_axis_tuser_int  = tuser_reg;

            output_ready = !tlast_reg[1] || m_axis_tready_int_reg;

            if (m_axis_tready_int_reg && (tkeep_reg[KEEP_W-1] || tlast_reg[0])) begin
                // shift out full words
                tdata_next[0 +: DATA_W] = tdata_reg[DATA_W +: DATA_W];
                tkeep_next = {{KEEP_W{1'b0}}, tkeep_reg[KEEP_W +: KEEP_W]};
                tstrb_next = {{KEEP_W{1'b0}}, tstrb_reg[KEEP_W +: KEEP_W]};
                tvalid_next = {1'b0, tvalid_reg[1]};
                tlast_next = {1'b0, tlast_reg[1]};

                m_axis_tvalid_int = 1'b1;
            end

            if (current_s_tvalid && current_s_tready) begin
                // store data with offset
                tdata_next[offset_reg*BYTE_SIZE +: DATA_W] = current_s_tdata;
                tkeep_next[offset_reg*1 +: KEEP_W] = current_s_tkeep;
                tstrb_next[offset_reg*1 +: KEEP_W] = current_s_tstrb;
                tvalid_next[0] = 1'b1;
                tid_next = current_s_tid;
                tdest_next = current_s_tdest;
                tuser_next = current_s_tuser;

                // compute new offset (natural wrapping)
                offset_next = offset_reg + CL_BYTE_LANES'(current_byte_count);

                if (tkeep_next[KEEP_W +: KEEP_W] != 0) begin
                    // wrapped to higher word
                    tvalid_next[1] = 1'b1;
                end

                if (current_s_tlast && select_reg == CL_S_COUNT'(S_COUNT-1)) begin
                    // end of frame
                    offset_next = '0;
                    if (tkeep_next[KEEP_W +: KEEP_W] != 0) begin
                        tvalid_next[0] = 1'b1;
                        tvalid_next[1] = 1'b1;
                        tlast_next[1] = 1'b1;
                        output_ready = 1'b0;
                    end else begin
                        tvalid_next[0] = 1'b1;
                        tlast_next[0] = 1'b1;
                    end
                end
            end
        end

        always_ff @(posedge clk) begin
            tdata_reg <= tdata_next;
            tkeep_reg <= tkeep_next;
            tstrb_reg <= tstrb_next;
            tvalid_reg <= tvalid_next;
            tlast_reg <= tlast_next;
            tid_reg <= tid_next;
            tdest_reg <= tdest_next;
            tuser_reg <= tuser_next;

            offset_reg <= offset_next;

            if (rst) begin
                tvalid_reg <= '0;
                offset_reg <= '0;
            end
        end
    end

end

// output datapath logic
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
logic store_axis_int_to_output;
logic store_axis_int_to_temp;
logic store_axis_temp_to_output;

assign m_axis.tdata  = m_axis_tdata_reg;
assign m_axis.tkeep  = KEEP_EN ? m_axis_tkeep_reg : '1;
assign m_axis.tstrb  = STRB_EN ? m_axis_tstrb_reg : m_axis.tkeep;
assign m_axis.tvalid = m_axis_tvalid_reg;
assign m_axis.tlast  = LAST_EN ? m_axis_tlast_reg : 1'b1;
assign m_axis.tid    = ID_EN   ? m_axis_tid_reg   : '0;
assign m_axis.tdest  = DEST_EN ? m_axis_tdest_reg : '0;
assign m_axis.tuser  = USER_EN ? m_axis_tuser_reg : '0;

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
assign m_axis_tready_int_early = m_axis.tready || (!temp_m_axis_tvalid_reg && (!m_axis_tvalid_reg || !m_axis_tvalid_int));

always_comb begin
    // transfer sink ready state to source
    m_axis_tvalid_next = m_axis_tvalid_reg;
    temp_m_axis_tvalid_next = temp_m_axis_tvalid_reg;

    store_axis_int_to_output = 1'b0;
    store_axis_int_to_temp = 1'b0;
    store_axis_temp_to_output = 1'b0;

    if (m_axis_tready_int_reg) begin
        // input is ready
        if (m_axis.tready || !m_axis_tvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            m_axis_tvalid_next = m_axis_tvalid_int;
            store_axis_int_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_axis_tvalid_next = m_axis_tvalid_int;
            store_axis_int_to_temp = 1'b1;
        end
    end else if (m_axis.tready) begin
        // input is not ready, but output is ready
        m_axis_tvalid_next = temp_m_axis_tvalid_reg;
        temp_m_axis_tvalid_next = 1'b0;
        store_axis_temp_to_output = 1'b1;
    end
end

always_ff @(posedge clk) begin
    m_axis_tvalid_reg <= m_axis_tvalid_next;
    m_axis_tready_int_reg <= m_axis_tready_int_early;
    temp_m_axis_tvalid_reg <= temp_m_axis_tvalid_next;

    // datapath
    if (store_axis_int_to_output) begin
        m_axis_tdata_reg <= m_axis_tdata_int;
        m_axis_tkeep_reg <= m_axis_tkeep_int;
        m_axis_tstrb_reg <= m_axis_tstrb_int;
        m_axis_tlast_reg <= m_axis_tlast_int;
        m_axis_tid_reg   <= m_axis_tid_int;
        m_axis_tdest_reg <= m_axis_tdest_int;
        m_axis_tuser_reg <= m_axis_tuser_int;
    end else if (store_axis_temp_to_output) begin
        m_axis_tdata_reg <= temp_m_axis_tdata_reg;
        m_axis_tkeep_reg <= temp_m_axis_tkeep_reg;
        m_axis_tstrb_reg <= temp_m_axis_tstrb_reg;
        m_axis_tlast_reg <= temp_m_axis_tlast_reg;
        m_axis_tid_reg   <= temp_m_axis_tid_reg;
        m_axis_tdest_reg <= temp_m_axis_tdest_reg;
        m_axis_tuser_reg <= temp_m_axis_tuser_reg;
    end

    if (store_axis_int_to_temp) begin
        temp_m_axis_tdata_reg <= m_axis_tdata_int;
        temp_m_axis_tkeep_reg <= m_axis_tkeep_int;
        temp_m_axis_tstrb_reg <= m_axis_tstrb_int;
        temp_m_axis_tlast_reg <= m_axis_tlast_int;
        temp_m_axis_tid_reg   <= m_axis_tid_int;
        temp_m_axis_tdest_reg <= m_axis_tdest_int;
        temp_m_axis_tuser_reg <= m_axis_tuser_int;
    end

    if (rst) begin
        m_axis_tvalid_reg <= 1'b0;
        m_axis_tready_int_reg <= 1'b0;
        temp_m_axis_tvalid_reg <= 1'b0;
    end
end

endmodule

`resetall
