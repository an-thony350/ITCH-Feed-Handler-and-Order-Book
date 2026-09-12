# Taxi Example Design for KR260

## Introduction

This example design targets the Xilinx KR260 FPGA board.

The design places looped-back MACs on the BASE-T ports and SFP+ cage.

*  RJ-45 Ethernet ports with TI DP83867CSRGZ PHY
    *  Looped-back MAC via RGMII
*  SFP+ cage
    *  Looped-back 1000BASE-X via Xilinx PCS/PMA core and GTH transceiver
    *  Looped-back 10GBASE-R MAC via GTH transceiver

## Board details

*  FPGA: xck26-sfvc784-2LV-c
*  1000BASE-T PHY: TI DP83867CSRGZ via RGMII
*  1000BASE-X PHY: Xilinx PCS/PMA core via GTH transceiver
*  10GBASE-R PHY: Soft PCS with GTH transceiver

## Licensing

*  Toolchain
    *  Vivado Standard (enterprise license not required)
*  IP
    *  No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back UART, use any serial terminal software like minicom, screen, etc.  The looped-back UART will echo typed text back without modification.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
