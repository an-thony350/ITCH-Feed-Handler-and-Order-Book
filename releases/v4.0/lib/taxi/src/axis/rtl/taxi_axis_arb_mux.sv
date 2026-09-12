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
 * AXI4-Stream arbitrated multiplexer
 */
module taxi_axis_arb_mux #
(
    // Number of AXI stream inputs
    parameter S_COUNT = 4,
    // Update tid with routing information
    parameter logic UPDATE_TID = 1'b0,
    // select round robin arbitration
    parameter logic ARB_ROUND_ROBIN = 1'b0,
    // LSB priority selection
    parameter logic ARB_LSB_HIGH_PRIO = 1'b1
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * AXI4-Stream inputs (sink)
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
localparam S_ID_W = s_axis[0].ID_W;
localparam logic DEST_EN = s_axis[0].DEST_EN && m_axis.DEST_EN;
localparam DEST_W = s_axis[0].DEST_W;
localparam logic USER_EN = s_axis[0].USER_EN && m_axis.USER_EN;
localparam USER_W = s_axis[0].USER_W;

localparam M_ID_W = m_axis.ID_W;

localparam CL_S_COUNT = $clog2(S_COUNT);

// check configuration
if (m_axis.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (KEEP_EN && m_axis.KEEP_W != KEEP_W)
    $fatal(0, "Error: Interface KEEP_W parameter mismatch (instance %m)");

if (UPDATE_TID) begin
    if (!ID_EN)
        $fatal(0, "Error: UPDATE_TID set requires ID_EN set (instance %m)");

    if (M_ID_W < CL_S_COUNT)
        $fatal(0, "Error: M_ID_W too small for port count (instance %m)");
end

// internal datapath
logic [DATA_W-1:0]  m_axis_tdata_int;
logic [KEEP_W-1:0]  m_axis_tkeep_int;
logic [KEEP_W-1:0]  m_axis_tstrb_int;
logic               m_axis_tvalid_int;
logic               m_axis_tready_int_reg = 1'b0;
logic               m_axis_tlast_int;
logic [M_ID_W-1:0]  m_axis_tid_int;
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
        m_axis_tid_int    = M_ID_W'(s_axis[0].tid);
        m_axis_tdest_int  = s_axis[0].tdest;
        m_axis_tuser_int  = s_axis[0].tuser;
    end

end else begin

    wire [S_COUNT-1:0] req;
    wire [S_COUNT-1:0] ack;
    wire [S_COUNT-1:0] grant;
    wire grant_valid;
    wire [CL_S_COUNT-1:0] grant_index;

    // input registers to pipeline arbitration delay
    logic [DATA_W-1:0]   s_axis_tdata_reg[S_COUNT] = '{S_COUNT{'0}};
    logic [KEEP_W-1:0]   s_axis_tkeep_reg[S_COUNT] = '{S_COUNT{'0}};
    logic [KEEP_W-1:0]   s_axis_tstrb_reg[S_COUNT] = '{S_COUNT{'0}};
    logic [S_COUNT-1:0]  s_axis_tvalid_reg = '0;
    logic [S_COUNT-1:0]  s_axis_tlast_reg = '0;
    logic [S_ID_W-1:0]   s_axis_tid_reg[S_COUNT] = '{S_COUNT{'0}};
    logic [DEST_W-1:0]   s_axis_tdest_reg[S_COUNT] = '{S_COUNT{'0}};
    logic [USER_W-1:0]   s_axis_tuser_reg[S_COUNT] = '{S_COUNT{'0}};

    // unpack interface array
    wire [S_COUNT-1:0]  s_axis_tvalid;
    wire [S_COUNT-1:0]  s_axis_tready;

    for (genvar n = 0; n < S_COUNT; n = n + 1) begin
        assign s_axis_tvalid[n] = s_axis[n].tvalid;
        assign s_axis[n].tready = s_axis_tready[n];
    end

    assign s_axis_tready = ~s_axis_tvalid_reg | ({S_COUNT{m_axis_tready_int_reg}} & grant);

    // mux for incoming packet
    wire [DATA_W-1:0]  current_s_tdata  = s_axis_tdata_reg[grant_index];
    wire [KEEP_W-1:0]  current_s_tkeep  = s_axis_tkeep_reg[grant_index];
    wire [KEEP_W-1:0]  current_s_tstrb  = s_axis_tstrb_reg[grant_index];
    wire               current_s_tvalid = s_axis_tvalid_reg[grant_index];
    wire               current_s_tready = s_axis_tready[grant_index];
    wire               current_s_tlast  = s_axis_tlast_reg[grant_index];
    wire [S_ID_W-1:0]  current_s_tid    = s_axis_tid_reg[grant_index];
    wire [DEST_W-1:0]  current_s_tdest  = s_axis_tdest_reg[grant_index];
    wire [USER_W-1:0]  current_s_tuser  = s_axis_tuser_reg[grant_index];

    // arbiter instance
    taxi_arbiter #(
        .PORTS(S_COUNT),
        .ARB_ROUND_ROBIN(ARB_ROUND_ROBIN),
        .ARB_BLOCK(1'b1),
        .ARB_BLOCK_ACK(1'b1),
        .LSB_HIGH_PRIO(ARB_LSB_HIGH_PRIO)
    )
    arb_inst (
        .clk(clk),
        .rst(rst),
        .req(req),
        .ack(ack),
        .grant(grant),
        .grant_valid(grant_valid),
        .grant_index(grant_index)
    );

    assign req = s_axis_tvalid | (s_axis_tvalid_reg & ~grant);
    assign ack = grant & s_axis_tvalid_reg & {S_COUNT{m_axis_tready_int_reg}} & (LAST_EN ? s_axis_tlast_reg : {S_COUNT{1'b1}});

    always_comb begin
        // pass through selected packet data
        m_axis_tdata_int  = current_s_tdata;
        m_axis_tkeep_int  = current_s_tkeep;
        m_axis_tstrb_int  = current_s_tstrb;
        m_axis_tvalid_int = current_s_tvalid && m_axis_tready_int_reg && grant_valid;
        m_axis_tlast_int  = current_s_tlast;
        m_axis_tid_int    = M_ID_W'(current_s_tid);
        if (UPDATE_TID && S_COUNT > 1) begin
            m_axis_tid_int[M_ID_W-1:M_ID_W-CL_S_COUNT] = grant_index;
        end
        m_axis_tdest_int  = current_s_tdest;
        m_axis_tuser_int  = current_s_tuser;
    end

    for (genvar n = 0; n < S_COUNT; n = n + 1) begin
        always_ff @(posedge clk) begin
            // register inputs
            if (s_axis_tready[n]) begin
                s_axis_tdata_reg[n] <= s_axis[n].tdata;
                s_axis_tkeep_reg[n] <= s_axis[n].tkeep;
                s_axis_tstrb_reg[n] <= s_axis[n].tstrb;
                s_axis_tvalid_reg[n] <= s_axis[n].tvalid;
                s_axis_tlast_reg[n] <= s_axis[n].tlast;
                s_axis_tid_reg[n]   <= s_axis[n].tid;
                s_axis_tdest_reg[n] <= s_axis[n].tdest;
                s_axis_tuser_reg[n] <= s_axis[n].tuser;
            end

            if (rst) begin
                s_axis_tvalid_reg[n] <= 1'b0;
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
logic [M_ID_W-1:0] m_axis_tid_reg    = '0;
logic [DEST_W-1:0] m_axis_tdest_reg  = '0;
logic [USER_W-1:0] m_axis_tuser_reg  = '0;

logic [DATA_W-1:0] temp_m_axis_tdata_reg  = '0;
logic [KEEP_W-1:0] temp_m_axis_tkeep_reg  = '0;
logic [KEEP_W-1:0] temp_m_axis_tstrb_reg  = '0;
logic              temp_m_axis_tvalid_reg = 1'b0, temp_m_axis_tvalid_next;
logic              temp_m_axis_tlast_reg  = 1'b0;
logic [M_ID_W-1:0] temp_m_axis_tid_reg    = '0;
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
