# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

set params [dict create]

# Type of PHY on RJ-45 10/100/1000BASE-T port (GMII, RGMII, or SGMII)
dict set params BASET_PHY_TYPE "SGMII"

# Invert polarity for SFP+ cage
# KC705 rev 1.0: diff pairs to SFP+ are polarity-swapped
dict set params SFP_INVERT "1"
# KC705 rev 1.1: diff pairs to SFP+ are correct
#dict set params SFP_INVERT "0"

# apply parameters to top-level
set param_list {}
dict for {name value} $params {
    lappend param_list $name=$value
}

set_property generic $param_list [get_filesets sources_1]
