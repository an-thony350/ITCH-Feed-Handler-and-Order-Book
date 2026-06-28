"""
Run with:

python -m unittest discover -s golden/tests -v
"""


from __future__ import annotations

import tempfile
import unittest

from golden.contracts import NormalisedEvent, Op, Side
from golden.itch_parser import (
    ItchParseError,
    load_itch_events,
    parse_itch_message,
    parse_itch_payloads,
    parse_itch_stream,
)


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
    timestamp: int = 100,
    order_ref: int = 1001,
    side: bytes = b"B",
    shares: int = 20,
    stock: bytes = b"MSFT    ",
    price: int = 123_456,
    attribution: bytes = b"NSDQ",
) -> bytes:
    message = (
        common(message_type, locate=locate, timestamp=timestamp, order_ref=order_ref)
        + side
        + u(shares, 4)
        + stock
        + u(price, 4)
    )
    if message_type == "F":
        message += attribution
    return message


def execute_message(
    message_type: str = "E",
    *,
    locate: int = 1,
    timestamp: int = 101,
    order_ref: int = 1001,
    shares: int = 5,
) -> bytes:
    message = (
        common(message_type, locate=locate, timestamp=timestamp, order_ref=order_ref)
        + u(shares, 4)
        + u(999, 8)
    )
    if message_type == "C":
        message += b"Y" + u(123_400, 4)
    return message


def cancel_message(
    *,
    locate: int = 1,
    timestamp: int = 102,
    order_ref: int = 1001,
    shares: int = 3,
) -> bytes:
    return common("X", locate=locate, timestamp=timestamp, order_ref=order_ref) + u(
        shares, 4
    )


def delete_message(
    *,
    locate: int = 1,
    timestamp: int = 103,
    order_ref: int = 1001,
) -> bytes:
    return common("D", locate=locate, timestamp=timestamp, order_ref=order_ref)


def replace_message(
    *,
    locate: int = 1,
    timestamp: int = 104,
    order_ref: int = 1001,
    new_order_ref: int = 2002,
    shares: int = 9,
    price: int = 123_500,
) -> bytes:
    return (
        common("U", locate=locate, timestamp=timestamp, order_ref=order_ref)
        + u(new_order_ref, 8)
        + u(shares, 4)
        + u(price, 4)
    )


def framed(message: bytes) -> bytes:
    return u(len(message), 2) + message


class ItchParserTests(unittest.TestCase):
    def test_add_no_mpid_normalises_to_add(self) -> None:
        self.assertEqual(
            parse_itch_message(add_message(), msg_index=0),
            NormalisedEvent(
                op=Op.ADD,
                locate=1,
                side=Side.BUY,
                order_ref=1001,
                msg_index=0,
                price=123_456,
                shares=20,
                timestamp_ns=100,
            ),
        )

    def test_add_with_mpid_ignores_attribution_for_book_state(self) -> None:
        self.assertEqual(
            parse_itch_message(add_message("F", side=b"S"), msg_index=1),
            NormalisedEvent(
                op=Op.ADD,
                locate=1,
                side=Side.SELL,
                order_ref=1001,
                msg_index=1,
                price=123_456,
                shares=20,
                timestamp_ns=100,
            ),
        )

    def test_execute_and_execute_with_price_both_reduce_displayed_order(self) -> None:
        self.assertEqual(
            parse_itch_message(execute_message("E", shares=5), msg_index=2),
            NormalisedEvent(
                op=Op.EXECUTE,
                locate=1,
                side=Side.UNKNOWN,
                order_ref=1001,
                msg_index=2,
                shares=5,
                timestamp_ns=101,
            ),
        )
        self.assertEqual(
            parse_itch_message(execute_message("C", shares=6), msg_index=3),
            NormalisedEvent(
                op=Op.EXECUTE,
                locate=1,
                side=Side.UNKNOWN,
                order_ref=1001,
                msg_index=3,
                shares=6,
                timestamp_ns=101,
            ),
        )

    def test_cancel_delete_and_replace_normalise_to_book_ops(self) -> None:
        self.assertEqual(
            parse_itch_message(cancel_message(shares=3), msg_index=4),
            NormalisedEvent(
                op=Op.CANCEL,
                locate=1,
                side=Side.UNKNOWN,
                order_ref=1001,
                msg_index=4,
                shares=3,
                timestamp_ns=102,
            ),
        )
        self.assertEqual(
            parse_itch_message(delete_message(), msg_index=5),
            NormalisedEvent(
                op=Op.DELETE,
                locate=1,
                side=Side.UNKNOWN,
                order_ref=1001,
                msg_index=5,
                timestamp_ns=103,
            ),
        )
        self.assertEqual(
            parse_itch_message(replace_message(), msg_index=6),
            NormalisedEvent(
                op=Op.REPLACE,
                locate=1,
                side=Side.UNKNOWN,
                order_ref=1001,
                msg_index=6,
                new_order_ref=2002,
                shares=9,
                price=123_500,
                timestamp_ns=104,
            ),
        )

    def test_unsupported_messages_are_ignored_without_reindexing_events(self) -> None:
        system_event = b"S" + b"\x00" * 11

        self.assertIsNone(parse_itch_message(system_event, msg_index=0))
        self.assertEqual(
            list(parse_itch_payloads([system_event, add_message()], start_index=10)),
            [
                NormalisedEvent(
                    op=Op.ADD,
                    locate=1,
                    side=Side.BUY,
                    order_ref=1001,
                    msg_index=11,
                    price=123_456,
                    shares=20,
                    timestamp_ns=100,
                )
            ],
        )

    def test_length_prefixed_stream_and_file_loader(self) -> None:
        stream = framed(b"S" + b"\x00" * 11) + framed(add_message()) + framed(
            execute_message(shares=4)
        )

        self.assertEqual(
            [event.op for event in parse_itch_stream(stream, start_index=20)],
            [Op.ADD, Op.EXECUTE],
        )

        with tempfile.NamedTemporaryFile() as handle:
            handle.write(stream)
            handle.flush()
            self.assertEqual(
                [event.msg_index for event in load_itch_events(handle.name)],
                [1, 2],
            )

    def test_malformed_supported_messages_raise_clear_parse_errors(self) -> None:
        with self.assertRaisesRegex(ItchParseError, "expected 36"):
            parse_itch_message(add_message()[:-1], msg_index=0)

        bad_side = add_message(side=b"T")
        with self.assertRaisesRegex(ItchParseError, "invalid buy/sell"):
            parse_itch_message(bad_side, msg_index=1)

        with self.assertRaisesRegex(ItchParseError, "truncated ITCH length"):
            list(parse_itch_stream(b"\x00"))


if __name__ == "__main__":
    unittest.main()
