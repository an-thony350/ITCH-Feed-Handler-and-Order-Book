from __future__ import annotations

import unittest

from golden.contracts import Bbo, Level, NormalisedEvent, Op, Side
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


class OrderBookStage1Tests(unittest.TestCase):
    def test_empty_book_has_empty_bbo_and_empty_levels(self) -> None:
        state = OrderBook().snapshot(msg_index=0)

        self.assertEqual(state.bbo, Bbo(None, None, None, None))
        self.assertEqual(state.bid_levels, {})
        self.assertEqual(state.ask_levels, {})

    def test_adds_orders_aggregates_levels_and_recomputes_bbo(self) -> None:
        book = OrderBook()

        book.apply(add(msg_index=0, order_ref=1001, side=Side.BUY, price=10_000, shares=20))
        book.apply(add(msg_index=1, order_ref=1002, side=Side.BUY, price=10_000, shares=5))
        book.apply(add(msg_index=2, order_ref=1003, side=Side.SELL, price=10_500, shares=9))
        book.apply(add(msg_index=3, order_ref=1004, side=Side.SELL, price=10_300, shares=7))

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

    def test_duplicate_add_order_ref_asserts_with_msg_index(self) -> None:
        book = OrderBook()
        book.apply(add(msg_index=0, order_ref=1001, side=Side.BUY, price=10_000, shares=20))

        with self.assertRaisesRegex(AssertionError, "msg_index=4.*1001"):
            book.apply(
                add(msg_index=4, order_ref=1001, side=Side.SELL, price=10_200, shares=3)
            )

    def test_snapshot_copies_level_dicts(self) -> None:
        book = OrderBook()
        book.apply(add(msg_index=0, order_ref=1001, side=Side.BUY, price=10_000, shares=20))
        before = book.snapshot(msg_index=0)

        book.apply(add(msg_index=1, order_ref=1002, side=Side.BUY, price=10_000, shares=5))
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


if __name__ == "__main__":
    unittest.main()
