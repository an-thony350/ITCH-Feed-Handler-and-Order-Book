# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx AC701 board
# part: xc7a200tfbg676-2

# GTX for Ethernet
set_property -dict {LOC AC12} [get_ports sfp_rx_p] ;# MGTXRXP0_213 GTPE2_CHANNEL_X0Y0 / GTPE2_COMMON_X0Y0 from P3.13
set_property -dict {LOC AD12} [get_ports sfp_rx_n] ;# MGTXRXN0_213 GTPE2_CHANNEL_X0Y0 / GTPE2_COMMON_X0Y0 from P3.12
set_property -dict {LOC AC10} [get_ports sfp_tx_p] ;# MGTXTXP0_213 GTPE2_CHANNEL_X0Y0 / GTPE2_COMMON_X0Y0 from P3.18
set_property -dict {LOC AD10} [get_ports sfp_tx_n] ;# MGTXTXN0_213 GTPE2_CHANNEL_X0Y0 / GTPE2_COMMON_X0Y0 from P3.19
set_property -dict {LOC AA13} [get_ports sfp_mgt_refclk_0_p] ;# MGTREFCLK0P_213 from U3.10
set_property -dict {LOC AB13} [get_ports sfp_mgt_refclk_0_n] ;# MGTREFCLK0N_213 from U3.11
#set_property -dict {LOC AA11} [get_ports sfp_mgt_refclk_1_p] ;# MGTREFCLK1P_213 from U4.10
#set_property -dict {LOC AB11} [get_ports sfp_mgt_refclk_1_n] ;# MGTREFCLK1N_213 from U4.11
#set_property -dict {LOC D23  IOSTANDARD LVDS_25} [get_ports sfp_recclk_p] ;# to Si5324 U24.16 CKIN1_P
#set_property -dict {LOC D24  IOSTANDARD LVDS_25} [get_ports sfp_recclk_n] ;# to Si5324 U24.17 CKIN1_N

#set_property -dict {LOC B24  IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports si5324_rst]
#set_property -dict {LOC M19  IOSTANDARD LVCMOS25 PULLUP true} [get_ports si5324_int]

set_property -dict {LOC R18 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {sfp_tx_disable}]
set_property -dict {LOC R23 IOSTANDARD LVCMOS33} [get_ports {sfp_rx_los}]

# U3 clock mux for SFP_MGT_CLK_0
# 2'b00 = EPHYCLK_Q0 (125 MHz)
# 2'b01 = SI5324_OUT0
# 2'b10 = FMC1_HPC_GBTCLK0
# 2'b00 = NC
set_property -dict {LOC B26  IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports "sfp_mgt_clk_sel[0]"]
set_property -dict {LOC C24  IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports "sfp_mgt_clk_sel[1]"]

# 125 MHz MGT reference clock (SGMII, 1000BASE-X)
create_clock -period 8.000 -name sfp_mgt_refclk_0 [get_ports sfp_mgt_refclk_0_p]

# U4 clock mux for SFP_MGT_CLK_1
# 2'b00 = SMA_MGT_REFCLK
# 2'b01 = SI5324_OUT1
# 2'b10 = FMC1_HPC_GBTCLK1
# 2'b00 = NC
#set_property -dict {LOC A24  IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports "pcie_mgt_clk_sel[0]"]
#set_property -dict {LOC C26  IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports "pcie_mgt_clk_sel[1]"]

# 125 MHz MGT reference clock (SGMII, 1000BASE-X)
#create_clock -period 6.400 -name sgmii_mgt_refclk_1 [get_ports sfp_mgt_refclk_1_p]

#set_false_path -to [get_ports {si5324_rst}]
#set_output_delay 0 [get_ports {si5324_rst}]
#set_false_path -from [get_ports {si5324_int}]
#set_input_delay 0 [get_ports {si5324_int}]

set_false_path -to [get_ports {sfp_tx_disable}]
set_output_delay 0 [get_ports {sfp_tx_disable}]
