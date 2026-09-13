"""Load and compare the fixed three-stock demo oracle."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


SYMBOLS = ("AAPL", "MSFT", "NFLX")
BASE_PRICE_CENTS = {
    "AAPL": 21_000,
    "MSFT": 12_000,
    "NFLX": 32_000,
}


def _normalise_hw_bbo(
    bid_price: int,
    bid_size: int,
    ask_price: int,
    ask_size: int,
) -> dict[str, int | None]:
    bid_valid = int(bid_price) if int(bid_size) != 0 else None
    ask_valid = int(ask_price) if int(ask_size) != 0 else None

    return {
        "bid_price_cents": bid_valid,
        "bid_size": int(bid_size) if bid_valid is not None else None,
        "ask_price_cents": ask_valid,
        "ask_size": int(ask_size) if ask_valid is not None else None,
    }


class OracleVerifier:
    """Positionally compare each emitted hardware BBO against its stock oracle."""

    def __init__(
        self,
        path: str | Path,
        *,
        message_limit: int | None = None,
    ) -> None:
        self.path = Path(path)
        if not self.path.is_file():
            raise FileNotFoundError(
                f"Oracle not found: {self.path}. "
                "Run generate_oracle.py once before starting the final demo."
            )

        with self.path.open("r", encoding="utf-8") as handle:
            self.document = json.load(handle)

        self.message_limit = self._validate_schema(message_limit)

        self.expected = {
            symbol: self.document["stocks"][symbol]["bbo_updates"]
            for symbol in SYMBOLS
        }
        # positions tracks the next expected oracle entry. observed_positions
        # is separate so a detected gap can resynchronise the expected stream
        # without corrupting the number of hardware updates actually observed.
        self.positions = {symbol: 0 for symbol in SYMBOLS}
        self.observed_positions = {symbol: 0 for symbol in SYMBOLS}
        self.comparisons = 0
        self.mismatches = 0
        self.latched_fail = False
        self.first_mismatch: dict[str, Any] | None = None

    def _validate_schema(self, message_limit: int | None) -> int:
        if self.document.get("schema_version") != 1:
            raise ValueError("Unsupported oracle schema_version")

        metadata = self.document.get("metadata", {})
        oracle_limit = int(metadata.get("source_message_limit", -1))
        if oracle_limit <= 0:
            raise ValueError("Oracle source_message_limit must be greater than zero")

        if message_limit is not None and oracle_limit != int(message_limit):
            raise ValueError(
                f"Oracle message limit is {oracle_limit:,}, but demo requested "
                f"{int(message_limit):,}"
            )

        oracle_bases = metadata.get("base_price_cents", {})
        if oracle_bases != BASE_PRICE_CENTS:
            raise ValueError(
                f"Oracle base-price configuration {oracle_bases} does not match "
                f"demo configuration {BASE_PRICE_CENTS}"
            )

        stocks = self.document.get("stocks", {})
        missing = [symbol for symbol in SYMBOLS if symbol not in stocks]
        if missing:
            raise ValueError(
                "Oracle is missing stock section(s): " + ", ".join(missing)
            )

        return oracle_limit

    @property
    def total_expected(self) -> int:
        return sum(len(self.expected[symbol]) for symbol in SYMBOLS)

    @property
    def expected_by_stock(self) -> dict[str, int]:
        return {
            symbol: len(self.expected[symbol])
            for symbol in SYMBOLS
        }

    def observe(
        self,
        symbol: str,
        bid_price: int,
        bid_size: int,
        ask_price: int,
        ask_size: int,
    ) -> dict[str, Any]:
        if symbol not in self.expected:
            raise ValueError(f"Unexpected hardware stock symbol: {symbol}")

        expected_position = self.positions[symbol]
        observed_index = self.observed_positions[symbol]
        actual = _normalise_hw_bbo(
            bid_price,
            bid_size,
            ask_price,
            ask_size,
        )

        expected_stream = self.expected[symbol]
        expected = (
            expected_stream[expected_position]
            if expected_position < len(expected_stream)
            else None
        )
        matched = actual == expected

        self.observed_positions[symbol] += 1
        self.comparisons += 1

        if matched:
            self.positions[symbol] += 1
        else:
            # A positional comparator makes one missed observation shift every
            # later comparison.  Search forward for this actual state so a real
            # gap is reported once and the streams are then re-aligned.
            resynchronised_to = None
            if expected_position < len(expected_stream):
                for index in range(expected_position + 1, len(expected_stream)):
                    if expected_stream[index] == actual:
                        resynchronised_to = index
                        break

            if resynchronised_to is not None:
                missing_count = resynchronised_to - expected_position
                self.mismatches += missing_count
                self.latched_fail = True

                if self.first_mismatch is None:
                    self.first_mismatch = {
                        "reason": "missing_hardware_bbo_updates",
                        "symbol": symbol,
                        "bbo_index": observed_index,
                        "expected_index": expected_position,
                        "resynchronised_to_expected_index": resynchronised_to,
                        "missing_count": missing_count,
                        "expected": expected,
                        "actual": actual,
                    }

                # The current actual value is valid; it corresponds to this
                # later oracle entry.  Continue from the following entry rather
                # than cascading the positional error through the whole stream.
                self.positions[symbol] = resynchronised_to + 1

            else:
                self.mismatches += 1
                self.latched_fail = True

                reason = (
                    "extra_hardware_bbo_update"
                    if expected_position >= len(expected_stream)
                    else "unexpected_hardware_bbo_state"
                )
                if self.first_mismatch is None:
                    self.first_mismatch = {
                        "reason": reason,
                        "symbol": symbol,
                        "bbo_index": observed_index,
                        "expected_index": expected_position,
                        "expected": expected,
                        "actual": actual,
                    }

                # Keep the expected pointer in place.  If this was one spurious
                # hardware observation, the next correct state can immediately
                # match without shifting all subsequent comparisons.

        return {
            "matched": matched,
            "symbol": symbol,
            "bbo_index": observed_index,
            "expected": expected,
            "actual": actual,
            "comparisons": self.comparisons,
            "mismatches": self.mismatches,
            "latched_fail": self.latched_fail,
        }

    def finalise(
        self,
        *,
        source_messages: int,
        workload_sha256: str,
    ) -> dict[str, Any]:
        metadata = self.document["metadata"]

        if int(source_messages) != int(metadata["source_message_limit"]):
            self._latch_summary_failure(
                "source_message_count",
                expected=int(metadata["source_message_limit"]),
                actual=int(source_messages),
            )

        expected_hash = str(metadata["workload_sha256"])
        if workload_sha256 != expected_hash:
            self._latch_summary_failure(
                "workload_sha256",
                expected=expected_hash,
                actual=workload_sha256,
            )

        remaining = {
            symbol: len(self.expected[symbol]) - self.positions[symbol]
            for symbol in SYMBOLS
        }
        missing_total = sum(max(0, value) for value in remaining.values())
        if missing_total:
            self._latch_summary_failure(
                "missing_hardware_bbo_updates_at_end",
                expected={symbol: len(self.expected[symbol]) for symbol in SYMBOLS},
                actual=dict(self.observed_positions),
                mismatch_increment=missing_total,
            )

        return self.snapshot()

    def _latch_summary_failure(
        self,
        reason: str,
        *,
        expected: Any,
        actual: Any,
        mismatch_increment: int = 1,
    ) -> None:
        self.mismatches += int(mismatch_increment)
        self.latched_fail = True
        if self.first_mismatch is None:
            self.first_mismatch = {
                "reason": reason,
                "expected": expected,
                "actual": actual,
            }

    def snapshot(self) -> dict[str, Any]:
        return {
            "enabled": True,
            "expected_total": self.total_expected,
            "expected_by_stock": self.expected_by_stock,
            "observed_by_stock": dict(self.observed_positions),
            "comparisons": self.comparisons,
            "mismatches": self.mismatches,
            "latched_fail": self.latched_fail,
            "first_mismatch": self.first_mismatch,
        }
