# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U45N/SN1022 board
# part: xcux35-vsva1365-3-e

# General configuration
set_property CFGBVS GND                                [current_design]
set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE           [current_design]
set_property CONFIG_MODE SPIx4                         [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4           [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 72.9          [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES        [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP         [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES       [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable  [current_design]

set_operating_conditions -design_power_budget 60

# System clocks
# 300 MHz
#set_property -dict {LOC AK23 IOSTANDARD LVDS} [get_ports clk_300mhz_p]
#set_property -dict {LOC AL23 IOSTANDARD LVDS} [get_ports clk_300mhz_n]
#create_clock -period 3.333 -name clk_300mhz [get_ports clk_300mhz_p]
