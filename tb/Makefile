SIM ?= verilator
TOPLEVEL_LANG = verilog

PWD := $(shell pwd)
REPO_ROOT := $(PWD)/..
TESTS_DIR := $(PWD)/tests
PYTHON ?= python

TOPLEVEL ?= order_book

# Performance tests take frequency in MHz so CLOCK_MHZ=100 means 100 MHz.
CLOCK_MHZ ?= 100
PERF_MODE ?= campaign
PERF_MESSAGE_COUNT ?=
PERF_PACKINGS ?=
PERF_RESULTS_DIR ?= $(REPO_ROOT)/build/perf/full_chain
PERF_COMPARE_DIR ?= $(REPO_ROOT)/build/perf/comparison

export CLOCK_MHZ
export PERF_MODE
export PERF_MESSAGE_COUNT
export PERF_PACKINGS
export PERF_RESULTS_DIR

VERILOG_SOURCES = \
$(REPO_ROOT)/rtl/hdl_header.sv

ifeq ($(TOPLEVEL),source_boundary_equiv_top)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/lane_rewire.sv \
$(REPO_ROOT)/rtl/axis_source_mux.sv \
$(REPO_ROOT)/tb/rtl/source_boundary_equiv_top.sv

MODULE ?= test_source_boundary_equiv

else ifeq ($(TOPLEVEL),axis_source_mux)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/axis_source_mux.sv

MODULE ?= test_axis_source_mux

else ifeq ($(TOPLEVEL),lane_rewire)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/lane_rewire.sv

MODULE ?= test_lane_rewire

else ifeq ($(TOPLEVEL),mold_seq_guard)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/mold_seq_guard.sv

MODULE ?= test_mold_seq_guard

else ifeq ($(TOPLEVEL),data_realign)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/data_realign.sv

MODULE ?= test_data_realign

else ifeq ($(TOPLEVEL),ingress_data_realign_top)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/frame_crack.sv \
$(REPO_ROOT)/rtl/mold_seq_guard.sv \
$(REPO_ROOT)/rtl/mold_deframe.sv \
$(REPO_ROOT)/rtl/data_realign.sv \
$(REPO_ROOT)/rtl/ingress_data_realign_top.sv

MODULE ?= test_ingress_data_realign

else ifeq ($(TOPLEVEL),ingress_data_realign_perf_probe)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/frame_crack.sv \
$(REPO_ROOT)/rtl/mold_seq_guard.sv \
$(REPO_ROOT)/rtl/mold_deframe.sv \
$(REPO_ROOT)/rtl/data_realign.sv \
$(REPO_ROOT)/rtl/ingress_data_realign_top.sv \
$(REPO_ROOT)/tb/rtl/ingress_data_realign_perf_probe.sv

MODULE ?= test_ingress_data_realign_perf

else ifeq ($(TOPLEVEL),ingress_top)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/frame_crack.sv \
$(REPO_ROOT)/rtl/mold_seq_guard.sv \
$(REPO_ROOT)/rtl/mold_deframe.sv \
$(REPO_ROOT)/rtl/realign.sv \
$(REPO_ROOT)/rtl/ingress_top.sv

MODULE ?= test_ingress

else ifeq ($(TOPLEVEL),ingress_top_perf_probe)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/frame_crack.sv \
$(REPO_ROOT)/rtl/mold_seq_guard.sv \
$(REPO_ROOT)/rtl/mold_deframe.sv \
$(REPO_ROOT)/rtl/realign.sv \
$(REPO_ROOT)/rtl/ingress_top.sv \
$(REPO_ROOT)/tb/rtl/ingress_top_perf_probe.sv

MODULE ?= test_ingress

else ifeq ($(TOPLEVEL),feed_handler_top)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/frame_crack.sv \
$(REPO_ROOT)/rtl/mold_seq_guard.sv \
$(REPO_ROOT)/rtl/mold_deframe.sv \
$(REPO_ROOT)/rtl/realign.sv \
$(REPO_ROOT)/rtl/ingress_top.sv \
$(REPO_ROOT)/rtl/data_handler.sv \
$(REPO_ROOT)/rtl/symbol_router.sv \
$(REPO_ROOT)/rtl/ob/order_book_v3.sv \
$(REPO_ROOT)/rtl/ob/ob_bram_block.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_block.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo_2.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo_3.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_1.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_2.sv \
$(REPO_ROOT)/rtl/ob/ob_replace_check.sv \
$(REPO_ROOT)/rtl/ob/ob_bbo_out.sv \
$(REPO_ROOT)/rtl/ob/ob_bbo_resolve.sv \
$(REPO_ROOT)/rtl/ob/ob_evaluate_bbo.sv \
$(REPO_ROOT)/rtl/ob/ob_idle.sv \
$(REPO_ROOT)/rtl/ob/ob_idx_req.sv \
$(REPO_ROOT)/rtl/ob/ob_idx_search.sv \
$(REPO_ROOT)/rtl/ob/ob_issue_book_read.sv \
$(REPO_ROOT)/rtl/ob/ob_update_read_book.sv \
$(REPO_ROOT)/rtl/ob/ob_update_read_tbl.sv \
$(REPO_ROOT)/rtl/ob/ob_update_write.sv \
$(REPO_ROOT)/rtl/order_book_top.sv \
$(REPO_ROOT)/rtl/feed_handler_top.sv

MODULE ?= test_feed_handler_top

else ifeq ($(TOPLEVEL),feed_handler_top_perf_probe)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/frame_crack.sv \
$(REPO_ROOT)/rtl/mold_seq_guard.sv \
$(REPO_ROOT)/rtl/mold_deframe.sv \
$(REPO_ROOT)/rtl/realign.sv \
$(REPO_ROOT)/rtl/ingress_top.sv \
$(REPO_ROOT)/rtl/data_handler.sv \
$(REPO_ROOT)/rtl/symbol_router.sv \
$(REPO_ROOT)/rtl/ob/order_book_v3.sv \
$(REPO_ROOT)/rtl/ob/ob_bram_block.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_block.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo_2.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo_3.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_1.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_2.sv \
$(REPO_ROOT)/rtl/ob/ob_replace_check.sv \
$(REPO_ROOT)/rtl/ob/ob_bbo_out.sv \
$(REPO_ROOT)/rtl/ob/ob_bbo_resolve.sv \
$(REPO_ROOT)/rtl/ob/ob_evaluate_bbo.sv \
$(REPO_ROOT)/rtl/ob/ob_idle.sv \
$(REPO_ROOT)/rtl/ob/ob_idx_req.sv \
$(REPO_ROOT)/rtl/ob/ob_idx_search.sv \
$(REPO_ROOT)/rtl/ob/ob_issue_book_read.sv \
$(REPO_ROOT)/rtl/ob/ob_update_read_book.sv \
$(REPO_ROOT)/rtl/ob/ob_update_read_tbl.sv \
$(REPO_ROOT)/rtl/ob/ob_update_write.sv \
$(REPO_ROOT)/rtl/order_book_top.sv \
$(REPO_ROOT)/rtl/feed_handler_top.sv \
$(REPO_ROOT)/tb/rtl/feed_handler_top_perf_probe.sv

MODULE ?= test_feed_handler_top

else ifeq ($(TOPLEVEL),data_handler)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/data_handler.sv

MODULE ?= test_data_handler

else ifeq ($(TOPLEVEL),order_book_top)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/symbol_router.sv \
$(REPO_ROOT)/rtl/ob/order_book_v3.sv \
$(REPO_ROOT)/rtl/ob/ob_bram_block.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_block.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo_2.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo_3.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_1.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_2.sv \
$(REPO_ROOT)/rtl/ob/ob_replace_check.sv \
$(REPO_ROOT)/rtl/ob/ob_bbo_out.sv \
$(REPO_ROOT)/rtl/ob/ob_bbo_resolve.sv \
$(REPO_ROOT)/rtl/ob/ob_evaluate_bbo.sv \
$(REPO_ROOT)/rtl/ob/ob_idle.sv \
$(REPO_ROOT)/rtl/ob/ob_idx_req.sv \
$(REPO_ROOT)/rtl/ob/ob_idx_search.sv \
$(REPO_ROOT)/rtl/ob/ob_issue_book_read.sv \
$(REPO_ROOT)/rtl/ob/ob_update_read_book.sv \
$(REPO_ROOT)/rtl/ob/ob_update_read_tbl.sv \
$(REPO_ROOT)/rtl/ob/ob_update_write.sv \
$(REPO_ROOT)/rtl/order_book_top.sv

MODULE ?= test_order_book_top

else ifeq ($(TOPLEVEL),order_book)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/ob/order_book_v3.sv \
$(REPO_ROOT)/rtl/ob/ob_bram_block.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_block.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo_2.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_bbo_3.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_1.sv \
$(REPO_ROOT)/rtl/ob/ob_uram_delay_2.sv \
$(REPO_ROOT)/rtl/ob/ob_replace_check.sv \
$(REPO_ROOT)/rtl/ob/ob_bbo_out.sv \
$(REPO_ROOT)/rtl/ob/ob_bbo_resolve.sv \
$(REPO_ROOT)/rtl/ob/ob_evaluate_bbo.sv \
$(REPO_ROOT)/rtl/ob/ob_idle.sv \
$(REPO_ROOT)/rtl/ob/ob_idx_req.sv \
$(REPO_ROOT)/rtl/ob/ob_idx_search.sv \
$(REPO_ROOT)/rtl/ob/ob_issue_book_read.sv \
$(REPO_ROOT)/rtl/ob/ob_update_read_book.sv \
$(REPO_ROOT)/rtl/ob/ob_update_read_tbl.sv \
$(REPO_ROOT)/rtl/ob/ob_update_write.sv

MODULE ?= test_order_book

else
$(error Unsupported TOPLEVEL=$(TOPLEVEL). Supported: mold_seq_guard, data_realign, data_handler, order_book, order_book_top, ingress_top, ingress_top_perf_probe, ingress_data_realign_top, ingress_data_realign_perf_probe, feed_handler_top, feed_handler_top_perf_probe)
endif

export PYTHONPATH := $(TESTS_DIR):$(PWD):$(REPO_ROOT):$(PYTHONPATH)

EXTRA_ARGS += --sv
EXTRA_ARGS += --timing
EXTRA_ARGS += --trace
EXTRA_ARGS += --trace-structs

ifneq ($(filter ingress_top ingress_top_perf_probe ingress_data_realign_top ingress_data_realign_perf_probe feed_handler_top feed_handler_top_perf_probe,$(TOPLEVEL)),)
# Keep current ingress width/lint warnings visible, but do not let them block
# functional ingress/feed-handler tests while this stage is being hardened.
EXTRA_ARGS += -Wno-fatal
endif

# Default behaviour:
#   make                         -> run the established correctness suite plus
#                                   the isolated merged-candidate gates
#   make TOPLEVEL=... MODULE=... -> preserve old single-cocotb-test workflow
ifneq ($(filter command line,$(origin TOPLEVEL) $(origin MODULE)),)
.DEFAULT_GOAL := results.xml
else
.DEFAULT_GOAL := test-all
endif

.PHONY: test-all test-golden test-rtl test-mold-seq-guard \
        test-data-realign test-data-handler \
        test-order-book test-order-book-top \
        test-ingress test-ingress-probe test-ingress-perf \
        test-ingress-data-realign test-ingress-data-realign-probe \
        test-ingress-data-realign-perf \
        test-feed-handler-top test-feed-handler-probe \
        test-feed-handler-perf perf-smoke perf-campaign perf-compare clean-all

test-all: test-golden test-rtl

test-golden:
	cd $(REPO_ROOT) && scripts/run_golden.sh

# Keep long-running performance campaigns out of the normal correctness suite.
# The merged candidate is included alongside the legacy path until integration
# is proven and the Vivado project is deliberately migrated.
test-rtl: test-mold-seq-guard test-data-realign test-data-handler \
          test-order-book test-order-book-top \
          test-ingress test-ingress-data-realign test-feed-handler-top

test-mold-seq-guard:
	$(MAKE) clean TOPLEVEL=mold_seq_guard MODULE=test_mold_seq_guard
	$(MAKE) results.xml TOPLEVEL=mold_seq_guard MODULE=test_mold_seq_guard

test-data-realign:
	$(MAKE) clean TOPLEVEL=data_realign MODULE=test_data_realign
	$(MAKE) results.xml TOPLEVEL=data_realign MODULE=test_data_realign

test-data-handler:
	$(MAKE) clean TOPLEVEL=data_handler MODULE=test_data_handler
	$(MAKE) results.xml TOPLEVEL=data_handler MODULE=test_data_handler

test-order-book:
	$(MAKE) clean TOPLEVEL=order_book MODULE=test_order_book
	$(MAKE) results.xml TOPLEVEL=order_book MODULE=test_order_book

test-order-book-top:
	$(MAKE) clean TOPLEVEL=order_book_top MODULE=test_order_book_top
	$(MAKE) results.xml TOPLEVEL=order_book_top MODULE=test_order_book_top

test-ingress:
	$(MAKE) clean TOPLEVEL=ingress_top MODULE=test_ingress
	$(MAKE) results.xml TOPLEVEL=ingress_top MODULE=test_ingress

test-ingress-probe:
	$(MAKE) clean TOPLEVEL=ingress_top_perf_probe MODULE=test_ingress
	$(MAKE) results.xml TOPLEVEL=ingress_top_perf_probe MODULE=test_ingress

test-ingress-perf:
	$(MAKE) clean TOPLEVEL=ingress_top_perf_probe MODULE=test_ingress_perf
	$(MAKE) results.xml TOPLEVEL=ingress_top_perf_probe MODULE=test_ingress_perf CLOCK_MHZ=$(CLOCK_MHZ)

test-ingress-data-realign:
	$(MAKE) clean TOPLEVEL=ingress_data_realign_top MODULE=test_ingress_data_realign
	$(MAKE) results.xml TOPLEVEL=ingress_data_realign_top MODULE=test_ingress_data_realign CLOCK_MHZ=156.25

test-ingress-data-realign-probe:
	$(MAKE) clean TOPLEVEL=ingress_data_realign_perf_probe MODULE=test_ingress_data_realign
	$(MAKE) results.xml TOPLEVEL=ingress_data_realign_perf_probe MODULE=test_ingress_data_realign CLOCK_MHZ=156.25

test-ingress-data-realign-perf:
	$(MAKE) clean TOPLEVEL=ingress_data_realign_perf_probe MODULE=test_ingress_data_realign_perf
	$(MAKE) results.xml TOPLEVEL=ingress_data_realign_perf_probe MODULE=test_ingress_data_realign_perf CLOCK_MHZ=156.25

test-feed-handler-top:
	$(MAKE) clean TOPLEVEL=feed_handler_top MODULE=test_feed_handler_top
	$(MAKE) results.xml TOPLEVEL=feed_handler_top MODULE=test_feed_handler_top

test-feed-handler-probe:
	$(MAKE) clean TOPLEVEL=feed_handler_top_perf_probe MODULE=test_feed_handler_top
	$(MAKE) results.xml TOPLEVEL=feed_handler_top_perf_probe MODULE=test_feed_handler_top

test-feed-handler-perf:
	rm -rf $(PERF_RESULTS_DIR)
	$(MAKE) clean TOPLEVEL=feed_handler_top_perf_probe MODULE=test_feed_handler_perf
	$(MAKE) results.xml TOPLEVEL=feed_handler_top_perf_probe MODULE=test_feed_handler_perf CLOCK_MHZ=$(CLOCK_MHZ) PERF_MODE=$(PERF_MODE) PERF_RESULTS_DIR=$(PERF_RESULTS_DIR)
	$(PYTHON) $(REPO_ROOT)/tools/summarise_perf.py --results-dir $(PERF_RESULTS_DIR)

perf-smoke:
	$(MAKE) test-feed-handler-perf PERF_MODE=smoke CLOCK_MHZ=$(CLOCK_MHZ) PERF_RESULTS_DIR=$(PERF_RESULTS_DIR)

perf-campaign:
	$(MAKE) test-feed-handler-perf PERF_MODE=campaign CLOCK_MHZ=$(CLOCK_MHZ) PERF_RESULTS_DIR=$(PERF_RESULTS_DIR)

perf-compare:
	@test -n "$(BASELINE)" || (echo "BASELINE is required" && exit 2)
	@test -n "$(CANDIDATE)" || (echo "CANDIDATE is required" && exit 2)
	$(PYTHON) $(REPO_ROOT)/tools/compare_perf.py --baseline $(BASELINE) --candidate $(CANDIDATE) --output-dir $(PERF_COMPARE_DIR) $(COMPARE_ARGS)

clean-all:
	$(MAKE) clean TOPLEVEL=data_realign MODULE=test_data_realign
	$(MAKE) clean TOPLEVEL=data_handler MODULE=test_data_handler
	$(MAKE) clean TOPLEVEL=ingress_data_realign_perf_probe MODULE=test_ingress_data_realign_perf
	$(MAKE) clean TOPLEVEL=ingress_top_perf_probe MODULE=test_ingress_perf
	$(MAKE) clean TOPLEVEL=feed_handler_top_perf_probe MODULE=test_feed_handler_perf
	rm -f results.xml
	rm -rf $(REPO_ROOT)/build/perf/full_chain
	rm -rf $(REPO_ROOT)/build/perf/data_realign_ingress_line_rate

include $(shell cocotb-config --makefiles)/Makefile.sim
