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
 * APB width adapter testbench
 */
module test_taxi_apb_adapter #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter ADDR_W = 32,
    parameter S_DATA_W = 32,
    parameter S_STRB_W = (S_DATA_W/8),
    parameter M_DATA_W = 32,
    parameter M_STRB_W = (M_DATA_W/8),
    parameter logic PAUSER_EN = 1'b0,
    parameter PAUSER_W = 1,
    parameter logic PWUSER_EN = 1'b0,
    parameter PWUSER_W = 1,
    parameter logic PRUSER_EN = 1'b0,
    parameter PRUSER_W = 1,
    parameter logic PBUSER_EN = 1'b0,
    parameter PBUSER_W = 1
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_apb_if #(
    .DATA_W(S_DATA_W),
    .ADDR_W(ADDR_W),
    .STRB_W(S_STRB_W),
    .PAUSER_EN(PAUSER_EN),
    .PAUSER_W(PAUSER_W),
    .PWUSER_EN(PWUSER_EN),
    .PWUSER_W(PWUSER_W),
    .PRUSER_EN(PRUSER_EN),
    .PRUSER_W(PRUSER_W),
    .PBUSER_EN(PBUSER_EN),
    .PBUSER_W(PBUSER_W)
) s_apb();

taxi_apb_if #(
    .DATA_W(M_DATA_W),
    .ADDR_W(ADDR_W),
    .STRB_W(M_STRB_W),
    .PAUSER_EN(PAUSER_EN),
    .PAUSER_W(PAUSER_W),
    .PWUSER_EN(PWUSER_EN),
    .PWUSER_W(PWUSER_W),
    .PRUSER_EN(PRUSER_EN),
    .PRUSER_W(PRUSER_W),
    .PBUSER_EN(PBUSER_EN),
    .PBUSER_W(PBUSER_W)
) m_apb();

taxi_apb_adapter
uut (
    .clk(clk),
    .rst(rst),

    /*
     * APB slave interface
     */
    .s_apb(s_apb),

    /*
     * APB master interface
     */
    .m_apb(m_apb)
);

endmodule

`resetall
