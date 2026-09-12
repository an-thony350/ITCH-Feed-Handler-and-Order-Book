# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VCU108 board
# part: xcvu095-ffva2104-2-e

# DDR4 C1
# 5x MT40A256M16GE-075E
set_property -dict {LOC C30  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[0]}]
set_property -dict {LOC D32  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[1]}]
set_property -dict {LOC B30  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[2]}]
set_property -dict {LOC C33  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[3]}]
set_property -dict {LOC E32  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[4]}]
set_property -dict {LOC A29  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[5]}]
set_property -dict {LOC C29  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[6]}]
set_property -dict {LOC E29  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[7]}]
set_property -dict {LOC A30  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[8]}]
set_property -dict {LOC C32  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[9]}]
set_property -dict {LOC A31  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[10]}]
set_property -dict {LOC A33  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[11]}]
set_property -dict {LOC F29  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[12]}]
set_property -dict {LOC B32  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[13]}]
set_property -dict {LOC D29  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[14]}]
set_property -dict {LOC B31  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[15]}]
set_property -dict {LOC B33  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_adr[16]}]
set_property -dict {LOC G30  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_ba[0]}]
set_property -dict {LOC F30  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_ba[1]}]
set_property -dict {LOC F33  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_bg[0]}]
set_property -dict {LOC E31  IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_c1_ck_t}]
set_property -dict {LOC D31  IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_c1_ck_c}]
set_property -dict {LOC K29  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_cke}]
set_property -dict {LOC D30  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_cs_n}]
set_property -dict {LOC E33  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_act_n}]
set_property -dict {LOC J31  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_odt}]
set_property -dict {LOC R29  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_c1_par}]
set_property -dict {LOC M28  IOSTANDARD LVCMOS12       } [get_ports {ddr4_c1_reset_n}]
set_property -dict {LOC J40  IOSTANDARD LVCMOS12       } [get_ports {ddr4_c1_alert_n}]

set_property -dict {LOC J37  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[0]}]       ;# U60.G2 DQL0
set_property -dict {LOC H40  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[1]}]       ;# U60.F7 DQL1
set_property -dict {LOC F38  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[2]}]       ;# U60.H3 DQL2
set_property -dict {LOC H39  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[3]}]       ;# U60.H7 DQL3
set_property -dict {LOC K37  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[4]}]       ;# U60.H2 DQL4
set_property -dict {LOC G40  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[5]}]       ;# U60.H8 DQL5
set_property -dict {LOC F39  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[6]}]       ;# U60.J3 DQL6
set_property -dict {LOC F40  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[7]}]       ;# U60.J7 DQL7
set_property -dict {LOC F36  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[8]}]       ;# U60.A3 DQU0
set_property -dict {LOC J36  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[9]}]       ;# U60.B8 DQU1
set_property -dict {LOC F35  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[10]}]      ;# U60.C3 DQU2
set_property -dict {LOC J35  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[11]}]      ;# U60.C7 DQU3
set_property -dict {LOC G37  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[12]}]      ;# U60.C2 DQU4
set_property -dict {LOC H35  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[13]}]      ;# U60.C8 DQU5
set_property -dict {LOC G36  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[14]}]      ;# U60.D3 DQU6
set_property -dict {LOC H37  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[15]}]      ;# U60.D7 DQU7
set_property -dict {LOC H38  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_t[0]}]    ;# U60.G3 DQSL_T
set_property -dict {LOC G38  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_c[0]}]    ;# U60.F3 DQSL_C
set_property -dict {LOC H34  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_t[1]}]    ;# U60.B7 DQSU_T
set_property -dict {LOC G35  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_c[1]}]    ;# U60.A7 DQSU_C
set_property -dict {LOC J39  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dm_dbi_n[0]}] ;# U60.E7 DML_B/DBIL_B
set_property -dict {LOC F34  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dm_dbi_n[1]}] ;# U60.E2 DMU_B/DBIU_B

set_property -dict {LOC C39  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[16]}]      ;# U61.G2 DQL0
set_property -dict {LOC A38  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[17]}]      ;# U61.F7 DQL1
set_property -dict {LOC B40  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[18]}]      ;# U61.H3 DQL2
set_property -dict {LOC D40  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[19]}]      ;# U61.H7 DQL3
set_property -dict {LOC E38  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[20]}]      ;# U61.H2 DQL4
set_property -dict {LOC B38  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[21]}]      ;# U61.H8 DQL5
set_property -dict {LOC E37  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[22]}]      ;# U61.J3 DQL6
set_property -dict {LOC C40  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[23]}]      ;# U61.J7 DQL7
set_property -dict {LOC C34  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[24]}]      ;# U61.A3 DQU0
set_property -dict {LOC A34  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[25]}]      ;# U61.B8 DQU1
set_property -dict {LOC D34  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[26]}]      ;# U61.C3 DQU2
set_property -dict {LOC A35  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[27]}]      ;# U61.C7 DQU3
set_property -dict {LOC A36  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[28]}]      ;# U61.C2 DQU4
set_property -dict {LOC C35  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[29]}]      ;# U61.C8 DQU5
set_property -dict {LOC B35  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[30]}]      ;# U61.D3 DQU6
set_property -dict {LOC D35  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[31]}]      ;# U61.D7 DQU7
set_property -dict {LOC A39  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_t[2]}]    ;# U61.G3 DQSL_T
set_property -dict {LOC A40  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_c[2]}]    ;# U61.F3 DQSL_C
set_property -dict {LOC B36  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_t[3]}]    ;# U61.B7 DQSU_T
set_property -dict {LOC B37  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_c[3]}]    ;# U61.A7 DQSU_C
set_property -dict {LOC E39  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dm_dbi_n[2]}] ;# U61.E7 DML_B/DBIL_B
set_property -dict {LOC D37  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dm_dbi_n[3]}] ;# U61.E2 DMU_B/DBIU_B

set_property -dict {LOC N27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[32]}]      ;# U62.G2 DQL0
set_property -dict {LOC R27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[33]}]      ;# U62.F7 DQL1
set_property -dict {LOC N24  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[34]}]      ;# U62.H3 DQL2
set_property -dict {LOC R24  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[35]}]      ;# U62.H7 DQL3
set_property -dict {LOC P24  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[36]}]      ;# U62.H2 DQL4
set_property -dict {LOC P26  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[37]}]      ;# U62.H8 DQL5
set_property -dict {LOC P27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[38]}]      ;# U62.J3 DQL6
set_property -dict {LOC T24  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[39]}]      ;# U62.J7 DQL7
set_property -dict {LOC K27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[40]}]      ;# U62.A3 DQU0
set_property -dict {LOC L26  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[41]}]      ;# U62.B8 DQU1
set_property -dict {LOC J27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[42]}]      ;# U62.C3 DQU2
set_property -dict {LOC K28  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[43]}]      ;# U62.C7 DQU3
set_property -dict {LOC K26  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[44]}]      ;# U62.C2 DQU4
set_property -dict {LOC M25  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[45]}]      ;# U62.C8 DQU5
set_property -dict {LOC J26  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[46]}]      ;# U62.D3 DQU6
set_property -dict {LOC L28  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[47]}]      ;# U62.D7 DQU7
set_property -dict {LOC P25  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_t[4]}]    ;# U62.G3 DQSL_T
set_property -dict {LOC N25  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_c[4]}]    ;# U62.F3 DQSL_C
set_property -dict {LOC L24  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_t[5]}]    ;# U62.B7 DQSU_T
set_property -dict {LOC L25  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_c[5]}]    ;# U62.A7 DQSU_C
set_property -dict {LOC T26  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dm_dbi_n[4]}] ;# U62.E7 DML_B/DBIL_B
set_property -dict {LOC M27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dm_dbi_n[5]}] ;# U62.E2 DMU_B/DBIU_B

set_property -dict {LOC E27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[48]}]      ;# U63.G2 DQL0
set_property -dict {LOC E28  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[49]}]      ;# U63.F7 DQL1
set_property -dict {LOC E26  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[50]}]      ;# U63.H3 DQL2
set_property -dict {LOC H27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[51]}]      ;# U63.H7 DQL3
set_property -dict {LOC F25  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[52]}]      ;# U63.H2 DQL4
set_property -dict {LOC F28  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[53]}]      ;# U63.H8 DQL5
set_property -dict {LOC G25  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[54]}]      ;# U63.J3 DQL6
set_property -dict {LOC G27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[55]}]      ;# U63.J7 DQL7
set_property -dict {LOC B28  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[56]}]      ;# U63.A3 DQU0
set_property -dict {LOC A28  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[57]}]      ;# U63.B8 DQU1
set_property -dict {LOC B25  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[58]}]      ;# U63.C3 DQU2
set_property -dict {LOC B27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[59]}]      ;# U63.C7 DQU3
set_property -dict {LOC D25  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[60]}]      ;# U63.C2 DQU4
set_property -dict {LOC C27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[61]}]      ;# U63.C8 DQU5
set_property -dict {LOC C25  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[62]}]      ;# U63.D3 DQU6
set_property -dict {LOC D26  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[63]}]      ;# U63.D7 DQU7
set_property -dict {LOC H28  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_t[6]}]    ;# U63.G3 DQSL_T
set_property -dict {LOC G28  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_c[6]}]    ;# U63.F3 DQSL_C
set_property -dict {LOC B26  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_t[7]}]    ;# U63.B7 DQSU_T
set_property -dict {LOC A26  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_c[7]}]    ;# U63.A7 DQSU_C
set_property -dict {LOC G26  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dm_dbi_n[6]}] ;# U63.E7 DML_B/DBIL_B
set_property -dict {LOC D27  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dm_dbi_n[7]}] ;# U63.E2 DMU_B/DBIU_B

set_property -dict {LOC N29  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[64]}]      ;# U64.G2 DQL0
set_property -dict {LOC M31  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[65]}]      ;# U64.F7 DQL1
set_property -dict {LOC P29  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[66]}]      ;# U64.H3 DQL2
set_property -dict {LOC L29  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[67]}]      ;# U64.H7 DQL3
set_property -dict {LOC P30  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[68]}]      ;# U64.H2 DQL4
set_property -dict {LOC N28  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[69]}]      ;# U64.H8 DQL5
set_property -dict {LOC L31  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[70]}]      ;# U64.J3 DQL6
set_property -dict {LOC L30  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[71]}]      ;# U64.J7 DQL7
set_property -dict {LOC H30  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[72]}]      ;# U64.A3 DQU0
set_property -dict {LOC J32  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[73]}]      ;# U64.B8 DQU1
set_property -dict {LOC H29  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[74]}]      ;# U64.C3 DQU2
set_property -dict {LOC H32  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[75]}]      ;# U64.C7 DQU3
set_property -dict {LOC J29  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[76]}]      ;# U64.C2 DQU4
set_property -dict {LOC K32  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[77]}]      ;# U64.C8 DQU5
set_property -dict {LOC J30  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[78]}]      ;# U64.D3 DQU6
set_property -dict {LOC G32  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dq[79]}]      ;# U64.D7 DQU7
set_property -dict {LOC N30  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_t[8]}]    ;# U64.G3 DQSL_T
set_property -dict {LOC M30  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_c[8]}]    ;# U64.F3 DQSL_C
set_property -dict {LOC H33  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_t[9]}]    ;# U64.B7 DQSU_T
set_property -dict {LOC G33  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_c1_dqs_c[9]}]    ;# U64.A7 DQSU_C
set_property -dict {LOC R28  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dm_dbi_n[8]}] ;# U64.E7 DML_B/DBIL_B
set_property -dict {LOC K31  IOSTANDARD POD12_DCI      } [get_ports {ddr4_c1_dm_dbi_n[9]}] ;# U64.E2 DMU_B/DBIU_B
