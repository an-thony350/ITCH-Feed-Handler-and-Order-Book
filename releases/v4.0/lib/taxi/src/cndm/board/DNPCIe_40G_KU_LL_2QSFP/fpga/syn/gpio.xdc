# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the DNPCIe_40G_KU_LL_2QSFP
# part: xcku040-ffva1156-2-e
# part: xcku060-ffva1156-2-e

# LEDs
set_property -dict {LOC H22  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {user_led[0]}]
set_property -dict {LOC E20  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {user_led[1]}]
set_property -dict {LOC F22  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {user_led[2]}]
set_property -dict {LOC G22  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {user_led[3]}]
set_property -dict {LOC F12  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {user_led[4]}]
set_property -dict {LOC F10  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {user_led[5]}]
set_property -dict {LOC D10  IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {user_led[6]}]
set_property -dict {LOC AK33 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {user_led[7]}]

set_property -dict {LOC AG14 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp0_led_green}]
set_property -dict {LOC AP14 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp0_led_red}]
set_property -dict {LOC AH29 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp1_led_green}]
set_property -dict {LOC AL33 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {qsfp1_led_red}]

set_false_path -to [get_ports {user_led[*] qsfp0_led_green qsfp0_led_red qsfp1_led_green qsfp1_led_red}]
set_output_delay 0 [get_ports {user_led[*] qsfp0_led_green qsfp0_led_red qsfp1_led_green qsfp1_led_red}]

# Reset button
#set_property -dict {LOC N21  IOSTANDARD LVCMOS12} [get_ports reset]

#set_false_path -from [get_ports {reset}]
#set_input_delay 0 [get_ports {reset}]

# UART
set_property -dict {LOC F20 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports uart_txd]
set_property -dict {LOC G20 IOSTANDARD LVCMOS12} [get_ports uart_rxd]

set_false_path -to [get_ports {uart_txd}]
set_output_delay 0 [get_ports {uart_txd}]
set_false_path -from [get_ports {uart_rxd}]
set_input_delay 0 [get_ports {uart_rxd}]

set_false_path -to [get_ports {flash_dq[*] flash_addr[*] flash_oe_n flash_we_n flash_adv_n}]
set_output_delay 0 [get_ports {flash_dq[*] flash_addr[*] flash_oe_n flash_we_n flash_adv_n}]
set_false_path -from [get_ports {flash_dq[*]}]
set_input_delay 0 [get_ports {flash_dq[*]}]
