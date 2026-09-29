"""Unit regression for data_realign.sv.

We check:
- all seven supported book-mutating ITCH types;
- every supported message type starting at every active AXI byte lane;
- semantic data_t fields against the independent Python ITCH parser;
- boundary values for locate, order reference, shares, price and side;
- unsupported ITCH messages being consumed without event output;
- exhaustive current-interface tkeep classification;
- zero length, truncated payload, overflow and bad-tkeep error recovery;
- length/payload channel decoupling;
- output backpressure, output stability and source bubbles;
- reset while idle, between datagrams, mid-message and with output pending;
- deterministic constrained-random mixed traffic.

"""

from __future__ import annotations

import os
import random
from dataclasses import asdict, dataclass
from typing import Any, Callable

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from golden.itch_parser import parse_itch_message
from itch_harness.axis import axis_bytes_to_words, axis_word_bytes
from itch_harness.ingress_packets import (
    add_order_payload,
    add_order_with_mpid_payload,
    cancel_order_payload,
    delete_order_payload,
    execute_order_payload,
    execute_order_with_price_payload,
    replace_order_payload,
)
from itch_harness.perf import start_perf_clock
from itch_harness.scoreboard import (
    assert_data_t_matches_word,
    signal_value_to_int,
)


TIMEOUT_CYCLES = 100_000
RESET_CYCLES = 5
MAX_PRICE_4 = 2_000_000_000

# Public hdl_header.sv error encoding. Keep this local for now, matching the
# frame_crack/mold_deframe unit tests.
REALIGN_ERR_LEN_ZERO = 0
REALIGN_ERR_PAYLOAD_UNDERFLOW = 1
REALIGN_ERR_PAYLOAD_OVERFLOW = 2
REALIGN_ERR_BAD_TKEEP = 3

TEST_SEED = int(os.environ.get("TEST_SEED", "7"), 0)


@dataclass(frozen=True)
class DriveStats:
    accepted: int
    stalled_cycles: int


@dataclass(frozen=True)
class ErrorPulse:
    cycle: int
    value: int


def _event_to_scoreboard_dict(
    payload: bytes,
    *,
    msg_index: int,
) -> dict[str, Any] | None:
    """Decode one payload independently for semantic comparison."""

    event = parse_itch_message(payload, msg_index=msg_index)
    if event is None:
        return None

    raw = asdict(event)
    raw["op"] = event.op.value
    raw["side"] = event.side.value
    return raw


def _system_event_payload(
    *,
    locate: int = 0,
    tracking: int = 1,
    timestamp_ns: int = 1,
    event_code: str = "O",
) -> bytes:
    """Build a valid 12-byte unsupported ITCH System Event."""

    if len(event_code) != 1:
        raise ValueError("event_code must be one character")

    payload = (
        b"S"
        + locate.to_bytes(2, "big")
        + tracking.to_bytes(2, "big")
        + timestamp_ns.to_bytes(6, "big")
        + event_code.encode("ascii")
    )
    assert len(payload) == 12
    return payload


def _supported_payloads(*, salt: int = 0) -> list[tuple[str, bytes]]:
    """One distinctive valid payload for every supported message type."""

    return [
        (
            "A",
            add_order_payload(
                0x0102_0304_0506_0708 + salt,
                side="B",
                shares=0x1122_3344,
                price=123_456_789,
                locate=0x1234,
                tracking=0x0101,
                timestamp_ns=0x0102_0304_0506,
                stock=b"AAPL",
            ),
        ),
        (
            "F",
            add_order_with_mpid_payload(
                0x1112_1314_1516_1718 + salt,
                side="S",
                shares=0x5566_7788,
                price=987_654_321,
                locate=0x2345,
                tracking=0x0202,
                timestamp_ns=0x1112_1314_1516,
                stock=b"MSFT",
                attribution=b"TEST",
            ),
        ),
        (
            "E",
            execute_order_payload(
                0x2122_2324_2526_2728 + salt,
                executed_shares=0x0102_0304,
                match_number=0x3132_3334_3536_3738,
                locate=0x3456,
                tracking=0x0303,
                timestamp_ns=0x2122_2324_2526,
            ),
        ),
        (
            "C",
            execute_order_with_price_payload(
                0x4142_4344_4546_4748 + salt,
                executed_shares=0x1112_1314,
                match_number=0x5152_5354_5556_5758,
                printable="Y",
                execution_price=1_234_567_890,
                locate=0x4567,
                tracking=0x0404,
                timestamp_ns=0x3132_3334_3536,
            ),
        ),
        (
            "X",
            cancel_order_payload(
                0x6162_6364_6566_6768 + salt,
                cancelled_shares=0x2122_2324,
                locate=0x5678,
                tracking=0x0505,
                timestamp_ns=0x4142_4344_4546,
            ),
        ),
        (
            "D",
            delete_order_payload(
                0x7172_7374_7576_7778 + salt,
                locate=0x6789,
                tracking=0x0606,
                timestamp_ns=0x5152_5354_5556,
            ),
        ),
        (
            "U",
            replace_order_payload(
                0x8182_8384_8586_8788 + salt,
                0x9192_9394_9596_9798 + salt,
                shares=0x3132_3334,
                price=1_111_222_333,
                locate=0x789A,
                tracking=0x0707,
                timestamp_ns=0x6162_6364_6566,
            ),
        ),
    ]


def _keep_from_count(valid_bytes: int, word_bytes: int) -> int:
    if not 1 <= valid_bytes <= word_bytes:
        raise ValueError(
            f"valid_bytes must be in 1..{word_bytes}, got {valid_bytes}"
        )
    return ((1 << valid_bytes) - 1) << (word_bytes - valid_bytes)


def _legal_final_keeps(word_bytes: int) -> set[int]:
    return {
        _keep_from_count(valid_bytes, word_bytes)
        for valid_bytes in range(1, word_bytes + 1)
    }


def _word_from_bytes(data: bytes, word_bytes: int) -> int:
    if len(data) > word_bytes:
        raise ValueError(
            f"cannot pack {len(data)} bytes into {word_bytes}-byte word"
        )
    return int.from_bytes(data.ljust(word_bytes, b"\x00"), byteorder="big")


def _prefix_count_for_lane(word_bytes: int, lane: int) -> int:
    """Number of 19-byte Delete prefixes needed to reach one start lane."""

    for count in range(word_bytes):
        if (19 * count) % word_bytes == lane:
            return count

    raise AssertionError(
        f"19-byte Delete messages cannot reach lane {lane} "
        f"for {word_bytes}-byte words"
    )


def _expected_event_count(payloads: list[bytes]) -> int:
    return sum(
        _event_to_scoreboard_dict(payload, msg_index=index) is not None
        for index, payload in enumerate(payloads)
    )


def _assert_events_match(
    got_words: list[int],
    payloads: list[bytes],
    *,
    context: str,
    msg_index_base: int = 0,
) -> None:
    expected_events: list[dict[str, Any]] = []

    for offset, payload in enumerate(payloads):
        expected = _event_to_scoreboard_dict(
            payload,
            msg_index=msg_index_base + offset,
        )
        if expected is not None:
            expected_events.append(expected)

    assert len(got_words) == len(expected_events), (
        f"{context}: expected {len(expected_events)} event(s), "
        f"got {len(got_words)}"
    )

    for event_index, (word, expected) in enumerate(
        zip(got_words, expected_events)
    ):
        try:
            assert_data_t_matches_word(word, expected)
        except AssertionError as exc:
            raise AssertionError(
                f"{context}: event {event_index} mismatch"
            ) from exc


def _assert_monitor_stability(monitor: "EventMonitor") -> None:
    assert monitor.stability_failures == [], (
        "output valid/data changed while backpressured:\n"
        + "\n".join(monitor.stability_failures)
    )


async def _reset_idle(dut: Any) -> None:
    """Reset the block with all external sources inactive."""

    await FallingEdge(dut.clk)

    dut.s_payload_tdata_i.value = 0
    dut.s_payload_tkeep_i.value = 0
    dut.s_payload_tvalid_i.value = 0
    dut.s_payload_tlast_i.value = 0

    dut.s_msg_len_i.value = 0
    dut.s_msg_len_valid_i.value = 0

    dut.ready_i.value = 1
    dut.rst_n.value = 0

    for _ in range(RESET_CYCLES):
        await RisingEdge(dut.clk)

    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await ReadOnly()

    assert signal_value_to_int(dut.s_msg_len_ready_o.value) == 1
    assert signal_value_to_int(dut.valid_o.value) == 0
    assert signal_value_to_int(dut.realign_err_o.value) == 0


async def _initialise(dut: Any) -> None:
    """Start the configured ingress clock and reset data_realign."""

    await start_perf_clock(dut)

    dut.rst_n.value = 0
    dut.s_payload_tdata_i.value = 0
    dut.s_payload_tkeep_i.value = 0
    dut.s_payload_tvalid_i.value = 0
    dut.s_payload_tlast_i.value = 0
    dut.s_msg_len_i.value = 0
    dut.s_msg_len_valid_i.value = 0
    dut.ready_i.value = 1

    await _reset_idle(dut)


def _bubble_count(
    bubble_cycles: Callable[[int], int] | None,
    index: int,
) -> int:
    if bubble_cycles is None:
        return 0

    count = int(bubble_cycles(index))
    if count < 0:
        raise ValueError(f"bubble count must be non-negative, got {count}")
    return count


async def _drive_length_tokens(
    dut: Any,
    lengths: list[int],
    *,
    bubble_cycles: Callable[[int], int] | None = None,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> DriveStats:
    """Drive the msg_len sideband independently with valid/ready semantics."""

    accepted = 0
    stalled_cycles = 0

    await FallingEdge(dut.clk)

    for index, length in enumerate(lengths):
        for _ in range(_bubble_count(bubble_cycles, index)):
            dut.s_msg_len_i.value = 0
            dut.s_msg_len_valid_i.value = 0
            await RisingEdge(dut.clk)
            await FallingEdge(dut.clk)

        dut.s_msg_len_i.value = length
        dut.s_msg_len_valid_i.value = 1

        for _ in range(timeout_cycles):
            await ReadOnly()
            ready_before_edge = signal_value_to_int(
                dut.s_msg_len_ready_o.value
            )

            await RisingEdge(dut.clk)

            if ready_before_edge == 1:
                accepted += 1
                await FallingEdge(dut.clk)
                break

            stalled_cycles += 1
            await FallingEdge(dut.clk)
        else:
            raise TimeoutError(
                f"timed out waiting to send length token {length} "
                f"at index {index}"
            )

    dut.s_msg_len_i.value = 0
    dut.s_msg_len_valid_i.value = 0

    return DriveStats(
        accepted=accepted,
        stalled_cycles=stalled_cycles,
    )


async def _drive_payload_beats(
    dut: Any,
    beats: list[tuple[int, int, bool]],
    *,
    bubble_cycles: Callable[[int], int] | None = None,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> DriveStats:
    """Drive already-packed payload beats and hold each beat until accepted."""

    accepted = 0
    stalled_cycles = 0

    await FallingEdge(dut.clk)

    for index, (word, keep, last) in enumerate(beats):
        for _ in range(_bubble_count(bubble_cycles, index)):
            dut.s_payload_tdata_i.value = 0
            dut.s_payload_tkeep_i.value = 0
            dut.s_payload_tlast_i.value = 0
            dut.s_payload_tvalid_i.value = 0
            await RisingEdge(dut.clk)
            await FallingEdge(dut.clk)

        dut.s_payload_tdata_i.value = word
        dut.s_payload_tkeep_i.value = keep
        dut.s_payload_tlast_i.value = int(last)
        dut.s_payload_tvalid_i.value = 1

        for _ in range(timeout_cycles):
            await ReadOnly()
            ready_before_edge = signal_value_to_int(
                dut.s_payload_tready_o.value
            )

            await RisingEdge(dut.clk)

            if ready_before_edge == 1:
                accepted += 1
                await FallingEdge(dut.clk)
                break

            stalled_cycles += 1
            await FallingEdge(dut.clk)
        else:
            raise TimeoutError(
                "timed out waiting for data_realign payload ready "
                f"at beat {index}"
            )

    dut.s_payload_tdata_i.value = 0
    dut.s_payload_tkeep_i.value = 0
    dut.s_payload_tlast_i.value = 0
    dut.s_payload_tvalid_i.value = 0

    return DriveStats(
        accepted=accepted,
        stalled_cycles=stalled_cycles,
    )


async def _drive_payload_bytes(
    dut: Any,
    payload: bytes,
    *,
    bubble_cycles: Callable[[int], int] | None = None,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> DriveStats:
    word_bytes = axis_word_bytes(
        dut.s_payload_tdata_i,
        dut.s_payload_tkeep_i,
        interface_name="data_realign payload",
    )
    beats = axis_bytes_to_words(payload, word_bytes=word_bytes)
    return await _drive_payload_beats(
        dut,
        beats,
        bubble_cycles=bubble_cycles,
        timeout_cycles=timeout_cycles,
    )


async def _run_stream(
    dut: Any,
    *,
    lengths: list[int],
    payload: bytes,
    length_bubbles: Callable[[int], int] | None = None,
    payload_bubbles: Callable[[int], int] | None = None,
) -> tuple[DriveStats, DriveStats]:
    """Run the independent length and payload sources concurrently."""

    length_task = cocotb.start_soon(
        _drive_length_tokens(
            dut,
            lengths,
            bubble_cycles=length_bubbles,
        )
    )
    payload_task = cocotb.start_soon(
        _drive_payload_bytes(
            dut,
            payload,
            bubble_cycles=payload_bubbles,
        )
    )

    length_stats = await length_task
    payload_stats = await payload_task
    return length_stats, payload_stats


async def _run_datagram(
    dut: Any,
    payloads: list[bytes],
    *,
    length_bubbles: Callable[[int], int] | None = None,
    payload_bubbles: Callable[[int], int] | None = None,
) -> tuple[DriveStats, DriveStats]:
    return await _run_stream(
        dut,
        lengths=[len(payload) for payload in payloads],
        payload=b"".join(payloads),
        length_bubbles=length_bubbles,
        payload_bubbles=payload_bubbles,
    )


class EventMonitor:
    """Independent event/error monitor with output-stability checking."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.running = True
        self.cycle = 0

        self.events: list[int] = []
        self.errors: list[ErrorPulse] = []

        self.backpressure_cycles = 0
        self.stability_failures: list[str] = []
        self._held_word: int | None = None

    async def run(self) -> None:
        while self.running:
            await FallingEdge(self.dut.clk)
            await ReadOnly()

            if signal_value_to_int(self.dut.rst_n.value) == 0:
                self._held_word = None
                self.cycle += 1
                continue

            error = signal_value_to_int(self.dut.realign_err_o.value)
            if error != 0:
                self.errors.append(
                    ErrorPulse(cycle=self.cycle, value=error)
                )

            valid = signal_value_to_int(self.dut.valid_o.value)
            ready = signal_value_to_int(self.dut.ready_i.value)
            word = signal_value_to_int(self.dut.rdata_o.value)

            if self._held_word is not None:
                if valid != 1:
                    self.stability_failures.append(
                        f"cycle={self.cycle}: valid dropped while stalled"
                    )
                elif word != self._held_word:
                    self.stability_failures.append(
                        f"cycle={self.cycle}: held word changed "
                        f"from 0x{self._held_word:x} to 0x{word:x}"
                    )

            if valid == 1 and ready == 0:
                self.backpressure_cycles += 1
                self._held_word = word
            else:
                self._held_word = None

            if valid == 1 and ready == 1:
                self.events.append(word)

            self.cycle += 1

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

    async def wait_for_errors(
        self,
        count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            if len(self.errors) >= count:
                return
            await RisingEdge(self.dut.clk)

        raise TimeoutError(
            f"timed out waiting for {count} error pulse(s); "
            f"got {len(self.errors)}"
        )

    def stop(self) -> None:
        self.running = False


async def _stop_monitor(
    dut: Any,
    monitor: EventMonitor,
    monitor_task: Any,
) -> None:
    monitor.stop()
    await FallingEdge(dut.clk)
    monitor_task.cancel()
    _assert_monitor_stability(monitor)


async def _send_and_check(
    dut: Any,
    monitor: EventMonitor,
    payloads: list[bytes],
    *,
    context: str,
    msg_index_base: int = 0,
    length_bubbles: Callable[[int], int] | None = None,
    payload_bubbles: Callable[[int], int] | None = None,
) -> tuple[DriveStats, DriveStats]:
    event_start = len(monitor.events)
    expected_count = _expected_event_count(payloads)

    stats = await _run_datagram(
        dut,
        payloads,
        length_bubbles=length_bubbles,
        payload_bubbles=payload_bubbles,
    )
    await monitor.wait_for_events(event_start + expected_count)

    # This interval is intentional: prove no unsupported/duplicate event appears
    # after the datagram has been fully accepted.
    for _ in range(2):
        await RisingEdge(dut.clk)

    got = monitor.events[event_start:]
    _assert_events_match(
        got,
        payloads,
        context=context,
        msg_index_base=msg_index_base,
    )
    return stats


async def _periodic_ready_driver(
    dut: Any,
    control: dict[str, bool],
    *,
    period: int,
    stalled_phases: tuple[int, ...],
) -> None:
    cycle = 0
    await FallingEdge(dut.clk)

    while control["running"]:
        dut.ready_i.value = int((cycle % period) not in stalled_phases)
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        cycle += 1

    dut.ready_i.value = 1


def _random_payload(
    rng: random.Random,
    *,
    index: int,
) -> bytes:
    """Generate one deterministic supported or unsupported ITCH message."""

    msg_kind = rng.randrange(8)
    locate = rng.randrange(1 << 16)
    tracking = index & 0xFFFF
    timestamp_ns = rng.randrange(1 << 48)
    order_ref = rng.getrandbits(64)
    shares = rng.getrandbits(32)
    price = rng.randrange(MAX_PRICE_4 + 1)

    if msg_kind == 0:
        return add_order_payload(
            order_ref,
            side=rng.choice(("B", "S")),
            shares=shares,
            price=price,
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )

    if msg_kind == 1:
        return add_order_with_mpid_payload(
            order_ref,
            side=rng.choice(("B", "S")),
            shares=shares,
            price=price,
            attribution=b"RAND",
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )

    if msg_kind == 2:
        return execute_order_payload(
            order_ref,
            executed_shares=shares,
            match_number=rng.getrandbits(64),
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )

    if msg_kind == 3:
        return execute_order_with_price_payload(
            order_ref,
            executed_shares=shares,
            match_number=rng.getrandbits(64),
            printable=rng.choice(("Y", "N")),
            execution_price=price,
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )

    if msg_kind == 4:
        return cancel_order_payload(
            order_ref,
            cancelled_shares=shares,
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )

    if msg_kind == 5:
        return delete_order_payload(
            order_ref,
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )

    if msg_kind == 6:
        new_order_ref = order_ref ^ (1 << 63)
        return replace_order_payload(
            order_ref,
            new_order_ref,
            shares=shares,
            price=price,
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )

    return _system_event_payload(
        locate=locate,
        tracking=tracking,
        timestamp_ns=timestamp_ns,
        event_code="O",
    )


@cocotb.test()
async def test_data_realign_decodes_mixed_packed_messages(dut: Any) -> None:
    """Decode one mixed packed datagram containing every supported type."""

    await _initialise(dut)

    payloads = [payload for _, payload in _supported_payloads()]

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    await _send_and_check(
        dut,
        monitor,
        payloads,
        context="mixed supported datagram",
    )

    assert monitor.errors == []
    await _stop_monitor(dut, monitor, monitor_task)


@cocotb.test()
async def test_data_realign_decodes_every_type_at_every_start_lane(
    dut: Any,
) -> None:
    """Exhaust the supported-message x start-lane matrix."""

    await _initialise(dut)

    word_bytes = axis_word_bytes(
        dut.s_payload_tdata_i,
        dut.s_payload_tkeep_i,
        interface_name="data_realign payload",
    )

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    msg_index_base = 0
    case_index = 0

    for msg_type, target in _supported_payloads():
        for lane in range(word_bytes):
            prefix_count = _prefix_count_for_lane(word_bytes, lane)

            prefixes = [
                delete_order_payload(
                    0xA000_0000_0000_0000 + (case_index << 8) + prefix_index,
                    locate=(0x8000 + case_index + prefix_index) & 0xFFFF,
                    tracking=(case_index + prefix_index) & 0xFFFF,
                    timestamp_ns=10_000 + case_index + prefix_index,
                )
                for prefix_index in range(prefix_count)
            ]

            payloads = prefixes + [target]
            target_start = sum(len(payload) for payload in prefixes) % word_bytes
            assert target_start == lane, (
                f"type={msg_type}: expected target start lane {lane}, "
                f"constructed lane {target_start}"
            )

            await _send_and_check(
                dut,
                monitor,
                payloads,
                context=f"type={msg_type} start_lane={lane}",
                msg_index_base=msg_index_base,
            )

            msg_index_base += len(payloads)
            case_index += 1

    assert monitor.errors == []
    await _stop_monitor(dut, monitor, monitor_task)


@cocotb.test()
async def test_data_realign_decodes_boundary_field_values(dut: Any) -> None:
    """Exercise useful low/high field values without mirroring RTL decode logic."""

    await _initialise(dut)

    max_u16 = (1 << 16) - 1
    max_u32 = (1 << 32) - 1
    max_u64 = (1 << 64) - 1

    payloads = [
        add_order_payload(
            0,
            side="B",
            shares=0,
            price=0,
            locate=0,
            tracking=0,
            timestamp_ns=0,
        ),
        add_order_with_mpid_payload(
            max_u64,
            side="S",
            shares=max_u32,
            price=MAX_PRICE_4,
            locate=max_u16,
            tracking=max_u16,
            timestamp_ns=(1 << 48) - 1,
            attribution=b"MAX!",
        ),
        execute_order_payload(
            1,
            executed_shares=0,
            match_number=max_u64,
            locate=1,
            tracking=1,
            timestamp_ns=1,
        ),
        execute_order_with_price_payload(
            max_u64 - 1,
            executed_shares=max_u32,
            match_number=0,
            printable="N",
            execution_price=MAX_PRICE_4,
            locate=max_u16 - 1,
            tracking=max_u16 - 1,
            timestamp_ns=(1 << 48) - 2,
        ),
        cancel_order_payload(
            0x0102_0304_0506_0708,
            cancelled_shares=max_u32,
            locate=0x0102,
            tracking=0x0304,
            timestamp_ns=0x0102_0304_0506,
        ),
        delete_order_payload(
            max_u64,
            locate=max_u16,
            tracking=0,
            timestamp_ns=1,
        ),
        replace_order_payload(
            0,
            max_u64,
            shares=max_u32,
            price=MAX_PRICE_4,
            locate=max_u16,
            tracking=max_u16,
            timestamp_ns=(1 << 48) - 1,
        ),
    ]

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    await _send_and_check(
        dut,
        monitor,
        payloads,
        context="boundary field values",
    )

    assert monitor.errors == []
    await _stop_monitor(dut, monitor, monitor_task)


@cocotb.test()
async def test_data_realign_skips_unsupported_messages_without_state_leak(
    dut: Any,
) -> None:
    """Unsupported messages are consumed and valid neighbours stay exact."""

    await _initialise(dut)

    payloads = [
        delete_order_payload(
            0x1111,
            locate=31,
            tracking=1,
            timestamp_ns=201,
        ),
        _system_event_payload(
            locate=0,
            tracking=2,
            timestamp_ns=202,
            event_code="O",
        ),
        _system_event_payload(
            locate=0,
            tracking=3,
            timestamp_ns=203,
            event_code="Q",
        ),
        cancel_order_payload(
            0x2222,
            cancelled_shares=12,
            locate=32,
            tracking=4,
            timestamp_ns=204,
        ),
    ]

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    await _send_and_check(
        dut,
        monitor,
        payloads,
        context="unsupported messages between valid events",
    )

    assert len(monitor.events) == 2
    assert monitor.errors == []
    await _stop_monitor(dut, monitor, monitor_task)


@cocotb.test()
async def test_data_realign_exhausts_tkeep_classification(dut: Any) -> None:
    """Exhaust every current tkeep value for final and non-final beats."""

    await _initialise(dut)

    word_bytes = axis_word_bytes(
        dut.s_payload_tdata_i,
        dut.s_payload_tkeep_i,
        interface_name="data_realign payload",
    )
    keep_values = range(1 << word_bytes)
    legal_final = _legal_final_keeps(word_bytes)
    full_keep = (1 << word_bytes) - 1
    top_keep = _keep_from_count(1, word_bytes)

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    # Final beats accept exactly the MSB-contiguous non-zero masks.
    for keep in keep_values:
        error_start = len(monitor.errors)

        if keep in legal_final:
            valid_bytes = keep.bit_count()
            payload = bytes(
                [ord("S")]
                + [((0x40 + index) & 0xFF) for index in range(valid_bytes - 1)]
            )
            word = _word_from_bytes(payload, word_bytes)

            await _drive_length_tokens(dut, [valid_bytes])
            await _drive_payload_beats(dut, [(word, keep, True)])

            await RisingEdge(dut.clk)
            assert len(monitor.errors) == error_start, (
                f"legal final keep 0x{keep:x} raised an error"
            )
        else:
            payload = bytes(
                [ord("S")]
                + [((0x80 + index) & 0xFF) for index in range(word_bytes - 1)]
            )
            word = _word_from_bytes(payload, word_bytes)

            await _drive_length_tokens(dut, [word_bytes])
            await _drive_payload_beats(dut, [(word, keep, True)])
            await monitor.wait_for_errors(error_start + 1)

            new_errors = monitor.errors[error_start:]
            assert len(new_errors) == 1, (
                f"final keep 0x{keep:x}: expected one error, "
                f"got {new_errors}"
            )
            assert new_errors[0].value == (1 << REALIGN_ERR_BAD_TKEEP), (
                f"final keep 0x{keep:x}: expected BAD_TKEEP, "
                f"got 0x{new_errors[0].value:x}"
            )

    # Non-final beats require a full keep. Illegal cases enter drain until tlast.
    for keep in keep_values:
        error_start = len(monitor.errors)
        first_payload = bytes(
            [ord("S")]
            + [((0x20 + index) & 0xFF) for index in range(word_bytes - 1)]
        )
        first_word = _word_from_bytes(first_payload, word_bytes)

        await _drive_length_tokens(dut, [word_bytes + 1])

        if keep == full_keep:
            final_word = _word_from_bytes(b"\x5a", word_bytes)
            await _drive_payload_beats(
                dut,
                [
                    (first_word, full_keep, False),
                    (final_word, top_keep, True),
                ],
            )
            await RisingEdge(dut.clk)
            assert len(monitor.errors) == error_start, (
                "full non-final keep unexpectedly raised an error"
            )
        else:
            await _drive_payload_beats(
                dut,
                [(first_word, keep, False)],
            )
            await monitor.wait_for_errors(error_start + 1)

            new_errors = monitor.errors[error_start:]
            assert len(new_errors) == 1, (
                f"non-final keep 0x{keep:x}: expected one error, "
                f"got {new_errors}"
            )
            assert new_errors[0].value == (1 << REALIGN_ERR_BAD_TKEEP), (
                f"non-final keep 0x{keep:x}: expected BAD_TKEEP, "
                f"got 0x{new_errors[0].value:x}"
            )

            # Parser is in drop mode now. One tlast beat finishes recovery.
            await _drive_payload_beats(
                dut,
                [(_word_from_bytes(b"\x00", word_bytes), top_keep, True)],
            )

    assert monitor.events == []
    await _stop_monitor(dut, monitor, monitor_task)


@cocotb.test()
async def test_data_realign_error_paths_recover_on_next_datagram(
    dut: Any,
) -> None:
    """Use valid A / bad B / valid C around every defined parser error."""

    await _initialise(dut)

    word_bytes = axis_word_bytes(
        dut.s_payload_tdata_i,
        dut.s_payload_tkeep_i,
        interface_name="data_realign payload",
    )
    full_keep = (1 << word_bytes) - 1
    bad_keep = (1 << (word_bytes - 1)) | 1

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    msg_index_base = 0

    async def prove_valid(tag: str, order_ref: int) -> None:
        nonlocal msg_index_base

        payload = delete_order_payload(
            order_ref,
            locate=(order_ref & 0xFFFF),
            tracking=(order_ref >> 4) & 0xFFFF,
            timestamp_ns=order_ref & ((1 << 48) - 1),
        )
        await _send_and_check(
            dut,
            monitor,
            [payload],
            context=f"{tag} recovery traffic",
            msg_index_base=msg_index_base,
        )
        msg_index_base += 1

    async def expect_error(
        expected_bit: int,
        bad_action: Callable[[], Any],
        *,
        context: str,
    ) -> None:
        event_start = len(monitor.events)
        error_start = len(monitor.errors)

        await bad_action()
        await monitor.wait_for_errors(error_start + 1)
        await RisingEdge(dut.clk)

        new_errors = monitor.errors[error_start:]
        assert len(new_errors) == 1, (
            f"{context}: expected exactly one error pulse, got {new_errors}"
        )
        assert new_errors[0].value == (1 << expected_bit), (
            f"{context}: expected bit {expected_bit}, "
            f"got 0x{new_errors[0].value:x}"
        )
        assert len(monitor.events) == event_start, (
            f"{context}: malformed traffic emitted an event"
        )

    # zero length. The following payload beat is the malformed datagram that
    # gets drained because the zero token already put the parser in drop mode.
    await prove_valid("before LEN_ZERO", 0x1001)

    async def zero_length_case() -> None:
        await _run_stream(
            dut,
            lengths=[0],
            payload=b"zero-len",
        )

    await expect_error(
        REALIGN_ERR_LEN_ZERO,
        zero_length_case,
        context="zero message length",
    )
    await prove_valid("after LEN_ZERO", 0x1002)

    # declared message is longer than the actual datagram.
    await prove_valid("before UNDERFLOW", 0x2001)

    async def underflow_case() -> None:
        await _run_stream(
            dut,
            lengths=[19],
            payload=b"S" + b"\x11" * 9,
        )

    await expect_error(
        REALIGN_ERR_PAYLOAD_UNDERFLOW,
        underflow_case,
        context="truncated message payload",
    )
    await prove_valid("after UNDERFLOW", 0x2002)

    # Two tiny declared messages would both finish inside one payload beat.
    await prove_valid("before OVERFLOW", 0x3001)

    async def overflow_case() -> None:
        await _run_stream(
            dut,
            lengths=[1, 1],
            payload=b"S1234567"[:word_bytes],
        )

    await expect_error(
        REALIGN_ERR_PAYLOAD_OVERFLOW,
        overflow_case,
        context="multiple message boundaries in one beat",
    )
    await prove_valid("after OVERFLOW", 0x3002)

    # Non-contiguous tkeep is rejected directly.
    await prove_valid("before BAD_TKEEP", 0x4001)

    async def bad_tkeep_case() -> None:
        await _drive_length_tokens(dut, [word_bytes])
        word = _word_from_bytes(
            b"S" + b"\x22" * (word_bytes - 1),
            word_bytes,
        )
        await _drive_payload_beats(
            dut,
            [(word, bad_keep, True)],
        )

    await expect_error(
        REALIGN_ERR_BAD_TKEEP,
        bad_tkeep_case,
        context="bad final tkeep",
    )
    await prove_valid("after BAD_TKEEP", 0x4002)

    assert full_keep == (1 << word_bytes) - 1
    await _stop_monitor(dut, monitor, monitor_task)


@cocotb.test()
async def test_data_realign_decouples_length_and_payload_channels(
    dut: Any,
) -> None:
    """Either side may arrive early without losing or inventing a transaction."""

    await _initialise(dut)

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    payload_a = delete_order_payload(
        0xAAAA,
        locate=0x1111,
        tracking=1,
        timestamp_ns=101,
    )

    # Payload source goes valid first. It must be held off until a length exists.
    event_start = len(monitor.events)
    payload_task = cocotb.start_soon(
        _drive_payload_bytes(dut, payload_a)
    )

    saw_source_valid = False
    for _ in range(TIMEOUT_CYCLES):
        await FallingEdge(dut.clk)
        await ReadOnly()

        if signal_value_to_int(dut.s_payload_tvalid_i.value) == 1:
            saw_source_valid = True
            break

    assert saw_source_valid, "payload source never became valid"

    for _ in range(3):
        assert signal_value_to_int(dut.s_payload_tready_o.value) == 0
        assert len(monitor.events) == event_start
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        await ReadOnly()

    length_task = cocotb.start_soon(
        _drive_length_tokens(dut, [len(payload_a)])
    )
    await length_task
    await payload_task
    await monitor.wait_for_events(event_start + 1)

    _assert_events_match(
        monitor.events[event_start:],
        [payload_a],
        context="payload before length",
    )

    # Now do the opposite. A descriptor may sit without creating output.
    payload_b = cancel_order_payload(
        0xBBBB,
        cancelled_shares=0x1234,
        locate=0x2222,
        tracking=2,
        timestamp_ns=202,
    )
    event_start = len(monitor.events)

    await _drive_length_tokens(dut, [len(payload_b)])

    for _ in range(3):
        assert len(monitor.events) == event_start
        await RisingEdge(dut.clk)

    await _drive_payload_bytes(dut, payload_b)
    await monitor.wait_for_events(event_start + 1)

    _assert_events_match(
        monitor.events[event_start:],
        [payload_b],
        context="length before payload",
        msg_index_base=1,
    )

    assert monitor.errors == []
    await _stop_monitor(dut, monitor, monitor_task)


@cocotb.test()
async def test_data_realign_backpressure_and_source_bubbles(
    dut: Any,
) -> None:
    """Hold an event, then run mixed traffic with periodic sink/source stalls."""

    await _initialise(dut)

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    # First force a long held output so stability/backpressure is definitely hit.
    held_payloads = [
        delete_order_payload(
            0x5000 + index,
            locate=0x500 + index,
            tracking=index,
            timestamp_ns=500 + index,
        )
        for index in range(3)
    ]

    # _initialise() returns after a ReadOnly sample. Move to the next writable
    # half-cycle before applying sink backpressure.
    await FallingEdge(dut.clk)
    dut.ready_i.value = 0

    event_start = len(monitor.events)
    held_task = cocotb.start_soon(
        _run_datagram(dut, held_payloads)
    )

    saw_valid = False
    for _ in range(TIMEOUT_CYCLES):
        await FallingEdge(dut.clk)
        await ReadOnly()

        if signal_value_to_int(dut.valid_o.value) == 1:
            saw_valid = True
            break

    assert saw_valid, "timed out waiting for held output event"

    for _ in range(6):
        assert signal_value_to_int(dut.valid_o.value) == 1
        assert signal_value_to_int(dut.ready_i.value) == 0
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        await ReadOnly()

    # Move out of ReadOnly before changing ready_i.
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.ready_i.value = 1

    _, held_payload_stats = await held_task
    await monitor.wait_for_events(event_start + len(held_payloads))

    _assert_events_match(
        monitor.events[event_start:],
        held_payloads,
        context="directed output backpressure",
    )
    assert held_payload_stats.stalled_cycles > 0, (
        "directed backpressure did not propagate to the payload source"
    )
    assert monitor.backpressure_cycles > 0

    # Periodic stalls plus independent bubbles on both source channels.
    payloads = [
        payload
        for repeat in range(4)
        for _, payload in _supported_payloads(salt=repeat * 0x100)
    ]
    payloads.insert(
        5,
        _system_event_payload(
            tracking=0x55,
            timestamp_ns=0x5555,
            event_code="O",
        ),
    )
    payloads.insert(
        17,
        _system_event_payload(
            tracking=0x66,
            timestamp_ns=0x6666,
            event_code="Q",
        ),
    )

    control = {"running": True}
    ready_task = cocotb.start_soon(
        _periodic_ready_driver(
            dut,
            control,
            period=7,
            stalled_phases=(2, 3, 4, 5),
        )
    )

    def length_bubbles(index: int) -> int:
        return 1 if index % 9 == 4 else 0

    def payload_bubbles(index: int) -> int:
        if index % 17 == 6:
            return 2
        if index % 11 == 3:
            return 1
        return 0

    event_start = len(monitor.events)
    _, payload_stats = await _run_datagram(
        dut,
        payloads,
        length_bubbles=length_bubbles,
        payload_bubbles=payload_bubbles,
    )
    await monitor.wait_for_events(
        event_start + _expected_event_count(payloads)
    )

    control["running"] = False
    await ready_task

    # allow a final accepted event to be captured before slicing
    for _ in range(2):
        await RisingEdge(dut.clk)

    _assert_events_match(
        monitor.events[event_start:],
        payloads,
        context="periodic backpressure/source bubbles",
        msg_index_base=100,
    )

    assert payload_stats.accepted > 0
    assert monitor.errors == []
    _assert_monitor_stability(monitor)
    await _stop_monitor(dut, monitor, monitor_task)


@cocotb.test()
async def test_data_realign_reset_recovery_from_meaningful_states(
    dut: Any,
) -> None:
    """Reset idle, after traffic, mid-message and while an event is pending."""

    await _initialise(dut)

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    # idle reset
    await _reset_idle(dut)
    assert monitor.errors == []

    payload_idle = delete_order_payload(
        0x6001,
        locate=0x6001,
        tracking=1,
        timestamp_ns=1,
    )
    await _send_and_check(
        dut,
        monitor,
        [payload_idle],
        context="recovery after idle reset",
    )

    # reset between complete datagrams
    await _reset_idle(dut)
    payload_between = cancel_order_payload(
        0x6002,
        cancelled_shares=7,
        locate=0x6002,
        tracking=2,
        timestamp_ns=2,
    )
    await _send_and_check(
        dut,
        monitor,
        [payload_between],
        context="recovery after between-datagram reset",
        msg_index_base=1,
    )

    # reset after accepting only a prefix of one message
    partial = add_order_payload(
        0x6003,
        side="B",
        shares=10,
        price=10_000,
        locate=0x6003,
        tracking=3,
        timestamp_ns=3,
    )
    word_bytes = axis_word_bytes(
        dut.s_payload_tdata_i,
        dut.s_payload_tkeep_i,
        interface_name="data_realign payload",
    )
    partial_beats = axis_bytes_to_words(partial, word_bytes=word_bytes)

    await _drive_length_tokens(dut, [len(partial)])
    await _drive_payload_beats(dut, partial_beats[:2])

    events_before_mid_reset = len(monitor.events)
    await _reset_idle(dut)

    assert len(monitor.events) == events_before_mid_reset
    assert signal_value_to_int(dut.valid_o.value) == 0
    assert signal_value_to_int(dut.realign_err_o.value) == 0

    payload_after_partial = delete_order_payload(
        0x6004,
        locate=0x6004,
        tracking=4,
        timestamp_ns=4,
    )
    await _send_and_check(
        dut,
        monitor,
        [payload_after_partial],
        context="recovery after mid-message reset",
        msg_index_base=2,
    )

    # reset while a completed event is held because ready_i is low
    pending = delete_order_payload(
        0x6005,
        locate=0x6005,
        tracking=5,
        timestamp_ns=5,
    )

    dut.ready_i.value = 0
    pending_event_start = len(monitor.events)
    await _run_datagram(dut, [pending])

    saw_pending = False
    for _ in range(TIMEOUT_CYCLES):
        await FallingEdge(dut.clk)
        await ReadOnly()

        if signal_value_to_int(dut.valid_o.value) == 1:
            saw_pending = True
            break

    assert saw_pending, "timed out waiting for pending event before reset"
    assert len(monitor.events) == pending_event_start

    await _reset_idle(dut)

    assert len(monitor.events) == pending_event_start
    assert signal_value_to_int(dut.valid_o.value) == 0
    assert signal_value_to_int(dut.realign_err_o.value) == 0

    payload_after_pending = replace_order_payload(
        0x6006,
        0x7006,
        shares=77,
        price=12_345,
        locate=0x6006,
        tracking=6,
        timestamp_ns=6,
    )
    await _send_and_check(
        dut,
        monitor,
        [payload_after_pending],
        context="recovery after pending-output reset",
        msg_index_base=3,
    )

    assert monitor.errors == []
    await _stop_monitor(dut, monitor, monitor_task)


@cocotb.test()
async def test_data_realign_deterministic_random_mixed_streams(
    dut: Any,
) -> None:
    """Deterministic mixed datagrams with source bubbles and sink stalls."""

    await _initialise(dut)

    cocotb.log.info("data_realign deterministic TEST_SEED=%d", TEST_SEED)
    rng = random.Random(TEST_SEED)

    datagrams: list[list[bytes]] = []
    remaining = 64
    message_index = 0

    while remaining:
        count = min(remaining, rng.randint(1, 6))
        payloads = [
            _random_payload(rng, index=message_index + offset)
            for offset in range(count)
        ]
        datagrams.append(payloads)
        message_index += count
        remaining -= count

    monitor = EventMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    control = {"running": True}
    ready_task = cocotb.start_soon(
        _periodic_ready_driver(
            dut,
            control,
            period=11,
            stalled_phases=(3, 4, 8),
        )
    )

    global_msg_index = 0

    for datagram_index, payloads in enumerate(datagrams):
        event_start = len(monitor.events)

        def length_bubbles(index: int, base: int = datagram_index) -> int:
            return 1 if (index + base) % 7 == 3 else 0

        def payload_bubbles(index: int, base: int = datagram_index) -> int:
            value = (index * 13 + base * 5 + TEST_SEED) % 23
            if value == 0:
                return 2
            if value in (7, 17):
                return 1
            return 0

        await _run_datagram(
            dut,
            payloads,
            length_bubbles=length_bubbles,
            payload_bubbles=payload_bubbles,
        )
        await monitor.wait_for_events(
            event_start + _expected_event_count(payloads)
        )

        for _ in range(2):
            await RisingEdge(dut.clk)

        got = monitor.events[event_start:]
        _assert_events_match(
            got,
            payloads,
            context=(
                f"random datagram={datagram_index} seed={TEST_SEED}"
            ),
            msg_index_base=global_msg_index,
        )

        global_msg_index += len(payloads)

    control["running"] = False
    await ready_task

    assert monitor.errors == [], (
        f"seed={TEST_SEED}: valid random traffic produced errors "
        f"{monitor.errors}"
    )
    _assert_monitor_stability(monitor)
    await _stop_monitor(dut, monitor, monitor_task)
