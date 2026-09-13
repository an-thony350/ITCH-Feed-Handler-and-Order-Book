"""Generate the fixed AAPL/MSFT/NFLX hardware-comparable BBO oracle.

The script streams the gzip file; it does not load the multi-gigabyte dataset
into RAM. It uses the repository's trusted golden parser and OrderBook model.

For the showcase, the default selection mode finds the shortest source prefix
that produces at least a useful number of comparable BBO changes for *every*
stock. The resulting exact source-message count is written into the oracle and
becomes the fixed replay limit used by the dashboard.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import json
from pathlib import Path

from golden.itch_parser import parse_itch_message, parse_stock_directory_message
from golden.order_book import OrderBook


ROOT = Path(__file__).resolve().parent

SYMBOLS = ("AAPL", "MSFT", "NFLX")
BASE_PRICE_CENTS = {
    "AAPL": 21_000,
    "MSFT": 12_000,
    "NFLX": 32_000,
}

DEFAULT_MIN_BBO_UPDATES = 400
DEFAULT_MAX_MESSAGES = 10_000_000


def _golden_source_hashes() -> dict[str, str]:
    """Hash the exact bundled golden-model source used to build the oracle."""

    source_dir = ROOT / "golden"
    hashes = {}
    for name in ("contracts.py", "itch_parser.py", "order_book.py"):
        hashes[name] = hashlib.sha256((source_dir / name).read_bytes()).hexdigest()
    return hashes


def _hardware_comparable_bbo(
    bbo,
    *,
    base_price_cents: int,
) -> dict[str, int | None] | None:
    """Convert the golden BBO to the units/empty-side form exposed by hardware.

    A state containing a non-empty side below the configured hardware base price
    is not representable by the current order book and is skipped, matching the
    established board-comparison policy.
    """

    if bbo.bid_price is not None:
        bid_price_cents = int(bbo.bid_price) // 100
        if bid_price_cents < base_price_cents:
            return None
    else:
        bid_price_cents = None

    if bbo.ask_price is not None:
        ask_price_cents = int(bbo.ask_price) // 100
        if ask_price_cents < base_price_cents:
            return None
    else:
        ask_price_cents = None

    return {
        "bid_price_cents": bid_price_cents,
        "bid_size": None if bbo.bid_size is None else int(bbo.bid_size),
        "ask_price_cents": ask_price_cents,
        "ask_size": None if bbo.ask_size is None else int(bbo.ask_size),
    }


def _target_reached(
    sequences: dict[str, list[dict[str, int | None]]],
    min_bbo_updates: int,
) -> bool:
    return all(len(sequences[symbol]) >= min_bbo_updates for symbol in SYMBOLS)


def generate(
    data_path: Path,
    output_path: Path,
    *,
    message_limit: int | None,
    min_bbo_updates: int,
    max_messages: int,
) -> dict:
    if message_limit is not None and message_limit <= 0:
        raise ValueError("message_limit must be greater than zero")
    if min_bbo_updates <= 0:
        raise ValueError("min_bbo_updates must be greater than zero")
    if max_messages <= 0:
        raise ValueError("max_messages must be greater than zero")

    books: dict[str, OrderBook] = {}
    locate_to_symbol: dict[int, str] = {}
    symbol_to_locate: dict[str, int] = {}

    previous_raw_bbo = {symbol: None for symbol in SYMBOLS}
    previous_comparable_bbo = {symbol: None for symbol in SYMBOLS}
    sequences: dict[str, list[dict[str, int | None]]] = {
        symbol: [] for symbol in SYMBOLS
    }
    skipped_unrepresentable = {symbol: 0 for symbol in SYMBOLS}

    workload_hash = hashlib.sha256()
    source_messages = 0
    last_report_bucket = 0

    with gzip.open(data_path, "rb") as gz_file:
        with io.BufferedReader(gz_file, buffer_size=1024 * 1024) as data:
            while True:
                if message_limit is not None:
                    if source_messages >= message_limit:
                        break
                elif source_messages >= max_messages:
                    break

                length_header = data.read(2)
                if not length_header:
                    break
                if len(length_header) != 2:
                    raise EOFError("Truncated 2-byte ITCH message-length header")

                message_length = int.from_bytes(length_header, "big")
                payload = data.read(message_length)
                if len(payload) != message_length:
                    raise EOFError(
                        f"Truncated ITCH message at index {source_messages}: "
                        f"expected {message_length}, got {len(payload)}"
                    )

                workload_hash.update(length_header)
                workload_hash.update(payload)

                msg_index = source_messages
                source_messages += 1

                directory = parse_stock_directory_message(
                    payload,
                    msg_index=msg_index,
                )
                if directory is not None and directory.stock in SYMBOLS:
                    existing = symbol_to_locate.get(directory.stock)
                    if existing is not None and existing != directory.locate:
                        raise RuntimeError(
                            f"{directory.stock} mapped to both {existing} "
                            f"and {directory.locate}"
                        )
                    symbol_to_locate[directory.stock] = directory.locate
                    locate_to_symbol[directory.locate] = directory.stock
                    books.setdefault(
                        directory.stock,
                        OrderBook(expected_locate=directory.locate),
                    )

                event = parse_itch_message(payload, msg_index=msg_index)
                if event is not None:
                    symbol = locate_to_symbol.get(event.locate)
                    if symbol is not None:
                        book = books[symbol]
                        book.apply(event)
                        raw_bbo = book.bbo()

                        # Hardware is sampled only when its exposed BBO state changes.
                        if raw_bbo != previous_raw_bbo[symbol]:
                            previous_raw_bbo[symbol] = raw_bbo

                            comparable = _hardware_comparable_bbo(
                                raw_bbo,
                                base_price_cents=BASE_PRICE_CENTS[symbol],
                            )
                            if comparable is None:
                                skipped_unrepresentable[symbol] += 1
                            elif comparable != previous_comparable_bbo[symbol]:
                                # Price conversion to cents can collapse two distinct
                                # Price(4) states to one hardware-visible state.
                                sequences[symbol].append(comparable)
                                previous_comparable_bbo[symbol] = comparable

                total_updates = sum(len(items) for items in sequences.values())
                report_bucket = total_updates // 250
                if total_updates and report_bucket > last_report_bucket:
                    last_report_bucket = report_bucket
                    counts = " ".join(
                        f"{symbol}={len(sequences[symbol]):,}" for symbol in SYMBOLS
                    )
                    print(f"source={source_messages:,} {counts}")

                if (
                    message_limit is None
                    and _target_reached(sequences, min_bbo_updates)
                ):
                    break

    if message_limit is not None and source_messages != message_limit:
        raise RuntimeError(
            f"Dataset ended after {source_messages:,} source messages; "
            f"requested {message_limit:,}"
        )

    missing_symbols = [
        symbol for symbol in SYMBOLS if symbol not in symbol_to_locate
    ]
    if missing_symbols:
        raise RuntimeError(
            "Missing Stock Directory mapping(s): " + ", ".join(missing_symbols)
        )

    empty_sequences = [symbol for symbol in SYMBOLS if not sequences[symbol]]
    if empty_sequences:
        raise RuntimeError(
            "No comparable BBO updates were produced for: "
            + ", ".join(empty_sequences)
        )

    if message_limit is None and not _target_reached(sequences, min_bbo_updates):
        counts = ", ".join(
            f"{symbol}={len(sequences[symbol]):,}" for symbol in SYMBOLS
        )
        raise RuntimeError(
            f"Did not reach {min_bbo_updates:,} comparable BBO updates per stock "
            f"within {source_messages:,} source messages ({counts}). "
            "Increase --max-messages or choose a smaller --min-bbo-updates."
        )

    if message_limit is None:
        selection = {
            "mode": "minimum_bbo_updates_per_stock",
            "minimum_bbo_updates_per_stock": int(min_bbo_updates),
            "max_source_messages": int(max_messages),
        }
    else:
        selection = {
            "mode": "fixed_source_message_limit",
            "requested_source_message_limit": int(message_limit),
        }

    document = {
        "schema_version": 1,
        "metadata": {
            "dataset_filename": data_path.name,
            "source_message_limit": source_messages,
            "workload_sha256": workload_hash.hexdigest(),
            "symbols": list(SYMBOLS),
            "base_price_cents": BASE_PRICE_CENTS,
            "stock_locates": symbol_to_locate,
            "golden_source_sha256": _golden_source_hashes(),
            "selection": selection,
            "comparison_units": {
                "price": "cents",
                "shares": "shares",
            },
            "notes": (
                "Per-stock hardware-visible BBO-change sequences. Golden states "
                "with a non-empty BBO side below that stock's configured hardware "
                "base price are excluded. The exact source prefix is frozen by "
                "source_message_limit and workload_sha256."
            ),
        },
        "stocks": {
            symbol: {
                "expected_updates": len(sequences[symbol]),
                "skipped_unrepresentable_states": skipped_unrepresentable[symbol],
                "bbo_updates": sequences[symbol],
            }
            for symbol in SYMBOLS
        },
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = output_path.with_suffix(output_path.suffix + ".tmp")
    with temp_path.open("w", encoding="utf-8") as handle:
        json.dump(document, handle, indent=2, sort_keys=True)
        handle.write("\n")
    temp_path.replace(output_path)

    return document


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate the fixed three-stock showcase oracle"
    )
    parser.add_argument(
        "--data",
        type=Path,
        default=ROOT / "data" / "12302019.NASDAQ_ITCH50.gz",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "oracle" / "demo_oracle.json",
    )
    parser.add_argument(
        "--message-limit",
        type=int,
        default=None,
        help=(
            "Use an explicit BinaryFILE source-message prefix. If omitted, the "
            "generator automatically finds a prefix with enough BBO activity "
            "for every showcase stock."
        ),
    )
    parser.add_argument(
        "--min-bbo-updates",
        type=int,
        default=DEFAULT_MIN_BBO_UPDATES,
        help=(
            "Adaptive-mode target: minimum comparable BBO updates required for "
            "each of AAPL/MSFT/NFLX."
        ),
    )
    parser.add_argument(
        "--max-messages",
        type=int,
        default=DEFAULT_MAX_MESSAGES,
        help="Adaptive-mode safety cap on the source prefix scan.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    document = generate(
        args.data.resolve(),
        args.output.resolve(),
        message_limit=args.message_limit,
        min_bbo_updates=int(args.min_bbo_updates),
        max_messages=int(args.max_messages),
    )

    print()
    print("Oracle generated successfully")
    print(f"  file:      {args.output.resolve()}")
    print(f"  messages:  {document['metadata']['source_message_limit']:,}")
    print(f"  SHA-256:   {document['metadata']['workload_sha256']}")
    for symbol in SYMBOLS:
        stock = document["stocks"][symbol]
        print(
            f"  {symbol}: "
            f"{stock['expected_updates']:,} expected BBO updates, "
            f"{stock['skipped_unrepresentable_states']:,} "
            "unrepresentable golden states skipped"
        )


if __name__ == "__main__":
    main()
