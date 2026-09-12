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
 * AXI4-Lite APB adapter testbench
 */
module test_taxi_axil_apb_adapter #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter ADDR_W = 32,
    parameter AXIL_DATA_W = 32,
    parameter AXIL_STRB_W = (AXIL_DATA_W/8),
    parameter APB_DATA_W = 32,
    parameter APB_STRB_W = (APB_DATA_W/8),
    parameter logic AWUSER_EN = 1'b0,
    parameter AWUSER_W = 1,
    parameter logic WUSER_EN = 1'b0,
    parameter WUSER_W = 1,
    parameter logic BUSER_EN = 1'b0,
    parameter BUSER_W = 1,
    parameter logic ARUSER_EN = 1'b0,
    parameter ARUSER_W = 1,
    parameter logic RUSER_EN = 1'b0,
    parameter RUSER_W = 1
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axil_if #(
    .DATA_W(AXIL_DATA_W),
    .ADDR_W(ADDR_W),
    .STRB_W(AXIL_STRB_W),
    .AWUSER_EN(AWUSER_EN),
    .AWUSER_W(AWUSER_W),
    .WUSER_EN(WUSER_EN),
    .WUSER_W(WUSER_W),
    .BUSER_EN(BUSER_EN),
    .BUSER_W(BUSER_W),
    .ARUSER_EN(ARUSER_EN),
    .ARUSER_W(ARUSER_W),
    .RUSER_EN(RUSER_EN),
    .RUSER_W(RUSER_W)
) s_axil();

taxi_apb_if #(
    .DATA_W(APB_DATA_W),
    .ADDR_W(ADDR_W),
    .STRB_W(APB_STRB_W),
    .PAUSER_EN(AWUSER_EN),
    .PAUSER_W(AWUSER_W),
    .PWUSER_EN(WUSER_EN),
    .PWUSER_W(WUSER_W),
    .PRUSER_EN(RUSER_EN),
    .PRUSER_W(RUSER_W),
    .PBUSER_EN(BUSER_EN),
    .PBUSER_W(BUSER_W)
) m_apb();

taxi_axil_apb_adapter
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-lite slave interface
     */
    .s_axil_wr(s_axil),
    .s_axil_rd(s_axil),

    /*
     * APB master interface
     */
    .m_apb(m_apb)
);

endmodule

`resetall
