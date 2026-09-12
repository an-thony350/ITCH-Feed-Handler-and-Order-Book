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
 * Synchronizes an active-high asynchronous reset signal to a given clock by
 * using a pipeline of N registers.
 */
module taxi_sync_reset #
(
    // depth of synchronizer
    parameter N = 2
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    output wire logic  out
);

(* async_reg="true", srl_style="register", shreg_extract="no" *)
logic [N-1:0] sync_reg = '1;

assign out = sync_reg[N-1];

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        sync_reg <= '1;
    end else begin
        sync_reg <= {sync_reg[N-2:0], 1'b0};
    end
end

endmodule

`resetall
