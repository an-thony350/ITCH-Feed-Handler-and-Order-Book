"""Golden-model runner for ITCH BinaryFILE oracle generation.

BinaryFILE input -> ITCH parser -> reference OrderBook -> JSONL outputs.

emits one message-indexed JSONL stream for normalised events, used to check
the RTL decoder, and one message-indexed JSONL stream for book states, used to
check the RTL order-book engine.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator, TextIO

from golden.contracts import Bbo, BookState, Level, NormalisedEvent, Side
from golden.itch_parser import ItchParseError, parse_itch_message
from golden.order_book import OrderBook


ReadableBytes = bytes | bytearray | memoryview


@dataclass(frozen=True)
class RunnerStats:
    """Summary of one runner invocation."""

    source_messages_seen: int
    events_written: int
    states_written: int
    final_msg_index: int | None
    final_bbo: Bbo | None
    peak_live_orders: int
    peak_bid_levels: int
    peak_ask_levels: int


def run_file(
    input_path: str | Path,
    *,
    events_out: str | Path,
    states_out: str | Path,
    locate: int | None = None,
    start_index: int = 0,
    max_messages: int | None = None,
    max_events: int | None = None,
) -> RunnerStats:
    """Run the golden model over an ITCH BinaryFILE and write JSONL oracles."""

    data = Path(input_path).read_bytes()
    events_path = Path(events_out)
    states_path = Path(states_out)
    events_path.parent.mkdir(parents=True, exist_ok=True)
    states_path.parent.mkdir(parents=True, exist_ok=True)

    with events_path.open("w", encoding="utf-8") as events_handle, states_path.open(
        "w", encoding="utf-8"
    ) as states_handle:
        return run_bytes(
            data,
            events_out=events_handle,
            states_out=states_handle,
            locate=locate,
            start_index=start_index,
            max_messages=max_messages,
            max_events=max_events,
        )


def run_bytes(
    data: ReadableBytes,
    *,
    events_out: TextIO,
    states_out: TextIO,
    locate: int | None = None,
    start_index: int = 0,
    max_messages: int | None = None,
    max_events: int | None = None,
) -> RunnerStats:
    """Run the golden model over in-memory BinaryFILE bytes."""

    book = OrderBook(expected_locate=locate)
    stats = _MutableStats()

    for msg_index, payload in iter_binaryfile_payloads(
        data,
        start_index=start_index,
        max_messages=max_messages,
    ):
        stats.source_messages_seen += 1

        event = parse_itch_message(payload, msg_index=msg_index)
        if event is None:
            continue
        if locate is not None and event.locate != locate:
            continue

        write_jsonl(events_out, event_to_dict(event))
        stats.events_written += 1

        book.apply(event)
        state = book.snapshot(msg_index=event.msg_index)
        write_jsonl(states_out, state_to_dict(state))
        stats.states_written += 1
        stats.final_msg_index = event.msg_index
        stats.final_bbo = state.bbo
        stats.peak_live_orders = max(stats.peak_live_orders, len(book.order_table))
        stats.peak_bid_levels = max(stats.peak_bid_levels, len(book.bid_levels))
        stats.peak_ask_levels = max(stats.peak_ask_levels, len(book.ask_levels))

        if max_events is not None and stats.events_written >= max_events:
            break

    return stats.freeze()


def iter_itch_events(
    data: ReadableBytes,
    *,
    locate: int | None = None,
    start_index: int = 0,
    max_messages: int | None = None,
    max_events: int | None = None,
) -> Iterator[NormalisedEvent]:
    """Yield parsed events from BinaryFILE bytes with optional filtering."""

    events_yielded = 0
    for msg_index, payload in iter_binaryfile_payloads(
        data,
        start_index=start_index,
        max_messages=max_messages,
    ):
        event = parse_itch_message(payload, msg_index=msg_index)
        if event is None:
            continue
        if locate is not None and event.locate != locate:
            continue

        yield event
        events_yielded += 1
        if max_events is not None and events_yielded >= max_events:
            return


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


def count_binaryfile_messages(
    data: ReadableBytes,
    *,
    start_index: int = 0,
    max_messages: int | None = None,
) -> int:
    """Count source BinaryFILE records, respecting the same truncation option."""

    return sum(
        1
        for _msg_index, _payload in iter_binaryfile_payloads(
            data,
            start_index=start_index,
            max_messages=max_messages,
        )
    )


def event_to_dict(event: NormalisedEvent) -> dict[str, int | str | None]:
    """Serialise a normalised event using stable, flat field names."""

    return {
        "msg_index": event.msg_index,
        "op": event.op.value,
        "locate": event.locate,
        "side": event.side.value,
        "order_ref": event.order_ref,
        "price": event.price,
        "shares": event.shares,
        "new_order_ref": event.new_order_ref,
        "timestamp_ns": event.timestamp_ns,
    }


def state_to_dict(state: BookState) -> dict[str, object]:
    """Serialise a book state snapshot with deterministic level ordering."""

    return {
        "msg_index": state.msg_index,
        "bbo": bbo_to_dict(state.bbo),
        "bid_levels": levels_to_list(state.bid_levels, side=Side.BUY),
        "ask_levels": levels_to_list(state.ask_levels, side=Side.SELL),
    }


def bbo_to_dict(bbo: Bbo) -> dict[str, int | None]:
    return {
        "bid_price": bbo.bid_price,
        "bid_size": bbo.bid_size,
        "ask_price": bbo.ask_price,
        "ask_size": bbo.ask_size,
    }


def levels_to_list(
    levels: dict[int, Level],
    *,
    side: Side,
) -> list[dict[str, int]]:
    """Serialise levels best-to-worst for the requested side."""

    reverse = side is Side.BUY
    return [
        {
            "price": price,
            "shares": level.shares,
            "order_count": level.order_count,
        }
        for price, level in sorted(levels.items(), reverse=reverse)
    ]


def write_jsonl(handle: TextIO, record: dict[str, object]) -> None:
    handle.write(json.dumps(record, sort_keys=True, separators=(",", ":")))
    handle.write("\n")


def _uint(payload: memoryview, offset: int, length: int) -> int:
    return int.from_bytes(payload[offset : offset + length], byteorder="big")


@dataclass
class _MutableStats:
    source_messages_seen: int = 0
    events_written: int = 0
    states_written: int = 0
    final_msg_index: int | None = None
    final_bbo: Bbo | None = None
    peak_live_orders: int = 0
    peak_bid_levels: int = 0
    peak_ask_levels: int = 0

    def freeze(self) -> RunnerStats:
        return RunnerStats(
            source_messages_seen=self.source_messages_seen,
            events_written=self.events_written,
            states_written=self.states_written,
            final_msg_index=self.final_msg_index,
            final_bbo=self.final_bbo,
            peak_live_orders=self.peak_live_orders,
            peak_bid_levels=self.peak_bid_levels,
            peak_ask_levels=self.peak_ask_levels,
        )


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate ITCH golden-model event and book-state JSONL oracles."
    )
    parser.add_argument("input", type=Path, help="input ITCH BinaryFILE path")
    parser.add_argument(
        "--events-out",
        type=Path,
        required=True,
        help="output JSONL path for normalised events",
    )
    parser.add_argument(
        "--states-out",
        type=Path,
        required=True,
        help="output JSONL path for book states after each event",
    )
    parser.add_argument(
        "--locate",
        type=int,
        default=None,
        help="optional stock locate filter",
    )
    parser.add_argument(
        "--start-index",
        type=int,
        default=0,
        help="msg_index assigned to the first source BinaryFILE record",
    )
    parser.add_argument(
        "--max-messages",
        type=int,
        default=None,
        help="maximum source BinaryFILE records to scan, including ignored records",
    )
    parser.add_argument(
        "--max-events",
        type=int,
        default=None,
        help="maximum parsed book events to emit after filtering",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    stats = run_file(
        args.input,
        events_out=args.events_out,
        states_out=args.states_out,
        locate=args.locate,
        start_index=args.start_index,
        max_messages=args.max_messages,
        max_events=args.max_events,
    )
    print(
        "wrote "
        f"{stats.events_written} events and {stats.states_written} states "
        f"from {stats.source_messages_seen} source messages; "
        f"final_msg_index={stats.final_msg_index}; "
        f"final_bbo={stats.final_bbo}; "
        f"peaks=(orders={stats.peak_live_orders}, "
        f"bid_levels={stats.peak_bid_levels}, ask_levels={stats.peak_ask_levels})"
    )


if __name__ == "__main__":
    main()
