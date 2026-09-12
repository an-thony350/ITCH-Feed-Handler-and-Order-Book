# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VC709
# part: xc7vx690tffg1761-2

# LEDs
set_property -dict {LOC G13  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_led[0][0]}]
set_property -dict {LOC L15  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_led[0][1]}]
set_property -dict {LOC AL22 IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_led[1][0]}]
set_property -dict {LOC BA20 IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_led[1][1]}]
set_property -dict {LOC AY18 IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_led[2][0]}]
set_property -dict {LOC AY17 IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_led[2][1]}]
set_property -dict {LOC P31  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_led[3][0]}]
set_property -dict {LOC K32  IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {sfp_led[3][1]}]
set_property -dict {LOC AR22 IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {led[0]}]
set_property -dict {LOC AR23 IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports {led[1]}]

set_false_path -to [get_ports {sfp_led[*][*] led[*]}]
set_output_delay 0 [get_ports {sfp_led[*][*] led[*]}]

# Push buttons
set_property -dict {LOC AR13 IOSTANDARD LVCMOS15} [get_ports {btn[0]}]
set_property -dict {LOC BB12 IOSTANDARD LVCMOS15} [get_ports {btn[1]}]

set_false_path -from [get_ports {btn[*]}]
set_input_delay 0 [get_ports {btn[*]}]

# UART (IC47 FT2232HQ)
set_property -dict {LOC BA19 IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 8} [get_ports {uart_txd}] ;# IC47.38 RXD_I
set_property -dict {LOC AY19 IOSTANDARD LVCMOS15} [get_ports {uart_rxd}] ;# IC47.39 TXD_O
set_property -dict {LOC BB16 IOSTANDARD LVCMOS15} [get_ports {uart_rts}] ;# IC47.40 RTS_O_B
set_property -dict {LOC BA16 IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 8} [get_ports {uart_cts}] ;# IC47.41 CTS_I_B

set_false_path -to [get_ports {uart_txd uart_cts}]
set_output_delay 0 [get_ports {uart_txd uart_cts}]
set_false_path -from [get_ports {uart_rxd uart_rts}]
set_input_delay 0 [get_ports {uart_rxd uart_rts}]
