SIM ?= verilator
TOPLEVEL_LANG = verilog

PWD := $(shell pwd)
REPO_ROOT := $(PWD)/..

TOPLEVEL ?= order_book

VERILOG_SOURCES = \
$(REPO_ROOT)/rtl/hdl_header.sv

ifeq ($(TOPLEVEL),ingress_top)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/frame_crack.sv \
$(REPO_ROOT)/rtl/mold_seq_guard.sv \
$(REPO_ROOT)/rtl/mold_deframe.sv \
$(REPO_ROOT)/rtl/realign.sv \
$(REPO_ROOT)/rtl/ingress_top.sv

MODULE ?= test_ingress

else ifeq ($(TOPLEVEL),data_handler)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/data_handler.sv

MODULE ?= test_data_handler

else ifeq ($(TOPLEVEL),order_book_top)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/symbol_router.sv \
$(REPO_ROOT)/rtl/order_book.sv \
$(REPO_ROOT)/rtl/order_book_top.sv

MODULE ?= test_order_book_top

else ifeq ($(TOPLEVEL),order_book)
VERILOG_SOURCES += \
$(REPO_ROOT)/rtl/order_book.sv

MODULE ?= test_order_book

else
$(error Unsupported TOPLEVEL=$(TOPLEVEL). Supported: data_handler, order_book, order_book_top, ingress_top)
endif

export PYTHONPATH := $(PWD):$(REPO_ROOT):$(PYTHONPATH)

EXTRA_ARGS += --sv
EXTRA_ARGS += --timing
EXTRA_ARGS += --trace
EXTRA_ARGS += --trace-structs

ifeq ($(TOPLEVEL),ingress_top)
# Keep current ingress width-lint warnings visible, but do not let them block
# the functional ingress-only test while this stage is still being hardened.
EXTRA_ARGS += -Wno-fatal
endif

# Default behaviour:
#   make                         -> run the full current repo test suite
#   make TOPLEVEL=... MODULE=... -> preserve old single-cocotb-test workflow
ifneq ($(filter command line,$(origin TOPLEVEL) $(origin MODULE)),)
.DEFAULT_GOAL := results.xml
else
.DEFAULT_GOAL := test-all
endif

.PHONY: test-all test-golden test-rtl test-data-handler test-order-book test-order-book-top test-ingress clean-all

test-all: test-golden test-rtl

test-golden:
	cd $(REPO_ROOT) && scripts/run_golden.sh

test-rtl: test-data-handler test-order-book test-order-book-top test-ingress

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

clean-all:
	$(MAKE) clean TOPLEVEL=data_handler MODULE=test_data_handler
	rm -f results.xml

include $(shell cocotb-config --makefiles)/Makefile.sim
