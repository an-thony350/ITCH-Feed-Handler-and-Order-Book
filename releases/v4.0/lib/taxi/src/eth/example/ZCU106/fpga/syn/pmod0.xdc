# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU106 board
# part: xczu7ev-ffvc1156-2-e

# PMOD0
set_property -dict {LOC B23  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[0]}] ;# J55.1
set_property -dict {LOC A23  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[1]}] ;# J55.3
set_property -dict {LOC F25  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[2]}] ;# J55.5
set_property -dict {LOC E20  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[3]}] ;# J55.7
set_property -dict {LOC K24  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[4]}] ;# J55.2
set_property -dict {LOC L23  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[5]}] ;# J55.4
set_property -dict {LOC L22  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[6]}] ;# J55.6
set_property -dict {LOC D7   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[7]}] ;# J55.8

set_false_path -to [get_ports {pmod0[*]}]
set_output_delay 0 [get_ports {pmod0[*]}]
