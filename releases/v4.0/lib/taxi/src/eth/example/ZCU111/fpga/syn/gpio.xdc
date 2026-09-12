# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU111 board
# part: xczu28dr-ffvg1517-2-e

# LEDs
set_property -dict {LOC AR13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[0]}] ;# DS11
set_property -dict {LOC AP13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[1]}] ;# DS12
set_property -dict {LOC AR16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[2]}] ;# DS13
set_property -dict {LOC AP16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[3]}] ;# DS14
set_property -dict {LOC AP15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[4]}] ;# DS15
set_property -dict {LOC AN16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[5]}] ;# DS16
set_property -dict {LOC AN17 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[6]}] ;# DS17
set_property -dict {LOC AV15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[7]}] ;# DS18

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Reset button
set_property -dict {LOC AF15 IOSTANDARD LVCMOS18} [get_ports reset] ;# SW20

set_false_path -from [get_ports {reset}]
set_input_delay 0 [get_ports {reset}]

# Push buttons
set_property -dict {LOC AW3  IOSTANDARD LVCMOS18} [get_ports btnu] ;# SW9
set_property -dict {LOC AW4  IOSTANDARD LVCMOS18} [get_ports btnl] ;# SW12
set_property -dict {LOC E8   IOSTANDARD LVCMOS18} [get_ports btnd] ;# SW13
set_property -dict {LOC AW6  IOSTANDARD LVCMOS18} [get_ports btnr] ;# SW10
set_property -dict {LOC AW5  IOSTANDARD LVCMOS18} [get_ports btnc] ;# SW11

set_false_path -from [get_ports {btnu btnl btnd btnr btnc}]
set_input_delay 0 [get_ports {btnu btnl btnd btnr btnc}]

# DIP switches
set_property -dict {LOC AF16 IOSTANDARD LVCMOS18} [get_ports {sw[0]}] ;# SW14.8
set_property -dict {LOC AF17 IOSTANDARD LVCMOS18} [get_ports {sw[1]}] ;# SW14.7
set_property -dict {LOC AH15 IOSTANDARD LVCMOS18} [get_ports {sw[2]}] ;# SW14.6
set_property -dict {LOC AH16 IOSTANDARD LVCMOS18} [get_ports {sw[3]}] ;# SW14.5
set_property -dict {LOC AH17 IOSTANDARD LVCMOS18} [get_ports {sw[4]}] ;# SW14.4
set_property -dict {LOC AG17 IOSTANDARD LVCMOS18} [get_ports {sw[5]}] ;# SW14.3
set_property -dict {LOC AJ15 IOSTANDARD LVCMOS18} [get_ports {sw[6]}] ;# SW14.2
set_property -dict {LOC AJ16 IOSTANDARD LVCMOS18} [get_ports {sw[7]}] ;# SW14.1

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# USB UART (U34 FT4232H CDBUS)
set_property -dict {LOC AU15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_txd] ;# U34.39 CDBUS1 RXD
set_property -dict {LOC AT15 IOSTANDARD LVCMOS18} [get_ports uart_rxd] ;# U34.38 CDBUS0 TXD
set_property -dict {LOC AU14 IOSTANDARD LVCMOS18} [get_ports uart_rts] ;# U34.40 CDBUS2 RTS#
set_property -dict {LOC AT14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_cts] ;# U34.41 CDBUS3 CTS#

set_false_path -to [get_ports {uart_txd uart_cts}]
set_output_delay 0 [get_ports {uart_txd uart_cts}]
set_false_path -from [get_ports {uart_rxd uart_rts}]
set_input_delay 0 [get_ports {uart_rxd uart_rts}]
