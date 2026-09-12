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
 * XFCP APB module testbench
 */
module test_taxi_xfcp_mod_apb #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter COUNT_SIZE = 16,
    parameter APB_DATA_W = 32,
    parameter APB_ADDR_W = 32,
    parameter APB_STRB_W = (APB_DATA_W/8)
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) xfcp_usp_ds(), xfcp_usp_us();

taxi_apb_if #(
    .DATA_W(APB_DATA_W),
    .ADDR_W(APB_ADDR_W),
    .STRB_W(APB_STRB_W)
) m_apb();

taxi_xfcp_mod_apb #(
    .COUNT_SIZE(COUNT_SIZE)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * XFCP upstream port
     */
    .xfcp_usp_ds(xfcp_usp_ds),
    .xfcp_usp_us(xfcp_usp_us),

    /*
     * APB master interface
     */
    .m_apb(m_apb)
);

endmodule

`resetall
