// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * MAC control transmitter testbench
 */
module test_taxi_mac_ctrl_tx #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 64,
    parameter ID_W = 8,
    parameter DEST_W = 8,
    parameter USER_W = 1,
    parameter MCF_PARAMS_SIZE = 18
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(DATA_W), .ID_EN(1), .ID_W(ID_W), .DEST_EN(1), .DEST_W(DEST_W), .USER_EN(1), .USER_W(USER_W)) s_axis(), m_axis();

logic mcf_valid;
logic mcf_ready;
logic [47:0] mcf_eth_dst;
logic [47:0] mcf_eth_src;
logic [15:0] mcf_eth_type;
logic [15:0] mcf_opcode;
logic [MCF_PARAMS_SIZE*8-1:0] mcf_params;
logic [ID_W-1:0] mcf_id;
logic [DEST_W-1:0] mcf_dest;
logic [USER_W-1:0] mcf_user;

logic tx_pause_req;
logic tx_pause_ack;

logic stat_tx_mcf;

taxi_mac_ctrl_tx #(
    .ID_W(ID_W),
    .DEST_W(DEST_W),
    .USER_W(USER_W),
    .MCF_PARAMS_SIZE(MCF_PARAMS_SIZE)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(s_axis),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(m_axis),

    /*
     * MAC control frame interface
     */
    .mcf_valid(mcf_valid),
    .mcf_ready(mcf_ready),
    .mcf_eth_dst(mcf_eth_dst),
    .mcf_eth_src(mcf_eth_src),
    .mcf_eth_type(mcf_eth_type),
    .mcf_opcode(mcf_opcode),
    .mcf_params(mcf_params),
    .mcf_id(mcf_id),
    .mcf_dest(mcf_dest),
    .mcf_user(mcf_user),

    /*
     * Pause interface
     */
    .tx_pause_req(tx_pause_req),
    .tx_pause_ack(tx_pause_ack),

    /*
     * Status
     */
    .stat_tx_mcf(stat_tx_mcf)
);

endmodule

`resetall
