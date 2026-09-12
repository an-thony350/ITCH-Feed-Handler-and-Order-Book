# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Digilent Arty board
# part: xc7a35t-csg324-1

# Ethernet MII PHY
set_property -dict {LOC F15  IOSTANDARD LVCMOS33} [get_ports phy_rx_clk]
set_property -dict {LOC D18  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[0]}]
set_property -dict {LOC E17  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[1]}]
set_property -dict {LOC E18  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[2]}]
set_property -dict {LOC G17  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[3]}]
set_property -dict {LOC G16  IOSTANDARD LVCMOS33} [get_ports phy_rx_dv]
set_property -dict {LOC C17  IOSTANDARD LVCMOS33} [get_ports phy_rx_er]
set_property -dict {LOC H16  IOSTANDARD LVCMOS33} [get_ports phy_tx_clk]
set_property -dict {LOC H14  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {phy_txd[0]}]
set_property -dict {LOC J14  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {phy_txd[1]}]
set_property -dict {LOC J13  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {phy_txd[2]}]
set_property -dict {LOC H17  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {phy_txd[3]}]
set_property -dict {LOC H15  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports phy_tx_en]
set_property -dict {LOC D17  IOSTANDARD LVCMOS33} [get_ports phy_col]
set_property -dict {LOC G14  IOSTANDARD LVCMOS33} [get_ports phy_crs]
set_property -dict {LOC G18  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_ref_clk]
set_property -dict {LOC C16  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_reset_n]
#set_property -dict {LOC K13  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_mdio]
#set_property -dict {LOC F16  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_mdc]

create_clock -period 40.000 -name phy_rx_clk [get_ports phy_rx_clk]
create_clock -period 40.000 -name phy_tx_clk [get_ports phy_tx_clk]

set_false_path -to [get_ports {phy_ref_clk phy_reset_n}]
set_output_delay 0 [get_ports {phy_ref_clk phy_reset_n}]

#set_false_path -to [get_ports {phy_mdio phy_mdc}]
#set_output_delay 0 [get_ports {phy_mdio phy_mdc}]
#set_false_path -from [get_ports {phy_mdio}]
#set_input_delay 0 [get_ports {phy_mdio}]
