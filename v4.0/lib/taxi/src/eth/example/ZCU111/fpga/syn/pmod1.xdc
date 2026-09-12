# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU111 board
# part: xczu28dr-ffvg1517-2-e

# PMOD1
set_property -dict {LOC L14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[0]}] ;# J49.1
set_property -dict {LOC L15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[1]}] ;# J49.3
set_property -dict {LOC M13  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[2]}] ;# J49.5
set_property -dict {LOC N13  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[3]}] ;# J49.7
set_property -dict {LOC M15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[4]}] ;# J49.2
set_property -dict {LOC N15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[5]}] ;# J49.4
set_property -dict {LOC M14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[6]}] ;# J49.6
set_property -dict {LOC N14  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[7]}] ;# J49.8

set_false_path -to [get_ports {pmod1[*]}]
set_output_delay 0 [get_ports {pmod1[*]}]
