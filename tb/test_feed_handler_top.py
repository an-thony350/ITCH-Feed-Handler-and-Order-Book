"""G3.1/G3.2 cocotb golden replay for feed_handler_top.sv.

Scope:
- Encapsulate the exact golden BinaryFILE stream as Ethernet/IPv4/UDP/
  MoldUDP64 frames.
- Drive complete Ethernet frames through the real top-level input.
- Compare every emitted BBO against states.jsonl.
- Check MoldUDP64 sequence metadata and baseline no-error/no-gap status.

G3.1 uses one ITCH message per MoldUDP64 packet.
G3.2 uses three ITCH messages per MoldUDP64 packet to exercise message-length
parsing, realignment and full-chain backpressure within a shared datagram.
G4.1 injects duplicate and A/B-copy packets and proves first-copy-wins
suppression without duplicate order-book mutations.
G4.2 injects an out-of-order sequence range, verifies gap/stale reporting,
accepts the post-gap packet, and suppresses the later missing packet.
G4.3 verifies that heartbeat and EOS packets are status-only through the
complete feed-handler chain, including heartbeat-driven gap reporting.
"""

from __future__ import annotations

from io import BytesIO, StringIO
import json
from pathlib import Path
from typing import Any

import cocotb
from cocotb.triggers import ReadOnly, RisingEdge

from golden.network_encapsulator import assert_roundtrip, encapsulate_bytes
from itch_harness.axis import (
    clock_cycles,
    drive_axis_frame,
    reset_dut,
    start_clock,
)
from itch_harness.oracle import GoldenOracle, load_oracle
from itch_harness.scoreboard import assert_bbo_matches_word, signal_value_to_int


SYNTHETIC_INPUT_FILENAME = "itch_synthetic.bin"

TARGET_LOCATE = 1
BASE_PRICE = 9000

G3_1_MESSAGES_PER_PACKET = 1
G3_2_MESSAGES_PER_PACKET = 3

SEQ_START = 1
SESSION = "SESSION1"
SRC_PORT = 40_000
DST_PORT = 26_400

RESET_CYCLES = 5
TIMEOUT_CYCLES = 500_000
QUIET_CYCLES = 30


JsonRecord = dict[str, Any]


def golden_input_path(oracle: GoldenOracle) -> Path:
    """Return the BinaryFILE input paired with the loaded golden JSONL files."""

    input_path = oracle.events_path.parent / SYNTHETIC_INPUT_FILENAME
    if not input_path.exists():
        raise FileNotFoundError(
            f"golden BinaryFILE input not found: {input_path}\n"
            "Run scripts/run_golden.sh from the repository root first."
        )
    return input_path


def build_frames(
    binaryfile_data: bytes,
    *,
    messages_per_packet: int,
    duplicate_frame: int | None = None,
    ab_duplicate: bool = False,
) -> tuple[list[bytes], list[JsonRecord], int, int]:
    """Encapsulate BinaryFILE data and split the concatenated frame stream.

    Return:
        frames:
            Ethernet frames in transmission order.
        metadata:
            One encapsulator metadata row per frame.
        source_message_count:
            Number of original ITCH BinaryFILE source messages.
        wire_message_count:
            Total ITCH message copies carried on the generated wire stream.
    """

    frames_buffer = BytesIO()
    metadata_buffer = StringIO()

    stats = encapsulate_bytes(
        binaryfile_data,
        frames_out=frames_buffer,
        meta_out=metadata_buffer,
        messages_per_packet=messages_per_packet,
        seq_start=SEQ_START,
        session=SESSION,
        src_port=SRC_PORT,
        dst_port=DST_PORT,
        duplicate_frame=duplicate_frame,
        ab_duplicate=ab_duplicate,
    )

    frames_data = frames_buffer.getvalue()
    metadata = [
        json.loads(line)
        for line in metadata_buffer.getvalue().splitlines()
        if line.strip()
    ]

    assert stats.frames_written == len(metadata)
    assert stats.data_frames_written == len(metadata)
    assert stats.frames_dropped == 0

    frames: list[bytes] = []
    cursor = 0

    for row, record in enumerate(metadata):
        frame_length = int(record["frame_length"])
        if frame_length <= 0:
            raise AssertionError(
                f"metadata row {row} has invalid frame_length={frame_length}"
            )

        frame_end = cursor + frame_length
        if frame_end > len(frames_data):
            raise AssertionError(
                f"metadata row {row} overruns concatenated frame bytes"
            )

        frames.append(frames_data[cursor:frame_end])
        cursor = frame_end

    assert cursor == len(frames_data), (
        f"frame metadata consumed {cursor} bytes, "
        f"but frame stream contains {len(frames_data)}"
    )

    # The byte-exact round-trip helper expects one wire copy of every source
    # message. Duplicate campaigns are validated structurally below instead.
    if duplicate_frame is None and not ab_duplicate:
        assert_roundtrip(binaryfile_data, frames_data)

    source_message_count = 0
    wire_message_count = 0

    for row, record in enumerate(metadata):
        count = int(record["count"])
        message_indices = list(record["message_indices"])
        payload_lengths = list(record["payload_lengths"])

        assert int(record["frame_index"]) == row
        assert count == len(message_indices)
        assert count == len(payload_lengths)
        assert 1 <= count <= messages_per_packet

        # Every frame except a possible final partial frame should be full.
        if row < len(metadata) - 1:
            assert count == messages_per_packet

        assert record["heartbeat"] is False
        assert record["eos"] is False

        wire_message_count += count
        if record["duplicate_of"] is None:
            source_message_count += count

    assert stats.source_messages_seen == source_message_count
    assert stats.messages_written == wire_message_count

    if metadata:
        assert stats.final_seq == int(metadata[-1]["expected_next"])
    else:
        assert stats.final_seq == SEQ_START

    return frames, metadata, source_message_count, wire_message_count


async def initialise_feed_handler(dut: Any) -> None:
    """Start/reset the complete feed handler with stable book configuration."""

    await start_clock(dut)

    dut.target_locate_i.value = TARGET_LOCATE
    dut.base_price_i.value = BASE_PRICE

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0

    await reset_dut(dut, cycles=RESET_CYCLES)


class FeedHandlerMonitor:
    """Collect BBOs, MoldUDP64 metadata and error/status outputs."""

    def __init__(self, dut: Any) -> None:
        self.dut = dut
        self.running = True

        self.bbo_words: list[int] = []
        self.seq_samples: list[dict[str, int]] = []

        self.frame_drop_errs: list[int] = []
        self.mold_drop_errs: list[int] = []
        self.realign_errs: list[int] = []
        self.stale_seen = False

    async def run(self) -> None:
        while self.running:
            await RisingEdge(self.dut.clk)
            await ReadOnly()

            if signal_value_to_int(self.dut.bbo_valid_o.value) == 1:
                self.bbo_words.append(
                    signal_value_to_int(self.dut.bbo_data_o.value)
                )

            if signal_value_to_int(self.dut.seq_valid_o.value) == 1:
                self.seq_samples.append(
                    {
                        "session": signal_value_to_int(self.dut.session_o.value),
                        "seq": signal_value_to_int(self.dut.seq_o.value),
                        "count": signal_value_to_int(self.dut.count_o.value),
                        "expected_next": signal_value_to_int(
                            self.dut.expected_next_o.value
                        ),
                        "in_order": signal_value_to_int(self.dut.in_order_o.value),
                        "duplicate": signal_value_to_int(
                            self.dut.duplicate_o.value
                        ),
                        "gap": signal_value_to_int(self.dut.gap_o.value),
                        "heartbeat": signal_value_to_int(
                            self.dut.heartbeat_o.value
                        ),
                        "eos": signal_value_to_int(self.dut.eos_o.value),
                        "stale": signal_value_to_int(self.dut.stale_o.value),
                        "expected_seq": signal_value_to_int(
                            self.dut.expected_seq_o.value
                        ),
                        "gap_start": signal_value_to_int(
                            self.dut.gap_start_o.value
                        ),
                        "gap_end": signal_value_to_int(
                            self.dut.gap_end_o.value
                        ),
                    }
                )

            if signal_value_to_int(self.dut.frame_drop_o.value) == 1:
                self.frame_drop_errs.append(
                    signal_value_to_int(self.dut.frame_err_o.value)
                )

            if signal_value_to_int(self.dut.mold_drop_o.value) == 1:
                self.mold_drop_errs.append(
                    signal_value_to_int(self.dut.mold_err_o.value)
                )

            realign_err = signal_value_to_int(self.dut.realign_err_o.value)
            if realign_err != 0:
                self.realign_errs.append(realign_err)

            if signal_value_to_int(self.dut.stale_o.value) == 1:
                self.stale_seen = True

    async def wait_for_counts(
        self,
        *,
        expected_bbos: int,
        expected_seq_samples: int,
        timeout_cycles: int = TIMEOUT_CYCLES,
    ) -> None:
        for _ in range(timeout_cycles):
            if (
                len(self.bbo_words) >= expected_bbos
                and len(self.seq_samples) >= expected_seq_samples
            ):
                return
            await RisingEdge(self.dut.clk)

        raise TimeoutError(
            "timed out waiting for complete feed-handler output: "
            f"BBOs={len(self.bbo_words)}/{expected_bbos}, "
            f"sequence samples={len(self.seq_samples)}/{expected_seq_samples}"
        )

    def stop(self) -> None:
        self.running = False


async def drive_frames(dut: Any, frames: list[bytes]) -> None:
    """Drive all frames in metadata order while respecting AXIS backpressure."""

    for frame in frames:
        await drive_axis_frame(
            dut,
            frame,
            timeout_cycles=TIMEOUT_CYCLES,
        )


async def run_golden_replay(
    dut: Any,
    *,
    messages_per_packet: int,
    stage_name: str,
    duplicate_frame: int | None = None,
    ab_duplicate: bool = False,
) -> None:
    """Run one complete in-order network-to-BBO replay configuration."""

    oracle = load_oracle()
    input_path = golden_input_path(oracle)
    binaryfile_data = input_path.read_bytes()

    frames, metadata, source_message_count, wire_message_count = build_frames(
        binaryfile_data,
        messages_per_packet=messages_per_packet,
        duplicate_frame=duplicate_frame,
        ab_duplicate=ab_duplicate,
    )

    # The current synthetic stream contains one unsupported source message.
    # It advances MoldUDP64 sequencing but intentionally produces no BBO.
    assert source_message_count >= oracle.count

    if messages_per_packet > 1:
        assert any(int(record["count"]) > 1 for record in metadata), (
            f"{stage_name} did not generate any multi-message MoldUDP64 packet"
        )

    duplicate_records = [
        record for record in metadata if record["duplicate_of"] is not None
    ]
    original_records = [
        record for record in metadata if record["duplicate_of"] is None
    ]

    if ab_duplicate:
        assert duplicate_frame is None
        assert len(duplicate_records) == len(original_records)
        assert len(metadata) == 2 * len(original_records)

        for pair_index in range(0, len(metadata), 2):
            original = metadata[pair_index]
            duplicate = metadata[pair_index + 1]

            assert original["duplicate_of"] is None
            assert original["feed"] == "A"
            assert duplicate["feed"] == "B"
            assert duplicate["duplicate_of"] == original["source_frame_index"]
            assert duplicate["seq"] == original["seq"]
            assert duplicate["count"] == original["count"]
            assert duplicate["message_indices"] == original["message_indices"]

    elif duplicate_frame is not None:
        assert len(duplicate_records) == 1
        duplicate = duplicate_records[0]
        assert duplicate["feed"] == "DUP"
        assert int(duplicate["duplicate_of"]) == duplicate_frame

    else:
        assert duplicate_records == []

    await initialise_feed_handler(dut)

    monitor = FeedHandlerMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())
    driver_task = cocotb.start_soon(drive_frames(dut, frames))

    await driver_task
    await monitor.wait_for_counts(
        expected_bbos=oracle.count,
        expected_seq_samples=len(metadata),
    )

    # Continue monitoring after completion to catch stale or duplicate pulses.
    await clock_cycles(dut, QUIET_CYCLES)

    monitor.stop()
    await monitor_task

    assert len(monitor.bbo_words) == oracle.count, (
        f"expected {oracle.count} BBO outputs, got {len(monitor.bbo_words)}"
    )

    for word, state in zip(monitor.bbo_words, oracle.states, strict=True):
        assert_bbo_matches_word(word, state)

    assert len(monitor.seq_samples) == len(metadata), (
        f"expected {len(metadata)} MoldUDP64 header samples, "
        f"got {len(monitor.seq_samples)}"
    )

    expected_session = SESSION.encode("ascii").ljust(10, b" ")

    for row, (sample, record) in enumerate(
        zip(monitor.seq_samples, metadata, strict=True)
    ):
        got_session = int(sample["session"]).to_bytes(10, byteorder="big")

        assert got_session == expected_session, (
            f"frame {row}: session mismatch: "
            f"expected {expected_session!r}, got {got_session!r}"
        )
        assert sample["seq"] == int(record["seq"])
        assert sample["count"] == int(record["count"])
        assert sample["expected_next"] == int(record["expected_next"])

        is_duplicate = record["duplicate_of"] is not None

        assert sample["in_order"] == int(not is_duplicate)
        assert sample["duplicate"] == int(is_duplicate)
        assert sample["gap"] == 0
        assert sample["heartbeat"] == 0
        assert sample["eos"] == 0

    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []
    assert monitor.stale_seen is False

    expected_final_seq = (
        int(metadata[-1]["expected_next"])
        if metadata
        else SEQ_START
    )
    assert signal_value_to_int(dut.expected_seq_o.value) == expected_final_seq

    dut._log.info(
        "%s passed: frames=%d source_messages=%d wire_message_copies=%d "
        "matched_bbos=%d duplicate_packets=%d messages_per_packet=%d "
        "seq_start=%d expected_final_seq=%d",
        stage_name,
        len(frames),
        source_message_count,
        wire_message_count,
        len(monitor.bbo_words),
        len(duplicate_records),
        messages_per_packet,
        SEQ_START,
        expected_final_seq,
    )



def directed_common_itch_header(
    msg_type: str,
    *,
    locate: int,
    tracking: int,
    timestamp_ns: int,
) -> bytes:
    """Build the 11-byte common ITCH header for a directed full-chain test."""

    if len(msg_type) != 1:
        raise ValueError("msg_type must be one character")
    if not 0 <= locate < (1 << 16):
        raise ValueError("locate must fit in 16 bits")
    if not 0 <= tracking < (1 << 16):
        raise ValueError("tracking must fit in 16 bits")
    if not 0 <= timestamp_ns < (1 << 48):
        raise ValueError("timestamp_ns must fit in 48 bits")

    return (
        msg_type.encode("ascii")
        + locate.to_bytes(2, "big")
        + tracking.to_bytes(2, "big")
        + timestamp_ns.to_bytes(6, "big")
    )


def directed_add_order_payload(
    order_ref: int,
    *,
    side: str,
    shares: int,
    price: int,
    tracking: int,
    timestamp_ns: int,
) -> bytes:
    """Build one 36-byte ITCH Add Order payload for the gap campaign."""

    if side not in ("B", "S"):
        raise ValueError("side must be 'B' or 'S'")

    payload = (
        directed_common_itch_header(
            "A",
            locate=TARGET_LOCATE,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )
        + order_ref.to_bytes(8, "big")
        + side.encode("ascii")
        + shares.to_bytes(4, "big")
        + b"GAPTEST ".ljust(8, b" ")[:8]
        + price.to_bytes(4, "big")
    )

    assert len(payload) == 36
    return payload


def directed_binaryfile(payloads: list[bytes]) -> bytes:
    """Encode raw ITCH payloads using the BinaryFILE length-prefix format."""

    return b"".join(
        len(payload).to_bytes(2, "big") + payload
        for payload in payloads
    )


def directed_frames(
    payloads: list[bytes],
    *,
    seq_start: int,
) -> tuple[list[bytes], list[JsonRecord]]:
    """Encapsulate one directed ITCH payload per MoldUDP64/Ethernet frame."""

    binaryfile_data = directed_binaryfile(payloads)
    frames_buffer = BytesIO()
    metadata_buffer = StringIO()

    stats = encapsulate_bytes(
        binaryfile_data,
        frames_out=frames_buffer,
        meta_out=metadata_buffer,
        messages_per_packet=1,
        seq_start=seq_start,
        session=SESSION,
        src_port=SRC_PORT,
        dst_port=DST_PORT,
    )

    frames_data = frames_buffer.getvalue()
    metadata = [
        json.loads(line)
        for line in metadata_buffer.getvalue().splitlines()
        if line.strip()
    ]

    assert stats.source_messages_seen == len(payloads)
    assert stats.frames_written == len(payloads)
    assert len(metadata) == len(payloads)

    frames: list[bytes] = []
    cursor = 0

    for row, record in enumerate(metadata):
        frame_length = int(record["frame_length"])
        frame_end = cursor + frame_length

        assert int(record["frame_index"]) == row
        assert int(record["count"]) == 1
        assert record["message_indices"] == [row]

        frames.append(frames_data[cursor:frame_end])
        cursor = frame_end

    assert cursor == len(frames_data)
    assert_roundtrip(binaryfile_data, frames_data)

    return frames, metadata



def directed_control_frame(
    *,
    seq: int,
    heartbeat: bool = False,
    eos: bool = False,
) -> tuple[bytes, JsonRecord]:
    """Build exactly one heartbeat or EOS Ethernet frame."""

    if heartbeat == eos:
        raise ValueError("select exactly one of heartbeat or eos")

    frames_buffer = BytesIO()
    metadata_buffer = StringIO()

    stats = encapsulate_bytes(
        b"",
        frames_out=frames_buffer,
        meta_out=metadata_buffer,
        messages_per_packet=1,
        seq_start=seq,
        session=SESSION,
        src_port=SRC_PORT,
        dst_port=DST_PORT,
        emit_heartbeat=heartbeat,
        emit_eos=eos,
    )

    metadata = [
        json.loads(line)
        for line in metadata_buffer.getvalue().splitlines()
        if line.strip()
    ]

    assert stats.source_messages_seen == 0
    assert stats.messages_written == 0
    assert stats.frames_written == 1
    assert stats.data_frames_written == 0
    assert stats.frames_dropped == 0
    assert stats.final_seq == seq
    assert len(metadata) == 1

    record = metadata[0]
    frame = frames_buffer.getvalue()

    assert int(record["frame_index"]) == 0
    assert int(record["seq"]) == seq
    assert int(record["frame_length"]) == len(frame)
    assert record["message_indices"] == []
    assert record["payload_lengths"] == []
    assert record["heartbeat"] is heartbeat
    assert record["eos"] is eos

    if heartbeat:
        assert int(record["count"]) == 0
    else:
        assert int(record["count"]) == 0xFFFF

    return frame, record

@cocotb.test()
async def test_feed_handler_top_one_message_per_packet_matches_golden(
    dut: Any,
) -> None:
    """G3.1: replay one ITCH message per MoldUDP64 packet."""

    await run_golden_replay(
        dut,
        messages_per_packet=G3_1_MESSAGES_PER_PACKET,
        stage_name="G3.1",
    )


@cocotb.test()
async def test_feed_handler_top_three_messages_per_packet_matches_golden(
    dut: Any,
) -> None:
    """G3.2: replay three ITCH messages per MoldUDP64 packet."""

    await run_golden_replay(
        dut,
        messages_per_packet=G3_2_MESSAGES_PER_PACKET,
        stage_name="G3.2",
    )



@cocotb.test()
async def test_feed_handler_top_single_duplicate_packet_is_suppressed(
    dut: Any,
) -> None:
    """G4.1a: one repeated MoldUDP64 packet must not update the book twice."""

    await run_golden_replay(
        dut,
        messages_per_packet=G3_2_MESSAGES_PER_PACKET,
        duplicate_frame=5,
        stage_name="G4.1a",
    )


@cocotb.test()
async def test_feed_handler_top_ab_duplicate_stream_first_copy_wins(
    dut: Any,
) -> None:
    """G4.1b: every B-feed copy is dropped after the matching A-feed copy."""

    await run_golden_replay(
        dut,
        messages_per_packet=G3_2_MESSAGES_PER_PACKET,
        ab_duplicate=True,
        stage_name="G4.1b",
    )



@cocotb.test()
async def test_feed_handler_top_gap_marks_stale_and_late_packet_is_dropped(
    dut: Any,
) -> None:
    """G4.2: accept post-gap data, mark stale, then drop the late missing packet."""

    gap_seq_start = 100

    payloads = [
        # Accepted first packet: seq=100, expected sequence becomes 101.
        directed_add_order_payload(
            1001,
            side="B",
            shares=100,
            price=10_000,
            tracking=1,
            timestamp_ns=1,
        ),
        # Missing range: seq=101. This frame is sent last and must be dropped.
        directed_add_order_payload(
            2001,
            side="S",
            shares=50,
            price=10_020,
            tracking=2,
            timestamp_ns=2,
        ),
        # Arrives early: seq=102. It must be accepted while reporting gap 101..101.
        directed_add_order_payload(
            1002,
            side="B",
            shares=40,
            price=10_005,
            tracking=3,
            timestamp_ns=3,
        ),
    ]

    frames, metadata = directed_frames(
        payloads,
        seq_start=gap_seq_start,
    )

    # Arrival order creates a one-message gap, then presents that missing packet
    # late. This models an A/B or retransmit path delivering old data after the
    # hot path has already continued.
    arrival_order = [0, 2, 1]
    arrival_frames = [frames[index] for index in arrival_order]
    arrival_metadata = [metadata[index] for index in arrival_order]

    assert [int(record["seq"]) for record in arrival_metadata] == [100, 102, 101]

    await initialise_feed_handler(dut)

    monitor = FeedHandlerMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())
    driver_task = cocotb.start_soon(drive_frames(dut, arrival_frames))

    await driver_task
    await monitor.wait_for_counts(
        expected_bbos=2,
        expected_seq_samples=3,
    )
    await clock_cycles(dut, QUIET_CYCLES)

    monitor.stop()
    await monitor_task

    # The missing ask packet must never reach the book. Only the first bid and
    # the accepted post-gap bid may produce BBO updates.
    expected_states = [
        {
            "msg_index": "gap-first",
            "bbo": {
                "bid_price": 10_000,
                "bid_size": 100,
                "ask_price": None,
                "ask_size": None,
            },
        },
        {
            "msg_index": "gap-post",
            "bbo": {
                "bid_price": 10_005,
                "bid_size": 40,
                "ask_price": None,
                "ask_size": None,
            },
        },
    ]

    assert len(monitor.bbo_words) == len(expected_states)
    for word, state in zip(monitor.bbo_words, expected_states, strict=True):
        assert_bbo_matches_word(word, state)

    assert len(monitor.seq_samples) == 3
    first, post_gap, late = monitor.seq_samples

    assert first["seq"] == 100
    assert first["count"] == 1
    assert first["in_order"] == 1
    assert first["gap"] == 0
    assert first["duplicate"] == 0
    assert first["stale"] == 0
    assert first["expected_seq"] == 101

    assert post_gap["seq"] == 102
    assert post_gap["count"] == 1
    assert post_gap["in_order"] == 0
    assert post_gap["gap"] == 1
    assert post_gap["duplicate"] == 0
    assert post_gap["stale"] == 1
    assert post_gap["gap_start"] == 101
    assert post_gap["gap_end"] == 101
    assert post_gap["expected_seq"] == 103

    assert late["seq"] == 101
    assert late["count"] == 1
    assert late["in_order"] == 0
    assert late["gap"] == 0
    assert late["duplicate"] == 1
    assert late["stale"] == 1
    assert late["gap_start"] == 101
    assert late["gap_end"] == 101
    assert late["expected_seq"] == 103

    assert signal_value_to_int(dut.stale_o.value) == 1
    assert signal_value_to_int(dut.expected_seq_o.value) == 103
    assert signal_value_to_int(dut.gap_start_o.value) == 101
    assert signal_value_to_int(dut.gap_end_o.value) == 101

    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []
    assert monitor.stale_seen is True

    dut._log.info(
        "G4.2 passed: arrival_seq=[100,102,101] gap=101..101 "
        "accepted_bbos=2 late_duplicates=1 expected_final_seq=103 stale=1"
    )


@cocotb.test()
async def test_feed_handler_top_heartbeat_and_eos_are_status_only(
    dut: Any,
) -> None:
    """G4.3a: in-order heartbeat/EOS frames must not mutate the order book."""

    first_payload = directed_add_order_payload(
        3001,
        side="B",
        shares=100,
        price=10_000,
        tracking=1,
        timestamp_ns=1,
    )
    second_payload = directed_add_order_payload(
        3002,
        side="S",
        shares=50,
        price=10_020,
        tracking=2,
        timestamp_ns=2,
    )

    first_frames, _ = directed_frames([first_payload], seq_start=500)
    heartbeat_frame, heartbeat_meta = directed_control_frame(
        seq=501,
        heartbeat=True,
    )
    second_frames, _ = directed_frames([second_payload], seq_start=501)
    eos_frame, eos_meta = directed_control_frame(
        seq=502,
        eos=True,
    )

    assert heartbeat_meta["expected_next"] == 501
    assert eos_meta["expected_next"] == 502

    frames = [
        first_frames[0],
        heartbeat_frame,
        second_frames[0],
        eos_frame,
    ]

    await initialise_feed_handler(dut)

    monitor = FeedHandlerMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())
    driver_task = cocotb.start_soon(drive_frames(dut, frames))

    await driver_task
    await monitor.wait_for_counts(
        expected_bbos=2,
        expected_seq_samples=4,
    )
    await clock_cycles(dut, QUIET_CYCLES)

    monitor.stop()
    await monitor_task

    expected_states = [
        {
            "msg_index": "heartbeat-before",
            "bbo": {
                "bid_price": 10_000,
                "bid_size": 100,
                "ask_price": None,
                "ask_size": None,
            },
        },
        {
            "msg_index": "heartbeat-after",
            "bbo": {
                "bid_price": 10_000,
                "bid_size": 100,
                "ask_price": 10_020,
                "ask_size": 50,
            },
        },
    ]

    assert len(monitor.bbo_words) == len(expected_states)
    for word, state in zip(monitor.bbo_words, expected_states, strict=True):
        assert_bbo_matches_word(word, state)

    assert len(monitor.seq_samples) == 4
    first, heartbeat, second, eos = monitor.seq_samples

    assert first["seq"] == 500
    assert first["count"] == 1
    assert first["in_order"] == 1
    assert first["heartbeat"] == 0
    assert first["eos"] == 0
    assert first["expected_seq"] == 501

    assert heartbeat["seq"] == 501
    assert heartbeat["count"] == 0
    assert heartbeat["in_order"] == 0
    assert heartbeat["duplicate"] == 0
    assert heartbeat["gap"] == 0
    assert heartbeat["heartbeat"] == 1
    assert heartbeat["eos"] == 0
    assert heartbeat["stale"] == 0
    assert heartbeat["expected_next"] == 501
    assert heartbeat["expected_seq"] == 501

    assert second["seq"] == 501
    assert second["count"] == 1
    assert second["in_order"] == 1
    assert second["heartbeat"] == 0
    assert second["eos"] == 0
    assert second["expected_seq"] == 502

    assert eos["seq"] == 502
    assert eos["count"] == 0xFFFF
    assert eos["in_order"] == 0
    assert eos["duplicate"] == 0
    assert eos["gap"] == 0
    assert eos["heartbeat"] == 0
    assert eos["eos"] == 1
    assert eos["stale"] == 0

    # expected_next_o is the raw seq+count header sideband. The sequence guard
    # correctly keeps expected_seq_o at 502 because EOS carries no messages.
    assert eos["expected_next"] == 502 + 0xFFFF
    assert eos["expected_seq"] == 502

    assert signal_value_to_int(dut.expected_seq_o.value) == 502
    assert signal_value_to_int(dut.stale_o.value) == 0

    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []
    assert monitor.stale_seen is False

    dut._log.info(
        "G4.3a passed: data=2 heartbeat=1 eos=1 matched_bbos=2 "
        "expected_final_seq=502 stale=0"
    )


@cocotb.test()
async def test_feed_handler_top_heartbeat_gap_is_status_only(
    dut: Any,
) -> None:
    """G4.3b: a future heartbeat reports a gap but emits no book event."""

    first_payload = directed_add_order_payload(
        4001,
        side="B",
        shares=80,
        price=10_000,
        tracking=1,
        timestamp_ns=1,
    )
    post_gap_payload = directed_add_order_payload(
        4002,
        side="S",
        shares=25,
        price=10_030,
        tracking=2,
        timestamp_ns=2,
    )

    first_frames, _ = directed_frames([first_payload], seq_start=700)
    heartbeat_frame, _ = directed_control_frame(
        seq=704,
        heartbeat=True,
    )
    post_gap_frames, _ = directed_frames([post_gap_payload], seq_start=704)

    frames = [
        first_frames[0],
        heartbeat_frame,
        post_gap_frames[0],
    ]

    await initialise_feed_handler(dut)

    monitor = FeedHandlerMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())
    driver_task = cocotb.start_soon(drive_frames(dut, frames))

    await driver_task
    await monitor.wait_for_counts(
        expected_bbos=2,
        expected_seq_samples=3,
    )
    await clock_cycles(dut, QUIET_CYCLES)

    monitor.stop()
    await monitor_task

    expected_states = [
        {
            "msg_index": "heartbeat-gap-before",
            "bbo": {
                "bid_price": 10_000,
                "bid_size": 80,
                "ask_price": None,
                "ask_size": None,
            },
        },
        {
            "msg_index": "heartbeat-gap-after",
            "bbo": {
                "bid_price": 10_000,
                "bid_size": 80,
                "ask_price": 10_030,
                "ask_size": 25,
            },
        },
    ]

    assert len(monitor.bbo_words) == len(expected_states)
    for word, state in zip(monitor.bbo_words, expected_states, strict=True):
        assert_bbo_matches_word(word, state)

    assert len(monitor.seq_samples) == 3
    first, heartbeat, post_gap = monitor.seq_samples

    assert first["seq"] == 700
    assert first["count"] == 1
    assert first["in_order"] == 1
    assert first["expected_seq"] == 701
    assert first["stale"] == 0

    assert heartbeat["seq"] == 704
    assert heartbeat["count"] == 0
    assert heartbeat["heartbeat"] == 1
    assert heartbeat["eos"] == 0
    assert heartbeat["in_order"] == 0
    assert heartbeat["duplicate"] == 0
    assert heartbeat["gap"] == 1
    assert heartbeat["stale"] == 1
    assert heartbeat["gap_start"] == 701
    assert heartbeat["gap_end"] == 703
    assert heartbeat["expected_seq"] == 704

    assert post_gap["seq"] == 704
    assert post_gap["count"] == 1
    assert post_gap["in_order"] == 1
    assert post_gap["duplicate"] == 0
    assert post_gap["gap"] == 0
    assert post_gap["heartbeat"] == 0
    assert post_gap["eos"] == 0
    assert post_gap["stale"] == 1
    assert post_gap["gap_start"] == 701
    assert post_gap["gap_end"] == 703
    assert post_gap["expected_seq"] == 705

    assert signal_value_to_int(dut.expected_seq_o.value) == 705
    assert signal_value_to_int(dut.stale_o.value) == 1
    assert signal_value_to_int(dut.gap_start_o.value) == 701
    assert signal_value_to_int(dut.gap_end_o.value) == 703

    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []
    assert monitor.stale_seen is True

    dut._log.info(
        "G4.3b passed: heartbeat_gap=701..703 matched_bbos=2 "
        "expected_final_seq=705 stale=1"
    )
