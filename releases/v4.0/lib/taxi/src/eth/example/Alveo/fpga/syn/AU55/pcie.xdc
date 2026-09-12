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

# PCIe Interface
set_property -dict {LOC AL2 } [get_ports {pcie_rx_p[0]}]  ;# MGTYRXP3_227 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AL1 } [get_ports {pcie_rx_n[0]}]  ;# MGTYRXN3_227 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AL11} [get_ports {pcie_tx_p[0]}]  ;# MGTYTXP3_227 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AL10} [get_ports {pcie_tx_n[0]}]  ;# MGTYTXN3_227 GTYE4_CHANNEL_X1Y15 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AM4 } [get_ports {pcie_rx_p[1]}]  ;# MGTYRXP2_227 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AM3 } [get_ports {pcie_rx_n[1]}]  ;# MGTYRXN2_227 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AM9 } [get_ports {pcie_tx_p[1]}]  ;# MGTYTXP2_227 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AM8 } [get_ports {pcie_tx_n[1]}]  ;# MGTYTXN2_227 GTYE4_CHANNEL_X1Y14 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AN6 } [get_ports {pcie_rx_p[2]}]  ;# MGTYRXP1_227 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AN5 } [get_ports {pcie_rx_n[2]}]  ;# MGTYRXN1_227 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AN11} [get_ports {pcie_tx_p[2]}]  ;# MGTYTXP1_227 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AN10} [get_ports {pcie_tx_n[2]}]  ;# MGTYTXN1_227 GTYE4_CHANNEL_X1Y13 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AN2 } [get_ports {pcie_rx_p[3]}]  ;# MGTYRXP0_227 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AN1 } [get_ports {pcie_rx_n[3]}]  ;# MGTYRXN0_227 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AP9 } [get_ports {pcie_tx_p[3]}]  ;# MGTYTXP0_227 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AP8 } [get_ports {pcie_tx_n[3]}]  ;# MGTYTXN0_227 GTYE4_CHANNEL_X1Y12 / GTYE4_COMMON_X1Y3
set_property -dict {LOC AP4 } [get_ports {pcie_rx_p[4]}]  ;# MGTYRXP3_226 GTYE4_CHANNEL_X1Y11 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AP3 } [get_ports {pcie_rx_n[4]}]  ;# MGTYRXN3_226 GTYE4_CHANNEL_X1Y11 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AR11} [get_ports {pcie_tx_p[4]}]  ;# MGTYTXP3_226 GTYE4_CHANNEL_X1Y11 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AR10} [get_ports {pcie_tx_n[4]}]  ;# MGTYTXN3_226 GTYE4_CHANNEL_X1Y11 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AR2 } [get_ports {pcie_rx_p[5]}]  ;# MGTYRXP2_226 GTYE4_CHANNEL_X1Y10 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AR1 } [get_ports {pcie_rx_n[5]}]  ;# MGTYRXN2_226 GTYE4_CHANNEL_X1Y10 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AR7 } [get_ports {pcie_tx_p[5]}]  ;# MGTYTXP2_226 GTYE4_CHANNEL_X1Y10 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AR6 } [get_ports {pcie_tx_n[5]}]  ;# MGTYTXN2_226 GTYE4_CHANNEL_X1Y10 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AT4 } [get_ports {pcie_rx_p[6]}]  ;# MGTYRXP1_226 GTYE4_CHANNEL_X1Y9 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AT3 } [get_ports {pcie_rx_n[6]}]  ;# MGTYRXN1_226 GTYE4_CHANNEL_X1Y9 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AT9 } [get_ports {pcie_tx_p[6]}]  ;# MGTYTXP1_226 GTYE4_CHANNEL_X1Y9 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AT8 } [get_ports {pcie_tx_n[6]}]  ;# MGTYTXN1_226 GTYE4_CHANNEL_X1Y9 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AU2 } [get_ports {pcie_rx_p[7]}]  ;# MGTYRXP0_226 GTYE4_CHANNEL_X1Y8 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AU1 } [get_ports {pcie_rx_n[7]}]  ;# MGTYRXN0_226 GTYE4_CHANNEL_X1Y8 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AU11} [get_ports {pcie_tx_p[7]}]  ;# MGTYTXP0_226 GTYE4_CHANNEL_X1Y8 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AU10} [get_ports {pcie_tx_n[7]}]  ;# MGTYTXN0_226 GTYE4_CHANNEL_X1Y8 / GTYE4_COMMON_X1Y2
set_property -dict {LOC AV4 } [get_ports {pcie_rx_p[8]}]  ;# MGTYRXP3_225 GTYE4_CHANNEL_X1Y7 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AV3 } [get_ports {pcie_rx_n[8]}]  ;# MGTYRXN3_225 GTYE4_CHANNEL_X1Y7 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AU7 } [get_ports {pcie_tx_p[8]}]  ;# MGTYTXP3_225 GTYE4_CHANNEL_X1Y7 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AU6 } [get_ports {pcie_tx_n[8]}]  ;# MGTYTXN3_225 GTYE4_CHANNEL_X1Y7 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AW6 } [get_ports {pcie_rx_p[9]}]  ;# MGTYRXP2_225 GTYE4_CHANNEL_X1Y6 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AW5 } [get_ports {pcie_rx_n[9]}]  ;# MGTYRXN2_225 GTYE4_CHANNEL_X1Y6 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AV9 } [get_ports {pcie_tx_p[9]}]  ;# MGTYTXP2_225 GTYE4_CHANNEL_X1Y6 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AV8 } [get_ports {pcie_tx_n[9]}]  ;# MGTYTXN2_225 GTYE4_CHANNEL_X1Y6 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AW2 } [get_ports {pcie_rx_p[10]}] ;# MGTYRXP1_225 GTYE4_CHANNEL_X1Y5 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AW1 } [get_ports {pcie_rx_n[10]}] ;# MGTYRXN1_225 GTYE4_CHANNEL_X1Y5 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AW11} [get_ports {pcie_tx_p[10]}] ;# MGTYTXP1_225 GTYE4_CHANNEL_X1Y5 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AW10} [get_ports {pcie_tx_n[10]}] ;# MGTYTXN1_225 GTYE4_CHANNEL_X1Y5 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AY4 } [get_ports {pcie_rx_p[11]}] ;# MGTYRXP0_225 GTYE4_CHANNEL_X1Y4 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AY3 } [get_ports {pcie_rx_n[11]}] ;# MGTYRXN0_225 GTYE4_CHANNEL_X1Y4 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AY9 } [get_ports {pcie_tx_p[11]}] ;# MGTYTXP0_225 GTYE4_CHANNEL_X1Y4 / GTYE4_COMMON_X1Y1
set_property -dict {LOC AY8 } [get_ports {pcie_tx_n[11]}] ;# MGTYTXN0_225 GTYE4_CHANNEL_X1Y4 / GTYE4_COMMON_X1Y1
set_property -dict {LOC BA6 } [get_ports {pcie_rx_p[12]}] ;# MGTYRXP3_224 GTYE4_CHANNEL_X1Y3 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BA5 } [get_ports {pcie_rx_n[12]}] ;# MGTYRXN3_224 GTYE4_CHANNEL_X1Y3 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BA11} [get_ports {pcie_tx_p[12]}] ;# MGTYTXP3_224 GTYE4_CHANNEL_X1Y3 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BA10} [get_ports {pcie_tx_n[12]}] ;# MGTYTXN3_224 GTYE4_CHANNEL_X1Y3 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BA2 } [get_ports {pcie_rx_p[13]}] ;# MGTYRXP2_224 GTYE4_CHANNEL_X1Y2 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BA1 } [get_ports {pcie_rx_n[13]}] ;# MGTYRXN2_224 GTYE4_CHANNEL_X1Y2 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BB9 } [get_ports {pcie_tx_p[13]}] ;# MGTYTXP2_224 GTYE4_CHANNEL_X1Y2 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BB8 } [get_ports {pcie_tx_n[13]}] ;# MGTYTXN2_224 GTYE4_CHANNEL_X1Y2 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BB4 } [get_ports {pcie_rx_p[14]}] ;# MGTYRXP1_224 GTYE4_CHANNEL_X1Y1 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BB3 } [get_ports {pcie_rx_n[14]}] ;# MGTYRXN1_224 GTYE4_CHANNEL_X1Y1 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BC11} [get_ports {pcie_tx_p[14]}] ;# MGTYTXP1_224 GTYE4_CHANNEL_X1Y1 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BC10} [get_ports {pcie_tx_n[14]}] ;# MGTYTXN1_224 GTYE4_CHANNEL_X1Y1 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BC2 } [get_ports {pcie_rx_p[15]}] ;# MGTYRXP0_224 GTYE4_CHANNEL_X1Y0 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BC1 } [get_ports {pcie_rx_n[15]}] ;# MGTYRXN0_224 GTYE4_CHANNEL_X1Y0 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BC7 } [get_ports {pcie_tx_p[15]}] ;# MGTYTXP0_224 GTYE4_CHANNEL_X1Y0 / GTYE4_COMMON_X1Y0
set_property -dict {LOC BC6 } [get_ports {pcie_tx_n[15]}] ;# MGTYTXN0_224 GTYE4_CHANNEL_X1Y0 / GTYE4_COMMON_X1Y0
#set_property -dict {LOC AL15} [get_ports {pcie_refclk_0_p}] ;# MGTREFCLK0P_227 (for x8 bifurcated lanes 0-7)
#set_property -dict {LOC AL14} [get_ports {pcie_refclk_0_n}] ;# MGTREFCLK0N_227 (for x8 bifurcated lanes 0-7)
#set_property -dict {LOC AK13} [get_ports {pcie_refclk_2_p}] ;# MGTREFCLK1P_227 (for async x8 bifurcated lanes 0-7)
#set_property -dict {LOC AK12} [get_ports {pcie_refclk_2_n}] ;# MGTREFCLK1N_227 (for async x8 bifurcated lanes 0-7)
set_property -dict {LOC AR15} [get_ports {pcie_refclk_1_p}] ;# MGTREFCLK0P_225 (for x16 or x8 bifurcated lanes 8-16)
set_property -dict {LOC AR14} [get_ports {pcie_refclk_1_n}] ;# MGTREFCLK0N_225 (for x16 or x8 bifurcated lanes 8-16)
#set_property -dict {LOC AP13} [get_ports {pcie_refclk_3_p}] ;# MGTREFCLK1P_225 (for async x16 or x8 bifurcated lanes 8-16)
#set_property -dict {LOC AP12} [get_ports {pcie_refclk_3_n}] ;# MGTREFCLK1N_225 (for async x16 or x8 bifurcated lanes 8-16)
set_property -dict {LOC BF41 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {pcie_reset_n}]
#set_property -dict {LOC BG43 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {pcie_pwrbrkn_n}]

# 100 MHz MGT reference clock
#create_clock -period 10.000 -name pcie_mgt_refclk_0 [get_ports {pcie_refclk_0_p}]
create_clock -period 10.000 -name pcie_mgt_refclk_1 [get_ports {pcie_refclk_1_p}]
#create_clock -period 10.000 -name pcie_mgt_refclk_2 [get_ports {pcie_refclk_2_p}]
#create_clock -period 10.000 -name pcie_mgt_refclk_3 [get_ports {pcie_refclk_3_p}]

set_false_path -from [get_ports {pcie_reset_n}]
set_input_delay 0 [get_ports {pcie_reset_n}]
