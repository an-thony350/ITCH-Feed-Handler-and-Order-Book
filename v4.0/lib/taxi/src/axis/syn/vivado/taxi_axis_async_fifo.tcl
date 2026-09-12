# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2019-2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# AXI stream asynchronous FIFO timing constraints

foreach fifo_inst [get_cells -hier -filter {(ORIG_REF_NAME == taxi_axis_async_fifo || REF_NAME == taxi_axis_async_fifo)}] {
    puts "Inserting timing constraints for taxi_axis_async_fifo instance $fifo_inst"

    # get clock periods
    set write_clk [get_clocks -of_objects [get_cells -quiet "$fifo_inst/wr_ptr_reg_reg[*] $fifo_inst/wr_ptr_gray_reg_reg[*] $fifo_inst/rd_ptr_gray_sync1_reg_reg[*]"]]
    set read_clk [get_clocks -of_objects [get_cells -quiet "$fifo_inst/rd_ptr_reg_reg[*] $fifo_inst/rd_ptr_gray_reg_reg[*] $fifo_inst/wr_ptr_gray_sync1_reg_reg[*]"]]

    set write_clk_period [if {[llength $write_clk]} {get_property -min PERIOD $write_clk} {expr 1.0}]
    set read_clk_period [if {[llength $read_clk]} {get_property -min PERIOD $read_clk} {expr 1.0}]

    set min_clk_period [expr min($write_clk_period, $read_clk_period)]

    # pointer synchronization
    set sync_ffs [get_cells -quiet -hier -regexp ".*/rd_ptr_gray_sync\[12\]_reg_reg\\\[\\d+\\\]" -filter "PARENT == $fifo_inst"]

    if {[llength $sync_ffs]} {
        set_property ASYNC_REG TRUE $sync_ffs

        set_max_delay -from [get_cells "$fifo_inst/rd_ptr_reg_reg[*] $fifo_inst/rd_ptr_gray_reg_reg[*]"] -to [get_cells "$fifo_inst/rd_ptr_gray_sync1_reg_reg[*]"] -datapath_only $read_clk_period
        set_bus_skew  -from [get_cells "$fifo_inst/rd_ptr_reg_reg[*] $fifo_inst/rd_ptr_gray_reg_reg[*]"] -to [get_cells "$fifo_inst/rd_ptr_gray_sync1_reg_reg[*]"] $write_clk_period
    }

    set sync_ffs [get_cells -quiet -hier -regexp ".*/wr_ptr_gray_sync\[12\]_reg_reg\\\[\\d+\\\]" -filter "PARENT == $fifo_inst"]

    if {[llength $sync_ffs]} {
        set_property ASYNC_REG TRUE $sync_ffs

        set_max_delay -from [get_cells -quiet "$fifo_inst/wr_ptr_reg_reg[*] $fifo_inst/wr_ptr_gray_reg_reg[*]"] -to [get_cells "$fifo_inst/wr_ptr_gray_sync1_reg_reg[*]"] -datapath_only $write_clk_period
        set_bus_skew  -from [get_cells -quiet "$fifo_inst/wr_ptr_reg_reg[*] $fifo_inst/wr_ptr_gray_reg_reg[*]"] -to [get_cells "$fifo_inst/wr_ptr_gray_sync1_reg_reg[*]"] $read_clk_period
    }

    set sync_ffs [get_cells -quiet -hier -regexp ".*/wr_ptr_commit_sync_reg_reg\\\[\\d+\\\]" -filter "PARENT == $fifo_inst"]

    if {[llength $sync_ffs]} {
        set_property ASYNC_REG TRUE $sync_ffs

        set_max_delay -from [get_cells -quiet "$fifo_inst/wr_ptr_sync_commit_reg_reg[*]"] -to [get_cells "$fifo_inst/wr_ptr_commit_sync_reg_reg[*]"] -datapath_only $write_clk_period
        set_bus_skew  -from [get_cells -quiet "$fifo_inst/wr_ptr_sync_commit_reg_reg[*]"] -to [get_cells "$fifo_inst/wr_ptr_commit_sync_reg_reg[*]"] $read_clk_period
    }

    # output register (needed for distributed RAM sync write/async read)
    set output_reg_ffs [get_cells -quiet "$fifo_inst/mem_rd_data_pipe_reg_reg[0][*]"]

    if {[llength $output_reg_ffs]} {
        if {[llength $write_clk]} {
            set_false_path -from $write_clk -to $output_reg_ffs
        }
    }

    # frame FIFO pointer update synchronization
    set update_ffs [get_cells -quiet -hier -regexp ".*/wr_ptr_update(_ack)?_sync\[123\]_reg_reg" -filter "PARENT == $fifo_inst"]

    if {[llength $update_ffs]} {
        set_property ASYNC_REG TRUE $update_ffs

        set_max_delay -from [get_cells "$fifo_inst/wr_ptr_update_reg_reg"] -to [get_cells "$fifo_inst/wr_ptr_update_sync1_reg_reg"] -datapath_only $write_clk_period
        set_max_delay -from [get_cells "$fifo_inst/wr_ptr_update_sync3_reg_reg"] -to [get_cells "$fifo_inst/wr_ptr_update_ack_sync1_reg_reg"] -datapath_only $read_clk_period
    }

    # status synchronization
    foreach i {overflow bad_frame good_frame} {
        set status_sync_regs [get_cells -quiet -hier -regexp ".*/${i}_sync\[123\]_reg_reg" -filter "PARENT == $fifo_inst"]

        if {[llength $status_sync_regs]} {
            set_property ASYNC_REG TRUE $status_sync_regs

            set_max_delay -from [get_cells "$fifo_inst/${i}_sync1_reg_reg"] -to [get_cells "$fifo_inst/${i}_sync2_reg_reg"] -datapath_only $read_clk_period
        }
    }
}
