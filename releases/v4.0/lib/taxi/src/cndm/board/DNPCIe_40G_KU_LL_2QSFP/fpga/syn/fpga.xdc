# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the DNPCIe_40G_KU_LL_2QSFP
# part: xcku040-ffva1156-2-e
# part: xcku060-ffva1156-2-e

# General configuration
set_property CFGBVS GND                                [current_design]
set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup         [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50            [current_design]
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE Type2      [current_design]
set_property CONFIG_MODE BPI16                         [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable  [current_design]

# 200 MHz DDR4 clock (Si598 FCA000126G) (Y6)
set_property -dict {LOC AH18 IOSTANDARD LVDS} [get_ports clk_ddr4_p] ;# from Y6.4
set_property -dict {LOC AH17 IOSTANDARD LVDS} [get_ports clk_ddr4_n] ;# from Y6.5
create_clock -period 5.000 -name clk_ddr4 [get_ports clk_ddr4_p]

#set_property -dict {LOC AG12 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12 PULLUP true} [get_ports clk_ddr4_i2c_scl]
#set_property -dict {LOC AH12 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12 PULLUP true} [get_ports clk_ddr4_i2c_sda]
