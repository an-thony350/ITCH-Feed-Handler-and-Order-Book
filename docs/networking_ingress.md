# Networking Ingress

## Scope

The ingress path takes Ethernet-frame AXI4-Stream input and emits aligned ITCH-message AXI4-Stream packets that can be consumed by `data_handler.sv`.

The real Nasdaq public sample files used by the golden model are not Ethernet captures. They are ITCH BinaryFILE streams: each record is a two-byte length followed by one ITCH payload. Therefore, the networking layer is verified using a software encapsulator that wraps the existing BinaryFILE messages into synthetic Ethernet/IP/UDP/MoldUDP64 frames.

The goal for this phase is:

```text
BinaryFILE ITCH
  -> software encapsulator
  -> Ethernet / IPv4 / UDP / MoldUDP64 frames
  -> ingress RTL
  -> recovered ITCH messages
  -> data_handler
  -> order_book
  -> bit-exact match against states.jsonl
```

This is not claiming direct access to a live market multicast stream. It is a deterministic way to exercise the exact protocol layers that a real wire-fed design would need.

## Current RTL top-level

`rtl/ingress_top.sv` wires the ingress chain as:

```text
s_frame AXIS
  -> frame_crack
  -> mold_deframe
  -> realign
  -> m_itch AXIS
```

The top-level input is a 64-bit AXI4-Stream Ethernet frame interface:

```systemverilog
s_frame_tdata_i
s_frame_tkeep_i
s_frame_tvalid_i
s_frame_tlast_i
s_frame_tready_o
```

The top-level output is a 64-bit AXI4-Stream ITCH-message interface:

```systemverilog
m_itch_tdata_o
m_itch_tvalid_o
m_itch_tlast_o
m_itch_tready_i
```

`ingress_top` also exposes MoldUDP64 sideband for the later gap/A-B logic:

```systemverilog
session_o
seq_o
count_o
expected_next_o
seq_valid_o
heartbeat_o
eos_o
```

and error/status outputs:

```systemverilog
frame_drop_o
frame_err_o
mold_drop_o
mold_err_o
realign_err_o
```

## Shared package conventions

The ingress path imports `hdl_header::*`.

Important package constants:

```systemverilog
parameter int AXIS_DATA_W = 64;
parameter int AXIS_KEEP_W = AXIS_DATA_W / 8;

typedef logic [AXIS_DATA_W-1:0] axis_data_t;
typedef logic [AXIS_KEEP_W-1:0] axis_keep_t;
```

Byte-lane convention from `hdl_header.sv`:

```text
lane 0 = tdata[63:56]
lane 1 = tdata[55:48]
...
lane 7 = tdata[7:0]

tkeep[7] corresponds to lane 0 / tdata[63:56]
```


## Stage 0: software encapsulator

Input:

```text
length-prefixed ITCH BinaryFILE records
```

Output:

```text
Ethernet II frames carrying IPv4/UDP/MoldUDP64 payloads
```

Required behaviour:

1. Read ITCH payloads from the same BinaryFILE source used by the golden model.
2. Group one or more ITCH messages into each MoldUDP64 datagram.
3. Wrap each MoldUDP64 datagram in UDP, IPv4, and Ethernet II.
4. Preserve enough metadata to match recovered messages back to the original `msg_index`.
5. Provide knobs for:
   - messages per datagram;
   - sequence number start;
   - injected gaps;
   - duplicate packets;
   - A/B duplicate streams;
   - heartbeat packets (`count == 0`);
   - end-of-session packets (`count == 0xffff`).

MoldUDP64 payload format:

```text
session[10] seq[8] count[2]
  repeated count times:
    message_length[2] message_payload[message_length]
```

`seq` is the sequence number of the first ITCH message in the packet.

```text
expected_next = seq + count
```

The encapsulator must be validated before RTL debugging. A good round-trip check is:

```text
BinaryFILE -> encapsulate -> software de-encapsulate -> BinaryFILE-equivalent messages
```

The recovered message list must exactly match the original ITCH payload list.

## Stage 1: `frame_crack`

`frame_crack` strips the fixed Ethernet II + IPv4 + UDP headers and emits the UDP payload as an AXI4-Stream datagram for `mold_deframe`.

Current implementation assumptions:

- `AXIS_DATA_W == 32`.
- One complete Ethernet frame is provided per input AXI packet.
- AXIS byte order is big-endian: byte lane 0 is `tdata[31:24]`.
- Ethernet is untagged Ethernet II.
- IPv4 only.
- IPv4 header length must be IHL = 5, so there are no IP options.
- UDP only.
- IPv4 fragments are dropped.
- UDP payload starts at fixed byte offset 42, so the implementation uses a fixed 2-byte carry aligner rather than a generic byte-lane packer.

Inputs:

```text
Ethernet frame AXI4-Stream
```

Outputs:

```text
m_axis_tdata
m_axis_tkeep
m_axis_tvalid
m_axis_tlast
m_axis_tready
m_dgram_len
m_dgram_start
frame_drop
frame_err
```

`m_dgram_len` is valid on the first output beat of a datagram, when `m_dgram_start` is asserted.

Minimum parse policy:

| Layer | Required parsing | Current policy |
|---|---|---|
| Ethernet II | EtherType at bytes 12..13 | Require IPv4 EtherType `0x0800`. Destination/source MAC are skipped in the current parser. VLAN support is deferred. |
| IPv4 | version, IHL, total length, flags/fragment offset, protocol | Require IPv4, IHL = 5, and UDP. Drop fragments. IHL > 5 is dropped for now; support can be added later by skipping IP options. |
| UDP | destination port, UDP length | Optionally check destination port using `CHECK_DST_PORT` / `EXPECTED_DST_PORT`. UDP source port is skipped in the current parser. |
| Checksums | IP/UDP checksums | Skipped initially. They can be computed in parallel later, but should not stall the hot path. |
| AXI framing | `tkeep`, `tlast` | Non-final beats must have full `tkeep`. Final-beat `tkeep` must be contiguous from lane 0. Bad `tkeep` drops the frame. |

Error policy:

- Bad `tkeep` -> assert `frame_drop_o` and set `FRAME_ERR_BAD_TKEEP`.
- Bad EtherType -> assert `frame_drop_o` and set `FRAME_ERR_BAD_ETHERTYPE`.
- Bad IP version -> drop and set `FRAME_ERR_BAD_IP_VER`.
- Bad IHL -> drop and set `FRAME_ERR_BAD_IHL`.
- Non-UDP IPv4 packet -> drop and set `FRAME_ERR_BAD_PROTO`.
- Fragmented IPv4 packet -> drop and set `FRAME_ERR_FRAGMENT`.
- Destination-port mismatch -> drop and set `FRAME_ERR_BAD_UDP_PORT`, only when `CHECK_DST_PORT == 1`.
- Bad UDP length -> drop and set `FRAME_ERR_BAD_UDP_LEN`.
- Runt frame / early `tlast` before the expected header or payload bytes -> drop and set `FRAME_ERR_RUNT_FRAME`.
- Dropped frames must not emit partial payload to `mold_deframe`.

Acceptance tests:

1. Valid minimal untagged IPv4/UDP frame emits exactly the UDP payload.
2. Valid frame with Ethernet padding emits only the UDP payload and drains the padding.
3. Zero-length UDP payload emits no payload beats and does not assert an error.
4. Bad EtherType is dropped.
5. Bad IPv4 version is dropped.
6. IHL other than 5 is dropped.
7. Non-UDP IPv4 packet is dropped.
8. Fragmented IPv4 packet is dropped.
9. Bad UDP length / runt frame is dropped.
10. Optional destination-port mismatch is dropped only when `CHECK_DST_PORT == 1`.
11. Bad `tkeep` is dropped.
12. Backpressure from `mold_deframe` does not lose bytes or corrupt `tlast`.


## Stage 2: `mold_deframe`

`mold_deframe` parses the MoldUDP64 header and splits message blocks.

Inputs:

```text
UDP payload AXIS
dgram_len
dgram_start
```

Outputs:

```text
payload_tdata
payload_tkeep
payload_tvalid
payload_tlast
payload_tready

msg_len
msg_len_valid
msg_len_ready

session
seq
count
expected_next
seq_valid
heartbeat
eos
mold_drop
mold_err
```

Required behaviour:

1. Consume the 20-byte MoldUDP64 header.
2. Extract:
   - 10-byte session;
   - 8-byte sequence number;
   - 2-byte message count.
3. For normal packets, emit each ITCH message payload and its 16-bit length.
4. For `count == 0`, assert heartbeat and emit no ITCH payload.
5. For `count == 0xffff`, assert end-of-session and emit no ITCH payload.
6. Detect length overruns where a message block claims bytes beyond the UDP payload.

The important contract between `mold_deframe` and `realign` is that each message has one `msg_len` token and exactly that many payload bytes.

Acceptance tests:

1. Single-message datagram emits one length and one payload.
2. Multi-message datagram emits all messages in order.
3. Message straddling across AXIS beats is preserved.
4. `count == 0` emits heartbeat only.
5. `count == 0xffff` emits EOS only.
6. Claimed message length beyond datagram end asserts drop/error.
7. Backpressure on payload and length channels is handled without losing alignment.

## Stage 3: `realign`

`realign` converts a byte stream of ITCH payloads into message-aligned 64-bit AXI packets for `data_handler`.

Why it exists:

- MoldUDP64 messages are variable length.
- Message boundaries are not guaranteed to align to 64-bit beats.
- Multiple short messages can sit in one beat.
- A single message can straddle multiple beats.

Input contract:

```text
payload AXIS byte stream
msg_len stream from mold_deframe
```

Output contract:

```text
one AXI packet per complete ITCH message
m_itch_tlast_o asserted on the final beat of each message
```

This lets the current `data_handler.sv` continue to operate in its file-fed model: one ITCH message per packet.

Acceptance tests:

1. One message aligned at beat boundary.
2. One message starting at a non-zero byte offset.
3. One message straddling several beats.
4. Two or more short messages inside one beat.
5. Partial final beat has correct `tkeep` and `tlast`.
6. Backpressure on `m_itch_tready_i` does not consume new bytes incorrectly.
7. Length zero and payload underflow/overflow assert `realign_err_o`.

## Stage 4: decoder/book integration

After `realign`, the recovered ITCH message stream should be equivalent to the file-fed payload stream.

The integration path is:

```text
ingress_top.m_itch_* -> data_handler.sv -> order_book.sv
```

Expected behaviour:

- `data_handler` decodes the recovered message into `data_t`.
- `order_book` applies the event.
- BBO/state comparison is made against `states.jsonl` generated from the original BinaryFILE source.

Acceptance test:

```text
encapsulated real/synthetic frames
  -> ingress_top
  -> data_handler
  -> order_book
  -> BBO/full-state match against golden states
```
