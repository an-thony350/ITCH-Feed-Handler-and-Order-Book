"""cocotb smoke tests for rtl/order_book.sv.

First target:
    - elaborate order_book.sv under Verilator
    - apply reset
    - wait for the internal CLEAR state to finish
    - check ready_o asserts

This is deliberately not the full golden-model comparison yet. The full compare
will come after the book emits a valid BBO sample pulse via bbo_valid_o.
"""

from __future__ import annotations

import cocotb

from itch_harness.axis import reset_dut, start_clock, wait_ready
from itch_harness.oracle import load_oracle


@cocotb.test()
async def test_order_book_reset_reaches_ready(dut):
    """After reset, order_book should clear internal state and become ready."""

    await start_clock(dut)

    dut.valid_i.value = 0
    dut.rdata_i.value = 0
    dut.ready_i.value = 1
    dut.base_price.value = 9000

    await reset_dut(dut, cycles=5)

    # HASH_W defaults to 14, so MAP_W is 16384 entries.
    # A correct CLEAR pass should finish just after that.
    await wait_ready(dut, "ready_o", timeout_cycles=20_000)

    assert int(dut.ready_o.value) == 1
    assert int(dut.bbo_valid_o.value) == 0


@cocotb.test()
async def test_golden_oracle_is_available(dut):
    """Check the cocotb environment can see the generated golden JSONL files."""

    oracle = load_oracle()

    assert oracle.count > 0
    assert len(oracle.events) == len(oracle.states)
    assert oracle.events[0]["msg_index"] == oracle.states[0]["msg_index"]

    dut._log.info(
        "Loaded golden oracle: %d events from %s",
        oracle.count,
        oracle.events_path,
    )
