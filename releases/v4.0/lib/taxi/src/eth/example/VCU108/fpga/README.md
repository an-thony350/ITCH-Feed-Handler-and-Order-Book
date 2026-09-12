# Taxi Example Design for VCU108

## Introduction

This example design targets the Xilinx VCU108 FPGA board.

The design places looped-back MACs on the BASE-T and QSFP28 ports, as well as XFCP on the USB UART for monitoring and control.

*  USB UART
    *  XFCP (921600 baud)
*  RJ-45 Ethernet port with Marvell 88E1111 PHY
    *  Looped-back MAC via SGMII via Xilinx PCS/PMA core and LVDS IOSERDES
*  QSFP28
    *  Looped-back 10GBASE-R or 25GBASE-R MACs via GTY transceivers

## Board details

*  FPGA: xcvu095-ffva2104-2-e
*  USB UART: Silicon Labs CP2105 SCI
*  1000BASE-T PHY: Marvell 88E1111 via SGMII
*  25GBASE-R PHY: Soft PCS with GTY transceivers

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
