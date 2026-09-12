# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2019-2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# PTP time distribution ToD timestamp reconstruction module

foreach inst [get_cells -hier -regexp -filter {(ORIG_REF_NAME =~ "taxi_ptp_td_rel2tod(__\w+__\d+)?" ||
        REF_NAME =~ "taxi_ptp_td_rel2tod(__\w+__\d+)?")}] {
    puts "Inserting timing constraints for taxi_ptp_td_rel2tod instance $inst"

    # get clock periods
    set input_clk [get_clocks -of_objects [get_pins "$inst/td_sync_reg_reg/C"]]
    set output_clk [get_clocks -of_objects [get_pins "$inst/td_sync_sync1_reg_reg/C"]]

    set input_clk_period [if {[llength $input_clk]} {get_property -min PERIOD $input_clk} {expr 1.0}]
    set output_clk_period [if {[llength $output_clk]} {get_property -min PERIOD $output_clk} {expr 1.0}]

    # TD data sync
    set_property ASYNC_REG TRUE [get_cells -hier -regexp ".*/dst_td_(tdata|tid)_reg_reg(\\\[\\d+\\\])?" -filter "PARENT == $inst"]

    set_max_delay -from [get_cells "$inst/td_tdata_reg_reg[*]"] -to [get_cells "$inst/dst_td_tdata_reg_reg[*]"] -datapath_only $output_clk_period
    set_bus_skew  -from [get_cells "$inst/td_tdata_reg_reg[*]"] -to [get_cells "$inst/dst_td_tdata_reg_reg[*]"] $input_clk_period
    set_max_delay -from [get_cells "$inst/td_tid_reg_reg[*]"] -to [get_cells "$inst/dst_td_tid_reg_reg[*]"] -datapath_only $output_clk_period
    set_bus_skew  -from [get_cells "$inst/td_tid_reg_reg[*]"] -to [get_cells "$inst/dst_td_tid_reg_reg[*]"] $input_clk_period

    set sync_ffs [get_cells -quiet -hier -regexp ".*/td_sync_sync\[12\]_reg_reg" -filter "PARENT == $inst"]

    if {[llength $sync_ffs]} {
        set_property ASYNC_REG TRUE $sync_ffs

        set_max_delay -from [get_cells "$inst/td_sync_reg_reg"] -to [get_cells "$inst/td_sync_sync1_reg_reg"] -datapath_only $input_clk_period
    }
}
