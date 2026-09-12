# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# Ethernet constraints

# BUFGMUX outputs (GMII)
set_clock_groups -physically_exclusive -group clk_mmcm_out -group phy_tx_clk
