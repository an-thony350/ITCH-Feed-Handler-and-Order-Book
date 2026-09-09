# ZCU106 Taxi 10GbE physical constraints
# Target: xczu7ev-ffvc1156-2-e

# Adapted from Taxi's upstream ZCU106 constraints to this project's top-level v3_release_wrapper port names.

# 125 MHz differential control clock

set_property -dict {LOC H9 IOSTANDARD LVDS} [get_ports CLK_IN1_D_0_clk_p]
set_property -dict {LOC G9 IOSTANDARD LVDS} [get_ports CLK_IN1_D_0_clk_n]

create_clock -period 8.000 -name taxi_ctrl_refclk [get_ports CLK_IN1_D_0_clk_p]

# ZCU106 SFP+ GTH lanes

# SFP+ lane 0
set_property LOC AA2 [get_ports {sfp_rx_p[0]}]
set_property LOC AA1 [get_ports {sfp_rx_n[0]}]
set_property LOC Y4  [get_ports {sfp_tx_p[0]}]
set_property LOC Y3  [get_ports {sfp_tx_n[0]}]

# SFP+ lane 1
set_property LOC W2  [get_ports {sfp_rx_p[1]}]
set_property LOC W1  [get_ports {sfp_rx_n[1]}]
set_property LOC W6  [get_ports {sfp_tx_p[1]}]
set_property LOC W5  [get_ports {sfp_tx_n[1]}]

# 156.25 MHz SFP+ MGT reference clock

set_property LOC U10 [get_ports sfp_mgt_refclk_p]
set_property LOC U9  [get_ports sfp_mgt_refclk_n]

create_clock -period 6.400 -name sfp_mgt_refclk [get_ports sfp_mgt_refclk_p]

# SFP+ TX disable

set_property -dict {LOC AE22 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8}     [get_ports {sfp_tx_disable_b[0]}]

set_property -dict {LOC AF20 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8}     [get_ports {sfp_tx_disable_b[1]}]

set_false_path -to [get_ports {sfp_tx_disable_b[*]}]
set_output_delay 0 [get_ports {sfp_tx_disable_b[*]}]
