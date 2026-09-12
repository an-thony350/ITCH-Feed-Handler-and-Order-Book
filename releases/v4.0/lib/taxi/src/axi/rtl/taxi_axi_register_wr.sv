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
 * AXI4 register (write)
 */
module taxi_axi_register_wr #
(
    // AW channel register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter AW_REG_TYPE = 1,
    // W channel register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter W_REG_TYPE = 2,
    // B channel register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter B_REG_TYPE = 1
)
(
    input  wire logic   clk,
    input  wire logic   rst,

    /*
     * AXI4 slave interface
     */
    taxi_axi_if.wr_slv  s_axi_wr,

    /*
     * AXI4 master interface
     */
    taxi_axi_if.wr_mst  m_axi_wr
);

// extract parameters
localparam DATA_W = s_axi_wr.DATA_W;
localparam ADDR_W = s_axi_wr.ADDR_W;
localparam STRB_W = s_axi_wr.STRB_W;
localparam ID_W = s_axi_wr.ID_W;
localparam logic AWUSER_EN = s_axi_wr.AWUSER_EN && m_axi_wr.AWUSER_EN;
localparam AWUSER_W = s_axi_wr.AWUSER_W;
localparam logic WUSER_EN = s_axi_wr.WUSER_EN && m_axi_wr.WUSER_EN;
localparam WUSER_W = s_axi_wr.WUSER_W;
localparam logic BUSER_EN = s_axi_wr.BUSER_EN && m_axi_wr.BUSER_EN;
localparam BUSER_W = s_axi_wr.BUSER_W;

if (m_axi_wr.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (m_axi_wr.STRB_W != STRB_W)
    $fatal(0, "Error: Interface STRB_W parameter mismatch (instance %m)");

// AW channel

if (AW_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                 s_axi_awready_reg = 1'b0;

    logic [ID_W-1:0]      m_axi_awid_reg     = '0;
    logic [ADDR_W-1:0]    m_axi_awaddr_reg   = '0;
    logic [7:0]           m_axi_awlen_reg    = '0;
    logic [2:0]           m_axi_awsize_reg   = '0;
    logic [1:0]           m_axi_awburst_reg  = '0;
    logic                 m_axi_awlock_reg   = '0;
    logic [3:0]           m_axi_awcache_reg  = '0;
    logic [2:0]           m_axi_awprot_reg   = '0;
    logic [3:0]           m_axi_awqos_reg    = '0;
    logic [3:0]           m_axi_awregion_reg = '0;
    logic [AWUSER_W-1:0]  m_axi_awuser_reg   = '0;
    logic                 m_axi_awvalid_reg  = 1'b0, m_axi_awvalid_next;

    logic [ID_W-1:0]      temp_m_axi_awid_reg     = '0;
    logic [ADDR_W-1:0]    temp_m_axi_awaddr_reg   = '0;
    logic [7:0]           temp_m_axi_awlen_reg    = '0;
    logic [2:0]           temp_m_axi_awsize_reg   = '0;
    logic [1:0]           temp_m_axi_awburst_reg  = '0;
    logic                 temp_m_axi_awlock_reg   = '0;
    logic [3:0]           temp_m_axi_awcache_reg  = '0;
    logic [2:0]           temp_m_axi_awprot_reg   = '0;
    logic [3:0]           temp_m_axi_awqos_reg    = '0;
    logic [3:0]           temp_m_axi_awregion_reg = '0;
    logic [AWUSER_W-1:0]  temp_m_axi_awuser_reg   = '0;
    logic                 temp_m_axi_awvalid_reg  = 1'b0, temp_m_axi_awvalid_next;

    // datapath control
    logic store_axi_aw_input_to_output;
    logic store_axi_aw_input_to_temp;
    logic store_axi_aw_temp_to_output;

    assign s_axi_wr.awready  = s_axi_awready_reg;

    assign m_axi_wr.awid     = m_axi_awid_reg;
    assign m_axi_wr.awaddr   = m_axi_awaddr_reg;
    assign m_axi_wr.awlen    = m_axi_awlen_reg;
    assign m_axi_wr.awsize   = m_axi_awsize_reg;
    assign m_axi_wr.awburst  = m_axi_awburst_reg;
    assign m_axi_wr.awlock   = m_axi_awlock_reg;
    assign m_axi_wr.awcache  = m_axi_awcache_reg;
    assign m_axi_wr.awprot   = m_axi_awprot_reg;
    assign m_axi_wr.awqos    = m_axi_awqos_reg;
    assign m_axi_wr.awregion = m_axi_awregion_reg;
    assign m_axi_wr.awuser   = AWUSER_EN ? m_axi_awuser_reg : '0;
    assign m_axi_wr.awvalid  = m_axi_awvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire s_axi_awready_early = m_axi_wr.awready || (!temp_m_axi_awvalid_reg && (!m_axi_awvalid_reg || !s_axi_wr.awvalid));

    always_comb begin
        // transfer sink ready state to source
        m_axi_awvalid_next = m_axi_awvalid_reg;
        temp_m_axi_awvalid_next = temp_m_axi_awvalid_reg;

        store_axi_aw_input_to_output = 1'b0;
        store_axi_aw_input_to_temp = 1'b0;
        store_axi_aw_temp_to_output = 1'b0;

        if (s_axi_awready_reg) begin
            // input is ready
            if (m_axi_wr.awready || !m_axi_awvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                m_axi_awvalid_next = s_axi_wr.awvalid;
                store_axi_aw_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_m_axi_awvalid_next = s_axi_wr.awvalid;
                store_axi_aw_input_to_temp = 1'b1;
            end
        end else if (m_axi_wr.awready) begin
            // input is not ready, but output is ready
            m_axi_awvalid_next = temp_m_axi_awvalid_reg;
            temp_m_axi_awvalid_next = 1'b0;
            store_axi_aw_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        s_axi_awready_reg <= s_axi_awready_early;
        m_axi_awvalid_reg <= m_axi_awvalid_next;
        temp_m_axi_awvalid_reg <= temp_m_axi_awvalid_next;

        // datapath
        if (store_axi_aw_input_to_output) begin
            m_axi_awid_reg <= s_axi_wr.awid;
            m_axi_awaddr_reg <= s_axi_wr.awaddr;
            m_axi_awlen_reg <= s_axi_wr.awlen;
            m_axi_awsize_reg <= s_axi_wr.awsize;
            m_axi_awburst_reg <= s_axi_wr.awburst;
            m_axi_awlock_reg <= s_axi_wr.awlock;
            m_axi_awcache_reg <= s_axi_wr.awcache;
            m_axi_awprot_reg <= s_axi_wr.awprot;
            m_axi_awqos_reg <= s_axi_wr.awqos;
            m_axi_awregion_reg <= s_axi_wr.awregion;
            m_axi_awuser_reg <= s_axi_wr.awuser;
        end else if (store_axi_aw_temp_to_output) begin
            m_axi_awid_reg <= temp_m_axi_awid_reg;
            m_axi_awaddr_reg <= temp_m_axi_awaddr_reg;
            m_axi_awlen_reg <= temp_m_axi_awlen_reg;
            m_axi_awsize_reg <= temp_m_axi_awsize_reg;
            m_axi_awburst_reg <= temp_m_axi_awburst_reg;
            m_axi_awlock_reg <= temp_m_axi_awlock_reg;
            m_axi_awcache_reg <= temp_m_axi_awcache_reg;
            m_axi_awprot_reg <= temp_m_axi_awprot_reg;
            m_axi_awqos_reg <= temp_m_axi_awqos_reg;
            m_axi_awregion_reg <= temp_m_axi_awregion_reg;
            m_axi_awuser_reg <= temp_m_axi_awuser_reg;
        end

        if (store_axi_aw_input_to_temp) begin
            temp_m_axi_awid_reg <= s_axi_wr.awid;
            temp_m_axi_awaddr_reg <= s_axi_wr.awaddr;
            temp_m_axi_awlen_reg <= s_axi_wr.awlen;
            temp_m_axi_awsize_reg <= s_axi_wr.awsize;
            temp_m_axi_awburst_reg <= s_axi_wr.awburst;
            temp_m_axi_awlock_reg <= s_axi_wr.awlock;
            temp_m_axi_awcache_reg <= s_axi_wr.awcache;
            temp_m_axi_awprot_reg <= s_axi_wr.awprot;
            temp_m_axi_awqos_reg <= s_axi_wr.awqos;
            temp_m_axi_awregion_reg <= s_axi_wr.awregion;
            temp_m_axi_awuser_reg <= s_axi_wr.awuser;
        end

        if (rst) begin
            s_axi_awready_reg <= 1'b0;
            m_axi_awvalid_reg <= 1'b0;
            temp_m_axi_awvalid_reg <= 1'b0;
        end
    end

end else if (AW_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                 s_axi_awready_reg = 1'b0;

    logic [ID_W-1:0]      m_axi_awid_reg     = '0;
    logic [ADDR_W-1:0]    m_axi_awaddr_reg   = '0;
    logic [7:0]           m_axi_awlen_reg    = '0;
    logic [2:0]           m_axi_awsize_reg   = '0;
    logic [1:0]           m_axi_awburst_reg  = '0;
    logic                 m_axi_awlock_reg   = '0;
    logic [3:0]           m_axi_awcache_reg  = '0;
    logic [2:0]           m_axi_awprot_reg   = '0;
    logic [3:0]           m_axi_awqos_reg    = '0;
    logic [3:0]           m_axi_awregion_reg = '0;
    logic [AWUSER_W-1:0]  m_axi_awuser_reg   = '0;
    logic                 m_axi_awvalid_reg  = 1'b0, m_axi_awvalid_next;

    // datapath control
    logic store_axi_aw_input_to_output;

    assign s_axi_wr.awready  = s_axi_awready_reg;

    assign m_axi_wr.awid     = m_axi_awid_reg;
    assign m_axi_wr.awaddr   = m_axi_awaddr_reg;
    assign m_axi_wr.awlen    = m_axi_awlen_reg;
    assign m_axi_wr.awsize   = m_axi_awsize_reg;
    assign m_axi_wr.awburst  = m_axi_awburst_reg;
    assign m_axi_wr.awlock   = m_axi_awlock_reg;
    assign m_axi_wr.awcache  = m_axi_awcache_reg;
    assign m_axi_wr.awprot   = m_axi_awprot_reg;
    assign m_axi_wr.awqos    = m_axi_awqos_reg;
    assign m_axi_wr.awregion = m_axi_awregion_reg;
    assign m_axi_wr.awuser   = AWUSER_EN ? m_axi_awuser_reg : '0;
    assign m_axi_wr.awvalid  = m_axi_awvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire s_axi_awready_eawly = !m_axi_awvalid_next;

    always_comb begin
        // transfer sink ready state to source
        m_axi_awvalid_next = m_axi_awvalid_reg;

        store_axi_aw_input_to_output = 1'b0;

        if (s_axi_awready_reg) begin
            m_axi_awvalid_next = s_axi_wr.awvalid;
            store_axi_aw_input_to_output = 1'b1;
        end else if (m_axi_wr.awready) begin
            m_axi_awvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        s_axi_awready_reg <= s_axi_awready_eawly;
        m_axi_awvalid_reg <= m_axi_awvalid_next;

        // datapath
        if (store_axi_aw_input_to_output) begin
            m_axi_awid_reg <= s_axi_wr.awid;
            m_axi_awaddr_reg <= s_axi_wr.awaddr;
            m_axi_awlen_reg <= s_axi_wr.awlen;
            m_axi_awsize_reg <= s_axi_wr.awsize;
            m_axi_awburst_reg <= s_axi_wr.awburst;
            m_axi_awlock_reg <= s_axi_wr.awlock;
            m_axi_awcache_reg <= s_axi_wr.awcache;
            m_axi_awprot_reg <= s_axi_wr.awprot;
            m_axi_awqos_reg <= s_axi_wr.awqos;
            m_axi_awregion_reg <= s_axi_wr.awregion;
            m_axi_awuser_reg <= s_axi_wr.awuser;
        end

        if (rst) begin
            s_axi_awready_reg <= 1'b0;
            m_axi_awvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass AW channel
    assign m_axi_wr.awid = s_axi_wr.awid;
    assign m_axi_wr.awaddr = s_axi_wr.awaddr;
    assign m_axi_wr.awlen = s_axi_wr.awlen;
    assign m_axi_wr.awsize = s_axi_wr.awsize;
    assign m_axi_wr.awburst = s_axi_wr.awburst;
    assign m_axi_wr.awlock = s_axi_wr.awlock;
    assign m_axi_wr.awcache = s_axi_wr.awcache;
    assign m_axi_wr.awprot = s_axi_wr.awprot;
    assign m_axi_wr.awqos = s_axi_wr.awqos;
    assign m_axi_wr.awregion = s_axi_wr.awregion;
    assign m_axi_wr.awuser = AWUSER_EN ? s_axi_wr.awuser : '0;
    assign m_axi_wr.awvalid = s_axi_wr.awvalid;
    assign s_axi_wr.awready = m_axi_wr.awready;

end

// W channel

if (W_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                s_axi_wready_reg = 1'b0;

    logic [DATA_W-1:0]   m_axi_wdata_reg  = '0;
    logic [STRB_W-1:0]   m_axi_wstrb_reg  = '0;
    logic                m_axi_wlast_reg  = 1'b0;
    logic [WUSER_W-1:0]  m_axi_wuser_reg  = '0;
    logic                m_axi_wvalid_reg = 1'b0, m_axi_wvalid_next;

    logic [DATA_W-1:0]   temp_m_axi_wdata_reg  = '0;
    logic [STRB_W-1:0]   temp_m_axi_wstrb_reg  = '0;
    logic                temp_m_axi_wlast_reg  = 1'b0;
    logic [WUSER_W-1:0]  temp_m_axi_wuser_reg  = '0;
    logic                temp_m_axi_wvalid_reg = 1'b0, temp_m_axi_wvalid_next;

    // datapath control
    logic store_axi_w_input_to_output;
    logic store_axi_w_input_to_temp;
    logic store_axi_w_temp_to_output;

    assign s_axi_wr.wready = s_axi_wready_reg;

    assign m_axi_wr.wdata  = m_axi_wdata_reg;
    assign m_axi_wr.wstrb  = m_axi_wstrb_reg;
    assign m_axi_wr.wlast  = m_axi_wlast_reg;
    assign m_axi_wr.wuser  = WUSER_EN ? m_axi_wuser_reg : '0;
    assign m_axi_wr.wvalid = m_axi_wvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire s_axi_wready_early = m_axi_wr.wready || (!temp_m_axi_wvalid_reg && (!m_axi_wvalid_reg || !s_axi_wr.wvalid));

    always_comb begin
        // transfer sink ready state to source
        m_axi_wvalid_next = m_axi_wvalid_reg;
        temp_m_axi_wvalid_next = temp_m_axi_wvalid_reg;

        store_axi_w_input_to_output = 1'b0;
        store_axi_w_input_to_temp = 1'b0;
        store_axi_w_temp_to_output = 1'b0;

        if (s_axi_wready_reg) begin
            // input is ready
            if (m_axi_wr.wready || !m_axi_wvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                m_axi_wvalid_next = s_axi_wr.wvalid;
                store_axi_w_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_m_axi_wvalid_next = s_axi_wr.wvalid;
                store_axi_w_input_to_temp = 1'b1;
            end
        end else if (m_axi_wr.wready) begin
            // input is not ready, but output is ready
            m_axi_wvalid_next = temp_m_axi_wvalid_reg;
            temp_m_axi_wvalid_next = 1'b0;
            store_axi_w_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        s_axi_wready_reg <= s_axi_wready_early;
        m_axi_wvalid_reg <= m_axi_wvalid_next;
        temp_m_axi_wvalid_reg <= temp_m_axi_wvalid_next;

        // datapath
        if (store_axi_w_input_to_output) begin
            m_axi_wdata_reg <= s_axi_wr.wdata;
            m_axi_wstrb_reg <= s_axi_wr.wstrb;
            m_axi_wlast_reg <= s_axi_wr.wlast;
            m_axi_wuser_reg <= s_axi_wr.wuser;
        end else if (store_axi_w_temp_to_output) begin
            m_axi_wdata_reg <= temp_m_axi_wdata_reg;
            m_axi_wstrb_reg <= temp_m_axi_wstrb_reg;
            m_axi_wlast_reg <= temp_m_axi_wlast_reg;
            m_axi_wuser_reg <= temp_m_axi_wuser_reg;
        end

        if (store_axi_w_input_to_temp) begin
            temp_m_axi_wdata_reg <= s_axi_wr.wdata;
            temp_m_axi_wstrb_reg <= s_axi_wr.wstrb;
            temp_m_axi_wlast_reg <= s_axi_wr.wlast;
            temp_m_axi_wuser_reg <= s_axi_wr.wuser;
        end

        if (rst) begin
            s_axi_wready_reg <= 1'b0;
            m_axi_wvalid_reg <= 1'b0;
            temp_m_axi_wvalid_reg <= 1'b0;
        end
    end

end else if (W_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                s_axi_wready_reg = 1'b0;

    logic [DATA_W-1:0]   m_axi_wdata_reg  = '0;
    logic [STRB_W-1:0]   m_axi_wstrb_reg  = '0;
    logic                m_axi_wlast_reg  = 1'b0;
    logic [WUSER_W-1:0]  m_axi_wuser_reg  = '0;
    logic                m_axi_wvalid_reg = 1'b0, m_axi_wvalid_next;

    // datapath control
    logic store_axi_w_input_to_output;

    assign s_axi_wr.wready = s_axi_wready_reg;

    assign m_axi_wr.wdata  = m_axi_wdata_reg;
    assign m_axi_wr.wstrb  = m_axi_wstrb_reg;
    assign m_axi_wr.wlast  = m_axi_wlast_reg;
    assign m_axi_wr.wuser  = WUSER_EN ? m_axi_wuser_reg : '0;
    assign m_axi_wr.wvalid = m_axi_wvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire s_axi_wready_ewly = !m_axi_wvalid_next;

    always_comb begin
        // transfer sink ready state to source
        m_axi_wvalid_next = m_axi_wvalid_reg;

        store_axi_w_input_to_output = 1'b0;

        if (s_axi_wready_reg) begin
            m_axi_wvalid_next = s_axi_wr.wvalid;
            store_axi_w_input_to_output = 1'b1;
        end else if (m_axi_wr.wready) begin
            m_axi_wvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        s_axi_wready_reg <= s_axi_wready_ewly;
        m_axi_wvalid_reg <= m_axi_wvalid_next;

        // datapath
        if (store_axi_w_input_to_output) begin
            m_axi_wdata_reg <= s_axi_wr.wdata;
            m_axi_wstrb_reg <= s_axi_wr.wstrb;
            m_axi_wlast_reg <= s_axi_wr.wlast;
            m_axi_wuser_reg <= s_axi_wr.wuser;
        end

        if (rst) begin
            s_axi_wready_reg <= 1'b0;
            m_axi_wvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass W channel
    assign m_axi_wr.wdata = s_axi_wr.wdata;
    assign m_axi_wr.wstrb = s_axi_wr.wstrb;
    assign m_axi_wr.wlast = s_axi_wr.wlast;
    assign m_axi_wr.wuser = WUSER_EN ? s_axi_wr.wuser : '0;
    assign m_axi_wr.wvalid = s_axi_wr.wvalid;
    assign s_axi_wr.wready = m_axi_wr.wready;

end

// B channel

if (B_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                m_axi_bready_reg = 1'b0;

    logic [ID_W-1:0]     s_axi_bid_reg    = '0;
    logic [1:0]          s_axi_bresp_reg  = 2'b0;
    logic [BUSER_W-1:0]  s_axi_buser_reg  = '0;
    logic                s_axi_bvalid_reg = 1'b0, s_axi_bvalid_next;

    logic [ID_W-1:0]     temp_s_axi_bid_reg    = '0;
    logic [1:0]          temp_s_axi_bresp_reg  = 2'b0;
    logic [BUSER_W-1:0]  temp_s_axi_buser_reg  = '0;
    logic                temp_s_axi_bvalid_reg = 1'b0, temp_s_axi_bvalid_next;

    // datapath control
    logic store_axi_b_input_to_output;
    logic store_axi_b_input_to_temp;
    logic store_axi_b_temp_to_output;

    assign m_axi_wr.bready = m_axi_bready_reg;

    assign s_axi_wr.bid    = s_axi_bid_reg;
    assign s_axi_wr.bresp  = s_axi_bresp_reg;
    assign s_axi_wr.buser  = BUSER_EN ? s_axi_buser_reg : '0;
    assign s_axi_wr.bvalid = s_axi_bvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire m_axi_bready_early = s_axi_wr.bready || (!temp_s_axi_bvalid_reg && (!s_axi_bvalid_reg || !m_axi_wr.bvalid));

    always_comb begin
        // transfer sink ready state to source
        s_axi_bvalid_next = s_axi_bvalid_reg;
        temp_s_axi_bvalid_next = temp_s_axi_bvalid_reg;

        store_axi_b_input_to_output = 1'b0;
        store_axi_b_input_to_temp = 1'b0;
        store_axi_b_temp_to_output = 1'b0;

        if (m_axi_bready_reg) begin
            // input is ready
            if (s_axi_wr.bready || !s_axi_bvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                s_axi_bvalid_next = m_axi_wr.bvalid;
                store_axi_b_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_s_axi_bvalid_next = m_axi_wr.bvalid;
                store_axi_b_input_to_temp = 1'b1;
            end
        end else if (s_axi_wr.bready) begin
            // input is not ready, but output is ready
            s_axi_bvalid_next = temp_s_axi_bvalid_reg;
            temp_s_axi_bvalid_next = 1'b0;
            store_axi_b_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        m_axi_bready_reg <= m_axi_bready_early;
        s_axi_bvalid_reg <= s_axi_bvalid_next;
        temp_s_axi_bvalid_reg <= temp_s_axi_bvalid_next;

        // datapath
        if (store_axi_b_input_to_output) begin
            s_axi_bid_reg   <= m_axi_wr.bid;
            s_axi_bresp_reg <= m_axi_wr.bresp;
            s_axi_buser_reg <= m_axi_wr.buser;
        end else if (store_axi_b_temp_to_output) begin
            s_axi_bid_reg   <= temp_s_axi_bid_reg;
            s_axi_bresp_reg <= temp_s_axi_bresp_reg;
            s_axi_buser_reg <= temp_s_axi_buser_reg;
        end

        if (store_axi_b_input_to_temp) begin
            temp_s_axi_bid_reg   <= m_axi_wr.bid;
            temp_s_axi_bresp_reg <= m_axi_wr.bresp;
            temp_s_axi_buser_reg <= m_axi_wr.buser;
        end

        if (rst) begin
            m_axi_bready_reg <= 1'b0;
            s_axi_bvalid_reg <= 1'b0;
            temp_s_axi_bvalid_reg <= 1'b0;
        end
    end

end else if (B_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                m_axi_bready_reg = 1'b0;

    logic [ID_W-1:0]     s_axi_bid_reg    = '0;
    logic [1:0]          s_axi_bresp_reg  = 2'b0;
    logic [BUSER_W-1:0]  s_axi_buser_reg  = '0;
    logic                s_axi_bvalid_reg = 1'b0, s_axi_bvalid_next;

    // datapath control
    logic store_axi_b_input_to_output;

    assign m_axi_wr.bready = m_axi_bready_reg;

    assign s_axi_wr.bid    = s_axi_bid_reg;
    assign s_axi_wr.bresp  = s_axi_bresp_reg;
    assign s_axi_wr.buser  = BUSER_EN ? s_axi_buser_reg : '0;
    assign s_axi_wr.bvalid = s_axi_bvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire m_axi_bready_early = !s_axi_bvalid_next;

    always_comb begin
        // transfer sink ready state to source
        s_axi_bvalid_next = s_axi_bvalid_reg;

        store_axi_b_input_to_output = 1'b0;

        if (m_axi_bready_reg) begin
            s_axi_bvalid_next = m_axi_wr.bvalid;
            store_axi_b_input_to_output = 1'b1;
        end else if (s_axi_wr.bready) begin
            s_axi_bvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        m_axi_bready_reg <= m_axi_bready_early;
        s_axi_bvalid_reg <= s_axi_bvalid_next;

        // datapath
        if (store_axi_b_input_to_output) begin
            s_axi_bid_reg   <= m_axi_wr.bid;
            s_axi_bresp_reg <= m_axi_wr.bresp;
            s_axi_buser_reg <= m_axi_wr.buser;
        end

        if (rst) begin
            m_axi_bready_reg <= 1'b0;
            s_axi_bvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass B channel
    assign s_axi_wr.bid = m_axi_wr.bid;
    assign s_axi_wr.bresp = m_axi_wr.bresp;
    assign s_axi_wr.buser = BUSER_EN ? m_axi_wr.buser : '0;
    assign s_axi_wr.bvalid = m_axi_wr.bvalid;
    assign m_axi_wr.bready = s_axi_wr.bready;

end

endmodule

`resetall
