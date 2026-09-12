# SPDX-License-Identifier: MIT
#
# Copyright (c) 2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Napatech NT40E3
# part: xc7vx330tffg1157-2

# 10/100 PHY (DP83630)
set_property -dict {LOC AJ16 IOSTANDARD LVCMOS18} [get_ports phy_tx_clk] ;# U5.1 TX_CLK via U53.4/13
set_property -dict {LOC AN14 IOSTANDARD LVCMOS18} [get_ports phy_tx_en] ;# U5.2 TX_EN via U51.4/13
set_property -dict {LOC AN18 IOSTANDARD LVCMOS18} [get_ports {phy_txd[0]}] ;# U5.3 TXD_0 via U50.4/13
set_property -dict {LOC AL16 IOSTANDARD LVCMOS18} [get_ports {phy_txd[1]}] ;# U5.4 TXD_1 via U50.5/12
set_property -dict {LOC AM16 IOSTANDARD LVCMOS18} [get_ports {phy_txd[2]}] ;# U5.5 TXD_2 via U50.6/11
set_property -dict {LOC AP17 IOSTANDARD LVCMOS18} [get_ports {phy_txd[3]}] ;# U5.6 TXD_3 via U50.7/10
set_property -dict {LOC AH15 IOSTANDARD LVCMOS18} [get_ports phy_rx_clk] ;# U5.38 RX_CLK via U55.5/12
set_property -dict {LOC AK18 IOSTANDARD LVCMOS18} [get_ports phy_rx_dv] ;# U5.39 RX_DV via U55.6/11
set_property -dict {LOC AL18 IOSTANDARD LVCMOS18} [get_ports phy_rx_er] ;# U5.41 RX_ER via U55.7/10
set_property -dict {LOC AP14 IOSTANDARD LVCMOS18} [get_ports {phy_rxd[0]}] ;# U5.46 RXD_0 via U53.5/12
set_property -dict {LOC AM17 IOSTANDARD LVCMOS18} [get_ports {phy_rxd[1]}] ;# U5.45 RXD_1 via U53.6/11
set_property -dict {LOC AN17 IOSTANDARD LVCMOS18} [get_ports {phy_rxd[2]}] ;# U5.44 RXD_2 via U53.7/10
set_property -dict {LOC AL15 IOSTANDARD LVCMOS18} [get_ports {phy_rxd[3]}] ;# U5.43 RXD_3 via U55.4/13
#set_property -dict {LOC AL14 IOSTANDARD LVCMOS18} [get_ports phy_crs] ;# U5.40 CRS/CRS_DV via U57.5/12
#set_property -dict {LOC AK14 IOSTANDARD LVCMOS18} [get_ports phy_col] ;# U5.42 COL via U57.4/13
set_property -dict {LOC AF16 IOSTANDARD LVCMOS18} [get_ports phy_refclk] ;# U5.34 X1
set_property -dict {LOC AC15 IOSTANDARD LVCMOS18} [get_ports phy_reset_n] ;# U5.29 RESET_N
set_property -dict {LOC AD15 IOSTANDARD LVCMOS18} [get_ports phy_int_n] ;# U5.7 PWRDOWN/INTN
#set_property -dict {LOC AJ17 IOSTANDARD LVCMOS18} [get_ports phy_mdc] ;# U5.31 MDC
#set_property -dict {LOC AK17 IOSTANDARD LVCMOS18} [get_ports phy_mdio] ;# U5.30 MDIO
#set_property -dict {LOC AF13 IOSTANDARD LVCMOS18} [get_ports phy_gpio1] ;# U5.21 GPIO1
#set_property -dict {LOC AG13 IOSTANDARD LVCMOS18} [get_ports phy_gpio2] ;# U5.22 GPIO2
#set_property -dict {LOC AE17 IOSTANDARD LVCMOS18} [get_ports phy_gpio3] ;# U5.23 GPIO3
#set_property -dict {LOC AE16 IOSTANDARD LVCMOS18} [get_ports phy_gpio4] ;# U5.25 GPIO4
#set_property -dict {LOC AE14 IOSTANDARD LVCMOS18} [get_ports phy_gpio5] ;# U5.26 GPIO5/LED_ACT
#set_property -dict {LOC AF14 IOSTANDARD LVCMOS18} [get_ports phy_gpio6] ;# U5.27 GPIO6/LED_SPEED/FX_SD
#set_property -dict {LOC AC17 IOSTANDARD LVCMOS18} [get_ports phy_gpio7] ;# U5.28 GPIO7/LED_LINK
#set_property -dict {LOC AD17 IOSTANDARD LVCMOS18} [get_ports phy_gpio8] ;# U5.36 GPIO8
#set_property -dict {LOC AD14 IOSTANDARD LVCMOS18} [get_ports phy_gpio9] ;# U5.37 GPIO9
#set_property -dict {LOC AG17 IOSTANDARD LVCMOS18} [get_ports phy_gpio12] ;# U5.24 GPIO12/CLK_OUT via U57.7/10
set_property -dict {LOC AJ14 IOSTANDARD LVCMOS18} [get_ports phy_isolate] ;# OE on U50, U51, U53, U55, U57
