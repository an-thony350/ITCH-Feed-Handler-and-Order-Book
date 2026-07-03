SIM ?= verilator
TOPLEVEL_LANG = verilog

PWD := $(shell pwd)
REPO_ROOT := $(PWD)/..

VERILOG_SOURCES = \
$(REPO_ROOT)/rtl/hdl_header.sv	\
$(REPO_ROOT)/rtl/order_book.sv

TOPLEVEL ?= order_book
MODULE ?= test_order_book

export PYTHONPATH := $(PWD):$(REPO_ROOT):$(PYTHONPATH)

EXTRA_ARGS += --sv
EXTRA_ARGS += --timing
EXTRA_ARGS += --trace
EXTRA_ARGS += --trace-structs

include $(shell cocotb-config --makefiles)/Makefile.sim
