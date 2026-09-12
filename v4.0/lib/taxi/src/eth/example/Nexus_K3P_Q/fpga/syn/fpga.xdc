# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Cisco Nexus K3P-Q / ExaNIC X100
# part: xcku3p-ffvb676-2-e

# General configuration
set_property CFGBVS GND                                      [current_design]
set_property CONFIG_VOLTAGE 1.8                              [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true                 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup               [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 72.9                [current_design]
set_property CONFIG_MODE SPIx4                               [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4                 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE Yes              [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable        [current_design]

# 10 MHz TXCO
#set_property -dict {LOC E13  IOSTANDARD LVCMOS33} [get_ports clk_10mhz]
#create_clock -period 100.000 -name clk_10mhz [get_ports clk_10mhz]

# E13 cannot directly drive MMCM, so need to set CLOCK_DEDICATED_ROUTE to satisfy DRC
#set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets clk_10mhz_bufg]
