# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx AC701 board
# part: xc7a200tfbg676-2

# LEDs
set_property -dict {LOC M26  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {led[0]}] ;# to DS2
set_property -dict {LOC T24  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {led[1]}] ;# to DS3
set_property -dict {LOC T25  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {led[2]}] ;# to DS4
set_property -dict {LOC R26  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {led[3]}] ;# to DS5

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Reset button
set_property -dict {LOC U4   IOSTANDARD LVCMOS15} [get_ports reset] ;# from SW7

set_false_path -from [get_ports {reset}]
set_input_delay 0 [get_ports {reset}]

# Push buttons
set_property -dict {LOC P6   IOSTANDARD LVCMOS15} [get_ports btnu] ;# from SW3
set_property -dict {LOC R5   IOSTANDARD LVCMOS15} [get_ports btnl] ;# from SW7
set_property -dict {LOC T5   IOSTANDARD LVCMOS15} [get_ports btnd] ;# from SW5
set_property -dict {LOC U5   IOSTANDARD LVCMOS15} [get_ports btnr] ;# from SW4
set_property -dict {LOC U6   IOSTANDARD LVCMOS15} [get_ports btnc] ;# from SW6

set_false_path -from [get_ports {btnu btnl btnd btnr btnc}]
set_input_delay 0 [get_ports {btnu btnl btnd btnr btnc}]

# DIP switches
set_property -dict {LOC R8   IOSTANDARD LVCMOS15} [get_ports {sw[0]}] ;# from SW2.1
set_property -dict {LOC P8   IOSTANDARD LVCMOS15} [get_ports {sw[1]}] ;# from SW2.2
set_property -dict {LOC R7   IOSTANDARD LVCMOS15} [get_ports {sw[2]}] ;# from SW2.3
set_property -dict {LOC R6   IOSTANDARD LVCMOS15} [get_ports {sw[3]}] ;# from SW2.4

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# PMOD
#set_property -dict {LOC P26  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod[0]}] ;# J48.1
#set_property -dict {LOC T22  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod[1]}] ;# J48.2
#set_property -dict {LOC R22  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod[2]}] ;# J48.3
#set_property -dict {LOC T23  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {pmod[3]}] ;# J48.4

#set_false_path -to [get_ports {pmod[*]}]
#set_output_delay 0 [get_ports {pmod[*]}]

# UART (U12 CP2103)
set_property -dict {LOC U19  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_txd}] ;# U44.24 RXD_I
set_property -dict {LOC T19  IOSTANDARD LVCMOS18} [get_ports {uart_rxd}] ;# U44.25 TXD_O
set_property -dict {LOC V19  IOSTANDARD LVCMOS18} [get_ports {uart_rts}] ;# U44.23 RTS_O_B
set_property -dict {LOC W19  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_cts}] ;# U44.22 CTS_I_B

set_false_path -to [get_ports {uart_txd uart_cts}]
set_output_delay 0 [get_ports {uart_txd uart_cts}]
set_false_path -from [get_ports {uart_rxd uart_rts}]
set_input_delay 0 [get_ports {uart_rxd uart_rts}]
