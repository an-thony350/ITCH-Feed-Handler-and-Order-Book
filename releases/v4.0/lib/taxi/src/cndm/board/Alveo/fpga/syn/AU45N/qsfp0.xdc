# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx Alveo U45N/SN1022 board
# part: xcu26-vsva1365-2LV-e

# QSFP28 via GTM
set_property -dict {LOC A13 } [get_ports {qsfp0_rx_p[0]}] ;# MGTMRXP0_234 GTM_DUAL_X0Y1 CH0
set_property -dict {LOC A12 } [get_ports {qsfp0_rx_n[0]}] ;# MGTMRXN0_234 GTM_DUAL_X0Y1 CH0
set_property -dict {LOC C15 } [get_ports {qsfp0_tx_p[0]}] ;# MGTMTXP0_234 GTM_DUAL_X0Y1 CH0
set_property -dict {LOC C14 } [get_ports {qsfp0_tx_n[0]}] ;# MGTMTXN0_234 GTM_DUAL_X0Y1 CH0
set_property -dict {LOC A16 } [get_ports {qsfp0_rx_p[1]}] ;# MGTMRXP1_234 GTM_DUAL_X0Y1 CH1
set_property -dict {LOC A15 } [get_ports {qsfp0_rx_n[1]}] ;# MGTMRXN1_234 GTM_DUAL_X0Y1 CH1
set_property -dict {LOC C18 } [get_ports {qsfp0_tx_p[1]}] ;# MGTMTXP1_234 GTM_DUAL_X0Y1 CH1
set_property -dict {LOC C17 } [get_ports {qsfp0_tx_n[1]}] ;# MGTMTXN1_234 GTM_DUAL_X0Y1 CH1
set_property -dict {LOC A7  } [get_ports {qsfp0_rx_p[2]}] ;# MGTMRXP0_233 GTM_DUAL_X0Y0 CH0
set_property -dict {LOC A6  } [get_ports {qsfp0_rx_n[2]}] ;# MGTMRXN0_233 GTM_DUAL_X0Y0 CH0
set_property -dict {LOC C9  } [get_ports {qsfp0_tx_p[2]}] ;# MGTMTXP0_233 GTM_DUAL_X0Y0 CH0
set_property -dict {LOC C8  } [get_ports {qsfp0_tx_n[2]}] ;# MGTMTXN0_233 GTM_DUAL_X0Y0 CH0
set_property -dict {LOC A10 } [get_ports {qsfp0_rx_p[3]}] ;# MGTMRXP1_233 GTM_DUAL_X0Y0 CH1
set_property -dict {LOC A9  } [get_ports {qsfp0_rx_n[3]}] ;# MGTMRXN1_233 GTM_DUAL_X0Y0 CH1
set_property -dict {LOC C12 } [get_ports {qsfp0_tx_p[3]}] ;# MGTMTXP1_233 GTM_DUAL_X0Y0 CH1
set_property -dict {LOC C11 } [get_ports {qsfp0_tx_n[3]}] ;# MGTMTXN1_233 GTM_DUAL_X0Y0 CH1
set_property -dict {LOC G10 } [get_ports {qsfp0_mgt_refclk_0_p}] ;# MGTREFCLK0P_234 from SI5394 OUT1 via U16
set_property -dict {LOC G9  } [get_ports {qsfp0_mgt_refclk_0_n}] ;# MGTREFCLK0N_234 from SI5394 OUT1 via U16
set_property -dict {LOC J10 } [get_ports {qsfp0_mgt_refclk_1_p}] ;# MGTREFCLK1P_233 from SI5394 OUT1 via U16
set_property -dict {LOC J9  } [get_ports {qsfp0_mgt_refclk_1_n}] ;# MGTREFCLK1N_233 from SI5394 OUT1 via U16

# 161.1328125 MHz MGT reference clock (SI5394 OUT1 via U16)
create_clock -period 6.206 -name qsfp0_mgt_refclk_0 [get_ports {qsfp0_mgt_refclk_0_p}]
create_clock -period 6.206 -name qsfp0_mgt_refclk_1 [get_ports {qsfp0_mgt_refclk_1_p}]
