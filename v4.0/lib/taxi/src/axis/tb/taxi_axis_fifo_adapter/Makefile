# SPDX-License-Identifier: CERN-OHL-S-2.0
#
# Copyright (c) 2021-2025 FPGA Ninja, LLC
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

DUT      = taxi_axis_fifo_adapter
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
export PARAM_S_DATA_W := 8
export PARAM_S_KEEP_EN := $(shell echo $$(( $(PARAM_S_DATA_W) > 8 )))
export PARAM_S_KEEP_W := $(shell echo $$(( ( $(PARAM_S_DATA_W) + 7 ) / 8 )))
export PARAM_S_STRB_EN := 0
export PARAM_M_DATA_W := 8
export PARAM_M_KEEP_EN := $(shell echo $$(( $(PARAM_M_DATA_W) > 8 )))
export PARAM_M_KEEP_W := $(shell echo $$(( ( $(PARAM_M_DATA_W) + 7 ) / 8 )))
export PARAM_M_STRB_EN := $(PARAM_S_STRB_EN)
export PARAM_DEPTH := $(shell echo $$(( 1024 * ($(PARAM_S_KEEP_W) > $(PARAM_M_KEEP_W) ? $(PARAM_S_KEEP_W) : $(PARAM_M_KEEP_W)) )))
export PARAM_ID_EN := 1
export PARAM_ID_W := 8
export PARAM_DEST_EN := 1
export PARAM_DEST_W := 8
export PARAM_USER_EN := 1
export PARAM_USER_W := 1
export PARAM_RAM_PIPELINE := 1
export PARAM_OUTPUT_FIFO_EN := 0
export PARAM_FRAME_FIFO := 1
export PARAM_USER_BAD_FRAME_VALUE := 1
export PARAM_USER_BAD_FRAME_MASK := 1
export PARAM_DROP_OVERSIZE_FRAME := $(PARAM_FRAME_FIFO)
export PARAM_DROP_BAD_FRAME := $(PARAM_DROP_OVERSIZE_FRAME)
export PARAM_DROP_WHEN_FULL := 0
export PARAM_MARK_WHEN_FULL := 0
export PARAM_PAUSE_EN := 1
export PARAM_FRAME_PAUSE := 1

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
