"""cocotb ingress-only correctness tests for ingress_top.sv.

Scope:
- Drive complete Ethernet/IPv4/UDP/MoldUDP64 frames into ingress_top.
- Check that the recovered ITCH payload messages on m_itch_* exactly match
  the original MoldUDP64 message blocks.
- Check basic MoldUDP64 sideband extraction.
- Check that malformed frame headers are dropped before they reach realign.

This intentionally does not instantiate data_handler/order_book. That keeps this
test focused on the Phase-3 ingress path:
    frame_crack -> mold_deframe -> realign
"""

from __future__ import annotations

from typing import Any, Callable

import cocotb
from cocotb.triggers import RisingEdge

from itch_harness.axis import clock_cycles, reset_dut, start_clock
from itch_harness.scoreboard import signal_value_to_int


WORD_BYTES = 4
AXIS_KEEP_W = 4

FRAME_ERR_BAD_ETHERTYPE = 0

SESSION = b"ITCHTEST01"  # exactly 10 bytes
SRC_PORT = 40_000
DST_PORT = 50_000


def common_itch_header(
    msg_type: str,
    *,
    locate: int = 1,
    tracking: int = 1,
    timestamp_ns: int = 1,
) -> bytes:
    """Build the 11-byte ITCH common header."""

    if len(msg_type) != 1:
        raise ValueError("msg_type must be one character")
    if timestamp_ns >= (1 << 48):
        raise ValueError("timestamp_ns must fit in 48 bits")

    return (
        msg_type.encode("ascii")
        + locate.to_bytes(2, "big")
        + tracking.to_bytes(2, "big")
        + timestamp_ns.to_bytes(6, "big")
    )


def add_order_payload(
    order_ref: int,
    *,
    side: str,
    shares: int,
    price: int,
    locate: int = 1,
    tracking: int = 1,
    timestamp_ns: int = 1,
    stock: bytes = b"AAPL",
) -> bytes:
    """Build an ITCH Add Order, type A, 36-byte payload."""

    payload = (
        common_itch_header(
            "A",
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )
        + order_ref.to_bytes(8, "big")
        + side.encode("ascii")
        + shares.to_bytes(4, "big")
        + stock.ljust(8, b" ")[:8]
        + price.to_bytes(4, "big")
    )

    assert len(payload) == 36
    return payload


def delete_order_payload(
    order_ref: int,
    *,
    locate: int = 1,
    tracking: int = 1,
    timestamp_ns: int = 1,
) -> bytes:
    """Build an ITCH Order Delete, type D, 19-byte payload."""

    payload = (
        common_itch_header(
            "D",
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )
        + order_ref.to_bytes(8, "big")
    )

    assert len(payload) == 19
    return payload


def cancel_order_payload(
    order_ref: int,
    *,
    cancelled_shares: int,
    locate: int = 1,
    tracking: int = 1,
    timestamp_ns: int = 1,
) -> bytes:
    """Build an ITCH Order Cancel, type X, 23-byte payload."""

    payload = (
        common_itch_header(
            "X",
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )
        + order_ref.to_bytes(8, "big")
        + cancelled_shares.to_bytes(4, "big")
    )

    assert len(payload) == 23
    return payload


def replace_order_payload(
    old_order_ref: int,
    new_order_ref: int,
    *,
    shares: int,
    price: int,
    locate: int = 1,
    tracking: int = 1,
    timestamp_ns: int = 1,
) -> bytes:
    """Build an ITCH Order Replace, type U, 35-byte payload."""

    payload = (
        common_itch_header(
            "U",
            locate=locate,
            tracking=tracking,
            timestamp_ns=timestamp_ns,
        )
        + old_order_ref.to_bytes(8, "big")
        + new_order_ref.to_bytes(8, "big")
        + shares.to_bytes(4, "big")
        + price.to_bytes(4, "big")
    )

    assert len(payload) == 35
    return payload


def build_mold_datagram(
    payloads: list[bytes],
    *,
    session: bytes = SESSION,
    seq: int = 1,
    count: int | None = None,
) -> bytes:
    """Build one MoldUDP64 datagram.

    Layout:
        session(10) + sequence(8) + count(2)
        + count * (message_length(2) + ITCH_payload)
    """

    if len(session) != 10:
        raise ValueError("MoldUDP64 session must be exactly 10 bytes")

    if count is None:
        count = len(payloads)

    datagram = session + seq.to_bytes(8, "big") + count.to_bytes(2, "big")

    for payload in payloads:
        datagram += len(payload).to_bytes(2, "big")
        datagram += payload

    return datagram


def build_eth_ipv4_udp_frame(
    udp_payload: bytes,
    *,
    ethertype: int = 0x0800,
    ip_protocol: int = 17,
    ip_flags_frag: int = 0,
    src_port: int = SRC_PORT,
    dst_port: int = DST_PORT,
) -> bytes:
    """Wrap a UDP payload in Ethernet II + IPv4 + UDP headers.

    Checksums are zero because the RTL currently either ignores them or leaves
    checksum validation out of the latency-critical path.
    """

    dst_mac = b"\x01\x02\x03\x04\x05\x06"
    src_mac = b"\x0a\x0b\x0c\x0d\x0e\x0f"

    eth = dst_mac + src_mac + ethertype.to_bytes(2, "big")

    udp_len = 8 + len(udp_payload)
    ip_total_len = 20 + udp_len

    ipv4 = (
        bytes([0x45, 0x00])
        + ip_total_len.to_bytes(2, "big")
        + b"\x00\x01"
        + ip_flags_frag.to_bytes(2, "big")
        + bytes([64, ip_protocol])
        + b"\x00\x00"
        + b"\x0a\x00\x00\x01"
        + b"\x0a\x00\x00\x02"
    )

    udp = (
        src_port.to_bytes(2, "big")
        + dst_port.to_bytes(2, "big")
        + udp_len.to_bytes(2, "big")
        + b"\x00\x00"
    )

    return eth + ipv4 + udp + udp_payload


def frame_to_axis_words(frame: bytes) -> list[tuple[int, int, bool]]:
    """Split a frame into 32-bit AXIS beats.

    Byte lane 0 maps to tdata[31:24]. Final tkeep is MSB-contiguous:
        1 byte  -> 1000
        2 bytes -> 1100
        3 bytes -> 1110
        4 bytes -> 1111
    """

    words: list[tuple[int, int, bool]] = []

    for offset in range(0, len(frame), WORD_BYTES):
        chunk = frame[offset : offset + WORD_BYTES]
        valid_bytes = len(chunk)

        data = int.from_bytes(chunk.ljust(WORD_BYTES, b"\x00"), "big")
        keep = ((1 << valid_bytes) - 1) << (AXIS_KEEP_W - valid_bytes)
        last = offset + WORD_BYTES >= len(frame)

        words.append((data, keep, last))

    return words


async def initialise_ingress(dut: Any) -> None:
    await start_clock(dut)

    dut.s_frame_tdata_i.value = 0
    dut.s_frame_tkeep_i.value = 0
    dut.s_frame_tvalid_i.value = 0
    dut.s_frame_tlast_i.value = 0
    dut.m_itch_tready_i.value = 1

    await reset_dut(dut, cycles=5)


async def drive_axis_frame(
    dut: Any,
    frame: bytes,
    *,
    timeout_cycles: int = 20_000,
) -> None:
    """Drive one Ethernet frame as one AXIS packet."""

    for word, keep, last in frame_to_axis_words(frame):
        dut.s_frame_tdata_i.value = word
        dut.s_frame_tkeep_i.value = keep
        dut.s_frame_tlast_i.value = int(last)
        dut.s_frame_tvalid_i.value = 1

        for _ in range(timeout_cycles):
            await RisingEdge(dut.clk)
            if signal_value_to_int(dut.s_frame_tready_o.value) == 1:
                break
        else:
            raise TimeoutError("timed out waiting for s_frame_tready_o")

        dut.s_frame_tvalid_i.value = 0
        dut.s_frame_tlast_i.value = 0
        dut.s_frame_tdata_i.value = 0
        dut.s_frame_tkeep_i.value = 0


class IngressMonitor:
    """Collect ingress_top outputs and one-cycle status pulses."""

    def __init__(
        self,
        dut: Any,
        *,
        ready_pattern: Callable[[int], bool] | None = None,
    ) -> None:
        self.dut = dut
        self.ready_pattern = ready_pattern

        self.running = True
        self.cycle = 0

        self.messages: list[bytes] = []
        self._current_message = bytearray()

        self.seq_samples: list[dict[str, int]] = []
        self.heartbeat_count = 0
        self.eos_count = 0

        self.frame_drop_errs: list[int] = []
        self.mold_drop_errs: list[int] = []
        self.realign_errs: list[int] = []

    async def run(self) -> None:
        while self.running:
            ready = 1
            if self.ready_pattern is not None:
                ready = int(self.ready_pattern(self.cycle))

            self.dut.m_itch_tready_i.value = ready

            await RisingEdge(self.dut.clk)

            if signal_value_to_int(self.dut.seq_valid_o.value) == 1:
                self.seq_samples.append(
                    {
                        "session": signal_value_to_int(self.dut.session_o.value),
                        "seq": signal_value_to_int(self.dut.seq_o.value),
                        "count": signal_value_to_int(self.dut.count_o.value),
                        "expected_next": signal_value_to_int(
                            self.dut.expected_next_o.value
                        ),
                    }
                )

            if signal_value_to_int(self.dut.heartbeat_o.value) == 1:
                self.heartbeat_count += 1

            if signal_value_to_int(self.dut.eos_o.value) == 1:
                self.eos_count += 1

            if signal_value_to_int(self.dut.frame_drop_o.value) == 1:
                self.frame_drop_errs.append(signal_value_to_int(self.dut.frame_err_o.value))

            if signal_value_to_int(self.dut.mold_drop_o.value) == 1:
                self.mold_drop_errs.append(signal_value_to_int(self.dut.mold_err_o.value))

            realign_err = signal_value_to_int(self.dut.realign_err_o.value)
            if realign_err != 0:
                self.realign_errs.append(realign_err)

            output_fire = (
                signal_value_to_int(self.dut.m_itch_tvalid_o.value) == 1
                and ready == 1
            )

            if output_fire:
                word = signal_value_to_int(self.dut.m_itch_tdata_o.value)
                self._current_message.extend(word.to_bytes(WORD_BYTES, "big"))

                if signal_value_to_int(self.dut.m_itch_tlast_o.value) == 1:
                    self.messages.append(bytes(self._current_message))
                    self._current_message.clear()

            self.cycle += 1

    async def wait_for_message_count(
        self,
        expected_count: int,
        *,
        timeout_cycles: int = 50_000,
    ) -> None:
        for _ in range(timeout_cycles):
            if len(self.messages) >= expected_count:
                return
            await RisingEdge(self.dut.clk)

        raise TimeoutError(
            f"timed out waiting for {expected_count} messages; "
            f"got {len(self.messages)}"
        )

    def stop(self) -> None:
        self.running = False


def assert_payloads_match(got_messages: list[bytes], expected_payloads: list[bytes]) -> None:
    assert len(got_messages) == len(expected_payloads), (
        f"message count mismatch: expected {len(expected_payloads)}, "
        f"got {len(got_messages)}"
    )

    for index, (got_raw, expected) in enumerate(zip(got_messages, expected_payloads)):
        got = got_raw[: len(expected)]
        padding = got_raw[len(expected) :]

        assert got == expected, (
            f"ITCH payload mismatch at message {index}: "
            f"expected {expected.hex()}, got {got.hex()}"
        )

        assert padding == b"\x00" * len(padding), (
            f"non-zero padding at message {index}: padding={padding.hex()}"
        )


def session_int_to_bytes(value: int) -> bytes:
    return value.to_bytes(10, "big")


@cocotb.test()
async def test_ingress_recovers_multiple_messages_from_one_mold_datagram(dut: Any) -> None:
    """One Ethernet frame containing several MoldUDP64 ITCH messages recovers exactly."""

    await initialise_ingress(dut)

    payloads = [
        add_order_payload(
            1001,
            side="B",
            shares=100,
            price=10_000,
            tracking=1,
            timestamp_ns=1,
        ),
        delete_order_payload(
            1001,
            tracking=2,
            timestamp_ns=2,
        ),
        cancel_order_payload(
            1002,
            cancelled_shares=25,
            tracking=3,
            timestamp_ns=3,
        ),
        replace_order_payload(
            1003,
            2003,
            shares=50,
            price=10_010,
            tracking=4,
            timestamp_ns=4,
        ),
    ]

    seq = 100
    datagram = build_mold_datagram(payloads, seq=seq)
    frame = build_eth_ipv4_udp_frame(datagram)

    monitor = IngressMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    await drive_axis_frame(dut, frame)
    await monitor.wait_for_message_count(len(payloads))
    await clock_cycles(dut, 20)

    monitor.stop()
    await clock_cycles(dut, 1)
    monitor_task.cancel()

    assert_payloads_match(monitor.messages, payloads)

    assert len(monitor.seq_samples) == 1
    sample = monitor.seq_samples[0]
    assert session_int_to_bytes(sample["session"]) == SESSION
    assert sample["seq"] == seq
    assert sample["count"] == len(payloads)
    assert sample["expected_next"] == seq + len(payloads)

    assert monitor.heartbeat_count == 0
    assert monitor.eos_count == 0
    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []


@cocotb.test()
async def test_ingress_preserves_messages_under_output_backpressure(dut: Any) -> None:
    """Backpressure on m_itch_tready_i must not drop or corrupt recovered messages."""

    await initialise_ingress(dut)

    payloads = [
        add_order_payload(1100, side="B", shares=10, price=9_990, tracking=1),
        add_order_payload(1101, side="S", shares=20, price=10_020, tracking=2),
        delete_order_payload(1100, tracking=3),
        cancel_order_payload(1101, cancelled_shares=5, tracking=4),
        replace_order_payload(1101, 2101, shares=15, price=10_025, tracking=5),
    ]

    seq = 250
    datagram = build_mold_datagram(payloads, seq=seq)
    frame = build_eth_ipv4_udp_frame(datagram)

    def ready_pattern(cycle: int) -> bool:
        # Deterministic stalls. This is intentionally simple so failures are
        # reproducible in the waveform.
        return cycle % 7 not in (3, 4)

    monitor = IngressMonitor(dut, ready_pattern=ready_pattern)
    monitor_task = cocotb.start_soon(monitor.run())

    await drive_axis_frame(dut, frame)
    await monitor.wait_for_message_count(len(payloads))
    await clock_cycles(dut, 20)

    monitor.stop()
    await clock_cycles(dut, 1)
    monitor_task.cancel()

    assert_payloads_match(monitor.messages, payloads)

    assert len(monitor.seq_samples) == 1
    assert monitor.seq_samples[0]["seq"] == seq
    assert monitor.seq_samples[0]["count"] == len(payloads)
    assert monitor.seq_samples[0]["expected_next"] == seq + len(payloads)

    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []


@cocotb.test()
async def test_ingress_heartbeat_and_eos_produce_sideband_only(dut: Any) -> None:
    """MoldUDP64 heartbeat/EOS datagrams should not emit ITCH payload messages."""

    await initialise_ingress(dut)

    heartbeat_seq = 500
    eos_seq = 600

    heartbeat = build_eth_ipv4_udp_frame(
        build_mold_datagram([], seq=heartbeat_seq, count=0x0000)
    )
    eos = build_eth_ipv4_udp_frame(
        build_mold_datagram([], seq=eos_seq, count=0xFFFF)
    )

    monitor = IngressMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    await drive_axis_frame(dut, heartbeat)
    await clock_cycles(dut, 30)

    await drive_axis_frame(dut, eos)
    await clock_cycles(dut, 60)

    monitor.stop()
    await clock_cycles(dut, 1)
    monitor_task.cancel()

    assert monitor.messages == []

    assert monitor.heartbeat_count == 1
    assert monitor.eos_count == 1

    assert len(monitor.seq_samples) == 2

    heartbeat_sample = monitor.seq_samples[0]
    assert heartbeat_sample["seq"] == heartbeat_seq
    assert heartbeat_sample["count"] == 0x0000
    assert heartbeat_sample["expected_next"] == heartbeat_seq

    eos_sample = monitor.seq_samples[1]
    assert eos_sample["seq"] == eos_seq
    assert eos_sample["count"] == 0xFFFF
    assert eos_sample["expected_next"] == eos_seq + 0xFFFF

    assert monitor.frame_drop_errs == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []


@cocotb.test()
async def test_ingress_drops_bad_ethertype_before_mold_and_realign(dut: Any) -> None:
    """A non-IPv4 Ethernet frame should be dropped by frame_crack."""

    await initialise_ingress(dut)

    payloads = [
        add_order_payload(3001, side="B", shares=100, price=10_000),
    ]

    datagram = build_mold_datagram(payloads, seq=900)
    frame = build_eth_ipv4_udp_frame(datagram, ethertype=0x86DD)

    monitor = IngressMonitor(dut)
    monitor_task = cocotb.start_soon(monitor.run())

    await drive_axis_frame(dut, frame)
    await clock_cycles(dut, 80)

    monitor.stop()
    await clock_cycles(dut, 1)
    monitor_task.cancel()

    assert monitor.messages == []
    assert monitor.seq_samples == []
    assert monitor.mold_drop_errs == []
    assert monitor.realign_errs == []

    assert any(
        err & (1 << FRAME_ERR_BAD_ETHERTYPE)
        for err in monitor.frame_drop_errs
    ), f"expected bad-EtherType frame_drop; got {monitor.frame_drop_errs}"
