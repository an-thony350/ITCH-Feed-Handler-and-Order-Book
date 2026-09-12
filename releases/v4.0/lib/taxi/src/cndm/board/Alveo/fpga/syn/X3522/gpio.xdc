# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U45N/SN1022 board
# part: xcux35-vsva1365-3-e

# LEDs
set_property -dict {LOC AM23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_r[0]}]
set_property -dict {LOC AN23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_g[0]}]
set_property -dict {LOC AM22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_b[0]}]
set_property -dict {LOC AN22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_r[1]}]
set_property -dict {LOC AN25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_g[1]}]
set_property -dict {LOC AP25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_b[1]}]
set_property -dict {LOC AH24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_r[2]}]
set_property -dict {LOC AK24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_g[2]}]
set_property -dict {LOC AL24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_b[2]}]
set_property -dict {LOC AJ25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_r[3]}]
set_property -dict {LOC AN24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_g[3]}]
set_property -dict {LOC AH25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {dsfp_led_b[3]}]

set_false_path -to [get_ports {dsfp_led_r[*] dsfp_led_g[*] dsfp_led_b[*]}]
set_output_delay 0 [get_ports {dsfp_led_r[*] dsfp_led_g[*] dsfp_led_b[*]}]

# PPS in/out
#set_property -dict {LOC AM25 IOSTANDARD LVCMOS18} [get_ports {pps_in}]
#set_property -dict {LOC AL25 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 8} [get_ports {pps_out}]

#set_false_path -from [get_ports {pps_in}]
#set_input_delay 0 [get_ports {pps_in}]
#set_false_path -to [get_ports {pps_out}]
#set_output_delay 0 [get_ports {pps_out}]

# UART (DMB-2 FT4232H channel CDBUS)
set_property -dict {LOC AP24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_txd] ;# DMB-2 U4.39 RXD CDBUS1
set_property -dict {LOC AR24 IOSTANDARD LVCMOS18} [get_ports uart_rxd] ;# DMB-2 U4.38 TXD CDBUS0

set_false_path -to [get_ports {uart_txd}]
set_output_delay 0 [get_ports {uart_txd}]
set_false_path -from [get_ports {uart_rxd}]
set_input_delay 0 [get_ports {uart_rxd}]

# SI5394 (SI5394J-A-GM)
# IN0: 20 MHz TCXO
# OUT1: 161.1328125 MHz to DSFP GTY
# OUT2: 100 MHz to ...
# OUT3: 300 MHz to ...
#set_property -dict {LOC AN20 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {si5394_rst_b}]
#set_property -dict {LOC AH19 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {si5394_int_b}]
#set_property -dict {LOC AJ19 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {si5394_lol_b}]
#set_property -dict {LOC AJ20 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {si5394_los_b}]

#set_false_path -to [get_ports {si5394_rst_b}]
#set_output_delay 0 [get_ports {si5394_rst_b}]
#set_false_path -from [get_ports {si5394_int_b si5394_lol_b si5394_los_b}]
#set_input_delay 0 [get_ports {si5394_int_b si5394_lol_b si5394_los_b}]
