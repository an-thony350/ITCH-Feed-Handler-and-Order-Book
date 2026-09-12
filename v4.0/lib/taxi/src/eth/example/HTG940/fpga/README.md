# Taxi Example Design for HTG-940

## Introduction

This example design targets the HiTech Global HTG-940 FPGA board.

The design places a looped-back MAC on the BASE-T port, as well as XFCP on the USB UART for monitoring and control.

*  USB UART
    *  XFCP (921600 baud)
*  RJ-45 Ethernet ports with TI DP83867IRPAP PHY
    *  Looped-back MAC via RGMII

## Board details

*  FPGA: xcvu9p-flgb2104-2-e
*  USB UART: Silicon Labs CP2103
*  1000BASE-T PHY: TI DP83867IRPAP via RGMII

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
