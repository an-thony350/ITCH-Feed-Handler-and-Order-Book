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

# 200 MHz RLD3 clock (Si598 FCA000126G) (Y3)
set_property -dict {LOC D23  IOSTANDARD LVDS} [get_ports clk_rld3_p] ;# from Y3.4
set_property -dict {LOC C23  IOSTANDARD LVDS} [get_ports clk_rld3_n] ;# from Y3.5
create_clock -period 5.000 -name clk_rld3 [get_ports clk_rld3_p]

#set_property -dict {LOC AG10 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12 PULLUP true} [get_ports clk_rld3_i2c_scl]
#set_property -dict {LOC AF9  IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12 PULLUP true} [get_ports clk_rld3_i2c_sda]
