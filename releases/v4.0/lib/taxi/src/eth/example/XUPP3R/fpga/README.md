# Taxi Example Design for XUP-P3R/XUSP3S

## Introduction

This example design targets the BittWare XUP-P3R/XUSP3S FPGA board.

The design places looped-back MACs on the QSFP28 ports, as well as XFCP on the USB UART for monitoring and control.

* USB UART
  * XFCP (3 Mbaud)
* QSFP28
  * Looped-back 10GBASE-R or 25GBASE-R MACs via GTY transceivers

## Board details

* FPGA: xcvu9p-flga2104-2L-e
  * XUP-P3R: xcvu9p-flgb2104-2-e
  * XUSP3S: xcvu095-ffvb2104-2-e
* USB UART: FTDI FT232R
* 25GBASE-R PHY: Soft PCS with GTY transceivers

## Licensing

* Toolchain
  * Vivado Enterprise (requires license)
* IP
  * No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
