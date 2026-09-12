# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the BittWare XUSP3S board
# part: xcvu095-ffvb2104-2-e

# QSFP28 Interfaces
set_property -dict {LOC BC45} [get_ports {qsfp0_rx_p[0]}] ;# MGTHRXP0_124 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BC46} [get_ports {qsfp0_rx_n[0]}] ;# MGTHRXN0_124 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BF42} [get_ports {qsfp0_tx_p[0]}] ;# MGTHTXP0_124 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BF43} [get_ports {qsfp0_tx_n[0]}] ;# MGTHTXN0_124 GTYE4_CHANNEL_X0Y4 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BA45} [get_ports {qsfp0_rx_p[1]}] ;# MGTHRXP1_124 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BA46} [get_ports {qsfp0_rx_n[1]}] ;# MGTHRXN1_124 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BD42} [get_ports {qsfp0_tx_p[1]}] ;# MGTHTXP1_124 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BD43} [get_ports {qsfp0_tx_n[1]}] ;# MGTHTXN1_124 GTYE4_CHANNEL_X0Y5 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AW45} [get_ports {qsfp0_rx_p[2]}] ;# MGTHRXP2_124 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AW46} [get_ports {qsfp0_rx_n[2]}] ;# MGTHRXN2_124 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BB42} [get_ports {qsfp0_tx_p[2]}] ;# MGTHTXP2_124 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BB43} [get_ports {qsfp0_tx_n[2]}] ;# MGTHTXN2_124 GTYE4_CHANNEL_X0Y6 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AV43} [get_ports {qsfp0_rx_p[3]}] ;# MGTHRXP3_124 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AV44} [get_ports {qsfp0_rx_n[3]}] ;# MGTHRXN3_124 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AW40} [get_ports {qsfp0_tx_p[3]}] ;# MGTHTXP3_124 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
set_property -dict {LOC AW41} [get_ports {qsfp0_tx_n[3]}] ;# MGTHTXN3_124 GTYE4_CHANNEL_X0Y7 / GTYE4_COMMON_X0Y1
set_property -dict {LOC BA40} [get_ports qsfp0_mgt_refclk_b0_p] ;# MGTREFCLK0P_124 from Si5338 B ch 0
set_property -dict {LOC BA41} [get_ports qsfp0_mgt_refclk_b0_n] ;# MGTREFCLK0N_124 from Si5338 B ch 0
#set_property -dict {LOC AY38} [get_ports qsfp0_mgt_refclk_b1_p] ;# MGTREFCLK1P_124 from Si5338 B ch 1
#set_property -dict {LOC AY39} [get_ports qsfp0_mgt_refclk_b1_n] ;# MGTREFCLK1N_124 from Si5338 B ch 1
set_property -dict {LOC BD24 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp0_resetl]
set_property -dict {LOC BD23 IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp0_modprsl]
set_property -dict {LOC BE23 IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp0_intl]
set_property -dict {LOC BC24 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp0_lpmode]
set_property -dict {LOC BF24 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp0_i2c_scl]
set_property -dict {LOC BF23 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp0_i2c_sda]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 0)
create_clock -period 3.103 -name qsfp0_mgt_refclk_b0 [get_ports qsfp0_mgt_refclk_b0_p]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 1)
#create_clock -period 3.103 -name qsfp0_mgt_refclk_b1 [get_ports qsfp0_mgt_refclk_b1_p]

set_false_path -to [get_ports {qsfp0_resetl qsfp0_lpmode}]
set_output_delay 0 [get_ports {qsfp0_resetl qsfp0_lpmode}]
set_false_path -from [get_ports {qsfp0_modprsl qsfp0_intl}]
set_input_delay 0 [get_ports {qsfp0_modprsl qsfp0_intl}]

set_false_path -to [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]
set_output_delay 0 [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]
set_false_path -from [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]
set_input_delay 0 [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]

set_property -dict {LOC AN45} [get_ports {qsfp1_rx_p[0]}] ;# MGTHRXP0_126 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AN46} [get_ports {qsfp1_rx_n[0]}] ;# MGTHRXN0_126 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AN40} [get_ports {qsfp1_tx_p[0]}] ;# MGTHTXP0_126 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AN41} [get_ports {qsfp1_tx_n[0]}] ;# MGTHTXN0_126 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AM43} [get_ports {qsfp1_rx_p[1]}] ;# MGTHRXP1_126 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AM44} [get_ports {qsfp1_rx_n[1]}] ;# MGTHRXN1_126 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AM38} [get_ports {qsfp1_tx_p[1]}] ;# MGTHTXP1_126 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AM39} [get_ports {qsfp1_tx_n[1]}] ;# MGTHTXN1_126 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AL45} [get_ports {qsfp1_rx_p[2]}] ;# MGTHRXP2_126 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AL46} [get_ports {qsfp1_rx_n[2]}] ;# MGTHRXN2_126 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AL40} [get_ports {qsfp1_tx_p[2]}] ;# MGTHTXP2_126 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AL41} [get_ports {qsfp1_tx_n[2]}] ;# MGTHTXN2_126 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AK43} [get_ports {qsfp1_rx_p[3]}] ;# MGTHRXP3_126 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AK44} [get_ports {qsfp1_rx_n[3]}] ;# MGTHRXN3_126 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AK38} [get_ports {qsfp1_tx_p[3]}] ;# MGTHTXP3_126 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AK39} [get_ports {qsfp1_tx_n[3]}] ;# MGTHTXN3_126 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AR36} [get_ports qsfp1_mgt_refclk_b0_p] ;# MGTREFCLK0P_126 from Si5338 B ch 0
set_property -dict {LOC AR37} [get_ports qsfp1_mgt_refclk_b0_n] ;# MGTREFCLK0N_126 from Si5338 B ch 0
#set_property -dict {LOC AN36} [get_ports qsfp1_mgt_refclk_b1_p] ;# MGTREFCLK1P_126 from Si5338 B ch 1
#set_property -dict {LOC AN37} [get_ports qsfp1_mgt_refclk_b1_n] ;# MGTREFCLK1N_126 from Si5338 B ch 1
set_property -dict {LOC BE20 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp1_resetl]
set_property -dict {LOC BD21 IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp1_modprsl]
set_property -dict {LOC BE21 IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp1_intl]
set_property -dict {LOC BD20 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp1_lpmode]
set_property -dict {LOC BE22 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp1_i2c_scl]
set_property -dict {LOC BF22 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp1_i2c_sda]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 0)
create_clock -period 3.103 -name qsfp1_mgt_refclk_b0 [get_ports qsfp1_mgt_refclk_b0_p]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 1)
#create_clock -period 3.103 -name qsfp1_mgt_refclk_b1 [get_ports qsfp1_mgt_refclk_b1_p]

set_false_path -to [get_ports {qsfp1_resetl qsfp1_lpmode}]
set_output_delay 0 [get_ports {qsfp1_resetl qsfp1_lpmode}]
set_false_path -from [get_ports {qsfp1_modprsl qsfp1_intl}]
set_input_delay 0 [get_ports {qsfp1_modprsl qsfp1_intl}]

set_false_path -to [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]
set_output_delay 0 [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]
set_false_path -from [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]
set_input_delay 0 [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]

set_property -dict {LOC AA45} [get_ports {qsfp2_rx_p[0]}] ;# MGTHRXP0_129 GTYE4_CHANNEL_X0Y24 / GTYE4_COMMON_X0Y6
set_property -dict {LOC AA46} [get_ports {qsfp2_rx_n[0]}] ;# MGTHRXN0_129 GTYE4_CHANNEL_X0Y24 / GTYE4_COMMON_X0Y6
set_property -dict {LOC AA40} [get_ports {qsfp2_tx_p[0]}] ;# MGTHTXP0_129 GTYE4_CHANNEL_X0Y24 / GTYE4_COMMON_X0Y6
set_property -dict {LOC AA41} [get_ports {qsfp2_tx_n[0]}] ;# MGTHTXN0_129 GTYE4_CHANNEL_X0Y24 / GTYE4_COMMON_X0Y6
set_property -dict {LOC Y43 } [get_ports {qsfp2_rx_p[1]}] ;# MGTHRXP1_129 GTYE4_CHANNEL_X0Y25 / GTYE4_COMMON_X0Y6
set_property -dict {LOC Y44 } [get_ports {qsfp2_rx_n[1]}] ;# MGTHRXN1_129 GTYE4_CHANNEL_X0Y25 / GTYE4_COMMON_X0Y6
set_property -dict {LOC Y38 } [get_ports {qsfp2_tx_p[1]}] ;# MGTHTXP1_129 GTYE4_CHANNEL_X0Y25 / GTYE4_COMMON_X0Y6
set_property -dict {LOC Y39 } [get_ports {qsfp2_tx_n[1]}] ;# MGTHTXN1_129 GTYE4_CHANNEL_X0Y25 / GTYE4_COMMON_X0Y6
set_property -dict {LOC W45 } [get_ports {qsfp2_rx_p[2]}] ;# MGTHRXP2_129 GTYE4_CHANNEL_X0Y26 / GTYE4_COMMON_X0Y6
set_property -dict {LOC W46 } [get_ports {qsfp2_rx_n[2]}] ;# MGTHRXN2_129 GTYE4_CHANNEL_X0Y26 / GTYE4_COMMON_X0Y6
set_property -dict {LOC W40 } [get_ports {qsfp2_tx_p[2]}] ;# MGTHTXP2_129 GTYE4_CHANNEL_X0Y26 / GTYE4_COMMON_X0Y6
set_property -dict {LOC W41 } [get_ports {qsfp2_tx_n[2]}] ;# MGTHTXN2_129 GTYE4_CHANNEL_X0Y26 / GTYE4_COMMON_X0Y6
set_property -dict {LOC V43 } [get_ports {qsfp2_rx_p[3]}] ;# MGTHRXP3_129 GTYE4_CHANNEL_X0Y27 / GTYE4_COMMON_X0Y6
set_property -dict {LOC V44 } [get_ports {qsfp2_rx_n[3]}] ;# MGTHRXN3_129 GTYE4_CHANNEL_X0Y27 / GTYE4_COMMON_X0Y6
set_property -dict {LOC V38 } [get_ports {qsfp2_tx_p[3]}] ;# MGTHTXP3_129 GTYE4_CHANNEL_X0Y27 / GTYE4_COMMON_X0Y6
set_property -dict {LOC V39 } [get_ports {qsfp2_tx_n[3]}] ;# MGTHTXN3_129 GTYE4_CHANNEL_X0Y27 / GTYE4_COMMON_X0Y6
set_property -dict {LOC AC36} [get_ports qsfp2_mgt_refclk_b0_p] ;# MGTREFCLK0P_129 from Si5338 B ch 0
set_property -dict {LOC AC37} [get_ports qsfp2_mgt_refclk_b0_n] ;# MGTREFCLK0N_129 from Si5338 B ch 0
#set_property -dict {LOC AA36} [get_ports qsfp2_mgt_refclk_b2_p] ;# MGTREFCLK1P_129 from Si5338 B ch 2
#set_property -dict {LOC AA37} [get_ports qsfp2_mgt_refclk_b2_n] ;# MGTREFCLK1N_129 from Si5338 B ch 2
set_property -dict {LOC BB22 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp2_resetl]
set_property -dict {LOC BB20 IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp2_modprsl]
set_property -dict {LOC BB21 IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp2_intl]
set_property -dict {LOC BC21 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp2_lpmode]
set_property -dict {LOC BF20 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp2_i2c_scl]
set_property -dict {LOC BA20 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp2_i2c_sda]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 0)
create_clock -period 3.103 -name qsfp2_mgt_refclk_b0 [get_ports qsfp2_mgt_refclk_b0_p]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 2)
#create_clock -period 3.103 -name qsfp2_mgt_refclk_b2 [get_ports qsfp2_mgt_refclk_b2_p]

set_false_path -to [get_ports {qsfp2_resetl qsfp2_lpmode}]
set_output_delay 0 [get_ports {qsfp2_resetl qsfp2_lpmode}]
set_false_path -from [get_ports {qsfp2_modprsl qsfp2_intl}]
set_input_delay 0 [get_ports {qsfp2_modprsl qsfp2_intl}]

set_false_path -to [get_ports {qsfp2_i2c_scl qsfp2_i2c_sda}]
set_output_delay 0 [get_ports {qsfp2_i2c_scl qsfp2_i2c_sda}]
set_false_path -from [get_ports {qsfp2_i2c_scl qsfp2_i2c_sda}]
set_input_delay 0 [get_ports {qsfp2_i2c_scl qsfp2_i2c_sda}]

set_property -dict {LOC N45 } [get_ports {qsfp3_rx_p[0]}] ;# MGTHRXP0_131 GTYE4_CHANNEL_X0Y32 / GTYE4_COMMON_X0Y8
set_property -dict {LOC N46 } [get_ports {qsfp3_rx_n[0]}] ;# MGTHRXN0_131 GTYE4_CHANNEL_X0Y32 / GTYE4_COMMON_X0Y8
set_property -dict {LOC N40 } [get_ports {qsfp3_tx_p[0]}] ;# MGTHTXP0_131 GTYE4_CHANNEL_X0Y32 / GTYE4_COMMON_X0Y8
set_property -dict {LOC N41 } [get_ports {qsfp3_tx_n[0]}] ;# MGTHTXN0_131 GTYE4_CHANNEL_X0Y32 / GTYE4_COMMON_X0Y8
set_property -dict {LOC M43 } [get_ports {qsfp3_rx_p[1]}] ;# MGTHRXP1_131 GTYE4_CHANNEL_X0Y33 / GTYE4_COMMON_X0Y8
set_property -dict {LOC M44 } [get_ports {qsfp3_rx_n[1]}] ;# MGTHRXN1_131 GTYE4_CHANNEL_X0Y33 / GTYE4_COMMON_X0Y8
set_property -dict {LOC M38 } [get_ports {qsfp3_tx_p[1]}] ;# MGTHTXP1_131 GTYE4_CHANNEL_X0Y33 / GTYE4_COMMON_X0Y8
set_property -dict {LOC M39 } [get_ports {qsfp3_tx_n[1]}] ;# MGTHTXN1_131 GTYE4_CHANNEL_X0Y33 / GTYE4_COMMON_X0Y8
set_property -dict {LOC L45 } [get_ports {qsfp3_rx_p[2]}] ;# MGTHRXP2_131 GTYE4_CHANNEL_X0Y34 / GTYE4_COMMON_X0Y8
set_property -dict {LOC L46 } [get_ports {qsfp3_rx_n[2]}] ;# MGTHRXN2_131 GTYE4_CHANNEL_X0Y34 / GTYE4_COMMON_X0Y8
set_property -dict {LOC L40 } [get_ports {qsfp3_tx_p[2]}] ;# MGTHTXP2_131 GTYE4_CHANNEL_X0Y34 / GTYE4_COMMON_X0Y8
set_property -dict {LOC L41 } [get_ports {qsfp3_tx_n[2]}] ;# MGTHTXN2_131 GTYE4_CHANNEL_X0Y34 / GTYE4_COMMON_X0Y8
set_property -dict {LOC K43 } [get_ports {qsfp3_rx_p[3]}] ;# MGTHRXP3_131 GTYE4_CHANNEL_X0Y35 / GTYE4_COMMON_X0Y8
set_property -dict {LOC K44 } [get_ports {qsfp3_rx_n[3]}] ;# MGTHRXN3_131 GTYE4_CHANNEL_X0Y35 / GTYE4_COMMON_X0Y8
set_property -dict {LOC J40 } [get_ports {qsfp3_tx_p[3]}] ;# MGTHTXP3_131 GTYE4_CHANNEL_X0Y35 / GTYE4_COMMON_X0Y8
set_property -dict {LOC J41 } [get_ports {qsfp3_tx_n[3]}] ;# MGTHTXN3_131 GTYE4_CHANNEL_X0Y35 / GTYE4_COMMON_X0Y8
set_property -dict {LOC R36 } [get_ports qsfp3_mgt_refclk_b0_p] ;# MGTREFCLK0P_131 from Si5338 B ch 0
set_property -dict {LOC R37 } [get_ports qsfp3_mgt_refclk_b0_n] ;# MGTREFCLK0N_131 from Si5338 B ch 0
#set_property -dict {LOC N36 } [get_ports qsfp3_mgt_refclk_b3_p] ;# MGTREFCLK1P_131 from Si5338 B ch 3
#set_property -dict {LOC N37 } [get_ports qsfp3_mgt_refclk_b3_n] ;# MGTREFCLK1N_131 from Si5338 B ch 3
set_property -dict {LOC BC23 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp3_resetl]
set_property -dict {LOC BB24 IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp3_modprsl]
set_property -dict {LOC AY22 IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp3_intl]
set_property -dict {LOC BA22 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp3_lpmode]
set_property -dict {LOC BC22 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp3_i2c_scl]
set_property -dict {LOC BA24 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8 PULLUP true} [get_ports qsfp3_i2c_sda]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 0)
create_clock -period 3.103 -name qsfp3_mgt_refclk_b0 [get_ports qsfp3_mgt_refclk_b0_p]

# 322.265625 MHz MGT reference clock (from Si5338 B ch 2)
#create_clock -period 3.103 -name qsfp3_mgt_refclk_b3 [get_ports qsfp3_mgt_refclk_b3_p]

set_false_path -to [get_ports {qsfp3_resetl qsfp3_lpmode}]
set_output_delay 0 [get_ports {qsfp3_resetl qsfp3_lpmode}]
set_false_path -from [get_ports {qsfp3_modprsl qsfp3_intl}]
set_input_delay 0 [get_ports {qsfp3_modprsl qsfp3_intl}]

set_false_path -to [get_ports {qsfp3_i2c_scl qsfp3_i2c_sda}]
set_output_delay 0 [get_ports {qsfp3_i2c_scl qsfp3_i2c_sda}]
set_false_path -from [get_ports {qsfp3_i2c_scl qsfp3_i2c_sda}]
set_input_delay 0 [get_ports {qsfp3_i2c_scl qsfp3_i2c_sda}]
