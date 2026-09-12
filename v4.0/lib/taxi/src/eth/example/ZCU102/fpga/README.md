# Taxi Example Design for ZCU102

## Introduction

This example design targets the Xilinx ZCU102 FPGA board.

The design places looped-back MACs on the SFP+ ports, as well as XFCP on the USB UART for monitoring and control.

*  USB UART
    *  XFCP (2 Mbaud)
    *  Looped-back UART
*  QSFP28
    *  Looped-back 10GBASE-R MACs via GTH transceivers

## Board details

*  FPGA: xczu9eg-ffvb1156-2-e
*  USB UART: Silicon Labs CP2108
*  10GBASE-R PHY: Soft PCS with GTH transceivers

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
