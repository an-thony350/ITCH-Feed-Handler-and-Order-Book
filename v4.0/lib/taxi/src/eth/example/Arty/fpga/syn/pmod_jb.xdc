# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Digilent Arty board
# part: xc7a35t-csg324-1

# PMOD JB
set_property -dict {LOC E15  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jb1}] ;# PMOD JB pin 1
set_property -dict {LOC E16  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jb2}] ;# PMOD JB pin 2
set_property -dict {LOC D15  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jb3}] ;# PMOD JB pin 3
set_property -dict {LOC C15  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jb4}] ;# PMOD JB pin 4
set_property -dict {LOC J17  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jb7}] ;# PMOD JB pin 7
set_property -dict {LOC J18  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jb8}] ;# PMOD JB pin 8
set_property -dict {LOC K15  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jb9}] ;# PMOD JB pin 9
set_property -dict {LOC J15  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jb10}] ;# PMOD JB pin 10
