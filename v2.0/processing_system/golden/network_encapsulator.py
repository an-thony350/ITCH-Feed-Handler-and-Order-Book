"""Software network encapsulator for ITCH BinaryFILE test vectors.

BinaryFILE input -> MoldUDP64 -> UDP -> IPv4 -> Ethernet II.

The output is a raw concatenation of Ethernet II frames plus a JSONL metadata
file. The metadata file is what the RTL testbench should use for frame lengths
and expected MoldUDP64 sequence/count sideband checks.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import BinaryIO, Iterator, TextIO

from golden.itch_parser import iter_binaryfile_payloads


ReadableBytes = bytes | bytearray | memoryview

_MOLD_SESSION_LEN = 10
_MOLD_HEADER_LEN = 20
_MOLD_EOS_COUNT = 0xFFFF
_ETH_HEADER_LEN = 14
_IPV4_HEADER_LEN = 20
_UDP_HEADER_LEN = 8
_IP_PROTOCOL_UDP = 17
_ETHERTYPE_IPV4 = 0x0800

_SRC_MAC = bytes.fromhex("02 00 00 00 00 01")
_DST_MAC = bytes.fromhex("02 00 00 00 00 02")
_SRC_IP = bytes([10, 0, 0, 1])
_DST_IP = bytes([10, 0, 0, 2])


class NetworkEncapsulationError(ValueError):
    """Raised when an encapsulated frame stream is structurally invalid."""


@dataclass(frozen=True)
class EncapsulationStats:
    """Summary of one encapsulation run."""

    source_messages_seen: int
    frames_written: int
    data_frames_written: int
    messages_written: int
    frames_dropped: int
    final_seq: int


@dataclass(frozen=True)
class RecoveredMessage:
    """One ITCH payload recovered from an Ethernet/IP/UDP/MoldUDP64 frame."""

    frame_index: int
    seq: int
    message_number: int
    payload: bytes


@dataclass(frozen=True)
class _SourceMessage:
    msg_index: int
    payload: bytes


@dataclass(frozen=True)
class _FramePlan:
    source_frame_index: int | None
    seq: int
    count: int
    messages: tuple[_SourceMessage, ...]
    heartbeat: bool = False
    eos: bool = False
    feed: str = "A"
    duplicate_of: int | None = None

    @property
    def expected_next(self) -> int:
        if self.heartbeat or self.eos:
            return self.seq
        return self.seq + self.count



def encapsulate_file(
    input_path: str | Path,
    *,
    frames_out: str | Path,
    meta_out: str | Path,
    messages_per_packet: int = 3,
    seq_start: int = 1,
    session: str = "SESSION1",
    src_port: int = 40_000,
    dst_port: int = 26_400,
    emit_heartbeat: bool = False,
    emit_eos: bool = False,
    duplicate_frame: int | None = None,
    drop_frame: int | None = None,
    ab_duplicate: bool = False,
    start_index: int = 0,
    max_messages: int | None = None,
) -> EncapsulationStats:
    """Read an ITCH BinaryFILE and write ``frames.bin`` plus ``frames.jsonl``."""

    input_data = Path(input_path).read_bytes()
    frames_path = Path(frames_out)
    meta_path = Path(meta_out)
    frames_path.parent.mkdir(parents=True, exist_ok=True)
    meta_path.parent.mkdir(parents=True, exist_ok=True)

    with frames_path.open("wb") as frames_handle, meta_path.open(
        "w", encoding="utf-8"
    ) as meta_handle:
        return encapsulate_bytes(
            input_data,
            frames_out=frames_handle,
            meta_out=meta_handle,
            messages_per_packet=messages_per_packet,
            seq_start=seq_start,
            session=session,
            src_port=src_port,
            dst_port=dst_port,
            emit_heartbeat=emit_heartbeat,
            emit_eos=emit_eos,
            duplicate_frame=duplicate_frame,
            drop_frame=drop_frame,
            ab_duplicate=ab_duplicate,
            start_index=start_index,
            max_messages=max_messages,
        )



def encapsulate_bytes(
    data: ReadableBytes,
    *,
    frames_out: BinaryIO,
    meta_out: TextIO,
    messages_per_packet: int = 3,
    seq_start: int = 1,
    session: str = "SESSION1",
    src_port: int = 40_000,
    dst_port: int = 26_400,
    emit_heartbeat: bool = False,
    emit_eos: bool = False,
    duplicate_frame: int | None = None,
    drop_frame: int | None = None,
    ab_duplicate: bool = False,
    start_index: int = 0,
    max_messages: int | None = None,
) -> EncapsulationStats:
    """Encapsulate in-memory BinaryFILE bytes into Ethernet frame bytes."""

    _validate_packet_options(
        messages_per_packet=messages_per_packet,
        seq_start=seq_start,
        src_port=src_port,
        dst_port=dst_port,
        duplicate_frame=duplicate_frame,
        drop_frame=drop_frame,
    )
    session_bytes = _encode_session(session)
    plans = _build_frame_plans(
        data,
        messages_per_packet=messages_per_packet,
        seq_start=seq_start,
        emit_heartbeat=emit_heartbeat,
        emit_eos=emit_eos,
        start_index=start_index,
        max_messages=max_messages,
    )
    _validate_requested_frame_indices(
        plans,
        duplicate_frame=duplicate_frame,
        drop_frame=drop_frame,
    )

    frame_index = 0
    data_frames_written = 0
    messages_written = 0
    frames_dropped = 0

    for plan in plans:
        if drop_frame is not None and plan.source_frame_index == drop_frame:
            frames_dropped += 1
            continue

        frame = _build_wire_frame(
            plan,
            session=session_bytes,
            src_port=src_port,
            dst_port=dst_port,
        )
        _write_frame(frames_out, meta_out, frame_index, plan, frame, src_port, dst_port)
        frame_index += 1
        if not plan.heartbeat and not plan.eos:
            data_frames_written += 1
            messages_written += plan.count

        if ab_duplicate and not plan.heartbeat and not plan.eos:
            duplicate_plan = _replace_feed(plan, feed="B", duplicate_of=plan.source_frame_index)
            duplicate = _build_wire_frame(
                duplicate_plan,
                session=session_bytes,
                src_port=src_port,
                dst_port=dst_port,
            )
            _write_frame(
                frames_out,
                meta_out,
                frame_index,
                duplicate_plan,
                duplicate,
                src_port,
                dst_port,
            )
            frame_index += 1
            data_frames_written += 1
            messages_written += duplicate_plan.count

        if duplicate_frame is not None and plan.source_frame_index == duplicate_frame:
            duplicate_plan = _replace_feed(
                plan,
                feed="DUP",
                duplicate_of=plan.source_frame_index,
            )
            duplicate = _build_wire_frame(
                duplicate_plan,
                session=session_bytes,
                src_port=src_port,
                dst_port=dst_port,
            )
            _write_frame(
                frames_out,
                meta_out,
                frame_index,
                duplicate_plan,
                duplicate,
                src_port,
                dst_port,
            )
            frame_index += 1
            data_frames_written += 1
            messages_written += duplicate_plan.count

    source_messages_seen = sum(plan.count for plan in plans if not plan.heartbeat and not plan.eos)
    final_seq = plans[-1].expected_next if plans else seq_start
    return EncapsulationStats(
        source_messages_seen=source_messages_seen,
        frames_written=frame_index,
        data_frames_written=data_frames_written,
        messages_written=messages_written,
        frames_dropped=frames_dropped,
        final_seq=final_seq,
    )



def recover_itch_payloads(frames: ReadableBytes) -> Iterator[RecoveredMessage]:
    """Yield ITCH payloads recovered from concatenated Ethernet frame bytes."""

    for frame_index, frame in enumerate(_iter_ethernet_frames(frames)):
        udp_payload = _extract_udp_payload(frame, frame_index=frame_index)
        yield from _iter_mold_messages(
            udp_payload,
            frame_index=frame_index,
        )



def assert_roundtrip(
    binaryfile_data: ReadableBytes,
    frames_data: ReadableBytes,
    *,
    start_index: int = 0,
    max_messages: int | None = None,
) -> None:
    """Assert that encapsulation followed by de-encapsulation is byte exact."""

    expected = [
        bytes(payload)
        for _msg_index, payload in iter_binaryfile_payloads(
            binaryfile_data,
            start_index=start_index,
            max_messages=max_messages,
        )
    ]
    recovered = [message.payload for message in recover_itch_payloads(frames_data)]

    if len(expected) != len(recovered):
        raise AssertionError(
            f"round-trip recovered {len(recovered)} messages, expected {len(expected)}"
        )

    for msg_index, (expected_payload, recovered_payload) in enumerate(
        zip(expected, recovered, strict=True)
    ):
        if expected_payload != recovered_payload:
            raise AssertionError(
                f"round-trip mismatch at recovered message {msg_index}: "
                f"expected {expected_payload.hex()}, got {recovered_payload.hex()}"
            )



def _build_frame_plans(
    data: ReadableBytes,
    *,
    messages_per_packet: int,
    seq_start: int,
    emit_heartbeat: bool,
    emit_eos: bool,
    start_index: int,
    max_messages: int | None,
) -> list[_FramePlan]:
    plans: list[_FramePlan] = []
    group: list[_SourceMessage] = []
    seq = seq_start
    source_frame_index = 0

    for msg_index, payload in iter_binaryfile_payloads(
        data,
        start_index=start_index,
        max_messages=max_messages,
    ):
        group.append(_SourceMessage(msg_index=msg_index, payload=bytes(payload)))
        if len(group) == messages_per_packet:
            plans.append(
                _data_plan(
                    source_frame_index=source_frame_index,
                    seq=seq,
                    messages=tuple(group),
                )
            )
            seq += len(group)
            source_frame_index += 1
            group = []

    if group:
        plans.append(
            _data_plan(
                source_frame_index=source_frame_index,
                seq=seq,
                messages=tuple(group),
            )
        )
        seq += len(group)

    if emit_heartbeat:
        plans.append(
            _FramePlan(
                source_frame_index=None,
                seq=seq,
                count=0,
                messages=(),
                heartbeat=True,
            )
        )

    if emit_eos:
        plans.append(
            _FramePlan(
                source_frame_index=None,
                seq=seq,
                count=_MOLD_EOS_COUNT,
                messages=(),
                eos=True,
            )
        )

    return plans



def _data_plan(
    *,
    source_frame_index: int,
    seq: int,
    messages: tuple[_SourceMessage, ...],
) -> _FramePlan:
    return _FramePlan(
        source_frame_index=source_frame_index,
        seq=seq,
        count=len(messages),
        messages=messages,
    )



def _replace_feed(plan: _FramePlan, *, feed: str, duplicate_of: int | None) -> _FramePlan:
    return _FramePlan(
        source_frame_index=plan.source_frame_index,
        seq=plan.seq,
        count=plan.count,
        messages=plan.messages,
        heartbeat=plan.heartbeat,
        eos=plan.eos,
        feed=feed,
        duplicate_of=duplicate_of,
    )



def _build_wire_frame(
    plan: _FramePlan,
    *,
    session: bytes,
    src_port: int,
    dst_port: int,
) -> bytes:
    mold_payload = _build_mold_payload(plan, session=session)
    udp_payload_len = _UDP_HEADER_LEN + len(mold_payload)
    ip_total_len = _IPV4_HEADER_LEN + udp_payload_len

    ethernet_header = _DST_MAC + _SRC_MAC + _uint(_ETHERTYPE_IPV4, 2, "ethertype")
    ipv4_header = (
        bytes([0x45, 0x00])
        + _uint(ip_total_len, 2, "ip_total_len")
        + _uint(0, 2, "ip_identification")
        + _uint(0, 2, "ip_flags_fragment")
        + bytes([64, _IP_PROTOCOL_UDP])
        + _uint(0, 2, "ip_checksum")
        + _SRC_IP
        + _DST_IP
    )
    udp_header = (
        _uint(src_port, 2, "src_port")
        + _uint(dst_port, 2, "dst_port")
        + _uint(udp_payload_len, 2, "udp_len")
        + _uint(0, 2, "udp_checksum")
    )
    return ethernet_header + ipv4_header + udp_header + mold_payload



def _build_mold_payload(plan: _FramePlan, *, session: bytes) -> bytes:
    payload = bytearray()
    payload += session
    payload += _uint(plan.seq, 8, "mold_seq")
    payload += _uint(plan.count, 2, "mold_count")

    if plan.heartbeat or plan.eos:
        return bytes(payload)

    for message in plan.messages:
        payload += _uint(len(message.payload), 2, "itch_payload_len")
        payload += message.payload
    return bytes(payload)



def _write_frame(
    frames_out: BinaryIO,
    meta_out: TextIO,
    frame_index: int,
    plan: _FramePlan,
    frame: bytes,
    src_port: int,
    dst_port: int,
) -> None:
    frames_out.write(frame)
    _write_jsonl(
        meta_out,
        {
            "frame_index": frame_index,
            "source_frame_index": plan.source_frame_index,
            "seq": plan.seq,
            "count": plan.count,
            "expected_next": plan.expected_next,
            "message_indices": [message.msg_index for message in plan.messages],
            "payload_lengths": [len(message.payload) for message in plan.messages],
            "heartbeat": plan.heartbeat,
            "eos": plan.eos,
            "duplicate_of": plan.duplicate_of,
            "feed": plan.feed,
            "frame_length": len(frame),
            "src_port": src_port,
            "dst_port": dst_port,
        },
    )



def _iter_ethernet_frames(data: ReadableBytes) -> Iterator[memoryview]:
    view = memoryview(data)
    cursor = 0
    while cursor < len(view):
        if len(view) - cursor < _ETH_HEADER_LEN + _IPV4_HEADER_LEN:
            raise NetworkEncapsulationError(
                f"truncated Ethernet frame at byte offset {cursor}"
            )

        ip_offset = cursor + _ETH_HEADER_LEN
        ihl = (view[ip_offset] & 0x0F) * 4
        if ihl < _IPV4_HEADER_LEN:
            raise NetworkEncapsulationError(
                f"frame at byte offset {cursor}: invalid IPv4 IHL {ihl}"
            )
        if len(view) - cursor < _ETH_HEADER_LEN + ihl:
            raise NetworkEncapsulationError(
                f"frame at byte offset {cursor}: truncated IPv4 header"
            )

        total_len = int.from_bytes(view[ip_offset + 2 : ip_offset + 4], "big")
        frame_len = _ETH_HEADER_LEN + total_len
        if total_len < ihl + _UDP_HEADER_LEN:
            raise NetworkEncapsulationError(
                f"frame at byte offset {cursor}: invalid IPv4 total length {total_len}"
            )
        if cursor + frame_len > len(view):
            raise NetworkEncapsulationError(
                f"frame at byte offset {cursor}: length {frame_len} exceeds stream"
            )

        yield view[cursor : cursor + frame_len]
        cursor += frame_len



def _extract_udp_payload(frame: memoryview, *, frame_index: int) -> memoryview:
    if int.from_bytes(frame[12:14], "big") != _ETHERTYPE_IPV4:
        raise NetworkEncapsulationError(f"frame {frame_index}: expected IPv4 EtherType")

    ip_offset = _ETH_HEADER_LEN
    version = frame[ip_offset] >> 4
    ihl = (frame[ip_offset] & 0x0F) * 4
    if version != 4:
        raise NetworkEncapsulationError(f"frame {frame_index}: expected IPv4")
    if frame[ip_offset + 9] != _IP_PROTOCOL_UDP:
        raise NetworkEncapsulationError(f"frame {frame_index}: expected UDP")

    udp_offset = ip_offset + ihl
    udp_len = int.from_bytes(frame[udp_offset + 4 : udp_offset + 6], "big")
    if udp_len < _UDP_HEADER_LEN:
        raise NetworkEncapsulationError(f"frame {frame_index}: invalid UDP length")

    payload_start = udp_offset + _UDP_HEADER_LEN
    payload_end = udp_offset + udp_len
    if payload_end > len(frame):
        raise NetworkEncapsulationError(f"frame {frame_index}: truncated UDP payload")
    return frame[payload_start:payload_end]



def _iter_mold_messages(
    payload: memoryview,
    *,
    frame_index: int,
) -> Iterator[RecoveredMessage]:
    if len(payload) < _MOLD_HEADER_LEN:
        raise NetworkEncapsulationError(f"frame {frame_index}: truncated MoldUDP64 header")

    seq = int.from_bytes(payload[10:18], "big")
    count = int.from_bytes(payload[18:20], "big")
    if count in (0, _MOLD_EOS_COUNT):
        return

    cursor = _MOLD_HEADER_LEN
    for message_number in range(count):
        if len(payload) - cursor < 2:
            raise NetworkEncapsulationError(
                f"frame {frame_index}: truncated MoldUDP64 message length"
            )
        message_len = int.from_bytes(payload[cursor : cursor + 2], "big")
        cursor += 2
        message_end = cursor + message_len
        if message_end > len(payload):
            raise NetworkEncapsulationError(
                f"frame {frame_index}: truncated MoldUDP64 message payload"
            )
        yield RecoveredMessage(
            frame_index=frame_index,
            seq=seq,
            message_number=message_number,
            payload=payload[cursor:message_end].tobytes(),
        )
        cursor = message_end

    if cursor != len(payload):
        raise NetworkEncapsulationError(
            f"frame {frame_index}: {len(payload) - cursor} trailing MoldUDP64 byte(s)"
        )



def _encode_session(session: str) -> bytes:
    encoded = session.encode("ascii")
    if len(encoded) > _MOLD_SESSION_LEN:
        raise ValueError("MoldUDP64 session must be at most 10 ASCII bytes")
    return encoded.ljust(_MOLD_SESSION_LEN, b" ")



def _uint(value: int, length: int, name: str) -> bytes:
    if value < 0 or value >= 1 << (8 * length):
        raise ValueError(f"{name}={value} does not fit in {length} byte(s)")
    return value.to_bytes(length, byteorder="big")



def _write_jsonl(handle: TextIO, record: dict[str, object]) -> None:
    handle.write(json.dumps(record, sort_keys=True, separators=(",", ":")))
    handle.write("\n")



def _validate_packet_options(
    *,
    messages_per_packet: int,
    seq_start: int,
    src_port: int,
    dst_port: int,
    duplicate_frame: int | None,
    drop_frame: int | None,
) -> None:
    if not 1 <= messages_per_packet < _MOLD_EOS_COUNT:
        raise ValueError("messages_per_packet must be in the range 1..65534")
    if not 0 <= seq_start < 1 << 64:
        raise ValueError("seq_start must fit in a MoldUDP64 64-bit sequence field")
    if not 1 <= src_port <= 0xFFFF:
        raise ValueError("src_port must be in the range 1..65535")
    if not 1 <= dst_port <= 0xFFFF:
        raise ValueError("dst_port must be in the range 1..65535")
    if duplicate_frame is not None and duplicate_frame < 0:
        raise ValueError("duplicate_frame must be non-negative")
    if drop_frame is not None and drop_frame < 0:
        raise ValueError("drop_frame must be non-negative")
    if duplicate_frame is not None and duplicate_frame == drop_frame:
        raise ValueError("cannot duplicate and drop the same source frame")



def _validate_requested_frame_indices(
    plans: list[_FramePlan], *, duplicate_frame: int | None, drop_frame: int | None
) -> None:
    data_frame_indices = {
        plan.source_frame_index for plan in plans if plan.source_frame_index is not None
    }
    if duplicate_frame is not None and duplicate_frame not in data_frame_indices:
        raise ValueError(f"duplicate_frame {duplicate_frame} does not exist")
    if drop_frame is not None and drop_frame not in data_frame_indices:
        raise ValueError(f"drop_frame {drop_frame} does not exist")



def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Wrap ITCH BinaryFILE records into Ethernet/IP/UDP/MoldUDP64 frames."
    )
    parser.add_argument("input", type=Path, help="input ITCH BinaryFILE path")
    parser.add_argument(
        "--frames-out",
        type=Path,
        default=Path("build/network/frames.bin"),
        help="raw Ethernet frame byte stream output path",
    )
    parser.add_argument(
        "--meta-out",
        type=Path,
        default=Path("build/network/frames.jsonl"),
        help="JSONL frame metadata output path",
    )
    parser.add_argument(
        "--messages-per-packet",
        type=int,
        default=3,
        help="number of ITCH messages per MoldUDP64 packet",
    )
    parser.add_argument(
        "--seq-start",
        type=int,
        default=1,
        help="MoldUDP64 sequence number for the first ITCH message",
    )
    parser.add_argument(
        "--session",
        type=str,
        default="SESSION1",
        help="MoldUDP64 session string, padded to 10 ASCII bytes",
    )
    parser.add_argument("--src-port", type=int, default=40_000, help="UDP source port")
    parser.add_argument("--dst-port", type=int, default=26_400, help="UDP destination port")
    parser.add_argument(
        "--emit-heartbeat",
        action="store_true",
        help="append a MoldUDP64 heartbeat packet with count=0",
    )
    parser.add_argument(
        "--emit-eos",
        action="store_true",
        help="append a MoldUDP64 end-of-session packet with count=0xffff",
    )
    parser.add_argument(
        "--duplicate-frame",
        type=int,
        default=None,
        help="duplicate one source data frame index",
    )
    parser.add_argument(
        "--drop-frame",
        type=int,
        default=None,
        help="drop one source data frame index before writing outputs",
    )
    parser.add_argument(
        "--ab-duplicate",
        action="store_true",
        help="emit a B-feed duplicate after every A-feed data frame",
    )
    parser.add_argument(
        "--start-index",
        type=int,
        default=0,
        help="msg_index assigned to the first source BinaryFILE record",
    )
    parser.add_argument(
        "--max-messages",
        type=int,
        default=None,
        help="maximum source BinaryFILE records to read",
    )
    parser.add_argument(
        "--check-roundtrip",
        action="store_true",
        help="de-encapsulate frames.bin and compare recovered payloads to BinaryFILE",
    )
    return parser.parse_args()



def main() -> None:
    args = _parse_args()
    if args.check_roundtrip and (
        args.duplicate_frame is not None or args.drop_frame is not None or args.ab_duplicate
    ):
        raise ValueError(
            "--check-roundtrip expects a non-destructive stream; do not combine it "
            "with --duplicate-frame, --drop-frame, or --ab-duplicate"
        )

    stats = encapsulate_file(
        args.input,
        frames_out=args.frames_out,
        meta_out=args.meta_out,
        messages_per_packet=args.messages_per_packet,
        seq_start=args.seq_start,
        session=args.session,
        src_port=args.src_port,
        dst_port=args.dst_port,
        emit_heartbeat=args.emit_heartbeat,
        emit_eos=args.emit_eos,
        duplicate_frame=args.duplicate_frame,
        drop_frame=args.drop_frame,
        ab_duplicate=args.ab_duplicate,
        start_index=args.start_index,
        max_messages=args.max_messages,
    )

    if args.check_roundtrip:
        assert_roundtrip(
            args.input.read_bytes(),
            args.frames_out.read_bytes(),
            start_index=args.start_index,
            max_messages=args.max_messages,
        )

    print(
        "wrote "
        f"{stats.frames_written} frames "
        f"({stats.data_frames_written} data frames), "
        f"{stats.messages_written} encapsulated messages "
        f"from {stats.source_messages_seen} source messages; "
        f"frames_dropped={stats.frames_dropped}; "
        f"final_seq={stats.final_seq}; "
        f"frames_out={args.frames_out}; "
        f"meta_out={args.meta_out}"
    )



if __name__ == "__main__":
    main()
