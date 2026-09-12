# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU111 board
# part: xczu28dr-ffvg1517-2-e

# DDR4 components
# 4x MT40A512M16JY-075E
set_property -dict {LOC D18  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[0]}]
set_property -dict {LOC E19  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[1]}]
set_property -dict {LOC E17  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[2]}]
set_property -dict {LOC E18  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[3]}]
set_property -dict {LOC E16  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[4]}]
set_property -dict {LOC F16  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[5]}]
set_property -dict {LOC F19  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[6]}]
set_property -dict {LOC G19  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[7]}]
set_property -dict {LOC F15  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[8]}]
set_property -dict {LOC G15  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[9]}]
set_property -dict {LOC G18  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[10]}]
set_property -dict {LOC H18  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[11]}]
set_property -dict {LOC K17  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[12]}]
set_property -dict {LOC L17  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[13]}]
set_property -dict {LOC B17  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[14]}]
set_property -dict {LOC D15  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[15]}]
set_property -dict {LOC C18  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_a[16]}]

set_property -dict {LOC A19  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_act_n}]
set_property -dict {LOC B18  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_alert_n}]

set_property -dict {LOC K18  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_ba[0]}]
set_property -dict {LOC K19  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_ba[1]}]
set_property -dict {LOC C16  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_bg[0]}]

set_property -dict {LOC A16  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_cke}]
set_property -dict {LOC G17  IOSTANDARD DIFF_SSTL2_DCI } [get_ports {ddr4_ck_t}]
set_property -dict {LOC F17  IOSTANDARD DIFF_SSTL2_DCI } [get_ports {ddr4_ck_c}]
set_property -dict {LOC D16  IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_cs_n}]

set_property -dict {LOC B19  IOSTANDARD LVCMOS12       } [get_ports {ddr4_odt}]
set_property -dict {LOC A17  IOSTANDARD LVCMOS12       } [get_ports {ddr4_rst_n}]
set_property -dict {LOC D19  IOSTANDARD LVCMOS12       } [get_ports {ddr4_par}]

set_property -dict {LOC D14  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[0]}]       ;# U80.G2 DQL0
set_property -dict {LOC E11  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[1]}]       ;# U80.F7 DQL1
set_property -dict {LOC F14  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[2]}]       ;# U80.H3 DQL2
set_property -dict {LOC F12  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[3]}]       ;# U80.H7 DQL3
set_property -dict {LOC E14  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[4]}]       ;# U80.H2 DQL4
set_property -dict {LOC H12  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[5]}]       ;# U80.H8 DQL5
set_property -dict {LOC G14  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[6]}]       ;# U80.J3 DQL6
set_property -dict {LOC H13  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[7]}]       ;# U80.J7 DQL7
set_property -dict {LOC B13  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[8]}]       ;# U80.A3 DQU0
set_property -dict {LOC A15  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[9]}]       ;# U80.B8 DQU1
set_property -dict {LOC A12  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[10]}]      ;# U80.C3 DQU2
set_property -dict {LOC A14  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[11]}]      ;# U80.C7 DQU3
set_property -dict {LOC D13  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[12]}]      ;# U80.C2 DQU4
set_property -dict {LOC B14  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[13]}]      ;# U80.C8 DQU5
set_property -dict {LOC A11  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[14]}]      ;# U80.D3 DQU6
set_property -dict {LOC C13  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[15]}]      ;# U80.D7 DQU7
set_property -dict {LOC E13  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[0]}]    ;# U80.G3 DQSL_T
set_property -dict {LOC E12  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[0]}]    ;# U80.F3 DQSL_C
set_property -dict {LOC C15  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[1]}]    ;# U80.B7 DQSU_T
set_property -dict {LOC B15  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[1]}]    ;# U80.A7 DQSU_C
set_property -dict {LOC G13  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[0]}] ;# U80.E7 DML_B/DBIL_B
set_property -dict {LOC C12  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[1]}] ;# U80.E2 DMU_B/DBIU_B

set_property -dict {LOC K11  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[16]}]      ;# U94.G2 DQL0
set_property -dict {LOC J11  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[17]}]      ;# U94.F7 DQL1
set_property -dict {LOC H10  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[18]}]      ;# U94.H3 DQL2
set_property -dict {LOC F11  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[19]}]      ;# U94.H7 DQL3
set_property -dict {LOC K10  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[20]}]      ;# U94.H2 DQL4
set_property -dict {LOC F10  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[21]}]      ;# U94.H8 DQL5
set_property -dict {LOC J10  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[22]}]      ;# U94.J3 DQL6
set_property -dict {LOC H11  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[23]}]      ;# U94.J7 DQL7
set_property -dict {LOC G9   IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[24]}]      ;# U94.A3 DQU0
set_property -dict {LOC G7   IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[25]}]      ;# U94.B8 DQU1
set_property -dict {LOC F9   IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[26]}]      ;# U94.C3 DQU2
set_property -dict {LOC G6   IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[27]}]      ;# U94.C7 DQU3
set_property -dict {LOC H6   IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[28]}]      ;# U94.C2 DQU4
set_property -dict {LOC H7   IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[29]}]      ;# U94.C8 DQU5
set_property -dict {LOC J9   IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[30]}]      ;# U94.D3 DQU6
set_property -dict {LOC K9   IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[31]}]      ;# U94.D7 DQU7
set_property -dict {LOC J14  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[2]}]    ;# U94.G3 DQSL_T
set_property -dict {LOC J13  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[2]}]    ;# U94.F3 DQSL_C
set_property -dict {LOC H8   IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[3]}]    ;# U94.B7 DQSU_T
set_property -dict {LOC G8   IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[3]}]    ;# U94.A7 DQSU_C
set_property -dict {LOC K13  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[2]}] ;# U94.E7 DML_B/DBIL_B
set_property -dict {LOC J8   IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[3]}] ;# U94.E2 DMU_B/DBIU_B

set_property -dict {LOC C22  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[32]}]      ;# U95.G2 DQL0
set_property -dict {LOC A20  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[33]}]      ;# U95.F7 DQL1
set_property -dict {LOC A21  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[34]}]      ;# U95.H3 DQL2
set_property -dict {LOC C21  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[35]}]      ;# U95.H7 DQL3
set_property -dict {LOC A24  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[36]}]      ;# U95.H2 DQL4
set_property -dict {LOC B20  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[37]}]      ;# U95.H8 DQL5
set_property -dict {LOC B24  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[38]}]      ;# U95.J3 DQL6
set_property -dict {LOC C20  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[39]}]      ;# U95.J7 DQL7
set_property -dict {LOC E24  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[40]}]      ;# U95.A3 DQU0
set_property -dict {LOC E22  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[41]}]      ;# U95.B8 DQU1
set_property -dict {LOC E23  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[42]}]      ;# U95.C3 DQU2
set_property -dict {LOC G20  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[43]}]      ;# U95.C7 DQU3
set_property -dict {LOC F24  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[44]}]      ;# U95.C2 DQU4
set_property -dict {LOC E21  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[45]}]      ;# U95.C8 DQU5
set_property -dict {LOC F20  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[46]}]      ;# U95.D3 DQU6
set_property -dict {LOC D21  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[47]}]      ;# U95.D7 DQU7
set_property -dict {LOC B22  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[4]}]    ;# U95.G3 DQSL_T
set_property -dict {LOC A22  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[4]}]    ;# U95.F3 DQSL_C
set_property -dict {LOC D23  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[5]}]    ;# U95.B7 DQSU_T
set_property -dict {LOC D24  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[5]}]    ;# U95.A7 DQSU_C
set_property -dict {LOC C23  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[4]}] ;# U95.E7 DML_B/DBIL_B
set_property -dict {LOC F21  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[5]}] ;# U95.E2 DMU_B/DBIU_B

set_property -dict {LOC H23  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[48]}]      ;# U96.G2 DQL0
set_property -dict {LOC G23  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[49]}]      ;# U96.F7 DQL1
set_property -dict {LOC K24  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[50]}]      ;# U96.H3 DQL2
set_property -dict {LOC G22  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[51]}]      ;# U96.H7 DQL3
set_property -dict {LOC J21  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[52]}]      ;# U96.H2 DQL4
set_property -dict {LOC H22  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[53]}]      ;# U96.H8 DQL5
set_property -dict {LOC L24  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[54]}]      ;# U96.J3 DQL6
set_property -dict {LOC H21  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[55]}]      ;# U96.J7 DQL7
set_property -dict {LOC L23  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[56]}]      ;# U96.A3 DQU0
set_property -dict {LOC L20  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[57]}]      ;# U96.B8 DQU1
set_property -dict {LOC L22  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[58]}]      ;# U96.C3 DQU2
set_property -dict {LOC L21  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[59]}]      ;# U96.C7 DQU3
set_property -dict {LOC M20  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[60]}]      ;# U96.C2 DQU4
set_property -dict {LOC L19  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[61]}]      ;# U96.C8 DQU5
set_property -dict {LOC M19  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[62]}]      ;# U96.D3 DQU6
set_property -dict {LOC N19  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[63]}]      ;# U96.D7 DQU7
set_property -dict {LOC J20  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[6]}]    ;# U96.G3 DQSL_T
set_property -dict {LOC H20  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[6]}]    ;# U96.F3 DQSL_C
set_property -dict {LOC K21  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[7]}]    ;# U96.B7 DQSU_T
set_property -dict {LOC K22  IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[7]}]    ;# U96.A7 DQSU_C
set_property -dict {LOC J23  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[6]}] ;# U96.E7 DML_B/DBIL_B
set_property -dict {LOC N20  IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[7]}] ;# U96.E2 DMU_B/DBIU_B
