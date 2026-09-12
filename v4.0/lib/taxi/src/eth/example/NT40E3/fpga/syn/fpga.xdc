# SPDX-License-Identifier: MIT
#
# Copyright (c) 2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Napatech NT40E3
# part: xc7vx330tffg1157-2

# General configuration
set_property CFGBVS GND                                [current_design]
set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
# set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE    [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DIV-1  [current_design]
# set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES       [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4           [current_design]
# set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES        [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP         [current_design]

# 80 MHz EMC clock
set_property -dict {LOC AP33 IOSTANDARD LVCMOS18} [get_ports clk_80mhz]
create_clock -period 12.5 -name clk_80mhz [get_ports clk_80mhz]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_80mhz_ibufg]

# 233.33 MHz DDR3 MIG clock
#set_property -dict {LOC J30 IOSTANDARD LVDS} [get_ports clk_ddr_233mhz_p]
#set_property -dict {LOC J31 IOSTANDARD LVDS} [get_ports clk_ddr_233mhz_n]
#create_clock -period 4.285 -name clk_ddr_233mhz [get_ports clk_ddr_233mhz_p]
