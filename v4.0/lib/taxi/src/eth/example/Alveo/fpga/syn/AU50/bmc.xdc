# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U50 board
# part: xcu50-fsvh2104-2-e

# BMC
set_property -dict {LOC C16  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {msp_gpio[0]}]
set_property -dict {LOC C17  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {msp_gpio[1]}]
set_property -dict {LOC BB25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {msp_uart_txd}]
set_property -dict {LOC BB26 IOSTANDARD LVCMOS18} [get_ports {msp_uart_rxd}]

set_false_path -to [get_ports {msp_uart_txd}]
set_output_delay 0 [get_ports {msp_uart_txd}]
set_false_path -from [get_ports {msp_gpio[*] msp_uart_rxd}]
set_input_delay 0 [get_ports {msp_gpio[*] msp_uart_rxd}]
