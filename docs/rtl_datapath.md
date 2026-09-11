# RTL Datapath

This document describes the current PL datapath, its clock-domain boundaries, and the latency/throughput decisions used in the ZCU106 implementation.

Detailed network parsing is in [`networking_ingress.md`](networking_ingress.md). MoldUDP64 sequence policy is in [`moldudp64_seq_handling.md`](moldudp64_seq_handling.md). Detailed order-book internals are documented separately in [`pipelined_order_book.md`](pipelined_order_book.md).

---

## 1. Current pipeline overview

The active Vivado datapath is:

```text
                         ZCU106 PL

          deterministic replay             physical Ethernet
                 path                           path
                  |                              |
PS DDR -> AXI DMA MM2S                  SFP+ -> Taxi MAC/PCS
                  |                              |
                  |                    64-bit Taxi RX AXIS
                  |                              |
          AXIS clock converter             lane_rewire
                  |                              |
                  +----------> source mux <------+
                                |
                         64-bit AXI-Stream
                                |
                           frame_crack
                                |
                         UDP / MoldUDP64
                                |
                          mold_deframe
                       + mold_seq_guard
                                |
                 packed ITCH payload + lengths
                                |
                           data_realign
                      + direct ITCH decode
                                |
                    217-bit normalised event
                                |
                        event_async_fifo
                 network clock -> data clock
                                |
                          symbol_router
                                |
                  three pipelined order books
                                |
                              BBO
                                |
                       AXI GPIO / PS readout
```

---

## 2. Clock domains and CDC boundaries

The current hardware deliberately separates the Ethernet ingress clock from the order-book/data clock.

| Domain | Clock source | Main logic |
|---|---|---|
| PS / DMA source | PS/PL clocking through the block design | AXI DMA and PS-facing AXI peripherals |
| Network ingress | Taxi lane-0 `rx_clk_o` | source mux output, `frame_crack`, `mold_deframe`, `mold_seq_guard`, `data_realign` |
| Data / order book | **250 MHz** PL clock | `symbol_router`, three order-book instances, BBO readout logic |

The DMA replay stream is clock-converted into the Taxi RX/user clock domain before it reaches the source mux. This means both DMA replay and Taxi Ethernet exercise the same network-domain ingress logic.

A complete decoded event is crossed into the 250 MHz data domain through `event_async_fifo`.

We split it up like this so that:

- raw Ethernet traffic remains entirely in the network clock domain;
- protocol parsing and ITCH field extraction complete before the crossing;
- only one **217-bit semantic event** crosses the asynchronous boundary;
- the order-book domain can run faster than the Ethernet ingress without forcing the raw packet path onto the same clock;
- the FIFO provides elasticity between short-term ingress and order-book stalls.

`event_async_fifo` uses an AMD/Xilinx `xpm_fifo_async` with a depth of 16 events, two CDC synchroniser stages, and first-word fall-through read behaviour.

---

## 3. Shared stream and event conventions

The current ingress width in `rtl/hdl_header.sv` is:

```text
AXIS_DATA_W = 64 bits
AXIS_KEEP_W = 8 bits
```

The project byte-lane convention is network-order/MSB-first.

`tkeep[7]` corresponds to lane 0 / `tdata[63:56]`.

For a valid final beat, active `tkeep` bits are therefore contiguous from the MSB side.

Non-final beats are required to have all eight lanes valid.

The normalised event contract is the packed `data_t` structure defined in `rtl/hdl_header.sv`. It is **217 bits** wide and carries the fields required by the hardware order book:

```text
message_type
stock_locate
order reference
updated order reference
side
shares
price
```

The supported displayed-book ITCH messages are:

```text
A, F, E, C, X, D, U
```

Unsupported ITCH messages are consumed by the ingress but do not emit a normalised event.

---

## 4. DMA / Taxi source boundary

The current block design supports two frame sources.

### DMA replay

The deterministic board-regression path is:

```text
PS DDR
  -> AXI DMA MM2S
  -> AXIS clock converter
  -> ingress_source_boundary
```

The AXIS clock converter moves the DMA stream into the Taxi RX/user clock domain before the ingress.

This path is used for repeatable board-versus-golden-model testing. It is a correctness path rather than a physical Ethernet throughput measurement.

### Taxi Ethernet RX

The physical Ethernet path is:

```text
SFP+
  -> ZCU106 GTH
  -> Taxi 10GbE MAC/PCS
  -> lane_rewire
  -> ingress_source_boundary
```

The current Taxi frontend instantiates two physical SFP+ lanes, but only lane 0 RX is connected to the ITCH datapath.

Taxi presents the earliest Ethernet byte in the least-significant byte lane. The project ingress uses the opposite convention, so `lane_rewire` reverses the eight `tdata` byte lanes and the corresponding `tkeep` bits.

`lane_rewire` is purely combinational.

`axis_source_mux` then selects either:

```text
0 -> DMA replay
1 -> Taxi Ethernet RX
```

The mux is also combinational, so the complete source boundary adds **zero pipeline cycles**.

The source-select signal is intended to remain static while ingress is active. It should only be changed while the ingress is held in reset or otherwise disabled.

---

## 5. `network_ingress`

Detailed network parsing is in [`networking_ingress.md`](networking_ingress.md).

---

## 6. `event_async_fifo`

The network ingress ends when `data_realign` produces a complete normalised event.

`event_async_fifo` crosses that event from:

```text
Taxi RX / network clock
```

to:

```text
250 MHz data / order-book clock
```

The FIFO maps the existing event valid/ready interface onto `xpm_fifo_async`.

Producer-side backpressure is asserted when the FIFO is full or its write side is in reset.

On the consumer side, first-word fall-through keeps the oldest event visible until the order-book path accepts it.

No network protocol processing occurs inside the FIFO.

Crossing at the event boundary keeps the CDC narrow compared with crossing the full 64-bit packet stream plus packet sideband and avoids introducing a second raw-data buffering architecture.

---

## 7. `order_book`

Detailed order book documentation is in [`pipelined_order_book.md`](pipelined_order_book.md).

---

## 8. Backpressure and buffering

The packet-side stages use AXI-style valid/ready semantics.


Buffering is used as it adds bounded latency but makes 156.25 MHz-class ingress timing substantially easier and prevents a 250 MHz order-book stall from immediately becoming a long combinational path back to the Ethernet source.

---

## 9. Current latency and throughput

The ingress performance regressions use a **156.25 MHz** modelled network clock.

At 156.25 MHz, or 6.4ns, measured ingress/decode latency from the first Ethernet beat to the emitted normalised event is:

| Message type | Cycles | Time at 156.25 MHz |
|---|---:|---:|
| `D`, `X` | 19 | 121.6 ns |
| `E` | 20 | 128.0 ns |
| `U`, `A`, `C`, `F` | 21 | 134.4 ns |

The difference is caused by where the fields required for each message occur in the ITCH payload. Price-bearing/longer formats require later bytes before the normalised event is complete.

### Downstream latency

Once a normalised event has been produced, the remaining path is:

```text
data_realign
    -> event_async_fifo
    -> symbol_router
    -> order_book
    -> per-stock BBO FIFO / round-robin output
```

The order-book side runs at **250 MHz**, or **4 ns per cycle**.

| Stage | Latency contribution |
|---|---:|
| `event_async_fifo` | **30.4 ns** for an empty FIFO using the configured XPM FWFT CDC path |
| `symbol_router` | **1 cycle / 4 ns** |
| `order_book` | add in |
| BBO FIFO + round-robin output | **2-4 cycles / 8-16 ns** |

The FIFO uses `CDC_SYNC_STAGES=2`, `READ_MODE="fwft"` and `FIFO_READ_LATENCY=0`. For an asynchronous XPM FIFO in FWFT mode, read-side visibility after a write is `1 wr_clk + (N+4) rd_clk`. With the 156.25 MHz write clock, 250 MHz read clock and `N=2`:

```text
1 x 6.4 ns + 6 x 4 ns = 30.4 ns
```

The final BBO output latency is variable by up to two cycles because each order book first writes into its own output FIFO and the round-robin scheduler services one of the three stock FIFOs each cycle.

---
