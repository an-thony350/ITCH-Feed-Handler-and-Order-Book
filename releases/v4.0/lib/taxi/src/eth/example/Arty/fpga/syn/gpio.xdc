# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Digilent Arty board
# part: xc7a35t-csg324-1

# LEDs
set_property -dict {LOC G6   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led0_r]
set_property -dict {LOC F6   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led0_g]
set_property -dict {LOC E1   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led0_b]
set_property -dict {LOC G3   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led1_r]
set_property -dict {LOC J4   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led1_g]
set_property -dict {LOC G4   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led1_b]
set_property -dict {LOC J3   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led2_r]
set_property -dict {LOC J2   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led2_g]
set_property -dict {LOC H4   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led2_b]
set_property -dict {LOC K1   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led3_r]
set_property -dict {LOC H6   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led3_g]
set_property -dict {LOC K2   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led3_b]
set_property -dict {LOC H5   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led4]
set_property -dict {LOC J5   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led5]
set_property -dict {LOC T9   IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led6]
set_property -dict {LOC T10  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports led7]

set_false_path -to [get_ports {led0_r led0_g led0_b led1_r led1_g led1_b led2_r led2_g led2_b led3_r led3_g led3_b led4 led5 led6 led7}]
set_output_delay 0 [get_ports {led0_r led0_g led0_b led1_r led1_g led1_b led2_r led2_g led2_b led3_r led3_g led3_b led4 led5 led6 led7}]

# Reset button
# Note: IC8.43 BDBUS4 DTR drives FPGA pin C2 (reset_n) via JP2
set_property -dict {LOC C2   IOSTANDARD LVCMOS33} [get_ports reset_n]

set_false_path -from [get_ports {reset_n}]
set_input_delay 0 [get_ports {reset_n}]

# Push buttons
set_property -dict {LOC D9   IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {LOC C9   IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {LOC B9   IOSTANDARD LVCMOS33} [get_ports {btn[2]}]
set_property -dict {LOC B8   IOSTANDARD LVCMOS33} [get_ports {btn[3]}]

set_false_path -from [get_ports {btn[*]}]
set_input_delay 0 [get_ports {btn[*]}]

# Toggle switches
set_property -dict {LOC A8   IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {LOC C11  IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property -dict {LOC C10  IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
set_property -dict {LOC A10  IOSTANDARD LVCMOS33} [get_ports {sw[3]}]

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# UART (IC8 FT2232H BDBUS)
# Note: IC8.43 BDBUS4 DTR drives FPGA pin C2 (reset_n) via JP2
set_property -dict {LOC D10  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports uart_txd] ;# IC8.39 BDBUS1 RXD
set_property -dict {LOC A9   IOSTANDARD LVCMOS33} [get_ports uart_rxd] ;# IC8.38 BDBUS0 TXD

set_false_path -to [get_ports {uart_txd}]
set_output_delay 0 [get_ports {uart_txd}]
set_false_path -from [get_ports {uart_rxd}]
set_input_delay 0 [get_ports {uart_rxd}]
