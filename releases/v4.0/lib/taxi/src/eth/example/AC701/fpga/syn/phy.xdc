# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx AC701 board
# part: xc7a200tfbg676-2

# Gigabit Ethernet RGMII PHY
set_property -dict {LOC U21  IOSTANDARD LVCMOS18} [get_ports phy_rx_clk] ;# from U12.53 RX_CLK
set_property -dict {LOC U17  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[0]}] ;# from U12.50 RXD0
set_property -dict {LOC V17  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[1]}] ;# from U12.51 RXD1
set_property -dict {LOC V16  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[2]}] ;# from U12.54 RXD2
set_property -dict {LOC V14  IOSTANDARD LVCMOS18} [get_ports {phy_rxd[3]}] ;# from U12.55 RXD3
set_property -dict {LOC U14  IOSTANDARD LVCMOS18} [get_ports phy_rx_ctl] ;# from U12.49 RX_CTRL
set_property -dict {LOC U22  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 16} [get_ports phy_tx_clk] ;# from U12.60 TX_CLK
set_property -dict {LOC U16  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 16} [get_ports {phy_txd[0]}] ;# from U12.58 TXD0
set_property -dict {LOC U15  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 16} [get_ports {phy_txd[1]}] ;# from U12.59 TXD1
set_property -dict {LOC T18  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 16} [get_ports {phy_txd[2]}] ;# from U12.61 TXD2
set_property -dict {LOC T17  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 16} [get_ports {phy_txd[3]}] ;# from U12.62 TXD3
set_property -dict {LOC T15  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 16} [get_ports phy_tx_ctl] ;# from U12.63 TX_CTRL
set_property -dict {LOC V18  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports phy_reset_n] ;# from U12.10 RESET_B
#set_property -dict {LOC T14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports phy_mdio] ;# from U12.45 MDIO
#set_property -dict {LOC W18  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports phy_mdc] ;# from U12.48 MDC

create_clock -period 8.000 -name phy_rx_clk [get_ports phy_rx_clk]

set_false_path -to [get_ports {phy_reset_n}]
set_output_delay 0 [get_ports {phy_reset_n}]

#set_false_path -to [get_ports {phy_mdio phy_mdc}]
#set_output_delay 0 [get_ports {phy_mdio phy_mdc}]
#set_false_path -from [get_ports {phy_mdio}]
#set_input_delay 0 [get_ports {phy_mdio}]
