// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2016-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream switch
 */
module taxi_axis_switch #
(
    // Number of AXI stream inputs
    parameter S_COUNT = 4,
    // Number of AXI stream outputs
    parameter M_COUNT = 4,
    // Output interface routing base tdest selection
    // Port selected if M_BASE <= tdest <= M_TOP
    parameter M_BASE[M_COUNT] = '{M_COUNT{'0}},
    // Output interface routing top tdest selection
    // Port selected if M_BASE <= tdest <= M_TOP
    parameter M_TOP[M_COUNT] = '{M_COUNT{'0}},
    // Set for default routing with tdest MSBs as port index
    parameter logic AUTO_ADDR = 1'b0,
    // Interface connection control
    parameter logic M_CONNECT[M_COUNT][S_COUNT] = '{M_COUNT{'{S_COUNT{1'b1}}}},
    // Update tid with routing information
    parameter logic UPDATE_TID = 1'b0,
    // Input interface register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_REG_TYPE = 0,
    // Output interface register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_REG_TYPE = 2,
    // select round robin arbitration
    parameter logic ARB_ROUND_ROBIN = 1'b1,
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
     * AXI4-Stream outputs (source)
     */
    taxi_axis_if.src   m_axis[M_COUNT]
);

// extract parameters
localparam DATA_W = s_axis[0].DATA_W;
localparam logic KEEP_EN = s_axis[0].KEEP_EN && m_axis[0].KEEP_EN;
localparam KEEP_W = s_axis[0].KEEP_W;
localparam logic STRB_EN = s_axis[0].STRB_EN && m_axis[0].STRB_EN;
localparam logic LAST_EN = s_axis[0].LAST_EN && m_axis[0].LAST_EN;
localparam logic ID_EN = s_axis[0].ID_EN && m_axis[0].ID_EN;
localparam S_ID_W = s_axis[0].ID_W;
localparam logic DEST_EN = s_axis[0].DEST_EN && m_axis[0].DEST_EN;
localparam S_DEST_W = s_axis[0].DEST_W;
localparam logic USER_EN = s_axis[0].USER_EN && m_axis[0].USER_EN;
localparam USER_W = s_axis[0].USER_W;

localparam M_ID_W = m_axis[0].ID_W;
localparam M_DEST_W = m_axis[0].DEST_W;

localparam CL_S_COUNT = $clog2(S_COUNT);
localparam CL_M_COUNT = $clog2(M_COUNT);

localparam S_ID_W_INT = S_ID_W > 0 ? S_ID_W : 1;
localparam M_ID_W_INT = M_ID_W > 0 ? M_ID_W : 1;
localparam S_DEST_W_INT = S_DEST_W > 0 ? S_DEST_W : 1;
localparam M_DEST_W_INT = M_DEST_W > 0 ? M_DEST_W : 1;

// check configuration
if (m_axis.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (KEEP_EN && m_axis.KEEP_W != KEEP_W)
    $fatal(0, "Error: Interface KEEP_W parameter mismatch (instance %m)");

if (M_COUNT > 1) begin
    if (!DEST_EN)
        $fatal(0, "Error: DEST_EN required for M_COUNT > 1 (instance %m)");

    if (S_DEST_W < CL_M_COUNT)
        $fatal(0, "Error: S_DEST_W too small for port count (instance %m)");
end

if (UPDATE_TID) begin
    if (!ID_EN)
        $fatal(0, "Error: UPDATE_TID set requires ID_EN set (instance %m)");

    if (M_ID_W < CL_S_COUNT)
        $fatal(0, "Error: M_ID_W too small for port count (instance %m)");
end

if (AUTO_ADDR) begin
    initial begin
        // route with tdest as port index
        $display("Addressing configuration for axis_switch instance %m");
        for (integer i = 0; i < M_COUNT; i = i + 1) begin
            $display("%d: %08x-%08x", i, i << (S_DEST_W-CL_M_COUNT), ((i+1) << (S_DEST_W-CL_M_COUNT))-1);
        end
    end
end else begin
    for (genvar i = 0; i < M_COUNT; i = i + 1) begin
        if (M_BASE[i] > M_TOP[i]) begin
            $fatal(0, "Error: range index %d is invalid (%08x > %08x) (instance %m)", i, M_BASE[i], M_TOP[i]);
        end

        for (genvar j = i+1; j < M_COUNT; j = j + 1) begin
            if (M_BASE[i] <= M_TOP[j] && M_BASE[j] <= M_TOP[i]) begin
                $fatal(0, "Error: ranges %d (%08x-%08x) and %d (%08x-%08x) overlap (instance %m)", i, M_BASE[i], M_TOP[i], j, M_BASE[j], M_TOP[j]);
            end
        end
    end

    initial begin
        $display("Addressing configuration for axis_switch instance %m");
        for (integer i = 0; i < M_COUNT; i = i + 1) begin
            $display("%d: %08x-%08x", i, M_BASE[i], M_TOP[i]);
        end
    end
end

wire [DATA_W-1:0]    int_s_axis_tdata[S_COUNT];
wire [KEEP_W-1:0]    int_s_axis_tkeep[S_COUNT];
wire                 int_s_axis_tvalid[S_COUNT];
wire                 int_s_axis_tready[S_COUNT];
wire                 int_s_axis_tlast[S_COUNT];
wire [S_ID_W-1:0]    int_s_axis_tid[S_COUNT];
wire [S_DEST_W-1:0]  int_s_axis_tdest[S_COUNT];
wire [USER_W-1:0]    int_s_axis_tuser[S_COUNT];

logic [M_COUNT-1:0]  int_axis_tvalid[S_COUNT];
logic [S_COUNT-1:0]  int_axis_tready[M_COUNT];

for (genvar m = 0; m < S_COUNT; m = m + 1) begin : s_if

    taxi_axis_if #(
        .DATA_W(s_axis.DATA_W),
        .KEEP_EN(s_axis.KEEP_EN),
        .KEEP_W(s_axis.KEEP_W),
        .STRB_EN(s_axis.STRB_EN),
        .LAST_EN(s_axis.LAST_EN),
        .ID_EN(s_axis.ID_EN),
        .ID_W(s_axis.ID_W),
        .DEST_EN(s_axis.DEST_EN),
        .DEST_W(s_axis.DEST_W),
        .USER_EN(s_axis.USER_EN),
        .USER_W(s_axis.USER_W)
    ) int_axis();

    // S side register
    taxi_axis_register #(
        .REG_TYPE(S_REG_TYPE)
    )
    reg_inst (
        .clk(clk),
        .rst(rst),

        /*
         * AXI4-Stream input (sink)
         */
        .s_axis(s_axis[m]),

        /*
         * AXI4-Stream output (source)
         */
        .m_axis(int_axis)
    );

    if (M_COUNT == 1) begin
        // degenerate case

        // forwarding
        assign int_s_axis_tdata[m] = int_axis.tdata;
        assign int_s_axis_tkeep[m] = int_axis.tkeep;
        assign int_s_axis_tvalid[m] = int_axis.tvalid;
        assign int_s_axis_tlast[m] = int_axis.tlast;
        assign int_s_axis_tid[m] = int_axis.tid;
        assign int_s_axis_tdest[m] = int_axis.tdest;
        assign int_s_axis_tuser[m] = int_axis.tuser;

        assign int_axis_tvalid[m] = int_axis.tvalid;
        assign int_axis.tready = int_axis_tready[0][m];

    end else begin

        // decoding
        logic frame_reg = 1'b0, frame_next;
        logic [CL_M_COUNT-1:0] select_reg = '0, select_next;
        logic drop_reg = 1'b0, drop_next;
        logic select_valid_reg = 1'b0, select_valid_next;

        always_comb begin
            select_next = select_reg;
            drop_next = drop_reg && !(int_axis.tvalid && int_axis.tready && int_axis.tlast);
            select_valid_next = select_valid_reg && !(int_axis.tvalid && int_axis.tready && int_axis.tlast);

            if (int_axis.tvalid && !select_valid_reg && !drop_reg) begin
                select_next = '0;
                select_valid_next = 1'b0;
                drop_next = 1'b1;
                for (integer k = 0; k < M_COUNT; k = k + 1) begin
                    if (AUTO_ADDR) begin
                        // route with $clog2(M_COUNT) MSBs of tdest as port index
                        if (int_axis.tdest[(S_DEST_W-CL_M_COUNT) +: CL_M_COUNT] == CL_M_COUNT'(k) && M_CONNECT[k][m]) begin
                            select_next = CL_M_COUNT'(k);
                            select_valid_next = 1'b1;
                            drop_next = 1'b0;
                        end
                    end else begin
                        if (int_axis.tdest >= S_DEST_W'(M_BASE[k]) && int_axis.tdest <= S_DEST_W'(M_TOP[k]) && M_CONNECT[k][m]) begin
                            select_next = CL_M_COUNT'(k);
                            select_valid_next = 1'b1;
                            drop_next = 1'b0;
                        end
                    end
                end
            end
        end

        always_ff @(posedge clk) begin
            select_reg <= select_next;
            drop_reg <= drop_next;
            select_valid_reg <= select_valid_next;

            if (rst) begin
                select_valid_reg <= 1'b0;
            end
        end

        // forwarding
        assign int_s_axis_tdata[m] = int_axis.tdata;
        assign int_s_axis_tkeep[m] = int_axis.tkeep;
        assign int_s_axis_tvalid[m] = int_axis.tvalid;
        assign int_s_axis_tlast[m] = int_axis.tlast;
        assign int_s_axis_tid[m] = int_axis.tid;
        assign int_s_axis_tdest[m] = int_axis.tdest;
        assign int_s_axis_tuser[m] = int_axis.tuser;

        always_comb begin
            int_axis_tvalid[m] = '0;
            int_axis_tvalid[m][select_reg] = int_axis.tvalid && select_valid_reg && !drop_reg;
        end

        assign int_axis.tready = (int_axis_tready[select_reg][m] || drop_reg) && select_valid_reg;

    end

end // s_if

for (genvar n = 0; n < M_COUNT; n = n + 1) begin : m_if

    taxi_axis_if #(
        .DATA_W(m_axis.DATA_W),
        .KEEP_EN(m_axis.KEEP_EN),
        .KEEP_W(m_axis.KEEP_W),
        .STRB_EN(m_axis.STRB_EN),
        .LAST_EN(m_axis.LAST_EN),
        .ID_EN(m_axis.ID_EN),
        .ID_W(m_axis.ID_W),
        .DEST_EN(m_axis.DEST_EN),
        .DEST_W(m_axis.DEST_W),
        .USER_EN(m_axis.USER_EN),
        .USER_W(m_axis.USER_W)
    ) int_axis();

    if (S_COUNT == 1) begin
        // degenerate case

        always_comb begin
            int_axis.tdata   = int_s_axis_tdata[0];
            int_axis.tkeep   = int_s_axis_tkeep[0];
            int_axis.tvalid  = int_axis_tvalid[0][n];
            int_axis.tlast   = int_s_axis_tlast[0];
            int_axis.tid     = M_ID_W'(int_s_axis_tid[0]);
            int_axis.tdest   = M_DEST_W'(int_s_axis_tdest[0]);
            int_axis.tuser   = int_s_axis_tuser[0];
        end

        assign int_axis_tready[n] = int_axis.tready;

    end else begin

        // arbitration
        wire [S_COUNT-1:0] req;
        wire [S_COUNT-1:0] ack;
        wire [S_COUNT-1:0] grant;
        wire grant_valid;
        wire [CL_S_COUNT-1:0] grant_index;

        taxi_arbiter #(
            .PORTS(S_COUNT),
            .ARB_ROUND_ROBIN(ARB_ROUND_ROBIN),
            .ARB_BLOCK(1),
            .ARB_BLOCK_ACK(1),
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

        always_comb begin
            int_axis.tdata   = int_s_axis_tdata[grant_index];
            int_axis.tkeep   = int_s_axis_tkeep[grant_index];
            int_axis.tvalid  = int_axis_tvalid[grant_index][n] && grant_valid;
            int_axis.tlast   = int_s_axis_tlast[grant_index];
            int_axis.tid     = M_ID_W'(int_s_axis_tid[grant_index]);
            if (UPDATE_TID) begin
                int_axis.tid[M_ID_W-1:M_ID_W-CL_S_COUNT] = grant_index;
            end
            int_axis.tdest   = M_DEST_W'(int_s_axis_tdest[grant_index]);
            int_axis.tuser   = int_s_axis_tuser[grant_index];
        end

        always_comb begin
            int_axis_tready[n] = '0;
            int_axis_tready[n][grant_index] = grant_valid && int_axis.tready;
        end

        for (genvar m = 0; m < S_COUNT; m = m + 1) begin
            assign req[m] = int_axis_tvalid[m][n] && !grant[m];
            assign ack[m] = grant[m] && int_axis_tvalid[m][n] && int_axis.tlast && int_axis.tready;
        end

    end

    // M side register
    taxi_axis_register #(
        .REG_TYPE(S_REG_TYPE)
    )
    reg_inst (
        .clk(clk),
        .rst(rst),

        /*
         * AXI4-Stream input (sink)
         */
        .s_axis(int_axis),

        /*
         * AXI4-Stream output (source)
         */
        .m_axis(m_axis[n])
    );

end // m_if

endmodule

`resetall
