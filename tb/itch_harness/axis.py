"""cocotb clock/reset/handshake helpers for ITCH RTL tests."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Any

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from .layout import pack_data_t
from .scoreboard import signal_value_to_int


async def start_clock(dut: Any, *, period_ns: int = 10) -> None:
    """Start the DUT clock.

    Usage:
        await start_clock(dut)
    """

    cocotb.start_soon(Clock(dut.clk, period_ns, unit="ns").start())


async def reset_dut(dut: Any, *, cycles: int = 5) -> None:
    """Apply an active-low reset to a DUT with clk/rst_n."""

    dut.rst_n.value = 0
    await clock_cycles(dut, cycles)
    dut.rst_n.value = 1
    await clock_cycles(dut, 1)


async def reset_order_book(dut: Any, *, cycles: int = 5) -> None:
    """Initialise and reset order_book.sv."""

    dut.valid_i.value = 0
    dut.rdata_i.value = 0
    dut.ready_i.value = 1

    await reset_dut(dut, cycles=cycles)
    await wait_ready(dut, "ready_o", timeout_cycles=100_000)


async def reset_data_handler(dut: Any, *, cycles: int = 5) -> None:
    """Initialise and reset data_handler.sv."""

    dut.s_tdata_i.value = 0
    dut.s_tvalid_i.value = 0
    dut.s_tlast_i.value = 0
    dut.ready_i.value = 1

    await reset_dut(dut, cycles=cycles)


async def clock_cycles(dut: Any, cycles: int) -> None:
    """Wait for a number of rising clock edges."""

    for _ in range(cycles):
        await RisingEdge(dut.clk)


async def wait_ready(
    dut: Any,
    signal_name: str,
    *,
    timeout_cycles: int = 10_000,
) -> None:
    """Wait until a ready-like signal is high."""

    signal = getattr(dut, signal_name)
    for _ in range(timeout_cycles):
        if signal_value_to_int(signal.value) == 1:
            return
        await RisingEdge(dut.clk)

    raise TimeoutError(f"timed out waiting for {signal_name} to assert")


async def wait_bbo_valid(
    dut: Any,
    *,
    timeout_cycles: int = 10_000,
) -> int:
    """Wait for bbo_valid_o and return the packed bbo_data_o word."""

    for _ in range(timeout_cycles):
        await RisingEdge(dut.clk)
        if signal_value_to_int(dut.bbo_valid_o.value) == 1:
            return signal_value_to_int(dut.bbo_data_o.value)

    raise TimeoutError("timed out waiting for bbo_valid_o")


async def drive_order_book_event(
    dut: Any,
    event: dict[str, Any],
    *,
    hold_valid_until_bbo: bool = False,
    timeout_cycles: int = 10_000,
) -> int | None:
    """Drive one golden event into order_book.sv.

    valid_i is asserted for exactly one accepted input handshake. The RTL should
    latch rdata_i internally and continue processing from that latched event.

    Return:
        packed bbo_data_o word if hold_valid_until_bbo is True, else None.
    """

    packed = pack_data_t(event)

    await wait_ready(dut, "ready_o", timeout_cycles=timeout_cycles)

    dut.rdata_i.value = packed
    dut.valid_i.value = 1

    await RisingEdge(dut.clk)

    dut.valid_i.value = 0
    dut.rdata_i.value = 0

    if not hold_valid_until_bbo:
        return None

    return await wait_bbo_valid(dut, timeout_cycles=timeout_cycles)

async def drive_order_book_events(
    dut: Any,
    events: Iterable[dict[str, Any]],
    *,
    timeout_cycles: int = 10_000,
) -> list[int]:
    """Drive many events into order_book.sv and collect BBO outputs."""

    bbo_words: list[int] = []
    for event in events:
        bbo_word = await drive_order_book_event(
            dut,
            event,
            hold_valid_until_bbo=True,
            timeout_cycles=timeout_cycles,
        )
        assert bbo_word is not None
        bbo_words.append(bbo_word)

    return bbo_words


def itch_payload_to_64b_words(payload: bytes | bytearray | memoryview) -> list[tuple[int, bool]]:
    """Split one ITCH payload into 64-bit big-endian words.

    Returns:
        list of ``(word, tlast)`` pairs.

    The first payload byte is placed in bits [63:56], matching data_handler.sv.
    The final word is zero-padded on the right if the payload length is not a
    multiple of 8 bytes.
    """

    data = bytes(payload)
    if not data:
        raise ValueError("cannot drive an empty ITCH payload")

    words: list[tuple[int, bool]] = []
    for offset in range(0, len(data), 8):
        chunk = data[offset : offset + 8]
        padded = chunk.ljust(8, b"\x00")
        word = int.from_bytes(padded, byteorder="big")
        tlast = offset + 8 >= len(data)
        words.append((word, tlast))

    return words


async def drive_data_handler_payload(
    dut: Any,
    payload: bytes | bytearray | memoryview,
    *,
    timeout_cycles: int = 10_000,
) -> int:
    """Drive one already-split ITCH payload into data_handler.sv.

    The payload must start at the ITCH message type byte. It must not include the
    two-byte BinaryFILE length prefix.

    Return:
        packed RTL data_t word emitted on rdata_o.
    """

    for word, tlast in itch_payload_to_64b_words(payload):
        await wait_ready(dut, "s_tready_o", timeout_cycles=timeout_cycles)

        dut.s_tdata_i.value = word
        dut.s_tlast_i.value = int(tlast)
        dut.s_tvalid_i.value = 1

        await RisingEdge(dut.clk)

        dut.s_tvalid_i.value = 0
        dut.s_tlast_i.value = 0
        dut.s_tdata_i.value = 0

    return await wait_data_handler_valid(dut, timeout_cycles=timeout_cycles)


async def wait_data_handler_valid(
    dut: Any,
    *,
    timeout_cycles: int = 10_000,
) -> int:
    """Wait for data_handler valid_o and return packed rdata_o."""

    for _ in range(timeout_cycles):
        await RisingEdge(dut.clk)
        if signal_value_to_int(dut.valid_o.value) == 1:
            return signal_value_to_int(dut.rdata_o.value)

    raise TimeoutError("timed out waiting for data_handler valid_o")
