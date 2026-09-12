# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU106 board
# part: xczu7ev-ffvc1156-2-e

# FMC HPC1 J4
set_property -dict {LOC B18  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[0]}]  ;# J4.G9  LA00_P_CC
set_property -dict {LOC B19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[0]}]  ;# J4.G10 LA00_N_CC
set_property -dict {LOC E24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[1]}]  ;# J4.D8  LA01_P_CC
set_property -dict {LOC D24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[1]}]  ;# J4.D9  LA01_N_CC
set_property -dict {LOC K22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[2]}]  ;# J4.H7  LA02_P
set_property -dict {LOC K23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[2]}]  ;# J4.H8  LA02_N
set_property -dict {LOC J21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[3]}]  ;# J4.G12 LA03_P
set_property -dict {LOC J22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[3]}]  ;# J4.G13 LA03_N
set_property -dict {LOC J24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[4]}]  ;# J4.H10 LA04_P
set_property -dict {LOC H24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[4]}]  ;# J4.H11 LA04_N
set_property -dict {LOC G25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[5]}]  ;# J4.D11 LA05_P
set_property -dict {LOC G26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[5]}]  ;# J4.D12 LA05_N
set_property -dict {LOC H21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[6]}]  ;# J4.C10 LA06_P
set_property -dict {LOC H22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[6]}]  ;# J4.C11 LA06_N
set_property -dict {LOC D22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[7]}]  ;# J4.H13 LA07_P
set_property -dict {LOC C23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[7]}]  ;# J4.H14 LA07_N
set_property -dict {LOC J25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[8]}]  ;# J4.G12 LA08_P
set_property -dict {LOC H26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[8]}]  ;# J4.G13 LA08_N
set_property -dict {LOC G20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[9]}]  ;# J4.D14 LA09_P
set_property -dict {LOC F20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[9]}]  ;# J4.D15 LA09_N
set_property -dict {LOC F22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[10]}] ;# J4.C14 LA10_P
set_property -dict {LOC E22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[10]}] ;# J4.C15 LA10_N
set_property -dict {LOC A20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[11]}] ;# J4.H16 LA11_P
set_property -dict {LOC A21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[11]}] ;# J4.H17 LA11_N
set_property -dict {LOC E19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[12]}] ;# J4.G15 LA12_P
set_property -dict {LOC D19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[12]}] ;# J4.G16 LA12_N
set_property -dict {LOC C21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[13]}] ;# J4.D17 LA13_P
set_property -dict {LOC C22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[13]}] ;# J4.D18 LA13_N
set_property -dict {LOC D20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[14]}] ;# J4.C18 LA14_P
set_property -dict {LOC D21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[14]}] ;# J4.C19 LA14_N
set_property -dict {LOC A18  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[15]}] ;# J4.H19 LA15_P
set_property -dict {LOC A19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[15]}] ;# J4.H20 LA15_N
set_property -dict {LOC C18  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_p[16]}] ;# J4.G18 LA16_P
set_property -dict {LOC C19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_la_n[16]}] ;# J4.G19 LA16_N

set_property -dict {LOC F23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_clk0_m2c_p}] ;# J4.H4 CLK0_M2C_P
set_property -dict {LOC E23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmc_hpc1_clk0_m2c_n}] ;# J4.H5 CLK0_M2C_N

set_property -dict {LOC AJ6 } [get_ports {fmc_hpc1_dp_c2m_p[0]}] ;# MGTHTXP3_223 GTHE4_CHANNEL_X0Y3 / GTHE4_COMMON_X0Y0 from J4.C2  DP0_C2M_P
set_property -dict {LOC AJ5 } [get_ports {fmc_hpc1_dp_c2m_n[0]}] ;# MGTHTXN3_223 GTHE4_CHANNEL_X0Y3 / GTHE4_COMMON_X0Y0 from J4.C3  DP0_C2M_N
set_property -dict {LOC AK4 } [get_ports {fmc_hpc1_dp_m2c_p[0]}] ;# MGTHRXP3_223 GTHE4_CHANNEL_X0Y3 / GTHE4_COMMON_X0Y0 from J4.C6  DP0_M2C_P
set_property -dict {LOC AK3 } [get_ports {fmc_hpc1_dp_m2c_n[0]}] ;# MGTHRXN3_223 GTHE4_CHANNEL_X0Y3 / GTHE4_COMMON_X0Y0 from J4.C7  DP0_M2C_N
set_property -dict {LOC Y8  } [get_ports {fmc_hpc1_mgt_refclk_p}] ;# MGTREFCLK0P_225 from J4.D4 GBTCLK0_M2C_P
set_property -dict {LOC Y7  } [get_ports {fmc_hpc1_mgt_refclk_n}] ;# MGTREFCLK0N_225 from J4.D5 GBTCLK0_M2C_N

# reference clock
create_clock -period 6.400 -name fmc_hpc1_mgt_refclk [get_ports {fmc_hpc1_mgt_refclk_p}]
