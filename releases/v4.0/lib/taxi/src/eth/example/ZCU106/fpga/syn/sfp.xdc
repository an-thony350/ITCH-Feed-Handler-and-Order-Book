# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU106 board
# part: xczu7ev-ffvc1156-2-e

# SFP+ Interface
set_property -dict {LOC AA2 } [get_ports {sfp_rx_p[0]}] ;# MGTHRXP2_225 GTHE4_CHANNEL_X0Y10 / GTHE4_COMMON_X0Y2
set_property -dict {LOC AA1 } [get_ports {sfp_rx_n[0]}] ;# MGTHRXN2_225 GTHE4_CHANNEL_X0Y10 / GTHE4_COMMON_X0Y2
set_property -dict {LOC Y4  } [get_ports {sfp_tx_p[0]}] ;# MGTHTXP2_225 GTHE4_CHANNEL_X0Y10 / GTHE4_COMMON_X0Y2
set_property -dict {LOC Y3  } [get_ports {sfp_tx_n[0]}] ;# MGTHTXN2_225 GTHE4_CHANNEL_X0Y10 / GTHE4_COMMON_X0Y2
set_property -dict {LOC W2  } [get_ports {sfp_rx_p[1]}] ;# MGTHRXP3_225 GTHE4_CHANNEL_X0Y11 / GTHE4_COMMON_X0Y2
set_property -dict {LOC W1  } [get_ports {sfp_rx_n[1]}] ;# MGTHRXN3_225 GTHE4_CHANNEL_X0Y11 / GTHE4_COMMON_X0Y2
set_property -dict {LOC W6  } [get_ports {sfp_tx_p[1]}] ;# MGTHTXP3_225 GTHE4_CHANNEL_X0Y11 / GTHE4_COMMON_X0Y2
set_property -dict {LOC W5  } [get_ports {sfp_tx_n[1]}] ;# MGTHTXN3_225 GTHE4_CHANNEL_X0Y11 / GTHE4_COMMON_X0Y2
set_property -dict {LOC U10 } [get_ports {sfp_mgt_refclk_0_p}] ;# MGTREFCLK1P_226 from U56 SI570 via U51 SI53340
set_property -dict {LOC U9  } [get_ports {sfp_mgt_refclk_0_n}] ;# MGTREFCLK1N_226 from U56 SI570 via U51 SI53340
#set_property -dict {LOC W10 } [get_ports {sfp_mgt_refclk_1_p}] ;# MGTREFCLK1P_225 from U20 CKOUT2 SI5328
#set_property -dict {LOC W9  } [get_ports {sfp_mgt_refclk_1_n}] ;# MGTREFCLK1N_225 from U20 CKOUT2 SI5328
#set_property -dict {LOC H11 IOSTANDARD LVDS} [get_ports {sfp_recclk_p}] ;# to U20 CKIN1 SI5328
#set_property -dict {LOC G11 IOSTANDARD LVDS} [get_ports {sfp_recclk_n}] ;# to U20 CKIN1 SI5328
set_property -dict {LOC AE22 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[0]}]
set_property -dict {LOC AF20 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {sfp_tx_disable_b[1]}]

# 156.25 MHz MGT reference clock
create_clock -period 6.400 -name sfp_mgt_refclk_0 [get_ports {sfp_mgt_refclk_0_p}]

set_false_path -to [get_ports {sfp_tx_disable_b[*]}]
set_output_delay 0 [get_ports {sfp_tx_disable_b[*]}]
