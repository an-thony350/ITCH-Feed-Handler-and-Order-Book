// SPDX-License-Identifier: MIT
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream null sink
 */
module taxi_axis_null_snk
(
    /*
     * AXI4-Stream input (sink)
     */
    taxi_axis_if.snk  s_axis
);

assign s_axis.tready = 1'b1;

endmodule

`resetall
