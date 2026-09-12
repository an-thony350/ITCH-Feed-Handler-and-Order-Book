# SPDX-License-Identifier: MIT
#
# Copyright (c) 2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Napatech NT40E3
# part: xc7vx330tffg1157-2

# LEDs
set_property -dict {LOC AC12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_led[0]}]
set_property -dict {LOC AE9  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_led[1]}]
set_property -dict {LOC AE8  IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_led[2]}]
set_property -dict {LOC AC10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {sfp_led[3]}]
set_property -dict {LOC AD30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[0]}]
set_property -dict {LOC AD31 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[1]}]
set_property -dict {LOC AG30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[2]}]
set_property -dict {LOC AH30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led[3]}]
set_property -dict {LOC AB27 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led_red}]
set_property -dict {LOC AB28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led_green}]
set_property -dict {LOC AJ26 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led_sync[0]}]
set_property -dict {LOC AP29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led_sync[1]}]

set_false_path -to [get_ports {sfp_led[*] led[*] led_red led_green led_sync[*]}]
set_output_delay 0 [get_ports {sfp_led[*] led[*] led_red led_green led_sync[*]}]
