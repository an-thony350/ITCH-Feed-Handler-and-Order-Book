# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the BittWare XUSP3S board
# part: xcvu095-ffvb2104-2-e

# General configuration
set_property CFGBVS VCCO                               [current_design]
set_property CONFIG_VOLTAGE 3.3                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 90            [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES       [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4           [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES        [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP         [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable  [current_design]

# System clocks
# 48 MHz system clock
set_property -dict {LOC AV23 IOSTANDARD LVCMOS33} [get_ports clk_48mhz]
create_clock -period 20.833 -name clk_48mhz [get_ports clk_48mhz]

# 322.265625 MHz clock from Si5338 B ch 1
#set_property -dict {LOC AY23 IOSTANDARD LVPECL} [get_ports clk_b1_p]
#set_property -dict {LOC BA23 IOSTANDARD LVPECL} [get_ports clk_b1_n]
#create_clock -period 3.103 -name clk_b1 [get_ports clk_b1_p]

# 322.265625 MHz clock from Si5338 B ch 2
#set_property -dict {LOC BB9  IOSTANDARD DIFF_SSTL15_DCI ODT RTT_48} [get_ports clk_b2_p]
#set_property -dict {LOC BC9  IOSTANDARD DIFF_SSTL15_DCI ODT RTT_48} [get_ports clk_b2_n]
#create_clock -period 3.103 -name clk_b2 [get_ports clk_b2_p]
