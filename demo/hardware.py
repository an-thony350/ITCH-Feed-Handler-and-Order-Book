"""Board-side deterministic DMA replay for the ITCH visual demo.

This module preserves the known-good notebook control flow:
- programme the overlay;
- configure the three fixed order-book base prices;
- discover AAPL/MSFT/NFLX stock-locate codes from Stock Directory messages;
- remap those locates to hardware stock IDs 1/2/3;
- convert Price(4) fields used by the order book from 1/10000 dollars to cents;
- wrap each retained ITCH message in synthetic Ethernet/IPv4/UDP/MoldUDP64;
- send one packet at a time through AXI DMA and wait for completion;
- read BBO state through the existing AXI GPIOs.

The browser never accesses the FPGA directly. app.py receives callbacks from this
module and only publishes cached software state.
"""

from __future__ import annotations

import gzip
import hashlib
import io
import math
import struct
import time
from pathlib import Path
from typing import Callable

import numpy as np
from pynq import Overlay, allocate


# Fixed showcase configuration. Hardware stock IDs are 1, 2 and 3.
TARGET_SYMBOLS = {
    b"AAPL": 1,
    b"MSFT": 2,
    b"NFLX": 3,
}

STOCK_NAMES = {
    1: "AAPL",
    2: "MSFT",
    3: "NFLX",
}

BASE_PRICE_CENTS = {
    1: 21_000,  # $210.00
    2: 12_000,  # $120.00
    3: 32_000,  # $320.00
}

# ITCH Price(4) field offsets for order-book messages that carry a price.
PRICE_OFFSETS = {
    b"A": 32,  # Add Order
    b"F": 32,  # Add Order with MPID
    b"C": 32,  # Order Executed with Price
    b"U": 31,  # Order Replace
}

# Message types which produce one completed order-book result.  The V4 block
# design exposes a 32-bit counter on axi_gpio_meta channel 2 which increments
# on order_book_top.bbo_valid_o.  We use that counter as the completion token
# rather than assuming DMA completion also means the order book has finished.
BOOK_MESSAGE_TYPES = {b"A", b"F", b"E", b"C", b"X", b"D", b"U"}

# The current V4 symbol_router only forwards A/F/U when their whole-cent price
# lies inside the configured 14-bit BBO window.  Such a filtered event never
# reaches an order book and therefore never increments the BBO completion
# counter.
ROUTER_PRICE_FILTER_TYPES = {b"A", b"F", b"U"}
BBO_W = 14

# ITCH fields used to mirror whether an order reference currently exists in
# the hardware order table.  This is only used to decide whether a BBO
# completion pulse is expected; it does not calculate market state in software.
ORDER_REF_OFFSET = 11
NEW_ORDER_REF_OFFSET = 19
REDUCE_SHARES_OFFSET = 19
ADD_SHARES_OFFSET = 20
REPLACE_SHARES_OFFSET = 27

BBO_WAIT_TIMEOUT_S = 0.25


def generate_network_headers(payload_len: int, seq_num: int) -> bytes:
    """Build the same synthetic network framing used by the working notebook."""

    mold_len = 20 + 2 + payload_len
    udp_len = 8 + mold_len
    ip_total_len = 20 + udp_len

    # Ethernet II: destination MAC, source MAC, EtherType=IPv4.
    eth = struct.pack(
        "!6s6sH",
        b"\x00\x11\x22\x33\x44\x55",
        b"\xAA\xBB\xCC\xDD\xEE\xFF",
        0x0800,
    )

    # IPv4: fixed 20-byte header, protocol=UDP.
    ip = struct.pack(
        "!BBHHHBBH4s4s",
        0x45,
        0x00,
        ip_total_len,
        0x0000,
        0x0000,
        64,
        17,
        0x0000,
        b"\xc0\xa8\x01\x64",
        b"\xc0\xa8\x01\xc8",
    )

    # UDP. A zero checksum is valid for IPv4 UDP.
    udp = struct.pack("!HHHH", 12345, 12345, udp_len, 0x0000)

    # One ITCH message per synthetic MoldUDP64 datagram.
    mold = struct.pack("!10sQH", b"SESSION123", seq_num, 1)
    msg_len_hdr = struct.pack("!H", payload_len)

    return eth + ip + udp + mold + msg_len_hdr


class HardwareReplay:
    """Own all FPGA/DMA/GPIO access for one deterministic replay run."""

    def __init__(
        self,
        bitstream_path: str | Path,
        data_path: str | Path,
        message_limit: int,
        on_ready: Callable[[], None],
        on_progress: Callable[[int, int, int], None],
        on_mapping: Callable[[str, int, int], None],
        on_bbo: Callable[[str, int, int, int, int], None],
    ) -> None:
        self.bitstream_path = Path(bitstream_path)
        self.data_path = Path(data_path)
        self.message_limit = int(message_limit)
        self.on_ready = on_ready
        self.on_progress = on_progress
        self.on_mapping = on_mapping
        self.on_bbo = on_bbo

        self.overlay = None
        self.dma = None
        self.gpio_bid = None
        self.gpio_ask = None
        self.gpio_base_price1 = None
        self.gpio_base_price2 = None
        self.gpio_stock_id = None

    def _check_inputs(self) -> None:
        if self.message_limit <= 0:
            raise ValueError("message_limit must be greater than zero")

        if not self.bitstream_path.is_file():
            raise FileNotFoundError(f"Bitstream not found: {self.bitstream_path}")

        hwh_path = self.bitstream_path.with_suffix(".hwh")
        if not hwh_path.is_file():
            raise FileNotFoundError(
                f"Matching HWH not found: {hwh_path}. "
                "The .bit and .hwh files must have the same stem."
            )

        if not self.data_path.is_file():
            raise FileNotFoundError(f"Nasdaq gzip file not found: {self.data_path}")

    def _load_overlay(self) -> None:
        # A fresh Overlay object is created for every run so the PL begins from
        # a known state.
        self.overlay = Overlay(str(self.bitstream_path))

        # Names match the current V4 ZCU106 design.
        self.gpio_bid = self.overlay.axi_gpio_bbo_bid
        self.gpio_ask = self.overlay.axi_gpio_bbo_ask
        self.gpio_base_price1 = self.overlay.axi_gpio_price
        self.gpio_base_price2 = self.overlay.axi_gpio_price1
        self.gpio_stock_id = self.overlay.axi_gpio_meta
        self.dma = self.overlay.axi_dma_0

    def _configure_base_prices(self) -> None:
        # axi_gpio_price carries stock 0 and stock 1 bases.
        self.gpio_base_price1.channel1.write(BASE_PRICE_CENTS[1], 0xFFFF_FFFF)
        self.gpio_base_price1.channel2.write(BASE_PRICE_CENTS[2], 0xFFFF_FFFF)

        # axi_gpio_price1 channel 1 carries stock 2 base.
        self.gpio_base_price2.channel1.write(BASE_PRICE_CENTS[3], 0xFFFF_FFFF)

        if not self.dma.sendchannel.running:
            self.dma.sendchannel.start()

    @staticmethod
    def _price_convert_for_hardware(message: bytearray, msg_type: bytes) -> None:
        """Convert relevant ITCH Price(4) fields to whole cents in-place."""

        offset = PRICE_OFFSETS.get(msg_type)
        if offset is None:
            return

        if len(message) < offset + 4:
            raise ValueError(
                f"Message {msg_type!r} too short for price field at offset {offset}"
            )

        price_4 = int.from_bytes(message[offset : offset + 4], "big")
        price_cents = price_4 // 100
        message[offset : offset + 4] = price_cents.to_bytes(4, "big")

    @staticmethod
    def _u64(message: bytearray, offset: int) -> int:
        return int.from_bytes(message[offset : offset + 8], "big")

    @staticmethod
    def _u32(message: bytearray, offset: int) -> int:
        return int.from_bytes(message[offset : offset + 4], "big")

    @classmethod
    def _plan_order_book_event(
        cls,
        message: bytearray,
        msg_type: bytes,
        stock_id: int | None,
        active_orders: dict[int, dict[int, int]],
    ) -> tuple[bool, tuple | None]:
        """Predict whether this event produces one hardware BBO completion.

        The current V4 RTL can consume a tracked mutation without producing
        bbo_valid_o in two normal cases:

        1. symbol_router rejects A/F/U whose whole-cent price lies outside the
           configured 14-bit price window;
        2. ob_idx_search drops a non-add operation when its order reference is
           not present in either the hash table or CAM.

        The second case matters after an earlier out-of-window ADD was rejected:
        a later E/C/X/D for that Nasdaq order is still decoded and routed, but
        the order book intentionally terminates the pipeline on the lookup miss.

        active_orders is therefore a minimal mirror of order-reference
        existence and remaining shares.  It is *not* a software order book and
        is never used to generate BBO values.
        """

        if stock_id not in BASE_PRICE_CENTS or msg_type not in BOOK_MESSAGE_TYPES:
            return False, None

        orders = active_orders[stock_id]

        if msg_type in ROUTER_PRICE_FILTER_TYPES:
            offset = PRICE_OFFSETS[msg_type]
            price_cents = cls._u32(message, offset)
            base_price_cents = BASE_PRICE_CENTS[stock_id]
            in_bounds = (
                price_cents >= base_price_cents
                and (price_cents - base_price_cents) < (1 << BBO_W)
            )

            if not in_bounds:
                # For U the complete replace is rejected by symbol_router, so
                # the old hardware order remains exactly as it was.
                return False, None

            if msg_type in (b"A", b"F"):
                orn = cls._u64(message, ORDER_REF_OFFSET)
                shares = cls._u32(message, ADD_SHARES_OFFSET)
                return True, ("add", orn, shares)

            # A routed U is expanded by ob_replace_check into DELETE(old)
            # followed by ADD(new).  The DELETE half suppresses BBO output and
            # the ADD half produces the single externally visible completion,
            # even if the old order itself was not resident.
            old_orn = cls._u64(message, ORDER_REF_OFFSET)
            new_orn = cls._u64(message, NEW_ORDER_REF_OFFSET)
            shares = cls._u32(message, REPLACE_SHARES_OFFSET)
            return True, ("replace", old_orn, new_orn, shares)

        orn = cls._u64(message, ORDER_REF_OFFSET)

        # ob_idx_search deasserts stage_valid_o on a lookup miss for every
        # non-add operation, so there will be no bbo_valid_o pulse to wait for.
        if orn not in orders:
            return False, None

        if msg_type == b"D":
            return True, ("delete", orn)

        # E, C and X all carry the reduced share count at byte offset 19.
        if msg_type in (b"E", b"C", b"X"):
            shares = cls._u32(message, REDUCE_SHARES_OFFSET)
            return True, ("reduce", orn, shares)

        raise RuntimeError(f"Unhandled order-book message type: {msg_type!r}")

    @staticmethod
    def _commit_order_book_event(
        action: tuple | None,
        orders: dict[int, int],
    ) -> None:
        """Advance the order-reference mirror after hardware completion."""

        if action is None:
            return

        kind = action[0]

        if kind == "add":
            _, orn, shares = action
            orders[orn] = shares
            return

        if kind == "replace":
            _, old_orn, new_orn, shares = action
            orders.pop(old_orn, None)
            orders[new_orn] = shares
            return

        if kind == "delete":
            _, orn = action
            orders.pop(orn, None)
            return

        if kind == "reduce":
            _, orn, reduced_by = action
            remaining = orders[orn] - reduced_by
            if remaining <= 0:
                orders.pop(orn, None)
            else:
                orders[orn] = remaining
            return

        raise RuntimeError(f"Unhandled order mirror action: {kind!r}")

    def _read_bbo_counter(self) -> int:
        """Read the PL BBO-output counter exposed on meta GPIO channel 2."""

        return int(self.gpio_stock_id.channel2.read()) & 0xFFFF_FFFF

    def _capture_completed_bbo(self, previous_counter: int) -> tuple[int, int, int, int, int]:
        """Wait for exactly one order-book result and return a coherent snapshot.

        DMA completion only proves that the packet left the DMA.  The decoded
        event still has to cross the async FIFO, pass the router/order book and
        reach the round-robin BBO output.  The block design already contains a
        32-bit counter clock-enabled by bbo_valid_o, so wait for that counter
        instead.

        Once it increments, no next packet is submitted until this function
        returns.  Two identical counter-qualified snapshots therefore avoid
        combining fields from different BBO outputs.
        """

        deadline = time.monotonic() + BBO_WAIT_TIMEOUT_S
        completed_counter = None

        while time.monotonic() < deadline:
            current_counter = self._read_bbo_counter()
            delta = (current_counter - previous_counter) & 0xFFFF_FFFF

            if delta == 0:
                continue
            if delta != 1:
                raise RuntimeError(
                    "BBO output counter advanced by "
                    f"{delta} while waiting for one ITCH event "
                    f"({previous_counter:#010x} -> {current_counter:#010x})"
                )

            completed_counter = current_counter
            break

        if completed_counter is None:
            raise TimeoutError(
                "Timed out waiting for order-book completion after DMA transfer"
            )

        previous_snapshot = None
        while time.monotonic() < deadline:
            counter_before = self._read_bbo_counter()
            if counter_before != completed_counter:
                raise RuntimeError(
                    "BBO output advanced again before the previous result was captured"
                )

            snapshot = (
                int(self.gpio_stock_id.channel1.read()),
                int(self.gpio_bid.channel1.read()),
                int(self.gpio_bid.channel2.read()),
                int(self.gpio_ask.channel1.read()),
                int(self.gpio_ask.channel2.read()),
            )

            counter_after = self._read_bbo_counter()
            if counter_after != completed_counter:
                raise RuntimeError(
                    "BBO output changed while the GPIO snapshot was being read"
                )

            if snapshot == previous_snapshot:
                return snapshot

            previous_snapshot = snapshot

        raise TimeoutError("Timed out waiting for a stable BBO GPIO snapshot")

    def run(self) -> dict:
        """Run the deterministic replay and return a verification summary."""

        self._check_inputs()
        self._load_overlay()
        self._configure_base_prices()
        self.on_ready()

        locate_to_stock_id: dict[bytes, int] = {}

        last_bid_price = {1: 0, 2: 0, 3: 0}
        last_ask_price = {1: 0, 2: 0, 3: 0}
        last_bid_shares = {1: 0, 2: 0, 3: 0}
        last_ask_shares = {1: 0, 2: 0, 3: 0}

        # Minimal mirror of which Nasdaq order references actually made it into
        # each hardware order book.  Needed only for completion synchronisation.
        active_orders: dict[int, dict[int, int]] = {
            1: {},
            2: {},
            3: {},
        }

        source_messages = 0
        dma_packets = 0
        bbo_updates = 0

        # Hash the exact BinaryFILE record prefix used by this run. This binds
        # the hardware replay to the oracle without hashing the unused remainder
        # of the multi-gigabyte archive.
        workload_hash = hashlib.sha256()

        # The working notebook uses 256 x uint64, comfortably larger than the
        # synthetic packet produced from any supported ITCH message.
        send_buffer = allocate(shape=(256,), dtype=np.uint64)

        try:
            gz_file = gzip.open(self.data_path, "rb")
            with io.BufferedReader(gz_file, buffer_size=1024 * 1024) as data:
                while source_messages < self.message_limit:
                    length_header = data.read(2)
                    if not length_header:
                        break
                    if len(length_header) != 2:
                        raise EOFError("Truncated 2-byte ITCH message-length header")

                    ins_len = int.from_bytes(length_header, byteorder="big")
                    output_data = data.read(ins_len)
                    if len(output_data) != ins_len:
                        raise EOFError(
                            f"Truncated ITCH message: expected {ins_len} bytes, "
                            f"received {len(output_data)}"
                        )
                    if ins_len < 3:
                        raise ValueError(f"Invalid ITCH message length: {ins_len}")

                    workload_hash.update(length_header)
                    workload_hash.update(output_data)

                    source_messages += 1
                    msg_type = output_data[0:1]
                    locate_code = output_data[1:3]

                    # Discover the day's Nasdaq locate codes from Stock Directory.
                    if msg_type == b"R" and len(output_data) >= 19:
                        symbol = output_data[11:19].rstrip(b" ")
                        stock_id = TARGET_SYMBOLS.get(symbol)
                        if stock_id is not None:
                            locate_to_stock_id[locate_code] = stock_id
                            self.on_mapping(
                                symbol.decode("ascii"),
                                stock_id,
                                int.from_bytes(locate_code, "big"),
                            )

                    modified_msg = bytearray(output_data)
                    keep_message = False
                    stock_id = locate_to_stock_id.get(locate_code)

                    # Preserve the known-good notebook filtering/remapping flow.
                    if msg_type == b"S":
                        keep_message = True
                    elif stock_id is not None:
                        modified_msg[1:3] = stock_id.to_bytes(2, byteorder="big")
                        self._price_convert_for_hardware(modified_msg, msg_type)
                        keep_message = True

                    if keep_message:
                        network_headers = generate_network_headers(
                            payload_len=ins_len,
                            seq_num=source_messages,
                        )
                        full_packet = network_headers + modified_msg

                        # 64-bit DMA storage is padded to a whole word. The PL
                        # uses UDP length to delimit the real payload.
                        packet_len = len(full_packet)
                        storage_len = math.ceil(packet_len / 8) * 8
                        padded = full_packet.ljust(storage_len, b"\x00")

                        temp_arr = np.frombuffer(padded, dtype=np.uint64)
                        if len(temp_arr) > len(send_buffer):
                            raise RuntimeError(
                                f"Generated packet needs {len(temp_arr)} DMA words; "
                                f"buffer only has {len(send_buffer)}"
                            )

                        # Project ingress convention expects the earliest network
                        # byte in the MSB lane of each 64-bit word.
                        send_buffer[: len(temp_arr)] = temp_arr.byteswap()

                        # For supported order-book messages, take the current
                        # completion counter before launching the packet.  This
                        # gives us an explicit end-to-end completion token.
                        expect_bbo, order_action = self._plan_order_book_event(
                            modified_msg,
                            msg_type,
                            stock_id,
                            active_orders,
                        )
                        counter_before = (
                            self._read_bbo_counter() if expect_bbo else None
                        )

                        self.dma.sendchannel.transfer(
                            send_buffer[: len(temp_arr)],
                            nbytes=storage_len,
                        )
                        self.dma.sendchannel.wait()
                        dma_packets += 1

                        # This remains a deterministic correctness path, not a
                        # throughput benchmark.  Do not send the next supported
                        # event until the current order-book result is captured.
                        if expect_bbo:
                            try:
                                (
                                    hw_stock_id,
                                    bid_price,
                                    bid_shares,
                                    ask_price,
                                    ask_shares,
                                ) = self._capture_completed_bbo(counter_before)
                            except TimeoutError as exc:
                                orn = (
                                    self._u64(modified_msg, ORDER_REF_OFFSET)
                                    if len(modified_msg) >= ORDER_REF_OFFSET + 8
                                    else None
                                )
                                raise TimeoutError(
                                    f"{exc}; source_message={source_messages:,}, "
                                    f"type={msg_type.decode('ascii', errors='replace')!r}, "
                                    f"stock_id={stock_id}, order_ref={orn}, "
                                    f"counter_before={counter_before}"
                                ) from exc

                            self._commit_order_book_event(
                                order_action,
                                active_orders[stock_id],
                            )

                            if hw_stock_id not in last_bid_price:
                                raise RuntimeError(
                                    f"Unexpected hardware stock ID {hw_stock_id}"
                                )

                            changed = (
                                bid_price != last_bid_price[hw_stock_id]
                                or ask_price != last_ask_price[hw_stock_id]
                                or bid_shares != last_bid_shares[hw_stock_id]
                                or ask_shares != last_ask_shares[hw_stock_id]
                            )

                            if changed:
                                last_bid_price[hw_stock_id] = bid_price
                                last_ask_price[hw_stock_id] = ask_price
                                last_bid_shares[hw_stock_id] = bid_shares
                                last_ask_shares[hw_stock_id] = ask_shares
                                bbo_updates += 1

                                self.on_bbo(
                                    STOCK_NAMES[hw_stock_id],
                                    bid_price,
                                    bid_shares,
                                    ask_price,
                                    ask_shares,
                                )

                    if source_messages % 5_000 == 0:
                        self.on_progress(
                            source_messages,
                            self.message_limit,
                            dma_packets,
                        )

            self.on_progress(
                source_messages,
                self.message_limit,
                dma_packets,
            )

            missing = [
                symbol.decode("ascii")
                for symbol, stock_id in TARGET_SYMBOLS.items()
                if stock_id not in locate_to_stock_id.values()
            ]
            if missing:
                raise RuntimeError(
                    "Did not discover Stock Directory entries for: "
                    + ", ".join(missing)
                )

            if source_messages != self.message_limit:
                raise RuntimeError(
                    f"Dataset ended after {source_messages:,} source messages; "
                    f"oracle expects {self.message_limit:,}"
                )

            return {
                "source_messages": source_messages,
                "dma_packets": dma_packets,
                "bbo_updates": bbo_updates,
                "mapped_stocks": len(locate_to_stock_id),
                "workload_sha256": workload_hash.hexdigest(),
            }

        finally:
            try:
                send_buffer.freebuffer()
            except Exception:
                pass
