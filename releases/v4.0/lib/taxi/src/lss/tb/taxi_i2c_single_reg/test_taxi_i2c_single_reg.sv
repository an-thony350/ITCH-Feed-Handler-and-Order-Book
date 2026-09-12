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
 * I2C single register testbench
 */
module test_taxi_i2c_single_reg #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter FILTER_LEN = 4,
    parameter logic [6:0] DEV_ADDR = 7'h70
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

logic scl_i;
logic scl_o;
logic sda_i;
logic sda_o;

logic [7:0] data_in;
logic data_latch;
logic [7:0] data_out;

taxi_i2c_single_reg #(
    .FILTER_LEN(FILTER_LEN),
    .DEV_ADDR(DEV_ADDR)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * I2C interface
     */
    .scl_i(scl_i),
    .scl_o(scl_o),
    .sda_i(sda_i),
    .sda_o(sda_o),

    /*
     * Data register
     */
    .data_in(data_in),
    .data_latch(data_latch),
    .data_out(data_out)
);

endmodule

`resetall
