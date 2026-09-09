"""Sustained line-rate regression for the merged ingress/decode candidate.

Scope:
    Ethernet -> frame_crack -> mold_deframe -> data_realign
             -> always-ready normalised-event sink

The source remains deliberately zero-gap, which is stricter than a physical
10GbE MAC stream. Gate mode therefore checks the measured sustained AXI frame
rate against the actual rate required by a saturated 10GbE wire after accounting
for preamble/SFD, FCS and IFG. Zero-gap stalls remain visible as a stress metric
but are not automatically a physical line-rate failure.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
import json
import os
import random
from pathlib import Path
from typing import Any

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from golden.itch_parser import parse_itch_message
from itch_harness.axis import reset_dut
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
    bytes_per_cycle,
    clock_mhz_from_env,
    drive_axis_frames_continuous,
    messages_per_second,
    start_perf_clock,
    throughput_gbps,
)
from itch_harness.scoreboard import (
    assert_data_t_matches_word,
    signal_value_to_int,
)


DEFAULT_CAMPAIGN_EVENTS = 192
SMOKE_CAMPAIGN_EVENTS = 48
MAX_MOLD_BODY_BYTES = 1_452
TIMEOUT_CYCLES_PER_BEAT = 20_000
WAIT_TIMEOUT_CYCLES = 30_000
RANDOM_SEED = 0x1_7C4

# Physical byte-times not visible on the MAC-side AXI frame stream:
# 8 preamble/SFD + 4 FCS + 12 minimum IFG.
WIRE_OVERHEAD_BYTES_PER_FRAME = 24


@dataclass(frozen=True)
class Campaign:
    name: str
    message_type: str
    payloads: tuple[bytes, ...]
    randomise_mold_counts: bool = False


@dataclass
class Capture:
    cycle: int = 0

    frame_fire_cycles: list[int] = field(default_factory=list)
    frame_fire_bytes: list[int] = field(default_factory=list)

    dgram_fire_cycles: list[int] = field(default_factory=list)
    dgram_fire_bytes: list[int] = field(default_factory=list)

    payload_fire_cycles: list[int] = field(default_factory=list)
    payload_fire_bytes: list[int] = field(default_factory=list)

    msg_len_fire_cycles: list[int] = field(default_factory=list)

    event_fire_cycles: list[int] = field(default_factory=list)
    event_words: list[int] = field(default_factory=list)

    frame_stalls: int = 0
    dgram_stalls: int = 0
    payload_stalls: int = 0
    msg_len_stalls: int = 0
    event_stalls: int = 0

    frame_errors: list[int] = field(default_factory=list)
    mold_errors: list[int] = field(default_factory=list)
    realign_errors: list[int] = field(default_factory=list)

    @property
    def frame_bytes(self) -> int:
        return sum(self.frame_fire_bytes)

    @property
    def dgram_bytes(self) -> int:
        return sum(self.dgram_fire_bytes)

    @property
    def payload_bytes(self) -> int:
        return sum(self.payload_fire_bytes)


class LineRateMonitor:
    """Snapshot combinational ready/valid before each active edge."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.capture = Capture()
        self.running = True

    async def run(self) -> None:
        while self.running:
            await FallingEdge(self.dut.clk)
            await ReadOnly()

            if signal_value_to_int(self.dut.rst_n.value) == 0:
                await RisingEdge(self.dut.clk)
                continue

            frame_valid = signal_value_to_int(
                self.dut.s_frame_tvalid_i.value
            )
            frame_ready = signal_value_to_int(
                self.dut.s_frame_tready_o.value
            )
            frame_keep = signal_value_to_int(
                self.dut.s_frame_tkeep_i.value
            )

            dgram_valid = signal_value_to_int(
                self.dut.probe_dgram_tvalid_o.value
            )
            dgram_ready = signal_value_to_int(
                self.dut.probe_dgram_tready_o.value
            )
            dgram_keep = signal_value_to_int(
                self.dut.dut.dgram_tkeep.value
            )

            payload_valid = signal_value_to_int(
                self.dut.probe_payload_tvalid_o.value
            )
            payload_ready = signal_value_to_int(
                self.dut.probe_payload_tready_o.value
            )
            payload_keep = signal_value_to_int(
                self.dut.dut.payload_tkeep.value
            )

            msg_len_valid = signal_value_to_int(
                self.dut.probe_msg_len_valid_o.value
            )
            msg_len_ready = signal_value_to_int(
                self.dut.probe_msg_len_ready_o.value
            )

            event_valid = signal_value_to_int(
                self.dut.m_event_valid_o.value
            )
            event_ready = signal_value_to_int(
                self.dut.m_event_ready_i.value
            )
            event_word = signal_value_to_int(
                self.dut.m_event_data_o.value
            )

            await RisingEdge(self.dut.clk)
            await ReadOnly()

            capture = self.capture

            if frame_valid and not frame_ready:
                capture.frame_stalls += 1
            if frame_valid and frame_ready:
                capture.frame_fire_cycles.append(capture.cycle)
                capture.frame_fire_bytes.append(frame_keep.bit_count())

            if dgram_valid and not dgram_ready:
                capture.dgram_stalls += 1
            if dgram_valid and dgram_ready:
                capture.dgram_fire_cycles.append(capture.cycle)
                capture.dgram_fire_bytes.append(dgram_keep.bit_count())

            if payload_valid and not payload_ready:
                capture.payload_stalls += 1
            if payload_valid and payload_ready:
                capture.payload_fire_cycles.append(capture.cycle)
                capture.payload_fire_bytes.append(payload_keep.bit_count())

            if msg_len_valid and not msg_len_ready:
                capture.msg_len_stalls += 1
            if msg_len_valid and msg_len_ready:
                capture.msg_len_fire_cycles.append(capture.cycle)

            if event_valid and not event_ready:
                capture.event_stalls += 1
            if event_valid and event_ready:
                capture.event_fire_cycles.append(capture.cycle)
                capture.event_words.append(event_word)

            if signal_value_to_int(self.dut.frame_drop_o.value) == 1:
                capture.frame_errors.append(
                    signal_value_to_int(self.dut.frame_err_o.value)
                )
            if signal_value_to_int(self.dut.mold_drop_o.value) == 1:
                capture.mold_errors.append(
                    signal_value_to_int(self.dut.mold_err_o.value)
                )

            realign_err = signal_value_to_int(
                self.dut.realign_err_o.value
            )
            if realign_err != 0:
                capture.realign_errors.append(realign_err)

            capture.cycle += 1

    def stop(self) -> None:
        self.running = False


def _mode() -> str:
    mode = os.environ.get("LINE_RATE_MODE", "campaign").strip().lower()
    if mode not in {"smoke", "campaign"}:
        raise ValueError(f"invalid LINE_RATE_MODE={mode!r}")
    return mode


def _event_count(mode: str) -> int:
    configured = os.environ.get("LINE_RATE_EVENT_COUNT", "").strip()
    if configured:
        count = int(configured)
    else:
        count = (
            SMOKE_CAMPAIGN_EVENTS
            if mode == "smoke"
            else DEFAULT_CAMPAIGN_EVENTS
        )
    if count <= 0:
        raise ValueError("LINE_RATE_EVENT_COUNT must be positive")
    return count


def _enforce() -> bool:
    value = os.environ.get("LINE_RATE_ENFORCE", "0").strip().lower()
    if value in {"0", "false", "no", "off"}:
        return False
    if value in {"1", "true", "yes", "on"}:
        return True
    raise ValueError(f"invalid LINE_RATE_ENFORCE={value!r}")


def _results_dir() -> Path:
    configured = os.environ.get("LINE_RATE_RESULTS_DIR", "").strip()
    if configured:
        return Path(configured).expanduser().resolve()
    return (
        Path(__file__).resolve().parents[2]
        / "build"
        / "perf"
        / "data_realign_ingress_line_rate"
    )


def _common(index: int) -> dict[str, int]:
    return {
        "locate": (index % 3) + 1,
        "tracking": (index + 1) & 0xFFFF,
        "timestamp_ns": index + 1,
    }


def _payload(message_type: str, index: int) -> bytes:
    order_ref = 1_000_000 + index
    common = _common(index)

    if message_type == "D":
        return delete_order_payload(order_ref, **common)
    if message_type == "X":
        return cancel_order_payload(
            order_ref,
            cancelled_shares=1,
            **common,
        )
    if message_type == "E":
        return execute_order_payload(
            order_ref,
            executed_shares=1,
            match_number=0xE000_0000 + index,
            **common,
        )
    if message_type == "U":
        return replace_order_payload(
            order_ref,
            2_000_000 + index,
            shares=100 + (index % 17),
            price=10_000 + (index % 128),
            **common,
        )
    if message_type == "A":
        return add_order_payload(
            order_ref,
            side="B" if index % 2 == 0 else "S",
            shares=100 + (index % 17),
            price=10_000 + (index % 128),
            stock=f"S{common['locate']}".encode("ascii"),
            **common,
        )
    if message_type == "C":
        return execute_order_with_price_payload(
            order_ref,
            executed_shares=1,
            match_number=0xC000_0000 + index,
            printable="Y",
            execution_price=10_000 + (index % 128),
            **common,
        )
    if message_type == "F":
        return add_order_with_mpid_payload(
            order_ref,
            side="B" if index % 2 == 0 else "S",
            shares=100 + (index % 17),
            price=10_000 + (index % 128),
            attribution=b"PERF",
            stock=f"S{common['locate']}".encode("ascii"),
            **common,
        )

    raise ValueError(f"unsupported message type {message_type!r}")


def _campaigns(mode: str, count: int) -> list[Campaign]:
    cases = [
        Campaign(
            name=f"dense_{message_type}_{count}",
            message_type=message_type,
            payloads=tuple(
                _payload(message_type, index)
                for index in range(count)
            ),
        )
        for message_type in ("D", "X", "E", "U", "A", "C", "F")
    ]

    operations = ("A", "F", "E", "C", "X", "D", "U")
    mixed = Campaign(
        name=f"mixed_A_F_E_C_X_D_U_{count}",
        message_type="mixed",
        payloads=tuple(
            _payload(operations[index % len(operations)], index)
            for index in range(count)
        ),
        randomise_mold_counts=True,
    )
    cases.append(mixed)

    if mode == "campaign":
        return cases

    selected = {"D", "U", "mixed"}
    return [case for case in cases if case.message_type in selected]


def _pack_frames(
    payloads: tuple[bytes, ...],
    *,
    seq_start: int,
    randomise_counts: bool,
) -> list[bytes]:
    frames: list[bytes] = []
    sequence = seq_start
    offset = 0
    rng = random.Random(RANDOM_SEED)

    while offset < len(payloads):
        body_budget = (
            rng.randint(256, MAX_MOLD_BODY_BYTES)
            if randomise_counts
            else MAX_MOLD_BODY_BYTES
        )

        chunk: list[bytes] = []
        used = 0

        while offset < len(payloads):
            payload = payloads[offset]
            record_bytes = 2 + len(payload)

            if chunk and used + record_bytes > body_budget:
                break
            if record_bytes > MAX_MOLD_BODY_BYTES:
                raise ValueError("ITCH record exceeds Mold body budget")

            chunk.append(payload)
            used += record_bytes
            offset += 1

            if randomise_counts and used >= body_budget:
                break

        frame = build_eth_ipv4_udp_frame(
            build_mold_datagram(chunk, seq=sequence)
        )
        if len(frame) > 1514:
            raise AssertionError(
                f"generated frame exceeds Ethernet MTU: {len(frame)}"
            )

        frames.append(frame)
        sequence += len(chunk)

    return frames


def _event_dict(payload: bytes, *, msg_index: int) -> dict[str, Any]:
    event = parse_itch_message(payload, msg_index=msg_index)
    assert event is not None

    record = asdict(event)
    record["op"] = event.op.value
    record["side"] = event.side.value
    return record


def _window(cycles: list[int]) -> int | None:
    if not cycles:
        return None
    return cycles[-1] - cycles[0] + 1


def _rate_record(
    *,
    case: Campaign,
    frames: list[bytes],
    capture: Capture,
    clock_mhz: float,
) -> dict[str, Any]:
    frame_window = _window(capture.frame_fire_cycles)
    event_window = _window(capture.event_fire_cycles)

    measured_gbps = (
        throughput_gbps(
            capture.frame_bytes,
            frame_window,
            clock_mhz=clock_mhz,
        )
        if frame_window not in (None, 0)
        else 0.0
    )

    generated_frame_bytes = sum(len(frame) for frame in frames)
    physical_wire_bytes = (
        generated_frame_bytes
        + WIRE_OVERHEAD_BYTES_PER_FRAME * len(frames)
    )

    required_mac_gbps = (
        10.0 * generated_frame_bytes / physical_wire_bytes
        if physical_wire_bytes
        else 0.0
    )

    stalls = {
        "frame_crack_input": capture.frame_stalls,
        "frame_crack_to_mold": capture.dgram_stalls,
        "mold_to_data_realign_payload": capture.payload_stalls,
        "mold_to_data_realign_length": capture.msg_len_stalls,
        "data_realign_output": capture.event_stalls,
    }
    stalled = [name for name, count in stalls.items() if count > 0]

    return {
        "case": case.name,
        "message_type": case.message_type,
        "clock_mhz": clock_mhz,
        "frames": len(frames),
        "expected_events": len(case.payloads),
        "decoded_events": len(capture.event_words),
        "accepted_frame_bytes": capture.frame_bytes,
        "expected_frame_bytes": generated_frame_bytes,
        "accepted_dgram_bytes": capture.dgram_bytes,
        "accepted_payload_bytes": capture.payload_bytes,
        "frame_window_cycles": frame_window,
        "input_bus_gbps": measured_gbps,
        "required_mac_gbps_for_10gbe_wire": required_mac_gbps,
        "wire_rate_margin_gbps": measured_gbps - required_mac_gbps,
        "meets_physical_10gbe_rate": measured_gbps + 1e-9 >= required_mac_gbps,
        "zero_gap_source_stalls": capture.frame_stalls,
        "zero_gap_stress_pass": capture.frame_stalls == 0,
        "completed_events_per_second": (
            messages_per_second(
                len(capture.event_words),
                event_window,
                clock_mhz=clock_mhz,
            )
            if event_window not in (None, 0)
            else 0.0
        ),
        "stall_cycles": stalls,
        "deepest_stalled_boundary": stalled[-1] if stalled else None,
        "frame_errors": capture.frame_errors,
        "mold_errors": capture.mold_errors,
        "realign_errors": capture.realign_errors,
    }


def _failures(record: dict[str, Any], mismatches: list[str]) -> list[str]:
    failures = list(mismatches)
    case = record["case"]

    if record["accepted_frame_bytes"] != record["expected_frame_bytes"]:
        failures.append(
            f"{case}: accepted Ethernet bytes "
            f"{record['accepted_frame_bytes']}/"
            f"{record['expected_frame_bytes']}"
        )
    if record["decoded_events"] != record["expected_events"]:
        failures.append(
            f"{case}: decoded {record['decoded_events']}/"
            f"{record['expected_events']} events"
        )
    if record["frame_errors"]:
        failures.append(f"{case}: frame errors {record['frame_errors']}")
    if record["mold_errors"]:
        failures.append(f"{case}: Mold errors {record['mold_errors']}")
    if record["realign_errors"]:
        failures.append(
            f"{case}: data_realign errors {record['realign_errors']}"
        )
    if not record["meets_physical_10gbe_rate"]:
        failures.append(
            f"{case}: measured {record['input_bus_gbps']:.3f} Gbit/s "
            f"is below the {record['required_mac_gbps_for_10gbe_wire']:.3f} "
            "Gbit/s MAC-side rate required for saturated 10GbE"
        )

    return failures


async def _reset_candidate(dut: Any) -> None:
    await FallingEdge(dut.clk)

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0
    dut.m_event_ready_i.value = 1

    await reset_dut(dut, cycles=5)


@cocotb.test()
async def test_candidate_merged_ingress_line_rate(dut: Any) -> None:
    mode = _mode()
    count = _event_count(mode)
    enforce = _enforce()
    clock_mhz = clock_mhz_from_env(default=156.25)

    await start_perf_clock(dut, clock_mhz=clock_mhz)
    await _reset_candidate(dut)

    records: list[dict[str, Any]] = []
    enforcement_failures: list[str] = []

    for case_index, case in enumerate(_campaigns(mode, count)):
        if case_index != 0:
            await _reset_candidate(dut)

        frames = _pack_frames(
            case.payloads,
            seq_start=1,
            randomise_counts=case.randomise_mold_counts,
        )

        monitor = LineRateMonitor(dut)
        monitor_task = cocotb.start_soon(monitor.run())

        await drive_axis_frames_continuous(
            dut,
            frames,
            timeout_cycles_per_beat=TIMEOUT_CYCLES_PER_BEAT,
        )

        for _ in range(WAIT_TIMEOUT_CYCLES):
            if len(monitor.capture.event_words) >= len(case.payloads):
                break
            await RisingEdge(dut.clk)
        else:
            raise TimeoutError(
                f"{case.name}: timed out waiting for "
                f"{len(case.payloads)} decoded events; "
                f"got {len(monitor.capture.event_words)}"
            )

        monitor.stop()
        await FallingEdge(dut.clk)
        monitor_task.cancel()

        capture = monitor.capture

        mismatches: list[str] = []
        if len(capture.event_words) == len(case.payloads):
            for index, (word, payload) in enumerate(
                zip(capture.event_words, case.payloads)
            ):
                try:
                    assert_data_t_matches_word(
                        word,
                        _event_dict(payload, msg_index=index),
                    )
                except AssertionError as exc:
                    mismatches.append(
                        f"{case.name}: event {index}: {exc}"
                    )
                    if len(mismatches) >= 8:
                        break

        record = _rate_record(
            case=case,
            frames=frames,
            capture=capture,
            clock_mhz=clock_mhz,
        )
        record["message_mismatches"] = mismatches
        records.append(record)

        case_failures = _failures(record, mismatches)
        enforcement_failures.extend(case_failures)

        dut._log.info(
            "%s: zero_gap_stalls=%d input=%.3f required=%.3f "
            "margin=%+.3f Gbit/s decoded=%d/%d deepest=%s",
            case.name,
            record["zero_gap_source_stalls"],
            record["input_bus_gbps"],
            record["required_mac_gbps_for_10gbe_wire"],
            record["wire_rate_margin_gbps"],
            record["decoded_events"],
            record["expected_events"],
            record["deepest_stalled_boundary"],
        )

    result = {
        "schema_version": 2,
        "benchmark": "data_realign_pre_taxi_ingress_line_rate",
        "mode": mode,
        "scope": "frame_crack -> mold_deframe -> data_realign -> always-ready event sink",
        "clock_mhz": clock_mhz,
        "axis_width_bits": 64,
        "wire_overhead_bytes_per_frame": WIRE_OVERHEAD_BYTES_PER_FRAME,
        "cases": records,
        "enforcement_failures": enforcement_failures,
    }

    results_dir = _results_dir()
    results_dir.mkdir(parents=True, exist_ok=True)

    (results_dir / "results.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    summary_lines = [
        "# Merged data_realign ingress line-rate regression",
        "",
        f"Mode: `{mode}`",
        "",
        f"Clock: {clock_mhz:.3f} MHz, 64-bit AXI4-Stream.",
        "",
        "Scope: `frame_crack -> mold_deframe -> data_realign -> always-ready event sink`.",
        "",
        "| Case | Frames | Zero-gap stalls | Measured Gbit/s | 10GbE-required Gbit/s | Margin | Events | Deepest stall |",
        "|---|---:|---:|---:|---:|---:|---:|---|",
    ]

    for record in records:
        summary_lines.append(
            "| {case} | {frames} | {zero_gap_source_stalls} | "
            "{input_bus_gbps:.3f} | "
            "{required_mac_gbps_for_10gbe_wire:.3f} | "
            "{wire_rate_margin_gbps:+.3f} | "
            "{decoded_events}/{expected_events} | "
            "{deepest} |".format(
                deepest=record["deepest_stalled_boundary"] or "-",
                **record,
            )
        )

    summary_lines += [
        "",
        "## Gate interpretation",
        "",
        "- Zero-gap source stalls are retained as a stress metric.",
        "- The physical 10GbE gate compares measured MAC-side frame throughput "
        "against the rate required after 8-byte preamble/SFD, 4-byte FCS and "
        "12-byte minimum IFG are accounted for.",
        "- Functional event mismatches or ingress protocol errors always fail.",
        "",
    ]

    if enforcement_failures:
        summary_lines.append("## Findings")
        summary_lines.append("")
        summary_lines.extend(
            f"- {failure}" for failure in enforcement_failures
        )
    else:
        summary_lines.append("No gate failures were observed.")

    (results_dir / "summary.md").write_text(
        "\n".join(summary_lines) + "\n",
        encoding="utf-8",
    )

    if enforce and enforcement_failures:
        raise AssertionError(
            "merged ingress line-rate gate failed:\n"
            + "\n".join(
                f"  - {failure}"
                for failure in enforcement_failures
            )
        )
