"""
- test against NormalisedEvent
- Maintains:
    - An Order Table: referenced by order_id, ordinary dict
    - Price Level Aggregates: two dicts keyed by price
    - the BBO

- Implements the lifecycle rules for each operation
"""

from __future__ import annotations

from dataclasses import dataclass, replace

from golden.contracts import Bbo, BookState, Level, NormalisedEvent, Op, Side


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
        if event.op is Op.EXECUTE:
            self._apply_execute(event)
            return
        if event.op is Op.CANCEL:
            self._apply_cancel(event)
            return
        if event.op is Op.DELETE:
            self._apply_delete(event)
            return
        if event.op is Op.REPLACE:
            self._apply_replace(event)
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
        price = self._required(event, "price", event.price)
        shares = self._required(event, "shares", event.shares)
        self._add_order(
            event,
            order_ref=event.order_ref,
            side=event.side,
            price=price,
            shares=shares,
        )

    def _apply_execute(self, event: NormalisedEvent) -> None:
        self._reduce_order(event)

    def _apply_cancel(self, event: NormalisedEvent) -> None:
        self._reduce_order(event)

    def _apply_delete(self, event: NormalisedEvent) -> None:
        record = self.order_table.get(event.order_ref)
        if record is None:
            raise self._fail(event, f"DELETE for unknown order_ref {event.order_ref}")

        self._remove_order(
            event,
            order_ref=event.order_ref,
            side=record.side,
            price=record.price,
            shares=record.shares,
        )

    def _apply_replace(self, event: NormalisedEvent) -> None:
        record = self.order_table.get(event.order_ref)
        if record is None:
            raise self._fail(event, f"REPLACE for unknown order_ref {event.order_ref}")

        original_side = record.side
        original_price = record.price
        original_shares = record.shares
        new_order_ref = self._required(event, "new_order_ref", event.new_order_ref)
        new_price = self._required(event, "price", event.price)
        new_shares = self._required(event, "shares", event.shares)
        if new_order_ref != event.order_ref and new_order_ref in self.order_table:
            raise self._fail(event, f"REPLACE reused new_order_ref {new_order_ref}")

        levels = self._levels_for_side(event, original_side)
        original_level = levels.get(original_price)
        if original_level is None:
            raise self._fail(
                event,
                f"cannot replace from missing price level {original_price}",
            )

        removed_level = self._level_after_decrease(
            event,
            original_price,
            original_level,
            shares_delta=original_shares,
            count_delta=1,
        )
        if new_price == original_price:
            add_base = removed_level
        else:
            add_base = levels.get(new_price)
        added_level = self._level_after_increase(add_base, new_shares)

        if new_price != original_price:
            if removed_level is None:
                del levels[original_price]
            else:
                levels[original_price] = removed_level
        levels[new_price] = added_level

        if new_order_ref != event.order_ref:
            del self.order_table[event.order_ref]
        self.order_table[new_order_ref] = _OrderRecord(
            side=original_side,
            price=new_price,
            shares=new_shares,
            locate=event.locate,
        )

    def _reduce_order(self, event: NormalisedEvent) -> None:
        record = self.order_table.get(event.order_ref)
        if record is None:
            raise self._fail(
                event,
                f"{event.op.value} for unknown order_ref {event.order_ref}",
            )

        shares_delta = self._required(event, "shares", event.shares)
        if shares_delta > record.shares:
            raise self._fail(
                event,
                f"{event.op.value} for {shares_delta} shares exceeds "
                f"order_ref {event.order_ref} remaining shares {record.shares}",
            )

        remaining = record.shares - shares_delta
        if remaining > 0:
            self._decrease_level(
                event,
                record.side,
                record.price,
                shares_delta=shares_delta,
                count_delta=0,
            )
            self.order_table[event.order_ref] = replace(record, shares=remaining)
            return

        self._decrease_level(
            event,
            record.side,
            record.price,
            shares_delta=shares_delta,
            count_delta=1,
        )
        del self.order_table[event.order_ref]

    def _add_order(
        self,
        event: NormalisedEvent,
        *,
        order_ref: int,
        side: Side,
        price: int,
        shares: int,
    ) -> None:
        if order_ref in self.order_table:
            raise self._fail(event, f"ADD reused order_ref {order_ref}")

        self.order_table[order_ref] = _OrderRecord(
            side=side,
            price=price,
            shares=shares,
            locate=event.locate,
        )
        self._increase_level(event, side, price, shares)

    def _remove_order(
        self,
        event: NormalisedEvent,
        *,
        order_ref: int,
        side: Side,
        price: int,
        shares: int,
    ) -> None:
        self._decrease_level(
            event,
            side,
            price,
            shares_delta=shares,
            count_delta=1,
        )
        del self.order_table[order_ref]

    def _increase_level(
        self, event: NormalisedEvent, side: Side, price: int, shares: int
    ) -> None:
        levels = self._levels_for_side(event, side)
        old_level = levels.get(price)
        levels[price] = self._level_after_increase(old_level, shares)

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

        new_level = self._level_after_decrease(
            event,
            price,
            old_level,
            shares_delta=shares_delta,
            count_delta=count_delta,
        )
        if new_level is None:
            del levels[price]
            return

        levels[price] = new_level

    @staticmethod
    def _level_after_increase(old_level: Level | None, shares: int) -> Level:
        if old_level is None:
            return Level(shares=shares, order_count=1)

        return Level(
            shares=old_level.shares + shares,
            order_count=old_level.order_count + 1,
        )

    def _level_after_decrease(
        self,
        event: NormalisedEvent,
        price: int,
        old_level: Level,
        *,
        shares_delta: int,
        count_delta: int,
    ) -> Level | None:
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
            return None

        return Level(shares=new_shares, order_count=new_count)

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
