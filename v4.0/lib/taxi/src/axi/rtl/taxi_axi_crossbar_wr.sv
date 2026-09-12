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
 * AXI4 crossbar (write)
 */
module taxi_axi_crossbar_wr #
(
    // Number of AXI inputs (slave interfaces)
    parameter S_COUNT = 4,
    // Number of AXI outputs (master interfaces)
    parameter M_COUNT = 4,
    // Address width in bits for address decoding
    parameter ADDR_W = 32,
    // TODO fix parametrization once verilator issue 5890 is fixed
    // Number of concurrent unique IDs for each slave interface
    // S_COUNT concatenated fields of 32 bits
    parameter S_THREADS = {S_COUNT{32'd2}},
    // Number of concurrent operations for each slave interface
    // S_COUNT concatenated fields of 32 bits
    parameter S_ACCEPT = {S_COUNT{32'd16}},
    // Number of regions per master interface
    parameter M_REGIONS = 1,
    // Master interface base addresses
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of ADDR_W bits
    // set to zero for default addressing based on M_ADDR_W
    parameter M_BASE_ADDR = '0,
    // Master interface address widths
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of 32 bits
    parameter M_ADDR_W = {M_COUNT{{M_REGIONS{32'd24}}}},
    // Write connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    // Number of concurrent operations for each master interface
    // M_COUNT concatenated fields of 32 bits
    parameter M_ISSUE = {M_COUNT{32'd4}},
    // Secure master (fail operations based on awprot/arprot)
    // M_COUNT bits
    parameter M_SECURE = {M_COUNT{1'b0}},
    // Slave interface AW channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_AW_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface W channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_W_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface B channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_B_REG_TYPE = {S_COUNT{2'd1}},
    // Master interface AW channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_AW_REG_TYPE = {M_COUNT{2'd1}},
    // Master interface W channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_W_REG_TYPE = {M_COUNT{2'd2}},
    // Master interface B channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_B_REG_TYPE = {M_COUNT{2'd0}}
)
(
    input  wire logic   clk,
    input  wire logic   rst,

    /*
     * AXI4 slave interfaces
     */
    taxi_axi_if.wr_slv  s_axi_wr[S_COUNT],

    /*
     * AXI4 master interfaces
     */
    taxi_axi_if.wr_mst  m_axi_wr[M_COUNT]
);

// extract parameters
localparam DATA_W = s_axi_wr[0].DATA_W;
localparam S_ADDR_W = s_axi_wr[0].ADDR_W;
localparam STRB_W = s_axi_wr[0].STRB_W;
localparam S_ID_W = s_axi_wr[0].ID_W;
localparam M_ID_W = m_axi_wr[0].ID_W;
localparam logic AWUSER_EN = s_axi_wr[0].AWUSER_EN && m_axi_wr[0].AWUSER_EN;
localparam AWUSER_W = s_axi_wr[0].AWUSER_W;
localparam logic WUSER_EN = s_axi_wr[0].WUSER_EN && m_axi_wr[0].WUSER_EN;
localparam WUSER_W = s_axi_wr[0].WUSER_W;
localparam logic BUSER_EN = s_axi_wr[0].BUSER_EN && m_axi_wr[0].BUSER_EN;
localparam BUSER_W = s_axi_wr[0].BUSER_W;

localparam AXI_M_ADDR_W = m_axi_wr[0].ADDR_W;

localparam CL_S_COUNT = $clog2(S_COUNT);
localparam CL_M_COUNT = $clog2(M_COUNT);
localparam CL_S_COUNT_INT = CL_S_COUNT > 0 ? CL_S_COUNT : 1;
localparam CL_M_COUNT_INT = CL_M_COUNT > 0 ? CL_M_COUNT : 1;
localparam M_COUNT_P1 = M_COUNT+1;
localparam CL_M_COUNT_P1 = $clog2(M_COUNT_P1);

localparam [S_COUNT-1:0][31:0] S_THREADS_INT = S_THREADS;
localparam [S_COUNT-1:0][31:0] S_ACCEPT_INT = S_ACCEPT;
localparam [M_COUNT-1:0][31:0] M_ISSUE_INT = M_ISSUE;

// check configuration
if (s_axi_wr[0].ADDR_W != ADDR_W)
    $fatal(0, "Error: Interface ADDR_W parameter mismatch (instance %m)");

if (m_axi_wr[0].DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (m_axi_wr[0].STRB_W != STRB_W)
    $fatal(0, "Error: Interface STRB_W parameter mismatch (instance %m)");

if (M_ID_W < S_ID_W+$clog2(S_COUNT))
    $fatal(0, "Error: M_ID_W must be at least $clog2(S_COUNT) larger than S_ID_W (instance %m)");

wire [S_ID_W-1:0]    int_s_axi_awid[S_COUNT];
wire [ADDR_W-1:0]    int_s_axi_awaddr[S_COUNT];
wire [7:0]           int_s_axi_awlen[S_COUNT];
wire [2:0]           int_s_axi_awsize[S_COUNT];
wire [1:0]           int_s_axi_awburst[S_COUNT];
wire                 int_s_axi_awlock[S_COUNT];
wire [3:0]           int_s_axi_awcache[S_COUNT];
wire [2:0]           int_s_axi_awprot[S_COUNT];
wire [3:0]           int_s_axi_awqos[S_COUNT];
wire [3:0]           int_s_axi_awregion[S_COUNT];
wire [AWUSER_W-1:0]  int_s_axi_awuser[S_COUNT];

logic [M_COUNT-1:0]  int_axi_awvalid[S_COUNT];
logic [S_COUNT-1:0]  int_axi_awready[M_COUNT];

wire [DATA_W-1:0]    int_s_axi_wdata[S_COUNT];
wire [STRB_W-1:0]    int_s_axi_wstrb[S_COUNT];
wire                 int_s_axi_wlast[S_COUNT];
wire [WUSER_W-1:0]   int_s_axi_wuser[S_COUNT];

logic [M_COUNT-1:0]  int_axi_wvalid[S_COUNT];
logic [S_COUNT-1:0]  int_axi_wready[M_COUNT];

wire [M_ID_W-1:0]    int_m_axi_bid[M_COUNT];
wire [1:0]           int_m_axi_bresp[M_COUNT];
wire [BUSER_W-1:0]   int_m_axi_buser[M_COUNT];

logic [S_COUNT-1:0]  int_axi_bvalid[M_COUNT];
logic [M_COUNT-1:0]  int_axi_bready[S_COUNT];

for (genvar m = 0; m < S_COUNT; m = m + 1) begin : s_ifaces

    taxi_axi_if #(
        .DATA_W(s_axi_wr[0].DATA_W),
        .ADDR_W(s_axi_wr[0].ADDR_W),
        .STRB_W(s_axi_wr[0].STRB_W),
        .ID_W(s_axi_wr[0].ID_W),
        .AWUSER_EN(s_axi_wr[0].AWUSER_EN),
        .AWUSER_W(s_axi_wr[0].AWUSER_W),
        .WUSER_EN(s_axi_wr[0].WUSER_EN),
        .WUSER_W(s_axi_wr[0].WUSER_W),
        .BUSER_EN(s_axi_wr[0].BUSER_EN),
        .BUSER_W(s_axi_wr[0].BUSER_W)
    ) int_axi();

    // S side register
    taxi_axi_register_wr #(
        .AW_REG_TYPE(S_AW_REG_TYPE[m*2 +: 2]),
        .W_REG_TYPE(S_W_REG_TYPE[m*2 +: 2]),
        .B_REG_TYPE(S_B_REG_TYPE[m*2 +: 2])
    )
    reg_inst (
        .clk(clk),
        .rst(rst),

        /*
         * AXI4 slave interface
         */
        .s_axi_wr(s_axi_wr[m]),

        /*
         * AXI4 master interface
         */
        .m_axi_wr(int_axi)
    );

    // address decode and admission control
    wire [CL_M_COUNT_INT-1:0] a_select;

    wire m_axi_avalid;
    wire m_axi_aready;

    wire [CL_M_COUNT_INT-1:0] m_wc_select;
    wire m_wc_decerr;
    wire m_wc_valid;
    wire m_wc_ready;

    wire m_rc_decerr;
    wire m_rc_valid;
    wire m_rc_ready;

    wire [S_ID_W-1:0] s_cpl_id;
    wire s_cpl_valid;

    taxi_axi_crossbar_addr #(
        .S(m),
        .S_COUNT(S_COUNT),
        .M_COUNT(M_COUNT),
        .SEL_W(CL_M_COUNT_INT),
        .ADDR_W(ADDR_W),
        .ID_W(S_ID_W),
        .S_THREADS(S_THREADS_INT[m]),
        .S_ACCEPT(S_ACCEPT_INT[m]),
        .M_REGIONS(M_REGIONS),
        .M_BASE_ADDR(M_BASE_ADDR),
        .M_ADDR_W(M_ADDR_W),
        .M_CONNECT(M_CONNECT),
        .M_SECURE(M_SECURE),
        .WC_OUTPUT(1)
    )
    addr_inst (
        .clk(clk),
        .rst(rst),

        /*
         * Address input
         */
        .s_axi_aid(int_axi.awid),
        .s_axi_aaddr(int_axi.awaddr),
        .s_axi_aprot(int_axi.awprot),
        .s_axi_aqos(int_axi.awqos),
        .s_axi_avalid(int_axi.awvalid),
        .s_axi_aready(int_axi.awready),

        /*
         * Address output
         */
        .m_axi_aregion(int_s_axi_awregion[m]),
        .m_select(a_select),
        .m_axi_avalid(m_axi_avalid),
        .m_axi_aready(m_axi_aready),

        /*
         * Write command output
         */
        .m_wc_select(m_wc_select),
        .m_wc_decerr(m_wc_decerr),
        .m_wc_valid(m_wc_valid),
        .m_wc_ready(m_wc_ready),

        /*
         * Response command output
         */
        .m_rc_decerr(m_rc_decerr),
        .m_rc_valid(m_rc_valid),
        .m_rc_ready(m_rc_ready),

        /*
         * Completion input
         */
        .s_cpl_id(s_cpl_id),
        .s_cpl_valid(s_cpl_valid)
    );

    assign int_s_axi_awid[m] = int_axi.awid;
    assign int_s_axi_awaddr[m] = int_axi.awaddr;
    assign int_s_axi_awlen[m] = int_axi.awlen;
    assign int_s_axi_awsize[m] = int_axi.awsize;
    assign int_s_axi_awburst[m] = int_axi.awburst;
    assign int_s_axi_awlock[m] = int_axi.awlock;
    assign int_s_axi_awcache[m] = int_axi.awcache;
    assign int_s_axi_awprot[m] = int_axi.awprot;
    assign int_s_axi_awqos[m] = int_axi.awqos;
    assign int_s_axi_awuser[m] = int_axi.awuser;

    always_comb begin
        int_axi_awvalid[m] = '0;
        int_axi_awvalid[m][a_select] = m_axi_avalid;
    end
    assign m_axi_aready = int_axi_awready[a_select][m];

    // write command handling
    logic [CL_M_COUNT_INT-1:0] w_select_reg = '0, w_select_next;
    logic w_drop_reg = 1'b0, w_drop_next;
    logic w_select_valid_reg = 1'b0, w_select_valid_next;

    assign m_wc_ready = !w_select_valid_reg;

    always_comb begin
        w_select_next = w_select_reg;
        w_drop_next = w_drop_reg && !(int_axi.wvalid && int_axi.wready && int_axi.wlast);
        w_select_valid_next = w_select_valid_reg && !(int_axi.wvalid && int_axi.wready && int_axi.wlast);

        if (m_wc_valid && !w_select_valid_reg) begin
            w_select_next = m_wc_select;
            w_drop_next = m_wc_decerr;
            w_select_valid_next = m_wc_valid;
        end
    end

    always_ff @(posedge clk) begin
        w_select_valid_reg <= w_select_valid_next;
        w_select_reg <= w_select_next;
        w_drop_reg <= w_drop_next;

        if (rst) begin
            w_select_valid_reg <= 1'b0;
        end
    end

    // write data forwarding
    assign int_s_axi_wdata[m] = int_axi.wdata;
    assign int_s_axi_wstrb[m] = int_axi.wstrb;
    assign int_s_axi_wlast[m] = int_axi.wlast;
    assign int_s_axi_wuser[m] = int_axi.wuser;

    always_comb begin
        int_axi_wvalid[m] = '0;
        int_axi_wvalid[m][w_select_reg] = int_axi.wvalid && w_select_valid_reg && !w_drop_reg;
    end
    assign int_axi.wready = int_axi_wready[w_select_reg][m] || w_drop_reg;

    // decode error handling
    logic [S_ID_W-1:0]  decerr_m_axi_bid_reg = '0, decerr_m_axi_bid_next;
    logic               decerr_m_axi_bvalid_reg = 1'b0, decerr_m_axi_bvalid_next;
    wire                decerr_m_axi_bready;

    assign m_rc_ready = !decerr_m_axi_bvalid_reg;

    always_comb begin
        decerr_m_axi_bid_next = decerr_m_axi_bid_reg;
        decerr_m_axi_bvalid_next = decerr_m_axi_bvalid_reg;

        if (decerr_m_axi_bvalid_reg) begin
            if (decerr_m_axi_bready) begin
                decerr_m_axi_bvalid_next = 1'b0;
            end
        end else if (m_rc_valid && m_rc_ready) begin
            decerr_m_axi_bid_next = int_s_axi_awid[m];
            decerr_m_axi_bvalid_next = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            decerr_m_axi_bvalid_reg <= 1'b0;
        end else begin
            decerr_m_axi_bvalid_reg <= decerr_m_axi_bvalid_next;
        end

        decerr_m_axi_bid_reg <= decerr_m_axi_bid_next;
    end

    // write response arbitration
    wire [M_COUNT_P1-1:0] b_req;
    wire [M_COUNT_P1-1:0] b_ack;
    wire [M_COUNT_P1-1:0] b_grant;
    wire b_grant_valid;
    wire [CL_M_COUNT_P1-1:0] b_grant_index;

    taxi_arbiter #(
        .PORTS(M_COUNT_P1),
        .ARB_ROUND_ROBIN(1),
        .ARB_BLOCK(1),
        .ARB_BLOCK_ACK(1),
        .LSB_HIGH_PRIO(1)
    )
    b_arb_inst (
        .clk(clk),
        .rst(rst),
        .req(b_req),
        .ack(b_ack),
        .grant(b_grant),
        .grant_valid(b_grant_valid),
        .grant_index(b_grant_index)
    );

    // write response mux
    always_comb begin
        if (b_grant_index == CL_M_COUNT_P1'(M_COUNT_P1-1)) begin
            int_axi.bid    = decerr_m_axi_bid_reg;
            int_axi.bresp  = 2'b11;
            int_axi.buser  = '0;
            int_axi.bvalid = decerr_m_axi_bvalid_reg & b_grant_valid;
        end else begin
            int_axi.bid    = S_ID_W'(int_m_axi_bid[b_grant_index[CL_M_COUNT_INT-1:0]]);
            int_axi.bresp  = int_m_axi_bresp[b_grant_index[CL_M_COUNT_INT-1:0]];
            int_axi.buser  = int_m_axi_buser[b_grant_index[CL_M_COUNT_INT-1:0]];
            int_axi.bvalid = int_axi_bvalid[b_grant_index[CL_M_COUNT_INT-1:0]][m] & b_grant_valid;
        end
    end

    always_comb begin
        int_axi_bready[m] = '0;
        int_axi_bready[m][b_grant_index[CL_M_COUNT_INT-1:0]] = b_grant_valid && int_axi.bready;
    end

    assign decerr_m_axi_bready = (b_grant_valid && int_axi.bready) && (b_grant_index == CL_M_COUNT_P1'(M_COUNT_P1-1));

    for (genvar n = 0; n < M_COUNT; n = n + 1) begin
        assign b_req[n] = int_axi_bvalid[n][m] && !b_grant[n];
        assign b_ack[n] = b_grant[n] && int_axi_bvalid[n][m] && int_axi.bready;
    end

    assign b_req[M_COUNT_P1-1] = decerr_m_axi_bvalid_reg && !b_grant[M_COUNT_P1-1];
    assign b_ack[M_COUNT_P1-1] = b_grant[M_COUNT_P1-1] && decerr_m_axi_bvalid_reg && int_axi.bready;

    assign s_cpl_id = int_axi.bid;
    assign s_cpl_valid = int_axi.bvalid && int_axi.bready;

end // s_ifaces

for (genvar n = 0; n < M_COUNT; n = n + 1) begin : m_ifaces

    taxi_axi_if #(
        .DATA_W(m_axi_wr[0].DATA_W),
        .ADDR_W(m_axi_wr[0].ADDR_W),
        .STRB_W(m_axi_wr[0].STRB_W),
        .ID_W(m_axi_wr[0].ID_W),
        .AWUSER_EN(m_axi_wr[0].AWUSER_EN),
        .AWUSER_W(m_axi_wr[0].AWUSER_W),
        .WUSER_EN(m_axi_wr[0].WUSER_EN),
        .WUSER_W(m_axi_wr[0].WUSER_W),
        .BUSER_EN(m_axi_wr[0].BUSER_EN),
        .BUSER_W(m_axi_wr[0].BUSER_W)
    ) int_axi();

    // in-flight transaction count
    wire trans_start;
    wire trans_complete;
    localparam TR_CNT_W = $clog2(M_ISSUE_INT[n]+1);
    logic [TR_CNT_W-1:0] trans_count_reg = '0;

    wire trans_limit = trans_count_reg >= TR_CNT_W'(M_ISSUE_INT[n]) && !trans_complete;

    always_ff @(posedge clk) begin
        if (trans_start && !trans_complete) begin
            trans_count_reg <= trans_count_reg + 1;
        end else if (!trans_start && trans_complete) begin
            trans_count_reg <= trans_count_reg - 1;
        end

        if (rst) begin
            trans_count_reg <= 0;
        end
    end

    // address arbitration
    logic [CL_S_COUNT_INT-1:0] w_select_reg = '0, w_select_next;
    logic w_select_valid_reg = 1'b0, w_select_valid_next;
    logic w_select_new_reg = 1'b0, w_select_new_next;

    wire [S_COUNT-1:0] a_req;
    wire [S_COUNT-1:0] a_ack;
    wire [S_COUNT-1:0] a_grant;
    wire a_grant_valid;
    wire [CL_S_COUNT_INT-1:0] a_grant_index;

    if (S_COUNT > 1) begin : arb

        taxi_arbiter #(
            .PORTS(S_COUNT),
            .ARB_ROUND_ROBIN(1),
            .ARB_BLOCK(1),
            .ARB_BLOCK_ACK(1),
            .LSB_HIGH_PRIO(1)
        )
        a_arb_inst (
            .clk(clk),
            .rst(rst),
            .req(a_req),
            .ack(a_ack),
            .grant(a_grant),
            .grant_valid(a_grant_valid),
            .grant_index(a_grant_index)
        );

    end else begin

        logic grant_valid_reg = 1'b0;

        always @(posedge clk) begin
            if (a_req) begin
                grant_valid_reg <= 1'b1;
            end

            if (a_ack || rst) begin
                grant_valid_reg <= 1'b0;
            end
        end

        assign a_grant_valid = grant_valid_reg;
        assign a_grant = grant_valid_reg;
        assign a_grant_index = '0;

    end

    // address mux
    if (S_COUNT > 1) begin
        assign int_axi.awid = {a_grant_index, int_s_axi_awid[a_grant_index]};
    end else begin
        assign int_axi.awid = int_s_axi_awid[a_grant_index];
    end
    assign int_axi.awaddr   = AXI_M_ADDR_W'(int_s_axi_awaddr[a_grant_index]);
    assign int_axi.awlen    = int_s_axi_awlen[a_grant_index];
    assign int_axi.awsize   = int_s_axi_awsize[a_grant_index];
    assign int_axi.awburst  = int_s_axi_awburst[a_grant_index];
    assign int_axi.awlock   = int_s_axi_awlock[a_grant_index];
    assign int_axi.awcache  = int_s_axi_awcache[a_grant_index];
    assign int_axi.awprot   = int_s_axi_awprot[a_grant_index];
    assign int_axi.awqos    = int_s_axi_awqos[a_grant_index];
    assign int_axi.awregion = int_s_axi_awregion[a_grant_index];
    assign int_axi.awuser   = int_s_axi_awuser[a_grant_index];
    assign int_axi.awvalid  = int_axi_awvalid[a_grant_index][n] && a_grant_valid;

    always_comb begin
        int_axi_awready[n] = '0;
        int_axi_awready[n][a_grant_index] = a_grant_valid && int_axi.awready;
    end

    for (genvar m = 0; m < S_COUNT; m = m + 1) begin
        assign a_req[m] = int_axi_awvalid[m][n] && !a_grant_valid && !trans_limit && !w_select_valid_next;
        assign a_ack[m] = a_grant[m] && int_axi_awvalid[m][n] && int_axi.awready;
    end

    assign trans_start = int_axi.awvalid && int_axi.awready && a_grant_valid;

    // write data mux
    assign int_axi.wdata   = int_s_axi_wdata[w_select_reg];
    assign int_axi.wstrb   = int_s_axi_wstrb[w_select_reg];
    assign int_axi.wlast   = int_s_axi_wlast[w_select_reg];
    assign int_axi.wuser   = int_s_axi_wuser[w_select_reg];
    assign int_axi.wvalid  = int_axi_wvalid[w_select_reg][n] && w_select_valid_reg;

    always_comb begin
        int_axi_wready[n] = '0;
        int_axi_wready[n][w_select_reg] = w_select_valid_reg && int_axi.wready;
    end

    // write data routing
    always_comb begin
        w_select_next = w_select_reg;
        w_select_valid_next = w_select_valid_reg && !(int_axi.wvalid && int_axi.wready && int_axi.wlast);
        w_select_new_next = w_select_new_reg || a_grant_valid == 0 || a_ack != 0;

        if (a_grant_valid && !w_select_valid_reg && w_select_new_reg) begin
            w_select_next = a_grant_index;
            w_select_valid_next = a_grant_valid;
            w_select_new_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        w_select_reg <= w_select_next;
        w_select_valid_reg <= w_select_valid_next;
        w_select_new_reg <= w_select_new_next;

        if (rst) begin
            w_select_valid_reg <= 1'b0;
            w_select_new_reg <= 1'b1;
        end
    end

    // write response forwarding
    wire [CL_S_COUNT_INT-1:0] b_select = CL_S_COUNT_INT'(int_axi.bid >> S_ID_W);

    assign int_m_axi_bid[n] = int_axi.bid;
    assign int_m_axi_bresp[n] = int_axi.bresp;
    assign int_m_axi_buser[n] = int_axi.buser;

    always_comb begin
        int_axi_bvalid[n] = '0;
        int_axi_bvalid[n][b_select] = int_axi.bvalid;
    end
    assign int_axi.bready = int_axi_bready[b_select][n];

    assign trans_complete = int_axi.bvalid && int_axi.bready;

    // M side register
    taxi_axi_register_wr #(
        .AW_REG_TYPE(M_AW_REG_TYPE[n*2 +: 2]),
        .W_REG_TYPE(M_W_REG_TYPE[n*2 +: 2]),
        .B_REG_TYPE(M_B_REG_TYPE[n*2 +: 2])
    )
    reg_inst (
        .clk(clk),
        .rst(rst),

        /*
         * AXI4 slave interface
         */
        .s_axi_wr(int_axi),

        /*
         * AXI4 master interface
         */
        .m_axi_wr(m_axi_wr[n])
    );

end // m_ifaces

endmodule

`resetall
