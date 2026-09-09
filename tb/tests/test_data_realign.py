"""cocotb tests for the merged data_realign streaming decoder.

Scope:
- Drive the exact packed 64-bit payload + message-length contract produced by
  mold_deframe.
- Prove supported ITCH messages decode directly into data_t without first being
  repacketised/padded onto a per-message AXI stream.
- Exercise message boundaries at every 64-bit byte-lane offset.
- Prove unsupported ITCH messages are consumed without producing events.
- Prove downstream event backpressure does not corrupt or overwrite output.

This test intentionally stops at data_realign. frame_crack, mold_deframe, the
event CDC FIFO, symbol_router, and order_book are outside this isolation gate.
"""

from __future__ import annotations

from dataclasses import asdict
from typing import Any

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from golden.itch_parser import parse_itch_message
from itch_harness.axis import axis_bytes_to_words
from itch_harness.ingress_packets import (
    add_order_payload,
    add_order_with_mpid_payload,
    cancel_order_payload,
    delete_order_payload,
    execute_order_payload,
    execute_order_with_price_payload,
    replace_order_payload,
)
from itch_harness.scoreboard import (
    assert_data_t_matches_word,
    signal_value_to_int,
)


CLOCK_PERIOD_NS = 6.4
TIMEOUT_CYCLES = 20_000


def event_to_scoreboard_dict(payload: bytes, *, msg_index: int) -> dict[str, Any] | None:
    """Decode one payload with the existing golden parser for RTL comparison."""

    event = parse_itch_message(payload, msg_index=msg_index)
    if event is None:
        return None

    raw = asdict(event)
    raw["op"] = event.op.value
    raw["side"] = event.side.value
    return raw


def system_event_payload(
    *,
    locate: int = 1,
    tracking: int = 1,
    timestamp_ns: int = 1,
    event_code: str = "O",
) -> bytes:
    """Build a valid 12-byte ITCH System Event message.

    System Event is deliberately unsupported by the current order-book decoder,
    so it is useful for proving that data_realign consumes non-book traffic
    without emitting a data_t event.
    """

    assert len(event_code) == 1

    payload = (
        b"S"
        + locate.to_bytes(2, "big")
        + tracking.to_bytes(2, "big")
        + timestamp_ns.to_bytes(6, "big")
        + event_code.encode("ascii")
    )

    assert len(payload) == 12
    return payload


async def initialise_data_realign(dut: Any) -> None:
    """Start the 156.25 MHz network clock and reset the isolated decoder."""

    cocotb.start_soon(Clock(dut.clk, CLOCK_PERIOD_NS, unit="ns").start())

    dut.s_payload_tdata_i.value = 0
    dut.s_payload_tkeep_i.value = 0
    dut.s_payload_tvalid_i.value = 0
    dut.s_payload_tlast_i.value = 0

    dut.s_msg_len_i.value = 0
    dut.s_msg_len_valid_i.value = 0

    dut.ready_i.value = 1

    dut.rst_n.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk)

    dut.rst_n.value = 1
    await FallingEdge(dut.clk)

    assert signal_value_to_int(dut.s_msg_len_ready_o.value) == 1
    assert signal_value_to_int(dut.valid_o.value) == 0
    assert signal_value_to_int(dut.realign_err_o.value) == 0


async def drive_length_tokens(
    dut: Any,
    lengths: list[int],
    *,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> None:
    """Drive message-length tokens with proper valid/ready handshakes."""

    for length in lengths:
        accepted = False

        for _ in range(timeout_cycles):
            await FallingEdge(dut.clk)

            dut.s_msg_len_i.value = length
            dut.s_msg_len_valid_i.value = 1

            await ReadOnly()
            ready_before_edge = signal_value_to_int(
                dut.s_msg_len_ready_o.value
            )

            await RisingEdge(dut.clk)

            if ready_before_edge == 1:
                accepted = True
                break

        if not accepted:
            raise TimeoutError(
                f"timed out waiting to send length token {length}"
            )

    await FallingEdge(dut.clk)
    dut.s_msg_len_i.value = 0
    dut.s_msg_len_valid_i.value = 0


async def drive_packed_datagram(
    dut: Any,
    payloads: list[bytes],
    *,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> tuple[int, int]:
    """Drive one packed payload stream with no padding between ITCH messages.

    Returns:
        (accepted_beats, stalled_cycles)
    """

    packed = b"".join(payloads)
    words = axis_bytes_to_words(packed, word_bytes=8)

    accepted_beats = 0
    stalled_cycles = 0

    for word, keep, last in words:
        accepted = False

        for _ in range(timeout_cycles):
            await FallingEdge(dut.clk)

            dut.s_payload_tdata_i.value = word
            dut.s_payload_tkeep_i.value = keep
            dut.s_payload_tlast_i.value = int(last)
            dut.s_payload_tvalid_i.value = 1

            await ReadOnly()
            ready_before_edge = signal_value_to_int(
                dut.s_payload_tready_o.value
            )

            await RisingEdge(dut.clk)

            if ready_before_edge == 1:
                accepted = True
                accepted_beats += 1
                break

            stalled_cycles += 1

        if not accepted:
            raise TimeoutError(
                "timed out waiting for data_realign payload ready"
            )

    await FallingEdge(dut.clk)
    dut.s_payload_tdata_i.value = 0
    dut.s_payload_tkeep_i.value = 0
    dut.s_payload_tvalid_i.value = 0
    dut.s_payload_tlast_i.value = 0

    return accepted_beats, stalled_cycles


class EventMonitor:
    """Collect normalised events and error pulses."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.running = True
        self.events: list[int] = []
        self.errors: list[int] = []

    async def run(self) -> None:
        while self.running:
            await FallingEdge(self.dut.clk)
            await ReadOnly()

            if signal_value_to_int(self.dut.rst_n.value) == 0:
                continue

            if signal_value_to_int(self.dut.realign_err_o.value) != 0:
                self.errors.append(
                    signal_value_to_int(self.dut.realign_err_o.value)
                )

            valid = signal_value_to_int(self.dut.valid_o.value)
            ready = signal_value_to_int(self.dut.ready_i.value)

            if valid == 1 and ready == 1:
                self.events.append(
                    signal_value_to_int(self.dut.rdata_o.value)
                )

    async def wait_for_events(
        self,
        count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            if len(self.events) >= count:
                return
            await RisingEdge(self.dut.clk)

        raise TimeoutError(
            f"timed out waiting for {count} events; got {len(self.events)}"
        )

    def stop(self) -> None:
        self.running = False


def assert_events_match(
    got_words: list[int],
    payloads: list[bytes],
) -> None:
    expected_events: list[dict[str, Any]] = []

    for msg_index, payload in enumerate(payloads):
        expected = event_to_scoreboard_dict(payload, msg_index=msg_index)
        if expected is not None:
            expected_events.append(expected)

    assert len(got_words) == len(expected_events), (
        f"expected {len(expected_events)} data_t events, "
        f"got {len(got_words)}"
    )

    for word, expected in zip(got_words, expected_events):
        assert_data_t_matches_word(word, expected)


@cocotb.test()
async def test_data_realign_decodes_mixed_packed_messages(dut: Any) -> None:
    """Decode every supported book-mutating message from one packed datagram."""

    await initialise_data_realign(dut)

    payloads = [
        add_order_payload(
            0x1001,
            side="B",
            shares=100,
            price=10_000,
            locate=11,
            tracking=1,
            timestamp_ns=101,
        ),
        delete_order_payload(
            0x1001,
            locate=11,
            tracking=2,
            timestamp_ns=102,
        ),
        cancel_order_payload(
            0x2002,
            cancelled_shares=25,
            locate=12,
            tracking=3,
            timestamp_ns=103,
        ),
        replace_order_payload(
            0x3003,
            0x4004,
            shares=55,
            price=10_025,
            locate=13,
            tracking=4,
            timestamp_ns=104,
        ),
        execute_order_payload(
            0x5005,
            executed_shares=40,
            match_number=0xABCDEF,
            locate=14,
            tracking=5,
            timestamp_ns=105,
        ),
        execute_order_with_price_payload(
            0x6006,
            executed_shares=15,
            match_number=0x123456,
            printable="Y",
            execution_price=10_030,
            locate=15,
            tracking=6,
            timestamp_ns=106,
        ),
        add_order_with_mpid_payload(
            0x7007,
            side="S",
            shares=75,
            price=10_040,
            attribution=b"TEST",
            locate=16,
            tracking=7,
            timestamp_ns=107,
        ),
    ]

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    await drive_length_tokens(dut, [len(payload) for payload in payloads])
    _, stalled_cycles = await drive_packed_datagram(dut, payloads)

    await monitor.wait_for_events(len(payloads))

    monitor.stop()
    await FallingEdge(dut.clk)
    monitor_task.cancel()

    assert stalled_cycles == 0, (
        "mixed packed payload unexpectedly stalled with ready_i held high: "
        f"{stalled_cycles} cycles"
    )
    assert monitor.errors == []
    assert_events_match(monitor.events, payloads)


@cocotb.test()
async def test_data_realign_covers_every_message_start_lane(dut: Any) -> None:
    """Repeated 19-byte D messages move the next start through all 8 byte lanes.

    gcd(19, 8) == 1, so eight consecutive Delete messages exercise every
    possible message-start alignment without inserting padding.
    """

    await initialise_data_realign(dut)

    payloads = [
        delete_order_payload(
            0x1000 + index,
            locate=20 + index,
            tracking=index,
            timestamp_ns=1_000 + index,
        )
        for index in range(8)
    ]

    start_offsets = []
    cursor = 0
    for payload in payloads:
        start_offsets.append(cursor % 8)
        cursor += len(payload)

    assert sorted(start_offsets) == list(range(8))

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    await drive_length_tokens(dut, [len(payload) for payload in payloads])
    accepted_beats, stalled_cycles = await drive_packed_datagram(dut, payloads)

    await monitor.wait_for_events(len(payloads))

    monitor.stop()
    await FallingEdge(dut.clk)
    monitor_task.cancel()

    expected_beats = (sum(len(payload) for payload in payloads) + 7) // 8

    assert accepted_beats == expected_beats
    assert stalled_cycles == 0, (
        "streaming decoder inserted a padding/realignment bubble: "
        f"{stalled_cycles} cycles"
    )
    assert monitor.errors == []
    assert_events_match(monitor.events, payloads)


@cocotb.test()
async def test_data_realign_skips_unsupported_message_without_padding(
    dut: Any,
) -> None:
    """Unsupported ITCH traffic must be consumed without disturbing neighbours."""

    await initialise_data_realign(dut)

    payloads = [
        delete_order_payload(
            0x1111,
            locate=31,
            tracking=1,
            timestamp_ns=201,
        ),
        system_event_payload(
            locate=0,
            tracking=2,
            timestamp_ns=202,
            event_code="O",
        ),
        cancel_order_payload(
            0x2222,
            cancelled_shares=12,
            locate=32,
            tracking=3,
            timestamp_ns=203,
        ),
    ]

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    await drive_length_tokens(dut, [len(payload) for payload in payloads])
    _, stalled_cycles = await drive_packed_datagram(dut, payloads)

    await monitor.wait_for_events(2)

    # Give the unsupported message plenty of opportunity to emit incorrectly.
    for _ in range(8):
        await RisingEdge(dut.clk)

    monitor.stop()
    await FallingEdge(dut.clk)
    monitor_task.cancel()

    assert stalled_cycles == 0
    assert monitor.errors == []
    assert_events_match(monitor.events, payloads)


@cocotb.test()
async def test_data_realign_holds_event_under_backpressure(dut: Any) -> None:
    """Hold one completed event and prove the packed input safely backpressures."""

    await initialise_data_realign(dut)

    payloads = [
        delete_order_payload(
            0xAAAA,
            locate=41,
            tracking=1,
            timestamp_ns=301,
        ),
        delete_order_payload(
            0xBBBB,
            locate=42,
            tracking=2,
            timestamp_ns=302,
        ),
        delete_order_payload(
            0xCCCC,
            locate=43,
            tracking=3,
            timestamp_ns=303,
        ),
    ]

    await drive_length_tokens(dut, [len(payload) for payload in payloads])

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    dut.ready_i.value = 0

    drive_task = cocotb.start_soon(
        drive_packed_datagram(dut, payloads)
    )

    # Wait until the first event is presented but intentionally not consumed.
    held_word = None
    for _ in range(TIMEOUT_CYCLES):
        await FallingEdge(dut.clk)
        await ReadOnly()

        if signal_value_to_int(dut.valid_o.value) == 1:
            held_word = signal_value_to_int(dut.rdata_o.value)
            break

    assert held_word is not None
    assert signal_value_to_int(dut.s_payload_tready_o.value) == 0

    for _ in range(6):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        await ReadOnly()

        assert signal_value_to_int(dut.valid_o.value) == 1
        assert signal_value_to_int(dut.rdata_o.value) == held_word
        assert signal_value_to_int(dut.s_payload_tready_o.value) == 0

    # The assertions above deliberately sample in ReadOnly. Move to the next
    # writable half-cycle before changing ready_i, then give the release half a
    # cycle of setup before the next active edge.
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)

    # Release the event FIFO side. The existing event may drain while payload
    # processing resumes on the same network clock.
    dut.ready_i.value = 1

    _, stalled_cycles = await drive_task
    await monitor.wait_for_events(len(payloads))

    monitor.stop()
    await FallingEdge(dut.clk)
    monitor_task.cancel()

    assert stalled_cycles >= 1, (
        "backpressure test expected the payload source to be stalled"
    )
    assert monitor.errors == []
    assert_events_match(monitor.events, payloads)
