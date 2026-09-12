# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# Ethernet constraints

# IDELAY from PHY chip (RGMII)
set_property DELAY_VALUE 0 [get_cells {phy2_rx_ctl_idelay phy2_rxd_idelay_bit[*].idelay_inst}]
set_property DELAY_VALUE 0 [get_cells {phy3_rx_ctl_idelay phy3_rxd_idelay_bit[*].idelay_inst}]

# MMCM phase (RGMII)
set_property CLKOUT1_PHASE 90 [get_cells clk_mmcm_inst]
