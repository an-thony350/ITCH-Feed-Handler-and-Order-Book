# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the BittWare XUSP3S board
# part: xcvu095-ffvb2104-2-e

# EEPROM I2C interface
set_property -dict {LOC AN24 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports eeprom_i2c_scl]
set_property -dict {LOC AP23 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports eeprom_i2c_sda]

set_false_path -to [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
set_output_delay 0 [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
set_false_path -from [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]
set_input_delay 0 [get_ports {eeprom_i2c_sda eeprom_i2c_scl}]

# I2C-related signals
set_property -dict {LOC AT24 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports fpga_i2c_master_l]
set_property -dict {LOC AN23 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports qsfp_ctl_en]

set_false_path -to [get_ports {fpga_i2c_master_l qsfp_ctl_en}]
set_output_delay 0 [get_ports {fpga_i2c_master_l qsfp_ctl_en}]
