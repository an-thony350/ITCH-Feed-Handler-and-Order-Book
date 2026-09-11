"""Pre-Taxi sustained-throughput regression for the native 64-bit datapath.

This test deliberately does not modify production RTL.  It drives a zero-gap
64-bit Ethernet source into the current ingress, crosses normalised 217-bit
events through a 16-entry asynchronous FIFO, then runs the existing three-book
order-book top at 100 MHz.

Default operation is measurement mode: all bottlenecks are recorded even when
the present design cannot yet satisfy the final line-rate gate.  Set
``LINE_RATE_ENFORCE=1`` once the measured bottlenecks have been removed to turn
those observations into hard pass/fail criteria.
"""

from __future__ import annotations

import json
import os
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import cocotb
from cocotb.triggers import RisingEdge

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
from itch_harness.line_rate_perf import (
    BBO_FIFO_DEPTH,
    EVENT_FIFO_DEPTH,
    LineRateMonitor,
    initialise_line_rate_probe,
    reset_line_rate_probe,
    wait_for_external_bbo,
    write_line_rate_summary,
)
from itch_harness.perf import drive_axis_frame_continuous, drive_axis_frames_continuous
from itch_harness.scoreboard import signal_value_to_int


DEFAULT_CAMPAIGN_EVENTS = 192
SMOKE_CAMPAIGN_EVENTS = 48
MAX_MOLD_BODY_BYTES = 1_452
# A healthy zero-gap campaign should make progress in far fewer cycles.
# Keep the watchdog long enough to avoid false failures, but short enough that
# a deadlocked ready/valid boundary fails in seconds rather than minutes.
TIMEOUT_CYCLES_PER_BEAT = 20_000
WAIT_TIMEOUT_NETWORK_CYCLES = 20_000
WAIT_TIMEOUT_DATA_CYCLES = 20_000
RANDOM_SEED = 0x1_7C4


@dataclass(frozen=True)
class Campaign:
    name: str
    message_type: str
    payloads: tuple[bytes, ...]
    primes: tuple[bytes, ...] = ()
    randomise_mold_counts: bool = False


def _mode() -> str:
    mode = os.environ.get("LINE_RATE_MODE", "campaign").strip().lower()
    if mode not in {"smoke", "campaign"}:
        raise ValueError(f"LINE_RATE_MODE must be smoke or campaign, got {mode!r}")
    return mode


def _event_count(mode: str) -> int:
    configured = os.environ.get("LINE_RATE_EVENT_COUNT", "").strip()
    if configured:
        count = int(configured)
    else:
        count = SMOKE_CAMPAIGN_EVENTS if mode == "smoke" else DEFAULT_CAMPAIGN_EVENTS
    if count <= 0:
        raise ValueError(f"LINE_RATE_EVENT_COUNT must be positive, got {count}")
    return count


def _enforce() -> bool:
    value = os.environ.get("LINE_RATE_ENFORCE", "0").strip().lower()
    if value in {"0", "false", "no", "off"}:
        return False
    if value in {"1", "true", "yes", "on"}:
        return True
    raise ValueError(f"invalid LINE_RATE_ENFORCE value {value!r}")


def _results_dir() -> Path:
    configured = os.environ.get("LINE_RATE_RESULTS_DIR", "").strip()
    if configured:
        return Path(configured).expanduser().resolve()
    return (
        Path(__file__).resolve().parents[2]
        / "build"
        / "perf"
        / "line_rate"
    )


def _locate(index: int) -> int:
    return (index % 3) + 1


def _side(index: int) -> str:
    return "B" if index % 2 == 0 else "S"


def _price(index: int) -> int:
    # The current 14-bit order-book price window is much wider than this range.
    return 10_000 + (index % 128)


def _prime_add(order_ref: int, index: int, *, locate: int) -> bytes:
    return add_order_payload(
        order_ref,
        side=_side(index),
        shares=10_000,
        price=_price(index),
        locate=locate,
        tracking=(0x4000 + index) & 0xFFFF,
        timestamp_ns=10_000 + index,
        stock=f"S{locate}".encode("ascii"),
    )


def _dense_campaign(
    message_type: str,
    count: int,
    *,
    ref_base: int,
) -> Campaign:
    payloads: list[bytes] = []
    primes: list[bytes] = []

    for index in range(count):
        locate = _locate(index)
        order_ref = ref_base + index

        if message_type == "A":
            payload = add_order_payload(
                order_ref,
                side=_side(index),
                shares=100 + (index % 17),
                price=_price(index),
                locate=locate,
                tracking=(index + 1) & 0xFFFF,
                timestamp_ns=index + 1,
                stock=f"S{locate}".encode("ascii"),
            )
        elif message_type == "D":
            primes.append(_prime_add(order_ref, index, locate=locate))
            payload = delete_order_payload(
                order_ref,
                locate=locate,
                tracking=(index + 1) & 0xFFFF,
                timestamp_ns=index + 1,
            )
        elif message_type == "X":
            primes.append(_prime_add(order_ref, index, locate=locate))
            payload = cancel_order_payload(
                order_ref,
                cancelled_shares=1,
                locate=locate,
                tracking=(index + 1) & 0xFFFF,
                timestamp_ns=index + 1,
            )
        elif message_type == "E":
            primes.append(_prime_add(order_ref, index, locate=locate))
            payload = execute_order_payload(
                order_ref,
                executed_shares=1,
                match_number=0xE000_0000 + index,
                locate=locate,
                tracking=(index + 1) & 0xFFFF,
                timestamp_ns=index + 1,
            )
        else:
            raise ValueError(f"unsupported dense campaign type {message_type!r}")

        payloads.append(payload)

    return Campaign(
        name=f"dense_{message_type}_{len(payloads)}",
        message_type=message_type,
        payloads=tuple(payloads),
        primes=tuple(primes),
    )


def _mixed_campaign(count: int) -> Campaign:
    operations = ("A", "F", "E", "C", "X", "D", "U")
    payloads: list[bytes] = []
    primes: list[bytes] = []

    for index in range(count):
        op = operations[index % len(operations)]
        locate = _locate(index)
        order_ref = 2_000_000 + index
        common = {
            "locate": locate,
            "tracking": (index + 1) & 0xFFFF,
            "timestamp_ns": index + 1,
        }

        if op == "A":
            payload = add_order_payload(
                order_ref,
                side=_side(index),
                shares=100 + (index % 17),
                price=_price(index),
                stock=f"S{locate}".encode("ascii"),
                **common,
            )
        elif op == "F":
            payload = add_order_with_mpid_payload(
                order_ref,
                side=_side(index),
                shares=100 + (index % 17),
                price=_price(index),
                attribution=b"PERF",
                stock=f"S{locate}".encode("ascii"),
                **common,
            )
        elif op == "E":
            primes.append(_prime_add(order_ref, index, locate=locate))
            payload = execute_order_payload(
                order_ref,
                executed_shares=1,
                match_number=0xE100_0000 + index,
                **common,
            )
        elif op == "C":
            primes.append(_prime_add(order_ref, index, locate=locate))
            payload = execute_order_with_price_payload(
                order_ref,
                executed_shares=1,
                match_number=0xC100_0000 + index,
                printable="Y",
                execution_price=_price(index),
                **common,
            )
        elif op == "X":
            primes.append(_prime_add(order_ref, index, locate=locate))
            payload = cancel_order_payload(
                order_ref,
                cancelled_shares=1,
                **common,
            )
        elif op == "D":
            primes.append(_prime_add(order_ref, index, locate=locate))
            payload = delete_order_payload(order_ref, **common)
        else:
            primes.append(_prime_add(order_ref, index, locate=locate))
            payload = replace_order_payload(
                order_ref,
                3_000_000 + index,
                shares=100 + (index % 17),
                price=_price(index),
                **common,
            )

        payloads.append(payload)

    return Campaign(
        name=f"mixed_A_F_E_C_X_D_U_{len(payloads)}",
        message_type="mixed",
        payloads=tuple(payloads),
        primes=tuple(primes),
        randomise_mold_counts=True,
    )


def _hot_book_campaign(count: int) -> Campaign:
    # Delete is the shortest supported mutation. With the current packetised
    # decoder it can already approach/exceed the fixed scheduler's 100/3 Mslot/s
    # service rate for one stock, so this is a much stronger BBO-output stress
    # than an Add-only hot-book stream.
    primes: list[bytes] = []
    payloads: list[bytes] = []
    for index in range(count):
        order_ref = 4_000_000 + index
        primes.append(_prime_add(order_ref, index, locate=1))
        payloads.append(
            delete_order_payload(
                order_ref,
                locate=1,
                tracking=(index + 1) & 0xFFFF,
                timestamp_ns=index + 1,
            )
        )

    return Campaign(
        name=f"single_hot_book_D_{count}",
        message_type="D_hot_book",
        payloads=tuple(payloads),
        primes=tuple(primes),
    )


def _campaigns(mode: str, count: int) -> list[Campaign]:
    campaigns = [
        _dense_campaign("D", count, ref_base=1_000_000),
        _dense_campaign("X", count, ref_base=1_100_000),
        _dense_campaign("E", count, ref_base=1_200_000),
        _dense_campaign("A", count, ref_base=1_300_000),
        _mixed_campaign(count),
        _hot_book_campaign(count),
    ]

    if mode == "campaign":
        return campaigns

    # Smoke mode keeps one shortest-message, one mixed and one output-contention
    # case so the test remains useful before running the full campaign.
    selected = {"D", "mixed", "D_hot_book"}
    return [case for case in campaigns if case.message_type in selected]


def _pack_frames(
    payloads: tuple[bytes, ...],
    *,
    seq_start: int,
    randomise_counts: bool,
) -> list[bytes]:
    """Pack legal Mold datagrams without exceeding a 1500-byte IPv4 payload path."""

    frames: list[bytes] = []
    sequence = seq_start
    offset = 0
    rng = random.Random(RANDOM_SEED)

    while offset < len(payloads):
        if randomise_counts:
            # Vary packet density while still making some MTU-dense packets.
            body_budget = rng.randint(256, MAX_MOLD_BODY_BYTES)
        else:
            body_budget = MAX_MOLD_BODY_BYTES

        chunk: list[bytes] = []
        used = 0
        while offset < len(payloads):
            payload = payloads[offset]
            record_bytes = 2 + len(payload)
            if chunk and used + record_bytes > body_budget:
                break
            if record_bytes > MAX_MOLD_BODY_BYTES:
                raise ValueError(
                    f"ITCH record of {record_bytes} bytes exceeds Mold body budget"
                )

            chunk.append(payload)
            used += record_bytes
            offset += 1

            if randomise_counts and used >= body_budget:
                break

        datagram = build_mold_datagram(chunk, seq=sequence)
        frame = build_eth_ipv4_udp_frame(datagram)
        if len(frame) > 1_514:
            raise AssertionError(
                f"generated frame exceeds Ethernet MTU envelope: {len(frame)} bytes"
            )
        frames.append(frame)
        sequence += len(chunk)

    return frames


async def _prime_campaign(dut: Any, primes: tuple[bytes, ...]) -> int:
    """Load semantic prerequisites slowly so they do not contaminate measurements."""

    sequence = 1
    for payload in primes:
        frame = build_eth_ipv4_udp_frame(
            build_mold_datagram([payload], seq=sequence)
        )
        await drive_axis_frame_continuous(
            dut,
            frame,
            timeout_cycles_per_beat=TIMEOUT_CYCLES_PER_BEAT,
        )
        await wait_for_external_bbo(dut)
        sequence += 1

    # A few data cycles guarantee the fixed scheduler has returned to an empty
    # steady state before the performance monitor starts.
    for _ in range(8):
        await RisingEdge(dut.data_clk)

    return sequence


def _case_failures(record: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    case = record["case"]
    expected = int(record["expected_events"])

    if record["stall_cycles"]["frame_crack_input"] != 0:
        failures.append(
            f"{case}: Ethernet source was backpressured for "
            f"{record['stall_cycles']['frame_crack_input']} network cycles"
        )
    if record["decoded_events"] != expected:
        failures.append(
            f"{case}: decoded {record['decoded_events']}/{expected} events"
        )
    if record["event_fifo_reads"] != expected:
        failures.append(
            f"{case}: order-book domain accepted "
            f"{record['event_fifo_reads']}/{expected} events"
        )
    if record["event_fifo_max_level"] >= EVENT_FIFO_DEPTH:
        failures.append(
            f"{case}: event FIFO reached/full exceeded its {EVENT_FIFO_DEPTH}-entry capacity"
        )
    if record["event_fifo_full_cycles"]:
        failures.append(
            f"{case}: event FIFO asserted full for "
            f"{record['event_fifo_full_cycles']} network cycles"
        )
    if record["internal_bbos"] != expected:
        failures.append(
            f"{case}: books produced {record['internal_bbos']}/{expected} BBO updates"
        )
    if record["external_bbos"] != expected:
        failures.append(
            f"{case}: external scheduler emitted "
            f"{record['external_bbos']}/{expected} BBO updates"
        )
    if any(record["bbo_fifo_overflow"]):
        failures.append(
            f"{case}: logical BBO FIFO occupancy reached the unsafe "
            f"{BBO_FIFO_DEPTH}-entry wrap point; HWM={record['bbo_fifo_max_occupancy']}"
        )

    return failures



def _live_snapshot(dut: Any, monitor: LineRateMonitor) -> str:
    """Return a compact snapshot of every observed ready/valid boundary."""

    def value(signal: Any) -> int:
        return signal_value_to_int(signal.value)

    capture = monitor.capture

    lines = [
        "line-rate live snapshot:",
        f"  frame      v/r={value(dut.s_frame_tvalid_i)}/{value(dut.s_frame_tready_o)}",
        (
            "  dgram      "
            f"v/r={value(dut.probe_dgram_tvalid_o)}/"
            f"{value(dut.probe_dgram_tready_o)}"
        ),
        (
            "  payload    "
            f"v/r={value(dut.probe_payload_tvalid_o)}/"
            f"{value(dut.probe_payload_tready_o)}"
        ),
        (
            "  msg_len    "
            f"v/r={value(dut.probe_msg_len_valid_o)}/"
            f"{value(dut.probe_msg_len_ready_o)}"
        ),
        (
            "  itch       "
            f"v/r={value(dut.probe_itch_tvalid_o)}/"
            f"{value(dut.probe_itch_tready_o)}"
        ),
        (
            "  decoded    "
            f"v/r={value(dut.probe_decoded_valid_o)}/"
            f"{value(dut.probe_decoded_ready_o)}"
        ),
        (
            "  event FIFO "
            f"m_v/r={value(dut.probe_fifo_m_valid_o)}/"
            f"{value(dut.probe_fifo_m_ready_o)} "
            f"level={value(dut.probe_event_fifo_wr_level_o)} "
            f"full={value(dut.probe_event_fifo_full_o)} "
            f"empty={value(dut.probe_event_fifo_empty_o)}"
        ),
        (
            "  books      "
            f"ready={value(dut.probe_book_ready_stock0_o)}/"
            f"{value(dut.probe_book_ready_stock1_o)}/"
            f"{value(dut.probe_book_ready_stock2_o)}"
        ),
        (
            "  counts     "
            f"frame_beats={len(capture.frame_fire_cycles)} "
            f"itch_beats={len(capture.itch_fire_cycles)} "
            f"itch_last={len(capture.itch_last_cycles)} "
            f"decoded={capture.decoded_event_count} "
            f"fifo_reads={capture.fifo_read_count} "
            f"internal_bbo={capture.internal_bbo_count} "
            f"external_bbo={capture.external_bbo_count}"
        ),
        (
            "  stalls     "
            f"frame={capture.frame_stall_cycles} "
            f"dgram={capture.dgram_stall_cycles} "
            f"payload={capture.payload_stall_cycles} "
            f"msg_len={capture.msg_len_stall_cycles} "
            f"itch={capture.itch_stall_cycles} "
            f"decoded={capture.decoded_stall_cycles} "
            f"fifo_read={capture.fifo_read_stall_cycles}"
        ),
        (
            "  errors     "
            f"frame={capture.frame_drop_errs} "
            f"mold={capture.mold_drop_errs} "
            f"realign={capture.realign_errs}"
        ),
    ]

    return "\n".join(lines)


@cocotb.test()
async def test_pre_taxi_sustained_line_rate(dut: Any) -> None:
    """Measure the first sustained-rate bottleneck across representative campaigns."""

    mode = _mode()
    event_count = _event_count(mode)
    enforce = _enforce()
    results_dir = _results_dir()

    await initialise_line_rate_probe(dut)

    records: list[dict[str, Any]] = []
    enforcement_failures: list[str] = []

    for campaign in _campaigns(mode, event_count):
        await reset_line_rate_probe(dut)
        next_sequence = await _prime_campaign(dut, campaign.primes)
        frames = _pack_frames(
            campaign.payloads,
            seq_start=next_sequence,
            randomise_counts=campaign.randomise_mold_counts,
        )

        monitor = LineRateMonitor(dut)
        network_task = cocotb.start_soon(monitor.run_network())
        data_task = cocotb.start_soon(monitor.run_data())


        dut._log.info(
            "%s: starting measured drive (%d events in %d frames)",
            campaign.name,
            len(campaign.payloads),
            len(frames),
        )

        try:
            await drive_axis_frames_continuous(
                dut,
                frames,
                timeout_cycles_per_beat=TIMEOUT_CYCLES_PER_BEAT,
            )
        except TimeoutError as exc:
            raise AssertionError(
                f"{campaign.name}: Ethernet drive stopped making progress\n"
                f"{_live_snapshot(dut, monitor)}"
            ) from exc

        dut._log.info(
            "%s: frame drive complete; decoded=%d fifo_reads=%d internal_bbo=%d",
            campaign.name,
            monitor.capture.decoded_event_count,
            monitor.capture.fifo_read_count,
            monitor.capture.internal_bbo_count,
        )

        try:
            await monitor.wait_for_decoded_events(
                len(campaign.payloads),
                timeout_cycles=WAIT_TIMEOUT_NETWORK_CYCLES,
            )
        except TimeoutError as exc:
            raise AssertionError(
                f"{campaign.name}: decoder did not produce all events\n"
                f"{_live_snapshot(dut, monitor)}"
            ) from exc

        try:
            await monitor.wait_for_fifo_reads(
                len(campaign.payloads),
                timeout_cycles=WAIT_TIMEOUT_DATA_CYCLES,
            )
        except TimeoutError as exc:
            raise AssertionError(
                f"{campaign.name}: event FIFO did not deliver all events\n"
                f"{_live_snapshot(dut, monitor)}"
            ) from exc

        all_internal_bbos = await monitor.wait_for_internal_bbos(
            len(campaign.payloads),
            timeout_cycles=WAIT_TIMEOUT_DATA_CYCLES,
        )
        if not all_internal_bbos:
            raise AssertionError(
                f"{campaign.name}: order books did not produce all internal BBOs\n"
                f"{_live_snapshot(dut, monitor)}"
            )

        # A single hot book receives only one fixed RR read slot every three data
        # cycles in the current RTL. Four cycles/event is therefore sufficient
        # to drain a healthy implementation, while avoiding an infinite wait if
        # a modulo-16 FIFO wrap has already lost updates.
        for _ in range(4 * len(campaign.payloads) + 64):
            await RisingEdge(dut.data_clk)

        monitor.stop()
        await network_task
        await data_task

        capture = monitor.capture
        capture.assert_protocol_clean()

        report = capture.rate_report(
            case_name=campaign.name,
            message_type=campaign.message_type,
            expected_events=len(campaign.payloads),
            frame_count=len(frames),
            primed_events=len(campaign.primes),
        )
        records.append(report)

        failures = _case_failures(report)
        enforcement_failures.extend(failures)

        dut._log.info(
            "%s: source_stalls=%d acceptance=%s decoded=%.3f Mmsg/s "
            "event_fifo_hwm=%d bbo_hwm=%s external=%d/%d deepest_stall=%s",
            campaign.name,
            report["stall_cycles"]["frame_crack_input"],
            (
                "n/a"
                if report["source_acceptance_ratio"] is None
                else f"{report['source_acceptance_ratio']:.6f}"
            ),
            (report["decoded_events_per_second"] or 0.0) / 1e6,
            report["event_fifo_max_level"],
            report["bbo_fifo_max_occupancy"],
            report["external_bbos"],
            report["expected_events"],
            report["deepest_stalled_boundary"],
        )

    write_line_rate_summary(
        results_dir=results_dir,
        records=records,
        enforcement_failures=enforcement_failures,
        mode=mode,
    )

    dut._log.info(
        "Wrote line-rate results to %s",
        results_dir / "results.json",
    )
    dut._log.info(
        "Line-rate measurement summary:\n%s",
        json.dumps(records, indent=2, sort_keys=True),
    )

    if enforce:
        assert enforcement_failures == [], (
            "line-rate gate failures:\n- " + "\n- ".join(enforcement_failures)
        )
