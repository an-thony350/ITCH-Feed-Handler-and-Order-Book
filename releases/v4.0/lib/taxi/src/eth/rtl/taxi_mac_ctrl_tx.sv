// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2023-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * MAC control transmitter
 */
module taxi_mac_ctrl_tx #
(
    parameter ID_W = 8,
    parameter DEST_W = 8,
    parameter USER_W = 1,
    parameter MCF_PARAMS_SIZE = 18
)
(
    input  wire logic                          clk,
    input  wire logic                          rst,

    /*
     * AXI4-Stream input (sink)
     */
    taxi_axis_if.snk                           s_axis,

    /*
     * AXI4-Stream output (source)
     */
    taxi_axis_if.src                           m_axis,

    /*
     * MAC control frame interface
     */
    input  wire logic                          mcf_valid,
    output wire logic                          mcf_ready,
    input  wire logic [47:0]                   mcf_eth_dst,
    input  wire logic [47:0]                   mcf_eth_src,
    input  wire logic [15:0]                   mcf_eth_type,
    input  wire logic [15:0]                   mcf_opcode,
    input  wire logic [MCF_PARAMS_SIZE*8-1:0]  mcf_params,
    input  wire logic [ID_W-1:0]               mcf_id,
    input  wire logic [DEST_W-1:0]             mcf_dest,
    input  wire logic [USER_W-1:0]             mcf_user,

    /*
     * Pause interface
     */
    input  wire logic                          tx_pause_req,
    output wire logic                          tx_pause_ack,

    /*
     * Status
     */
    output wire logic                          stat_tx_mcf
);

// extract parameters
localparam DATA_W = s_axis.DATA_W;
localparam logic KEEP_EN = s_axis.KEEP_EN && m_axis.KEEP_EN;
localparam KEEP_W = s_axis.KEEP_W;
localparam logic STRB_EN = s_axis.STRB_EN && m_axis.STRB_EN;
localparam logic LAST_EN = s_axis.LAST_EN && m_axis.LAST_EN;
localparam logic ID_EN = s_axis.ID_EN && m_axis.ID_EN;
localparam logic DEST_EN = s_axis.DEST_EN && m_axis.DEST_EN;
localparam logic USER_EN = s_axis.USER_EN && m_axis.USER_EN;

localparam BYTE_LANES = KEEP_EN ? KEEP_W : 1;

localparam HDR_SIZE = 60;

localparam CYCLE_CNT = (HDR_SIZE+BYTE_LANES-1)/BYTE_LANES;

localparam PTR_W = $clog2(CYCLE_CNT+1);

localparam OFFSET = HDR_SIZE % BYTE_LANES;

// check configuration
if (BYTE_LANES * 8 != DATA_W)
    $fatal(0, "Error: AXI stream interface requires byte (8-bit) granularity (instance %m)");

if (MCF_PARAMS_SIZE > 44)
    $fatal(0, "Error: Maximum MCF_PARAMS_SIZE is 44 bytes (instance %m)");

if (m_axis.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (KEEP_EN && m_axis.KEEP_W != KEEP_W)
    $fatal(0, "Error: Interface KEEP_W parameter mismatch (instance %m)");

/*

MAC control frame

 Field                       Length
 Destination MAC address     6 octets [01:80:C2:00:00:01]
 Source MAC address          6 octets
 Ethertype                   2 octets [0x8808]
 Opcode                      2 octets
 Parameters                  0-44 octets

This module manages the transmission of MAC control frames.  Control frames
are accepted in parallel, serialized, and merged at a higher priority with
data traffic.

*/

logic send_data_reg = 1'b0, send_data_next;
logic send_mcf_reg = 1'b0, send_mcf_next;
logic [PTR_W-1:0] ptr_reg = 0, ptr_next;

logic s_axis_tready_reg = 1'b0, s_axis_tready_next;
logic mcf_ready_reg = 1'b0, mcf_ready_next;
logic tx_pause_ack_reg = 1'b0, tx_pause_ack_next;
logic stat_tx_mcf_reg = 1'b0, stat_tx_mcf_next;

// internal datapath
logic [DATA_W-1:0]  m_axis_tdata_int;
logic [KEEP_W-1:0]  m_axis_tkeep_int;
logic               m_axis_tvalid_int;
logic               m_axis_tready_int_reg = 1'b0;
logic               m_axis_tlast_int;
logic [ID_W-1:0]    m_axis_tid_int;
logic [DEST_W-1:0]  m_axis_tdest_int;
logic [USER_W-1:0]  m_axis_tuser_int;
wire                m_axis_tready_int_early;

assign s_axis.tready = s_axis_tready_reg;
assign mcf_ready = mcf_ready_reg;
assign tx_pause_ack = tx_pause_ack_reg;
assign stat_tx_mcf = stat_tx_mcf_reg;

always_comb begin
    send_data_next = send_data_reg;
    send_mcf_next = send_mcf_reg;
    ptr_next = ptr_reg;

    s_axis_tready_next = 1'b0;
    mcf_ready_next = 1'b0;
    tx_pause_ack_next = tx_pause_ack_reg;
    stat_tx_mcf_next = 1'b0;

    m_axis_tdata_int = 0;
    m_axis_tkeep_int = 0;
    m_axis_tvalid_int = 1'b0;
    m_axis_tlast_int = 1'b0;
    m_axis_tid_int = 0;
    m_axis_tdest_int = 0;
    m_axis_tuser_int = 0;

    if (!send_data_reg && !send_mcf_reg) begin
        m_axis_tdata_int = s_axis.tdata;
        m_axis_tkeep_int = s_axis.tkeep;
        m_axis_tvalid_int = 1'b0;
        m_axis_tlast_int = s_axis.tlast;
        m_axis_tid_int = s_axis.tid;
        m_axis_tdest_int = s_axis.tdest;
        m_axis_tuser_int = USER_W'(s_axis.tuser);
        s_axis_tready_next = m_axis_tready_int_early && !tx_pause_req;
        tx_pause_ack_next = tx_pause_req;
        if (s_axis.tvalid && s_axis.tready) begin
            s_axis_tready_next = m_axis_tready_int_early;
            tx_pause_ack_next = 1'b0;
            m_axis_tvalid_int = 1'b1;
            if (s_axis.tlast) begin
                s_axis_tready_next = m_axis_tready_int_early && !mcf_valid && !mcf_ready;
                send_data_next = 1'b0;
            end else begin
                send_data_next = 1'b1;
            end
        end else if (mcf_valid) begin
            s_axis_tready_next = 1'b0;
            ptr_next = 0;
            send_mcf_next = 1'b1;
            mcf_ready_next = (CYCLE_CNT == 1) && m_axis_tready_int_early;
        end
    end

    if (send_data_reg) begin
        m_axis_tdata_int = s_axis.tdata;
        m_axis_tkeep_int = s_axis.tkeep;
        m_axis_tvalid_int = 1'b0;
        m_axis_tlast_int = s_axis.tlast;
        m_axis_tid_int = s_axis.tid;
        m_axis_tdest_int = s_axis.tdest;
        m_axis_tuser_int = USER_W'(s_axis.tuser);
        s_axis_tready_next = m_axis_tready_int_early;
        if (s_axis.tvalid && s_axis.tready) begin
            m_axis_tvalid_int = 1'b1;
            if (s_axis.tlast) begin
                s_axis_tready_next = m_axis_tready_int_early && !tx_pause_req;
                send_data_next = 1'b0;
                if (mcf_valid) begin
                    s_axis_tready_next = 1'b0;
                    ptr_next = 0;
                    send_mcf_next = 1'b1;
                    mcf_ready_next = (CYCLE_CNT == 1) && m_axis_tready_int_early;
                end
            end else begin
                send_data_next = 1'b1;
            end
        end
    end

    if (send_mcf_reg) begin
        mcf_ready_next = (CYCLE_CNT == 1 || ptr_reg == PTR_W'(CYCLE_CNT-1)) && m_axis_tready_int_early;
        if (m_axis_tready_int_reg) begin
            ptr_next = ptr_reg + 1;

            m_axis_tvalid_int = 1'b1;
            m_axis_tid_int = mcf_id;
            m_axis_tdest_int = mcf_dest;
            m_axis_tuser_int = mcf_user;

            `define _HEADER_FIELD_(offset, field) \
                if (ptr_reg == PTR_W'(offset/BYTE_LANES)) begin \
                    m_axis_tdata_int[(offset%BYTE_LANES)*8 +: 8] = field; \
                    m_axis_tkeep_int[offset%BYTE_LANES] = 1'b1; \
                end

            `_HEADER_FIELD_(0,  mcf_eth_dst[5*8 +: 8])
            `_HEADER_FIELD_(1,  mcf_eth_dst[4*8 +: 8])
            `_HEADER_FIELD_(2,  mcf_eth_dst[3*8 +: 8])
            `_HEADER_FIELD_(3,  mcf_eth_dst[2*8 +: 8])
            `_HEADER_FIELD_(4,  mcf_eth_dst[1*8 +: 8])
            `_HEADER_FIELD_(5,  mcf_eth_dst[0*8 +: 8])
            `_HEADER_FIELD_(6,  mcf_eth_src[5*8 +: 8])
            `_HEADER_FIELD_(7,  mcf_eth_src[4*8 +: 8])
            `_HEADER_FIELD_(8,  mcf_eth_src[3*8 +: 8])
            `_HEADER_FIELD_(9,  mcf_eth_src[2*8 +: 8])
            `_HEADER_FIELD_(10, mcf_eth_src[1*8 +: 8])
            `_HEADER_FIELD_(11, mcf_eth_src[0*8 +: 8])
            `_HEADER_FIELD_(12, mcf_eth_type[1*8 +: 8])
            `_HEADER_FIELD_(13, mcf_eth_type[0*8 +: 8])
            `_HEADER_FIELD_(14, mcf_opcode[1*8 +: 8])
            `_HEADER_FIELD_(15, mcf_opcode[0*8 +: 8])

            for (integer k = 0; k < HDR_SIZE-16; k = k + 1) begin
                if (ptr_reg == PTR_W'((16+k)/BYTE_LANES)) begin
                    if (k < MCF_PARAMS_SIZE) begin
                        m_axis_tdata_int[((16+k)%BYTE_LANES)*8 +: 8] = mcf_params[k*8 +: 8];
                    end else begin
                        m_axis_tdata_int[((16+k)%BYTE_LANES)*8 +: 8] = 0;
                    end
                    m_axis_tkeep_int[(16+k)%BYTE_LANES] = 1'b1;
                end
            end

            if (ptr_reg == PTR_W'((HDR_SIZE-1)/BYTE_LANES)) begin
                s_axis_tready_next = m_axis_tready_int_early && !tx_pause_req;
                mcf_ready_next = 1'b0;
                m_axis_tlast_int = 1'b1;
                send_mcf_next = 1'b0;
                stat_tx_mcf_next = 1'b1;
            end else begin
                mcf_ready_next = (ptr_next == PTR_W'(CYCLE_CNT-1)) && m_axis_tready_int_early;
            end

            `undef _HEADER_FIELD_
        end
    end
end

always_ff @(posedge clk) begin
    send_data_reg <= send_data_next;
    send_mcf_reg <= send_mcf_next;
    ptr_reg <= ptr_next;

    s_axis_tready_reg <= s_axis_tready_next;
    mcf_ready_reg <= mcf_ready_next;
    tx_pause_ack_reg <= tx_pause_ack_next;
    stat_tx_mcf_reg <= stat_tx_mcf_next;

    if (rst) begin
        send_data_reg <= 1'b0;
        send_mcf_reg <= 1'b0;
        ptr_reg <= 0;
        s_axis_tready_reg <= 1'b0;
        mcf_ready_reg <= 1'b0;
        tx_pause_ack_reg <= 1'b0;
        stat_tx_mcf_reg <= 1'b0;
    end
end

// output datapath logic
logic [DATA_W-1:0] m_axis_tdata_reg  = '0;
logic [KEEP_W-1:0] m_axis_tkeep_reg  = '0;
logic              m_axis_tvalid_reg = 1'b0, m_axis_tvalid_next;
logic              m_axis_tlast_reg  = 1'b0;
logic [ID_W-1:0]   m_axis_tid_reg    = '0;
logic [DEST_W-1:0] m_axis_tdest_reg  = '0;
logic [USER_W-1:0] m_axis_tuser_reg  = '0;

logic [DATA_W-1:0] temp_m_axis_tdata_reg  = '0;
logic [KEEP_W-1:0] temp_m_axis_tkeep_reg  = '0;
logic              temp_m_axis_tvalid_reg = 1'b0, temp_m_axis_tvalid_next;
logic              temp_m_axis_tlast_reg  = 1'b0;
logic [ID_W-1:0]   temp_m_axis_tid_reg    = '0;
logic [DEST_W-1:0] temp_m_axis_tdest_reg  = '0;
logic [USER_W-1:0] temp_m_axis_tuser_reg  = '0;

// datapath control
logic store_axis_int_to_output;
logic store_axis_int_to_temp;
logic store_axis_temp_to_output;

assign m_axis.tdata  = m_axis_tdata_reg;
assign m_axis.tkeep  = KEEP_EN ? m_axis_tkeep_reg : '1;
assign m_axis.tstrb  = m_axis.tkeep;
assign m_axis.tvalid = m_axis_tvalid_reg;
assign m_axis.tlast  = m_axis_tlast_reg;
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
        m_axis_tlast_reg <= m_axis_tlast_int;
        m_axis_tid_reg   <= m_axis_tid_int;
        m_axis_tdest_reg <= m_axis_tdest_int;
        m_axis_tuser_reg <= m_axis_tuser_int;
    end else if (store_axis_temp_to_output) begin
        m_axis_tdata_reg <= temp_m_axis_tdata_reg;
        m_axis_tkeep_reg <= temp_m_axis_tkeep_reg;
        m_axis_tlast_reg <= temp_m_axis_tlast_reg;
        m_axis_tid_reg   <= temp_m_axis_tid_reg;
        m_axis_tdest_reg <= temp_m_axis_tdest_reg;
        m_axis_tuser_reg <= temp_m_axis_tuser_reg;
    end

    if (store_axis_int_to_temp) begin
        temp_m_axis_tdata_reg <= m_axis_tdata_int;
        temp_m_axis_tkeep_reg <= m_axis_tkeep_int;
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
