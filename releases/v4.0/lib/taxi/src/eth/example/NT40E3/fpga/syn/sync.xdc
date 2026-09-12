# SPDX-License-Identifier: MIT
#
# Copyright (c) 2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Napatech NT40E3
# part: xc7vx330tffg1157-2

# Time sync
set_property -dict {LOC AB31 IOSTANDARD LVCMOS18} [get_ports {sync_ext_in}]
set_property -dict {LOC AB32 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {sync_ext_out}]
set_property -dict {LOC AB30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_ext_in_en}]
set_property -dict {LOC AA30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_ext_out_en[0]}]
set_property -dict {LOC W32  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_ext_out_en[1]}]
set_property -dict {LOC Y32  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_ext_term[0]}]
set_property -dict {LOC AA31 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_ext_term[1]}]
set_property -dict {LOC V30  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_ext_vsel[0]}]
set_property -dict {LOC U30  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_ext_vsel[1]}]

set_property -dict {LOC AK26 IOSTANDARD LVCMOS18} [get_ports {sync_int_1_in}]
set_property -dict {LOC AK27 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {sync_int_1_out}]
set_property -dict {LOC AH24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_1_in_en}]
set_property -dict {LOC AH25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_1_out_en[0]}]
set_property -dict {LOC AJ25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_1_out_en[1]}]
set_property -dict {LOC AL25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_1_term[0]}]
set_property -dict {LOC AL26 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_1_term[1]}]
set_property -dict {LOC AG25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_1_vsel[0]}]
set_property -dict {LOC AJ27 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_1_vsel[1]}]

set_property -dict {LOC AM27 IOSTANDARD LVCMOS18} [get_ports {sync_int_2_in}]
set_property -dict {LOC AN29 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12} [get_ports {sync_int_2_out}]
set_property -dict {LOC AN28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_2_in_en}]
set_property -dict {LOC AM28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_2_out_en[0]}]
set_property -dict {LOC AP25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_2_out_en[1]}]
set_property -dict {LOC AP26 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_2_term[0]}]
set_property -dict {LOC AN27 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_2_term[1]}]
set_property -dict {LOC AN25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_2_vsel[0]}]
set_property -dict {LOC AM25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sync_int_2_vsel[1]}]

set_false_path -from [get_ports {sync_ext_in}]
set_input_delay 0 [get_ports {sync_ext_in}]
set_false_path -to [get_ports {sync_ext_out sync_ext_in_en sync_ext_out_en[*] sync_ext_term[*] sync_ext_vsel[*]}]
set_output_delay 0 [get_ports {sync_ext_out sync_ext_in_en sync_ext_out_en[*] sync_ext_term[*] sync_ext_vsel[*]}]

set_false_path -from [get_ports {sync_int_1_in}]
set_input_delay 0 [get_ports {sync_int_1_in}]
set_false_path -to [get_ports {sync_int_1_out sync_int_1_in_en sync_int_1_out_en[*] sync_int_1_term[*] sync_int_1_vsel[*]}]
set_output_delay 0 [get_ports {sync_int_1_out sync_int_1_in_en sync_int_1_out_en[*] sync_int_1_term[*] sync_int_1_vsel[*]}]

set_false_path -from [get_ports {sync_int_2_in}]
set_input_delay 0 [get_ports {sync_int_2_in}]
set_false_path -to [get_ports {sync_int_2_out sync_int_2_in_en sync_int_2_out_en[*] sync_int_2_term[*] sync_int_2_vsel[*]}]
set_output_delay 0 [get_ports {sync_int_2_out sync_int_2_in_en sync_int_2_out_en[*] sync_int_2_term[*] sync_int_2_vsel[*]}]
