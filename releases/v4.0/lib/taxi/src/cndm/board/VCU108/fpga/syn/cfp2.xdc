# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VCU108 board
# part: xcvu095-ffva2104-2-e

# CFP2 GTY
set_property -dict {LOC J45 } [get_ports {cfp2_rx_p[0]}] ;# MGTYRXP1_130 GTYE3_CHANNEL_X0Y25 / GTYE3_COMMON_X0Y6
set_property -dict {LOC J46 } [get_ports {cfp2_rx_n[0]}] ;# MGTYRXN1_130 GTYE3_CHANNEL_X0Y25 / GTYE3_COMMON_X0Y6
set_property -dict {LOC F42 } [get_ports {cfp2_tx_p[0]}] ;# MGTYTXP1_130 GTYE3_CHANNEL_X0Y25 / GTYE3_COMMON_X0Y6
set_property -dict {LOC F43 } [get_ports {cfp2_tx_n[0]}] ;# MGTYTXN1_130 GTYE3_CHANNEL_X0Y25 / GTYE3_COMMON_X0Y6
set_property -dict {LOC N45 } [get_ports {cfp2_rx_p[1]}] ;# MGTYRXP3_129 GTYE3_CHANNEL_X0Y23 / GTYE3_COMMON_X0Y5
set_property -dict {LOC N46 } [get_ports {cfp2_rx_n[1]}] ;# MGTYRXN3_129 GTYE3_CHANNEL_X0Y23 / GTYE3_COMMON_X0Y5
set_property -dict {LOC K42 } [get_ports {cfp2_tx_p[1]}] ;# MGTYTXP3_129 GTYE3_CHANNEL_X0Y23 / GTYE3_COMMON_X0Y5
set_property -dict {LOC K43 } [get_ports {cfp2_tx_n[1]}] ;# MGTYTXN3_129 GTYE3_CHANNEL_X0Y23 / GTYE3_COMMON_X0Y5
set_property -dict {LOC R45 } [get_ports {cfp2_rx_p[2]}] ;# MGTYRXP2_129 GTYE3_CHANNEL_X0Y22 / GTYE3_COMMON_X0Y5
set_property -dict {LOC R46 } [get_ports {cfp2_rx_n[2]}] ;# MGTYRXN2_129 GTYE3_CHANNEL_X0Y22 / GTYE3_COMMON_X0Y5
set_property -dict {LOC M42 } [get_ports {cfp2_tx_p[2]}] ;# MGTYTXP2_129 GTYE3_CHANNEL_X0Y22 / GTYE3_COMMON_X0Y5
set_property -dict {LOC M43 } [get_ports {cfp2_tx_n[2]}] ;# MGTYTXN2_129 GTYE3_CHANNEL_X0Y22 / GTYE3_COMMON_X0Y5
set_property -dict {LOC L45 } [get_ports {cfp2_rx_p[3]}] ;# MGTYRXP0_130 GTYE3_CHANNEL_X0Y24 / GTYE3_COMMON_X0Y6
set_property -dict {LOC L46 } [get_ports {cfp2_rx_n[3]}] ;# MGTYRXN0_130 GTYE3_CHANNEL_X0Y24 / GTYE3_COMMON_X0Y6
set_property -dict {LOC H42 } [get_ports {cfp2_tx_p[3]}] ;# MGTYTXP0_130 GTYE3_CHANNEL_X0Y24 / GTYE3_COMMON_X0Y6
set_property -dict {LOC H43 } [get_ports {cfp2_tx_n[3]}] ;# MGTYTXN0_130 GTYE3_CHANNEL_X0Y24 / GTYE3_COMMON_X0Y6
set_property -dict {LOC Y43 } [get_ports {cfp2_rx_p[4]}] ;# MGTYRXP3_128 GTYE3_CHANNEL_X0Y19 / GTYE3_COMMON_X0Y4
set_property -dict {LOC Y44 } [get_ports {cfp2_rx_n[4]}] ;# MGTYRXN3_128 GTYE3_CHANNEL_X0Y19 / GTYE3_COMMON_X0Y4
set_property -dict {LOC U40 } [get_ports {cfp2_tx_p[4]}] ;# MGTYTXP3_128 GTYE3_CHANNEL_X0Y19 / GTYE3_COMMON_X0Y4
set_property -dict {LOC U41 } [get_ports {cfp2_tx_n[4]}] ;# MGTYTXN3_128 GTYE3_CHANNEL_X0Y19 / GTYE3_COMMON_X0Y4
set_property -dict {LOC U45 } [get_ports {cfp2_rx_p[5]}] ;# MGTYRXP1_129 GTYE3_CHANNEL_X0Y21 / GTYE3_COMMON_X0Y5
set_property -dict {LOC U46 } [get_ports {cfp2_rx_n[5]}] ;# MGTYRXN1_129 GTYE3_CHANNEL_X0Y21 / GTYE3_COMMON_X0Y5
set_property -dict {LOC P42 } [get_ports {cfp2_tx_p[5]}] ;# MGTYTXP1_129 GTYE3_CHANNEL_X0Y21 / GTYE3_COMMON_X0Y5
set_property -dict {LOC P43 } [get_ports {cfp2_tx_n[5]}] ;# MGTYTXN1_129 GTYE3_CHANNEL_X0Y21 / GTYE3_COMMON_X0Y5
set_property -dict {LOC W45 } [get_ports {cfp2_rx_p[6]}] ;# MGTYRXP0_129 GTYE3_CHANNEL_X0Y20 / GTYE3_COMMON_X0Y5
set_property -dict {LOC W46 } [get_ports {cfp2_rx_n[6]}] ;# MGTYRXN0_129 GTYE3_CHANNEL_X0Y20 / GTYE3_COMMON_X0Y5
set_property -dict {LOC T42 } [get_ports {cfp2_tx_p[6]}] ;# MGTYTXP0_129 GTYE3_CHANNEL_X0Y20 / GTYE3_COMMON_X0Y5
set_property -dict {LOC T43 } [get_ports {cfp2_tx_n[6]}] ;# MGTYTXN0_129 GTYE3_CHANNEL_X0Y20 / GTYE3_COMMON_X0Y5
set_property -dict {LOC AA45} [get_ports {cfp2_rx_p[7]}] ;# MGTYRXP2_128 GTYE3_CHANNEL_X0Y18 / GTYE3_COMMON_X0Y4
set_property -dict {LOC AA46} [get_ports {cfp2_rx_n[7]}] ;# MGTYRXN2_128 GTYE3_CHANNEL_X0Y18 / GTYE3_COMMON_X0Y4
set_property -dict {LOC W40 } [get_ports {cfp2_tx_p[7]}] ;# MGTYTXP2_128 GTYE3_CHANNEL_X0Y18 / GTYE3_COMMON_X0Y4
set_property -dict {LOC W41 } [get_ports {cfp2_tx_n[7]}] ;# MGTYTXN2_128 GTYE3_CHANNEL_X0Y18 / GTYE3_COMMON_X0Y4
set_property -dict {LOC AB43} [get_ports {cfp2_rx_p[8]}] ;# MGTYRXP1_128 GTYE3_CHANNEL_X0Y17 / GTYE3_COMMON_X0Y4
set_property -dict {LOC AB44} [get_ports {cfp2_rx_n[8]}] ;# MGTYRXN1_128 GTYE3_CHANNEL_X0Y17 / GTYE3_COMMON_X0Y4
set_property -dict {LOC AA40} [get_ports {cfp2_tx_p[8]}] ;# MGTYTXP1_128 GTYE3_CHANNEL_X0Y17 / GTYE3_COMMON_X0Y4
set_property -dict {LOC AA41} [get_ports {cfp2_tx_n[8]}] ;# MGTYTXN1_128 GTYE3_CHANNEL_X0Y17 / GTYE3_COMMON_X0Y4
set_property -dict {LOC AC45} [get_ports {cfp2_rx_p[9]}] ;# MGTYRXP0_128 GTYE3_CHANNEL_X0Y16 / GTYE3_COMMON_X0Y4
set_property -dict {LOC AC46} [get_ports {cfp2_rx_n[9]}] ;# MGTYRXN0_128 GTYE3_CHANNEL_X0Y16 / GTYE3_COMMON_X0Y4
set_property -dict {LOC AC40} [get_ports {cfp2_tx_p[9]}] ;# MGTYTXP0_128 GTYE3_CHANNEL_X0Y16 / GTYE3_COMMON_X0Y4
set_property -dict {LOC AC41} [get_ports {cfp2_tx_n[9]}] ;# MGTYTXN0_128 GTYE3_CHANNEL_X0Y16 / GTYE3_COMMON_X0Y4
set_property -dict {LOC V38 } [get_ports cfp2_mgt_refclk_0_p] ;# MGTREFCLK0P_129 from U32 SI570 via U104 SI53340
set_property -dict {LOC V39 } [get_ports cfp2_mgt_refclk_0_n] ;# MGTREFCLK0N_129 from U32 SI570 via U104 SI53340
set_property -dict {LOC T38 } [get_ports cfp2_mgt_refclk_1_p] ;# MGTREFCLK1P_129 from U57 CKOUT1 SI5328
set_property -dict {LOC T39 } [get_ports cfp2_mgt_refclk_1_n] ;# MGTREFCLK1N_129 from U57 CKOUT1 SI5328
set_property -dict {LOC BA21 IOSTANDARD LVCMOS18} [get_ports {cfp2_prg_cntl[0]}]
set_property -dict {LOC AY24 IOSTANDARD LVCMOS18} [get_ports {cfp2_prg_cntl[1]}]
set_property -dict {LOC AY23 IOSTANDARD LVCMOS18} [get_ports {cfp2_prg_cntl[2]}]
set_property -dict {LOC BB24 IOSTANDARD LVCMOS18} [get_ports {cfp2_prg_alrm[0]}]
set_property -dict {LOC BB23 IOSTANDARD LVCMOS18} [get_ports {cfp2_prg_alrm[1]}]
set_property -dict {LOC BB22 IOSTANDARD LVCMOS18} [get_ports {cfp2_prg_alrm[2]}]
set_property -dict {LOC BA22 IOSTANDARD LVCMOS18} [get_ports {cfp2_prtadr[0]}]
set_property -dict {LOC AW25 IOSTANDARD LVCMOS18} [get_ports {cfp2_prtadr[1]}]
set_property -dict {LOC AY25 IOSTANDARD LVCMOS18} [get_ports {cfp2_prtadr[2]}]
set_property -dict {LOC AY22 IOSTANDARD LVCMOS18} [get_ports cfp2_tx_dis]
set_property -dict {LOC BB21 IOSTANDARD LVCMOS18} [get_ports cfp2_rx_los]
set_property -dict {LOC BC21 IOSTANDARD LVCMOS18} [get_ports cfp2_mod_lopwr]
set_property -dict {LOC BD21 IOSTANDARD LVCMOS18} [get_ports cfp2_mod_rstn]
set_property -dict {LOC BA25 IOSTANDARD LVCMOS18} [get_ports cfp2_mod_abs]
set_property -dict {LOC BA24 IOSTANDARD LVCMOS18} [get_ports cfp2_glb_alrmn]
set_property -dict {LOC BE22 IOSTANDARD LVCMOS18} [get_ports cfp2_mdc]
set_property -dict {LOC BF22 IOSTANDARD LVCMOS18} [get_ports cfp2_mdio]

# 156.25 MHz MGT reference clock
create_clock -period 6.4 -name cfp2_mgt_refclk [get_ports cfp2_mgt_refclk_0_p]
create_clock -period 6.4 -name cfp2_mgt_refclk [get_ports cfp2_mgt_refclk_1_p]
