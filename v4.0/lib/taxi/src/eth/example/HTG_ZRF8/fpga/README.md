# Taxi Example Design for HTG-ZRF8

## Introduction

This example design targets the HiTech Global HTG-ZRF8-R2 and HTG-ZRF8-EM FPGA boards.

The design places looped-back MACs on the FMC+ for use with SFP and QSFP FMC adapters, as well as XFCP on the USB UART for monitoring and control.  The RF data converters are also enabled at 1 Gsps per channel.

*  USB UART
    *  XFCP (921600 baud)
*  QSFP28
    *  Looped-back 10GBASE-R or 25GBASE-R MACs via GTY transceivers

## Board details

*  FPGA: xczu48dr-ffvg1517-2-e
*  USB UART: Silicon Labs CP2103

## Licensing

*  Toolchain
    *  Vivado Enterprise (requires license)
*  IP
    *  No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## FMC

All variants of the HTG-ZRF8 only connect 8 MGT lanes to the FMC+, DP0-7, so on some FMC/FMC+ boards, not all of the connectors will be usable.

Another complicating factor is that the FMC+ connector has GA0/GA1 wired to ground, which causes an address conflict between the FMC EEPROM and any SFP/QSFP modules that can be connected to the FMC I2C pins.  Fixing the address conflict necessitates modification of either the FPGA board or the FMC board.

Additionally, the HTG-ZRF8-EM only connects LA0-LA9, which can cause some problems with driving module control lines on FMC/FMC+.  In some cases, alternative approaches might be required to use a given FMC/FMC+, including module configuration via I2C as well as modifications to the FMC/FMC+ board.

This design has been tested with:

*  HTG-FMC-QSFP28-DEG90
    *  QSFP on DP0-3, DP4-7 not connected
    *  resetl: on disconnected pin LA31_P, pulled high via R10 (OK)
    *  lpmode: on disconnected pin LA32_N, pulled high via R3 (no good on -EM)
    *  modsell: on disconnected pin LA31_N, pulled low via R8 (OK)

Since the Si5341 PLL is directly connected to the MGTREFCLK pins for the sites connected to the FMC+, no reference clocks are required from the FMC+ and as such any reference PLL on the FMC does not need to be configured and any oscillators can be disabled.

## Board configuration (HTG-ZRF8-R2)

For correct operation, several DIP switches need to be set correctly.  Additionally, some other component-level modifications may be required.

DIP switch settings:

*  S2.1-4: all ON for JTAG boot
*  S3.1: OFF (enable U19 outputs)
*  S3.2: don't care (U19 IN_SEL1)
*  S3.4: don't care (ON to disable PS ref clock)

The PLL configuration in this design ignores the IN_SEL pins, so S3.2 has no effect.  The other DIP switches do not affect the operation of this design.  A simple "safe" configuration is S3 all OFF and S2 all ON.

When using optical modules or active optical cables, it is necessary to pull the lpmode pins low and the resetl pins high to enable the lasers.  For I2C communication with the module, modsell must be pulled low.

Additionally, the standard SFP/QSFP I2C address of 0x50 conflicts with the address 0 FMC EEPROM address.  The FMC address pins (GA0 and GA1) are controlled by R430/R411 and R441/R451.  See the table below for how to configure these resistors.

| Address | R430 | R411 | R441 | R451 |
| ------- | ---- | ---- | ---- | ---- |
| 0       | 0    | DNP  | 0    | DNP  |
| 1       | DNP  | 4.7K | 0    | DNP  |
| 2       | 0    | DNP  | DNP  | 4.7K |
| 3       | DNP  | 4.7K | DNP  | 4.7K |

## Board configuration (HTG-ZRF8-EM)

For correct operation, several DIP switches need to be set correctly.  Additionally, some other component-level modifications may be required.

DIP switch settings:

*  S2.1: OFF (enable U48 outputs)
*  S2.3: don't care (U48 IN_SEL0)
*  S2.2: don't care (U48 IN_SEL1)
*  S2.4: don't care (ON to disable PS ref clock)
*  S3.1-4: all ON for JTAG boot

The PLL configuration in this design ignores the IN_SEL pins, so S2.2 and S2.3 have no effect.  The other DIP switches do not affect the operation of this design.  A simple "safe" configuration is S2 all OFF and S3 all ON.

When using optical modules or active optical cables, it is necessary to pull the lpmode pins low and the resetl pins high to enable the lasers.  For I2C communication with the module, modsell must be pulled low.  On the HTG-ZRF8-EM, only the first 20 LA pins (pairs LA0-LA9) are connected on the FMC+, so for some adapters, the lpmode and reset pins may not be connected to the FPGA.

Additionally, the standard SFP/QSFP I2C address of 0x50 conflicts with the address 0 FMC EEPROM address.  The FMC address pins (GA0 and GA1) are controlled by R471/R472 and R478/R479.  See the table below for how to configure these resistors.

| Address | R471 | R472 | R478 | R479 |
| ------- | ---- | ---- | ---- | ---- |
| 0       | 0    | DNP  | 0    | DNP  |
| 1       | DNP  | 4.7K | 0    | DNP  |
| 2       | 0    | DNP  | DNP  | 4.7K |
| 3       | DNP  | 4.7K | DNP  | 4.7K |

## How to test

Run `make program` to program the board with Vivado.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
