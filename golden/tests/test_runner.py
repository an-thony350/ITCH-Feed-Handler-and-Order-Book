from __future__ import annotations

import io
import json
import tempfile
import unittest
from pathlib import Path

from golden.contracts import Bbo, Side
from golden.runner import iter_itch_events, run_bytes, run_file
from golden.stimulus import add_message, default_stream, encode_binaryfile, system_event


def read_jsonl(path: Path) -> list[dict[str, object]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]


def parse_jsonl(text: str) -> list[dict[str, object]]:
    return [json.loads(line) for line in text.splitlines()]


class RunnerTests(unittest.TestCase):
    def test_run_file_writes_event_and_state_jsonl_oracles(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            input_path = temp_path / "synthetic.bin"
            events_path = temp_path / "events.jsonl"
            states_path = temp_path / "states.jsonl"
            input_path.write_bytes(default_stream(seed=7, random_message_count=25))

            stats = run_file(
                input_path,
                events_out=events_path,
                states_out=states_path,
            )

            events = read_jsonl(events_path)
            states = read_jsonl(states_path)
            self.assertEqual(stats.source_messages_seen, 42)
            self.assertEqual(stats.events_written, 41)
            self.assertEqual(stats.states_written, 41)
            self.assertEqual(stats.final_msg_index, 41)
            self.assertEqual(stats.final_bbo, Bbo(10_000, 503, 10_005, 60))
            self.assertEqual(events[0]["msg_index"], 1)
            self.assertEqual(events[0]["op"], "ADD")
            self.assertEqual(events[0]["price"], 10_000)
            self.assertEqual(states[-1]["bbo"]["bid_price"], 10_000)
            self.assertEqual(states[-1]["bbo"]["ask_price"], 10_005)

    def test_run_bytes_preserves_msg_index_after_ignored_messages(self) -> None:
        stream = encode_binaryfile(
            (
                system_event(timestamp_ns=10),
                add_message(
                    timestamp_ns=11,
                    order_ref=1001,
                    side=Side.BUY,
                    shares=20,
                    price=10_000,
                ),
            )
        )
        events_out = io.StringIO()
        states_out = io.StringIO()

        stats = run_bytes(stream, events_out=events_out, states_out=states_out)

        events = parse_jsonl(events_out.getvalue())
        states = parse_jsonl(states_out.getvalue())
        self.assertEqual(stats.source_messages_seen, 2)
        self.assertEqual(stats.events_written, 1)
        self.assertEqual(events[0]["msg_index"], 1)
        self.assertEqual(states[0]["msg_index"], 1)

    def test_locate_filter_skips_other_symbols(self) -> None:
        stream = encode_binaryfile(
            (
                add_message(
                    locate=1,
                    timestamp_ns=10,
                    order_ref=1001,
                    side=Side.BUY,
                    shares=20,
                    price=10_000,
                ),
                add_message(
                    locate=2,
                    timestamp_ns=11,
                    order_ref=2001,
                    side=Side.SELL,
                    shares=30,
                    price=10_100,
                ),
            )
        )
        events_out = io.StringIO()
        states_out = io.StringIO()

        stats = run_bytes(
            stream,
            events_out=events_out,
            states_out=states_out,
            locate=2,
        )

        events = parse_jsonl(events_out.getvalue())
        states = parse_jsonl(states_out.getvalue())
        self.assertEqual(stats.source_messages_seen, 2)
        self.assertEqual(stats.events_written, 1)
        self.assertEqual(events[0]["locate"], 2)
        self.assertEqual(events[0]["msg_index"], 1)
        self.assertEqual(states[0]["bbo"], {
            "ask_price": 10_100,
            "ask_size": 30,
            "bid_price": None,
            "bid_size": None,
        })

    def test_max_messages_limits_source_records_including_ignored_messages(self) -> None:
        events = tuple(
            iter_itch_events(
                default_stream(seed=7, random_message_count=25),
                max_messages=2,
            )
        )

        self.assertEqual(len(events), 1)
        self.assertEqual(events[0].msg_index, 1)

    def test_max_events_stops_after_requested_number_of_book_events(self) -> None:
        events_out = io.StringIO()
        states_out = io.StringIO()

        stats = run_bytes(
            default_stream(seed=7, random_message_count=25),
            events_out=events_out,
            states_out=states_out,
            max_events=3,
        )

        events = parse_jsonl(events_out.getvalue())
        states = parse_jsonl(states_out.getvalue())
        self.assertEqual(stats.source_messages_seen, 4)
        self.assertEqual(stats.events_written, 3)
        self.assertEqual([event["msg_index"] for event in events], [1, 2, 3])
        self.assertEqual(states[-1]["msg_index"], 3)


if __name__ == "__main__":
    unittest.main()
