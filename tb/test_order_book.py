"""cocotb tests for rtl/order_book.sv."""

from __future__ import annotations

import cocotb

from itch_harness.axis import (
    drive_order_book_event,
    reset_dut,
    start_clock,
    wait_ready,
)
from itch_harness.oracle import load_oracle
from itch_harness.scoreboard import assert_bbo_matches_word


BASE_PRICE = 9000


@cocotb.test()
async def test_order_book_reset_reaches_ready(dut):
    """After reset, order_book should clear internal state and become ready."""

    await start_clock(dut)

    dut.valid_i.value = 0
    dut.rdata_i.value = 0
    dut.ready_i.value = 1
    dut.base_price.value = BASE_PRICE

    await reset_dut(dut, cycles=5)

    # HASH_W defaults to 14, so HASH_DEPTH is 16384 entries.
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


@cocotb.test()
async def test_order_book_first_add_matches_golden_bbo(dut):
    """Drive the first golden ADD event and compare the first BBO output."""

    await start_clock(dut)

    dut.valid_i.value = 0
    dut.rdata_i.value = 0
    dut.ready_i.value = 1
    dut.base_price.value = BASE_PRICE

    await reset_dut(dut, cycles=5)
    await wait_ready(dut, "ready_o", timeout_cycles=20_000)

    oracle = load_oracle()
    event = oracle.events[0]
    expected_state = oracle.states[0]

    assert event["op"] == "ADD", f"first synthetic event should be ADD, got {event}"

    dut._log.info("Driving first event: %s", event)
    dut._log.info("Expected first BBO: %s", expected_state["bbo"])

    bbo_word = await drive_order_book_event(
        dut,
        event,
        hold_valid_until_bbo=True,
        timeout_cycles=5_000,
    )

    assert bbo_word is not None
    assert_bbo_matches_word(bbo_word, expected_state)


@cocotb.test()
async def test_order_book_first_ten_events_match_golden_bbo(dut):
    """Replay a small golden prefix and compare BBO after every event."""

    await start_clock(dut)

    dut.valid_i.value = 0
    dut.rdata_i.value = 0
    dut.ready_i.value = 1
    dut.base_price.value = BASE_PRICE

    await reset_dut(dut, cycles=5)
    await wait_ready(dut, "ready_o", timeout_cycles=20_000)

    oracle = load_oracle()
    limit = min(10, oracle.count)

    dut._log.info("Replaying first %d golden events", limit)

    for index, (event, expected_state) in enumerate(
        oracle.event_state_pairs()[:limit],
        start=1,
    ):
        dut._log.info(
            "Driving oracle row %d/%d: msg_index=%s op=%s",
            index,
            limit,
            event["msg_index"],
            event["op"],
        )

        bbo_word = await drive_order_book_event(
            dut,
            event,
            hold_valid_until_bbo=True,
            timeout_cycles=5_000,
        )

        assert bbo_word is not None
        assert_bbo_matches_word(bbo_word, expected_state)

        dut._log.info(
            "Matched BBO after msg_index=%s: %s",
            expected_state["msg_index"],
            expected_state["bbo"],
        )

@cocotb.test()
async def test_order_book_full_golden_stream_matches_bbo(dut):
    """Replay the full generated golden stream and compare BBO after every event."""

    await start_clock(dut)

    dut.valid_i.value = 0
    dut.rdata_i.value = 0
    dut.ready_i.value = 1
    dut.base_price.value = BASE_PRICE

    await reset_dut(dut, cycles=5)
    await wait_ready(dut, "ready_o", timeout_cycles=20_000)

    oracle = load_oracle()

    dut._log.info("Replaying full golden stream: %d events", oracle.count)

    for index, (event, expected_state) in enumerate(
        oracle.event_state_pairs(),
        start=1,
    ):
        dut._log.info(
            "Driving oracle row %d/%d: msg_index=%s op=%s",
            index,
            oracle.count,
            event["msg_index"],
            event["op"],
        )

        bbo_word = await drive_order_book_event(
            dut,
            event,
            hold_valid_until_bbo=True,
            timeout_cycles=5_000,
        )

        assert bbo_word is not None
        assert_bbo_matches_word(bbo_word, expected_state)

    dut._log.info("Full golden stream matched: %d events", oracle.count)
