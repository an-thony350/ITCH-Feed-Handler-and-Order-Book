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
 * AXI4 crossbar (read)
 */
module taxi_axi_crossbar_rd #
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
    // Read connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    // Number of concurrent operations for each master interface
    // M_COUNT concatenated fields of 32 bits
    parameter M_ISSUE = {M_COUNT{32'd4}},
    // Secure master (fail operations based on awprot/arprot)
    // M_COUNT bits
    parameter M_SECURE = {M_COUNT{1'b0}},
    // Slave interface AR channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_AR_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface R channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_R_REG_TYPE = {S_COUNT{2'd2}},
    // Master interface AR channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_AR_REG_TYPE = {M_COUNT{2'd1}},
    // Master interface R channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_R_REG_TYPE = {M_COUNT{2'd0}}
)
(
    input  wire logic   clk,
    input  wire logic   rst,

    /*
     * AXI4 slave interfaces
     */
    taxi_axi_if.rd_slv  s_axi_rd[S_COUNT],

    /*
     * AXI4 master interfaces
     */
    taxi_axi_if.rd_mst  m_axi_rd[M_COUNT]
);

// extract parameters
localparam DATA_W = s_axi_rd[0].DATA_W;
localparam S_ADDR_W = s_axi_rd[0].ADDR_W;
localparam STRB_W = s_axi_rd[0].STRB_W;
localparam S_ID_W = s_axi_rd[0].ID_W;
localparam M_ID_W = m_axi_rd[0].ID_W;
localparam logic ARUSER_EN = s_axi_rd[0].ARUSER_EN && m_axi_rd[0].ARUSER_EN;
localparam ARUSER_W = s_axi_rd[0].ARUSER_W;
localparam logic RUSER_EN = s_axi_rd[0].RUSER_EN && m_axi_rd[0].RUSER_EN;
localparam RUSER_W = s_axi_rd[0].RUSER_W;

localparam AXI_M_ADDR_W = m_axi_rd[0].ADDR_W;

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
if (s_axi_rd[0].ADDR_W != ADDR_W)
    $fatal(0, "Error: Interface ADDR_W parameter mismatch (instance %m)");

if (m_axi_rd[0].DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (m_axi_rd[0].STRB_W != STRB_W)
    $fatal(0, "Error: Interface STRB_W parameter mismatch (instance %m)");

if (M_ID_W < S_ID_W+$clog2(S_COUNT))
    $fatal(0, "Error: M_ID_W must be at least $clog2(S_COUNT) larger than S_ID_W (instance %m)");

wire [S_ID_W-1:0]    int_s_axi_arid[S_COUNT];
wire [ADDR_W-1:0]    int_s_axi_araddr[S_COUNT];
wire [7:0]           int_s_axi_arlen[S_COUNT];
wire [2:0]           int_s_axi_arsize[S_COUNT];
wire [1:0]           int_s_axi_arburst[S_COUNT];
wire                 int_s_axi_arlock[S_COUNT];
wire [3:0]           int_s_axi_arcache[S_COUNT];
wire [2:0]           int_s_axi_arprot[S_COUNT];
wire [3:0]           int_s_axi_arqos[S_COUNT];
wire [3:0]           int_s_axi_arregion[S_COUNT];
wire [ARUSER_W-1:0]  int_s_axi_aruser[S_COUNT];

logic [M_COUNT-1:0]  int_axi_arvalid[S_COUNT];
logic [S_COUNT-1:0]  int_axi_arready[M_COUNT];

wire [M_ID_W-1:0]    int_m_axi_rid[M_COUNT];
wire [DATA_W-1:0]    int_m_axi_rdata[M_COUNT];
wire [1:0]           int_m_axi_rresp[M_COUNT];
wire                 int_m_axi_rlast[M_COUNT];
wire [RUSER_W-1:0]   int_m_axi_ruser[M_COUNT];

logic [S_COUNT-1:0]  int_axi_rvalid[M_COUNT];
logic [M_COUNT-1:0]  int_axi_rready[S_COUNT];

for (genvar m = 0; m < S_COUNT; m = m + 1) begin : s_ifaces

    taxi_axi_if #(
        .DATA_W(s_axi_rd[0].DATA_W),
        .ADDR_W(s_axi_rd[0].ADDR_W),
        .STRB_W(s_axi_rd[0].STRB_W),
        .ID_W(s_axi_rd[0].ID_W),
        .ARUSER_EN(s_axi_rd[0].ARUSER_EN),
        .ARUSER_W(s_axi_rd[0].ARUSER_W),
        .RUSER_EN(s_axi_rd[0].RUSER_EN),
        .RUSER_W(s_axi_rd[0].RUSER_W)
    ) int_axi();

    // S side register
    taxi_axi_register_rd #(
        .AR_REG_TYPE(S_AR_REG_TYPE[m*2 +: 2]),
        .R_REG_TYPE(S_R_REG_TYPE[m*2 +: 2])
    )
    reg_inst (
        .clk(clk),
        .rst(rst),

        /*
         * AXI4 slave interface
         */
        .s_axi_rd(s_axi_rd[m]),

        /*
         * AXI4 master interface
         */
        .m_axi_rd(int_axi)
    );

    // address decode and admission control
    wire [CL_M_COUNT_INT-1:0] a_select;

    wire m_axi_avalid;
    wire m_axi_aready;

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
        .WC_OUTPUT(0)
    )
    addr_inst (
        .clk(clk),
        .rst(rst),

        /*
         * Address input
         */
        .s_axi_aid(int_axi.arid),
        .s_axi_aaddr(int_axi.araddr),
        .s_axi_aprot(int_axi.arprot),
        .s_axi_aqos(int_axi.arqos),
        .s_axi_avalid(int_axi.arvalid),
        .s_axi_aready(int_axi.arready),

        /*
         * Address output
         */
        .m_axi_aregion(int_s_axi_arregion[m]),
        .m_select(a_select),
        .m_axi_avalid(m_axi_avalid),
        .m_axi_aready(m_axi_aready),

        /*
         * Write command output
         */
        .m_wc_select(),
        .m_wc_decerr(),
        .m_wc_valid(),
        .m_wc_ready(1'b1),

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

    assign int_s_axi_arid[m] = int_axi.arid;
    assign int_s_axi_araddr[m] = int_axi.araddr;
    assign int_s_axi_arlen[m] = int_axi.arlen;
    assign int_s_axi_arsize[m] = int_axi.arsize;
    assign int_s_axi_arburst[m] = int_axi.arburst;
    assign int_s_axi_arlock[m] = int_axi.arlock;
    assign int_s_axi_arcache[m] = int_axi.arcache;
    assign int_s_axi_arprot[m] = int_axi.arprot;
    assign int_s_axi_arqos[m] = int_axi.arqos;
    assign int_s_axi_aruser[m] = int_axi.aruser;

    always_comb begin
        int_axi_arvalid[m] = '0;
        int_axi_arvalid[m][a_select] = m_axi_avalid;
    end
    assign m_axi_aready = int_axi_arready[a_select][m];

    // decode error handling
    logic [S_ID_W-1:0]  decerr_m_axi_rid_reg = '0, decerr_m_axi_rid_next;
    logic               decerr_m_axi_rlast_reg = 1'b0, decerr_m_axi_rlast_next;
    logic               decerr_m_axi_rvalid_reg = 1'b0, decerr_m_axi_rvalid_next;
    wire                decerr_m_axi_rready;

    logic [7:0] decerr_len_reg = 8'd0, decerr_len_next;

    assign m_rc_ready = !decerr_m_axi_rvalid_reg;

    always_comb begin
        decerr_len_next = decerr_len_reg;
        decerr_m_axi_rid_next = decerr_m_axi_rid_reg;
        decerr_m_axi_rlast_next = decerr_m_axi_rlast_reg;
        decerr_m_axi_rvalid_next = decerr_m_axi_rvalid_reg;

        if (decerr_m_axi_rvalid_reg) begin
            if (decerr_m_axi_rready) begin
                if (decerr_len_reg != 0) begin
                    decerr_len_next = decerr_len_reg-1;
                    decerr_m_axi_rlast_next = (decerr_len_next == 0);
                    decerr_m_axi_rvalid_next = 1'b1;
                end else begin
                    decerr_m_axi_rvalid_next = 1'b0;
                end
            end
        end else if (m_rc_valid && m_rc_ready) begin
            decerr_len_next = int_axi.arlen;
            decerr_m_axi_rid_next = int_axi.arid;
            decerr_m_axi_rlast_next = (decerr_len_next == 0);
            decerr_m_axi_rvalid_next = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        decerr_m_axi_rvalid_reg <= decerr_m_axi_rvalid_next;
        decerr_m_axi_rid_reg <= decerr_m_axi_rid_next;
        decerr_m_axi_rlast_reg <= decerr_m_axi_rlast_next;
        decerr_len_reg <= decerr_len_next;

        if (rst) begin
            decerr_m_axi_rvalid_reg <= 1'b0;
        end
    end

    // read response arbitration
    wire [M_COUNT_P1-1:0] r_req;
    wire [M_COUNT_P1-1:0] r_ack;
    wire [M_COUNT_P1-1:0] r_grant;
    wire r_grant_valid;
    wire [CL_M_COUNT_P1-1:0] r_grant_index;

    taxi_arbiter #(
        .PORTS(M_COUNT_P1),
        .ARB_ROUND_ROBIN(1),
        .ARB_BLOCK(1),
        .ARB_BLOCK_ACK(1),
        .LSB_HIGH_PRIO(1)
    )
    r_arb_inst (
        .clk(clk),
        .rst(rst),
        .req(r_req),
        .ack(r_ack),
        .grant(r_grant),
        .grant_valid(r_grant_valid),
        .grant_index(r_grant_index)
    );

    // read response mux
    always_comb begin
        if (r_grant_index == CL_M_COUNT_P1'(M_COUNT_P1-1)) begin
            int_axi.rid    = decerr_m_axi_rid_reg;
            int_axi.rdata  = '0;
            int_axi.rresp  = 2'b11;
            int_axi.rlast  = decerr_m_axi_rlast_reg;
            int_axi.ruser  = '0;
            int_axi.rvalid = decerr_m_axi_rvalid_reg & r_grant_valid;
        end else begin
            int_axi.rid    = S_ID_W'(int_m_axi_rid[r_grant_index[CL_M_COUNT_INT-1:0]]);
            int_axi.rdata  = int_m_axi_rdata[r_grant_index[CL_M_COUNT_INT-1:0]];
            int_axi.rresp  = int_m_axi_rresp[r_grant_index[CL_M_COUNT_INT-1:0]];
            int_axi.rlast  = int_m_axi_rlast[r_grant_index[CL_M_COUNT_INT-1:0]];
            int_axi.ruser  = int_m_axi_ruser[r_grant_index[CL_M_COUNT_INT-1:0]];
            int_axi.rvalid = int_axi_rvalid[r_grant_index[CL_M_COUNT_INT-1:0]][m] & r_grant_valid;
        end
    end

    always_comb begin
        int_axi_rready[m] = '0;
        int_axi_rready[m][r_grant_index[CL_M_COUNT_INT-1:0]] = r_grant_valid && int_axi.rready;
    end

    assign decerr_m_axi_rready = (r_grant_valid && int_axi.rready) && (r_grant_index == CL_M_COUNT_P1'(M_COUNT_P1-1));

    for (genvar n = 0; n < M_COUNT; n = n + 1) begin
        assign r_req[n] = int_axi_rvalid[n][m] && !r_grant[n];
        assign r_ack[n] = r_grant_valid && int_axi_rvalid[n][m] && int_axi.rlast && int_axi.rready;
    end

    assign r_req[M_COUNT_P1-1] = decerr_m_axi_rvalid_reg && !r_grant[M_COUNT_P1-1];
    assign r_ack[M_COUNT_P1-1] = r_grant_valid && decerr_m_axi_rvalid_reg && decerr_m_axi_rlast_reg && int_axi.rready;

    assign s_cpl_id = int_axi.rid;
    assign s_cpl_valid = int_axi.rvalid && int_axi.rready && int_axi.rlast;

end // s_ifaces

for (genvar n = 0; n < M_COUNT; n = n + 1) begin : m_ifaces

    taxi_axi_if #(
        .DATA_W(m_axi_rd[0].DATA_W),
        .ADDR_W(m_axi_rd[0].ADDR_W),
        .STRB_W(m_axi_rd[0].STRB_W),
        .ID_W(m_axi_rd[0].ID_W),
        .ARUSER_EN(m_axi_rd[0].ARUSER_EN),
        .ARUSER_W(m_axi_rd[0].ARUSER_W),
        .RUSER_EN(m_axi_rd[0].RUSER_EN),
        .RUSER_W(m_axi_rd[0].RUSER_W)
    ) int_axi();

    // in-flight transaction count
    wire trans_start;
    wire trans_complete;
    localparam TR_CNT_W = $clog2(M_ISSUE_INT[n]+1);
    logic [TR_CNT_W-1:0] trans_count_reg = '0;

    wire trans_limit = trans_count_reg >= TR_CNT_W'(M_ISSUE_INT[n]) && !trans_complete;

    always_ff @(posedge clk) begin
        if (rst) begin
            trans_count_reg <= 0;
        end else begin
            if (trans_start && !trans_complete) begin
                trans_count_reg <= trans_count_reg + 1;
            end else if (!trans_start && trans_complete) begin
                trans_count_reg <= trans_count_reg - 1;
            end
        end
    end

    // address arbitration
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
        assign int_axi.arid = {a_grant_index, int_s_axi_arid[a_grant_index]};
    end else begin
        assign int_axi.arid = int_s_axi_arid[a_grant_index];
    end
    assign int_axi.araddr   = AXI_M_ADDR_W'(int_s_axi_araddr[a_grant_index]);
    assign int_axi.arlen    = int_s_axi_arlen[a_grant_index];
    assign int_axi.arsize   = int_s_axi_arsize[a_grant_index];
    assign int_axi.arburst  = int_s_axi_arburst[a_grant_index];
    assign int_axi.arlock   = int_s_axi_arlock[a_grant_index];
    assign int_axi.arcache  = int_s_axi_arcache[a_grant_index];
    assign int_axi.arprot   = int_s_axi_arprot[a_grant_index];
    assign int_axi.arqos    = int_s_axi_arqos[a_grant_index];
    assign int_axi.arregion = int_s_axi_arregion[a_grant_index];
    assign int_axi.aruser   = int_s_axi_aruser[a_grant_index];
    assign int_axi.arvalid  = int_axi_arvalid[a_grant_index][n] && a_grant_valid;

    always_comb begin
        int_axi_arready[n] = '0;
        int_axi_arready[n][a_grant_index] = a_grant_valid && int_axi.arready;
    end

    for (genvar m = 0; m < S_COUNT; m = m + 1) begin
        assign a_req[m] = int_axi_arvalid[m][n] && !a_grant_valid && !trans_limit;
        assign a_ack[m] = a_grant[m] && int_axi_arvalid[m][n] && int_axi.arready;
    end

    assign trans_start = int_axi.arvalid && int_axi.arready && a_grant_valid;

    // read response forwarding
    wire [CL_S_COUNT_INT-1:0] r_select = CL_S_COUNT_INT'(int_axi.rid >> S_ID_W);

    assign int_m_axi_rid[n]   = int_axi.rid;
    assign int_m_axi_rdata[n] = int_axi.rdata;
    assign int_m_axi_rresp[n] = int_axi.rresp;
    assign int_m_axi_rlast[n] = int_axi.rlast;
    assign int_m_axi_ruser[n] = int_axi.ruser;

    always_comb begin
        int_axi_rvalid[n] = '0;
        int_axi_rvalid[n][r_select] = int_axi.rvalid;
    end
    assign int_axi.rready = int_axi_rready[r_select][n];

    assign trans_complete = int_axi.rvalid && int_axi.rready && int_axi.rlast;

    // M side register
    taxi_axi_register_rd #(
        .AR_REG_TYPE(M_AR_REG_TYPE[n*2 +: 2]),
        .R_REG_TYPE(M_R_REG_TYPE[n*2 +: 2])
    )
    reg_inst (
        .clk(clk),
        .rst(rst),

        /*
         * AXI4 slave interface
         */
        .s_axi_rd(int_axi),

        /*
         * AXI4 master interface
         */
        .m_axi_rd(m_axi_rd[n])
    );

end // m_ifaces

endmodule

`resetall
