# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U50 board
# part: xcu50-fsvh2104-2-e

# LEDs
set_property -dict {LOC E18 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp_led_act]
set_property -dict {LOC E16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp_led_stat_g]
set_property -dict {LOC F17 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports qsfp_led_stat_y]

set_false_path -to [get_ports {qsfp_led_act qsfp_led_stat_g qsfp_led_stat_y}]
set_output_delay 0 [get_ports {qsfp_led_act qsfp_led_stat_g qsfp_led_stat_y}]

# UART (DMB-1 FT4232H)
set_property -dict {LOC BE26 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_txd[0]}] ;# DMB-1 U9.39 CDBUS1 RXD
set_property -dict {LOC BF26 IOSTANDARD LVCMOS18} [get_ports {uart_rxd[0]}] ;# DMB-1 U9.38 CDBUS0 TXD
set_property -dict {LOC A17  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_txd[1]}] ;# DMB-1 U9.52 DDBUS1 RXD
set_property -dict {LOC B15  IOSTANDARD LVCMOS18} [get_ports {uart_rxd[1]}] ;# DMB-1 U9.48 DDBUS0 TXD
set_property -dict {LOC A19  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_txd[2]}] ;# DMB-1 U18.39 CDBUS1 RXD
set_property -dict {LOC A18  IOSTANDARD LVCMOS18} [get_ports {uart_rxd[2]}] ;# DMB-1 U18.38 CDBUS0 TXD

set_false_path -to [get_ports {uart_txd[*]}]
set_output_delay 0 [get_ports {uart_txd[*]}]
set_false_path -from [get_ports {uart_rxd[*]}]
set_input_delay 0 [get_ports {uart_rxd[*]}]

# HBM overtemp
set_property -dict {LOC J18 IOSTANDARD LVCMOS18} [get_ports hbm_cattrip]

set_false_path -to [get_ports {hbm_cattrip}]
set_output_delay 0 [get_ports {hbm_cattrip}]

# SI5394 (SI5394B-A10605-GM)
# I2C address 0x68
# IN0: 161.1328125 MHz from qsfp_recclk
# OUT0: 161.1328125 MHz to qsfp_mgt_refclk_0
# OUT2: 322.265625 MHz to qsfp_mgt_refclk_1
# OUT3: 100 MHz to clk_100mhz_0, clk_100mhz_1, pcie_refclk_2, pcie_refclk_3
#set_property -dict {LOC F20 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {si5394_rst_b}]
#set_property -dict {LOC H18 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {si5394_int_b}]
#set_property -dict {LOC G19 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {si5394_lol_b}]
#set_property -dict {LOC H19 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {si5394_los_b}]
#set_property -dict {LOC J16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports {si5394_sda}]
#set_property -dict {LOC L19 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports {si5394_scl}]

#set_false_path -to [get_ports {si5394_rst_b}]
#set_output_delay 0 [get_ports {si5394_rst_b}]
#set_false_path -from [get_ports {si5394_int_b si5394_lol_b si5394_los_b}]
#set_input_delay 0 [get_ports {si5394_int_b si5394_lol_b si5394_los_b}]

#set_false_path -to [get_ports {si5394_i2c_sda si5394_i2c_scl}]
#set_output_delay 0 [get_ports {si5394_i2c_sda si5394_i2c_scl}]
#set_false_path -from [get_ports {si5394_i2c_sda si5394_i2c_scl}]
#set_input_delay 0 [get_ports {si5394_i2c_sda si5394_i2c_scl}]
