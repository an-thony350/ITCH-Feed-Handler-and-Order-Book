"""Correctness tests for the candidate merged ingress/decode path.

Measured path:
    Ethernet -> frame_crack -> mold_deframe -> data_realign -> data_t

The legacy ingress_top/realign/data_handler path remains untouched so these tests
are an A/B candidate gate before the production/Vivado integration is changed.
"""

from __future__ import annotations

from dataclasses import asdict
from typing import Any, Callable

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from golden.itch_parser import parse_itch_message
from itch_harness.axis import drive_axis_frame, reset_dut
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
from itch_harness.scoreboard import (
    assert_data_t_matches_word,
    signal_value_to_int,
)


CLOCK_PERIOD_NS = 6.4
TIMEOUT_CYCLES = 50_000
FRAME_ERR_BAD_ETHERTYPE = 0


def _event_dict(payload: bytes, *, msg_index: int) -> dict[str, Any] | None:
    event = parse_itch_message(payload, msg_index=msg_index)
    if event is None:
        return None

    record = asdict(event)
    record["op"] = event.op.value
    record["side"] = event.side.value
    return record


def _system_event_payload(*, event_code: str = "O") -> bytes:
    payload = (
        b"S"
        + (0).to_bytes(2, "big")
        + (1).to_bytes(2, "big")
        + (1).to_bytes(6, "big")
        + event_code.encode("ascii")
    )
    assert len(payload) == 12
    return payload


async def _initialise(dut: Any) -> None:
    cocotb.start_soon(Clock(dut.clk, CLOCK_PERIOD_NS, unit="ns").start())

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0
    dut.m_event_ready_i.value = 1

    await reset_dut(dut, cycles=5)


class CandidateIngressMonitor:
    """Collect event handshakes plus ingress status without changing the DUT."""

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

        self.heartbeat_count = 0
        self.eos_count = 0

        self.frame_drop_errs: list[int] = []
        self.mold_drop_errs: list[int] = []
        self.realign_errs: list[int] = []

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

            await RisingEdge(self.dut.clk)
            await ReadOnly()

            if event_valid == 1 and ready == 1:
                self.event_words.append(event_word)

            if signal_value_to_int(self.dut.seq_valid_o.value) == 1:
                self.seq_samples.append(
                    {
                        "session": signal_value_to_int(self.dut.session_o.value),
                        "seq": signal_value_to_int(self.dut.seq_o.value),
                        "count": signal_value_to_int(self.dut.count_o.value),
                        "expected_next": signal_value_to_int(
                            self.dut.expected_next_o.value
                        ),
                    }
                )

            if signal_value_to_int(self.dut.heartbeat_o.value) == 1:
                self.heartbeat_count += 1
            if signal_value_to_int(self.dut.eos_o.value) == 1:
                self.eos_count += 1

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

    def stop(self) -> None:
        self.running = False


def _assert_events(
    got_words: list[int],
    payloads: list[bytes],
) -> None:
    expected = [
        event
        for index, payload in enumerate(payloads)
        if (event := _event_dict(payload, msg_index=index)) is not None
    ]

    assert len(got_words) == len(expected), (
        f"expected {len(expected)} decoded events, got {len(got_words)}"
    )

    for word, event in zip(got_words, expected):
        assert_data_t_matches_word(word, event)


@cocotb.test()
async def test_candidate_ingress_decodes_mixed_mold_datagram(dut: Any) -> None:
    """One densely packed Mold datagram decodes every supported mutation."""

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

    datagram = build_mold_datagram(payloads, seq=100)
    frame = build_eth_ipv4_udp_frame(datagram)

    monitor = CandidateIngressMonitor(dut)
    task = cocotb.start_soon(monitor.run())

    await drive_axis_frame(dut, frame)
    await monitor.wait_for_events(len(payloads))

    monitor.stop()
    await FallingEdge(dut.clk)
    task.cancel()

    _assert_events(monitor.event_words, payloads)

    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []

    assert len(monitor.seq_samples) == 1
    assert monitor.seq_samples[0]["seq"] == 100
    assert monitor.seq_samples[0]["count"] == len(payloads)
    assert monitor.seq_samples[0]["expected_next"] == 100 + len(payloads)


@cocotb.test()
async def test_candidate_ingress_dense_delete_crosses_every_alignment(
    dut: Any,
) -> None:
    """Dense 19-byte deletes exercise every packed 64-bit start offset."""

    await _initialise(dut)

    payloads = [
        delete_order_payload(
            0x1000 + index,
            locate=(index % 3) + 1,
            tracking=index + 1,
            timestamp_ns=1000 + index,
        )
        for index in range(16)
    ]

    start_offsets: list[int] = []
    cursor = 0
    for payload in payloads:
        start_offsets.append(cursor % 8)
        cursor += len(payload)

    assert set(start_offsets) == set(range(8))

    frame = build_eth_ipv4_udp_frame(
        build_mold_datagram(payloads, seq=200)
    )

    monitor = CandidateIngressMonitor(dut)
    task = cocotb.start_soon(monitor.run())

    await drive_axis_frame(dut, frame)
    await monitor.wait_for_events(len(payloads))

    monitor.stop()
    await FallingEdge(dut.clk)
    task.cancel()

    _assert_events(monitor.event_words, payloads)
    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []


@cocotb.test()
async def test_candidate_ingress_skips_unsupported_message(dut: Any) -> None:
    """Unsupported ITCH traffic is consumed without disturbing neighbours."""

    await _initialise(dut)

    payloads = [
        delete_order_payload(0xAAAA, locate=1),
        _system_event_payload(),
        cancel_order_payload(0xBBBB, cancelled_shares=7, locate=2),
    ]

    frame = build_eth_ipv4_udp_frame(
        build_mold_datagram(payloads, seq=300)
    )

    monitor = CandidateIngressMonitor(dut)
    task = cocotb.start_soon(monitor.run())

    await drive_axis_frame(dut, frame)
    await monitor.wait_for_events(2)

    for _ in range(8):
        await RisingEdge(dut.clk)

    monitor.stop()
    await FallingEdge(dut.clk)
    task.cancel()

    _assert_events(monitor.event_words, payloads)
    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []


@cocotb.test()
async def test_candidate_ingress_preserves_events_under_backpressure(
    dut: Any,
) -> None:
    """Event-output stalls must propagate safely without loss/corruption."""

    await _initialise(dut)

    payloads = [
        delete_order_payload(0x2000 + index, locate=(index % 3) + 1)
        for index in range(12)
    ]
    frame = build_eth_ipv4_udp_frame(
        build_mold_datagram(payloads, seq=400)
    )

    def ready_pattern(cycle: int) -> bool:
        return cycle % 7 not in (3, 4)

    monitor = CandidateIngressMonitor(dut, ready_pattern=ready_pattern)
    task = cocotb.start_soon(monitor.run())

    await drive_axis_frame(dut, frame)
    await monitor.wait_for_events(len(payloads))

    monitor.stop()
    await FallingEdge(dut.clk)
    task.cancel()

    _assert_events(monitor.event_words, payloads)
    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []


@cocotb.test()
async def test_candidate_ingress_heartbeat_and_eos_are_status_only(
    dut: Any,
) -> None:
    """Heartbeat/EOS datagrams must not create normalised book events."""

    await _initialise(dut)

    monitor = CandidateIngressMonitor(dut)
    task = cocotb.start_soon(monitor.run())

    heartbeat = build_eth_ipv4_udp_frame(
        build_mold_datagram([], seq=500, count=0x0000)
    )
    eos = build_eth_ipv4_udp_frame(
        build_mold_datagram([], seq=600, count=0xFFFF)
    )

    await drive_axis_frame(dut, heartbeat)
    for _ in range(30):
        await RisingEdge(dut.clk)

    await drive_axis_frame(dut, eos)
    for _ in range(60):
        await RisingEdge(dut.clk)

    monitor.stop()
    await FallingEdge(dut.clk)
    task.cancel()

    assert monitor.event_words == []
    assert monitor.heartbeat_count == 1
    assert monitor.eos_count == 1
    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []


@cocotb.test()
async def test_candidate_ingress_drops_bad_ethertype(dut: Any) -> None:
    """frame_crack must still reject malformed Ethernet before decoding."""

    await _initialise(dut)

    payload = delete_order_payload(0xDEAD, locate=1)
    frame = build_eth_ipv4_udp_frame(
        build_mold_datagram([payload], seq=700),
        ethertype=0x86DD,
    )

    monitor = CandidateIngressMonitor(dut)
    task = cocotb.start_soon(monitor.run())

    await drive_axis_frame(dut, frame)
    for _ in range(80):
        await RisingEdge(dut.clk)

    monitor.stop()
    await FallingEdge(dut.clk)
    task.cancel()

    assert monitor.event_words == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []
    assert any(
        err & (1 << FRAME_ERR_BAD_ETHERTYPE)
        for err in monitor.frame_drop_errs
    )
