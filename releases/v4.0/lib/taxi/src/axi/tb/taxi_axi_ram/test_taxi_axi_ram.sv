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
 * AXI4 RAM testbench
 */
module test_taxi_axi_ram #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 32,
    parameter ADDR_W = 16,
    parameter STRB_W = (DATA_W/8),
    parameter ID_W = 8,
    parameter PIPELINE_OUTPUT = 0
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axi_if #(
    .DATA_W(DATA_W),
    .ADDR_W(ADDR_W+16),
    .STRB_W(STRB_W),
    .ID_W(ID_W)
) s_axi();

taxi_axi_ram #(
    .ADDR_W(ADDR_W),
    .PIPELINE_OUTPUT(PIPELINE_OUTPUT)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Lite slave interface
     */
    .s_axi_wr(s_axi),
    .s_axi_rd(s_axi)
);

endmodule

`resetall
