"""Full-chain latency, packet-packing and sustained-throughput campaigns.

Measured path:
    Ethernet frame input -> aligned ITCH -> decoded event -> selected book
    -> individual-book BBO -> order_book_top FIFO/scheduler -> external BBO

The performance wrapper is simulation-only, so these tests add no logic to the
production implementation.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import cocotb
from cocotb.triggers import RisingEdge

from itch_harness.feed_perf import (
    DEFAULT_BASE_PRICE,
    FeedHandlerPerfMonitor,
    drive_frame_and_wait_for_bbo,
    initialise_perf_feed_handler,
    reset_perf_feed_handler,
)
from itch_harness.ingress_packets import (
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
from itch_harness.perf import (
    drive_axis_frame_continuous,
    drive_axis_frames_continuous,
)


SCHEMA_VERSION = 1
DEFAULT_CAMPAIGN_MESSAGES = 192
SMOKE_CAMPAIGN_MESSAGES = 24
TIMEOUT_CYCLES = 1_000_000
QUIET_CYCLES = 4


@dataclass(frozen=True)
class LatencyCase:
    name: str
    path: str
    payload: bytes
    primes: tuple[bytes, ...] = ()



def _results_dir() -> Path:
    configured = os.environ.get("PERF_RESULTS_DIR")
    if configured:
        return Path(configured).expanduser().resolve()

    return (
        Path(__file__).resolve().parents[1]
        / "build"
        / "perf"
        / "full_chain"
    )


def _performance_mode() -> str:
    mode = os.environ.get("PERF_MODE", "campaign").strip().lower()
    if mode not in {"smoke", "campaign"}:
        raise ValueError(f"PERF_MODE must be smoke or campaign, got {mode!r}")
    return mode


def _frame(payloads: list[bytes], *, seq: int) -> bytes:
    datagram = build_mold_datagram(payloads, seq=seq)
    return build_eth_ipv4_udp_frame(datagram)


def _hash_orn(order_ref: int, *, hash_width: int = 10) -> int:
    result = 0
    for bit_index in range(64):
        if (order_ref >> bit_index) & 1:
            result ^= 1 << (bit_index % hash_width)
    return result


def _colliding_order_refs() -> tuple[int, int, int, int]:
    base = 0x155
    refs = (
        base,
        base ^ (1 << 0) ^ (1 << 10),
        base ^ (1 << 1) ^ (1 << 11),
        base ^ (1 << 2) ^ (1 << 12),
    )
    assert len(set(refs)) == 4
    assert len({_hash_orn(order_ref) for order_ref in refs}) == 1
    return refs


def _latency_cases() -> list[LatencyCase]:
    colliding_refs = _colliding_order_refs()

    cam_primes = tuple(
        add_order_payload(
            order_ref,
            side="B",
            shares=100,
            price=10_000 + index,
            locate=1,
            tracking=100 + index,
            timestamp_ns=100 + index,
        )
        for index, order_ref in enumerate(colliding_refs[:3])
    )

    cam_hit_primes = cam_primes + (
        add_order_payload(
            colliding_refs[3],
            side="B",
            shares=100,
            price=10_003,
            locate=1,
            tracking=103,
            timestamp_ns=103,
        ),
    )

    return [
        LatencyCase(
            name="A_stock0_new_best",
            path="add_free_bucket_new_best_stock0",
            payload=add_order_payload(
                1_001,
                side="B",
                shares=100,
                price=10_000,
                locate=1,
            ),
        ),
        LatencyCase(
            name="A_stock1_new_best",
            path="add_free_bucket_new_best_stock1",
            payload=add_order_payload(
                1_002,
                side="B",
                shares=100,
                price=10_000,
                locate=2,
            ),
        ),
        LatencyCase(
            name="A_stock2_new_best",
            path="add_free_bucket_new_best_stock2",
            payload=add_order_payload(
                1_003,
                side="B",
                shares=100,
                price=10_000,
                locate=3,
            ),
        ),
        LatencyCase(
            name="A_non_best",
            path="add_free_bucket_bbo_unchanged",
            primes=(
                add_order_payload(
                    2_001,
                    side="B",
                    shares=100,
                    price=10_100,
                    locate=1,
                ),
            ),
            payload=add_order_payload(
                2_002,
                side="B",
                shares=75,
                price=10_050,
                locate=1,
            ),
        ),
        LatencyCase(
            name="F_new_ask",
            path="add_mpid_free_bucket_new_best",
            payload=add_order_with_mpid_payload(
                3_001,
                side="S",
                shares=125,
                price=10_020,
                attribution=b"PERF",
                locate=1,
            ),
        ),
        LatencyCase(
            name="E_partial_reduce",
            path="hash_hit_partial_execute",
            primes=(
                add_order_payload(
                    4_001,
                    side="B",
                    shares=100,
                    price=10_000,
                    locate=1,
                ),
            ),
            payload=execute_order_payload(
                4_001,
                executed_shares=25,
                match_number=40_001,
                locate=1,
            ),
        ),
        LatencyCase(
            name="C_partial_reduce_with_price",
            path="hash_hit_execute_with_price",
            primes=(
                add_order_payload(
                    5_001,
                    side="S",
                    shares=100,
                    price=10_100,
                    locate=1,
                ),
            ),
            payload=execute_order_with_price_payload(
                5_001,
                executed_shares=20,
                match_number=50_001,
                printable="Y",
                execution_price=10_090,
                locate=1,
            ),
        ),
        LatencyCase(
            name="X_partial_cancel",
            path="hash_hit_partial_cancel",
            primes=(
                add_order_payload(
                    6_001,
                    side="B",
                    shares=100,
                    price=10_000,
                    locate=1,
                ),
            ),
            payload=cancel_order_payload(
                6_001,
                cancelled_shares=30,
                locate=1,
            ),
        ),
        LatencyCase(
            name="D_best_deplete_rescan",
            path="hash_hit_delete_current_best_bbo_rescan",
            primes=(
                add_order_payload(
                    7_001,
                    side="B",
                    shares=100,
                    price=10_000,
                    locate=1,
                ),
                add_order_payload(
                    7_002,
                    side="B",
                    shares=100,
                    price=10_010,
                    locate=1,
                ),
            ),
            payload=delete_order_payload(7_002, locate=1),
        ),
        LatencyCase(
            name="U_same_price",
            path="hash_hit_replace_same_price",
            primes=(
                add_order_payload(
                    8_001,
                    side="B",
                    shares=100,
                    price=10_000,
                    locate=1,
                ),
            ),
            payload=replace_order_payload(
                8_001,
                8_002,
                shares=150,
                price=10_000,
                locate=1,
            ),
        ),
        LatencyCase(
            name="U_different_price_new_best",
            path="hash_hit_replace_different_price_new_best",
            primes=(
                add_order_payload(
                    9_001,
                    side="S",
                    shares=100,
                    price=10_100,
                    locate=1,
                ),
            ),
            payload=replace_order_payload(
                9_001,
                9_002,
                shares=100,
                price=10_050,
                locate=1,
            ),
        ),
        LatencyCase(
            name="A_cam_fallback",
            path="three_way_bucket_full_add_to_cam",
            primes=cam_primes,
            payload=add_order_payload(
                colliding_refs[3],
                side="B",
                shares=100,
                price=10_003,
                locate=1,
                tracking=103,
                timestamp_ns=103,
            ),
        ),
        LatencyCase(
            name="D_cam_hit",
            path="cam_hit_delete",
            primes=cam_hit_primes,
            payload=delete_order_payload(
                colliding_refs[3],
                locate=1,
                tracking=104,
                timestamp_ns=104,
            ),
        ),
    ]


def _selected_latency_cases(mode: str) -> list[LatencyCase]:
    cases = _latency_cases()
    if mode == "campaign":
        return cases

    smoke_names = {
        "A_stock0_new_best",
        "E_partial_reduce",
        "D_best_deplete_rescan",
        "U_same_price",
        "A_cam_fallback",
    }
    return [case for case in cases if case.name in smoke_names]


async def _prime_case(dut: Any, case: LatencyCase) -> int:
    sequence = 1
    for prime_payload in case.primes:
        expected_stock_id = int.from_bytes(prime_payload[1:3], "big")
        observed_stock_id = await drive_frame_and_wait_for_bbo(
            dut,
            _frame([prime_payload], seq=sequence),
            timeout_cycles=TIMEOUT_CYCLES,
        )
        assert observed_stock_id == expected_stock_id, (
            f"{case.name}: priming BBO stock mismatch: "
            f"expected={expected_stock_id}, got={observed_stock_id}"
        )
        sequence += 1

    return sequence


def _throughput_packings(mode: str) -> list[int]:
    configured = os.environ.get("PERF_PACKINGS")
    if configured:
        packings = [
            int(value.strip())
            for value in configured.split(",")
            if value.strip()
        ]
    else:
        packings = [1, 4] if mode == "smoke" else [1, 2, 4, 8]

    if not packings or any(packing <= 0 for packing in packings):
        raise ValueError(f"invalid PERF_PACKINGS: {packings}")
    return packings


def _throughput_message_count(mode: str) -> int:
    default = (
        SMOKE_CAMPAIGN_MESSAGES
        if mode == "smoke"
        else DEFAULT_CAMPAIGN_MESSAGES
    )
    configured = os.environ.get("PERF_MESSAGE_COUNT")
    count = default if not configured else int(configured)
    if count <= 0:
        raise ValueError(f"PERF_MESSAGE_COUNT must be positive, got {count}")
    return count


def _throughput_payloads(message_count: int) -> list[bytes]:
    payloads: list[bytes] = []

    for index in range(message_count):
        locate = (index % 3) + 1
        side = "B" if index % 2 == 0 else "S"
        payloads.append(
            add_order_payload(
                1_000_000 + index,
                side=side,
                shares=100 + (index % 17),
                price=DEFAULT_BASE_PRICE + 1_000 + (index % 128),
                locate=locate,
                tracking=(index + 1) & 0xFFFF,
                timestamp_ns=index + 1,
                stock=f"S{locate}".encode("ascii"),
            )
        )

    return payloads


def _pack_frames(payloads: list[bytes], *, packing: int) -> list[bytes]:
    frames: list[bytes] = []
    sequence = 1

    for offset in range(0, len(payloads), packing):
        chunk = payloads[offset : offset + packing]
        frames.append(_frame(chunk, seq=sequence))
        sequence += len(chunk)

    return frames


@cocotb.test()
async def test_isolated_full_chain_latency(dut: Any) -> None:
    """Measure representative common, BBO-rescan and CAM paths."""

    mode = _performance_mode()
    clock_mhz, _ = await initialise_perf_feed_handler(dut)

    reports: list[dict[str, Any]] = []

    for case in _selected_latency_cases(mode):
        reset_to_ready_cycles = await reset_perf_feed_handler(dut)
        next_sequence = await _prime_case(dut, case)

        monitor = FeedHandlerPerfMonitor(dut)
        monitor_task = cocotb.start_soon(monitor.run())

        frame = _frame([case.payload], seq=next_sequence)
        await drive_axis_frame_continuous(
            dut,
            frame,
            timeout_cycles_per_beat=TIMEOUT_CYCLES,
        )
        await monitor.wait_for_external_bbos(
            1,
            timeout_cycles=TIMEOUT_CYCLES,
        )

        for _ in range(QUIET_CYCLES):
            await RisingEdge(dut.clk)

        monitor.stop()
        await monitor_task

        capture = monitor.capture
        capture.assert_clean(expected_events=1)

        report = capture.isolated_latency_report(
            case_name=case.name,
            path_name=case.path,
            clock_mhz=clock_mhz,
        )
        report["mode"] = mode
        report["reset_to_ready_cycles"] = reset_to_ready_cycles
        report["prime_event_count"] = len(case.primes)
        report["expected_frame_bytes"] = len(frame)
        report["expected_message_bytes"] = len(case.payload)
        reports.append(report)

        dut._log.info(
            "%s: frame->external=%d cycles, decoded->internal=%d cycles, "
            "internal->external=%d cycles",
            case.name,
            report["frame_first_to_external_bbo_cycles"],
            report["decoded_to_internal_bbo_cycles"],
            report["internal_to_external_bbo_cycles"],
        )

    result = {
        "schema_version": SCHEMA_VERSION,
        "benchmark": "full_chain_isolated_latency",
        "mode": mode,
        "clock_frequency_mhz": clock_mhz,
        "cases": reports,
    }

    results_path = _results_dir() / "latency.json"
    results_path.parent.mkdir(parents=True, exist_ok=True)
    results_path.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    dut._log.info("Wrote full-chain latency results to %s", results_path)


@cocotb.test()
async def test_sustained_full_chain_throughput(dut: Any) -> None:
    """Measure packet packing, backpressure and three-book output contention."""

    mode = _performance_mode()
    clock_mhz, _ = await initialise_perf_feed_handler(dut)
    message_count = _throughput_message_count(mode)
    payloads = _throughput_payloads(message_count)

    reports: list[dict[str, Any]] = []

    for packing in _throughput_packings(mode):
        reset_to_ready_cycles = await reset_perf_feed_handler(dut)
        frames = _pack_frames(payloads, packing=packing)

        monitor = FeedHandlerPerfMonitor(dut)
        monitor_task = cocotb.start_soon(monitor.run())

        await drive_axis_frames_continuous(
            dut,
            frames,
            timeout_cycles_per_beat=TIMEOUT_CYCLES,
        )
        await monitor.wait_for_external_bbos(
            message_count,
            timeout_cycles=TIMEOUT_CYCLES,
        )

        for _ in range(QUIET_CYCLES):
            await RisingEdge(dut.clk)

        monitor.stop()
        await monitor_task

        capture = monitor.capture
        assert len(capture.frame_start_cycles) == len(frames)
        assert len(capture.frame_last_cycles) == len(frames)
        assert len(capture.itch_last_cycles) == message_count
        assert len(capture.decoded_fire_cycles) == message_count

        report = capture.throughput_report(
            case_name=f"three_stock_adds_packing_{packing}",
            packet_packing=packing,
            expected_events=message_count,
            clock_mhz=clock_mhz,
        )
        report["mode"] = mode
        report["reset_to_ready_cycles"] = reset_to_ready_cycles
        reports.append(report)

        dut._log.info(
            "packing=%d: external=%.3f Mmsg/s, campaign=%.3f Mmsg/s, "
            "frame_stalls=%d, max_fifo=%s",
            packing,
            report["external_bbos_per_second"] / 1e6,
            report["campaign_messages_per_second"] / 1e6,
            report["frame_stall_cycles"],
            report["fifo_max_occupancy"],
        )

    result = {
        "schema_version": SCHEMA_VERSION,
        "benchmark": "full_chain_sustained_throughput",
        "mode": mode,
        "clock_frequency_mhz": clock_mhz,
        "message_count_per_case": message_count,
        "cases": reports,
    }

    results_path = _results_dir() / "throughput.json"
    results_path.parent.mkdir(parents=True, exist_ok=True)
    results_path.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    dut._log.info("Wrote full-chain throughput results to %s", results_path)
