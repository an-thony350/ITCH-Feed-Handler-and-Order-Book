# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U45N/SN1022 board
# part: xcu26-vsva1365-2LV-e

# BMC
set_property -dict {LOC AM17 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {suc_gpio[0]}]
set_property -dict {LOC AL18 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {suc_gpio[1]}]
set_property -dict {LOC AK21 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {suc_uart_txd}]
set_property -dict {LOC AJ21 IOSTANDARD LVCMOS18} [get_ports {suc_uart_rxd}]

set_false_path -to [get_ports {suc_uart_txd}]
set_output_delay 0 [get_ports {suc_uart_txd}]
set_false_path -from [get_ports {suc_gpio[*] suc_uart_rxd}]
set_input_delay 0 [get_ports {suc_gpio[*] suc_uart_rxd}]
