"""Shared packet builders for ingress correctness and performance tests.

These helpers construct complete ITCH payloads, MoldUDP64 datagrams, and
Ethernet/IPv4/UDP frames using the byte ordering expected by ingress_top.sv.
They deliberately contain no cocotb or DUT-specific logic so the same stimulus
format can be reused by multiple test modules.
"""

from __future__ import annotations


WORD_BYTES = 4
AXIS_KEEP_W = 4

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
