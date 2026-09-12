# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU111 board
# part: xczu28dr-ffvg1517-2-e

# I2C interfaces
set_property -dict {LOC AT16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports i2c0_scl]
set_property -dict {LOC AW16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports i2c0_sda]
set_property -dict {LOC AV16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports i2c1_scl]
set_property -dict {LOC AV13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports i2c1_sda]

set_false_path -to [get_ports {i2c0_sda i2c0_scl}]
set_output_delay 0 [get_ports {i2c0_sda i2c0_scl}]
set_false_path -from [get_ports {i2c0_sda i2c0_scl}]
set_input_delay 0 [get_ports {i2c0_sda i2c0_scl}]

set_false_path -to [get_ports {i2c1_sda i2c1_scl}]
set_output_delay 0 [get_ports {i2c1_sda i2c1_scl}]
set_false_path -from [get_ports {i2c1_sda i2c1_scl}]
set_input_delay 0 [get_ports {i2c1_sda i2c1_scl}]
