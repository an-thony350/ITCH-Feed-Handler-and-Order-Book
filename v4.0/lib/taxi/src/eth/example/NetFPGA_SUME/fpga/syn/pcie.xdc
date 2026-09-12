# SPDX-License-Identifier: MIT
#
# Copyright (c) 2014-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx VC709
# part: xc7vx690tffg1761-2

# PCIe Interface
set_property -dict {LOC Y4   } [get_ports {pcie_rx_p[0]}] ;# MGTHTXP3_115 GTHE2_CHANNEL_X1Y23 / GTHE2_COMMON_X1Y5
set_property -dict {LOC Y3   } [get_ports {pcie_rx_n[0]}] ;# MGTHTXN3_115 GTHE2_CHANNEL_X1Y23 / GTHE2_COMMON_X1Y5
set_property -dict {LOC W2   } [get_ports {pcie_tx_p[0]}] ;# MGTHTXP3_115 GTHE2_CHANNEL_X1Y23 / GTHE2_COMMON_X1Y5
set_property -dict {LOC W1   } [get_ports {pcie_tx_n[0]}] ;# MGTHTXN3_115 GTHE2_CHANNEL_X1Y23 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AA6  } [get_ports {pcie_rx_p[1]}] ;# MGTHTXP2_115 GTHE2_CHANNEL_X1Y22 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AA5  } [get_ports {pcie_rx_n[1]}] ;# MGTHTXN2_115 GTHE2_CHANNEL_X1Y22 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AA2  } [get_ports {pcie_tx_p[1]}] ;# MGTHTXP2_115 GTHE2_CHANNEL_X1Y22 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AA1  } [get_ports {pcie_tx_n[1]}] ;# MGTHTXN2_115 GTHE2_CHANNEL_X1Y22 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AB4  } [get_ports {pcie_rx_p[2]}] ;# MGTHTXP1_115 GTHE2_CHANNEL_X1Y21 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AB3  } [get_ports {pcie_rx_n[2]}] ;# MGTHTXN1_115 GTHE2_CHANNEL_X1Y21 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AC2  } [get_ports {pcie_tx_p[2]}] ;# MGTHTXP1_115 GTHE2_CHANNEL_X1Y21 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AC1  } [get_ports {pcie_tx_n[2]}] ;# MGTHTXN1_115 GTHE2_CHANNEL_X1Y21 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AC6  } [get_ports {pcie_rx_p[3]}] ;# MGTHTXP0_115 GTHE2_CHANNEL_X1Y20 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AC5  } [get_ports {pcie_rx_n[3]}] ;# MGTHTXN0_115 GTHE2_CHANNEL_X1Y20 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AE2  } [get_ports {pcie_tx_p[3]}] ;# MGTHTXP0_115 GTHE2_CHANNEL_X1Y20 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AE1  } [get_ports {pcie_tx_n[3]}] ;# MGTHTXN0_115 GTHE2_CHANNEL_X1Y20 / GTHE2_COMMON_X1Y5
set_property -dict {LOC AD4  } [get_ports {pcie_rx_p[4]}] ;# MGTHTXP3_114 GTHE2_CHANNEL_X1Y19 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AD3  } [get_ports {pcie_rx_n[4]}] ;# MGTHTXN3_114 GTHE2_CHANNEL_X1Y19 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AG2  } [get_ports {pcie_tx_p[4]}] ;# MGTHTXP3_114 GTHE2_CHANNEL_X1Y19 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AG1  } [get_ports {pcie_tx_n[4]}] ;# MGTHTXN3_114 GTHE2_CHANNEL_X1Y19 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AE6  } [get_ports {pcie_rx_p[5]}] ;# MGTHTXP2_114 GTHE2_CHANNEL_X1Y18 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AE5  } [get_ports {pcie_rx_n[5]}] ;# MGTHTXN2_114 GTHE2_CHANNEL_X1Y18 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AH4  } [get_ports {pcie_tx_p[5]}] ;# MGTHTXP2_114 GTHE2_CHANNEL_X1Y18 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AH3  } [get_ports {pcie_tx_n[5]}] ;# MGTHTXN2_114 GTHE2_CHANNEL_X1Y18 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AF4  } [get_ports {pcie_rx_p[6]}] ;# MGTHTXP1_114 GTHE2_CHANNEL_X1Y17 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AF3  } [get_ports {pcie_rx_n[6]}] ;# MGTHTXN1_114 GTHE2_CHANNEL_X1Y17 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AJ2  } [get_ports {pcie_tx_p[6]}] ;# MGTHTXP1_114 GTHE2_CHANNEL_X1Y17 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AJ1  } [get_ports {pcie_tx_n[6]}] ;# MGTHTXN1_114 GTHE2_CHANNEL_X1Y17 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AG6  } [get_ports {pcie_rx_p[7]}] ;# MGTHTXP0_114 GTHE2_CHANNEL_X1Y16 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AG5  } [get_ports {pcie_rx_n[7]}] ;# MGTHTXN0_114 GTHE2_CHANNEL_X1Y16 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AK4  } [get_ports {pcie_tx_p[7]}] ;# MGTHTXP0_114 GTHE2_CHANNEL_X1Y16 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AK3  } [get_ports {pcie_tx_n[7]}] ;# MGTHTXN0_114 GTHE2_CHANNEL_X1Y16 / GTHE2_COMMON_X1Y4
set_property -dict {LOC AB8  } [get_ports pcie_mgt_refclk_p] ;# MGTREFCLK1P_115
set_property -dict {LOC AB7  } [get_ports pcie_mgt_refclk_n] ;# MGTREFCLK1N_115
set_property -dict {LOC AY35 IOSTANDARD LVCMOS18 PULLUP true} [get_ports pcie_reset_n]

# 100 MHz MGT reference clock
create_clock -period 10.000 -name pcie_mgt_refclk [get_ports pcie_mgt_refclk_p]

set_false_path -from [get_ports {pcie_reset_n}]
set_input_delay 0 [get_ports {pcie_reset_n}]
