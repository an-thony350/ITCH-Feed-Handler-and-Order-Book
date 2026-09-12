# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

create_ip -name gig_ethernet_pcs_pma -vendor xilinx.com -library ip -module_name basex_pcs_pma_0

set_property -dict [list \
    CONFIG.Standard {1000BASEX} \
    CONFIG.Physical_Interface {Transceiver} \
    CONFIG.Management_Interface {false} \
    CONFIG.Auto_Negotiation {false} \
    CONFIG.TransceiverControl {true} \
    CONFIG.SupportLevel {Include_Shared_Logic_in_Example_Design} \
] [get_ips basex_pcs_pma_0]
