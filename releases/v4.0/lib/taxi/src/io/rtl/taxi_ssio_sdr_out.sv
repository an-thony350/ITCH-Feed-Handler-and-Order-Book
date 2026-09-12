// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2016-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Generic source synchronous SDR output
 */
module taxi_ssio_sdr_out #
(
    // simulation (set to avoid vendor primitives)
    parameter logic SIM = 1'b0,
    // vendor ("GENERIC", "XILINX", "ALTERA")
    parameter string VENDOR = "XILINX",
    // device family
    parameter string FAMILY = "virtex7",
    // Width of register in bits
    parameter WIDTH = 1
)
(
    input  wire logic              clk,

    input  wire logic [WIDTH-1:0]  input_d,

    output wire logic              output_clk,
    output wire logic [WIDTH-1:0]  output_q
);

taxi_oddr #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .WIDTH(1)
)
clk_oddr_inst (
    .clk(clk),
    .d1(1'b0),
    .d2(1'b1),
    .q(output_clk)
);

(* IOB = "TRUE" *)
logic [WIDTH-1:0] output_q_reg = '0;

assign output_q = output_q_reg;

always_ff @(posedge clk) begin
    output_q_reg <= input_d;
end

endmodule

`resetall
