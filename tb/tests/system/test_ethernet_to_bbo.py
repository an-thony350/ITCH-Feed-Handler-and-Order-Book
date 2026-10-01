"""End-to-end cocotb regression from Ethernet frames to BBO output.

DUT path:
    Ethernet AXIS -> ingress -> async FIFO -> symbol router -> pipelined ob -> BBO

The same BinaryFILE stimulus is used to build both sides of the comparison:
- Python parser + OrderBook produce the semantic event/BBO oracle;
- network_encapsulator wraps those bytes in MoldUDP64/UDP/IPv4/Ethernet for RTL.

"""

from __future__ import annotations

import io
import json
import os
from typing import Any

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from golden.itch_parser import parse_itch_stream
from golden.network_encapsulator import encapsulate_bytes
from golden.order_book import OrderBook
from golden.runner import event_to_dict, state_to_dict
from golden.stimulus import (
    add_message,
    cancel_message,
    delete_message,
    encode_binaryfile,
    execute_message,
    replace_message,
    system_event,
)
from golden.contracts import Side
from itch_harness.axis import axis_word_bytes, drive_axis_frame
from itch_harness.perf import clock_mhz_from_env, clock_period_ps_from_mhz
from itch_harness.scoreboard import (
    assert_bbo_matches_word,
    assert_data_t_matches_word,
    signal_value_to_int,
)


TARGET_LOCATE = 1
BASE_PRICE = 9_000
MESSAGES_PER_PACKET = 3
SEQ_START = 100

RESET_CYCLES = 8
TIMEOUT_CYCLES = 200_000
DRAIN_CYCLES = 32

DATA_CLOCK_MHZ_ENV = "DATA_CLOCK_MHZ"
DEFAULT_DATA_CLOCK_MHZ = 250.0


def _data_clock_mhz_from_env() -> float:
    raw_value = os.environ.get(DATA_CLOCK_MHZ_ENV)
    clock_mhz = (
        DEFAULT_DATA_CLOCK_MHZ if raw_value is None else float(raw_value)
    )
    if clock_mhz <= 0:
        raise ValueError(
            f"{DATA_CLOCK_MHZ_ENV} must be positive, got {clock_mhz}"
        )
    return clock_mhz


def _directed_messages() -> tuple[bytes, ...]:
    """Build a legal stream covering every supported wire-level mutation."""

    return (
        system_event(timestamp_ns=90),
        add_message(
            timestamp_ns=100,
            order_ref=1001,
            side=Side.BUY,
            shares=100,
            price=10_000,
        ),
        add_message(
            timestamp_ns=101,
            order_ref=2001,
            side=Side.SELL,
            shares=80,
            price=10_050,
            with_mpid=True,
            attribution=b"TEST",
        ),
        execute_message(
            timestamp_ns=102,
            order_ref=1001,
            shares=25,
            match_number=9001,
        ),
        execute_message(
            timestamp_ns=103,
            order_ref=2001,
            shares=20,
            match_number=9002,
            with_price=True,
            execution_price=10_045,
        ),
        cancel_message(
            timestamp_ns=104,
            order_ref=1001,
            shares=15,
        ),
        replace_message(
            timestamp_ns=105,
            order_ref=2001,
            new_order_ref=2002,
            shares=40,
            price=10_040,
        ),
        delete_message(
            timestamp_ns=106,
            order_ref=1001,
        ),
        delete_message(
            timestamp_ns=107,
            order_ref=2002,
        ),
    )


def _build_golden(
    binaryfile_data: bytes,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Return matched semantic events and post-event BBO states."""

    book = OrderBook(expected_locate=TARGET_LOCATE)
    expected_events: list[dict[str, Any]] = []
    expected_states: list[dict[str, Any]] = []

    for event in parse_itch_stream(binaryfile_data):
        expected_events.append(event_to_dict(event))
        book.apply(event)
        expected_states.append(
            state_to_dict(book.snapshot(msg_index=event.msg_index))
        )

    return expected_events, expected_states


def _encapsulate_frames(binaryfile_data: bytes) -> list[bytes]:
    """Wrap one BinaryFILE stream into individually driveable Ethernet frames."""

    frames_out = io.BytesIO()
    meta_out = io.StringIO()

    stats = encapsulate_bytes(
        binaryfile_data,
        frames_out=frames_out,
        meta_out=meta_out,
        messages_per_packet=MESSAGES_PER_PACKET,
        seq_start=SEQ_START,
    )

    metadata = [
        json.loads(line)
        for line in meta_out.getvalue().splitlines()
        if line.strip()
    ]
    raw_frames = frames_out.getvalue()

    assert len(metadata) == stats.frames_written, (
        "network encapsulator metadata/frame count mismatch: "
        f"metadata={len(metadata)} frames={stats.frames_written}"
    )

    frames: list[bytes] = []
    cursor = 0
    for frame_index, record in enumerate(metadata):
        frame_length = int(record["frame_length"])
        frame_end = cursor + frame_length
        if frame_end > len(raw_frames):
            raise AssertionError(
                f"frame {frame_index} length {frame_length} exceeds "
                "encapsulated byte stream"
            )

        frames.append(raw_frames[cursor:frame_end])
        cursor = frame_end

    assert cursor == len(raw_frames), (
        f"encapsulated frame split left {len(raw_frames) - cursor} trailing bytes"
    )

    return frames


async def _initialise(dut: Any) -> tuple[float, float, int]:
    """Start independent clocks and hold both domains in reset."""

    network_clock_mhz = clock_mhz_from_env(default=156.25)
    data_clock_mhz = _data_clock_mhz_from_env()

    network_period_ps = clock_period_ps_from_mhz(network_clock_mhz)
    data_period_ps = clock_period_ps_from_mhz(data_clock_mhz)

    dut.rst_n.value = 0

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0

    dut.base_price_stock0_i.value = BASE_PRICE
    dut.base_price_stock1_i.value = BASE_PRICE
    dut.base_price_stock2_i.value = BASE_PRICE

    cocotb.start_soon(
        Clock(dut.clk, network_period_ps, unit="ps").start()
    )
    cocotb.start_soon(
        Clock(dut.data_clk, data_period_ps, unit="ps").start()
    )

    for _ in range(RESET_CYCLES):
        await RisingEdge(dut.clk)
    for _ in range(RESET_CYCLES):
        await RisingEdge(dut.data_clk)

    await FallingEdge(dut.clk)
    dut.rst_n.value = 1

    # Let the event FIFO pointers and order-book reset pipeline settle before
    # presenting the first Ethernet frame. This is reset settling, not latency
    # checking for a functional transaction.
    for _ in range(4):
        await RisingEdge(dut.data_clk)
    for _ in range(2):
        await RisingEdge(dut.clk)

    word_bytes = axis_word_bytes(
        dut.s_frame_tdata_i,
        dut.s_frame_tkeep_i,
        interface_name="end-to-end Ethernet input",
    )

    return network_clock_mhz, data_clock_mhz, word_bytes


class DataPathMonitor:
    """Capture CDC output handshakes and externally emitted BBOs."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.running = True
        self.event_words: list[int] = []
        self.bbo_words: list[int] = []

    async def run(self) -> None:
        while self.running:
            # Capture the event boundary before the active edge so the exact
            # FIFO -> order_book valid/ready handshake is unambiguous.
            await FallingEdge(self.dut.data_clk)
            await ReadOnly()

            event_valid = signal_value_to_int(
                self.dut.probe_event_valid_o.value
            )
            event_ready = signal_value_to_int(
                self.dut.probe_event_ready_o.value
            )
            event_word = signal_value_to_int(
                self.dut.probe_event_data_o.value
            )

            await RisingEdge(self.dut.data_clk)

            if event_valid == 1 and event_ready == 1:
                self.event_words.append(event_word)

            # BBO valid is a registered pulse with no ready signal. Sampling
            # after the edge catches the newly emitted result for this cycle.
            await ReadOnly()
            if signal_value_to_int(self.dut.bbo_valid_o.value) == 1:
                self.bbo_words.append(
                    signal_value_to_int(self.dut.bbo_data_o.value)
                )

    async def wait_for_completion(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            await FallingEdge(self.dut.data_clk)
            if (
                len(self.event_words) >= expected_count
                and len(self.bbo_words) >= expected_count
            ):
                return

        raise TimeoutError(
            "timed out waiting for end-to-end completion: "
            f"events={len(self.event_words)}/{expected_count} "
            f"bbos={len(self.bbo_words)}/{expected_count}"
        )

    def stop(self) -> None:
        self.running = False


class NetworkStatusMonitor:
    """Capture ingress errors and unexpected sequence decisions."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.running = True

        self.frame_errors: list[int] = []
        self.mold_errors: list[int] = []
        self.realign_errors: list[int] = []
        self.sequence_errors: list[dict[str, int]] = []
        self.sequence_samples = 0

    async def run(self) -> None:
        while self.running:
            await RisingEdge(self.dut.clk)
            await ReadOnly()

            if signal_value_to_int(self.dut.frame_drop_o.value) == 1:
                self.frame_errors.append(
                    signal_value_to_int(self.dut.frame_err_o.value)
                )

            if signal_value_to_int(self.dut.mold_drop_o.value) == 1:
                self.mold_errors.append(
                    signal_value_to_int(self.dut.mold_err_o.value)
                )

            realign_err = signal_value_to_int(self.dut.realign_err_o.value)
            if realign_err != 0:
                self.realign_errors.append(realign_err)

            if signal_value_to_int(self.dut.seq_valid_o.value) == 1:
                self.sequence_samples += 1

                duplicate = signal_value_to_int(self.dut.duplicate_o.value)
                gap = signal_value_to_int(self.dut.gap_o.value)
                stale = signal_value_to_int(self.dut.stale_o.value)
                if duplicate or gap or stale:
                    self.sequence_errors.append(
                        {
                            "seq": signal_value_to_int(self.dut.seq_o.value),
                            "duplicate": duplicate,
                            "gap": gap,
                            "stale": stale,
                        }
                    )

    def stop(self) -> None:
        self.running = False


def _assert_stock_id(dut: Any, bbo_word: int, *, expected: int) -> None:
    """Check the two-bit stock ID without baking in the rest of bbo_t width."""

    bbo_width = len(dut.bbo_data_o)
    if bbo_width < 2:
        raise AssertionError(f"bbo_data_o is unexpectedly narrow: {bbo_width} bits")

    stock_id = (bbo_word >> (bbo_width - 2)) & 0x3
    assert stock_id == expected, (
        f"expected stock_id={expected}, got stock_id={stock_id} "
        f"from 0x{bbo_word:x}"
    )


@cocotb.test()
async def test_ethernet_to_bbo_matches_golden_model(dut: Any) -> None:
    """Drive a complete mixed ITCH lifecycle from Ethernet to golden BBOs."""

    network_clock_mhz, data_clock_mhz, word_bytes = await _initialise(dut)

    messages = _directed_messages()
    binaryfile_data = encode_binaryfile(messages)
    expected_events, expected_states = _build_golden(binaryfile_data)
    frames = _encapsulate_frames(binaryfile_data)

    # One System Event is intentionally ignored. The remaining eight book
    # mutations cover A/F/E/C/X/U/D and the replacement reference lifecycle.
    assert len(messages) == 9
    assert len(expected_events) == 8
    assert len(expected_states) == len(expected_events)

    dut._log.info(
        "Ethernet-to-BBO config: axis=%d-bit network=%.3f MHz "
        "data=%.3f MHz frames=%d source_messages=%d expected_events=%d",
        word_bytes * 8,
        network_clock_mhz,
        data_clock_mhz,
        len(frames),
        len(messages),
        len(expected_events),
    )

    data_monitor = DataPathMonitor(dut)
    network_monitor = NetworkStatusMonitor(dut)

    data_task = cocotb.start_soon(data_monitor.run())
    network_task = cocotb.start_soon(network_monitor.run())

    for frame_index, frame in enumerate(frames):
        dut._log.info(
            "driving Ethernet frame=%d bytes=%d",
            frame_index,
            len(frame),
        )
        await drive_axis_frame(
            dut,
            frame,
            timeout_cycles=TIMEOUT_CYCLES,
        )

    await data_monitor.wait_for_completion(len(expected_events))

    event_count = len(data_monitor.event_words)
    bbo_count = len(data_monitor.bbo_words)

    # Give any accidental extra output enough time to become visible. This is
    # only a no-extra-output check, not a latency requirement for valid work.
    for _ in range(DRAIN_CYCLES):
        await RisingEdge(dut.data_clk)

    assert len(data_monitor.event_words) == event_count, (
        "extra normalised event appeared after expected end-to-end completion"
    )
    assert len(data_monitor.bbo_words) == bbo_count, (
        "extra BBO appeared after expected end-to-end completion"
    )

    data_monitor.stop()
    network_monitor.stop()
    data_task.cancel()
    network_task.cancel()

    assert len(data_monitor.event_words) == len(expected_events), (
        f"expected {len(expected_events)} CDC events, "
        f"got {len(data_monitor.event_words)}"
    )
    assert len(data_monitor.bbo_words) == len(expected_states), (
        f"expected {len(expected_states)} BBO outputs, "
        f"got {len(data_monitor.bbo_words)}"
    )

    for event_index, (event_word, expected_event) in enumerate(
        zip(data_monitor.event_words, expected_events, strict=True)
    ):
        try:
            assert_data_t_matches_word(event_word, expected_event)
        except AssertionError as exc:
            raise AssertionError(
                f"CDC/event mismatch at event_index={event_index} "
                f"msg_index={expected_event['msg_index']}"
            ) from exc

    for event_index, (bbo_word, expected_state) in enumerate(
        zip(data_monitor.bbo_words, expected_states, strict=True)
    ):
        try:
            assert_bbo_matches_word(bbo_word, expected_state)
            _assert_stock_id(dut, bbo_word, expected=TARGET_LOCATE)
        except AssertionError as exc:
            raise AssertionError(
                f"BBO mismatch at event_index={event_index} "
                f"msg_index={expected_state['msg_index']}"
            ) from exc

    assert network_monitor.frame_errors == [], (
        f"unexpected frame errors: {network_monitor.frame_errors}"
    )
    assert network_monitor.mold_errors == [], (
        f"unexpected Mold errors: {network_monitor.mold_errors}"
    )
    assert network_monitor.realign_errors == [], (
        f"unexpected realign errors: {network_monitor.realign_errors}"
    )
    assert network_monitor.sequence_errors == [], (
        f"unexpected sequence decisions: {network_monitor.sequence_errors}"
    )
    assert network_monitor.sequence_samples == len(frames), (
        f"expected one sequence decision per frame ({len(frames)}), "
        f"got {network_monitor.sequence_samples}"
    )

    dut._log.info(
        "Ethernet-to-BBO golden replay passed: events=%d BBOs=%d frames=%d",
        len(data_monitor.event_words),
        len(data_monitor.bbo_words),
        len(frames),
    )
