"""cocotb clock/reset/handshake helpers for ITCH RTL tests."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Any

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from .layout import pack_data_t, pack_decoder_data_t
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


def itch_payload_to_words(
    payload: bytes | bytearray | memoryview,
    *,
    word_bytes: int,
) -> list[tuple[int, bool]]:
    """Split one ITCH payload into fixed-width big-endian words.

    Returns:
        list of ``(word, tlast)`` pairs.

    The first payload byte is placed in the most-significant byte lane, matching
    the byte ordering used by data_handler.sv. The final word is zero-padded on
    the right when the payload length is not a multiple of ``word_bytes``.
    """

    if word_bytes <= 0:
        raise ValueError(f"word_bytes must be positive, got {word_bytes}")

    data = bytes(payload)
    if not data:
        raise ValueError("cannot drive an empty ITCH payload")

    words: list[tuple[int, bool]] = []
    for offset in range(0, len(data), word_bytes):
        chunk = data[offset : offset + word_bytes]
        padded = chunk.ljust(word_bytes, b"\x00")
        word = int.from_bytes(padded, byteorder="big")
        tlast = offset + word_bytes >= len(data)
        words.append((word, tlast))

    return words


def itch_payload_to_64b_words(
    payload: bytes | bytearray | memoryview,
) -> list[tuple[int, bool]]:
    """Compatibility wrapper for callers that explicitly require 64-bit words."""

    return itch_payload_to_words(payload, word_bytes=8)


async def drive_data_handler_payload(
    dut: Any,
    payload: bytes | bytearray | memoryview,
    *,
    wait_for_output: bool = True,
    timeout_cycles: int = 10_000,
) -> int | None:
    """Drive one already-split ITCH payload into data_handler.sv.

    The payload must start at the ITCH message type byte. It must not include the
    two-byte BinaryFILE length prefix.

    Each beat is changed on a falling edge and held through the following rising
    edge. Sampling ``s_tready_o`` before that rising edge removes delta-cycle
    ambiguity about whether the beat was accepted.

    Return:
        packed RTL data_t word when ``wait_for_output`` is True, otherwise None.
    """

    input_width_bits = len(dut.s_tdata_i)
    if input_width_bits % 8 != 0:
        raise ValueError(
            f"s_tdata_i width must be byte-aligned, got {input_width_bits} bits"
        )

    words = itch_payload_to_words(
        payload,
        word_bytes=input_width_bits // 8,
    )

    for word, tlast in words:
        accepted = False

        for _ in range(timeout_cycles):
            await FallingEdge(dut.clk)

            dut.s_tdata_i.value = word
            dut.s_tlast_i.value = int(tlast)
            dut.s_tvalid_i.value = 1

            ready_before_edge = signal_value_to_int(dut.s_tready_o.value)
            await RisingEdge(dut.clk)

            if ready_before_edge == 1:
                accepted = True
                break

        if not accepted:
            raise TimeoutError("timed out waiting for s_tready_o during payload")

    # Remove the final beat away from the active sampling edge. This also allows
    # the post-handshake SEND/IDLE state outputs to settle before the caller
    # observes valid_o or starts the next message.
    await FallingEdge(dut.clk)
    dut.s_tvalid_i.value = 0
    dut.s_tlast_i.value = 0
    dut.s_tdata_i.value = 0

    if not wait_for_output:
        return None

    return await wait_data_handler_valid(dut, timeout_cycles=timeout_cycles)


async def wait_data_handler_valid(
    dut: Any,
    *,
    timeout_cycles: int = 10_000,
) -> int:
    """Wait for data_handler valid_o and return the packed rdata_o word."""

    for _ in range(timeout_cycles):
        # ReadOnly samples the fully-settled value for the current clock cycle.
        # Checking before the next RisingEdge is important because SEND may be
        # consumed on that edge when ready_i is already high.
        await ReadOnly()
        if signal_value_to_int(dut.valid_o.value) == 1:
            return signal_value_to_int(dut.rdata_o.value)
        await RisingEdge(dut.clk)

    raise TimeoutError("timed out waiting for data_handler valid_o")


async def drive_order_book_top_event(
    dut: Any,
    event: dict[str, Any],
    *,
    wait_for_bbo: bool = True,
    timeout_cycles: int = 100_000,
) -> int | None:
    """Drive one golden event into order_book_top.sv.

    ``order_book_top.ready_o`` depends on ``valid_i`` because the symbol router
    accepts non-matching locates immediately while applying downstream
    backpressure to matching events. Therefore this driver asserts valid first,
    then holds the packed 217-bit data_t stable until a real valid/ready
    handshake occurs.

    Return:
        packed bbo_data_o word when ``wait_for_bbo`` is True, otherwise None.
    """

    packed = pack_decoder_data_t(event)

    if len(dut.rdata_i) != 217:
        raise ValueError(
            f"order_book_top.rdata_i must be 217 bits, got {len(dut.rdata_i)}"
        )

    await FallingEdge(dut.clk)

    dut.rdata_i.value = packed
    dut.valid_i.value = 1

    accepted = False
    for _ in range(timeout_cycles):
        # The event is already stable from the falling edge. ReadOnly allows the
        # combinational router ready path to settle before the active edge.
        await ReadOnly()
        ready_before_edge = signal_value_to_int(dut.ready_o.value)

        await RisingEdge(dut.clk)

        if ready_before_edge == 1:
            accepted = True
            break

        await FallingEdge(dut.clk)

    if not accepted:
        raise TimeoutError(
            "timed out waiting for order_book_top ready_o with valid_i asserted"
        )

    # Remove the accepted event away from the active sampling edge.
    await FallingEdge(dut.clk)
    dut.valid_i.value = 0
    dut.rdata_i.value = 0

    if not wait_for_bbo:
        return None

    return await wait_order_book_top_bbo(
        dut,
        timeout_cycles=timeout_cycles,
    )


async def wait_order_book_top_bbo(
    dut: Any,
    *,
    timeout_cycles: int = 100_000,
) -> int:
    """Wait for order_book_top bbo_valid_o and return bbo_data_o.

    Sampling on the falling half-cycle avoids delta-cycle races with the
    order-book FSM's registered EMIT pulse.
    """

    for _ in range(timeout_cycles):
        await ReadOnly()
        if signal_value_to_int(dut.bbo_valid_o.value) == 1:
            return signal_value_to_int(dut.bbo_data_o.value)

        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

    raise TimeoutError("timed out waiting for order_book_top bbo_valid_o")



def axis_bytes_to_words(
    payload: bytes | bytearray | memoryview,
    *,
    word_bytes: int,
) -> list[tuple[int, int, bool]]:
    """Split bytes into big-endian AXI4-Stream data/keep/last beats.

    Byte zero occupies the most-significant byte lane. The final ``tkeep`` is
    MSB-contiguous, matching the Ethernet input convention used by ingress_top:

        1 valid byte  -> 1000 for a 32-bit stream
        2 valid bytes -> 1100
        3 valid bytes -> 1110
        4 valid bytes -> 1111
    """

    if word_bytes <= 0:
        raise ValueError(f"word_bytes must be positive, got {word_bytes}")

    data = bytes(payload)
    if not data:
        raise ValueError("cannot drive an empty AXI4-Stream packet")

    keep_width = word_bytes
    words: list[tuple[int, int, bool]] = []

    for offset in range(0, len(data), word_bytes):
        chunk = data[offset : offset + word_bytes]
        valid_bytes = len(chunk)

        word = int.from_bytes(chunk.ljust(word_bytes, b"\x00"), byteorder="big")
        keep = ((1 << valid_bytes) - 1) << (keep_width - valid_bytes)
        last = offset + word_bytes >= len(data)

        words.append((word, keep, last))

    return words


async def drive_axis_frame(
    dut: Any,
    frame: bytes | bytearray | memoryview,
    *,
    timeout_cycles: int = 500_000,
) -> None:
    """Drive one Ethernet frame into a DUT exposing ``s_frame_*`` AXIS ports.

    Each beat is changed on a falling edge and held through the following
    rising edge. Ready is sampled before that rising edge, so a beat is removed
    only after an unambiguous valid/ready handshake. Accepted beats remain
    contiguous at one beat per clock whenever the DUT stays ready.
    """

    data_width_bits = len(dut.s_frame_tdata_i)
    keep_width_bits = len(dut.s_frame_tkeep_i)

    if data_width_bits % 8 != 0:
        raise ValueError(
            f"s_frame_tdata_i width must be byte-aligned, got {data_width_bits} bits"
        )

    word_bytes = data_width_bits // 8
    if keep_width_bits != word_bytes:
        raise ValueError(
            "s_frame_tkeep_i width must equal the number of tdata byte lanes: "
            f"got keep={keep_width_bits}, byte_lanes={word_bytes}"
        )

    words = axis_bytes_to_words(frame, word_bytes=word_bytes)

    await FallingEdge(dut.clk)

    for word, keep, last in words:
        dut.s_frame_tdata_i.value = word
        dut.s_frame_tkeep_i.value = keep
        dut.s_frame_tlast_i.value = int(last)
        dut.s_frame_tvalid_i.value = 1

        accepted = False
        for _ in range(timeout_cycles):
            await ReadOnly()
            ready_before_edge = signal_value_to_int(dut.s_frame_tready_o.value)

            await RisingEdge(dut.clk)

            if ready_before_edge == 1:
                accepted = True
                break

            await FallingEdge(dut.clk)

        if not accepted:
            raise TimeoutError(
                "timed out waiting for s_frame_tready_o during Ethernet frame"
            )

        # Move to the falling edge before either replacing this beat with the
        # next beat or deasserting valid after the final beat.
        await FallingEdge(dut.clk)

    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0
    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
