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
 * MT19937/MT19937-64 Mersenne Twister PRNG
 */
module taxi_mt19937 #(
    parameter integer MT_W = 32,
    parameter logic [MT_W-1:0] INIT_SEED = 5489
)
(
    input  wire logic             clk,
    input  wire logic             rst,

    /*
     * AXI output
     */
    taxi_axis_if.src              m_axis,

    /*
     * Status
     */
    output wire logic             busy,

    /*
     * Configuration
     */
    input  wire logic [MT_W-1:0]  seed_val,
    input  wire logic             seed_start
);

// check configuration
if (MT_W != 32 && MT_W != 64)
    $fatal(0, "Error: MT_W must be 32 or 64 (instance %m)", MT_W);

if (m_axis.DATA_W != MT_W)
    $fatal(0, "Error: Interface DATA_W parameter must be %d (instance %m)", MT_W);

localparam MT_N = MT_W == 64 ? 312 : 624;
localparam MT_M = MT_W == 64 ? 156 : 397;

localparam CL_MT_N = $clog2(MT_N);

// state register
localparam [0:0]
    STATE_SEED = 1'd0,
    STATE_RUN = 1'd1;

logic [0:0] state_reg = STATE_SEED, state_next;

logic [MT_W-1:0] mt_ram[MT_N];
logic [MT_W-1:0] mt_save_reg = '0, mt_save_next;
logic [CL_MT_N-1:0] mti_reg = '0, mti_next;

logic [CL_MT_N-1:0] mt_wr_ptr;
logic [MT_W-1:0] mt_wr_data;
logic mt_wr_en;

logic [CL_MT_N-1:0] mt_rd_a_ptr_reg = '0, mt_rd_a_ptr_next;
logic [MT_W-1:0] mt_rd_a_data_reg = '0;

logic [CL_MT_N-1:0] mt_rd_b_ptr_reg = '0, mt_rd_b_ptr_next;
logic [MT_W-1:0] mt_rd_b_data_reg = '0;

logic [MT_W-1:0] product_reg = INIT_SEED, product_next;
logic [MT_W-1:0] factor1_reg = '0, factor1_next;
logic [MT_W-1:0] factor2_reg = '0, factor2_next;
logic mul_done_reg = 1'b1, mul_done_next;

logic [MT_W-1:0] m_axis_tdata_reg = '0, m_axis_tdata_next;
logic m_axis_tvalid_reg = 1'b0, m_axis_tvalid_next;

logic busy_reg = 1'b0;

assign m_axis.tdata = m_axis_tdata_reg;
assign m_axis.tkeep  = '1;
assign m_axis.tstrb  = m_axis.tkeep;
assign m_axis.tvalid = m_axis_tvalid_reg;
assign m_axis.tlast  = 1'b1;
assign m_axis.tid    = '0;
assign m_axis.tdest  = '0;
assign m_axis.tuser  = '0;

assign busy = busy_reg;

wire [MT_W-1:0] y1, y2, y3, y4, y5;

if (MT_W == 32) begin

    assign y1 = {mt_save_reg[31], mt_rd_a_data_reg[30:0]};
    assign y2 = mt_rd_b_data_reg ^ (y1 >> 1) ^ (y1[0] ? 32'h9908b0df : 32'h0);
    assign y3 = y2 ^ (y2 >> 11);
    assign y4 = y3 ^ ((y3 << 7) & 32'h9d2c5680);
    assign y5 = y4 ^ ((y4 << 15) & 32'hefc60000);

end else begin

    assign y1 = {mt_save_reg[63:31], mt_rd_a_data_reg[30:0]};
    assign y2 = mt_rd_b_data_reg ^ (y1 >> 1) ^ (y1[0] ? 64'hB5026F5AA96619E9 : 64'h0);
    assign y3 = y2 ^ ((y2 >> 29) & 64'h5555555555555555);
    assign y4 = y3 ^ ((y3 << 17) & 64'h71D67FFFEDA60000);
    assign y5 = y4 ^ ((y4 << 37) & 64'hFFF7EEE000000000);

end

always_comb begin
    state_next = STATE_SEED;

    mt_save_next = mt_save_reg;
    mti_next = mti_reg;

    mt_wr_data = y2;
    mt_wr_ptr = mti_reg;
    mt_wr_en = '0;

    mt_rd_a_ptr_next = mt_rd_a_ptr_reg;
    mt_rd_b_ptr_next = mt_rd_b_ptr_reg;

    product_next = product_reg;
    factor1_next = factor1_reg;
    factor2_next = factor2_reg;
    mul_done_next = mul_done_reg;

    m_axis_tdata_next = m_axis_tdata_reg;
    m_axis_tvalid_next = m_axis_tvalid_reg && !m_axis.tready;

    case (state_reg)
        STATE_SEED: begin
            mt_save_next = product_reg + MT_W'(mti_reg);
            mt_wr_data = mt_save_next;
            mt_rd_b_ptr_next = MT_M;
            if (mul_done_reg) begin
                product_next = '0;
                if (MT_W == 32) begin
                    factor1_next = mt_save_next ^ (mt_save_next >> 30);
                    /* verilator lint_off WIDTHEXPAND */
                    factor2_next = 32'd1812433253;
                    /* verilator lint_on WIDTHEXPAND */
                end else begin
                    factor1_next = mt_save_next ^ (mt_save_next >> 62);
                    /* verilator lint_off WIDTHTRUNC */
                    factor2_next = 64'd6364136223846793005;
                    /* verilator lint_on WIDTHTRUNC */
                end
                mul_done_next = 1'b0;
                if (mti_reg < CL_MT_N'(MT_N)) begin
                    product_next = '0;
                    mul_done_next = 1'b0;
                    mt_wr_data = mt_save_next;
                    mt_wr_ptr = mti_reg;
                    mt_wr_en = 1'b1;
                    mti_next = mti_reg + 1;
                    mt_rd_a_ptr_next = '0;
                    state_next = STATE_SEED;
                end else begin
                    mti_next = '0;
                    mt_rd_a_ptr_next = 1;
                    mt_rd_b_ptr_next = MT_M;
                    mt_save_next = mt_rd_a_data_reg;
                    state_next = STATE_RUN;
                end
            end else begin
                factor1_next = factor1_reg << 1;
                factor2_next = factor2_reg >> 1;
                mul_done_next = factor2_reg[8:1] == 0;
                if (factor2_reg[0]) begin
                    product_next = product_reg + factor1_reg;
                end
                state_next = STATE_SEED;
            end
        end
        STATE_RUN: begin
            // idle state
            if (m_axis.tready) begin
                if (mti_reg < CL_MT_N'(MT_N-1))
                    mti_next = mti_reg + 1;
                else
                    mti_next = '0;

                if (mt_rd_a_ptr_reg < CL_MT_N'(MT_N-1))
                    mt_rd_a_ptr_next = mt_rd_a_ptr_reg + 1;
                else
                    mt_rd_a_ptr_next = '0;

                if (mt_rd_b_ptr_reg < CL_MT_N'(MT_N-1))
                    mt_rd_b_ptr_next = mt_rd_b_ptr_reg + 1;
                else
                    mt_rd_b_ptr_next = '0;

                mt_save_next = mt_rd_a_data_reg;

                if (MT_W == 32) begin
                    m_axis_tdata_next = y5 ^ (y5 >> 18);
                end else begin
                    m_axis_tdata_next = y5 ^ (y5 >> 43);
                end
                m_axis_tvalid_next = 1'b1;

                mt_wr_data = y2;
                mt_wr_ptr = mti_reg;
                mt_wr_en = 1'b1;
            end
            state_next = STATE_RUN;
        end
    endcase

    if (seed_start) begin
        product_next = seed_val;
        mti_next = '0;
        mul_done_next = 1'b1;
        state_next = STATE_SEED;
    end
end

always_ff @(posedge clk) begin
    state_reg <= state_next;

    mt_save_reg <= mt_save_next;
    mti_reg <= mti_next;

    mt_rd_a_ptr_reg <= mt_rd_a_ptr_next;
    mt_rd_b_ptr_reg <= mt_rd_b_ptr_next;

    product_reg <= product_next;
    factor1_reg <= factor1_next;
    factor2_reg <= factor2_next;
    mul_done_reg <= mul_done_next;

    m_axis_tdata_reg <= m_axis_tdata_next;
    m_axis_tvalid_reg <= m_axis_tvalid_next;

    busy_reg <= state_next != STATE_RUN;

    if (mt_wr_en) begin
        mt_ram[mt_wr_ptr] <= mt_wr_data;
    end

    mt_rd_a_data_reg <= mt_ram[mt_rd_a_ptr_next];
    mt_rd_b_data_reg <= mt_ram[mt_rd_b_ptr_next];

    if (rst) begin
        state_reg <= STATE_SEED;
        mti_reg <= '0;
        mt_rd_a_ptr_reg <= '0;
        mt_rd_b_ptr_reg <= '0;
        product_reg <= INIT_SEED;
        factor1_reg <= '0;
        factor2_reg <= '0;
        mul_done_reg <= 1'b1;
        m_axis_tdata_reg <= '0;
        m_axis_tvalid_reg <= 1'b0;
        busy_reg <= 1'b0;
    end
end

endmodule

`resetall
