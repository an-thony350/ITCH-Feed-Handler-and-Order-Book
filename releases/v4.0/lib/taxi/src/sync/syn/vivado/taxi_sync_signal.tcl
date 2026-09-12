# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2020-2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# signal synchronizer timing constraints

foreach inst [get_cells -hier -filter {(ORIG_REF_NAME == taxi_sync_signal || REF_NAME == taxi_sync_signal)}] {
    puts "Inserting timing constraints for taxi_sync_signal instance $inst"

    set_false_path -to [get_cells -hier "sync_reg_reg[0][*]" -filter "PARENT == $inst"]
}
