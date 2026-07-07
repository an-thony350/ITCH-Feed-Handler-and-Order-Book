# ITCH 5.0 Feed Handler and Hardware Order Book

SystemVerilog RTL and Python verification for a Nasdaq TotalView-ITCH 5.0-style feed handler and hardware order book.

The project targets a PYNQ-Z1 / Zynq-7020 bring-up path. On this board, market-data-style input is fed from the Processing System into the Programmable Logic through AXI DMA. The PL pipeline parses Ethernet/IP/UDP/MoldUDP64-style frames, recovers ITCH messages, decodes book events, updates a hardware order book, and exposes best-bid/best-offer output back to the PS.

The repository also contains a Python golden model used as the reference for parser and book behaviour.

## What is implemented

- Python ITCH BinaryFILE parser and order-book golden model
- Synthetic ITCH stimulus generation
- JSONL oracle generation for decoded events and expected book states
- RTL ITCH decoder (`data_handler`)
- RTL ingress chain:
  - Ethernet/IPv4/UDP frame parser
  - MoldUDP64 deframer
  - message realignment stage
- RTL symbol router and single-symbol order-book path
- RTL order book with:
  - order-reference table
  - bid/ask price-level storage
  - active-level tracking
  - BBO output
- Directed SystemVerilog testbenches for the main RTL blocks
- cocotb/Verilator order-book verification harness
- Vivado block design for PYNQ-Z1 PS-to-PL DMA ingress

## System architecture

```text
Host / Python
  ├── ITCH BinaryFILE reader
  ├── synthetic stimulus generator
  ├── golden parser
  └── golden order book
            │
            │ events.jsonl / states.jsonl
            ▼
PYNQ-Z1 Processing System
  ├── reads input data
  ├── writes PS DDR
  └── feeds PL through AXI DMA MM2S
            │
            ▼
Programmable Logic
  ├── ingress_top
  │     ├── frame_crack      Ethernet / IPv4 / UDP parsing
  │     ├── mold_deframe     MoldUDP64 deframing
  │     └── realign          byte stream to ITCH message packets
  ├── data_handler           ITCH payload to normalised event
  ├── symbol_router          locate-based single-symbol route
  └── order_book             book state and BBO maintenance
            │
            ▼
BBO output through AXI GPIO
```

## PYNQ-Z1 hardware model

The PYNQ-Z1 Ethernet port is connected to the Zynq Processing System, not directly to PL transceivers. This project therefore uses a PS-to-PL DMA model on PYNQ-Z1: the PS supplies input data to the same AXI-Stream-facing ingress path that a real MAC/CMAC would feed on a larger networking FPGA.

This repository does not claim direct live multicast feed access, SFP+/QSFP integration, 10G/25G/100G Ethernet, GT transceiver integration, or live Nasdaq connectivity on PYNQ-Z1.

## Repository layout

```text
golden/
  contracts.py        Shared Python-side event and book-state types
  itch_parser.py      ITCH BinaryFILE parser
  order_book.py       Python reference order book
  runner.py           Oracle generation entry point
  stimulus.py         Synthetic ITCH BinaryFILE generation
  tests/              Python unit tests

rtl/
  data_handler.sv     ITCH decoder
  frame_crack.sv      Ethernet / IPv4 / UDP parser
  mold_deframe.sv     MoldUDP64 deframer
  realign.sv          ITCH message realignment
  ingress_top.sv      Network ingress wrapper
  symbol_router.sv    Locate router / base-price path
  order_book.sv       Hardware order book
  order_book_top.sv   Router + book top-level wrapper

tb/
  *_tb.sv             Directed SystemVerilog testbenches
  test_order_book.py  cocotb order-book tests
  itch_harness/       AXI helpers, layout helpers, scoreboards

scripts/
  run_golden.sh       Golden model compile/test/oracle wrapper
```

## Golden model

The Python golden model is the reference implementation for the RTL verification flow. It parses ITCH BinaryFILE-style records and emits two oracle streams:

```text
build/golden/events.jsonl
build/golden/states.jsonl
```

`events.jsonl` contains the normalised book-mutating events accepted by the parser. `states.jsonl` contains the expected book state after each accepted event.

The parser covers the book-relevant ITCH message types:

| Type | Meaning | Golden-model treatment |
|---|---|---|
| `A` | Add Order | Add displayed order |
| `F` | Add Order with MPID | Add displayed order, ignoring attribution |
| `E` | Order Executed | Reduce displayed shares |
| `C` | Order Executed With Price | Reduce displayed shares |
| `X` | Order Cancel | Reduce displayed shares |
| `D` | Order Delete | Remove order |
| `U` | Order Replace | Delete old reference, add new reference |
| `R` | Stock Directory | Used for symbol-to-locate resolution |

Unsupported non-book messages are ignored for displayed-book reconstruction.

## RTL pipeline

### `frame_crack`

Parses Ethernet II, IPv4, and UDP headers and emits the UDP payload.

Current assumptions:

- 32-bit AXI-Stream input
- big-endian byte-lane convention
- Ethernet II / IPv4 / UDP only
- untagged Ethernet only
- IPv4 IHL must be 5
- fragmented IPv4 packets are dropped
- IP and UDP checksums are not validated

### `mold_deframe`

Parses MoldUDP64 datagrams and strips the MoldUDP64 header and per-message length fields. It emits the ITCH payload byte stream plus one message-length token per ITCH message.

It also exposes session, sequence number, message count, heartbeat, end-of-session, and expected-next-sequence sideband signals.

### `realign`

Converts the MoldUDP64 payload byte stream into one aligned AXI packet per ITCH message. This handles the fact that ITCH messages are variable length and can start at arbitrary byte offsets inside an AXI beat.

### `data_handler`

Decodes a single aligned ITCH message packet into the internal `data_t` event format.

The RTL currently decodes:

| Type | Meaning |
|---|---|
| `A` | Add Order |
| `E` | Order Executed |
| `C` | Order Executed With Price |
| `X` | Order Cancel |
| `D` | Order Delete |
| `U` | Order Replace |

The golden model supports `F` Add-with-MPID, but the current RTL decoder does not yet decode `F`.

### `symbol_router`

Routes decoded events into the current single-book path. The present implementation routes `stock_locate == 16'd1` and supplies a hard-coded base price to the order book.

### `order_book`

Maintains one displayed order book. It stores order-reference state, aggregates shares by price level, tracks active bid/ask levels, and emits BBO updates.

The book is implemented as a serial multi-cycle FSM. It accepts a new event only when `ready_o` is high. This keeps update ordering simple and avoids overlapping read-modify-write hazards, but it is not an initiation-interval-one book.

## Interfaces

### AXI-Stream convention

The ingress path uses AXI-Stream-style handshaking:

| Signal | Meaning |
|---|---|
| `tdata` | Data bus |
| `tkeep` | Valid byte lanes |
| `tvalid` | Producer has valid data |
| `tready` | Consumer can accept data |
| `tlast` | End of packet |

A transfer occurs when `tvalid && tready`.

The current shared package uses:

```text
AXIS_DATA_W = 32
AXIS_KEEP_W = AXIS_DATA_W / 8
```

Byte lanes are treated in network byte order:

```text
lane 0 = tdata[31:24]
lane 1 = tdata[23:16]
lane 2 = tdata[15:8]
lane 3 = tdata[7:0]
```

### `data_t`

Decoder-to-router event format:

```text
data_t, 217 bits, MSB -> LSB

message_type [216:209]  8 bits
stock_locate [208:193] 16 bits
orn          [192:129] 64 bits
updated_orn  [128:65]  64 bits
side         [64]       1 bit
shares       [63:32]   32 bits
price        [31:0]    32 bits
```

### `o_data_t`

Router-to-book event format:

```text
o_data_t, 201 bits, MSB -> LSB

message_type [200:193]  8 bits
orn          [192:129] 64 bits
updated_orn  [128:65]  64 bits
side         [64]       1 bit
shares       [63:32]   32 bits
price        [31:0]    32 bits
```

### `bbo_t`

BBO output format:

```text
bbo_t, 128 bits, MSB -> LSB

bid_price  [127:96] 32 bits
bid_shares [95:64]  32 bits
ask_price  [63:32]  32 bits
ask_shares [31:0]   32 bits
```

The current `bbo_t` does not include explicit valid bits for empty bid or ask sides. The test harness maps empty sides to zero.

## Running the golden model

From the repository root:

```bash
python -m py_compile golden/*.py golden/tests/*.py
python -m unittest discover -s golden/tests -v
```

Generate the default synthetic oracle:

```bash
scripts/run_golden.sh
```

Generate a deterministic synthetic run:

```bash
scripts/run_golden.sh --seed 7 --random-message-count 25
```

Run against a local ITCH BinaryFILE by symbol:

```bash
scripts/run_golden.sh \
    --input path/to/itch.bin \
    --symbol AAPL \
    --max-messages 100000 \
    --max-events 10000
```

Run against a known locate:

```bash
scripts/run_golden.sh \
    --input path/to/itch.bin \
    --locate 24 \
    --max-messages 100000 \
    --max-events 10000
```

## Running cocotb / Verilator

From the repository root:

```bash
cd tb
make SIM=verilator TOPLEVEL=order_book MODULE=test_order_book
```

Use a specific golden output directory:

```bash
cd tb
GOLDEN_DIR=../build/golden make SIM=verilator TOPLEVEL=order_book MODULE=test_order_book
```

Clean generated simulator output:

```bash
cd tb
make clean
rm -rf sim_build results.xml dump.vcd *.vcd *.fst
```

## Directed SystemVerilog testbenches

Directed testbenches are under `tb/` for the main RTL blocks:

- `data_handler_tb.sv`
- `order_book_tb.sv`
- `frame_crack_tb.sv`
- `mold_deframe_tb.sv`
- `realign_tb.sv`

These are intended for Vivado/xsim-based RTL simulation.

## Vivado build status

Build summary:

| Item | Value |
|---|---|
| Vivado version | 2023.2 |
| Project | `Itch_Handler` |
| Top design | `design_1_wrapper` |
| Block design | `design_1` |
| Part | `xc7z020clg400-1` |
| Primary clock | `clk_fpga_0` |
| Clock period | 10.625 ns |
| Clock frequency | 94.118 MHz |
| Implementation status | Routed, bitstream generated |
| Timing | WNS `+0.012 ns`, TNS `0.000 ns` |

Top-level resource use from that build:

| Resource | Used | Available | Utilisation |
|---|---:|---:|---:|
| LUT | 36,835 | 53,200 | 69.24% |
| FF | 13,542 | 106,400 | 12.73% |
| BRAM | 23 | 140 | 16.43% |
| DSP | 0 | 220 | 0.00% |

The dominant custom block is `order_book_top_0`, mainly due to the single `order_book` instance.

## Current Vivado data path

The routed block design wires the input path as:

```text
PS DDR / OCM
  -> axi_dma_0 MM2S
  -> network_ingress_0
  -> data_handler_0
  -> order_book_top_0
  -> BBO output through AXI GPIO
```

BBO fields are exported through AXI GPIO:

| BBO field | Route |
|---|---|
| `bid_price` | `bbo_data_o[127:96] -> axi_gpio_0` |
| `bid_shares` | `bbo_data_o[95:64] -> axi_gpio_0` |
| `ask_price` | `bbo_data_o[63:32] -> axi_gpio_1` |
| `ask_shares` | `bbo_data_o[31:0] -> axi_gpio_1` |
| `bbo_valid_o` | `axi_gpio_2` |

The current AXI DMA instance is MM2S-only. There is no S2MM result DMA path in this build.
