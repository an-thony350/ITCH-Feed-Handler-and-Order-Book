# Taxi Example Design for KC705

## Introduction

This example design targets the Xilinx KC705 FPGA board.

The design places looped-back MACs on both the BASE-T port and the SFP+ cage, as well as XFCP on the USB UART for monitoring and control.

*  USB UART
    *  XFCP (921600 baud)
*  RJ-45 Ethernet port with Marvell 88E1111 PHY
    *  Looped-back MAC via GMII
    *  Looped-back MAC via RGMII
    *  Looped-back MAC via SGMII via Xilinx PCS/PMA core and GTX transceiver
*  SFP+ cage
    *  Looped-back 1000BASE-X via Xilinx PCS/PMA core and GTX transceiver

## Board details

*  FPGA: XC7K325T-2FFG900C
*  USB UART: Silicon Labs CP2103
*  1000BASE-T PHY: Marvell 88E1111 via GMII, RGMII, or SGMII
*  1000BASE-X PHY: Xilinx PCS/PMA core via GTX transceiver

## Licensing

*  Toolchain
    *  Vivado Enterprise (requires license)
*  IP
    *  No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## Board configuration

Several jumpers must be configured to configure the PHY chip for the appropriate mode.

| Mode     | J29  | J30  | J64  |
| -------- | ---- | ---- | ---- |
| GMII/MII | 1-2  | 1-2  | open |
| RGMII    | 1-2  | open | 1-2  |
| SGMII    | 2-3  | 2-3  | open |

Also, note that version 1.0 of the KC705 has the SFP+ TX and RX connections polarity-inverted.  Version 1.1 has this fixed.  This setting is controlled via a top-level parameter setting that is configurable via config.tcl, so ensure to use a design matching the board revision.

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
