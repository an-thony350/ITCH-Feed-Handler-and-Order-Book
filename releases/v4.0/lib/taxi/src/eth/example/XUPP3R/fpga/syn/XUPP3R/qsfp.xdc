# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the BittWare XUP-P3R board
# part: xcvu9p-flgb2104-2-e

# QSFP28 Interfaces
set_property -dict {LOC BC45} [get_ports {qsfp0_rx_p[0]}] ;# MGTYRXP0_120 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BC46} [get_ports {qsfp0_rx_n[0]}] ;# MGTYRXN0_120 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BF42} [get_ports {qsfp0_tx_p[0]}] ;# MGTYTXP0_120 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BF43} [get_ports {qsfp0_tx_n[0]}] ;# MGTYTXN0_120 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BA45} [get_ports {qsfp0_rx_p[1]}] ;# MGTYRXP1_120 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BA46} [get_ports {qsfp0_rx_n[1]}] ;# MGTYRXN1_120 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BD42} [get_ports {qsfp0_tx_p[1]}] ;# MGTYTXP1_120 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BD43} [get_ports {qsfp0_tx_n[1]}] ;# MGTYTXN1_120 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AW45} [get_ports {qsfp0_rx_p[2]}] ;# MGTYRXP2_120 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AW46} [get_ports {qsfp0_rx_n[2]}] ;# MGTYRXN2_120 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BB42} [get_ports {qsfp0_tx_p[2]}] ;# MGTYTXP2_120 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BB43} [get_ports {qsfp0_tx_n[2]}] ;# MGTYTXN2_120 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AV43} [get_ports {qsfp0_rx_p[3]}] ;# MGTYRXP3_120 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AV44} [get_ports {qsfp0_rx_n[3]}] ;# MGTYRXN3_120 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AW40} [get_ports {qsfp0_tx_p[3]}] ;# MGTYTXP3_120 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AW41} [get_ports {qsfp0_tx_n[3]}] ;# MGTYTXN3_120 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BA40} [get_ports qsfp0_mgt_refclk_b0_p] ;# MGTREFCLK0P_120 from Si5338 B ch 0
set_property -dict {LOC BA41} [get_ports qsfp0_mgt_refclk_b0_n] ;# MGTREFCLK0N_120 from Si5338 B ch 0
#set_property -dict {LOC AY38} [get_ports qsfp0_mgt_refclk_b1_p] ;# MGTREFCLK1P_120 from Si5338 B ch 1
#set_property -dict {LOC AY39} [get_ports qsfp0_mgt_refclk_b1_n] ;# MGTREFCLK1N_120 from Si5338 B ch 1
#set_property -dict {LOC AU36} [get_ports qsfp0_mgt_refclk_c0_p] ;# MGTREFCLK0P_121 from Si5338 C ch 0
#set_property -dict {LOC AU37} [get_ports qsfp0_mgt_refclk_c0_n] ;# MGTREFCLK0N_121 from Si5338 C ch 0
#set_property -dict {LOC AV38} [get_ports qsfp0_mgt_refclk_c1_p] ;# MGTREFCLK1P_121 from Si5338 C ch 1
#set_property -dict {LOC AV39} [get_ports qsfp0_mgt_refclk_c1_n] ;# MGTREFCLK1N_121 from Si5338 C ch 1
set_property -dict {LOC BD24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp0_resetl]
set_property -dict {LOC BD23 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp0_modprsl]
set_property -dict {LOC BE23 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp0_intl]
set_property -dict {LOC BC24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp0_lpmode]
set_property -dict {LOC BF24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp0_i2c_scl]
set_property -dict {LOC BF23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp0_i2c_sda]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 0)
create_clock -period 3.103 -name qsfp0_mgt_refclk_b0 [get_ports qsfp0_mgt_refclk_b0_p]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 1)
#create_clock -period 3.103 -name qsfp0_mgt_refclk_b1 [get_ports qsfp0_mgt_refclk_b1_p]

# 322.265625 MHz MGT reference clock (from Si5338 C ch 0)
#create_clock -period 3.103 -name qsfp0_mgt_refclk_c0 [get_ports qsfp0_mgt_refclk_c0_p]

# 322.265625 MHz MGT reference clock (from Si5338 C ch 1)
#create_clock -period 3.103 -name qsfp0_mgt_refclk_c1 [get_ports qsfp0_mgt_refclk_c1_p]

set_false_path -to [get_ports {qsfp0_resetl qsfp0_lpmode}]
set_output_delay 0 [get_ports {qsfp0_resetl qsfp0_lpmode}]
set_false_path -from [get_ports {qsfp0_modprsl qsfp0_intl}]
set_input_delay 0 [get_ports {qsfp0_modprsl qsfp0_intl}]

set_false_path -to [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]
set_output_delay 0 [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]
set_false_path -from [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]
set_input_delay 0 [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]

set_property -dict {LOC AN45} [get_ports {qsfp1_rx_p[0]}] ;# MGTYRXP0_122 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AN46} [get_ports {qsfp1_rx_n[0]}] ;# MGTYRXN0_122 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AN40} [get_ports {qsfp1_tx_p[0]}] ;# MGTYTXP0_122 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AN41} [get_ports {qsfp1_tx_n[0]}] ;# MGTYTXN0_122 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AM43} [get_ports {qsfp1_rx_p[1]}] ;# MGTYRXP1_122 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AM44} [get_ports {qsfp1_rx_n[1]}] ;# MGTYRXN1_122 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AM38} [get_ports {qsfp1_tx_p[1]}] ;# MGTYTXP1_122 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AM39} [get_ports {qsfp1_tx_n[1]}] ;# MGTYTXN1_122 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AL45} [get_ports {qsfp1_rx_p[2]}] ;# MGTYRXP2_122 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AL46} [get_ports {qsfp1_rx_n[2]}] ;# MGTYRXN2_122 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AL40} [get_ports {qsfp1_tx_p[2]}] ;# MGTYTXP2_122 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AL41} [get_ports {qsfp1_tx_n[2]}] ;# MGTYTXN2_122 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AK43} [get_ports {qsfp1_rx_p[3]}] ;# MGTYRXP3_122 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AK44} [get_ports {qsfp1_rx_n[3]}] ;# MGTYRXN3_122 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AK38} [get_ports {qsfp1_tx_p[3]}] ;# MGTYTXP3_122 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AK39} [get_ports {qsfp1_tx_n[3]}] ;# MGTYTXN3_122 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AR36} [get_ports qsfp1_mgt_refclk_b0_p] ;# MGTREFCLK0P_122 from Si5338 B ch 0
set_property -dict {LOC AR37} [get_ports qsfp1_mgt_refclk_b0_n] ;# MGTREFCLK0N_122 from Si5338 B ch 0
#set_property -dict {LOC AN36} [get_ports qsfp1_mgt_refclk_b1_p] ;# MGTREFCLK1P_122 from Si5338 B ch 1
#set_property -dict {LOC AN37} [get_ports qsfp1_mgt_refclk_b1_n] ;# MGTREFCLK1N_122 from Si5338 B ch 1
#set_property -dict {LOC AL36} [get_ports qsfp1_mgt_refclk_c2_p] ;# MGTREFCLK0P_123 from Si5338 C ch 2
#set_property -dict {LOC AL37} [get_ports qsfp1_mgt_refclk_c2_n] ;# MGTREFCLK0N_123 from Si5338 C ch 2
#set_property -dict {LOC AJ36} [get_ports qsfp1_mgt_refclk_c3_p] ;# MGTREFCLK1P_123 from Si5338 C ch 3
#set_property -dict {LOC AJ37} [get_ports qsfp1_mgt_refclk_c3_n] ;# MGTREFCLK1N_123 from Si5338 C ch 3
set_property -dict {LOC BE20 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp1_resetl]
set_property -dict {LOC BD21 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp1_modprsl]
set_property -dict {LOC BE21 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp1_intl]
set_property -dict {LOC BD20 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp1_lpmode]
set_property -dict {LOC BE22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp1_i2c_scl]
set_property -dict {LOC BF22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp1_i2c_sda]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 0)
create_clock -period 3.103 -name qsfp1_mgt_refclk_b0 [get_ports qsfp1_mgt_refclk_b0_p]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 1)
#create_clock -period 3.103 -name qsfp1_mgt_refclk_b1 [get_ports qsfp1_mgt_refclk_b1_p]

# 322.265625 MHz MGT reference clock (from Si5338 C ch 2)
#create_clock -period 3.103 -name qsfp1_mgt_refclk_c2 [get_ports qsfp1_mgt_refclk_c2_p]

# 322.265625 MHz MGT reference clock (from Si5338 C ch 3)
#create_clock -period 3.103 -name qsfp1_mgt_refclk_c3 [get_ports qsfp1_mgt_refclk_c3_p]

set_false_path -to [get_ports {qsfp1_resetl qsfp1_lpmode}]
set_output_delay 0 [get_ports {qsfp1_resetl qsfp1_lpmode}]
set_false_path -from [get_ports {qsfp1_modprsl qsfp1_intl}]
set_input_delay 0 [get_ports {qsfp1_modprsl qsfp1_intl}]

set_false_path -to [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]
set_output_delay 0 [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]
set_false_path -from [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]
set_input_delay 0 [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]

set_property -dict {LOC AA45} [get_ports {qsfp2_rx_p[0]}] ;# MGTYRXP0_125 GTYE4_CHANNEL_X0Y24 / GTYE4_COMMON_X0Y6
set_property -dict {LOC AA46} [get_ports {qsfp2_rx_n[0]}] ;# MGTYRXN0_125 GTYE4_CHANNEL_X0Y24 / GTYE4_COMMON_X0Y6
set_property -dict {LOC AA40} [get_ports {qsfp2_tx_p[0]}] ;# MGTYTXP0_125 GTYE4_CHANNEL_X0Y24 / GTYE4_COMMON_X0Y6
set_property -dict {LOC AA41} [get_ports {qsfp2_tx_n[0]}] ;# MGTYTXN0_125 GTYE4_CHANNEL_X0Y24 / GTYE4_COMMON_X0Y6
set_property -dict {LOC Y43 } [get_ports {qsfp2_rx_p[1]}] ;# MGTYRXP1_125 GTYE4_CHANNEL_X0Y25 / GTYE4_COMMON_X0Y6
set_property -dict {LOC Y44 } [get_ports {qsfp2_rx_n[1]}] ;# MGTYRXN1_125 GTYE4_CHANNEL_X0Y25 / GTYE4_COMMON_X0Y6
set_property -dict {LOC Y38 } [get_ports {qsfp2_tx_p[1]}] ;# MGTYTXP1_125 GTYE4_CHANNEL_X0Y25 / GTYE4_COMMON_X0Y6
set_property -dict {LOC Y39 } [get_ports {qsfp2_tx_n[1]}] ;# MGTYTXN1_125 GTYE4_CHANNEL_X0Y25 / GTYE4_COMMON_X0Y6
set_property -dict {LOC W45 } [get_ports {qsfp2_rx_p[2]}] ;# MGTYRXP2_125 GTYE4_CHANNEL_X0Y26 / GTYE4_COMMON_X0Y6
set_property -dict {LOC W46 } [get_ports {qsfp2_rx_n[2]}] ;# MGTYRXN2_125 GTYE4_CHANNEL_X0Y26 / GTYE4_COMMON_X0Y6
set_property -dict {LOC W40 } [get_ports {qsfp2_tx_p[2]}] ;# MGTYTXP2_125 GTYE4_CHANNEL_X0Y26 / GTYE4_COMMON_X0Y6
set_property -dict {LOC W41 } [get_ports {qsfp2_tx_n[2]}] ;# MGTYTXN2_125 GTYE4_CHANNEL_X0Y26 / GTYE4_COMMON_X0Y6
set_property -dict {LOC V43 } [get_ports {qsfp2_rx_p[3]}] ;# MGTYRXP3_125 GTYE4_CHANNEL_X0Y27 / GTYE4_COMMON_X0Y6
set_property -dict {LOC V44 } [get_ports {qsfp2_rx_n[3]}] ;# MGTYRXN3_125 GTYE4_CHANNEL_X0Y27 / GTYE4_COMMON_X0Y6
set_property -dict {LOC V38 } [get_ports {qsfp2_tx_p[3]}] ;# MGTYTXP3_125 GTYE4_CHANNEL_X0Y27 / GTYE4_COMMON_X0Y6
set_property -dict {LOC V39 } [get_ports {qsfp2_tx_n[3]}] ;# MGTYTXN3_125 GTYE4_CHANNEL_X0Y27 / GTYE4_COMMON_X0Y6
set_property -dict {LOC AC36} [get_ports qsfp2_mgt_refclk_b0_p] ;# MGTREFCLK0P_125 from Si5338 B ch 0
set_property -dict {LOC AC37} [get_ports qsfp2_mgt_refclk_b0_n] ;# MGTREFCLK0N_125 from Si5338 B ch 0
#set_property -dict {LOC AA36} [get_ports qsfp2_mgt_refclk_b2_p] ;# MGTREFCLK1P_125 from Si5338 B ch 2
#set_property -dict {LOC AA37} [get_ports qsfp2_mgt_refclk_b2_n] ;# MGTREFCLK1N_125 from Si5338 B ch 2
#set_property -dict {LOC W36 } [get_ports qsfp2_mgt_refclk_d0_p] ;# MGTREFCLK0P_126 from Si5338 D ch 0
#set_property -dict {LOC W37 } [get_ports qsfp2_mgt_refclk_d0_n] ;# MGTREFCLK0N_126 from Si5338 D ch 0
#set_property -dict {LOC U36 } [get_ports qsfp2_mgt_refclk_d1_p] ;# MGTREFCLK1P_126 from Si5338 D ch 1
#set_property -dict {LOC U37 } [get_ports qsfp2_mgt_refclk_d1_n] ;# MGTREFCLK1N_126 from Si5338 D ch 1
set_property -dict {LOC BB22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp2_resetl]
set_property -dict {LOC BB20 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp2_modprsl]
set_property -dict {LOC BB21 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp2_intl]
set_property -dict {LOC BC21 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp2_lpmode]
set_property -dict {LOC BF20 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp2_i2c_scl]
set_property -dict {LOC BA20 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp2_i2c_sda]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 0)
create_clock -period 3.103 -name qsfp2_mgt_refclk_b0 [get_ports qsfp2_mgt_refclk_b0_p]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 2)
#create_clock -period 3.103 -name qsfp2_mgt_refclk_b2 [get_ports qsfp2_mgt_refclk_b2_p]

# 322.265625 MHz MGT reference clock (from Si5338 D ch 0)
#create_clock -period 3.103 -name qsfp2_mgt_refclk_d0 [get_ports qsfp2_mgt_refclk_d0_p]

# 322.265625 MHz MGT reference clock (from Si5338 D ch 1)
#create_clock -period 3.103 -name qsfp2_mgt_refclk_d1 [get_ports qsfp2_mgt_refclk_d1_p]

set_false_path -to [get_ports {qsfp2_resetl qsfp2_lpmode}]
set_output_delay 0 [get_ports {qsfp2_resetl qsfp2_lpmode}]
set_false_path -from [get_ports {qsfp2_modprsl qsfp2_intl}]
set_input_delay 0 [get_ports {qsfp2_modprsl qsfp2_intl}]

set_false_path -to [get_ports {qsfp2_i2c_scl qsfp2_i2c_sda}]
set_output_delay 0 [get_ports {qsfp2_i2c_scl qsfp2_i2c_sda}]
set_false_path -from [get_ports {qsfp2_i2c_scl qsfp2_i2c_sda}]
set_input_delay 0 [get_ports {qsfp2_i2c_scl qsfp2_i2c_sda}]

set_property -dict {LOC N45 } [get_ports {qsfp3_rx_p[0]}] ;# MGTYRXP0_127 GTYE4_CHANNEL_X0Y32 / GTYE4_COMMON_X0Y8
set_property -dict {LOC N46 } [get_ports {qsfp3_rx_n[0]}] ;# MGTYRXN0_127 GTYE4_CHANNEL_X0Y32 / GTYE4_COMMON_X0Y8
set_property -dict {LOC N40 } [get_ports {qsfp3_tx_p[0]}] ;# MGTYTXP0_127 GTYE4_CHANNEL_X0Y32 / GTYE4_COMMON_X0Y8
set_property -dict {LOC N41 } [get_ports {qsfp3_tx_n[0]}] ;# MGTYTXN0_127 GTYE4_CHANNEL_X0Y32 / GTYE4_COMMON_X0Y8
set_property -dict {LOC M43 } [get_ports {qsfp3_rx_p[1]}] ;# MGTYRXP1_127 GTYE4_CHANNEL_X0Y33 / GTYE4_COMMON_X0Y8
set_property -dict {LOC M44 } [get_ports {qsfp3_rx_n[1]}] ;# MGTYRXN1_127 GTYE4_CHANNEL_X0Y33 / GTYE4_COMMON_X0Y8
set_property -dict {LOC M38 } [get_ports {qsfp3_tx_p[1]}] ;# MGTYTXP1_127 GTYE4_CHANNEL_X0Y33 / GTYE4_COMMON_X0Y8
set_property -dict {LOC M39 } [get_ports {qsfp3_tx_n[1]}] ;# MGTYTXN1_127 GTYE4_CHANNEL_X0Y33 / GTYE4_COMMON_X0Y8
set_property -dict {LOC L45 } [get_ports {qsfp3_rx_p[2]}] ;# MGTYRXP2_127 GTYE4_CHANNEL_X0Y34 / GTYE4_COMMON_X0Y8
set_property -dict {LOC L46 } [get_ports {qsfp3_rx_n[2]}] ;# MGTYRXN2_127 GTYE4_CHANNEL_X0Y34 / GTYE4_COMMON_X0Y8
set_property -dict {LOC L40 } [get_ports {qsfp3_tx_p[2]}] ;# MGTYTXP2_127 GTYE4_CHANNEL_X0Y34 / GTYE4_COMMON_X0Y8
set_property -dict {LOC L41 } [get_ports {qsfp3_tx_n[2]}] ;# MGTYTXN2_127 GTYE4_CHANNEL_X0Y34 / GTYE4_COMMON_X0Y8
set_property -dict {LOC K43 } [get_ports {qsfp3_rx_p[3]}] ;# MGTYRXP3_127 GTYE4_CHANNEL_X0Y35 / GTYE4_COMMON_X0Y8
set_property -dict {LOC K44 } [get_ports {qsfp3_rx_n[3]}] ;# MGTYRXN3_127 GTYE4_CHANNEL_X0Y35 / GTYE4_COMMON_X0Y8
set_property -dict {LOC J40 } [get_ports {qsfp3_tx_p[3]}] ;# MGTYTXP3_127 GTYE4_CHANNEL_X0Y35 / GTYE4_COMMON_X0Y8
set_property -dict {LOC J41 } [get_ports {qsfp3_tx_n[3]}] ;# MGTYTXN3_127 GTYE4_CHANNEL_X0Y35 / GTYE4_COMMON_X0Y8
set_property -dict {LOC R36 } [get_ports qsfp3_mgt_refclk_b0_p] ;# MGTREFCLK0P_127 from Si5338 B ch 0
set_property -dict {LOC R37 } [get_ports qsfp3_mgt_refclk_b0_n] ;# MGTREFCLK0N_127 from Si5338 B ch 0
#set_property -dict {LOC N36 } [get_ports qsfp3_mgt_refclk_b3_p] ;# MGTREFCLK1P_127 from Si5338 B ch 3
#set_property -dict {LOC N37 } [get_ports qsfp3_mgt_refclk_b3_n] ;# MGTREFCLK1N_127 from Si5338 B ch 3
#set_property -dict {LOC L36 } [get_ports qsfp3_mgt_refclk_d2_p] ;# MGTREFCLK0P_128 from Si5338 D ch 2
#set_property -dict {LOC L37 } [get_ports qsfp3_mgt_refclk_d2_n] ;# MGTREFCLK0N_128 from Si5338 D ch 2
#set_property -dict {LOC K38 } [get_ports qsfp3_mgt_refclk_d3_p] ;# MGTREFCLK1P_128 from Si5338 D ch 3
#set_property -dict {LOC K39 } [get_ports qsfp3_mgt_refclk_d3_n] ;# MGTREFCLK1N_128 from Si5338 D ch 3
set_property -dict {LOC BC23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp3_resetl]
set_property -dict {LOC BB24 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp3_modprsl]
set_property -dict {LOC AY22 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp3_intl]
set_property -dict {LOC BA22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp3_lpmode]
set_property -dict {LOC BC22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp3_i2c_scl]
set_property -dict {LOC BA24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp3_i2c_sda]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 0)
create_clock -period 3.103 -name qsfp3_mgt_refclk_b0 [get_ports qsfp3_mgt_refclk_b0_p]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 2)
#create_clock -period 3.103 -name qsfp3_mgt_refclk_b3 [get_ports qsfp3_mgt_refclk_b3_p]

# 322.265625 MHz MGT reference clock (from Si5338 D ch 2)
#create_clock -period 3.103 -name qsfp3_mgt_refclk_d2 [get_ports qsfp3_mgt_refclk_d2_p]

# 322.265625 MHz MGT reference clock (from Si5338 D ch 3)
#create_clock -period 3.103 -name qsfp3_mgt_refclk_d3 [get_ports qsfp3_mgt_refclk_d3_p]

set_false_path -to [get_ports {qsfp3_resetl qsfp3_lpmode}]
set_output_delay 0 [get_ports {qsfp3_resetl qsfp3_lpmode}]
set_false_path -from [get_ports {qsfp3_modprsl qsfp3_intl}]
set_input_delay 0 [get_ports {qsfp3_modprsl qsfp3_intl}]

set_false_path -to [get_ports {qsfp3_i2c_scl qsfp3_i2c_sda}]
set_output_delay 0 [get_ports {qsfp3_i2c_scl qsfp3_i2c_sda}]
set_false_path -from [get_ports {qsfp3_i2c_scl qsfp3_i2c_sda}]
set_input_delay 0 [get_ports {qsfp3_i2c_scl qsfp3_i2c_sda}]
