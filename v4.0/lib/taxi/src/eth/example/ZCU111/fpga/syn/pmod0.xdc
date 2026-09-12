# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU111 board
# part: xczu28dr-ffvg1517-2-e

# PMOD0
set_property -dict {LOC C17  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[0]}] ;# J48.1
set_property -dict {LOC M18  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[1]}] ;# J48.3
set_property -dict {LOC H16  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[2]}] ;# J48.5
set_property -dict {LOC H17  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[3]}] ;# J48.7
set_property -dict {LOC J16  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[4]}] ;# J48.2
set_property -dict {LOC K16  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[5]}] ;# J48.4
set_property -dict {LOC H15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[6]}] ;# J48.6
set_property -dict {LOC J15  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[7]}] ;# J48.8

set_false_path -to [get_ports {pmod0[*]}]
set_output_delay 0 [get_ports {pmod0[*]}]
