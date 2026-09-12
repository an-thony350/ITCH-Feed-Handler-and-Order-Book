# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# Ethernet constraints

# IDELAY from PHY chip (RGMII)
set_property IDELAY_VALUE 0 [get_cells {phy_if.phy_rx_ctl_idelay phy_if.phy_rxd_idelay_bit[*].idelay_inst}]

# MMCM phase (RGMII)
set_property CLKOUT1_PHASE 90 [get_cells clk_mmcm_inst]
