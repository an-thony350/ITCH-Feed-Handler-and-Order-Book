# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U280 board
# part: xcu280-fsvh2892-2L-e

# General configuration
set_property CFGBVS GND                                [current_design]
set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE    [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE           [current_design]
set_property CONFIG_MODE SPIx4                         [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4           [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 85.0          [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES        [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP         [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES       [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable  [current_design]

set_operating_conditions -design_power_budget 160

# System clocks
# 100 MHz
#set_property -dict {LOC G31 IOSTANDARD LVDS} [get_ports clk_100mhz_2_p]
#set_property -dict {LOC F31 IOSTANDARD LVDS} [get_ports clk_100mhz_2_n]
#create_clock -period 10.000 -name clk_100mhz_2 [get_ports clk_100mhz_2_p]

# SI570 user clock
#set_property -dict {LOC G30 IOSTANDARD LVDS} [get_ports clk_si570_p]
#set_property -dict {LOC F30 IOSTANDARD LVDS} [get_ports clk_si570_n]
#create_clock -period 6.4 -name clk_si570 [get_ports clk_si570_p]
