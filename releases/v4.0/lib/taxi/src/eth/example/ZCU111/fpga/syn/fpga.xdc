# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU111 board
# part: xczu28dr-ffvg1517-2-e

# General configuration
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]

# System clocks
# 125 MHz
set_property -dict {LOC AL17 IOSTANDARD LVDS} [get_ports clk_125mhz_p]
set_property -dict {LOC AM17 IOSTANDARD LVDS} [get_ports clk_125mhz_n]
create_clock -period 8.000 -name clk_125mhz [get_ports clk_125mhz_p]

# 100 MHz
#set_property -dict {LOC AM15 IOSTANDARD LVDS} [get_ports clk_100mhz_p]
#set_property -dict {LOC AN15 IOSTANDARD LVDS} [get_ports clk_100mhz_n]
#create_clock -period 10.000 -name clk_100mhz [get_ports clk_100mhz_p]
