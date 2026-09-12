# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the BittWare XUSP3S board
# part: xcvu095-ffvb2104-2-e

# PCIe Interface
set_property -dict {LOC AF2  } [get_ports {pcie_rx_p[0]}]  ;# MGTHRXP3_227 GTYE4_CHANNEL_X1Y35 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AF1  } [get_ports {pcie_rx_n[0]}]  ;# MGTHRXN3_227 GTYE4_CHANNEL_X1Y35 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AF7  } [get_ports {pcie_tx_p[0]}]  ;# MGTHTXP3_227 GTYE4_CHANNEL_X1Y35 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AF6  } [get_ports {pcie_tx_n[0]}]  ;# MGTHTXN3_227 GTYE4_CHANNEL_X1Y35 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AG4  } [get_ports {pcie_rx_p[1]}]  ;# MGTHRXP2_227 GTYE4_CHANNEL_X1Y34 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AG3  } [get_ports {pcie_rx_n[1]}]  ;# MGTHRXN2_227 GTYE4_CHANNEL_X1Y34 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AG9  } [get_ports {pcie_tx_p[1]}]  ;# MGTHTXP2_227 GTYE4_CHANNEL_X1Y34 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AG8  } [get_ports {pcie_tx_n[1]}]  ;# MGTHTXN2_227 GTYE4_CHANNEL_X1Y34 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AH2  } [get_ports {pcie_rx_p[2]}]  ;# MGTHRXP1_227 GTYE4_CHANNEL_X1Y33 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AH1  } [get_ports {pcie_rx_n[2]}]  ;# MGTHRXN1_227 GTYE4_CHANNEL_X1Y33 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AH7  } [get_ports {pcie_tx_p[2]}]  ;# MGTHTXP1_227 GTYE4_CHANNEL_X1Y33 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AH6  } [get_ports {pcie_tx_n[2]}]  ;# MGTHTXN1_227 GTYE4_CHANNEL_X1Y33 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AJ4  } [get_ports {pcie_rx_p[3]}]  ;# MGTHRXP0_227 GTYE4_CHANNEL_X1Y32 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AJ3  } [get_ports {pcie_rx_n[3]}]  ;# MGTHRXN0_227 GTYE4_CHANNEL_X1Y32 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AJ9  } [get_ports {pcie_tx_p[3]}]  ;# MGTHTXP0_227 GTYE4_CHANNEL_X1Y32 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AJ8  } [get_ports {pcie_tx_n[3]}]  ;# MGTHTXN0_227 GTYE4_CHANNEL_X1Y32 / GTYE4_COMMON_X1Y8
set_property -dict {LOC AK2  } [get_ports {pcie_rx_p[4]}]  ;# MGTHRXP3_226 GTYE4_CHANNEL_X1Y31 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AK1  } [get_ports {pcie_rx_n[4]}]  ;# MGTHRXN3_226 GTYE4_CHANNEL_X1Y31 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AK7  } [get_ports {pcie_tx_p[4]}]  ;# MGTHTXP3_226 GTYE4_CHANNEL_X1Y31 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AK6  } [get_ports {pcie_tx_n[4]}]  ;# MGTHTXN3_226 GTYE4_CHANNEL_X1Y31 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AL4  } [get_ports {pcie_rx_p[5]}]  ;# MGTHRXP2_226 GTYE4_CHANNEL_X1Y30 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AL3  } [get_ports {pcie_rx_n[5]}]  ;# MGTHRXN2_226 GTYE4_CHANNEL_X1Y30 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AL9  } [get_ports {pcie_tx_p[5]}]  ;# MGTHTXP2_226 GTYE4_CHANNEL_X1Y30 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AL8  } [get_ports {pcie_tx_n[5]}]  ;# MGTHTXN2_226 GTYE4_CHANNEL_X1Y30 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AM2  } [get_ports {pcie_rx_p[6]}]  ;# MGTHRXP1_226 GTYE4_CHANNEL_X1Y29 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AM1  } [get_ports {pcie_rx_n[6]}]  ;# MGTHRXN1_226 GTYE4_CHANNEL_X1Y29 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AM7  } [get_ports {pcie_tx_p[6]}]  ;# MGTHTXP1_226 GTYE4_CHANNEL_X1Y29 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AM6  } [get_ports {pcie_tx_n[6]}]  ;# MGTHTXN1_226 GTYE4_CHANNEL_X1Y29 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AN4  } [get_ports {pcie_rx_p[7]}]  ;# MGTHRXP0_226 GTYE4_CHANNEL_X1Y28 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AN3  } [get_ports {pcie_rx_n[7]}]  ;# MGTHRXN0_226 GTYE4_CHANNEL_X1Y28 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AN9  } [get_ports {pcie_tx_p[7]}]  ;# MGTHTXP0_226 GTYE4_CHANNEL_X1Y28 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AN8  } [get_ports {pcie_tx_n[7]}]  ;# MGTHTXN0_226 GTYE4_CHANNEL_X1Y28 / GTYE4_COMMON_X1Y7
set_property -dict {LOC AP2  } [get_ports {pcie_rx_p[8]}]  ;# MGTHRXP3_225 GTYE4_CHANNEL_X1Y27 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AP1  } [get_ports {pcie_rx_n[8]}]  ;# MGTHRXN3_225 GTYE4_CHANNEL_X1Y27 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AP7  } [get_ports {pcie_tx_p[8]}]  ;# MGTHTXP3_225 GTYE4_CHANNEL_X1Y27 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AP6  } [get_ports {pcie_tx_n[8]}]  ;# MGTHTXN3_225 GTYE4_CHANNEL_X1Y27 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AR4  } [get_ports {pcie_rx_p[9]}]  ;# MGTHRXP2_225 GTYE4_CHANNEL_X1Y26 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AR3  } [get_ports {pcie_rx_n[9]}]  ;# MGTHRXN2_225 GTYE4_CHANNEL_X1Y26 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AR9  } [get_ports {pcie_tx_p[9]}]  ;# MGTHTXP2_225 GTYE4_CHANNEL_X1Y26 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AR8  } [get_ports {pcie_tx_n[9]}]  ;# MGTHTXN2_225 GTYE4_CHANNEL_X1Y26 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AT2  } [get_ports {pcie_rx_p[10]}] ;# MGTHRXP1_225 GTYE4_CHANNEL_X1Y25 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AT1  } [get_ports {pcie_rx_n[10]}] ;# MGTHRXN1_225 GTYE4_CHANNEL_X1Y25 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AT7  } [get_ports {pcie_tx_p[10]}] ;# MGTHTXP1_225 GTYE4_CHANNEL_X1Y25 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AT6  } [get_ports {pcie_tx_n[10]}] ;# MGTHTXN1_225 GTYE4_CHANNEL_X1Y25 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AU4  } [get_ports {pcie_rx_p[11]}] ;# MGTHRXP0_225 GTYE4_CHANNEL_X1Y24 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AU3  } [get_ports {pcie_rx_n[11]}] ;# MGTHRXN0_225 GTYE4_CHANNEL_X1Y24 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AU9  } [get_ports {pcie_tx_p[11]}] ;# MGTHTXP0_225 GTYE4_CHANNEL_X1Y24 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AU8  } [get_ports {pcie_tx_n[11]}] ;# MGTHTXN0_225 GTYE4_CHANNEL_X1Y24 / GTYE4_COMMON_X1Y6
set_property -dict {LOC AV2  } [get_ports {pcie_rx_p[12]}] ;# MGTHRXP3_224 GTYE4_CHANNEL_X1Y23 / GTYE4_COMMON_X1Y5
set_property -dict {LOC AV1  } [get_ports {pcie_rx_n[12]}] ;# MGTHRXN3_224 GTYE4_CHANNEL_X1Y23 / GTYE4_COMMON_X1Y5
set_property -dict {LOC AV7  } [get_ports {pcie_tx_p[12]}] ;# MGTHTXP3_224 GTYE4_CHANNEL_X1Y23 / GTYE4_COMMON_X1Y5
set_property -dict {LOC AV6  } [get_ports {pcie_tx_n[12]}] ;# MGTHTXN3_224 GTYE4_CHANNEL_X1Y23 / GTYE4_COMMON_X1Y5
set_property -dict {LOC AW4  } [get_ports {pcie_rx_p[13]}] ;# MGTHRXP2_224 GTYE4_CHANNEL_X1Y22 / GTYE4_COMMON_X1Y5
set_property -dict {LOC AW3  } [get_ports {pcie_rx_n[13]}] ;# MGTHRXN2_224 GTYE4_CHANNEL_X1Y22 / GTYE4_COMMON_X1Y5
set_property -dict {LOC BB5  } [get_ports {pcie_tx_p[13]}] ;# MGTHTXP2_224 GTYE4_CHANNEL_X1Y22 / GTYE4_COMMON_X1Y5
set_property -dict {LOC BB4  } [get_ports {pcie_tx_n[13]}] ;# MGTHTXN2_224 GTYE4_CHANNEL_X1Y22 / GTYE4_COMMON_X1Y5
set_property -dict {LOC BA2  } [get_ports {pcie_rx_p[14]}] ;# MGTHRXP1_224 GTYE4_CHANNEL_X1Y21 / GTYE4_COMMON_X1Y5
set_property -dict {LOC BA1  } [get_ports {pcie_rx_n[14]}] ;# MGTHRXN1_224 GTYE4_CHANNEL_X1Y21 / GTYE4_COMMON_X1Y5
set_property -dict {LOC BD5  } [get_ports {pcie_tx_p[14]}] ;# MGTHTXP1_224 GTYE4_CHANNEL_X1Y21 / GTYE4_COMMON_X1Y5
set_property -dict {LOC BD4  } [get_ports {pcie_tx_n[14]}] ;# MGTHTXN1_224 GTYE4_CHANNEL_X1Y21 / GTYE4_COMMON_X1Y5
set_property -dict {LOC BC2  } [get_ports {pcie_rx_p[15]}] ;# MGTHRXP0_224 GTYE4_CHANNEL_X1Y20 / GTYE4_COMMON_X1Y5
set_property -dict {LOC BC1  } [get_ports {pcie_rx_n[15]}] ;# MGTHRXN0_224 GTYE4_CHANNEL_X1Y20 / GTYE4_COMMON_X1Y5
set_property -dict {LOC BF5  } [get_ports {pcie_tx_p[15]}] ;# MGTHTXP0_224 GTYE4_CHANNEL_X1Y20 / GTYE4_COMMON_X1Y5
set_property -dict {LOC BF4  } [get_ports {pcie_tx_n[15]}] ;# MGTHTXN0_224 GTYE4_CHANNEL_X1Y20 / GTYE4_COMMON_X1Y5
set_property -dict {LOC AT11 } [get_ports pcie_refclk_0_p] ;# MGTREFCLK0P_225
set_property -dict {LOC AT10 } [get_ports pcie_refclk_0_n] ;# MGTREFCLK0N_225
set_property -dict {LOC AM11 } [get_ports pcie_refclk_b1_p] ;# MGTREFCLK0P_226 from Si5338 B ch 1
set_property -dict {LOC AM10 } [get_ports pcie_refclk_b1_n] ;# MGTREFCLK0N_226 from Si5338 B ch 1
set_property -dict {LOC AH11 } [get_ports pcie_refclk_1_p] ;# MGTREFCLK0P_227
set_property -dict {LOC AH10 } [get_ports pcie_refclk_1_n] ;# MGTREFCLK0N_227
set_property -dict {LOC AR26 IOSTANDARD LVCMOS12 PULLUP true} [get_ports pcie_reset_n]

# 100 MHz MGT reference clock
create_clock -period 10.000 -name pcie_mgt_refclk_0 [get_ports pcie_refclk_0_p]
create_clock -period 10.000 -name pcie_mgt_refclk_b1 [get_ports pcie_refclk_b1_p]
create_clock -period 10.000 -name pcie_mgt_refclk_1 [get_ports pcie_refclk_1_p]

set_false_path -from [get_ports {pcie_reset_n}]
set_input_delay 0 [get_ports {pcie_reset_n}]
