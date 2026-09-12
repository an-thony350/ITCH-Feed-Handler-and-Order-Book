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
 * AXI4 FIFO testbench
 */
module test_taxi_axi_fifo #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter ADDR_W = 32,
    parameter DATA_W = 32,
    parameter STRB_W = (DATA_W/8),
    parameter ID_W = 8,
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
    parameter WRITE_FIFO_DEPTH = 32,
    parameter READ_FIFO_DEPTH = 32,
    parameter logic WRITE_FIFO_DELAY = 1'b0,
    parameter logic READ_FIFO_DELAY = 1'b0
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axi_if #(
    .DATA_W(DATA_W),
    .ADDR_W(ADDR_W),
    .STRB_W(STRB_W),
    .ID_W(ID_W),
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
) s_axi(), m_axi();

taxi_axi_fifo #(
    .WRITE_FIFO_DEPTH(WRITE_FIFO_DEPTH),
    .READ_FIFO_DEPTH(READ_FIFO_DEPTH),
    .WRITE_FIFO_DELAY(WRITE_FIFO_DELAY),
    .READ_FIFO_DELAY(READ_FIFO_DELAY)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4 slave interface
     */
    .s_axi_wr(s_axi),
    .s_axi_rd(s_axi),

    /*
     * AXI4 master interface
     */
    .m_axi_wr(m_axi),
    .m_axi_rd(m_axi)
);

endmodule

`resetall
