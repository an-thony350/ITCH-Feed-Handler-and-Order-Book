# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx AC701 board
# part: xc7a200tfbg676-2

# General configuration
set_property CFGBVS VCCO                      [current_design]
set_property CONFIG_VOLTAGE 3.3               [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true  [current_design]

# System clocks
# 200 MHz system clock
set_property -dict {LOC R3  IOSTANDARD LVDS_25} [get_ports clk_200mhz_p] ;# from SiT9102 U51.4
set_property -dict {LOC P3  IOSTANDARD LVDS_25} [get_ports clk_200mhz_n] ;# from SiT9102 U51.5
create_clock -period 5.000 -name clk_200mhz [get_ports clk_200mhz_p]

# Si570 user clock (156.25 MHz default)
#set_property -dict {LOC M21  IOSTANDARD LVDS_25} [get_ports clk_user_p] ;# from Si570 U34.4
#set_property -dict {LOC M22  IOSTANDARD LVDS_25} [get_ports clk_user_n] ;# from Si570 U34.5
#create_clock -period 6.400 -name clk_user [get_ports clk_user_p]

# User SMA clock
#set_property -dict {LOC J23 IOSTANDARD LVDS_25} [get_ports clk_user_sma_p] ;# from J31
#set_property -dict {LOC H23 IOSTANDARD LVDS_25} [get_ports clk_user_sma_n] ;# from J32
#create_clock -period 10.000 -name clk_user_sma [get_ports clk_user_sma_p]

# User SMA GPIO J33/J34
#set_property -dict {LOC T8  IOSTANDARD LVDS_25} [get_ports user_sma_gpio_p] ;# J33
#set_property -dict {LOC T7  IOSTANDARD LVDS_25} [get_ports user_sma_gpio_n] ;# J34
