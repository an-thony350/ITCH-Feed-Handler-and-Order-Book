# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the BittWare XUP-P3R board
# part: xcvu9p-flgb2104-2-e

# LEDs
set_property -dict {LOC AR22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[0]}]
set_property -dict {LOC AT22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[1]}]
set_property -dict {LOC AR23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[2]}]
set_property -dict {LOC AV22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[3]}]

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Timing
#set_property -dict {LOC AU22 IOSTANDARD LVCMOS18} [get_ports ext_pps_in] ;# from J1
#set_property -dict {LOC AV24 IOSTANDARD LVCMOS18} [get_ports ext_clk_in] ;# from J2

#create_clock -period 100.000 -name ext_clk_in [get_ports ext_clk_in]

#set_false_path -from [get_ports {ext_pps_in ext_clk_in}]
#set_input_delay 0 [get_ports {ext_pps_in ext_clk_in}]

# Reset
set_property -dict {LOC AT23 IOSTANDARD LVCMOS18} [get_ports sys_rst_l]

set_false_path -from [get_ports {sys_rst_l}]
set_input_delay 0 [get_ports {sys_rst_l}]

# UART
set_property -dict {LOC AM24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_txd]
set_property -dict {LOC AL24 IOSTANDARD LVCMOS18} [get_ports uart_rxd]

set_false_path -to [get_ports {uart_txd}]
set_output_delay 0 [get_ports {uart_txd}]
set_false_path -from [get_ports {uart_rxd}]
set_input_delay 0 [get_ports {uart_rxd}]
