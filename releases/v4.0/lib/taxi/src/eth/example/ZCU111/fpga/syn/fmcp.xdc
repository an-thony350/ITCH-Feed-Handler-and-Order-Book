# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU111 board
# part: xczu28dr-ffvg1517-2-e

# FMC+ HSPC J26
set_property -dict {LOC AP9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[0]}]  ;# J26.G9  LA00_P_CC
set_property -dict {LOC AR9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[0]}]  ;# J26.G10 LA00_N_CC
set_property -dict {LOC AP8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[1]}]  ;# J26.D8  LA01_P_CC
set_property -dict {LOC AR8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[1]}]  ;# J26.D9  LA01_N_CC
set_property -dict {LOC AH13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[2]}]  ;# J26.H7  LA02_P
set_property -dict {LOC AJ13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[2]}]  ;# J26.H8  LA02_N
set_property -dict {LOC AJ12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[3]}]  ;# J26.G12 LA03_P
set_property -dict {LOC AK12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[3]}]  ;# J26.G13 LA03_N
set_property -dict {LOC AG12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[4]}]  ;# J26.H10 LA04_P
set_property -dict {LOC AH12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[4]}]  ;# J26.H11 LA04_N
set_property -dict {LOC AM8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[5]}]  ;# J26.D11 LA05_P
set_property -dict {LOC AM7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[5]}]  ;# J26.D12 LA05_N
set_property -dict {LOC AL8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[6]}]  ;# J26.C10 LA06_P
set_property -dict {LOC AL7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[6]}]  ;# J26.C11 LA06_N
set_property -dict {LOC AK13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[7]}]  ;# J26.H13 LA07_P
set_property -dict {LOC AL12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[7]}]  ;# J26.H14 LA07_N
set_property -dict {LOC AL9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[8]}]  ;# J26.G12 LA08_P
set_property -dict {LOC AM9  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[8]}]  ;# J26.G13 LA08_N
set_property -dict {LOC AN8  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[9]}]  ;# J26.D14 LA09_P
set_property -dict {LOC AN7  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[9]}]  ;# J26.D15 LA09_N
set_property -dict {LOC AM12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[10]}] ;# J26.C14 LA10_P
set_property -dict {LOC AN12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[10]}] ;# J26.C15 LA10_N
set_property -dict {LOC AT10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[11]}] ;# J26.H16 LA11_P
set_property -dict {LOC AU10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[11]}] ;# J26.H17 LA11_N
set_property -dict {LOC AL10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[12]}] ;# J26.G15 LA12_P
set_property -dict {LOC AM10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[12]}] ;# J26.G16 LA12_N
set_property -dict {LOC AM13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[13]}] ;# J26.D17 LA13_P
set_property -dict {LOC AN13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[13]}] ;# J26.D18 LA13_N
set_property -dict {LOC AL14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[14]}] ;# J26.C18 LA14_P
set_property -dict {LOC AM14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[14]}] ;# J26.C19 LA14_N
set_property -dict {LOC AJ14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[15]}] ;# J26.H19 LA15_P
set_property -dict {LOC AK14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[15]}] ;# J26.H20 LA15_N
set_property -dict {LOC AR12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[16]}] ;# J26.G18 LA16_P
set_property -dict {LOC AR11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[16]}] ;# J26.G19 LA16_N
set_property -dict {LOC AN21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[17]}] ;# J26.D20 LA17_P_CC
set_property -dict {LOC AP21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[17]}] ;# J26.D21 LA17_N_CC
set_property -dict {LOC AM20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[18]}] ;# J26.C22 LA18_P_CC
set_property -dict {LOC AN20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[18]}] ;# J26.C23 LA18_N_CC
set_property -dict {LOC AU20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[19]}] ;# J26.H22 LA19_P
set_property -dict {LOC AU19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[19]}] ;# J26.H23 LA19_N
set_property -dict {LOC AR17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[20]}] ;# J26.G21 LA20_P
set_property -dict {LOC AT17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[20]}] ;# J26.G22 LA20_N
set_property -dict {LOC AL19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[21]}] ;# J26.H25 LA21_P
set_property -dict {LOC AM19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[21]}] ;# J26.H26 LA21_N
set_property -dict {LOC AR19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[22]}] ;# J26.G24 LA22_P
set_property -dict {LOC AT19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[22]}] ;# J26.G25 LA22_N
set_property -dict {LOC AM18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[23]}] ;# J26.D23 LA23_P
set_property -dict {LOC AN18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[23]}] ;# J26.D24 LA23_N
set_property -dict {LOC AL22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[24]}] ;# J26.H28 LA24_P
set_property -dict {LOC AM22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[24]}] ;# J26.H29 LA24_N
set_property -dict {LOC AL21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[25]}] ;# J26.G27 LA25_P
set_property -dict {LOC AL20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[25]}] ;# J26.G28 LA25_N
set_property -dict {LOC AR22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[26]}] ;# J26.D26 LA26_P
set_property -dict {LOC AT22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[26]}] ;# J26.D27 LA26_N
set_property -dict {LOC AR21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[27]}] ;# J26.C26 LA27_P
set_property -dict {LOC AT21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[27]}] ;# J26.C27 LA27_N
set_property -dict {LOC AJ18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[28]}] ;# J26.H31 LA28_P
set_property -dict {LOC AK18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[28]}] ;# J26.H32 LA28_N
set_property -dict {LOC AK22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[29]}] ;# J26.G30 LA29_P
set_property -dict {LOC AK21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[29]}] ;# J26.G31 LA29_N
set_property -dict {LOC AG20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[30]}] ;# J26.H34 LA30_P
set_property -dict {LOC AH20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[30]}] ;# J26.H35 LA30_N
set_property -dict {LOC AJ20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[31]}] ;# J26.G33 LA31_P
set_property -dict {LOC AJ19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[31]}] ;# J26.G34 LA31_N
set_property -dict {LOC AF20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[32]}] ;# J26.H37 LA32_P
set_property -dict {LOC AF19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[32]}] ;# J26.H38 LA32_N
set_property -dict {LOC AG18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_p[33]}] ;# J26.G36 LA33_P
set_property -dict {LOC AH18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_la_n[33]}] ;# J26.G37 LA33_N

set_property -dict {LOC AN10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_clk0_m2c_p}] ;# J26.H4 CLK0_M2C_P
set_property -dict {LOC AP10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_clk0_m2c_n}] ;# J26.H5 CLK0_M2C_N
set_property -dict {LOC AP20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_clk1_m2c_p}] ;# J26.G2 CLK1_M2C_P
set_property -dict {LOC AP19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_clk1_m2c_n}] ;# J26.G3 CLK1_M2C_N

set_property -dict {LOC AV11 IOSTANDARD LVDS                       } [get_ports {fmcp_hspc_refclk_c2m_p}] ;# J26.L20 REFCLK_C2M_P
set_property -dict {LOC AW11 IOSTANDARD LVDS                       } [get_ports {fmcp_hspc_refclk_c2m_n}] ;# J26.L21 REFCLK_C2M_N
set_property -dict {LOC AN11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_refclk_m2c_p}] ;# J26.L24 REFCLK_M2C_P
set_property -dict {LOC AP11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_refclk_m2c_n}] ;# J26.L25 REFCLK_M2C_N
set_property -dict {LOC AT11 IOSTANDARD LVDS                       } [get_ports {fmcp_hspc_sync_c2m_p}]   ;# J26.L16 SYNC_C2M_P
set_property -dict {LOC AT12 IOSTANDARD LVDS                       } [get_ports {fmcp_hspc_sync_c2m_n}]   ;# J26.L17 SYNC_C2M_N
set_property -dict {LOC AV12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_sync_m2c_p}]   ;# J26.L28 SYNC_M2C_P
set_property -dict {LOC AU12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {fmcp_hspc_sync_m2c_n}]   ;# J26.L29 SYNC_M2C_N

set_property -dict {LOC P35 } [get_ports {fmcp_hspc_dp_c2m_p[0]}]  ;# MGTYTXP0_129 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2 from J26.C2  DP0_C2M_P
set_property -dict {LOC P36 } [get_ports {fmcp_hspc_dp_c2m_n[0]}]  ;# MGTYTXN0_129 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2 from J26.C3  DP0_C2M_N
set_property -dict {LOC N38 } [get_ports {fmcp_hspc_dp_m2c_p[0]}]  ;# MGTYRXP0_129 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2 from J26.C6  DP0_M2C_P
set_property -dict {LOC N39 } [get_ports {fmcp_hspc_dp_m2c_n[0]}]  ;# MGTYRXN0_129 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2 from J26.C7  DP0_M2C_N
set_property -dict {LOC N33 } [get_ports {fmcp_hspc_dp_c2m_p[1]}]  ;# MGTYTXP1_129 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2 from J26.A22 DP1_C2M_P
set_property -dict {LOC N34 } [get_ports {fmcp_hspc_dp_c2m_n[1]}]  ;# MGTYTXN1_129 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2 from J26.A23 DP1_C2M_N
set_property -dict {LOC M36 } [get_ports {fmcp_hspc_dp_m2c_p[1]}]  ;# MGTYRXP1_129 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2 from J26.A2  DP1_M2C_P
set_property -dict {LOC M37 } [get_ports {fmcp_hspc_dp_m2c_n[1]}]  ;# MGTYRXN1_129 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2 from J26.A3  DP1_M2C_N
set_property -dict {LOC L33 } [get_ports {fmcp_hspc_dp_c2m_p[2]}]  ;# MGTYTXP2_129 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2 from J26.A26 DP2_C2M_P
set_property -dict {LOC L34 } [get_ports {fmcp_hspc_dp_c2m_n[2]}]  ;# MGTYTXN2_129 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2 from J26.A27 DP2_C2M_N
set_property -dict {LOC L38 } [get_ports {fmcp_hspc_dp_m2c_p[2]}]  ;# MGTYRXP2_129 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2 from J26.A6  DP2_M2C_P
set_property -dict {LOC L39 } [get_ports {fmcp_hspc_dp_m2c_n[2]}]  ;# MGTYRXN2_129 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2 from J26.A7  DP2_M2C_N
set_property -dict {LOC J33 } [get_ports {fmcp_hspc_dp_c2m_p[3]}]  ;# MGTYTXP3_129 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2 from J26.A30 DP3_C2M_P
set_property -dict {LOC J34 } [get_ports {fmcp_hspc_dp_c2m_n[3]}]  ;# MGTYTXN3_129 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2 from J26.A31 DP3_C2M_N
set_property -dict {LOC K36 } [get_ports {fmcp_hspc_dp_m2c_p[3]}]  ;# MGTYRXP3_129 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2 from J26.A10 DP3_M2C_P
set_property -dict {LOC K37 } [get_ports {fmcp_hspc_dp_m2c_n[3]}]  ;# MGTYRXN3_129 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2 from J26.A11 DP3_M2C_N
set_property -dict {LOC W33 } [get_ports {fmcp_hspc_mgt_refclk_0_0_p}] ;# MGTREFCLK0P_129 from J26.D4 GBTCLK0_M2C_P
set_property -dict {LOC W34 } [get_ports {fmcp_hspc_mgt_refclk_0_0_n}] ;# MGTREFCLK0N_129 from J26.D5 GBTCLK0_M2C_N
set_property -dict {LOC V31 } [get_ports {fmcp_hspc_mgt_refclk_0_1_p}] ;# MGTREFCLK1P_129 from U49 SI570
set_property -dict {LOC V32 } [get_ports {fmcp_hspc_mgt_refclk_0_1_n}] ;# MGTREFCLK1N_129 from U49 SI570

# reference clock
create_clock -period 6.400 -name fmcp_hspc_mgt_refclk_0_0 [get_ports {fmcp_hspc_mgt_refclk_0_0_p}]
create_clock -period 6.400 -name fmcp_hspc_mgt_refclk_0_1 [get_ports {fmcp_hspc_mgt_refclk_0_1_p}]

set_property -dict {LOC H31 } [get_ports {fmcp_hspc_dp_c2m_p[4]}]  ;# MGTYTXP0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7 from J26.A34 DP4_C2M_P
set_property -dict {LOC H32 } [get_ports {fmcp_hspc_dp_c2m_n[4]}]  ;# MGTYTXN0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7 from J26.A35 DP4_C2M_N
set_property -dict {LOC J38 } [get_ports {fmcp_hspc_dp_m2c_p[4]}]  ;# MGTYRXP0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7 from J26.A14 DP4_M2C_P
set_property -dict {LOC J39 } [get_ports {fmcp_hspc_dp_m2c_n[4]}]  ;# MGTYRXN0_130 GTYE4_CHANNEL_X0Y28 / GTYE4_COMMON_X0Y7 from J26.A15 DP4_M2C_N
set_property -dict {LOC G33 } [get_ports {fmcp_hspc_dp_c2m_p[5]}]  ;# MGTYTXP1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7 from J26.A38 DP5_C2M_P
set_property -dict {LOC G34 } [get_ports {fmcp_hspc_dp_c2m_n[5]}]  ;# MGTYTXN1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7 from J26.A39 DP5_C2M_N
set_property -dict {LOC H36 } [get_ports {fmcp_hspc_dp_m2c_p[5]}]  ;# MGTYRXP1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7 from J26.A18 DP5_M2C_P
set_property -dict {LOC H37 } [get_ports {fmcp_hspc_dp_m2c_n[5]}]  ;# MGTYRXN1_130 GTYE4_CHANNEL_X0Y29 / GTYE4_COMMON_X0Y7 from J26.A19 DP5_M2C_N
set_property -dict {LOC F31 } [get_ports {fmcp_hspc_dp_c2m_p[6]}]  ;# MGTYTXP2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7 from J26.B36 DP6_C2M_P
set_property -dict {LOC F32 } [get_ports {fmcp_hspc_dp_c2m_n[6]}]  ;# MGTYTXN2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7 from J26.B37 DP6_C2M_N
set_property -dict {LOC G38 } [get_ports {fmcp_hspc_dp_m2c_p[6]}]  ;# MGTYRXP2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7 from J26.B16 DP6_M2C_P
set_property -dict {LOC G39 } [get_ports {fmcp_hspc_dp_m2c_n[6]}]  ;# MGTYRXN2_130 GTYE4_CHANNEL_X0Y30 / GTYE4_COMMON_X0Y7 from J26.B17 DP6_M2C_N
set_property -dict {LOC E33 } [get_ports {fmcp_hspc_dp_c2m_p[7]}]  ;# MGTYTXP3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7 from J26.B32 DP7_C2M_P
set_property -dict {LOC E34 } [get_ports {fmcp_hspc_dp_c2m_n[7]}]  ;# MGTYTXN3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7 from J26.B33 DP7_C2M_N
set_property -dict {LOC F36 } [get_ports {fmcp_hspc_dp_m2c_p[7]}]  ;# MGTYRXP3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7 from J26.B12 DP7_M2C_P
set_property -dict {LOC F37 } [get_ports {fmcp_hspc_dp_m2c_n[7]}]  ;# MGTYRXN3_130 GTYE4_CHANNEL_X0Y31 / GTYE4_COMMON_X0Y7 from J26.B13 DP7_M2C_N
set_property -dict {LOC U33 } [get_ports {fmcp_hspc_mgt_refclk_1_0_p}] ;# MGTREFCLK0P_130 from J26.B20 GBTCLK1_M2C_P
set_property -dict {LOC U34 } [get_ports {fmcp_hspc_mgt_refclk_1_0_n}] ;# MGTREFCLK0N_130 from J26.B21 GBTCLK1_M2C_N
set_property -dict {LOC T31 } [get_ports {fmcp_hspc_mgt_refclk_1_1_p}] ;# MGTREFCLK1P_130 from J14
set_property -dict {LOC T32 } [get_ports {fmcp_hspc_mgt_refclk_1_1_n}] ;# MGTREFCLK1N_130 from J15

# reference clock
create_clock -period 6.400 -name fmcp_hspc_mgt_refclk_1_0 [get_ports {fmcp_hspc_mgt_refclk_1_0_p}]
create_clock -period 6.400 -name fmcp_hspc_mgt_refclk_1_1 [get_ports {fmcp_hspc_mgt_refclk_1_1_p}]

set_property -dict {LOC D31 } [get_ports {fmcp_hspc_dp_c2m_p[8]}]  ;# MGTYTXP0_131 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3 from J26.B28 DP8_C2M_P
set_property -dict {LOC D32 } [get_ports {fmcp_hspc_dp_c2m_n[8]}]  ;# MGTYTXN0_131 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3 from J26.B29 DP8_C2M_N
set_property -dict {LOC E38 } [get_ports {fmcp_hspc_dp_m2c_p[8]}]  ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3 from J26.B8  DP8_M2C_P
set_property -dict {LOC E39 } [get_ports {fmcp_hspc_dp_m2c_n[8]}]  ;# MGTYRXN0_131 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3 from J26.B9  DP8_M2C_N
set_property -dict {LOC C33 } [get_ports {fmcp_hspc_dp_c2m_p[9]}]  ;# MGTYTXP1_131 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3 from J26.B24 DP9_C2M_P
set_property -dict {LOC C34 } [get_ports {fmcp_hspc_dp_c2m_n[9]}]  ;# MGTYTXN1_131 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3 from J26.B25 DP9_C2M_N
set_property -dict {LOC D36 } [get_ports {fmcp_hspc_dp_m2c_p[9]}]  ;# MGTYRXP1_131 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3 from J26.B4  DP9_M2C_P
set_property -dict {LOC D37 } [get_ports {fmcp_hspc_dp_m2c_n[9]}]  ;# MGTYRXN1_131 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3 from J26.B5  DP9_M2C_N
set_property -dict {LOC B31 } [get_ports {fmcp_hspc_dp_c2m_p[10]}] ;# MGTYTXP2_131 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3 from J26.Z24 DP10_C2M_P
set_property -dict {LOC B32 } [get_ports {fmcp_hspc_dp_c2m_n[10]}] ;# MGTYTXN2_131 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3 from J26.Z25 DP10_C2M_N
set_property -dict {LOC C38 } [get_ports {fmcp_hspc_dp_m2c_p[10]}] ;# MGTYRXP2_131 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3 from J26.Y10 DP10_M2C_P
set_property -dict {LOC C39 } [get_ports {fmcp_hspc_dp_m2c_n[10]}] ;# MGTYRXN2_131 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3 from J26.Y11 DP10_M2C_N
set_property -dict {LOC A33 } [get_ports {fmcp_hspc_dp_c2m_p[11]}] ;# MGTYTXP3_131 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3 from J26.Y26 DP11_C2M_P
set_property -dict {LOC A34 } [get_ports {fmcp_hspc_dp_c2m_n[11]}] ;# MGTYTXN3_131 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3 from J26.Y27 DP11_C2M_N
set_property -dict {LOC B36 } [get_ports {fmcp_hspc_dp_m2c_p[11]}] ;# MGTYRXP3_131 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3 from J26.Z12 DP11_M2C_P
set_property -dict {LOC B37 } [get_ports {fmcp_hspc_dp_m2c_n[11]}] ;# MGTYRXN3_131 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3 from J26.Z13 DP11_M2C_N
set_property -dict {LOC P31 } [get_ports {fmcp_hspc_mgt_refclk_2_p}] ;# MGTREFCLK0P_131 from J26.L12 GBTCLK2_M2C_P
set_property -dict {LOC P32 } [get_ports {fmcp_hspc_mgt_refclk_2_n}] ;# MGTREFCLK0N_131 from J26.L13 GBTCLK2_M2C_N

# reference clock
create_clock -period 6.400 -name fmcp_hspc_mgt_refclk_2 [get_ports {fmcp_hspc_mgt_refclk_2_p}]
