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
    """Internal per-order state resolved by order reference."""
    side: Side
    price: int
    shares: int
    locate: int

class OrderBook:
    """Small, obvious oracle book built from frozen contract snapshots."""
    def __init__(self, *, expected_locate: int | None = None) -> None:
        self.order_table: dict[int, _OrderRecord] = {}
        self.bid_levels: dict[int, Level] = {}
        self.ask_levels: dict[int, Level] = {}
        self._expected_locate = expected_locate

    def apply(self, event: NormalisedEvent) -> None:
        """Apply one normalised event to the book."""
        self._assert_expected_locate(event)
        if event.op is Op.ADD:
            self._apply_add(event)
            return
        if event.op is Op.DELETE:
            self._apply_delete(event)
            return

        raise self._fail(event, f"{event.op.value} is not implemented yet")

    def bbo(self) -> Bbo:
        """Recompute the top of book from occupied price levels."""
        bid_price = max(self.bid_levels) if self.bid_levels else None
        ask_price = min(self.ask_levels) if self.ask_levels else None
        return Bbo(
            bid_price=bid_price,
            bid_size=self.bid_levels[bid_price].shares if bid_price is not None else None,
            ask_price=ask_price,
            ask_size=self.ask_levels[ask_price].shares if ask_price is not None else None,
        )

    def snapshot(self, msg_index: int) -> BookState:
        """Return a stable compare snapshot of the current book state."""
        return BookState(
            msg_index=msg_index,
            bbo=self.bbo(),
            bid_levels=dict(self.bid_levels),
            ask_levels=dict(self.ask_levels),
        )

    def _apply_add(self, event: NormalisedEvent) -> None:
        if event.order_ref in self.order_table:
            raise self._fail(event, f"ADD reused order_ref {event.order_ref}")

        price = self._required(event, "price", event.price)
        shares = self._required(event, "shares", event.shares)
        self.order_table[event.order_ref] = _OrderRecord(
            side=event.side,
            price=price,
            shares=shares,
            locate=event.locate,
        )
        self._increase_level(event, event.side, price, shares)

    def _apply_delete(self, event: NormalisedEvent) -> None:
        record = self.order_table.pop(event.order_ref, None)
        if record is None:
            raise self._fail(event, f"DELETE for unknown order_ref {event.order_ref}")

        self._decrease_level(
            event,
            record.side,
            record.price,
            shares_delta=record.shares,
            count_delta=1,
        )

    def _increase_level(
        self, event: NormalisedEvent, side: Side, price: int, shares: int
    ) -> None:
        levels = self._levels_for_side(event, side)
        old_level = levels.get(price)
        if old_level is None:
            levels[price] = Level(shares=shares, order_count=1)
            return

        levels[price] = Level(
            shares=old_level.shares + shares,
            order_count=old_level.order_count + 1,
        )

    def _decrease_level(
        self,
        event: NormalisedEvent,
        side: Side,
        price: int,
        *,
        shares_delta: int,
        count_delta: int,
    ) -> None:
        levels = self._levels_for_side(event, side)
        old_level = levels.get(price)
        if old_level is None:
            raise self._fail(event, f"cannot decrease missing price level {price}")

        new_shares = old_level.shares - shares_delta
        new_count = old_level.order_count - count_delta
        if new_shares < 0:
            raise self._fail(
                event,
                f"price level {price} shares would go negative: {new_shares}",
            )
        if new_count < 0:
            raise self._fail(
                event,
                f"price level {price} order_count would go negative: {new_count}",
            )

        if new_count == 0:
            if new_shares != 0:
                raise self._fail(
                    event,
                    f"empty price level {price} has {new_shares} remaining shares",
                )
            del levels[price]
            return

        levels[price] = Level(shares=new_shares, order_count=new_count)

    def _levels_for_side(
        self, event: NormalisedEvent, side: Side
    ) -> dict[int, Level]:
        if side is Side.BUY:
            return self.bid_levels
        if side is Side.SELL:
            return self.ask_levels
        raise self._fail(event, "book update requires BUY or SELL side")

    def _assert_expected_locate(self, event: NormalisedEvent) -> None:
        if self._expected_locate is None:
            return
        if event.locate != self._expected_locate:
            raise self._fail(
                event,
                f"unexpected locate {event.locate}, expected {self._expected_locate}",
            )

    @staticmethod
    def _required(event: NormalisedEvent, name: str, value: int | None) -> int:
        if value is None:
            raise OrderBook._fail(event, f"{name} is required")
        return value

    @staticmethod
    def _fail(event: NormalisedEvent, message: str) -> AssertionError:
        return AssertionError(f"msg_index={event.msg_index}: {message}")
