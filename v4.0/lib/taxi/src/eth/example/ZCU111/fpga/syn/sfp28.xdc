# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU111 board
# part: xczu28dr-ffvg1517-2-e

# SFP28 Interface
set_property -dict {LOC AA38} [get_ports {sfp_rx_p[0]}] ;# MGTYRXP0_128 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AA39} [get_ports {sfp_rx_n[0]}] ;# MGTYRXN0_128 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC Y35 } [get_ports {sfp_tx_p[0]}] ;# MGTYTXP0_128 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC Y36 } [get_ports {sfp_tx_n[0]}] ;# MGTYTXN0_128 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC W38 } [get_ports {sfp_rx_p[1]}] ;# MGTYRXP1_128 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC W39 } [get_ports {sfp_rx_n[1]}] ;# MGTYRXN1_128 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC V35 } [get_ports {sfp_tx_p[1]}] ;# MGTYTXP1_128 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC V36 } [get_ports {sfp_tx_n[1]}] ;# MGTYTXN1_128 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC U38 } [get_ports {sfp_rx_p[2]}] ;# MGTYRXP2_128 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC U39 } [get_ports {sfp_rx_n[2]}] ;# MGTYRXN2_128 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC T35 } [get_ports {sfp_tx_p[2]}] ;# MGTYTXP2_128 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC T36 } [get_ports {sfp_tx_n[2]}] ;# MGTYTXN2_128 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC R38 } [get_ports {sfp_rx_p[3]}] ;# MGTYRXP3_128 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC R39 } [get_ports {sfp_rx_n[3]}] ;# MGTYRXN3_128 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC R33 } [get_ports {sfp_tx_p[3]}] ;# MGTYTXP3_128 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC R34 } [get_ports {sfp_tx_n[3]}] ;# MGTYTXN3_128 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC V31 } [get_ports {sfp_mgt_refclk_0_p}] ;# MGTREFCLK1P_129 from U49 SI570
set_property -dict {LOC V32 } [get_ports {sfp_mgt_refclk_0_n}] ;# MGTREFCLK1N_129 from U49 SI570
#set_property -dict {LOC Y31 } [get_ports {sfp_mgt_refclk_1_p}] ;# MGTREFCLK1P_128 from U48 OUT0 SI5382A
#set_property -dict {LOC Y32 } [get_ports {sfp_mgt_refclk_1_n}] ;# MGTREFCLK1N_128 from U48 OUT0 SI5382A
#set_property -dict {LOC AW14 IOSTANDARD LVDS} [get_ports {sfp_recclk_p}] ;# to U48 CKIN1 SI5382
#set_property -dict {LOC AW13 IOSTANDARD LVDS} [get_ports {sfp_recclk_n}] ;# to U48 CKIN1 SI5382
set_property -dict {LOC G12  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[0]}]
set_property -dict {LOC G10  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[1]}]
set_property -dict {LOC K12  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[2]}]
set_property -dict {LOC J7   IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[3]}]

# 156.25 MHz MGT reference clock
create_clock -period 6.400 -name sfp_mgt_refclk_0 [get_ports {sfp_mgt_refclk_0_p}]

set_false_path -to [get_ports {sfp_tx_disable_b[*]}]
set_output_delay 0 [get_ports {sfp_tx_disable_b[*]}]
