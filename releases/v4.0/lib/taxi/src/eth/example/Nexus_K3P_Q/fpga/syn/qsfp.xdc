# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Cisco Nexus K3P-Q / ExaNIC X100
# part: xcku3p-ffvb676-2-e

# QSFP28 Interfaces
set_property -dict {LOC M2  } [get_ports {qsfp_0_rx_p[0]}] ;# MGTYRXP0_226 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2
set_property -dict {LOC M1  } [get_ports {qsfp_0_rx_n[0]}] ;# MGTYRXN0_226 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2
set_property -dict {LOC N5  } [get_ports {qsfp_0_tx_p[0]}] ;# MGTYTXP0_226 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2
set_property -dict {LOC N4  } [get_ports {qsfp_0_tx_n[0]}] ;# MGTYTXN0_226 GTYE4_CHANNEL_X0Y8 / GTYE4_COMMON_X0Y2
set_property -dict {LOC K2  } [get_ports {qsfp_0_rx_p[1]}] ;# MGTYRXP1_226 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2
set_property -dict {LOC K1  } [get_ports {qsfp_0_rx_n[1]}] ;# MGTYRXN1_226 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2
set_property -dict {LOC L5  } [get_ports {qsfp_0_tx_p[1]}] ;# MGTYTXP1_226 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2
set_property -dict {LOC L4  } [get_ports {qsfp_0_tx_n[1]}] ;# MGTYTXN1_226 GTYE4_CHANNEL_X0Y9 / GTYE4_COMMON_X0Y2
set_property -dict {LOC F2  } [get_ports {qsfp_0_rx_p[2]}] ;# MGTYRXP3_226 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2
set_property -dict {LOC F1  } [get_ports {qsfp_0_rx_n[2]}] ;# MGTYRXN3_226 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2
set_property -dict {LOC G5  } [get_ports {qsfp_0_tx_p[2]}] ;# MGTYTXP3_226 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2
set_property -dict {LOC G4  } [get_ports {qsfp_0_tx_n[2]}] ;# MGTYTXN3_226 GTYE4_CHANNEL_X0Y11 / GTYE4_COMMON_X0Y2
set_property -dict {LOC H2  } [get_ports {qsfp_0_rx_p[3]}] ;# MGTYRXP2_226 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2
set_property -dict {LOC H1  } [get_ports {qsfp_0_rx_n[3]}] ;# MGTYRXN2_226 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2
set_property -dict {LOC J5  } [get_ports {qsfp_0_tx_p[3]}] ;# MGTYTXP2_226 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2
set_property -dict {LOC J4  } [get_ports {qsfp_0_tx_n[3]}] ;# MGTYTXN2_226 GTYE4_CHANNEL_X0Y10 / GTYE4_COMMON_X0Y2
set_property -dict {LOC W16  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp_0_modsell]
set_property -dict {LOC Y15  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp_0_resetl]
set_property -dict {LOC W14  IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp_0_modprsl]
set_property -dict {LOC W15  IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp_0_intl]
set_property -dict {LOC Y13  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp_0_lpmode]
#set_property -dict {LOC AC13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12 PULLUP true} [get_ports qsfp_0_i2c_sda]
#set_property -dict {LOC Y16  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12 PULLUP true} [get_ports qsfp_0_i2c_scl]

set_false_path -to [get_ports {qsfp_0_modsell qsfp_0_resetl qsfp_0_lpmode}]
set_output_delay 0 [get_ports {qsfp_0_modsell qsfp_0_resetl qsfp_0_lpmode}]
set_false_path -from [get_ports {qsfp_0_modprsl qsfp_0_intl}]
set_input_delay 0 [get_ports {qsfp_0_modprsl qsfp_0_intl}]

#set_false_path -to [get_ports {qsfp_0_i2c_sda qsfp_0_i2c_scl}]
#set_output_delay 0 [get_ports {qsfp_0_i2c_sda qsfp_0_i2c_scl}]
#set_false_path -from [get_ports {qsfp_0_i2c_sda qsfp_0_i2c_scl}]
#set_input_delay 0 [get_ports {qsfp_0_i2c_sda qsfp_0_i2c_scl}]

set_property -dict {LOC D2  } [get_ports {qsfp_1_rx_p[0]}] ;# MGTYRXP0_227 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC D1  } [get_ports {qsfp_1_rx_n[0]}] ;# MGTYRXN0_227 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC F7  } [get_ports {qsfp_1_tx_p[0]}] ;# MGTYTXP0_227 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC F6  } [get_ports {qsfp_1_tx_n[0]}] ;# MGTYTXN0_227 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y3
set_property -dict {LOC C4  } [get_ports {qsfp_1_rx_p[1]}] ;# MGTYRXP1_227 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC C3  } [get_ports {qsfp_1_rx_n[1]}] ;# MGTYRXN1_227 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC E5  } [get_ports {qsfp_1_tx_p[1]}] ;# MGTYTXP1_227 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC E4  } [get_ports {qsfp_1_tx_n[1]}] ;# MGTYTXN1_227 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y3
set_property -dict {LOC A4  } [get_ports {qsfp_1_rx_p[2]}] ;# MGTYRXP3_227 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC A3  } [get_ports {qsfp_1_rx_n[2]}] ;# MGTYRXN3_227 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC B7  } [get_ports {qsfp_1_tx_p[2]}] ;# MGTYTXP3_227 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC B6  } [get_ports {qsfp_1_tx_n[2]}] ;# MGTYTXN3_227 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y3
set_property -dict {LOC B2  } [get_ports {qsfp_1_rx_p[3]}] ;# MGTYRXP2_227 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC B1  } [get_ports {qsfp_1_rx_n[3]}] ;# MGTYRXN2_227 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC D7  } [get_ports {qsfp_1_tx_p[3]}] ;# MGTYTXP2_227 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC D6  } [get_ports {qsfp_1_tx_n[3]}] ;# MGTYTXN2_227 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y3
set_property -dict {LOC AA14 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp_1_modsell]
set_property -dict {LOC AE13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp_1_resetl]
set_property -dict {LOC A13  IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp_1_modprsl]
set_property -dict {LOC A14  IOSTANDARD LVCMOS33 PULLUP true} [get_ports qsfp_1_intl]
set_property -dict {LOC B14  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp_1_lpmode]
#set_property -dict {LOC AD13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12 PULLUP true} [get_ports qsfp_1_i2c_sda]
#set_property -dict {LOC AF13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12 PULLUP true} [get_ports qsfp_1_i2c_scl]

# 161.1328125 MHz MGT reference clock
set_property -dict {LOC K7  } [get_ports qsfp_mgt_refclk_p] ;# MGTREFCLK0P_227 from X2
set_property -dict {LOC K6  } [get_ports qsfp_mgt_refclk_n] ;# MGTREFCLK0N_227 from X2
create_clock -period 6.206 -name qsfp_mgt_refclk [get_ports qsfp_mgt_refclk_p]

set_false_path -to [get_ports {qsfp_1_modsell qsfp_1_resetl qsfp_1_lpmode}]
set_output_delay 0 [get_ports {qsfp_1_modsell qsfp_1_resetl qsfp_1_lpmode}]
set_false_path -from [get_ports {qsfp_1_modprsl qsfp_1_intl}]
set_input_delay 0 [get_ports {qsfp_1_modprsl qsfp_1_intl}]

#set_false_path -to [get_ports {qsfp_1_i2c_sda qsfp_1_i2c_scl}]
#set_output_delay 0 [get_ports {qsfp_1_i2c_sda qsfp_1_i2c_scl}]
#set_false_path -from [get_ports {qsfp_1_i2c_sda qsfp_1_i2c_scl}]
#set_input_delay 0 [get_ports {qsfp_1_i2c_sda qsfp_1_i2c_scl}]
