# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU106 board
# part: xczu7ev-ffvc1156-2-e

# PMOD1
set_property -dict {LOC AN8  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[0]}] ;# J87.1
set_property -dict {LOC AN9  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[1]}] ;# J87.3
set_property -dict {LOC AP11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[2]}] ;# J87.5
set_property -dict {LOC AN11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[3]}] ;# J87.7
set_property -dict {LOC AP9  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[4]}] ;# J87.2
set_property -dict {LOC AP10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[5]}] ;# J87.4
set_property -dict {LOC AP12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[6]}] ;# J87.6
set_property -dict {LOC AN12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[7]}] ;# J87.8

set_false_path -to [get_ports {pmod1[*]}]
set_output_delay 0 [get_ports {pmod1[*]}]
