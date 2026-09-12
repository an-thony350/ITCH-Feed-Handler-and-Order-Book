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

# DNCPU
set_property -dict {LOC Y26  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[0]]  ;# J10.1
set_property -dict {LOC AA22 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[1]]  ;# J10.2
set_property -dict {LOC Y27  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[2]]  ;# J10.3
set_property -dict {LOC AB22 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[3]]  ;# J10.4
set_property -dict {LOC AD25 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[4]]  ;# J10.5
set_property -dict {LOC AC22 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[5]]  ;# J10.6
set_property -dict {LOC AD26 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[6]]  ;# J10.7
set_property -dict {LOC AC23 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[7]]  ;# J10.8
set_property -dict {LOC AB24 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[8]]  ;# J10.9
set_property -dict {LOC AA20 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[9]]  ;# J10.10
set_property -dict {LOC AC24 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[10]] ;# J10.11
set_property -dict {LOC AB20 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[11]] ;# J10.12
set_property -dict {LOC AC26 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[12]] ;# J10.13
set_property -dict {LOC AB21 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[13]] ;# J10.14
set_property -dict {LOC AC27 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[14]] ;# J10.15
set_property -dict {LOC AC21 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[15]] ;# J10.16
set_property -dict {LOC AA27 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[16]] ;# J10.17
set_property -dict {LOC Y23  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[17]] ;# J10.18
set_property -dict {LOC AB27 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[18]] ;# J10.19
set_property -dict {LOC AA23 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[19]] ;# J10.20
set_property -dict {LOC AB25 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[20]] ;# J10.21
set_property -dict {LOC AA24 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[21]] ;# J10.22
set_property -dict {LOC AB26 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[22]] ;# J10.23
set_property -dict {LOC AA25 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[23]] ;# J10.24
set_property -dict {LOC AA28 IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[24]] ;# J10.25
set_property -dict {LOC Y22  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[25]] ;# J10.26
set_property -dict {LOC W23  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[26]] ;# J10.27
set_property -dict {LOC V27  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[27]] ;# J10.28
set_property -dict {LOC W24  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[28]] ;# J10.29
set_property -dict {LOC V28  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[29]] ;# J10.30
set_property -dict {LOC W25  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[30]] ;# J10.31
set_property -dict {LOC U24  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[31]] ;# J10.32
set_property -dict {LOC Y25  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[32]] ;# J10.33
set_property -dict {LOC U25  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[33]] ;# J10.34
set_property -dict {LOC U21  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[34]] ;# J10.35
set_property -dict {LOC W28  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[35]] ;# J10.36
set_property -dict {LOC U22  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[36]] ;# J10.37
set_property -dict {LOC Y28  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[37]] ;# J10.38
set_property -dict {LOC V22  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[38]] ;# J10.39
set_property -dict {LOC U26  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[39]] ;# J10.40
set_property -dict {LOC V23  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[40]] ;# J10.41
set_property -dict {LOC U27  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[41]] ;# J10.42
set_property -dict {LOC T22  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[42]] ;# J10.43
set_property -dict {LOC V29  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[43]] ;# J10.44
set_property -dict {LOC T23  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[44]] ;# J10.45
set_property -dict {LOC W29  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[45]] ;# J10.46
set_property -dict {LOC V21  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[46]] ;# J10.47
set_property -dict {LOC V26  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[47]] ;# J10.48
set_property -dict {LOC W21  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[48]] ;# J10.49
set_property -dict {LOC W26  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[49]] ;# J10.50
set_property -dict {LOC Y21  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[50]] ;# J10.51
set_property -dict {LOC U29  IOSTANDARD LVCMOS12} [get_ports gpio_j10_a[51]] ;# J10.52

set_property -dict {LOC AE27 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[0]]  ;# J10.121
set_property -dict {LOC AG31 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[1]]  ;# J10.122
set_property -dict {LOC AF27 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[2]]  ;# J10.123
set_property -dict {LOC AG32 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[3]]  ;# J10.124
set_property -dict {LOC AE28 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[4]]  ;# J10.125
set_property -dict {LOC AF33 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[5]]  ;# J10.126
set_property -dict {LOC AF28 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[6]]  ;# J10.127
set_property -dict {LOC AG34 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[7]]  ;# J10.128
set_property -dict {LOC AC28 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[8]]  ;# J10.129
set_property -dict {LOC AE32 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[9]]  ;# J10.130
set_property -dict {LOC AD28 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[10]] ;# J10.131
set_property -dict {LOC AF32 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[11]] ;# J10.132
set_property -dict {LOC AF29 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[12]] ;# J10.133
set_property -dict {LOC AE33 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[13]] ;# J10.134
set_property -dict {LOC AG29 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[14]] ;# J10.135
set_property -dict {LOC AF34 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[15]] ;# J10.136
set_property -dict {LOC AD29 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[16]] ;# J10.137
set_property -dict {LOC AD30 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[17]] ;# J10.138
set_property -dict {LOC AE30 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[18]] ;# J10.139
set_property -dict {LOC AD31 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[19]] ;# J10.140
set_property -dict {LOC AF30 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[20]] ;# J10.141
set_property -dict {LOC AC31 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[21]] ;# J10.142
set_property -dict {LOC AG30 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[22]] ;# J10.143
set_property -dict {LOC AC32 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[23]] ;# J10.144
set_property -dict {LOC AC29 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[24]] ;# J10.145
set_property -dict {LOC AE31 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[25]] ;# J10.146
set_property -dict {LOC AA32 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[26]] ;# J10.147
set_property -dict {LOC W33  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[27]] ;# J10.148
set_property -dict {LOC AB32 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[28]] ;# J10.149
set_property -dict {LOC Y33  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[29]] ;# J10.150
set_property -dict {LOC AB30 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[30]] ;# J10.151
set_property -dict {LOC W30  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[31]] ;# J10.152
set_property -dict {LOC AB31 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[32]] ;# J10.153
set_property -dict {LOC Y30  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[33]] ;# J10.154
set_property -dict {LOC AC34 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[34]] ;# J10.155
set_property -dict {LOC V33  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[35]] ;# J10.156
set_property -dict {LOC AD34 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[36]] ;# J10.157
set_property -dict {LOC W34  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[37]] ;# J10.158
set_property -dict {LOC AA29 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[38]] ;# J10.159
set_property -dict {LOC Y31  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[39]] ;# J10.160
set_property -dict {LOC AB29 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[40]] ;# J10.161
set_property -dict {LOC Y32  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[41]] ;# J10.162
set_property -dict {LOC AA34 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[42]] ;# J10.163
set_property -dict {LOC U34  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[43]] ;# J10.164
set_property -dict {LOC AB34 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[44]] ;# J10.165
set_property -dict {LOC V34  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[45]] ;# J10.166
set_property -dict {LOC AC33 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[46]] ;# J10.167
set_property -dict {LOC V31  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[47]] ;# J10.168
set_property -dict {LOC AD33 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[48]] ;# J10.169
set_property -dict {LOC W31  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[49]] ;# J10.170
set_property -dict {LOC AA33 IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[50]] ;# J10.171
set_property -dict {LOC V32  IOSTANDARD LVCMOS12} [get_ports gpio_j10_b[51]] ;# J10.172
