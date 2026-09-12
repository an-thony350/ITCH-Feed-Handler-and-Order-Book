// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2026 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * IRQ rate limit module testbench
 */
module test_taxi_irq_rate_limit #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter IRQN_W = 11
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(
    .DATA_W(IRQN_W),
    .KEEP_EN(0),
    .KEEP_W(1)
) s_axis_irq(), m_axis_irq();

logic [15:0] prescale;
logic [15:0] min_interval;

taxi_irq_rate_limit
uut (
    .clk(clk),
    .rst(rst),

    /*
     * Interrupt request input
     */
    .s_axis_irq(s_axis_irq),

    /*
     * Interrupt request output
     */
    .m_axis_irq(m_axis_irq),

    /*
     * Configuration
     */
    .prescale(prescale),
    .min_interval(min_interval)
);

endmodule

`resetall
