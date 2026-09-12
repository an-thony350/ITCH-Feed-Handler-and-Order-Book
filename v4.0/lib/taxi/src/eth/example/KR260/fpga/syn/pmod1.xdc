# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx KR260 board
# part: xck26-sfvc784-2LV-c

# PMOD1
set_property -dict {LOC H12  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[0]}] ;# J2.1 / HDA11 som240_1_a17
set_property -dict {LOC E10  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[1]}] ;# J2.3 / HDA12 som240_1_d20
set_property -dict {LOC D10  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[2]}] ;# J2.5 / HDA13 som240_1_d21
set_property -dict {LOC C11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[3]}] ;# J2.7 / HDA14 som240_1_d22
set_property -dict {LOC B10  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[4]}] ;# J2.2 / HDA15 som240_1_b20
set_property -dict {LOC E12  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[5]}] ;# J2.4 / HDA16_CC som240_1_b21
set_property -dict {LOC D11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[6]}] ;# J2.6 / HDA17 som240_1_b22
set_property -dict {LOC B11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod1[7]}] ;# J2.8 / HDA18 som240_1_c22

set_false_path -to [get_ports {pmod1[*]}]
set_output_delay 0 [get_ports {pmod1[*]}]
