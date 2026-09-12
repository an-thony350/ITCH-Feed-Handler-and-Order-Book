# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Cisco Nexus K3P-Q / ExaNIC X100
# part: xcku3p-ffvb676-2-e

# I2C interface
set_property -dict {LOC W12  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12 PULLUP true} [get_ports eeprom_i2c_scl]
set_property -dict {LOC W13  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12 PULLUP true} [get_ports eeprom_i2c_sda]

set_false_path -to [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
set_output_delay 0 [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
set_false_path -from [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
set_input_delay 0 [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
