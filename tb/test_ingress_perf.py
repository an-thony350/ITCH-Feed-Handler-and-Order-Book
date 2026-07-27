"""Initial cycle-accurate latency smoke test for ingress_top_perf_probe.

This first performance test measures one valid Add Order frame with an
always-ready output. It establishes that the probe and monitor can timestamp
every ingress boundary before larger latency and throughput campaigns are added.
"""

from __future__ import annotations

import json
from typing import Any

import cocotb

from itch_harness.ingress_packets import (
    add_order_payload,
    build_eth_ipv4_udp_frame,
    build_mold_datagram,
)
from itch_harness.perf import (
    IngressPerfMonitor,
    drive_axis_frame_continuous,
    initialise_perf_ingress,
)


@cocotb.test()
async def test_single_add_order_latency_smoke(dut: Any) -> None:
    """Measure one always-ready Ethernet-to-ITCH transaction."""

    await initialise_perf_ingress(dut)

    payload = add_order_payload(
        1_001,
        side="B",
        shares=100,
        price=10_000,
        locate=1,
        tracking=1,
        timestamp_ns=1,
    )

    datagram = build_mold_datagram(
        [payload],
        seq=100,
    )
    frame = build_eth_ipv4_udp_frame(datagram)

    monitor = IngressPerfMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    await drive_axis_frame_continuous(dut, frame)
    await monitor.wait_for_completed_messages(1)

    monitor.stop()
    await monitor_task

    capture = monitor.capture

    assert len(capture.messages) == 1

    got_raw = capture.messages[0]
    got_payload = got_raw[: len(payload)]
    got_padding = got_raw[len(payload) :]

    assert got_payload == payload, (
        f"recovered ITCH payload mismatch: "
        f"expected={payload.hex()} got={got_payload.hex()}"
    )
    assert got_padding == b"\x00" * len(got_padding), (
        f"recovered ITCH padding was non-zero: {got_padding.hex()}"
    )

    assert capture.frame_drop_errs == []
    assert capture.mold_drop_errs == []
    assert capture.realign_errs == []

    assert len(capture.dgram_start_cycles) == 1
    assert len(capture.seq_valid_cycles) == 1
    assert len(capture.msg_len_fire_cycles) == 1
    assert capture.completed_message_count == 1

    report = capture.single_frame_latency_report(
        exact_itch_bytes=len(payload),
    )

    dut._log.info(
        "Single-frame ingress latency report:\n%s",
        json.dumps(report, indent=2, sort_keys=True),
    )
