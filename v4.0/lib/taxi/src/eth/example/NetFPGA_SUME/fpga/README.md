# Taxi Example Design for NetFPGA SUME

## Introduction

This example design targets the Digilent NetFPGA SUME FPGA board.

The design places looped-back MACs on the SFP+ cages, as well as XFCP on the USB UART for monitoring and control.

*  USB UART
    *  XFCP (3 Mbaud)
*  SFP+ cages
    *  Looped-back 10GBASE-R MACs via GTH transceivers

## Board details

*  FPGA: XC7VX690T-3FFG1761
*  USB UART: FTDI FT2232HQ

## Licensing

*  Toolchain
    *  Vivado Enterprise (requires license)
*  IP
    *  No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
