# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U45N/SN1022 board
# part: xcu26-vsva1365-2LV-e

# 300 MHz (DDR4 C1)
set_property -dict {LOC H34  IOSTANDARD LVDS} [get_ports clk_ddr4_c1_p]
set_property -dict {LOC H35  IOSTANDARD LVDS} [get_ports clk_ddr4_c1_n]
#create_clock -period 10 -name clk_ddr4_c1 [get_ports clk_ddr4_c1_p]

# DDR4 C1
set_property -dict {LOC K32  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[0]}]      ;# Bank  72 VCCO  - Net DDR4_C1_A0              - IO_L6P_T0U_N10_AD6P_72
set_property -dict {LOC K37  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[1]}]      ;# Bank  72 VCCO  - Net DDR4_C1_A1              - IO_L9P_T1L_N4_AD12P_72
set_property -dict {LOC J31  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[2]}]      ;# Bank  72 VCCO  - Net DDR4_C1_A2              - IO_L5N_T0U_N9_AD14N_72
set_property -dict {LOC J35  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[3]}]      ;# Bank  72 VCCO  - Net DDR4_C1_A3              - IO_L11P_T1U_N8_GC_72
set_property -dict {LOC L34  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[4]}]      ;# Bank  72 VCCO  - Net DDR4_C1_A4              - IO_L10P_T1U_N6_QBC_AD4P_72
set_property -dict {LOC E37  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[5]}]      ;# Bank  72 VCCO  - Net DDR4_C1_A5              - IO_L17N_T2U_N9_AD10N_72
set_property -dict {LOC L36  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[6]}]      ;# Bank  72 VCCO  - Net DDR4_C1_A6              - IO_L7N_T1L_N1_QBC_AD13N_72
set_property -dict {LOC F35  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[7]}]      ;# Bank  72 VCCO  - Net DDR4_C1_A7              - IO_L16N_T2U_N7_QBC_AD3N_72
set_property -dict {LOC M35  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[8]}]      ;# Bank  72 VCCO  - Net DDR4_C1_A8              - IO_L7P_T1L_N0_QBC_AD13P_72
set_property -dict {LOC M37  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[9]}]      ;# Bank  72 VCCO  - Net DDR4_C1_A9              - IO_L8N_T1L_N3_AD5N_72
set_property -dict {LOC J32  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[10]}]     ;# Bank  72 VCCO  - Net DDR4_C1_A10             - IO_L6N_T0U_N11_AD6N_72
set_property -dict {LOC M36  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[11]}]     ;# Bank  72 VCCO  - Net DDR4_C1_A11             - IO_L8P_T1L_N2_AD5P_72
set_property -dict {LOC H37  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[12]}]     ;# Bank  72 VCCO  - Net DDR4_C1_A12             - IO_L15P_T2L_N4_AD11P_72
set_property -dict {LOC F36  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[13]}]     ;# Bank  72 VCCO  - Net DDR4_C1_A13             - IO_T2U_N12_72
set_property -dict {LOC M32  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[14]}]     ;# Bank  72 VCCO  - Net DDR4_C1_WE_B            - IO_L2P_T0L_N2_72
set_property -dict {LOC E34  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[15]}]     ;# Bank  72 VCCO  - Net DDR4_C1_CAS_B           - IO_L18P_T2U_N10_AD2P_72
set_property -dict {LOC D34  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_adr[16]}]     ;# Bank  72 VCCO  - Net DDR4_C1_RAS_B           - IO_L18N_T2U_N11_AD2N_72
set_property -dict {LOC K36  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_ba[0]}]       ;# Bank  72 VCCO  - Net DDR4_C1_BA0             - IO_T1U_N12_72
set_property -dict {LOC E36  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_ba[1]}]       ;# Bank  72 VCCO  - Net DDR4_C1_BA1             - IO_L17P_T2U_N8_AD10P_72
set_property -dict {LOC J36  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_bg[0]}]       ;# Bank  72 VCCO  - Net DDR4_C1_BG0             - IO_L11N_T1U_N9_GC_72
set_property -dict {LOC G36  IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_c1_ck_c[0]}]     ;# Bank  72 VCCO  - Net DDR4_C1_CK0_C           - IO_L14N_T2L_N3_GC_72
set_property -dict {LOC G35  IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_c1_ck_t[0]}]     ;# Bank  72 VCCO  - Net DDR4_C1_CK0_T           - IO_L14P_T2L_N2_GC_72
set_property -dict {LOC K29  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_cke[0]}]      ;# Bank  72 VCCO  - Net DDR4_C1_CKE0            - IO_L4P_T0U_N6_DBC_AD7P_72
set_property -dict {LOC G37  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_cs_n[0]}]     ;# Bank  72 VCCO  - Net DDR4_C1_CS0_B           - IO_L15N_T2L_N5_AD11N_72
set_property -dict {LOC J34  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_act_n}]       ;# Bank  72 VCCO  - Net DDR4_C1_ACT_B           - IO_L12N_T1U_N11_GC_72
set_property -dict {LOC J37  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_odt[0]}]      ;# Bank  72 VCCO  - Net DDR4_C1_ODT0            - IO_L9N_T1L_N5_AD12N_72
set_property -dict {LOC J30  IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c1_par}]         ;# Bank  72 VCCO  - Net DDR4_C1_PARITY          - IO_L5P_T0U_N8_AD14P_72
set_property -dict {LOC L29  IOSTANDARD LVCMOS12}        [get_ports {ddr4_c1_reset_n}]     ;# Bank  72 VCCO  - Net DDR4_C1_RESET_B_FPGA    - IO_L1P_T0L_N0_DBC_72
set_property -dict {LOC L35  IOSTANDARD LVCMOS12}        [get_ports {ddr4_c1_alert_n}]     ;# Bank  72 VCCO  - Net DDR4_C1_ALERT_B         - IO_L10N_T1U_N7_QBC_AD4N_72

set_property -dict {LOC A28  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[0]}]       ;# Bank  73 VCCO  - Net DDR4_C1_DQ0             - IO_L23P_T3U_N8_73
set_property -dict {LOC C25  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[1]}]       ;# Bank  73 VCCO  - Net DDR4_C1_DQ1             - IO_L21N_T3L_N5_AD8N_73
set_property -dict {LOC A26  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[2]}]       ;# Bank  73 VCCO  - Net DDR4_C1_DQ2             - IO_L24N_T3U_N11_73
set_property -dict {LOC D25  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[3]}]       ;# Bank  73 VCCO  - Net DDR4_C1_DQ3             - IO_L21P_T3L_N4_AD8P_73
set_property -dict {LOC A29  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[4]}]       ;# Bank  73 VCCO  - Net DDR4_C1_DQ4             - IO_L23N_T3U_N9_73
set_property -dict {LOC D27  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[5]}]       ;# Bank  73 VCCO  - Net DDR4_C1_DQ5             - IO_L20N_T3L_N3_AD1N_73
set_property -dict {LOC B26  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[6]}]       ;# Bank  73 VCCO  - Net DDR4_C1_DQ6             - IO_L24P_T3U_N10_73
set_property -dict {LOC D26  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[7]}]       ;# Bank  73 VCCO  - Net DDR4_C1_DQ7             - IO_L20P_T3L_N2_AD1P_73
set_property -dict {LOC G27  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[8]}]       ;# Bank  73 VCCO  - Net DDR4_C1_DQ8             - IO_L3N_T0L_N5_AD15N_73
set_property -dict {LOC E26  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[9]}]       ;# Bank  73 VCCO  - Net DDR4_C1_DQ9             - IO_L5P_T0U_N8_AD14P_73
set_property -dict {LOC H27  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[10]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ10            - IO_L3P_T0L_N4_AD15P_73
set_property -dict {LOC F28  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[11]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ11            - IO_L6P_T0U_N10_AD6P_73
set_property -dict {LOC E27  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[12]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ12            - IO_L5N_T0U_N9_AD14N_73
set_property -dict {LOC F26  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[13]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ13            - IO_L2N_T0L_N3_73
set_property -dict {LOC G26  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[14]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ14            - IO_L2P_T0L_N2_73
set_property -dict {LOC E28  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[15]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ15            - IO_L6N_T0U_N11_AD6N_73
set_property -dict {LOC B27  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_t[0]}]    ;# Bank  73 VCCO  - Net DDR4_C1_DQS_T0          - IO_L22P_T3U_N6_DBC_AD0P_73
set_property -dict {LOC B28  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_c[0]}]    ;# Bank  73 VCCO  - Net DDR4_C1_DQS_C0          - IO_L22N_T3U_N7_DBC_AD0N_73
set_property -dict {LOC H28  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_t[1]}]    ;# Bank  73 VCCO  - Net DDR4_C1_DQS_T1          - IO_L4P_T0U_N6_DBC_AD7P_73
set_property -dict {LOC G28  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_c[1]}]    ;# Bank  73 VCCO  - Net DDR4_C1_DQS_C1          - IO_L4N_T0U_N7_DBC_AD7N_73
set_property -dict {LOC C28  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dm_dbi_n[0]}] ;# Bank  73 VCCO  - Net DDR4_C1_DM_B0           - IO_L19P_T3L_N0_DBC_AD9P_73
set_property -dict {LOC H25  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dm_dbi_n[1]}] ;# Bank  73 VCCO  - Net DDR4_C1_DM_B1           - IO_L1P_T0L_N0_DBC_73

set_property -dict {LOC D30  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[16]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ16            - IO_L14P_T2L_N2_GC_73
set_property -dict {LOC A30  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[17]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ17            - IO_L18P_T2U_N10_AD2P_73
set_property -dict {LOC A31  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[18]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ18            - IO_L18N_T2U_N11_AD2N_73
set_property -dict {LOC B30  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[19]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ19            - IO_L17N_T2U_N9_AD10N_73
set_property -dict {LOC D31  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[20]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ20            - IO_L14N_T2L_N3_GC_73
set_property -dict {LOC C30  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[21]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ21            - IO_L17P_T2U_N8_AD10P_73
set_property -dict {LOC E29  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[22]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ22            - IO_L15P_T2L_N4_AD11P_73
set_property -dict {LOC D29  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[23]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ23            - IO_L15N_T2L_N5_AD11N_73
set_property -dict {LOC E33  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[24]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ24            - IO_L9N_T1L_N5_AD12N_73
set_property -dict {LOC F29  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[25]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ25            - IO_L11P_T1U_N8_GC_73
set_property -dict {LOC F33  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[26]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ26            - IO_L9P_T1L_N4_AD12P_73
set_property -dict {LOC F30  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[27]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ27            - IO_L11N_T1U_N9_GC_73
set_property -dict {LOC H33  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[28]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ28            - IO_L8P_T1L_N2_AD5P_73
set_property -dict {LOC E31  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[29]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ29            - IO_L12N_T1U_N11_GC_73
set_property -dict {LOC G33  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[30]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ30            - IO_L8N_T1L_N3_AD5N_73
set_property -dict {LOC F31  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[31]}]      ;# Bank  73 VCCO  - Net DDR4_C1_DQ31            - IO_L12P_T1U_N10_GC_73
set_property -dict {LOC C32  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_t[2]}]    ;# Bank  73 VCCO  - Net DDR4_C1_DQS_T2          - IO_L16P_T2U_N6_QBC_AD3P_73
set_property -dict {LOC B32  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_c[2]}]    ;# Bank  73 VCCO  - Net DDR4_C1_DQS_C2          - IO_L16N_T2U_N7_QBC_AD3N_73
set_property -dict {LOC G30  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_t[3]}]    ;# Bank  73 VCCO  - Net DDR4_C1_DQS_T3          - IO_L10P_T1U_N6_QBC_AD4P_73
set_property -dict {LOC G31  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_c[3]}]    ;# Bank  73 VCCO  - Net DDR4_C1_DQS_C3          - IO_L10N_T1U_N7_QBC_AD4N_73
set_property -dict {LOC E32  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dm_dbi_n[2]}] ;# Bank  73 VCCO  - Net DDR4_C1_DM_B2           - IO_L13P_T2L_N0_GC_QBC_73
set_property -dict {LOC H32  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dm_dbi_n[3]}] ;# Bank  73 VCCO  - Net DDR4_C1_DM_B3           - IO_L7P_T1L_N0_QBC_AD13P_73

set_property -dict {LOC B25  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[32]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ32            - IO_L24P_T3U_N10_74
set_property -dict {LOC C22  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[33]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ33            - IO_L20N_T3L_N3_AD1N_74
set_property -dict {LOC A23  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[34]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ34            - IO_L23P_T3U_N8_74
set_property -dict {LOC A24  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[35]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ35            - IO_L23N_T3U_N9_74
set_property -dict {LOC A25  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[36]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ36            - IO_L24N_T3U_N11_74
set_property -dict {LOC D24  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[37]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ37            - IO_L21P_T3L_N4_AD8P_74
set_property -dict {LOC C24  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[38]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ38            - IO_L21N_T3L_N5_AD8N_74
set_property -dict {LOC D22  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[39]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ39            - IO_L20P_T3L_N2_AD1P_74
set_property -dict {LOC F23  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[40]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ40            - IO_L9P_T1L_N4_AD12P_74
set_property -dict {LOC G21  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[41]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ41            - IO_L11P_T1U_N8_GC_74
set_property -dict {LOC F24  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[42]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ42            - IO_L9N_T1L_N5_AD12N_74
set_property -dict {LOC F20  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[43]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ43            - IO_L12N_T1U_N11_GC_74
set_property -dict {LOC H23  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[44]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ44            - IO_L8P_T1L_N2_AD5P_74
set_property -dict {LOC F19  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[45]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ45            - IO_L12P_T1U_N10_GC_74
set_property -dict {LOC H24  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[46]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ46            - IO_L8N_T1L_N3_AD5N_74
set_property -dict {LOC F21  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[47]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ47            - IO_L11N_T1U_N9_GC_74
set_property -dict {LOC B22  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_t[4]}]    ;# Bank  74 VCCO  - Net DDR4_C1_DQS_T4          - IO_L22P_T3U_N6_DBC_AD0P_74
set_property -dict {LOC B23  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_c[4]}]    ;# Bank  74 VCCO  - Net DDR4_C1_DQS_C4          - IO_L22N_T3U_N7_DBC_AD0N_74
set_property -dict {LOC H19  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_t[5]}]    ;# Bank  74 VCCO  - Net DDR4_C1_DQS_T5          - IO_L10P_T1U_N6_QBC_AD4P_74
set_property -dict {LOC H20  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_c[5]}]    ;# Bank  74 VCCO  - Net DDR4_C1_DQS_C5          - IO_L10N_T1U_N7_QBC_AD4N_74
set_property -dict {LOC E23  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dm_dbi_n[4]}] ;# Bank  74 VCCO  - Net DDR4_C1_DM_B4           - IO_L19P_T3L_N0_DBC_AD9P_74
set_property -dict {LOC H22  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dm_dbi_n[5]}] ;# Bank  74 VCCO  - Net DDR4_C1_DM_B5           - IO_L7P_T1L_N0_QBC_AD13P_74

set_property -dict {LOC G18  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[48]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ48            - IO_L6P_T0U_N10_AD6P_74
set_property -dict {LOC G17  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[49]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ49            - IO_L3N_T0L_N5_AD15N_74
set_property -dict {LOC F16  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[50]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ50            - IO_L5P_T0U_N8_AD14P_74
set_property -dict {LOC G16  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[51]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ51            - IO_L3P_T0L_N4_AD15P_74
set_property -dict {LOC F18  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[52]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ52            - IO_L6N_T0U_N11_AD6N_74
set_property -dict {LOC H15  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[53]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ53            - IO_L2P_T0L_N2_74
set_property -dict {LOC E16  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[54]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ54            - IO_L5N_T0U_N9_AD14N_74
set_property -dict {LOC G15  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[55]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ55            - IO_L2N_T0L_N3_74
set_property -dict {LOC B21  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[56]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ56            - IO_L18P_T2U_N10_AD2P_74
set_property -dict {LOC D20  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[57]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ57            - IO_L14P_T2L_N2_GC_74
set_property -dict {LOC A21  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[58]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ58            - IO_L18N_T2U_N11_AD2N_74
set_property -dict {LOC B20  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[59]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ59            - IO_L17P_T2U_N8_AD10P_74
set_property -dict {LOC E22  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[60]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ60            - IO_L15N_T2L_N5_AD11N_74
set_property -dict {LOC C20  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[61]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ61            - IO_L14N_T2L_N3_GC_74
set_property -dict {LOC E21  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[62]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ62            - IO_L15P_T2L_N4_AD11P_74
set_property -dict {LOC A20  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[63]}]      ;# Bank  74 VCCO  - Net DDR4_C1_DQ63            - IO_L17N_T2U_N9_AD10N_74
set_property -dict {LOC H17  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_t[6]}]    ;# Bank  74 VCCO  - Net DDR4_C1_DQS_T6          - IO_L4P_T0U_N6_DBC_AD7P_74
set_property -dict {LOC H18  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_c[6]}]    ;# Bank  74 VCCO  - Net DDR4_C1_DQS_C6          - IO_L4N_T0U_N7_DBC_AD7N_74
set_property -dict {LOC A18  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_t[7]}]    ;# Bank  74 VCCO  - Net DDR4_C1_DQS_T7          - IO_L16P_T2U_N6_QBC_AD3P_74
set_property -dict {LOC A19  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_c[7]}]    ;# Bank  74 VCCO  - Net DDR4_C1_DQS_C7          - IO_L16N_T2U_N7_QBC_AD3N_74
set_property -dict {LOC H14  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dm_dbi_n[6]}] ;# Bank  74 VCCO  - Net DDR4_C1_DM_B6           - IO_L1P_T0L_N0_DBC_74
set_property -dict {LOC E18  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dm_dbi_n[7]}] ;# Bank  74 VCCO  - Net DDR4_C1_DM_B7           - IO_L13P_T2L_N0_GC_QBC_74

set_property -dict {LOC C37  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[64]}]      ;# Bank  72 VCCO  - Net DDR4_C1_DQ64            - IO_L20N_T3L_N3_AD1N_72
set_property -dict {LOC A34  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[65]}]      ;# Bank  72 VCCO  - Net DDR4_C1_DQ65            - IO_L23P_T3U_N8_72
set_property -dict {LOC C35  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[66]}]      ;# Bank  72 VCCO  - Net DDR4_C1_DQ66            - IO_L21N_T3L_N5_AD8N_72
set_property -dict {LOC C34  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[67]}]      ;# Bank  72 VCCO  - Net DDR4_C1_DQ67            - IO_L21P_T3L_N4_AD8P_72
set_property -dict {LOC D37  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[68]}]      ;# Bank  72 VCCO  - Net DDR4_C1_DQ68            - IO_L20P_T3L_N2_AD1P_72
set_property -dict {LOC B33  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[69]}]      ;# Bank  72 VCCO  - Net DDR4_C1_DQ69            - IO_L24P_T3U_N10_72
set_property -dict {LOC A35  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[70]}]      ;# Bank  72 VCCO  - Net DDR4_C1_DQ70            - IO_L23N_T3U_N9_72
set_property -dict {LOC A33  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dq[71]}]      ;# Bank  72 VCCO  - Net DDR4_C1_DQ71            - IO_L24N_T3U_N11_72
set_property -dict {LOC B35  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_t[8]}]    ;# Bank  72 VCCO  - Net DDR4_C1_DQS_T8          - IO_L22P_T3U_N6_DBC_AD0P_72
set_property -dict {LOC B36  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c1_dqs_c[8]}]    ;# Bank  72 VCCO  - Net DDR4_C1_DQS_C8          - IO_L22N_T3U_N7_DBC_AD0N_72
set_property -dict {LOC D35  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c1_dm_dbi_n[8]}] ;# Bank  72 VCCO  - Net DDR4_C1_DM_B8           - IO_L19P_T3L_N0_DBC_AD9P_72
