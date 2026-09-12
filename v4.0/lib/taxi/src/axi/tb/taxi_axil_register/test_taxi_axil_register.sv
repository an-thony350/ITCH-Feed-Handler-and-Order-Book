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
 * AXI4 lite register testbench
 */
module test_taxi_axil_register #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 32,
    parameter ADDR_W = 32,
    parameter STRB_W = (DATA_W/8),
    parameter logic AWUSER_EN = 1'b0,
    parameter AWUSER_W = 1,
    parameter logic WUSER_EN = 1'b0,
    parameter WUSER_W = 1,
    parameter logic BUSER_EN = 1'b0,
    parameter BUSER_W = 1,
    parameter logic ARUSER_EN = 1'b0,
    parameter ARUSER_W = 1,
    parameter logic RUSER_EN = 1'b0,
    parameter RUSER_W = 1,
    parameter AW_REG_TYPE = 1,
    parameter W_REG_TYPE = 1,
    parameter B_REG_TYPE = 1,
    parameter AR_REG_TYPE = 1,
    parameter R_REG_TYPE = 1
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axil_if #(
    .DATA_W(DATA_W),
    .ADDR_W(ADDR_W),
    .STRB_W(STRB_W),
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
) s_axil(), m_axil();

taxi_axil_register #(
    .AW_REG_TYPE(AW_REG_TYPE),
    .W_REG_TYPE(W_REG_TYPE),
    .B_REG_TYPE(B_REG_TYPE),
    .AR_REG_TYPE(AR_REG_TYPE),
    .R_REG_TYPE(R_REG_TYPE)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Lite slave interface
     */
    .s_axil_wr(s_axil),
    .s_axil_rd(s_axil),

    /*
     * AXI4-Lite master interface
     */
    .m_axil_wr(m_axil),
    .m_axil_rd(m_axil)
);

endmodule

`resetall
