# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U45N/SN1022 board
# part: xcu26-vsva1365-2LV-e

# LEDs
set_property -dict {LOC AH24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {card_heart_bit}]
set_property -dict {LOC AL24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {card_status_led}]
set_property -dict {LOC AM23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_act[0]}]
set_property -dict {LOC AM22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_stat_g[0]}]
set_property -dict {LOC AN23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_stat_y[0]}]
set_property -dict {LOC AJ25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_act[1]}]
set_property -dict {LOC AH25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_stat_g[1]}]
set_property -dict {LOC AN24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_stat_y[1]}]

set_false_path -to [get_ports {qsfp_led_act[*] qsfp_led_stat_g[*] qsfp_led_stat_y[*]}]
set_output_delay 0 [get_ports {qsfp_led_act[*] qsfp_led_stat_g[*] qsfp_led_stat_y[*]}]

# UART (DMB-2 FT4232H channel CDBUS)
set_property -dict {LOC AP24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_txd] ;# DMB-2 U4.39 RXD CDBUS1
set_property -dict {LOC AR24 IOSTANDARD LVCMOS18} [get_ports uart_rxd] ;# DMB-2 U4.38 TXD CDBUS0

set_false_path -to [get_ports {uart_txd}]
set_output_delay 0 [get_ports {uart_txd}]
set_false_path -from [get_ports {uart_rxd}]
set_input_delay 0 [get_ports {uart_rxd}]

# SI5394 (SI5394J-A-GM)
# IN0: 20 MHz TCXO
# OUT1: 161.1328125 MHz to QSFP GTM and GTY
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
