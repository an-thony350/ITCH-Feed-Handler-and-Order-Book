# Networking Ingress

## Scope

The ingress path accepts a 32-bit AXI4-Stream Ethernet frame and emits one aligned AXI packet per recovered ITCH message for `data_handler.sv`.

Public Nasdaq ITCH sample files are BinaryFILE streams, not Ethernet captures. The host-side encapsulator wraps the same length-prefixed ITCH payloads used by the golden model into synthetic Ethernet II / IPv4 / UDP / MoldUDP64 frames. This makes the network path deterministic and allows controlled duplicate, gap, heartbeat, and EOS campaigns.

```text
BinaryFILE ITCH
    -> software encapsulator
    -> Ethernet / IPv4 / UDP / MoldUDP64 frames
    -> ingress RTL
    -> aligned ITCH messages
    -> decoder and book
    -> comparison with the Python oracle
```

This flow tests the protocol layers required by a wire-fed design without claiming direct access to a live Nasdaq multicast stream.

---

## Current RTL top level

`rtl/ingress_top.sv` connects:

```text
s_frame AXI stream
    -> frame_crack
    -> mold_deframe + mold_seq_guard
    -> realign
    -> m_itch AXI stream
```

The shared package defines:

```text
AXIS_DATA_W = 32
AXIS_KEEP_W = 4
```

The earliest byte occupies the most-significant active lane. Final-beat `tkeep` values must be contiguous from that lane.

### Ethernet-frame input

```text
s_frame_tdata_i
s_frame_tkeep_i
s_frame_tvalid_i
s_frame_tlast_i
s_frame_tready_o
```

### Aligned ITCH output

```text
m_itch_tdata_o
m_itch_tvalid_o
m_itch_tlast_o
m_itch_tready_i
```

### MoldUDP64 and sequence status

```text
session_o
seq_o
count_o
expected_next_o
seq_valid_o
in_order_o
duplicate_o
gap_o
heartbeat_o
eos_o
stale_o
expected_seq_o
gap_start_o
gap_end_o
```

### Error status

```text
frame_drop_o
frame_err_o
mold_drop_o
mold_err_o
realign_err_o
```

These status outputs are available for simulation and future CSR mapping. The current PYNQ block design does not expose every status bit to the Processing System.

---

## Software encapsulator

`golden/network_encapsulator.py` reads BinaryFILE payloads and writes:

```text
build/network/frames.bin
build/network/frames.jsonl
```

The frame stream contains raw concatenated Ethernet II frames. The metadata stream records frame lengths, source indices, sequence/count fields, and duplicate/feed annotations.

The encapsulator can control:

- number of ITCH messages per datagram;
- sequence start;
- MoldUDP64 session;
- UDP source and destination ports;
- exact frame duplication;
- logical A/B copies;
- a dropped frame for gap testing;
- heartbeat and end-of-session packets;
- source start index and maximum message count.

A baseline round-trip check de-encapsulates the generated frames and compares every recovered ITCH payload byte-for-byte with the BinaryFILE source. Perform this check before using the vectors to debug RTL.

Commands are in [`running_the_project.md`](running_the_project.md).

---

## Stage 1 — `frame_crack`

`frame_crack` strips the supported Ethernet II, IPv4, and UDP headers and emits the UDP payload as one AXI datagram.

### Supported packet shape

| Layer | Current policy |
|---|---|
| Ethernet II | Require untagged EtherType `0x0800`; source/destination MAC are not used for filtering |
| VLAN | Not supported; tagged frames are rejected by the EtherType check |
| IPv4 | Require version 4 and IHL = 5 |
| Fragmentation | Drop fragmented packets |
| UDP | Require protocol 17; optionally check destination port |
| Checksums | IP and UDP checksums are not validated |
| Ethernet FCS | Assumed to have been handled before the RTL boundary |
| AXI framing | Non-final beats require full `tkeep`; final `tkeep` must be contiguous |

The fixed supported prefix is:

```text
Ethernet II 14 bytes + IPv4 20 bytes + UDP 8 bytes = 42 bytes
```

At four bytes per cycle, the complete header requires eleven input beats. The payload begins two bytes into the final header beat, so the stage uses a fixed two-byte carry aligner.

This is a latency and simplicity trade-off: the fixed implementation avoids a general variable-offset parser, while unsupported VLAN tags and IPv4 options are rejected explicitly.

### Outputs

In addition to the UDP payload AXI stream, the stage provides:

```text
datagram length
datagram-start pulse
frame-drop pulse
frame-error bit map
```

### Error conditions

The stage reports and drops:

- bad `tkeep`;
- unsupported EtherType;
- non-IPv4 version;
- IHL other than 5;
- non-UDP protocol;
- fragmented IPv4 packets;
- configured destination-port mismatch;
- invalid UDP length;
- runt frames or early `tlast`.

Dropped frames must not emit a partial UDP payload downstream.

---

## Stage 2 — `mold_deframe`

`mold_deframe` parses:

```text
session[10] + sequence[8] + message_count[2]
```

For a normal data packet it then extracts:

```text
message_length[2] + ITCH payload
```

for each advertised message.

The stage emits:

- concatenated ITCH payload bytes;
- one 16-bit length token per ITCH message;
- parsed session, sequence, count, and expected-next metadata;
- message/count/length error status;
- the sequence-guard status exposed by `ingress_top`.

The contract with `realign` is exact: one accepted length token must be followed by exactly that many payload bytes.

Heartbeat, EOS, duplicate, gap, and stale semantics are kept in [`moldudp64_sequence_handling.md`](moldudp64_sequence_handling.md) rather than duplicated here.

### Malformed datagrams

The stage detects cases including:

- datagrams shorter than the 20-byte MoldUDP64 header;
- a message length that extends beyond the UDP payload;
- message count that cannot be satisfied by the datagram;
- malformed final `tkeep`;
- payload accompanying an EOS control header.

Malformed datagrams are dropped and must not emit a partial ITCH message.

---

## Stage 3 — `realign`

MoldUDP64 messages are variable length and not aligned to the 32-bit stream. `realign` combines the payload byte stream with the corresponding message-length tokens and emits:

```text
one aligned AXI packet per ITCH message
```

It handles:

- messages beginning at arbitrary byte offsets;
- messages spanning several input beats;
- multiple message boundaries within one datagram;
- partial final output beats;
- correct `tkeep` and `tlast` generation;
- downstream backpressure;
- zero length, underflow, overflow, and malformed-`tkeep` status.

The aligned output preserves the decoder's file-fed contract: `data_handler` sees one complete ITCH message per AXI packet regardless of its original position in the MoldUDP64 datagram.

---

## Integration with decoder and book

After realignment, the network path and file-fed path have the same decoder input contract:

```text
ingress_top.m_itch_* -> data_handler -> symbol_router -> order_book
```

The complete test flow is:

1. generate `events.jsonl` and `states.jsonl` from a BinaryFILE source;
2. encapsulate the same source messages into Ethernet frames;
3. drive those frames into `ingress_top`;
4. compare recovered ITCH messages where required;
5. decode and apply accepted events;
6. compare BBO output with the corresponding golden states.

This common-source rule is important: network and file-fed tests must not accidentally use different event sequences.

---

## Verification coverage

Directed ingress cases include:

| Campaign | Purpose |
|---|---|
| Valid minimal frame | Baseline Ethernet/IPv4/UDP stripping |
| Ethernet padding | Stop at UDP length rather than forwarding padding |
| Multiple ITCH messages per datagram | MoldUDP64 block splitting |
| Message crosses AXI beats | Deframe and realignment correctness |
| Partial final message beat | Correct `tkeep` and `tlast` |
| Random downstream stalls | Lossless backpressure behaviour |
| Invalid EtherType, IP version, IHL, protocol, fragment, or UDP length | Explicit frame-drop policies |
| MoldUDP64 length/count overrun | No partial malformed message emission |
| Duplicate/gap/control packets | Sequence guard and no unintended book mutation |

The full verification architecture is in [`golden_model.md`](golden_model.md).

---

## Current performance limitation

`frame_crack` can forward approximately one 32-bit payload beat per cycle after the fixed header. The current bottleneck is later:

```text
mold_deframe: stored beat -> one byte per cycle -> rebuilt payload beat
realign:      stored beat -> one byte per cycle -> rebuilt aligned beat
```

Both stages therefore achieve about four payload bytes per six cycles, limiting raw recovered ITCH throughput to approximately 0.569 Gbit/s at 106.667 MHz.

The intended optimisation order is:

1. make `mold_deframe` consume all four byte lanes each cycle;
2. replace `realign` with a register/LUT reservoir that can accept and emit simultaneously;
3. add skid buffers only where timing or elasticity measurements justify them;
4. widen the interface only after the 32-bit path sustains one beat per cycle.

This spends available LUT/register headroom while avoiding additional BRAM consumption.
