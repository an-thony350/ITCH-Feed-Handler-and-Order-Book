# Taxi Example Design for fb2CG@KU15P

## Introduction

This example design targets the Silicom fb2CG@KU15P FPGA board.

The design places looped-back MACs on the QSFP28 ports.

* QSFP28
  * Looped-back 10GBASE-R or 25GBASE-R MACs via GTY transceivers

## Board details

* FPGA: xcku15p-ffve1760-2-e
* 25GBASE-R PHY: Soft PCS with GTY transceivers

## Licensing

* Toolchain
  *  Vivado Enterprise (requires license)
* IP
  *  No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
