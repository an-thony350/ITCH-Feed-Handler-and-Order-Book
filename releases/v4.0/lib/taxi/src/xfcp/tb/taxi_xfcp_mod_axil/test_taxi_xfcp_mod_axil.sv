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
 * XFCP AXI lite module testbench
 */
module test_taxi_xfcp_mod_axil #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter COUNT_SIZE = 16,
    parameter AXIL_DATA_W = 32,
    parameter AXIL_ADDR_W = 32,
    parameter AXIL_STRB_W = (AXIL_DATA_W/8)
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) xfcp_usp_ds(), xfcp_usp_us();

taxi_axil_if #(
    .DATA_W(AXIL_DATA_W),
    .ADDR_W(AXIL_ADDR_W),
    .STRB_W(AXIL_STRB_W)
) m_axil();

taxi_xfcp_mod_axil #(
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
     * AXI lite master interface
     */
    .m_axil_wr(m_axil),
    .m_axil_rd(m_axil)
);

endmodule

`resetall
