# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U55C/Alveo U55N/Varium C1100 board
# U55C       part: xcu55c-fsvh2892-2L-e
# U55N/C1100 part: xcu55n-fsvh2892-2L-e

# QSFP28 Interfaces
set_property -dict {LOC AD51} [get_ports {qsfp0_rx_p[0]}] ;# MGTYRXP0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AD52} [get_ports {qsfp0_rx_n[0]}] ;# MGTYRXN0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AD46} [get_ports {qsfp0_tx_p[0]}] ;# MGTYTXP0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AD47} [get_ports {qsfp0_tx_n[0]}] ;# MGTYTXN0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AC53} [get_ports {qsfp0_rx_p[1]}] ;# MGTYRXP1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AC54} [get_ports {qsfp0_rx_n[1]}] ;# MGTYRXN1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AC44} [get_ports {qsfp0_tx_p[1]}] ;# MGTYTXP1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AC45} [get_ports {qsfp0_tx_n[1]}] ;# MGTYTXN1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AC49} [get_ports {qsfp0_rx_p[2]}] ;# MGTYRXP2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AC50} [get_ports {qsfp0_rx_n[2]}] ;# MGTYRXN2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AB46} [get_ports {qsfp0_tx_p[2]}] ;# MGTYTXP2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AB47} [get_ports {qsfp0_tx_n[2]}] ;# MGTYTXN2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AB51} [get_ports {qsfp0_rx_p[3]}] ;# MGTYRXP3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AB52} [get_ports {qsfp0_rx_n[3]}] ;# MGTYRXN3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AA48} [get_ports {qsfp0_tx_p[3]}] ;# MGTYTXP3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AA49} [get_ports {qsfp0_tx_n[3]}] ;# MGTYTXN3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AD42} [get_ports {qsfp0_mgt_refclk_p}] ;# MGTREFCLK0P_130 from SI5394 OUT0
set_property -dict {LOC AD43} [get_ports {qsfp0_mgt_refclk_n}] ;# MGTREFCLK0N_130 from SI5394 OUT0

# 161.1328125 MHz MGT reference clock (SI5394 OUT0)
create_clock -period 6.206 -name qsfp0_mgt_refclk [get_ports {qsfp0_mgt_refclk_p}]

set_property -dict {LOC AA53} [get_ports {qsfp1_rx_p[0]}] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AA54} [get_ports {qsfp1_rx_n[0]}] ;# MGTYRXN0_131 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AA44} [get_ports {qsfp1_tx_p[0]}] ;# MGTYTXP0_131 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AA45} [get_ports {qsfp1_tx_n[0]}] ;# MGTYTXN0_131 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC Y51 } [get_ports {qsfp1_rx_p[1]}] ;# MGTYRXP1_131 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC Y52 } [get_ports {qsfp1_rx_n[1]}] ;# MGTYRXN1_131 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC Y46 } [get_ports {qsfp1_tx_p[1]}] ;# MGTYTXP1_131 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC Y47 } [get_ports {qsfp1_tx_n[1]}] ;# MGTYTXN1_131 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC W53 } [get_ports {qsfp1_rx_p[2]}] ;# MGTYRXP2_131 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC W54 } [get_ports {qsfp1_rx_n[2]}] ;# MGTYRXN2_131 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC W48 } [get_ports {qsfp1_tx_p[2]}] ;# MGTYTXP2_131 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC W49 } [get_ports {qsfp1_tx_n[2]}] ;# MGTYTXN2_131 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC V51 } [get_ports {qsfp1_rx_p[3]}] ;# MGTYRXP3_131 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC V52 } [get_ports {qsfp1_rx_n[3]}] ;# MGTYRXN3_131 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC W44 } [get_ports {qsfp1_tx_p[3]}] ;# MGTYTXP3_131 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC W45 } [get_ports {qsfp1_tx_n[3]}] ;# MGTYTXN3_131 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC AB42} [get_ports {qsfp1_mgt_refclk_p}] ;# MGTREFCLK0P_131 from SI5394 OUT1
set_property -dict {LOC AB43} [get_ports {qsfp1_mgt_refclk_n}] ;# MGTREFCLK0N_131 from SI5394 OUT1

# 161.1328125 MHz MGT reference clock (SI5394 OUT1)
create_clock -period 6.206 -name qsfp1_mgt_refclk [get_ports {qsfp1_mgt_refclk_p}]
