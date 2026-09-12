# SPDX-License-Identifier: MIT
#
# Copyright (c) 2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Napatech NT40E3
# part: xc7vx330tffg1157-2

# Si5338 U18
set_property -dict {LOC AF33 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports si5338_i2c_scl] ;# U18.12 SCL
set_property -dict {LOC AF34 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports si5338_i2c_sda] ;# U18.19 SDA
set_property -dict {LOC AC27 IOSTANDARD LVCMOS18} [get_ports si5338_intr] ;# U18.8 INTR

set_false_path -to [get_ports {si5338_i2c_scl si5338_i2c_sda}]
set_output_delay 0 [get_ports {si5338_i2c_scl si5338_i2c_sda}]
set_false_path -from [get_ports {si5338_i2c_scl si5338_i2c_sda si5338_intr}]
set_input_delay 0 [get_ports {si5338_i2c_scl si5338_i2c_sda si5338_intr}]
