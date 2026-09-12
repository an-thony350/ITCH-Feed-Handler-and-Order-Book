# ITCH Feed Handler & Order Book - top-level simulation/test entry point
#
# Current active RTL regression only. Deprecated cocotb tests under
# tb/tests/deprecated/ are intentionally not exposed here.

SIM ?= verilator
TOPLEVEL_LANG := verilog
PYTHON ?= python

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
RTL_DIR := $(REPO_ROOT)/rtl
TB_DIR := $(REPO_ROOT)/tb
TESTS_DIR := $(TB_DIR)/tests
TB_RTL_DIR := $(TB_DIR)/rtl

# The active Ethernet/ITCH ingress is 64-bit at 156.25 MHz.
INGRESS_CLOCK_MHZ ?= 156.25
CLOCK_MHZ ?= $(INGRESS_CLOCK_MHZ)

LINE_RATE_MODE ?= campaign
LINE_RATE_EVENT_COUNT ?=
LINE_RATE_ENFORCE ?= 1
LINE_RATE_RESULTS_DIR ?= $(REPO_ROOT)/build/perf/data_realign_ingress_line_rate
INGRESS_LATENCY_RESULTS_FILE ?= $(REPO_ROOT)/build/perf/data_realign_ingress_latency.json

export CLOCK_MHZ
export LINE_RATE_MODE
export LINE_RATE_EVENT_COUNT
export LINE_RATE_ENFORCE
export LINE_RATE_RESULTS_DIR

# Keep generated simulator build output under build/, which is already gitignored.
# Leave cocotb's results file at its standard name because the test targets
# invoke `results.xml` directly.
SIM_BUILD ?= $(REPO_ROOT)/build/sim/$(TOPLEVEL)
COCOTB_RESULTS_FILE ?= results.xml

# Keep imports identical whether tests are launched locally or from CI.
export PYTHONPATH := $(TESTS_DIR):$(TB_DIR):$(REPO_ROOT):$(PYTHONPATH)

# Cocotb 2.x uses COCOTB_TEST_MODULES. Retain MODULE as a convenience for any
# existing local command lines while the repository is being cleaned up.
ifneq ($(strip $(MODULE)),)
COCOTB_TEST_MODULES := $(MODULE)
endif

TOPLEVEL ?= order_book
COCOTB_TEST_MODULES ?= test_order_book

# RTL source groups

COMMON_RTL := \
	$(RTL_DIR)/hdl_header.sv

CURRENT_INGRESS_RTL := \
	$(RTL_DIR)/frame_crack.sv \
	$(RTL_DIR)/mold_seq_guard.sv \
	$(RTL_DIR)/mold_deframe.sv \
	$(RTL_DIR)/data_realign.sv \
	$(RTL_DIR)/ingress_data_realign_top.sv

ORDER_BOOK_CORE_RTL := \
	$(RTL_DIR)/ob/order_book_v4.sv \
	$(RTL_DIR)/ob/ob_bram_block.sv \
	$(RTL_DIR)/ob/ob_uram_block.sv \
	$(RTL_DIR)/ob/ob_uram_delay_bbo.sv \
	$(RTL_DIR)/ob/ob_uram_delay_bbo_2.sv \
	$(RTL_DIR)/ob/ob_uram_delay_bbo_3.sv \
	$(RTL_DIR)/ob/ob_uram_delay_1.sv \
	$(RTL_DIR)/ob/ob_uram_delay_2.sv \
	$(RTL_DIR)/ob/ob_replace_check.sv \
	$(RTL_DIR)/ob/ob_bbo_out.sv \
	$(RTL_DIR)/ob/ob_bbo_resolve.sv \
	$(RTL_DIR)/ob/ob_evaluate_bbo.sv \
	$(RTL_DIR)/ob/ob_idle.sv \
	$(RTL_DIR)/ob/ob_idx_req.sv \
	$(RTL_DIR)/ob/ob_idx_search.sv \
	$(RTL_DIR)/ob/ob_issue_book_read.sv \
	$(RTL_DIR)/ob/ob_update_read_book.sv \
	$(RTL_DIR)/ob/ob_update_read_tbl.sv \
	$(RTL_DIR)/ob/ob_update_write.sv

ORDER_BOOK_TOP_RTL := \
	$(RTL_DIR)/symbol_router.sv \
	$(ORDER_BOOK_CORE_RTL) \
	$(RTL_DIR)/order_book_top.sv

# Cocotb DUT selection

VERILOG_SOURCES := $(COMMON_RTL)

ifeq ($(TOPLEVEL),axis_source_mux)
VERILOG_SOURCES += \
	$(RTL_DIR)/axis_source_mux.sv

else ifeq ($(TOPLEVEL),lane_rewire)
VERILOG_SOURCES += \
	$(RTL_DIR)/lane_rewire.sv

else ifeq ($(TOPLEVEL),source_boundary_equiv_top)
VERILOG_SOURCES += \
	$(RTL_DIR)/lane_rewire.sv \
	$(RTL_DIR)/axis_source_mux.sv \
	$(TB_RTL_DIR)/source_boundary_equiv_top.sv

else ifeq ($(TOPLEVEL),mold_seq_guard)
VERILOG_SOURCES += \
	$(RTL_DIR)/mold_seq_guard.sv

else ifeq ($(TOPLEVEL),data_realign)
VERILOG_SOURCES += \
	$(RTL_DIR)/data_realign.sv

else ifeq ($(TOPLEVEL),ingress_data_realign_top)
VERILOG_SOURCES += \
	$(CURRENT_INGRESS_RTL)

else ifeq ($(TOPLEVEL),ingress_data_realign_perf_probe)
VERILOG_SOURCES += \
	$(CURRENT_INGRESS_RTL) \
	$(TB_RTL_DIR)/ingress_data_realign_perf_probe.sv

else ifeq ($(TOPLEVEL),order_book)
VERILOG_SOURCES += \
	$(ORDER_BOOK_CORE_RTL)

else ifeq ($(TOPLEVEL),order_book_top)
VERILOG_SOURCES += \
	$(ORDER_BOOK_TOP_RTL)

else
$(error Unsupported TOPLEVEL=$(TOPLEVEL). Supported: axis_source_mux, lane_rewire, source_boundary_equiv_top, mold_seq_guard, data_realign, ingress_data_realign_top, ingress_data_realign_perf_probe, order_book, order_book_top)
endif

# Preserve the current Verilator setup. Tracing is useful for local failure
# diagnosis and does not change cycle-based latency/throughput measurements.
EXTRA_ARGS += --sv
EXTRA_ARGS += --timing
EXTRA_ARGS += --trace
EXTRA_ARGS += --trace-structs

# The current ingress/data_realign path still has non-fatal width/lint warnings.
# Keep them visible without allowing Verilator warnings alone to block tests.
ifneq ($(filter data_realign ingress_data_realign_top ingress_data_realign_perf_probe,$(TOPLEVEL)),)
EXTRA_ARGS += -Wno-fatal
endif

# A direct DUT/module override still behaves like the old single-test workflow:
#   make TOPLEVEL=data_realign COCOTB_TEST_MODULES=test_data_realign
ifneq ($(filter command line,$(origin TOPLEVEL) $(origin COCOTB_TEST_MODULES) $(origin MODULE)),)
.DEFAULT_GOAL := results.xml
else
.DEFAULT_GOAL := test
endif

# These simulations share generated outputs, so keep the aggregate local suite
# sequential. CI can still run individual named targets in separate jobs.
.NOTPARALLEL:

.PHONY: \
	help quality test test-golden test-rtl \
	test-axis-source-mux test-lane-rewire test-source-boundary-equiv \
	test-mold-seq-guard test-data-realign test-ingress \
	test-order-book test-order-book-top \
	perf-smoke perf-campaign perf-measure \
	perf-ingress-latency perf-ingress-line-rate-measure \
	perf-ingress-line-rate-gate perf-clean clean-all

# Aggregate targets

test: test-golden test-rtl

# Active functional RTL suite. Deprecated architectural paths are deliberately
# excluded; they remain archived under tb/tests/deprecated/.
test-rtl: \
	test-axis-source-mux \
	test-lane-rewire \
	test-source-boundary-equiv \
	test-mold-seq-guard \
	test-data-realign \
	test-ingress \
	test-order-book \
	test-order-book-top

quality:
	cd $(REPO_ROOT) && pre-commit run --all-files --show-diff-on-failure

test-golden:
	cd $(REPO_ROOT) && PYTHON="$(PYTHON)" scripts/run_golden.sh \
		--seed 7 \
		--random-message-count 25

# Active cocotb correctness tests

test-axis-source-mux:
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=axis_source_mux COCOTB_TEST_MODULES=test_axis_source_mux
	$(MAKE) -C $(REPO_ROOT) results.xml TOPLEVEL=axis_source_mux COCOTB_TEST_MODULES=test_axis_source_mux

test-lane-rewire:
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=lane_rewire COCOTB_TEST_MODULES=test_lane_rewire
	$(MAKE) -C $(REPO_ROOT) results.xml TOPLEVEL=lane_rewire COCOTB_TEST_MODULES=test_lane_rewire

test-source-boundary-equiv:
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=source_boundary_equiv_top COCOTB_TEST_MODULES=test_source_boundary_equiv
	$(MAKE) -C $(REPO_ROOT) results.xml TOPLEVEL=source_boundary_equiv_top COCOTB_TEST_MODULES=test_source_boundary_equiv

test-mold-seq-guard:
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=mold_seq_guard COCOTB_TEST_MODULES=test_mold_seq_guard
	$(MAKE) -C $(REPO_ROOT) results.xml TOPLEVEL=mold_seq_guard COCOTB_TEST_MODULES=test_mold_seq_guard

test-data-realign:
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=data_realign COCOTB_TEST_MODULES=test_data_realign
	$(MAKE) -C $(REPO_ROOT) results.xml TOPLEVEL=data_realign COCOTB_TEST_MODULES=test_data_realign

# "test-ingress" now means the current 64-bit merged ingress/decode path:
# frame_crack -> mold_deframe -> data_realign -> normalised data_t event.
test-ingress:
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=ingress_data_realign_top COCOTB_TEST_MODULES=test_ingress_data_realign
	$(MAKE) -C $(REPO_ROOT) results.xml TOPLEVEL=ingress_data_realign_top COCOTB_TEST_MODULES=test_ingress_data_realign CLOCK_MHZ=$(INGRESS_CLOCK_MHZ)

test-order-book:
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=order_book COCOTB_TEST_MODULES=test_order_book
	$(MAKE) -C $(REPO_ROOT) results.xml TOPLEVEL=order_book COCOTB_TEST_MODULES=test_order_book

test-order-book-top:
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=order_book_top COCOTB_TEST_MODULES=test_order_book_top
	$(MAKE) -C $(REPO_ROOT) results.xml TOPLEVEL=order_book_top COCOTB_TEST_MODULES=test_order_book_top

# Current ingress performance tests

# Cold-path Ethernet-frame -> normalised-event latency sweep at 156.25 MHz.
perf-ingress-latency:
	rm -f $(INGRESS_LATENCY_RESULTS_FILE)
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=ingress_data_realign_perf_probe COCOTB_TEST_MODULES=test_ingress_data_realign_perf
	$(MAKE) -C $(REPO_ROOT) results.xml \
		TOPLEVEL=ingress_data_realign_perf_probe \
		COCOTB_TEST_MODULES=test_ingress_data_realign_perf \
		CLOCK_MHZ=$(INGRESS_CLOCK_MHZ)

# Measurement-only line-rate run. Useful for experiments because it records
# failures in the report without making the cocotb test fail on the rate gate.
perf-ingress-line-rate-measure:
	rm -rf $(LINE_RATE_RESULTS_DIR)
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=ingress_data_realign_perf_probe COCOTB_TEST_MODULES=test_ingress_data_realign_line_rate
	$(MAKE) -C $(REPO_ROOT) results.xml \
		TOPLEVEL=ingress_data_realign_perf_probe \
		COCOTB_TEST_MODULES=test_ingress_data_realign_line_rate \
		CLOCK_MHZ=$(INGRESS_CLOCK_MHZ) \
		LINE_RATE_MODE=$(LINE_RATE_MODE) \
		LINE_RATE_EVENT_COUNT=$(LINE_RATE_EVENT_COUNT) \
		LINE_RATE_ENFORCE=0 \
		LINE_RATE_RESULTS_DIR=$(LINE_RATE_RESULTS_DIR)

# CI/local gate. Functional mismatches, protocol errors and insufficient
# physical-10GbE-equivalent MAC-side throughput make the test fail.
perf-ingress-line-rate-gate:
	rm -rf $(LINE_RATE_RESULTS_DIR)
	$(MAKE) -C $(REPO_ROOT) clean TOPLEVEL=ingress_data_realign_perf_probe COCOTB_TEST_MODULES=test_ingress_data_realign_line_rate
	$(MAKE) -C $(REPO_ROOT) results.xml \
		TOPLEVEL=ingress_data_realign_perf_probe \
		COCOTB_TEST_MODULES=test_ingress_data_realign_line_rate \
		CLOCK_MHZ=$(INGRESS_CLOCK_MHZ) \
		LINE_RATE_MODE=$(LINE_RATE_MODE) \
		LINE_RATE_EVENT_COUNT=$(LINE_RATE_EVENT_COUNT) \
		LINE_RATE_ENFORCE=1 \
		LINE_RATE_RESULTS_DIR=$(LINE_RATE_RESULTS_DIR)

# Quick local/current-CI performance gate.
perf-smoke: perf-ingress-latency
	$(MAKE) -C $(REPO_ROOT) perf-ingress-line-rate-gate LINE_RATE_MODE=smoke

# Full current ingress campaign.
perf-campaign: perf-ingress-latency
	$(MAKE) -C $(REPO_ROOT) perf-ingress-line-rate-gate LINE_RATE_MODE=campaign

# Explicit non-gating campaign for collecting measurements only.
perf-measure: perf-ingress-latency
	$(MAKE) -C $(REPO_ROOT) perf-ingress-line-rate-measure LINE_RATE_MODE=campaign

# Cleanup / help

perf-clean:
	rm -f $(INGRESS_LATENCY_RESULTS_FILE)
	rm -rf $(LINE_RATE_RESULTS_DIR)

clean-all:
	rm -rf $(REPO_ROOT)/build/sim
	rm -rf $(REPO_ROOT)/build/golden
	rm -rf $(REPO_ROOT)/build/perf

help:
	@printf '%s\n' \
		'Primary targets:' \
		'  make test                         Golden model + all active RTL correctness tests' \
		'  make test-golden                  Golden unit tests + deterministic oracle generation' \
		'  make test-rtl                     All active cocotb RTL correctness tests' \
		'  make quality                      Run pre-commit repository checks' \
		'' \
		'Individual RTL targets:' \
		'  make test-axis-source-mux' \
		'  make test-lane-rewire' \
		'  make test-source-boundary-equiv' \
		'  make test-mold-seq-guard' \
		'  make test-data-realign' \
		'  make test-ingress                 Current 64-bit merged ingress/decode path' \
		'  make test-order-book' \
		'  make test-order-book-top' \
		'' \
		'Performance targets:' \
		'  make perf-smoke                   Latency sweep + short enforced line-rate gate' \
		'  make perf-campaign                Latency sweep + full enforced line-rate gate' \
		'  make perf-measure                 Full non-gating ingress measurement campaign' \
		'  make perf-ingress-latency' \
		'  make perf-ingress-line-rate-gate' \
		'' \
		'Useful overrides:' \
		'  SIM=verilator' \
		'  INGRESS_CLOCK_MHZ=156.25' \
		'  LINE_RATE_MODE=smoke|campaign' \
		'  LINE_RATE_EVENT_COUNT=<count>' \
		'' \
		'Direct cocotb run:' \
		'  make TOPLEVEL=data_realign COCOTB_TEST_MODULES=test_data_realign'

# Only load cocotb's simulator Makefile when this invocation actually needs a
# simulator. This keeps non-simulation targets such as `quality`,
# `test-golden` and `help` usable without Verilator installed.
COCOTB_MAKE_GOALS := results.xml clean debug

ifneq ($(filter $(COCOTB_MAKE_GOALS),$(MAKECMDGOALS)),)
include $(shell cocotb-config --makefiles)/Makefile.sim
else ifneq ($(filter command line,$(origin TOPLEVEL) $(origin COCOTB_TEST_MODULES) $(origin MODULE)),)
include $(shell cocotb-config --makefiles)/Makefile.sim
endif
