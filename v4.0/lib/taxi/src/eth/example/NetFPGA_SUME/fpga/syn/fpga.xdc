# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VC709
# part: xc7vx690tffg1761-2

# General configuration
set_property CFGBVS GND                                [current_design]
set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup         [current_design]

# 200 MHz system clock
set_property -dict {LOC H19  IOSTANDARD LVDS} [get_ports clk_200mhz_p]
set_property -dict {LOC G18  IOSTANDARD LVDS} [get_ports clk_200mhz_n]
create_clock -period 5 -name clk_200mhz [get_ports clk_200mhz_p]

# 200 MHz QDRII A/B MIG clock
#set_property -dict {LOC AD32 IOSTANDARD LVDS} [get_ports clk_qdrii_200mhz_p]
#set_property -dict {LOC AD33 IOSTANDARD LVDS} [get_ports clk_qdrii_200mhz_n]
#create_clock -period 5 -name clk_qdrii_200mhz [get_ports clk_qdrii_200mhz_p]

# 200 MHz QDRII C MIG clock
#set_property -dict {LOC AU14 IOSTANDARD LVDS} [get_ports clk_qdriic_200mhz_p]
#set_property -dict {LOC AU13 IOSTANDARD LVDS} [get_ports clk_qdriic_200mhz_n]
#create_clock -period 5 -name clk_qdriic_200mhz [get_ports clk_qdriic_200mhz_p]

# 233.33 MHz DDR3 MIG clock
#set_property -dict {LOC E34  IOSTANDARD LVDS} [get_ports clk_ddr_233mhz_p]
#set_property -dict {LOC E35  IOSTANDARD LVDS} [get_ports clk_ddr_233mhz_n]
#create_clock -period 4.286 -name clk_ddr_233mhz [get_ports clk_ddr_233mhz_p]
