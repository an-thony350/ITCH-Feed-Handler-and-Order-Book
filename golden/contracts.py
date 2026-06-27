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
        if self.op == Op.ADD:
            assert self.side in (Side.BUY, Side.SELL)
            assert self.price is not None
            assert self.shares is not None
            assert self.new_order_ref is None
        
        elif self.op == Op.EXECUTE:
            assert self.side == Side.UNKNOWN
            assert self.price is None
            assert self.shares is not None
            assert self.new_order_ref is None

        elif self.op == Op.CANCEL:
            assert self.side == Side.UNKNOWN
            assert self.price is None
            assert self.shares is not None
            assert self.new_order_ref is None
        
        elif self.op == Op.DELETE:
            assert self.side == Side.UNKNOWN
            assert self.price is None
            assert self.shares is None
            assert self.new_order_ref is None

        elif self.op == Op.REPLACE:
            assert self.side == Side.UNKNOWN
            assert self.price is not None
            assert self.shares is not None
            assert self.new_order_ref is not None

@dataclass(frozen=True)
class Bbo:
    bid_price: Optional[int]
    bid_size: Optional [int]
    ask_price: Optional[int]
    ask_size: Optional[int]

    def __post_init__(self) -> None:
        assert (self.bid_price is None) == (self.bid_size is None)
        assert (self.ask_price is None) == (self.ask_size is None)

@dataclass(frozen=True)
class Level:
    shares: int
    order_count: int

@dataclass(frozen=True)
class BookState:
    msg_index: int
    bbo: Bbo

    bid_levels: dict[int, Level]
    ask_levels: dict[int, Level]