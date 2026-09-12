# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx KR260 board
# part: xck26-sfvc784-2LV-c

# PHY2
set_property -dict {LOC D4   IOSTANDARD LVCMOS18} [get_ports {phy2_rx_clk}] ;# from U79.32 RX_CLK / HPA09P_CLK som240_1_d10
set_property -dict {LOC A1   IOSTANDARD LVCMOS18} [get_ports {phy2_rxd[0]}] ;# from U79.33 RX_D0_SGMII_COP / HPA06N som240_1_a4
set_property -dict {LOC B3   IOSTANDARD LVCMOS18} [get_ports {phy2_rxd[1]}] ;# from U79.34 RX_D1_SGMII_CON / HPA07P som240_1_b7
set_property -dict {LOC A3   IOSTANDARD LVCMOS18} [get_ports {phy2_rxd[2]}] ;# from U79.35 RX_D2_SGMII_SOP / HPA07N som240_1_b8
set_property -dict {LOC B4   IOSTANDARD LVCMOS18} [get_ports {phy2_rxd[3]}] ;# from U79.36 RX_D3_SGMII_SON / HPA08P som240_1_c9
set_property -dict {LOC A4   IOSTANDARD LVCMOS18} [get_ports {phy2_rx_ctl}] ;# from U79.38 RX_CTRL / HPA08N som240_1_c10
set_property -dict {LOC A2   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_tx_clk}] ;# from U79.29 GTX_CLK / HPA06P_CLK som240_1_a3
set_property -dict {LOC E1   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_txd[0]}] ;# from U79.28 TX_D0_SGMII_SIN / HPA01P som240_1_d7
set_property -dict {LOC D1   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_txd[1]}] ;# from U79.27 TX_D1_SGMII_SIP / HPA01N som240_1_d8
set_property -dict {LOC F2   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_txd[2]}] ;# from U79.26 TX_D2 / HPA02P som240_1_d4
set_property -dict {LOC E2   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_txd[3]}] ;# from U79.25 TX_D3 / HPA02N som240_1_d5
set_property -dict {LOC F1   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy2_tx_ctl}] ;# from U79.37 TX_CTRL / HPA00_CCN som240_1_c4
set_property -dict {LOC B1   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy2_reset_n}] ;# from U79.43 RESET_B / HPA05_CCN som240_1_b2
#set_property -dict {LOC F3   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy2_mdio}] ;# from U79.17 MDIO / HPA03N som240_1_c7
#set_property -dict {LOC G3   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy2_mdc}] ;# from U79.16 MDC / HPA03P som240_1_c6
#set_property -dict {LOC E4   IOSTANDARD LVCMOS18} [get_ports {phy2_led[0]}] ;# from U79.47 LED_0 / HPA04P som240_1_b4
#set_property -dict {LOC E3   IOSTANDARD LVCMOS18} [get_ports {phy2_led[1]}] ;# from U79.46 LED_1 / HPA04N som240_1_b5
#set_property -dict {LOC C1   IOSTANDARD LVCMOS18} [get_ports {phy2_led[2]}] ;# from U79.45 LED_2 / HPA05_CCP som240_1_b1

create_clock -period 8.000 -name {phy2_rx_clk} [get_ports {phy2_rx_clk}]

set_false_path -to [get_ports {phy2_reset_n}]
set_output_delay 0 [get_ports {phy2_reset_n}]
# set_false_path -from [get_ports {phy2_led[*]}]
# set_input_delay 0 [get_ports {phy2_led[*]}]

#set_false_path -to [get_ports {phy2_mdio phy2_mdc}]
#set_output_delay 0 [get_ports {phy2_mdio phy2_mdc}]
#set_false_path -from [get_ports {phy2_mdio}]
#set_input_delay 0 [get_ports {phy2_mdio}]
