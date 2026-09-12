# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the DNPCIe_40G_KU_LL_2QSFP
# part: xcku040-ffva1156-2-e
# part: xcku060-ffva1156-2-e

# DDR4
# 9x MT40A512M8RH-083E
# Control
set_property -dict {LOC AG17 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[0]}]     ;# IO_L15P_T2L_N4_AD11P_45
set_property -dict {LOC AH16 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[1]}]     ;# IO_L14P_T2L_N2_GC_45
set_property -dict {LOC AF15 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[2]}]     ;# IO_L20P_T3L_N2_AD1P_45
set_property -dict {LOC AJ16 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[3]}]     ;# IO_L14N_T2L_N3_GC_45
set_property -dict {LOC AH19 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[4]}]     ;# IO_L17N_T2U_N9_AD10N_45
set_property -dict {LOC AJ15 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[5]}]     ;# IO_L16P_T2U_N6_QBC_AD3P_45
set_property -dict {LOC AE18 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[6]}]     ;# IO_L21P_T3L_N4_AD8P_45
set_property -dict {LOC AG15 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[7]}]     ;# IO_L18P_T2U_N10_AD2P_45
set_property -dict {LOC AD18 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[8]}]     ;# IO_L19N_T3L_N1_DBC_AD9N_45
set_property -dict {LOC AF14 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[9]}]     ;# IO_L20N_T3L_N3_AD1N_45
set_property -dict {LOC AJ18 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[10]}]    ;# IO_L11P_T1U_N8_GC_45
set_property -dict {LOC AD19 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[11]}]    ;# IO_L19P_T3L_N0_DBC_AD9P_45
set_property -dict {LOC AK16 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[12]}]    ;# IO_L12N_T1U_N11_GC_45
set_property -dict {LOC AG16 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[13]}]    ;# IO_L15N_T2L_N5_AD11N_45
set_property -dict {LOC AJ19 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[14]}]    ;# IO_T1U_N12_45
set_property -dict {LOC AL17 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[15]}]    ;# IO_L10N_T1U_N7_QBC_AD4N_45
set_property -dict {LOC AL14 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_adr[16]}]    ;# IO_L7P_T1L_N0_QBC_AD13P_45
set_property -dict {LOC AF18 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_ba[0]}]      ;# IO_L21N_T3L_N5_AD8N_45
set_property -dict {LOC AJ14 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_ba[1]}]      ;# IO_L16N_T2U_N7_QBC_AD3N_45
set_property -dict {LOC AG19 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_bg[0]}]      ;# IO_L17P_T2U_N8_AD10P_45
set_property -dict {LOC AK15 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_bg[1]}]      ;# IO_L9P_T1L_N4_AD12P_45
set_property -dict {LOC AE17 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_ck_t}]       ;# IO_L23P_T3U_N8_45
set_property -dict {LOC AF17 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_ck_c}]       ;# IO_L23N_T3U_N9_45
set_property -dict {LOC AL18 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_cke}]        ;# IO_L10P_T1U_N6_QBC_AD4P_45
set_property -dict {LOC AL15 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_cs_n}]       ;# IO_L9N_T1L_N5_AD12N_45
set_property -dict {LOC AK17 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_act_n}]      ;# IO_L12P_T1U_N10_GC_45
set_property -dict {LOC AM19 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_odt}]        ;# IO_L8N_T1L_N3_AD5N_45
set_property -dict {LOC AE16 IOSTANDARD SSTL12_DCI     } [get_ports {ddr4_par}]        ;# IO_L22P_T3U_N6_DBC_AD0P_45
set_property -dict {LOC AD16 IOSTANDARD LVCMOS12       } [get_ports {ddr4_reset_n}]    ;# IO_L24P_T3U_N10_45
set_property -dict {LOC AD15 IOSTANDARD LVCMOS12       } [get_ports {ddr4_alert_n}]    ;# IO_L24N_T3U_N11_45
set_property -dict {LOC AD14 IOSTANDARD LVCMOS12       } [get_ports {ddr4_ten}]        ;# IO_T3U_N12_45
# U30
set_property -dict {LOC AD21 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[0]}] ;# IO_L1P_T0L_N0_DBC_44 to U30.DM_DBI_n
set_property -dict {LOC AF20 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[0]}]       ;# IO_L2P_T0L_N2_44 to U30.DQ[7:0]
set_property -dict {LOC AG20 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[1]}]       ;# IO_L2N_T0L_N3_44 to U30.DQ[7:0]
set_property -dict {LOC AD20 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[2]}]       ;# IO_L3P_T0L_N4_AD15P_44 to U30.DQ[7:0]
set_property -dict {LOC AE20 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[3]}]       ;# IO_L3N_T0L_N5_AD15N_44 to U30.DQ[7:0]
set_property -dict {LOC AG21 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[0]}]    ;# IO_L4P_T0U_N6_DBC_AD7P_44 to U30.DQS_t
set_property -dict {LOC AH21 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[0]}]    ;# IO_L4N_T0U_N7_DBC_AD7N_44 to U30.DQS_c
set_property -dict {LOC AE22 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[4]}]       ;# IO_L5P_T0U_N8_AD14P_44 to U30.DQ[7:0]
set_property -dict {LOC AE23 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[5]}]       ;# IO_L5N_T0U_N9_AD14N_44 to U30.DQ[7:0]
set_property -dict {LOC AF22 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[6]}]       ;# IO_L6P_T0U_N10_AD6P_44 to U30.DQ[7:0]
set_property -dict {LOC AG22 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[7]}]       ;# IO_L6N_T0U_N11_AD6N_44 to U30.DQ[7:0]
# U31
set_property -dict {LOC AJ21 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[1]}] ;# IO_L13P_T2L_N0_GC_QBC_44 to U31.DM_DBI_n
set_property -dict {LOC AK22 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[8]}]       ;# IO_L14P_T2L_N2_GC_44 to U31.DQ[7:0]
set_property -dict {LOC AK23 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[9]}]       ;# IO_L14N_T2L_N3_GC_44 to U31.DQ[7:0]
set_property -dict {LOC AL20 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[10]}]      ;# IO_L15P_T2L_N4_AD11P_44 to U31.DQ[7:0]
set_property -dict {LOC AM20 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[11]}]      ;# IO_L15N_T2L_N5_AD11N_44 to U31.DQ[7:0]
set_property -dict {LOC AJ20 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[1]}]    ;# IO_L16P_T2U_N6_QBC_AD3P_44 to U31.DQS_t
set_property -dict {LOC AK20 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[1]}]    ;# IO_L16N_T2U_N7_QBC_AD3N_44 to U31.DQS_c
set_property -dict {LOC AL22 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[12]}]      ;# IO_L17P_T2U_N8_AD10P_44 to U31.DQ[7:0]
set_property -dict {LOC AL23 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[13]}]      ;# IO_L17N_T2U_N9_AD10N_44 to U31.DQ[7:0]
set_property -dict {LOC AL24 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[14]}]      ;# IO_L18P_T2U_N10_AD2P_44 to U31.DQ[7:0]
set_property -dict {LOC AL25 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[15]}]      ;# IO_L18N_T2U_N11_AD2N_44 to U31.DQ[7:0]
# U32
set_property -dict {LOC AH26 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[2]}] ;# IO_L1P_T0L_N0_DBC_46 to U32.DM_DBI_n
set_property -dict {LOC AM26 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[16]}]      ;# IO_L2P_T0L_N2_46 to U32.DQ[7:0]
set_property -dict {LOC AM27 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[17]}]      ;# IO_L2N_T0L_N3_46 to U32.DQ[7:0]
set_property -dict {LOC AK26 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[18]}]      ;# IO_L3P_T0L_N4_AD15P_46 to U32.DQ[7:0]
set_property -dict {LOC AK27 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[19]}]      ;# IO_L3N_T0L_N5_AD15N_46 to U32.DQ[7:0]
set_property -dict {LOC AL27 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[2]}]    ;# IO_L4P_T0U_N6_DBC_AD7P_46 to U32.DQS_t
set_property -dict {LOC AL28 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[2]}]    ;# IO_L4N_T0U_N7_DBC_AD7N_46 to U32.DQS_c
set_property -dict {LOC AH27 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[20]}]      ;# IO_L5P_T0U_N8_AD14P_46 to U32.DQ[7:0]
set_property -dict {LOC AH28 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[21]}]      ;# IO_L5N_T0U_N9_AD14N_46 to U32.DQ[7:0]
set_property -dict {LOC AJ28 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[22]}]      ;# IO_L6P_T0U_N10_AD6P_46 to U32.DQ[7:0]
set_property -dict {LOC AK28 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[23]}]      ;# IO_L6N_T0U_N11_AD6N_46 to U32.DQ[7:0]
# U33
set_property -dict {LOC AN26 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[3]}] ;# IO_L7P_T1L_N0_QBC_AD13P_46 to U33.DM_DBI_n
set_property -dict {LOC AP28 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[24]}]      ;# IO_L8P_T1L_N2_AD5P_46 to U33.DQ[7:0]
set_property -dict {LOC AP29 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[25]}]      ;# IO_L8N_T1L_N3_AD5N_46 to U33.DQ[7:0]
set_property -dict {LOC AN27 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[26]}]      ;# IO_L9P_T1L_N4_AD12P_46 to U33.DQ[7:0]
set_property -dict {LOC AN28 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[27]}]      ;# IO_L9N_T1L_N5_AD12N_46 to U33.DQ[7:0]
set_property -dict {LOC AN29 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[3]}]    ;# IO_L10P_T1U_N6_QBC_AD4P_46 to U33.DQS_t
set_property -dict {LOC AP30 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[3]}]    ;# IO_L10N_T1U_N7_QBC_AD4N_46 to U33.DQS_c
set_property -dict {LOC AL29 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[28]}]      ;# IO_L11P_T1U_N8_GC_46 to U33.DQ[7:0]
set_property -dict {LOC AM29 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[29]}]      ;# IO_L11N_T1U_N9_GC_46 to U33.DQ[7:0]
set_property -dict {LOC AL30 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[30]}]      ;# IO_L12P_T1U_N10_GC_46 to U33.DQ[7:0]
set_property -dict {LOC AM30 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[31]}]      ;# IO_L12N_T1U_N11_GC_46 to U33.DQ[7:0]
# U83
set_property -dict {LOC AN14 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[4]}] ;# IO_L1P_T0L_N0_DBC_45 to U83.DM_DBI_n
set_property -dict {LOC AN19 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[32]}]      ;# IO_L2P_T0L_N2_45 to U83.DQ[7:0]
set_property -dict {LOC AP18 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[33]}]      ;# IO_L2N_T0L_N3_45 to U83.DQ[7:0]
set_property -dict {LOC AM17 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[34]}]      ;# IO_L3P_T0L_N4_AD15P_45 to U83.DQ[7:0]
set_property -dict {LOC AN16 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[35]}]      ;# IO_L3N_T0L_N5_AD15N_45 to U83.DQ[7:0]
set_property -dict {LOC AN18 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[4]}]    ;# IO_L4P_T0U_N6_DBC_AD7P_45 to U83.DQS_t
set_property -dict {LOC AN17 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[4]}]    ;# IO_L4N_T0U_N7_DBC_AD7N_45 to U83.DQS_c
set_property -dict {LOC AM16 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[36]}]      ;# IO_L5P_T0U_N8_AD14P_45 to U83.DQ[7:0]
set_property -dict {LOC AM15 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[37]}]      ;# IO_L5N_T0U_N9_AD14N_45 to U83.DQ[7:0]
set_property -dict {LOC AP16 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[38]}]      ;# IO_L6P_T0U_N10_AD6P_45 to U83.DQ[7:0]
set_property -dict {LOC AP15 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[39]}]      ;# IO_L6N_T0U_N11_AD6N_45 to U83.DQ[7:0]
# U86
set_property -dict {LOC AM21 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[5]}] ;# IO_L19P_T3L_N0_DBC_AD9P_44 to U86.DM_DBI_n
set_property -dict {LOC AM22 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[40]}]      ;# IO_L20P_T3L_N2_AD1P_44 to U86.DQ[7:0]
set_property -dict {LOC AN22 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[41]}]      ;# IO_L20N_T3L_N3_AD1N_44 to U86.DQ[7:0]
set_property -dict {LOC AM24 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[42]}]      ;# IO_L21P_T3L_N4_AD8P_44 to U86.DQ[7:0]
set_property -dict {LOC AN24 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[43]}]      ;# IO_L21N_T3L_N5_AD8N_44 to U86.DQ[7:0]
set_property -dict {LOC AP20 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[5]}]    ;# IO_L22P_T3U_N6_DBC_AD0P_44 to U86.DQS_t
set_property -dict {LOC AP21 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[5]}]    ;# IO_L22N_T3U_N7_DBC_AD0N_44 to U86.DQS_c
set_property -dict {LOC AP24 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[44]}]      ;# IO_L23P_T3U_N8_44 to U86.DQ[7:0]
set_property -dict {LOC AP25 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[45]}]      ;# IO_L23N_T3U_N9_44 to U86.DQ[7:0]
set_property -dict {LOC AN23 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[46]}]      ;# IO_L24P_T3U_N10_44 to U86.DQ[7:0]
set_property -dict {LOC AP23 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[47]}]      ;# IO_L24N_T3U_N11_44 to U86.DQ[7:0]
# U87
set_property -dict {LOC AE25 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[6]}] ;# IO_L7P_T1L_N0_QBC_AD13P_44 to U87.DM_DBI_n
set_property -dict {LOC AF23 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[48]}]      ;# IO_L8P_T1L_N2_AD5P_44 to U87.DQ[7:0]
set_property -dict {LOC AF24 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[49]}]      ;# IO_L8N_T1L_N3_AD5N_44 to U87.DQ[7:0]
set_property -dict {LOC AG24 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[50]}]      ;# IO_L9P_T1L_N4_AD12P_44 to U87.DQ[7:0]
set_property -dict {LOC AG25 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[51]}]      ;# IO_L9N_T1L_N5_AD12N_44 to U87.DQ[7:0]
set_property -dict {LOC AH24 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[6]}]    ;# IO_L10P_T1U_N6_QBC_AD4P_44 to U87.DQS_t
set_property -dict {LOC AJ25 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[6]}]    ;# IO_L10N_T1U_N7_QBC_AD4N_44 to U87.DQS_c
set_property -dict {LOC AJ23 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[52]}]      ;# IO_L11P_T1U_N8_GC_44 to U87.DQ[7:0]
set_property -dict {LOC AJ24 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[53]}]      ;# IO_L11N_T1U_N9_GC_44 to U87.DQ[7:0]
set_property -dict {LOC AH22 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[54]}]      ;# IO_L12P_T1U_N10_GC_44 to U87.DQ[7:0]
set_property -dict {LOC AH23 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[55]}]      ;# IO_L12N_T1U_N11_GC_44 to U87.DQ[7:0]
# U88
set_property -dict {LOC AJ29 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[7]}] ;# IO_L13P_T2L_N0_GC_QBC_46 to U88.DM_DBI_n
set_property -dict {LOC AK31 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[56]}]      ;# IO_L14P_T2L_N2_GC_46 to U88.DQ[7:0]
set_property -dict {LOC AK32 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[57]}]      ;# IO_L14N_T2L_N3_GC_46 to U88.DQ[7:0]
set_property -dict {LOC AJ30 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[58]}]      ;# IO_L15P_T2L_N4_AD11P_46 to U88.DQ[7:0]
set_property -dict {LOC AJ31 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[59]}]      ;# IO_L15N_T2L_N5_AD11N_46 to U88.DQ[7:0]
set_property -dict {LOC AH33 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[7]}]    ;# IO_L16P_T2U_N6_QBC_AD3P_46 to U88.DQS_t
set_property -dict {LOC AJ33 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[7]}]    ;# IO_L16N_T2U_N7_QBC_AD3N_46 to U88.DQS_c
set_property -dict {LOC AH31 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[60]}]      ;# IO_L17P_T2U_N8_AD10P_46 to U88.DQ[7:0]
set_property -dict {LOC AH32 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[61]}]      ;# IO_L17N_T2U_N9_AD10N_46 to U88.DQ[7:0]
set_property -dict {LOC AH34 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[62]}]      ;# IO_L18P_T2U_N10_AD2P_46 to U88.DQ[7:0]
set_property -dict {LOC AJ34 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[63]}]      ;# IO_L18N_T2U_N11_AD2N_46 to U88.DQ[7:0]
# U89
set_property -dict {LOC AL32 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dm_dbi_n[8]}] ;# IO_L19P_T3L_N0_DBC_AD9P_46 to U89.DM_DBI_n
set_property -dict {LOC AN33 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[64]}]      ;# IO_L20P_T3L_N2_AD1P_46 to U89.DQ[7:0]
set_property -dict {LOC AP33 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[65]}]      ;# IO_L20N_T3L_N3_AD1N_46 to U89.DQ[7:0]
set_property -dict {LOC AN31 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[66]}]      ;# IO_L21P_T3L_N4_AD8P_46 to U89.DQ[7:0]
set_property -dict {LOC AP31 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[67]}]      ;# IO_L21N_T3L_N5_AD8N_46 to U89.DQ[7:0]
set_property -dict {LOC AN34 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_t[8]}]    ;# IO_L22P_T3U_N6_DBC_AD0P_46 to U89.DQS_t
set_property -dict {LOC AP34 IOSTANDARD DIFF_POD12_DCI } [get_ports {ddr4_dqs_c[8]}]    ;# IO_L22N_T3U_N7_DBC_AD0N_46 to U89.DQS_c
set_property -dict {LOC AM32 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[68]}]      ;# IO_L23P_T3U_N8_46 to U89.DQ[7:0]
set_property -dict {LOC AN32 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[69]}]      ;# IO_L23N_T3U_N9_46 to U89.DQ[7:0]
set_property -dict {LOC AL34 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[70]}]      ;# IO_L24P_T3U_N10_46 to U89.DQ[7:0]
set_property -dict {LOC AM34 IOSTANDARD POD12_DCI      } [get_ports {ddr4_dq[71]}]      ;# IO_L24N_T3U_N11_46 to U89.DQ[7:0]
