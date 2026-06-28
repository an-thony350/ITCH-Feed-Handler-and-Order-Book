from __future__ import annotations

import unittest

from golden.contracts import Bbo, Level, NormalisedEvent, Op, Side
from golden.itch_parser import parse_itch_stream
from golden.order_book import OrderBook


def add(
    *,
    msg_index: int,
    order_ref: int,
    side: Side,
    price: int,
    shares: int,
    locate: int = 1,
) -> NormalisedEvent:
    return NormalisedEvent(
        op=Op.ADD,
        locate=locate,
        side=side,
        order_ref=order_ref,
        msg_index=msg_index,
        price=price,
        shares=shares,
    )


def execute(
    *,
    msg_index: int,
    order_ref: int,
    shares: int,
    locate: int = 1,
) -> NormalisedEvent:
    return NormalisedEvent(
        op=Op.EXECUTE,
        locate=locate,
        side=Side.UNKNOWN,
        order_ref=order_ref,
        msg_index=msg_index,
        shares=shares,
    )


def cancel(
    *,
    msg_index: int,
    order_ref: int,
    shares: int,
    locate: int = 1,
) -> NormalisedEvent:
    return NormalisedEvent(
        op=Op.CANCEL,
        locate=locate,
        side=Side.UNKNOWN,
        order_ref=order_ref,
        msg_index=msg_index,
        shares=shares,
    )


def delete(
    *,
    msg_index: int,
    order_ref: int,
    locate: int = 1,
) -> NormalisedEvent:
    return NormalisedEvent(
        op=Op.DELETE,
        locate=locate,
        side=Side.UNKNOWN,
        order_ref=order_ref,
        msg_index=msg_index,
    )


def replace_order(
    *,
    msg_index: int,
    order_ref: int,
    new_order_ref: int,
    price: int,
    shares: int,
    locate: int = 1,
) -> NormalisedEvent:
    return NormalisedEvent(
        op=Op.REPLACE,
        locate=locate,
        side=Side.UNKNOWN,
        order_ref=order_ref,
        msg_index=msg_index,
        new_order_ref=new_order_ref,
        price=price,
        shares=shares,
    )


def uint(value: int, length: int) -> bytes:
    return value.to_bytes(length, byteorder="big")


def common_message(
    message_type: str,
    *,
    locate: int = 1,
    timestamp: int,
    order_ref: int,
) -> bytes:
    return (
        message_type.encode("ascii")
        + uint(locate, 2)
        + uint(7, 2)
        + uint(timestamp, 6)
        + uint(order_ref, 8)
    )


def add_message(
    message_type: str = "A",
    *,
    locate: int = 1,
    timestamp: int,
    order_ref: int,
    side: bytes,
    shares: int,
    price: int,
) -> bytes:
    message = (
        common_message(
            message_type,
            locate=locate,
            timestamp=timestamp,
            order_ref=order_ref,
        )
        + side
        + uint(shares, 4)
        + b"MSFT    "
        + uint(price, 4)
    )
    if message_type == "F":
        message += b"NSDQ"
    return message


def execute_message(
    message_type: str = "E",
    *,
    locate: int = 1,
    timestamp: int,
    order_ref: int,
    shares: int,
) -> bytes:
    message = (
        common_message(
            message_type,
            locate=locate,
            timestamp=timestamp,
            order_ref=order_ref,
        )
        + uint(shares, 4)
        + uint(9001, 8)
    )
    if message_type == "C":
        message += b"Y" + uint(10_020, 4)
    return message


def cancel_message(
    *,
    locate: int = 1,
    timestamp: int,
    order_ref: int,
    shares: int,
) -> bytes:
    return common_message(
        "X",
        locate=locate,
        timestamp=timestamp,
        order_ref=order_ref,
    ) + uint(shares, 4)


def replace_message(
    *,
    locate: int = 1,
    timestamp: int,
    order_ref: int,
    new_order_ref: int,
    shares: int,
    price: int,
) -> bytes:
    return (
        common_message(
            "U",
            locate=locate,
            timestamp=timestamp,
            order_ref=order_ref,
        )
        + uint(new_order_ref, 8)
        + uint(shares, 4)
        + uint(price, 4)
    )


def framed(message: bytes) -> bytes:
    return uint(len(message), 2) + message


def assert_book_invariants(test: unittest.TestCase, book: OrderBook) -> None:
    bid_totals: dict[int, tuple[int, int]] = {}
    ask_totals: dict[int, tuple[int, int]] = {}

    for record in book.order_table.values():
        totals = bid_totals if record.side is Side.BUY else ask_totals
        shares, count = totals.get(record.price, (0, 0))
        totals[record.price] = shares + record.shares, count + 1

    test.assertEqual(
        book.bid_levels,
        {
            price: Level(shares=shares, order_count=count)
            for price, (shares, count) in bid_totals.items()
        },
    )
    test.assertEqual(
        book.ask_levels,
        {
            price: Level(shares=shares, order_count=count)
            for price, (shares, count) in ask_totals.items()
        },
    )
    for levels in (book.bid_levels, book.ask_levels):
        for level in levels.values():
            test.assertGreater(level.shares, 0)
            test.assertGreater(level.order_count, 0)


class OrderBookTests(unittest.TestCase):
    def test_empty_book_has_empty_bbo_and_empty_levels(self) -> None:
        state = OrderBook().snapshot(msg_index=0)

        self.assertEqual(state.bbo, Bbo(None, None, None, None))
        self.assertEqual(state.bid_levels, {})
        self.assertEqual(state.ask_levels, {})

    def test_adds_orders_aggregates_levels_and_recomputes_bbo(self) -> None:
        book = OrderBook()

        book.apply(
            add(
                msg_index=0,
                order_ref=1001,
                side=Side.BUY,
                price=10_000,
                shares=20,
            )
        )
        book.apply(
            add(
                msg_index=1,
                order_ref=1002,
                side=Side.BUY,
                price=10_000,
                shares=5,
            )
        )
        book.apply(
            add(
                msg_index=2,
                order_ref=1003,
                side=Side.SELL,
                price=10_500,
                shares=9,
            )
        )
        book.apply(
            add(
                msg_index=3,
                order_ref=1004,
                side=Side.SELL,
                price=10_300,
                shares=7,
            )
        )

        state = book.snapshot(msg_index=3)

        self.assertEqual(state.bid_levels, {10_000: Level(shares=25, order_count=2)})
        self.assertEqual(
            state.ask_levels,
            {
                10_300: Level(shares=7, order_count=1),
                10_500: Level(shares=9, order_count=1),
            },
        )
        self.assertEqual(
            state.bbo,
            Bbo(bid_price=10_000, bid_size=25, ask_price=10_300, ask_size=7),
        )
        assert_book_invariants(self, book)

    def test_crossed_and_locked_books_keep_independent_best_prices(self) -> None:
        book = OrderBook()

        book.apply(
            add(
                msg_index=0,
                order_ref=1001,
                side=Side.BUY,
                price=10_000,
                shares=20,
            )
        )
        book.apply(
            add(
                msg_index=1,
                order_ref=1002,
                side=Side.SELL,
                price=10_000,
                shares=5,
            )
        )
        self.assertEqual(
            book.bbo(),
            Bbo(bid_price=10_000, bid_size=20, ask_price=10_000, ask_size=5),
        )

        book.apply(
            add(
                msg_index=2,
                order_ref=1003,
                side=Side.BUY,
                price=10_010,
                shares=7,
            )
        )
        self.assertEqual(
            book.bbo(),
            Bbo(bid_price=10_010, bid_size=7, ask_price=10_000, ask_size=5),
        )
        assert_book_invariants(self, book)

    def test_duplicate_add_order_ref_asserts_with_msg_index(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1001,
                side=Side.BUY,
                price=10_000,
                shares=20,
            )
        )

        with self.assertRaisesRegex(AssertionError, "msg_index=4.*1001"):
            book.apply(
                add(
                    msg_index=4,
                    order_ref=1001,
                    side=Side.SELL,
                    price=10_200,
                    shares=3,
                )
            )

    def test_snapshot_copies_level_dicts(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1001,
                side=Side.BUY,
                price=10_000,
                shares=20,
            )
        )
        before = book.snapshot(msg_index=0)

        book.apply(
            add(
                msg_index=1,
                order_ref=1002,
                side=Side.BUY,
                price=10_000,
                shares=5,
            )
        )
        after = book.snapshot(msg_index=1)

        self.assertIsNot(before.bid_levels, book.bid_levels)
        self.assertEqual(before.bid_levels, {10_000: Level(shares=20, order_count=1)})
        self.assertEqual(after.bid_levels, {10_000: Level(shares=25, order_count=2)})

    def test_expected_locate_asserts_with_msg_index(self) -> None:
        book = OrderBook(expected_locate=7)

        with self.assertRaisesRegex(AssertionError, "msg_index=0.*unexpected locate"):
            book.apply(
                add(
                    msg_index=0,
                    order_ref=1001,
                    side=Side.BUY,
                    price=10_000,
                    shares=20,
                    locate=8,
                )
            )

    def test_partial_execute_updates_table_before_second_execute(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1,
                side=Side.BUY,
                price=5_000,
                shares=100,
            )
        )

        book.apply(execute(msg_index=1, order_ref=1, shares=30))
        self.assertEqual(book.bid_levels, {5_000: Level(shares=70, order_count=1)})
        self.assertEqual(
            book.bbo(),
            Bbo(bid_price=5_000, bid_size=70, ask_price=None, ask_size=None),
        )
        self.assertEqual(book.order_table[1].shares, 70)
        assert_book_invariants(self, book)

        book.apply(execute(msg_index=2, order_ref=1, shares=70))
        self.assertEqual(book.bid_levels, {})
        self.assertNotIn(1, book.order_table)
        self.assertEqual(book.bbo(), Bbo(None, None, None, None))
        assert_book_invariants(self, book)

    def test_full_execute_best_level_drops_bbo_to_next_level(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1,
                side=Side.BUY,
                price=5_000,
                shares=100,
            )
        )
        book.apply(
            add(
                msg_index=1,
                order_ref=2,
                side=Side.BUY,
                price=4_999,
                shares=200,
            )
        )

        book.apply(execute(msg_index=2, order_ref=1, shares=100))

        self.assertEqual(book.bid_levels, {4_999: Level(shares=200, order_count=1)})
        self.assertEqual(
            book.bbo(),
            Bbo(bid_price=4_999, bid_size=200, ask_price=None, ask_size=None),
        )
        assert_book_invariants(self, book)

    def test_cancel_to_zero_removes_order_and_empty_level(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1,
                side=Side.SELL,
                price=5_005,
                shares=50,
            )
        )

        book.apply(cancel(msg_index=1, order_ref=1, shares=50))

        self.assertEqual(book.ask_levels, {})
        self.assertNotIn(1, book.order_table)
        self.assertEqual(book.bbo(), Bbo(None, None, None, None))
        assert_book_invariants(self, book)

    def test_delete_removes_empty_level_and_bbo_drops_to_next_best_bid(self) -> None:
        book = OrderBook()

        book.apply(
            add(
                msg_index=0,
                order_ref=1001,
                side=Side.BUY,
                price=10_100,
                shares=20,
            )
        )
        book.apply(
            add(
                msg_index=1,
                order_ref=1002,
                side=Side.BUY,
                price=10_000,
                shares=30,
            )
        )

        self.assertEqual(
            book.bbo(),
            Bbo(bid_price=10_100, bid_size=20, ask_price=None, ask_size=None),
        )

        book.apply(delete(msg_index=2, order_ref=1001))
        state = book.snapshot(msg_index=2)

        self.assertEqual(state.bid_levels, {10_000: Level(shares=30, order_count=1)})
        self.assertEqual(
            state.bbo,
            Bbo(bid_price=10_000, bid_size=30, ask_price=None, ask_size=None),
        )
        self.assertNotIn(1001, book.order_table)
        assert_book_invariants(self, book)

    def test_delete_unknown_order_ref_asserts_with_msg_index(self) -> None:
        book = OrderBook()

        with self.assertRaisesRegex(
            AssertionError,
            "msg_index=7.*unknown order_ref 9999",
        ):
            book.apply(delete(msg_index=7, order_ref=9999))

    def test_execute_more_than_remaining_asserts_without_mutating_book(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1,
                side=Side.BUY,
                price=5_000,
                shares=20,
            )
        )
        before = book.snapshot(msg_index=0)

        with self.assertRaisesRegex(AssertionError, "msg_index=1.*exceeds.*20"):
            book.apply(execute(msg_index=1, order_ref=1, shares=21))

        self.assertEqual(book.snapshot(msg_index=1).bid_levels, before.bid_levels)
        self.assertEqual(book.order_table[1].shares, 20)
        assert_book_invariants(self, book)

    def test_cancel_unknown_order_ref_asserts_with_msg_index(self) -> None:
        book = OrderBook()

        with self.assertRaisesRegex(AssertionError, "msg_index=3.*unknown order_ref 9"):
            book.apply(cancel(msg_index=3, order_ref=9, shares=1))

    def test_replace_captures_original_side_before_delete(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1,
                side=Side.SELL,
                price=5_005,
                shares=50,
            )
        )

        book.apply(
            replace_order(
                msg_index=1,
                order_ref=1,
                new_order_ref=2,
                price=5_004,
                shares=30,
            )
        )

        self.assertNotIn(1, book.order_table)
        self.assertEqual(book.order_table[2].side, Side.SELL)
        self.assertEqual(book.order_table[2].price, 5_004)
        self.assertEqual(book.order_table[2].shares, 30)
        self.assertEqual(book.ask_levels, {5_004: Level(shares=30, order_count=1)})
        self.assertEqual(
            book.bbo(),
            Bbo(bid_price=None, bid_size=None, ask_price=5_004, ask_size=30),
        )
        assert_book_invariants(self, book)

    def test_replace_only_order_at_same_price_keeps_level_coherent(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1,
                side=Side.BUY,
                price=5_000,
                shares=100,
            )
        )

        book.apply(
            replace_order(
                msg_index=1,
                order_ref=1,
                new_order_ref=2,
                price=5_000,
                shares=40,
            )
        )

        self.assertNotIn(1, book.order_table)
        self.assertEqual(book.order_table[2].shares, 40)
        self.assertEqual(book.bid_levels, {5_000: Level(shares=40, order_count=1)})
        self.assertEqual(
            book.bbo(),
            Bbo(bid_price=5_000, bid_size=40, ask_price=None, ask_size=None),
        )
        assert_book_invariants(self, book)

    def test_replace_same_ref_at_same_price_updates_size(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1,
                side=Side.BUY,
                price=5_000,
                shares=100,
            )
        )

        book.apply(
            replace_order(
                msg_index=1,
                order_ref=1,
                new_order_ref=1,
                price=5_000,
                shares=60,
            )
        )

        self.assertEqual(book.order_table[1].shares, 60)
        self.assertEqual(book.order_table[1].price, 5_000)
        self.assertEqual(book.bid_levels, {5_000: Level(shares=60, order_count=1)})
        assert_book_invariants(self, book)

    def test_replace_one_of_multiple_orders_at_same_price_preserves_count(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1,
                side=Side.BUY,
                price=5_000,
                shares=100,
            )
        )
        book.apply(
            add(
                msg_index=1,
                order_ref=2,
                side=Side.BUY,
                price=5_000,
                shares=200,
            )
        )

        book.apply(
            replace_order(
                msg_index=2,
                order_ref=1,
                new_order_ref=3,
                price=5_000,
                shares=40,
            )
        )

        self.assertNotIn(1, book.order_table)
        self.assertEqual(book.order_table[2].shares, 200)
        self.assertEqual(book.order_table[3].shares, 40)
        self.assertEqual(book.bid_levels, {5_000: Level(shares=240, order_count=2)})
        assert_book_invariants(self, book)

    def test_replace_to_existing_new_order_ref_asserts_without_mutating_book(self) -> None:
        book = OrderBook()
        book.apply(
            add(
                msg_index=0,
                order_ref=1,
                side=Side.BUY,
                price=5_000,
                shares=100,
            )
        )
        book.apply(
            add(
                msg_index=1,
                order_ref=2,
                side=Side.BUY,
                price=4_999,
                shares=50,
            )
        )
        before = book.snapshot(msg_index=1)

        with self.assertRaisesRegex(AssertionError, "msg_index=2.*reused new_order_ref 2"):
            book.apply(
                replace_order(
                    msg_index=2,
                    order_ref=1,
                    new_order_ref=2,
                    price=4_998,
                    shares=10,
                )
            )

        self.assertIn(1, book.order_table)
        self.assertIn(2, book.order_table)
        self.assertEqual(book.snapshot(msg_index=2).bid_levels, before.bid_levels)
        assert_book_invariants(self, book)

    def test_replace_unknown_order_ref_asserts_with_msg_index(self) -> None:
        book = OrderBook()

        with self.assertRaisesRegex(AssertionError, "msg_index=4.*unknown order_ref 99"):
            book.apply(
                replace_order(
                    msg_index=4,
                    order_ref=99,
                    new_order_ref=100,
                    price=5_000,
                    shares=10,
                )
            )

    def test_worked_trace_end_to_end(self) -> None:
        book = OrderBook()

        book.apply(
            add(
                msg_index=0,
                order_ref=1,
                side=Side.BUY,
                price=5_000,
                shares=100,
            )
        )
        book.apply(
            add(
                msg_index=1,
                order_ref=2,
                side=Side.SELL,
                price=5_005,
                shares=50,
            )
        )
        book.apply(
            add(
                msg_index=2,
                order_ref=3,
                side=Side.BUY,
                price=4_999,
                shares=200,
            )
        )
        book.apply(execute(msg_index=3, order_ref=1, shares=30))
        book.apply(delete(msg_index=4, order_ref=2))
        book.apply(execute(msg_index=5, order_ref=1, shares=70))

        state = book.snapshot(msg_index=5)
        self.assertEqual(state.bid_levels, {4_999: Level(shares=200, order_count=1)})
        self.assertEqual(state.ask_levels, {})
        self.assertEqual(
            state.bbo,
            Bbo(bid_price=4_999, bid_size=200, ask_price=None, ask_size=None),
        )
        self.assertNotIn(1, book.order_table)
        self.assertNotIn(2, book.order_table)
        assert_book_invariants(self, book)

    def test_raw_itch_stream_drives_order_book_to_expected_state(self) -> None:
        stream = b"".join(
            [
                framed(b"S" + b"\x00" * 11),
                framed(
                    add_message(
                        timestamp=100,
                        order_ref=1001,
                        side=b"B",
                        shares=100,
                        price=10_000,
                    )
                ),
                framed(
                    add_message(
                        "F",
                        timestamp=101,
                        order_ref=2001,
                        side=b"S",
                        shares=50,
                        price=10_050,
                    )
                ),
                framed(
                    add_message(
                        timestamp=102,
                        order_ref=1002,
                        side=b"B",
                        shares=200,
                        price=9_990,
                    )
                ),
                framed(execute_message(timestamp=103, order_ref=1001, shares=25)),
                framed(execute_message("C", timestamp=104, order_ref=1001, shares=75)),
                framed(cancel_message(timestamp=105, order_ref=1002, shares=50)),
                framed(
                    replace_message(
                        timestamp=106,
                        order_ref=2001,
                        new_order_ref=2002,
                        shares=30,
                        price=10_040,
                    )
                ),
            ]
        )
        events = list(parse_itch_stream(stream))
        book = OrderBook()

        for event in events:
            book.apply(event)

        state = book.snapshot(msg_index=events[-1].msg_index)
        self.assertEqual([event.msg_index for event in events], [1, 2, 3, 4, 5, 6, 7])
        self.assertEqual(state.bid_levels, {9_990: Level(shares=150, order_count=1)})
        self.assertEqual(state.ask_levels, {10_040: Level(shares=30, order_count=1)})
        self.assertEqual(
            state.bbo,
            Bbo(bid_price=9_990, bid_size=150, ask_price=10_040, ask_size=30),
        )
        self.assertNotIn(1001, book.order_table)
        self.assertNotIn(2001, book.order_table)
        self.assertEqual(book.order_table[1002].shares, 150)
        self.assertEqual(book.order_table[2002].price, 10_040)
        assert_book_invariants(self, book)


if __name__ == "__main__":
    unittest.main()
