"""
- Turns the ITCH feed into a stream of NormalisedEvents

- Split into:
    - Record reader that walks the BinaryFILE
    - Decoder that given one message's bytes, decodes it into a NormalisedEvent
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator

from golden.contracts import NormalisedEvent, Op, Side

ReadableBytes = bytes | bytearray | memoryview

class ItchParseError(ValueError):
    """Raised when an ITCH payload is structurally invalid."""


@dataclass(frozen=True)
class StockDirectory:
    """Symbol-to-locate entry from an ITCH Stock Directory message."""

    locate: int
    stock: str
    msg_index: int
    timestamp_ns: int


_STOCK_DIRECTORY = ord("R")
_ADD_NO_MPID = ord("A")
_ADD_WITH_MPID = ord("F")
_ORDER_EXECUTED = ord("E")
_ORDER_EXECUTED_WITH_PRICE = ord("C")
_ORDER_CANCEL = ord("X")
_ORDER_DELETE = ord("D")
_ORDER_REPLACE = ord("U")

_STOCK_DIRECTORY_LENGTH = 39
_BOOK_MESSAGE_LENGTHS = {
    _ADD_NO_MPID: 36,
    _ADD_WITH_MPID: 40,
    _ORDER_EXECUTED: 31,
    _ORDER_EXECUTED_WITH_PRICE: 36,
    _ORDER_CANCEL: 23,
    _ORDER_DELETE: 19,
    _ORDER_REPLACE: 35,
}


def iter_binaryfile_payloads(
    data: ReadableBytes,
    *,
    start_index: int = 0,
    max_messages: int | None = None,
) -> Iterator[tuple[int, memoryview]]:
    """Yield ``(msg_index, payload)`` from two-byte length-prefixed records."""

    view = memoryview(data)
    cursor = 0
    messages_seen = 0
    msg_index = start_index
    while cursor < len(view):
        if max_messages is not None and messages_seen >= max_messages:
            return
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

        yield msg_index, view[payload_start:payload_end]
        cursor = payload_end
        messages_seen += 1
        msg_index += 1


def parse_itch_message(
    message: ReadableBytes,
    *,
    msg_index: int,
) -> NormalisedEvent | None:
    """Parse one ITCH 5.0 message payload.

    The payload starts at the ITCH message type byte. It must not include the
    two-byte record length used by SoupBinTCP-style binary files.

    Unsupported messages return None because directory, halt, trade-print, and
    auction messages do not directly mutate the displayed order book represented
    by NormalisedEvent.
    """

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


def parse_stock_directory_message(
    message: ReadableBytes,
    *,
    msg_index: int,
) -> StockDirectory | None:
    """Parse a Stock Directory message into its symbol-to-locate mapping."""

    payload = memoryview(message)
    if len(payload) == 0:
        raise ItchParseError(f"msg_index={msg_index}: empty ITCH message")
    if payload[0] != _STOCK_DIRECTORY:
        return None

    _require_length(payload, _STOCK_DIRECTORY_LENGTH, msg_index)
    stock = payload[11:19].tobytes().decode("ascii").strip()
    return StockDirectory(
        locate=_uint(payload, 1, 2),
        stock=_normalise_symbol(stock),
        msg_index=msg_index,
        timestamp_ns=_uint(payload, 5, 6),
    )


def iter_stock_directories(
    data: ReadableBytes,
    *,
    start_index: int = 0,
    max_messages: int | None = None,
) -> Iterator[StockDirectory]:
    """Yield Stock Directory entries from a BinaryFILE stream."""

    for msg_index, payload in iter_binaryfile_payloads(
        data,
        start_index=start_index,
        max_messages=max_messages,
    ):
        directory = parse_stock_directory_message(payload, msg_index=msg_index)
        if directory is not None:
            yield directory


def stock_locate_map(
    data: ReadableBytes,
    *,
    start_index: int = 0,
    max_messages: int | None = None,
) -> dict[str, int]:
    """Return the daily ``symbol -> locate`` mapping advertised by the feed."""

    locates: dict[str, int] = {}
    for directory in iter_stock_directories(
        data,
        start_index=start_index,
        max_messages=max_messages,
    ):
        existing = locates.get(directory.stock)
        if existing is not None and existing != directory.locate:
            raise ItchParseError(
                f"symbol {directory.stock!r} maps to both locate "
                f"{existing} and {directory.locate}"
            )
        locates[directory.stock] = directory.locate
    return locates


def resolve_symbol_locate(
    data: ReadableBytes,
    symbol: str,
    *,
    start_index: int = 0,
    max_messages: int | None = None,
) -> int:
    """Resolve a stock symbol to its daily ITCH locate from Stock Directory records."""

    wanted = _normalise_symbol(symbol)
    if not wanted:
        raise ValueError("symbol must not be empty")

    locates = stock_locate_map(
        data,
        start_index=start_index,
        max_messages=max_messages,
    )
    try:
        return locates[wanted]
    except KeyError as exc:
        raise ItchParseError(
            f"symbol {wanted!r} was not found in Stock Directory messages"
        ) from exc


def parse_itch_payloads(
    messages: Iterable[ReadableBytes],
    *,
    start_index: int = 0,
) -> Iterator[NormalisedEvent]:
    """Yield normalised book events from already-split ITCH messages.

    msg_index tracks the source ITCH message number, including ignored messages,
    so diagnostics can be traced back to the original feed position.
    """

    for offset, message in enumerate(messages):
        event = parse_itch_message(message, msg_index=start_index + offset)
        if event is not None:
            yield event


def parse_itch_stream(
    data: ReadableBytes,
    *,
    start_index: int = 0,
    max_messages: int | None = None,
) -> Iterator[NormalisedEvent]:
    """Yield normalised events from two-byte length-prefixed ITCH records."""

    for msg_index, payload in iter_binaryfile_payloads(
        data,
        start_index=start_index,
        max_messages=max_messages,
    ):
        event = parse_itch_message(payload, msg_index=msg_index)
        if event is not None:
            yield event


def load_itch_events(path: str | Path, *, start_index: int = 0) -> list[NormalisedEvent]:
    """Read a length-prefixed binary ITCH file and return normalised events."""

    return list(parse_itch_stream(Path(path).read_bytes(), start_index=start_index))


def _uint(payload: memoryview, offset: int, length: int) -> int:
    return int.from_bytes(payload[offset : offset + length], byteorder="big")


def _parse_side(raw_side: int, msg_index: int) -> Side:
    if raw_side == ord("B"):
        return Side.BUY
    if raw_side == ord("S"):
        return Side.SELL
    raise ItchParseError(
        f"msg_index={msg_index}: invalid buy/sell indicator {chr(raw_side)!r}"
    )


def _normalise_symbol(symbol: str) -> str:
    return symbol.strip().upper()


def _require_length(payload: memoryview, expected_length: int, msg_index: int) -> None:
    if len(payload) != expected_length:
        message_type = chr(payload[0]) if len(payload) else "<empty>"
        raise ItchParseError(
            f"msg_index={msg_index}: ITCH {message_type!r} expected "
            f"{expected_length} bytes, got {len(payload)}"
        )
