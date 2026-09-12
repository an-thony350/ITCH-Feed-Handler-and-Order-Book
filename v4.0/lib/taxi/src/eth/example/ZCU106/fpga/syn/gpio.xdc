# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU106 board
# part: xczu7ev-ffvc1156-2-e

# LEDs
set_property -dict {LOC AL11 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led[0]}]
set_property -dict {LOC AL13 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led[1]}]
set_property -dict {LOC AK13 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led[2]}]
set_property -dict {LOC AE15 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led[3]}]
set_property -dict {LOC AM8  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led[4]}]
set_property -dict {LOC AM9  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led[5]}]
set_property -dict {LOC AM10 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led[6]}]
set_property -dict {LOC AM11 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led[7]}]

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Reset button
set_property -dict {LOC G13  IOSTANDARD LVCMOS12} [get_ports reset]

set_false_path -from [get_ports {reset}]
set_input_delay 0 [get_ports {reset}]

# Push buttons
set_property -dict {LOC AG13 IOSTANDARD LVCMOS12} [get_ports btnu]
set_property -dict {LOC AK12 IOSTANDARD LVCMOS12} [get_ports btnl]
set_property -dict {LOC AP20 IOSTANDARD LVCMOS12} [get_ports btnd]
set_property -dict {LOC AC14 IOSTANDARD LVCMOS12} [get_ports btnr]
set_property -dict {LOC AL10 IOSTANDARD LVCMOS12} [get_ports btnc]

set_false_path -from [get_ports {btnu btnl btnd btnr btnc}]
set_input_delay 0 [get_ports {btnu btnl btnd btnr btnc}]

# DIP switches
set_property -dict {LOC A17  IOSTANDARD LVCMOS18} [get_ports {sw[0]}]
set_property -dict {LOC A16  IOSTANDARD LVCMOS18} [get_ports {sw[1]}]
set_property -dict {LOC B16  IOSTANDARD LVCMOS18} [get_ports {sw[2]}]
set_property -dict {LOC B15  IOSTANDARD LVCMOS18} [get_ports {sw[3]}]
set_property -dict {LOC A15  IOSTANDARD LVCMOS18} [get_ports {sw[4]}]
set_property -dict {LOC A14  IOSTANDARD LVCMOS18} [get_ports {sw[5]}]
set_property -dict {LOC B14  IOSTANDARD LVCMOS18} [get_ports {sw[6]}]
set_property -dict {LOC B13  IOSTANDARD LVCMOS18} [get_ports {sw[7]}]

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# PMOD0
#set_property -dict {LOC B23  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[0]}] ;# J55.1
#set_property -dict {LOC A23  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[1]}] ;# J55.3
#set_property -dict {LOC F25  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[2]}] ;# J55.5
#set_property -dict {LOC E20  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[3]}] ;# J55.7
#set_property -dict {LOC K24  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[4]}] ;# J55.2
#set_property -dict {LOC L23  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[5]}] ;# J55.4
#set_property -dict {LOC L22  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[6]}] ;# J55.6
#set_property -dict {LOC D7   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[7]}] ;# J55.8

#set_false_path -to [get_ports {pmod0[*]}]
#set_output_delay 0 [get_ports {pmod0[*]}]

# PMOD1
#set_property -dict {LOC AN8  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[0]}] ;# J87.1
#set_property -dict {LOC AN9  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[1]}] ;# J87.3
#set_property -dict {LOC AP11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[2]}] ;# J87.5
#set_property -dict {LOC AN11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[3]}] ;# J87.7
#set_property -dict {LOC AP9  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[4]}] ;# J87.2
#set_property -dict {LOC AP10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[5]}] ;# J87.4
#set_property -dict {LOC AP12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[6]}] ;# J87.6
#set_property -dict {LOC AN12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[7]}] ;# J87.8

#set_false_path -to [get_ports {pmod1[*]}]
#set_output_delay 0 [get_ports {pmod1[*]}]

# "Prototype header" GPIO
#set_property -dict {LOC K13  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[0]}] ;# J3.6
#set_property -dict {LOC L14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[1]}] ;# J3.8
#set_property -dict {LOC J14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[2]}] ;# J3.10
#set_property -dict {LOC K14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[3]}] ;# J3.12
#set_property -dict {LOC J11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[4]}] ;# J3.14
#set_property -dict {LOC K12  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[5]}] ;# J3.16
#set_property -dict {LOC L11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[6]}] ;# J3.18
#set_property -dict {LOC L12  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[7]}] ;# J3.20
#set_property -dict {LOC G24  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[8]}] ;# J3.22
#set_property -dict {LOC G23  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {proto_gpio[9]}] ;# J3.24

#set_false_path -to [get_ports {proto_gpio[*]}]
#set_output_delay 0 [get_ports {proto_gpio[*]}]

# UART (U40 CP2108 ch 2)
set_property -dict {LOC AL17 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports uart_txd] ;# U40.15 RX_2
set_property -dict {LOC AH17 IOSTANDARD LVCMOS12} [get_ports uart_rxd] ;# U40.16 TX_2
set_property -dict {LOC AM15 IOSTANDARD LVCMOS12} [get_ports uart_rts] ;# U40.14 RTS_2
set_property -dict {LOC AP17 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports uart_cts] ;# U40.13 CTS_2

set_false_path -to [get_ports {uart_txd uart_cts}]
set_output_delay 0 [get_ports {uart_txd uart_cts}]
set_false_path -from [get_ports {uart_rxd uart_rts}]
set_input_delay 0 [get_ports {uart_rxd uart_rts}]
