# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Cisco Nexus K3P-Q / ExaNIC X100
# part: xcku3p-ffvb676-2-e

# QSPI flash
set_property -dict {LOC H11  IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {qspi_clk}]
set_property -dict {LOC H9   IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {qspi_dq[0]}]
set_property -dict {LOC J9   IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {qspi_dq[1]}]
set_property -dict {LOC J10  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {qspi_dq[2]}]
set_property -dict {LOC J11  IOSTANDARD LVCMOS18 DRIVE 16} [get_ports {qspi_dq[3]}]
set_property -dict {LOC K9   IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {qspi_0_cs}]
set_property -dict {LOC K10  IOSTANDARD LVCMOS18 DRIVE 12} [get_ports {qspi_1_cs}]

set_false_path -to [get_ports {qspi_clk qspi_dq[*] qspi_0_cs qspi_1_cs}]
set_output_delay 0 [get_ports {qspi_clk qspi_dq[*] qspi_0_cs qspi_1_cs}]
set_false_path -from [get_ports {qspi_dq[*]}]
set_input_delay 0 [get_ports {qspi_dq[*]}]
