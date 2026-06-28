"""
- Creates a synthetic ITCH stream for testing the parser and order book
"""
from __future__ import annotations

import argparse
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

from golden.contracts import BookState, NormalisedEvent, Side
from golden.itch_parser import parse_itch_stream
from golden.order_book import OrderBook


DEFAULT_LOCATE = 1
DEFAULT_STOCK = b"MSFT    "
DEFAULT_TRACKING_NUMBER = 7


@dataclass(frozen=True)
class StimulusCase:
    """A named, inspectable BinaryFILE scenario."""

    name: str
    description: str
    messages: tuple[bytes, ...]

    def stream(self) -> bytes:
        return encode_binaryfile(self.messages)

    def events(self, *, start_index: int = 0) -> tuple[NormalisedEvent, ...]:
        return tuple(parse_itch_stream(self.stream(), start_index=start_index))

    def states(self, *, start_index: int = 0) -> tuple[BookState, ...]:
        return replay_events(self.events(start_index=start_index))


@dataclass(frozen=True)
class _LiveOrder:
    side: Side
    price: int
    shares: int


def uint(value: int, length: int) -> bytes:
    """Encode an unsigned integer using ITCH's big-endian byte order."""

    return value.to_bytes(length, byteorder="big")


def frame(message: bytes) -> bytes:
    """Prefix one ITCH message with its two-byte BinaryFILE length."""

    return uint(len(message), 2) + message


def encode_binaryfile(messages: Iterable[bytes]) -> bytes:
    """Encode already-built ITCH payloads as a BinaryFILE byte stream."""

    return b"".join(frame(message) for message in messages)


def write_binaryfile(path: str | Path, messages: Iterable[bytes]) -> None:
    """Write a synthetic BinaryFILE stream to disk."""

    Path(path).write_bytes(encode_binaryfile(messages))


def system_event(
    *,
    locate: int = DEFAULT_LOCATE,
    tracking_number: int = DEFAULT_TRACKING_NUMBER,
    timestamp_ns: int = 0,
    event_code: bytes = b"O",
) -> bytes:
    """Build an unsupported System Event message.

    The current parser intentionally ignores non-book messages, so this is useful
    for proving that ``msg_index`` still follows the source feed position.
    """

    assert len(event_code) == 1
    return (
        b"S"
        + uint(locate, 2)
        + uint(tracking_number, 2)
        + uint(timestamp_ns, 6)
        + event_code
    )


def add_message(
    *,
    order_ref: int,
    side: Side,
    shares: int,
    price: int,
    locate: int = DEFAULT_LOCATE,
    tracking_number: int = DEFAULT_TRACKING_NUMBER,
    timestamp_ns: int,
    stock: bytes = DEFAULT_STOCK,
    with_mpid: bool = False,
    attribution: bytes = b"NSDQ",
) -> bytes:
    """Build an Add Order message, using ``F`` when attribution is requested."""

    assert side in (Side.BUY, Side.SELL)
    assert len(stock) == 8
    message_type = b"F" if with_mpid else b"A"
    message = (
        _common(message_type, locate, tracking_number, timestamp_ns, order_ref)
        + _side_byte(side)
        + uint(shares, 4)
        + stock
        + uint(price, 4)
    )
    if with_mpid:
        assert len(attribution) == 4
        message += attribution
    return message


def execute_message(
    *,
    order_ref: int,
    shares: int,
    locate: int = DEFAULT_LOCATE,
    tracking_number: int = DEFAULT_TRACKING_NUMBER,
    timestamp_ns: int,
    match_number: int = 1,
    with_price: bool = False,
    printable: bytes = b"Y",
    execution_price: int = 0,
) -> bytes:
    """Build an Order Executed message.

    ITCH ``E`` and ``C`` both reduce displayed order-book size, so the parser
    normalises both to ``Op.EXECUTE`` and ignores the optional execution price.
    """

    message_type = b"C" if with_price else b"E"
    message = (
        _common(message_type, locate, tracking_number, timestamp_ns, order_ref)
        + uint(shares, 4)
        + uint(match_number, 8)
    )
    if with_price:
        assert len(printable) == 1
        message += printable + uint(execution_price, 4)
    return message


def cancel_message(
    *,
    order_ref: int,
    shares: int,
    locate: int = DEFAULT_LOCATE,
    tracking_number: int = DEFAULT_TRACKING_NUMBER,
    timestamp_ns: int,
) -> bytes:
    """Build an Order Cancel message."""

    return (
        _common(b"X", locate, tracking_number, timestamp_ns, order_ref)
        + uint(shares, 4)
    )


def delete_message(
    *,
    order_ref: int,
    locate: int = DEFAULT_LOCATE,
    tracking_number: int = DEFAULT_TRACKING_NUMBER,
    timestamp_ns: int,
) -> bytes:
    """Build an Order Delete message."""

    return _common(b"D", locate, tracking_number, timestamp_ns, order_ref)


def replace_message(
    *,
    order_ref: int,
    new_order_ref: int,
    shares: int,
    price: int,
    locate: int = DEFAULT_LOCATE,
    tracking_number: int = DEFAULT_TRACKING_NUMBER,
    timestamp_ns: int,
) -> bytes:
    """Build an Order Replace message."""

    return (
        _common(b"U", locate, tracking_number, timestamp_ns, order_ref)
        + uint(new_order_ref, 8)
        + uint(shares, 4)
        + uint(price, 4)
    )


def directed_cases() -> tuple[StimulusCase, ...]:
    """Return deterministic edge-case scenarios for parser and book testing."""

    return (
        StimulusCase(
            name="lifecycle_with_ignored_message",
            description=(
                "Unsupported message, add on both sides, partial/full execute, "
                "cancel, and replace across price levels."
            ),
            messages=(
                system_event(timestamp_ns=90),
                add_message(
                    timestamp_ns=100,
                    order_ref=1001,
                    side=Side.BUY,
                    shares=100,
                    price=10_000,
                ),
                add_message(
                    timestamp_ns=101,
                    order_ref=2001,
                    side=Side.SELL,
                    shares=50,
                    price=10_050,
                    with_mpid=True,
                ),
                add_message(
                    timestamp_ns=102,
                    order_ref=1002,
                    side=Side.BUY,
                    shares=200,
                    price=9_990,
                ),
                execute_message(
                    timestamp_ns=103,
                    order_ref=1001,
                    shares=25,
                    match_number=9001,
                ),
                execute_message(
                    timestamp_ns=104,
                    order_ref=1001,
                    shares=75,
                    match_number=9002,
                    with_price=True,
                    execution_price=10_020,
                ),
                cancel_message(timestamp_ns=105, order_ref=1002, shares=50),
                replace_message(
                    timestamp_ns=106,
                    order_ref=2001,
                    new_order_ref=2002,
                    shares=30,
                    price=10_040,
                ),
            ),
        ),
        StimulusCase(
            name="replace_same_price_edges",
            description=(
                "Replace the only order at a price, replace one of several orders "
                "at a shared price, and replace using the same order reference."
            ),
            messages=(
                add_message(
                    timestamp_ns=200,
                    order_ref=3001,
                    side=Side.BUY,
                    shares=100,
                    price=10_000,
                ),
                replace_message(
                    timestamp_ns=201,
                    order_ref=3001,
                    new_order_ref=3002,
                    shares=40,
                    price=10_000,
                ),
                add_message(
                    timestamp_ns=202,
                    order_ref=3003,
                    side=Side.BUY,
                    shares=200,
                    price=10_000,
                ),
                replace_message(
                    timestamp_ns=203,
                    order_ref=3002,
                    new_order_ref=3002,
                    shares=60,
                    price=10_000,
                ),
                replace_message(
                    timestamp_ns=204,
                    order_ref=3003,
                    new_order_ref=3004,
                    shares=10,
                    price=9_995,
                ),
            ),
        ),
        StimulusCase(
            name="bbo_walk_down",
            description=(
                "Best ask moves down on add, then walks back up as levels empty."
            ),
            messages=(
                add_message(
                    timestamp_ns=300,
                    order_ref=4001,
                    side=Side.SELL,
                    shares=20,
                    price=10_030,
                ),
                add_message(
                    timestamp_ns=301,
                    order_ref=4002,
                    side=Side.SELL,
                    shares=30,
                    price=10_020,
                ),
                delete_message(timestamp_ns=302, order_ref=4002),
                cancel_message(timestamp_ns=303, order_ref=4001, shares=20),
            ),
        ),
    )


def random_valid_messages(
    *,
    seed: int,
    message_count: int,
    locate: int = DEFAULT_LOCATE,
    start_order_ref: int = 1_000_000,
    start_timestamp_ns: int = 1_000,
    base_price: int = 10_000,
) -> tuple[bytes, ...]:
    """Generate a seeded, contract-valid stream of book-mutating messages."""

    rng = random.Random(seed)
    live_orders: dict[int, _LiveOrder] = {}
    next_order_ref = start_order_ref
    timestamp_ns = start_timestamp_ns
    messages: list[bytes] = []

    def emit_add() -> None:
        nonlocal next_order_ref, timestamp_ns

        side = rng.choice((Side.BUY, Side.SELL))
        price_offset = rng.randint(-20, 20)
        if side is Side.BUY:
            price = base_price + min(price_offset, 0)
        else:
            price = base_price + max(price_offset, 1)
        shares = rng.randint(1, 500)
        order_ref = next_order_ref
        next_order_ref += 1
        live_orders[order_ref] = _LiveOrder(side=side, price=price, shares=shares)
        messages.append(
            add_message(
                locate=locate,
                timestamp_ns=timestamp_ns,
                order_ref=order_ref,
                side=side,
                shares=shares,
                price=price,
                with_mpid=rng.random() < 0.2,
            )
        )
        timestamp_ns += 1

    for _ in range(message_count):
        if not live_orders or rng.random() < 0.35:
            emit_add()
            continue

        order_ref = rng.choice(tuple(live_orders))
        order = live_orders[order_ref]
        operation = rng.choices(
            ("execute", "cancel", "delete", "replace"),
            weights=(30, 25, 20, 25),
            k=1,
        )[0]

        if operation == "execute":
            shares = rng.randint(1, order.shares)
            messages.append(
                execute_message(
                    locate=locate,
                    timestamp_ns=timestamp_ns,
                    order_ref=order_ref,
                    shares=shares,
                    match_number=timestamp_ns,
                    with_price=rng.random() < 0.2,
                    execution_price=order.price,
                )
            )
            _reduce_live_order(live_orders, order_ref, shares)
        elif operation == "cancel":
            shares = rng.randint(1, order.shares)
            messages.append(
                cancel_message(
                    locate=locate,
                    timestamp_ns=timestamp_ns,
                    order_ref=order_ref,
                    shares=shares,
                )
            )
            _reduce_live_order(live_orders, order_ref, shares)
        elif operation == "delete":
            messages.append(
                delete_message(
                    locate=locate,
                    timestamp_ns=timestamp_ns,
                    order_ref=order_ref,
                )
            )
            del live_orders[order_ref]
        else:
            same_ref = rng.random() < 0.2
            new_order_ref = order_ref if same_ref else next_order_ref
            if not same_ref:
                next_order_ref += 1
            price_step = rng.randint(-5, 5)
            if order.side is Side.BUY:
                new_price = max(1, min(base_price, order.price + price_step))
            else:
                new_price = max(base_price + 1, order.price + price_step)
            new_shares = rng.randint(1, 500)
            messages.append(
                replace_message(
                    locate=locate,
                    timestamp_ns=timestamp_ns,
                    order_ref=order_ref,
                    new_order_ref=new_order_ref,
                    shares=new_shares,
                    price=new_price,
                )
            )
            del live_orders[order_ref]
            live_orders[new_order_ref] = _LiveOrder(
                side=order.side,
                price=new_price,
                shares=new_shares,
            )

        timestamp_ns += 1

    return tuple(messages)


def default_messages(
    *,
    seed: int = 1,
    random_message_count: int = 50,
) -> tuple[bytes, ...]:
    """Return the standard synthetic stimulus campaign."""

    messages: list[bytes] = []
    for case in directed_cases():
        messages.extend(case.messages)
    messages.extend(
        random_valid_messages(seed=seed, message_count=random_message_count)
    )
    return tuple(messages)


def default_stream(*, seed: int = 1, random_message_count: int = 50) -> bytes:
    """Return the standard synthetic campaign as BinaryFILE bytes."""

    return encode_binaryfile(
        default_messages(seed=seed, random_message_count=random_message_count)
    )


def replay_events(events: Iterable[NormalisedEvent]) -> tuple[BookState, ...]:
    """Replay events through the oracle book and snapshot after every event."""

    book = OrderBook()
    states: list[BookState] = []
    for event in events:
        book.apply(event)
        states.append(book.snapshot(msg_index=event.msg_index))
    return tuple(states)


def parsed_default_events(
    *,
    seed: int = 1,
    random_message_count: int = 50,
) -> tuple[NormalisedEvent, ...]:
    """Parse the default synthetic stream back into normalised events."""

    return tuple(
        parse_itch_stream(
            default_stream(seed=seed, random_message_count=random_message_count)
        )
    )


def default_states(
    *,
    seed: int = 1,
    random_message_count: int = 50,
) -> tuple[BookState, ...]:
    """Return oracle book states for the default synthetic stream."""

    return replay_events(
        parsed_default_events(
            seed=seed,
            random_message_count=random_message_count,
        )
    )


def _common(
    message_type: bytes,
    locate: int,
    tracking_number: int,
    timestamp_ns: int,
    order_ref: int,
) -> bytes:
    assert len(message_type) == 1
    return (
        message_type
        + uint(locate, 2)
        + uint(tracking_number, 2)
        + uint(timestamp_ns, 6)
        + uint(order_ref, 8)
    )


def _side_byte(side: Side) -> bytes:
    if side is Side.BUY:
        return b"B"
    if side is Side.SELL:
        return b"S"
    raise ValueError(f"cannot encode non-book side {side!r}")


def _reduce_live_order(
    live_orders: dict[int, _LiveOrder],
    order_ref: int,
    shares_delta: int,
) -> None:
    order = live_orders[order_ref]
    remaining = order.shares - shares_delta
    if remaining == 0:
        del live_orders[order_ref]
        return
    live_orders[order_ref] = _LiveOrder(
        side=order.side,
        price=order.price,
        shares=remaining,
    )


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate deterministic synthetic ITCH BinaryFILE stimulus."
    )
    parser.add_argument("output", type=Path, help="BinaryFILE path to write")
    parser.add_argument("--seed", type=int, default=1, help="random stimulus seed")
    parser.add_argument(
        "--random-message-count",
        type=int,
        default=50,
        help="number of seeded random book messages to append",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    messages = default_messages(
        seed=args.seed,
        random_message_count=args.random_message_count,
    )
    write_binaryfile(args.output, messages)
    events = tuple(parse_itch_stream(encode_binaryfile(messages)))
    states = replay_events(events)
    final_bbo = states[-1].bbo if states else None
    print(
        f"wrote {args.output} "
        f"({len(messages)} frames, {len(events)} book events, final_bbo={final_bbo})"
    )


if __name__ == "__main__":
    main()
