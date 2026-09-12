# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VCU108 board
# part: xcvu095-ffva2104-2-e

# PMOD1
set_property -dict {LOC P22  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[0]}] ;# J53.1
set_property -dict {LOC N22  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[1]}] ;# J53.3
set_property -dict {LOC J20  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[2]}] ;# J53.5
set_property -dict {LOC K24  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[3]}] ;# J53.7
set_property -dict {LOC J24  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[4]}] ;# J53.2
set_property -dict {LOC T23  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[5]}] ;# J53.4
set_property -dict {LOC R23  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[6]}] ;# J53.6
set_property -dict {LOC R22  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[7]}] ;# J53.8

set_false_path -to [get_ports {pmod1[*]}]
set_output_delay 0 [get_ports {pmod1[*]}]
