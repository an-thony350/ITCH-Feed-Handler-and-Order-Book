# Networking Ingress

## Scope

The current ingress accepts a native **64-bit AXI4-Stream Ethernet frame** and emits a decoded **217-bit normalised ITCH event**.

The active Vivado path is:

```text
DMA replay or Taxi Ethernet RX
        |
        v
64-bit common AXI stream
        |
        v
frame_crack
        |
        v
UDP / MoldUDP64 datagram
        |
        v
mold_deframe + mold_seq_guard
        |
        v
packed ITCH payload + message lengths
        |
        v
data_realign
        |
        v
217-bit normalised event
```

 `data_realign` performs message-boundary tracking and ITCH field extraction directly from the packed MoldUDP64 payload stream.


Public Nasdaq ITCH samples are BinaryFILE streams rather than Ethernet captures. The host-side encapsulator therefore wraps the same ITCH messages used by the golden model in synthetic:

```text
Ethernet II -> IPv4 -> UDP -> MoldUDP64
```

frames for deterministic simulation and DMA replay.

---

## 1. Current hardware sources

The ingress can receive frames from two sources.

### DMA

```text
PS DDR
  -> AXI DMA MM2S
  -> AXIS clock converter
  -> source boundary
```

This is the current board-level correctness path.

The DMA AXI stream is clock-converted into the Taxi RX/user clock domain before source selection, so DMA replay exercises the same network-domain ingress as the Ethernet source.

The notebook waits for individual DMA transfers and reads the resulting BBO state. It is therefore intended for deterministic correctness testing rather than as a measurement of maximum ingress throughput.

### Taxi 10GbE RX

```text
SFP+
  -> ZCU106 GTH
  -> Taxi MAC/PCS
  -> lane_rewire
  -> source boundary
```

The Taxi frontend instantiates both ZCU106 SFP+ lanes, while the ITCH feed-handler currently consumes lane 0 RX.

Taxi exposes a 64-bit RX AXI stream and its native RX/user clock. The network ingress is clocked directly from that RX domain.

The Taxi frontend also exposes lane-0 bring-up/debug status which we can track with an ILA:

```text
GT power-good
RX status
block lock
high BER
error count
bad packet
bad FCS
```

Physical SFP+/10GbE traffic is not yet the project's proven board input. The frontend is integrated and routed, while final external-network bring-up remains pending.

---

## 2. Source boundary and byte order

The project and Taxi use opposite AXI byte-lane conventions.

### Project convention

The ingress package defines:

```text
AXIS_DATA_W = 64
AXIS_KEEP_W = 8
```

and uses:

```text
first network byte -> tdata[63:56]
second byte        -> tdata[55:48]
...
eighth byte        -> tdata[7:0]
```

### Taxi convention

Taxi presents the earliest frame byte in `tdata[7:0]`.

`lane_rewire` reverses all eight byte lanes and the eight `tkeep` bits before the Taxi stream enters the common source mux.

This is a pure wiring operation, so adds no cycles.

### Static source mux

`axis_source_mux` selects:

```text
select_taxi_i = 0 -> DMA
select_taxi_i = 1 -> Taxi
```

Only the selected source receives downstream `ready`.

---

## 3. Software encapsulator

`golden/network_encapsulator.py` reads length-prefixed BinaryFILE messages and generates Ethernet test vectors.

Typical outputs are:

```text
build/network/frames.bin
build/network/frames.jsonl
```

The binary stream contains concatenated Ethernet frames. The metadata stream records the corresponding frame lengths, source indices, sequence/count values, and duplicate/feed annotations.

The encapsulator can generate:

- one or multiple ITCH messages per MoldUDP64 datagram;
- configurable sequence start;
- configurable MoldUDP64 session;
- configurable UDP source/destination ports;
- exact packet duplicates;
- logical A/B duplicate copies;
- a deliberate missing packet for gap testing;
- heartbeat packets;
- end-of-session packets;
- bounded source ranges for repeatable campaigns.

Commands are documented in [`running_the_project.md`](running_the_project.md).

---

## 4. Stage 1 — `frame_crack`

`frame_crack` accepts one complete Ethernet frame per AXI packet and emits only the UDP payload.

The UDP payload is the MoldUDP64 datagram consumed by the next stage.

### Supported packet shape

| Layer | Current policy |
|---|---|
| Ethernet II | Untagged Ethernet II |
| EtherType | Must be `0x0800` |
| MAC filtering | Source/destination MAC addresses are not used for filtering |
| VLAN | Not supported |
| IPv4 | Version 4 with IHL = 5 |
| IPv4 options | Not supported |
| Fragmentation | Fragmented packets are dropped |
| L4 | UDP / protocol 17 |
| UDP destination port | Optional configured check |
| IP checksum | Not validated |
| UDP checksum | Not validated |
| Ethernet FCS | Assumed to be handled before this RTL boundary |
| AXI non-final `tkeep` | Must be `8'hff` |
| AXI final `tkeep` | Must be contiguous from the MSB-side lane |

The fixed supported prefix is:

```text
Ethernet II 14 bytes
IPv4        20 bytes
UDP          8 bytes
--------------------
total        42 bytes
```

### 64-bit alignment

Forty-two bytes do not align to a 64-bit boundary.

The first 40 bytes occupy five complete 64-bit beats. On zero-based input beat 5:

```text
bytes 40..41 -> final two UDP-header bytes
bytes 42..47 -> first six MoldUDP64 bytes
```

The stage captures those six payload bytes and carries them into the aligned output stream.

After this start-up alignment, it can forward up to one 64-bit payload beat per cycle.

Supporting only the required fixed Ethernet/IPv4/UDP shape avoids inserting a general variable-offset barrel shifter into the latency-critical ingress path.

### Metadata and errors

The stage additionally produces:

```text
m_dgram_len_o
m_dgram_start_o
frame_drop_o
frame_err_o
```

The datagram length is the UDP payload length.

Drop/error conditions include:

- malformed `tkeep`;
- unsupported EtherType;
- invalid IP version;
- IHL other than 5;
- fragmented IPv4;
- non-UDP protocol;
- configured UDP destination-port mismatch;
- invalid UDP length;
- runt/early-terminated frame.

---

## 5. Stage 2 — `mold_deframe`

`mold_deframe` consumes one MoldUDP64 datagram per AXI packet.

The header is:

```text
session[10 bytes]
sequence_number[8 bytes]
message_count[2 bytes]
```

For a normal data datagram, the body is:

```text
message_length[2 bytes]
ITCH payload
message_length[2 bytes]
ITCH payload
...
```

The stage removes the two-byte length prefixes and emits:

```text
packed ITCH payload AXI stream
+
one 16-bit message-length token per ITCH message
```

`m_payload_tlast_o` marks the end of the **MoldUDP64 datagram**, not the end of an individual ITCH message.

### Parallel 64-bit parser

The current implementation was redesigned for the native 64-bit ingress.

Its main structure is:

```text
64-bit MoldUDP64 input
        |
        v
20-byte header decode
        |
        v
small raw-body FIFO
        |
        v
parallel boundary parser
        |
        v
registered descriptor
        |
        v
payload compactor
        |
        v
24-byte payload reservoir
        |
        v
64-bit packed payload output
```

The parser can consume up to **8 raw body bytes per cycle**.

A body beat may contain combinations such as:

```text
tail of message N
length prefix for N+1
head of message N+1
```

These cases are classified together in one parser cycle rather than being serialised byte-by-byte.

Only one new message-length prefix needs to be discovered per cycle for legal ITCH traffic because even the shortest supported ITCH message plus its two-byte MoldUDP64 prefix is longer than one 64-bit beat.

### Why the registered compaction pipeline exists

The boundary parser does not directly perform a wide variable compaction and state update in one large combinational cone.

Instead:

```text
boundary classification -> register -> byte compaction -> register/reservoir
```

This adds a small fixed latency but reduces the critical-path depth and preserves a one-input-beat-per-cycle initiation rate.


### Length-token credit

Message lengths are buffered separately from payload bytes.

Payload bytes for a message are not released until the corresponding length token has been accepted downstream.

This guarantees the contract expected by `data_realign` without allowing message payload to overtake its boundary information.

---

## 6. `mold_seq_guard`

Sequence checking is performed around the MoldUDP64 header metadata.

The complete policy is documented in [`moldudp64_seq_handling.md`](moldudp64_seq_handling.md).

---

## 7. Stage 3 — `data_realign`

`data_realign` is both the message-boundary tracker and the active ITCH decoder.

It receives:

```text
s_payload_tdata_i[63:0]
s_payload_tkeep_i[7:0]
s_payload_tvalid_i
s_payload_tlast_i
+
s_msg_len_i[15:0]
s_msg_len_valid_i
```

and emits:

```text
data_t rdata_o      // 217-bit normalised event
valid_o
ready_i
```

### Direct decode

Fields are captured from fixed ITCH byte positions while the packed 64-bit stream passes through the module.

Only fields needed by the hardware order-book contract are stored. Fields not required by the book, such as tracking number, timestamp, stock text, match number, printable flag, and MPID attribution, are consumed but are not copied into `data_t`.

Supported book-mutating types are:

```text
A  Add Order
F  Add Order with MPID
E  Order Executed
C  Order Executed with Price
X  Order Cancel
D  Order Delete
U  Order Replace
```

### Message crossings inside a beat

A packed payload beat can contain:

```text
message N tail | message N+1 head
```

The current message is completed first, then the buffered next-message length is used to start the next decode context from the remaining lanes of the same beat.

This avoids per-message padding/realignment bubbles.

A local message-length FIFO allows the next boundary to be known before the crossing beat arrives.

### Output elasticity

A one-entry event register absorbs downstream backpressure.

If the previous event is accepted in a cycle, a newly completed event can replace it in that same cycle.

This avoids an unconditional event-output bubble while keeping the output stable under valid/ready backpressure.

---

## 8. Event CDC and downstream boundary

The active packaged Vivado IP `network_ingress` ends at the normalised event interface:

```text
ready_i
rdata_o[216:0]
valid_o
```

This connects directly to `event_async_fifo`.

The FIFO crosses:

```text
network/Taxis RX domain
        ->
250 MHz order-book/data domain
```

Only complete semantic events cross this boundary.

---

## 9. Backpressure architecture

The current ingress is designed so that downstream pressure does not create one long combinational path through the entire parser.

Key decoupling points are:

```text
AXIS clock converter
mold_deframe raw-body FIFO
mold_deframe descriptor register
mold_deframe compacted-payload register
mold_deframe payload reservoir
mold_deframe length FIFO
data_realign length FIFO
data_realign event register
event_async_fifo
```

`mold_deframe` input readiness is based on registered local state rather than directly on downstream event readiness.

`data_realign` similarly bases payload readiness on registered parser/output capacity and buffered message-length availability.

This adds bounded local latency, but it is necessary to keep timing manageable at the 64-bit network frequency and to preserve sustained throughput.

---

## 10. Latency

The native-64-bit ingress performance tests use a **156.25 MHz** modelled clock:

```text
period = 6.4 ns
```

Measured latency from the first Ethernet beat to the normalised event is:

| ITCH type | Cycles | Approx. latency |
|---|---:|---:|
| `D` | 19 | 121.6 ns |
| `X` | 19 | 121.6 ns |
| `E` | 20 | 128.0 ns |
| `U` | 21 | 134.4 ns |
| `A` | 21 | 134.4 ns |
| `C` | 21 | 134.4 ns |
| `F` | 21 | 134.4 ns |

The longer formats do not take extra cycles because of expensive arithmetic. Their required fields occur later in the ITCH payload, so more input bytes must arrive before the event can be declared complete.

---

## 11. Sustained throughput

The current ingress was changed from a byte-serial implementation to the native 64-bit architecture specifically so that ingress throughput no longer limits a 10GbE frontend.

The final native-64-bit simulation campaign reports:

| Message | Measured AXI frame-path rate |
|---|---:|
| `D` | 9.911 Gbit/s |
| `X` | 9.906 Gbit/s |
| `E` | 9.866 Gbit/s |
| `U` | 9.870 Gbit/s |
| `A` | 9.902 Gbit/s |
| `C` | 9.902 Gbit/s |
| `F` | 9.911 Gbit/s |
| Mixed | 9.830 Gbit/s |

These figures are **simulation measurements on the AXI frame path**, not a measurement from an external cable/SFP+ link.

The physical-wire pass/fail calculation includes Ethernet overhead that is not present as AXI frame bytes:

```text
preamble / SFD
FCS
inter-frame gap
```

Therefore the required AXI-side frame-byte rate for a saturated 10GbE wire is below 10.000 Gbit/s.

All of the supported message campaigns pass that physical-wire-rate gate.

A small number of zero-gap synthetic AXI stalls remain around the `frame_crack -> mold_deframe` boundary. They do not prevent the design from meeting the calculated 10GbE wire-rate requirement, but they remain useful stress-test instrumentation.

---

## 12. Verification coverage

The current ingress verification includes both legacy/reference isolation tests and the active merged path.


Directed coverage includes:

| Campaign | Purpose |
|---|---|
| Valid minimal frame | Baseline Ethernet/IPv4/UDP stripping |
| Ethernet padding | Respect UDP length rather than forwarding padding |
| Multiple ITCH messages per MoldUDP64 packet | Deframe/message-boundary correctness |
| Message crossing 64-bit beats | Packed-stream decode correctness |
| Two messages sharing one payload beat | Tail/head boundary handling |
| Partial final beat | `tkeep` correctness |
| Random downstream stalls | Valid/ready stability and lossless backpressure |
| Invalid Ethernet/IP/UDP fields | Explicit frame-drop policy |
| MoldUDP64 length/count overrun | No partial malformed message emission |
| Exact duplicate | Duplicate suppression |
| Logical A/B copy | First-copy acceptance, second-copy suppression |
| Forward gap | Gap range + sticky stale behaviour |
| Late missing packet | Duplicate/late drop after gap |
| Heartbeat | Status only; no order-book mutation |
| EOS | Status only; no order-book mutation |
| Lane rewire | Taxi byte ordering matches project convention |
| Source mux | Only selected source participates in handshake |
| Native line-rate campaigns | Throughput against physical 10GbE requirement |

The complete verification architecture is documented in [`golden_model.md`](golden_model.md).

---

## 13. Current hardware status and limitations

The current ZCU106 Vivado design includes:

```text
Taxi 10GbE SFP+ frontend
64-bit Taxi RX datapath
DMA replay source
DMA -> Taxi-domain AXIS clock conversion
combinational DMA/Taxi source boundary
native 64-bit network_ingress_top
217-bit asynchronous event FIFO
250 MHz downstream order-book domain
```

The deterministic DMA path has already been used to compare hardware BBO behaviour against the Python golden model.

The Taxi frontend is integrated into the routed design, but final physical 10GbE receive validation is still pending external network-hardware bring-up as we are trying to get our hands on a 10GbE NIC.
