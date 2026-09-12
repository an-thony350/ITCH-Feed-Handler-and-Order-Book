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
 * AXI4 register (read)
 */
module taxi_axi_register_rd #
(
    // AR channel register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter AR_REG_TYPE = 1,
    // R channel register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter R_REG_TYPE = 2
)
(
    input  wire logic   clk,
    input  wire logic   rst,

    /*
     * AXI4 slave interface
     */
    taxi_axi_if.rd_slv  s_axi_rd,

    /*
     * AXI4 master interface
     */
    taxi_axi_if.rd_mst  m_axi_rd
);

// extract parameters
localparam DATA_W = s_axi_rd.DATA_W;
localparam ADDR_W = s_axi_rd.ADDR_W;
localparam STRB_W = s_axi_rd.STRB_W;
localparam ID_W = s_axi_rd.ID_W;
localparam logic ARUSER_EN = s_axi_rd.ARUSER_EN && m_axi_rd.ARUSER_EN;
localparam ARUSER_W = s_axi_rd.ARUSER_W;
localparam logic RUSER_EN = s_axi_rd.RUSER_EN && m_axi_rd.RUSER_EN;
localparam RUSER_W = s_axi_rd.RUSER_W;

if (m_axi_rd.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (m_axi_rd.STRB_W != STRB_W)
    $fatal(0, "Error: Interface STRB_W parameter mismatch (instance %m)");

// AR channel

if (AR_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                 s_axi_arready_reg = 1'b0;

    logic [ID_W-1:0]      m_axi_arid_reg     = '0;
    logic [ADDR_W-1:0]    m_axi_araddr_reg   = '0;
    logic [7:0]           m_axi_arlen_reg    = '0;
    logic [2:0]           m_axi_arsize_reg   = '0;
    logic [1:0]           m_axi_arburst_reg  = '0;
    logic                 m_axi_arlock_reg   = '0;
    logic [3:0]           m_axi_arcache_reg  = '0;
    logic [2:0]           m_axi_arprot_reg   = '0;
    logic [3:0]           m_axi_arqos_reg    = '0;
    logic [3:0]           m_axi_arregion_reg = '0;
    logic [ARUSER_W-1:0]  m_axi_aruser_reg   = '0;
    logic                 m_axi_arvalid_reg  = 1'b0, m_axi_arvalid_next;

    logic [ID_W-1:0]      temp_m_axi_arid_reg     = '0;
    logic [ADDR_W-1:0]    temp_m_axi_araddr_reg   = '0;
    logic [7:0]           temp_m_axi_arlen_reg    = '0;
    logic [2:0]           temp_m_axi_arsize_reg   = '0;
    logic [1:0]           temp_m_axi_arburst_reg  = '0;
    logic                 temp_m_axi_arlock_reg   = '0;
    logic [3:0]           temp_m_axi_arcache_reg  = '0;
    logic [2:0]           temp_m_axi_arprot_reg   = '0;
    logic [3:0]           temp_m_axi_arqos_reg    = '0;
    logic [3:0]           temp_m_axi_arregion_reg = '0;
    logic [ARUSER_W-1:0]  temp_m_axi_aruser_reg   = '0;
    logic                 temp_m_axi_arvalid_reg  = 1'b0, temp_m_axi_arvalid_next;

    // datapath control
    logic store_axi_ar_input_to_output;
    logic store_axi_ar_input_to_temp;
    logic store_axi_ar_temp_to_output;

    assign s_axi_rd.arready  = s_axi_arready_reg;

    assign m_axi_rd.arid     = m_axi_arid_reg;
    assign m_axi_rd.araddr   = m_axi_araddr_reg;
    assign m_axi_rd.arlen    = m_axi_arlen_reg;
    assign m_axi_rd.arsize   = m_axi_arsize_reg;
    assign m_axi_rd.arburst  = m_axi_arburst_reg;
    assign m_axi_rd.arlock   = m_axi_arlock_reg;
    assign m_axi_rd.arcache  = m_axi_arcache_reg;
    assign m_axi_rd.arprot   = m_axi_arprot_reg;
    assign m_axi_rd.arqos    = m_axi_arqos_reg;
    assign m_axi_rd.arregion = m_axi_arregion_reg;
    assign m_axi_rd.aruser   = ARUSER_EN ? m_axi_aruser_reg : '0;
    assign m_axi_rd.arvalid  = m_axi_arvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire s_axi_arready_early = m_axi_rd.arready || (!temp_m_axi_arvalid_reg && (!m_axi_arvalid_reg || !s_axi_rd.arvalid));

    always_comb begin
        // transfer sink ready state to source
        m_axi_arvalid_next = m_axi_arvalid_reg;
        temp_m_axi_arvalid_next = temp_m_axi_arvalid_reg;

        store_axi_ar_input_to_output = 1'b0;
        store_axi_ar_input_to_temp = 1'b0;
        store_axi_ar_temp_to_output = 1'b0;

        if (s_axi_arready_reg) begin
            // input is ready
            if (m_axi_rd.arready || !m_axi_arvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                m_axi_arvalid_next = s_axi_rd.arvalid;
                store_axi_ar_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_m_axi_arvalid_next = s_axi_rd.arvalid;
                store_axi_ar_input_to_temp = 1'b1;
            end
        end else if (m_axi_rd.arready) begin
            // input is not ready, but output is ready
            m_axi_arvalid_next = temp_m_axi_arvalid_reg;
            temp_m_axi_arvalid_next = 1'b0;
            store_axi_ar_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        s_axi_arready_reg <= s_axi_arready_early;
        m_axi_arvalid_reg <= m_axi_arvalid_next;
        temp_m_axi_arvalid_reg <= temp_m_axi_arvalid_next;

        // datapath
        if (store_axi_ar_input_to_output) begin
            m_axi_arid_reg <= s_axi_rd.arid;
            m_axi_araddr_reg <= s_axi_rd.araddr;
            m_axi_arlen_reg <= s_axi_rd.arlen;
            m_axi_arsize_reg <= s_axi_rd.arsize;
            m_axi_arburst_reg <= s_axi_rd.arburst;
            m_axi_arlock_reg <= s_axi_rd.arlock;
            m_axi_arcache_reg <= s_axi_rd.arcache;
            m_axi_arprot_reg <= s_axi_rd.arprot;
            m_axi_arqos_reg <= s_axi_rd.arqos;
            m_axi_arregion_reg <= s_axi_rd.arregion;
            m_axi_aruser_reg <= s_axi_rd.aruser;
        end else if (store_axi_ar_temp_to_output) begin
            m_axi_arid_reg <= temp_m_axi_arid_reg;
            m_axi_araddr_reg <= temp_m_axi_araddr_reg;
            m_axi_arlen_reg <= temp_m_axi_arlen_reg;
            m_axi_arsize_reg <= temp_m_axi_arsize_reg;
            m_axi_arburst_reg <= temp_m_axi_arburst_reg;
            m_axi_arlock_reg <= temp_m_axi_arlock_reg;
            m_axi_arcache_reg <= temp_m_axi_arcache_reg;
            m_axi_arprot_reg <= temp_m_axi_arprot_reg;
            m_axi_arqos_reg <= temp_m_axi_arqos_reg;
            m_axi_arregion_reg <= temp_m_axi_arregion_reg;
            m_axi_aruser_reg <= temp_m_axi_aruser_reg;
        end

        if (store_axi_ar_input_to_temp) begin
            temp_m_axi_arid_reg <= s_axi_rd.arid;
            temp_m_axi_araddr_reg <= s_axi_rd.araddr;
            temp_m_axi_arlen_reg <= s_axi_rd.arlen;
            temp_m_axi_arsize_reg <= s_axi_rd.arsize;
            temp_m_axi_arburst_reg <= s_axi_rd.arburst;
            temp_m_axi_arlock_reg <= s_axi_rd.arlock;
            temp_m_axi_arcache_reg <= s_axi_rd.arcache;
            temp_m_axi_arprot_reg <= s_axi_rd.arprot;
            temp_m_axi_arqos_reg <= s_axi_rd.arqos;
            temp_m_axi_arregion_reg <= s_axi_rd.arregion;
            temp_m_axi_aruser_reg <= s_axi_rd.aruser;
        end

        if (rst) begin
            s_axi_arready_reg <= 1'b0;
            m_axi_arvalid_reg <= 1'b0;
            temp_m_axi_arvalid_reg <= 1'b0;
        end
    end

end else if (AR_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                 s_axi_arready_reg = 1'b0;

    logic [ID_W-1:0]      m_axi_arid_reg     = '0;
    logic [ADDR_W-1:0]    m_axi_araddr_reg   = '0;
    logic [7:0]           m_axi_arlen_reg    = '0;
    logic [2:0]           m_axi_arsize_reg   = '0;
    logic [1:0]           m_axi_arburst_reg  = '0;
    logic                 m_axi_arlock_reg   = '0;
    logic [3:0]           m_axi_arcache_reg  = '0;
    logic [2:0]           m_axi_arprot_reg   = '0;
    logic [3:0]           m_axi_arqos_reg    = '0;
    logic [3:0]           m_axi_arregion_reg = '0;
    logic [ARUSER_W-1:0]  m_axi_aruser_reg   = '0;
    logic                 m_axi_arvalid_reg  = 1'b0, m_axi_arvalid_next;

    // datapath control
    logic store_axi_ar_input_to_output;

    assign s_axi_rd.arready  = s_axi_arready_reg;

    assign m_axi_rd.arid     = m_axi_arid_reg;
    assign m_axi_rd.araddr   = m_axi_araddr_reg;
    assign m_axi_rd.arlen    = m_axi_arlen_reg;
    assign m_axi_rd.arsize   = m_axi_arsize_reg;
    assign m_axi_rd.arburst  = m_axi_arburst_reg;
    assign m_axi_rd.arlock   = m_axi_arlock_reg;
    assign m_axi_rd.arcache  = m_axi_arcache_reg;
    assign m_axi_rd.arprot   = m_axi_arprot_reg;
    assign m_axi_rd.arqos    = m_axi_arqos_reg;
    assign m_axi_rd.arregion = m_axi_arregion_reg;
    assign m_axi_rd.aruser   = ARUSER_EN ? m_axi_aruser_reg : '0;
    assign m_axi_rd.arvalid  = m_axi_arvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire s_axi_arready_early = !m_axi_arvalid_next;

    always_comb begin
        // transfer sink ready state to source
        m_axi_arvalid_next = m_axi_arvalid_reg;

        store_axi_ar_input_to_output = 1'b0;

        if (s_axi_arready_reg) begin
            m_axi_arvalid_next = s_axi_rd.arvalid;
            store_axi_ar_input_to_output = 1'b1;
        end else if (m_axi_rd.arready) begin
            m_axi_arvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        s_axi_arready_reg <= s_axi_arready_early;
        m_axi_arvalid_reg <= m_axi_arvalid_next;

        // datapath
        if (store_axi_ar_input_to_output) begin
            m_axi_arid_reg <= s_axi_rd.arid;
            m_axi_araddr_reg <= s_axi_rd.araddr;
            m_axi_arlen_reg <= s_axi_rd.arlen;
            m_axi_arsize_reg <= s_axi_rd.arsize;
            m_axi_arburst_reg <= s_axi_rd.arburst;
            m_axi_arlock_reg <= s_axi_rd.arlock;
            m_axi_arcache_reg <= s_axi_rd.arcache;
            m_axi_arprot_reg <= s_axi_rd.arprot;
            m_axi_arqos_reg <= s_axi_rd.arqos;
            m_axi_arregion_reg <= s_axi_rd.arregion;
            m_axi_aruser_reg <= s_axi_rd.aruser;
        end

        if (rst) begin
            s_axi_arready_reg <= 1'b0;
            m_axi_arvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass AR channel
    assign m_axi_rd.arid = s_axi_rd.arid;
    assign m_axi_rd.araddr = s_axi_rd.araddr;
    assign m_axi_rd.arlen = s_axi_rd.arlen;
    assign m_axi_rd.arsize = s_axi_rd.arsize;
    assign m_axi_rd.arburst = s_axi_rd.arburst;
    assign m_axi_rd.arlock = s_axi_rd.arlock;
    assign m_axi_rd.arcache = s_axi_rd.arcache;
    assign m_axi_rd.arprot = s_axi_rd.arprot;
    assign m_axi_rd.arqos = s_axi_rd.arqos;
    assign m_axi_rd.arregion = s_axi_rd.arregion;
    assign m_axi_rd.aruser = ARUSER_EN ? s_axi_rd.aruser : '0;
    assign m_axi_rd.arvalid = s_axi_rd.arvalid;
    assign s_axi_rd.arready = m_axi_rd.arready;

end

// R channel

if (R_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                m_axi_rready_reg = 1'b0;

    logic [ID_W-1:0]     s_axi_rid_reg    = '0;
    logic [DATA_W-1:0]   s_axi_rdata_reg  = '0;
    logic [1:0]          s_axi_rresp_reg  = 2'b0;
    logic                s_axi_rlast_reg  = 1'b0;
    logic [RUSER_W-1:0]  s_axi_ruser_reg  = '0;
    logic                s_axi_rvalid_reg = 1'b0, s_axi_rvalid_next;

    logic [ID_W-1:0]     temp_s_axi_rid_reg    = '0;
    logic [DATA_W-1:0]   temp_s_axi_rdata_reg  = '0;
    logic [1:0]          temp_s_axi_rresp_reg  = 2'b0;
    logic                temp_s_axi_rlast_reg  = 1'b0;
    logic [RUSER_W-1:0]  temp_s_axi_ruser_reg  = '0;
    logic                temp_s_axi_rvalid_reg = 1'b0, temp_s_axi_rvalid_next;

    // datapath control
    logic store_axi_r_input_to_output;
    logic store_axi_r_input_to_temp;
    logic store_axi_r_temp_to_output;

    assign m_axi_rd.rready = m_axi_rready_reg;

    assign s_axi_rd.rid    = s_axi_rid_reg;
    assign s_axi_rd.rdata  = s_axi_rdata_reg;
    assign s_axi_rd.rresp  = s_axi_rresp_reg;
    assign s_axi_rd.rlast  = s_axi_rlast_reg;
    assign s_axi_rd.ruser  = RUSER_EN ? s_axi_ruser_reg : '0;
    assign s_axi_rd.rvalid = s_axi_rvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire m_axi_rready_early = s_axi_rd.rready || (!temp_s_axi_rvalid_reg && (!s_axi_rvalid_reg || !m_axi_rd.rvalid));

    always_comb begin
        // transfer sink ready state to source
        s_axi_rvalid_next = s_axi_rvalid_reg;
        temp_s_axi_rvalid_next = temp_s_axi_rvalid_reg;

        store_axi_r_input_to_output = 1'b0;
        store_axi_r_input_to_temp = 1'b0;
        store_axi_r_temp_to_output = 1'b0;

        if (m_axi_rready_reg) begin
            // input is ready
            if (s_axi_rd.rready || !s_axi_rvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                s_axi_rvalid_next = m_axi_rd.rvalid;
                store_axi_r_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_s_axi_rvalid_next = m_axi_rd.rvalid;
                store_axi_r_input_to_temp = 1'b1;
            end
        end else if (s_axi_rd.rready) begin
            // input is not ready, but output is ready
            s_axi_rvalid_next = temp_s_axi_rvalid_reg;
            temp_s_axi_rvalid_next = 1'b0;
            store_axi_r_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        m_axi_rready_reg <= m_axi_rready_early;
        s_axi_rvalid_reg <= s_axi_rvalid_next;
        temp_s_axi_rvalid_reg <= temp_s_axi_rvalid_next;

        // datapath
        if (store_axi_r_input_to_output) begin
            s_axi_rid_reg   <= m_axi_rd.rid;
            s_axi_rdata_reg <= m_axi_rd.rdata;
            s_axi_rresp_reg <= m_axi_rd.rresp;
            s_axi_rlast_reg <= m_axi_rd.rlast;
            s_axi_ruser_reg <= m_axi_rd.ruser;
        end else if (store_axi_r_temp_to_output) begin
            s_axi_rid_reg   <= temp_s_axi_rid_reg;
            s_axi_rdata_reg <= temp_s_axi_rdata_reg;
            s_axi_rresp_reg <= temp_s_axi_rresp_reg;
            s_axi_rlast_reg <= temp_s_axi_rlast_reg;
            s_axi_ruser_reg <= temp_s_axi_ruser_reg;
        end

        if (store_axi_r_input_to_temp) begin
            temp_s_axi_rid_reg   <= m_axi_rd.rid;
            temp_s_axi_rdata_reg <= m_axi_rd.rdata;
            temp_s_axi_rresp_reg <= m_axi_rd.rresp;
            temp_s_axi_rlast_reg <= m_axi_rd.rlast;
            temp_s_axi_ruser_reg <= m_axi_rd.ruser;
        end

        if (rst) begin
            m_axi_rready_reg <= 1'b0;
            s_axi_rvalid_reg <= 1'b0;
            temp_s_axi_rvalid_reg <= 1'b0;
        end
    end

end else if (R_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                m_axi_rready_reg = 1'b0;

    logic [ID_W-1:0]     s_axi_rid_reg    = '0;
    logic [DATA_W-1:0]   s_axi_rdata_reg  = '0;
    logic [1:0]          s_axi_rresp_reg  = 2'b0;
    logic                s_axi_rlast_reg  = 1'b0;
    logic [RUSER_W-1:0]  s_axi_ruser_reg  = '0;
    logic                s_axi_rvalid_reg = 1'b0, s_axi_rvalid_next;

    // datapath control
    logic store_axi_r_input_to_output;

    assign m_axi_rd.rready = m_axi_rready_reg;

    assign s_axi_rd.rid    = s_axi_rid_reg;
    assign s_axi_rd.rdata  = s_axi_rdata_reg;
    assign s_axi_rd.rresp  = s_axi_rresp_reg;
    assign s_axi_rd.rlast  = s_axi_rlast_reg;
    assign s_axi_rd.ruser  = RUSER_EN ? s_axi_ruser_reg : '0;
    assign s_axi_rd.rvalid = s_axi_rvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire m_axi_rready_early = !s_axi_rvalid_next;

    always_comb begin
        // transfer sink ready state to source
        s_axi_rvalid_next = s_axi_rvalid_reg;

        store_axi_r_input_to_output = 1'b0;

        if (m_axi_rready_reg) begin
            s_axi_rvalid_next = m_axi_rd.rvalid;
            store_axi_r_input_to_output = 1'b1;
        end else if (s_axi_rd.rready) begin
            s_axi_rvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        m_axi_rready_reg <= m_axi_rready_early;
        s_axi_rvalid_reg <= s_axi_rvalid_next;

        // datapath
        if (store_axi_r_input_to_output) begin
            s_axi_rid_reg   <= m_axi_rd.rid;
            s_axi_rdata_reg <= m_axi_rd.rdata;
            s_axi_rresp_reg <= m_axi_rd.rresp;
            s_axi_rlast_reg <= m_axi_rd.rlast;
            s_axi_ruser_reg <= m_axi_rd.ruser;
        end

        if (rst) begin
            m_axi_rready_reg <= 1'b0;
            s_axi_rvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass R channel
    assign s_axi_rd.rid = m_axi_rd.rid;
    assign s_axi_rd.rdata = m_axi_rd.rdata;
    assign s_axi_rd.rresp = m_axi_rd.rresp;
    assign s_axi_rd.rlast = m_axi_rd.rlast;
    assign s_axi_rd.ruser = RUSER_EN ? m_axi_rd.ruser : '0;
    assign s_axi_rd.rvalid = m_axi_rd.rvalid;
    assign m_axi_rd.rready = s_axi_rd.rready;

end

endmodule

`resetall
