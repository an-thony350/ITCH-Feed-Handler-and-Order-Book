# SPDX-License-Identifier: MIT
#
# Copyright (c) 2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Napatech NT40E3
# part: xc7vx330tffg1157-2

# PCIe Interface
set_property -dict {LOC AC4 } [get_ports {pcie_rx_p[0]}] ;# MGTHRXP3_115 GTHE2_CHANNEL_X0Y11 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AC3 } [get_ports {pcie_rx_n[0]}] ;# MGTHRXN3_115 GTHE2_CHANNEL_X0Y11 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AB2 } [get_ports {pcie_tx_p[0]}] ;# MGTHTXP3_115 GTHE2_CHANNEL_X0Y11 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AB1 } [get_ports {pcie_tx_n[0]}] ;# MGTHTXN3_115 GTHE2_CHANNEL_X0Y11 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AE4 } [get_ports {pcie_rx_p[1]}] ;# MGTHRXP2_115 GTHE2_CHANNEL_X0Y10 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AE3 } [get_ports {pcie_rx_n[1]}] ;# MGTHRXN2_115 GTHE2_CHANNEL_X0Y10 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AD2 } [get_ports {pcie_tx_p[1]}] ;# MGTHTXP2_115 GTHE2_CHANNEL_X0Y10 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AD1 } [get_ports {pcie_tx_n[1]}] ;# MGTHTXN2_115 GTHE2_CHANNEL_X0Y10 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AF6 } [get_ports {pcie_rx_p[2]}] ;# MGTHRXP1_115 GTHE2_CHANNEL_X0Y9 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AF5 } [get_ports {pcie_rx_n[2]}] ;# MGTHRXN1_115 GTHE2_CHANNEL_X0Y9 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AF2 } [get_ports {pcie_tx_p[2]}] ;# MGTHTXP1_115 GTHE2_CHANNEL_X0Y9 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AF1 } [get_ports {pcie_tx_n[2]}] ;# MGTHTXN1_115 GTHE2_CHANNEL_X0Y9 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AG4 } [get_ports {pcie_rx_p[3]}] ;# MGTHRXP0_115 GTHE2_CHANNEL_X0Y8 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AG3 } [get_ports {pcie_rx_n[3]}] ;# MGTHRXN0_115 GTHE2_CHANNEL_X0Y8 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AH2 } [get_ports {pcie_tx_p[3]}] ;# MGTHTXP0_115 GTHE2_CHANNEL_X0Y8 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AH1 } [get_ports {pcie_tx_n[3]}] ;# MGTHTXN0_115 GTHE2_CHANNEL_X0Y8 / GTHE2_COMMON_X0Y2
set_property -dict {LOC AJ4 } [get_ports {pcie_rx_p[4]}] ;# MGTHRXP3_114 GTHE2_CHANNEL_X0Y7 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AJ3 } [get_ports {pcie_rx_n[4]}] ;# MGTHRXN3_114 GTHE2_CHANNEL_X0Y7 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AK2 } [get_ports {pcie_tx_p[4]}] ;# MGTHTXP3_114 GTHE2_CHANNEL_X0Y7 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AK1 } [get_ports {pcie_tx_n[4]}] ;# MGTHTXN3_114 GTHE2_CHANNEL_X0Y7 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AL4 } [get_ports {pcie_rx_p[5]}] ;# MGTHRXP2_114 GTHE2_CHANNEL_X0Y6 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AL3 } [get_ports {pcie_rx_n[5]}] ;# MGTHRXN2_114 GTHE2_CHANNEL_X0Y6 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AM2 } [get_ports {pcie_tx_p[5]}] ;# MGTHTXP2_114 GTHE2_CHANNEL_X0Y6 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AM1 } [get_ports {pcie_tx_n[5]}] ;# MGTHTXN2_114 GTHE2_CHANNEL_X0Y6 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AM6 } [get_ports {pcie_rx_p[6]}] ;# MGTHRXP1_114 GTHE2_CHANNEL_X0Y5 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AM5 } [get_ports {pcie_rx_n[6]}] ;# MGTHRXN1_114 GTHE2_CHANNEL_X0Y5 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AN4 } [get_ports {pcie_tx_p[6]}] ;# MGTHTXP1_114 GTHE2_CHANNEL_X0Y5 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AN3 } [get_ports {pcie_tx_n[6]}] ;# MGTHTXN1_114 GTHE2_CHANNEL_X0Y5 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AP6 } [get_ports {pcie_rx_p[7]}] ;# MGTHRXP0_114 GTHE2_CHANNEL_X0Y4 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AP5 } [get_ports {pcie_rx_n[7]}] ;# MGTHRXN0_114 GTHE2_CHANNEL_X0Y4 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AP2 } [get_ports {pcie_tx_p[7]}] ;# MGTHTXP0_114 GTHE2_CHANNEL_X0Y4 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AP1 } [get_ports {pcie_tx_n[7]}] ;# MGTHTXN0_114 GTHE2_CHANNEL_X0Y4 / GTHE2_COMMON_X0Y1
set_property -dict {LOC AK6 } [get_ports pcie_mgt_refclk_p] ;# MGTREFCLK1P_115 via U28
set_property -dict {LOC AK5 } [get_ports pcie_mgt_refclk_n] ;# MGTREFCLK1N_115 via U28
set_property -dict {LOC AK32 IOSTANDARD LVCMOS18 PULLUP true} [get_ports pcie_reset]

# 100 MHz MGT reference clock
create_clock -period 10.000 -name pcie_mgt_refclk [get_ports pcie_mgt_refclk_p]

set_false_path -from [get_ports {pcie_reset}]
set_input_delay 0 [get_ports {pcie_reset}]
