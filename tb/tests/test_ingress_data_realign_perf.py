"""Cold-path latency sweep for the merged ingress/decode candidate.

Each case drives one Ethernet/IPv4/UDP/MoldUDP64 frame containing one supported
ITCH mutation while m_event_ready_i remains asserted. Latency is measured to the
normalised data_t event, not to an intermediate padded ITCH packet.
"""

from __future__ import annotations

from dataclasses import asdict
import json
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
    clock_mhz_from_env,
    cycles_to_ns,
    drive_axis_frame_continuous,
    start_perf_clock,
)
from itch_harness.scoreboard import (
    assert_data_t_matches_word,
    signal_value_to_int,
)


RESULTS_PATH = (
    Path(__file__).resolve().parents[2]
    / "build"
    / "perf"
    / "data_realign_ingress_latency.json"
)


def _event_dict(payload: bytes) -> dict[str, Any]:
    event = parse_itch_message(payload, msg_index=0)
    assert event is not None

    record = asdict(event)
    record["op"] = event.op.value
    record["side"] = event.side.value
    return record


def _cases() -> list[tuple[str, bytes]]:
    return [
        ("D_order_delete_19B", delete_order_payload(1001)),
        (
            "X_order_cancel_23B",
            cancel_order_payload(1002, cancelled_shares=25),
        ),
        (
            "E_order_executed_31B",
            execute_order_payload(
                1003,
                executed_shares=10,
                match_number=10_003,
            ),
        ),
        (
            "U_order_replace_35B",
            replace_order_payload(
                1004,
                2004,
                shares=50,
                price=10_010,
            ),
        ),
        (
            "A_add_order_36B",
            add_order_payload(
                1005,
                side="B",
                shares=100,
                price=10_000,
            ),
        ),
        (
            "C_order_executed_with_price_36B",
            execute_order_with_price_payload(
                1006,
                executed_shares=15,
                match_number=10_006,
                printable="Y",
                execution_price=10_005,
            ),
        ),
        (
            "F_add_order_with_mpid_40B",
            add_order_with_mpid_payload(
                1007,
                side="S",
                shares=125,
                price=10_020,
                attribution=b"TEST",
            ),
        ),
    ]


async def _reset_candidate(dut: Any) -> None:
    await FallingEdge(dut.clk)

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0
    dut.m_event_ready_i.value = 1

    await reset_dut(dut, cycles=5)


async def _capture_one_event(
    dut: Any,
    *,
    timeout_cycles: int = 50_000,
) -> dict[str, Any]:
    """Capture one transaction using pre-edge ready/valid semantics."""

    cycle = 0

    first_frame = None
    last_frame = None
    first_dgram = None
    first_payload = None
    first_msg_len = None

    frame_bytes = 0
    dgram_bytes = 0
    payload_bytes = 0

    frame_stalls = 0
    dgram_stalls = 0
    payload_stalls = 0
    msg_len_stalls = 0
    event_stalls = 0

    for _ in range(timeout_cycles):
        await FallingEdge(dut.clk)
        await ReadOnly()

        frame_valid = signal_value_to_int(dut.s_frame_tvalid_i.value)
        frame_ready = signal_value_to_int(dut.s_frame_tready_o.value)
        frame_keep = signal_value_to_int(dut.s_frame_tkeep_i.value)
        frame_last = signal_value_to_int(dut.s_frame_tlast_i.value)

        dgram_valid = signal_value_to_int(dut.probe_dgram_tvalid_o.value)
        dgram_ready = signal_value_to_int(dut.probe_dgram_tready_o.value)

        payload_valid = signal_value_to_int(dut.probe_payload_tvalid_o.value)
        payload_ready = signal_value_to_int(dut.probe_payload_tready_o.value)

        msg_len_valid = signal_value_to_int(dut.probe_msg_len_valid_o.value)
        msg_len_ready = signal_value_to_int(dut.probe_msg_len_ready_o.value)

        event_valid = signal_value_to_int(dut.m_event_valid_o.value)
        event_ready = signal_value_to_int(dut.m_event_ready_i.value)
        event_word = signal_value_to_int(dut.m_event_data_o.value)

        dgram_keep = signal_value_to_int(dut.dut.dgram_tkeep.value)
        payload_keep = signal_value_to_int(dut.dut.payload_tkeep.value)

        await RisingEdge(dut.clk)
        await ReadOnly()

        if frame_valid and not frame_ready:
            frame_stalls += 1
        if frame_valid and frame_ready:
            if first_frame is None:
                first_frame = cycle
            if frame_last:
                last_frame = cycle
            frame_bytes += frame_keep.bit_count()

        if dgram_valid and not dgram_ready:
            dgram_stalls += 1
        if dgram_valid and dgram_ready:
            if first_dgram is None:
                first_dgram = cycle
            dgram_bytes += dgram_keep.bit_count()

        if payload_valid and not payload_ready:
            payload_stalls += 1
        if payload_valid and payload_ready:
            if first_payload is None:
                first_payload = cycle
            payload_bytes += payload_keep.bit_count()

        if msg_len_valid and not msg_len_ready:
            msg_len_stalls += 1
        if msg_len_valid and msg_len_ready and first_msg_len is None:
            first_msg_len = cycle

        if event_valid and not event_ready:
            event_stalls += 1
        if event_valid and event_ready:
            if first_frame is None or last_frame is None:
                raise AssertionError("decoded event arrived before frame accounting")
            return {
                "event_cycle": cycle,
                "event_word": event_word,
                "first_frame_cycle": first_frame,
                "last_frame_cycle": last_frame,
                "first_dgram_cycle": first_dgram,
                "first_payload_cycle": first_payload,
                "first_msg_len_cycle": first_msg_len,
                "frame_bytes": frame_bytes,
                "dgram_bytes": dgram_bytes,
                "payload_bytes": payload_bytes,
                "frame_stalls": frame_stalls,
                "dgram_stalls": dgram_stalls,
                "payload_stalls": payload_stalls,
                "msg_len_stalls": msg_len_stalls,
                "event_stalls": event_stalls,
            }

        cycle += 1

    raise TimeoutError("timed out waiting for merged decoded event")


@cocotb.test()
async def test_candidate_single_message_latency_sweep(dut: Any) -> None:
    clock_mhz = clock_mhz_from_env(default=156.25)
    await start_perf_clock(dut, clock_mhz=clock_mhz)
    await _reset_candidate(dut)

    reports: list[dict[str, Any]] = []

    for case_index, (case_name, payload) in enumerate(_cases()):
        if case_index != 0:
            await _reset_candidate(dut)

        datagram = build_mold_datagram([payload], seq=100 + case_index)
        frame = build_eth_ipv4_udp_frame(datagram)

        capture_task = cocotb.start_soon(_capture_one_event(dut))
        await drive_axis_frame_continuous(dut, frame)
        capture = await capture_task

        assert_data_t_matches_word(
            int(capture["event_word"]),
            _event_dict(payload),
        )

        assert signal_value_to_int(dut.frame_drop_o.value) == 0
        assert signal_value_to_int(dut.mold_drop_o.value) == 0
        assert signal_value_to_int(dut.realign_err_o.value) == 0

        event_cycle = int(capture["event_cycle"])
        first_frame = int(capture["first_frame_cycle"])
        last_frame = int(capture["last_frame_cycle"])

        report = {
            "case": case_name,
            "message_type": chr(payload[0]),
            "message_bytes": len(payload),
            "frame_bytes": len(frame),
            "datagram_bytes": len(datagram),
            "clock_mhz": clock_mhz,
            "frame_to_event_cycles": event_cycle - first_frame,
            "frame_to_event_ns": cycles_to_ns(
                event_cycle - first_frame,
                clock_mhz=clock_mhz,
            ),
            "last_frame_to_event_cycles": event_cycle - last_frame,
            "last_frame_to_event_ns": cycles_to_ns(
                event_cycle - last_frame,
                clock_mhz=clock_mhz,
            ),
            "accepted_frame_bytes": int(capture["frame_bytes"]),
            "accepted_dgram_bytes": int(capture["dgram_bytes"]),
            "accepted_payload_bytes": int(capture["payload_bytes"]),
            "stall_cycles": {
                "frame_crack_input": int(capture["frame_stalls"]),
                "frame_crack_to_mold": int(capture["dgram_stalls"]),
                "mold_to_data_realign_payload": int(
                    capture["payload_stalls"]
                ),
                "mold_to_data_realign_length": int(
                    capture["msg_len_stalls"]
                ),
                "data_realign_output": int(capture["event_stalls"]),
            },
        }

        assert report["accepted_frame_bytes"] == len(frame)
        assert report["accepted_dgram_bytes"] == len(datagram)
        assert report["accepted_payload_bytes"] == len(payload)

        reports.append(report)

        dut._log.info(
            "%s: frame->event=%d cycles, last-frame->event=%d cycles",
            case_name,
            report["frame_to_event_cycles"],
            report["last_frame_to_event_cycles"],
        )

    RESULTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    RESULTS_PATH.write_text(
        json.dumps(reports, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
