# Golden Model

General Idea: the golden model consumes ITCH BinaryFILE input, normalises ITCH messages into a stable event contract, replays those events through a reference order book, and emits JSONL oracle files for RTL comparison.

---

## 1. What the golden model is for

The golden model is the software source of truth for correctness. It is deliberately written as clear Python rather than as an optimised hardware-like model.

It produces two output streams:

| Output | Purpose | Used for |
|---|---|---|
| `events.jsonl` | One normalised event per accepted book-mutating ITCH message | Decoder isolation: check that RTL decoding matches Python parsing |
| `states.jsonl` | One full book snapshot after each accepted event | Order-book / full-chain verification: check BBO and price-level state |

The intended verification flow is:

```text
ITCH BinaryFILE
    -> golden.itch_parser
    -> NormalisedEvent stream
    -> golden.order_book.OrderBook
    -> events.jsonl + states.jsonl
    -> cocotb / Verilator scoreboard checks RTL
```

---

## 2. Source files

| File | Role |
|---|---|
| `contracts.py` | Shared dataclasses and enums: `NormalisedEvent`, `BookState`, `Bbo`, `Level`, `Op`, `Side` |
| `itch_parser.py` | ITCH BinaryFILE reader, ITCH message decoder, Stock Directory parsing, symbol-to-locate resolution |
| `order_book.py` | Reference order book implementation |
| `stimulus.py` | Synthetic BinaryFILE generator for directed and seeded-random tests |
| `runner.py` | CLI/module entry point that emits `events.jsonl` and `states.jsonl` |
| `run_golden.sh` | Repo-level convenience wrapper for compile, unit tests, stimulus generation, and oracle generation |
| `golden/tests/` | Unit tests for parser, order book, stimulus, round-trip behaviour, and runner |
| `tb/itch_harness/` | cocotb-side packing, unpacking, oracle loading, AXI helpers, and scoreboarding |

---

## 3. Input format

The golden model currently consumes Nasdaq ITCH **BinaryFILE** records:

```text
2-byte big-endian message length
ITCH payload bytes
2-byte big-endian message length
ITCH payload bytes
...
```

The BinaryFILE length prefix is not part of the ITCH message payload. `golden.itch_parser.iter_binaryfile_payloads()` strips that prefix and yields:

```python
(msg_index, payload)
```

`msg_index` counts source records, including ignored messages. This is important because it lets the RTL scoreboard report the exact source-feed position where a divergence first occurred.

---

## 4. Normalised event contract

The parser converts supported ITCH messages into a single internal event shape:

```python
@dataclass(frozen=True)
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
```

Supported operations:

| `Op` | Meaning |
|---|---|
| `ADD` | Add a new displayed order |
| `EXECUTE` | Reduce displayed shares after execution |
| `CANCEL` | Reduce displayed shares after cancellation |
| `DELETE` | Remove all remaining displayed shares for an order |
| `REPLACE` | Remove the old order reference and add a new order reference |

The dataclass assertions in `contracts.py` are part of the contract. For example:

- `ADD` must have `BUY` or `SELL` side, plus `price` and `shares`.
- `EXECUTE` and `CANCEL` must have `shares`, but no `price`.
- `DELETE` must not carry `price` or `shares`.
- `REPLACE` must carry `new_order_ref`, new `price`, and new `shares`.

This keeps malformed parser output from silently entering the oracle book.

---

## 5. ITCH messages currently decoded

The book-mutating message set is:

| ITCH type | Name | Normalised op | Notes |
|---|---|---|---|
| `A` | Add Order, no MPID | `ADD` | Uses order ref, side, shares, stock locate, price |
| `F` | Add Order, with MPID | `ADD` | Same book effect as `A`; attribution is ignored |
| `E` | Order Executed | `EXECUTE` | Reduces shares; does not carry a display price |
| `C` | Order Executed With Price | `EXECUTE` | Same book effect as `E`; execution price is ignored for displayed-book state |
| `X` | Order Cancel | `CANCEL` | Partial displayed-size reduction |
| `D` | Order Delete | `DELETE` | Full removal of remaining displayed shares |
| `U` | Order Replace | `REPLACE` | Delete old ref, add new ref with new price/shares |

Unsupported messages return `None` from the parser. That includes non-book administrative messages and trade/auction messages that do not mutate the displayed order book represented here.

Stock Directory messages (`R`) are handled separately for symbol-to-locate resolution.

---

## 6. Symbol / locate filtering

Real ITCH input is multi-symbol. The golden runner can filter to one instrument in either of two ways:

```bash
# Directly filter by locate code
python -m golden.runner path/to/input.bin \
    --locate 24 \
    --events-out build/golden/events.jsonl \
    --states-out build/golden/states.jsonl

# Resolve a symbol through Stock Directory messages, then filter by its daily locate
python -m golden.runner path/to/input.bin \
    --symbol AAPL \
    --events-out build/golden/events.jsonl \
    --states-out build/golden/states.jsonl
```

Use `--symbol` for real captured/sample files when the Stock Directory spin is present. Use `--locate` when the locate is already known.

Do **not** pass both `--symbol` and `--locate`; the runner treats them as mutually exclusive.

---

## 7. Reference order-book behaviour

`golden.order_book.OrderBook` maintains:

```text
order_table: order_ref -> {side, price, shares, locate}
bid_levels: price -> {aggregate shares, order count}
ask_levels: price -> {aggregate shares, order count}
```

Book updates:

| Operation | Order table update | Level update |
|---|---|---|
| `ADD` | Insert new `order_ref` | Increase shares and order count at `(side, price)` |
| `EXECUTE` | Reduce order shares; delete order if fully executed | Reduce shares; reduce order count only if order reaches zero |
| `CANCEL` | Same reduction semantics as execute | Same reduction semantics as execute |
| `DELETE` | Remove the order | Remove remaining shares and decrement order count |
| `REPLACE` | Remove old ref, insert new ref | Delete-then-add using the original side and new price/shares |

The BBO is recomputed from occupied price levels:

```text
best bid = max(bid_levels)
best ask = min(ask_levels)
```

Empty sides are represented as `None` in Python and `null` in JSON.

---

## 8. JSONL outputs

### `events.jsonl`

One line per accepted event:

```json
{"msg_index":1,"op":"ADD","locate":1,"side":"BUY","order_ref":1001,"price":10000,"shares":100,"new_order_ref":null,"timestamp_ns":100}
```

Field meanings:

| Field | Meaning |
|---|---|
| `msg_index` | Original BinaryFILE source-record index |
| `op` | Normalised operation string |
| `locate` | ITCH stock locate |
| `side` | `BUY`, `SELL`, or `UNKNOWN` |
| `order_ref` | Existing / original order reference |
| `price` | Price integer with ITCH implied precision, when relevant |
| `shares` | Share quantity, when relevant |
| `new_order_ref` | Replacement order reference for `REPLACE`, otherwise `null` |
| `timestamp_ns` | ITCH timestamp in nanoseconds since midnight |

### `states.jsonl`

One line per accepted event, after applying that event:

```json
{
  "msg_index":1,
  "bbo":{"bid_price":10000,"bid_size":100,"ask_price":null,"ask_size":null},
  "bid_levels":[{"price":10000,"shares":100,"order_count":1}],
  "ask_levels":[]
}
```

Level lists are sorted best-to-worst:

- bids: descending price
- asks: ascending price

This makes diffs stable and readable.

---

## 9. Running the golden model

### Recommended wrapper

From the repo root:

```bash
scripts/run_golden.sh
```

This default flow:

1. compiles golden Python files,
2. runs unit tests,
3. generates a synthetic BinaryFILE input,
4. writes oracle JSONL into `build/golden/`.

Default outputs:

```text
build/golden/itch_synthetic.bin
build/golden/events.jsonl
build/golden/states.jsonl
```

### Synthetic run with explicit seed/count

```bash
scripts/run_golden.sh --seed 7 --random-message-count 25
```

### Real ITCH run by symbol

```bash
scripts/run_golden.sh \
    --input path/to/real_itch.bin \
    --symbol AAPL \
    --max-messages 100000 \
    --max-events 10000
```

### Real ITCH run by locate

```bash
scripts/run_golden.sh \
    --input path/to/real_itch.bin \
    --locate 24 \
    --max-messages 100000 \
    --max-events 10000
```

### Skip compile/tests for quick iteration

```bash
scripts/run_golden.sh --skip-tests --seed 3 --random-message-count 10
```

Only use this when you are iterating locally and have already run the full checks.

---

## 10. Direct Python commands

Compile the Python files:

```bash
python -m py_compile golden/*.py golden/tests/*.py
```

Run unit tests:

```bash
python -m unittest discover -s golden/tests -v
```

Generate synthetic input directly:

```bash
python -m golden.stimulus build/golden/itch_synthetic.bin \
    --seed 7 \
    --random-message-count 25
```

Generate oracle JSONL directly:

```bash
python -m golden.runner build/golden/itch_synthetic.bin \
    --events-out build/golden/events.jsonl \
    --states-out build/golden/states.jsonl \
    --locate 1
```

---

## 11. Relationship to the RTL harness

The normalised event stream is also used by the cocotb harness for order-book isolation.

Relevant harness files:

| File | Role |
|---|---|
| `tb/itch_harness/layout.py` | Packs `events.jsonl` records into RTL `data_t`-style vectors and unpacks `bbo_t` |
| `tb/itch_harness/oracle.py` | Loads oracle JSONL streams |
| `tb/itch_harness/scoreboard.py` | Compares RTL outputs against expected golden values |
| `tb/itch_harness/axis.py` | AXI-style driver/helpers |

The intended gate split is:

```text
G1 decoder isolation:
    RTL decoder output == events.jsonl

G2 book isolation / integrated flow:
    RTL book BBO and level state == states.jsonl
```

---

## 12. Assumptions and limitations

Current assumptions:

- The input is BinaryFILE-style length-prefixed ITCH, not Ethernet/IP/UDP/MoldUDP64 frames.
- Prices remain integer ITCH `Price(4)` values. Do not use floats in the golden model or RTL path.
- The book model tracks displayed-book state only.
- Trade/auction/administrative messages that do not mutate the displayed order book are ignored by `parse_itch_message()`.
- For real multi-symbol input, use `--symbol` or `--locate` so the generated oracle matches the single-instrument RTL book configuration.

Known interface note:

- The Python BBO uses `None`/`null` for an empty side. The current packed RTL `bbo_t` has no explicit valid bits, so the harness may need a documented conversion convention or a future `bid_valid` / `ask_valid` contract change.

---
