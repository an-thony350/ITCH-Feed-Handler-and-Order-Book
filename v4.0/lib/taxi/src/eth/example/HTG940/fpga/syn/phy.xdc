# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the HiTech Global HTG-9200 board
# part: xcvu9p-flgb2104-2-e
# part: xcvu13p-fhgb2104-2-e

# Gigabit Ethernet RGMII PHY
set_property -dict {LOC G20  IOSTANDARD LVCMOS18} [get_ports {phy_rx_clk}] ;# from U2.43 // MAYBE
set_property -dict {LOC A20  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[0]}] ;# from U2.44
set_property -dict {LOC D21  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[1]}] ;# from U2.45
set_property -dict {LOC E21  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[2]}] ;# from U2.46
set_property -dict {LOC C21  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[3]}] ;# from U2.47
set_property -dict {LOC B21  IOSTANDARD LVCMOS18} [get_ports {phy_rx_ctl}] ;# from U2.53
set_property -dict {LOC B20  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_tx_clk}] ;# from U2.40
set_property -dict {LOC D20  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_txd[0]}] ;# from U2.38
set_property -dict {LOC A19  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_txd[1]}] ;# from U2.37
set_property -dict {LOC B19  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_txd[2]}] ;# from U2.36
set_property -dict {LOC E20  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_txd[3]}] ;# from U2.35
set_property -dict {LOC G21  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy_tx_ctl}] ;# from U2.52
#set_property -dict {LOC G19  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy_mdio}] ;# from U2.21
#set_property -dict {LOC A18  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy_mdc}] ;# from U2.20

create_clock -period 8.000 -name {phy_rx_clk} [get_ports {phy_rx_clk}]

#set_false_path -to [get_ports {phy_mdio phy_mdc}]
#set_output_delay 0 [get_ports {phy_mdio phy_mdc}]
#set_false_path -from [get_ports {phy_mdio}]
#set_input_delay 0 [get_ports {phy_mdio}]
