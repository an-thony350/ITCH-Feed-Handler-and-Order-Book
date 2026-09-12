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
 * 10G Ethernet PHY TX
 */
module taxi_eth_phy_10g_tx #
(
    parameter DATA_W = 64,
    parameter CTRL_W = (DATA_W/8),
    parameter HDR_W = 2,
    parameter logic GBX_IF_EN = 1'b0,
    parameter logic BIT_REVERSE = 1'b0,
    parameter logic SCRAMBLER_DISABLE = 1'b0,
    parameter logic PRBS31_EN = 1'b0,
    parameter SERDES_PIPELINE = 0
)
(
    input  wire logic               clk,
    input  wire logic               rst,

    /*
     * XGMII interface
     */
    input  wire logic [DATA_W-1:0]  xgmii_txd,
    input  wire logic [CTRL_W-1:0]  xgmii_txc,
    input  wire logic               xgmii_tx_valid = 1'b1,
    output wire logic               tx_gbx_req_sync,
    output wire logic               tx_gbx_req_stall,
    input  wire logic               tx_gbx_sync = 1'b0,

    /*
     * SERDES interface
     */
    output wire logic [DATA_W-1:0]  serdes_tx_data,
    output wire logic               serdes_tx_data_valid,
    output wire logic [HDR_W-1:0]   serdes_tx_hdr,
    output wire logic               serdes_tx_hdr_valid,
    input  wire logic               serdes_tx_gbx_req_sync = 1'b0,
    input  wire logic               serdes_tx_gbx_req_stall = 1'b0,
    output wire logic               serdes_tx_gbx_sync,

    /*
     * Status
     */
    output wire logic               tx_bad_block,

    /*
     * Configuration
     */
    input  wire logic               cfg_tx_prbs31_enable
);

wire [DATA_W-1:0] encoded_tx_data;
wire              encoded_tx_data_valid;
wire [HDR_W-1:0]  encoded_tx_hdr;
wire              encoded_tx_hdr_valid;

wire tx_gbx_sync_int;

taxi_xgmii_baser_enc #(
    .DATA_W(DATA_W),
    .CTRL_W(CTRL_W),
    .HDR_W(HDR_W),
    .GBX_IF_EN(GBX_IF_EN),
    .GBX_CNT(1)
)
xgmii_baser_enc_inst (
    .clk(clk),
    .rst(rst),

    /*
     * XGMII interface
     */
    .xgmii_txd(xgmii_txd),
    .xgmii_txc(xgmii_txc),
    .xgmii_tx_valid(xgmii_tx_valid),
    .tx_gbx_sync_in(tx_gbx_sync),

    /*
     * 10GBASE-R encoded interface
     */
    .encoded_tx_data(encoded_tx_data),
    .encoded_tx_data_valid(encoded_tx_data_valid),
    .encoded_tx_hdr(encoded_tx_hdr),
    .encoded_tx_hdr_valid(encoded_tx_hdr_valid),
    .tx_gbx_sync_out(tx_gbx_sync_int),

    /*
     * Ordered sets
     */
    .tx_os('0),
    .tx_os_sig(1'b0),
    .tx_os_valid(1'b0),
    .tx_os_ready(),

    /*
     * Status
     */
    .tx_bad_block(tx_bad_block)
);

taxi_eth_phy_10g_tx_if #(
    .DATA_W(DATA_W),
    .HDR_W(HDR_W),
    .GBX_IF_EN(GBX_IF_EN),
    .BIT_REVERSE(BIT_REVERSE),
    .SCRAMBLER_DISABLE(SCRAMBLER_DISABLE),
    .PRBS31_EN(PRBS31_EN),
    .SERDES_PIPELINE(SERDES_PIPELINE)
)
eth_phy_10g_tx_if_inst (
    .clk(clk),
    .rst(rst),

    /*
     * 10GBASE-R encoded interface
     */
    .encoded_tx_data(encoded_tx_data),
    .encoded_tx_data_valid(encoded_tx_data_valid),
    .encoded_tx_hdr(encoded_tx_hdr),
    .encoded_tx_hdr_valid(encoded_tx_hdr_valid),
    .tx_gbx_req_sync(tx_gbx_req_sync),
    .tx_gbx_req_stall(tx_gbx_req_stall),
    .tx_gbx_sync(tx_gbx_sync_int),

    /*
     * SERDES interface
     */
    .serdes_tx_data(serdes_tx_data),
    .serdes_tx_data_valid(serdes_tx_data_valid),
    .serdes_tx_hdr(serdes_tx_hdr),
    .serdes_tx_hdr_valid(serdes_tx_hdr_valid),
    .serdes_tx_gbx_req_sync(serdes_tx_gbx_req_sync),
    .serdes_tx_gbx_req_stall(serdes_tx_gbx_req_stall),
    .serdes_tx_gbx_sync(serdes_tx_gbx_sync),

    /*
     * Configuration
     */
    .cfg_tx_prbs31_enable(cfg_tx_prbs31_enable)
);

endmodule

`resetall
