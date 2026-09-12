# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Digilent Arty board
# part: xc7a35t-csg324-1

# PMOD JD
set_property -dict {LOC D4   IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jd1}] ;# PMOD JD pin 1
set_property -dict {LOC D3   IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jd2}] ;# PMOD JD pin 2
set_property -dict {LOC F4   IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jd3}] ;# PMOD JD pin 3
set_property -dict {LOC F3   IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jd4}] ;# PMOD JD pin 4
set_property -dict {LOC E2   IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jd7}] ;# PMOD JD pin 7
set_property -dict {LOC D2   IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jd8}] ;# PMOD JD pin 8
set_property -dict {LOC H2   IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jd9}] ;# PMOD JD pin 9
set_property -dict {LOC G2   IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {gpio_jd10}] ;# PMOD JD pin 10
