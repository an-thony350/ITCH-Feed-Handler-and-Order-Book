"""Ingress-only sustained-throughput regression for the native 64-bit path.

This test deliberately stops at the aligned ITCH-message boundary:

    Ethernet -> frame_crack -> mold_deframe -> realign -> always-ready sink

No data_handler, CDC FIFO, symbol router, or order book is instantiated.  This
makes any source backpressure attributable to the Taxi-facing ingress itself.

Measurement mode always writes/updates the report, even when a case misses the
event count or encounters stalls.  Set ``LINE_RATE_ENFORCE=1`` only when the
isolated ingress is ready to be used as a hard gate.
"""

from __future__ import annotations

import json
import os
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from itch_harness.axis import axis_word_bytes, reset_dut
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
    IngressPerfCapture,
    bytes_per_cycle,
    clock_mhz_from_env,
    drive_axis_frames_continuous,
    initialise_perf_ingress,
    messages_per_second,
    throughput_gbps,
)
from itch_harness.scoreboard import signal_value_to_int


DEFAULT_CAMPAIGN_EVENTS = 192
SMOKE_CAMPAIGN_EVENTS = 48
MAX_MOLD_BODY_BYTES = 1_452

TIMEOUT_CYCLES_PER_BEAT = 20_000
WAIT_TIMEOUT_CYCLES = 20_000
RANDOM_SEED = 0x1_7C4


class IngressLineRateMonitor:
    """Sample ready/valid state before the active edge.

    The older ingress performance monitor samples combinational ready/valid
    signals after the rising edge. That is fine for stable always-ready paths,
    but a destination may change ready as a consequence of the transfer on that
    same edge. For sustained-rate accounting that can miss a real handshake or
    count a handshake that did not occur.

    This monitor samples all transfer inputs on the falling half-cycle, after
    combinational logic has settled, then commits those observations on the next
    rising edge. That matches the source driver's own pre-edge ready sampling.
    """

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.capture = IngressPerfCapture()

        self.running = True
        self.cycle = 0
        self._current_message = bytearray()
        self._itch_word_bytes = axis_word_bytes(
            dut.m_itch_tdata_o,
            interface_name="m_itch",
        )

    async def run(self) -> None:
        while self.running:
            await FallingEdge(self.dut.clk)
            await ReadOnly()

            if signal_value_to_int(self.dut.rst_n.value) == 0:
                await RisingEdge(self.dut.clk)
                continue

            # Snapshot every ready/valid boundary before the active edge.
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
                self.dut.probe_dgram_tkeep_o.value
            )

            payload_valid = signal_value_to_int(
                self.dut.probe_payload_tvalid_o.value
            )
            payload_ready = signal_value_to_int(
                self.dut.probe_payload_tready_o.value
            )
            payload_keep = signal_value_to_int(
                self.dut.probe_payload_tkeep_o.value
            )

            msg_len_valid = signal_value_to_int(
                self.dut.probe_msg_len_valid_o.value
            )
            msg_len_ready = signal_value_to_int(
                self.dut.probe_msg_len_ready_o.value
            )

            itch_valid = signal_value_to_int(
                self.dut.m_itch_tvalid_o.value
            )
            itch_ready = signal_value_to_int(
                self.dut.m_itch_tready_i.value
            )
            itch_last = signal_value_to_int(
                self.dut.m_itch_tlast_o.value
            )
            itch_word = signal_value_to_int(
                self.dut.m_itch_tdata_o.value
            )

            await RisingEdge(self.dut.clk)
            await ReadOnly()

            capture = self.capture

            if frame_valid == 1 and frame_ready == 0:
                capture.frame_stall_cycles += 1
            if frame_valid == 1 and frame_ready == 1:
                capture.frame_fire_cycles.append(self.cycle)
                capture.frame_fire_bytes.append(frame_keep.bit_count())

            if dgram_valid == 1 and dgram_ready == 0:
                capture.dgram_stall_cycles += 1
            if dgram_valid == 1 and dgram_ready == 1:
                capture.dgram_fire_cycles.append(self.cycle)
                capture.dgram_fire_bytes.append(dgram_keep.bit_count())

            if payload_valid == 1 and payload_ready == 0:
                capture.payload_stall_cycles += 1
            if payload_valid == 1 and payload_ready == 1:
                capture.payload_fire_cycles.append(self.cycle)
                capture.payload_fire_bytes.append(payload_keep.bit_count())

            if msg_len_valid == 1 and msg_len_ready == 0:
                capture.msg_len_stall_cycles += 1
            if msg_len_valid == 1 and msg_len_ready == 1:
                capture.msg_len_fire_cycles.append(self.cycle)

            if itch_valid == 1 and itch_ready == 0:
                capture.itch_stall_cycles += 1
            if itch_valid == 1 and itch_ready == 1:
                capture.itch_fire_cycles.append(self.cycle)
                self._current_message.extend(
                    itch_word.to_bytes(self._itch_word_bytes, "big")
                )

                if itch_last == 1:
                    capture.itch_last_cycles.append(self.cycle)
                    capture.messages.append(bytes(self._current_message))
                    self._current_message.clear()

            # Error/status outputs are registered by the RTL, so sample them
            # after the edge that generated the pulse.
            if signal_value_to_int(self.dut.frame_drop_o.value) == 1:
                capture.frame_drop_cycles.append(self.cycle)
                capture.frame_drop_errs.append(
                    signal_value_to_int(self.dut.frame_err_o.value)
                )

            if signal_value_to_int(self.dut.mold_drop_o.value) == 1:
                capture.mold_drop_cycles.append(self.cycle)
                capture.mold_drop_errs.append(
                    signal_value_to_int(self.dut.mold_err_o.value)
                )

            realign_err = signal_value_to_int(
                self.dut.realign_err_o.value
            )
            if realign_err != 0:
                capture.realign_err_cycles.append(self.cycle)
                capture.realign_errs.append(realign_err)

            self.cycle += 1

    def stop(self) -> None:
        self.running = False


@dataclass(frozen=True)
class Campaign:
    name: str
    message_type: str
    payloads: tuple[bytes, ...]
    randomise_mold_counts: bool = False


def _mode() -> str:
    mode = os.environ.get("LINE_RATE_MODE", "campaign").strip().lower()
    if mode not in {"smoke", "campaign"}:
        raise ValueError(
            f"LINE_RATE_MODE must be smoke or campaign, got {mode!r}"
        )
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
        raise ValueError(
            f"LINE_RATE_EVENT_COUNT must be positive, got {count}"
        )
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
        / "ingress_line_rate"
    )


def _locate(index: int) -> int:
    return (index % 3) + 1


def _side(index: int) -> str:
    return "B" if index % 2 == 0 else "S"


def _price(index: int) -> int:
    return 10_000 + (index % 128)


def _payload(
    message_type: str,
    index: int,
    *,
    ref_base: int,
) -> bytes:
    locate = _locate(index)
    order_ref = ref_base + index
    common = {
        "locate": locate,
        "tracking": (index + 1) & 0xFFFF,
        "timestamp_ns": index + 1,
    }

    if message_type == "A":
        return add_order_payload(
            order_ref,
            side=_side(index),
            shares=100 + (index % 17),
            price=_price(index),
            stock=f"S{locate}".encode("ascii"),
            **common,
        )

    if message_type == "F":
        return add_order_with_mpid_payload(
            order_ref,
            side=_side(index),
            shares=100 + (index % 17),
            price=_price(index),
            attribution=b"PERF",
            stock=f"S{locate}".encode("ascii"),
            **common,
        )

    if message_type == "E":
        return execute_order_payload(
            order_ref,
            executed_shares=1,
            match_number=0xE000_0000 + index,
            **common,
        )

    if message_type == "C":
        return execute_order_with_price_payload(
            order_ref,
            executed_shares=1,
            match_number=0xC000_0000 + index,
            printable="Y",
            execution_price=_price(index),
            **common,
        )

    if message_type == "X":
        return cancel_order_payload(
            order_ref,
            cancelled_shares=1,
            **common,
        )

    if message_type == "D":
        return delete_order_payload(
            order_ref,
            **common,
        )

    if message_type == "U":
        return replace_order_payload(
            order_ref,
            8_000_000 + index,
            shares=100 + (index % 17),
            price=_price(index),
            **common,
        )

    raise ValueError(f"unsupported campaign type {message_type!r}")


def _dense_campaign(
    message_type: str,
    count: int,
    *,
    ref_base: int,
) -> Campaign:
    payloads = tuple(
        _payload(message_type, index, ref_base=ref_base)
        for index in range(count)
    )
    return Campaign(
        name=f"dense_{message_type}_{count}",
        message_type=message_type,
        payloads=payloads,
    )


def _mixed_campaign(count: int) -> Campaign:
    operations = ("A", "F", "E", "C", "X", "D", "U")
    payloads = tuple(
        _payload(
            operations[index % len(operations)],
            index,
            ref_base=7_000_000,
        )
        for index in range(count)
    )

    return Campaign(
        name=f"mixed_A_F_E_C_X_D_U_{count}",
        message_type="mixed",
        payloads=payloads,
        randomise_mold_counts=True,
    )


def _campaigns(mode: str, count: int) -> list[Campaign]:
    campaigns = [
        _dense_campaign("D", count, ref_base=1_000_000),
        _dense_campaign("X", count, ref_base=1_100_000),
        _dense_campaign("E", count, ref_base=1_200_000),
        _dense_campaign("U", count, ref_base=1_300_000),
        _dense_campaign("A", count, ref_base=1_400_000),
        _dense_campaign("C", count, ref_base=1_500_000),
        _dense_campaign("F", count, ref_base=1_600_000),
        _mixed_campaign(count),
    ]

    if mode == "campaign":
        return campaigns

    # Smoke mode keeps the shortest supported message, the longest supported
    # message, and a mixed-length packetisation case.
    selected = {"D", "F", "mixed"}
    return [
        campaign
        for campaign in campaigns
        if campaign.message_type in selected
    ]


def _pack_frames(
    payloads: tuple[bytes, ...],
    *,
    randomise_counts: bool,
) -> tuple[list[bytes], list[bytes]]:
    """Pack legal Mold datagrams into MTU-sized Ethernet frames."""

    frames: list[bytes] = []
    datagrams: list[bytes] = []

    sequence = 1
    offset = 0
    rng = random.Random(RANDOM_SEED)

    while offset < len(payloads):
        if randomise_counts:
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

        datagrams.append(datagram)
        frames.append(frame)
        sequence += len(chunk)

    return frames, datagrams


async def _reset_ingress(dut: Any) -> None:
    """Restore an idle, always-ready ingress between measured campaigns."""

    # A monitor can stop immediately after ReadOnly(), so move to a writable
    # simulator phase before touching the DUT.
    await FallingEdge(dut.clk)

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0
    dut.m_itch_tready_i.value = 1

    await reset_dut(dut, cycles=8)


async def _wait_for_messages(
    dut: Any,
    monitor: IngressPerfMonitor,
    expected_count: int,
) -> bool:
    for _ in range(WAIT_TIMEOUT_CYCLES):
        if monitor.capture.completed_message_count >= expected_count:
            return True
        await RisingEdge(dut.clk)
    return False


def _window(cycles: list[int]) -> int | None:
    if not cycles:
        return None
    return cycles[-1] - cycles[0] + 1


def _bytes_per_cycle_or_none(
    byte_count: int,
    cycles: list[int],
) -> float | None:
    elapsed = _window(cycles)
    if elapsed is None:
        return None
    return bytes_per_cycle(byte_count, elapsed)


def _gbps_or_none(
    byte_count: int,
    cycles: list[int],
    *,
    clock_mhz: float,
) -> float | None:
    elapsed = _window(cycles)
    if elapsed is None:
        return None
    return throughput_gbps(
        byte_count,
        elapsed,
        clock_mhz=clock_mhz,
    )


def _messages_per_second_or_none(
    count: int,
    cycles: list[int],
    *,
    clock_mhz: float,
) -> float | None:
    elapsed = _window(cycles)
    if elapsed is None:
        return None
    return messages_per_second(
        count,
        elapsed,
        clock_mhz=clock_mhz,
    )


def _message_mismatches(
    captured: list[bytes],
    expected: tuple[bytes, ...],
) -> list[int]:
    mismatches: list[int] = []

    for index, got_raw in enumerate(captured[: len(expected)]):
        wanted = expected[index]
        got_payload = got_raw[: len(wanted)]
        got_padding = got_raw[len(wanted) :]

        if got_payload != wanted:
            mismatches.append(index)
            continue

        if got_padding != b"\x00" * len(got_padding):
            mismatches.append(index)

    return mismatches


def _rate_report(
    capture: IngressPerfCapture,
    *,
    campaign: Campaign,
    frames: list[bytes],
    datagrams: list[bytes],
    clock_mhz: float,
    drive_timeout: bool,
    drain_timeout: bool,
) -> dict[str, Any]:
    frame_window = _window(capture.frame_fire_cycles)
    accepted_frame_beats = len(capture.frame_fire_cycles)

    source_acceptance_ratio = (
        accepted_frame_beats / frame_window
        if frame_window not in (None, 0)
        else None
    )

    stalls = {
        "frame_crack_input": capture.frame_stall_cycles,
        "frame_crack_to_mold": capture.dgram_stall_cycles,
        "mold_to_realign_payload": capture.payload_stall_cycles,
        "mold_to_realign_length": capture.msg_len_stall_cycles,
        "realign_output": capture.itch_stall_cycles,
    }
    stalled_boundaries = [
        name for name, count in stalls.items() if count > 0
    ]

    return {
        "case": campaign.name,
        "message_type": campaign.message_type,
        "expected_messages": len(campaign.payloads),
        "frames": len(frames),
        "clock_mhz": clock_mhz,
        "drive_timeout": drive_timeout,
        "drain_timeout": drain_timeout,
        "expected_frame_bytes": sum(len(frame) for frame in frames),
        "accepted_frame_beats": accepted_frame_beats,
        "accepted_frame_bytes": capture.accepted_frame_bytes,
        "expected_dgram_bytes": sum(len(datagram) for datagram in datagrams),
        "accepted_dgram_bytes": capture.accepted_dgram_bytes,
        "expected_payload_bytes": sum(len(payload) for payload in campaign.payloads),
        "accepted_payload_bytes": capture.accepted_payload_bytes,
        "accepted_payload_beats": len(capture.payload_fire_cycles),
        "accepted_itch_beats": len(capture.itch_fire_cycles),
        "completed_messages": capture.completed_message_count,
        "message_mismatches": _message_mismatches(
            capture.messages,
            campaign.payloads,
        ),
        "frame_window_cycles": frame_window,
        "source_acceptance_ratio": source_acceptance_ratio,
        "input_bytes_per_cycle": _bytes_per_cycle_or_none(
            capture.accepted_frame_bytes,
            capture.frame_fire_cycles,
        ),
        "input_bus_gbps": _gbps_or_none(
            capture.accepted_frame_bytes,
            capture.frame_fire_cycles,
            clock_mhz=clock_mhz,
        ),
        "dgram_bytes_per_cycle": _bytes_per_cycle_or_none(
            capture.accepted_dgram_bytes,
            capture.dgram_fire_cycles,
        ),
        "payload_bytes_per_cycle": _bytes_per_cycle_or_none(
            capture.accepted_payload_bytes,
            capture.payload_fire_cycles,
        ),
        "completed_messages_per_second": _messages_per_second_or_none(
            capture.completed_message_count,
            capture.itch_last_cycles,
            clock_mhz=clock_mhz,
        ),
        "stall_cycles": stalls,
        "deepest_stalled_boundary": (
            stalled_boundaries[-1] if stalled_boundaries else None
        ),
        "frame_errors": capture.frame_drop_errs,
        "mold_errors": capture.mold_drop_errs,
        "realign_errors": capture.realign_errs,
    }


def _case_failures(record: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    case = record["case"]

    if record["drive_timeout"]:
        failures.append(f"{case}: Ethernet source drive timed out")

    if record["drain_timeout"]:
        failures.append(
            f"{case}: ingress did not drain all expected ITCH messages"
        )

    if record["stall_cycles"]["frame_crack_input"] != 0:
        failures.append(
            f"{case}: Ethernet source was backpressured for "
            f"{record['stall_cycles']['frame_crack_input']} cycles"
        )

    if record["accepted_frame_bytes"] != record["expected_frame_bytes"]:
        failures.append(
            f"{case}: accepted "
            f"{record['accepted_frame_bytes']}/{record['expected_frame_bytes']} "
            "Ethernet bytes"
        )

    if record["accepted_dgram_bytes"] != record["expected_dgram_bytes"]:
        failures.append(
            f"{case}: recovered "
            f"{record['accepted_dgram_bytes']}/{record['expected_dgram_bytes']} "
            "UDP/Mold bytes"
        )

    if record["accepted_payload_bytes"] != record["expected_payload_bytes"]:
        failures.append(
            f"{case}: recovered "
            f"{record['accepted_payload_bytes']}/{record['expected_payload_bytes']} "
            "Mold payload bytes"
        )

    if record["completed_messages"] != record["expected_messages"]:
        failures.append(
            f"{case}: completed "
            f"{record['completed_messages']}/{record['expected_messages']} "
            "ITCH messages"
        )

    if record["message_mismatches"]:
        failures.append(
            f"{case}: recovered ITCH byte mismatches at indices "
            f"{record['message_mismatches'][:8]}"
        )

    if record["frame_errors"]:
        failures.append(
            f"{case}: frame errors observed: {record['frame_errors']}"
        )

    if record["mold_errors"]:
        failures.append(
            f"{case}: MoldUDP64 errors observed: {record['mold_errors']}"
        )

    if record["realign_errors"]:
        failures.append(
            f"{case}: realign errors observed: {record['realign_errors']}"
        )

    if record["stall_cycles"]["realign_output"] != 0:
        failures.append(
            f"{case}: aligned ITCH output stalled even though the sink was "
            "forced ready"
        )

    return failures


def _write_summary(
    *,
    results_dir: Path,
    records: list[dict[str, Any]],
    enforcement_failures: list[str],
    mode: str,
    clock_mhz: float,
) -> None:
    """Write the current result set after every campaign."""

    results_dir.mkdir(parents=True, exist_ok=True)

    result = {
        "schema_version": 1,
        "benchmark": "pre_taxi_ingress_only_line_rate",
        "mode": mode,
        "clock_mhz": clock_mhz,
        "axis_width_bits": 64,
        "sink_policy": "m_itch_tready_i held high",
        "scope": "frame_crack -> mold_deframe -> realign",
        "cases": records,
        "enforcement_failures": enforcement_failures,
    }

    (results_dir / "results.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    lines = [
        "# Pre-Taxi ingress-only line-rate regression",
        "",
        f"Mode: `{mode}`",
        "",
        f"Clock: {clock_mhz:.3f} MHz, 64-bit AXI4-Stream.",
        "",
        "Scope: `frame_crack -> mold_deframe -> realign -> always-ready sink`.",
        "",
        "| Case | Frames | Source stalls | Input acceptance | Input bus Gbit/s | "
        "Completed/expected | Deepest stalled boundary |",
        "|---|---:|---:|---:|---:|---:|---|",
    ]

    for record in records:
        acceptance = record["source_acceptance_ratio"]
        acceptance_text = (
            "n/a" if acceptance is None else f"{acceptance:.6f}"
        )
        input_gbps = record["input_bus_gbps"]
        input_gbps_text = (
            "n/a" if input_gbps is None else f"{input_gbps:.3f}"
        )

        lines.append(
            f"| {record['case']} | {record['frames']} | "
            f"{record['stall_cycles']['frame_crack_input']} | "
            f"{acceptance_text} | {input_gbps_text} | "
            f"{record['completed_messages']}/{record['expected_messages']} | "
            f"{record['deepest_stalled_boundary'] or 'none'} |"
        )

    lines.extend(["", "## Findings", ""])

    if enforcement_failures:
        lines.extend(f"- {failure}" for failure in enforcement_failures)
    else:
        lines.append("- No ingress-only line-rate gate failures were observed.")

    lines.extend(
        [
            "",
            "The source deliberately presents consecutive AXI beats with no "
            "forced inter-frame bubble. This is stricter than the physical "
            "10GbE wire because preamble/FCS/IFG time is not represented on "
            "this stream. Use this as a pre-Taxi stress test; final line-rate "
            "sign-off still requires post-synthesis timing closure at 6.4 ns "
            "and a Taxi/MAC-aware hardware test.",
            "",
        ]
    )

    (results_dir / "summary.md").write_text(
        "\n".join(lines),
        encoding="utf-8",
    )


@cocotb.test()
async def test_pre_taxi_ingress_only_line_rate(dut: Any) -> None:
    """Measure sustained throughput with every downstream block removed."""

    mode = _mode()
    event_count = _event_count(mode)
    enforce = _enforce()
    results_dir = _results_dir()

    clock_mhz = clock_mhz_from_env(default=156.25)
    await initialise_perf_ingress(dut, clock_mhz=clock_mhz)

    records: list[dict[str, Any]] = []
    enforcement_failures: list[str] = []

    for campaign_index, campaign in enumerate(_campaigns(mode, event_count)):
        if campaign_index != 0:
            await _reset_ingress(dut)

        frames, datagrams = _pack_frames(
            campaign.payloads,
            randomise_counts=campaign.randomise_mold_counts,
        )

        monitor = IngressLineRateMonitor(dut)
        monitor_task = cocotb.start_soon(monitor.run())

        dut._log.info(
            "%s: starting ingress-only drive (%d messages in %d frames)",
            campaign.name,
            len(campaign.payloads),
            len(frames),
        )

        drive_timeout = False
        drain_timeout = False

        try:
            await drive_axis_frames_continuous(
                dut,
                frames,
                timeout_cycles_per_beat=TIMEOUT_CYCLES_PER_BEAT,
            )
        except TimeoutError:
            drive_timeout = True

            # The continuous driver exits before clearing TVALID on timeout.
            # Return the source to idle so the current campaign can still be
            # reported and the next one can be reset cleanly.
            await FallingEdge(dut.clk)
            dut.s_frame_tdata_i.value = 0
            dut.s_frame_tkeep_i.value = 0
            dut.s_frame_tvalid_i.value = 0
            dut.s_frame_tlast_i.value = 0

        if not drive_timeout:
            drained = await _wait_for_messages(
                dut,
                monitor,
                len(campaign.payloads),
            )
            drain_timeout = not drained

        # Give registered status/probe outputs one final cycle to settle before
        # stopping observation.
        await RisingEdge(dut.clk)
        monitor.stop()
        await monitor_task

        report = _rate_report(
            monitor.capture,
            campaign=campaign,
            frames=frames,
            datagrams=datagrams,
            clock_mhz=clock_mhz,
            drive_timeout=drive_timeout,
            drain_timeout=drain_timeout,
        )
        records.append(report)

        failures = _case_failures(report)
        enforcement_failures.extend(failures)

        # Write after every case so measurement data survives a later campaign
        # failure or simulator interruption.
        _write_summary(
            results_dir=results_dir,
            records=records,
            enforcement_failures=enforcement_failures,
            mode=mode,
            clock_mhz=clock_mhz,
        )

        dut._log.info(
            "%s: source_stalls=%d acceptance=%s input=%.3f Gbit/s "
            "completed=%d/%d deepest_stall=%s",
            campaign.name,
            report["stall_cycles"]["frame_crack_input"],
            (
                "n/a"
                if report["source_acceptance_ratio"] is None
                else f"{report['source_acceptance_ratio']:.6f}"
            ),
            report["input_bus_gbps"] or 0.0,
            report["completed_messages"],
            report["expected_messages"],
            report["deepest_stalled_boundary"],
        )

    dut._log.info(
        "Wrote ingress-only line-rate results to %s",
        results_dir / "results.json",
    )
    dut._log.info(
        "Ingress-only line-rate summary:\n%s",
        json.dumps(records, indent=2, sort_keys=True),
    )

    if enforce:
        assert enforcement_failures == [], (
            "ingress-only line-rate gate failures:\n- "
            + "\n- ".join(enforcement_failures)
        )
