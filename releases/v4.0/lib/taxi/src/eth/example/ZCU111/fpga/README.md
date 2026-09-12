# Taxi Example Design for ZCU111

## Introduction

This example design targets the Xilinx ZCU111 FPGA board.

The design places looped-back MACs on the SFP+ ports, as well as XFCP on the USB UART for monitoring and control.  The RF data converters are also enabled at 1 Gsps per channel.

*  USB UART
    *  XFCP (3 Mbaud)
*  QSFP28
    *  Looped-back 10GBASE-R or 25GBASE-R MACs via GTY transceivers

## Board details

*  FPGA: xczu28dr-ffvg1517-2-e
*  USB UART: FTDI FT4232H
*  25GBASE-R PHY: Soft PCS with GTY transceivers

## Licensing

*  Toolchain
    *  Vivado Enterprise (requires license)
*  IP
    *  No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## Board configuration

For correct operation, several DIP switches need to be set correctly.

DIP switch settings:

*  SW6: all ON (select JTAG boot)

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
