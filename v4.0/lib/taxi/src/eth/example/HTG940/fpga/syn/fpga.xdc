# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the HiTech Global HTG-9200 board
# part: xcvu9p-flgb2104-2-e
# part: xcvu13p-fhgb2104-2-e

# General configuration
set_property CFGBVS GND                                [current_design]
set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN {DIV-1} [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES       [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8           [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES        [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable  [current_design]

# System clocks
# DDR4 clocks from U37 (200 MHz)
#set_property -dict {LOC BA34 IOSTANDARD DIFF_SSTL12} [get_ports sys_clk_ddr4_a_p]
#set_property -dict {LOC BB34 IOSTANDARD DIFF_SSTL12} [get_ports sys_clk_ddr4_a_n]
#create_clock -period 5.000 -name sys_clk_ddr4_a [get_ports sys_clk_ddr4_a_p]

# refclk from U39 (156.25 MHz)
set_property -dict {LOC AW28 IOSTANDARD LVDS} [get_ports ref_clk_p]
set_property -dict {LOC AY28 IOSTANDARD LVDS} [get_ports ref_clk_n]
create_clock -period 6.400 -name ref_clk [get_ports ref_clk_p]
