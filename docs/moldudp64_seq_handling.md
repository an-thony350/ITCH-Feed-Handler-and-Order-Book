# MoldUDP64 Sequence Handling

This document defines the packet-level sequence policy implemented around `mold_deframe.sv` and `mold_seq_guard.sv`.

The sequence guard protects the downstream ITCH decoder and order book from duplicate packet application, reports gaps, and keeps a sticky stale state. It deliberately does not implement a retransmission or state-recovery channel.

Commands for generating duplicate, A/B, gap, heartbeat, and EOS vectors are in [`running_the_project.md`](running_the_project.md).

---

## 1. MoldUDP64 framing

A MoldUDP64 UDP payload begins with:

```text
session[10 bytes]
sequence_number[8 bytes]
message_count[2 bytes]
```

For a normal data packet, the header is followed by `message_count` blocks:

```text
message_length[2 bytes]
ITCH_message[message_length bytes]
```

The sequence number identifies the first ITCH message in the packet. Subsequent messages increment implicitly, so for a normal packet:

```text
packet_end = sequence_number + message_count
```

`packet_end` becomes the next expected sequence after the packet is accepted.

Special message counts are:

```text
0x0000 -> heartbeat
0xffff -> end of session
```

Both are status-only and contain no ITCH message blocks.

---

## 2. RTL split

```mermaid
flowchart LR
    A[UDP payload] --> B[mold_deframe]
    B --> C[session / seq / count]
    C --> D[mold_seq_guard]
    D --> E[accept or drop]
    D --> F[in-order / duplicate / gap / stale / heartbeat / EOS]
    B -->|accepted message bytes + lengths| G[realign]
```

`mold_deframe` parses the header and message blocks. `mold_seq_guard` decides whether the current datagram may forward payload and updates the expected sequence state.

The sequence decision is made when one `seq_valid` pulse is presented for the parsed header.

---

## 3. Acceptance policy

| Condition | Packet action | Sequence/status action |
|---|---|---|
| First normal data packet | Accept | Establish `expected_seq = seq + count`; pulse in-order |
| `seq == expected_seq` | Accept | Advance `expected_seq` by `count`; pulse in-order |
| `seq > expected_seq` | Accept | Record the missing range, set sticky stale, and advance past the accepted packet; pulse gap |
| `seq < expected_seq` | Drop | Do not mutate the book; pulse duplicate |
| `count == 0` | Drop payload | Pulse heartbeat; establish or update sequence status as described below |
| `count == 0xffff` | Drop payload | Pulse EOS; establish or update sequence status as described below |

A packet that begins before `expected_seq` is treated as wholly duplicate/late. The first implementation does not partially recover a packet that overlaps the expected sequence range.

---

## 4. Gap and stale behaviour

When a packet starts after the expected sequence:

```text
gap_start = expected_seq
gap_end   = received_seq - 1
```

The post-gap packet is still accepted. This is a deliberate low-latency decision: the hot path continues processing available data instead of blocking while waiting for recovery.

The consequence is that the book is no longer guaranteed to represent complete exchange state. `stale` therefore becomes sticky until explicitly cleared.

Clearing stale status:

- clears the sticky `stale` indication;
- does not rewind `expected_seq`;
- does not reconstruct missed orders;
- is only a status/control action, not recovery.

A production implementation would pair gap detection with a retransmission or snapshot service and would only declare the book current after recovery had been applied.

---

## 5. Duplicate suppression and logical A/B behaviour

Nasdaq-style A/B feeds carry redundant copies of the same sequenced data. The implemented packet-level rule is first-copy-wins:

```text
first copy at the expected sequence -> accepted
later copy beginning below expected -> dropped as duplicate/late
```

The current verification campaign generates logical A and B copies and presents them to the same RTL input. This proves that a second copy cannot update the book twice.

It does **not** implement or prove:

- two independent physical receive ports;
- arbitration between separate MAC clock domains;
- per-feed health monitoring;
- recovery when the two copies contain different damage patterns.

Those features belong in a future dual-ingress front end ahead of the common sequence guard.

---

## 6. Heartbeat handling

A heartbeat has `count == 0` and no ITCH payload.

Behaviour:

- the payload path is dropped;
- `heartbeat` pulses for one cycle;
- a first heartbeat establishes the expected sequence at its advertised `seq`;
- a heartbeat equal to the current expectation confirms liveness without changing it;
- a heartbeat ahead of the current expectation reports a gap, sets stale, records the missing range, and moves `expected_seq` to the heartbeat sequence.

Because a heartbeat contains no messages, it never mutates the order book.

---

## 7. End-of-session handling

An end-of-session packet has `count == 0xffff` and no ITCH payload.

Behaviour:

- the payload path is dropped;
- `eos` pulses for one cycle;
- the sequence/status comparison follows the same control-packet rules as heartbeat;
- no order-book event is emitted.

The current sequence guard reports EOS but does not itself clear or invalidate order-book memory. Session-reset policy remains a higher-level control decision.

---

## 8. Exposed status

The ingress wrapper exposes:

```text
session
seq
count
expected_next
seq_valid
in_order
duplicate
gap
heartbeat
eos
stale
expected_seq
gap_start
gap_end
```

The complete status set is useful in simulation and is suitable for a future AXI-Lite CSR block. The current PYNQ block design does not map every sequence/error signal into PS-visible registers.

---

## 9. Verification campaigns

Required directed cases are:

| Campaign | Expected result |
|---|---|
| First packet | Accepted and expectation established |
| Consecutive packet | Accepted as in-order |
| Exact repeated packet | Dropped; duplicate pulse; no second book mutation |
| Logical B copy after A | First accepted, second suppressed |
| Forward sequence jump | Post-gap packet accepted; gap range and stale asserted |
| Late missing packet after jump | Dropped as duplicate/late |
| Heartbeat at expectation | Heartbeat pulse; no book mutation |
| Heartbeat ahead | Gap and stale reported; no book mutation |
| EOS | EOS pulse; no book mutation |
| Explicit stale clear | Sticky stale clears without rewinding expected sequence |

The complete full-chain test must also prove that duplicate and control packets do not change the number or ordering of accepted book events.

---

## 10. Current limitations

- 64-bit sequence wrap is out of scope.
- Overlapping packets are dropped as whole datagrams rather than partially accepted.
- Session-identifier changes do not yet enforce a defined book/session reset policy.
- There is no retransmission request, GLIMPSE snapshot, or recovery state machine.
- A/B verification uses one logical input, not two physical receivers.
- Stale clear is a status operation only and does not prove that state has been recovered.
