# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VCU108 board
# part: xcvu095-ffva2104-2-e

# Bullseye GTY
set_property -dict {LOC AR45} [get_ports {bullseye_rx_p[0]}] ;# MGTYRXP0_126 GTYE3_CHANNEL_X0Y8 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AR46} [get_ports {bullseye_rx_n[0]}] ;# MGTYRXN0_126 GTYE3_CHANNEL_X0Y8 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AT42} [get_ports {bullseye_tx_p[0]}] ;# MGTYTXP0_126 GTYE3_CHANNEL_X0Y8 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AT43} [get_ports {bullseye_tx_n[0]}] ;# MGTYTXN0_126 GTYE3_CHANNEL_X0Y8 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AN45} [get_ports {bullseye_rx_p[1]}] ;# MGTYRXP1_126 GTYE3_CHANNEL_X0Y9 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AN46} [get_ports {bullseye_rx_n[1]}] ;# MGTYRXN1_126 GTYE3_CHANNEL_X0Y9 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AP42} [get_ports {bullseye_tx_p[1]}] ;# MGTYTXP1_126 GTYE3_CHANNEL_X0Y9 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AP43} [get_ports {bullseye_tx_n[1]}] ;# MGTYTXN1_126 GTYE3_CHANNEL_X0Y9 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AL45} [get_ports {bullseye_rx_p[2]}] ;# MGTYRXP2_126 GTYE3_CHANNEL_X0Y10 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AL46} [get_ports {bullseye_rx_n[2]}] ;# MGTYRXN2_126 GTYE3_CHANNEL_X0Y10 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AM42} [get_ports {bullseye_tx_p[2]}] ;# MGTYTXP2_126 GTYE3_CHANNEL_X0Y10 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AM43} [get_ports {bullseye_tx_n[2]}] ;# MGTYTXN2_126 GTYE3_CHANNEL_X0Y10 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AJ45} [get_ports {bullseye_rx_p[3]}] ;# MGTYRXP3_126 GTYE3_CHANNEL_X0Y11 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AJ46} [get_ports {bullseye_rx_n[3]}] ;# MGTYRXN3_126 GTYE3_CHANNEL_X0Y11 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AL40} [get_ports {bullseye_tx_p[3]}] ;# MGTYTXP3_126 GTYE3_CHANNEL_X0Y11 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AL41} [get_ports {bullseye_tx_n[3]}] ;# MGTYTXN3_126 GTYE3_CHANNEL_X0Y11 / GTYE3_COMMON_X0Y2
set_property -dict {LOC AK38} [get_ports bullseye_mgt_refclk_0_p] ;# MGTREFCLK0P_126 from J87 P19
set_property -dict {LOC AK39} [get_ports bullseye_mgt_refclk_0_n] ;# MGTREFCLK0N_126 from J87 P20
set_property -dict {LOC AH38} [get_ports bullseye_mgt_refclk_1_p] ;# MGTREFCLK1P_126 from U32 SI570 via U104 SI53340
set_property -dict {LOC AH39} [get_ports bullseye_mgt_refclk_1_n] ;# MGTREFCLK1N_126 from U32 SI570 via U104 SI53340

# 156.25 MHz MGT reference clock
create_clock -period 6.4 -name bullseye_mgt_refclk [get_ports bullseye_mgt_refclk_1_p]
