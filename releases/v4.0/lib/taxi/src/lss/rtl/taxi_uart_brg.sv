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
 * AXI4-Stream UART baud rate generator
 */
module taxi_uart_brg #(
    parameter PRE_W = 16
)
(
    input  wire logic              clk,
    input  wire logic              rst,

    /*
     * Baud rate pulse out
     */
    output wire logic              baud_clk,

    /*
     * Configuration
     */
    input  wire logic [PRE_W-1:0]  prescale
);

localparam FRAC_W = 3;
localparam INT_W = PRE_W - FRAC_W;

logic [INT_W-1:0] prescale_int_reg = 0;
logic [FRAC_W-1:0] prescale_frac_reg = 0;
logic frac_ovf_reg = 1'b0;
logic baud_clk_reg = 1'b0;

assign baud_clk = baud_clk_reg;

always_ff @(posedge clk) begin
    frac_ovf_reg <= 1'b0;
    baud_clk_reg <= 1'b0;

    if (frac_ovf_reg) begin
        // delay extra cycle
        frac_ovf_reg <= 1'b0;
    end else if (prescale_int_reg != 0) begin
        prescale_int_reg <= prescale_int_reg - 1;
    end else begin
        prescale_int_reg <= prescale[FRAC_W +: INT_W] - 1;
        {frac_ovf_reg, prescale_frac_reg} <= prescale_frac_reg + prescale[FRAC_W-1:0];
        baud_clk_reg <= 1'b1;
    end

    if (rst) begin
        prescale_int_reg <= 0;
        prescale_frac_reg <= 0;
        baud_clk_reg <= 0;
    end
end

endmodule

`resetall
