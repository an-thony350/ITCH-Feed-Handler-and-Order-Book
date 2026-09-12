# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VCU108 board
# part: xcvu095-ffva2104-2-e

# PCIe Interface
set_property -dict {LOC AJ4 } [get_ports {pcie_rx_p[0]}] ;# MGTHRXP3_225 GTHE3_CHANNEL_X0Y7 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AJ3 } [get_ports {pcie_rx_n[0]}] ;# MGTHRXN3_225 GTHE3_CHANNEL_X0Y7 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AP7 } [get_ports {pcie_tx_p[0]}] ;# MGTHTXP3_225 GTHE3_CHANNEL_X0Y7 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AP6 } [get_ports {pcie_tx_n[0]}] ;# MGTHTXN3_225 GTHE3_CHANNEL_X0Y7 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AK2 } [get_ports {pcie_rx_p[1]}] ;# MGTHRXP2_225 GTHE3_CHANNEL_X0Y6 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AK1 } [get_ports {pcie_rx_n[1]}] ;# MGTHRXN2_225 GTHE3_CHANNEL_X0Y6 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AR5 } [get_ports {pcie_tx_p[1]}] ;# MGTHTXP2_225 GTHE3_CHANNEL_X0Y6 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AR4 } [get_ports {pcie_tx_n[1]}] ;# MGTHTXN2_225 GTHE3_CHANNEL_X0Y6 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AM2 } [get_ports {pcie_rx_p[2]}] ;# MGTHRXP1_225 GTHE3_CHANNEL_X0Y5 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AM1 } [get_ports {pcie_rx_n[2]}] ;# MGTHRXN1_225 GTHE3_CHANNEL_X0Y5 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AT7 } [get_ports {pcie_tx_p[2]}] ;# MGTHTXP1_225 GTHE3_CHANNEL_X0Y5 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AT6 } [get_ports {pcie_tx_n[2]}] ;# MGTHTXN1_225 GTHE3_CHANNEL_X0Y5 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AP2 } [get_ports {pcie_rx_p[3]}] ;# MGTHRXP0_225 GTHE3_CHANNEL_X0Y4 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AP1 } [get_ports {pcie_rx_n[3]}] ;# MGTHRXN0_225 GTHE3_CHANNEL_X0Y4 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AU5 } [get_ports {pcie_tx_p[3]}] ;# MGTHTXP0_225 GTHE3_CHANNEL_X0Y4 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AU4 } [get_ports {pcie_tx_n[3]}] ;# MGTHTXN0_225 GTHE3_CHANNEL_X0Y4 / GTHE3_COMMON_X0Y1
set_property -dict {LOC AT2 } [get_ports {pcie_rx_p[4]}] ;# MGTHRXP3_224 GTHE3_CHANNEL_X0Y3 / GTHE3_COMMON_X0Y0
set_property -dict {LOC AT1 } [get_ports {pcie_rx_n[4]}] ;# MGTHRXN3_224 GTHE3_CHANNEL_X0Y3 / GTHE3_COMMON_X0Y0
set_property -dict {LOC AW5 } [get_ports {pcie_tx_p[4]}] ;# MGTHTXP3_224 GTHE3_CHANNEL_X0Y3 / GTHE3_COMMON_X0Y0
set_property -dict {LOC AW4 } [get_ports {pcie_tx_n[4]}] ;# MGTHTXN3_224 GTHE3_CHANNEL_X0Y3 / GTHE3_COMMON_X0Y0
set_property -dict {LOC AV2 } [get_ports {pcie_rx_p[5]}] ;# MGTHRXP2_224 GTHE3_CHANNEL_X0Y2 / GTHE3_COMMON_X0Y0
set_property -dict {LOC AV1 } [get_ports {pcie_rx_n[5]}] ;# MGTHRXN2_224 GTHE3_CHANNEL_X0Y2 / GTHE3_COMMON_X0Y0
set_property -dict {LOC BA5 } [get_ports {pcie_tx_p[5]}] ;# MGTHTXP2_224 GTHE3_CHANNEL_X0Y2 / GTHE3_COMMON_X0Y0
set_property -dict {LOC BA4 } [get_ports {pcie_tx_n[5]}] ;# MGTHTXN2_224 GTHE3_CHANNEL_X0Y2 / GTHE3_COMMON_X0Y0
set_property -dict {LOC AY2 } [get_ports {pcie_rx_p[6]}] ;# MGTHRXP1_224 GTHE3_CHANNEL_X0Y1 / GTHE3_COMMON_X0Y0
set_property -dict {LOC AY1 } [get_ports {pcie_rx_n[6]}] ;# MGTHRXN1_224 GTHE3_CHANNEL_X0Y1 / GTHE3_COMMON_X0Y0
set_property -dict {LOC BC5 } [get_ports {pcie_tx_p[6]}] ;# MGTHTXP1_224 GTHE3_CHANNEL_X0Y1 / GTHE3_COMMON_X0Y0
set_property -dict {LOC BC4 } [get_ports {pcie_tx_n[6]}] ;# MGTHTXN1_224 GTHE3_CHANNEL_X0Y1 / GTHE3_COMMON_X0Y0
set_property -dict {LOC BB2 } [get_ports {pcie_rx_p[7]}] ;# MGTHRXP0_224 GTHE3_CHANNEL_X0Y0 / GTHE3_COMMON_X0Y0
set_property -dict {LOC BB1 } [get_ports {pcie_rx_n[7]}] ;# MGTHRXN0_224 GTHE3_CHANNEL_X0Y0 / GTHE3_COMMON_X0Y0
set_property -dict {LOC BE5 } [get_ports {pcie_tx_p[7]}] ;# MGTHTXP0_224 GTHE3_CHANNEL_X0Y0 / GTHE3_COMMON_X0Y0
set_property -dict {LOC BE4 } [get_ports {pcie_tx_n[7]}] ;# MGTHTXN0_224 GTHE3_CHANNEL_X0Y0 / GTHE3_COMMON_X0Y0
set_property -dict {LOC AL9 } [get_ports pcie_refclk_p] ;# MGTREFCLK0P_225
set_property -dict {LOC AL8 } [get_ports pcie_refclk_n] ;# MGTREFCLK0N_225
set_property -dict {LOC AM17 IOSTANDARD LVCMOS18 PULLUP true} [get_ports pcie_reset_n]

# 100 MHz MGT reference clock
create_clock -period 10.000 -name pcie_refclk [get_ports pcie_refclk_p]

set_false_path -from [get_ports {pcie_reset_n}]
set_input_delay 0 [get_ports {pcie_reset_n}]
