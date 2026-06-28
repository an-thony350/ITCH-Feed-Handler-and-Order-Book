from __future__ import annotations

import unittest

from golden.contracts import Bbo, Level, Op
from golden.itch_parser import parse_itch_stream
from golden.order_book import OrderBook
from golden.stimulus import (
    default_messages,
    default_stream,
    directed_cases,
    encode_binaryfile,
    parsed_default_events,
    random_valid_messages,
)


class StimulusTests(unittest.TestCase):
    def test_directed_cases_parse_and_replay_through_book(self) -> None:
        for case in directed_cases():
            with self.subTest(case=case.name):
                events = case.events()
                states = case.states()

                self.assertGreater(len(events), 0)
                self.assertEqual(len(states), len(events))
                self.assertEqual(states[-1].msg_index, events[-1].msg_index)

    def test_lifecycle_case_preserves_source_msg_index_across_ignored_message(
        self,
    ) -> None:
        case = directed_cases()[0]

        events = case.events()

        self.assertEqual([event.msg_index for event in events[:4]], [1, 2, 3, 4])
        self.assertEqual([event.op for event in events[:4]], [Op.ADD] * 3 + [Op.EXECUTE])

    def test_lifecycle_case_reaches_expected_final_book_state(self) -> None:
        case = directed_cases()[0]

        final_state = case.states()[-1]

        self.assertEqual(final_state.bid_levels, {9_990: Level(shares=150, order_count=1)})
        self.assertEqual(final_state.ask_levels, {10_040: Level(shares=30, order_count=1)})
        self.assertEqual(
            final_state.bbo,
            Bbo(bid_price=9_990, bid_size=150, ask_price=10_040, ask_size=30),
        )

    def test_seeded_random_messages_are_deterministic(self) -> None:
        self.assertEqual(
            random_valid_messages(seed=7, message_count=50),
            random_valid_messages(seed=7, message_count=50),
        )
        self.assertNotEqual(
            random_valid_messages(seed=7, message_count=50),
            random_valid_messages(seed=8, message_count=50),
        )

    def test_default_stream_round_trips_to_events_and_book_states(self) -> None:
        messages = default_messages(seed=7, random_message_count=25)
        stream = default_stream(seed=7, random_message_count=25)

        self.assertEqual(stream, encode_binaryfile(messages))
        self.assertEqual(
            tuple(parse_itch_stream(stream)),
            parsed_default_events(seed=7, random_message_count=25),
        )

        book = OrderBook()
        events = parsed_default_events(seed=7, random_message_count=25)
        for event in events:
            book.apply(event)

        self.assertEqual(
            book.bbo(),
            Bbo(bid_price=10_000, bid_size=503, ask_price=10_005, ask_size=60),
        )


if __name__ == "__main__":
    unittest.main()
