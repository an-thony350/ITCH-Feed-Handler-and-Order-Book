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

# 200 MHz system clock (U51)
set_property -dict {LOC H19  IOSTANDARD DIFF_SSTL15_DCI} [get_ports clk_200mhz_p]
set_property -dict {LOC G18  IOSTANDARD DIFF_SSTL15_DCI} [get_ports clk_200mhz_n]
create_clock -period 5.0 -name clk_200mhz [get_ports clk_200mhz_p]

# User clock (U34)
#set_property -dict {LOC AL34 IOSTANDARD LVDS} [get_ports clk_user_p]
#set_property -dict {LOC AK34 IOSTANDARD LVDS} [get_ports clk_user_n]
#create_clock -period 6.4 -name clk_user [get_ports clk_user_p]

# User SMA clock (J31/J32)
#set_property -dict {LOC AJ32 IOSTANDARD LVDS} [get_ports clk_sma_p]
#set_property -dict {LOC AK32 IOSTANDARD LVDS} [get_ports clk_sma_n]
#create_clock -period 6.4 -name clk_sma [get_ports clk_sma_p]

# 233.33 MHz DDR3 MIG clock (U13)
#set_property -dict {LOC AY17 IOSTANDARD DIFF_SSTL15_DCI} [get_ports clk_233mhz_p]
#set_property -dict {LOC AY18 IOSTANDARD DIFF_SSTL15_DCI} [get_ports clk_233mhz_n]
#create_clock -period 4.285 -name clk_233mhz [get_ports clk_233mhz_p]

# EMC clock (U40)
#set_property -dict {LOC AP37 IOSTANDARD LVCMOS18} [get_ports emcclk]
#create_clock -period 1.25 -name emcclk [get_ports emcclk]
