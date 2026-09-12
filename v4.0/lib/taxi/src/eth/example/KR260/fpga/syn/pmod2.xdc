# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx KR260 board
# part: xck26-sfvc784-2LV-c

# PMOD2
set_property -dict {LOC J11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[0]}] ;# J18.1 / HDA02 som240_1_d18
set_property -dict {LOC J10  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[1]}] ;# J18.3 / HDA03 som240_1_b16
set_property -dict {LOC K13  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[2]}] ;# J18.5 / HDA04 som240_1_b17
set_property -dict {LOC K12  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[3]}] ;# J18.7 / HDA05 som240_1_b18
set_property -dict {LOC H11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[4]}] ;# J18.2 / HDA06 som240_1_c18
set_property -dict {LOC G10  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[5]}] ;# J18.4 / HDA07 som240_1_c19
set_property -dict {LOC F12  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[6]}] ;# J18.6 / HDA08_CC som240_1_c20
set_property -dict {LOC F11  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod2[7]}] ;# J18.8 / HDA09 som240_1_a15

set_false_path -to [get_ports {pmod2[*]}]
set_output_delay 0 [get_ports {pmod2[*]}]
