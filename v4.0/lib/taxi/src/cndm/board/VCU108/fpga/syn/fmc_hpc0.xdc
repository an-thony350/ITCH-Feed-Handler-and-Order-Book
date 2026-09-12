# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VCU108 board
# part: xcvu095-ffva2104-2-e

# FMC HPC0 J22
set_property -dict {LOC AY9  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[0]"]  ;# J22.G9  LA00_P_CC
set_property -dict {LOC BA9  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[0]"]  ;# J22.G10 LA00_N_CC
set_property -dict {LOC BC10 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[1]"]  ;# J22.D8  LA01_P_CC
set_property -dict {LOC BD10 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[1]"]  ;# J22.D9  LA01_N_CC
set_property -dict {LOC BA7  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[2]"]  ;# J22.H7  LA02_P
set_property -dict {LOC BB7  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[2]"]  ;# J22.H8  LA02_N
set_property -dict {LOC BD8  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[3]"]  ;# J22.G12 LA03_P
set_property -dict {LOC BD7  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[3]"]  ;# J22.G13 LA03_N
set_property -dict {LOC BE8  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[4]"]  ;# J22.H10 LA04_P
set_property -dict {LOC BE7  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[4]"]  ;# J22.H11 LA04_N
set_property -dict {LOC BF12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[5]"]  ;# J22.D11 LA05_P
set_property -dict {LOC BF11 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[5]"]  ;# J22.D12 LA05_N
set_property -dict {LOC BE10 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[6]"]  ;# J22.C10 LA06_P
set_property -dict {LOC BE9  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[6]"]  ;# J22.C11 LA06_N
set_property -dict {LOC BD12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[7]"]  ;# J22.H13 LA07_P
set_property -dict {LOC BE12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[7]"]  ;# J22.H14 LA07_N
set_property -dict {LOC BF10 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[8]"]  ;# J22.G12 LA08_P
set_property -dict {LOC BF9  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[8]"]  ;# J22.G13 LA08_N
set_property -dict {LOC BD13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[9]"]  ;# J22.D14 LA09_P
set_property -dict {LOC BE13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[9]"]  ;# J22.D15 LA09_N
set_property -dict {LOC BE14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[10]"] ;# J22.C14 LA10_P
set_property -dict {LOC BF14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[10]"] ;# J22.C15 LA10_N
set_property -dict {LOC BC11 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[11]"] ;# J22.H16 LA11_P
set_property -dict {LOC BD11 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[11]"] ;# J22.H17 LA11_N
set_property -dict {LOC BE15 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[12]"] ;# J22.G15 LA12_P
set_property -dict {LOC BF15 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[12]"] ;# J22.G16 LA12_N
set_property -dict {LOC BA14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[13]"] ;# J22.D17 LA13_P
set_property -dict {LOC BB14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[13]"] ;# J22.D18 LA13_N
set_property -dict {LOC BB13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[14]"] ;# J22.C18 LA14_P
set_property -dict {LOC BB12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[14]"] ;# J22.C19 LA14_N
set_property -dict {LOC AV9  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[15]"] ;# J22.H19 LA15_P
set_property -dict {LOC AV8  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[15]"] ;# J22.H20 LA15_N
set_property -dict {LOC AY8  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[16]"] ;# J22.G18 LA16_P
set_property -dict {LOC AY7  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[16]"] ;# J22.G19 LA16_N
set_property -dict {LOC AV14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[17]"] ;# J22.D20 LA17_P_CC
set_property -dict {LOC AV13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[17]"] ;# J22.D21 LA17_N_CC
set_property -dict {LOC AP13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[18]"] ;# J22.C22 LA18_P_CC
set_property -dict {LOC AR13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[18]"] ;# J22.C23 LA18_N_CC
set_property -dict {LOC AV15 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[19]"] ;# J22.H22 LA19_P
set_property -dict {LOC AW15 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[19]"] ;# J22.H23 LA19_N
set_property -dict {LOC AY15 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[20]"] ;# J22.G21 LA20_P
set_property -dict {LOC AY14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[20]"] ;# J22.G22 LA20_N
set_property -dict {LOC AN16 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[21]"] ;# J22.H25 LA21_P
set_property -dict {LOC AP16 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[21]"] ;# J22.H26 LA21_N
set_property -dict {LOC AN15 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[22]"] ;# J22.G24 LA22_P
set_property -dict {LOC AP15 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[22]"] ;# J22.G25 LA22_N
set_property -dict {LOC AT16 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[23]"] ;# J22.D23 LA23_P
set_property -dict {LOC AT15 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[23]"] ;# J22.D24 LA23_N
set_property -dict {LOC AK15 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[24]"] ;# J22.H28 LA24_P
set_property -dict {LOC AL15 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[24]"] ;# J22.H29 LA24_N
set_property -dict {LOC AM13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[25]"] ;# J22.G27 LA25_P
set_property -dict {LOC AM12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[25]"] ;# J22.G28 LA25_N
set_property -dict {LOC AL14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[26]"] ;# J22.D26 LA26_P
set_property -dict {LOC AM14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[26]"] ;# J22.D27 LA26_N
set_property -dict {LOC AN14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[27]"] ;# J22.C26 LA27_P
set_property -dict {LOC AN13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[27]"] ;# J22.C27 LA27_N
set_property -dict {LOC AJ13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[28]"] ;# J22.H31 LA28_P
set_property -dict {LOC AJ12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[28]"] ;# J22.H32 LA28_N
set_property -dict {LOC AK14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[29]"] ;# J22.G30 LA29_P
set_property -dict {LOC AK13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[29]"] ;# J22.G31 LA29_N
set_property -dict {LOC AK12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[30]"] ;# J22.H34 LA30_P
set_property -dict {LOC AL12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[30]"] ;# J22.H35 LA30_N
set_property -dict {LOC AP12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[31]"] ;# J22.G33 LA31_P
set_property -dict {LOC AR12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[31]"] ;# J22.G34 LA31_N
set_property -dict {LOC AU11 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[32]"] ;# J22.H37 LA32_P
set_property -dict {LOC AV11 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[32]"] ;# J22.H38 LA32_N
set_property -dict {LOC AU16 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_p[33]"] ;# J22.G36 LA33_P
set_property -dict {LOC AV16 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_la_n[33]"] ;# J22.G37 LA33_N

set_property -dict {LOC N14  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[0]"]  ;# J22.F4  HA00_P_CC
set_property -dict {LOC N13  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[0]"]  ;# J22.F5  HA00_N_CC
set_property -dict {LOC T14  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[1]"]  ;# J22.E2  HA01_P_CC
set_property -dict {LOC R13  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[1]"]  ;# J22.E3  HA01_N_CC
set_property -dict {LOC T16  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[2]"]  ;# J22.K7  HA02_P
set_property -dict {LOC T15  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[2]"]  ;# J22.K8  HA02_N
set_property -dict {LOC K11  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[3]"]  ;# J22.J6  HA03_P
set_property -dict {LOC J11  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[3]"]  ;# J22.J7  HA03_N
set_property -dict {LOC AA13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[4]"]  ;# J22.F7  HA04_P
set_property -dict {LOC Y13  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[4]"]  ;# J22.F8  HA04_N
set_property -dict {LOC AA12 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[5]"]  ;# J22.E6  HA05_P
set_property -dict {LOC Y12  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[5]"]  ;# J22.E7  HA05_N
set_property -dict {LOC P15  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[6]"]  ;# J22.K10 HA06_P
set_property -dict {LOC N15  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[6]"]  ;# J22.K11 HA06_N
set_property -dict {LOC R12  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[7]"]  ;# J22.J9  HA07_P
set_property -dict {LOC P12  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[7]"]  ;# J22.J10 HA07_N
set_property -dict {LOC W12  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[8]"]  ;# J22.F10 HA08_P
set_property -dict {LOC V12  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[8]"]  ;# J22.F11 HA08_N
set_property -dict {LOC AA14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[9]"]  ;# J22.E9  HA09_P
set_property -dict {LOC Y14  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[9]"]  ;# J22.E10 HA09_N
set_property -dict {LOC K12  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[10]"] ;# J22.K13 HA10_P
set_property -dict {LOC J12  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[10]"] ;# J22.K14 HA10_N
set_property -dict {LOC M11  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[11]"] ;# J22.J12 HA11_P
set_property -dict {LOC L11  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[11]"] ;# J22.J13 HA11_N
set_property -dict {LOC V15  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[12]"] ;# J22.F13 HA12_P
set_property -dict {LOC U15  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[12]"] ;# J22.F14 HA12_N
set_property -dict {LOC W14  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[13]"] ;# J22.E12 HA13_P
set_property -dict {LOC V14  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[13]"] ;# J22.E13 HA13_N
set_property -dict {LOC K14  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[14]"] ;# J22.J15 HA14_P
set_property -dict {LOC K13  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[14]"] ;# J22.J16 HA14_N
set_property -dict {LOC V13  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[15]"] ;# J22.F14 HA15_P
set_property -dict {LOC U12  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[15]"] ;# J22.F16 HA15_N
set_property -dict {LOC V16  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[16]"] ;# J22.E15 HA16_P
set_property -dict {LOC U16  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[16]"] ;# J22.E16 HA16_N
set_property -dict {LOC U13  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[17]"] ;# J22.K16 HA17_P_CC
set_property -dict {LOC T13  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[17]"] ;# J22.K17 HA17_N_CC
set_property -dict {LOC L14  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[18]"] ;# J22.J18 HA18_P_CC
set_property -dict {LOC L13  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[18]"] ;# J22.J19 HA18_N_CC
set_property -dict {LOC R14  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[19]"] ;# J22.F19 HA19_P
set_property -dict {LOC P14  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[19]"] ;# J22.F20 HA19_N
set_property -dict {LOC R11  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[20]"] ;# J22.E18 HA20_P
set_property -dict {LOC P11  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[20]"] ;# J22.E19 HA20_N
set_property -dict {LOC M13  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[21]"] ;# J22.K19 HA21_P
set_property -dict {LOC M12  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[21]"] ;# J22.K20 HA21_N
set_property -dict {LOC M15  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[22]"] ;# J22.J21 HA22_P
set_property -dict {LOC L15  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[22]"] ;# J22.J22 HA22_N
set_property -dict {LOC U11  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_p[23]"] ;# J22.K22 HA23_P
set_property -dict {LOC T11  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_ha_n[23]"] ;# J22.K23 HA23_N

set_property -dict {LOC BB9  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_clk0_m2c_p"] ;# J22.H4 CLK0_M2C_P
set_property -dict {LOC BB8  IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_clk0_m2c_n"] ;# J22.H5 CLK0_M2C_N
set_property -dict {LOC AU14 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_clk1_m2c_p"] ;# J22.G2 CLK1_M2C_P
set_property -dict {LOC AU13 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports "fmc_hpc0_clk1_m2c_n"] ;# J22.G3 CLK1_M2C_N

set_property -dict {LOC AP22 IOSTANDARD LVCMOS18} [get_ports {fmc_hpc0_pg_m2c}]      ;# J22.F1 PG_M2C
set_property -dict {LOC AL19 IOSTANDARD LVCMOS18} [get_ports {fmc_hpc0_prsnt_m2c_l}] ;# J22.H2 PRSNT_M2C_L

set_property -dict {LOC G5  } [get_ports {fmc_hpc0_dp_c2m_p[0]}] ;# MGTHTXP0_230 GTHE3_CHANNEL_X0Y24 / GTHE3_COMMON_X0Y6 from J22.C2  DP0_C2M_P
set_property -dict {LOC G4  } [get_ports {fmc_hpc0_dp_c2m_n[0]}] ;# MGTHTXN0_230 GTHE3_CHANNEL_X0Y24 / GTHE3_COMMON_X0Y6 from J22.C3  DP0_C2M_N
set_property -dict {LOC K2  } [get_ports {fmc_hpc0_dp_m2c_p[0]}] ;# MGTHRXP0_230 GTHE3_CHANNEL_X0Y24 / GTHE3_COMMON_X0Y6 from J22.C6  DP0_M2C_P
set_property -dict {LOC K1  } [get_ports {fmc_hpc0_dp_m2c_n[0]}] ;# MGTHRXN0_230 GTHE3_CHANNEL_X0Y24 / GTHE3_COMMON_X0Y6 from J22.C7  DP0_M2C_N
set_property -dict {LOC F7  } [get_ports {fmc_hpc0_dp_c2m_p[1]}] ;# MGTHTXP1_230 GTHE3_CHANNEL_X0Y25 / GTHE3_COMMON_X0Y6 from J22.A22 DP1_C2M_P
set_property -dict {LOC F6  } [get_ports {fmc_hpc0_dp_c2m_n[1]}] ;# MGTHTXN1_230 GTHE3_CHANNEL_X0Y25 / GTHE3_COMMON_X0Y6 from J22.A23 DP1_C2M_N
set_property -dict {LOC H2  } [get_ports {fmc_hpc0_dp_m2c_p[1]}] ;# MGTHRXP1_230 GTHE3_CHANNEL_X0Y25 / GTHE3_COMMON_X0Y6 from J22.A2  DP1_M2C_P
set_property -dict {LOC H1  } [get_ports {fmc_hpc0_dp_m2c_n[1]}] ;# MGTHRXN1_230 GTHE3_CHANNEL_X0Y25 / GTHE3_COMMON_X0Y6 from J22.A3  DP1_M2C_N
set_property -dict {LOC E5  } [get_ports {fmc_hpc0_dp_c2m_p[2]}] ;# MGTHTXP2_230 GTHE3_CHANNEL_X0Y26 / GTHE3_COMMON_X0Y6 from J22.A26 DP2_C2M_P
set_property -dict {LOC E4  } [get_ports {fmc_hpc0_dp_c2m_n[2]}] ;# MGTHTXN2_230 GTHE3_CHANNEL_X0Y26 / GTHE3_COMMON_X0Y6 from J22.A27 DP2_C2M_N
set_property -dict {LOC F2  } [get_ports {fmc_hpc0_dp_m2c_p[2]}] ;# MGTHRXP2_230 GTHE3_CHANNEL_X0Y26 / GTHE3_COMMON_X0Y6 from J22.A6  DP2_M2C_P
set_property -dict {LOC F1  } [get_ports {fmc_hpc0_dp_m2c_n[2]}] ;# MGTHRXN2_230 GTHE3_CHANNEL_X0Y26 / GTHE3_COMMON_X0Y6 from J22.A7  DP2_M2C_N
set_property -dict {LOC C5  } [get_ports {fmc_hpc0_dp_c2m_p[3]}] ;# MGTHTXP3_230 GTHE3_CHANNEL_X0Y27 / GTHE3_COMMON_X0Y6 from J22.A30 DP3_C2M_P
set_property -dict {LOC C4  } [get_ports {fmc_hpc0_dp_c2m_n[3]}] ;# MGTHTXN3_230 GTHE3_CHANNEL_X0Y27 / GTHE3_COMMON_X0Y6 from J22.A31 DP3_C2M_N
set_property -dict {LOC D2  } [get_ports {fmc_hpc0_dp_m2c_p[3]}] ;# MGTHRXP3_230 GTHE3_CHANNEL_X0Y27 / GTHE3_COMMON_X0Y6 from J22.A10 DP3_M2C_P
set_property -dict {LOC D1  } [get_ports {fmc_hpc0_dp_m2c_n[3]}] ;# MGTHRXN3_230 GTHE3_CHANNEL_X0Y27 / GTHE3_COMMON_X0Y6 from J22.A11 DP3_M2C_N

set_property -dict {LOC L5  } [get_ports {fmc_hpc0_dp_c2m_p[4]}] ;# MGTHTXP0_229 GTHE3_CHANNEL_X0Y20 / GTHE3_COMMON_X0Y5 from J22.A34 DP4_C2M_P
set_property -dict {LOC L4  } [get_ports {fmc_hpc0_dp_c2m_n[4]}] ;# MGTHTXN0_229 GTHE3_CHANNEL_X0Y20 / GTHE3_COMMON_X0Y5 from J22.A35 DP4_C2M_N
set_property -dict {LOC T2  } [get_ports {fmc_hpc0_dp_m2c_p[4]}] ;# MGTHRXP0_229 GTHE3_CHANNEL_X0Y20 / GTHE3_COMMON_X0Y5 from J22.A14 DP4_M2C_P
set_property -dict {LOC T1  } [get_ports {fmc_hpc0_dp_m2c_n[4]}] ;# MGTHRXN0_229 GTHE3_CHANNEL_X0Y20 / GTHE3_COMMON_X0Y5 from J22.A15 DP4_M2C_N
set_property -dict {LOC K7  } [get_ports {fmc_hpc0_dp_c2m_p[5]}] ;# MGTHTXP1_229 GTHE3_CHANNEL_X0Y21 / GTHE3_COMMON_X0Y5 from J22.A38 DP5_C2M_P
set_property -dict {LOC K6  } [get_ports {fmc_hpc0_dp_c2m_n[5]}] ;# MGTHTXN1_229 GTHE3_CHANNEL_X0Y21 / GTHE3_COMMON_X0Y5 from J22.A39 DP5_C2M_N
set_property -dict {LOC R4  } [get_ports {fmc_hpc0_dp_m2c_p[5]}] ;# MGTHRXP1_229 GTHE3_CHANNEL_X0Y21 / GTHE3_COMMON_X0Y5 from J22.A18 DP5_M2C_P
set_property -dict {LOC R3  } [get_ports {fmc_hpc0_dp_m2c_n[5]}] ;# MGTHRXN1_229 GTHE3_CHANNEL_X0Y21 / GTHE3_COMMON_X0Y5 from J22.A19 DP5_M2C_N
set_property -dict {LOC J5  } [get_ports {fmc_hpc0_dp_c2m_p[6]}] ;# MGTHTXP2_229 GTHE3_CHANNEL_X0Y22 / GTHE3_COMMON_X0Y5 from J22.B36 DP6_C2M_P
set_property -dict {LOC J4  } [get_ports {fmc_hpc0_dp_c2m_n[6]}] ;# MGTHTXN2_229 GTHE3_CHANNEL_X0Y22 / GTHE3_COMMON_X0Y5 from J22.B37 DP6_C2M_N
set_property -dict {LOC P2  } [get_ports {fmc_hpc0_dp_m2c_p[6]}] ;# MGTHRXP2_229 GTHE3_CHANNEL_X0Y22 / GTHE3_COMMON_X0Y5 from J22.B16 DP6_M2C_P
set_property -dict {LOC P1  } [get_ports {fmc_hpc0_dp_m2c_n[6]}] ;# MGTHRXN2_229 GTHE3_CHANNEL_X0Y22 / GTHE3_COMMON_X0Y5 from J22.B17 DP6_M2C_N
set_property -dict {LOC H7  } [get_ports {fmc_hpc0_dp_c2m_p[7]}] ;# MGTHTXP3_229 GTHE3_CHANNEL_X0Y23 / GTHE3_COMMON_X0Y5 from J22.B32 DP7_C2M_P
set_property -dict {LOC H6  } [get_ports {fmc_hpc0_dp_c2m_n[7]}] ;# MGTHTXN3_229 GTHE3_CHANNEL_X0Y23 / GTHE3_COMMON_X0Y5 from J22.B33 DP7_C2M_N
set_property -dict {LOC M2  } [get_ports {fmc_hpc0_dp_m2c_p[7]}] ;# MGTHRXP3_229 GTHE3_CHANNEL_X0Y23 / GTHE3_COMMON_X0Y5 from J22.B12 DP7_M2C_P
set_property -dict {LOC M1  } [get_ports {fmc_hpc0_dp_m2c_n[7]}] ;# MGTHRXN3_229 GTHE3_CHANNEL_X0Y23 / GTHE3_COMMON_X0Y5 from J22.B13 DP7_M2C_N
set_property -dict {LOC R9  } [get_ports fmc_hpc0_mgt_refclk_0_p] ;# MGTREFCLK0P_229 from J22.D4 GBTCLK0_M2C_P
set_property -dict {LOC R8  } [get_ports fmc_hpc0_mgt_refclk_0_n] ;# MGTREFCLK0N_229 from J22.D5 GBTCLK0_M2C_N
set_property -dict {LOC N9  } [get_ports fmc_hpc0_mgt_refclk_1_p] ;# MGTREFCLK1P_229 from J22.B20 GBTCLK1_M2C_P
set_property -dict {LOC N8  } [get_ports fmc_hpc0_mgt_refclk_1_n] ;# MGTREFCLK1N_229 from J22.B21 GBTCLK1_M2C_N

# reference clock
create_clock -period 6.400 -name fmc_hpc0_mgt_refclk_0 [get_ports fmc_hpc0_mgt_refclk_0_p]
create_clock -period 6.400 -name fmc_hpc0_mgt_refclk_1 [get_ports fmc_hpc0_mgt_refclk_1_p]

set_property -dict {LOC V7  } [get_ports {fmc_hpc0_dp_c2m_p[8]}] ;# MGTHTXP0_228 GTHE3_CHANNEL_X0Y16 / GTHE3_COMMON_X0Y4 from J22.B28 DP8_C2M_P
set_property -dict {LOC V6  } [get_ports {fmc_hpc0_dp_c2m_n[8]}] ;# MGTHTXN0_228 GTHE3_CHANNEL_X0Y16 / GTHE3_COMMON_X0Y4 from J22.B29 DP8_C2M_N
set_property -dict {LOC Y2  } [get_ports {fmc_hpc0_dp_m2c_p[8]}] ;# MGTHRXP0_228 GTHE3_CHANNEL_X0Y16 / GTHE3_COMMON_X0Y4 from J22.B8  DP8_M2C_P
set_property -dict {LOC Y1  } [get_ports {fmc_hpc0_dp_m2c_n[8]}] ;# MGTHRXN0_228 GTHE3_CHANNEL_X0Y16 / GTHE3_COMMON_X0Y4 from J22.B9  DP8_M2C_N
set_property -dict {LOC T7  } [get_ports {fmc_hpc0_dp_c2m_p[9]}] ;# MGTHTXP1_228 GTHE3_CHANNEL_X0Y17 / GTHE3_COMMON_X0Y4 from J22.B24 DP9_C2M_P
set_property -dict {LOC T6  } [get_ports {fmc_hpc0_dp_c2m_n[9]}] ;# MGTHTXN1_228 GTHE3_CHANNEL_X0Y17 / GTHE3_COMMON_X0Y4 from J22.B25 DP9_C2M_N
set_property -dict {LOC W4  } [get_ports {fmc_hpc0_dp_m2c_p[9]}] ;# MGTHRXP1_228 GTHE3_CHANNEL_X0Y17 / GTHE3_COMMON_X0Y4 from J22.B4  DP9_M2C_P
set_property -dict {LOC W3  } [get_ports {fmc_hpc0_dp_m2c_n[9]}] ;# MGTHRXN1_228 GTHE3_CHANNEL_X0Y17 / GTHE3_COMMON_X0Y4 from J22.B5  DP9_M2C_N
set_property -dict {LOC W9  } [get_ports fmc_hpc0_mgt_refclk_2_p] ;# MGTREFCLK0P_228 from from J87 P1
set_property -dict {LOC W8  } [get_ports fmc_hpc0_mgt_refclk_2_n] ;# MGTREFCLK0N_228 from from J87 P2

# reference clock
create_clock -period 6.400 -name fmc_hpc0_mgt_refclk_2 [get_ports fmc_hpc0_mgt_refclk_2_p]
