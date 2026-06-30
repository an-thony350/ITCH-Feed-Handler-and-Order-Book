"""cocotb tests for order_book.sv."""

from __future__ import annotations

import random
from typing import Any

import cocotb
from cocotb.triggers import RisingEdge

from golden.contracts import NormalisedEvent, Op, Side
from golden.order_book import OrderBook
from itch_harness.axis import (
    clock_cycles,
    drive_order_book_event,
    reset_dut,
    start_clock,
    wait_ready,
)
from itch_harness.oracle import load_oracle
from itch_harness.scoreboard import assert_bbo_matches_word, signal_value_to_int


BASE_PRICE = 9000
LOCATE = 1


# Event / expected-state helpers


def add_event(
    msg_index: int,
    *,
    order_ref: int,
    side: str,
    shares: int,
    price: int,
    locate: int = LOCATE,
) -> dict[str, Any]:
    return {
        "op": "ADD",
        "locate": locate,
        "side": side,
        "order_ref": order_ref,
        "price": price,
        "shares": shares,
        "msg_index": msg_index,
        "timestamp_ns": msg_index * 100,
    }


def execute_event(
    msg_index: int,
    *,
    order_ref: int,
    shares: int,
    locate: int = LOCATE,
) -> dict[str, Any]:
    return {
        "op": "EXECUTE",
        "locate": locate,
        "side": "UNKNOWN",
        "order_ref": order_ref,
        "price": None,
        "shares": shares,
        "msg_index": msg_index,
        "timestamp_ns": msg_index * 100,
    }


def cancel_event(
    msg_index: int,
    *,
    order_ref: int,
    shares: int,
    locate: int = LOCATE,
) -> dict[str, Any]:
    return {
        "op": "CANCEL",
        "locate": locate,
        "side": "UNKNOWN",
        "order_ref": order_ref,
        "price": None,
        "shares": shares,
        "msg_index": msg_index,
        "timestamp_ns": msg_index * 100,
    }


def delete_event(
    msg_index: int,
    *,
    order_ref: int,
    locate: int = LOCATE,
) -> dict[str, Any]:
    return {
        "op": "DELETE",
        "locate": locate,
        "side": "UNKNOWN",
        "order_ref": order_ref,
        "price": None,
        "shares": None,
        "msg_index": msg_index,
        "timestamp_ns": msg_index * 100,
    }


def replace_event(
    msg_index: int,
    *,
    order_ref: int,
    new_order_ref: int,
    shares: int,
    price: int,
    locate: int = LOCATE,
) -> dict[str, Any]:
    return {
        "op": "REPLACE",
        "locate": locate,
        "side": "UNKNOWN",
        "order_ref": order_ref,
        "new_order_ref": new_order_ref,
        "price": price,
        "shares": shares,
        "msg_index": msg_index,
        "timestamp_ns": msg_index * 100,
    }


def expected_state(
    msg_index: int,
    *,
    bid_price: int | None = None,
    bid_size: int | None = None,
    ask_price: int | None = None,
    ask_size: int | None = None,
) -> dict[str, Any]:
    return {
        "msg_index": msg_index,
        "bbo": {
            "bid_price": bid_price,
            "bid_size": bid_size,
            "ask_price": ask_price,
            "ask_size": ask_size,
        },
    }


def event_to_normalised(event: dict[str, Any]) -> NormalisedEvent:
    return NormalisedEvent(
        op=Op(event["op"]),
        locate=event["locate"],
        side=Side(event["side"]),
        order_ref=event["order_ref"],
        msg_index=event["msg_index"],
        price=event.get("price"),
        shares=event.get("shares"),
        new_order_ref=event.get("new_order_ref"),
        timestamp_ns=event.get("timestamp_ns"),
    )


def snapshot_to_expected_state(snapshot: Any) -> dict[str, Any]:
    return {
        "msg_index": snapshot.msg_index,
        "bbo": {
            "bid_price": snapshot.bbo.bid_price,
            "bid_size": snapshot.bbo.bid_size,
            "ask_price": snapshot.bbo.ask_price,
            "ask_size": snapshot.bbo.ask_size,
        },
    }


async def initialise_order_book(dut: Any) -> None:
    await start_clock(dut)

    dut.valid_i.value = 0
    dut.rdata_i.value = 0
    dut.ready_i.value = 1
    dut.base_price_i.value = BASE_PRICE

    await reset_dut(dut, cycles=5)
    await wait_ready(dut, "ready_o", timeout_cycles=100_000)


async def drive_and_check(
    dut: Any,
    event: dict[str, Any],
    state: dict[str, Any],
    *,
    timeout_cycles: int = 20_000,
) -> None:
    bbo_word = await drive_order_book_event(
        dut,
        event,
        hold_valid_until_bbo=True,
        timeout_cycles=timeout_cycles,
    )

    assert bbo_word is not None
    assert_bbo_matches_word(bbo_word, state)

    dut._log.info(
        "matched msg_index=%s op=%s expected_bbo=%s",
        event["msg_index"],
        event["op"],
        state["bbo"],
    )


async def drive_sequence_with_hand_expected(
    dut: Any,
    events: list[dict[str, Any]],
    states: list[dict[str, Any]],
) -> None:
    assert len(events) == len(states)

    await initialise_order_book(dut)

    for event, state in zip(events, states):
        await drive_and_check(dut, event, state)


async def drive_sequence_against_python_golden(
    dut: Any,
    events: list[dict[str, Any]],
) -> None:
    await initialise_order_book(dut)

    book = OrderBook(expected_locate=LOCATE)

    for event in events:
        normalised = event_to_normalised(event)
        book.apply(normalised)

        expected = snapshot_to_expected_state(book.snapshot(event["msg_index"]))
        await drive_and_check(dut, event, expected)


async def assert_no_extra_bbo_valid_pulses(
    dut: Any,
    *,
    cycles: int = 20,
) -> None:
    for _ in range(cycles):
        await RisingEdge(dut.clk)
        assert signal_value_to_int(dut.bbo_valid_o.value) == 0, (
            "bbo_valid_o produced an extra/stale pulse while no new event "
            "was being driven"
        )


# Basic smoke / handshake tests


@cocotb.test()
async def test_order_book_reset_reaches_ready(dut: Any) -> None:
    await initialise_order_book(dut)

    assert signal_value_to_int(dut.ready_o.value) == 1
    assert signal_value_to_int(dut.bbo_valid_o.value) == 0


@cocotb.test()
async def test_order_book_single_add_matches_expected_bbo(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10000),
    ]
    states = [
        expected_state(1, bid_price=10000, bid_size=100),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


@cocotb.test()
async def test_order_book_bbo_valid_is_not_sticky(dut: Any) -> None:
    await initialise_order_book(dut)

    await drive_and_check(
        dut,
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10000),
        expected_state(1, bid_price=10000, bid_size=100),
    )

    await assert_no_extra_bbo_valid_pulses(dut, cycles=20)


# ADD / BBO priority behaviour


@cocotb.test()
async def test_order_book_adds_update_best_bid_and_best_ask(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10000),
        add_event(2, order_ref=1002, side="BUY", shares=50, price=10005),
        add_event(3, order_ref=1003, side="SELL", shares=70, price=10020),
        add_event(4, order_ref=1004, side="SELL", shares=30, price=10015),
    ]

    states = [
        expected_state(1, bid_price=10000, bid_size=100),
        expected_state(2, bid_price=10005, bid_size=50),
        expected_state(3, bid_price=10005, bid_size=50, ask_price=10020, ask_size=70),
        expected_state(4, bid_price=10005, bid_size=50, ask_price=10015, ask_size=30),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


@cocotb.test()
async def test_order_book_same_price_adds_aggregate_shares(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10000),
        add_event(2, order_ref=1002, side="BUY", shares=40, price=10000),
        execute_event(3, order_ref=1001, shares=30),
        cancel_event(4, order_ref=1002, shares=10),
    ]

    states = [
        expected_state(1, bid_price=10000, bid_size=100),
        expected_state(2, bid_price=10000, bid_size=140),
        expected_state(3, bid_price=10000, bid_size=110),
        expected_state(4, bid_price=10000, bid_size=100),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


# EXECUTE / CANCEL / DELETE lifecycle tests


@cocotb.test()
async def test_order_book_partial_execute_then_second_execute_is_cumulative(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10000),
        execute_event(2, order_ref=1001, shares=30),
        execute_event(3, order_ref=1001, shares=20),
    ]

    states = [
        expected_state(1, bid_price=10000, bid_size=100),
        expected_state(2, bid_price=10000, bid_size=70),
        expected_state(3, bid_price=10000, bid_size=50),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


@cocotb.test()
async def test_order_book_full_execute_best_bid_drops_to_next_level(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10005),
        add_event(2, order_ref=1002, side="BUY", shares=200, price=10000),
        execute_event(3, order_ref=1001, shares=100),
    ]

    states = [
        expected_state(1, bid_price=10005, bid_size=100),
        expected_state(2, bid_price=10005, bid_size=100),
        expected_state(3, bid_price=10000, bid_size=200),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


@cocotb.test()
async def test_order_book_cancel_to_zero_best_bid_drops_to_next_level(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10005),
        add_event(2, order_ref=1002, side="BUY", shares=50, price=10000),
        cancel_event(3, order_ref=1001, shares=100),
    ]

    states = [
        expected_state(1, bid_price=10005, bid_size=100),
        expected_state(2, bid_price=10005, bid_size=100),
        expected_state(3, bid_price=10000, bid_size=50),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


@cocotb.test()
async def test_order_book_delete_best_ask_drops_to_next_level(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="SELL", shares=100, price=10020),
        add_event(2, order_ref=1002, side="SELL", shares=50, price=10015),
        delete_event(3, order_ref=1002),
    ]

    states = [
        expected_state(1, ask_price=10020, ask_size=100),
        expected_state(2, ask_price=10015, ask_size=50),
        expected_state(3, ask_price=10020, ask_size=100),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


# REPLACE behaviour


@cocotb.test()
async def test_order_book_replace_moves_bid_to_new_ref_new_price(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10000),
        replace_event(2, order_ref=1001, new_order_ref=2001, shares=50, price=10010),
        cancel_event(3, order_ref=2001, shares=20),
    ]

    states = [
        expected_state(1, bid_price=10000, bid_size=100),
        expected_state(2, bid_price=10010, bid_size=50),
        expected_state(3, bid_price=10010, bid_size=30),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


@cocotb.test()
async def test_order_book_replace_inherits_original_sell_side(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="SELL", shares=100, price=10020),
        replace_event(2, order_ref=1001, new_order_ref=2001, shares=60, price=10015),
    ]

    states = [
        expected_state(1, ask_price=10020, ask_size=100),
        expected_state(2, ask_price=10015, ask_size=60),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


@cocotb.test()
async def test_order_book_replace_only_order_same_price_changes_size(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10000),
        replace_event(2, order_ref=1001, new_order_ref=2001, shares=30, price=10000),
    ]

    states = [
        expected_state(1, bid_price=10000, bid_size=100),
        expected_state(2, bid_price=10000, bid_size=30),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


@cocotb.test()
async def test_order_book_replace_same_ref_same_price_changes_size(dut: Any) -> None:
    events = [
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10000),
        replace_event(2, order_ref=1001, new_order_ref=1001, shares=75, price=10000),
        execute_event(3, order_ref=1001, shares=25),
    ]

    states = [
        expected_state(1, bid_price=10000, bid_size=100),
        expected_state(2, bid_price=10000, bid_size=75),
        expected_state(3, bid_price=10000, bid_size=50),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


# Hash collision / linked-list behaviour


@cocotb.test()
async def test_order_book_same_hash_collision_insert_lookup_delete(dut: Any) -> None:
    """Two different refs with the same XOR hash should both be reachable.

    With the current hash function:
      ref 1       hashes to 1
      ref 1<<14   also hashes to 1
    """

    colliding_ref_a = 1
    colliding_ref_b = 1 << 14

    events = [
        add_event(1, order_ref=colliding_ref_a, side="BUY", shares=100, price=10000),
        add_event(2, order_ref=colliding_ref_b, side="BUY", shares=40, price=10005),
        delete_event(3, order_ref=colliding_ref_b),
        execute_event(4, order_ref=colliding_ref_a, shares=25),
    ]

    states = [
        expected_state(1, bid_price=10000, bid_size=100),
        expected_state(2, bid_price=10005, bid_size=40),
        expected_state(3, bid_price=10000, bid_size=100),
        expected_state(4, bid_price=10000, bid_size=75),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


# Side-independence test


@cocotb.test()
async def test_order_book_locked_book_same_price_keeps_bid_and_ask_sizes_independent(
    dut: Any,
) -> None:
    """Bid and ask at the same price must not share aggregate-size storage.

    This intentionally catches the design bug where one shared price_book array is
    used for both sides. Correct hardware needs separate bid/ask level storage or
    a side-tagged level structure.
    """

    events = [
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10000),
        add_event(2, order_ref=1002, side="SELL", shares=70, price=10000),
    ]

    states = [
        expected_state(1, bid_price=10000, bid_size=100),
        expected_state(
            2,
            bid_price=10000,
            bid_size=100,
            ask_price=10000,
            ask_size=70,
        ),
    ]

    await drive_sequence_with_hand_expected(dut, events, states)


# ready_i backpressure


@cocotb.test()
async def test_order_book_holds_done_when_downstream_not_ready(dut: Any) -> None:
    await initialise_order_book(dut)

    dut.ready_i.value = 0

    bbo_word = await drive_order_book_event(
        dut,
        add_event(1, order_ref=1001, side="BUY", shares=100, price=10000),
        hold_valid_until_bbo=True,
        timeout_cycles=20_000,
    )

    assert bbo_word is not None
    assert_bbo_matches_word(
        bbo_word,
        expected_state(1, bid_price=10000, bid_size=100),
    )

    await clock_cycles(dut, 5)
    assert signal_value_to_int(dut.ready_o.value) == 0, (
        "order_book should not accept a new input while downstream ready_i is low"
    )

    dut.ready_i.value = 1
    await wait_ready(dut, "ready_o", timeout_cycles=20_000)


# Generated oracle replay


@cocotb.test()
async def test_order_book_first_ten_oracle_events_match_golden_bbo(dut: Any) -> None:
    await initialise_order_book(dut)

    oracle = load_oracle()
    limit = min(10, len(oracle.events))

    for event, state in zip(oracle.events[:limit], oracle.states[:limit]):
        await drive_and_check(dut, event, state)


@cocotb.test()
async def test_order_book_full_generated_oracle_matches_golden_bbo(dut: Any) -> None:
    await initialise_order_book(dut)

    oracle = load_oracle()

    for event, state in zip(oracle.events, oracle.states):
        await drive_and_check(dut, event, state)


# Deterministic valid-random stream


def make_random_valid_events(
    *,
    seed: int,
    count: int,
) -> list[dict[str, Any]]:
    rng = random.Random(seed)

    events: list[dict[str, Any]] = []
    live: dict[int, dict[str, Any]] = {}
    next_ref = 10_000

    def fresh_ref() -> int:
        nonlocal next_ref
        ref = next_ref
        next_ref += 1
        return ref

    for msg_index in range(1, count + 1):
        legal_ops = ["ADD"]
        if live:
            legal_ops.extend(["EXECUTE", "CANCEL", "DELETE", "REPLACE"])

        op = rng.choice(legal_ops)

        if op == "ADD":
            ref = fresh_ref()
            side = rng.choice(["BUY", "SELL"])

            # Keep bid/ask price ranges separated in this fuzz test so this
            # stream exercises lifecycle logic without intentionally triggering
            # the same-price bid/ask shared-level bug.
            price = rng.randint(10000, 10020) if side == "BUY" else rng.randint(10050, 10070)
            shares = rng.randint(10, 100)

            live[ref] = {
                "side": side,
                "price": price,
                "shares": shares,
            }
            events.append(
                add_event(
                    msg_index,
                    order_ref=ref,
                    side=side,
                    shares=shares,
                    price=price,
                )
            )
            continue

        ref = rng.choice(list(live))
        record = live[ref]

        if op in ("EXECUTE", "CANCEL"):
            shares = rng.randint(1, record["shares"])
            if op == "EXECUTE":
                events.append(execute_event(msg_index, order_ref=ref, shares=shares))
            else:
                events.append(cancel_event(msg_index, order_ref=ref, shares=shares))

            record["shares"] -= shares
            if record["shares"] == 0:
                del live[ref]
            continue

        if op == "DELETE":
            events.append(delete_event(msg_index, order_ref=ref))
            del live[ref]
            continue

        if op == "REPLACE":
            same_ref = rng.random() < 0.20
            new_ref = ref if same_ref else fresh_ref()
            side = record["side"]
            price = rng.randint(10000, 10020) if side == "BUY" else rng.randint(10050, 10070)
            shares = rng.randint(10, 100)

            events.append(
                replace_event(
                    msg_index,
                    order_ref=ref,
                    new_order_ref=new_ref,
                    shares=shares,
                    price=price,
                )
            )

            del live[ref]
            live[new_ref] = {
                "side": side,
                "price": price,
                "shares": shares,
            }
            continue

        raise AssertionError(f"unhandled generated op {op}")

    return events


@cocotb.test()
async def test_order_book_random_valid_stream_matches_python_golden(dut: Any) -> None:
    events = make_random_valid_events(seed=12345, count=75)
    await drive_sequence_against_python_golden(dut, events)
