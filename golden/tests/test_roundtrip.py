"""
Run with:

python -m py_compile golden/itch_parser.py golden/order_book.py golden/tests/test_roundtrip.py golden/tests/test_itch_parser.py golden/tests/test_order_book.py
python -m unittest discover -s golden/tests -v
"""


from __future__ import annotations

import unittest

from golden.contracts import Bbo, Level
from golden.itch_parser import parse_itch_stream
from golden.order_book import OrderBook


def u(value: int, length: int) -> bytes:
    return value.to_bytes(length, byteorder="big")


def common(message_type: str, *, locate: int, timestamp: int, order_ref: int) -> bytes:
    return (
        message_type.encode("ascii")
        + u(locate, 2)
        + u(7, 2)
        + u(timestamp, 6)
        + u(order_ref, 8)
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
        common(message_type, locate=locate, timestamp=timestamp, order_ref=order_ref)
        + side
        + u(shares, 4)
        + b"MSFT    "
        + u(price, 4)
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
        common(message_type, locate=locate, timestamp=timestamp, order_ref=order_ref)
        + u(shares, 4)
        + u(9001, 8)
    )
    if message_type == "C":
        message += b"Y" + u(10_020, 4)
    return message


def cancel_message(
    *, locate: int = 1, timestamp: int, order_ref: int, shares: int
) -> bytes:
    return common("X", locate=locate, timestamp=timestamp, order_ref=order_ref) + u(
        shares, 4
    )


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
        common("U", locate=locate, timestamp=timestamp, order_ref=order_ref)
        + u(new_order_ref, 8)
        + u(shares, 4)
        + u(price, 4)
    )


def framed(message: bytes) -> bytes:
    return u(len(message), 2) + message


class OrderBookIntegrationTests(unittest.TestCase):
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
                framed(
                    execute_message(timestamp=103, order_ref=1001, shares=25)
                ),
                framed(
                    execute_message("C", timestamp=104, order_ref=1001, shares=75)
                ),
                framed(
                    cancel_message(timestamp=105, order_ref=1002, shares=50)
                ),
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


if __name__ == "__main__":
    unittest.main()
