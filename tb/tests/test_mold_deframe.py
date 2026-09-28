"""Unit regression for mold_deframe.sv.

We check:
- MoldUDP64 header extraction and sequence sideband;
- length-prefix stripping and exact payload ordering;
- one and multiple messages per datagram;
- every currently supported book-mutating ITCH message length;
- message bodies and 2-byte length prefixes at every reachable AXI lane;
- descriptor-before-payload ordering;
- consecutive datagrams and source bubbles;
- payload and length-channel backpressure with stability checks;
- duplicate, gap, heartbeat and EOS behaviour through the integrated guard;
- every public Mold error class exercised by directed malformed traffic;
- reset during active parsing and while output is pending;
- deterministic constrained-random valid traffic.

Compatible for future switch to 32-bit

We don't cover latency here
"""

from __future__ import annotations

import os
import random
from dataclasses import dataclass
from typing import Any, Callable

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from itch_harness.axis import axis_bytes_to_words, axis_word_bytes, reset_dut
from itch_harness.ingress_packets import (
    SESSION,
    add_order_payload,
    add_order_with_mpid_payload,
    build_mold_datagram,
    cancel_order_payload,
    delete_order_payload,
    execute_order_payload,
    execute_order_with_price_payload,
    replace_order_payload,
)
from itch_harness.perf import start_perf_clock
from itch_harness.scoreboard import signal_value_to_int


TIMEOUT_CYCLES = 100_000
RESET_CYCLES = 5
MOLD_HEADER_BYTES = 20

MOLD_COUNT_HEARTBEAT = 0x0000
MOLD_COUNT_EOS = 0xFFFF

# Public hdl_header.sv error encoding. These can move to a shared
# itch_harness/contracts.py once the other ingress unit tests use the same map.
MOLD_ERR_SHORT_DGRAM = 0
MOLD_ERR_LEN_OVERRUN = 1
MOLD_ERR_COUNT_OVERRUN = 2
MOLD_ERR_BAD_TKEEP = 3
MOLD_ERR_EOS_PAYLOAD = 4

TEST_SEED = int(os.environ.get("TEST_SEED", "7"), 0)


@dataclass(frozen=True)
class DriveStats:
    accepted_beats: int
    stall_cycles: int


@dataclass(frozen=True)
class CapturedPayloadBeat:
    cycle: int
    data: int
    keep: int
    last: int
    byte_start: int
    byte_count: int


@dataclass(frozen=True)
class CapturedLength:
    cycle: int
    value: int


@dataclass(frozen=True)
class SequenceEvent:
    cycle: int
    session: int
    seq: int
    count: int
    expected_next: int
    heartbeat: int
    eos: int
    in_order: int
    duplicate: int
    gap: int
    stale: int
    expected_seq: int
    gap_start: int
    gap_end: int


@dataclass(frozen=True)
class CapturedDatagram:
    payload: bytes
    lengths: tuple[int, ...]
    beats: tuple[CapturedPayloadBeat, ...]
    length_events: tuple[CapturedLength, ...]
    sequence: SequenceEvent


@dataclass(frozen=True)
class DropEvent:
    cycle: int
    error: int
    aborted_payload: bytes


def _keep_from_count(valid_bytes: int, word_bytes: int) -> int:
    if not 1 <= valid_bytes <= word_bytes:
        raise ValueError(
            f"valid_bytes must be in 1..{word_bytes}, got {valid_bytes}"
        )
    return ((1 << valid_bytes) - 1) << (word_bytes - valid_bytes)


def _bytes_from_beat(data: int, keep: int, word_bytes: int) -> bytes:
    result = bytearray()

    for lane in range(word_bytes):
        keep_bit = word_bytes - 1 - lane
        if keep & (1 << keep_bit):
            shift = 8 * (word_bytes - 1 - lane)
            result.append((data >> shift) & 0xFF)

    return bytes(result)


def _supported_itch_payloads() -> list[tuple[str, bytes]]:
    """Return one valid example of every supported book-mutating ITCH type."""

    return [
        (
            "A",
            add_order_payload(
                0x1001,
                side="B",
                shares=100,
                price=12_345,
                locate=1,
                tracking=1,
                timestamp_ns=1,
                stock=b"AAPL",
            ),
        ),
        (
            "F",
            add_order_with_mpid_payload(
                0x1002,
                side="S",
                shares=200,
                price=12_350,
                locate=2,
                tracking=2,
                timestamp_ns=2,
                stock=b"MSFT",
                attribution=b"TEST",
            ),
        ),
        (
            "E",
            execute_order_payload(
                0x1003,
                executed_shares=25,
                match_number=0xABCDEF,
                locate=3,
                tracking=3,
                timestamp_ns=3,
            ),
        ),
        (
            "C",
            execute_order_with_price_payload(
                0x1004,
                executed_shares=30,
                match_number=0x123456,
                printable="Y",
                execution_price=12_360,
                locate=4,
                tracking=4,
                timestamp_ns=4,
            ),
        ),
        (
            "X",
            cancel_order_payload(
                0x1005,
                cancelled_shares=15,
                locate=5,
                tracking=5,
                timestamp_ns=5,
            ),
        ),
        (
            "D",
            delete_order_payload(
                0x1006,
                locate=6,
                tracking=6,
                timestamp_ns=6,
            ),
        ),
        (
            "U",
            replace_order_payload(
                0x1007,
                0x2007,
                shares=175,
                price=12_370,
                locate=7,
                tracking=7,
                timestamp_ns=7,
            ),
        ),
    ]


async def _initialise(dut: Any) -> None:
    """Start the configured ingress clock and reset mold_deframe."""

    await start_perf_clock(dut)

    dut.s_axis_tdata_i.value = 0
    dut.s_axis_tkeep_i.value = 0
    dut.s_axis_tvalid_i.value = 0
    dut.s_axis_tlast_i.value = 0
    dut.s_dgram_len_i.value = 0
    dut.s_dgram_start_i.value = 0

    dut.m_payload_tready_i.value = 1
    dut.m_msg_len_ready_i.value = 1

    await reset_dut(dut, cycles=RESET_CYCLES)
    await ReadOnly()


async def _reset_idle(dut: Any) -> None:
    """Reset while forcing both streaming endpoints into an idle-safe state."""

    await FallingEdge(dut.clk)

    dut.s_axis_tdata_i.value = 0
    dut.s_axis_tkeep_i.value = 0
    dut.s_axis_tvalid_i.value = 0
    dut.s_axis_tlast_i.value = 0
    dut.s_dgram_len_i.value = 0
    dut.s_dgram_start_i.value = 0

    dut.m_payload_tready_i.value = 1
    dut.m_msg_len_ready_i.value = 1

    await reset_dut(dut, cycles=RESET_CYCLES)
    await ReadOnly()


async def _force_reset_during_activity(
    dut: Any,
    *,
    task_to_cancel: Any | None = None,
) -> None:
    """Assert reset away from the active edge, cancel traffic and return idle."""

    await FallingEdge(dut.clk)
    dut.rst_n.value = 0

    if task_to_cancel is not None:
        task_to_cancel.cancel()

    dut.s_axis_tdata_i.value = 0
    dut.s_axis_tkeep_i.value = 0
    dut.s_axis_tvalid_i.value = 0
    dut.s_axis_tlast_i.value = 0
    dut.s_dgram_len_i.value = 0
    dut.s_dgram_start_i.value = 0

    dut.m_payload_tready_i.value = 1
    dut.m_msg_len_ready_i.value = 1

    for _ in range(RESET_CYCLES):
        await RisingEdge(dut.clk)

    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await ReadOnly()


async def _drive_raw_beats(
    dut: Any,
    beats: list[tuple[int, int, bool]],
    *,
    declared_len: int,
    assert_start: bool = True,
    bubble_cycles: Callable[[int], int] | None = None,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> DriveStats:
    """Drive one Mold datagram with stable ready/valid handshake timing."""

    if not beats:
        raise ValueError("a Mold datagram must contain at least one AXI beat")

    accepted_beats = 0
    stall_cycles = 0

    await FallingEdge(dut.clk)

    for beat_index, (word, keep, last) in enumerate(beats):
        bubble_count = 0 if bubble_cycles is None else bubble_cycles(beat_index)
        if bubble_count < 0:
            raise ValueError("bubble_cycles must not return a negative value")

        for _ in range(bubble_count):
            dut.s_axis_tdata_i.value = 0
            dut.s_axis_tkeep_i.value = 0
            dut.s_axis_tvalid_i.value = 0
            dut.s_axis_tlast_i.value = 0
            dut.s_dgram_len_i.value = 0
            dut.s_dgram_start_i.value = 0

            await RisingEdge(dut.clk)
            await FallingEdge(dut.clk)

        dut.s_axis_tdata_i.value = word
        dut.s_axis_tkeep_i.value = keep
        dut.s_axis_tvalid_i.value = 1
        dut.s_axis_tlast_i.value = int(last)
        dut.s_dgram_start_i.value = int(assert_start and beat_index == 0)
        dut.s_dgram_len_i.value = declared_len if beat_index == 0 else 0

        accepted = False
        for _ in range(timeout_cycles):
            await ReadOnly()
            ready_before_edge = signal_value_to_int(dut.s_axis_tready_o.value)

            await RisingEdge(dut.clk)

            if ready_before_edge == 1:
                accepted = True
                accepted_beats += 1
                break

            stall_cycles += 1
            await FallingEdge(dut.clk)

        if not accepted:
            raise TimeoutError(
                "timed out waiting for s_axis_tready_o; "
                f"beat_index={beat_index} declared_len={declared_len} "
                f"keep=0x{keep:x} last={int(last)}"
            )

        await FallingEdge(dut.clk)

    dut.s_axis_tdata_i.value = 0
    dut.s_axis_tkeep_i.value = 0
    dut.s_axis_tvalid_i.value = 0
    dut.s_axis_tlast_i.value = 0
    dut.s_dgram_len_i.value = 0
    dut.s_dgram_start_i.value = 0

    return DriveStats(
        accepted_beats=accepted_beats,
        stall_cycles=stall_cycles,
    )


async def _drive_datagram(
    dut: Any,
    datagram: bytes,
    *,
    declared_len: int | None = None,
    assert_start: bool = True,
    bubble_cycles: Callable[[int], int] | None = None,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> DriveStats:
    """Pack one byte-oriented Mold datagram for the active DUT width."""

    word_bytes = axis_word_bytes(
        dut.s_axis_tdata_i,
        dut.s_axis_tkeep_i,
        interface_name="mold_deframe input",
    )
    beats = axis_bytes_to_words(datagram, word_bytes=word_bytes)

    return await _drive_raw_beats(
        dut,
        beats,
        declared_len=len(datagram) if declared_len is None else declared_len,
        assert_start=assert_start,
        bubble_cycles=bubble_cycles,
        timeout_cycles=timeout_cycles,
    )


class MoldDeframeMonitor:
    """Independent payload/descriptor/status monitor with stability checks."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.word_bytes = axis_word_bytes(
            dut.m_payload_tdata_o,
            dut.m_payload_tkeep_o,
            interface_name="mold_deframe payload output",
        )

        self.running = True
        self.cycle = 0
        self.failure: Exception | None = None

        self.datagrams: list[CapturedDatagram] = []
        self.sequence_events: list[SequenceEvent] = []
        self.drops: list[DropEvent] = []
        self.all_payload_beats: list[CapturedPayloadBeat] = []
        self.all_lengths: list[CapturedLength] = []

        self._mode = "forbid"
        self._current_sequence: SequenceEvent | None = None
        self._current_payload = bytearray()
        self._current_beats: list[CapturedPayloadBeat] = []
        self._current_lengths: list[CapturedLength] = []

        self._held_payload: tuple[int, int, int] | None = None
        self._held_length: int | None = None

    def _clear_current(self) -> bytes:
        aborted = bytes(self._current_payload)
        self._current_sequence = None
        self._current_payload.clear()
        self._current_beats.clear()
        self._current_lengths.clear()
        return aborted

    def _check_failure(self) -> None:
        if self.failure is not None:
            raise self.failure

    def _capture_sequence_event(self) -> SequenceEvent:
        event = SequenceEvent(
            cycle=self.cycle,
            session=signal_value_to_int(self.dut.session_o.value),
            seq=signal_value_to_int(self.dut.seq_o.value),
            count=signal_value_to_int(self.dut.count_o.value),
            expected_next=signal_value_to_int(self.dut.expected_next_o.value),
            heartbeat=signal_value_to_int(self.dut.heartbeat_o.value),
            eos=signal_value_to_int(self.dut.eos_o.value),
            in_order=signal_value_to_int(self.dut.in_order_o.value),
            duplicate=signal_value_to_int(self.dut.duplicate_o.value),
            gap=signal_value_to_int(self.dut.gap_o.value),
            stale=signal_value_to_int(self.dut.stale_o.value),
            expected_seq=signal_value_to_int(self.dut.expected_seq_o.value),
            gap_start=signal_value_to_int(self.dut.gap_start_o.value),
            gap_end=signal_value_to_int(self.dut.gap_end_o.value),
        )
        self.sequence_events.append(event)
        return event

    async def run(self) -> None:
        try:
            while self.running:
                await FallingEdge(self.dut.clk)
                await ReadOnly()

                if signal_value_to_int(self.dut.rst_n.value) == 0:
                    self._clear_current()
                    self._mode = "forbid"
                    self._held_payload = None
                    self._held_length = None

                    await RisingEdge(self.dut.clk)
                    self.cycle += 1
                    continue

                if signal_value_to_int(self.dut.seq_valid_o.value) == 1:
                    event = self._capture_sequence_event()

                    normal_accept = (
                        event.heartbeat == 0
                        and event.eos == 0
                        and event.duplicate == 0
                        and (event.in_order == 1 or event.gap == 1)
                    )

                    if normal_accept:
                        if self._current_sequence is not None:
                            raise AssertionError(
                                "new accepted Mold datagram began before the "
                                "previous payload datagram completed"
                            )
                        self._clear_current()
                        self._current_sequence = event
                        self._mode = "allow"
                    else:
                        self._clear_current()
                        self._mode = "forbid"

                mold_drop = signal_value_to_int(self.dut.mold_drop_o.value)
                mold_err = signal_value_to_int(self.dut.mold_err_o.value)

                if mold_drop:
                    aborted = self._clear_current()
                    self.drops.append(
                        DropEvent(
                            cycle=self.cycle,
                            error=mold_err,
                            aborted_payload=aborted,
                        )
                    )
                    # The RTL contract allows an already-presented payload beat
                    # to complete while an error drain is being entered.
                    self._mode = "discard"
                elif mold_err != 0:
                    raise AssertionError(
                        "mold_err_o was non-zero without mold_drop_o: "
                        f"cycle={self.cycle} err=0x{mold_err:x}"
                    )

                payload_valid = signal_value_to_int(
                    self.dut.m_payload_tvalid_o.value
                )
                payload_ready = signal_value_to_int(
                    self.dut.m_payload_tready_i.value
                )
                payload_data = signal_value_to_int(
                    self.dut.m_payload_tdata_o.value
                )
                payload_keep = signal_value_to_int(
                    self.dut.m_payload_tkeep_o.value
                )
                payload_last = signal_value_to_int(
                    self.dut.m_payload_tlast_o.value
                )
                payload_snapshot = (
                    payload_data,
                    payload_keep,
                    payload_last,
                )

                if payload_valid and not payload_ready:
                    if (
                        self._held_payload is not None
                        and payload_snapshot != self._held_payload
                    ):
                        raise AssertionError(
                            "payload output changed while valid=1 and ready=0: "
                            f"previous={self._held_payload} "
                            f"current={payload_snapshot}"
                        )
                    self._held_payload = payload_snapshot

                elif payload_valid and payload_ready:
                    if (
                        self._held_payload is not None
                        and payload_snapshot != self._held_payload
                    ):
                        raise AssertionError(
                            "backpressured payload changed on its acceptance "
                            f"cycle: held={self._held_payload} "
                            f"accepted={payload_snapshot}"
                        )
                    self._held_payload = None

                    beat_bytes = _bytes_from_beat(
                        payload_data,
                        payload_keep,
                        self.word_bytes,
                    )

                    if not beat_bytes:
                        raise AssertionError(
                            "accepted payload beat contained no valid bytes"
                        )

                    if self._mode == "forbid":
                        raise AssertionError(
                            "payload was emitted for a duplicate/control packet "
                            "or before any accepted Mold header"
                        )

                    if self._mode == "allow":
                        if self._current_sequence is None:
                            raise AssertionError(
                                "payload accepted without an active sequence event"
                            )

                        beat = CapturedPayloadBeat(
                            cycle=self.cycle,
                            data=payload_data,
                            keep=payload_keep,
                            last=payload_last,
                            byte_start=len(self._current_payload),
                            byte_count=len(beat_bytes),
                        )
                        self.all_payload_beats.append(beat)
                        self._current_beats.append(beat)
                        self._current_payload.extend(beat_bytes)

                        if payload_last:
                            self.datagrams.append(
                                CapturedDatagram(
                                    payload=bytes(self._current_payload),
                                    lengths=tuple(
                                        item.value
                                        for item in self._current_lengths
                                    ),
                                    beats=tuple(self._current_beats),
                                    length_events=tuple(self._current_lengths),
                                    sequence=self._current_sequence,
                                )
                            )
                            self._clear_current()
                            self._mode = "forbid"

                elif self._held_payload is not None:
                    raise AssertionError(
                        "m_payload_tvalid_o deasserted before a held beat "
                        "was accepted"
                    )

                length_valid = signal_value_to_int(
                    self.dut.m_msg_len_valid_o.value
                )
                length_ready = signal_value_to_int(
                    self.dut.m_msg_len_ready_i.value
                )
                length_value = signal_value_to_int(self.dut.m_msg_len_o.value)

                if length_valid and not length_ready:
                    if (
                        self._held_length is not None
                        and length_value != self._held_length
                    ):
                        raise AssertionError(
                            "message length changed while valid=1 and ready=0: "
                            f"previous={self._held_length} "
                            f"current={length_value}"
                        )
                    self._held_length = length_value

                elif length_valid and length_ready:
                    if (
                        self._held_length is not None
                        and length_value != self._held_length
                    ):
                        raise AssertionError(
                            "backpressured message length changed on its "
                            f"acceptance cycle: held={self._held_length} "
                            f"accepted={length_value}"
                        )
                    self._held_length = None

                    if self._mode == "forbid":
                        raise AssertionError(
                            "message length was emitted for a duplicate/control "
                            "packet or before any accepted Mold header"
                        )

                    if self._mode == "allow":
                        item = CapturedLength(
                            cycle=self.cycle,
                            value=length_value,
                        )
                        self.all_lengths.append(item)
                        self._current_lengths.append(item)

                elif self._held_length is not None:
                    raise AssertionError(
                        "m_msg_len_valid_o deasserted before a held descriptor "
                        "was accepted"
                    )

                await RisingEdge(self.dut.clk)
                self.cycle += 1

        except Exception as exc:
            self.failure = exc

    async def wait_for_datagrams(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            self._check_failure()
            if len(self.datagrams) >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        self._check_failure()
        raise TimeoutError(
            f"timed out waiting for {expected_count} payload datagram(s); "
            f"got {len(self.datagrams)}"
        )

    async def wait_for_sequence_events(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            self._check_failure()
            if len(self.sequence_events) >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        self._check_failure()
        raise TimeoutError(
            f"timed out waiting for {expected_count} sequence event(s); "
            f"got {len(self.sequence_events)}"
        )

    async def wait_for_drops(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            self._check_failure()
            if len(self.drops) >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        self._check_failure()
        raise TimeoutError(
            f"timed out waiting for {expected_count} Mold drop(s); "
            f"got {len(self.drops)}"
        )

    def assert_clean(self) -> None:
        self._check_failure()


def _assert_datagram(
    observed: CapturedDatagram,
    expected_payloads: list[bytes],
    *,
    seq: int,
    context: str,
    word_bytes: int,
    expected_session: bytes = SESSION,
) -> None:
    expected_payload = b"".join(expected_payloads)
    expected_lengths = tuple(len(payload) for payload in expected_payloads)

    assert observed.payload == expected_payload, (
        f"{context}: payload mismatch\n"
        f"expected={expected_payload.hex()}\n"
        f"observed={observed.payload.hex()}"
    )
    assert observed.lengths == expected_lengths, (
        f"{context}: length stream mismatch\n"
        f"expected={expected_lengths}\n"
        f"observed={observed.lengths}"
    )

    assert observed.sequence.session == int.from_bytes(
        expected_session,
        "big",
    ), f"{context}: session mismatch"
    assert observed.sequence.seq == seq, (
        f"{context}: seq expected {seq}, got {observed.sequence.seq}"
    )
    assert observed.sequence.count == len(expected_payloads), (
        f"{context}: count expected {len(expected_payloads)}, "
        f"got {observed.sequence.count}"
    )
    assert observed.sequence.expected_next == seq + len(expected_payloads), (
        f"{context}: expected_next mismatch"
    )
    assert observed.sequence.in_order == 1 or observed.sequence.gap == 1, (
        f"{context}: normal packet had neither in_order nor gap status"
    )
    assert observed.sequence.heartbeat == 0
    assert observed.sequence.eos == 0
    assert observed.sequence.duplicate == 0

    assert observed.beats, f"{context}: non-empty payload produced no beats"
    assert observed.beats[-1].last == 1, (
        f"{context}: final payload beat did not assert tlast"
    )
    assert sum(beat.last for beat in observed.beats) == 1, (
        f"{context}: expected exactly one accepted payload tlast"
    )

    final_valid = len(expected_payload) % word_bytes
    if final_valid == 0:
        final_valid = word_bytes
    expected_keep = _keep_from_count(final_valid, word_bytes)
    assert observed.beats[-1].keep == expected_keep, (
        f"{context}: final tkeep expected 0x{expected_keep:x}, "
        f"got 0x{observed.beats[-1].keep:x}"
    )

    assert len(observed.length_events) == len(expected_payloads), (
        f"{context}: expected {len(expected_payloads)} accepted length tokens, "
        f"got {len(observed.length_events)}"
    )

    # Each length token must be accepted before the output beat containing the
    # first payload byte of that message.
    byte_offset = 0
    for msg_index, (payload, length_event) in enumerate(
        zip(expected_payloads, observed.length_events, strict=True)
    ):
        first_beat = next(
            beat
            for beat in observed.beats
            if beat.byte_start
            <= byte_offset
            < beat.byte_start + beat.byte_count
        )
        assert length_event.cycle < first_beat.cycle, (
            f"{context}: message {msg_index} payload appeared before its "
            f"length token was accepted; len_cycle={length_event.cycle} "
            f"payload_cycle={first_beat.cycle}"
        )
        byte_offset += len(payload)


def _assert_drop_has_bit(
    drop: DropEvent,
    error_bit: int,
    *,
    context: str,
) -> None:
    mask = 1 << error_bit
    assert (drop.error & mask) == mask, (
        f"{context}: expected error bit {error_bit} / mask 0x{mask:04x}, "
        f"got 0x{drop.error:04x}"
    )


async def _prove_no_new_datagram(
    dut: Any,
    monitor: MoldDeframeMonitor,
    *,
    datagrams: int,
    cycles: int = 8,
) -> None:
    """Fixed interval used only to prove that no payload datagram appears."""

    for _ in range(cycles):
        await RisingEdge(dut.clk)
        monitor.assert_clean()

    assert len(monitor.datagrams) == datagrams


async def _stop_monitor(
    monitor: MoldDeframeMonitor,
    task: Any,
) -> None:
    monitor.assert_clean()
    monitor.running = False
    task.cancel()


async def _stall_next_payload(
    dut: Any,
    monitor: MoldDeframeMonitor,
    *,
    predicate: Callable[[int, int], bool],
    stall_cycles: int,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> None:
    """Stall the next visible payload beat matching predicate(last, relative)."""

    baseline = len(monitor.all_payload_beats)

    for _ in range(timeout_cycles):
        await FallingEdge(dut.clk)

        valid = signal_value_to_int(dut.m_payload_tvalid_o.value)
        last = signal_value_to_int(dut.m_payload_tlast_o.value)
        relative_accepted = len(monitor.all_payload_beats) - baseline

        if valid and predicate(last, relative_accepted):
            dut.m_payload_tready_i.value = 0

            for _ in range(stall_cycles):
                await RisingEdge(dut.clk)
                await FallingEdge(dut.clk)

            dut.m_payload_tready_i.value = 1
            return

    raise TimeoutError("timed out waiting for requested payload stall point")


async def _wait_for_signal_high(
    dut: Any,
    signal_name: str,
    *,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> None:
    signal = getattr(dut, signal_name)

    for _ in range(timeout_cycles):
        await ReadOnly()
        if signal_value_to_int(signal.value) == 1:
            return
        await RisingEdge(dut.clk)

    raise TimeoutError(f"timed out waiting for {signal_name} to assert")


@cocotb.test()
async def test_mold_deframe_extracts_payload_lengths_and_header_metadata(
    dut: Any,
) -> None:
    """One valid message is stripped, described and forwarded exactly once."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    payload = add_order_payload(
        0x101,
        side="B",
        shares=250,
        price=10_125,
        locate=11,
        tracking=22,
        timestamp_ns=33,
        stock=b"AAPL",
    )
    seq = 100
    datagram = build_mold_datagram([payload], seq=seq)

    await _drive_datagram(dut, datagram)
    await monitor.wait_for_datagrams(1)

    _assert_datagram(
        monitor.datagrams[0],
        [payload],
        seq=seq,
        context="single-message datagram",
        word_bytes=monitor.word_bytes,
    )
    assert monitor.drops == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_mold_deframe_handles_multiple_messages_and_split_prefix(
    dut: Any,
) -> None:
    """A/D/X traffic crosses a two-byte prefix over an AXI beat boundary."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    payloads = [
        add_order_payload(
            0x201,
            side="B",
            shares=100,
            price=20_100,
        ),
        delete_order_payload(0x201),
        cancel_order_payload(
            0x202,
            cancelled_shares=25,
        ),
    ]

    word_bytes = axis_word_bytes(
        dut.s_axis_tdata_i,
        dut.s_axis_tkeep_i,
        interface_name="mold_deframe input",
    )

    # Header + first block + second block puts the third length prefix on the
    # final lane for the current 64-bit implementation, so the prefix straddles
    # the next beat.
    third_prefix_offset = (
        MOLD_HEADER_BYTES
        + 2
        + len(payloads[0])
        + 2
        + len(payloads[1])
    )
    assert third_prefix_offset % word_bytes == word_bytes - 1

    seq = 200
    datagram = build_mold_datagram(payloads, seq=seq)

    await _drive_datagram(dut, datagram)
    await monitor.wait_for_datagrams(1)

    _assert_datagram(
        monitor.datagrams[0],
        payloads,
        seq=seq,
        context="A/D/X split-prefix datagram",
        word_bytes=monitor.word_bytes,
    )
    assert monitor.drops == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_mold_deframe_covers_supported_itch_message_lengths(
    dut: Any,
) -> None:
    """Every currently supported book-mutating ITCH length passes exactly."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    base_seq = 300
    payload_cases = _supported_itch_payloads()

    for index, (msg_type, payload) in enumerate(payload_cases):
        seq = base_seq + index
        await _drive_datagram(
            dut,
            build_mold_datagram([payload], seq=seq),
        )
        await monitor.wait_for_datagrams(index + 1)

        _assert_datagram(
            monitor.datagrams[index],
            [payload],
            seq=seq,
            context=f"ITCH type {msg_type} length={len(payload)}",
            word_bytes=monitor.word_bytes,
        )

    observed_lengths = [item.lengths[0] for item in monitor.datagrams]
    assert observed_lengths == [len(payload) for _, payload in payload_cases]
    assert monitor.drops == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_mold_deframe_message_alignment_sweep(dut: Any) -> None:
    """Second-message bodies and prefixes cover every active AXI byte lane."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    word_bytes = axis_word_bytes(
        dut.s_axis_tdata_i,
        dut.s_axis_tkeep_i,
        interface_name="mold_deframe input",
    )
    base_seq = 500
    next_seq = base_seq

    for target_lane in range(word_bytes):
        # The second payload starts after:
        # header(20) + prefix(2) + first payload + prefix(2).
        fixed_before_second = MOLD_HEADER_BYTES + 4
        first_len = (target_lane - (fixed_before_second % word_bytes)) % word_bytes
        if first_len == 0:
            first_len = word_bytes

        first = bytes(
            ((0x20 + target_lane + i) & 0xFF)
            for i in range(first_len)
        )
        second = bytes(
            ((0xA0 + target_lane + i) & 0xFF)
            for i in range(word_bytes + 3)
        )

        second_start = fixed_before_second + first_len
        assert second_start % word_bytes == target_lane

        prefix_start = MOLD_HEADER_BYTES + 2 + first_len
        if target_lane == 1:
            assert prefix_start % word_bytes == word_bytes - 1

        await _drive_datagram(
            dut,
            build_mold_datagram(
                [first, second],
                seq=next_seq,
            ),
        )
        await monitor.wait_for_datagrams(target_lane + 1)

        _assert_datagram(
            monitor.datagrams[-1],
            [first, second],
            seq=next_seq,
            context=f"second payload start lane={target_lane}",
            word_bytes=monitor.word_bytes,
        )

        next_seq += 2

    assert monitor.drops == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_mold_deframe_consecutive_datagrams_and_source_bubbles(
    dut: Any,
) -> None:
    """Equivalent traffic remains exact with bubbles and no output waits."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    datagrams = [
        [bytes(range(1, 18))],
        [bytes(range(0x20, 0x20 + 9)), bytes(range(0x60, 0x60 + 27))],
        [bytes(range(0x90, 0x90 + 33))],
    ]

    next_seq = 700
    expected: list[tuple[int, list[bytes]]] = []

    for packet_index, payloads in enumerate(datagrams):
        seq = next_seq
        expected.append((seq, payloads))

        await _drive_datagram(
            dut,
            build_mold_datagram(payloads, seq=seq),
            bubble_cycles=lambda beat_index, packet_index=packet_index: (
                1 if (beat_index + packet_index) % 3 == 1 else 0
            ),
        )
        next_seq += len(payloads)

    await monitor.wait_for_datagrams(len(expected))

    for index, (seq, payloads) in enumerate(expected):
        _assert_datagram(
            monitor.datagrams[index],
            payloads,
            seq=seq,
            context=f"source-bubble packet={index}",
            word_bytes=monitor.word_bytes,
        )

    assert monitor.drops == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_mold_deframe_payload_backpressure_and_stability(
    dut: Any,
) -> None:
    """First, middle and final payload stalls preserve data and eventually flow."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    cases = [
        ("first", lambda last, relative: relative == 0, 256, 20),
        ("middle", lambda last, relative: relative == 2, 80, 7),
        ("final", lambda last, relative: last == 1, 45, 7),
    ]

    next_seq = 900

    for case_index, (name, predicate, payload_len, stall_cycles) in enumerate(cases):
        payload = bytes(
            ((case_index * 53 + byte_index) & 0xFF)
            for byte_index in range(payload_len)
        )
        datagram = build_mold_datagram([payload], seq=next_seq)

        stall_task = cocotb.start_soon(
            _stall_next_payload(
                dut,
                monitor,
                predicate=predicate,
                stall_cycles=stall_cycles,
            )
        )
        stats = await _drive_datagram(dut, datagram)
        await stall_task
        await monitor.wait_for_datagrams(case_index + 1)

        _assert_datagram(
            monitor.datagrams[-1],
            [payload],
            seq=next_seq,
            context=f"{name} payload backpressure",
            word_bytes=monitor.word_bytes,
        )

        if name == "first":
            assert stats.stall_cycles > 0, (
                "long downstream stall never propagated back to the input"
            )

        next_seq += 1

    assert monitor.drops == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_mold_deframe_length_backpressure_blocks_payload(
    dut: Any,
) -> None:
    """A message payload cannot be released before its length token is accepted."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    payload = bytes((0xC0 + i) & 0xFF for i in range(37))
    seq = 1000

    await FallingEdge(dut.clk)
    dut.m_msg_len_ready_i.value = 0

    drive_task = cocotb.start_soon(
        _drive_datagram(
            dut,
            build_mold_datagram([payload], seq=seq),
        )
    )

    await _wait_for_signal_high(dut, "m_msg_len_valid_o")

    held_length = signal_value_to_int(dut.m_msg_len_o.value)
    assert held_length == len(payload)

    for cycle in range(6):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        await ReadOnly()

        assert signal_value_to_int(dut.m_msg_len_valid_o.value) == 1, (
            f"length valid dropped during backpressure at cycle {cycle}"
        )
        assert signal_value_to_int(dut.m_msg_len_o.value) == held_length, (
            f"length changed during backpressure at cycle {cycle}"
        )
        assert signal_value_to_int(dut.m_payload_tvalid_o.value) == 0, (
            "payload became valid before its length token was accepted"
        )

    # The loop samples in ReadOnly, so return to a writable phase before
    # releasing the downstream ready signal.
    await FallingEdge(dut.clk)
    dut.m_msg_len_ready_i.value = 1

    await drive_task
    await monitor.wait_for_datagrams(1)

    _assert_datagram(
        monitor.datagrams[0],
        [payload],
        seq=seq,
        context="message-length backpressure",
        word_bytes=monitor.word_bytes,
    )
    assert monitor.drops == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_mold_deframe_sequence_control_packets(dut: Any) -> None:
    """Duplicate/control packets are suppressed while a forward gap is accepted."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    first = b"first-payload"
    gap_payload = b"post-gap-payload"

    await _drive_datagram(
        dut,
        build_mold_datagram([first], seq=1100),
    )
    await monitor.wait_for_datagrams(1)

    # A duplicate of the first packet must not appear a second time.
    await _drive_datagram(
        dut,
        build_mold_datagram([first], seq=1100),
    )
    await monitor.wait_for_sequence_events(2)
    await _prove_no_new_datagram(
        dut,
        monitor,
        datagrams=1,
    )

    # expected_seq is now 1101, so 1105 records [1101, 1104] and is accepted.
    await _drive_datagram(
        dut,
        build_mold_datagram([gap_payload], seq=1105),
    )
    await monitor.wait_for_datagrams(2)

    # The accepted gap packet advances expectation to 1106. Heartbeat/EOS at
    # that exact sequence are status-only and do not emit payload.
    await _drive_datagram(
        dut,
        build_mold_datagram(
            [],
            seq=1106,
            count=MOLD_COUNT_HEARTBEAT,
        ),
    )
    await _drive_datagram(
        dut,
        build_mold_datagram(
            [],
            seq=1106,
            count=MOLD_COUNT_EOS,
        ),
    )
    await monitor.wait_for_sequence_events(5)
    await _prove_no_new_datagram(
        dut,
        monitor,
        datagrams=2,
    )

    _assert_datagram(
        monitor.datagrams[0],
        [first],
        seq=1100,
        context="first normal packet",
        word_bytes=monitor.word_bytes,
    )
    _assert_datagram(
        monitor.datagrams[1],
        [gap_payload],
        seq=1105,
        context="accepted post-gap packet",
        word_bytes=monitor.word_bytes,
    )

    first_event, duplicate, gap, heartbeat, eos = monitor.sequence_events

    assert first_event.in_order == 1
    assert duplicate.duplicate == 1
    assert duplicate.in_order == 0
    assert duplicate.gap == 0

    assert gap.gap == 1
    assert gap.stale == 1
    assert gap.gap_start == 1101
    assert gap.gap_end == 1104
    assert gap.expected_seq == 1106

    assert heartbeat.heartbeat == 1
    assert heartbeat.eos == 0
    assert eos.eos == 1
    assert eos.heartbeat == 0

    assert monitor.drops == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_mold_deframe_rejects_defined_malformed_datagrams(
    dut: Any,
) -> None:
    """Exercise every public Mold error class with a directed malformed packet."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    word_bytes = axis_word_bytes(
        dut.s_axis_tdata_i,
        dut.s_axis_tkeep_i,
        interface_name="mold_deframe input",
    )

    # SHORT_DGRAM: declared packet itself is smaller than the fixed 20-byte header.
    drops_before = len(monitor.drops)
    datagrams_before = len(monitor.datagrams)
    short = bytes(range(10))
    await _drive_datagram(dut, short)
    await monitor.wait_for_drops(drops_before + 1)
    _assert_drop_has_bit(
        monitor.drops[-1],
        MOLD_ERR_SHORT_DGRAM,
        context="short Mold datagram",
    )
    assert len(monitor.datagrams) == datagrams_before

    # Prove recovery after an early/header rejection without relying on any
    # ambiguous sequence-state behaviour from a later body-parser fault.
    recovery = b"recovered"
    await _drive_datagram(
        dut,
        build_mold_datagram([recovery], seq=1200),
    )
    await monitor.wait_for_datagrams(datagrams_before + 1)
    _assert_datagram(
        monitor.datagrams[-1],
        [recovery],
        seq=1200,
        context="recovery after short datagram",
        word_bytes=monitor.word_bytes,
    )

    # Each remaining malformed case starts from a clean sequence state. This
    # keeps this test focused on parser/error behaviour rather than defining
    # sequence rollback after a malformed normal packet.
    async def run_error_case(
        *,
        name: str,
        datagram: bytes,
        error_bit: int,
        declared_len: int | None = None,
        assert_start: bool = True,
        mutate_beats: Callable[
            [list[tuple[int, int, bool]]],
            list[tuple[int, int, bool]],
        ]
        | None = None,
    ) -> None:
        await _reset_idle(dut)

        drops_before_case = len(monitor.drops)
        datagrams_before_case = len(monitor.datagrams)

        if mutate_beats is None:
            await _drive_datagram(
                dut,
                datagram,
                declared_len=declared_len,
                assert_start=assert_start,
            )
        else:
            beats = axis_bytes_to_words(datagram, word_bytes=word_bytes)
            beats = mutate_beats(beats)
            await _drive_raw_beats(
                dut,
                beats,
                declared_len=(
                    len(datagram)
                    if declared_len is None
                    else declared_len
                ),
                assert_start=assert_start,
            )

        await monitor.wait_for_drops(drops_before_case + 1)
        _assert_drop_has_bit(
            monitor.drops[drops_before_case],
            error_bit,
            context=name,
        )
        assert len(monitor.datagrams) == datagrams_before_case, (
            f"{name}: malformed packet completed a payload datagram"
        )

    valid_one = build_mold_datagram([b"header-start"], seq=10)
    await run_error_case(
        name="missing datagram start metadata",
        datagram=valid_one,
        error_bit=MOLD_ERR_SHORT_DGRAM,
        assert_start=False,
    )

    def corrupt_body_tkeep(
        beats: list[tuple[int, int, bool]],
    ) -> list[tuple[int, int, bool]]:
        corrupted = list(beats)
        if len(corrupted) < 4:
            raise AssertionError("test datagram did not reach a body AXI beat")

        word, _, last = corrupted[3]
        if last:
            raise AssertionError("chosen bad-tkeep beat unexpectedly final")

        # Non-final beats must be full keep. A one-byte-left-aligned keep is
        # deliberately invalid here.
        corrupted[3] = (
            word,
            _keep_from_count(1, word_bytes),
            last,
        )
        return corrupted

    long_for_tkeep = build_mold_datagram(
        [bytes(range(40))],
        seq=10,
    )
    await run_error_case(
        name="bad non-final tkeep",
        datagram=long_for_tkeep,
        error_bit=MOLD_ERR_BAD_TKEEP,
        mutate_beats=corrupt_body_tkeep,
    )

    # Declared message length exceeds the remaining body.
    bad_len = bytearray(
        build_mold_datagram([b"ABCD"], seq=10)
    )
    bad_len[MOLD_HEADER_BYTES : MOLD_HEADER_BYTES + 2] = (10).to_bytes(
        2,
        "big",
    )
    await run_error_case(
        name="message length exceeds remaining body",
        datagram=bytes(bad_len),
        error_bit=MOLD_ERR_LEN_OVERRUN,
    )

    # Zero is not a legal normal-message length.
    zero_len = (
        SESSION
        + (10).to_bytes(8, "big")
        + (1).to_bytes(2, "big")
        + b"\x00\x00"
    )
    await run_error_case(
        name="zero message length",
        datagram=zero_len,
        error_bit=MOLD_ERR_LEN_OVERRUN,
    )

    # Count says one message, but a second complete block remains in the body.
    count_too_small = build_mold_datagram(
        [b"one", b"two"],
        seq=10,
        count=1,
    )
    await run_error_case(
        name="message count smaller than body relationship",
        datagram=count_too_small,
        error_bit=MOLD_ERR_COUNT_OVERRUN,
    )

    heartbeat_with_payload = build_mold_datagram(
        [b"unexpected"],
        seq=10,
        count=MOLD_COUNT_HEARTBEAT,
    )
    await run_error_case(
        name="heartbeat with body payload",
        datagram=heartbeat_with_payload,
        error_bit=MOLD_ERR_COUNT_OVERRUN,
    )

    eos_with_payload = build_mold_datagram(
        [b"unexpected"],
        seq=10,
        count=MOLD_COUNT_EOS,
    )
    await run_error_case(
        name="EOS with body payload",
        datagram=eos_with_payload,
        error_bit=MOLD_ERR_EOS_PAYLOAD,
    )

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_mold_deframe_reset_during_activity_recovers(dut: Any) -> None:
    """Reset mid-header and with a pending output, then prove clean recovery."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    word_bytes = axis_word_bytes(
        dut.s_axis_tdata_i,
        dut.s_axis_tkeep_i,
        interface_name="mold_deframe input",
    )

    # Reset after accepting only the first header beat.
    interrupted = build_mold_datagram(
        [bytes(range(32))],
        seq=1300,
    )
    interrupted_beats = axis_bytes_to_words(
        interrupted,
        word_bytes=word_bytes,
    )
    first_word, first_keep, _ = interrupted_beats[0]

    await _drive_raw_beats(
        dut,
        [(first_word, first_keep, False)],
        declared_len=len(interrupted),
    )
    await _force_reset_during_activity(dut)

    recovery_a = b"after-header-reset"
    await _drive_datagram(
        dut,
        build_mold_datagram([recovery_a], seq=1400),
    )
    await monitor.wait_for_datagrams(1)
    _assert_datagram(
        monitor.datagrams[0],
        [recovery_a],
        seq=1400,
        context="recovery after header reset",
        word_bytes=monitor.word_bytes,
    )

    # Hold the payload sink so reset occurs with a real output beat pending.
    await FallingEdge(dut.clk)
    dut.m_payload_tready_i.value = 0

    long_payload = bytes((0x70 + i) & 0xFF for i in range(160))
    drive_task = cocotb.start_soon(
        _drive_datagram(
            dut,
            build_mold_datagram([long_payload], seq=1401),
        )
    )

    await _wait_for_signal_high(dut, "m_payload_tvalid_o")
    await _force_reset_during_activity(
        dut,
        task_to_cancel=drive_task,
    )

    # _force_reset_during_activity already returns after a settled ReadOnly
    # sample of the first post-reset cycle.
    assert signal_value_to_int(dut.m_payload_tvalid_o.value) == 0
    assert signal_value_to_int(dut.m_msg_len_valid_o.value) == 0
    assert signal_value_to_int(dut.mold_drop_o.value) == 0
    assert signal_value_to_int(dut.stale_o.value) == 0
    assert signal_value_to_int(dut.expected_seq_o.value) == 0

    recovery_b = b"after-output-reset"
    await _drive_datagram(
        dut,
        build_mold_datagram([recovery_b], seq=1500),
    )
    await monitor.wait_for_datagrams(2)
    _assert_datagram(
        monitor.datagrams[-1],
        [recovery_b],
        seq=1500,
        context="recovery after pending-output reset",
        word_bytes=monitor.word_bytes,
    )

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_mold_deframe_deterministic_random_valid_stream(dut: Any) -> None:
    """Deterministic random valid traffic proves ordering, loss and duplication."""

    await _initialise(dut)
    monitor = MoldDeframeMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    rng = random.Random(TEST_SEED)
    cocotb.log.info("mold_deframe TEST_SEED=%d", TEST_SEED)

    expected: list[tuple[int, list[bytes]]] = []
    next_seq = 2000

    for packet_index in range(24):
        message_count = rng.randint(1, 4)
        payloads: list[bytes] = []

        for msg_index in range(message_count):
            payload_len = rng.randint(1, 64)
            payloads.append(
                bytes(rng.randrange(256) for _ in range(payload_len))
            )

        expected.append((next_seq, payloads))

        await _drive_datagram(
            dut,
            build_mold_datagram(
                payloads,
                seq=next_seq,
            ),
            bubble_cycles=lambda beat_index: (
                1 if rng.randrange(7) == 0 else 0
            ),
        )

        next_seq += message_count

    await monitor.wait_for_datagrams(len(expected))

    for packet_index, (seq, payloads) in enumerate(expected):
        _assert_datagram(
            monitor.datagrams[packet_index],
            payloads,
            seq=seq,
            context=(
                f"random packet={packet_index} seed={TEST_SEED}"
            ),
            word_bytes=monitor.word_bytes,
        )

    expected_lengths = [
        len(payload)
        for _, payloads in expected
        for payload in payloads
    ]
    observed_lengths = [
        item.value
        for datagram in monitor.datagrams
        for item in datagram.length_events
    ]

    assert observed_lengths == expected_lengths, (
        f"seed={TEST_SEED}: descriptor loss/duplication/reordering\n"
        f"expected={expected_lengths}\n"
        f"observed={observed_lengths}"
    )
    assert monitor.drops == [], (
        f"seed={TEST_SEED}: valid traffic produced Mold drops: "
        f"{monitor.drops}"
    )

    await _stop_monitor(monitor, monitor_task)
