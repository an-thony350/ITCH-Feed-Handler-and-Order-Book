"""
- test against NormalisedEvent
- Maintains:
    - An Order Table: referenced by order_id, ordinary dict
    - Price Level Aggregates: two dicts keyed by price
    - the BBO

- Implements the lifecycle rules for each operation
"""

from __future__ import annotations
from dataclasses import dataclass
from golden.contracts import Bbo, BookState, NormalisedEvent, Op, Side, Level

@dataclass(frozen=True, slots=True)
class _OrderRecord:
    side: Side
    price: int
    shares: int
    locate: int

class OrderBook:
    def __init__(self, *, expected_locate: int | None = None) -> None:
        self.order_table: dict[int, _OrderRecord] = {}
        self.bid_levels: dict[int, Level] = {}
        self.ask_levels: dict[int, Level] = {}
        self.expected_locate = expected_locate

    def apply(self, event: NormalisedEvent) -> None:
        """Apply one normalised event to the book."""
        self._assert_expected_locate(event)
        if event.op == Op.ADD:
            self._apply_add(event)
            return

        self._fail(event, f"{event.op.value} is not implemented yet")

    def bbo(self) -> Bbo:
        """Recompute the top of book from occupied price levels"""
        bid_price = max(self.bid_levels) if self.bid_levels else None
        ask_price = min(self.ask_levels) if self.ask_levels else None
        return Bbo(
            bid_price=bid_price,
            bid_size=self.bid_levels[bid_price].shares if bid_price is not None else None,
            ask_price=ask_price,
            ask_size=self.ask_levels[ask_price].shares if ask_price is not None else None,
        )

    def snapshot(self, msg_index: int) -> BookState:
        """Return a snapshot of the current book state."""
        return BookState(
            msg_index=msg_index,
            bbo=self.bbo(),
            bid_levels=dict(self.bid_levels),
            ask_levels=dict(self.ask_levels),
        )

    def _apply_add(self, event: NormalisedEvent) -> None:
        """Apply an ADD event to the book."""
        if event.order_ref in self.order_table:
            self._fail(event, f"ADD with duplicate order_ref {event.order_ref}")

        price = self._required(event, "price", event.price)
        shares = self._required(event, "shares", event.shares)

        self.order_table[event.order_ref] = _OrderRecord(
            side=event.side,
            price=price,
            shares=shares,
            locate=event.locate,
        )
        self._increase_level(event, event.side, price, shares)

    def _increase_level(self, event: NormalisedEvent, side: Side, price: int, shares: int) -> None:
        """Increase the shares and order count at a price level."""
        levels = self._levels_for_side(event, side)
        old_level = levels.get(price)
        if old_level is None:
            levels[price] = Level(shares=shares, order_count=1)
            return

        levels[price] = Level(shares=old_level.shares + shares, order_count=old_level.order_count + 1)

    def _levels_for_side(self, event: NormalisedEvent, side: Side) -> dict[int, Level]:
        """Return the price level dict for the given side."""
        if side == Side.BUY:
            return self.bid_levels
        if side == Side.SELL:
            return self.ask_levels
        self._fail(event, f"Unknown side {side}")

    def _assert_expected_locate(self, event: NormalisedEvent) -> None:
        if self.expected_locate is None:
            return
        if self.expected_locate != event.locate:
            self._fail(event, f"Expected locate {self.expected_locate}, got {event.locate}")

    @staticmethod
    def _required(event: NormalisedEvent, name: str, value: int | None) -> int:
        if value is None:
            OrderBook._fail(event, f"Missing required field {name}")
        return value

    @staticmethod
    def _fail(event: NormalisedEvent, message: str) -> None:
        raise AssertionError(f"msg_index={event.msg_index}: {message}")
