# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Cisco Nexus K3P-Q / ExaNIC X100
# part: xcku3p-ffvb676-2-e

# LEDs
set_property -dict {LOC AB15 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {qsfp_led_green[0]}]
set_property -dict {LOC AC14 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {qsfp_led_orange[0]}]
set_property -dict {LOC AA15 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {qsfp_led_green[1]}]
set_property -dict {LOC AB14 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {qsfp_led_orange[1]}]
set_property -dict {LOC C12  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {sma_led_green}]
set_property -dict {LOC C13  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {sma_led_red}]

set_false_path -to [get_ports {qsfp_led_green[*] qsfp_led_orange[*] sma_led_green sma_led_red}]
set_output_delay 0 [get_ports {qsfp_led_green[*] qsfp_led_orange[*] sma_led_green sma_led_red}]

# GPIO
#set_property -dict {LOC   IOSTANDARD LVCMOS18} [get_ports gpio[0]]
#set_property -dict {LOC   IOSTANDARD LVCMOS18} [get_ports gpio[1]]
#set_property -dict {LOC   IOSTANDARD LVCMOS18} [get_ports gpio[2]]
#set_property -dict {LOC   IOSTANDARD LVCMOS18} [get_ports gpio[3]]
#set_property -dict {LOC   IOSTANDARD LVCMOS18} [get_ports gpio[4]]

# SMA
#set_property -dict {LOC AD15 IOSTANDARD LVCMOS33} [get_ports {sma_in}]
#set_property -dict {LOC AF14 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {sma_out}]
#set_property -dict {LOC AD14 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {sma_out_en}]
#set_property -dict {LOC AB16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {sma_term_en}]

#set_false_path -to [get_ports {sma_out sma_out_en sma_term_en}]
#set_output_delay 0 [get_ports {sma_out sma_out_en sma_term_en}]
#set_false_path -from [get_ports {sma_in}]
#set_input_delay 0 [get_ports {sma_in}]

# Config
#set_property -dict {LOC C14  IOSTANDARD LVCMOS33} [get_ports ddr_npres]
