// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2014-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Synchronizes switch and button inputs with a slow sampled shift register
 */
module taxi_debounce_switch  #(
    // width of the input and output signals
    parameter WIDTH = 1,
    // length of shift register
    parameter N = 3,
    // clock division factor
    parameter RATE = 125000
)
(
    input  wire logic              clk,
    input  wire logic              rst,

    input  wire logic [WIDTH-1:0]  in,
    output wire logic [WIDTH-1:0]  out
);

localparam CNT_W = $clog2(RATE);

logic [CNT_W-1:0] cnt_reg = '0;
logic strb_reg = 1'b0;

logic [N-1:0] debounce_reg[WIDTH-1:0];

logic [WIDTH-1:0] state_reg = '0;

assign out = state_reg;

always_ff @(posedge clk) begin
    strb_reg <= 1'b0;

    if (cnt_reg) begin
        cnt_reg <= cnt_reg - 1;
    end else begin
        cnt_reg <= RATE-1;
        strb_reg <= 1'b1;
    end

    if (strb_reg) begin
        for (integer k = 0; k < WIDTH; k = k + 1) begin
            debounce_reg[k] <= {debounce_reg[k][N-2:0], in[k]};
        end
    end

    for (integer k = 0; k < WIDTH; k = k + 1) begin
        if (|debounce_reg[k] == 0) begin
            state_reg[k] <= 1'b0;
        end else if (&debounce_reg[k] == 1) begin
            state_reg[k] <= 1'b1;
        end
    end

    if (rst) begin
        cnt_reg <= '0;
        state_reg <= '0;

        for (integer k = 0; k < WIDTH; k = k + 1) begin
            debounce_reg[k] <= '0;
        end
    end
end

endmodule

`resetall
