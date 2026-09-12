# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VCU108 board
# part: xcvu095-ffva2104-2-e

# QSFP28 Interface
set_property -dict {LOC AG45} [get_ports {qsfp_rx_p[0]}] ;# MGTYRXP0_127 GTYE3_CHANNEL_X0Y12 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AG46} [get_ports {qsfp_rx_n[0]}] ;# MGTYRXN0_127 GTYE3_CHANNEL_X0Y12 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AK42} [get_ports {qsfp_tx_p[0]}] ;# MGTYTXP0_127 GTYE3_CHANNEL_X0Y12 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AK43} [get_ports {qsfp_tx_n[0]}] ;# MGTYTXN0_127 GTYE3_CHANNEL_X0Y12 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AF43} [get_ports {qsfp_rx_p[1]}] ;# MGTYRXP1_127 GTYE3_CHANNEL_X0Y13 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AF44} [get_ports {qsfp_rx_n[1]}] ;# MGTYRXN1_127 GTYE3_CHANNEL_X0Y13 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AJ40} [get_ports {qsfp_tx_p[1]}] ;# MGTYTXP1_127 GTYE3_CHANNEL_X0Y13 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AJ41} [get_ports {qsfp_tx_n[1]}] ;# MGTYTXN1_127 GTYE3_CHANNEL_X0Y13 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AE45} [get_ports {qsfp_rx_p[2]}] ;# MGTYRXP2_127 GTYE3_CHANNEL_X0Y14 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AE46} [get_ports {qsfp_rx_n[2]}] ;# MGTYRXN2_127 GTYE3_CHANNEL_X0Y14 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AG40} [get_ports {qsfp_tx_p[2]}] ;# MGTYTXP2_127 GTYE3_CHANNEL_X0Y14 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AG41} [get_ports {qsfp_tx_n[2]}] ;# MGTYTXN2_127 GTYE3_CHANNEL_X0Y14 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AD43} [get_ports {qsfp_rx_p[3]}] ;# MGTYRXP3_127 GTYE3_CHANNEL_X0Y15 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AD44} [get_ports {qsfp_rx_n[3]}] ;# MGTYRXN3_127 GTYE3_CHANNEL_X0Y15 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AE40} [get_ports {qsfp_tx_p[3]}] ;# MGTYTXP3_127 GTYE3_CHANNEL_X0Y15 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AE41} [get_ports {qsfp_tx_n[3]}] ;# MGTYTXN3_127 GTYE3_CHANNEL_X0Y15 / GTYE3_COMMON_X0Y3
set_property -dict {LOC AF38} [get_ports qsfp_mgt_refclk_0_p] ;# MGTREFCLK0P_127 from U32 SI570 via U102 SI53340
set_property -dict {LOC AF39} [get_ports qsfp_mgt_refclk_0_n] ;# MGTREFCLK0N_127 from U32 SI570 via U102 SI53340
#set_property -dict {LOC AD38} [get_ports qsfp_mgt_refclk_1_p] ;# MGTREFCLK1P_127 from U57 CKOUT2 SI5328
#set_property -dict {LOC AD39} [get_ports qsfp_mgt_refclk_1_n] ;# MGTREFCLK1N_127 from U57 CKOUT2 SI5328
#set_property -dict {LOC AG34 IOSTANDARD LVDS} [get_ports qsfp_recclk_p] ;# to U57 CKIN1 SI5328
#set_property -dict {LOC AH35 IOSTANDARD LVDS} [get_ports qsfp_recclk_n] ;# to U57 CKIN1 SI5328
set_property -dict {LOC AL24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp_modsell]
set_property -dict {LOC AM24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp_resetl]
set_property -dict {LOC AL25 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_modprsl]
set_property -dict {LOC AL21 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_intl]
set_property -dict {LOC AM21 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp_lpmode]

# 156.25 MHz MGT reference clock
create_clock -period 6.400 -name qsfp_mgt_refclk_0 [get_ports qsfp_mgt_refclk_0_p]

set_false_path -to [get_ports {qsfp_modsell qsfp_resetl qsfp_lpmode}]
set_output_delay 0 [get_ports {qsfp_modsell qsfp_resetl qsfp_lpmode}]
set_false_path -from [get_ports {qsfp_modprsl qsfp_intl}]
set_input_delay 0 [get_ports {qsfp_modprsl qsfp_intl}]
