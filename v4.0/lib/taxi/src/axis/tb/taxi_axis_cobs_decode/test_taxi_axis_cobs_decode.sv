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
 * AXI4-Stream COBS decoder testbench
 */
module test_taxi_axis_cobs_decode();

logic clk;
logic rst;

taxi_axis_if #(
    .DATA_W(8),
    .LAST_EN(1),
    .USER_EN(1),
    .USER_W(1)
) s_axis(), m_axis();

taxi_axis_cobs_decode
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(s_axis),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(m_axis)
);

endmodule

`resetall
