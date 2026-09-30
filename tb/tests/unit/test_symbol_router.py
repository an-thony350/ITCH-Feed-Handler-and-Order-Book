"""Correctness tests for symbol_router.sv.

The router should:
- route stock locates 1/2/3 to the matching order book only;
- forward the matching base price and event fields;
- drop unmapped locates and out-of-window price messages;
- honour backpressure from the selected order book;
- clear any pending output on reset.

"""

from __future__ import annotations

from typing import Any

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from itch_harness.axis import reset_dut, start_clock
from itch_harness.layout import OP_TO_MSG_TYPE, pack_decoder_data_t, unpack_o_data_t
from itch_harness.scoreboard import signal_value_to_int


BASE_PRICES = {
    1: 10_000,
    2: 20_000,
    3: 30_000,
}

BBO_WINDOW = 1 << 14
RESET_CYCLES = 5
TIMEOUT_CYCLES = 100


def make_event(
    *,
    locate: int,
    order_ref: int,
    price: int,
    shares: int = 100,
    side: str = "BUY",
    op: str = "ADD",
    new_order_ref: int | None = None,
) -> dict[str, Any]:
    """Build one normalised event for the router input."""

    return {
        "op": op,
        "locate": locate,
        "side": side,
        "order_ref": order_ref,
        "new_order_ref": new_order_ref,
        "shares": shares,
        "price": price,
    }


async def initialise(dut: Any) -> None:
    """Start the clock and reset the router with all sinks ready."""

    await start_clock(dut)

    dut.rdata_i.value = 0
    dut.valid_i.value = 0
    dut.ready_i.value = 0b1111

    dut.base_price_stock0_i.value = BASE_PRICES[1]
    dut.base_price_stock1_i.value = BASE_PRICES[2]
    dut.base_price_stock2_i.value = BASE_PRICES[3]

    await reset_dut(dut, cycles=RESET_CYCLES)
    await FallingEdge(dut.clk)

    assert current_valids(dut) == (0, 0, 0)
    assert signal_value_to_int(dut.base_price_o.value) == 0


def current_valids(dut: Any) -> tuple[int, int, int]:
    """Return the three routed valid outputs."""

    return (
        signal_value_to_int(dut.valid_stock0_o.value),
        signal_value_to_int(dut.valid_stock1_o.value),
        signal_value_to_int(dut.valid_stock2_o.value),
    )


def assert_routed_event(
    dut: Any,
    event: dict[str, Any],
    *,
    expected_stock: int,
) -> None:
    """Check the one-hot destination, base price and forwarded event fields."""

    expected_valids = [0, 0, 0]
    expected_valids[expected_stock] = 1

    assert current_valids(dut) == tuple(expected_valids), (
        f"locate={event['locate']}: wrong destination valid, "
        f"got={current_valids(dut)} expected={tuple(expected_valids)}"
    )

    expected_base = BASE_PRICES[event["locate"]]
    observed_base = signal_value_to_int(dut.base_price_o.value)
    assert observed_base == expected_base, (
        f"locate={event['locate']}: base price mismatch, "
        f"got={observed_base} expected={expected_base}"
    )

    observed = unpack_o_data_t(signal_value_to_int(dut.rdata_o.value))
    expected = {
        "message_type": OP_TO_MSG_TYPE[event["op"]],
        "orn": event["order_ref"],
        "updated_orn": event["new_order_ref"] or 0,
        "side": 1 if event["side"] == "BUY" else 0,
        "shares": event["shares"],
        "price": event["price"],
    }

    assert observed == expected, (
        f"locate={event['locate']}: routed event mismatch, "
        f"got={observed} expected={expected}"
    )


async def drive_and_capture(
    dut: Any,
    event: dict[str, Any],
    *,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> None:
    """Hold one input event until a real valid/ready handshake occurs."""

    await FallingEdge(dut.clk)
    dut.rdata_i.value = pack_decoder_data_t(event)
    dut.valid_i.value = 1

    for _ in range(timeout_cycles):
        await ReadOnly()
        ready = signal_value_to_int(dut.ready_o.value)

        await RisingEdge(dut.clk)
        if ready == 1:
            await FallingEdge(dut.clk)
            dut.valid_i.value = 0
            dut.rdata_i.value = 0
            return

        await FallingEdge(dut.clk)

    raise TimeoutError(
        f"timed out waiting for symbol_router ready_o, "
        f"locate={event['locate']} op={event['op']}"
    )


@cocotb.test()
async def test_symbol_router_routes_configured_stocks(dut: Any) -> None:
    """Locates 1/2/3 must reach only their matching book with the right base."""

    await initialise(dut)

    cases = [
        (1, 0, 101),
        (2, 1, 202),
        (3, 2, 303),
        (1, 0, 404),  # repeated traffic to the same book
    ]

    for locate, expected_stock, order_ref in cases:
        event = make_event(
            locate=locate,
            order_ref=order_ref,
            price=BASE_PRICES[locate] + 25,
        )

        await drive_and_capture(dut, event)
        assert_routed_event(
            dut,
            event,
            expected_stock=expected_stock,
        )


@cocotb.test()
async def test_symbol_router_drops_unmapped_and_out_of_window_price(dut: Any) -> None:
    """Invalid locates and price messages outside the book window must not route."""

    await initialise(dut)

    unmapped = make_event(
        locate=9,
        order_ref=501,
        price=12_345,
    )
    await drive_and_capture(dut, unmapped)
    assert current_valids(dut) == (0, 0, 0)

    below_base = make_event(
        locate=2,
        order_ref=502,
        price=BASE_PRICES[2] - 1,
    )
    await drive_and_capture(dut, below_base)
    assert current_valids(dut) == (0, 0, 0)

    above_window = make_event(
        locate=3,
        order_ref=503,
        price=BASE_PRICES[3] + BBO_WINDOW,
    )
    await drive_and_capture(dut, above_window)
    assert current_valids(dut) == (0, 0, 0)


@cocotb.test()
async def test_symbol_router_honours_selected_backpressure_and_reset(dut: Any) -> None:
    """Only the selected sink may block acceptance, and reset clears held output."""

    await initialise(dut)

    event = make_event(
        locate=2,
        order_ref=601,
        price=BASE_PRICES[2] + 10,
    )

    # Block only stock 1, which is ready_i[2].
    dut.ready_i.value = 0b1011

    await FallingEdge(dut.clk)
    dut.rdata_i.value = pack_decoder_data_t(event)
    dut.valid_i.value = 1

    for _ in range(3):
        await ReadOnly()
        assert signal_value_to_int(dut.ready_o.value) == 0
        assert current_valids(dut) == (0, 0, 0)
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

    # Release the selected book and accept the event.
    dut.ready_i.value = 0b1111
    await ReadOnly()
    assert signal_value_to_int(dut.ready_o.value) == 1
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)

    dut.valid_i.value = 0
    dut.rdata_i.value = 0
    assert_routed_event(dut, event, expected_stock=1)

    # Once routed, downstream backpressure must hold the event stable.
    held_word = signal_value_to_int(dut.rdata_o.value)
    held_base = signal_value_to_int(dut.base_price_o.value)
    dut.ready_i.value = 0b1011

    for _ in range(3):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

        assert current_valids(dut) == (0, 1, 0)
        assert signal_value_to_int(dut.rdata_o.value) == held_word
        assert signal_value_to_int(dut.base_price_o.value) == held_base

    # Reset must clear the pending routed transaction.
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)

    assert current_valids(dut) == (0, 0, 0)
    assert signal_value_to_int(dut.rdata_o.value) == 0
    assert signal_value_to_int(dut.base_price_o.value) == 0
