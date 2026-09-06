"""Dual-clock sustained-throughput helpers for the pre-Taxi line-rate regression.

The production RTL is observed at the existing protocol/event boundaries.  The
simulation wrapper models the ZCU106 clock partition rather than running the
whole feed handler from one clock:

    ingress + data_handler : 156.25 MHz
    normalised event FIFO  : asynchronous CDC, depth 16
    order_book_top         : 100 MHz
    order-book BRAM        : 200 MHz

The Ethernet source deliberately keeps ``tvalid`` asserted and changes to the
next beat immediately after a handshake.  If ``tready`` deasserts, the current
beat is held stable as required by AXI4-Stream; no source-side bubbles are added.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from .axis import reset_dut
from .perf import bytes_per_cycle, messages_per_second, throughput_gbps
from .scoreboard import signal_value_to_int


NETWORK_CLOCK_MHZ = 156.25
DATA_CLOCK_MHZ = 100.0
BRAM_CLOCK_MHZ = 200.0

NETWORK_PERIOD_PS = 6_400
DATA_PERIOD_PS = 10_000
BRAM_PERIOD_PS = 5_000

EVENT_FIFO_DEPTH = 16
BBO_FIFO_DEPTH = 16
BBO_FIFO_SAFE_OCCUPANCY = BBO_FIFO_DEPTH - 1

DEFAULT_BASE_PRICE = 9_000
DEFAULT_TIMEOUT_NETWORK_CYCLES = 2_000_000
DEFAULT_TIMEOUT_DATA_CYCLES = 2_000_000


@dataclass
class LineRateCapture:
    """Cycle-accurate observations from the network and data clock domains."""

    # Network-domain transfer cycles and byte counts.
    frame_fire_cycles: list[int] = field(default_factory=list)
    frame_fire_bytes: list[int] = field(default_factory=list)
    frame_last_cycles: list[int] = field(default_factory=list)

    dgram_fire_cycles: list[int] = field(default_factory=list)
    dgram_fire_bytes: list[int] = field(default_factory=list)
    payload_fire_cycles: list[int] = field(default_factory=list)
    payload_fire_bytes: list[int] = field(default_factory=list)
    msg_len_fire_cycles: list[int] = field(default_factory=list)
    itch_fire_cycles: list[int] = field(default_factory=list)
    itch_fire_bytes: list[int] = field(default_factory=list)
    itch_last_cycles: list[int] = field(default_factory=list)
    decoded_fire_cycles: list[int] = field(default_factory=list)

    # Network-domain stalls: valid is being offered but downstream is not ready.
    frame_stall_cycles: int = 0
    dgram_stall_cycles: int = 0
    payload_stall_cycles: int = 0
    msg_len_stall_cycles: int = 0
    itch_stall_cycles: int = 0
    decoded_stall_cycles: int = 0

    # Event FIFO write-domain occupancy/high-water data.
    event_fifo_level_samples: list[int] = field(default_factory=list)
    event_fifo_max_level: int = 0
    event_fifo_full_cycles: list[int] = field(default_factory=list)

    # Data-domain event acceptance / order-book state.
    fifo_read_fire_cycles: list[int] = field(default_factory=list)
    fifo_read_stall_cycles: int = 0
    book_busy_cycles: list[int] = field(default_factory=lambda: [0, 0, 0])

    internal_bbo_cycles: list[list[int]] = field(
        default_factory=lambda: [[], [], []]
    )
    external_bbo_cycles: list[int] = field(default_factory=list)
    external_bbo_stock_ids: list[int] = field(default_factory=list)

    # Track the logical occupancy independently of the RTL's modulo-16 pointers.
    # This detects the current no-full-condition failure exactly when occupancy
    # reaches 16, even though the RTL pointers then alias an empty FIFO.
    bbo_fifo_occupancy: list[int] = field(default_factory=lambda: [0, 0, 0])
    bbo_fifo_max_occupancy: list[int] = field(default_factory=lambda: [0, 0, 0])
    bbo_fifo_overflow_cycles: list[list[int]] = field(
        default_factory=lambda: [[], [], []]
    )
    bbo_fifo_underflow_notes: list[str] = field(default_factory=list)

    frame_drop_errs: list[int] = field(default_factory=list)
    mold_drop_errs: list[int] = field(default_factory=list)
    realign_errs: list[int] = field(default_factory=list)
    unexpected_gap_cycles: list[int] = field(default_factory=list)
    unexpected_duplicate_cycles: list[int] = field(default_factory=list)
    unexpected_stale_cycles: list[int] = field(default_factory=list)

    @property
    def accepted_frame_bytes(self) -> int:
        return sum(self.frame_fire_bytes)

    @property
    def accepted_dgram_bytes(self) -> int:
        return sum(self.dgram_fire_bytes)

    @property
    def accepted_payload_bytes(self) -> int:
        return sum(self.payload_fire_bytes)

    @property
    def accepted_itch_bytes(self) -> int:
        return sum(self.itch_fire_bytes)

    @property
    def decoded_event_count(self) -> int:
        return len(self.decoded_fire_cycles)

    @property
    def fifo_read_count(self) -> int:
        return len(self.fifo_read_fire_cycles)

    @property
    def internal_bbo_count(self) -> int:
        return sum(len(cycles) for cycles in self.internal_bbo_cycles)

    @property
    def external_bbo_count(self) -> int:
        return len(self.external_bbo_cycles)

    def assert_protocol_clean(self) -> None:
        """Fail on malformed-protocol behaviour unrelated to throughput."""

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
            f"unexpected Mold gap pulses: {self.unexpected_gap_cycles}"
        )
        assert self.unexpected_duplicate_cycles == [], (
            "unexpected Mold duplicate pulses: "
            f"{self.unexpected_duplicate_cycles}"
        )
        assert self.unexpected_stale_cycles == [], (
            f"unexpected Mold stale pulses: {self.unexpected_stale_cycles}"
        )

    def rate_report(
        self,
        *,
        case_name: str,
        message_type: str,
        expected_events: int,
        frame_count: int,
        primed_events: int,
    ) -> dict[str, Any]:
        """Build one sustained-throughput report without hiding any failure."""

        def window(cycles: list[int]) -> int | None:
            if not cycles:
                return None
            return cycles[-1] - cycles[0] + 1

        def bpc(byte_count: int, cycles: list[int]) -> float | None:
            elapsed = window(cycles)
            if elapsed is None:
                return None
            return bytes_per_cycle(byte_count, elapsed)

        def gbps(byte_count: int, cycles: list[int]) -> float | None:
            elapsed = window(cycles)
            if elapsed is None:
                return None
            return throughput_gbps(
                byte_count,
                elapsed,
                clock_mhz=NETWORK_CLOCK_MHZ,
            )

        def mps(count: int, cycles: list[int], clock_mhz: float) -> float | None:
            elapsed = window(cycles)
            if elapsed is None:
                return None
            return messages_per_second(count, elapsed, clock_mhz=clock_mhz)

        frame_window = window(self.frame_fire_cycles)
        accepted_frame_beats = len(self.frame_fire_cycles)
        source_acceptance_ratio = (
            accepted_frame_beats / frame_window
            if frame_window not in (None, 0)
            else None
        )

        # The deepest stage with observed backpressure is useful when a source
        # stall has propagated all the way to Ethernet.
        stalls = {
            "frame_crack_input": self.frame_stall_cycles,
            "frame_crack_to_mold": self.dgram_stall_cycles,
            "mold_to_realign_payload": self.payload_stall_cycles,
            "mold_to_realign_length": self.msg_len_stall_cycles,
            "realign_to_data_handler": self.itch_stall_cycles,
            "data_handler_to_event_fifo": self.decoded_stall_cycles,
            "event_fifo_to_order_book": self.fifo_read_stall_cycles,
        }
        stalled_boundaries = [
            name for name, count in stalls.items() if count > 0
        ]
        deepest_stalled_boundary = (
            stalled_boundaries[-1] if stalled_boundaries else None
        )

        return {
            "case": case_name,
            "message_type": message_type,
            "expected_events": expected_events,
            "primed_events": primed_events,
            "frames": frame_count,
            "network_clock_mhz": NETWORK_CLOCK_MHZ,
            "data_clock_mhz": DATA_CLOCK_MHZ,
            "bram_clock_mhz": BRAM_CLOCK_MHZ,
            "accepted_frame_beats": accepted_frame_beats,
            "accepted_frame_bytes": self.accepted_frame_bytes,
            "accepted_dgram_bytes": self.accepted_dgram_bytes,
            "accepted_payload_bytes": self.accepted_payload_bytes,
            "accepted_itch_bytes": self.accepted_itch_bytes,
            "frame_window_cycles": frame_window,
            "source_acceptance_ratio": source_acceptance_ratio,
            "input_bytes_per_cycle": bpc(
                self.accepted_frame_bytes,
                self.frame_fire_cycles,
            ),
            "input_bus_gbps": gbps(
                self.accepted_frame_bytes,
                self.frame_fire_cycles,
            ),
            "dgram_bytes_per_cycle": bpc(
                self.accepted_dgram_bytes,
                self.dgram_fire_cycles,
            ),
            "payload_bytes_per_cycle": bpc(
                self.accepted_payload_bytes,
                self.payload_fire_cycles,
            ),
            "itch_bytes_per_cycle": bpc(
                self.accepted_itch_bytes,
                self.itch_fire_cycles,
            ),
            "decoded_events": self.decoded_event_count,
            "decoded_events_per_second": mps(
                self.decoded_event_count,
                self.decoded_fire_cycles,
                NETWORK_CLOCK_MHZ,
            ),
            "event_fifo_reads": self.fifo_read_count,
            "event_fifo_reads_per_second": mps(
                self.fifo_read_count,
                self.fifo_read_fire_cycles,
                DATA_CLOCK_MHZ,
            ),
            "event_fifo_max_level": self.event_fifo_max_level,
            "event_fifo_full_cycles": len(self.event_fifo_full_cycles),
            "internal_bbos": self.internal_bbo_count,
            "external_bbos": self.external_bbo_count,
            "bbo_fifo_max_occupancy": self.bbo_fifo_max_occupancy,
            "bbo_fifo_overflow": [
                bool(cycles) for cycles in self.bbo_fifo_overflow_cycles
            ],
            "stall_cycles": stalls,
            "deepest_stalled_boundary": deepest_stalled_boundary,
            "source_stalled": self.frame_stall_cycles > 0,
            "event_fifo_bounded": self.event_fifo_max_level < EVENT_FIFO_DEPTH,
            "bbo_output_loss": self.external_bbo_count != expected_events,
        }


class LineRateMonitor:
    """Observe the dual-clock line-rate probe without driving production state."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.capture = LineRateCapture()
        self.running = True
        self.network_cycle = 0
        self.data_cycle = 0

    async def run_network(self) -> None:
        while self.running:
            await RisingEdge(self.dut.clk)
            await ReadOnly()
            self._sample_network()
            self.network_cycle += 1

    async def run_data(self) -> None:
        while self.running:
            await RisingEdge(self.dut.data_clk)
            await ReadOnly()
            self._sample_data()
            self.data_cycle += 1

    def _sample_network(self) -> None:
        if signal_value_to_int(self.dut.rst_n.value) == 0:
            return

        capture = self.capture

        if (
            signal_value_to_int(self.dut.s_frame_tvalid_i.value) == 1
            and signal_value_to_int(self.dut.s_frame_tready_o.value) == 0
        ):
            capture.frame_stall_cycles += 1

        stage_pairs = (
            ("dgram", self.dut.probe_dgram_tvalid_o, self.dut.probe_dgram_tready_o),
            (
                "payload",
                self.dut.probe_payload_tvalid_o,
                self.dut.probe_payload_tready_o,
            ),
            (
                "msg_len",
                self.dut.probe_msg_len_valid_o,
                self.dut.probe_msg_len_ready_o,
            ),
            ("itch", self.dut.probe_itch_tvalid_o, self.dut.probe_itch_tready_o),
            (
                "decoded",
                self.dut.probe_decoded_valid_o,
                self.dut.probe_decoded_ready_o,
            ),
        )
        for name, valid_signal, ready_signal in stage_pairs:
            if (
                signal_value_to_int(valid_signal.value) == 1
                and signal_value_to_int(ready_signal.value) == 0
            ):
                setattr(
                    capture,
                    f"{name}_stall_cycles",
                    getattr(capture, f"{name}_stall_cycles") + 1,
                )

        if signal_value_to_int(self.dut.probe_frame_fire_o.value) == 1:
            keep = signal_value_to_int(self.dut.probe_frame_keep_o.value)
            capture.frame_fire_cycles.append(self.network_cycle)
            capture.frame_fire_bytes.append(keep.bit_count())
            if signal_value_to_int(self.dut.probe_frame_last_fire_o.value) == 1:
                capture.frame_last_cycles.append(self.network_cycle)

        if signal_value_to_int(self.dut.probe_dgram_fire_o.value) == 1:
            keep = signal_value_to_int(self.dut.probe_dgram_keep_o.value)
            capture.dgram_fire_cycles.append(self.network_cycle)
            capture.dgram_fire_bytes.append(keep.bit_count())

        if signal_value_to_int(self.dut.probe_payload_fire_o.value) == 1:
            keep = signal_value_to_int(self.dut.probe_payload_keep_o.value)
            capture.payload_fire_cycles.append(self.network_cycle)
            capture.payload_fire_bytes.append(keep.bit_count())

        if signal_value_to_int(self.dut.probe_msg_len_fire_o.value) == 1:
            capture.msg_len_fire_cycles.append(self.network_cycle)

        if signal_value_to_int(self.dut.probe_itch_fire_o.value) == 1:
            keep = signal_value_to_int(self.dut.probe_itch_keep_o.value)
            capture.itch_fire_cycles.append(self.network_cycle)
            capture.itch_fire_bytes.append(keep.bit_count())
            if signal_value_to_int(self.dut.probe_itch_last_fire_o.value) == 1:
                capture.itch_last_cycles.append(self.network_cycle)

        if signal_value_to_int(self.dut.probe_decoded_fire_o.value) == 1:
            capture.decoded_fire_cycles.append(self.network_cycle)

        fifo_level = signal_value_to_int(
            self.dut.probe_event_fifo_wr_level_o.value
        )
        capture.event_fifo_level_samples.append(fifo_level)
        capture.event_fifo_max_level = max(capture.event_fifo_max_level, fifo_level)
        if signal_value_to_int(self.dut.probe_event_fifo_full_o.value) == 1:
            capture.event_fifo_full_cycles.append(self.network_cycle)

        if signal_value_to_int(self.dut.frame_drop_o.value) == 1:
            capture.frame_drop_errs.append(
                signal_value_to_int(self.dut.frame_err_o.value)
            )
        if signal_value_to_int(self.dut.mold_drop_o.value) == 1:
            capture.mold_drop_errs.append(
                signal_value_to_int(self.dut.mold_err_o.value)
            )

        realign_err = signal_value_to_int(self.dut.realign_err_o.value)
        if realign_err != 0:
            capture.realign_errs.append(realign_err)

        if signal_value_to_int(self.dut.gap_o.value) == 1:
            capture.unexpected_gap_cycles.append(self.network_cycle)
        if signal_value_to_int(self.dut.duplicate_o.value) == 1:
            capture.unexpected_duplicate_cycles.append(self.network_cycle)
        if signal_value_to_int(self.dut.stale_o.value) == 1:
            capture.unexpected_stale_cycles.append(self.network_cycle)

    def _sample_data(self) -> None:
        if signal_value_to_int(self.dut.rst_n.value) == 0:
            return

        capture = self.capture

        if (
            signal_value_to_int(self.dut.probe_fifo_m_valid_o.value) == 1
            and signal_value_to_int(self.dut.probe_fifo_m_ready_o.value) == 0
        ):
            capture.fifo_read_stall_cycles += 1

        if signal_value_to_int(self.dut.probe_fifo_read_fire_o.value) == 1:
            capture.fifo_read_fire_cycles.append(self.data_cycle)

        ready_signals = (
            self.dut.probe_book_ready_stock0_o,
            self.dut.probe_book_ready_stock1_o,
            self.dut.probe_book_ready_stock2_o,
        )
        for stock_index, signal in enumerate(ready_signals):
            if signal_value_to_int(signal.value) == 0:
                capture.book_busy_cycles[stock_index] += 1

        writes = [
            signal_value_to_int(
                self.dut.probe_internal_bbo_valid_stock0_o.value
            ),
            signal_value_to_int(
                self.dut.probe_internal_bbo_valid_stock1_o.value
            ),
            signal_value_to_int(
                self.dut.probe_internal_bbo_valid_stock2_o.value
            ),
        ]

        external_valid = signal_value_to_int(self.dut.bbo_valid_o.value) == 1
        external_stock_index: int | None = None
        if external_valid:
            stock_id = signal_value_to_int(
                self.dut.probe_external_stock_id_o.value
            )
            capture.external_bbo_cycles.append(self.data_cycle)
            capture.external_bbo_stock_ids.append(stock_id)
            if 1 <= stock_id <= 3:
                external_stock_index = stock_id - 1
            else:
                capture.bbo_fifo_underflow_notes.append(
                    f"cycle {self.data_cycle}: invalid external stock_id={stock_id}"
                )

        for stock_index, write in enumerate(writes):
            read = external_stock_index == stock_index

            if write:
                capture.internal_bbo_cycles[stock_index].append(self.data_cycle)
                capture.bbo_fifo_occupancy[stock_index] += 1

            if read:
                if capture.bbo_fifo_occupancy[stock_index] <= 0:
                    capture.bbo_fifo_underflow_notes.append(
                        f"cycle {self.data_cycle}: stock {stock_index} read "
                        "with logical occupancy zero"
                    )
                else:
                    capture.bbo_fifo_occupancy[stock_index] -= 1

            capture.bbo_fifo_max_occupancy[stock_index] = max(
                capture.bbo_fifo_max_occupancy[stock_index],
                capture.bbo_fifo_occupancy[stock_index],
            )

            if capture.bbo_fifo_occupancy[stock_index] >= BBO_FIFO_DEPTH:
                capture.bbo_fifo_overflow_cycles[stock_index].append(
                    self.data_cycle
                )

    async def wait_for_decoded_events(
        self,
        count: int,
        *,
        timeout_cycles: int = DEFAULT_TIMEOUT_NETWORK_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            if self.capture.decoded_event_count >= count:
                return
            await RisingEdge(self.dut.clk)
        raise TimeoutError(
            f"timed out waiting for {count} decoded events; "
            f"got {self.capture.decoded_event_count}"
        )

    async def wait_for_fifo_reads(
        self,
        count: int,
        *,
        timeout_cycles: int = DEFAULT_TIMEOUT_DATA_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            if self.capture.fifo_read_count >= count:
                return
            await RisingEdge(self.dut.data_clk)
        raise TimeoutError(
            f"timed out waiting for {count} event-FIFO reads; "
            f"got {self.capture.fifo_read_count}"
        )

    async def wait_for_internal_bbos(
        self,
        count: int,
        *,
        timeout_cycles: int = DEFAULT_TIMEOUT_DATA_CYCLES,
    ) -> bool:
        """Return False on timeout so a broken output path is reported, not hidden."""

        for _ in range(timeout_cycles):
            if self.capture.internal_bbo_count >= count:
                return True
            await RisingEdge(self.dut.data_clk)
        return False

    def stop(self) -> None:
        self.running = False


async def start_line_rate_clocks(dut: Any) -> None:
    """Start exact 156.25/100/200 MHz clocks used by the regression model."""

    cocotb.start_soon(
        Clock(dut.clk, NETWORK_PERIOD_PS, unit="ps").start()
    )
    cocotb.start_soon(
        Clock(dut.data_clk, DATA_PERIOD_PS, unit="ps").start()
    )
    cocotb.start_soon(
        Clock(dut.bram_clk, BRAM_PERIOD_PS, unit="ps").start()
    )


async def initialise_line_rate_probe(dut: Any) -> None:
    """Initialise stable controls, start clocks and reset the complete probe."""

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0

    dut.base_price_stock0_i.value = DEFAULT_BASE_PRICE
    dut.base_price_stock1_i.value = DEFAULT_BASE_PRICE
    dut.base_price_stock2_i.value = DEFAULT_BASE_PRICE

    await start_line_rate_clocks(dut)
    await reset_line_rate_probe(dut)


async def reset_line_rate_probe(
    dut: Any,
    *,
    reset_network_cycles: int = 8,
    ready_timeout_data_cycles: int = 100_000,
) -> None:
    """Reset all domains and wait for all three order books to finish clearing."""

    # A monitor task can finish immediately after ``ReadOnly()``, which means a
    # caller awaiting that task resumes in the read-only simulator phase.  Move
    # to the next network falling edge before driving the input/reset controls.
    # This is outside every measured campaign, so it does not alter any latency
    # or sustained-throughput result.
    await FallingEdge(dut.clk)

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0

    # Reuse the established active-low reset helper on the network clock.  The
    # same reset reaches the data/BRAM domains and the simulated async FIFO.
    await reset_dut(dut, cycles=reset_network_cycles)

    for _ in range(ready_timeout_data_cycles):
        await RisingEdge(dut.data_clk)
        await ReadOnly()
        if signal_value_to_int(dut.probe_books_ready_o.value) == 1:
            await FallingEdge(dut.data_clk)
            return

    raise TimeoutError("timed out waiting for all order books to finish clearing")


async def wait_for_external_bbo(
    dut: Any,
    *,
    timeout_data_cycles: int = DEFAULT_TIMEOUT_DATA_CYCLES,
) -> None:
    """Wait for one external BBO pulse, used to pace unmeasured priming traffic."""

    for _ in range(timeout_data_cycles):
        await RisingEdge(dut.data_clk)
        await ReadOnly()
        if signal_value_to_int(dut.bbo_valid_o.value) == 1:
            return
    raise TimeoutError("timed out waiting for external BBO during priming")


def write_line_rate_summary(
    *,
    results_dir: Path,
    records: list[dict[str, Any]],
    enforcement_failures: list[str],
    mode: str,
) -> None:
    """Write machine-readable and compact human-readable regression results."""

    results_dir.mkdir(parents=True, exist_ok=True)

    short_record_bytes = 2 + 19  # Mold message length prefix + D payload.
    conservative_short_event_rate = 10e9 / (8 * short_record_bytes)

    result = {
        "schema_version": 1,
        "benchmark": "pre_taxi_dual_clock_line_rate",
        "mode": mode,
        "network_clock_mhz": NETWORK_CLOCK_MHZ,
        "data_clock_mhz": DATA_CLOCK_MHZ,
        "bram_clock_mhz": BRAM_CLOCK_MHZ,
        "conservative_short_event_ceiling_per_second": (
            conservative_short_event_rate
        ),
        "order_book_ii1_capacity_per_second": DATA_CLOCK_MHZ * 1e6,
        "cases": records,
        "enforcement_failures": enforcement_failures,
    }

    (results_dir / "results.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    lines = [
        "# Pre-Taxi dual-clock line-rate regression",
        "",
        f"Mode: `{mode}`",
        "",
        "Clock model: 156.25 MHz network / 100 MHz order book / 200 MHz BRAM.",
        "",
        "| Case | Source stalls | Input acceptance | Event FIFO HWM | "
        "BBO FIFO HWM | External/expected BBO | Deepest stalled boundary |",
        "|---|---:|---:|---:|---|---:|---|",
    ]

    for record in records:
        acceptance = record.get("source_acceptance_ratio")
        acceptance_text = "n/a" if acceptance is None else f"{acceptance:.6f}"
        bbo_hwm = "/".join(str(v) for v in record["bbo_fifo_max_occupancy"])
        lines.append(
            f"| {record['case']} | {record['stall_cycles']['frame_crack_input']} | "
            f"{acceptance_text} | {record['event_fifo_max_level']} | {bbo_hwm} | "
            f"{record['external_bbos']}/{record['expected_events']} | "
            f"{record['deepest_stalled_boundary'] or 'none'} |"
        )

    lines.extend(["", "## Enforcement findings", ""])
    if enforcement_failures:
        lines.extend(f"- {failure}" for failure in enforcement_failures)
    else:
        lines.append("- No line-rate gate failures were observed.")

    lines.extend(
        [
            "",
            "The zero-gap AXI source is deliberately stricter than a physical "
            "10GbE MAC stream because it does not insert Ethernet IFG/FCS wire "
            "overhead. The primary ingress gate is therefore zero persistent "
            "source backpressure and bounded buffering, rather than requiring "
            "the valid-byte `input_bus_gbps` field to print exactly 10.000.",
            "",
        ]
    )

    (results_dir / "summary.md").write_text(
        "\n".join(lines),
        encoding="utf-8",
    )
