# Verification Flow

## Source of truth

The Python golden model is the oracle for all functional verification.

Main files:

| File | Purpose |
|---|---|
| `golden/contracts.py` | Shared Python-side contract types: `NormalisedEvent`, `Bbo`, `Level`, `BookState`. |
| `golden/itch_parser.py` | BinaryFILE record reader and ITCH payload parser. |
| `golden/order_book.py` | Reference order book model. |
| `golden/stimulus.py` | Synthetic BinaryFILE generator with directed and seeded-valid-random cases. |
| `golden/runner.py` | Runs parser + book and emits JSONL oracle streams. |
| `scripts/run_golden.sh` | One-command compile/test/stimulus/oracle generation flow. |

The runner emits:

```text
build/golden/events.jsonl
build/golden/states.jsonl
```

`events.jsonl` is the decoder oracle. Each row is one accepted book-mutating event.

`states.jsonl` is the order-book oracle. Each row is the expected book state after the corresponding event.

The two files are a matched pair: row `n` in `events.jsonl` and row `n` in `states.jsonl` refer to the same source `msg_index`.

## Oracle generation

Default synthetic run:

```bash
scripts/run_golden.sh
```

This performs four actions:

1. compiles golden Python files;
2. runs golden unit tests;
3. generates synthetic ITCH BinaryFILE input if no `--input` is supplied;
4. writes `events.jsonl` and `states.jsonl`.

Useful variants:

```bash
# deterministic synthetic run
scripts/run_golden.sh --seed 7 --random-message-count 100

# real ITCH BinaryFILE, resolving locate from Stock Directory messages
scripts/run_golden.sh --input path/to/real_itch.bin --symbol AAPL --max-events 10000

# real ITCH BinaryFILE, known locate
scripts/run_golden.sh --input path/to/real_itch.bin --locate 24 --max-events 10000
```

Real multi-symbol input should normally use `--symbol` or `--locate`. Unfiltered real data can blend different symbols into one single-symbol RTL book unless the RTL has a locate filter and/or partitioned book state.

## Test layers

The verification stack is deliberately layered. Do not jump straight to full-chain tests before the lower gates pass.

```text
Golden Python tests
  -> decoder isolation
  -> book isolation
  -> decoder + book integration
  -> ingress + decoder + book integration
  -> gap/A-B campaigns
  -> timing/resource checks
```

## Layer 0: golden model unit tests

Purpose:

- prove the parser and reference book are internally consistent;
- catch Python-side regressions before using the oracle against RTL.

Run:

```bash
python -m unittest discover -s golden/tests -v
```

Covered by current tests:

- BinaryFILE record parsing;
- ignored non-book messages preserving `msg_index`;
- `R` Stock Directory symbol-to-locate resolution;
- locate filtering;
- `A` and `F` Add messages;
- `E` and `C` Execute messages;
- `X`, `D`, and `U`;
- full order lifecycle;
- level aggregation;
- BBO recompute;
- replace edge cases;
- invariants between order table and price levels.

Gate:

```text
All golden unit tests pass.
```

## Layer 1: decoder isolation, G1

Purpose:

```text
BinaryFILE ITCH payloads -> data_handler.sv -> data_t
```

must match:

```text
events.jsonl
```

for every accepted book event.

The scoreboard comparison should use:

```python
itch_harness.scoreboard.assert_data_t_matches_word(...)
```

Expected comparison mask:

| Op | Always compare | Extra fields |
|---|---|---|
| `ADD` | message type/op, locate, order ref | side, shares, price |
| `EXECUTE` | message type/op, locate, order ref | shares |
| `CANCEL` | message type/op, locate, order ref | shares |
| `DELETE` | message type/op, locate, order ref | none |
| `REPLACE` | message type/op, locate, old order ref | new order ref, shares, price |

Important current issue:

`rtl/hdl_header.sv` defines `data_t` with `stock_locate`, giving a packed width of 217 bits. The current Python `tb/itch_harness/layout.py` still documents `DATA_W = 201` and does not include `stock_locate` in `DATA_FIELDS`, while `scoreboard.py` already tries to compare `got["stock_locate"]`.

Resolve this before G1, otherwise decoder-isolation scoring is not trustworthy.

Correct Python-side `data_t` layout should be:

```text
message_type [216:209]
stock_locate [208:193]
orn          [192:129]
updated_orn  [128:65]
side         [64]
shares       [63:32]
price        [31:0]
```

G1 acceptance:

```text
[ ] data_handler emits the same event sequence as events.jsonl.
[ ] All compared fields match bit-exactly.
[ ] A and F both normalise to ADD.
[ ] Backpressure does not drop, duplicate, or corrupt events.
[ ] msg_index of the first mismatch is reported clearly.
```

## Layer 2: book isolation, G2

Purpose:

```text
events.jsonl -> packed data_t -> order_book.sv -> bbo_t / state
```

must match:

```text
states.jsonl
```

Current cocotb entry point:

```bash
cd tb
make SIM=verilator TOPLEVEL=order_book MODULE=test_order_book
```

The Makefile already sets:

```make
VERILOG_SOURCES = ../rtl/hdl_header.sv ../rtl/order_book.sv
TOPLEVEL ?= order_book
MODULE ?= test_order_book
```

Current checks include:

- reset reaches ready;
- single add;
- BBO valid pulse is not sticky;
- best bid/ask update;
- same-price aggregation;
- partial and full execute;
- cancel-to-zero;
- delete;
- replace to new ref/new price;
- replace preserving original side;
- replace same price;
- hash collision insert/lookup/delete;
- same-price bid/ask independence;
- replay against generated oracle.

Current limitation:

The primary cocotb scoreboard compares BBO, not full internal state. For a stronger G2, the testbench should also compare:

- bid level shares and order counts;
- ask level shares and order counts;
- order table entries, at least through a debug/backdoor mechanism.

G2 acceptance:

```text
[ ] Directed cocotb order-book tests pass.
[ ] Full generated oracle replay passes.
[ ] BBO matches after every event.
[ ] Full book state matches after every event, or the limitation is explicitly documented until implemented.
[ ] Empty book-side encoding is decided: valid bits preferred, zero-means-empty acceptable only if documented.
```

## Layer 3: decoder + book integration

Purpose:

```text
BinaryFILE payloads -> data_handler.sv -> order_book.sv
```

must match:

```text
states.jsonl
```

This proves that the decoder emits the same normalised stream that the book-isolation test uses.

Integration wiring:

```text
data_handler.rdata_o  -> order_book.rdata_i
data_handler.valid_o  -> order_book.valid_i
order_book.ready_o    -> data_handler.ready_i
```

Recommended test structure:

1. Generate oracle using `scripts/run_golden.sh`.
2. Drive the same BinaryFILE payloads into `data_handler`.
3. Let the decoder feed the book through the real handshake.
4. On every `bbo_valid_o`, compare against the next `states.jsonl` row.
5. Fail on:
   - missing event;
   - extra event;
   - BBO mismatch;
   - timeout waiting for BBO;
   - final event count mismatch.

Acceptance:

```text
[ ] Full file-fed decoder->book chain matches the golden states.
[ ] The first mismatch reports source msg_index, op, expected state, and observed RTL values.
```

## Layer 4: ingress integration, G3

Purpose:

```text
encapsulated Ethernet frames
  -> ingress_top.sv
  -> data_handler.sv
  -> order_book.sv
```

must match:

```text
states.jsonl
```

Flow:

1. Start from the same BinaryFILE input.
2. Generate `events.jsonl` and `states.jsonl`.
3. Encapsulate the BinaryFILE messages into MoldUDP64/UDP/IPv4/Ethernet frames.
4. Drive frames into `ingress_top`.
5. `ingress_top` recovers aligned ITCH messages.
6. Feed recovered ITCH messages into `data_handler`.
7. Feed normalised events into `order_book`.
8. Compare output against `states.jsonl`.

G3 directed campaigns:

| Campaign | What it proves |
|---|---|
| one message per datagram | baseline MoldUDP64 path |
| multiple messages per datagram | real message-block splitting |
| message straddles AXIS beat | realignment correctness |
| multiple short messages per beat | realignment carry-over correctness |
| bad EtherType / bad protocol / fragment | frame drop policy |
| heartbeat | `count == 0` handling |
| EOS | `count == 0xffff` handling |

G3 acceptance:

```text
[ ] Recovered ITCH payload stream exactly matches the original accepted payload stream.
[ ] Full ingress->decoder->book chain matches states.jsonl.
[ ] Frame/drop/error conditions are covered by directed tests.
```

## Layer 5: gap and A/B campaigns, G4

Purpose:

Verify MoldUDP64 sequence handling.

Required behaviours:

| Case | Expected hardware behaviour |
|---|---|
| `received_seq == expected_seq` | accept packet and advance expected sequence |
| `received_seq > expected_seq` | gap detected, book marked stale/reported |
| `received_seq < expected_seq` | duplicate/late packet dropped |
| A and B both send same sequence | first copy wins, second suppressed |
| heartbeat | liveness event, no book mutation |
| EOS | end-of-session event, no book mutation |

Acceptance:

```text
[ ] Gap injection asserts stale/gap status.
[ ] Duplicate datagrams do not duplicate book updates.
[ ] A/B reorder campaigns accept first arrival only.
[ ] Heartbeat and EOS do not mutate the book.
```

## Layer 6: timing/resource checks

Simulation correctness is not the final gate. The milestone also needs Vivado numbers.

Target toolchain:

```text
Vivado 2023.2
Target part: xc7z020 / PYNQ-Z1
Initial clock target: 100 MHz
```

Record:

- LUT utilisation;
- FF utilisation;
- BRAM utilisation;
- DSP utilisation;
- achieved Fmax / worst negative slack;
- critical path summary.

Acceptance:

```text
[ ] Design elaborates in Vivado.
[ ] Synthesis completes.
[ ] Implementation completes, or timing failure is documented with critical path and mitigation.
[ ] Resource numbers are copied into docs/results.md.
```

## Scoreboard files

Current harness helpers:

| File | Role |
|---|---|
| `tb/itch_harness/oracle.py` | loads `events.jsonl` / `states.jsonl` and checks matching `msg_index` rows |
| `tb/itch_harness/layout.py` | packs/unpacks RTL vectors |
| `tb/itch_harness/scoreboard.py` | compares RTL outputs against oracle records |
| `tb/itch_harness/axis.py` | cocotb driving/reset/clock helpers |

The oracle loader searches:

1. explicit events/states paths;
2. explicit golden directory;
3. `GOLDEN_DIR` environment variable;
4. default `build/golden` from repo root or `tb/`.

Useful override:

```bash
GOLDEN_DIR=../build/golden make SIM=verilator TOPLEVEL=order_book MODULE=test_order_book
```
