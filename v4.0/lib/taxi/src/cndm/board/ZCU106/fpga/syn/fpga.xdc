# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU106 board
# part: xczu7ev-ffvc1156-2-e

# General configuration
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]

# System clocks
# 125 MHz
set_property -dict {LOC H9   IOSTANDARD LVDS} [get_ports clk_125mhz_p]
set_property -dict {LOC G9   IOSTANDARD LVDS} [get_ports clk_125mhz_n]
create_clock -period 8.000 -name clk_125mhz [get_ports clk_125mhz_p]

# 74.25 MHz
#set_property -dict {LOC D15  IOSTANDARD LVDS} [get_ports clk_74mhz_p]
#set_property -dict {LOC D14  IOSTANDARD LVDS} [get_ports clk_74mhz_n]
#create_clock -period 13.468 -name clk_74mhz [get_ports clk_74mhz_p]

# User Si570 (default 300 MHz)
#set_property -dict {LOC AH12 IOSTANDARD DIFF_SSTL12} [get_ports clk_user_si570_p]
#set_property -dict {LOC AJ12 IOSTANDARD DIFF_SSTL12} [get_ports clk_user_si570_n]
#create_clock -period 3.333 -name clk_user_si570 [get_ports clk_user_si570_p]
