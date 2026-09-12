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
 * LFSR CRC generator
 */
module taxi_lfsr_crc #
(
    // width of LFSR
    parameter LFSR_W = 32,
    // LFSR polynomial
    parameter logic [LFSR_W-1:0] LFSR_POLY = 32'h04c11db7,
    // Initial state
    parameter logic [LFSR_W-1:0] LFSR_INIT = '1,
    // LFSR configuration: 0 for Fibonacci (PRBS), 1 for Galois (CRC)
    parameter logic LFSR_GALOIS = 1'b1,
    // bit-reverse input and output
    parameter logic REVERSE = 1'b1,
    // invert output
    parameter logic INVERT = 1'b1,
    // width of data input and output
    parameter DATA_W = 8
)
(
    input  wire logic               clk,
    input  wire logic               rst,

    input  wire logic [DATA_W-1:0]  data_in,
    input  wire logic               data_in_valid,
    output wire logic [LFSR_W-1:0]  crc_out
);

/*

Fully parametrizable combinatorial parallel LFSR CRC module.  Implements an unrolled LFSR
next state computation.

Ports:

clk

Clock input

rst

Reset module, set state to LFSR_INIT

data_in

CRC data input

data_in_valid

Shift input data through CRC when asserted

data_out

LFSR output (OUTPUT_W bits)

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

Bit-reverse LFSR input and output.  Shifts MSB first by default, set REVERSE for LSB first.

INVERT

Bitwise invert CRC output.

DATA_W

Specify width of input data bus.  The module will perform one shift per input data bit,
so if the input data bus is not required tie data_in to zero and set DATA_W to the
required number of shifts per clock cycle.

Settings for common LFSR/CRC implementations:

Name        Configuration           Length  Polynomial      Initial value   Notes
CRC16-IBM   Galois, bit-reverse     16      16'h8005        16'hffff
CRC16-CCITT Galois                  16      16'h1021        16'h1d0f
CRC32       Galois, bit-reverse     32      32'h04c11db7    32'hffffffff    Ethernet FCS; invert final output
CRC32C      Galois, bit-reverse     32      32'h1edc6f41    32'hffffffff    iSCSI, Intel CRC32 instruction; invert final output

*/

logic [LFSR_W-1:0] state_reg = LFSR_INIT;

wire [LFSR_W-1:0] lfsr_state;

assign crc_out = INVERT ? ~state_reg : state_reg;

taxi_lfsr #(
    .LFSR_W(LFSR_W),
    .LFSR_POLY(LFSR_POLY),
    .LFSR_GALOIS(LFSR_GALOIS),
    .LFSR_FEED_FORWARD('0),
    .REVERSE(REVERSE),
    .DATA_W(DATA_W),
    .DATA_IN_EN(1'b1),
    .DATA_OUT_EN(1'b0),
    .STATE_SHIFT_PRE(0),
    .STATE_SHIFT_POST(0)
)
lfsr_inst (
    .data_in(data_in),
    .state_in(state_reg),
    .data_out(),
    .state_out(lfsr_state)
);

always_ff @(posedge clk) begin
    if (data_in_valid) begin
        state_reg <= lfsr_state;
    end

    if (rst) begin
        state_reg <= LFSR_INIT;
    end
end

endmodule

`resetall
