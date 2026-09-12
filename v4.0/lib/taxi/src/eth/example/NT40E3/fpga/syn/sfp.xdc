# SPDX-License-Identifier: MIT
#
# Copyright (c) 2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Napatech NT40E3
# part: xc7vx330tffg1157-2

# SFP+ Interfaces (J1-J4)
set_property -dict {LOC B6  } [get_ports {sfp_rx_p[0]}] ;# MGTHRXP3_118 GTHE2_CHANNEL_X1Y39 / GTHE2_COMMON_X1Y9
set_property -dict {LOC B5  } [get_ports {sfp_rx_n[0]}] ;# MGTHRXN3_118 GTHE2_CHANNEL_X1Y39 / GTHE2_COMMON_X1Y9
set_property -dict {LOC A4  } [get_ports {sfp_tx_p[0]}] ;# MGTHTXP3_118 GTHE2_CHANNEL_X1Y39 / GTHE2_COMMON_X1Y9
set_property -dict {LOC A3  } [get_ports {sfp_tx_n[0]}] ;# MGTHTXN3_118 GTHE2_CHANNEL_X1Y39 / GTHE2_COMMON_X1Y9
set_property -dict {LOC D6  } [get_ports {sfp_rx_p[1]}] ;# MGTHRXP2_118 GTHE2_CHANNEL_X1Y38 / GTHE2_COMMON_X1Y9
set_property -dict {LOC D5  } [get_ports {sfp_rx_n[1]}] ;# MGTHRXN2_118 GTHE2_CHANNEL_X1Y38 / GTHE2_COMMON_X1Y9
set_property -dict {LOC B2  } [get_ports {sfp_tx_p[1]}] ;# MGTHTXP2_118 GTHE2_CHANNEL_X1Y38 / GTHE2_COMMON_X1Y9
set_property -dict {LOC B1  } [get_ports {sfp_tx_n[1]}] ;# MGTHTXN2_118 GTHE2_CHANNEL_X1Y38 / GTHE2_COMMON_X1Y9
set_property -dict {LOC H6  } [get_ports {sfp_mgt_refclk_p[0]}] ;# MGTREFCLK1P_118 from U20.10
set_property -dict {LOC H5  } [get_ports {sfp_mgt_refclk_n[0]}] ;# MGTREFCLK1N_118 from U20.9
set_property -dict {LOC W4  } [get_ports {sfp_rx_p[2]}] ;# MGTHRXP1_116 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC W3  } [get_ports {sfp_rx_n[2]}] ;# MGTHRXN1_116 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC V2  } [get_ports {sfp_tx_p[2]}] ;# MGTHTXP1_116 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC V1  } [get_ports {sfp_tx_n[2]}] ;# MGTHTXN1_116 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC AA4 } [get_ports {sfp_rx_p[3]}] ;# MGTHRXP0_116 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC AA3 } [get_ports {sfp_rx_n[3]}] ;# MGTHRXN0_116 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC Y2  } [get_ports {sfp_tx_p[3]}] ;# MGTHTXP0_116 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC Y1  } [get_ports {sfp_tx_n[3]}] ;# MGTHTXN0_116 GTHE2_CHANNEL_X1Y37 / GTHE2_COMMON_X1Y9
set_property -dict {LOC T6  } [get_ports {sfp_mgt_refclk_p[1]}] ;# MGTREFCLK0P_116 from U20.20
set_property -dict {LOC T5  } [get_ports {sfp_mgt_refclk_n[1]}] ;# MGTREFCLK0N_116 from U20.21
set_property -dict {LOC AG12 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_abs[0]}]
set_property -dict {LOC AJ11 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_abs[1]}]
set_property -dict {LOC AK9  IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_abs[2]}]
set_property -dict {LOC AN10 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {sfp_mod_abs[3]}]
set_property -dict {LOC AF10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[0][0]}]
set_property -dict {LOC AG10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[0][1]}]
set_property -dict {LOC AJ12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[1][0]}]
set_property -dict {LOC AK12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[1][1]}]
set_property -dict {LOC AL11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[2][0]}]
set_property -dict {LOC AM11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[2][1]}]
set_property -dict {LOC AP12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[3][0]}]
set_property -dict {LOC AP11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_rs[3][1]}]
set_property -dict {LOC AH10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[0]}]
set_property -dict {LOC AK8  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[1]}]
set_property -dict {LOC AM12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[2]}]
set_property -dict {LOC AM13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable[3]}]
# set_property -dict {LOC AF9  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports {sfp_i2c_scl[0]}]
# set_property -dict {LOC AD9  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports {sfp_i2c_sda[0]}]
# set_property -dict {LOC AD12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports {sfp_i2c_scl[1]}]
# set_property -dict {LOC AF8  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports {sfp_i2c_sda[1]}]
# set_property -dict {LOC AF11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports {sfp_i2c_scl[2]}]
# set_property -dict {LOC AD11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports {sfp_i2c_sda[2]}]
# set_property -dict {LOC AG8  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports {sfp_i2c_scl[3]}]
# set_property -dict {LOC AG11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports {sfp_i2c_sda[3]}]

# 156.25 MHz MGT reference clock
create_clock -period 6.4 -name {sfp_mgt_refclk_0} [get_ports {sfp_mgt_refclk_p[0]}]
create_clock -period 6.4 -name {sfp_mgt_refclk_1} [get_ports {sfp_mgt_refclk_p[1]}]

set_false_path -from [get_ports {sfp_mod_abs[*]}]
set_input_delay 0 [get_ports {sfp_mod_abs[*]}]
set_false_path -to [get_ports {sfp_rs[*][*]}]
set_output_delay 0 [get_ports {sfp_rs[*][*]}]
set_false_path -to [get_ports {get_ports sfp_tx_disable[*]}]
set_output_delay 0 [get_ports {get_ports sfp_tx_disable[*]}]
# set_false_path -to [get_ports {sfp_i2c_scl[*] sfp_i2c_sda[*]}]
# set_output_delay 0 [get_ports {sfp_i2c_scl[*] sfp_i2c_sda[*]}]
# set_false_path -from [get_ports {sfp_i2c_scl[*] sfp_i2c_sda[*]}]
# set_input_delay 0 [get_ports {sfp_i2c_scl[*] sfp_i2c_sda[*]}]
