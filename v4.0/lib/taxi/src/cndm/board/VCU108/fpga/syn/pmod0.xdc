# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VCU108 board
# part: xcvu095-ffva2104-2-e

# PMOD0
set_property -dict {LOC BC14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[0]}] ;# J52.1
set_property -dict {LOC BA10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[1]}] ;# J52.3
set_property -dict {LOC AW16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[2]}] ;# J52.5
set_property -dict {LOC BB16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[3]}] ;# J52.7
set_property -dict {LOC BC13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[4]}] ;# J52.2
set_property -dict {LOC BF7  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[5]}] ;# J52.4
set_property -dict {LOC AW12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[6]}] ;# J52.6
set_property -dict {LOC BC16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[7]}] ;# J52.8

set_false_path -to [get_ports {pmod0[*]}]
set_output_delay 0 [get_ports {pmod0[*]}]
