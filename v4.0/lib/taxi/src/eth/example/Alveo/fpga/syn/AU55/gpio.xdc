# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U55C/Alveo U55N/Varium C1100 board
# U55C       part: xcu55c-fsvh2892-2L-e
# U55N/C1100 part: xcu55n-fsvh2892-2L-e

# Reset button
set_property -dict {LOC BG45 IOSTANDARD LVCMOS18} [get_ports reset]

set_false_path -from [get_ports {reset}]
set_input_delay 0 [get_ports {reset}]

# LEDs
set_property -dict {LOC BL13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_act[0]}]
set_property -dict {LOC BK11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_stat_g[0]}]
set_property -dict {LOC BJ11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_stat_y[0]}]
set_property -dict {LOC BK14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_act[1]}]
set_property -dict {LOC BK15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_stat_g[1]}]
set_property -dict {LOC BL12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {qsfp_led_stat_y[1]}]

set_false_path -to [get_ports {qsfp_led_act[*] qsfp_led_stat_g[*] qsfp_led_stat_y[*]}]
set_output_delay 0 [get_ports {qsfp_led_act[*] qsfp_led_stat_g[*] qsfp_led_stat_y[*]}]

# GPIO
#set_property -dict {LOC BN42 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {testclk_out}]
#set_property -dict {LOC BJ33 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pps_in}]
#set_property -dict {LOC BH32 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pps_out}]

# UART (U35 FT4232H/DMB-1 FT4232H)
set_property -dict {LOC BJ41 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_txd[0]}] ;# U35.39 CDBUS1 RXD / DMB-1 U9.39 CDBUS1 RXD
set_property -dict {LOC BK41 IOSTANDARD LVCMOS18} [get_ports {uart_rxd[0]}] ;# U35.38 CDBUS0 TXD / DMB-1 U9.38 CDBUS0 TXD
set_property -dict {LOC BN47 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_txd[1]}] ;# U35.52 DDBUS1 RXD / DMB-1 U9.52 DDBUS1 RXD
set_property -dict {LOC BP47 IOSTANDARD LVCMOS18} [get_ports {uart_rxd[1]}] ;# U35.48 DDBUS0 TXD / DMB-1 U9.48 DDBUS0 TXD
set_property -dict {LOC BL45 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_txd[2]}] ;# DMB-1 U18.39 CDBUS1 RXD
set_property -dict {LOC BL46 IOSTANDARD LVCMOS18} [get_ports {uart_rxd[2]}] ;# DMB-1 U18.38 CDBUS0 TXD

set_false_path -to [get_ports {uart_txd[*]}]
set_output_delay 0 [get_ports {uart_txd[*]}]
set_false_path -from [get_ports {uart_rxd[*]}]
set_input_delay 0 [get_ports {uart_rxd[*]}]

# HBM overtemp
set_property -dict {LOC BE45 IOSTANDARD LVCMOS18} [get_ports hbm_cattrip]

set_false_path -to [get_ports {hbm_cattrip}]
set_output_delay 0 [get_ports {hbm_cattrip}]

# SI5394 (SI5394B-A10605-GM)
# I2C address 0x68
# IN0: 161.1328125 MHz from qsfp_recclk
# OUT0: 161.1328125 MHz to qsfp0_mgt_refclk
# OUT1: 161.1328125 MHz to qsfp1_mgt_refclk
# OUT3: 100 MHz to clk_100mhz_0, clk_100mhz_1, pcie_refclk_2, pcie_refclk_3
#set_property -dict {LOC BM8  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {si5394_rst_b}]
#set_property -dict {LOC BM9  IOSTANDARD LVCMOS18 PULLUP true} [get_ports {si5394_int_b}]
#set_property -dict {LOC BN10 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {si5394_lol_b}]
#set_property -dict {LOC BM10 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {si5394_los_b}]
#set_property -dict {LOC BN14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports {si5394_sda}]
#set_property -dict {LOC BM14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8 PULLUP true} [get_ports {si5394_scl}]

#set_false_path -to [get_ports {si5394_rst_b}]
#set_output_delay 0 [get_ports {si5394_rst_b}]
#set_false_path -from [get_ports {si5394_int_b si5394_lol_b si5394_los_b}]
#set_input_delay 0 [get_ports {si5394_int_b si5394_lol_b si5394_los_b}]

#set_false_path -to [get_ports {si5394_i2c_sda si5394_i2c_scl}]
#set_output_delay 0 [get_ports {si5394_i2c_sda si5394_i2c_scl}]
#set_false_path -from [get_ports {si5394_i2c_sda si5394_i2c_scl}]
#set_input_delay 0 [get_ports {si5394_i2c_sda si5394_i2c_scl}]
