# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo AU200/AU250/VCU1525
# AU200 part: xcu200-fsgd2104-2-e
# AU250 part: xcu250-figd2104-2-e
# VCU1525 part: xcvu9p-fsgd2104-2L-e

# QSFP28 Interfaces
set_property -dict {LOC N4  } [get_ports {qsfp0_rx_p[0]}] ;# MGTYRXP0_231 GTYE4_CHANNEL_X1Y48 / GTYE4_COMMON_X1Y12
set_property -dict {LOC N3  } [get_ports {qsfp0_rx_n[0]}] ;# MGTYRXN0_231 GTYE4_CHANNEL_X1Y48 / GTYE4_COMMON_X1Y12
set_property -dict {LOC N9  } [get_ports {qsfp0_tx_p[0]}] ;# MGTYTXP0_231 GTYE4_CHANNEL_X1Y48 / GTYE4_COMMON_X1Y12
set_property -dict {LOC N8  } [get_ports {qsfp0_tx_n[0]}] ;# MGTYTXN0_231 GTYE4_CHANNEL_X1Y48 / GTYE4_COMMON_X1Y12
set_property -dict {LOC M2  } [get_ports {qsfp0_rx_p[1]}] ;# MGTYRXP1_231 GTYE4_CHANNEL_X1Y49 / GTYE4_COMMON_X1Y12
set_property -dict {LOC M1  } [get_ports {qsfp0_rx_n[1]}] ;# MGTYRXN1_231 GTYE4_CHANNEL_X1Y49 / GTYE4_COMMON_X1Y12
set_property -dict {LOC M7  } [get_ports {qsfp0_tx_p[1]}] ;# MGTYTXP1_231 GTYE4_CHANNEL_X1Y49 / GTYE4_COMMON_X1Y12
set_property -dict {LOC M6  } [get_ports {qsfp0_tx_n[1]}] ;# MGTYTXN1_231 GTYE4_CHANNEL_X1Y49 / GTYE4_COMMON_X1Y12
set_property -dict {LOC L4  } [get_ports {qsfp0_rx_p[2]}] ;# MGTYRXP2_231 GTYE4_CHANNEL_X1Y50 / GTYE4_COMMON_X1Y12
set_property -dict {LOC L3  } [get_ports {qsfp0_rx_n[2]}] ;# MGTYRXN2_231 GTYE4_CHANNEL_X1Y50 / GTYE4_COMMON_X1Y12
set_property -dict {LOC L9  } [get_ports {qsfp0_tx_p[2]}] ;# MGTYTXP2_231 GTYE4_CHANNEL_X1Y50 / GTYE4_COMMON_X1Y12
set_property -dict {LOC L8  } [get_ports {qsfp0_tx_n[2]}] ;# MGTYTXN2_231 GTYE4_CHANNEL_X1Y50 / GTYE4_COMMON_X1Y12
set_property -dict {LOC K2  } [get_ports {qsfp0_rx_p[3]}] ;# MGTYRXP3_231 GTYE4_CHANNEL_X1Y51 / GTYE4_COMMON_X1Y12
set_property -dict {LOC K1  } [get_ports {qsfp0_rx_n[3]}] ;# MGTYRXN3_231 GTYE4_CHANNEL_X1Y51 / GTYE4_COMMON_X1Y12
set_property -dict {LOC K7  } [get_ports {qsfp0_tx_p[3]}] ;# MGTYTXP3_231 GTYE4_CHANNEL_X1Y51 / GTYE4_COMMON_X1Y12
set_property -dict {LOC K6  } [get_ports {qsfp0_tx_n[3]}] ;# MGTYTXN3_231 GTYE4_CHANNEL_X1Y51 / GTYE4_COMMON_X1Y12
set_property -dict {LOC M11 } [get_ports {qsfp0_mgt_refclk_0_p}] ;# MGTREFCLK0P_231 from U14.4 via U43.13
set_property -dict {LOC M10 } [get_ports {qsfp0_mgt_refclk_0_n}] ;# MGTREFCLK0N_231 from U14.5 via U43.14
#set_property -dict {LOC K11 } [get_ports {qsfp0_mgt_refclk_1_p}] ;# MGTREFCLK1P_231 from U9.18
#set_property -dict {LOC K10 } [get_ports {qsfp0_mgt_refclk_1_n}] ;# MGTREFCLK1N_231 from U9.17
set_property -dict {LOC BE16 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp0_modsell}]
set_property -dict {LOC BE17 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp0_resetl}]
set_property -dict {LOC BE20 IOSTANDARD LVCMOS12 PULLUP true} [get_ports {qsfp0_modprsl}]
set_property -dict {LOC BE21 IOSTANDARD LVCMOS12 PULLUP true} [get_ports {qsfp0_intl}]
set_property -dict {LOC BD18 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp0_lpmode}]
# set_property -dict {LOC AT22 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp0_refclk_reset}]
# set_property -dict {LOC AT20 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp0_fs[0]}]
# set_property -dict {LOC AU22 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp0_fs[1]}]

# 156.25 MHz MGT reference clock (from SI570)
create_clock -period 6.400 -name qsfp0_mgt_refclk_0 [get_ports {qsfp0_mgt_refclk_0_p}]

# 156.25 MHz MGT reference clock (from SI5335, FS = 0b01)
#create_clock -period 6.400 -name qsfp0_mgt_refclk_1 [get_ports {qsfp0_mgt_refclk_1_p}]

# 161.1328125 MHz MGT reference clock (from SI5335, FS = 0b10)
#create_clock -period 6.206 -name qsfp0_mgt_refclk_1 [get_ports {qsfp0_mgt_refclk_1_p}]

set_false_path -to [get_ports {qsfp0_modsell qsfp0_resetl qsfp0_lpmode}]
set_output_delay 0 [get_ports {qsfp0_modsell qsfp0_resetl qsfp0_lpmode}]
set_false_path -from [get_ports {qsfp0_modprsl qsfp0_intl}]
set_input_delay 0 [get_ports {qsfp0_modprsl qsfp0_intl}]
#set_false_path -to [get_ports {qsfp0_refclk_reset qsfp0_fs[*]}]
#set_output_delay 0 [get_ports {qsfp0_refclk_reset qsfp0_fs[*]}]

set_property -dict {LOC U4  } [get_ports {qsfp1_rx_p[0]}] ;# MGTYRXP0_230 GTYE4_CHANNEL_X1Y44 / GTYE4_COMMON_X1Y11
set_property -dict {LOC U3  } [get_ports {qsfp1_rx_n[0]}] ;# MGTYRXN0_230 GTYE4_CHANNEL_X1Y44 / GTYE4_COMMON_X1Y11
set_property -dict {LOC U9  } [get_ports {qsfp1_tx_p[0]}] ;# MGTYTXP0_230 GTYE4_CHANNEL_X1Y44 / GTYE4_COMMON_X1Y11
set_property -dict {LOC U8  } [get_ports {qsfp1_tx_n[0]}] ;# MGTYTXN0_230 GTYE4_CHANNEL_X1Y44 / GTYE4_COMMON_X1Y11
set_property -dict {LOC T2  } [get_ports {qsfp1_rx_p[1]}] ;# MGTYRXP1_230 GTYE4_CHANNEL_X1Y45 / GTYE4_COMMON_X1Y11
set_property -dict {LOC T1  } [get_ports {qsfp1_rx_n[1]}] ;# MGTYRXN1_230 GTYE4_CHANNEL_X1Y45 / GTYE4_COMMON_X1Y11
set_property -dict {LOC T7  } [get_ports {qsfp1_tx_p[1]}] ;# MGTYTXP1_230 GTYE4_CHANNEL_X1Y45 / GTYE4_COMMON_X1Y11
set_property -dict {LOC T6  } [get_ports {qsfp1_tx_n[1]}] ;# MGTYTXN1_230 GTYE4_CHANNEL_X1Y45 / GTYE4_COMMON_X1Y11
set_property -dict {LOC R4  } [get_ports {qsfp1_rx_p[2]}] ;# MGTYRXP2_230 GTYE4_CHANNEL_X1Y46 / GTYE4_COMMON_X1Y11
set_property -dict {LOC R3  } [get_ports {qsfp1_rx_n[2]}] ;# MGTYRXN2_230 GTYE4_CHANNEL_X1Y46 / GTYE4_COMMON_X1Y11
set_property -dict {LOC R9  } [get_ports {qsfp1_tx_p[2]}] ;# MGTYTXP2_230 GTYE4_CHANNEL_X1Y46 / GTYE4_COMMON_X1Y11
set_property -dict {LOC R8  } [get_ports {qsfp1_tx_n[2]}] ;# MGTYTXN2_230 GTYE4_CHANNEL_X1Y46 / GTYE4_COMMON_X1Y11
set_property -dict {LOC P2  } [get_ports {qsfp1_rx_p[3]}] ;# MGTYRXP3_230 GTYE4_CHANNEL_X1Y47 / GTYE4_COMMON_X1Y11
set_property -dict {LOC P1  } [get_ports {qsfp1_rx_n[3]}] ;# MGTYRXN3_230 GTYE4_CHANNEL_X1Y47 / GTYE4_COMMON_X1Y11
set_property -dict {LOC P7  } [get_ports {qsfp1_tx_p[3]}] ;# MGTYTXP3_230 GTYE4_CHANNEL_X1Y47 / GTYE4_COMMON_X1Y11
set_property -dict {LOC P6  } [get_ports {qsfp1_tx_n[3]}] ;# MGTYTXN3_230 GTYE4_CHANNEL_X1Y47 / GTYE4_COMMON_X1Y11
set_property -dict {LOC T11 } [get_ports {qsfp1_mgt_refclk_0_p}] ;# MGTREFCLK0P_230 from U14.4 via U43.15
set_property -dict {LOC T10 } [get_ports {qsfp1_mgt_refclk_0_n}] ;# MGTREFCLK0N_230 from U14.5 via U43.16
#set_property -dict {LOC P11 } [get_ports {qsfp1_mgt_refclk_1_p}] ;# MGTREFCLK1P_230 from U12.18
#set_property -dict {LOC P10 } [get_ports {qsfp1_mgt_refclk_1_n}] ;# MGTREFCLK1N_230 from U12.17
set_property -dict {LOC AY20 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp1_modsell}]
set_property -dict {LOC BC18 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp1_resetl}]
set_property -dict {LOC BC19 IOSTANDARD LVCMOS12 PULLUP true} [get_ports {qsfp1_modprsl}]
set_property -dict {LOC AV21 IOSTANDARD LVCMOS12 PULLUP true} [get_ports {qsfp1_intl}]
set_property -dict {LOC AV22 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp1_lpmode}]
# set_property -dict {LOC AR21 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp1_refclk_reset}]
# set_property -dict {LOC AR22 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp1_fs[0]}]
# set_property -dict {LOC AU20 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp1_fs[1]}]

# 156.25 MHz MGT reference clock (from SI570)
create_clock -period 6.400 -name qsfp1_mgt_refclk_0 [get_ports {qsfp1_mgt_refclk_0_p}]

# 156.25 MHz MGT reference clock (from SI5335, FS = 0b01)
#create_clock -period 6.400 -name qsfp1_mgt_refclk_1 [get_ports {qsfp1_mgt_refclk_1_p}]

# 161.1328125 MHz MGT reference clock (from SI5335, FS = 0b10)
#create_clock -period 6.206 -name qsfp1_mgt_refclk_1 [get_ports {qsfp1_mgt_refclk_1_p}]

set_false_path -to [get_ports {qsfp1_modsell qsfp1_resetl qsfp1_lpmode}]
set_output_delay 0 [get_ports {qsfp1_modsell qsfp1_resetl qsfp1_lpmode}]
set_false_path -from [get_ports {qsfp1_modprsl qsfp1_intl}]
set_input_delay 0 [get_ports {qsfp1_modprsl qsfp1_intl}]
#set_false_path -to [get_ports {qsfp1_refclk_reset qsfp1_fs[*]}]
#set_output_delay 0 [get_ports {qsfp1_refclk_reset qsfp1_fs[*]}]
