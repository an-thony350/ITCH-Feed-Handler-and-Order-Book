from __future__ import annotations

import unittest

from golden.contracts import Bbo, Level, NormalisedEvent, Op, Side
from golden.order_book import OrderBook


def add(*, msg_index: int, order_ref: int, side: Side, price: int, shares: int, locate: int = 1) -> NormalisedEvent:
    return NormalisedEvent(
        op=Op.ADD,
        locate=locate,
        side=side,
        order_ref=order_ref,
        msg_index=msg_index,
        price=price,
        shares=shares,
    )


def execute(*, msg_index: int, order_ref: int, shares: int, locate: int = 1) -> NormalisedEvent:
    return NormalisedEvent(
        op=Op.EXECUTE,
        locate=locate,
        side=Side.UNKNOWN,
        order_ref=order_ref,
        msg_index=msg_index,
        shares=shares,
    )


def cancel(*, msg_index: int, order_ref: int, shares: int, locate: int = 1) -> NormalisedEvent:
    return NormalisedEvent(
        op=Op.CANCEL,
        locate=locate,
        side=Side.UNKNOWN,
        order_ref=order_ref,
        msg_index=msg_index,
        shares=shares,
    )


def delete(*, msg_index: int, order_ref: int, locate: int = 1) -> NormalisedEvent:
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


class OrderBookTests(unittest.TestCase):
    def test_adds_aggregate_price_levels_and_bbo(self) -> None:
        book = OrderBook()

        book.apply(add(msg_index=0, order_ref=1, side=Side.BUY, price=10_000, shares=100))
        book.apply(add(msg_index=1, order_ref=2, side=Side.BUY, price=10_000, shares=50))
        book.apply(add(msg_index=2, order_ref=3, side=Side.SELL, price=10_050, shares=20))

        self.assertEqual(book.bid_levels, {10_000: Level(shares=150, order_count=2)})
        self.assertEqual(book.ask_levels, {10_050: Level(shares=20, order_count=1)})
        self.assertEqual(
            book.bbo(),
            Bbo(bid_price=10_000, bid_size=150, ask_price=10_050, ask_size=20),
        )

    def test_partial_and_full_execute_updates_order_and_level(self) -> None:
        book = OrderBook()
        book.apply(add(msg_index=0, order_ref=1, side=Side.BUY, price=10_000, shares=100))

        book.apply(execute(msg_index=1, order_ref=1, shares=40))
        self.assertEqual(book.order_table[1].shares, 60)
        self.assertEqual(book.bid_levels, {10_000: Level(shares=60, order_count=1)})

        book.apply(execute(msg_index=2, order_ref=1, shares=60))
        self.assertNotIn(1, book.order_table)
        self.assertEqual(book.bid_levels, {})
        self.assertEqual(book.bbo(), Bbo(None, None, None, None))

    def test_cancel_to_zero_removes_order(self) -> None:
        book = OrderBook()
        book.apply(add(msg_index=0, order_ref=1, side=Side.SELL, price=10_050, shares=30))

        book.apply(cancel(msg_index=1, order_ref=1, shares=30))

        self.assertNotIn(1, book.order_table)
        self.assertEqual(book.ask_levels, {})

    def test_delete_removes_remaining_order(self) -> None:
        book = OrderBook()
        book.apply(add(msg_index=0, order_ref=1, side=Side.BUY, price=10_000, shares=100))

        book.apply(delete(msg_index=1, order_ref=1))

        self.assertNotIn(1, book.order_table)
        self.assertEqual(book.bid_levels, {})

    def test_replace_preserves_side_and_updates_ref_price_and_size(self) -> None:
        book = OrderBook()
        book.apply(add(msg_index=0, order_ref=1, side=Side.SELL, price=10_050, shares=100))

        book.apply(
            replace_order(
                msg_index=1,
                order_ref=1,
                new_order_ref=2,
                price=10_040,
                shares=25,
            )
        )

        self.assertNotIn(1, book.order_table)
        self.assertEqual(book.order_table[2].side, Side.SELL)
        self.assertEqual(book.order_table[2].price, 10_040)
        self.assertEqual(book.order_table[2].shares, 25)
        self.assertEqual(book.ask_levels, {10_040: Level(shares=25, order_count=1)})
        self.assertEqual(
            book.bbo(),
            Bbo(bid_price=None, bid_size=None, ask_price=10_040, ask_size=25),
        )

    def test_invalid_lifecycle_events_assert_with_msg_index(self) -> None:
        book = OrderBook()
        book.apply(add(msg_index=0, order_ref=1, side=Side.BUY, price=10_000, shares=10))

        with self.assertRaisesRegex(AssertionError, "msg_index=1.*exceeds"):
            book.apply(execute(msg_index=1, order_ref=1, shares=11))

        with self.assertRaisesRegex(AssertionError, "msg_index=2.*unknown order_ref"):
            book.apply(delete(msg_index=2, order_ref=999))

        with self.assertRaisesRegex(AssertionError, "msg_index=3.*reused order_ref"):
            book.apply(add(msg_index=3, order_ref=1, side=Side.SELL, price=10_050, shares=5))


if __name__ == "__main__":
    unittest.main()
