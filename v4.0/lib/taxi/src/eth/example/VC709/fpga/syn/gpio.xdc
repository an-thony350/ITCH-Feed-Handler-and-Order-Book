# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VC709
# part: xc7vx690tffg1761-2

# LEDs
set_property -dict {LOC AM39 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[0]}] ;# DS2
set_property -dict {LOC AN39 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[1]}] ;# DS3
set_property -dict {LOC AR37 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[2]}] ;# DS4
set_property -dict {LOC AT37 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[3]}] ;# DS5
set_property -dict {LOC AR35 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[4]}] ;# DS6
set_property -dict {LOC AP41 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[5]}] ;# DS7
set_property -dict {LOC AP42 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[6]}] ;# DS8
set_property -dict {LOC AU39 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[7]}] ;# DS9

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Reset button
set_property -dict {LOC AV40 IOSTANDARD LVCMOS18} [get_ports reset] ;# from SW8

set_false_path -from [get_ports {reset}]
set_input_delay 0 [get_ports {reset}]

# Push buttons
set_property -dict {LOC AR40 IOSTANDARD LVCMOS18} [get_ports btnu] ;# from SW3
set_property -dict {LOC AW40 IOSTANDARD LVCMOS18} [get_ports btnl] ;# from SW7
set_property -dict {LOC AP40 IOSTANDARD LVCMOS18} [get_ports btnd] ;# from SW5
set_property -dict {LOC AU38 IOSTANDARD LVCMOS18} [get_ports btnr] ;# from SW4
set_property -dict {LOC AV39 IOSTANDARD LVCMOS18} [get_ports btnc] ;# from SW6

set_false_path -from [get_ports {btnu btnl btnd btnr btnc}]
set_input_delay 0 [get_ports {btnu btnl btnd btnr btnc}]

# DIP switches
set_property -dict {LOC AV30 IOSTANDARD LVCMOS18} [get_ports {sw[0]}] ;# from SW2.1
set_property -dict {LOC AY33 IOSTANDARD LVCMOS18} [get_ports {sw[1]}] ;# from SW2.2
set_property -dict {LOC BA31 IOSTANDARD LVCMOS18} [get_ports {sw[2]}] ;# from SW2.3
set_property -dict {LOC BA32 IOSTANDARD LVCMOS18} [get_ports {sw[3]}] ;# from SW2.4
set_property -dict {LOC AW30 IOSTANDARD LVCMOS18} [get_ports {sw[4]}] ;# from SW2.5
set_property -dict {LOC AY30 IOSTANDARD LVCMOS18} [get_ports {sw[5]}] ;# from SW2.6
set_property -dict {LOC BA30 IOSTANDARD LVCMOS18} [get_ports {sw[6]}] ;# from SW2.7
set_property -dict {LOC BB31 IOSTANDARD LVCMOS18} [get_ports {sw[7]}] ;# from SW2.8

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# UART (U44 CP2103)
set_property -dict {LOC AU36 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_txd}] ;# U44.24 RXD_I
set_property -dict {LOC AU33 IOSTANDARD LVCMOS18} [get_ports {uart_rxd}] ;# U44.25 TXD_O
set_property -dict {LOC AT32 IOSTANDARD LVCMOS18} [get_ports {uart_rts}] ;# U44.23 RTS_O_B
set_property -dict {LOC AR34 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_cts}] ;# U44.22 CTS_I_B

set_false_path -to [get_ports {uart_txd uart_cts}]
set_output_delay 0 [get_ports {uart_txd uart_cts}]
set_false_path -from [get_ports {uart_rxd uart_rts}]
set_input_delay 0 [get_ports {uart_rxd uart_rts}]
