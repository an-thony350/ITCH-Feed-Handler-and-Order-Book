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

# QSPI flash
set_property -dict {LOC AF8  IOSTANDARD LVCMOS25 DRIVE 12 PULLUP true} [get_ports {qspi_clk}]
set_property -dict {LOC AD10 IOSTANDARD LVCMOS25 DRIVE 12 PULLUP true} [get_ports {qspi_dq[0]}]
set_property -dict {LOC AH8  IOSTANDARD LVCMOS25 DRIVE 12 PULLUP true} [get_ports {qspi_dq[1]}]
set_property -dict {LOC AE10 IOSTANDARD LVCMOS25 DRIVE 12 PULLUP true} [get_ports {qspi_dq[2]}]
set_property -dict {LOC AD9  IOSTANDARD LVCMOS25 DRIVE 12 PULLUP true} [get_ports {qspi_dq[3]}]
set_property -dict {LOC AH9  IOSTANDARD LVCMOS25 DRIVE 12 PULLUP true} [get_ports {qspi_cs}]
set_property -dict {LOC AD8  IOSTANDARD LVCMOS25 DRIVE 12 PULLUP true} [get_ports {qspi_reset}]
