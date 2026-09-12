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
 * AXI4 lite register (write)
 */
module taxi_axil_register_wr #
(
    // AW channel register type
    // 0 to bypass, 1 for simple buffer
    parameter AW_REG_TYPE = 1,
    // W channel register type
    // 0 to bypass, 1 for simple buffer
    parameter W_REG_TYPE = 1,
    // B channel register type
    // 0 to bypass, 1 for simple buffer
    parameter B_REG_TYPE = 1
)
(
    input  wire logic    clk,
    input  wire logic    rst,

    /*
     * AXI4-Lite slave interface
     */
    taxi_axil_if.wr_slv  s_axil_wr,

    /*
     * AXI4-Lite master interface
     */
    taxi_axil_if.wr_mst  m_axil_wr
);

// extract parameters
localparam DATA_W = s_axil_wr.DATA_W;
localparam ADDR_W = s_axil_wr.ADDR_W;
localparam STRB_W = s_axil_wr.STRB_W;
localparam logic AWUSER_EN = s_axil_wr.AWUSER_EN && m_axil_wr.AWUSER_EN;
localparam AWUSER_W = s_axil_wr.AWUSER_W;
localparam logic WUSER_EN = s_axil_wr.WUSER_EN && m_axil_wr.WUSER_EN;
localparam WUSER_W = s_axil_wr.WUSER_W;
localparam logic BUSER_EN = s_axil_wr.BUSER_EN && m_axil_wr.BUSER_EN;
localparam BUSER_W = s_axil_wr.BUSER_W;

if (m_axil_wr.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (m_axil_wr.STRB_W != STRB_W)
    $fatal(0, "Error: Interface STRB_W parameter mismatch (instance %m)");

// AW channel

if (AW_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                 s_axil_awready_reg = 1'b0;

    logic [ADDR_W-1:0]    m_axil_awaddr_reg   = '0;
    logic [2:0]           m_axil_awprot_reg   = '0;
    logic [AWUSER_W-1:0]  m_axil_awuser_reg   = '0;
    logic                 m_axil_awvalid_reg  = 1'b0, m_axil_awvalid_next;

    logic [ADDR_W-1:0]    temp_m_axil_awaddr_reg   = '0;
    logic [2:0]           temp_m_axil_awprot_reg   = '0;
    logic [AWUSER_W-1:0]  temp_m_axil_awuser_reg   = '0;
    logic                 temp_m_axil_awvalid_reg  = 1'b0, temp_m_axil_awvalid_next;

    // datapath control
    logic store_axil_aw_input_to_output;
    logic store_axil_aw_input_to_temp;
    logic store_axil_aw_temp_to_output;

    assign s_axil_wr.awready  = s_axil_awready_reg;

    assign m_axil_wr.awaddr   = m_axil_awaddr_reg;
    assign m_axil_wr.awprot   = m_axil_awprot_reg;
    assign m_axil_wr.awuser   = AWUSER_EN ? m_axil_awuser_reg : '0;
    assign m_axil_wr.awvalid  = m_axil_awvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire s_axil_awready_early = m_axil_wr.awready || (!temp_m_axil_awvalid_reg && (!m_axil_awvalid_reg || !s_axil_wr.awvalid));

    always_comb begin
        // transfer sink ready state to source
        m_axil_awvalid_next = m_axil_awvalid_reg;
        temp_m_axil_awvalid_next = temp_m_axil_awvalid_reg;

        store_axil_aw_input_to_output = 1'b0;
        store_axil_aw_input_to_temp = 1'b0;
        store_axil_aw_temp_to_output = 1'b0;

        if (s_axil_awready_reg) begin
            // input is ready
            if (m_axil_wr.awready || !m_axil_awvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                m_axil_awvalid_next = s_axil_wr.awvalid;
                store_axil_aw_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_m_axil_awvalid_next = s_axil_wr.awvalid;
                store_axil_aw_input_to_temp = 1'b1;
            end
        end else if (m_axil_wr.awready) begin
            // input is not ready, but output is ready
            m_axil_awvalid_next = temp_m_axil_awvalid_reg;
            temp_m_axil_awvalid_next = 1'b0;
            store_axil_aw_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        s_axil_awready_reg <= s_axil_awready_early;
        m_axil_awvalid_reg <= m_axil_awvalid_next;
        temp_m_axil_awvalid_reg <= temp_m_axil_awvalid_next;

        // datapath
        if (store_axil_aw_input_to_output) begin
            m_axil_awaddr_reg <= s_axil_wr.awaddr;
            m_axil_awprot_reg <= s_axil_wr.awprot;
            m_axil_awuser_reg <= s_axil_wr.awuser;
        end else if (store_axil_aw_temp_to_output) begin
            m_axil_awaddr_reg <= temp_m_axil_awaddr_reg;
            m_axil_awprot_reg <= temp_m_axil_awprot_reg;
            m_axil_awuser_reg <= temp_m_axil_awuser_reg;
        end

        if (store_axil_aw_input_to_temp) begin
            temp_m_axil_awaddr_reg <= s_axil_wr.awaddr;
            temp_m_axil_awprot_reg <= s_axil_wr.awprot;
            temp_m_axil_awuser_reg <= s_axil_wr.awuser;
        end

        if (rst) begin
            s_axil_awready_reg <= 1'b0;
            m_axil_awvalid_reg <= 1'b0;
            temp_m_axil_awvalid_reg <= 1'b0;
        end
    end

end else if (AW_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                 s_axil_awready_reg = 1'b0;

    logic [ADDR_W-1:0]    m_axil_awaddr_reg   = '0;
    logic [2:0]           m_axil_awprot_reg   = '0;
    logic [AWUSER_W-1:0]  m_axil_awuser_reg   = '0;
    logic                 m_axil_awvalid_reg  = 1'b0, m_axil_awvalid_next;

    // datapath control
    logic store_axil_aw_input_to_output;

    assign s_axil_wr.awready  = s_axil_awready_reg;

    assign m_axil_wr.awaddr   = m_axil_awaddr_reg;
    assign m_axil_wr.awprot   = m_axil_awprot_reg;
    assign m_axil_wr.awuser   = AWUSER_EN ? m_axil_awuser_reg : '0;
    assign m_axil_wr.awvalid  = m_axil_awvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire s_axil_awready_early = !m_axil_awvalid_next;

    always_comb begin
        // transfer sink ready state to source
        m_axil_awvalid_next = m_axil_awvalid_reg;

        store_axil_aw_input_to_output = 1'b0;

        if (s_axil_awready_reg) begin
            m_axil_awvalid_next = s_axil_wr.awvalid;
            store_axil_aw_input_to_output = 1'b1;
        end else if (m_axil_wr.awready) begin
            m_axil_awvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        s_axil_awready_reg <= s_axil_awready_early;
        m_axil_awvalid_reg <= m_axil_awvalid_next;

        // datapath
        if (store_axil_aw_input_to_output) begin
            m_axil_awaddr_reg <= s_axil_wr.awaddr;
            m_axil_awprot_reg <= s_axil_wr.awprot;
            m_axil_awuser_reg <= s_axil_wr.awuser;
        end

        if (rst) begin
            s_axil_awready_reg <= 1'b0;
            m_axil_awvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass AW channel
    assign m_axil_wr.awaddr = s_axil_wr.awaddr;
    assign m_axil_wr.awprot = s_axil_wr.awprot;
    assign m_axil_wr.awuser = AWUSER_EN ? s_axil_wr.awuser : '0;
    assign m_axil_wr.awvalid = s_axil_wr.awvalid;
    assign s_axil_wr.awready = m_axil_wr.awready;

end

// W channel

if (W_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                s_axil_wready_reg = 1'b0;

    logic [DATA_W-1:0]   m_axil_wdata_reg  = '0;
    logic [STRB_W-1:0]   m_axil_wstrb_reg  = '0;
    logic [WUSER_W-1:0]  m_axil_wuser_reg  = '0;
    logic                m_axil_wvalid_reg = 1'b0, m_axil_wvalid_next;

    logic [DATA_W-1:0]   temp_m_axil_wdata_reg  = '0;
    logic [STRB_W-1:0]   temp_m_axil_wstrb_reg  = '0;
    logic [WUSER_W-1:0]  temp_m_axil_wuser_reg  = '0;
    logic                temp_m_axil_wvalid_reg = 1'b0, temp_m_axil_wvalid_next;

    // datapath control
    logic store_axil_w_input_to_output;
    logic store_axil_w_input_to_temp;
    logic store_axil_w_temp_to_output;

    assign s_axil_wr.wready = s_axil_wready_reg;

    assign m_axil_wr.wdata  = m_axil_wdata_reg;
    assign m_axil_wr.wstrb  = m_axil_wstrb_reg;
    assign m_axil_wr.wuser  = WUSER_EN ? m_axil_wuser_reg : '0;
    assign m_axil_wr.wvalid = m_axil_wvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire s_axil_wready_early = m_axil_wr.wready || (!temp_m_axil_wvalid_reg && (!m_axil_wvalid_reg || !s_axil_wr.wvalid));

    always_comb begin
        // transfer sink ready state to source
        m_axil_wvalid_next = m_axil_wvalid_reg;
        temp_m_axil_wvalid_next = temp_m_axil_wvalid_reg;

        store_axil_w_input_to_output = 1'b0;
        store_axil_w_input_to_temp = 1'b0;
        store_axil_w_temp_to_output = 1'b0;

        if (s_axil_wready_reg) begin
            // input is ready
            if (m_axil_wr.wready || !m_axil_wvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                m_axil_wvalid_next = s_axil_wr.wvalid;
                store_axil_w_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_m_axil_wvalid_next = s_axil_wr.wvalid;
                store_axil_w_input_to_temp = 1'b1;
            end
        end else if (m_axil_wr.wready) begin
            // input is not ready, but output is ready
            m_axil_wvalid_next = temp_m_axil_wvalid_reg;
            temp_m_axil_wvalid_next = 1'b0;
            store_axil_w_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        s_axil_wready_reg <= s_axil_wready_early;
        m_axil_wvalid_reg <= m_axil_wvalid_next;
        temp_m_axil_wvalid_reg <= temp_m_axil_wvalid_next;

        // datapath
        if (store_axil_w_input_to_output) begin
            m_axil_wdata_reg <= s_axil_wr.wdata;
            m_axil_wstrb_reg <= s_axil_wr.wstrb;
            m_axil_wuser_reg <= s_axil_wr.wuser;
        end else if (store_axil_w_temp_to_output) begin
            m_axil_wdata_reg <= temp_m_axil_wdata_reg;
            m_axil_wstrb_reg <= temp_m_axil_wstrb_reg;
            m_axil_wuser_reg <= temp_m_axil_wuser_reg;
        end

        if (store_axil_w_input_to_temp) begin
            temp_m_axil_wdata_reg <= s_axil_wr.wdata;
            temp_m_axil_wstrb_reg <= s_axil_wr.wstrb;
            temp_m_axil_wuser_reg <= s_axil_wr.wuser;
        end

        if (rst) begin
            s_axil_wready_reg <= 1'b0;
            m_axil_wvalid_reg <= 1'b0;
            temp_m_axil_wvalid_reg <= 1'b0;
        end
    end

end else if (W_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                s_axil_wready_reg = 1'b0;

    logic [DATA_W-1:0]   m_axil_wdata_reg  = '0;
    logic [STRB_W-1:0]   m_axil_wstrb_reg  = '0;
    logic [WUSER_W-1:0]  m_axil_wuser_reg  = '0;
    logic                m_axil_wvalid_reg = 1'b0, m_axil_wvalid_next;

    // datapath control
    logic store_axil_w_input_to_output;

    assign s_axil_wr.wready = s_axil_wready_reg;

    assign m_axil_wr.wdata  = m_axil_wdata_reg;
    assign m_axil_wr.wstrb  = m_axil_wstrb_reg;
    assign m_axil_wr.wuser  = WUSER_EN ? m_axil_wuser_reg : '0;
    assign m_axil_wr.wvalid = m_axil_wvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire s_axil_wready_early = !m_axil_wvalid_next;

    always_comb begin
        // transfer sink ready state to source
        m_axil_wvalid_next = m_axil_wvalid_reg;

        store_axil_w_input_to_output = 1'b0;

        if (s_axil_wready_reg) begin
            m_axil_wvalid_next = s_axil_wr.wvalid;
            store_axil_w_input_to_output = 1'b1;
        end else if (m_axil_wr.wready) begin
            m_axil_wvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        s_axil_wready_reg <= s_axil_wready_early;
        m_axil_wvalid_reg <= m_axil_wvalid_next;

        // datapath
        if (store_axil_w_input_to_output) begin
            m_axil_wdata_reg <= s_axil_wr.wdata;
            m_axil_wstrb_reg <= s_axil_wr.wstrb;
            m_axil_wuser_reg <= s_axil_wr.wuser;
        end

        if (rst) begin
            s_axil_wready_reg <= 1'b0;
            m_axil_wvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass W channel
    assign m_axil_wr.wdata = s_axil_wr.wdata;
    assign m_axil_wr.wstrb = s_axil_wr.wstrb;
    assign m_axil_wr.wuser = WUSER_EN ? s_axil_wr.wuser : '0;
    assign m_axil_wr.wvalid = s_axil_wr.wvalid;
    assign s_axil_wr.wready = m_axil_wr.wready;

end

// B channel

if (B_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                m_axil_bready_reg = 1'b0;

    logic [1:0]          s_axil_bresp_reg  = 2'b0;
    logic [BUSER_W-1:0]  s_axil_buser_reg  = '0;
    logic                s_axil_bvalid_reg = 1'b0, s_axil_bvalid_next;

    logic [1:0]          temp_s_axil_bresp_reg  = 2'b0;
    logic [BUSER_W-1:0]  temp_s_axil_buser_reg  = '0;
    logic                temp_s_axil_bvalid_reg = 1'b0, temp_s_axil_bvalid_next;

    // datapath control
    logic store_axil_b_input_to_output;
    logic store_axil_b_input_to_temp;
    logic store_axil_b_temp_to_output;

    assign m_axil_wr.bready = m_axil_bready_reg;

    assign s_axil_wr.bresp  = s_axil_bresp_reg;
    assign s_axil_wr.buser  = BUSER_EN ? s_axil_buser_reg : '0;
    assign s_axil_wr.bvalid = s_axil_bvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire m_axil_bready_early = s_axil_wr.bready || (!temp_s_axil_bvalid_reg && (!s_axil_bvalid_reg || !m_axil_wr.bvalid));

    always_comb begin
        // transfer sink ready state to source
        s_axil_bvalid_next = s_axil_bvalid_reg;
        temp_s_axil_bvalid_next = temp_s_axil_bvalid_reg;

        store_axil_b_input_to_output = 1'b0;
        store_axil_b_input_to_temp = 1'b0;
        store_axil_b_temp_to_output = 1'b0;

        if (m_axil_bready_reg) begin
            // input is ready
            if (s_axil_wr.bready || !s_axil_bvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                s_axil_bvalid_next = m_axil_wr.bvalid;
                store_axil_b_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_s_axil_bvalid_next = m_axil_wr.bvalid;
                store_axil_b_input_to_temp = 1'b1;
            end
        end else if (s_axil_wr.bready) begin
            // input is not ready, but output is ready
            s_axil_bvalid_next = temp_s_axil_bvalid_reg;
            temp_s_axil_bvalid_next = 1'b0;
            store_axil_b_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        m_axil_bready_reg <= m_axil_bready_early;
        s_axil_bvalid_reg <= s_axil_bvalid_next;
        temp_s_axil_bvalid_reg <= temp_s_axil_bvalid_next;

        // datapath
        if (store_axil_b_input_to_output) begin
            s_axil_bresp_reg <= m_axil_wr.bresp;
            s_axil_buser_reg <= m_axil_wr.buser;
        end else if (store_axil_b_temp_to_output) begin
            s_axil_bresp_reg <= temp_s_axil_bresp_reg;
            s_axil_buser_reg <= temp_s_axil_buser_reg;
        end

        if (store_axil_b_input_to_temp) begin
            temp_s_axil_bresp_reg <= m_axil_wr.bresp;
            temp_s_axil_buser_reg <= m_axil_wr.buser;
        end

        if (rst) begin
            m_axil_bready_reg <= 1'b0;
            s_axil_bvalid_reg <= 1'b0;
            temp_s_axil_bvalid_reg <= 1'b0;
        end
    end

end else if (B_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                m_axil_bready_reg = 1'b0;

    logic [1:0]          s_axil_bresp_reg  = 2'b0;
    logic [BUSER_W-1:0]  s_axil_buser_reg  = '0;
    logic                s_axil_bvalid_reg = 1'b0, s_axil_bvalid_next;

    // datapath control
    logic store_axil_b_input_to_output;

    assign m_axil_wr.bready = m_axil_bready_reg;

    assign s_axil_wr.bresp  = s_axil_bresp_reg;
    assign s_axil_wr.buser  = BUSER_EN ? s_axil_buser_reg : '0;
    assign s_axil_wr.bvalid = s_axil_bvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire m_axil_bready_early = !s_axil_bvalid_next;

    always_comb begin
        // transfer sink ready state to source
        s_axil_bvalid_next = s_axil_bvalid_reg;

        store_axil_b_input_to_output = 1'b0;

        if (m_axil_bready_reg) begin
            s_axil_bvalid_next = m_axil_wr.bvalid;
            store_axil_b_input_to_output = 1'b1;
        end else if (s_axil_wr.bready) begin
            s_axil_bvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        m_axil_bready_reg <= m_axil_bready_early;
        s_axil_bvalid_reg <= s_axil_bvalid_next;

        // datapath
        if (store_axil_b_input_to_output) begin
            s_axil_bresp_reg <= m_axil_wr.bresp;
            s_axil_buser_reg <= m_axil_wr.buser;
        end

        if (rst) begin
            m_axil_bready_reg <= 1'b0;
            s_axil_bvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass B channel
    assign s_axil_wr.bresp = m_axil_wr.bresp;
    assign s_axil_wr.buser = BUSER_EN ? m_axil_wr.buser : '0;
    assign s_axil_wr.bvalid = m_axil_wr.bvalid;
    assign m_axil_wr.bready = s_axil_wr.bready;

end

endmodule

`resetall
