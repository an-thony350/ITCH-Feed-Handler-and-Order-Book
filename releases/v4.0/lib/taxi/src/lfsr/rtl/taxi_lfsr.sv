// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2016-2026 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Parametrizable combinatorial parallel LFSR/CRC
 */
module taxi_lfsr #
(
    // width of LFSR
    parameter LFSR_W = 31,
    // LFSR polynomial
    parameter logic [LFSR_W-1:0] LFSR_POLY = 31'h10000001,
    // LFSR configuration: 0 for Fibonacci (PRBS), 1 for Galois (CRC)
    parameter logic LFSR_GALOIS = 1'b0,
    // LFSR feed forward enable
    parameter logic LFSR_FEED_FORWARD = 1'b0,
    // bit-reverse input and output
    parameter logic REVERSE = 1'b0,
    // width of data ports
    parameter DATA_W = 8,
    // enable data input and output
    parameter logic DATA_IN_EN = 1'b1,
    parameter logic DATA_OUT_EN = 1'b1,
    // shift control
    parameter STATE_SHIFT_PRE = 0,
    parameter STATE_SHIFT_POST = 0
)
(
    input  wire logic [DATA_W-1:0]  data_in,
    input  wire logic [LFSR_W-1:0]  state_in,
    output wire logic [DATA_W-1:0]  data_out,
    output wire logic [LFSR_W-1:0]  state_out
);

/*

Fully parametrizable combinatorial parallel LFSR/CRC module.  Implements an unrolled LFSR
next state computation, shifting DATA_W bits per pass through the module.  Input data
is XORed with LFSR feedback path, tie data_in to zero if this is not required.

Works in two parts: statically computes a set of bit masks, then uses these bit masks to
select bits for XORing to compute the next state.

Ports:

data_in

Data bits to be shifted through the LFSR (DATA_W bits)

state_in

LFSR/CRC current state input (LFSR_W bits)

data_out

Data bits shifted out of LFSR (DATA_W bits)

state_out

LFSR/CRC next state output (LFSR_W bits)

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

LFSR_FEED_FORWARD

Generate feed forward instead of feed back LFSR.  Enable this for PRBS checking and self-
synchronous descrambling.

Fibonacci feed-forward style (example for 64b66b descrambler, 0x8000000001)

   DIN (LSB first)
    |
    |  .----.  .----.       .----.    .----.       .----.  .----.
    +->|  0 |->|  1 |->...->| 38 |-+->| 39 |->...->| 56 |->| 57 |--.
    |  '----'  '----'       '----' |  '----'       '----'  '----'  |
    |                              V                               |
   (+)<---------------------------(+)------------------------------'
    |
    V
   DOUT

Galois feed-forward style

    ,-------------------+-------------------------+------------+--- DIN (MSB first)
    |                   |                         |            |
    |  .----.  .----.   V   .----.       .----.   V   .----.   V
    `->|  0 |->|  1 |->(+)->|  2 |->...->| 14 |->(+)->| 15 |->(+)-> DOUT
       '----'  '----'       '----'       '----'       '----'

REVERSE

Bit-reverse LFSR input and output.  Shifts MSB first by default, set REVERSE for LSB first.

DATA_W

Specify width of input and output data bus.  The module will perform one shift per input
data bit, so if the input data bus is not required tie data_in to zero and set DATA_W
to the required number of shifts per clock cycle.

DATA_IN_EN, DATA_OUT_EN

Enable data input and/or output ports.  Useful for CRC computation where the
data shifted out of the register is not used, or PRBS generation where no data
is shifted in to the register.  Disabling unused inputs and outputs will
increase simulation speed.

STATE_SHIFT_PRE, STATE_SHIFT_POST

Shift the state before/after shifting the data.  Useful for either shifting the
state only, or for performing a split CRC computation on a wide/segmented data
bus.  Positive shift values are equivalent to extending the data input port with
zeros.  Negative shift amounts shift the state backwards, useful for removing
zero padding and similar.

Settings for common LFSR/CRC implementations:

Name        Configuration           Length  Polynomial      Initial value   Notes
CRC16-IBM   Galois, bit-reverse     16      16'h8005        16'hffff
CRC16-CCITT Galois                  16      16'h1021        16'h1d0f
CRC32       Galois, bit-reverse     32      32'h04c11db7    32'hffffffff    Ethernet FCS; invert final output
CRC32C      Galois, bit-reverse     32      32'h1edc6f41    32'hffffffff    iSCSI, Intel CRC32 instruction; invert final output
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
pcie        Galois, bit-reverse     16      16'h0039        16'hffff        PCIe gen 1/2
128b130b    Galois, bit-reverse     23      23'h210125      any             PCIe gen 3

*/

localparam INPUT_DATA_IN_STATE = DATA_IN_EN && LFSR_GALOIS && !LFSR_FEED_FORWARD && DATA_W <= LFSR_W;
localparam INPUT_STATE_IN_DATA = DATA_IN_EN && LFSR_GALOIS && !LFSR_FEED_FORWARD && DATA_W > LFSR_W;
localparam OUTPUT_DATA_IN_STATE = DATA_OUT_EN && !LFSR_GALOIS && !LFSR_FEED_FORWARD && DATA_W <= LFSR_W;
localparam OUTPUT_STATE_IN_DATA = DATA_OUT_EN && !LFSR_GALOIS && !LFSR_FEED_FORWARD && DATA_W > LFSR_W;

localparam DATA_IN_INT = DATA_IN_EN && !INPUT_DATA_IN_STATE;
localparam DATA_OUT_INT = DATA_OUT_EN && !OUTPUT_DATA_IN_STATE;

localparam IN_W = INPUT_STATE_IN_DATA ? DATA_W : (LFSR_W+(DATA_IN_INT ? DATA_W : 0));
localparam OUT_W = OUTPUT_STATE_IN_DATA ? DATA_W : (LFSR_W+(DATA_OUT_INT ? DATA_W : 0));

function [OUT_W-1:0][IN_W-1:0] lfsr_mask();
    logic [LFSR_W-1:0] lfsr_mask_state[LFSR_W-1:0];
    logic [DATA_W-1:0] lfsr_mask_data[LFSR_W-1:0];
    logic [LFSR_W-1:0] output_mask_state[DATA_W-1:0];
    logic [DATA_W-1:0] output_mask_data[DATA_W-1:0];

    logic [LFSR_W-1:0] state_val;
    logic [DATA_W-1:0] data_val;

    logic [DATA_W-1:0] data_mask;

    // init bit masks
    for (integer i = 0; i < LFSR_W; i = i + 1) begin
        lfsr_mask_state[i] = '0;
        lfsr_mask_state[i][i] = 1'b1;
        lfsr_mask_data[i] = '0;
    end
    for (integer i = 0; i < DATA_W; i = i + 1) begin
        output_mask_state[i] = '0;
        output_mask_data[i] = '0;
    end

    // simulate shift register
    if (LFSR_GALOIS) begin
        // Galois configuration

        // Shift state alone before shifting data
        if (STATE_SHIFT_PRE > 0) begin
            // forward shift
            for (integer i = 0; i < STATE_SHIFT_PRE; i = i + 1) begin
                // determine shift in value
                // current value in last FF, XOR with input data bit (MSB first)
                state_val = lfsr_mask_state[LFSR_W-1];
                data_val = lfsr_mask_data[LFSR_W-1];

                // shift
                for (integer j = LFSR_W-1; j > 0; j = j - 1) begin
                    lfsr_mask_state[j] = lfsr_mask_state[j-1];
                    lfsr_mask_data[j] = lfsr_mask_data[j-1];
                end
                if (LFSR_FEED_FORWARD) begin
                    // only shift in new input data
                    state_val = '0;
                    data_val = '0;
                end
                lfsr_mask_state[0] = state_val;
                lfsr_mask_data[0] = data_val;

                // add XOR inputs at correct indicies
                for (integer j = 1; j < LFSR_W; j = j + 1) begin
                    if (LFSR_POLY[j]) begin
                        lfsr_mask_state[j] = lfsr_mask_state[j] ^ state_val;
                        lfsr_mask_data[j] = lfsr_mask_data[j] ^ data_val;
                    end
                end
            end
        end else if (STATE_SHIFT_PRE < 0) begin
            // reverse shift
            for (integer i = 0; i < -STATE_SHIFT_PRE; i = i + 1) begin
                state_val = lfsr_mask_state[0];
                data_val = lfsr_mask_data[0];

                // add XOR inputs at correct indicies
                for (integer j = 1; j < LFSR_W; j = j + 1) begin
                    if (LFSR_POLY[j]) begin
                        lfsr_mask_state[j] = lfsr_mask_state[j] ^ state_val;
                        lfsr_mask_data[j] = lfsr_mask_data[j] ^ data_val;
                    end
                end

                // shift
                for (integer j = 0; j < LFSR_W-1; j = j + 1) begin
                    lfsr_mask_state[j] = lfsr_mask_state[j+1];
                    lfsr_mask_data[j] = lfsr_mask_data[j+1];
                end
                if (LFSR_FEED_FORWARD) begin
                    // only shift in new input data
                    state_val = '0;
                    data_val = '0;
                end
                lfsr_mask_state[LFSR_W-1] = state_val;
                lfsr_mask_data[LFSR_W-1] = data_val;
            end
        end

        // Shift data
        if (DATA_IN_EN || DATA_OUT_EN) begin
            for (data_mask = {1'b1, {DATA_W-1{1'b0}}}; data_mask != 0; data_mask = data_mask >> 1) begin
                // determine shift in value
                // current value in last FF, XOR with input data bit (MSB first)
                state_val = lfsr_mask_state[LFSR_W-1];
                data_val = lfsr_mask_data[LFSR_W-1];
                data_val = data_val ^ data_mask;

                // shift
                for (integer j = LFSR_W-1; j > 0; j = j - 1) begin
                    lfsr_mask_state[j] = lfsr_mask_state[j-1];
                    lfsr_mask_data[j] = lfsr_mask_data[j-1];
                end
                for (integer j = DATA_W-1; j > 0; j = j - 1) begin
                    output_mask_state[j] = output_mask_state[j-1];
                    output_mask_data[j] = output_mask_data[j-1];
                end
                output_mask_state[0] = state_val;
                output_mask_data[0] = data_val;
                if (LFSR_FEED_FORWARD) begin
                    // only shift in new input data
                    state_val = '0;
                    data_val = data_mask;
                end
                lfsr_mask_state[0] = state_val;
                lfsr_mask_data[0] = data_val;

                // add XOR inputs at correct indicies
                for (integer j = 1; j < LFSR_W; j = j + 1) begin
                    if (LFSR_POLY[j]) begin
                        lfsr_mask_state[j] = lfsr_mask_state[j] ^ state_val;
                        lfsr_mask_data[j] = lfsr_mask_data[j] ^ data_val;
                    end
                end
            end
        end

        // Shift state alone after shifting data
        if (STATE_SHIFT_POST > 0) begin
            // forward shift
            for (integer i = 0; i < STATE_SHIFT_POST; i = i + 1) begin
                // determine shift in value
                // current value in last FF, XOR with input data bit (MSB first)
                state_val = lfsr_mask_state[LFSR_W-1];
                data_val = lfsr_mask_data[LFSR_W-1];

                // shift
                for (integer j = LFSR_W-1; j > 0; j = j - 1) begin
                    lfsr_mask_state[j] = lfsr_mask_state[j-1];
                    lfsr_mask_data[j] = lfsr_mask_data[j-1];
                end
                if (LFSR_FEED_FORWARD) begin
                    // only shift in new input data
                    state_val = '0;
                    data_val = '0;
                end
                lfsr_mask_state[0] = state_val;
                lfsr_mask_data[0] = data_val;

                // add XOR inputs at correct indicies
                for (integer j = 1; j < LFSR_W; j = j + 1) begin
                    if (LFSR_POLY[j]) begin
                        lfsr_mask_state[j] = lfsr_mask_state[j] ^ state_val;
                        lfsr_mask_data[j] = lfsr_mask_data[j] ^ data_val;
                    end
                end
            end
        end else if (STATE_SHIFT_POST < 0) begin
            // reverse shift
            for (integer i = 0; i < -STATE_SHIFT_POST; i = i + 1) begin
                state_val = lfsr_mask_state[0];
                data_val = lfsr_mask_data[0];

                // add XOR inputs at correct indicies
                for (integer j = 1; j < LFSR_W; j = j + 1) begin
                    if (LFSR_POLY[j]) begin
                        lfsr_mask_state[j] = lfsr_mask_state[j] ^ state_val;
                        lfsr_mask_data[j] = lfsr_mask_data[j] ^ data_val;
                    end
                end

                // shift
                for (integer j = 0; j < LFSR_W-1; j = j + 1) begin
                    lfsr_mask_state[j] = lfsr_mask_state[j+1];
                    lfsr_mask_data[j] = lfsr_mask_data[j+1];
                end
                if (LFSR_FEED_FORWARD) begin
                    // only shift in new input data
                    state_val = '0;
                    data_val = '0;
                end
                lfsr_mask_state[LFSR_W-1] = state_val;
                lfsr_mask_data[LFSR_W-1] = data_val;
            end
        end
    end else begin
        // Fibonacci configuration

        // Shift state alone before shifting data
        if (STATE_SHIFT_PRE > 0) begin
            // forward shift
            for (integer i = 0; i < STATE_SHIFT_PRE; i = i + 1) begin
                // determine shift in value
                // current value in last FF, XOR with input data bit (MSB first)
                state_val = lfsr_mask_state[LFSR_W-1];
                data_val = lfsr_mask_data[LFSR_W-1];

                // add XOR inputs from correct indicies
                for (integer j = 1; j < LFSR_W; j = j + 1) begin
                    if (LFSR_POLY[j]) begin
                        state_val = lfsr_mask_state[j-1] ^ state_val;
                        data_val = lfsr_mask_data[j-1] ^ data_val;
                    end
                end

                // shift
                for (integer j = LFSR_W-1; j > 0; j = j - 1) begin
                    lfsr_mask_state[j] = lfsr_mask_state[j-1];
                    lfsr_mask_data[j] = lfsr_mask_data[j-1];
                end
                if (LFSR_FEED_FORWARD) begin
                    // only shift in new input data
                    state_val = '0;
                    data_val = '0;
                end
                lfsr_mask_state[0] = state_val;
                lfsr_mask_data[0] = data_val;
            end
        end else if (STATE_SHIFT_PRE < 0) begin
            // reverse shift
            for (integer i = 0; i < -STATE_SHIFT_PRE; i = i + 1) begin
                state_val = lfsr_mask_state[0];
                data_val = lfsr_mask_data[0];

                // shift
                for (integer j = 0; j < LFSR_W-1; j = j + 1) begin
                    lfsr_mask_state[j] = lfsr_mask_state[j+1];
                    lfsr_mask_data[j] = lfsr_mask_data[j+1];
                end
                if (LFSR_FEED_FORWARD) begin
                    // only shift in new input data
                    state_val = '0;
                    data_val = '0;
                end
                lfsr_mask_state[LFSR_W-1] = state_val;
                lfsr_mask_data[LFSR_W-1] = data_val;

                // add XOR inputs from correct indicies
                for (integer j = 1; j < LFSR_W; j = j + 1) begin
                    if (LFSR_POLY[j]) begin
                        state_val = lfsr_mask_state[j-1] ^ state_val;
                        data_val = lfsr_mask_data[j-1] ^ data_val;
                    end
                end
            end
        end

        // Shift data
        if (DATA_IN_EN || DATA_OUT_EN) begin
            for (data_mask = {1'b1, {DATA_W-1{1'b0}}}; data_mask != 0; data_mask = data_mask >> 1) begin
                // determine shift in value
                // current value in last FF, XOR with input data bit (MSB first)
                state_val = lfsr_mask_state[LFSR_W-1];
                data_val = lfsr_mask_data[LFSR_W-1];
                data_val = data_val ^ data_mask;

                // add XOR inputs from correct indicies
                for (integer j = 1; j < LFSR_W; j = j + 1) begin
                    if (LFSR_POLY[j]) begin
                        state_val = lfsr_mask_state[j-1] ^ state_val;
                        data_val = lfsr_mask_data[j-1] ^ data_val;
                    end
                end

                // shift
                for (integer j = LFSR_W-1; j > 0; j = j - 1) begin
                    lfsr_mask_state[j] = lfsr_mask_state[j-1];
                    lfsr_mask_data[j] = lfsr_mask_data[j-1];
                end
                for (integer j = DATA_W-1; j > 0; j = j - 1) begin
                    output_mask_state[j] = output_mask_state[j-1];
                    output_mask_data[j] = output_mask_data[j-1];
                end
                output_mask_state[0] = state_val;
                output_mask_data[0] = data_val;
                if (LFSR_FEED_FORWARD) begin
                    // only shift in new input data
                    state_val = '0;
                    data_val = data_mask;
                end
                lfsr_mask_state[0] = state_val;
                lfsr_mask_data[0] = data_val;
            end
        end

        // Shift state alone after shifting data
        if (STATE_SHIFT_POST > 0) begin
            for (integer i = 0; i < STATE_SHIFT_POST; i = i + 1) begin
                // determine shift in value
                // current value in last FF, XOR with input data bit (MSB first)
                state_val = lfsr_mask_state[LFSR_W-1];
                data_val = lfsr_mask_data[LFSR_W-1];

                // add XOR inputs from correct indicies
                for (integer j = 1; j < LFSR_W; j = j + 1) begin
                    if (LFSR_POLY[j]) begin
                        state_val = lfsr_mask_state[j-1] ^ state_val;
                        data_val = lfsr_mask_data[j-1] ^ data_val;
                    end
                end

                // shift
                for (integer j = LFSR_W-1; j > 0; j = j - 1) begin
                    lfsr_mask_state[j] = lfsr_mask_state[j-1];
                    lfsr_mask_data[j] = lfsr_mask_data[j-1];
                end
                if (LFSR_FEED_FORWARD) begin
                    // only shift in new input data
                    state_val = '0;
                    data_val = '0;
                end
                lfsr_mask_state[0] = state_val;
                lfsr_mask_data[0] = data_val;
            end
        end else if (STATE_SHIFT_POST < 0) begin
            // reverse shift
            for (integer i = 0; i < -STATE_SHIFT_POST; i = i + 1) begin
                state_val = lfsr_mask_state[0];
                data_val = lfsr_mask_data[0];

                // shift
                for (integer j = 0; j < LFSR_W-1; j = j + 1) begin
                    lfsr_mask_state[j] = lfsr_mask_state[j+1];
                    lfsr_mask_data[j] = lfsr_mask_data[j+1];
                end
                if (LFSR_FEED_FORWARD) begin
                    // only shift in new input data
                    state_val = '0;
                    data_val = '0;
                end
                lfsr_mask_state[LFSR_W-1] = state_val;
                lfsr_mask_data[LFSR_W-1] = data_val;

                // add XOR inputs from correct indicies
                for (integer j = 1; j < LFSR_W; j = j + 1) begin
                    if (LFSR_POLY[j]) begin
                        state_val = lfsr_mask_state[j-1] ^ state_val;
                        data_val = lfsr_mask_data[j-1] ^ data_val;
                    end
                end
            end
        end
    end

    // disable broken linter
    /* verilator lint_off WIDTH */
    if (REVERSE) begin
        // output reversed
        if (OUTPUT_STATE_IN_DATA) begin
            for (integer i = 0; i < DATA_W; i = i + 1) begin
                if (INPUT_STATE_IN_DATA) begin
                    for (integer j = 0; j < DATA_W; j = j + 1) begin
                        lfsr_mask[i][j] = output_mask_data[DATA_W-i-1][DATA_W-j-1];
                    end
                end else begin
                    for (integer j = 0; j < LFSR_W; j = j + 1) begin
                        lfsr_mask[i][j] = output_mask_state[DATA_W-i-1][LFSR_W-j-1];
                    end
                    if (DATA_IN_INT) begin
                        for (integer j = 0; j < DATA_W; j = j + 1) begin
                            lfsr_mask[i][j+LFSR_W] = output_mask_data[DATA_W-i-1][DATA_W-j-1];
                        end
                    end
                end
            end
        end else begin
            for (integer i = 0; i < LFSR_W; i = i + 1) begin
                if (INPUT_STATE_IN_DATA) begin
                    for (integer j = 0; j < DATA_W; j = j + 1) begin
                        lfsr_mask[i][j] = lfsr_mask_data[LFSR_W-i-1][DATA_W-j-1];
                    end
                end else begin
                    for (integer j = 0; j < LFSR_W; j = j + 1) begin
                        lfsr_mask[i][j] = lfsr_mask_state[LFSR_W-i-1][LFSR_W-j-1];
                    end
                    if (DATA_IN_INT) begin
                        for (integer j = 0; j < DATA_W; j = j + 1) begin
                            lfsr_mask[i][j+LFSR_W] = lfsr_mask_data[LFSR_W-i-1][DATA_W-j-1];
                        end
                    end
                end
            end
            if (DATA_OUT_INT) begin
                for (integer i = 0; i < DATA_W; i = i + 1) begin
                    if (INPUT_STATE_IN_DATA) begin
                        for (integer j = 0; j < DATA_W; j = j + 1) begin
                            lfsr_mask[i+LFSR_W][j] = output_mask_data[DATA_W-i-1][DATA_W-j-1];
                        end
                    end else begin
                        for (integer j = 0; j < LFSR_W; j = j + 1) begin
                            lfsr_mask[i+LFSR_W][j] = output_mask_state[DATA_W-i-1][LFSR_W-j-1];
                        end
                        if (DATA_IN_INT) begin
                            for (integer j = 0; j < DATA_W; j = j + 1) begin
                                lfsr_mask[i+LFSR_W][j+LFSR_W] = output_mask_data[DATA_W-i-1][DATA_W-j-1];
                            end
                        end
                    end
                end
            end
        end
    end else begin
        // output normal
        if (OUTPUT_STATE_IN_DATA) begin
            for (integer i = 0; i < DATA_W; i = i + 1) begin
                if (INPUT_STATE_IN_DATA) begin
                    lfsr_mask[i] = output_mask_data[i];
                end else if (DATA_IN_INT) begin
                    lfsr_mask[i] = {output_mask_data[i], output_mask_state[i]};
                end else begin
                    lfsr_mask[i] = output_mask_state[i];
                end
            end

        end else begin
            for (integer i = 0; i < LFSR_W; i = i + 1) begin
                if (INPUT_STATE_IN_DATA) begin
                    lfsr_mask[i] = lfsr_mask_data[i];
                end else if (DATA_IN_INT) begin
                    lfsr_mask[i] = {lfsr_mask_data[i], lfsr_mask_state[i]};
                end else begin
                    lfsr_mask[i] = lfsr_mask_state[i];
                end
            end
            if (DATA_OUT_INT) begin
                for (integer i = 0; i < DATA_W; i = i + 1) begin
                    if (INPUT_STATE_IN_DATA) begin
                        lfsr_mask[i+LFSR_W] = output_mask_data[i];
                    end else if (DATA_IN_INT) begin
                        lfsr_mask[i+LFSR_W] = {output_mask_data[i], output_mask_state[i]};
                    end else begin
                        lfsr_mask[i+LFSR_W] = output_mask_state[i];
                    end
                end
            end
        end
    end
    /* verilator lint_on WIDTH */
endfunction

wire [OUT_W-1:0][IN_W-1:0] mask = lfsr_mask();

wire [IN_W-1:0] lfsr_in;
wire [OUT_W-1:0] lfsr_out;

if (DATA_IN_EN) begin
    if (INPUT_STATE_IN_DATA) begin
        if (DATA_W == LFSR_W) begin
            assign lfsr_in = data_in ^ state_in;
        end else begin
            if (REVERSE) begin
                assign lfsr_in = data_in ^ {{DATA_W - LFSR_W{1'b0}}, state_in};
            end else begin
                assign lfsr_in = data_in ^ {state_in, {DATA_W - LFSR_W{1'b0}}};
            end
        end
    end else if (INPUT_DATA_IN_STATE) begin
        if (REVERSE) begin
            assign lfsr_in = {{LFSR_W - DATA_W{1'b0}}, data_in} ^ state_in;
        end else begin
            assign lfsr_in = {data_in, {LFSR_W - DATA_W{1'b0}}} ^ state_in;
        end
    end else begin
        assign lfsr_in = {data_in, state_in};
    end
end else begin
    assign lfsr_in = state_in;
end

for (genvar n = 0; n < OUT_W; n = n + 1) begin
    assign lfsr_out[n] = ^(lfsr_in & mask[n]);
end

if (OUTPUT_DATA_IN_STATE) begin
    assign state_out = lfsr_out;
    assign data_out = REVERSE ? lfsr_out[OUT_W-1 -: DATA_W] : lfsr_out[0 +: DATA_W];
end else if (OUTPUT_STATE_IN_DATA) begin
    assign state_out = REVERSE ? lfsr_out[OUT_W-1 -: LFSR_W] : lfsr_out[0 +: LFSR_W];
    assign data_out = lfsr_out;
end else begin
    assign state_out = lfsr_out[0 +: LFSR_W];

    if (DATA_OUT_EN) begin
        assign data_out = lfsr_out[LFSR_W +: DATA_W];
    end else begin
        assign data_out = '0;
    end
end

endmodule

`resetall
