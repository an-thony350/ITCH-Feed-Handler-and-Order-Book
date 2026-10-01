"""System regression for the current Ethernet-to-event ingress path.

DUT path:
    Ethernet -> frame_crack -> mold_deframe -> data_realign -> data_t

We check the contracts that only make sense across the connected ingress blocks:
- mixed MoldUDP64 datagrams decode into the expected normalised events;
- payload compaction and message alignment survive the full ingress path;
- unsupported ITCH messages are skipped without disturbing neighbouring events;
- Mold sequence decisions suppress duplicates and accept/report forward gaps;
- heartbeat and end-of-session packets remain status-only;
- event backpressure propagates without loss, corruption or output instability;
- frame rejection happens before Mold sequence state is changed, with recovery.

"""

from __future__ import annotations

from dataclasses import asdict
from typing import Any, Callable

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from golden.itch_parser import parse_itch_message
from itch_harness.axis import axis_word_bytes, drive_axis_frame, reset_dut, wait_ready
from itch_harness.ingress_packets import (
    SESSION,
    add_order_payload,
    add_order_with_mpid_payload,
    build_eth_ipv4_udp_frame,
    build_mold_datagram,
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
FRAME_ERR_BAD_ETHERTYPE = 0


def _event_dict(payload: bytes, *, msg_index: int) -> dict[str, Any] | None:
    """Decode one ITCH payload independently for semantic comparison."""

    event = parse_itch_message(payload, msg_index=msg_index)
    if event is None:
        return None

    record = asdict(event)
    record["op"] = event.op.value
    record["side"] = event.side.value
    return record


def _system_event_payload(
    *,
    locate: int = 0,
    tracking: int = 1,
    timestamp_ns: int = 1,
    event_code: str = "O",
) -> bytes:
    """Build a valid unsupported 12-byte ITCH System Event."""

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


async def _initialise(dut: Any) -> None:
    """Start the configured ingress clock and reset inactive interfaces."""

    await start_perf_clock(dut)

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0
    dut.m_event_ready_i.value = 1

    await reset_dut(dut, cycles=RESET_CYCLES)


class IngressMonitor:
    """Collect event handshakes and public ingress status outputs."""

    def __init__(
        self,
        dut: Any,
        *,
        ready_pattern: Callable[[int], bool] | None = None,
    ) -> None:
        self.dut = dut
        self.ready_pattern = ready_pattern
        self.running = True
        self.cycle = 0

        self.event_words: list[int] = []
        self.seq_samples: list[dict[str, int]] = []

        self.frame_drop_errs: list[int] = []
        self.mold_drop_errs: list[int] = []
        self.realign_errs: list[int] = []
        self.stability_errors: list[str] = []

        self._held_event_word: int | None = None

    async def run(self) -> None:
        while self.running:
            await FallingEdge(self.dut.clk)

            ready = 1
            if self.ready_pattern is not None:
                ready = int(self.ready_pattern(self.cycle))
            self.dut.m_event_ready_i.value = ready

            await ReadOnly()
            event_valid = signal_value_to_int(self.dut.m_event_valid_o.value)
            event_word = signal_value_to_int(self.dut.m_event_data_o.value)

            if self._held_event_word is not None:
                if event_valid != 1:
                    self.stability_errors.append(
                        f"cycle={self.cycle}: event valid dropped while stalled"
                    )
                    self._held_event_word = None
                elif event_word != self._held_event_word:
                    self.stability_errors.append(
                        f"cycle={self.cycle}: stalled event changed "
                        f"from 0x{self._held_event_word:x} to 0x{event_word:x}"
                    )

            if event_valid == 1 and ready == 0 and self._held_event_word is None:
                self._held_event_word = event_word

            await RisingEdge(self.dut.clk)
            await ReadOnly()

            if event_valid == 1 and ready == 1:
                if (
                    self._held_event_word is not None
                    and event_word != self._held_event_word
                ):
                    self.stability_errors.append(
                        f"cycle={self.cycle}: accepted stalled event changed "
                        f"from 0x{self._held_event_word:x} to 0x{event_word:x}"
                    )
                self.event_words.append(event_word)
                self._held_event_word = None

            if signal_value_to_int(self.dut.seq_valid_o.value) == 1:
                self.seq_samples.append(
                    {
                        "session": signal_value_to_int(self.dut.session_o.value),
                        "seq": signal_value_to_int(self.dut.seq_o.value),
                        "count": signal_value_to_int(self.dut.count_o.value),
                        "expected_next": signal_value_to_int(
                            self.dut.expected_next_o.value
                        ),
                        "in_order": signal_value_to_int(
                            self.dut.in_order_o.value
                        ),
                        "duplicate": signal_value_to_int(
                            self.dut.duplicate_o.value
                        ),
                        "gap": signal_value_to_int(self.dut.gap_o.value),
                        "heartbeat": signal_value_to_int(
                            self.dut.heartbeat_o.value
                        ),
                        "eos": signal_value_to_int(self.dut.eos_o.value),
                        "stale": signal_value_to_int(self.dut.stale_o.value),
                        "expected_seq": signal_value_to_int(
                            self.dut.expected_seq_o.value
                        ),
                        "gap_start": signal_value_to_int(
                            self.dut.gap_start_o.value
                        ),
                        "gap_end": signal_value_to_int(
                            self.dut.gap_end_o.value
                        ),
                    }
                )

            if signal_value_to_int(self.dut.frame_drop_o.value) == 1:
                self.frame_drop_errs.append(
                    signal_value_to_int(self.dut.frame_err_o.value)
                )
            if signal_value_to_int(self.dut.mold_drop_o.value) == 1:
                self.mold_drop_errs.append(
                    signal_value_to_int(self.dut.mold_err_o.value)
                )

            realign_err = signal_value_to_int(self.dut.realign_err_o.value)
            if realign_err != 0:
                self.realign_errs.append(realign_err)

            self.cycle += 1

    async def wait_for_events(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            if len(self.event_words) >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        raise TimeoutError(
            f"timed out waiting for {expected_count} events; "
            f"got {len(self.event_words)}"
        )

    async def wait_for_seq_samples(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            if len(self.seq_samples) >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        raise TimeoutError(
            f"timed out waiting for {expected_count} sequence samples; "
            f"got {len(self.seq_samples)}"
        )

    async def wait_for_frame_drops(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            if len(self.frame_drop_errs) >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        raise TimeoutError(
            f"timed out waiting for {expected_count} frame drops; "
            f"got {len(self.frame_drop_errs)}"
        )

    def stop(self) -> None:
        self.running = False


async def _start_monitor(
    dut: Any,
    *,
    ready_pattern: Callable[[int], bool] | None = None,
) -> tuple[IngressMonitor, Any]:
    monitor = IngressMonitor(dut, ready_pattern=ready_pattern)
    task = cocotb.start_soon(monitor.run())
    return monitor, task


async def _stop_monitor(dut: Any, monitor: IngressMonitor, task: Any) -> None:
    monitor.stop()
    await FallingEdge(dut.clk)
    task.cancel()


def _assert_events(
    got_words: list[int],
    payloads: list[bytes],
    *,
    context: str,
) -> None:
    expected = [
        event
        for index, payload in enumerate(payloads)
        if (event := _event_dict(payload, msg_index=index)) is not None
    ]

    assert len(got_words) == len(expected), (
        f"{context}: expected {len(expected)} decoded events, "
        f"got {len(got_words)}"
    )

    for index, (word, event) in enumerate(zip(got_words, expected)):
        try:
            assert_data_t_matches_word(word, event)
        except AssertionError as exc:
            raise AssertionError(
                f"{context}: semantic mismatch at event index {index}"
            ) from exc


def _assert_clean_ingress(monitor: IngressMonitor, *, context: str) -> None:
    assert monitor.frame_drop_errs == [], (
        f"{context}: unexpected frame errors {monitor.frame_drop_errs}"
    )
    assert monitor.mold_drop_errs == [], (
        f"{context}: unexpected Mold errors {monitor.mold_drop_errs}"
    )
    assert monitor.realign_errs == [], (
        f"{context}: unexpected realign errors {monitor.realign_errs}"
    )
    assert monitor.stability_errors == [], (
        f"{context}: output stability failures {monitor.stability_errors}"
    )


def _assert_sequence_sample(
    sample: dict[str, int],
    *,
    seq: int,
    count: int,
    expected_seq: int,
    in_order: int = 0,
    duplicate: int = 0,
    gap: int = 0,
    heartbeat: int = 0,
    eos: int = 0,
    stale: int = 0,
    gap_start: int = 0,
    gap_end: int = 0,
    context: str,
) -> None:
    assert sample["session"] == int.from_bytes(SESSION, "big"), (
        f"{context}: session mismatch"
    )
    assert sample["seq"] == seq, (
        f"{context}: expected seq={seq}, got {sample['seq']}"
    )
    assert sample["count"] == count, (
        f"{context}: expected count={count}, got {sample['count']}"
    )
    expected_next = (seq + count) & ((1 << 64) - 1)
    assert sample["expected_next"] == expected_next, (
        f"{context}: expected expected_next={expected_next}, "
        f"got {sample['expected_next']}"
    )

    expected_flags = {
        "in_order": in_order,
        "duplicate": duplicate,
        "gap": gap,
        "heartbeat": heartbeat,
        "eos": eos,
        "stale": stale,
        "expected_seq": expected_seq,
        "gap_start": gap_start,
        "gap_end": gap_end,
    }
    observed_flags = {key: sample[key] for key in expected_flags}
    assert observed_flags == expected_flags, (
        f"{context}: sequence/status mismatch\n"
        f"expected={expected_flags}\n"
        f"observed={observed_flags}"
    )


@cocotb.test()
async def test_ingress_decodes_mixed_mold_datagram(dut: Any) -> None:
    """One Mold datagram decodes all seven supported book mutations."""

    await _initialise(dut)

    payloads = [
        add_order_payload(
            1001, side="B", shares=100, price=10_000, locate=1, tracking=1
        ),
        add_order_with_mpid_payload(
            1002,
            side="S",
            shares=125,
            price=10_020,
            attribution=b"TEST",
            locate=2,
            tracking=2,
        ),
        execute_order_payload(
            1003,
            executed_shares=10,
            match_number=10_003,
            locate=3,
            tracking=3,
        ),
        execute_order_with_price_payload(
            1004,
            executed_shares=15,
            match_number=10_004,
            printable="Y",
            execution_price=10_005,
            locate=1,
            tracking=4,
        ),
        cancel_order_payload(
            1005,
            cancelled_shares=25,
            locate=2,
            tracking=5,
        ),
        delete_order_payload(
            1006,
            locate=3,
            tracking=6,
        ),
        replace_order_payload(
            1007,
            2007,
            shares=50,
            price=10_010,
            locate=1,
            tracking=7,
        ),
    ]

    seq = 100
    frame = build_eth_ipv4_udp_frame(build_mold_datagram(payloads, seq=seq))

    monitor, task = await _start_monitor(dut)

    await drive_axis_frame(dut, frame)
    await monitor.wait_for_events(len(payloads))
    await monitor.wait_for_seq_samples(1)
    await wait_ready(dut, "s_frame_tready_o", timeout_cycles=TIMEOUT_CYCLES)

    await _stop_monitor(dut, monitor, task)

    _assert_events(
        monitor.event_words,
        payloads,
        context="mixed Mold datagram",
    )
    _assert_sequence_sample(
        monitor.seq_samples[0],
        seq=seq,
        count=len(payloads),
        expected_seq=seq + len(payloads),
        in_order=1,
        context="mixed Mold datagram",
    )
    _assert_clean_ingress(monitor, context="mixed Mold datagram")


@cocotb.test()
async def test_ingress_handles_every_payload_start_alignment(dut: Any) -> None:
    """Dense 19-byte Deletes cross every realign start lane end to end."""

    await _initialise(dut)

    word_bytes = axis_word_bytes(
        dut.s_frame_tdata_i,
        dut.s_frame_tkeep_i,
        interface_name="ingress Ethernet input",
    )

    payloads = [
        delete_order_payload(
            0x1000 + index,
            locate=(index % 3) + 1,
            tracking=index + 1,
            timestamp_ns=1000 + index,
        )
        for index in range(word_bytes * 2)
    ]

    start_offsets: list[int] = []
    cursor = 0
    for payload in payloads:
        start_offsets.append(cursor % word_bytes)
        cursor += len(payload)

    assert set(start_offsets) == set(range(word_bytes)), (
        f"test construction failed: offsets={start_offsets}, "
        f"word_bytes={word_bytes}"
    )

    seq = 200
    frame = build_eth_ipv4_udp_frame(build_mold_datagram(payloads, seq=seq))

    monitor, task = await _start_monitor(dut)

    await drive_axis_frame(dut, frame)
    await monitor.wait_for_events(len(payloads))
    await monitor.wait_for_seq_samples(1)
    await wait_ready(dut, "s_frame_tready_o", timeout_cycles=TIMEOUT_CYCLES)

    await _stop_monitor(dut, monitor, task)

    _assert_events(
        monitor.event_words,
        payloads,
        context="all payload start alignments",
    )
    _assert_sequence_sample(
        monitor.seq_samples[0],
        seq=seq,
        count=len(payloads),
        expected_seq=seq + len(payloads),
        in_order=1,
        context="all payload start alignments",
    )
    _assert_clean_ingress(monitor, context="all payload start alignments")


@cocotb.test()
async def test_ingress_skips_unsupported_message_between_valid_events(
    dut: Any,
) -> None:
    """Unsupported ITCH traffic is consumed without disturbing neighbours."""

    await _initialise(dut)

    payloads = [
        delete_order_payload(0xAAAA, locate=1),
        _system_event_payload(),
        cancel_order_payload(0xBBBB, cancelled_shares=7, locate=2),
    ]

    seq = 300
    frame = build_eth_ipv4_udp_frame(build_mold_datagram(payloads, seq=seq))

    monitor, task = await _start_monitor(dut)

    await drive_axis_frame(dut, frame)
    await monitor.wait_for_events(2)
    await monitor.wait_for_seq_samples(1)
    await wait_ready(dut, "s_frame_tready_o", timeout_cycles=TIMEOUT_CYCLES)

    await _stop_monitor(dut, monitor, task)

    _assert_events(
        monitor.event_words,
        payloads,
        context="unsupported ITCH message",
    )
    _assert_sequence_sample(
        monitor.seq_samples[0],
        seq=seq,
        count=len(payloads),
        expected_seq=seq + len(payloads),
        in_order=1,
        context="unsupported ITCH message",
    )
    _assert_clean_ingress(monitor, context="unsupported ITCH message")


@cocotb.test()
async def test_ingress_suppresses_duplicate_datagram_and_recovers(
    dut: Any,
) -> None:
    """A duplicate Mold packet produces no event and does not block recovery."""

    await _initialise(dut)

    first_payloads = [
        delete_order_payload(0x2001, locate=1),
        cancel_order_payload(0x2002, cancelled_shares=5, locate=2),
    ]
    duplicate_payloads = [
        delete_order_payload(0xDEAD, locate=1),
        delete_order_payload(0xBEEF, locate=2),
    ]
    recovery_payload = delete_order_payload(0x2003, locate=3)

    first_seq = 1000
    recovery_seq = first_seq + len(first_payloads)

    monitor, task = await _start_monitor(dut)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(
            build_mold_datagram(first_payloads, seq=first_seq)
        ),
    )
    await monitor.wait_for_events(len(first_payloads))
    await monitor.wait_for_seq_samples(1)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(
            build_mold_datagram(duplicate_payloads, seq=first_seq)
        ),
    )
    await monitor.wait_for_seq_samples(2)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(
            build_mold_datagram([recovery_payload], seq=recovery_seq)
        ),
    )
    await monitor.wait_for_events(len(first_payloads) + 1)
    await monitor.wait_for_seq_samples(3)
    await wait_ready(dut, "s_frame_tready_o", timeout_cycles=TIMEOUT_CYCLES)

    await _stop_monitor(dut, monitor, task)

    _assert_events(
        monitor.event_words,
        first_payloads + [recovery_payload],
        context="duplicate suppression and recovery",
    )
    _assert_sequence_sample(
        monitor.seq_samples[0],
        seq=first_seq,
        count=len(first_payloads),
        expected_seq=recovery_seq,
        in_order=1,
        context="initial packet before duplicate",
    )
    _assert_sequence_sample(
        monitor.seq_samples[1],
        seq=first_seq,
        count=len(duplicate_payloads),
        expected_seq=recovery_seq,
        duplicate=1,
        context="duplicate packet",
    )
    _assert_sequence_sample(
        monitor.seq_samples[2],
        seq=recovery_seq,
        count=1,
        expected_seq=recovery_seq + 1,
        in_order=1,
        context="recovery after duplicate",
    )
    _assert_clean_ingress(monitor, context="duplicate suppression and recovery")


@cocotb.test()
async def test_ingress_accepts_forward_gap_and_reports_missing_range(
    dut: Any,
) -> None:
    """A forward-gap packet is decoded while the missing range becomes stale."""

    await _initialise(dut)

    first_payload = delete_order_payload(0x3001, locate=1)
    gap_payload = delete_order_payload(0x3002, locate=2)

    first_seq = 2000
    gap_seq = 2004

    monitor, task = await _start_monitor(dut)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(
            build_mold_datagram([first_payload], seq=first_seq)
        ),
    )
    await monitor.wait_for_events(1)
    await monitor.wait_for_seq_samples(1)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(
            build_mold_datagram([gap_payload], seq=gap_seq)
        ),
    )
    await monitor.wait_for_events(2)
    await monitor.wait_for_seq_samples(2)
    await wait_ready(dut, "s_frame_tready_o", timeout_cycles=TIMEOUT_CYCLES)

    await _stop_monitor(dut, monitor, task)

    _assert_events(
        monitor.event_words,
        [first_payload, gap_payload],
        context="forward gap",
    )
    _assert_sequence_sample(
        monitor.seq_samples[0],
        seq=first_seq,
        count=1,
        expected_seq=first_seq + 1,
        in_order=1,
        context="packet before forward gap",
    )
    _assert_sequence_sample(
        monitor.seq_samples[1],
        seq=gap_seq,
        count=1,
        expected_seq=gap_seq + 1,
        gap=1,
        stale=1,
        gap_start=first_seq + 1,
        gap_end=gap_seq - 1,
        context="forward gap packet",
    )
    _assert_clean_ingress(monitor, context="forward gap")


@cocotb.test()
async def test_ingress_heartbeat_and_eos_are_status_only(dut: Any) -> None:
    """Heartbeat and EOS do not emit events or advance sequence expectation."""

    await _initialise(dut)

    payload = delete_order_payload(0x4001, locate=1)
    seq = 3000
    control_seq = seq + 1

    monitor, task = await _start_monitor(dut)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(build_mold_datagram([payload], seq=seq)),
    )
    await monitor.wait_for_events(1)
    await monitor.wait_for_seq_samples(1)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(
            build_mold_datagram([], seq=control_seq, count=0x0000)
        ),
    )
    await monitor.wait_for_seq_samples(2)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(
            build_mold_datagram([], seq=control_seq, count=0xFFFF)
        ),
    )
    await monitor.wait_for_seq_samples(3)
    await wait_ready(dut, "s_frame_tready_o", timeout_cycles=TIMEOUT_CYCLES)

    await _stop_monitor(dut, monitor, task)

    _assert_events(
        monitor.event_words,
        [payload],
        context="heartbeat/EOS status-only",
    )
    _assert_sequence_sample(
        monitor.seq_samples[0],
        seq=seq,
        count=1,
        expected_seq=control_seq,
        in_order=1,
        context="normal packet before control packets",
    )
    _assert_sequence_sample(
        monitor.seq_samples[1],
        seq=control_seq,
        count=0x0000,
        expected_seq=control_seq,
        heartbeat=1,
        context="heartbeat",
    )
    _assert_sequence_sample(
        monitor.seq_samples[2],
        seq=control_seq,
        count=0xFFFF,
        expected_seq=control_seq,
        eos=1,
        context="end of session",
    )
    _assert_clean_ingress(monitor, context="heartbeat/EOS status-only")


@cocotb.test()
async def test_ingress_preserves_events_under_output_backpressure(
    dut: Any,
) -> None:
    """Event stalls propagate without loss, corruption or valid/data changes."""

    await _initialise(dut)

    payloads = [
        delete_order_payload(
            0x5000 + index,
            locate=(index % 3) + 1,
            tracking=index + 1,
        )
        for index in range(16)
    ]
    seq = 4000
    frame = build_eth_ipv4_udp_frame(build_mold_datagram(payloads, seq=seq))

    def ready_pattern(cycle: int) -> bool:
        return cycle % 9 not in (2, 3, 4)

    monitor, task = await _start_monitor(dut, ready_pattern=ready_pattern)

    await drive_axis_frame(dut, frame)
    await monitor.wait_for_events(len(payloads))
    await monitor.wait_for_seq_samples(1)
    await wait_ready(dut, "s_frame_tready_o", timeout_cycles=TIMEOUT_CYCLES)

    await _stop_monitor(dut, monitor, task)

    _assert_events(
        monitor.event_words,
        payloads,
        context="event-output backpressure",
    )
    _assert_sequence_sample(
        monitor.seq_samples[0],
        seq=seq,
        count=len(payloads),
        expected_seq=seq + len(payloads),
        in_order=1,
        context="event-output backpressure",
    )
    _assert_clean_ingress(monitor, context="event-output backpressure")


@cocotb.test()
async def test_ingress_bad_frame_does_not_mutate_sequence_and_recovers(
    dut: Any,
) -> None:
    """A frame rejected before Mold parsing must leave sequence state untouched."""

    await _initialise(dut)

    first_payload = delete_order_payload(0x6001, locate=1)
    bad_payload = delete_order_payload(0xBAD0, locate=2)
    recovery_payload = delete_order_payload(0x6002, locate=3)

    first_seq = 5000
    recovery_seq = first_seq + 1

    monitor, task = await _start_monitor(dut)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(
            build_mold_datagram([first_payload], seq=first_seq)
        ),
    )
    await monitor.wait_for_events(1)
    await monitor.wait_for_seq_samples(1)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(
            build_mold_datagram([bad_payload], seq=recovery_seq),
            ethertype=0x86DD,
        ),
    )
    await monitor.wait_for_frame_drops(1)

    await drive_axis_frame(
        dut,
        build_eth_ipv4_udp_frame(
            build_mold_datagram([recovery_payload], seq=recovery_seq)
        ),
    )
    await monitor.wait_for_events(2)
    await monitor.wait_for_seq_samples(2)
    await wait_ready(dut, "s_frame_tready_o", timeout_cycles=TIMEOUT_CYCLES)

    await _stop_monitor(dut, monitor, task)

    _assert_events(
        monitor.event_words,
        [first_payload, recovery_payload],
        context="bad frame isolation and recovery",
    )
    assert len(monitor.seq_samples) == 2, (
        "bad Ethernet frame unexpectedly reached Mold sequence tracking"
    )
    _assert_sequence_sample(
        monitor.seq_samples[0],
        seq=first_seq,
        count=1,
        expected_seq=recovery_seq,
        in_order=1,
        context="packet before bad frame",
    )
    _assert_sequence_sample(
        monitor.seq_samples[1],
        seq=recovery_seq,
        count=1,
        expected_seq=recovery_seq + 1,
        in_order=1,
        context="recovery after bad frame",
    )

    assert len(monitor.frame_drop_errs) == 1, (
        f"expected one frame drop, got {monitor.frame_drop_errs}"
    )
    assert monitor.frame_drop_errs[0] & (1 << FRAME_ERR_BAD_ETHERTYPE), (
        "bad EtherType did not set FRAME_ERR_BAD_ETHERTYPE"
    )
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []
    assert monitor.stability_errors == []
