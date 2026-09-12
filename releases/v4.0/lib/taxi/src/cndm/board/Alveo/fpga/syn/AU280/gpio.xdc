# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U280 board
# part: xcu280-fsvh2892-2L-e

# Reset button
set_property -dict {LOC L30 IOSTANDARD LVCMOS18} [get_ports reset]

set_false_path -from [get_ports {reset}]
set_input_delay 0 [get_ports {reset}]

# UART (U34 FT4232H channel CDBUS)
set_property -dict {LOC B33 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_txd}] ;# U34.39 CDBUS1 RXD
set_property -dict {LOC A28 IOSTANDARD LVCMOS18} [get_ports {uart_rxd}] ;# U34.38 CDBUS0 TXD

set_false_path -to [get_ports {uart_txd}]
set_output_delay 0 [get_ports {uart_txd}]
set_false_path -from [get_ports {uart_rxd}]
set_input_delay 0 [get_ports {uart_rxd}]

# HBM overtemp
set_property -dict {LOC D32 IOSTANDARD LVCMOS18} [get_ports hbm_cattrip]

set_false_path -to [get_ports {hbm_cattrip}]
set_output_delay 0 [get_ports {hbm_cattrip}]
