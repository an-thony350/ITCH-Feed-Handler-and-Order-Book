# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2020-2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# reset synchronizer timing constraints

foreach inst [get_cells -hier -filter {(ORIG_REF_NAME == taxi_sync_reset || REF_NAME == taxi_sync_reset)}] {
    puts "Inserting timing constraints for taxi_sync_reset instance $inst"

    # reset synchronization
    set reset_ffs [get_cells -quiet -hier "sync_reg_reg[*]" -filter "PARENT == $inst"]

    set_false_path -to [get_pins -of_objects $reset_ffs -filter {IS_PRESET || IS_RESET}]
}
