# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U45N/SN1022 board
# part: xcux35-vsva1365-3-e

# PCIe Interface
set_property -dict {LOC AT4 } [get_ports {pcie_rx_p[0]}] ;# MGTYRXP3_225 GTYE4_CHANNEL_X1Y7 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AT3 } [get_ports {pcie_rx_n[0]}] ;# MGTYRXN3_225 GTYE4_CHANNEL_X1Y7 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AP8 } [get_ports {pcie_tx_p[0]}] ;# MGTYTXP3_225 GTYE4_CHANNEL_X1Y7 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AP7 } [get_ports {pcie_tx_n[0]}] ;# MGTYTXN3_225 GTYE4_CHANNEL_X1Y7 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AU6 } [get_ports {pcie_rx_p[1]}] ;# MGTYRXP2_225 GTYE4_CHANNEL_X1Y6 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AU5 } [get_ports {pcie_rx_n[1]}] ;# MGTYRXN2_225 GTYE4_CHANNEL_X1Y6 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AR6 } [get_ports {pcie_tx_p[1]}] ;# MGTYTXP2_225 GTYE4_CHANNEL_X1Y6 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AR5 } [get_ports {pcie_tx_n[1]}] ;# MGTYTXN2_225 GTYE4_CHANNEL_X1Y6 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AT8 } [get_ports {pcie_rx_p[2]}] ;# MGTYRXP1_225 GTYE4_CHANNEL_X1Y5 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AT7 } [get_ports {pcie_rx_n[2]}] ;# MGTYRXN1_225 GTYE4_CHANNEL_X1Y5 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AR10} [get_ports {pcie_tx_p[2]}] ;# MGTYTXP1_225 GTYE4_CHANNEL_X1Y5 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AR9 } [get_ports {pcie_tx_n[2]}] ;# MGTYTXN1_225 GTYE4_CHANNEL_X1Y5 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AU10} [get_ports {pcie_rx_p[3]}] ;# MGTYRXP0_225 GTYE4_CHANNEL_X1Y4 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AU9 } [get_ports {pcie_rx_n[3]}] ;# MGTYRXN0_225 GTYE4_CHANNEL_X1Y4 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AT12} [get_ports {pcie_tx_p[3]}] ;# MGTYTXP0_225 GTYE4_CHANNEL_X1Y4 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AT11} [get_ports {pcie_tx_n[3]}] ;# MGTYTXN0_225 GTYE4_CHANNEL_X1Y4 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AU14} [get_ports {pcie_rx_p[4]}] ;# MGTYRXP3_224 GTYE4_CHANNEL_X1Y3 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AU13} [get_ports {pcie_rx_n[4]}] ;# MGTYRXN3_224 GTYE4_CHANNEL_X1Y3 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AR14} [get_ports {pcie_tx_p[4]}] ;# MGTYTXP3_224 GTYE4_CHANNEL_X1Y3 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AR13} [get_ports {pcie_tx_n[4]}] ;# MGTYTXN3_224 GTYE4_CHANNEL_X1Y3 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AT16} [get_ports {pcie_rx_p[5]}] ;# MGTYRXP2_224 GTYE4_CHANNEL_X1Y2 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AT15} [get_ports {pcie_rx_n[5]}] ;# MGTYRXN2_224 GTYE4_CHANNEL_X1Y2 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AR18} [get_ports {pcie_tx_p[5]}] ;# MGTYTXP2_224 GTYE4_CHANNEL_X1Y2 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AR17} [get_ports {pcie_tx_n[5]}] ;# MGTYTXN2_224 GTYE4_CHANNEL_X1Y2 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AU18} [get_ports {pcie_rx_p[6]}] ;# MGTYRXP1_224 GTYE4_CHANNEL_X1Y1 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AU17} [get_ports {pcie_rx_n[6]}] ;# MGTYRXN1_224 GTYE4_CHANNEL_X1Y1 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AT20} [get_ports {pcie_tx_p[6]}] ;# MGTYTXP1_224 GTYE4_CHANNEL_X1Y1 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AT19} [get_ports {pcie_tx_n[6]}] ;# MGTYTXN1_224 GTYE4_CHANNEL_X1Y1 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AU22} [get_ports {pcie_rx_p[7]}] ;# MGTYRXP0_224 GTYE4_CHANNEL_X1Y0 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AU21} [get_ports {pcie_rx_n[7]}] ;# MGTYRXN0_224 GTYE4_CHANNEL_X1Y0 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AR22} [get_ports {pcie_tx_p[7]}] ;# MGTYTXP0_224 GTYE4_CHANNEL_X1Y0 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AR21} [get_ports {pcie_tx_n[7]}] ;# MGTYTXN0_224 GTYE4_CHANNEL_X1Y0 / GTYE4_COMMON_X1Y0
set_property -dict {LOC AL10} [get_ports {pcie_refclk_p}] ;# MGTREFCLK0P_225
set_property -dict {LOC AL9 } [get_ports {pcie_refclk_n}] ;# MGTREFCLK0N_225
#set_property -dict {LOC AK8 } [get_ports {pcie_refclk_p}] ;# MGTREFCLK1P_225
#set_property -dict {LOC AK7 } [get_ports {pcie_refclk_n}] ;# MGTREFCLK1N_225
set_property -dict {LOC AK18 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {pcie_reset_n}]
#set_property -dict {LOC AM20 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {pcie_pwrbrkn_n}]

# 100 MHz MGT reference clock
create_clock -period 10.000 -name pcie_mgt_refclk_1 [get_ports {pcie_refclk_p}]

set_false_path -from [get_ports {pcie_reset_n pcie_pwrbrkn_n}]
set_input_delay 0 [get_ports {pcie_reset_n pcie_pwrbrkn_n}]
