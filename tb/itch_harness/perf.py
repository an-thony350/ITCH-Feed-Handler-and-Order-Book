"""Cycle-accurate measurement helpers for ingress performance tests.

The monitors observe actual ready/valid handshakes exposed by simulation-only
probe wrappers. They do not modify the production RTL.

Cycle conventions:
- A transfer occurs when valid and ready are both high at a rising clock edge.
- Latency is the difference between destination and source handshake cycles.
- A throughput window is inclusive: last_cycle - first_cycle + 1.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Any

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from .axis import reset_dut
from .ingress_packets import WORD_BYTES, frame_to_axis_words
from .scoreboard import signal_value_to_int


DEFAULT_CLOCK_MHZ = 100.0
CLOCK_MHZ_ENV = "CLOCK_MHZ"


def clock_mhz_from_env(*, default: float = DEFAULT_CLOCK_MHZ) -> float:
    """Read the routed clock frequency from ``CLOCK_MHZ``.

    Examples:
        CLOCK_MHZ=100     -> 100 MHz / 10 ns
        CLOCK_MHZ=106.667 -> approximately 9.375 ns
    """

    raw_value = os.environ.get(CLOCK_MHZ_ENV)
    clock_mhz = default if raw_value is None else float(raw_value)

    if clock_mhz <= 0:
        raise ValueError(f"{CLOCK_MHZ_ENV} must be positive, got {clock_mhz}")

    return clock_mhz


def resolve_clock_mhz(clock_mhz: float | None) -> float:
    """Return an explicit frequency or the environment/default frequency."""

    resolved = clock_mhz_from_env() if clock_mhz is None else float(clock_mhz)
    if resolved <= 0:
        raise ValueError(f"clock_mhz must be positive, got {resolved}")
    return resolved


def clock_period_ns_from_mhz(clock_mhz: float | None = None) -> float:
    """Convert MHz to an exact floating-point period in nanoseconds."""

    return 1_000.0 / resolve_clock_mhz(clock_mhz)


def clock_period_ps_from_mhz(clock_mhz: float | None = None) -> int:
    """Convert MHz to the nearest integer-picosecond simulator period."""

    period_ps = int(round(1_000_000.0 / resolve_clock_mhz(clock_mhz)))
    if period_ps <= 0:
        raise ValueError(f"derived clock period must be positive, got {period_ps} ps")
    return period_ps


def cycles_to_ns(
    cycles: int,
    *,
    clock_mhz: float | None = None,
) -> float:
    """Convert a cycle count using the selected clock frequency."""

    if cycles < 0:
        raise ValueError(f"cycles must be non-negative, got {cycles}")
    return cycles * clock_period_ns_from_mhz(clock_mhz)


def transfer_window_cycles(cycles: list[int]) -> int:
    """Return the inclusive number of cycles spanning a transfer sequence."""

    if not cycles:
        raise ValueError("cannot calculate a transfer window from no transfers")
    return cycles[-1] - cycles[0] + 1


def bytes_per_cycle(byte_count: int, elapsed_cycles: int) -> float:
    """Calculate bytes transferred per elapsed cycle."""

    if byte_count < 0:
        raise ValueError(f"byte_count must be non-negative, got {byte_count}")
    if elapsed_cycles <= 0:
        raise ValueError(
            f"elapsed_cycles must be positive, got {elapsed_cycles}"
        )
    return byte_count / elapsed_cycles


def throughput_gbps(
    byte_count: int,
    elapsed_cycles: int,
    *,
    clock_mhz: float | None = None,
) -> float:
    """Convert bytes/cycle into decimal Gbit/s at the selected clock."""

    clock_hz = resolve_clock_mhz(clock_mhz) * 1_000_000.0
    return bytes_per_cycle(byte_count, elapsed_cycles) * 8 * clock_hz / 1e9


def messages_per_second(
    message_count: int,
    elapsed_cycles: int,
    *,
    clock_mhz: float | None = None,
) -> float:
    """Convert completed messages/cycle into messages per second."""

    if message_count < 0:
        raise ValueError(
            f"message_count must be non-negative, got {message_count}"
        )
    if elapsed_cycles <= 0:
        raise ValueError(
            f"elapsed_cycles must be positive, got {elapsed_cycles}"
        )

    clock_hz = resolve_clock_mhz(clock_mhz) * 1_000_000.0
    return message_count * clock_hz / elapsed_cycles


def _valid_byte_count(keep_value: int) -> int:
    """Count asserted byte qualifiers in an AXI4-Stream tkeep value."""

    return keep_value.bit_count()


def _first(cycles: list[int], name: str) -> int:
    if not cycles:
        raise ValueError(f"no {name} handshake was captured")
    return cycles[0]


def _last(cycles: list[int], name: str) -> int:
    if not cycles:
        raise ValueError(f"no {name} handshake was captured")
    return cycles[-1]


@dataclass
class IngressPerfCapture:
    """Captured cycles, byte counts, stalls, messages, and error events."""

    frame_fire_cycles: list[int] = field(default_factory=list)
    frame_fire_bytes: list[int] = field(default_factory=list)

    dgram_start_cycles: list[int] = field(default_factory=list)
    dgram_fire_cycles: list[int] = field(default_factory=list)
    dgram_fire_bytes: list[int] = field(default_factory=list)
    dgram_last_cycles: list[int] = field(default_factory=list)

    seq_valid_cycles: list[int] = field(default_factory=list)

    payload_fire_cycles: list[int] = field(default_factory=list)
    payload_fire_bytes: list[int] = field(default_factory=list)
    payload_last_cycles: list[int] = field(default_factory=list)

    msg_len_fire_cycles: list[int] = field(default_factory=list)

    itch_fire_cycles: list[int] = field(default_factory=list)
    itch_last_cycles: list[int] = field(default_factory=list)

    frame_stall_cycles: int = 0
    dgram_stall_cycles: int = 0
    payload_stall_cycles: int = 0
    msg_len_stall_cycles: int = 0
    itch_stall_cycles: int = 0

    messages: list[bytes] = field(default_factory=list)

    frame_drop_cycles: list[int] = field(default_factory=list)
    frame_drop_errs: list[int] = field(default_factory=list)
    mold_drop_cycles: list[int] = field(default_factory=list)
    mold_drop_errs: list[int] = field(default_factory=list)
    realign_err_cycles: list[int] = field(default_factory=list)
    realign_errs: list[int] = field(default_factory=list)

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
    def completed_message_count(self) -> int:
        return len(self.itch_last_cycles)

    def single_frame_latency_report(
        self,
        *,
        exact_itch_bytes: int,
        clock_mhz: float | None = None,
    ) -> dict[str, int | float]:
        """Build a latency report for one accepted frame.

        Both first-output and complete-message latency are reported. The ITCH
        output has no tkeep, so the exact message byte count is supplied by the
        stimulus rather than inferred from the padded final word.
        """

        if exact_itch_bytes <= 0:
            raise ValueError(
                f"exact_itch_bytes must be positive, got {exact_itch_bytes}"
            )

        resolved_clock_mhz = resolve_clock_mhz(clock_mhz)
        clock_period_ns = clock_period_ns_from_mhz(resolved_clock_mhz)

        first_frame = _first(self.frame_fire_cycles, "frame")
        last_frame = _last(self.frame_fire_cycles, "frame")
        first_dgram = _first(self.dgram_fire_cycles, "datagram")
        seq_valid = _first(self.seq_valid_cycles, "sequence-valid")
        first_payload = _first(self.payload_fire_cycles, "payload")
        first_msg_len = _first(self.msg_len_fire_cycles, "message-length")
        first_itch = _first(self.itch_fire_cycles, "ITCH")
        last_itch = _last(self.itch_last_cycles, "ITCH-last")

        latency_cycles = {
            "frame_to_first_dgram": first_dgram - first_frame,
            "frame_to_seq_valid": seq_valid - first_frame,
            "frame_to_first_payload": first_payload - first_frame,
            "frame_to_first_msg_len": first_msg_len - first_frame,
            "frame_to_first_itch": first_itch - first_frame,
            "frame_to_complete_itch": last_itch - first_frame,
            "last_frame_to_complete_itch": last_itch - last_frame,
        }

        for name, value in latency_cycles.items():
            if value < 0:
                raise ValueError(
                    f"captured negative latency for {name}: {value} cycles"
                )

        report: dict[str, int | float] = {
            "clock_period_ns": clock_period_ns,
            "clock_frequency_mhz": resolved_clock_mhz,
            "first_frame_cycle": first_frame,
            "last_frame_cycle": last_frame,
            "first_dgram_cycle": first_dgram,
            "seq_valid_cycle": seq_valid,
            "first_payload_cycle": first_payload,
            "first_msg_len_cycle": first_msg_len,
            "first_itch_cycle": first_itch,
            "complete_itch_cycle": last_itch,
            "accepted_frame_beats": len(self.frame_fire_cycles),
            "accepted_frame_bytes": self.accepted_frame_bytes,
            "accepted_dgram_beats": len(self.dgram_fire_cycles),
            "accepted_dgram_bytes": self.accepted_dgram_bytes,
            "accepted_payload_beats": len(self.payload_fire_cycles),
            "accepted_payload_bytes": self.accepted_payload_bytes,
            "accepted_itch_beats": len(self.itch_fire_cycles),
            "exact_itch_bytes": exact_itch_bytes,
            "completed_messages": self.completed_message_count,
            "frame_stall_cycles": self.frame_stall_cycles,
            "dgram_stall_cycles": self.dgram_stall_cycles,
            "payload_stall_cycles": self.payload_stall_cycles,
            "msg_len_stall_cycles": self.msg_len_stall_cycles,
            "itch_stall_cycles": self.itch_stall_cycles,
        }

        for name, value in latency_cycles.items():
            report[f"{name}_cycles"] = value
            report[f"{name}_ns"] = cycles_to_ns(
                value,
                clock_mhz=resolved_clock_mhz,
            )

        return report


class IngressPerfMonitor:
    """Observe the ingress performance-probe wrapper without affecting it."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.capture = IngressPerfCapture()

        self.running = True
        self.cycle = 0
        self._current_message = bytearray()

    async def run(self) -> None:
        while self.running:
            await RisingEdge(self.dut.clk)
            await ReadOnly()

            self._sample_current_cycle()
            self.cycle += 1

    def _sample_current_cycle(self) -> None:
        rst_n = signal_value_to_int(self.dut.rst_n.value)
        if rst_n == 0:
            return

        frame_valid = signal_value_to_int(self.dut.s_frame_tvalid_i.value)
        frame_ready = signal_value_to_int(self.dut.s_frame_tready_o.value)

        if frame_valid == 1 and frame_ready == 0:
            self.capture.frame_stall_cycles += 1

        if signal_value_to_int(self.dut.probe_frame_fire_o.value) == 1:
            keep = signal_value_to_int(self.dut.s_frame_tkeep_i.value)
            self.capture.frame_fire_cycles.append(self.cycle)
            self.capture.frame_fire_bytes.append(_valid_byte_count(keep))

        dgram_valid = signal_value_to_int(
            self.dut.probe_dgram_tvalid_o.value
        )
        dgram_ready = signal_value_to_int(
            self.dut.probe_dgram_tready_o.value
        )

        if dgram_valid == 1 and dgram_ready == 0:
            self.capture.dgram_stall_cycles += 1

        if signal_value_to_int(self.dut.probe_dgram_start_o.value) == 1:
            self.capture.dgram_start_cycles.append(self.cycle)

        if signal_value_to_int(self.dut.probe_dgram_fire_o.value) == 1:
            keep = signal_value_to_int(
                self.dut.probe_dgram_tkeep_o.value
            )
            self.capture.dgram_fire_cycles.append(self.cycle)
            self.capture.dgram_fire_bytes.append(_valid_byte_count(keep))

            if signal_value_to_int(
                self.dut.probe_dgram_tlast_o.value
            ) == 1:
                self.capture.dgram_last_cycles.append(self.cycle)

        if signal_value_to_int(self.dut.seq_valid_o.value) == 1:
            self.capture.seq_valid_cycles.append(self.cycle)

        payload_valid = signal_value_to_int(
            self.dut.probe_payload_tvalid_o.value
        )
        payload_ready = signal_value_to_int(
            self.dut.probe_payload_tready_o.value
        )

        if payload_valid == 1 and payload_ready == 0:
            self.capture.payload_stall_cycles += 1

        if signal_value_to_int(self.dut.probe_payload_fire_o.value) == 1:
            keep = signal_value_to_int(
                self.dut.probe_payload_tkeep_o.value
            )
            self.capture.payload_fire_cycles.append(self.cycle)
            self.capture.payload_fire_bytes.append(_valid_byte_count(keep))

            if signal_value_to_int(
                self.dut.probe_payload_tlast_o.value
            ) == 1:
                self.capture.payload_last_cycles.append(self.cycle)

        msg_len_valid = signal_value_to_int(
            self.dut.probe_msg_len_valid_o.value
        )
        msg_len_ready = signal_value_to_int(
            self.dut.probe_msg_len_ready_o.value
        )

        if msg_len_valid == 1 and msg_len_ready == 0:
            self.capture.msg_len_stall_cycles += 1

        if signal_value_to_int(self.dut.probe_msg_len_fire_o.value) == 1:
            self.capture.msg_len_fire_cycles.append(self.cycle)

        itch_valid = signal_value_to_int(self.dut.m_itch_tvalid_o.value)
        itch_ready = signal_value_to_int(self.dut.m_itch_tready_i.value)

        if itch_valid == 1 and itch_ready == 0:
            self.capture.itch_stall_cycles += 1

        if signal_value_to_int(self.dut.probe_itch_fire_o.value) == 1:
            self.capture.itch_fire_cycles.append(self.cycle)

            word = signal_value_to_int(self.dut.m_itch_tdata_o.value)
            self._current_message.extend(word.to_bytes(WORD_BYTES, "big"))

            if signal_value_to_int(
                self.dut.probe_itch_last_fire_o.value
            ) == 1:
                self.capture.itch_last_cycles.append(self.cycle)
                self.capture.messages.append(bytes(self._current_message))
                self._current_message.clear()

        if signal_value_to_int(self.dut.frame_drop_o.value) == 1:
            self.capture.frame_drop_cycles.append(self.cycle)
            self.capture.frame_drop_errs.append(
                signal_value_to_int(self.dut.frame_err_o.value)
            )

        if signal_value_to_int(self.dut.mold_drop_o.value) == 1:
            self.capture.mold_drop_cycles.append(self.cycle)
            self.capture.mold_drop_errs.append(
                signal_value_to_int(self.dut.mold_err_o.value)
            )

        realign_err = signal_value_to_int(self.dut.realign_err_o.value)
        if realign_err != 0:
            self.capture.realign_err_cycles.append(self.cycle)
            self.capture.realign_errs.append(realign_err)

    async def wait_for_completed_messages(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = 100_000,
    ) -> None:
        """Wait until the requested number of ITCH tlast handshakes occur."""

        if expected_count <= 0:
            raise ValueError(
                f"expected_count must be positive, got {expected_count}"
            )

        for _ in range(timeout_cycles):
            if self.capture.completed_message_count >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        raise TimeoutError(
            f"timed out waiting for {expected_count} completed message(s); "
            f"got {self.capture.completed_message_count}"
        )

    def stop(self) -> None:
        self.running = False


async def start_perf_clock(
    dut: Any,
    *,
    clock_mhz: float | None = None,
) -> float:
    """Start a simulator clock and return the resolved frequency in MHz."""

    resolved_clock_mhz = resolve_clock_mhz(clock_mhz)
    clock_period_ps = clock_period_ps_from_mhz(resolved_clock_mhz)

    # Odd integer-picosecond periods need an explicit high time so the two
    # half-periods sum to the requested rounded simulator period.
    clock_high_ps = clock_period_ps // 2

    cocotb.start_soon(
        Clock(
            dut.clk,
            clock_period_ps,
            unit="ps",
            period_high=clock_high_ps,
        ).start()
    )

    return resolved_clock_mhz


async def initialise_perf_ingress(
    dut: Any,
    *,
    clock_mhz: float | None = None,
    reset_cycles: int = 5,
) -> float:
    """Start the selected clock and reset the ingress performance-probe DUT."""

    resolved_clock_mhz = await start_perf_clock(dut, clock_mhz=clock_mhz)

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0
    dut.m_itch_tready_i.value = 1

    await reset_dut(dut, cycles=reset_cycles)
    return resolved_clock_mhz


async def _drive_axis_words_continuous(
    dut: Any,
    words: list[tuple[int, int, bool]],
    *,
    timeout_cycles_per_beat: int,
) -> None:
    if not words:
        raise ValueError("cannot drive an empty AXI4-Stream sequence")

    await FallingEdge(dut.clk)

    for index, (word, keep, last) in enumerate(words):
        dut.s_frame_tdata_i.value = word
        dut.s_frame_tkeep_i.value = keep
        dut.s_frame_tlast_i.value = int(last)
        dut.s_frame_tvalid_i.value = 1

        accepted = False

        for _ in range(timeout_cycles_per_beat):
            # Sample ready before the active edge; the destination may update its
            # state and deassert ready immediately after accepting this beat.
            await ReadOnly()
            ready_before_edge = signal_value_to_int(
                dut.s_frame_tready_o.value
            )
            await RisingEdge(dut.clk)

            if ready_before_edge == 1:
                accepted = True
                break

            await FallingEdge(dut.clk)

        if not accepted:
            raise TimeoutError(
                f"timed out waiting for input beat {index} of {len(words)} "
                "to be accepted"
            )

        if index + 1 < len(words):
            await FallingEdge(dut.clk)

    await FallingEdge(dut.clk)

    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0
    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0


async def drive_axis_frame_continuous(
    dut: Any,
    frame: bytes,
    *,
    timeout_cycles_per_beat: int = 100_000,
) -> None:
    """Drive one Ethernet frame without source-side beat bubbles."""

    words = frame_to_axis_words(frame)
    if not words:
        raise ValueError("cannot drive an empty Ethernet frame")

    await _drive_axis_words_continuous(
        dut,
        words,
        timeout_cycles_per_beat=timeout_cycles_per_beat,
    )


async def drive_axis_frames_continuous(
    dut: Any,
    frames: list[bytes],
    *,
    timeout_cycles_per_beat: int = 100_000,
) -> None:
    """Drive consecutive Ethernet frames with no forced inter-frame bubble."""

    if not frames:
        raise ValueError("cannot drive an empty frame list")

    words: list[tuple[int, int, bool]] = []
    for frame in frames:
        frame_words = frame_to_axis_words(frame)
        if not frame_words:
            raise ValueError("cannot drive an empty Ethernet frame")
        words.extend(frame_words)

    await _drive_axis_words_continuous(
        dut,
        words,
        timeout_cycles_per_beat=timeout_cycles_per_beat,
    )
