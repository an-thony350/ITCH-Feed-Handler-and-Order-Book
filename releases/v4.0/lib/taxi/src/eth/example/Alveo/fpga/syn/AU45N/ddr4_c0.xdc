# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U45N/SN1022 board
# part: xcu26-vsva1365-2LV-e

# 300 MHz (DDR4 C0)
set_property -dict {LOC AN27 IOSTANDARD LVDS} [get_ports clk_ddr4_c0_p]
set_property -dict {LOC AN28 IOSTANDARD LVDS} [get_ports clk_ddr4_c0_n]
#create_clock -period 10 -name clk_ddr4_c0 [get_ports clk_ddr4_c0_p]

# DDR4 C0
set_property -dict {LOC AT30 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[0]}]      ;# Bank  66 VCCO  - Net DDR4_C0_A0              - IO_L6N_T0U_N11_AD6N_66
set_property -dict {LOC AJ27 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[1]}]      ;# Bank  66 VCCO  - Net DDR4_C0_A1              - IO_L17P_T2U_N8_AD10P_66
set_property -dict {LOC AP30 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[2]}]      ;# Bank  66 VCCO  - Net DDR4_C0_A2              - IO_L4N_T0U_N7_DBC_AD7N_66
set_property -dict {LOC AM31 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[3]}]      ;# Bank  66 VCCO  - Net DDR4_C0_A3              - IO_L2N_T0L_N3_66
set_property -dict {LOC AM30 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[4]}]      ;# Bank  66 VCCO  - Net DDR4_C0_A4              - IO_L2P_T0L_N2_66
set_property -dict {LOC AP29 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[5]}]      ;# Bank  66 VCCO  - Net DDR4_C0_A5              - IO_L4P_T0U_N6_DBC_AD7P_66
set_property -dict {LOC AU25 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[6]}]      ;# Bank  66 VCCO  - Net DDR4_C0_A6              - IO_T1U_N12_66
set_property -dict {LOC AP27 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[7]}]      ;# Bank  66 VCCO  - Net DDR4_C0_A7              - IO_L12N_T1U_N11_GC_66
set_property -dict {LOC AR26 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[8]}]      ;# Bank  66 VCCO  - Net DDR4_C0_A8              - IO_L11P_T1U_N8_GC_66
set_property -dict {LOC AL26 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[9]}]      ;# Bank  66 VCCO  - Net DDR4_C0_A9              - IO_L16N_T2U_N7_QBC_AD3N_66
set_property -dict {LOC AT31 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[10]}]     ;# Bank  66 VCCO  - Net DDR4_C0_A10             - IO_L5N_T0U_N9_AD14N_66
set_property -dict {LOC AP26 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[11]}]     ;# Bank  66 VCCO  - Net DDR4_C0_A11             - IO_L12P_T1U_N10_GC_66
set_property -dict {LOC AL31 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[12]}]     ;# Bank  66 VCCO  - Net DDR4_C0_A12             - IO_L1N_T0L_N1_DBC_66
set_property -dict {LOC AN29 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[13]}]     ;# Bank  66 VCCO  - Net DDR4_C0_A13             - IO_L3P_T0L_N4_AD15P_66
set_property -dict {LOC AR27 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[14]}]     ;# Bank  66 VCCO  - Net DDR4_C0_WE_B            - IO_L11N_T1U_N9_GC_66
set_property -dict {LOC AR28 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[15]}]     ;# Bank  66 VCCO  - Net DDR4_C0_CAS_B           - IO_L8P_T1L_N2_AD5P_66
set_property -dict {LOC AU28 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_adr[16]}]     ;# Bank  66 VCCO  - Net DDR4_C0_RAS_B           - IO_L9N_T1L_N5_AD12N_66
set_property -dict {LOC AT26 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_ba[0]}]       ;# Bank  66 VCCO  - Net DDR4_C0_BA0             - IO_L10P_T1U_N6_QBC_AD4P_66
set_property -dict {LOC AU27 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_ba[1]}]       ;# Bank  66 VCCO  - Net DDR4_C0_BA1             - IO_L9P_T1L_N4_AD12P_66
set_property -dict {LOC AU26 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_bg[0]}]       ;# Bank  66 VCCO  - Net DDR4_C0_BG0             - IO_L10N_T1U_N7_QBC_AD4N_66
set_property -dict {LOC AU30 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_c0_ck_c[0]}]     ;# Bank  66 VCCO  - Net DDR4_C0_CK0_C           - IO_L7N_T1L_N1_QBC_AD13N_66
set_property -dict {LOC AT29 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_c0_ck_t[0]}]     ;# Bank  66 VCCO  - Net DDR4_C0_CK0_T           - IO_L7P_T1L_N0_QBC_AD13P_66
set_property -dict {LOC AT28 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_cke[0]}]      ;# Bank  66 VCCO  - Net DDR4_C0_CKE0            - IO_L8N_T1L_N3_AD5N_66
set_property -dict {LOC AL30 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_cs_n[0]}]     ;# Bank  66 VCCO  - Net DDR4_C0_CS0_B           - IO_L1P_T0L_N0_DBC_66
set_property -dict {LOC AN30 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_act_n}]       ;# Bank  66 VCCO  - Net DDR4_C0_ACT_B           - IO_L3N_T0L_N5_AD15N_66
set_property -dict {LOC AR31 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_odt[0]}]      ;# Bank  66 VCCO  - Net DDR4_C0_ODT0            - IO_L5P_T0U_N8_AD14P_66
set_property -dict {LOC AR29 IOSTANDARD SSTL12_DCI}      [get_ports {ddr4_c0_par}]         ;# Bank  66 VCCO  - Net DDR4_C0_PARITY          - IO_L6P_T0U_N10_AD6P_66
set_property -dict {LOC AK31 IOSTANDARD LVCMOS12}        [get_ports {ddr4_c0_reset_n}]     ;# Bank  66 VCCO  - Net DDR4_C0_RESET_B_FPGA    - IO_T3U_N12_66
set_property -dict {LOC AK26 IOSTANDARD LVCMOS12}        [get_ports {ddr4_c0_alert_n}]     ;# Bank  66 VCCO  - Net DDR4_C0_ALERT_B         - IO_L16P_T2U_N6_QBC_AD3P_66

set_property -dict {LOC AJ29 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[0]}]       ;# Bank  66 VCCO  - Net DDR4_C0_DQ0             - IO_L21N_T3L_N5_AD8N_66
set_property -dict {LOC AJ31 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[1]}]       ;# Bank  66 VCCO  - Net DDR4_C0_DQ1             - IO_L20N_T3L_N3_AD1N_66
set_property -dict {LOC AF30 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[2]}]       ;# Bank  66 VCCO  - Net DDR4_C0_DQ2             - IO_L23N_T3U_N9_66
set_property -dict {LOC AF29 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[3]}]       ;# Bank  66 VCCO  - Net DDR4_C0_DQ3             - IO_L23P_T3U_N8_66
set_property -dict {LOC AH29 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[4]}]       ;# Bank  66 VCCO  - Net DDR4_C0_DQ4             - IO_L21P_T3L_N4_AD8P_66
set_property -dict {LOC AG31 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[5]}]       ;# Bank  66 VCCO  - Net DDR4_C0_DQ5             - IO_L24N_T3U_N11_66
set_property -dict {LOC AJ30 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[6]}]       ;# Bank  66 VCCO  - Net DDR4_C0_DQ6             - IO_L20P_T3L_N2_AD1P_66
set_property -dict {LOC AF31 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[7]}]       ;# Bank  66 VCCO  - Net DDR4_C0_DQ7             - IO_L24P_T3U_N10_66
set_property -dict {LOC AP36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[8]}]       ;# Bank  67 VCCO  - Net DDR4_C0_DQ8             - IO_L8P_T1L_N2_AD5P_67
set_property -dict {LOC AM35 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[9]}]       ;# Bank  67 VCCO  - Net DDR4_C0_DQ9             - IO_L12P_T1U_N10_GC_67
set_property -dict {LOC AR37 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[10]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ10            - IO_L8N_T1L_N3_AD5N_67
set_property -dict {LOC AN35 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[11]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ11            - IO_L12N_T1U_N11_GC_67
set_property -dict {LOC AN33 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[12]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ12            - IO_L9P_T1L_N4_AD12P_67
set_property -dict {LOC AN34 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[13]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ13            - IO_L11N_T1U_N9_GC_67
set_property -dict {LOC AP34 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[14]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ14            - IO_L9N_T1L_N5_AD12N_67
set_property -dict {LOC AM33 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[15]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ15            - IO_L11P_T1U_N8_GC_67
set_property -dict {LOC AG30 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_t[0]}]    ;# Bank  66 VCCO  - Net DDR4_C0_DQS_T0          - IO_L22P_T3U_N6_DBC_AD0P_66
set_property -dict {LOC AH30 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_c[0]}]    ;# Bank  66 VCCO  - Net DDR4_C0_DQS_C0          - IO_L22N_T3U_N7_DBC_AD0N_66
set_property -dict {LOC AM32 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_t[1]}]    ;# Bank  67 VCCO  - Net DDR4_C0_DQS_T1          - IO_L10P_T1U_N6_QBC_AD4P_67
set_property -dict {LOC AN32 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_c[1]}]    ;# Bank  67 VCCO  - Net DDR4_C0_DQS_C1          - IO_L10N_T1U_N7_QBC_AD4N_67
set_property -dict {LOC AK29 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dm_dbi_n[0]}] ;# Bank  66 VCCO  - Net DDR4_C0_DM_B0           - IO_L19P_T3L_N0_DBC_AD9P_66
set_property -dict {LOC AN37 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dm_dbi_n[1]}] ;# Bank  67 VCCO  - Net DDR4_C0_DM_B1           - IO_L7P_T1L_N0_QBC_AD13P_67

set_property -dict {LOC AA29 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[16]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ16            - IO_L24N_T3U_N11_68
set_property -dict {LOC W32  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[17]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ17            - IO_L20P_T3L_N2_AD1P_68
set_property -dict {LOC Y32  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[18]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ18            - IO_L20N_T3L_N3_AD1N_68
set_property -dict {LOC W31  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[19]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ19            - IO_L23N_T3U_N9_68
set_property -dict {LOC AB32 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[20]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ20            - IO_L21N_T3L_N5_AD8N_68
set_property -dict {LOC W30  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[21]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ21            - IO_L23P_T3U_N8_68
set_property -dict {LOC AB31 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[22]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ22            - IO_L21P_T3L_N4_AD8P_68
set_property -dict {LOC Y29  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[23]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ23            - IO_L24P_T3U_N10_68
set_property -dict {LOC AA35 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[24]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ24            - IO_L5N_T0U_N9_AD14N_68
set_property -dict {LOC Y34  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[25]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ25            - IO_L5P_T0U_N8_AD14P_68
set_property -dict {LOC Y36  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[26]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ26            - IO_L2P_T0L_N2_68
set_property -dict {LOC W37  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[27]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ27            - IO_L3N_T0L_N5_AD15N_68
set_property -dict {LOC AB35 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[28]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ28            - IO_L6N_T0U_N11_AD6N_68
set_property -dict {LOC AA34 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[29]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ29            - IO_L6P_T0U_N10_AD6P_68
set_property -dict {LOC AA36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[30]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ30            - IO_L2N_T0L_N3_68
set_property -dict {LOC W36  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[31]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ31            - IO_L3P_T0L_N4_AD15P_68
set_property -dict {LOC Y31  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_t[2]}]    ;# Bank  68 VCCO  - Net DDR4_C0_DQS_T2          - IO_L22P_T3U_N6_DBC_AD0P_68
set_property -dict {LOC AA31 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_c[2]}]    ;# Bank  68 VCCO  - Net DDR4_C0_DQS_C2          - IO_L22N_T3U_N7_DBC_AD0N_68
set_property -dict {LOC W34  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_t[3]}]    ;# Bank  68 VCCO  - Net DDR4_C0_DQS_T3          - IO_L4P_T0U_N6_DBC_AD7P_68
set_property -dict {LOC W35  IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_c[3]}]    ;# Bank  68 VCCO  - Net DDR4_C0_DQS_C3          - IO_L4N_T0U_N7_DBC_AD7N_68
set_property -dict {LOC Y33  IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dm_dbi_n[2]}] ;# Bank  68 VCCO  - Net DDR4_C0_DM_B2           - IO_L19P_T3L_N0_DBC_AD9P_68
set_property -dict {LOC AB36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dm_dbi_n[3]}] ;# Bank  68 VCCO  - Net DDR4_C0_DM_B3           - IO_L1P_T0L_N0_DBC_68

set_property -dict {LOC AL35 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[32]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ32            - IO_L14P_T2L_N2_GC_67
set_property -dict {LOC AK37 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[33]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ33            - IO_L17N_T2U_N9_AD10N_67
set_property -dict {LOC AL36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[34]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ34            - IO_L14N_T2L_N3_GC_67
set_property -dict {LOC AK36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[35]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ35            - IO_L17P_T2U_N8_AD10P_67
set_property -dict {LOC AL34 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[36]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ36            - IO_L15N_T2L_N5_AD11N_67
set_property -dict {LOC AJ35 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[37]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ37            - IO_L18P_T2U_N10_AD2P_67
set_property -dict {LOC AL33 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[38]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ38            - IO_L15P_T2L_N4_AD11P_67
set_property -dict {LOC AJ36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[39]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ39            - IO_L18N_T2U_N11_AD2N_67
set_property -dict {LOC AG37 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[40]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ40            - IO_L24N_T3U_N11_67
set_property -dict {LOC AH32 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[41]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ41            - IO_L21P_T3L_N4_AD8P_67
set_property -dict {LOC AH34 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[42]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ42            - IO_L20P_T3L_N2_AD1P_67
set_property -dict {LOC AG35 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[43]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ43            - IO_L23P_T3U_N8_67
set_property -dict {LOC AH35 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[44]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ44            - IO_L23N_T3U_N9_67
set_property -dict {LOC AJ32 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[45]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ45            - IO_L21N_T3L_N5_AD8N_67
set_property -dict {LOC AJ34 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[46]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ46            - IO_L20N_T3L_N3_AD1N_67
set_property -dict {LOC AG36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[47]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ47            - IO_L24P_T3U_N10_67
set_property -dict {LOC AK33 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_t[4]}]    ;# Bank  67 VCCO  - Net DDR4_C0_DQS_T4          - IO_L16P_T2U_N6_QBC_AD3P_67
set_property -dict {LOC AK34 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_c[4]}]    ;# Bank  67 VCCO  - Net DDR4_C0_DQS_C4          - IO_L16N_T2U_N7_QBC_AD3N_67
set_property -dict {LOC AF33 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_t[5]}]    ;# Bank  67 VCCO  - Net DDR4_C0_DQS_T5          - IO_L22P_T3U_N6_DBC_AD0P_67
set_property -dict {LOC AG33 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_c[5]}]    ;# Bank  67 VCCO  - Net DDR4_C0_DQS_C5          - IO_L22N_T3U_N7_DBC_AD0N_67
set_property -dict {LOC AM36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dm_dbi_n[4]}] ;# Bank  67 VCCO  - Net DDR4_C0_DM_B4           - IO_L13P_T2L_N0_GC_QBC_67
set_property -dict {LOC AH37 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dm_dbi_n[5]}] ;# Bank  67 VCCO  - Net DDR4_C0_DM_B5           - IO_L19P_T3L_N0_DBC_AD9P_67

set_property -dict {LOC AE36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[48]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ48            - IO_L9P_T1L_N4_AD12P_68
set_property -dict {LOC AF34 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[49]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ49            - IO_L12N_T1U_N11_GC_68
set_property -dict {LOC AD36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[50]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ50            - IO_L8P_T1L_N2_AD5P_68
set_property -dict {LOC AC34 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[51]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ51            - IO_L11P_T1U_N8_GC_68
set_property -dict {LOC AF36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[52]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ52            - IO_L9N_T1L_N5_AD12N_68
set_property -dict {LOC AE34 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[53]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ53            - IO_L12P_T1U_N10_GC_68
set_property -dict {LOC AE37 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[54]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ54            - IO_L8N_T1L_N3_AD5N_68
set_property -dict {LOC AD34 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[55]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ55            - IO_L11N_T1U_N9_GC_68
set_property -dict {LOC AB33 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[56]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ56            - IO_L18P_T2U_N10_AD2P_68
set_property -dict {LOC AD30 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[57]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ57            - IO_L14P_T2L_N2_GC_68
set_property -dict {LOC AC33 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[58]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ58            - IO_L18N_T2U_N11_AD2N_68
set_property -dict {LOC AD29 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[59]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ59            - IO_L15N_T2L_N5_AD11N_68
set_property -dict {LOC AE31 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[60]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ60            - IO_L14N_T2L_N3_GC_68
set_property -dict {LOC AC29 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[61]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ61            - IO_L15P_T2L_N4_AD11P_68
set_property -dict {LOC AD32 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[62]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ62            - IO_L17N_T2U_N9_AD10N_68
set_property -dict {LOC AC32 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[63]}]      ;# Bank  68 VCCO  - Net DDR4_C0_DQ63            - IO_L17P_T2U_N8_AD10P_68
set_property -dict {LOC AC35 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_t[6]}]    ;# Bank  68 VCCO  - Net DDR4_C0_DQS_T6          - IO_L10P_T1U_N6_QBC_AD4P_68
set_property -dict {LOC AD35 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_c[6]}]    ;# Bank  68 VCCO  - Net DDR4_C0_DQS_C6          - IO_L10N_T1U_N7_QBC_AD4N_68
set_property -dict {LOC AC30 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_t[7]}]    ;# Bank  68 VCCO  - Net DDR4_C0_DQS_T7          - IO_L16P_T2U_N6_QBC_AD3P_68
set_property -dict {LOC AD31 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_c[7]}]    ;# Bank  68 VCCO  - Net DDR4_C0_DQS_C7          - IO_L16N_T2U_N7_QBC_AD3N_68
set_property -dict {LOC AC37 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dm_dbi_n[6]}] ;# Bank  68 VCCO  - Net DDR4_C0_DM_B6           - IO_L7P_T1L_N0_QBC_AD13P_68
set_property -dict {LOC AE32 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dm_dbi_n[7]}] ;# Bank  68 VCCO  - Net DDR4_C0_DM_B7           - IO_L13P_T2L_N0_GC_QBC_68

set_property -dict {LOC AT33 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[64]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ64            - IO_L2P_T0L_N2_67
set_property -dict {LOC AT36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[65]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ65            - IO_L5N_T0U_N9_AD14N_67
set_property -dict {LOC AR33 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[66]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ66            - IO_L3N_T0L_N5_AD15N_67
set_property -dict {LOC AR36 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[67]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ67            - IO_L6N_T0U_N11_AD6N_67
set_property -dict {LOC AR32 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[68]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ68            - IO_L3P_T0L_N4_AD15P_67
set_property -dict {LOC AT35 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[69]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ69            - IO_L5P_T0U_N8_AD14P_67
set_property -dict {LOC AU33 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[70]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ70            - IO_L2N_T0L_N3_67
set_property -dict {LOC AP35 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dq[71]}]      ;# Bank  67 VCCO  - Net DDR4_C0_DQ71            - IO_L6P_T0U_N10_AD6P_67
set_property -dict {LOC AT34 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_t[8]}]    ;# Bank  67 VCCO  - Net DDR4_C0_DQS_T8          - IO_L4P_T0U_N6_DBC_AD7P_67
set_property -dict {LOC AU35 IOSTANDARD DIFF_POD12_DCI}  [get_ports {ddr4_c0_dqs_c[8]}]    ;# Bank  67 VCCO  - Net DDR4_C0_DQS_C8          - IO_L4N_T0U_N7_DBC_AD7N_67
set_property -dict {LOC AU31 IOSTANDARD POD12_DCI}       [get_ports {ddr4_c0_dm_dbi_n[8]}] ;# Bank  67 VCCO  - Net DDR4_C0_DM_B8           - IO_L1P_T0L_N0_DBC_67
