# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo AU200/AU250/VCU1525
# AU200 part: xcu200-fsgd2104-2-e
# AU250 part: xcu250-figd2104-2-e
# VCU1525 part: xcvu9p-fsgd2104-2L-e

# BMC
set_property -dict {LOC AR20 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 4} [get_ports {msp_gpio[0]}]
set_property -dict {LOC AM20 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 4} [get_ports {msp_gpio[1]}]
set_property -dict {LOC AM21 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 4} [get_ports {msp_gpio[2]}]
set_property -dict {LOC AN21 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 4} [get_ports {msp_gpio[3]}]
set_property -dict {LOC BB19 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 4} [get_ports {msp_uart_txd}]
set_property -dict {LOC BA19 IOSTANDARD LVCMOS12} [get_ports {msp_uart_rxd}]

set_false_path -to [get_ports {msp_uart_txd}]
set_output_delay 0 [get_ports {msp_uart_txd}]
set_false_path -from [get_ports {msp_gpio[*] msp_uart_rxd}]
set_input_delay 0 [get_ports {msp_gpio[*] msp_uart_rxd}]
