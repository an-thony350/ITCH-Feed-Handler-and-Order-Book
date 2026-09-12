# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU106 board
# part: xczu7ev-ffvc1156-2-e

# PCIe Interface
set_property -dict {LOC AE2 } [get_ports {pcie_rx_p[0]}] ;# MGTHRXP3_224 GTHE4_CHANNEL_X0Y7 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AE1 } [get_ports {pcie_rx_n[0]}] ;# MGTHRXN3_224 GTHE4_CHANNEL_X0Y7 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AD4 } [get_ports {pcie_tx_p[0]}] ;# MGTHTXP3_224 GTHE4_CHANNEL_X0Y7 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AD3 } [get_ports {pcie_tx_n[0]}] ;# MGTHTXN3_224 GTHE4_CHANNEL_X0Y7 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AF4 } [get_ports {pcie_rx_p[1]}] ;# MGTHRXP2_224 GTHE4_CHANNEL_X0Y6 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AF3 } [get_ports {pcie_rx_n[1]}] ;# MGTHRXN2_224 GTHE4_CHANNEL_X0Y6 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AE6 } [get_ports {pcie_tx_p[1]}] ;# MGTHTXP2_224 GTHE4_CHANNEL_X0Y6 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AE5 } [get_ports {pcie_tx_n[1]}] ;# MGTHTXN2_224 GTHE4_CHANNEL_X0Y6 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AG2 } [get_ports {pcie_rx_p[2]}] ;# MGTHRXP1_224 GTHE4_CHANNEL_X0Y5 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AG1 } [get_ports {pcie_rx_n[2]}] ;# MGTHRXN1_224 GTHE4_CHANNEL_X0Y5 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AG6 } [get_ports {pcie_tx_p[2]}] ;# MGTHTXP1_224 GTHE4_CHANNEL_X0Y5 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AG5 } [get_ports {pcie_tx_n[2]}] ;# MGTHTXN1_224 GTHE4_CHANNEL_X0Y5 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AJ2 } [get_ports {pcie_rx_p[3]}] ;# MGTHRXP0_224 GTHE4_CHANNEL_X0Y4 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AJ1 } [get_ports {pcie_rx_n[3]}] ;# MGTHRXN0_224 GTHE4_CHANNEL_X0Y4 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AH4 } [get_ports {pcie_tx_p[3]}] ;# MGTHTXP0_224 GTHE4_CHANNEL_X0Y4 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AH3 } [get_ports {pcie_tx_n[3]}] ;# MGTHTXN0_224 GTHE4_CHANNEL_X0Y4 / GTHE4_COMMON_X0Y1
set_property -dict {LOC AB8 } [get_ports pcie_refclk_p] ;# MGTREFCLK0P_224
set_property -dict {LOC AB7 } [get_ports pcie_refclk_n] ;# MGTREFCLK0N_224
set_property -dict {LOC L8  IOSTANDARD LVCMOS33 PULLUP true} [get_ports pcie_reset_n]

# 100 MHz MGT reference clock
create_clock -period 10.000 -name pcie_mgt_refclk [get_ports pcie_mgt_refclk_p]

set_false_path -from [get_ports {pcie_reset_n}]
set_input_delay 0 [get_ports {pcie_reset_n}]
