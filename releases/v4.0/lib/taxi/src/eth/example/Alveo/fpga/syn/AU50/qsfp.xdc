# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U50 board
# part: xcu50-fsvh2104-2-e

# QSFP28 Interfaces
set_property -dict {LOC J45 } [get_ports {qsfp_rx_p[0]}] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC J46 } [get_ports {qsfp_rx_n[0]}] ;# MGTYRXN0_131 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC D42 } [get_ports {qsfp_tx_p[0]}] ;# MGTYTXP0_131 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC D43 } [get_ports {qsfp_tx_n[0]}] ;# MGTYTXN0_131 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC G45 } [get_ports {qsfp_rx_p[1]}] ;# MGTYRXP1_131 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC G46 } [get_ports {qsfp_rx_n[1]}] ;# MGTYRXN1_131 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC C40 } [get_ports {qsfp_tx_p[1]}] ;# MGTYTXP1_131 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC C41 } [get_ports {qsfp_tx_n[1]}] ;# MGTYTXN1_131 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC F43 } [get_ports {qsfp_rx_p[2]}] ;# MGTYRXP2_131 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC F44 } [get_ports {qsfp_rx_n[2]}] ;# MGTYRXN2_131 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC B42 } [get_ports {qsfp_tx_p[2]}] ;# MGTYTXP2_131 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC B43 } [get_ports {qsfp_tx_n[2]}] ;# MGTYTXN2_131 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC E45 } [get_ports {qsfp_rx_p[3]}] ;# MGTYRXP3_131 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC E46 } [get_ports {qsfp_rx_n[3]}] ;# MGTYRXN3_131 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC A40 } [get_ports {qsfp_tx_p[3]}] ;# MGTYTXP3_131 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC A41 } [get_ports {qsfp_tx_n[3]}] ;# MGTYTXN3_131 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC N36 } [get_ports {qsfp_mgt_refclk_0_p}] ;# MGTREFCLK0P_131 from SI5394 OUT0
set_property -dict {LOC N37 } [get_ports {qsfp_mgt_refclk_0_n}] ;# MGTREFCLK0N_131 from SI5394 OUT0
#set_property -dict {LOC M38 } [get_ports {qsfp_mgt_refclk_1_p}] ;# MGTREFCLK1P_131 from SI5394 OUT2
#set_property -dict {LOC M39 } [get_ports {qsfp_mgt_refclk_1_n}] ;# MGTREFCLK1N_131 from SI5394 OUT2
#set_property -dict {LOC F19 IOSTANDARD LVDS} [get_ports {qsfp_recclk_p}] ;# to SI5394 IN0
#set_property -dict {LOC F18 IOSTANDARD LVDS} [get_ports {qsfp_recclk_n}] ;# to SI5394 IN0

# 161.1328125 MHz MGT reference clock (SI5394 OUT0)
create_clock -period 6.206 -name qsfp_mgt_refclk_0 [get_ports {qsfp_mgt_refclk_0_p}]

# 322.265625 MHz MGT reference clock (SI5394 OUT2)
#create_clock -period 3.103 -name qsfp_mgt_refclk_1 [get_ports {qsfp_mgt_refclk_1_p}]
