# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U45N/SN1022 board
# part: xcux35-vsva1365-3-e

# DSFP Interfaces
set_property -dict {LOC K4} [get_ports {dsfp1_rx_p[0]}] ;# MGTYRXP0_231 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC K3} [get_ports {dsfp1_rx_n[0]}] ;# MGTYRXN0_231 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC J7} [get_ports {dsfp1_tx_p[0]}] ;# MGTYTXP0_231 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC J6} [get_ports {dsfp1_tx_n[0]}] ;# MGTYTXN0_231 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7
set_property -dict {LOC J2} [get_ports {dsfp1_rx_p[1]}] ;# MGTYRXP1_231 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC J1} [get_ports {dsfp1_rx_n[1]}] ;# MGTYRXN1_231 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC H5} [get_ports {dsfp1_tx_p[1]}] ;# MGTYTXP1_231 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7
set_property -dict {LOC H4} [get_ports {dsfp1_tx_n[1]}] ;# MGTYTXN1_231 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7

set_property -dict {LOC G2} [get_ports {dsfp0_rx_p[0]}] ;# MGTYRXP2_231 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC G1} [get_ports {dsfp0_rx_n[0]}] ;# MGTYRXN2_231 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC G7} [get_ports {dsfp0_tx_p[0]}] ;# MGTYTXP2_231 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC G6} [get_ports {dsfp0_tx_n[0]}] ;# MGTYTXN2_231 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7
set_property -dict {LOC E2} [get_ports {dsfp0_rx_p[1]}] ;# MGTYRXP3_231 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC E1} [get_ports {dsfp0_rx_n[1]}] ;# MGTYRXN3_231 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC F5} [get_ports {dsfp0_tx_p[1]}] ;# MGTYTXP3_231 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7
set_property -dict {LOC F4} [get_ports {dsfp0_tx_n[1]}] ;# MGTYTXN3_231 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7

set_property -dict {LOC P9} [get_ports {dsfp_mgt_refclk_p}] ;# MGTREFCLK0P_231 from SI5394 OUT1 via U16
set_property -dict {LOC P8} [get_ports {dsfp_mgt_refclk_n}] ;# MGTREFCLK0N_231 from SI5394 OUT1 via U16

# 161.1328125 MHz MGT reference clock (SI5394 OUT1 via U16)
create_clock -period 6.206 -name dsfp_mgt_refclk [get_ports {dsfp_mgt_refclk_p}]
