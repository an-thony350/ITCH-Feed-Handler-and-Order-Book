# Taxi Example Design for HTG-9200

## Introduction

This example design targets the HiTech Global HTG-9200 FPGA board.  Design variants are provided for both the bare HTG-9200, as well as the HTG-9200 with the HiTech Global HTG-FMC-X6QSFP28 FMC+ board installed on J9.

The design places looped-back MACs on the Ethernet ports, as well as XFCP on the USB UART for monitoring and control.

*  USB UART
    *  XFCP (921600 baud)
*  QSFP28
    *  Looped-back 10GBASE-R or 25GBASE-R MACs via GTY transceivers

## Board details

*  FPGA: xcvu9p-flgb2104-2-e
*  USB UART: Silicon Labs CP2103

## Licensing

*  Toolchain
    *  Vivado Enterprise (requires license)
*  IP
    *  No licensed vendor IP or 3rd party IP

## How to build

Run `make` in the appropriate `fpga*` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

## Board configuration

For correct operation, several DIP switches need to be set correctly.  Additionally, some other component-level modifications may be required.

DIP switch settings:

* S2.1: off (enable EMCCLK, if needed to boot from flash)
* S3.2: off (enable U24 ref_clk)
* S4.5: off (enable U47 osc_gty2)
* S4.8: on  (enable U48 outputs)

Note that S4.8 has no effect if R441 is not installed (which appears to be the default configuration) as U48 has an internal pull-down on OEb.  The PLL configuration in this design also ignores the IN_SEL pins, so S4.6 and S4.7 have no effect.  The other DIP switches do not affect the operation of this design.

When using optical modules or active optical cables, it is necessary to pull the lpmode pins low to enable the lasers.  On the HTG-9200, the lpmode pins are not connected to the FPGA, so it is necessary to pull the pins low on the board.  The board has footprints for pull-down resistors on the lpmode pins, which are not populated by default.   These are R414, R392, R336, R316, R276, R475, R471, R473, and R477 (respectively for QSFP1-9).  Shorting across these footprints or installing pull-down resistors of around 150 ohms will bring installed modules out of low power mode.

The HTG-9200 was originally designed for Virtex UltraScale, so by default some of the power supply voltages are too high for an UltraScale+ device.  In particular, the Avcc supplies for the GTY transceivers are set to 1.0 V, which is not only outside of the recommended range of 0.873-0.927 V but it also matches the absolute max of 1.0 V.  Additionally, Vccint and Vccbram are set to 0.95V, which is outside of the recommended range of 0.825-0.876 V for standard speed grades but below the absolute max of 1.0 V.  Checking the supply voltages and swapping out the feedback resistors on the Vccint, Vccbram and MGT Avcc power supplies is therefore highly recommended.  Note that the supplies labeled GTH feed the MGT banks on the right side of the device, which are GTH transceivers on UltraScale and GTY transceivers on UltraScale+.

The table below contains the power rail test points and feedback resistor values for the power supply rails in question for several different speed grades of Virtex UltraScale and UltraScale+ devices.

| Rail        | VCCINT       | VCCBRAM      | GTY_AVCC     | GTH_AVCC     |
| ----------- | ------------ | ------------ | ------------ | ------------ |
| Test point  | P6           | P8           | P9           | P1           |
| Regulator   | U4, U56      | U11          | U13          | U20          |
| Part        | 4/2 LTM4650  | LTM4625      | 4/4 LTM4644  | 4/4 LTM4644  |
| Current     | 100A         | 5A           | 16A          | 16A          |
| FB resistor | R354         | R494         | R38          | R61          |
| US -3, -1H  | 90.9K (1.0V) | 90.9K (1.0V) | 22.6K (1.0V) | 22.6K (1.0V) |
| US -2, -1   | 105K (0.95V) | 105K (0.95V) | 22.6K (1.0V) | 22.6K (1.0V) |
| US+ -3      | 121K (0.90V) | 121K (0.90V) | 30.1K (0.9V) | 30.1K (0.9V) |
| US+ -2, -1  | 147K (0.85V) | 147K (0.85V) | 30.1K (0.9V) | 30.1K (0.9V) |
| US+ -2L     | 301K (0.72V) | 147K (0.85V) | 30.1K (0.9V) | 30.1K (0.9V) |

## How to test

Run `make program` to program the board with Vivado.

LED D46 on the HTG-9200 indicates that the Si5341 PLL is locked and providing stable reference clocks to the transceivers.  On the HTG-FMC-X6QSFP28 FMC+ board, LED D10 indicates that the Si5341 PLL is locked.

To test the looped-back MAC, it is recommended to use a network tester like the Viavi T-BERD 5800 that supports basic layer 2 tests with a loopback.  Do not connect the looped-back MAC to a network as the reflected packets may cause problems.
