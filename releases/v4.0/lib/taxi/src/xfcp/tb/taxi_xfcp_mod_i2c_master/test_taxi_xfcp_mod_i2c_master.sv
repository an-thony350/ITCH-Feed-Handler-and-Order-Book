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
 * XFCP I2C master module testbench
 */
module test_taxi_xfcp_mod_i2c_master #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter logic [15:0] DEFAULT_PRESCALE = 125000000/400000/4
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) xfcp_usp_ds(), xfcp_usp_us();

logic  i2c_scl_i;
logic  i2c_scl_o;
logic  i2c_sda_i;
logic  i2c_sda_o;

taxi_xfcp_mod_i2c_master #(
    .DEFAULT_PRESCALE(DEFAULT_PRESCALE)
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
     * I2C interface
     */
    .i2c_scl_i(i2c_scl_i),
    .i2c_scl_o(i2c_scl_o),
    .i2c_sda_i(i2c_sda_i),
    .i2c_sda_o(i2c_sda_o)
);

endmodule

`resetall
