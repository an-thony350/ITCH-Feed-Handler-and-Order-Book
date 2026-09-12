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
 * MAC control receiver
 */
module taxi_mac_ctrl_rx #
(
    parameter ID_W = 8,
    parameter DEST_W = 8,
    parameter USER_W = 1,
    parameter logic USE_READY = 1'b0,
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
    output wire logic                          mcf_valid,
    output wire logic [47:0]                   mcf_eth_dst,
    output wire logic [47:0]                   mcf_eth_src,
    output wire logic [15:0]                   mcf_eth_type,
    output wire logic [15:0]                   mcf_opcode,
    output wire logic [MCF_PARAMS_SIZE*8-1:0]  mcf_params,
    output wire logic [ID_W-1:0]               mcf_id,
    output wire logic [DEST_W-1:0]             mcf_dest,
    output wire logic [USER_W-1:0]             mcf_user,

    /*
     * Configuration
     */
    input  wire logic [47:0]                   cfg_mcf_rx_eth_dst_mcast,
    input  wire logic                          cfg_mcf_rx_check_eth_dst_mcast,
    input  wire logic [47:0]                   cfg_mcf_rx_eth_dst_ucast,
    input  wire logic                          cfg_mcf_rx_check_eth_dst_ucast,
    input  wire logic [47:0]                   cfg_mcf_rx_eth_src,
    input  wire logic                          cfg_mcf_rx_check_eth_src,
    input  wire logic [15:0]                   cfg_mcf_rx_eth_type,
    input  wire logic [15:0]                   cfg_mcf_rx_opcode_lfc,
    input  wire logic                          cfg_mcf_rx_check_opcode_lfc,
    input  wire logic [15:0]                   cfg_mcf_rx_opcode_pfc,
    input  wire logic                          cfg_mcf_rx_check_opcode_pfc,
    input  wire logic                          cfg_mcf_rx_forward,
    input  wire logic                          cfg_mcf_rx_enable,

    /*
     * Status
     */
    output wire logic                          stat_rx_mcf
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

This module manages the reception of MAC control frames.  Incoming frames are
checked based on the ethertype and (optionally) MAC addresses.  Matching control
frames are marked by setting tuser[0] on the data output and forwarded through
a separate interface for processing.

*/

logic read_mcf_reg = 1'b1, read_mcf_next;
logic mcf_frame_reg = 1'b0, mcf_frame_next;
logic [PTR_W-1:0] ptr_reg = 0, ptr_next;

logic s_axis_tready_reg = 1'b0, s_axis_tready_next;

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

logic                          mcf_valid_reg = 0, mcf_valid_next;
logic [47:0]                   mcf_eth_dst_reg = 0, mcf_eth_dst_next;
logic [47:0]                   mcf_eth_src_reg = 0, mcf_eth_src_next;
logic [15:0]                   mcf_eth_type_reg = 0, mcf_eth_type_next;
logic [15:0]                   mcf_opcode_reg = 0, mcf_opcode_next;
logic [MCF_PARAMS_SIZE*8-1:0]  mcf_params_reg = 0, mcf_params_next;
logic [ID_W-1:0]               mcf_id_reg = 0, mcf_id_next;
logic [DEST_W-1:0]             mcf_dest_reg = 0, mcf_dest_next;
logic [USER_W-1:0]             mcf_user_reg = 0, mcf_user_next;

logic stat_rx_mcf_reg = 1'b0, stat_rx_mcf_next;

assign s_axis.tready = s_axis_tready_reg;

assign mcf_valid = mcf_valid_reg;
assign mcf_eth_dst = mcf_eth_dst_reg;
assign mcf_eth_src = mcf_eth_src_reg;
assign mcf_eth_type = mcf_eth_type_reg;
assign mcf_opcode = mcf_opcode_reg;
assign mcf_params = mcf_params_reg;
assign mcf_id = mcf_id_reg;
assign mcf_dest = mcf_dest_reg;
assign mcf_user = mcf_user_reg;

assign stat_rx_mcf = stat_rx_mcf_reg;

wire mcf_eth_dst_mcast_match = mcf_eth_dst_next == cfg_mcf_rx_eth_dst_mcast;
wire mcf_eth_dst_ucast_match = mcf_eth_dst_next == cfg_mcf_rx_eth_dst_ucast;
wire mcf_eth_src_match = mcf_eth_src_next == cfg_mcf_rx_eth_src;
wire mcf_eth_type_match = mcf_eth_type_next == cfg_mcf_rx_eth_type;
wire mcf_opcode_lfc_match = mcf_opcode_next == cfg_mcf_rx_opcode_lfc;
wire mcf_opcode_pfc_match = mcf_opcode_next == cfg_mcf_rx_opcode_pfc;

wire mcf_eth_dst_match = ((mcf_eth_dst_mcast_match && cfg_mcf_rx_check_eth_dst_mcast) ||
    (mcf_eth_dst_ucast_match && cfg_mcf_rx_check_eth_dst_ucast) ||
    (!cfg_mcf_rx_check_eth_dst_mcast && !cfg_mcf_rx_check_eth_dst_ucast));

wire mcf_opcode_match = ((mcf_opcode_lfc_match && cfg_mcf_rx_check_opcode_lfc) ||
    (mcf_opcode_pfc_match && cfg_mcf_rx_check_opcode_pfc) ||
    (!cfg_mcf_rx_check_opcode_lfc && !cfg_mcf_rx_check_opcode_pfc));

wire mcf_match = (mcf_eth_dst_match &&
    (mcf_eth_src_match || !cfg_mcf_rx_check_eth_src) &&
    mcf_eth_type_match && mcf_opcode_match);

always_comb begin
    read_mcf_next = read_mcf_reg;
    mcf_frame_next = mcf_frame_reg;
    ptr_next = ptr_reg;

    // pass through data
    m_axis_tdata_int = s_axis.tdata;
    m_axis_tkeep_int = s_axis.tkeep;
    m_axis_tvalid_int = s_axis.tvalid;
    m_axis_tlast_int = s_axis.tlast;
    m_axis_tid_int = s_axis.tid;
    m_axis_tdest_int = s_axis.tdest;
    m_axis_tuser_int = USER_W'(s_axis.tuser);

    s_axis_tready_next = m_axis_tready_int_early || !USE_READY;

    mcf_valid_next = 1'b0;
    mcf_eth_dst_next = mcf_eth_dst_reg;
    mcf_eth_src_next = mcf_eth_src_reg;
    mcf_eth_type_next = mcf_eth_type_reg;
    mcf_opcode_next = mcf_opcode_reg;
    mcf_params_next = mcf_params_reg;
    mcf_id_next = mcf_id_reg;
    mcf_dest_next = mcf_dest_reg;
    mcf_user_next = mcf_user_reg;

    stat_rx_mcf_next = 1'b0;

    if ((s_axis.tready || !USE_READY) && s_axis.tvalid) begin
        if (read_mcf_reg) begin
            ptr_next = ptr_reg + 1;

            mcf_id_next = s_axis.tid;
            mcf_dest_next = s_axis.tdest;
            mcf_user_next = s_axis.tuser;

            `define _HEADER_FIELD_(offset, field) \
                if (ptr_reg == PTR_W'(offset/BYTE_LANES)) begin \
                    field = s_axis.tdata[(offset%BYTE_LANES)*8 +: 8]; \
                end

            `_HEADER_FIELD_(0,  mcf_eth_dst_next[5*8 +: 8])
            `_HEADER_FIELD_(1,  mcf_eth_dst_next[4*8 +: 8])
            `_HEADER_FIELD_(2,  mcf_eth_dst_next[3*8 +: 8])
            `_HEADER_FIELD_(3,  mcf_eth_dst_next[2*8 +: 8])
            `_HEADER_FIELD_(4,  mcf_eth_dst_next[1*8 +: 8])
            `_HEADER_FIELD_(5,  mcf_eth_dst_next[0*8 +: 8])
            `_HEADER_FIELD_(6,  mcf_eth_src_next[5*8 +: 8])
            `_HEADER_FIELD_(7,  mcf_eth_src_next[4*8 +: 8])
            `_HEADER_FIELD_(8,  mcf_eth_src_next[3*8 +: 8])
            `_HEADER_FIELD_(9,  mcf_eth_src_next[2*8 +: 8])
            `_HEADER_FIELD_(10, mcf_eth_src_next[1*8 +: 8])
            `_HEADER_FIELD_(11, mcf_eth_src_next[0*8 +: 8])
            `_HEADER_FIELD_(12, mcf_eth_type_next[1*8 +: 8])
            `_HEADER_FIELD_(13, mcf_eth_type_next[0*8 +: 8])
            `_HEADER_FIELD_(14, mcf_opcode_next[1*8 +: 8])
            `_HEADER_FIELD_(15, mcf_opcode_next[0*8 +: 8])

            if (ptr_reg == PTR_W'(0/BYTE_LANES)) begin
                // ensure params field gets cleared
                mcf_params_next = 0;
            end

            for (integer k = 0; k < MCF_PARAMS_SIZE; k = k + 1) begin
                if (ptr_reg == PTR_W'((16+k)/BYTE_LANES)) begin
                    mcf_params_next[k*8 +: 8] = s_axis.tdata[((16+k)%BYTE_LANES)*8 +: 8];
                end
            end

            if (ptr_reg == PTR_W'(15/BYTE_LANES) && (!KEEP_EN || s_axis.tkeep[13%BYTE_LANES])) begin
                // record match at end of opcode field
                mcf_frame_next = mcf_match && cfg_mcf_rx_enable;
            end

            if (ptr_reg == PTR_W'((HDR_SIZE-1)/BYTE_LANES)) begin
                read_mcf_next = 1'b0;
            end

            `undef _HEADER_FIELD_
        end

        if (s_axis.tlast) begin
            if (s_axis.tuser[0]) begin
                // frame marked invalid
            end else if (mcf_frame_next) begin
                if (!cfg_mcf_rx_forward) begin
                    // mark frame invalid
                    m_axis_tuser_int[0] = 1'b1;
                end
                // transfer out MAC control frame
                mcf_valid_next = 1'b1;
                stat_rx_mcf_next = 1'b1;
            end

            read_mcf_next = 1'b1;
            mcf_frame_next = 1'b0;
            ptr_next = '0;
        end
    end
end

always_ff @(posedge clk) begin
    read_mcf_reg <= read_mcf_next;
    mcf_frame_reg <= mcf_frame_next;
    ptr_reg <= ptr_next;

    s_axis_tready_reg <= s_axis_tready_next;

    mcf_valid_reg <= mcf_valid_next;
    mcf_eth_dst_reg <= mcf_eth_dst_next;
    mcf_eth_src_reg <= mcf_eth_src_next;
    mcf_eth_type_reg <= mcf_eth_type_next;
    mcf_opcode_reg <= mcf_opcode_next;
    mcf_params_reg <= mcf_params_next;
    mcf_id_reg <= mcf_id_next;
    mcf_dest_reg <= mcf_dest_next;
    mcf_user_reg <= mcf_user_next;

    stat_rx_mcf_reg <= stat_rx_mcf_next;

    if (rst) begin
        read_mcf_reg <= 1'b1;
        mcf_frame_reg <= 1'b0;
        ptr_reg <= '0;
        s_axis_tready_reg <= 1'b0;
        mcf_valid_reg <= 1'b0;
        stat_rx_mcf_reg <= 1'b0;
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
assign m_axis_tready_int_early = m_axis.tready || !USE_READY || (!temp_m_axis_tvalid_reg && (!m_axis_tvalid_reg || !m_axis_tvalid_int));

always_comb begin
    // transfer sink ready state to source
    m_axis_tvalid_next = m_axis_tvalid_reg;
    temp_m_axis_tvalid_next = temp_m_axis_tvalid_reg;

    store_axis_int_to_output = 1'b0;
    store_axis_int_to_temp = 1'b0;
    store_axis_temp_to_output = 1'b0;

    if (m_axis_tready_int_reg) begin
        // input is ready
        if (m_axis.tready || !USE_READY || !m_axis_tvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            m_axis_tvalid_next = m_axis_tvalid_int;
            store_axis_int_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_axis_tvalid_next = m_axis_tvalid_int;
            store_axis_int_to_temp = 1'b1;
        end
    end else if (m_axis.tready || !USE_READY) begin
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
