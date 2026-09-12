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

# QSFP Interfaces
set_property -dict {LOC Y2  } [get_ports {qsfp0_rx_p[0]}] ;# MGTHRXP0_226 GTHE3_CHANNEL_X1Y44 / GTHE3_COMMON_X1Y11
set_property -dict {LOC Y1  } [get_ports {qsfp0_rx_n[0]}] ;# MGTHRXN0_226 GTHE3_CHANNEL_X1Y44 / GTHE3_COMMON_X1Y11
set_property -dict {LOC AA4 } [get_ports {qsfp0_tx_p[0]}] ;# MGTHTXP0_226 GTHE3_CHANNEL_X1Y44 / GTHE3_COMMON_X1Y11
set_property -dict {LOC AA3 } [get_ports {qsfp0_tx_n[0]}] ;# MGTHTXN0_226 GTHE3_CHANNEL_X1Y44 / GTHE3_COMMON_X1Y11
set_property -dict {LOC V2  } [get_ports {qsfp0_rx_p[1]}] ;# MGTHRXP1_226 GTHE3_CHANNEL_X1Y45 / GTHE3_COMMON_X1Y11
set_property -dict {LOC V1  } [get_ports {qsfp0_rx_n[1]}] ;# MGTHRXN1_226 GTHE3_CHANNEL_X1Y45 / GTHE3_COMMON_X1Y11
set_property -dict {LOC W4  } [get_ports {qsfp0_tx_p[1]}] ;# MGTHTXP1_226 GTHE3_CHANNEL_X1Y45 / GTHE3_COMMON_X1Y11
set_property -dict {LOC W3  } [get_ports {qsfp0_tx_n[1]}] ;# MGTHTXN1_226 GTHE3_CHANNEL_X1Y45 / GTHE3_COMMON_X1Y11
set_property -dict {LOC T2  } [get_ports {qsfp0_rx_p[2]}] ;# MGTHRXP2_226 GTHE3_CHANNEL_X1Y46 / GTHE3_COMMON_X1Y11
set_property -dict {LOC T1  } [get_ports {qsfp0_rx_n[2]}] ;# MGTHRXN2_226 GTHE3_CHANNEL_X1Y46 / GTHE3_COMMON_X1Y11
set_property -dict {LOC U4  } [get_ports {qsfp0_tx_p[2]}] ;# MGTHTXP2_226 GTHE3_CHANNEL_X1Y46 / GTHE3_COMMON_X1Y11
set_property -dict {LOC U3  } [get_ports {qsfp0_tx_n[2]}] ;# MGTHTXN2_226 GTHE3_CHANNEL_X1Y46 / GTHE3_COMMON_X1Y11
set_property -dict {LOC P2  } [get_ports {qsfp0_rx_p[3]}] ;# MGTHRXP3_226 GTHE3_CHANNEL_X1Y47 / GTHE3_COMMON_X1Y11
set_property -dict {LOC P1  } [get_ports {qsfp0_rx_n[3]}] ;# MGTHRXN3_226 GTHE3_CHANNEL_X1Y47 / GTHE3_COMMON_X1Y11
set_property -dict {LOC R4  } [get_ports {qsfp0_tx_p[3]}] ;# MGTHTXP3_226 GTHE3_CHANNEL_X1Y47 / GTHE3_COMMON_X1Y11
set_property -dict {LOC R3  } [get_ports {qsfp0_tx_n[3]}] ;# MGTHTXN3_226 GTHE3_CHANNEL_X1Y47 / GTHE3_COMMON_X1Y11
set_property -dict {LOC V6  } [get_ports qsfp0_mgt_refclk_p] ;# MGTREFCLK0P_226 from Y5.4
set_property -dict {LOC V5  } [get_ports qsfp0_mgt_refclk_n] ;# MGTREFCLK0N_226 from Y5.5
set_property -dict {LOC AJ11 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports {qsfp0_fs[0]}] ;# to Y5.8
set_property -dict {LOC AF10 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports {qsfp0_fs[1]}] ;# to Y5.7
set_property -dict {LOC AJ13 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports qsfp0_modsell]
set_property -dict {LOC AE12 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports qsfp0_resetl]
set_property -dict {LOC AE26 IOSTANDARD LVCMOS12 PULLUP true} [get_ports qsfp0_modprsl]
set_property -dict {LOC AE21 IOSTANDARD LVCMOS12 PULLUP true} [get_ports qsfp0_intl]
set_property -dict {LOC AF12 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports qsfp0_lpmode]
#set_property -dict {LOC AD11 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12 PULLUP true} [get_ports qsfp0_i2c_scl]
#set_property -dict {LOC AE11 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12 PULLUP true} [get_ports qsfp0_i2c_sda]

# 156.25 MHz MGT reference clock (from Y5 Si534 FB000184G, FS = 0b00)
create_clock -period 6.400 -name qsfp0_mgt_refclk [get_ports qsfp0_mgt_refclk_p]

# 200 MHz MGT reference clock (from Y5 Si534 FB000184G, FS = 0b01)
#create_clock -period 5.000 -name qsfp0_mgt_refclk [get_ports qsfp0_mgt_refclk_p]

# 250 MHz MGT reference clock (from Y5 Si534 FB000184G, FS = 0b10)
#create_clock -period 4.000 -name qsfp0_mgt_refclk [get_ports qsfp0_mgt_refclk_p]

# 312.5 MHz MGT reference clock (from Y5 Si534 FB000184G, FS = 0b11)
#create_clock -period 3.200 -name qsfp0_mgt_refclk [get_ports qsfp0_mgt_refclk_p]

set_false_path -to [get_ports {qsfp0_modsell qsfp0_resetl qsfp0_lpmode qsfp0_fs[*]}]
set_output_delay 0 [get_ports {qsfp0_modsell qsfp0_resetl qsfp0_lpmode qsfp0_fs[*]}]
set_false_path -from [get_ports {qsfp0_modprsl qsfp0_intl}]
set_input_delay 0 [get_ports {qsfp0_modprsl qsfp0_intl}]

#set_false_path -to [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]
#set_output_delay 0 [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]
#set_false_path -from [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]
#set_input_delay 0 [get_ports {qsfp0_i2c_scl qsfp0_i2c_sda}]

set_property -dict {LOC M2  } [get_ports {qsfp1_rx_p[0]}] ;# MGTHRXP0_227 GTHE3_CHANNEL_X1Y40 / GTHE3_COMMON_X1Y2
set_property -dict {LOC M1  } [get_ports {qsfp1_rx_n[0]}] ;# MGTHRXN0_227 GTHE3_CHANNEL_X1Y40 / GTHE3_COMMON_X1Y2
set_property -dict {LOC N4  } [get_ports {qsfp1_tx_p[0]}] ;# MGTHTXP0_227 GTHE3_CHANNEL_X1Y40 / GTHE3_COMMON_X1Y2
set_property -dict {LOC N3  } [get_ports {qsfp1_tx_n[0]}] ;# MGTHTXN0_227 GTHE3_CHANNEL_X1Y40 / GTHE3_COMMON_X1Y2
set_property -dict {LOC K2  } [get_ports {qsfp1_rx_p[1]}] ;# MGTHRXP1_227 GTHE3_CHANNEL_X1Y41 / GTHE3_COMMON_X1Y2
set_property -dict {LOC K1  } [get_ports {qsfp1_rx_n[1]}] ;# MGTHRXN1_227 GTHE3_CHANNEL_X1Y41 / GTHE3_COMMON_X1Y2
set_property -dict {LOC L4  } [get_ports {qsfp1_tx_p[1]}] ;# MGTHTXP1_227 GTHE3_CHANNEL_X1Y41 / GTHE3_COMMON_X1Y2
set_property -dict {LOC L3  } [get_ports {qsfp1_tx_n[1]}] ;# MGTHTXN1_227 GTHE3_CHANNEL_X1Y41 / GTHE3_COMMON_X1Y2
set_property -dict {LOC H2  } [get_ports {qsfp1_rx_p[2]}] ;# MGTHRXP2_227 GTHE3_CHANNEL_X1Y42 / GTHE3_COMMON_X1Y2
set_property -dict {LOC H1  } [get_ports {qsfp1_rx_n[2]}] ;# MGTHRXN2_227 GTHE3_CHANNEL_X1Y42 / GTHE3_COMMON_X1Y2
set_property -dict {LOC J4  } [get_ports {qsfp1_tx_p[2]}] ;# MGTHTXP2_227 GTHE3_CHANNEL_X1Y42 / GTHE3_COMMON_X1Y2
set_property -dict {LOC J3  } [get_ports {qsfp1_tx_n[2]}] ;# MGTHTXN2_227 GTHE3_CHANNEL_X1Y42 / GTHE3_COMMON_X1Y2
set_property -dict {LOC F2  } [get_ports {qsfp1_rx_p[3]}] ;# MGTHRXP3_227 GTHE3_CHANNEL_X1Y43 / GTHE3_COMMON_X1Y2
set_property -dict {LOC F1  } [get_ports {qsfp1_rx_n[3]}] ;# MGTHRXN3_227 GTHE3_CHANNEL_X1Y43 / GTHE3_COMMON_X1Y2
set_property -dict {LOC G4  } [get_ports {qsfp1_tx_p[3]}] ;# MGTHTXP3_227 GTHE3_CHANNEL_X1Y43 / GTHE3_COMMON_X1Y2
set_property -dict {LOC G3  } [get_ports {qsfp1_tx_n[3]}] ;# MGTHTXN3_227 GTHE3_CHANNEL_X1Y43 / GTHE3_COMMON_X1Y2
#set_property -dict {LOC P6  } [get_ports qsfp1_mgt_refclk_p] ;# MGTREFCLK0P_227 from Y4.4
#set_property -dict {LOC P5  } [get_ports qsfp1_mgt_refclk_n] ;# MGTREFCLK0N_227 from Y4.5
set_property -dict {LOC AG11 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports {qsfp1_fs[0]}] ;# to Y4.8
set_property -dict {LOC AH11 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports {qsfp1_fs[1]}] ;# to Y4.7
set_property -dict {LOC AK13 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports qsfp1_modsell]
set_property -dict {LOC AL13 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports qsfp1_resetl]
set_property -dict {LOC AM9  IOSTANDARD LVCMOS25 PULLUP true} [get_ports qsfp1_modprsl]
set_property -dict {LOC AH13 IOSTANDARD LVCMOS25 PULLUP true} [get_ports qsfp1_intl]
set_property -dict {LOC AK11 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12} [get_ports qsfp1_lpmode]
#set_property -dict {LOC AE13 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12 PULLUP true} [get_ports qsfp1_i2c_scl]
#set_property -dict {LOC AF13 IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12 PULLUP true} [get_ports qsfp1_i2c_sda]

# 156.25 MHz MGT reference clock (from Y4 Si534 FB000184G, FS = 0b00)
#create_clock -period 6.400 -name qsfp1_mgt_refclk [get_ports qsfp1_mgt_refclk_p]

# 200 MHz MGT reference clock (from Y4 Si534 FB000184G, FS = 0b01)
#create_clock -period 5.000 -name qsfp1_mgt_refclk [get_ports qsfp1_mgt_refclk_p]

# 250 MHz MGT reference clock (from Y4 Si534 FB000184G, FS = 0b10)
#create_clock -period 4.000 -name qsfp1_mgt_refclk [get_ports qsfp1_mgt_refclk_p]

# 312.5 MHz MGT reference clock (from Y4 Si534 FB000184G, FS = 0b11)
#create_clock -period 3.200 -name qsfp1_mgt_refclk [get_ports qsfp1_mgt_refclk_p]

set_false_path -to [get_ports {qsfp1_modsell qsfp1_resetl qsfp1_lpmode qsfp1_fs[*]}]
set_output_delay 0 [get_ports {qsfp1_modsell qsfp1_resetl qsfp1_lpmode qsfp1_fs[*]}]
set_false_path -from [get_ports {qsfp1_modprsl qsfp1_intl}]
set_input_delay 0 [get_ports {qsfp1_modprsl qsfp1_intl}]

#set_false_path -to [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]
#set_output_delay 0 [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]
#set_false_path -from [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]
#set_input_delay 0 [get_ports {qsfp1_i2c_scl qsfp1_i2c_sda}]
