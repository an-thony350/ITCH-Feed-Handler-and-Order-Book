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
 * XFCP AXI module testbench
 */
module test_taxi_xfcp_mod_axi #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter COUNT_SIZE = 16,
    parameter AXI_DATA_W = 32,
    parameter AXI_ADDR_W = 32,
    parameter AXI_STRB_W = (AXI_DATA_W/8)
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) xfcp_usp_ds(), xfcp_usp_us();

taxi_axi_if #(
    .DATA_W(AXI_DATA_W),
    .ADDR_W(AXI_ADDR_W),
    .STRB_W(AXI_STRB_W)
) m_axi();

taxi_xfcp_mod_axi #(
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
     * AXI master interface
     */
    .m_axi_wr(m_axi),
    .m_axi_rd(m_axi)
);

endmodule

`resetall
