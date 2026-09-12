# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx KR260 board
# part: xck26-sfvc784-2LV-c

# SFP+ Interface
set_property -dict {LOC T2  } [get_ports sfp_rx_p] ;# MGTHRXP2_224 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3 / GTH_DP2_C2M_P som240_2_b1
set_property -dict {LOC T1  } [get_ports sfp_rx_n] ;# MGTHRXN2_224 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3 / GTH_DP2_C2M_N som240_2_b2
set_property -dict {LOC R4  } [get_ports sfp_tx_p] ;# MGTHTXP2_224 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3 / GTH_DP2_M2C_P som240_2_b5
set_property -dict {LOC R3  } [get_ports sfp_tx_n] ;# MGTHTXN2_224 GTHE4_CHANNEL_X1Y12 / GTHE4_COMMON_X1Y3 / GTH_DP2_M2C_N som240_2_b6
set_property -dict {LOC Y6  } [get_ports sfp_mgt_refclk_p] ;# MGTREFCLK0P_224 from U90 / GTH_REFCLK0_C2M_P som240_2_c3
set_property -dict {LOC Y5  } [get_ports sfp_mgt_refclk_n] ;# MGTREFCLK0N_224 from U90 / GTH_REFCLK0_C2M_N som240_2_c4
set_property -dict {LOC Y10  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports sfp_tx_disable] ;# HDB19 som240_2_a47
set_property -dict {LOC A10  IOSTANDARD LVCMOS33} [get_ports sfp_tx_fault]   ;# HDA19 som240_1_c23
set_property -dict {LOC J12  IOSTANDARD LVCMOS33} [get_ports sfp_rx_los]     ;# HDA10 som240_1_a16
set_property -dict {LOC W10  IOSTANDARD LVCMOS33} [get_ports sfp_mod_abs]    ;# HDB18 som240_2_a46
set_property -dict {LOC AB11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports sfp_i2c_scl]    ;# HDB16 som240_2_b49
set_property -dict {LOC AC11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports sfp_i2c_sda]    ;# HDB17 som240_2_b50

# 156.25 MHz MGT reference clock
create_clock -period 6.400 -name sfp_mgt_refclk [get_ports sfp_mgt_refclk_p]

set_false_path -to [get_ports {sfp_tx_disable}]
set_output_delay 0 [get_ports {sfp_tx_disable}]
set_false_path -from [get_ports {sfp_tx_fault sfp_rx_los sfp_mod_abs}]
set_input_delay 0 [get_ports {sfp_tx_fault sfp_rx_los sfp_mod_abs}]

set_false_path -to [get_ports {sfp_i2c_sda sfp_i2c_scl}]
set_output_delay 0 [get_ports {sfp_i2c_sda sfp_i2c_scl}]
set_false_path -from [get_ports {sfp_i2c_sda sfp_i2c_scl}]
set_input_delay 0 [get_ports {sfp_i2c_sda sfp_i2c_scl}]
