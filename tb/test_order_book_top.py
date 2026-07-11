"""cocotb golden-replay tests for order_book_top.sv.

Scope:
- Drive the 217-bit data_t boundary produced by data_handler.sv.
- Verify symbol-router locate filtering and base-price forwarding.
- Compare every emitted BBO against the matched states.jsonl oracle.

This is the G2 wrapper/book gate. It deliberately excludes data_handler and the
network ingress chain so failures remain local to symbol_router + order_book.
"""

from __future__ import annotations

from typing import Any

import cocotb
from cocotb.triggers import FallingEdge, RisingEdge

from itch_harness.axis import (
    drive_order_book_top_event,
    reset_dut,
    start_clock,
)
from itch_harness.oracle import GoldenOracle, load_oracle
from itch_harness.scoreboard import (
    assert_bbo_matches_word,
    signal_value_to_int,
)


TARGET_LOCATE = 1
BASE_PRICE = 9000

# order_book.sv currently indexes 4096 price levels using a 12-bit delta from
# base_price_i. Keep this explicit so an out-of-window oracle fails clearly
# rather than silently wrapping through RTL truncation.
PRICE_INDEX_MAX = (1 << 12) - 1

RESET_CYCLES = 5
EVENT_TIMEOUT_CYCLES = 100_000


def add_event(
    msg_index: int,
    *,
    order_ref: int,
    locate: int,
    side: str,
    shares: int,
    price: int,
) -> dict[str, Any]:
    """Build the minimal normalised ADD record required by the RTL packer."""

    return {
        "op": "ADD",
        "locate": locate,
        "side": side,
        "order_ref": order_ref,
        "price": price,
        "shares": shares,
        "new_order_ref": None,
        "msg_index": msg_index,
        "timestamp_ns": msg_index,
    }


def expected_state(
    msg_index: int,
    *,
    bid_price: int | None = None,
    bid_size: int | None = None,
    ask_price: int | None = None,
    ask_size: int | None = None,
) -> dict[str, Any]:
    """Build the BBO subset consumed by the shared scoreboard."""

    return {
        "msg_index": msg_index,
        "bbo": {
            "bid_price": bid_price,
            "bid_size": bid_size,
            "ask_price": ask_price,
            "ask_size": ask_size,
        },
    }


def validate_oracle_for_hardware_window(
    oracle: GoldenOracle,
    *,
    target_locate: int,
    base_price: int,
) -> None:
    """Reject oracle data that cannot be represented by this book instance."""

    if oracle.count == 0:
        raise AssertionError("golden oracle contains no events")

    for row, event in enumerate(oracle.events):
        locate = int(event["locate"])
        if locate != target_locate:
            raise AssertionError(
                f"oracle row {row} has locate={locate}, "
                f"expected target locate={target_locate}"
            )

        price = event.get("price")
        if price is None:
            continue

        delta = int(price) - base_price
        if not 0 <= delta <= PRICE_INDEX_MAX:
            raise AssertionError(
                f"oracle row {row} msg_index={event.get('msg_index')} "
                f"price={price} is outside the hardware window "
                f"[{base_price}, {base_price + PRICE_INDEX_MAX}]"
            )


async def initialise_order_book_top(
    dut: Any,
    *,
    target_locate: int = TARGET_LOCATE,
    base_price: int = BASE_PRICE,
) -> None:
    """Start and reset order_book_top with stable configuration inputs."""

    await start_clock(dut)

    dut.rdata_i.value = 0
    dut.valid_i.value = 0
    dut.base_price_i.value = base_price

    await reset_dut(dut, cycles=RESET_CYCLES)
    await FallingEdge(dut.clk)

    assert signal_value_to_int(dut.bbo_valid_o.value) == 0

    # Do not use ready_o here as proof that the internal book has finished its
    # table clear. With valid_i low, symbol_router intentionally drives ready_o
    # high regardless of downstream readiness. The first matching event is held
    # by drive_order_book_top_event() until the real ready handshake occurs.


async def drive_and_check(
    dut: Any,
    event: dict[str, Any],
    state: dict[str, Any],
) -> None:
    """Drive one event through the wrapper and check its resulting BBO."""

    bbo_word = await drive_order_book_top_event(
        dut,
        event,
        wait_for_bbo=True,
        timeout_cycles=EVENT_TIMEOUT_CYCLES,
    )

    assert bbo_word is not None
    assert_bbo_matches_word(bbo_word, state)


async def assert_no_extra_bbo_valid_pulses(
    dut: Any,
    *,
    cycles: int,
) -> None:
    """Prove that no additional BBO pulse occurs without another accepted event."""

    for _ in range(cycles):
        # Move beyond any expected pulse just consumed by the scoreboard, then
        # inspect the stable middle of the following cycle.
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

        assert signal_value_to_int(dut.bbo_valid_o.value) == 0, (
            "order_book_top emitted an extra/stale bbo_valid_o pulse while no "
            "new event was being driven"
        )


@cocotb.test()
async def test_order_book_top_replays_events_against_states(dut: Any) -> None:
    """Replay the complete matched event/state oracle through order_book_top."""

    oracle = load_oracle()
    validate_oracle_for_hardware_window(
        oracle,
        target_locate=TARGET_LOCATE,
        base_price=BASE_PRICE,
    )

    await initialise_order_book_top(dut)

    matched = 0
    for row, (event, state) in enumerate(oracle.event_state_pairs()):
        await drive_and_check(dut, event, state)
        matched += 1

        dut._log.info(
            "matched oracle row=%d msg_index=%s op=%s expected_bbo=%s",
            row,
            event["msg_index"],
            event["op"],
            state["bbo"],
        )

    assert matched == oracle.count
    await assert_no_extra_bbo_valid_pulses(dut, cycles=20)

    dut._log.info(
        "G2 replay passed: matched_events=%d target_locate=%d base_price=%d",
        matched,
        TARGET_LOCATE,
        BASE_PRICE,
    )


@cocotb.test()
async def test_order_book_top_drops_non_target_locate(dut: Any) -> None:
    """A non-target locate must be accepted without mutating the target book."""

    await initialise_order_book_top(dut)

    off_target_event = add_event(
        1,
        order_ref=8001,
        locate=TARGET_LOCATE + 1,
        side="BUY",
        shares=999,
        price=10010,
    )

    result = await drive_order_book_top_event(
        dut,
        off_target_event,
        wait_for_bbo=False,
        timeout_cycles=EVENT_TIMEOUT_CYCLES,
    )
    assert result is None

    await assert_no_extra_bbo_valid_pulses(dut, cycles=20)

    target_event = add_event(
        2,
        order_ref=8002,
        locate=TARGET_LOCATE,
        side="BUY",
        shares=100,
        price=10000,
    )
    target_state = expected_state(
        2,
        bid_price=10000,
        bid_size=100,
    )

    await drive_and_check(dut, target_event, target_state)
    await assert_no_extra_bbo_valid_pulses(dut, cycles=10)

    dut._log.info(
        "locate filtering passed: dropped locate=%d, accepted locate=%d",
        TARGET_LOCATE + 1,
        TARGET_LOCATE,
    )


@cocotb.test()
async def test_order_book_top_forwards_configurable_base_price(dut: Any) -> None:
    """Changing base_price_i must not change the externally reported BBO price."""

    alternate_base_price = 9500
    event_price = 10000

    assert 0 <= event_price - alternate_base_price <= PRICE_INDEX_MAX

    await initialise_order_book_top(
        dut,
        base_price=alternate_base_price,
    )

    event = add_event(
        1,
        order_ref=9001,
        locate=TARGET_LOCATE,
        side="SELL",
        shares=75,
        price=event_price,
    )
    state = expected_state(
        1,
        ask_price=event_price,
        ask_size=75,
    )

    await drive_and_check(dut, event, state)
    await assert_no_extra_bbo_valid_pulses(dut, cycles=10)

    dut._log.info(
        "base-price forwarding passed: base_price=%d event_price=%d",
        alternate_base_price,
        event_price,
    )
