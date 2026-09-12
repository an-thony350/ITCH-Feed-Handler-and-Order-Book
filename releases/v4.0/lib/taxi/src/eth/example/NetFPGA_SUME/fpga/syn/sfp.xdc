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
set_property -dict {LOC A6  } [get_ports {sfp_rx_p[0]}] ;# MGTHRXP3_119 GTHE2_CHANNEL_X1Y39 / GTHE2_COMMON_X1Y9
set_property -dict {LOC A5  } [get_ports {sfp_rx_n[0]}] ;# MGTHRXN3_119 GTHE2_CHANNEL_X1Y39 / GTHE2_COMMON_X1Y9
set_property -dict {LOC B4  } [get_ports {sfp_tx_p[0]}] ;# MGTHTXP3_119 GTHE2_CHANNEL_X1Y39 / GTHE2_COMMON_X1Y9
set_property -dict {LOC B3  } [get_ports {sfp_tx_n[0]}] ;# MGTHTXN3_119 GTHE2_CHANNEL_X1Y39 / GTHE2_COMMON_X1Y9
set_property -dict {LOC B8  } [get_ports {sfp_rx_p[1]}] ;# MGTHRXP2_119 GTHE2_CHANNEL_X1Y38 / GTHE2_COMMON_X1Y9
set_property -dict {LOC B7  } [get_ports {sfp_rx_n[1]}] ;# MGTHRXN2_119 GTHE2_CHANNEL_X1Y38 / GTHE2_COMMON_X1Y9
set_property -dict {LOC C2  } [get_ports {sfp_tx_p[1]}] ;# MGTHTXP2_119 GTHE2_CHANNEL_X1Y38 / GTHE2_COMMON_X1Y9
set_property -dict {LOC C1  } [get_ports {sfp_tx_n[1]}] ;# MGTHTXN2_119 GTHE2_CHANNEL_X1Y38 / GTHE2_COMMON_X1Y9
set_property -dict {LOC C6  } [get_ports {sfp_rx_p[2]}] ;# MGTHRXP1_119 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC C5  } [get_ports {sfp_rx_n[2]}] ;# MGTHRXN1_119 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC D4  } [get_ports {sfp_tx_p[2]}] ;# MGTHTXP1_119 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC D3  } [get_ports {sfp_tx_n[2]}] ;# MGTHTXN1_119 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC D8  } [get_ports {sfp_rx_p[3]}] ;# MGTHRXP0_119 GTHE2_CHANNEL_X1Y36 / GTHE2_COMMON_X1Y9
set_property -dict {LOC D7  } [get_ports {sfp_rx_n[3]}] ;# MGTHRXN0_119 GTHE2_CHANNEL_X1Y36 / GTHE2_COMMON_X1Y9
set_property -dict {LOC E2  } [get_ports {sfp_tx_p[3]}] ;# MGTHTXP0_119 GTHE2_CHANNEL_X1Y36 / GTHE2_COMMON_X1Y9
set_property -dict {LOC E1  } [get_ports {sfp_tx_n[3]}] ;# MGTHTXN0_119 GTHE2_CHANNEL_X1Y36 / GTHE2_COMMON_X1Y9
set_property -dict {LOC E10 } [get_ports sfp_mgt_refclk_p] ;# MGTREFCLK0P_118 from IC20.28
set_property -dict {LOC E9  } [get_ports sfp_mgt_refclk_n] ;# MGTREFCLK0N_118 from IC20.29
#set_property -dict {LOC AW32 IOSTANDARD LVDS} [get_ports sfp_recclk_p] ;# to IC20.16
#set_property -dict {LOC AW33 IOSTANDARD LVDS} [get_ports sfp_recclk_n] ;# to IC20.17

set_property -dict {LOC BA29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports si5324_rst]
set_property -dict {LOC AM29 IOSTANDARD LVCMOS18 PULLUP true} [get_ports si5324_int]

set_property -dict {LOC N18  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_mod_detect[0]}]
set_property -dict {LOC L19  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_mod_detect[1]}]
set_property -dict {LOC J37  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_mod_detect[2]}]
set_property -dict {LOC H36  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_mod_detect[3]}]
set_property -dict {LOC N19  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[0][0]}]
set_property -dict {LOC P18  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[0][1]}]
set_property -dict {LOC P20  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[1][0]}]
set_property -dict {LOC N20  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[1][1]}]
set_property -dict {LOC F39  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[2][0]}]
set_property -dict {LOC G36  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[2][1]}]
set_property -dict {LOC H38  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[3][0]}]
set_property -dict {LOC G38  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[3][1]}]
set_property -dict {LOC L17  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_los[0]}]
set_property -dict {LOC L20  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_los[1]}]
set_property -dict {LOC G37  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_los[2]}]
set_property -dict {LOC J36  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_los[3]}]
set_property -dict {LOC M18  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[0]}]
set_property -dict {LOC B31  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[1]}]
set_property -dict {LOC J38  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[2]}]
set_property -dict {LOC L21  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[3]}]
set_property -dict {LOC M19  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_tx_fault[0]}]
set_property -dict {LOC C26  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_tx_fault[1]}]
set_property -dict {LOC E39  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_tx_fault[2]}]
set_property -dict {LOC J26  IOSTANDARD LVCMOS15 PULLUP true} [get_ports {sfp_tx_fault[3]}]

# 156.25 MHz MGT reference clock
create_clock -period 6.4 -name sfp_mgt_refclk [get_ports sfp_mgt_refclk_p]

set_false_path -to [get_ports {si5324_rst}]
set_output_delay 0 [get_ports {si5324_rst}]
set_false_path -from [get_ports {si5324_int}]
set_input_delay 0 [get_ports {si5324_int}]

set_false_path -from [get_ports {sfp_mod_detect[*] sfp_los[*] sfp_tx_fault[*]}]
set_input_delay 0 [get_ports {sfp_mod_detect[*] sfp_los[*] sfp_tx_fault[*]}]
set_false_path -to [get_ports {sfp_rs[*][*] sfp_tx_disable[*]}]
set_output_delay 0 [get_ports {sfp_rs[*][*] sfp_tx_disable[*]}]
