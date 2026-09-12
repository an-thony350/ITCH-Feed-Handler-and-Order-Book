# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U280 board
# part: xcu280-fsvh2892-2L-e

# BMC
set_property -dict {LOC K28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {msp_gpio[0]}]
set_property -dict {LOC J29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {msp_gpio[1]}]
set_property -dict {LOC K29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {msp_gpio[2]}]
set_property -dict {LOC J31 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {msp_gpio[3]}]
set_property -dict {LOC D29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {msp_uart_txd}]
set_property -dict {LOC E28 IOSTANDARD LVCMOS18} [get_ports {msp_uart_rxd}]

set_false_path -to [get_ports {msp_uart_txd}]
set_output_delay 0 [get_ports {msp_uart_txd}]
set_false_path -from [get_ports {msp_gpio[*] msp_uart_rxd}]
set_input_delay 0 [get_ports {msp_gpio[*] msp_uart_rxd}]
