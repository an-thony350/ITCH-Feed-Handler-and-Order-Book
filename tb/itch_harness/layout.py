"""Bit layout helpers for the RTL/golden-model cocotb harness.

The RTL currently has two closely related packed event structs:

Order-book input ``o_data_t`` layout, MSB first:
    message_type [200:193]
    orn          [192:129]
    updated_orn  [128:65]
    side         [64]
    shares       [63:32]
    price        [31:0]

Decoder output ``data_t`` layout, MSB first:
    message_type [216:209]
    stock_locate [208:193]
    orn          [192:129]
    updated_orn  [128:65]
    side         [64]
    shares       [63:32]
    price        [31:0]

RTL bbo_t layout, MSB first:
    bid_price    [127:96]
    bid_shares   [95:64]
    ask_price    [63:32]
    ask_shares   [31:0]
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


# Existing order_book.sv input width. Keep DATA_W as this value because the
# current order-book cocotb drivers use pack_data_t() to drive rdata_i.
DATA_W = 201
O_DATA_T_W = DATA_W

# data_handler.sv output width. Decoder-isolation scoreboards should use
# unpack_data_t() / pack_decoder_data_t() for this wider layout.
DECODER_DATA_W = 217

BBO_W = 128

MSG_W = 8
LOCATE_W = 16
ORDER_REF_W = 64
SIDE_W = 1
SHARES_W = 32
PRICE_W = 32


ITCH_ADD = ord("A")              # 0x41
ITCH_ADD_WITH_MPID = ord("F")    # 0x46
ITCH_EXECUTE = ord("E")          # 0x45
ITCH_EXECUTE_PRICE = ord("C")    # 0x43
ITCH_CANCEL = ord("X")           # 0x58
ITCH_DELETE = ord("D")           # 0x44
ITCH_REPLACE = ord("U")          # 0x55


OP_TO_MSG_TYPE = {
    "ADD": ITCH_ADD,
    "EXECUTE": ITCH_EXECUTE,
    "CANCEL": ITCH_CANCEL,
    "DELETE": ITCH_DELETE,
    "REPLACE": ITCH_REPLACE,
}


@dataclass(frozen=True)
class Field:
    """A field inside a packed RTL bit vector."""

    lsb: int
    width: int

    @property
    def mask(self) -> int:
        return (1 << self.width) - 1


# o_data_t / order_book.rdata_i, 201 bits.
DATA_FIELDS = {
    "price": Field(0, 32),
    "shares": Field(32, 32),
    "side": Field(64, 1),
    "updated_orn": Field(65, 64),
    "orn": Field(129, 64),
    "message_type": Field(193, 8),
}

O_DATA_FIELDS = DATA_FIELDS


# data_t / data_handler.rdata_o, 217 bits.
DECODER_DATA_FIELDS = {
    "price": Field(0, 32),
    "shares": Field(32, 32),
    "side": Field(64, 1),
    "updated_orn": Field(65, 64),
    "orn": Field(129, 64),
    "stock_locate": Field(193, 16),
    "message_type": Field(209, 8),
}

BBO_FIELDS = {
    "ask_shares": Field(0, 32),
    "ask_price": Field(32, 32),
    "bid_shares": Field(64, 32),
    "bid_price": Field(96, 32),
}


def insert_field(word: int, field: Field, value: int) -> int:
    """Insert an integer field into a packed word."""

    if value < 0:
        raise ValueError(f"value must be non-negative, got {value}")
    if value > field.mask:
        raise ValueError(
            f"value {value} does not fit in {field.width} bits "
            f"(max {field.mask})"
        )

    word &= ~(field.mask << field.lsb)
    word |= value << field.lsb
    return word


def extract_field(word: int, field: Field) -> int:
    """Extract an integer field from a packed word."""

    return (word >> field.lsb) & field.mask


def pack_data_t(event: dict[str, Any]) -> int:
    """Pack one events.jsonl record into the RTL o_data_t vector.

    This is used for order_book isolation tests where the golden normalised
    event is driven directly into order_book.rdata_i. That port is still
    ``o_data_t`` / 201 bits and does not contain stock_locate.
    """

    return _pack_event(event, fields=DATA_FIELDS, width=DATA_W, include_locate=False)


def pack_o_data_t(event: dict[str, Any]) -> int:
    """Explicit alias for packing the order-book input o_data_t layout."""

    return pack_data_t(event)


def pack_decoder_data_t(event: dict[str, Any]) -> int:
    """Pack one events.jsonl record into the RTL data_t decoder-output vector."""

    return _pack_event(
        event,
        fields=DECODER_DATA_FIELDS,
        width=DECODER_DATA_W,
        include_locate=True,
    )


def unpack_data_t(word: int) -> dict[str, int]:
    """Unpack a decoder-output data_t vector into raw integer fields."""

    return {
        name: extract_field(word, field)
        for name, field in DECODER_DATA_FIELDS.items()
    }


def unpack_o_data_t(word: int) -> dict[str, int]:
    """Unpack an order-book input o_data_t vector into raw integer fields."""

    return {name: extract_field(word, field) for name, field in DATA_FIELDS.items()}


def unpack_bbo_t(word: int) -> dict[str, int]:
    """Unpack an RTL bbo_t vector into raw integer BBO fields."""

    return {name: extract_field(word, field) for name, field in BBO_FIELDS.items()}


def expected_bbo_to_rtl_dict(bbo: dict[str, Any]) -> dict[str, int]:
    """Convert golden JSON BBO into the initial RTL comparison format.

    The golden model uses None/null for an empty bid or ask. The current RTL
    bbo_t has no valid bits, so the first harness maps empty sides to zero.

    Later, if the RTL adds bid_valid/ask_valid bits, replace this conversion.
    """

    return {
        "bid_price": _none_to_zero(bbo.get("bid_price")),
        "bid_shares": _none_to_zero(bbo.get("bid_size")),
        "ask_price": _none_to_zero(bbo.get("ask_price")),
        "ask_shares": _none_to_zero(bbo.get("ask_size")),
    }


def message_type_matches_op(message_type: int, op: str) -> bool:
    """Return whether an RTL message_type is compatible with a golden op."""

    if op == "ADD":
        return message_type in (ITCH_ADD, ITCH_ADD_WITH_MPID)
    if op == "EXECUTE":
        return message_type in (ITCH_EXECUTE, ITCH_EXECUTE_PRICE)

    expected = OP_TO_MSG_TYPE.get(op)
    return expected is not None and message_type == expected


def _pack_event(
    event: dict[str, Any],
    *,
    fields: dict[str, Field],
    width: int,
    include_locate: bool,
) -> int:
    op = event["op"]
    try:
        message_type = OP_TO_MSG_TYPE[op]
    except KeyError as exc:
        raise ValueError(f"unsupported op for RTL packing: {op!r}") from exc

    word = 0
    word = insert_field(word, fields["message_type"], message_type)
    if include_locate:
        word = insert_field(word, fields["stock_locate"], int(event["locate"]))
    word = insert_field(word, fields["orn"], int(event["order_ref"]))
    word = insert_field(
        word,
        fields["updated_orn"],
        _none_to_zero(event.get("new_order_ref")),
    )
    word = insert_field(word, fields["side"], _pack_side(event.get("side")))
    word = insert_field(word, fields["shares"], _none_to_zero(event.get("shares")))
    word = insert_field(word, fields["price"], _none_to_zero(event.get("price")))

    if word >= (1 << width):
        raise ValueError(f"packed event exceeds {width} bits: {word:#x}")

    return word


def _pack_side(side: Any) -> int:
    """Map golden side strings to the RTL side bit.

    RTL convention:
        BUY  -> 1
        SELL -> 0
        UNKNOWN/non-ADD -> 0
    """

    if side == "BUY":
        return 1
    if side in ("SELL", "UNKNOWN", None):
        return 0
    raise ValueError(f"unsupported side value: {side!r}")


def _none_to_zero(value: Any) -> int:
    return 0 if value is None else int(value)
