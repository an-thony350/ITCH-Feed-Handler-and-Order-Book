# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2019-2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# RGMII PHY IF timing constraints

foreach inst [get_cells -hier -regexp -filter {(ORIG_REF_NAME =~ "taxi_rgmii_phy_if(__\w+__\d+)?" ||
        REF_NAME =~ "taxi_rgmii_phy_if(__\w+__\d+)?")}] {
    puts "Inserting timing constraints for taxi_rgmii_phy_if instance $inst"

    # clock output
    set_property ASYNC_REG TRUE [get_cells $inst/clk_oddr_inst/oddr[0].oddr_inst]

    set src_clk [get_clocks -of_objects [get_pins $inst/rgmii_tx_clk_1_reg_reg/C]]

    set src_clk_period [if {[llength $src_clk]} {get_property -min PERIOD $src_clk} {expr 8.0}]

    set_max_delay -from [get_cells $inst/rgmii_tx_clk_1_reg_reg] -to [get_cells $inst/clk_oddr_inst/oddr[0].oddr_inst] -datapath_only [expr $src_clk_period/4]
    set_max_delay -from [get_cells $inst/rgmii_tx_clk_2_reg_reg] -to [get_cells $inst/clk_oddr_inst/oddr[0].oddr_inst] -datapath_only [expr $src_clk_period/4]
}
