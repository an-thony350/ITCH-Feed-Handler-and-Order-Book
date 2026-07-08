from __future__ import annotations

import io
import json
import unittest

from golden.contracts import Side
from golden.itch_parser import iter_binaryfile_payloads
from golden.network_encapsulator import (
    assert_roundtrip,
    encapsulate_bytes,
    recover_itch_payloads,
)
from golden.stimulus import add_message, encode_binaryfile, system_event


def read_jsonl(text: str) -> list[dict[str, object]]:
    return [json.loads(line) for line in text.splitlines()]


def binaryfile_payloads(stream: bytes) -> list[bytes]:
    return [bytes(payload) for _msg_index, payload in iter_binaryfile_payloads(stream)]


def make_messages(count: int) -> tuple[bytes, ...]:
    return tuple(
        add_message(
            order_ref=1000 + index,
            side=Side.BUY if index % 2 == 0 else Side.SELL,
            shares=10 + index,
            price=10_000 + index,
            timestamp_ns=100 + index,
        )
        for index in range(count)
    )


def encapsulate_to_memory(
    stream: bytes,
    **kwargs: object,
) -> tuple[object, bytes, list[dict[str, object]]]:
    frames_out = io.BytesIO()
    meta_out = io.StringIO()
    stats = encapsulate_bytes(stream, frames_out=frames_out, meta_out=meta_out, **kwargs)
    return stats, frames_out.getvalue(), read_jsonl(meta_out.getvalue())


class NetworkEncapsulatorTests(unittest.TestCase):
    def test_single_packet_roundtrip_is_byte_exact(self) -> None:
        stream = encode_binaryfile(
            (
                system_event(timestamp_ns=1),
                add_message(
                    order_ref=1001,
                    side=Side.BUY,
                    shares=100,
                    price=10_000,
                    timestamp_ns=2,
                ),
                add_message(
                    order_ref=1002,
                    side=Side.SELL,
                    shares=50,
                    price=10_020,
                    timestamp_ns=3,
                    with_mpid=True,
                ),
            )
        )

        stats, frames, meta = encapsulate_to_memory(
            stream,
            messages_per_packet=8,
            seq_start=1,
            session="ITCHSIM",
        )

        self.assertEqual(stats.source_messages_seen, 3)
        self.assertEqual(stats.frames_written, 1)
        self.assertEqual(stats.messages_written, 3)
        self.assertEqual([message.payload for message in recover_itch_payloads(frames)], binaryfile_payloads(stream))
        self.assertEqual(meta[0]["seq"], 1)
        self.assertEqual(meta[0]["count"], 3)
        self.assertEqual(meta[0]["expected_next"], 4)
        self.assertEqual(meta[0]["message_indices"], [0, 1, 2])
        assert_roundtrip(stream, frames)

    def test_multiple_packets_roundtrip_and_metadata(self) -> None:
        stream = encode_binaryfile(make_messages(5))

        stats, frames, meta = encapsulate_to_memory(
            stream,
            messages_per_packet=2,
            seq_start=7,
            session="ABCD",
        )

        self.assertEqual(stats.frames_written, 3)
        self.assertEqual(stats.data_frames_written, 3)
        self.assertEqual(stats.messages_written, 5)
        self.assertEqual(stats.final_seq, 12)
        self.assertEqual([message.payload for message in recover_itch_payloads(frames)], binaryfile_payloads(stream))
        self.assertEqual([record["seq"] for record in meta], [7, 9, 11])
        self.assertEqual([record["count"] for record in meta], [2, 2, 1])
        self.assertEqual([record["expected_next"] for record in meta], [9, 11, 12])
        self.assertEqual([record["message_indices"] for record in meta], [[0, 1], [2, 3], [4]])

    def test_heartbeat_and_eos_emit_metadata_without_payload_messages(self) -> None:
        stream = encode_binaryfile(make_messages(1))

        stats, frames, meta = encapsulate_to_memory(
            stream,
            messages_per_packet=1,
            seq_start=20,
            emit_heartbeat=True,
            emit_eos=True,
        )

        self.assertEqual(stats.frames_written, 3)
        self.assertEqual([message.payload for message in recover_itch_payloads(frames)], binaryfile_payloads(stream))
        self.assertEqual(meta[0]["heartbeat"], False)
        self.assertEqual(meta[0]["eos"], False)
        self.assertEqual(meta[1]["heartbeat"], True)
        self.assertEqual(meta[1]["eos"], False)
        self.assertEqual(meta[1]["count"], 0)
        self.assertEqual(meta[1]["seq"], 21)
        self.assertEqual(meta[1]["expected_next"], 21)
        self.assertEqual(meta[2]["heartbeat"], False)
        self.assertEqual(meta[2]["eos"], True)
        self.assertEqual(meta[2]["count"], 0xFFFF)
        self.assertEqual(meta[2]["seq"], 21)
        self.assertEqual(meta[2]["expected_next"], 21)

    def test_duplicate_frame_writes_duplicate_payload_and_metadata(self) -> None:
        stream = encode_binaryfile(make_messages(3))
        expected_payloads = binaryfile_payloads(stream)

        stats, frames, meta = encapsulate_to_memory(
            stream,
            messages_per_packet=1,
            seq_start=10,
            duplicate_frame=1,
        )

        recovered_payloads = [message.payload for message in recover_itch_payloads(frames)]
        self.assertEqual(stats.frames_written, 4)
        self.assertEqual(stats.messages_written, 4)
        self.assertEqual(
            recovered_payloads,
            [expected_payloads[0], expected_payloads[1], expected_payloads[1], expected_payloads[2]],
        )
        self.assertEqual([record["source_frame_index"] for record in meta], [0, 1, 1, 2])
        self.assertEqual([record["feed"] for record in meta], ["A", "A", "DUP", "A"])
        self.assertEqual(meta[2]["duplicate_of"], 1)
        self.assertEqual(meta[2]["seq"], meta[1]["seq"])
        self.assertEqual(meta[2]["message_indices"], meta[1]["message_indices"])

    def test_drop_frame_omits_payloads_and_preserves_gap_metadata(self) -> None:
        stream = encode_binaryfile(make_messages(5))
        expected_payloads = binaryfile_payloads(stream)

        stats, frames, meta = encapsulate_to_memory(
            stream,
            messages_per_packet=2,
            seq_start=1,
            drop_frame=1,
        )

        recovered_payloads = [message.payload for message in recover_itch_payloads(frames)]
        self.assertEqual(stats.frames_dropped, 1)
        self.assertEqual(stats.frames_written, 2)
        self.assertEqual(stats.source_messages_seen, 5)
        self.assertEqual(stats.messages_written, 3)
        self.assertEqual(recovered_payloads, [expected_payloads[0], expected_payloads[1], expected_payloads[4]])
        self.assertEqual([record["source_frame_index"] for record in meta], [0, 2])
        self.assertEqual([record["seq"] for record in meta], [1, 5])
        self.assertEqual([record["expected_next"] for record in meta], [3, 6])

    def test_ab_duplicate_writes_b_feed_after_each_a_feed_frame(self) -> None:
        stream = encode_binaryfile(make_messages(2))
        expected_payloads = binaryfile_payloads(stream)

        stats, frames, meta = encapsulate_to_memory(
            stream,
            messages_per_packet=1,
            ab_duplicate=True,
        )

        recovered_payloads = [message.payload for message in recover_itch_payloads(frames)]
        self.assertEqual(stats.frames_written, 4)
        self.assertEqual(recovered_payloads, [expected_payloads[0], expected_payloads[0], expected_payloads[1], expected_payloads[1]])
        self.assertEqual([record["feed"] for record in meta], ["A", "B", "A", "B"])
        self.assertEqual([record["duplicate_of"] for record in meta], [None, 0, None, 1])
        self.assertEqual(meta[1]["seq"], meta[0]["seq"])
        self.assertEqual(meta[3]["seq"], meta[2]["seq"])

    def test_fixed_headers_match_current_rtl_assumptions(self) -> None:
        stream = encode_binaryfile(make_messages(1))

        _stats, frames, meta = encapsulate_to_memory(
            stream,
            messages_per_packet=1,
            seq_start=42,
            session="ABC",
            src_port=12_345,
            dst_port=26_400,
        )

        self.assertEqual(len(frames), meta[0]["frame_length"])
        self.assertEqual(frames[0:6], bytes.fromhex("02 00 00 00 00 02"))
        self.assertEqual(frames[6:12], bytes.fromhex("02 00 00 00 00 01"))
        self.assertEqual(frames[12:14], b"\x08\x00")

        ip_offset = 14
        udp_offset = ip_offset + 20
        mold_offset = udp_offset + 8
        ip_total_len = int.from_bytes(frames[ip_offset + 2 : ip_offset + 4], "big")
        udp_len = int.from_bytes(frames[udp_offset + 4 : udp_offset + 6], "big")

        self.assertEqual(frames[ip_offset], 0x45)          # IPv4, IHL=5
        self.assertEqual(frames[ip_offset + 6 : ip_offset + 8], b"\x00\x00")
        self.assertEqual(frames[ip_offset + 8], 64)        # TTL
        self.assertEqual(frames[ip_offset + 9], 17)        # UDP
        self.assertEqual(frames[ip_offset + 10 : ip_offset + 12], b"\x00\x00")
        self.assertEqual(frames[ip_offset + 12 : ip_offset + 16], bytes([10, 0, 0, 1]))
        self.assertEqual(frames[ip_offset + 16 : ip_offset + 20], bytes([10, 0, 0, 2]))
        self.assertEqual(ip_total_len, len(frames) - 14)

        self.assertEqual(int.from_bytes(frames[udp_offset : udp_offset + 2], "big"), 12_345)
        self.assertEqual(int.from_bytes(frames[udp_offset + 2 : udp_offset + 4], "big"), 26_400)
        self.assertEqual(frames[udp_offset + 6 : udp_offset + 8], b"\x00\x00")
        self.assertEqual(udp_len, len(frames) - udp_offset)

        self.assertEqual(frames[mold_offset : mold_offset + 10], b"ABC       ")
        self.assertEqual(int.from_bytes(frames[mold_offset + 10 : mold_offset + 18], "big"), 42)
        self.assertEqual(int.from_bytes(frames[mold_offset + 18 : mold_offset + 20], "big"), 1)


if __name__ == "__main__":
    unittest.main()
