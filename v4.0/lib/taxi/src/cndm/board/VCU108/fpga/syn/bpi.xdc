# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VCU108 board
# part: xcvu095-ffva2104-2-e

# BPI flash
set_property -dict {LOC AM19 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[4]}]
set_property -dict {LOC AM18 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[5]}]
set_property -dict {LOC AN20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[6]}]
set_property -dict {LOC AP20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[7]}]
set_property -dict {LOC AN19 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[8]}]
set_property -dict {LOC AN18 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[9]}]
set_property -dict {LOC AR18 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[10]}]
set_property -dict {LOC AR17 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[11]}]
set_property -dict {LOC AT20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[12]}]
set_property -dict {LOC AT19 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[13]}]
set_property -dict {LOC AT17 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[14]}]
set_property -dict {LOC AU17 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_dq[15]}]
set_property -dict {LOC AR20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[0]}]
set_property -dict {LOC AR19 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[1]}]
set_property -dict {LOC AV20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[2]}]
set_property -dict {LOC AW20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[3]}]
set_property -dict {LOC AU19 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[4]}]
set_property -dict {LOC AU18 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[5]}]
set_property -dict {LOC AV19 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[6]}]
set_property -dict {LOC AV18 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[7]}]
set_property -dict {LOC AW18 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[8]}]
set_property -dict {LOC AY18 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[9]}]
set_property -dict {LOC AY19 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[10]}]
set_property -dict {LOC BA19 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[11]}]
set_property -dict {LOC BA17 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[12]}]
set_property -dict {LOC BB17 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[13]}]
set_property -dict {LOC BB19 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[14]}]
set_property -dict {LOC BC19 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[15]}]
set_property -dict {LOC BB18 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[16]}]
set_property -dict {LOC BC18 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[17]}]
set_property -dict {LOC AY20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[18]}]
set_property -dict {LOC BA20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[19]}]
set_property -dict {LOC BD18 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[20]}]
set_property -dict {LOC BD17 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[21]}]
set_property -dict {LOC BC20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[22]}]
set_property -dict {LOC BD20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_addr[23]}]
set_property -dict {LOC BE20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_region[0]}]
set_property -dict {LOC BF20 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_region[1]}]
set_property -dict {LOC BF17 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_oe_n}]
set_property -dict {LOC BF16 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_we_n}]
set_property -dict {LOC AW17 IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {flash_adv_n}]
set_property -dict {LOC BC23 IOSTANDARD LVCMOS18} [get_ports {flash_wait}]

set_false_path -to [get_ports {flash_dq[*] flash_addr[*] flash_region[*] flash_oe_n flash_we_n flash_adv_n}]
set_output_delay 0 [get_ports {flash_dq[*] flash_addr[*] flash_region[*] flash_oe_n flash_we_n flash_adv_n}]
set_false_path -from [get_ports {flash_dq[*] flash_wait}]
set_input_delay 0 [get_ports {flash_dq[*] flash_wait}]
