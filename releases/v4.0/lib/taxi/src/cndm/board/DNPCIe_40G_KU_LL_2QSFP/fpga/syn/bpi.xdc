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

# BPI flash
set_property -dict {LOC M20  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[4]}]
set_property -dict {LOC L20  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[5]}]
set_property -dict {LOC R21  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[6]}]
set_property -dict {LOC R22  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[7]}]
set_property -dict {LOC P20  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[8]}]
set_property -dict {LOC P21  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[9]}]
set_property -dict {LOC N22  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[10]}]
set_property -dict {LOC M22  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[11]}]
set_property -dict {LOC R23  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[12]}]
set_property -dict {LOC P23  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[13]}]
set_property -dict {LOC R25  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[14]}]
set_property -dict {LOC R26  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_dq[15]}]
set_property -dict {LOC T24  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[0]}]
set_property -dict {LOC T25  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[1]}]
set_property -dict {LOC T27  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[2]}]
set_property -dict {LOC R27  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[3]}]
set_property -dict {LOC P24  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[4]}]
set_property -dict {LOC P25  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[5]}]
set_property -dict {LOC P26  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[6]}]
set_property -dict {LOC N26  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[7]}]
set_property -dict {LOC N24  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[8]}]
set_property -dict {LOC M24  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[9]}]
set_property -dict {LOC M25  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[10]}]
set_property -dict {LOC M26  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[11]}]
set_property -dict {LOC L22  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[12]}]
set_property -dict {LOC K23  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[13]}]
set_property -dict {LOC L25  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[14]}]
set_property -dict {LOC K25  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[15]}]
set_property -dict {LOC L23  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[16]}]
set_property -dict {LOC L24  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[17]}]
set_property -dict {LOC M27  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[18]}]
set_property -dict {LOC L27  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[19]}]
set_property -dict {LOC J23  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[20]}]
set_property -dict {LOC H24  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[21]}]
set_property -dict {LOC J26  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[22]}]
set_property -dict {LOC H26  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_addr[23]}]
set_property -dict {LOC J24  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_region[0]}]
set_property -dict {LOC J25  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_region[1]}]
set_property -dict {LOC G25  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_oe_n}]
set_property -dict {LOC G26  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_we_n}]
set_property -dict {LOC N27  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {flash_adv_n}]

set_false_path -to [get_ports {flash_dq[*] flash_addr[*] flash_oe_n flash_we_n flash_adv_n}]
set_output_delay 0 [get_ports {flash_dq[*] flash_addr[*] flash_oe_n flash_we_n flash_adv_n}]
set_false_path -from [get_ports {flash_dq[*]}]
set_input_delay 0 [get_ports {flash_dq[*]}]
