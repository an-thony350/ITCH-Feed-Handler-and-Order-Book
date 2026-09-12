# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VCU108 board
# part: xcvu095-ffva2104-2-e

# FMC HPC1 J2
set_property -dict {LOC T33  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[0]"]  ;# J2.G9  LA00_P_CC
set_property -dict {LOC R33  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[0]"]  ;# J2.G10 LA00_N_CC
set_property -dict {LOC P35  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[1]"]  ;# J2.D8  LA01_P_CC
set_property -dict {LOC P36  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[1]"]  ;# J2.D9  LA01_N_CC
set_property -dict {LOC N33  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[2]"]  ;# J2.H7  LA02_P
set_property -dict {LOC M33  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[2]"]  ;# J2.H8  LA02_N
set_property -dict {LOC N34  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[3]"]  ;# J2.G12 LA03_P
set_property -dict {LOC N35  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[3]"]  ;# J2.G13 LA03_N
set_property -dict {LOC M37  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[4]"]  ;# J2.H10 LA04_P
set_property -dict {LOC L38  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[4]"]  ;# J2.H11 LA04_N
set_property -dict {LOC N38  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[5]"]  ;# J2.D11 LA05_P
set_property -dict {LOC M38  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[5]"]  ;# J2.D12 LA05_N
set_property -dict {LOC P37  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[6]"]  ;# J2.C10 LA06_P
set_property -dict {LOC N37  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[6]"]  ;# J2.C11 LA06_N
set_property -dict {LOC L34  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[7]"]  ;# J2.H13 LA07_P
set_property -dict {LOC K34  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[7]"]  ;# J2.H14 LA07_N
set_property -dict {LOC M35  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[8]"]  ;# J2.G12 LA08_P
set_property -dict {LOC L35  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[8]"]  ;# J2.G13 LA08_N
set_property -dict {LOC M36  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[9]"]  ;# J2.D14 LA09_P
set_property -dict {LOC L36  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[9]"]  ;# J2.D15 LA09_N
set_property -dict {LOC N32  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[10]"] ;# J2.C14 LA10_P
set_property -dict {LOC M32  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[10]"] ;# J2.C15 LA10_N
set_property -dict {LOC Y31  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[11]"] ;# J2.H16 LA11_P
set_property -dict {LOC W31  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[11]"] ;# J2.H17 LA11_N
set_property -dict {LOC R31  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[12]"] ;# J2.G15 LA12_P
set_property -dict {LOC P31  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[12]"] ;# J2.G16 LA12_N
set_property -dict {LOC T30  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[13]"] ;# J2.D17 LA13_P
set_property -dict {LOC T31  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[13]"] ;# J2.D18 LA13_N
set_property -dict {LOC L33  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[14]"] ;# J2.C18 LA14_P
set_property -dict {LOC K33  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[14]"] ;# J2.C19 LA14_N
set_property -dict {LOC T34  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[15]"] ;# J2.H19 LA15_P
set_property -dict {LOC T35  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[15]"] ;# J2.H20 LA15_N
set_property -dict {LOC U31  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[16]"] ;# J2.G18 LA16_P
set_property -dict {LOC U32  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[16]"] ;# J2.G19 LA16_N
set_property -dict {LOC AJ32 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[17]"] ;# J2.D20 LA17_P_CC
set_property -dict {LOC AK32 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[17]"] ;# J2.D21 LA17_N_CC
set_property -dict {LOC AL32 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[18]"] ;# J2.C22 LA18_P_CC
set_property -dict {LOC AM32 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[18]"] ;# J2.C23 LA18_N_CC
set_property -dict {LOC AT39 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[19]"] ;# J2.H22 LA19_P
set_property -dict {LOC AT40 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[19]"] ;# J2.H23 LA19_N
set_property -dict {LOC AR37 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[20]"] ;# J2.G21 LA20_P
set_property -dict {LOC AT37 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[20]"] ;# J2.G22 LA20_N
set_property -dict {LOC AT35 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[21]"] ;# J2.H25 LA21_P
set_property -dict {LOC AT36 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[21]"] ;# J2.H26 LA21_N
set_property -dict {LOC AL30 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[22]"] ;# J2.G24 LA22_P
set_property -dict {LOC AL31 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[22]"] ;# J2.G25 LA22_N
set_property -dict {LOC AN33 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[23]"] ;# J2.D23 LA23_P
set_property -dict {LOC AP33 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[23]"] ;# J2.D24 LA23_N
set_property -dict {LOC AM36 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[24]"] ;# J2.H28 LA24_P
set_property -dict {LOC AN36 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[24]"] ;# J2.H29 LA24_N
set_property -dict {LOC AP36 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[25]"] ;# J2.G27 LA25_P
set_property -dict {LOC AP37 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[25]"] ;# J2.G28 LA25_N
set_property -dict {LOC AL29 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[26]"] ;# J2.D26 LA26_P
set_property -dict {LOC AM29 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[26]"] ;# J2.D27 LA26_N
set_property -dict {LOC AP35 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[27]"] ;# J2.C26 LA27_P
set_property -dict {LOC AR35 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[27]"] ;# J2.C27 LA27_N
set_property -dict {LOC AL35 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[28]"] ;# J2.H31 LA28_P
set_property -dict {LOC AL36 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[28]"] ;# J2.H32 LA28_N
set_property -dict {LOC AP38 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[29]"] ;# J2.G30 LA29_P
set_property -dict {LOC AR38 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[29]"] ;# J2.G31 LA29_N
set_property -dict {LOC AJ30 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[30]"] ;# J2.H34 LA30_P
set_property -dict {LOC AJ31 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[30]"] ;# J2.H35 LA30_N
set_property -dict {LOC AN34 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[31]"] ;# J2.G33 LA31_P
set_property -dict {LOC AN35 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[31]"] ;# J2.G34 LA31_N
set_property -dict {LOC AG31 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[32]"] ;# J2.H37 LA32_P
set_property -dict {LOC AH31 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[32]"] ;# J2.H38 LA32_N
set_property -dict {LOC AG32 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_p[33]"] ;# J2.G36 LA33_P
set_property -dict {LOC AG33 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_la_n[33]"] ;# J2.G37 LA33_N

set_property -dict {LOC R32  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_clk0_m2c_p"] ;# J2.H4 CLK0_M2C_P
set_property -dict {LOC P32  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_clk0_m2c_n"] ;# J2.H5 CLK0_M2C_N
set_property -dict {LOC AK34 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_clk1_m2c_p"] ;# J2.G2 CLK1_M2C_P
set_property -dict {LOC AL34 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc1_clk1_m2c_n"] ;# J2.G3 CLK1_M2C_N

set_property -dict {LOC AU24 IOSTANDARD LVCMOS18} [get_ports {fmc_hpc1_pg_m2c}]      ;# J2.F1 PG_M2C
set_property -dict {LOC BD23 IOSTANDARD LVCMOS18} [get_ports {fmc_hpc1_prsnt_m2c_l}] ;# J2.H2 PRSNT_M2C_L

set_property -dict {LOC AN5 } [get_ports {fmc_hpc1_dp_c2m_p[0]}] ;# MGTHTXP0_226 GTHE3_CHANNEL_X0Y8 / GTHE3_COMMON_X0Y2 from J2.C2  DP0_C2M_P
set_property -dict {LOC AN4 } [get_ports {fmc_hpc1_dp_c2m_n[0]}] ;# MGTHTXN0_226 GTHE3_CHANNEL_X0Y8 / GTHE3_COMMON_X0Y2 from J2.C3  DP0_C2M_N
set_property -dict {LOC AH2 } [get_ports {fmc_hpc1_dp_m2c_p[0]}] ;# MGTHRXP0_226 GTHE3_CHANNEL_X0Y8 / GTHE3_COMMON_X0Y2 from J2.C6  DP0_M2C_P
set_property -dict {LOC AH1 } [get_ports {fmc_hpc1_dp_m2c_n[0]}] ;# MGTHRXN0_226 GTHE3_CHANNEL_X0Y8 / GTHE3_COMMON_X0Y2 from J2.C7  DP0_M2C_N
set_property -dict {LOC AM7 } [get_ports {fmc_hpc1_dp_c2m_p[1]}] ;# MGTHTXP1_226 GTHE3_CHANNEL_X0Y9 / GTHE3_COMMON_X0Y2 from J2.A22 DP1_C2M_P
set_property -dict {LOC AM6 } [get_ports {fmc_hpc1_dp_c2m_n[1]}] ;# MGTHTXN1_226 GTHE3_CHANNEL_X0Y9 / GTHE3_COMMON_X0Y2 from J2.A23 DP1_C2M_N
set_property -dict {LOC AG4 } [get_ports {fmc_hpc1_dp_m2c_p[1]}] ;# MGTHRXP1_226 GTHE3_CHANNEL_X0Y9 / GTHE3_COMMON_X0Y2 from J2.A2  DP1_M2C_P
set_property -dict {LOC AG3 } [get_ports {fmc_hpc1_dp_m2c_n[1]}] ;# MGTHRXN1_226 GTHE3_CHANNEL_X0Y9 / GTHE3_COMMON_X0Y2 from J2.A3  DP1_M2C_N
set_property -dict {LOC AK7 } [get_ports {fmc_hpc1_dp_c2m_p[2]}] ;# MGTHTXP2_226 GTHE3_CHANNEL_X0Y10 / GTHE3_COMMON_X0Y2 from J2.A26 DP2_C2M_P
set_property -dict {LOC AK6 } [get_ports {fmc_hpc1_dp_c2m_n[2]}] ;# MGTHTXN2_226 GTHE3_CHANNEL_X0Y10 / GTHE3_COMMON_X0Y2 from J2.A27 DP2_C2M_N
set_property -dict {LOC AF2 } [get_ports {fmc_hpc1_dp_m2c_p[2]}] ;# MGTHRXP2_226 GTHE3_CHANNEL_X0Y10 / GTHE3_COMMON_X0Y2 from J2.A6  DP2_M2C_P
set_property -dict {LOC AF1 } [get_ports {fmc_hpc1_dp_m2c_n[2]}] ;# MGTHRXN2_226 GTHE3_CHANNEL_X0Y10 / GTHE3_COMMON_X0Y2 from J2.A7  DP2_M2C_N
set_property -dict {LOC AH7 } [get_ports {fmc_hpc1_dp_c2m_p[3]}] ;# MGTHTXP3_226 GTHE3_CHANNEL_X0Y11 / GTHE3_COMMON_X0Y2 from J2.A30 DP3_C2M_P
set_property -dict {LOC AH6 } [get_ports {fmc_hpc1_dp_c2m_n[3]}] ;# MGTHTXN3_226 GTHE3_CHANNEL_X0Y11 / GTHE3_COMMON_X0Y2 from J2.A31 DP3_C2M_N
set_property -dict {LOC AE4 } [get_ports {fmc_hpc1_dp_m2c_p[3]}] ;# MGTHRXP3_226 GTHE3_CHANNEL_X0Y11 / GTHE3_COMMON_X0Y2 from J2.A10 DP3_M2C_P
set_property -dict {LOC AE3 } [get_ports {fmc_hpc1_dp_m2c_n[3]}] ;# MGTHRXN3_226 GTHE3_CHANNEL_X0Y11 / GTHE3_COMMON_X0Y2 from J2.A11 DP3_M2C_N

set_property -dict {LOC AF7 } [get_ports {fmc_hpc1_dp_c2m_p[4]}] ;# MGTHTXP0_227 GTHE3_CHANNEL_X0Y12 / GTHE3_COMMON_X0Y3 from J2.A34 DP4_C2M_P
set_property -dict {LOC AF6 } [get_ports {fmc_hpc1_dp_c2m_n[4]}] ;# MGTHTXN0_227 GTHE3_CHANNEL_X0Y12 / GTHE3_COMMON_X0Y3 from J2.A35 DP4_C2M_N
set_property -dict {LOC AD2 } [get_ports {fmc_hpc1_dp_m2c_p[4]}] ;# MGTHRXP0_227 GTHE3_CHANNEL_X0Y12 / GTHE3_COMMON_X0Y3 from J2.A14 DP4_M2C_P
set_property -dict {LOC AD1 } [get_ports {fmc_hpc1_dp_m2c_n[4]}] ;# MGTHRXN0_227 GTHE3_CHANNEL_X0Y12 / GTHE3_COMMON_X0Y3 from J2.A15 DP4_M2C_N
set_property -dict {LOC AD7 } [get_ports {fmc_hpc1_dp_c2m_p[5]}] ;# MGTHTXP1_227 GTHE3_CHANNEL_X0Y13 / GTHE3_COMMON_X0Y3 from J2.A38 DP5_C2M_P
set_property -dict {LOC AD6 } [get_ports {fmc_hpc1_dp_c2m_n[5]}] ;# MGTHTXN1_227 GTHE3_CHANNEL_X0Y13 / GTHE3_COMMON_X0Y3 from J2.A39 DP5_C2M_N
set_property -dict {LOC AC4 } [get_ports {fmc_hpc1_dp_m2c_p[5]}] ;# MGTHRXP1_227 GTHE3_CHANNEL_X0Y13 / GTHE3_COMMON_X0Y3 from J2.A18 DP5_M2C_P
set_property -dict {LOC AC3 } [get_ports {fmc_hpc1_dp_m2c_n[5]}] ;# MGTHRXN1_227 GTHE3_CHANNEL_X0Y13 / GTHE3_COMMON_X0Y3 from J2.A19 DP5_M2C_N
set_property -dict {LOC AB7 } [get_ports {fmc_hpc1_dp_c2m_p[6]}] ;# MGTHTXP2_227 GTHE3_CHANNEL_X0Y14 / GTHE3_COMMON_X0Y3 from J2.B36 DP6_C2M_P
set_property -dict {LOC AB6 } [get_ports {fmc_hpc1_dp_c2m_n[6]}] ;# MGTHTXN2_227 GTHE3_CHANNEL_X0Y14 / GTHE3_COMMON_X0Y3 from J2.B37 DP6_C2M_N
set_property -dict {LOC AB2 } [get_ports {fmc_hpc1_dp_m2c_p[6]}] ;# MGTHRXP2_227 GTHE3_CHANNEL_X0Y14 / GTHE3_COMMON_X0Y3 from J2.B16 DP6_M2C_P
set_property -dict {LOC AB1 } [get_ports {fmc_hpc1_dp_m2c_n[6]}] ;# MGTHRXN2_227 GTHE3_CHANNEL_X0Y14 / GTHE3_COMMON_X0Y3 from J2.B17 DP6_M2C_N
set_property -dict {LOC Y7  } [get_ports {fmc_hpc1_dp_c2m_p[7]}] ;# MGTHTXP3_227 GTHE3_CHANNEL_X0Y15 / GTHE3_COMMON_X0Y3 from J2.B32 DP7_C2M_P
set_property -dict {LOC Y6  } [get_ports {fmc_hpc1_dp_c2m_n[7]}] ;# MGTHTXN3_227 GTHE3_CHANNEL_X0Y15 / GTHE3_COMMON_X0Y3 from J2.B33 DP7_C2M_N
set_property -dict {LOC AA4 } [get_ports {fmc_hpc1_dp_m2c_p[7]}] ;# MGTHRXP3_227 GTHE3_CHANNEL_X0Y15 / GTHE3_COMMON_X0Y3 from J2.B12 DP7_M2C_P
set_property -dict {LOC AA3 } [get_ports {fmc_hpc1_dp_m2c_n[7]}] ;# MGTHRXN3_227 GTHE3_CHANNEL_X0Y15 / GTHE3_COMMON_X0Y3 from J2.B13 DP7_M2C_N
set_property -dict {LOC AC9 } [get_ports fmc_hpc1_mgt_refclk_0_p] ;# MGTREFCLK0P_227 from J2.D4 GBTCLK0_M2C_P
set_property -dict {LOC AC8 } [get_ports fmc_hpc1_mgt_refclk_0_n] ;# MGTREFCLK0N_227 from J2.D5 GBTCLK0_M2C_N
set_property -dict {LOC AA9 } [get_ports fmc_hpc1_mgt_refclk_1_p] ;# MGTREFCLK1P_227 from J2.B20 GBTCLK1_M2C_P
set_property -dict {LOC AA8 } [get_ports fmc_hpc1_mgt_refclk_1_n] ;# MGTREFCLK1N_227 from J2.B21 GBTCLK1_M2C_N

# reference clock
create_clock -period 6.400 -name fmc_hpc0_mgt_refclk_0 [get_ports fmc_hpc0_mgt_refclk_0_p]
create_clock -period 6.400 -name fmc_hpc0_mgt_refclk_1 [get_ports fmc_hpc0_mgt_refclk_1_p]

set_property -dict {LOC P7  } [get_ports {fmc_hpc1_dp_c2m_p[8]}] ;# MGTHTXP2_228 GTHE3_CHANNEL_X0Y18 / GTHE3_COMMON_X0Y4 from J2.B28 DP8_C2M_P
set_property -dict {LOC P6  } [get_ports {fmc_hpc1_dp_c2m_n[8]}] ;# MGTHTXN2_228 GTHE3_CHANNEL_X0Y18 / GTHE3_COMMON_X0Y4 from J2.B29 DP8_C2M_N
set_property -dict {LOC V2  } [get_ports {fmc_hpc1_dp_m2c_p[8]}] ;# MGTHRXP2_228 GTHE3_CHANNEL_X0Y18 / GTHE3_COMMON_X0Y4 from J2.B8  DP8_M2C_P
set_property -dict {LOC V1  } [get_ports {fmc_hpc1_dp_m2c_n[8]}] ;# MGTHRXN2_228 GTHE3_CHANNEL_X0Y18 / GTHE3_COMMON_X0Y4 from J2.B9  DP8_M2C_N
set_property -dict {LOC M7  } [get_ports {fmc_hpc1_dp_c2m_p[9]}] ;# MGTHTXP3_228 GTHE3_CHANNEL_X0Y18 / GTHE3_COMMON_X0Y4 from J2.B24 DP9_C2M_P
set_property -dict {LOC M6  } [get_ports {fmc_hpc1_dp_c2m_n[9]}] ;# MGTHTXN3_228 GTHE3_CHANNEL_X0Y18 / GTHE3_COMMON_X0Y4 from J2.B25 DP9_C2M_N
set_property -dict {LOC U4  } [get_ports {fmc_hpc1_dp_m2c_p[9]}] ;# MGTHRXP3_228 GTHE3_CHANNEL_X0Y18 / GTHE3_COMMON_X0Y4 from J2.B4  DP9_M2C_P
set_property -dict {LOC U3  } [get_ports {fmc_hpc1_dp_m2c_n[9]}] ;# MGTHRXN3_228 GTHE3_CHANNEL_X0Y18 / GTHE3_COMMON_X0Y4 from J2.B5  DP9_M2C_N
set_property -dict {LOC W9  } [get_ports fmc_hpc1_mgt_refclk_2_p] ;# MGTREFCLK0P_228 from from J87 P1
set_property -dict {LOC W8  } [get_ports fmc_hpc1_mgt_refclk_2_n] ;# MGTREFCLK0N_228 from from J87 P2

# reference clock
create_clock -period 6.400 -name fmc_hpc1_mgt_refclk_2 [get_ports fmc_hpc1_mgt_refclk_2_p]
