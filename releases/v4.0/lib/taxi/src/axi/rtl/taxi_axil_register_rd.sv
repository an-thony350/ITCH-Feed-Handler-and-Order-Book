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
 * AXI4 lite register (read)
 */
module taxi_axil_register_rd #
(
    // AR channel register type
    // 0 to bypass, 1 for simple buffer
    parameter AR_REG_TYPE = 1,
    // R channel register type
    // 0 to bypass, 1 for simple buffer
    parameter R_REG_TYPE = 1
)
(
    input  wire logic    clk,
    input  wire logic    rst,

    /*
     * AXI4-Lite slave interface
     */
    taxi_axil_if.rd_slv  s_axil_rd,

    /*
     * AXI4-Lite master interface
     */
    taxi_axil_if.rd_mst  m_axil_rd
);

// extract parameters
localparam DATA_W = s_axil_rd.DATA_W;
localparam ADDR_W = s_axil_rd.ADDR_W;
localparam STRB_W = s_axil_rd.STRB_W;
localparam logic ARUSER_EN = s_axil_rd.ARUSER_EN && m_axil_rd.ARUSER_EN;
localparam ARUSER_W = s_axil_rd.ARUSER_W;
localparam logic RUSER_EN = s_axil_rd.RUSER_EN && m_axil_rd.RUSER_EN;
localparam RUSER_W = s_axil_rd.RUSER_W;

if (m_axil_rd.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (m_axil_rd.STRB_W != STRB_W)
    $fatal(0, "Error: Interface STRB_W parameter mismatch (instance %m)");

// AR channel

if (AR_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                 s_axil_arready_reg = 1'b0;

    logic [ADDR_W-1:0]    m_axil_araddr_reg   = '0;
    logic [2:0]           m_axil_arprot_reg   = '0;
    logic [ARUSER_W-1:0]  m_axil_aruser_reg   = '0;
    logic                 m_axil_arvalid_reg  = 1'b0, m_axil_arvalid_next;

    logic [ADDR_W-1:0]    temp_m_axil_araddr_reg   = '0;
    logic [2:0]           temp_m_axil_arprot_reg   = '0;
    logic [ARUSER_W-1:0]  temp_m_axil_aruser_reg   = '0;
    logic                 temp_m_axil_arvalid_reg  = 1'b0, temp_m_axil_arvalid_next;

    // datapath control
    logic store_axil_ar_input_to_output;
    logic store_axil_ar_input_to_temp;
    logic store_axil_ar_temp_to_output;

    assign s_axil_rd.arready  = s_axil_arready_reg;

    assign m_axil_rd.araddr   = m_axil_araddr_reg;
    assign m_axil_rd.arprot   = m_axil_arprot_reg;
    assign m_axil_rd.aruser   = ARUSER_EN ? m_axil_aruser_reg : '0;
    assign m_axil_rd.arvalid  = m_axil_arvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire s_axil_arready_early = m_axil_rd.arready || (!temp_m_axil_arvalid_reg && (!m_axil_arvalid_reg || !s_axil_rd.arvalid));

    always_comb begin
        // transfer sink ready state to source
        m_axil_arvalid_next = m_axil_arvalid_reg;
        temp_m_axil_arvalid_next = temp_m_axil_arvalid_reg;

        store_axil_ar_input_to_output = 1'b0;
        store_axil_ar_input_to_temp = 1'b0;
        store_axil_ar_temp_to_output = 1'b0;

        if (s_axil_arready_reg) begin
            // input is ready
            if (m_axil_rd.arready || !m_axil_arvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                m_axil_arvalid_next = s_axil_rd.arvalid;
                store_axil_ar_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_m_axil_arvalid_next = s_axil_rd.arvalid;
                store_axil_ar_input_to_temp = 1'b1;
            end
        end else if (m_axil_rd.arready) begin
            // input is not ready, but output is ready
            m_axil_arvalid_next = temp_m_axil_arvalid_reg;
            temp_m_axil_arvalid_next = 1'b0;
            store_axil_ar_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        s_axil_arready_reg <= s_axil_arready_early;
        m_axil_arvalid_reg <= m_axil_arvalid_next;
        temp_m_axil_arvalid_reg <= temp_m_axil_arvalid_next;

        // datapath
        if (store_axil_ar_input_to_output) begin
            m_axil_araddr_reg <= s_axil_rd.araddr;
            m_axil_arprot_reg <= s_axil_rd.arprot;
            m_axil_aruser_reg <= s_axil_rd.aruser;
        end else if (store_axil_ar_temp_to_output) begin
            m_axil_araddr_reg <= temp_m_axil_araddr_reg;
            m_axil_arprot_reg <= temp_m_axil_arprot_reg;
            m_axil_aruser_reg <= temp_m_axil_aruser_reg;
        end

        if (store_axil_ar_input_to_temp) begin
            temp_m_axil_araddr_reg <= s_axil_rd.araddr;
            temp_m_axil_arprot_reg <= s_axil_rd.arprot;
            temp_m_axil_aruser_reg <= s_axil_rd.aruser;
        end

        if (rst) begin
            s_axil_arready_reg <= 1'b0;
            m_axil_arvalid_reg <= 1'b0;
            temp_m_axil_arvalid_reg <= 1'b0;
        end
    end

end else if (AR_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                 s_axil_arready_reg = 1'b0;

    logic [ADDR_W-1:0]    m_axil_araddr_reg   = '0;
    logic [2:0]           m_axil_arprot_reg   = '0;
    logic [ARUSER_W-1:0]  m_axil_aruser_reg   = '0;
    logic                 m_axil_arvalid_reg  = 1'b0, m_axil_arvalid_next;

    // datapath control
    logic store_axil_ar_input_to_output;

    assign s_axil_rd.arready  = s_axil_arready_reg;

    assign m_axil_rd.araddr   = m_axil_araddr_reg;
    assign m_axil_rd.arprot   = m_axil_arprot_reg;
    assign m_axil_rd.aruser   = ARUSER_EN ? m_axil_aruser_reg : '0;
    assign m_axil_rd.arvalid  = m_axil_arvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire s_axil_arready_early = !m_axil_arvalid_next;

    always_comb begin
        // transfer sink ready state to source
        m_axil_arvalid_next = m_axil_arvalid_reg;

        store_axil_ar_input_to_output = 1'b0;

        if (s_axil_arready_reg) begin
            m_axil_arvalid_next = s_axil_rd.arvalid;
            store_axil_ar_input_to_output = 1'b1;
        end else if (m_axil_rd.arready) begin
            m_axil_arvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        s_axil_arready_reg <= s_axil_arready_early;
        m_axil_arvalid_reg <= m_axil_arvalid_next;

        // datapath
        if (store_axil_ar_input_to_output) begin
            m_axil_araddr_reg <= s_axil_rd.araddr;
            m_axil_arprot_reg <= s_axil_rd.arprot;
            m_axil_aruser_reg <= s_axil_rd.aruser;
        end

        if (rst) begin
            s_axil_arready_reg <= 1'b0;
            m_axil_arvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass AR channel
    assign m_axil_rd.araddr = s_axil_rd.araddr;
    assign m_axil_rd.arprot = s_axil_rd.arprot;
    assign m_axil_rd.aruser = ARUSER_EN ? s_axil_rd.aruser : '0;
    assign m_axil_rd.arvalid = s_axil_rd.arvalid;
    assign s_axil_rd.arready = m_axil_rd.arready;

end

// R channel

if (R_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                m_axil_rready_reg = 1'b0;

    logic [DATA_W-1:0]   s_axil_rdata_reg  = '0;
    logic [1:0]          s_axil_rresp_reg  = 2'b0;
    logic [RUSER_W-1:0]  s_axil_ruser_reg  = '0;
    logic                s_axil_rvalid_reg = 1'b0, s_axil_rvalid_next;

    logic [DATA_W-1:0]   temp_s_axil_rdata_reg  = '0;
    logic [1:0]          temp_s_axil_rresp_reg  = 2'b0;
    logic [RUSER_W-1:0]  temp_s_axil_ruser_reg  = '0;
    logic                temp_s_axil_rvalid_reg = 1'b0, temp_s_axil_rvalid_next;

    // datapath control
    logic store_axil_r_input_to_output;
    logic store_axil_r_input_to_temp;
    logic store_axil_r_temp_to_output;

    assign m_axil_rd.rready = m_axil_rready_reg;

    assign s_axil_rd.rdata  = s_axil_rdata_reg;
    assign s_axil_rd.rresp  = s_axil_rresp_reg;
    assign s_axil_rd.ruser  = RUSER_EN ? s_axil_ruser_reg : '0;
    assign s_axil_rd.rvalid = s_axil_rvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire m_axil_rready_early = s_axil_rd.rready || (!temp_s_axil_rvalid_reg && (!s_axil_rvalid_reg || !m_axil_rd.rvalid));

    always_comb begin
        // transfer sink ready state to source
        s_axil_rvalid_next = s_axil_rvalid_reg;
        temp_s_axil_rvalid_next = temp_s_axil_rvalid_reg;

        store_axil_r_input_to_output = 1'b0;
        store_axil_r_input_to_temp = 1'b0;
        store_axil_r_temp_to_output = 1'b0;

        if (m_axil_rready_reg) begin
            // input is ready
            if (s_axil_rd.rready || !s_axil_rvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                s_axil_rvalid_next = m_axil_rd.rvalid;
                store_axil_r_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_s_axil_rvalid_next = m_axil_rd.rvalid;
                store_axil_r_input_to_temp = 1'b1;
            end
        end else if (s_axil_rd.rready) begin
            // input is not ready, but output is ready
            s_axil_rvalid_next = temp_s_axil_rvalid_reg;
            temp_s_axil_rvalid_next = 1'b0;
            store_axil_r_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        m_axil_rready_reg <= m_axil_rready_early;
        s_axil_rvalid_reg <= s_axil_rvalid_next;
        temp_s_axil_rvalid_reg <= temp_s_axil_rvalid_next;

        // datapath
        if (store_axil_r_input_to_output) begin
            s_axil_rdata_reg <= m_axil_rd.rdata;
            s_axil_rresp_reg <= m_axil_rd.rresp;
            s_axil_ruser_reg <= m_axil_rd.ruser;
        end else if (store_axil_r_temp_to_output) begin
            s_axil_rdata_reg <= temp_s_axil_rdata_reg;
            s_axil_rresp_reg <= temp_s_axil_rresp_reg;
            s_axil_ruser_reg <= temp_s_axil_ruser_reg;
        end

        if (store_axil_r_input_to_temp) begin
            temp_s_axil_rdata_reg <= m_axil_rd.rdata;
            temp_s_axil_rresp_reg <= m_axil_rd.rresp;
            temp_s_axil_ruser_reg <= m_axil_rd.ruser;
        end

        if (rst) begin
            m_axil_rready_reg <= 1'b0;
            s_axil_rvalid_reg <= 1'b0;
            temp_s_axil_rvalid_reg <= 1'b0;
        end
    end

end else if (R_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                m_axil_rready_reg = 1'b0;

    logic [DATA_W-1:0]   s_axil_rdata_reg  = '0;
    logic [1:0]          s_axil_rresp_reg  = 2'b0;
    logic [RUSER_W-1:0]  s_axil_ruser_reg  = '0;
    logic                s_axil_rvalid_reg = 1'b0, s_axil_rvalid_next;

    // datapath control
    logic store_axil_r_input_to_output;

    assign m_axil_rd.rready = m_axil_rready_reg;

    assign s_axil_rd.rdata  = s_axil_rdata_reg;
    assign s_axil_rd.rresp  = s_axil_rresp_reg;
    assign s_axil_rd.ruser  = RUSER_EN ? s_axil_ruser_reg : '0;
    assign s_axil_rd.rvalid = s_axil_rvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire m_axil_rready_early = !s_axil_rvalid_next;

    always_comb begin
        // transfer sink ready state to source
        s_axil_rvalid_next = s_axil_rvalid_reg;

        store_axil_r_input_to_output = 1'b0;

        if (m_axil_rready_reg) begin
            s_axil_rvalid_next = m_axil_rd.rvalid;
            store_axil_r_input_to_output = 1'b1;
        end else if (s_axil_rd.rready) begin
            s_axil_rvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        m_axil_rready_reg <= m_axil_rready_early;
        s_axil_rvalid_reg <= s_axil_rvalid_next;

        // datapath
        if (store_axil_r_input_to_output) begin
            s_axil_rdata_reg <= m_axil_rd.rdata;
            s_axil_rresp_reg <= m_axil_rd.rresp;
            s_axil_ruser_reg <= m_axil_rd.ruser;
        end

        if (rst) begin
            m_axil_rready_reg <= 1'b0;
            s_axil_rvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass R channel
    assign s_axil_rd.rdata = m_axil_rd.rdata;
    assign s_axil_rd.rresp = m_axil_rd.rresp;
    assign s_axil_rd.ruser = RUSER_EN ? m_axil_rd.ruser : '0;
    assign s_axil_rd.rvalid = m_axil_rd.rvalid;
    assign m_axil_rd.rready = s_axil_rd.rready;

end

endmodule

`resetall
