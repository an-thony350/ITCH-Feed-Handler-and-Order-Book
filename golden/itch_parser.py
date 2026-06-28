"""
- Turns the ITCH feed into a stream of NormalisedEvents

- Split into:
    - Record reader that walks the BinaryFILE
    - Decoder that given one message's bytes, decodes it into a NormalisedEvent
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable, Iterator

from golden.contracts import NormalisedEvent, Op, Side

ReadableBytes = bytes | bytearray | memoryview

class ItchParseError(ValueError):
    """Raised when the ITCH feed is malformed or unexpected."""

_ADD_NO_MPID = ord("A")
_ADD_WITH_MPID = ord("F")
_ORDER_EXECUTED = ord("E")
_ORDER_EXECUTED_WITH_PRICE = ord("C")
_ORDER_CANCEL = ord("X")
_ORDER_DELETE = ord("D")
_ORDER_REPLACE = ord("U")

_BOOK_MESSAGE_LENGTHS = {
    _ADD_NO_MPID: 36,
    _ADD_WITH_MPID: 40,
    _ORDER_EXECUTED: 31,
    _ORDER_EXECUTED_WITH_PRICE: 36,
    _ORDER_CANCEL: 23,
    _ORDER_DELETE: 19,
    _ORDER_REPLACE: 35,
}

def parse_itch_message(message: ReadableBytes, *, msg_index: int) -> NormalisedEvent | None:
    """Parse one ITCH message into a NormalisedEvent, or None if the message is not relevant to the order book."""
    payload = memoryview(message)
    if len(payload) == 0:
        raise ItchParseError(f"msg_index={msg_index}: empty ITCH message")

    message_type = payload[0]
    expected_length = _BOOK_MESSAGE_LENGTHS.get(message_type)
    if expected_length is None:
        return None
    _require_length(payload, expected_length, msg_index)

    locate = _uint(payload, 1, 2)
    timestamp_ns = _uint(payload, 5, 6)
    order_ref = _uint(payload, 11, 8)

    if message_type in (_ADD_NO_MPID, _ADD_WITH_MPID):
        return NormalisedEvent(
            op=Op.ADD,
            locate=locate,
            side=_parse_side(payload[19], msg_index),
            order_ref=order_ref,
            msg_index=msg_index,
            price=_uint(payload, 32, 4),
            shares=_uint(payload, 20, 4),
            timestamp_ns=timestamp_ns,
        )

    if message_type in (_ORDER_EXECUTED, _ORDER_EXECUTED_WITH_PRICE):
        return NormalisedEvent(
            op=Op.EXECUTE,
            locate=locate,
            side=Side.UNKNOWN,
            order_ref=order_ref,
            msg_index=msg_index,
            shares=_uint(payload, 19, 4),
            timestamp_ns=timestamp_ns,
        )

    if message_type == _ORDER_CANCEL:
        return NormalisedEvent(
            op=Op.CANCEL,
            locate=locate,
            side=Side.UNKNOWN,
            order_ref=order_ref,
            msg_index=msg_index,
            shares=_uint(payload, 19, 4),
            timestamp_ns=timestamp_ns,
        )

    if message_type == _ORDER_DELETE:
        return NormalisedEvent(
            op=Op.DELETE,
            locate=locate,
            side=Side.UNKNOWN,
            order_ref=order_ref,
            msg_index=msg_index,
            timestamp_ns=timestamp_ns,
        )

    if message_type == _ORDER_REPLACE:
        return NormalisedEvent(
            op=Op.REPLACE,
            locate=locate,
            side=Side.UNKNOWN,
            order_ref=order_ref,
            msg_index=msg_index,
            new_order_ref=_uint(payload, 19, 8),
            shares=_uint(payload, 27, 4),
            price=_uint(payload, 31, 4),
            timestamp_ns=timestamp_ns,
        )

    raise AssertionError(f"unhandled supported ITCH type {chr(message_type)!r}")



def parse_itch_payloads(messages: Iterable[ReadableBytes], *, start_index: int = 0) -> Iterator[NormalisedEvent]:
    """Yield normalised book events from already-split ITCH messages."""
    for offset, message in enumerate(messages):
        event = parse_itch_message(message, msg_index=start_index + offset)
        if event is not None:
            yield event

def parse_itch_stream(data: ReadableBytes, *, start_index: int=0) -> Iterator[NormalisedEvent]:
    """Yield normalised events from two-byte length-prefixed ITCH records"""
    view = memoryview(data)
    cursor = 0
    msg_index = start_index
    while cursor < len(view):
        if len(view) - cursor < 2:
            raise ItchParseError(
                f"truncated ITCH length at byte offset {cursor}: "
                f"{len(view) - cursor} byte(s) available"
            )

        message_length = _uint(view, cursor, 2)
        payload_start = cursor + 2
        payload_end = payload_start + message_length

        if payload_end > len(view):
            raise ItchParseError(
                f"msg_index={msg_index}: frame length {message_length} at byte "
                f"offset {cursor} exceeds remaining stream bytes"
            )

        event = parse_itch_message(view[payload_start:payload_end], msg_index=msg_index)
        if event is not None:
            yield event

        cursor = payload_end
        msg_index += 1

def load_itch_events(path: str | Path, *, start_index: int = 0) -> list[NormalisedEvent]:
    """Read a length-prefixed binary ITCH file and return normalised events"""
    return list(parse_itch_stream(Path(path).read_bytes(), start_index=start_index))

def _uint(payload: memoryview, offset: int, length: int) -> int:
    return int.from_bytes(payload[offset : offset + length], byteorder="big")

def _parse_side(raw_side: int, msg_index: int) -> Side:
    if raw_side == ord("B"):
        return Side.BUY
    if raw_side == ord("S"):
        return Side.SELL
    raise ItchParseError(f"msg_index={msg_index}: invalid buy/sell indicator {chr(raw_side)!r}")

def _require_length(payload: memoryview, expected_length: int, msg_index: int) -> None:
    if len(payload) != expected_length:
        message_type = chr(payload[0]) if len(payload) else "<empty>"
        raise ItchParseError(
            f"Message {msg_index} has length {len(payload)} but expected {expected_length} for type {message_type}"
        )
