# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx KR260 board
# part: xck26-sfvc784-2LV-c

# PMOD3
set_property -dict {LOC AE12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[0]}] ;# J19.1 / HDB00_CC som240_2_d44
set_property -dict {LOC AF12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[1]}] ;# J19.3 / HDB01 som240_2_d45
set_property -dict {LOC AG10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[2]}] ;# J19.5 / HDB02 som240_2_d46
set_property -dict {LOC AH10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[3]}] ;# J19.7 / HDB03 som240_2_d48
set_property -dict {LOC AF11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[4]}] ;# J19.2 / HDB04 som240_2_d49
set_property -dict {LOC AG11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[5]}] ;# J19.4 / HDB05 som240_2_d50
set_property -dict {LOC AH12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[6]}] ;# J19.6 / HDB06 som240_2_c46
set_property -dict {LOC AH11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod3[7]}] ;# J19.8 / HDB07 som240_2_c47

set_false_path -to [get_ports {pmod3[*]}]
set_output_delay 0 [get_ports {pmod3[*]}]
