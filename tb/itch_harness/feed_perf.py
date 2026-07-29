"""Cycle-accurate helpers for feed_handler_top_perf_probe.

The measurement path is intentionally simulation-only. Production RTL is
observed at the Ethernet, aligned-ITCH, decoded-event, individual-book BBO and
external BBO scheduler boundaries without carrying timestamps through the DUT.
"""

from __future__ import annotations

import math
import statistics
from collections import deque
from dataclasses import dataclass, field
from typing import Any

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from .axis import reset_dut
from .perf import (
    bytes_per_cycle,
    clock_period_ns_from_mhz,
    cycles_to_ns,
    messages_per_second,
    resolve_clock_mhz,
    start_perf_clock,
    throughput_gbps,
    transfer_window_cycles,
)
from .scoreboard import signal_value_to_int


FIFO_DEPTH = 16
FIFO_SAFE_OCCUPANCY = FIFO_DEPTH - 1
DEFAULT_BASE_PRICE = 9_000
DEFAULT_TIMEOUT_CYCLES = 500_000


@dataclass
class FeedPerfEvent:
    """One decoded event correlated through the complete book/output path."""

    message_type: str
    stock_locate: int
    orn: int
    updated_orn: int
    decoded_cycle: int
    book_accept_cycle: int | None = None
    internal_bbo_cycle: int | None = None
    external_bbo_cycle: int | None = None

    @property
    def stock_index(self) -> int:
        return self.stock_locate - 1

    def require_complete(self) -> None:
        missing: list[str] = []
        if self.book_accept_cycle is None:
            missing.append("book_accept_cycle")
        if self.internal_bbo_cycle is None:
            missing.append("internal_bbo_cycle")
        if self.external_bbo_cycle is None:
            missing.append("external_bbo_cycle")
        if missing:
            raise ValueError(
                f"event {self.message_type}/{self.orn} is incomplete: {missing}"
            )

    def latency_cycles(self) -> dict[str, int]:
        self.require_complete()
        assert self.book_accept_cycle is not None
        assert self.internal_bbo_cycle is not None
        assert self.external_bbo_cycle is not None

        result = {
            "decoded_to_book_accept": self.book_accept_cycle - self.decoded_cycle,
            "book_accept_to_internal_bbo": (
                self.internal_bbo_cycle - self.book_accept_cycle
            ),
            "decoded_to_internal_bbo": (
                self.internal_bbo_cycle - self.decoded_cycle
            ),
            "internal_to_external_bbo": (
                self.external_bbo_cycle - self.internal_bbo_cycle
            ),
            "decoded_to_external_bbo": (
                self.external_bbo_cycle - self.decoded_cycle
            ),
        }

        for name, value in result.items():
            if value < 0:
                raise ValueError(
                    f"event {self.message_type}/{self.orn} has negative "
                    f"{name} latency: {value}"
                )

        return result

    def to_record(self, *, clock_mhz: float) -> dict[str, int | float | str]:
        latencies = self.latency_cycles()
        record: dict[str, int | float | str] = {
            "message_type": self.message_type,
            "stock_locate": self.stock_locate,
            "orn": self.orn,
            "updated_orn": self.updated_orn,
            "decoded_cycle": self.decoded_cycle,
            "book_accept_cycle": int(self.book_accept_cycle),
            "internal_bbo_cycle": int(self.internal_bbo_cycle),
            "external_bbo_cycle": int(self.external_bbo_cycle),
        }

        for name, value in latencies.items():
            record[f"{name}_cycles"] = value
            record[f"{name}_ns"] = cycles_to_ns(value, clock_mhz=clock_mhz)

        return record


@dataclass
class FeedHandlerPerfCapture:
    """Full-chain cycles, stalls, correlation state and FIFO safety data."""

    frame_fire_cycles: list[int] = field(default_factory=list)
    frame_fire_bytes: list[int] = field(default_factory=list)
    frame_start_cycles: list[int] = field(default_factory=list)
    frame_last_cycles: list[int] = field(default_factory=list)

    itch_fire_cycles: list[int] = field(default_factory=list)
    itch_start_cycles: list[int] = field(default_factory=list)
    itch_last_cycles: list[int] = field(default_factory=list)

    decoded_fire_cycles: list[int] = field(default_factory=list)
    book_fire_cycles: list[list[int]] = field(
        default_factory=lambda: [[], [], []]
    )
    internal_bbo_cycles: list[list[int]] = field(
        default_factory=lambda: [[], [], []]
    )
    external_bbo_cycles: list[int] = field(default_factory=list)

    events: list[FeedPerfEvent] = field(default_factory=list)

    frame_stall_cycles: int = 0
    itch_stall_cycles: int = 0
    decoded_stall_cycles: int = 0
    book_busy_cycles: list[int] = field(default_factory=lambda: [0, 0, 0])

    fifo_occupancy: list[int] = field(default_factory=lambda: [0, 0, 0])
    fifo_max_occupancy: list[int] = field(default_factory=lambda: [0, 0, 0])
    fifo_overflow_cycles: list[list[int]] = field(
        default_factory=lambda: [[], [], []]
    )
    fifo_pointer_anomalies: list[str] = field(default_factory=list)

    frame_drop_errs: list[int] = field(default_factory=list)
    mold_drop_errs: list[int] = field(default_factory=list)
    realign_errs: list[int] = field(default_factory=list)
    unexpected_gap_cycles: list[int] = field(default_factory=list)
    unexpected_duplicate_cycles: list[int] = field(default_factory=list)
    unexpected_stale_cycles: list[int] = field(default_factory=list)

    correlation_errors: list[str] = field(default_factory=list)

    @property
    def accepted_frame_bytes(self) -> int:
        return sum(self.frame_fire_bytes)

    @property
    def completed_event_count(self) -> int:
        return sum(event.external_bbo_cycle is not None for event in self.events)

    def assert_clean(self, *, expected_events: int | None = None) -> None:
        """Fail on drops, correlation errors, incomplete events or FIFO overwrite."""

        assert self.frame_drop_errs == [], (
            f"frame errors observed: {self.frame_drop_errs}"
        )
        assert self.mold_drop_errs == [], (
            f"MoldUDP64 errors observed: {self.mold_drop_errs}"
        )
        assert self.realign_errs == [], (
            f"realign errors observed: {self.realign_errs}"
        )
        assert self.unexpected_gap_cycles == [], (
            f"unexpected gap pulses: {self.unexpected_gap_cycles}"
        )
        assert self.unexpected_duplicate_cycles == [], (
            f"unexpected duplicate pulses: {self.unexpected_duplicate_cycles}"
        )
        assert self.unexpected_stale_cycles == [], (
            f"unexpected stale pulses: {self.unexpected_stale_cycles}"
        )
        assert self.correlation_errors == [], (
            f"event correlation errors: {self.correlation_errors}"
        )
        assert self.fifo_pointer_anomalies == [], (
            f"FIFO pointer anomalies: {self.fifo_pointer_anomalies}"
        )
        assert all(not cycles for cycles in self.fifo_overflow_cycles), (
            "unsafe FIFO occupancy observed: "
            f"cycles={self.fifo_overflow_cycles}, "
            f"max={self.fifo_max_occupancy}"
        )
        assert self.fifo_occupancy == [0, 0, 0], (
            f"FIFO output queues did not drain: {self.fifo_occupancy}"
        )

        for event in self.events:
            event.require_complete()

        if expected_events is not None:
            assert len(self.events) == expected_events, (
                f"expected {expected_events} decoded event(s), "
                f"captured {len(self.events)}"
            )
            assert self.completed_event_count == expected_events, (
                f"expected {expected_events} external BBO(s), "
                f"captured {self.completed_event_count}"
            )

    def isolated_latency_report(
        self,
        *,
        case_name: str,
        path_name: str,
        clock_mhz: float,
    ) -> dict[str, Any]:
        """Build a report for exactly one measured frame/event/BBO."""

        if len(self.frame_start_cycles) != 1 or len(self.frame_last_cycles) != 1:
            raise ValueError(
                "isolated report requires exactly one captured Ethernet frame"
            )
        if len(self.itch_start_cycles) != 1 or len(self.itch_last_cycles) != 1:
            raise ValueError(
                "isolated report requires exactly one captured ITCH message"
            )
        if len(self.events) != 1:
            raise ValueError(
                f"isolated report requires one event, got {len(self.events)}"
            )

        event = self.events[0]
        event.require_complete()
        assert event.internal_bbo_cycle is not None
        assert event.external_bbo_cycle is not None

        frame_first = self.frame_start_cycles[0]
        frame_last = self.frame_last_cycles[0]
        itch_first = self.itch_start_cycles[0]
        itch_last = self.itch_last_cycles[0]

        latency_cycles = {
            "frame_first_to_external_bbo": (
                event.external_bbo_cycle - frame_first
            ),
            "frame_last_to_external_bbo": (
                event.external_bbo_cycle - frame_last
            ),
            "itch_first_to_external_bbo": (
                event.external_bbo_cycle - itch_first
            ),
            "itch_last_to_external_bbo": (
                event.external_bbo_cycle - itch_last
            ),
        }
        latency_cycles.update(event.latency_cycles())

        for name, value in latency_cycles.items():
            if value < 0:
                raise ValueError(f"negative isolated latency {name}={value}")

        report: dict[str, Any] = {
            "case": case_name,
            "path": path_name,
            "message_type": event.message_type,
            "stock_locate": event.stock_locate,
            "clock_frequency_mhz": clock_mhz,
            "clock_period_ns": clock_period_ns_from_mhz(clock_mhz),
            "frame_first_cycle": frame_first,
            "frame_last_cycle": frame_last,
            "itch_first_cycle": itch_first,
            "itch_last_cycle": itch_last,
            "decoded_cycle": event.decoded_cycle,
            "book_accept_cycle": event.book_accept_cycle,
            "internal_bbo_cycle": event.internal_bbo_cycle,
            "external_bbo_cycle": event.external_bbo_cycle,
            "accepted_frame_beats": len(self.frame_fire_cycles),
            "accepted_frame_bytes": self.accepted_frame_bytes,
            "accepted_itch_beats": len(self.itch_fire_cycles),
            "frame_stall_cycles": self.frame_stall_cycles,
            "itch_stall_cycles": self.itch_stall_cycles,
            "decoded_stall_cycles": self.decoded_stall_cycles,
            "book_busy_cycles": self.book_busy_cycles,
            "fifo_max_occupancy": self.fifo_max_occupancy,
        }

        for name, value in latency_cycles.items():
            report[f"{name}_cycles"] = value
            report[f"{name}_ns"] = cycles_to_ns(
                value,
                clock_mhz=clock_mhz,
            )

        return report

    def throughput_report(
        self,
        *,
        case_name: str,
        packet_packing: int,
        expected_events: int,
        clock_mhz: float,
    ) -> dict[str, Any]:
        """Build sustained input/event/BBO rate and latency-distribution data."""

        self.assert_clean(expected_events=expected_events)

        frame_window = transfer_window_cycles(self.frame_fire_cycles)
        decoded_window = transfer_window_cycles(self.decoded_fire_cycles)
        internal_cycles_flat = sorted(
            cycle
            for stock_cycles in self.internal_bbo_cycles
            for cycle in stock_cycles
        )
        internal_window = transfer_window_cycles(internal_cycles_flat)
        external_window = transfer_window_cycles(self.external_bbo_cycles)
        campaign_window = (
            self.external_bbo_cycles[-1] - self.frame_fire_cycles[0] + 1
        )

        latency_samples: dict[str, list[int]] = {
            "decoded_to_book_accept": [],
            "book_accept_to_internal_bbo": [],
            "decoded_to_internal_bbo": [],
            "internal_to_external_bbo": [],
            "decoded_to_external_bbo": [],
        }

        event_records: list[dict[str, int | float | str]] = []
        for event in self.events:
            for name, value in event.latency_cycles().items():
                latency_samples[name].append(value)
            event_records.append(event.to_record(clock_mhz=clock_mhz))

        return {
            "case": case_name,
            "packet_packing": packet_packing,
            "clock_frequency_mhz": clock_mhz,
            "clock_period_ns": clock_period_ns_from_mhz(clock_mhz),
            "frames": len(self.frame_start_cycles),
            "events": expected_events,
            "accepted_frame_beats": len(self.frame_fire_cycles),
            "accepted_frame_bytes": self.accepted_frame_bytes,
            "frame_window_cycles": frame_window,
            "decoded_window_cycles": decoded_window,
            "internal_bbo_window_cycles": internal_window,
            "external_bbo_window_cycles": external_window,
            "campaign_window_cycles": campaign_window,
            "input_bytes_per_cycle": bytes_per_cycle(
                self.accepted_frame_bytes,
                frame_window,
            ),
            "input_gbps": throughput_gbps(
                self.accepted_frame_bytes,
                frame_window,
                clock_mhz=clock_mhz,
            ),
            "decoded_events_per_second": messages_per_second(
                expected_events,
                decoded_window,
                clock_mhz=clock_mhz,
            ),
            "internal_bbos_per_second": messages_per_second(
                expected_events,
                internal_window,
                clock_mhz=clock_mhz,
            ),
            "external_bbos_per_second": messages_per_second(
                expected_events,
                external_window,
                clock_mhz=clock_mhz,
            ),
            "campaign_messages_per_second": messages_per_second(
                expected_events,
                campaign_window,
                clock_mhz=clock_mhz,
            ),
            "frame_stall_cycles": self.frame_stall_cycles,
            "itch_stall_cycles": self.itch_stall_cycles,
            "decoded_stall_cycles": self.decoded_stall_cycles,
            "book_busy_cycles": self.book_busy_cycles,
            "fifo_max_occupancy": self.fifo_max_occupancy,
            "latency_cycles": {
                name: distribution(samples)
                for name, samples in latency_samples.items()
            },
            "event_records": event_records,
        }


def _nearest_rank(sorted_values: list[int], percentile: float) -> int:
    if not sorted_values:
        raise ValueError("cannot calculate a percentile from no samples")
    index = max(0, math.ceil(percentile * len(sorted_values)) - 1)
    return sorted_values[index]


def distribution(values: list[int]) -> dict[str, int | float]:
    """Return deterministic min/median/p95/p99/max/mean statistics."""

    if not values:
        raise ValueError("cannot build a distribution from no values")

    ordered = sorted(values)
    return {
        "count": len(ordered),
        "min": ordered[0],
        "median": statistics.median(ordered),
        "p95": _nearest_rank(ordered, 0.95),
        "p99": _nearest_rank(ordered, 0.99),
        "max": ordered[-1],
        "mean": statistics.fmean(ordered),
    }


class FeedHandlerPerfMonitor:
    """Correlate ordered events through three books and the BBO scheduler."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.capture = FeedHandlerPerfCapture()

        self.running = True
        self.cycle = 0

        self._in_frame = False
        self._in_itch_message = False

        self._pending_book: list[deque[FeedPerfEvent]] = [
            deque(),
            deque(),
            deque(),
        ]
        self._pending_internal: list[deque[FeedPerfEvent]] = [
            deque(),
            deque(),
            deque(),
        ]
        self._pending_external: list[deque[FeedPerfEvent]] = [
            deque(),
            deque(),
            deque(),
        ]

        self._previous_wr_ptrs: list[int] | None = None
        self._previous_rd_ptrs: list[int] | None = None

    async def run(self) -> None:
        while self.running:
            await RisingEdge(self.dut.clk)
            await ReadOnly()

            self._sample_current_cycle()
            self.cycle += 1

    def _sample_current_cycle(self) -> None:
        if signal_value_to_int(self.dut.rst_n.value) == 0:
            return

        self._sample_stalls()
        self._sample_frames()
        self._sample_itch()
        self._sample_decoded_event()
        self._sample_book_accepts()
        self._sample_internal_bbos()
        self._sample_external_bbo()
        self._sample_fifo_pointers()
        self._sample_errors()

    def _sample_stalls(self) -> None:
        if (
            signal_value_to_int(self.dut.s_frame_tvalid_i.value) == 1
            and signal_value_to_int(self.dut.s_frame_tready_o.value) == 0
        ):
            self.capture.frame_stall_cycles += 1

        if (
            signal_value_to_int(self.dut.probe_itch_tvalid_o.value) == 1
            and signal_value_to_int(self.dut.probe_itch_tready_o.value) == 0
        ):
            self.capture.itch_stall_cycles += 1

        if (
            signal_value_to_int(self.dut.probe_decoded_valid_o.value) == 1
            and signal_value_to_int(self.dut.probe_decoded_ready_o.value) == 0
        ):
            self.capture.decoded_stall_cycles += 1

        ready_signals = (
            self.dut.probe_book_ready_stock0_o,
            self.dut.probe_book_ready_stock1_o,
            self.dut.probe_book_ready_stock2_o,
        )
        for stock_index, signal in enumerate(ready_signals):
            if signal_value_to_int(signal.value) == 0:
                self.capture.book_busy_cycles[stock_index] += 1

    def _sample_frames(self) -> None:
        if signal_value_to_int(self.dut.probe_frame_fire_o.value) != 1:
            return

        keep = signal_value_to_int(self.dut.probe_frame_keep_o.value)
        self.capture.frame_fire_cycles.append(self.cycle)
        self.capture.frame_fire_bytes.append(keep.bit_count())

        if not self._in_frame:
            self.capture.frame_start_cycles.append(self.cycle)
            self._in_frame = True

        if signal_value_to_int(
            self.dut.probe_frame_last_fire_o.value
        ) == 1:
            self.capture.frame_last_cycles.append(self.cycle)
            self._in_frame = False

    def _sample_itch(self) -> None:
        if signal_value_to_int(self.dut.probe_itch_fire_o.value) != 1:
            return

        self.capture.itch_fire_cycles.append(self.cycle)

        if not self._in_itch_message:
            self.capture.itch_start_cycles.append(self.cycle)
            self._in_itch_message = True

        if signal_value_to_int(
            self.dut.probe_itch_last_fire_o.value
        ) == 1:
            self.capture.itch_last_cycles.append(self.cycle)
            self._in_itch_message = False

    def _sample_decoded_event(self) -> None:
        if signal_value_to_int(self.dut.probe_decoded_fire_o.value) != 1:
            return

        message_type_value = signal_value_to_int(
            self.dut.probe_decoded_message_type_o.value
        )
        stock_locate = signal_value_to_int(
            self.dut.probe_decoded_stock_locate_o.value
        )
        event = FeedPerfEvent(
            message_type=chr(message_type_value),
            stock_locate=stock_locate,
            orn=signal_value_to_int(self.dut.probe_decoded_orn_o.value),
            updated_orn=signal_value_to_int(
                self.dut.probe_decoded_updated_orn_o.value
            ),
            decoded_cycle=self.cycle,
        )

        self.capture.events.append(event)
        self.capture.decoded_fire_cycles.append(self.cycle)

        if not 1 <= stock_locate <= 3:
            self.capture.correlation_errors.append(
                f"cycle {self.cycle}: decoded unsupported locate {stock_locate}"
            )
            return

        self._pending_book[event.stock_index].append(event)

    def _sample_book_accepts(self) -> None:
        fire_signals = (
            self.dut.probe_book_fire_stock0_o,
            self.dut.probe_book_fire_stock1_o,
            self.dut.probe_book_fire_stock2_o,
        )

        for stock_index, signal in enumerate(fire_signals):
            if signal_value_to_int(signal.value) != 1:
                continue

            self.capture.book_fire_cycles[stock_index].append(self.cycle)
            if not self._pending_book[stock_index]:
                self.capture.correlation_errors.append(
                    f"cycle {self.cycle}: stock {stock_index} book accept "
                    "without a decoded event"
                )
                continue

            event = self._pending_book[stock_index].popleft()
            event.book_accept_cycle = self.cycle
            self._pending_internal[stock_index].append(event)

    def _sample_internal_bbos(self) -> None:
        valid_signals = (
            self.dut.probe_internal_bbo_valid_stock0_o,
            self.dut.probe_internal_bbo_valid_stock1_o,
            self.dut.probe_internal_bbo_valid_stock2_o,
        )

        for stock_index, signal in enumerate(valid_signals):
            if signal_value_to_int(signal.value) != 1:
                continue

            self.capture.internal_bbo_cycles[stock_index].append(self.cycle)
            if not self._pending_internal[stock_index]:
                self.capture.correlation_errors.append(
                    f"cycle {self.cycle}: stock {stock_index} internal BBO "
                    "without an accepted event"
                )
                continue

            event = self._pending_internal[stock_index].popleft()
            event.internal_bbo_cycle = self.cycle
            self._pending_external[stock_index].append(event)

    def _sample_external_bbo(self) -> None:
        if signal_value_to_int(self.dut.bbo_valid_o.value) != 1:
            return

        stock_id = signal_value_to_int(
            self.dut.probe_external_stock_id_o.value
        )
        self.capture.external_bbo_cycles.append(self.cycle)

        if not 1 <= stock_id <= 3:
            self.capture.correlation_errors.append(
                f"cycle {self.cycle}: external BBO has invalid stock_id={stock_id}"
            )
            return

        stock_index = stock_id - 1
        if not self._pending_external[stock_index]:
            self.capture.correlation_errors.append(
                f"cycle {self.cycle}: stock {stock_index} external BBO "
                "without an internal BBO"
            )
            return

        event = self._pending_external[stock_index].popleft()
        event.external_bbo_cycle = self.cycle

    def _sample_fifo_pointers(self) -> None:
        wr_ptrs = [
            signal_value_to_int(self.dut.probe_fifo_wr_ptr_stock0_o.value),
            signal_value_to_int(self.dut.probe_fifo_wr_ptr_stock1_o.value),
            signal_value_to_int(self.dut.probe_fifo_wr_ptr_stock2_o.value),
        ]
        rd_ptrs = [
            signal_value_to_int(self.dut.probe_fifo_rd_ptr_stock0_o.value),
            signal_value_to_int(self.dut.probe_fifo_rd_ptr_stock1_o.value),
            signal_value_to_int(self.dut.probe_fifo_rd_ptr_stock2_o.value),
        ]

        if self._previous_wr_ptrs is None or self._previous_rd_ptrs is None:
            self._previous_wr_ptrs = wr_ptrs
            self._previous_rd_ptrs = rd_ptrs
            return

        for stock_index in range(3):
            wr_delta = (
                wr_ptrs[stock_index] - self._previous_wr_ptrs[stock_index]
            ) % FIFO_DEPTH
            rd_delta = (
                rd_ptrs[stock_index] - self._previous_rd_ptrs[stock_index]
            ) % FIFO_DEPTH

            if wr_delta not in (0, 1):
                self.capture.fifo_pointer_anomalies.append(
                    f"cycle {self.cycle}: stock {stock_index} write pointer "
                    f"jumped by {wr_delta}"
                )
            if rd_delta not in (0, 1):
                self.capture.fifo_pointer_anomalies.append(
                    f"cycle {self.cycle}: stock {stock_index} read pointer "
                    f"jumped by {rd_delta}"
                )

            self.capture.fifo_occupancy[stock_index] += wr_delta - rd_delta
            if self.capture.fifo_occupancy[stock_index] < 0:
                self.capture.fifo_pointer_anomalies.append(
                    f"cycle {self.cycle}: stock {stock_index} FIFO occupancy "
                    f"became {self.capture.fifo_occupancy[stock_index]}"
                )

            self.capture.fifo_max_occupancy[stock_index] = max(
                self.capture.fifo_max_occupancy[stock_index],
                self.capture.fifo_occupancy[stock_index],
            )

            if (
                self.capture.fifo_occupancy[stock_index]
                > FIFO_SAFE_OCCUPANCY
            ):
                self.capture.fifo_overflow_cycles[stock_index].append(self.cycle)

        self._previous_wr_ptrs = wr_ptrs
        self._previous_rd_ptrs = rd_ptrs

    def _sample_errors(self) -> None:
        if signal_value_to_int(self.dut.frame_drop_o.value) == 1:
            self.capture.frame_drop_errs.append(
                signal_value_to_int(self.dut.frame_err_o.value)
            )
        if signal_value_to_int(self.dut.mold_drop_o.value) == 1:
            self.capture.mold_drop_errs.append(
                signal_value_to_int(self.dut.mold_err_o.value)
            )

        realign_err = signal_value_to_int(self.dut.realign_err_o.value)
        if realign_err != 0:
            self.capture.realign_errs.append(realign_err)

        if signal_value_to_int(self.dut.gap_o.value) == 1:
            self.capture.unexpected_gap_cycles.append(self.cycle)
        if signal_value_to_int(self.dut.duplicate_o.value) == 1:
            self.capture.unexpected_duplicate_cycles.append(self.cycle)
        if signal_value_to_int(self.dut.stale_o.value) == 1:
            self.capture.unexpected_stale_cycles.append(self.cycle)

    async def wait_for_external_bbos(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = DEFAULT_TIMEOUT_CYCLES,
    ) -> None:
        if expected_count <= 0:
            raise ValueError(
                f"expected_count must be positive, got {expected_count}"
            )

        for _ in range(timeout_cycles):
            if self.capture.completed_event_count >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        raise TimeoutError(
            f"timed out waiting for {expected_count} external BBO(s); "
            f"got {self.capture.completed_event_count}"
        )

    def stop(self) -> None:
        self.running = False


async def wait_for_books_ready(
    dut: Any,
    *,
    timeout_cycles: int = 100_000,
) -> int:
    """Wait for all three order books to complete their startup clear."""

    waited_cycles = 0
    for _ in range(timeout_cycles):
        await ReadOnly()
        if signal_value_to_int(dut.probe_books_ready_o.value) == 1:
            return waited_cycles
        await RisingEdge(dut.clk)
        waited_cycles += 1

    raise TimeoutError("timed out waiting for all order books to become ready")


async def initialise_perf_feed_handler(
    dut: Any,
    *,
    clock_mhz: float | None = None,
    base_prices: tuple[int, int, int] = (
        DEFAULT_BASE_PRICE,
        DEFAULT_BASE_PRICE,
        DEFAULT_BASE_PRICE,
    ),
    reset_cycles: int = 5,
) -> tuple[float, int]:
    """Start the clock, reset the full chain and wait out BRAM clearing."""

    resolved_clock_mhz = await start_perf_clock(dut, clock_mhz=clock_mhz)
    reset_to_ready_cycles = await reset_perf_feed_handler(
        dut,
        base_prices=base_prices,
        reset_cycles=reset_cycles,
    )
    return resolved_clock_mhz, reset_to_ready_cycles


async def reset_perf_feed_handler(
    dut: Any,
    *,
    base_prices: tuple[int, int, int] = (
        DEFAULT_BASE_PRICE,
        DEFAULT_BASE_PRICE,
        DEFAULT_BASE_PRICE,
    ),
    reset_cycles: int = 5,
) -> int:
    """Restore an idle full-chain DUT and wait for all books to leave CLEAR.

    The previous operation may have returned from cocotb's ReadOnly phase. Wait
    for a falling edge before driving configuration or AXI inputs so every call
    starts from a phase in which signal writes are legal.
    """

    await FallingEdge(dut.clk)

    dut.base_price_stock0_i.value = base_prices[0]
    dut.base_price_stock1_i.value = base_prices[1]
    dut.base_price_stock2_i.value = base_prices[2]

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0

    await reset_dut(dut, cycles=reset_cycles)
    return await wait_for_books_ready(dut)


async def wait_for_external_bbo_pulse(
    dut: Any,
    *,
    timeout_cycles: int = DEFAULT_TIMEOUT_CYCLES,
) -> int:
    """Wait for one external BBO pulse and return its stock ID."""

    for _ in range(timeout_cycles):
        await RisingEdge(dut.clk)
        await ReadOnly()
        if signal_value_to_int(dut.bbo_valid_o.value) == 1:
            return signal_value_to_int(dut.probe_external_stock_id_o.value)

    raise TimeoutError("timed out waiting for an external BBO pulse")


async def drive_frame_and_wait_for_bbo(
    dut: Any,
    frame: bytes,
    *,
    timeout_cycles: int = DEFAULT_TIMEOUT_CYCLES,
) -> int:
    """Drive one priming frame while a concurrent task watches for its BBO."""

    from .perf import drive_axis_frame_continuous

    waiter = cocotb.start_soon(
        wait_for_external_bbo_pulse(dut, timeout_cycles=timeout_cycles)
    )
    await drive_axis_frame_continuous(
        dut,
        frame,
        timeout_cycles_per_beat=timeout_cycles,
    )
    return await waiter
