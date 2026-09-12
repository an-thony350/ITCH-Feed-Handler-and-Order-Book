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

# I2C EEPROM
set_property -dict {LOC AG9  IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12 PULLUP true} [get_ports eeprom_i2c_scl]
set_property -dict {LOC AE8  IOSTANDARD LVCMOS25 SLEW SLOW DRIVE 12 PULLUP true} [get_ports eeprom_i2c_sda]

set_false_path -to [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
set_output_delay 0 [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
set_false_path -from [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
set_input_delay 0 [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
