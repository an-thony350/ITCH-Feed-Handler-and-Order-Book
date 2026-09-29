"""Unit test for frame_crack, included in CI

Compile-time param of destination-port checking is done by running the same test twice with different environment variables

We check:
- valid payload extraction, header stripping, ordering and metadata;
- payload lengths 0..31 and a long legal payload;
- Ethernet padding, MAC independence and checksum independence;
- exhaustive current-interface tkeep classification;
- every RTL-defined header rejection path and combined error bitmasks;
- destination-port parameter behaviour for the active elaboration;
- runt/truncated frames and recovery;
- first/middle/final/periodic output backpressure with stability checks;
- source bubbles;
- consecutive valid/rejected/padded frames;
- reset during header, payload, backpressure and drain states;
- deterministic constrained-random valid traffic.

we don't cover latency/throughput stuff in this test
"""

from __future__ import annotations

import os
import random
from dataclasses import dataclass
from typing import Any, Callable

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from itch_harness.axis import axis_bytes_to_words, axis_word_bytes, reset_dut
from itch_harness.ingress_packets import build_eth_ipv4_udp_frame
from itch_harness.perf import start_perf_clock
from itch_harness.scoreboard import signal_value_to_int


TIMEOUT_CYCLES = 100_000
RESET_CYCLES = 5
FIXED_HEADER_BYTES = 42

# maybe make itch_harness/contracts.py for later unit tests
FRAME_ERR_BAD_ETHERTYPE = 0
FRAME_ERR_BAD_IP_VER = 1
FRAME_ERR_BAD_IHL = 2
FRAME_ERR_FRAGMENT = 3
FRAME_ERR_BAD_PROTO = 4
FRAME_ERR_BAD_UDP_PORT = 5
FRAME_ERR_BAD_UDP_LEN = 6
FRAME_ERR_RUNT_FRAME = 7
FRAME_ERR_BAD_TKEEP = 8

TEST_SEED = int(os.environ.get("TEST_SEED", "7"), 0)


@dataclass(frozen=True)
class PortConfig:
    check_enabled: bool
    expected_port: int


@dataclass(frozen=True)
class CapturedBeat:
    cycle: int
    data: int
    keep: int
    last: int
    start: int
    dgram_len: int


@dataclass(frozen=True)
class CapturedDatagram:
    payload: bytes
    dgram_len: int
    beats: tuple[CapturedBeat, ...]


@dataclass(frozen=True)
class DropEvent:
    cycle: int
    error: int
    aborted_payload: bytes


def _read_parameter(dut: Any, name: str) -> int | None:
    """Return a simulator-visible module parameter when one is exposed."""

    handle = getattr(dut, name, None)
    if handle is None:
        return None

    for candidate in (getattr(handle, "value", None), handle):
        try:
            return int(candidate)
        except (TypeError, ValueError):
            pass

    return None


def _port_config(dut: Any) -> PortConfig:
    """Resolve the active dest-port parameterisation"""

    check_value = _read_parameter(dut, "CHECK_DST_PORT")
    expected_value = _read_parameter(dut, "EXPECTED_DST_PORT")

    if check_value is None:
        check_value = int(os.environ.get("FRAME_CRACK_CHECK_DST_PORT", "0"), 0)
    if expected_value is None:
        expected_value = int(
            os.environ.get("FRAME_CRACK_EXPECTED_DST_PORT", "5000"),
            0,
        )

    if not 0 <= expected_value <= 0xFFFF:
        raise ValueError(
            "FRAME_CRACK_EXPECTED_DST_PORT must fit in 16 bits, "
            f"got {expected_value}"
        )

    return PortConfig(
        check_enabled=bool(check_value),
        expected_port=expected_value,
    )


def _set_u16(data: bytearray, offset: int, value: int) -> None:
    if not 0 <= value <= 0xFFFF:
        raise ValueError(f"16-bit field value out of range: {value}")
    data[offset : offset + 2] = value.to_bytes(2, "big")


def _build_frame(
    payload: bytes,
    *,
    dst_port: int,
    ethertype: int = 0x0800,
    ip_version: int = 4,
    ip_ihl: int = 5,
    ip_protocol: int = 17,
    ip_flags_frag: int = 0,
    ip_total_len: int | None = None,
    udp_len: int | None = None,
    dst_mac: bytes = b"\x01\x02\x03\x04\x05\x06",
    src_mac: bytes = b"\x0a\x0b\x0c\x0d\x0e\x0f",
    ipv4_checksum: int = 0,
    udp_checksum: int = 0,
    padding: bytes = b"",
) -> bytes:

    if len(dst_mac) != 6 or len(src_mac) != 6:
        raise ValueError("source and destination MAC addresses must be 6 bytes")
    if not 0 <= ip_version <= 0xF:
        raise ValueError("ip_version must fit in four bits")
    if not 0 <= ip_ihl <= 0xF:
        raise ValueError("ip_ihl must fit in four bits")

    frame = bytearray(
        build_eth_ipv4_udp_frame(
            payload,
            ethertype=ethertype,
            ip_protocol=ip_protocol,
            ip_flags_frag=ip_flags_frag,
            src_port=5000,
            dst_port=dst_port,
        )
    )

    frame[0:6] = dst_mac
    frame[6:12] = src_mac
    frame[14] = (ip_version << 4) | ip_ihl
    _set_u16(frame, 24, ipv4_checksum)
    _set_u16(frame, 40, udp_checksum)

    if ip_total_len is not None:
        _set_u16(frame, 16, ip_total_len)
    if udp_len is not None:
        _set_u16(frame, 38, udp_len)

    frame.extend(padding)
    return bytes(frame)


def _valid_payload(length: int, *, salt: int = 0) -> bytes:
    return bytes(((index + salt) & 0xFF) for index in range(length))


def _keep_from_count(valid_bytes: int, word_bytes: int) -> int:
    if not 1 <= valid_bytes <= word_bytes:
        raise ValueError(
            f"valid_bytes must be in 1..{word_bytes}, got {valid_bytes}"
        )
    return ((1 << valid_bytes) - 1) << (word_bytes - valid_bytes)


def _legal_final_keeps(word_bytes: int) -> set[int]:
    return {
        _keep_from_count(valid_bytes, word_bytes)
        for valid_bytes in range(1, word_bytes + 1)
    }


def _bytes_from_beat(data: int, keep: int, word_bytes: int) -> bytes:
    result = bytearray()

    for lane in range(word_bytes):
        keep_bit = word_bytes - 1 - lane
        if keep & (1 << keep_bit):
            shift = 8 * (word_bytes - 1 - lane)
            result.append((data >> shift) & 0xFF)

    return bytes(result)


async def _initialise(dut: Any) -> PortConfig:
    """Start the configured clock and reset frame_crack"""

    await start_perf_clock(dut)

    dut.s_axis_tdata_i.value = 0
    dut.s_axis_tkeep_i.value = 0
    dut.s_axis_tvalid_i.value = 0
    dut.s_axis_tlast_i.value = 0
    dut.m_axis_tready_i.value = 1

    await reset_dut(dut, cycles=RESET_CYCLES)
    await ReadOnly()

    return _port_config(dut)


async def _reset_idle(dut: Any) -> None:
    """reset & guarantee that neither endpoint presents a transaction"""

    await FallingEdge(dut.clk)
    dut.s_axis_tdata_i.value = 0
    dut.s_axis_tkeep_i.value = 0
    dut.s_axis_tvalid_i.value = 0
    dut.s_axis_tlast_i.value = 0
    dut.m_axis_tready_i.value = 1

    await reset_dut(dut, cycles=RESET_CYCLES)
    await ReadOnly()


async def _drive_beats(
    dut: Any,
    beats: list[tuple[int, int, bool]],
    *,
    bubble_cycles: Callable[[int], int] | None = None,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> None:
    """drive s_axis_* beats with unambiguous ready/valid timing."""

    if not beats:
        return

    await FallingEdge(dut.clk)

    for beat_index, (word, keep, last) in enumerate(beats):
        bubble_count = 0 if bubble_cycles is None else bubble_cycles(beat_index)
        if bubble_count < 0:
            raise ValueError("bubble_cycles must not return a negative value")

        for _ in range(bubble_count):
            dut.s_axis_tdata_i.value = 0
            dut.s_axis_tkeep_i.value = 0
            dut.s_axis_tvalid_i.value = 0
            dut.s_axis_tlast_i.value = 0

            await RisingEdge(dut.clk)
            await FallingEdge(dut.clk)

        dut.s_axis_tdata_i.value = word
        dut.s_axis_tkeep_i.value = keep
        dut.s_axis_tvalid_i.value = 1
        dut.s_axis_tlast_i.value = int(last)

        accepted = False
        for _ in range(timeout_cycles):
            await ReadOnly()
            ready_before_edge = signal_value_to_int(dut.s_axis_tready_o.value)

            await RisingEdge(dut.clk)

            if ready_before_edge == 1:
                accepted = True
                break

            await FallingEdge(dut.clk)

        if not accepted:
            raise TimeoutError(
                "timed out waiting for s_axis_tready_o; "
                f"beat_index={beat_index} keep=0x{keep:x} last={int(last)}"
            )

        await FallingEdge(dut.clk)

    dut.s_axis_tdata_i.value = 0
    dut.s_axis_tkeep_i.value = 0
    dut.s_axis_tvalid_i.value = 0
    dut.s_axis_tlast_i.value = 0


async def _drive_packets(
    dut: Any,
    frames: list[bytes],
    *,
    bubble_cycles: Callable[[int], int] | None = None,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> None:
    """drive multiple b2b frames"""

    word_bytes = axis_word_bytes(
        dut.s_axis_tdata_i,
        dut.s_axis_tkeep_i,
        interface_name="frame_crack input",
    )

    beats: list[tuple[int, int, bool]] = []
    for frame in frames:
        beats.extend(axis_bytes_to_words(frame, word_bytes=word_bytes))

    await _drive_beats(
        dut,
        beats,
        bubble_cycles=bubble_cycles,
        timeout_cycles=timeout_cycles,
    )


class FrameCrackMonitor:
    """output/status monitor with ready/valid stability checking."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.word_bytes = axis_word_bytes(
            dut.m_axis_tdata_o,
            dut.m_axis_tkeep_o,
            interface_name="frame_crack output",
        )

        self.running = True
        self.cycle = 0
        self.failure: Exception | None = None

        self.datagrams: list[CapturedDatagram] = []
        self.drops: list[DropEvent] = []
        self.accepted_beats: list[CapturedBeat] = []

        self._current_payload = bytearray()
        self._current_beats: list[CapturedBeat] = []
        self._current_len: int | None = None
        self._held_snapshot: tuple[int, int, int, int, int, int] | None = None

    def _abort_active_packet(self) -> bytes:
        aborted = bytes(self._current_payload)
        self._current_payload.clear()
        self._current_beats.clear()
        self._current_len = None
        self._held_snapshot = None
        return aborted

    def _check_failure(self) -> None:
        if self.failure is not None:
            raise self.failure

    async def run(self) -> None:
        try:
            while self.running:
                await FallingEdge(self.dut.clk)
                await ReadOnly()

                if signal_value_to_int(self.dut.rst_n.value) == 0:
                    self._abort_active_packet()
                    await RisingEdge(self.dut.clk)
                    self.cycle += 1
                    continue

                drop = signal_value_to_int(self.dut.frame_drop_o.value)
                error = signal_value_to_int(self.dut.frame_err_o.value)

                if drop:
                    aborted = self._abort_active_packet()
                    self.drops.append(
                        DropEvent(
                            cycle=self.cycle,
                            error=error,
                            aborted_payload=aborted,
                        )
                    )
                elif error != 0:
                    raise AssertionError(
                        "frame_err_o was non-zero without frame_drop_o: "
                        f"cycle={self.cycle} err=0x{error:x}"
                    )

                valid = signal_value_to_int(self.dut.m_axis_tvalid_o.value)
                ready = signal_value_to_int(self.dut.m_axis_tready_i.value)
                data = signal_value_to_int(self.dut.m_axis_tdata_o.value)
                keep = signal_value_to_int(self.dut.m_axis_tkeep_o.value)
                last = signal_value_to_int(self.dut.m_axis_tlast_o.value)
                start = signal_value_to_int(self.dut.m_dgram_start_o.value)
                dgram_len = signal_value_to_int(self.dut.m_dgram_len_o.value)

                snapshot = (valid, data, keep, last, start, dgram_len)

                if start and not valid:
                    raise AssertionError(
                        "m_dgram_start_o asserted without m_axis_tvalid_o"
                    )

                if valid and not ready:
                    input_ready = signal_value_to_int(
                        self.dut.s_axis_tready_o.value
                    )
                    if input_ready != 0:
                        raise AssertionError(
                            "s_axis_tready_o stayed high while an output beat "
                            "was backpressured"
                        )

                    if (
                        self._held_snapshot is not None
                        and snapshot != self._held_snapshot
                    ):
                        raise AssertionError(
                            "output transaction changed while valid=1 and ready=0: "
                            f"previous={self._held_snapshot} current={snapshot}"
                        )

                    self._held_snapshot = snapshot

                elif valid and ready:
                    if (
                        self._held_snapshot is not None
                        and snapshot != self._held_snapshot
                    ):
                        raise AssertionError(
                            "backpressured output changed on its acceptance cycle: "
                            f"held={self._held_snapshot} accepted={snapshot}"
                        )
                    self._held_snapshot = None

                    beat = CapturedBeat(
                        cycle=self.cycle,
                        data=data,
                        keep=keep,
                        last=last,
                        start=start,
                        dgram_len=dgram_len,
                    )
                    self.accepted_beats.append(beat)

                    if start:
                        if self._current_beats:
                            raise AssertionError(
                                "new datagram started before the previous "
                                "datagram completed or was dropped"
                            )
                        self._current_len = dgram_len
                    elif not self._current_beats:
                        raise AssertionError(
                            "first accepted output beat did not assert "
                            "m_dgram_start_o"
                        )

                    self._current_beats.append(beat)
                    self._current_payload.extend(
                        _bytes_from_beat(data, keep, self.word_bytes)
                    )

                    if last:
                        if self._current_len is None:
                            raise AssertionError(
                                "output tlast observed without datagram metadata"
                            )

                        self.datagrams.append(
                            CapturedDatagram(
                                payload=bytes(self._current_payload),
                                dgram_len=self._current_len,
                                beats=tuple(self._current_beats),
                            )
                        )
                        self._current_payload.clear()
                        self._current_beats.clear()
                        self._current_len = None

                elif self._held_snapshot is not None:
                    raise AssertionError(
                        "m_axis_tvalid_o deasserted before a held transaction "
                        "was accepted"
                    )

                await RisingEdge(self.dut.clk)
                self.cycle += 1

        except Exception as exc:
            self.failure = exc

    async def wait_for_datagrams(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            self._check_failure()
            if len(self.datagrams) >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        self._check_failure()
        raise TimeoutError(
            f"timed out waiting for {expected_count} datagram(s); "
            f"got {len(self.datagrams)}"
        )

    async def wait_for_drops(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            self._check_failure()
            if len(self.drops) >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        self._check_failure()
        raise TimeoutError(
            f"timed out waiting for {expected_count} frame drop(s); "
            f"got {len(self.drops)}"
        )

    def assert_clean(self) -> None:
        self._check_failure()


def _assert_datagram(
    observed: CapturedDatagram,
    expected_payload: bytes,
    *,
    context: str,
    word_bytes: int,
) -> None:
    assert observed.payload == expected_payload, (
        f"{context}: payload mismatch\n"
        f"expected={expected_payload.hex()}\n"
        f"observed={observed.payload.hex()}"
    )
    assert observed.dgram_len == len(expected_payload), (
        f"{context}: m_dgram_len_o expected {len(expected_payload)}, "
        f"got {observed.dgram_len}"
    )
    assert observed.beats, f"{context}: non-empty datagram produced no beats"
    assert observed.beats[0].start == 1, (
        f"{context}: first accepted output beat did not assert dgram_start"
    )
    assert sum(beat.start for beat in observed.beats) == 1, (
        f"{context}: expected exactly one dgram_start pulse"
    )
    assert observed.beats[-1].last == 1, (
        f"{context}: final accepted output beat did not assert tlast"
    )
    assert sum(beat.last for beat in observed.beats) == 1, (
        f"{context}: expected exactly one accepted tlast"
    )

    final_valid = len(expected_payload) % word_bytes
    if final_valid == 0:
        final_valid = word_bytes
    expected_keep = _keep_from_count(final_valid, word_bytes)
    assert observed.beats[-1].keep == expected_keep, (
        f"{context}: final tkeep expected 0x{expected_keep:x}, "
        f"got 0x{observed.beats[-1].keep:x}"
    )


def _assert_single_drop(
    drop: DropEvent,
    expected_error: int,
    *,
    context: str,
    exact: bool = True,
) -> None:
    if exact:
        assert drop.error == expected_error, (
            f"{context}: error mask expected 0x{expected_error:04x}, "
            f"got 0x{drop.error:04x}"
        )
    else:
        assert (drop.error & expected_error) == expected_error, (
            f"{context}: expected error bits 0x{expected_error:04x}, "
            f"got 0x{drop.error:04x}"
        )


async def _prove_no_new_activity(
    dut: Any,
    monitor: FrameCrackMonitor,
    *,
    datagrams: int,
    drops: int,
    cycles: int = 6,
) -> None:
    """Use a fixed interval only to prove that no transaction appears."""

    for _ in range(cycles):
        await RisingEdge(dut.clk)
        monitor.assert_clean()

    assert len(monitor.datagrams) == datagrams
    assert len(monitor.drops) == drops


async def _stop_monitor(
    monitor: FrameCrackMonitor,
    task: Any,
) -> None:
    monitor.assert_clean()
    monitor.running = False
    task.cancel()


async def _stall_next_matching_output(
    dut: Any,
    monitor: FrameCrackMonitor,
    *,
    predicate: Callable[[int, int], bool],
    stall_cycles: int,
    timeout_cycles: int = TIMEOUT_CYCLES,
) -> None:
    """stall the next output beat matching predicate(last, accepted_count)"""

    for _ in range(timeout_cycles):
        await FallingEdge(dut.clk)

        valid = signal_value_to_int(dut.m_axis_tvalid_o.value)
        last = signal_value_to_int(dut.m_axis_tlast_o.value)

        if valid and predicate(last, len(monitor.accepted_beats)):
            dut.m_axis_tready_i.value = 0

            for _ in range(stall_cycles):
                await RisingEdge(dut.clk)
                await FallingEdge(dut.clk)

            dut.m_axis_tready_i.value = 1
            return

    raise TimeoutError("timed out waiting for the requested output stall point")


async def _periodic_ready_driver(
    dut: Any,
    control: dict[str, bool],
    *,
    period: int = 7,
    stalled_phases: tuple[int, ...] = (2, 3),
) -> None:
    cycle = 0

    while control["running"]:
        await FallingEdge(dut.clk)
        dut.m_axis_tready_i.value = int(
            (cycle % period) not in stalled_phases
        )
        cycle += 1

    await FallingEdge(dut.clk)
    dut.m_axis_tready_i.value = 1


@cocotb.test()
async def test_frame_crack_extracts_udp_payload_and_metadata(dut: Any) -> None:
    """check that a valid frame emits only UDP payload bytes inorder."""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    payload = bytes(range(32))
    frame = _build_frame(
        payload,
        dst_port=port.expected_port,
        dst_mac=b"\xda\x02\x03\x04\x05\x06",
        src_mac=b"\x5a\x07\x08\x09\x0a\x0b",
        ipv4_checksum=0xA5A5,
        udp_checksum=0x5A5A,
    )

    await _drive_packets(dut, [frame])
    await monitor.wait_for_datagrams(1)

    _assert_datagram(
        monitor.datagrams[0],
        payload,
        context="basic valid frame",
        word_bytes=monitor.word_bytes,
    )
    assert monitor.drops == []

    # distinctive L2/L3/L4 bytes must not leak into the payload
    assert monitor.datagrams[0].payload == frame[FIXED_HEADER_BYTES : FIXED_HEADER_BYTES + len(payload)]

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_payload_length_sweep(dut: Any) -> None:
    """lengths 0 to 31 cover zero payload and every final alignment repeatedly"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    observed_input_final_keeps: set[int] = set()

    for payload_len in range(32):
        payload = _valid_payload(payload_len, salt=payload_len)
        frame = _build_frame(payload, dst_port=port.expected_port)

        input_beats = axis_bytes_to_words(
            frame,
            word_bytes=axis_word_bytes(
                dut.s_axis_tdata_i,
                dut.s_axis_tkeep_i,
            ),
        )
        observed_input_final_keeps.add(input_beats[-1][1])

        datagrams_before = len(monitor.datagrams)
        drops_before = len(monitor.drops)

        await _drive_packets(dut, [frame])

        if payload_len == 0:
            await _prove_no_new_activity(
                dut,
                monitor,
                datagrams=datagrams_before,
                drops=drops_before,
            )
            continue

        await monitor.wait_for_datagrams(datagrams_before + 1)
        _assert_datagram(
            monitor.datagrams[-1],
            payload,
            context=f"payload_len={payload_len}",
            word_bytes=monitor.word_bytes,
        )
        assert len(monitor.drops) == drops_before

    assert observed_input_final_keeps == _legal_final_keeps(
        axis_word_bytes(dut.s_axis_tdata_i, dut.s_axis_tkeep_i)
    )
    assert monitor.drops == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_long_payload_padding_mac_and_checksums(dut: Any) -> None:
    """long traffic remains exact and unimportant fields are ignored"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    long_payload = bytes((index * 37 + 11) & 0xFF for index in range(1472))
    await _drive_packets(
        dut,
        [
            _build_frame(
                long_payload,
                dst_port=port.expected_port,
                dst_mac=b"\xff\xee\xdd\xcc\xbb\xaa",
                src_mac=b"\x10\x20\x30\x40\x50\x60",
                ipv4_checksum=0x1234,
                udp_checksum=0xBEEF,
            )
        ],
    )
    await monitor.wait_for_datagrams(1)
    _assert_datagram(
        monitor.datagrams[0],
        long_payload,
        context="1472-byte payload",
        word_bytes=monitor.word_bytes,
    )

    padded_payload = b"\x01\x23\x45\x67\x89\xab\xcd"
    padding = bytes((0xE0 + index) & 0xFF for index in range(37))

    await _drive_packets(
        dut,
        [
            _build_frame(
                padded_payload,
                dst_port=port.expected_port,
                dst_mac=b"\x00\x11\x22\x33\x44\x55",
                src_mac=b"\xaa\xbb\xcc\xdd\xee\xff",
                ipv4_checksum=0xCAFE,
                udp_checksum=0xFACE,
                padding=padding,
            )
        ],
    )
    await monitor.wait_for_datagrams(2)

    _assert_datagram(
        monitor.datagrams[1],
        padded_payload,
        context="padded frame",
        word_bytes=monitor.word_bytes,
    )
    assert padding not in monitor.datagrams[1].payload
    assert monitor.drops == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_exhaustive_tkeep_classification(dut: Any) -> None:
    """check tkeep properly dealt with"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    word_bytes = axis_word_bytes(
        dut.s_axis_tdata_i,
        dut.s_axis_tkeep_i,
        interface_name="frame_crack input",
    )
    if word_bytes > 8:
        raise AssertionError(
            "exhaustive tkeep classification is intentionally bounded to "
            f"<=8 byte lanes, got {word_bytes}"
        )

    legal_final = _legal_final_keeps(word_bytes)
    all_masks = set(range(1 << word_bytes))

    # Prove every legal final mask using a frame whose byte count is consistent with that mask
    for valid_count in range(1, word_bytes + 1):
        payload_len = next(
            length
            for length in range(word_bytes * 2)
            if ((FIXED_HEADER_BYTES + length - 1) % word_bytes) + 1
            == valid_count
        )
        payload = _valid_payload(payload_len, salt=valid_count)
        frame = _build_frame(payload, dst_port=port.expected_port)
        beats = axis_bytes_to_words(frame, word_bytes=word_bytes)

        assert beats[-1][1] == _keep_from_count(valid_count, word_bytes)

        datagrams_before = len(monitor.datagrams)
        drops_before = len(monitor.drops)

        await _drive_beats(dut, beats)

        if payload_len == 0:
            await _prove_no_new_activity(
                dut,
                monitor,
                datagrams=datagrams_before,
                drops=drops_before,
            )
        else:
            await monitor.wait_for_datagrams(datagrams_before + 1)
            _assert_datagram(
                monitor.datagrams[-1],
                payload,
                context=f"legal final tkeep 0x{beats[-1][1]:x}",
                word_bytes=monitor.word_bytes,
            )
            assert len(monitor.drops) == drops_before

    # Use a zero-payload frame so no payload can legitimately escape before a malformed final beat is detected
    zero_frame = _build_frame(b"", dst_port=port.expected_port)
    zero_beats = axis_bytes_to_words(zero_frame, word_bytes=word_bytes)

    for keep in sorted(all_masks - legal_final):
        corrupted = list(zero_beats)
        word, _, last = corrupted[-1]
        corrupted[-1] = (word, keep, last)

        datagrams_before = len(monitor.datagrams)
        drops_before = len(monitor.drops)

        await _drive_beats(dut, corrupted)
        await monitor.wait_for_drops(drops_before + 1)

        _assert_single_drop(
            monitor.drops[-1],
            1 << FRAME_ERR_BAD_TKEEP,
            context=f"illegal final tkeep 0x{keep:x}",
        )
        assert len(monitor.datagrams) == datagrams_before

    full_keep = (1 << word_bytes) - 1
    for keep in sorted(all_masks - {full_keep}):
        corrupted = list(zero_beats)
        first_word, _, _ = corrupted[0]
        corrupted[0] = (first_word, keep, False)

        datagrams_before = len(monitor.datagrams)
        drops_before = len(monitor.drops)

        await _drive_beats(dut, corrupted)
        await monitor.wait_for_drops(drops_before + 1)

        _assert_single_drop(
            monitor.drops[-1],
            1 << FRAME_ERR_BAD_TKEEP,
            context=f"illegal non-final tkeep 0x{keep:x}",
        )
        assert len(monitor.datagrams) == datagrams_before

    # recovery after the rejection campaign
    recovery = b"tkeep recovery"
    recovery_target = len(monitor.datagrams) + 1
    await _drive_packets(
        dut,
        [_build_frame(recovery, dst_port=port.expected_port)],
    )
    await monitor.wait_for_datagrams(recovery_target)
    _assert_datagram(
        monitor.datagrams[-1],
        recovery,
        context="post-tkeep recovery",
        word_bytes=monitor.word_bytes,
    )

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_rejects_defined_header_errors(dut: Any) -> None:
    """every single-fault header rejection path correctly reports its error bit"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    payload = b"header-check"

    cases = [
        (
            "bad ethertype",
            _build_frame(
                payload,
                dst_port=port.expected_port,
                ethertype=0x86DD,
            ),
            1 << FRAME_ERR_BAD_ETHERTYPE,
        ),
        (
            "bad IP version",
            _build_frame(
                payload,
                dst_port=port.expected_port,
                ip_version=6,
            ),
            1 << FRAME_ERR_BAD_IP_VER,
        ),
        (
            "bad IHL",
            _build_frame(
                payload,
                dst_port=port.expected_port,
                ip_ihl=6,
            ),
            1 << FRAME_ERR_BAD_IHL,
        ),
        (
            "more fragments",
            _build_frame(
                payload,
                dst_port=port.expected_port,
                ip_flags_frag=0x2000,
            ),
            1 << FRAME_ERR_FRAGMENT,
        ),
        (
            "non-zero fragment offset",
            _build_frame(
                payload,
                dst_port=port.expected_port,
                ip_flags_frag=0x0001,
            ),
            1 << FRAME_ERR_FRAGMENT,
        ),
        (
            "bad transport protocol",
            _build_frame(
                payload,
                dst_port=port.expected_port,
                ip_protocol=6,
            ),
            1 << FRAME_ERR_BAD_PROTO,
        ),
        (
            "UDP length below header size",
            _build_frame(
                payload,
                dst_port=port.expected_port,
                udp_len=7,
            ),
            1 << FRAME_ERR_BAD_UDP_LEN,
        ),
        (
            "IP total length below IPv4 plus UDP headers",
            _build_frame(
                payload,
                dst_port=port.expected_port,
                ip_total_len=27,
            ),
            1 << FRAME_ERR_BAD_UDP_LEN,
        ),
        (
            "UDP length exceeds IP payload",
            _build_frame(
                payload,
                dst_port=port.expected_port,
                ip_total_len=32,
                udp_len=20,
            ),
            1 << FRAME_ERR_BAD_UDP_LEN,
        ),
    ]

    for case_name, frame, expected_error in cases:
        datagrams_before = len(monitor.datagrams)
        drops_before = len(monitor.drops)

        await _drive_packets(dut, [frame])
        await monitor.wait_for_drops(drops_before + 1)

        assert len(monitor.drops) == drops_before + 1, (
            f"{case_name}: expected exactly one frame_drop pulse"
        )
        _assert_single_drop(
            monitor.drops[-1],
            expected_error,
            context=case_name,
        )
        assert len(monitor.datagrams) == datagrams_before, (
            f"{case_name}: rejected header leaked a payload"
        )

    # only MF/non-zero fragment offset are rejected
    legal_df_payload = b"DF is legal"
    await _drive_packets(
        dut,
        [
            _build_frame(
                legal_df_payload,
                dst_port=port.expected_port,
                ip_flags_frag=0x4000,
            )
        ],
    )
    await monitor.wait_for_datagrams(1)
    _assert_datagram(
        monitor.datagrams[-1],
        legal_df_payload,
        context="legal DF flag",
        word_bytes=monitor.word_bytes,
    )

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_error_bitmask_accumulates_header_faults(
    dut: Any,
) -> None:
    """check that multiple errors actually show up in the bitmask"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    wrong_port = (port.expected_port + 1) & 0xFFFF

    frame = _build_frame(
        b"multi-error",
        dst_port=wrong_port,
        ethertype=0x86DD,
        ip_version=6,
        ip_ihl=6,
        ip_protocol=6,
        ip_flags_frag=0x2001,
        ip_total_len=27,
        udp_len=7,
    )

    await _drive_packets(dut, [frame])
    await monitor.wait_for_drops(1)

    expected = (
        (1 << FRAME_ERR_BAD_ETHERTYPE)
        | (1 << FRAME_ERR_BAD_IP_VER)
        | (1 << FRAME_ERR_BAD_IHL)
        | (1 << FRAME_ERR_FRAGMENT)
        | (1 << FRAME_ERR_BAD_PROTO)
        | (1 << FRAME_ERR_BAD_UDP_LEN)
    )
    if port.check_enabled:
        expected |= 1 << FRAME_ERR_BAD_UDP_PORT

    _assert_single_drop(
        monitor.drops[0],
        expected,
        context="combined header errors",
    )
    assert monitor.datagrams == []

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_destination_port_parameter_contract(dut: Any) -> None:
    """exercise the active CHECK_DST_PORT elaboration parameter and confirm that the DUT behaves accordingly"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    matching_payload = b"matching port"
    await _drive_packets(
        dut,
        [_build_frame(matching_payload, dst_port=port.expected_port)],
    )
    await monitor.wait_for_datagrams(1)
    _assert_datagram(
        monitor.datagrams[-1],
        matching_payload,
        context="matching destination port",
        word_bytes=monitor.word_bytes,
    )

    mismatch_port = (port.expected_port + 1) & 0xFFFF
    mismatch_payload = b"mismatch port"
    datagrams_before = len(monitor.datagrams)
    drops_before = len(monitor.drops)

    await _drive_packets(
        dut,
        [_build_frame(mismatch_payload, dst_port=mismatch_port)],
    )

    if port.check_enabled:
        await monitor.wait_for_drops(drops_before + 1)
        _assert_single_drop(
            monitor.drops[-1],
            1 << FRAME_ERR_BAD_UDP_PORT,
            context="destination-port check enabled",
        )
        assert len(monitor.datagrams) == datagrams_before
    else:
        await monitor.wait_for_datagrams(datagrams_before + 1)
        _assert_datagram(
            monitor.datagrams[-1],
            mismatch_payload,
            context="destination-port check disabled",
            word_bytes=monitor.word_bytes,
        )
        assert len(monitor.drops) == drops_before

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_runt_and_truncation_recovery(dut: Any) -> None:
    """check runt frames report faults and the next complete frame still succeeds"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    declared_payload = bytes((0x80 + index) & 0xFF for index in range(48))
    full_frame = _build_frame(
        declared_payload,
        dst_port=port.expected_port,
    )

    # These cuts are for early header, UDP-length/checksum, first-payload and later-payload truncation points
    cut_lengths = (10, 34, 39, 41, 45, 61)

    for cut_length in cut_lengths:
        datagrams_before = len(monitor.datagrams)
        drops_before = len(monitor.drops)

        await _drive_packets(dut, [full_frame[:cut_length]])
        await monitor.wait_for_drops(drops_before + 1)

        drop = monitor.drops[-1]
        _assert_single_drop(
            drop,
            1 << FRAME_ERR_RUNT_FRAME,
            context=f"truncated frame at byte {cut_length}",
            exact=False,
        )
        assert len(monitor.datagrams) == datagrams_before

        # Late detection may occur after an earlier payload prefix has already streamed
        # Any such bytes must be the exact leading payload bytes
        assert declared_payload.startswith(drop.aborted_payload), (
            f"cut={cut_length}: escaped bytes were not a payload prefix; "
            f"escaped={drop.aborted_payload.hex()}"
        )

        recovery_payload = f"recovery-{cut_length}".encode("ascii")
        await _drive_packets(
            dut,
            [
                _build_frame(
                    recovery_payload,
                    dst_port=port.expected_port,
                )
            ],
        )
        await monitor.wait_for_datagrams(datagrams_before + 1)
        _assert_datagram(
            monitor.datagrams[-1],
            recovery_payload,
            context=f"recovery after truncation at {cut_length}",
            word_bytes=monitor.word_bytes,
        )

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_holds_output_stable_under_backpressure(
    dut: Any,
) -> None:
    """stall first, middle and final output beats and preserve the packet"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    cases = [
        (
            "first output beat",
            lambda last, accepted: accepted == 0,
        ),
        (
            "middle output beat",
            lambda last, accepted: accepted >= 1 and last == 0,
        ),
        (
            "final output beat",
            lambda last, accepted: last == 1,
        ),
    ]

    for case_index, (case_name, predicate) in enumerate(cases):
        payload = bytes(
            (case_index * 53 + index) & 0xFF
            for index in range(40)
        )
        frame = _build_frame(payload, dst_port=port.expected_port)

        datagrams_before = len(monitor.datagrams)
        accepted_before = len(monitor.accepted_beats)

        stall_task = cocotb.start_soon(
            _stall_next_matching_output(
                dut,
                monitor,
                predicate=lambda last, accepted, base=accepted_before, p=predicate: p(
                    last,
                    accepted - base,
                ),
                stall_cycles=4,
            )
        )

        await _drive_packets(dut, [frame])
        await monitor.wait_for_datagrams(datagrams_before + 1)
        await stall_task

        _assert_datagram(
            monitor.datagrams[-1],
            payload,
            context=case_name,
            word_bytes=monitor.word_bytes,
        )

    assert monitor.drops == []
    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_periodic_backpressure_and_source_bubbles(
    dut: Any,
) -> None:
    """sink stalls and legal source bubbles mustn't change semantic output"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    control = {"running": True}
    ready_task = cocotb.start_soon(
        _periodic_ready_driver(
            dut,
            control,
            period=7,
            stalled_phases=(2, 3),
        )
    )

    payloads = [
        bytes((0x10 + index) & 0xFF for index in range(9)),
        bytes((0x40 + index) & 0xFF for index in range(37)),
        bytes((0x80 + index) & 0xFF for index in range(73)),
    ]
    frames = [
        _build_frame(payload, dst_port=port.expected_port)
        for payload in payloads
    ]

    def source_bubbles(beat_index: int) -> int:
        if beat_index % 11 == 3:
            return 1
        if beat_index % 17 == 5:
            return 2
        return 0

    await _drive_packets(
        dut,
        frames,
        bubble_cycles=source_bubbles,
    )
    await monitor.wait_for_datagrams(len(payloads))

    control["running"] = False
    await ready_task

    for index, payload in enumerate(payloads):
        _assert_datagram(
            monitor.datagrams[index],
            payload,
            context=f"bubble/backpressure frame {index}",
            word_bytes=monitor.word_bytes,
        )

    assert monitor.drops == []
    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_consecutive_frames_and_recovery(dut: Any) -> None:
    """b2b valid/rejected/padded traffic cannot leak state"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    payload_a = b"A"
    payload_b = bytes(range(80))
    payload_c = b"padded"
    payload_d = b"final"

    frames = [
        _build_frame(payload_a, dst_port=port.expected_port),
        _build_frame(payload_b, dst_port=port.expected_port),
        _build_frame(
            b"must be rejected",
            dst_port=port.expected_port,
            ethertype=0x86DD,
        ),
        _build_frame(
            payload_c,
            dst_port=port.expected_port,
            padding=b"\xee" * 31,
        ),
        _build_frame(payload_d, dst_port=port.expected_port),
    ]

    await _drive_packets(dut, frames)
    await monitor.wait_for_datagrams(4)
    await monitor.wait_for_drops(1)

    expected_payloads = [payload_a, payload_b, payload_c, payload_d]
    for index, payload in enumerate(expected_payloads):
        _assert_datagram(
            monitor.datagrams[index],
            payload,
            context=f"consecutive frame {index}",
            word_bytes=monitor.word_bytes,
        )

    _assert_single_drop(
        monitor.drops[0],
        1 << FRAME_ERR_BAD_ETHERTYPE,
        context="rejected frame between valid frames",
    )

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_reset_recovery_from_meaningful_states(
    dut: Any,
) -> None:
    """check reset behaviour in edge cases"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    word_bytes = axis_word_bytes(
        dut.s_axis_tdata_i,
        dut.s_axis_tkeep_i,
    )
    long_payload = bytes((index * 9 + 3) & 0xFF for index in range(96))
    long_frame = _build_frame(
        long_payload,
        dst_port=port.expected_port,
    )
    long_beats = axis_bytes_to_words(long_frame, word_bytes=word_bytes)

    async def assert_reset_outputs_clear(context: str) -> None:
        # _reset_idle() already returns in cocotb's ReadOnly phase, so sample
        # directly here rather than attempting a second ReadOnly transition
        assert signal_value_to_int(dut.m_axis_tvalid_o.value) == 0, context
        assert signal_value_to_int(dut.m_dgram_start_o.value) == 0, context
        assert signal_value_to_int(dut.frame_drop_o.value) == 0, context
        assert signal_value_to_int(dut.frame_err_o.value) == 0, context

    async def prove_recovery(tag: str) -> None:
        payload = f"reset-{tag}".encode("ascii")
        target = len(monitor.datagrams) + 1
        await _drive_packets(
            dut,
            [_build_frame(payload, dst_port=port.expected_port)],
        )
        await monitor.wait_for_datagrams(target)
        _assert_datagram(
            monitor.datagrams[-1],
            payload,
            context=f"reset recovery {tag}",
            word_bytes=monitor.word_bytes,
        )

    # reset during header reception
    await _drive_beats(dut, long_beats[:2])
    await _reset_idle(dut)
    await assert_reset_outputs_clear("reset during header")
    await prove_recovery("header")

    # reset after the first payload-containing input beat has been accepted
    await _drive_beats(dut, long_beats[:6])
    await _reset_idle(dut)
    await assert_reset_outputs_clear("reset during payload")
    await prove_recovery("payload")

    # reset while an output transaction is held by sink backpressure
    dut.m_axis_tready_i.value = 0
    driver_task = cocotb.start_soon(_drive_packets(dut, [long_frame]))

    saw_valid = False
    for _ in range(TIMEOUT_CYCLES):
        await FallingEdge(dut.clk)
        if signal_value_to_int(dut.m_axis_tvalid_o.value) == 1:
            saw_valid = True
            break

    assert saw_valid, "timed out waiting for backpressured output before reset"

    driver_task.cancel()
    await FallingEdge(dut.clk)
    dut.s_axis_tdata_i.value = 0
    dut.s_axis_tkeep_i.value = 0
    dut.s_axis_tvalid_i.value = 0
    dut.s_axis_tlast_i.value = 0

    await _reset_idle(dut)
    await assert_reset_outputs_clear("reset during output backpressure")
    await prove_recovery("backpressure")

    # enter drain with an early-rejected frame, then reset before Ethernet tlast
    bad_frame = _build_frame(
        long_payload,
        dst_port=port.expected_port,
        ethertype=0x86DD,
    )
    bad_beats = axis_bytes_to_words(bad_frame, word_bytes=word_bytes)
    drops_before = len(monitor.drops)

    # header validation occurs before the payload stream
    await _drive_beats(dut, bad_beats[:5])
    await monitor.wait_for_drops(drops_before + 1)
    await _reset_idle(dut)
    await assert_reset_outputs_clear("reset while draining a rejected frame")
    await prove_recovery("drain")

    await _stop_monitor(monitor, monitor_task)


@cocotb.test()
async def test_frame_crack_deterministic_random_valid_frames(dut: Any) -> None:
    """random valid traffic testing"""

    port = await _initialise(dut)
    monitor = FrameCrackMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    cocotb.log.info("frame_crack deterministic TEST_SEED=%d", TEST_SEED)
    rng = random.Random(TEST_SEED)

    frames: list[bytes] = []
    expected_payloads: list[bytes] = []

    for frame_index in range(40):
        payload_len = rng.randrange(0, 257)
        payload = bytes(rng.randrange(256) for _ in range(payload_len))
        padding_len = rng.randrange(0, 33)

        dst_mac = bytes(rng.randrange(256) for _ in range(6))
        src_mac = bytes(rng.randrange(256) for _ in range(6))

        frames.append(
            _build_frame(
                payload,
                dst_port=port.expected_port,
                dst_mac=dst_mac,
                src_mac=src_mac,
                ipv4_checksum=rng.randrange(1 << 16),
                udp_checksum=rng.randrange(1 << 16),
                padding=bytes(rng.randrange(256) for _ in range(padding_len)),
            )
        )

        if payload:
            expected_payloads.append(payload)

    control = {"running": True}
    ready_task = cocotb.start_soon(
        _periodic_ready_driver(
            dut,
            control,
            period=13,
            stalled_phases=(4, 5, 9),
        )
    )

    def bubbles(beat_index: int) -> int:
        value = (beat_index * 17 + TEST_SEED) % 29
        if value == 0:
            return 2
        if value in (7, 19):
            return 1
        return 0

    await _drive_packets(dut, frames, bubble_cycles=bubbles)
    await monitor.wait_for_datagrams(len(expected_payloads))

    control["running"] = False
    await ready_task

    assert len(monitor.datagrams) == len(expected_payloads)
    for frame_index, (observed, expected) in enumerate(
        zip(monitor.datagrams, expected_payloads)
    ):
        _assert_datagram(
            observed,
            expected,
            context=(
                f"random frame_index={frame_index} seed={TEST_SEED} "
                f"payload_len={len(expected)}"
            ),
            word_bytes=monitor.word_bytes,
        )

    assert monitor.drops == [], (
        f"seed={TEST_SEED}: valid random traffic produced drops "
        f"{monitor.drops}"
    )

    await _stop_monitor(monitor, monitor_task)
