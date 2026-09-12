# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VC709
# part: xc7vx690tffg1761-2

# SFP+ Interfaces
# NOTE: modules 0 and 1 swapped relative to schematic net names to match board layout
set_property -dict {LOC AN2 } [get_ports {sfp_tx_p[0]}] ;# MGTHTXP2_113 GTHE2_CHANNEL_X1Y13 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AN1 } [get_ports {sfp_tx_n[0]}] ;# MGTHTXN2_113 GTHE2_CHANNEL_X1Y13 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AM8 } [get_ports {sfp_rx_p[0]}] ;# MGTHRXP2_113 GTHE2_CHANNEL_X1Y13 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AM7 } [get_ports {sfp_rx_n[0]}] ;# MGTHRXN2_113 GTHE2_CHANNEL_X1Y13 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AP4 } [get_ports {sfp_tx_p[1]}] ;# MGTHTXP3_113 GTHE2_CHANNEL_X1Y12 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AP3 } [get_ports {sfp_tx_n[1]}] ;# MGTHTXN3_113 GTHE2_CHANNEL_X1Y12 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AN6 } [get_ports {sfp_rx_p[1]}] ;# MGTHRXP3_113 GTHE2_CHANNEL_X1Y12 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AN5 } [get_ports {sfp_rx_n[1]}] ;# MGTHRXN3_113 GTHE2_CHANNEL_X1Y12 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AM4 } [get_ports {sfp_tx_p[2]}] ;# MGTHTXP1_113 GTHE2_CHANNEL_X1Y14 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AM3 } [get_ports {sfp_tx_n[2]}] ;# MGTHTXN1_113 GTHE2_CHANNEL_X1Y14 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AL6 } [get_ports {sfp_rx_p[2]}] ;# MGTHRXP1_113 GTHE2_CHANNEL_X1Y14 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AL5 } [get_ports {sfp_rx_n[2]}] ;# MGTHRXN1_113 GTHE2_CHANNEL_X1Y14 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AL2 } [get_ports {sfp_tx_p[3]}] ;# MGTHTXP0_113 GTHE2_CHANNEL_X1Y15 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AL1 } [get_ports {sfp_tx_n[3]}] ;# MGTHTXN0_113 GTHE2_CHANNEL_X1Y15 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AJ6 } [get_ports {sfp_rx_p[3]}] ;# MGTHRXP0_113 GTHE2_CHANNEL_X1Y15 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AJ5 } [get_ports {sfp_rx_n[3]}] ;# MGTHRXN0_113 GTHE2_CHANNEL_X1Y15 / GTHE2_COMMON_X1Y3
set_property -dict {LOC AH8 } [get_ports sfp_mgt_refclk_p] ;# MGTREFCLK0P_113 from U24.28
set_property -dict {LOC AH7 } [get_ports sfp_mgt_refclk_n] ;# MGTREFCLK0N_113 from U24.29
# set_property -dict {LOC AK8 } [get_ports sma_mgt_refclk_p] ;# MGTREFCLK1P_113 from J25
# set_property -dict {LOC AK7 } [get_ports sma_mgt_refclk_n] ;# MGTREFCLK1N_113 from J26
#set_property -dict {LOC AW32 IOSTANDARD LVDS} [get_ports sfp_recclk_p] ;# to IC20.16
#set_property -dict {LOC AW33 IOSTANDARD LVDS} [get_ports sfp_recclk_n] ;# to IC20.17

set_property -dict {LOC AT36 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports si5324_rst]
set_property -dict {LOC AU34 IOSTANDARD LVCMOS18 PULLUP true} [get_ports si5324_int]

set_property -dict {LOC AA42 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_detect[0]}]
set_property -dict {LOC AB42 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_detect[1]}]
set_property -dict {LOC AC39 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_detect[2]}]
set_property -dict {LOC AC41 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_detect[3]}]
set_property -dict {LOC AB38 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[0][0]}]
set_property -dict {LOC AB39 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[0][1]}]
set_property -dict {LOC W40  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[1][0]}]
set_property -dict {LOC Y40  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[1][1]}]
set_property -dict {LOC AD42 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[2][0]}]
set_property -dict {LOC AE42 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[2][1]}]
set_property -dict {LOC AE39 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[3][0]}]
set_property -dict {LOC AE40 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[3][1]}]
set_property -dict {LOC AA40 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_los[0]}]
set_property -dict {LOC Y39  IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_los[1]}]
set_property -dict {LOC AD38 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_los[2]}]
set_property -dict {LOC AD40 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_los[3]}]
set_property -dict {LOC Y42  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[0]}]
set_property -dict {LOC AB41 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[1]}]
set_property -dict {LOC AC38 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[2]}]
set_property -dict {LOC AC40 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[3]}]
set_property -dict {LOC AA39 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_tx_fault[0]}]
set_property -dict {LOC Y38  IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_tx_fault[1]}]
set_property -dict {LOC AA41 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_tx_fault[2]}]
set_property -dict {LOC AE38 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_tx_fault[3]}]

# 156.25 MHz MGT reference clock
create_clock -period 6.4 -name sfp_mgt_refclk [get_ports sfp_mgt_refclk_p]

# 156.25 MHz MGT reference clock
#create_clock -period 6.4 -name sma_mgt_refclk [get_ports sma_mgt_refclk_p]

set_false_path -to [get_ports {si5324_rst}]
set_output_delay 0 [get_ports {si5324_rst}]
set_false_path -from [get_ports {si5324_int}]
set_input_delay 0 [get_ports {si5324_int}]

set_false_path -from [get_ports {sfp_mod_detect[*] sfp_los[*] sfp_tx_fault[*]}]
set_input_delay 0 [get_ports {sfp_mod_detect[*] sfp_los[*] sfp_tx_fault[*]}]
set_false_path -to [get_ports {sfp_rs[*][*] sfp_tx_disable[*]}]
set_output_delay 0 [get_ports {sfp_rs[*][*] sfp_tx_disable[*]}]
