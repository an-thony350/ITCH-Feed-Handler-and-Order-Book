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

class Op(Enum):
    ADD = "ADD"
    EXECUTE = "EXECUTE"
    CANCEL = "CANCEL"
    DELETE = "DELETE"
    REPLACE = "REPLACE"

class Side(Enum):
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

    shares: Optional[int] = None

    timestamp_ns: Optional[int] = None

@dataclass(frozen=True)
class Bbo:
    bid_price: Optional[int]
    bid_size: int
    ask_price: Optional[int]
    ask_size: Optional[int]

@dataclass(frozen=True)
class BookState:
    msg_index: int
    bbo: Bbo

    bid_levels: dict[int, int]
    ask_levels: dict[int, int]