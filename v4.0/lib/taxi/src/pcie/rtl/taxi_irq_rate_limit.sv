// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2022-2026 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * IRQ rate limit module
 */
module taxi_irq_rate_limit
(
    input  wire logic         clk,
    input  wire logic         rst,

    /*
     * Interrupt request input
     */
     taxi_axis_if.snk         s_axis_irq,

    /*
     * Interrupt request output
     */
     taxi_axis_if.src         m_axis_irq,

    /*
     * Configuration
     */
    input  wire logic [15:0]  prescale,
    input  wire logic [15:0]  min_interval
);

localparam IRQN_W = s_axis_irq.DATA_W;

localparam TSTAMP_W = 17;

// check configuration
if (m_axis_irq.DATA_W != IRQN_W)
    $fatal(0, "Error: AXI stream width mismatch (instance %m)");

typedef enum logic [1:0] {
    STATE_INIT,
    STATE_IDLE,
    STATE_IRQ_IN,
    STATE_IRQ_OUT
} state_t;

state_t state_reg = STATE_INIT, state_next;

logic [IRQN_W-1:0] cur_index_reg = '0, cur_index_next;
logic [IRQN_W-1:0] irqn_reg = '0, irqn_next;

localparam MEM_W = TSTAMP_W+1+1;

logic mem_rd_en;
logic mem_wr_en;
logic [IRQN_W-1:0] mem_addr;
logic [MEM_W-1:0] mem_wr_data;
logic [MEM_W-1:0] mem_rd_data_reg;
logic mem_rd_data_valid_reg = 1'b0, mem_rd_data_valid_next;

(* ramstyle = "no_rw_check, mlab" *)
logic [MEM_W-1:0] mem_reg[2**IRQN_W] = '{default: '0};

logic s_axis_irq_tready_reg = 0, s_axis_irq_tready_next;

logic [IRQN_W-1:0] m_axis_irq_irqn_reg = '0, m_axis_irq_irqn_next;
logic m_axis_irq_tvalid_reg = 1'b0, m_axis_irq_tvalid_next;

assign s_axis_irq.tready = s_axis_irq_tready_reg;

assign m_axis_irq.tdata  = m_axis_irq_irqn_reg;
assign m_axis_irq.tkeep  = '1;
assign m_axis_irq.tstrb  = m_axis_irq.tkeep;
assign m_axis_irq.tvalid = m_axis_irq_tvalid_reg;
assign m_axis_irq.tlast  = 1'b1;
assign m_axis_irq.tid    = '0;
assign m_axis_irq.tdest  = '0;
assign m_axis_irq.tuser  = '0;

logic [15:0] prescale_count_reg = '0;
logic [TSTAMP_W-1:0] time_count_reg = '0;

always_ff @(posedge clk) begin
    if (prescale_count_reg != 0) begin
        prescale_count_reg <= prescale_count_reg - 1;
    end else begin
        prescale_count_reg <= prescale;
        time_count_reg <= time_count_reg + 1;
    end

    if (rst) begin
        prescale_count_reg <= '0;
        time_count_reg <= '0;
    end
end

always_comb begin
    state_next = STATE_INIT;

    cur_index_next = cur_index_reg;
    irqn_next = irqn_reg;

    s_axis_irq_tready_next = 1'b0;

    m_axis_irq_irqn_next = m_axis_irq_irqn_reg;
    m_axis_irq_tvalid_next = m_axis_irq_tvalid_reg && !m_axis_irq.tready;

    mem_rd_en = 1'b0;
    mem_wr_en = 1'b0;
    mem_addr = cur_index_reg;
    mem_wr_data = mem_rd_data_reg;
    mem_rd_data_valid_next = mem_rd_data_valid_reg;

    case (state_reg)
        STATE_INIT: begin
            // init - clear all timers
            mem_addr = cur_index_reg;
            mem_wr_data[0] = 1'b0;
            mem_wr_data[1] = 1'b0;
            mem_wr_data[2 +: TSTAMP_W] = '0;
            mem_wr_en = 1'b1;
            cur_index_next = cur_index_reg + 1;
            if (&cur_index_reg) begin
                state_next = STATE_IDLE;
            end else begin
                state_next = STATE_INIT;
            end
        end
        STATE_IDLE: begin
            // idle - wait for requests and check timers
            if (s_axis_irq.tvalid) begin
                // new interrupt request
                irqn_next = s_axis_irq.tdata;
                mem_addr = s_axis_irq.tdata;
                mem_rd_en = 1'b1;
                mem_rd_data_valid_next = 1'b1;
                s_axis_irq_tready_next = 1'b1;
                state_next = STATE_IRQ_IN;
            end else if (mem_rd_data_valid_reg && mem_rd_data_reg[1] && (mem_rd_data_reg[2 +: TSTAMP_W] - time_count_reg) >> (TSTAMP_W-1) != 0) begin
                // timer expired
                state_next = STATE_IRQ_OUT;
            end else begin
                // read next timer
                irqn_next = cur_index_reg;
                mem_addr = cur_index_reg;
                mem_rd_en = 1'b1;
                mem_rd_data_valid_next = 1'b1;
                cur_index_next = cur_index_reg + 1;
                state_next = STATE_IDLE;
            end
        end
        STATE_IRQ_IN: begin
            // pass through IRQ
            if (mem_rd_data_reg[1]) begin
                // timer running, set pending bit
                mem_addr = irqn_reg;
                mem_wr_data[0] = 1'b1;
                mem_wr_data[1] = 1'b1;
                mem_wr_data[2 +: TSTAMP_W] = mem_rd_data_reg[2 +: TSTAMP_W];
                mem_wr_en = 1'b1;
                mem_rd_data_valid_next = 1'b0;

                state_next = STATE_IDLE;
            end else if (!m_axis_irq_tvalid_reg || m_axis_irq.tready) begin
                // timer not running, start timer and generate IRQ
                mem_addr = irqn_reg;
                mem_wr_data[0] = 1'b0;
                mem_wr_data[1] = min_interval != 0;
                mem_wr_data[2 +: TSTAMP_W] = time_count_reg + min_interval;
                mem_wr_en = 1'b1;
                mem_rd_data_valid_next = 1'b0;

                m_axis_irq_tvalid_next = 1'b1;
                m_axis_irq_irqn_next = irqn_reg;

                state_next = STATE_IDLE;
            end else begin
                state_next = STATE_IRQ_IN;
            end
        end
        STATE_IRQ_OUT: begin
            // handle timer expiration
            if (mem_rd_data_reg[0]) begin
                // pending bit set, generate IRQ and restart timer
                if (!m_axis_irq_tvalid_reg || m_axis_irq.tready) begin
                    mem_addr = irqn_reg;
                    mem_wr_data[0] = 1'b0;
                    mem_wr_data[1] = min_interval != 0;
                    mem_wr_data[2 +: TSTAMP_W] = time_count_reg + min_interval;
                    mem_wr_en = 1'b1;
                    mem_rd_data_valid_next = 1'b0;

                    m_axis_irq_tvalid_next = 1'b1;
                    m_axis_irq_irqn_next = irqn_reg;

                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_IRQ_OUT;
                end
            end else begin
                // pending bit not set, reset timer
                mem_addr = irqn_reg;
                mem_wr_data[0] = 1'b0;
                mem_wr_data[1] = 1'b0;
                mem_wr_data[2 +: TSTAMP_W] = '0;
                mem_wr_en = 1'b1;
                mem_rd_data_valid_next = 1'b0;

                state_next = STATE_IDLE;
            end
        end
    endcase
end

always_ff @(posedge clk) begin
    state_reg <= state_next;

    cur_index_reg <= cur_index_next;
    irqn_reg <= irqn_next;

    s_axis_irq_tready_reg <= s_axis_irq_tready_next;

    m_axis_irq_irqn_reg <= m_axis_irq_irqn_next;
    m_axis_irq_tvalid_reg <= m_axis_irq_tvalid_next;

    if (mem_wr_en) begin
        mem_reg[mem_addr] <= mem_wr_data;
    end else if (mem_rd_en) begin
        mem_rd_data_reg <= mem_reg[mem_addr];
    end

    mem_rd_data_valid_reg <= mem_rd_data_valid_next;

    if (rst) begin
        state_reg <= STATE_INIT;
        cur_index_reg <= '0;
        s_axis_irq_tready_reg <= 1'b0;
        m_axis_irq_tvalid_reg <= 1'b0;
        mem_rd_data_valid_reg <= 1'b0;
    end
end

endmodule

`resetall
