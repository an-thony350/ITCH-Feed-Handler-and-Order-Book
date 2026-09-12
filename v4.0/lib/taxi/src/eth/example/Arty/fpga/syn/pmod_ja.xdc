# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Digilent Arty board
# part: xc7a35t-csg324-1

# PMOD JA
set_property -dict {LOC G13  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_ja1}] ;# PMOD JA pin 1
set_property -dict {LOC B11  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_ja2}] ;# PMOD JA pin 2
set_property -dict {LOC A11  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_ja3}] ;# PMOD JA pin 3
set_property -dict {LOC D12  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_ja4}] ;# PMOD JA pin 4
set_property -dict {LOC D13  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_ja7}] ;# PMOD JA pin 7
set_property -dict {LOC B18  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_ja8}] ;# PMOD JA pin 8
set_property -dict {LOC A18  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_ja9}] ;# PMOD JA pin 9
set_property -dict {LOC K16  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_ja10}] ;# PMOD JA pin 10
