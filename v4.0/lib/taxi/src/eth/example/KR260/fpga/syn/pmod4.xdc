# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx KR260 board
# part: xck26-sfvc784-2LV-c

# PMOD4
set_property -dict {LOC AC12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[0]}] ;# J20.1 / HDB08_CC som240_2_c48
set_property -dict {LOC AD12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[1]}] ;# J20.3 / HDB09 som240_2_c50
set_property -dict {LOC AE10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[2]}] ;# J20.5 / HDB10 som240_2_c51
set_property -dict {LOC AF10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[3]}] ;# J20.7 / HDB11 som240_2_c52
set_property -dict {LOC AD11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[4]}] ;# J20.2 / HDB12 som240_2_b44
set_property -dict {LOC AD10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[5]}] ;# J20.4 / HDB13 som240_2_b45
set_property -dict {LOC AA11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[6]}] ;# J20.6 / HDB14 som240_2_b46
set_property -dict {LOC AA10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod4[7]}] ;# J20.8 / HDB15 som240_2_b48

set_false_path -to [get_ports {pmod4[*]}]
set_output_delay 0 [get_ports {pmod4[*]}]
