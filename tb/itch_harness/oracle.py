"""Golden-oracle loading helpers for cocotb RTL tests.

The golden runner emits two JSONL files:

    build/golden/events.jsonl
        One normalised event per line. Used to drive/check decoder/order-book
        inputs.

    build/golden/states.jsonl
        One expected book state per line. Used to check order-book BBO output.

This module only loads and sanity-checks those files. It does not know anything
about RTL signals or bit layouts; that belongs in layout.py and scoreboard.py.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_GOLDEN_DIR = Path("build/golden")
EVENTS_FILENAME = "events.jsonl"
STATES_FILENAME = "states.jsonl"

JsonRecord = dict[str, Any]


@dataclass(frozen=True)
class GoldenOracle:
    """Matched event/state oracle streams from the golden model."""

    events: list[JsonRecord]
    states: list[JsonRecord]
    events_path: Path
    states_path: Path

    def __post_init__(self) -> None:
        if len(self.events) != len(self.states):
            raise ValueError(
                "golden oracle length mismatch: "
                f"{len(self.events)} events vs {len(self.states)} states"
            )

        for index, (event, state) in enumerate(zip(self.events, self.states)):
            event_msg_index = event.get("msg_index")
            state_msg_index = state.get("msg_index")
            if event_msg_index != state_msg_index:
                raise ValueError(
                    "golden oracle msg_index mismatch at oracle row "
                    f"{index}: event msg_index={event_msg_index}, "
                    f"state msg_index={state_msg_index}"
                )

    @property
    def count(self) -> int:
        return len(self.events)

    def event_state_pairs(self) -> list[tuple[JsonRecord, JsonRecord]]:
        """Return matched ``(event, state)`` pairs."""

        return list(zip(self.events, self.states))


def load_oracle(
    *,
    golden_dir: str | Path | None = None,
    events_path: str | Path | None = None,
    states_path: str | Path | None = None,
) -> GoldenOracle:
    """Load the matched golden event/state streams.

    Priority:
    1. Explicit ``events_path`` / ``states_path`` if supplied.
    2. Explicit ``golden_dir`` if supplied.
    3. ``GOLDEN_DIR`` environment variable if set.
    4. Auto-detect ``build/golden`` from either repo root or ``tb/``.
    """

    if events_path is not None or states_path is not None:
        if events_path is None or states_path is None:
            raise ValueError("pass both events_path and states_path, or neither")

        resolved_events_path = Path(events_path)
        resolved_states_path = Path(states_path)
    else:
        resolved_golden_dir = _resolve_golden_dir(golden_dir)
        resolved_events_path = resolved_golden_dir / EVENTS_FILENAME
        resolved_states_path = resolved_golden_dir / STATES_FILENAME

    events = load_jsonl(resolved_events_path)
    states = load_jsonl(resolved_states_path)

    return GoldenOracle(
        events=events,
        states=states,
        events_path=resolved_events_path,
        states_path=resolved_states_path,
    )


def load_events(path: str | Path | None = None) -> list[JsonRecord]:
    """Load only the normalised-event oracle stream."""

    if path is None:
        path = _resolve_golden_dir(None) / EVENTS_FILENAME
    return load_jsonl(path)


def load_states(path: str | Path | None = None) -> list[JsonRecord]:
    """Load only the book-state oracle stream."""

    if path is None:
        path = _resolve_golden_dir(None) / STATES_FILENAME
    return load_jsonl(path)


def load_jsonl(path: str | Path) -> list[JsonRecord]:
    """Load newline-delimited JSON records from ``path``."""

    resolved_path = Path(path)
    if not resolved_path.exists():
        raise FileNotFoundError(
            f"golden oracle file not found: {resolved_path}\n"
            "Run scripts/run_golden.sh from the repo root first."
        )

    records: list[JsonRecord] = []
    with resolved_path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            stripped = line.strip()
            if not stripped:
                continue

            try:
                record = json.loads(stripped)
            except json.JSONDecodeError as exc:
                raise ValueError(
                    f"{resolved_path}:{line_number}: invalid JSONL record"
                ) from exc

            if not isinstance(record, dict):
                raise ValueError(
                    f"{resolved_path}:{line_number}: expected JSON object, "
                    f"got {type(record).__name__}"
                )

            records.append(record)

    return records


def _resolve_golden_dir(golden_dir: str | Path | None) -> Path:
    if golden_dir is not None:
        return Path(golden_dir)

    env_golden_dir = os.environ.get("GOLDEN_DIR")
    if env_golden_dir:
        return Path(env_golden_dir)

    candidates = [
        Path.cwd() / DEFAULT_GOLDEN_DIR,
        Path.cwd().parent / DEFAULT_GOLDEN_DIR,
    ]

    for candidate in candidates:
        if (candidate / EVENTS_FILENAME).exists() and (
            candidate / STATES_FILENAME
        ).exists():
            return candidate

    return DEFAULT_GOLDEN_DIR
