# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo AU200/AU250/VCU1525
# AU200 part: xcu200-fsgd2104-2-e
# AU250 part: xcu250-figd2104-2-e
# VCU1525 part: xcvu9p-fsgd2104-2L-e

# I2C interface
#set_property -dict {LOC BF19 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports i2c_mux_reset]
set_property -dict {LOC BF20 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports i2c_scl]
set_property -dict {LOC BF17 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports i2c_sda]

set_false_path -to [get_ports {i2c_sda i2c_scl}]
set_output_delay 0 [get_ports {i2c_sda i2c_scl}]
set_false_path -from [get_ports {i2c_sda i2c_scl}]
set_input_delay 0 [get_ports {i2c_sda i2c_scl}]
