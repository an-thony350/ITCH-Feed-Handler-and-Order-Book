# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Digilent Arty board
# part: xc7a35t-csg324-1

# PMOD JC
set_property -dict {LOC U12  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jc1}] ;# PMOD JC pin 1
set_property -dict {LOC V12  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jc2}] ;# PMOD JC pin 2
set_property -dict {LOC V10  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jc3}] ;# PMOD JC pin 3
set_property -dict {LOC V11  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jc4}] ;# PMOD JC pin 4
set_property -dict {LOC U14  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jc7}] ;# PMOD JC pin 7
set_property -dict {LOC V14  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jc8}] ;# PMOD JC pin 8
set_property -dict {LOC T13  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jc9}] ;# PMOD JC pin 9
set_property -dict {LOC U13  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jc10}] ;# PMOD JC pin 10
