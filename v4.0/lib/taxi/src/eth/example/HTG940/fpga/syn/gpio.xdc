# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the HiTech Global HTG-9200 board
# part: xcvu9p-flgb2104-2-e
# part: xcvu13p-fhgb2104-2-e

# LEDs
set_property -dict {LOC AP28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[0]}]
set_property -dict {LOC AN28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[1]}]
set_property -dict {LOC AP26 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[2]}]
set_property -dict {LOC AP25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[3]}]
set_property -dict {LOC AR28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[4]}]
set_property -dict {LOC AR27 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[5]}]
set_property -dict {LOC AT28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[6]}]
set_property -dict {LOC AR25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[7]}]

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# Push buttons
set_property -dict {LOC AJ34 IOSTANDARD LVCMOS12} [get_ports {btn[0]}]
set_property -dict {LOC AK32 IOSTANDARD LVCMOS12} [get_ports {btn[1]}]

set_false_path -from [get_ports {btn[*]}]
set_input_delay 0 [get_ports {btn[*]}]

# DIP switches
set_property -dict {LOC BF33 IOSTANDARD LVCMOS12} [get_ports {sw[0]}]
set_property -dict {LOC AK27 IOSTANDARD LVCMOS12} [get_ports {sw[1]}]
set_property -dict {LOC AR32 IOSTANDARD LVCMOS12} [get_ports {sw[2]}]
set_property -dict {LOC AR31 IOSTANDARD LVCMOS12} [get_ports {sw[3]}]
set_property -dict {LOC AT32 IOSTANDARD LVCMOS12} [get_ports {sw[4]}]
set_property -dict {LOC AW30 IOSTANDARD LVCMOS12} [get_ports {sw[5]}]
set_property -dict {LOC BC32 IOSTANDARD LVCMOS12} [get_ports {sw[6]}]
set_property -dict {LOC BC33 IOSTANDARD LVCMOS12} [get_ports {sw[7]}]

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# UART (U53 CP2103)
set_property -dict {LOC R15  IOSTANDARD LVCMOS18} [get_ports {uart_txd}] ;# U53.25 TXD_O
set_property -dict {LOC P15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_rxd}] ;# U53.24 RXD_I
set_property -dict {LOC L15  IOSTANDARD LVCMOS18} [get_ports {uart_rts}] ;# U53.23 RTS_O_B
set_property -dict {LOC D14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_cts}] ;# U53.22 CTS_I_B
set_property -dict {LOC P16  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {uart_rst_n}] ;# U53.9 RST_B

set_false_path -to [get_ports {uart_rxd uart_cts uart_rst_n}]
set_output_delay 0 [get_ports {uart_rxd uart_cts uart_rst_n}]
set_false_path -from [get_ports {uart_txd uart_rts}]
set_input_delay 0 [get_ports {uart_txd uart_rts}]
