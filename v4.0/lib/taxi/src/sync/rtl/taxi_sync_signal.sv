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
 * Synchronizes an asynchronous signal to a given clock by using a pipeline of
 * two registers.
 */
module taxi_sync_signal #(
    // width of the input and output signals
    parameter WIDTH = 1,
    // depth of synchronizer
    parameter N = 2
)
(
    input  wire logic              clk,

    input  wire logic [WIDTH-1:0]  in,
    output wire logic [WIDTH-1:0]  out
);

(* async_reg="true", srl_style="register", shreg_extract="no" *)
logic [WIDTH-1:0] sync_reg[N-1:0];

assign out = sync_reg[N-1];

always_ff @(posedge clk) begin
    sync_reg[0] <= in;
    for (integer k = 1; k < N; k = k + 1) begin
        sync_reg[k] <= sync_reg[k-1];
    end
end

endmodule

`resetall
