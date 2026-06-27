# defines the types of contracts that can be used in the golden framework
"""
Need a couple of things
- Op: enumerations of the operations the book understands
- Side: enumerations of the sides the book understands
- NormalisedEvent: a class that represents a normalised event that the book understands
    - op
    - locate
    - side
    - order_ref
    - price
    - shares
    - msg_index
    - maybe some other things im forgetting
- Bbo: top of book representation
- BookState: a class that represents the state of the book at a given time
"""

from dataclasses import dataclass
from enum import Enum
from typing import Optional

LOCATE_BITS = 16
ORDER_REF_BITS = 64
PRICE_BITS = 32
SHARES_BITS = 32
TIMESTAMP_BITS = 48

class Op(str, Enum):
    ADD = "ADD"
    EXECUTE = "EXECUTE"
    CANCEL = "CANCEL"
    DELETE = "DELETE"
    REPLACE = "REPLACE"

class Side(str, Enum):
    BUY = "BUY"
    SELL = "SELL"
    UNKNOWN = "UNKNOWN"

@dataclass(frozen=True) # frozen true to prevent changes to state after creation
class NormalisedEvent:
    op: Op
    locate: int
    side: Side
    order_ref: int
    msg_index: int

    price: Optional[int] = None

    shares: Optional[int] = None

    new_order_ref: Optional[int] = None

    timestamp_ns: Optional[int] = None

    def __post_init__(self) -> None:
        self._check_common_widths()
        if self.op == Op.ADD:
            assert self.side in (Side.BUY, Side.SELL), f"ADD at msg {self.msg_index} must have BUY or SELL side"
            assert self.price is not None, f"ADD at msg {self.msg_index} missing price"
            assert self.shares is not None, f"ADD at msg {self.msg_index} missing shares"
            assert (self.new_order_ref is None), f"ADD at msg {self.msg_index} must not set new_order_ref" 
            self._check_width("price", self.price, PRICE_BITS) 
            self._check_width("shares", self.shares, SHARES_BITS)
        
        elif self.op == Op.EXECUTE:
            assert (self.side == Side.UNKNOWN), f"EXECUTE at msg {self.msg_index} must have UNKNOWN side"
            assert self.price is None, f"EXECUTE at msg {self.msg_index} must not set price"
            assert (self.shares is not None), f"EXECUTE at msg {self.msg_index} missing shares"
            assert (self.new_order_ref is None), f"EXECUTE at msg {self.msg_index} must not set new_order_ref"
            self._check_width("shares", self.shares, SHARES_BITS)

        elif self.op == Op.CANCEL:
            assert (self.side == Side.UNKNOWN), f"CANCEL at msg {self.msg_index} must have UNKNOWN side"
            assert self.price is None, f"CANCEL at msg {self.msg_index} must not set price"
            assert (self.shares is not None), f"CANCEL at msg {self.msg_index} missing shares"
            assert (self.new_order_ref is None), f"CANCEL at msg {self.msg_index} must not set new_order_ref"
            self._check_width("shares", self.shares, SHARES_BITS)
        
        elif self.op == Op.DELETE:
            assert (self.side == Side.UNKNOWN), f"DELETE at msg {self.msg_index} must have UNKNOWN side"
            assert self.price is None, f"DELETE at msg {self.msg_index} must not set price"
            assert (self.shares is None), f"DELETE at msg {self.msg_index} must not set shares"
            assert (self.new_order_ref is None), f"DELETE at msg {self.msg_index} must not set new_order_ref"

        elif self.op == Op.REPLACE:
            assert (self.side == Side.UNKNOWN), f"REPLACE at msg {self.msg_index} must have UNKNOWN side"
            assert (self.price is not None), f"REPLACE at msg {self.msg_index} missing new price"
            assert (self.shares is not None), f"REPLACE at msg {self.msg_index} missing new shares"
            assert (self.new_order_ref is not None), f"REPLACE at msg {self.msg_index} missing new_order_ref"
            self._check_width("price", self.price, PRICE_BITS)
            self._check_width("shares", self.shares, SHARES_BITS)
            self._check_width("new_order_ref", self.new_order_ref, ORDER_REF_BITS)
        
        else:
            raise ValueError(f"Unsupported op {self.op!r} at msg {self.msg_index}")

    def _check_common_widths(self) -> None:
        self._check_width("locate", self.locate, LOCATE_BITS)
        self._check_width("order_ref", self.order_ref, ORDER_REF_BITS)
        assert self.msg_index >= 0, f"msg_index must be non-negative: {self.msg_index}"
        if self.timestamp_ns is not None:
            self._check_width("timestamp_ns", self.timestamp_ns, TIMESTAMP_BITS)
    

    def _check_width(self, field_name: str, value: int, width_bits: int) -> None:
        assert ( 0 <= value < (1 << width_bits)), (f"{field_name} at msg {self.msg_index} must fit in {width_bits} bits, " f"got {value}")

@dataclass(frozen=True)
class Bbo:
    bid_price: Optional[int]
    bid_size: Optional[int]
    ask_price: Optional[int]
    ask_size: Optional[int]

    def __post_init__(self) -> None:
        assert (self.bid_price is None) == (self.bid_size is None), "bid_price and bid_size must both be set or both be None"
        assert (self.ask_price is None) == (self.ask_size is None), "ask_price and ask_size must both be set or both be None"

        if self.bid_price is not None:
            self._check_bbo_width("bid_price", self.bid_price, PRICE_BITS)
            self._check_bbo_width("bid_size", self.bid_size, SHARES_BITS)
        if self.ask_price is not None:
            self._check_bbo_width("ask_price", self.ask_price, PRICE_BITS)
            self._check_bbo_width("ask_size", self.ask_size, SHARES_BITS)
        
    def _check_bbo_width(self, field_name: str, value: int, width_bits: int) -> None:
        assert 0 <= value < (1 << width_bits), (f"{field_name} must fit in {width_bits} bits, got {value}")

@dataclass(frozen=True)
class Level:
    shares: int
    order_count: int

    def __post_init__(self) -> None:
        assert self.shares >= 0, f"Level shares must be non-negative, got {self.shares}"
        assert (self.order_count >= 0), f"Level order_count must be non-negative, got {self.order_count}"
        assert self.shares < (1 << SHARES_BITS), (f"Level shares must fit in {SHARES_BITS} bits, got {self.shares}")

@dataclass(frozen=True)
class BookState:
    msg_index: int
    bbo: Bbo

    bid_levels: dict[int, Level]
    ask_levels: dict[int, Level]

    def __post_init__(self) -> None:
        assert self.msg_index >= 0, f"msg_index must be non-negative: {self.msg_index}"
        self._check_levels("bid_levels", self.bid_levels)
        self._check_levels("ask_levels", self.ask_levels)
    
    def _check_levels(self, name: str, levels: dict[int, Level]) -> None:
        for price, level in levels.items():
            assert 0 <= price < (1 << PRICE_BITS), (f"{name} price must fit in {PRICE_BITS} bits, got {price}")
            assert isinstance(level, Level), (f"{name}[{price}] must be a Level, got {type(level).__name__}")