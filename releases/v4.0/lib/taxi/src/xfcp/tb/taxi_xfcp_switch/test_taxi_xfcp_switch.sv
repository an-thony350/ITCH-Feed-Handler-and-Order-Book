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
 * XFCP switch testbench
 */
module test_taxi_xfcp_switch #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter PORTS = 4
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) xfcp_usp_ds(), xfcp_usp_us();
taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) xfcp_dsp_ds[PORTS](), xfcp_dsp_us[PORTS]();

taxi_xfcp_switch #(
    .PORTS(PORTS)
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
     * XFCP downstream ports
     */
    .xfcp_dsp_ds(xfcp_dsp_ds),
    .xfcp_dsp_us(xfcp_dsp_us)
);

endmodule

`resetall
