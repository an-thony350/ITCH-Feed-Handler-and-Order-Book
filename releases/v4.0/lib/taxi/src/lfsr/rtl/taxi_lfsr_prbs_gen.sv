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
 * LFSR PRBS generator
 */
module taxi_lfsr_prbs_gen #
(
    // width of LFSR
    parameter LFSR_W = 31,
    // LFSR polynomial
    parameter logic [LFSR_W-1:0] LFSR_POLY = 31'h10000001,
    // Initial state
    parameter logic [LFSR_W-1:0] LFSR_INIT = '1,
    // LFSR configuration: 0 for Fibonacci (PRBS), 1 for Galois (CRC)
    parameter logic LFSR_GALOIS = 1'b0,
    // bit-reverse input and output
    parameter logic REVERSE = 1'b0,
    // invert output
    parameter logic INVERT = 1'b1,
    // width of data output
    parameter DATA_W = 8
)
(
    input  wire logic               clk,
    input  wire logic               rst,

    input  wire logic               enable,
    output wire logic [DATA_W-1:0]  data_out
);

/*

Fully parametrizable combinatorial parallel LFSR PRBS module.  Implements an unrolled LFSR
next state computation.

Ports:

clk

Clock input

rst

Reset input, set state to LFSR_INIT

enable

Generate new output data

data_out

LFSR output (DATA_W bits)

Parameters:

LFSR_W

Specify width of LFSR/CRC register

LFSR_POLY

Specify the LFSR/CRC polynomial in hex format.  For example, the polynomial

x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1

would be represented as

32'h04c11db7

Note that the largest term (x^32) is suppressed.  This term is generated automatically based
on LFSR_W.

LFSR_INIT

Initial state of LFSR.  Defaults to all 1s.

LFSR_GALOIS

Specify the LFSR configuration, either Fibonacci (0) or Galois (1).  Fibonacci is generally used
for linear-feedback shift registers (LFSR) for pseudorandom binary sequence (PRBS) generators,
scramblers, and descrambers, while Galois is generally used for cyclic redundancy check
generators and checkers.

Fibonacci style (example for 64b66b scrambler, 0x8000000001)

   DIN (LSB first)
    |
    V
   (+)<---------------------------(+)<-----------------------------.
    |                              ^                               |
    |  .----.  .----.       .----. |  .----.       .----.  .----.  |
    +->|  0 |->|  1 |->...->| 38 |-+->| 39 |->...->| 56 |->| 57 |--'
    |  '----'  '----'       '----'    '----'       '----'  '----'
    V
   DOUT

Galois style (example for CRC16, 0x8005)

    ,-------------------+-------------------------+----------(+)<-- DIN (MSB first)
    |                   |                         |           ^
    |  .----.  .----.   V   .----.       .----.   V   .----.  |
    `->|  0 |->|  1 |->(+)->|  2 |->...->| 14 |->(+)->| 15 |--+---> DOUT
       '----'  '----'       '----'       '----'       '----'

REVERSE

Bit-reverse LFSR output.  Shifts MSB first by default, set REVERSE for LSB first.

INVERT

Bitwise invert PRBS output.

DATA_W

Specify width of output data bus.

Settings for common LFSR/CRC implementations:

Name        Configuration           Length  Polynomial      Initial value   Notes
CRC32       Galois, bit-reverse     32      32'h04c11db7    32'hffffffff    Ethernet FCS; invert final output
PRBS6       Fibonacci               6       6'h21           any
PRBS7       Fibonacci               7       7'h41           any
PRBS9       Fibonacci               9       9'h021          any             ITU V.52
PRBS10      Fibonacci               10      10'h081         any             ITU
PRBS11      Fibonacci               11      11'h201         any             ITU O.152
PRBS15      Fibonacci, inverted     15      15'h4001        any             ITU O.152
PRBS17      Fibonacci               17      17'h04001       any
PRBS20      Fibonacci               20      20'h00009       any             ITU V.57
PRBS23      Fibonacci, inverted     23      23'h040001      any             ITU O.151
PRBS29      Fibonacci, inverted     29      29'h08000001    any
PRBS31      Fibonacci, inverted     31      31'h10000001    any
64b66b      Fibonacci, bit-reverse  58      58'h8000000001  any             10G Ethernet
128b130b    Galois, bit-reverse     23      23'h210125      any             PCIe gen 3

*/

logic [LFSR_W-1:0] state_reg = LFSR_INIT;

wire [DATA_W-1:0] lfsr_data;
wire [LFSR_W-1:0] lfsr_state;

assign data_out = INVERT ? ~lfsr_data : lfsr_data;

taxi_lfsr #(
    .LFSR_W(LFSR_W),
    .LFSR_POLY(LFSR_POLY),
    .LFSR_GALOIS(LFSR_GALOIS),
    .LFSR_FEED_FORWARD('0),
    .REVERSE(REVERSE),
    .DATA_W(DATA_W),
    .DATA_IN_EN(1'b0),
    .DATA_OUT_EN(1'b1),
    .STATE_SHIFT_PRE(0),
    .STATE_SHIFT_POST(0)
)
lfsr_inst (
    .data_in('0),
    .state_in(state_reg),
    .data_out(lfsr_data),
    .state_out(lfsr_state)
);

always_ff @(posedge clk) begin
    if (enable) begin
        state_reg <= lfsr_state;
    end

    if (rst) begin
        state_reg <= LFSR_INIT;
    end
end

endmodule

`resetall
