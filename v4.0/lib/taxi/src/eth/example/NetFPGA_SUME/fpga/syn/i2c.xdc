# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VC709
# part: xc7vx690tffg1761-2

# I2C interface
set_property -dict {LOC AK24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports i2c_scl]
set_property -dict {LOC AK25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12 PULLUP true} [get_ports i2c_sda]
set_property -dict {LOC AM39 IOSTANDARD LVCMOS15 SLEW SLOW DRIVE 12} [get_ports i2c_mux_reset]

set_false_path -to [get_ports {i2c_sda i2c_scl i2c_mux_reset}]
set_output_delay 0 [get_ports {i2c_sda i2c_scl i2c_mux_reset}]
set_false_path -from [get_ports {i2c_sda i2c_scl}]
set_input_delay 0 [get_ports {i2c_sda i2c_scl}]
