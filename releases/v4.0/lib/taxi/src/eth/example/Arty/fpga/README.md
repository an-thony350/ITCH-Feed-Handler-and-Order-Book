# Taxi Example Design for Arty A7

## Introduction

This example design targets the Digilent Arty A7 FPGA board.

The design places a looped-back MAC on the BASE-T port, as well as XFCP on the USB UART for monitoring and control.

*  USB UART
    *  XFCP (3 Mbaud)
*  RJ-45 Ethernet port with TI DP83848J PHY
    *  Looped-back MAC via MII

## Board details

*  FPGA: XC7A35TICSG324-1L
*  USB UART: FTDI FT2232H
*  PHY: TI DP83848J via MII

## Licensing

*  Toolchain
    *  Vivado Standard (enterprise license not required)
*  IP
    *  No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
