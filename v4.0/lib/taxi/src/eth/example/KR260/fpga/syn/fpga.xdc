# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx KR260 board
# part: xck26-sfvc784-2LV-c

# General configuration
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]

# System clocks
# 25 MHz system clock
set_property -dict {LOC C3   IOSTANDARD LVCMOS18} [get_ports clk_25mhz] ;# HPA_CLK0_P som240_1_a6
create_clock -period 40.000 -name clk_25mhz [get_ports clk_25mhz]

# 25 MHz system clock
#set_property -dict {LOC L3 IOSTANDARD LVCMOS18} [get_ports clk_25mhz] ;# HPB_CLK0_P som240_2_d18
#create_clock -period 40.000 -name clk_25mhz [get_ports clk_25mhz]
