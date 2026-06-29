"""Scoreboard helpers for comparing RTL outputs against golden JSONL records."""

from __future__ import annotations

from typing import Any

from .layout import (
    expected_bbo_to_rtl_dict,
    message_type_matches_op,
    unpack_bbo_t,
    unpack_data_t,
)


class ScoreboardError(AssertionError):
    """Raised when the RTL diverges from the golden oracle."""


def signal_value_to_int(value: Any) -> int:
    """Convert a cocotb signal value or raw value into an int."""

    try:
        return int(value)
    except ValueError as exc:
        raise ScoreboardError(f"cannot convert RTL value to int: {value!r}") from exc


def assert_bbo_matches_signal(signal: Any, state: dict[str, Any]) -> None:
    """Compare a cocotb bbo_data_o signal against one golden state record."""

    assert_bbo_matches_word(signal_value_to_int(signal.value), state)


def assert_bbo_matches_word(word: int, state: dict[str, Any]) -> None:
    """Compare a packed RTL bbo_t word against one golden state record."""

    got = unpack_bbo_t(word)
    expected = expected_bbo_to_rtl_dict(state["bbo"])
    msg_index = state.get("msg_index")
    assert_dict_matches(
        got,
        expected,
        context=f"msg_index={msg_index}: BBO mismatch",
    )


def assert_data_t_matches_signal(signal: Any, event: dict[str, Any]) -> None:
    """Compare a cocotb rdata/data_t signal against one golden event record."""

    assert_data_t_matches_word(signal_value_to_int(signal.value), event)


def assert_data_t_matches_word(word: int, event: dict[str, Any]) -> None:
    """Compare a packed RTL data_t word against one golden event record.

    This is intended for decoder isolation. It follows the same comparison mask
    as the golden contract:

    - always compare locate/order_ref/op class;
    - ADD compares side, price, shares;
    - EXECUTE compares shares;
    - CANCEL compares shares;
    - DELETE compares order_ref only beyond common fields;
    - REPLACE compares new_order_ref, price, shares;
    - never compare side on non-ADD ops.
    """

    got = unpack_data_t(word)
    msg_index = event.get("msg_index")
    op = str(event["op"])

    if not message_type_matches_op(got["message_type"], op):
        raise ScoreboardError(
            f"msg_index={msg_index}: op/message_type mismatch: "
            f"expected op={op}, got message_type=0x{got['message_type']:02x}"
        )

    checks: dict[str, tuple[int, int]] = {
        "stock_locate": (got["stock_locate"], int(event["locate"])),
        "orn": (got["orn"], int(event["order_ref"])),
    }

    if op == "ADD":
        checks["side"] = (got["side"], _expected_side_bit(event.get("side")))
        checks["price"] = (got["price"], _none_to_zero(event.get("price")))
        checks["shares"] = (got["shares"], _none_to_zero(event.get("shares")))

    elif op in ("EXECUTE", "CANCEL"):
        checks["shares"] = (got["shares"], _none_to_zero(event.get("shares")))

    elif op == "DELETE":
        pass

    elif op == "REPLACE":
        checks["updated_orn"] = (
            got["updated_orn"],
            _none_to_zero(event.get("new_order_ref")),
        )
        checks["price"] = (got["price"], _none_to_zero(event.get("price")))
        checks["shares"] = (got["shares"], _none_to_zero(event.get("shares")))

    else:
        raise ScoreboardError(f"msg_index={msg_index}: unsupported op {op!r}")

    for field, (actual, expected) in checks.items():
        if actual != expected:
            raise ScoreboardError(
                f"msg_index={msg_index}: data_t field mismatch for {field}: "
                f"expected {expected}, got {actual}; "
                f"event={event}; unpacked_rtl={got}"
            )


def assert_dict_matches(
    got: dict[str, int],
    expected: dict[str, int],
    *,
    context: str,
) -> None:
    """Compare two flat dictionaries and report all differing fields."""

    mismatches: list[str] = []
    for field, expected_value in expected.items():
        got_value = got.get(field)
        if got_value != expected_value:
            mismatches.append(f"{field}: expected {expected_value}, got {got_value}")

    if mismatches:
        raise ScoreboardError(
            f"{context}\n"
            + "\n".join(f"  - {mismatch}" for mismatch in mismatches)
            + f"\n  expected={expected}\n  got={got}"
        )


def _expected_side_bit(side: Any) -> int:
    if side == "BUY":
        return 1
    if side == "SELL":
        return 0
    raise ScoreboardError(f"ADD event has invalid side {side!r}")


def _none_to_zero(value: Any) -> int:
    return 0 if value is None else int(value)
