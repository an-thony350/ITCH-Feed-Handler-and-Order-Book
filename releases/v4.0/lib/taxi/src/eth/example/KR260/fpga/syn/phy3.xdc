# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx KR260 board
# part: xck26-sfvc784-2LV-c

# PHY3
set_property -dict {LOC K4   IOSTANDARD LVCMOS18} [get_ports {phy3_rx_clk}] ;# from U80.32 RX_CLK / HPB09P_CLK som240_2_c11
set_property -dict {LOC H1   IOSTANDARD LVCMOS18} [get_ports {phy3_rxd[0]}] ;# from U80.33 RX_D0_SGMII_COP / HPB06N som240_2_a21
set_property -dict {LOC K2   IOSTANDARD LVCMOS18} [get_ports {phy3_rxd[1]}] ;# from U80.34 RX_D1_SGMII_CON / HPB07P som240_2_b15
set_property -dict {LOC J2   IOSTANDARD LVCMOS18} [get_ports {phy3_rxd[2]}] ;# from U80.35 RX_D2_SGMII_SOP / HPB07N som240_2_b16
set_property -dict {LOC H4   IOSTANDARD LVCMOS18} [get_ports {phy3_rxd[3]}] ;# from U80.36 RX_D3_SGMII_SON / HPB08P som240_2_a14
set_property -dict {LOC H3   IOSTANDARD LVCMOS18} [get_ports {phy3_rx_ctl}] ;# from U80.38 RX_CTRL HBP08N som240_2_a15
set_property -dict {LOC J1   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_tx_clk}] ;# from U80.29 GTX_CLK / HPB06P_CLK som240_2_a20
set_property -dict {LOC U9   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_txd[0]}] ;# from U80.28 TX_D0_SGMII_SIN / HPB01P som240_2_d12
set_property -dict {LOC V9   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_txd[1]}] ;# from U80.27 TX_D1_SGMII_SIP / HPB01N som240_2_d13
set_property -dict {LOC U8   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_txd[2]}] ;# from U80.26 TX_D2 / HPB02P som240_2_c17
set_property -dict {LOC V8   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_txd[3]}] ;# from U80.25 TX_D3 / HPB02N som240_2_c18
set_property -dict {LOC Y8   IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {phy3_tx_ctl}] ;# from U80.37 TX_CTRL / HPB00_CCN som240_2_d16
set_property -dict {LOC K1   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy3_reset_n}] ;# from U80.43 RESET_B / HPB05_CCN som240_2_b19
#set_property -dict {LOC T8   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy3_mdio}] ;# from U80.17 MDIO / HPB03N som240_2_b25
#set_property -dict {LOC R8   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {phy3_mdc}] ;# from U80.16 MDC / HPB03P som240_2_b24
#set_property -dict {LOC R7   IOSTANDARD LVCMOS18} [get_ports {phy3_led[0]}] ;# from U80.47 LED_0 / HPB04P som240_2_d21
#set_property -dict {LOC T7   IOSTANDARD LVCMOS18} [get_ports {phy3_led[1]}] ;# from U80.46 LED_1 / HPB04N som240_2_d22
#set_property -dict {LOC L1   IOSTANDARD LVCMOS18} [get_ports {phy3_led[2]}] ;# from U80.45 LED_2 / HPB05_CCP som240_2_b18

create_clock -period 8.000 -name {phy3_rx_clk} [get_ports {phy3_rx_clk}]

set_false_path -to [get_ports {phy3_reset_n}]
set_output_delay 0 [get_ports {phy3_reset_n}]
# set_false_path -from [get_ports {phy3_led[*]}]
# set_input_delay 0 [get_ports {phy3_led[*]}]

#set_false_path -to [get_ports {phy3_mdio phy3_mdc}]
#set_output_delay 0 [get_ports {phy3_mdio phy3_mdc}]
#set_false_path -from [get_ports {phy3_mdio}]
#set_input_delay 0 [get_ports {phy3_mdio}]
