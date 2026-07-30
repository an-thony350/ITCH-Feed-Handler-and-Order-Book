"""Message-length latency sweep for ingress_top_perf_probe.

Each case sends one valid Ethernet/IPv4/UDP/MoldUDP64 frame containing one ITCH
message while the output remains always ready. The DUT is reset between cases so
every result measures an independent cold-path transaction.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import cocotb
from cocotb.triggers import FallingEdge

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
    IngressPerfMonitor,
    drive_axis_frame_continuous,
    initialise_perf_ingress,
)


RESULTS_PATH = (
    Path(__file__).resolve().parents[2]
    / "build"
    / "perf"
    / "ingress_latency_by_message.json"
)


def _build_latency_cases() -> list[tuple[str, bytes]]:
    """Build representative supported ITCH messages across the length range."""

    return [
        (
            "D_order_delete_19B",
            delete_order_payload(
                1_001,
                tracking=1,
                timestamp_ns=1,
            ),
        ),
        (
            "X_order_cancel_23B",
            cancel_order_payload(
                1_002,
                cancelled_shares=25,
                tracking=2,
                timestamp_ns=2,
            ),
        ),
        (
            "E_order_executed_31B",
            execute_order_payload(
                1_003,
                executed_shares=10,
                match_number=10_003,
                tracking=3,
                timestamp_ns=3,
            ),
        ),
        (
            "U_order_replace_35B",
            replace_order_payload(
                1_004,
                2_004,
                shares=50,
                price=10_010,
                tracking=4,
                timestamp_ns=4,
            ),
        ),
        (
            "A_add_order_36B",
            add_order_payload(
                1_005,
                side="B",
                shares=100,
                price=10_000,
                tracking=5,
                timestamp_ns=5,
            ),
        ),
        (
            "C_order_executed_with_price_36B",
            execute_order_with_price_payload(
                1_006,
                executed_shares=15,
                match_number=10_006,
                printable="Y",
                execution_price=10_005,
                tracking=6,
                timestamp_ns=6,
            ),
        ),
        (
            "F_add_order_with_mpid_40B",
            add_order_with_mpid_payload(
                1_007,
                side="S",
                shares=125,
                price=10_020,
                attribution=b"TEST",
                tracking=7,
                timestamp_ns=7,
            ),
        ),
    ]


def _assert_message_matches(got_raw: bytes, expected: bytes, case_name: str) -> None:
    got_payload = got_raw[: len(expected)]
    got_padding = got_raw[len(expected) :]

    assert got_payload == expected, (
        f"{case_name}: recovered ITCH payload mismatch: "
        f"expected={expected.hex()} got={got_payload.hex()}"
    )

    assert got_padding == b"\x00" * len(got_padding), (
        f"{case_name}: recovered ITCH padding was non-zero: "
        f"{got_padding.hex()}"
    )


@cocotb.test()
async def test_single_message_latency_sweep(dut: Any) -> None:
    """Measure isolated latency for supported ITCH message lengths."""

    await initialise_perf_ingress(dut)

    reports: list[dict[str, int | float | str]] = []

    for case_index, (case_name, payload) in enumerate(_build_latency_cases()):
        if case_index != 0:
            # Hold all interfaces idle while restoring an independent ingress
            # state for the next message-length measurement.
            dut.s_frame_tdata_i.value = 0
            dut.s_frame_tkeep_i.value = 0
            dut.s_frame_tvalid_i.value = 0
            dut.s_frame_tlast_i.value = 0
            dut.m_itch_tready_i.value = 1

            await reset_dut(dut, cycles=5)

        datagram = build_mold_datagram(
            [payload],
            seq=100 + case_index,
        )
        frame = build_eth_ipv4_udp_frame(datagram)

        monitor = IngressPerfMonitor(dut)
        monitor_task = cocotb.start_soon(monitor.run())

        await drive_axis_frame_continuous(dut, frame)
        await monitor.wait_for_completed_messages(1)

        monitor.stop()
        await monitor_task
        await FallingEdge(dut.clk)

        capture = monitor.capture

        assert len(capture.messages) == 1, (
            f"{case_name}: expected one recovered message, "
            f"got {len(capture.messages)}"
        )
        _assert_message_matches(capture.messages[0], payload, case_name)

        assert capture.frame_drop_errs == [], (
            f"{case_name}: frame errors {capture.frame_drop_errs}"
        )
        assert capture.mold_drop_errs == [], (
            f"{case_name}: MoldUDP64 errors {capture.mold_drop_errs}"
        )
        assert capture.realign_errs == [], (
            f"{case_name}: realign errors {capture.realign_errs}"
        )

        assert len(capture.dgram_start_cycles) == 1
        assert len(capture.seq_valid_cycles) == 1
        assert len(capture.msg_len_fire_cycles) == 1
        assert capture.completed_message_count == 1

        assert capture.accepted_frame_bytes == len(frame), (
            f"{case_name}: frame byte count mismatch: "
            f"expected {len(frame)}, got {capture.accepted_frame_bytes}"
        )
        assert capture.accepted_dgram_bytes == len(datagram), (
            f"{case_name}: datagram byte count mismatch: "
            f"expected {len(datagram)}, got {capture.accepted_dgram_bytes}"
        )
        assert capture.accepted_payload_bytes == len(payload), (
            f"{case_name}: payload byte count mismatch: "
            f"expected {len(payload)}, got {capture.accepted_payload_bytes}"
        )

        report = capture.single_frame_latency_report(
            exact_itch_bytes=len(payload),
        )
        report["case"] = case_name
        report["message_type"] = chr(payload[0])
        report["expected_frame_bytes"] = len(frame)
        report["expected_dgram_bytes"] = len(datagram)

        reports.append(report)

        dut._log.info(
            "%s: first_itch=%d cycles, complete_itch=%d cycles, "
            "frame_stalls=%d, dgram_stalls=%d",
            case_name,
            report["frame_to_first_itch_cycles"],
            report["frame_to_complete_itch_cycles"],
            report["frame_stall_cycles"],
            report["dgram_stall_cycles"],
        )

    RESULTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    RESULTS_PATH.write_text(
        json.dumps(reports, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    dut._log.info(
        "Wrote ingress latency sweep results to %s",
        RESULTS_PATH,
    )
    dut._log.info(
        "Complete ingress latency sweep:\n%s",
        json.dumps(reports, indent=2, sort_keys=True),
    )
