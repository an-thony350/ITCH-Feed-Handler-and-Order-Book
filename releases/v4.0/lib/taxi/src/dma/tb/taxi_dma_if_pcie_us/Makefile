# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2020-2025 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich

TOPLEVEL_LANG = verilog

SIM ?= verilator
WAVES ?= 0

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

RTL_DIR = ../../rtl
LIB_DIR = ../../lib
TAXI_SRC_DIR = $(LIB_DIR)/taxi/src

DUT      = taxi_dma_if_pcie_us
COCOTB_TEST_MODULES = test_$(DUT)
COCOTB_TOPLEVEL     = test_$(DUT)
MODULE   = $(COCOTB_TEST_MODULES)
TOPLEVEL = $(COCOTB_TOPLEVEL)
VERILOG_SOURCES += $(COCOTB_TOPLEVEL).sv
VERILOG_SOURCES += $(RTL_DIR)/$(DUT).f

# handle file list files
process_f_file = $(call process_f_files,$(addprefix $(dir $1),$(shell cat $1)))
process_f_files = $(foreach f,$1,$(if $(filter %.f,$f),$(call process_f_file,$f),$f))
uniq_base = $(if $1,$(call uniq_base,$(foreach f,$1,$(if $(filter-out $(notdir $(lastword $1)),$(notdir $f)),$f,))) $(lastword $1))
VERILOG_SOURCES := $(call uniq_base,$(call process_f_files,$(VERILOG_SOURCES)))

# module parameters
export PARAM_AXIS_PCIE_DATA_W := 64
export PARAM_AXIS_PCIE_KEEP_W := $(shell expr $(PARAM_AXIS_PCIE_DATA_W) / 32 )
export PARAM_AXIS_PCIE_RQ_USER_W := $(if $(filter-out 512,$(PARAM_AXIS_PCIE_DATA_W)),62,137)
export PARAM_AXIS_PCIE_RC_USER_W := $(if $(filter-out 512,$(PARAM_AXIS_PCIE_DATA_W)),75,161)
export PARAM_RQ_SEQ_NUM_W := $(if $(filter-out 60,$(PARAM_AXIS_PCIE_RQ_USER_W)),6,4)
export PARAM_RQ_SEQ_NUM_EN := 1
export PARAM_RAM_SEL_W := 2
export PARAM_RAM_ADDR_W := 16
export PARAM_RAM_SEGS := $(shell python -c "print(max(2, $(PARAM_AXIS_PCIE_DATA_W) * 2 // 128))")
export PARAM_PCIE_TAG_CNT := $(if $(filter-out 60,$(PARAM_AXIS_PCIE_RQ_USER_W)),256,64)
export PARAM_IMM_EN := 1
export PARAM_IMM_W := $(PARAM_AXIS_PCIE_DATA_W)
export PARAM_LEN_W := 20
export PARAM_TAG_W := 8
export PARAM_RD_OP_TBL_SIZE := $(PARAM_PCIE_TAG_CNT)
export PARAM_RD_TX_LIMIT := $(shell echo "$$(( 1 << ($(PARAM_RQ_SEQ_NUM_W)-1) ))" )
export PARAM_RD_TX_FC_EN := 1
export PARAM_RD_CPLH_FC_LIMIT := 512
export PARAM_RD_CPLD_FC_LIMIT := $(shell expr $(PARAM_RD_CPLH_FC_LIMIT) \* 4 )
export PARAM_WR_OP_TBL_SIZE := $(shell echo "$$(( 1 << ($(PARAM_RQ_SEQ_NUM_W)-1) ))" )
export PARAM_WR_TX_LIMIT := $(shell echo "$$(( 1 << ($(PARAM_RQ_SEQ_NUM_W)-1) ))" )
export PARAM_WR_TX_FC_EN := 1

ifeq ($(SIM), icarus)
	PLUSARGS += -fst

	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-P $(COCOTB_TOPLEVEL).$(subst PARAM_,,$(v))=$($(v)))
else ifeq ($(SIM), verilator)
	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-G$(subst PARAM_,,$(v))=$($(v)))

	ifeq ($(WAVES), 1)
		COMPILE_ARGS += --trace-fst
		VERILATOR_TRACE = 1
	endif
endif

include $(shell cocotb-config --makefiles)/Makefile.sim
