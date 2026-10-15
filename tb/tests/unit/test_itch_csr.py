"""AXI4-Lite register and snapshot tests for itch_csr.v"""

from __future__ import annotations

import os
import random
from typing import Any

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge


ID = 0x0000
VERSION = 0x0004
BASE_ADDRESSES = (0x0010, 0x0014, 0x0018)
BBO_COUNT = 0x0020
BBO_STOCK = 0x0024
BBO_BID_PRICE = 0x0028
BBO_BID_SHARES = 0x002C
BBO_ASK_PRICE = 0x0030
BBO_ASK_SHARES = 0x0034
CAM_STATUS = 0x0038
RESET_STATUS = 0x003C

OKAY = 0
SLVERR = 2
TIMEOUT_CYCLES = 40
TEST_SEED = int(os.environ.get("TEST_SEED", "7"), 0)


async def tick(dut: Any, **values: int) -> dict[str, int]:
    """Drive inputs before the edge and sample AXI handshakes before that edge."""

    await FallingEdge(dut.s_axi_aclk)

    # These are one-cycle requests, not levels that should leak to later calls.
    for name in (
        "s_axi_awvalid", "s_axi_wvalid", "s_axi_bready",
        "s_axi_arvalid", "s_axi_rready",
    ):
        getattr(dut, name).value = values.get(name, 0)

    for name, value in values.items():
        getattr(dut, name).value = value

    await ReadOnly()
    sampled = {
        name: int(getattr(dut, name).value)
        for name in (
            "s_axi_awready", "s_axi_wready", "s_axi_bvalid", "s_axi_bresp",
            "s_axi_arready", "s_axi_rvalid", "s_axi_rdata", "s_axi_rresp",
        )
    }
    await RisingEdge(dut.s_axi_aclk)
    return sampled


async def initialise(dut: Any) -> None:
    """Start the AXI clock, drive all inputs, then apply synchronous reset."""

    dut.s_axi_aresetn.value = 0
    for name in (
        "s_axi_awaddr", "s_axi_awprot", "s_axi_awvalid", "s_axi_wdata",
        "s_axi_wstrb", "s_axi_wvalid", "s_axi_bready", "s_axi_araddr",
        "s_axi_arprot", "s_axi_arvalid", "s_axi_rready", "bbo_data_i",
        "bbo_valid_i", "bbo_count_i", "cam_status_i", "reset_status_i",
    ):
        getattr(dut, name).value = 0

    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, unit="ns").start())
    for _ in range(5):
        await RisingEdge(dut.s_axi_aclk)
    await tick(dut, s_axi_aresetn=1)


def pack_bbo(stock: int, bid_price: int, bid_shares: int,
             ask_price: int, ask_shares: int) -> int:
    """The external, documented 130-bit order-book result format."""

    return (
        (stock << 128)
        | (bid_price << 96)
        | (bid_shares << 64)
        | (ask_price << 32)
        | ask_shares
    )


async def send_aw(dut: Any, address: int) -> None:
    for _ in range(TIMEOUT_CYCLES):
        seen = await tick(dut, s_axi_awvalid=1, s_axi_awaddr=address)
        if seen["s_axi_awready"]:
            return
    raise TimeoutError(f"CSR AW handshake timed out: address={address:#06x}")


async def send_w(dut: Any, data: int, strobe: int) -> None:
    for _ in range(TIMEOUT_CYCLES):
        seen = await tick(
            dut, s_axi_wvalid=1, s_axi_wdata=data, s_axi_wstrb=strobe
        )
        if seen["s_axi_wready"]:
            return
    raise TimeoutError(f"CSR W handshake timed out: data={data:#010x}")


async def wait_b_response(dut: Any, *, context: str) -> dict[str, int]:
    """Wait for a write response without assuming a fixed pipeline latency."""

    for _ in range(TIMEOUT_CYCLES):
        seen = await tick(dut)
        if seen["s_axi_bvalid"]:
            return seen
    raise TimeoutError(f"CSR B response timed out: {context}")


async def write(dut: Any, address: int, data: int, *, strobe: int = 0xF,
                order: str = "together", stall_cycles: int = 0) -> int:
    """Complete one write with independent AW/W channels and a B response."""

    if order == "aw_first":
        await send_aw(dut, address)
        await tick(dut)
        await send_w(dut, data, strobe)
    elif order == "w_first":
        await send_w(dut, data, strobe)
        await tick(dut)
        await send_aw(dut, address)
    elif order == "together":
        for _ in range(TIMEOUT_CYCLES):
            seen = await tick(
                dut, s_axi_awvalid=1, s_axi_awaddr=address,
                s_axi_wvalid=1, s_axi_wdata=data, s_axi_wstrb=strobe,
            )
            if seen["s_axi_awready"] and seen["s_axi_wready"]:
                break
        else:
            raise TimeoutError(f"CSR simultaneous AW/W timed out: {address:#06x}")
    else:
        raise ValueError(f"unknown AXI write ordering: {order}")

    seen = await wait_b_response(dut, context=f"address={address:#06x}")

    resp = seen["s_axi_bresp"]
    for _ in range(stall_cycles):
        held = await tick(dut)
        assert held["s_axi_bvalid"] == 1, "BVALID dropped before BREADY"
        assert held["s_axi_bresp"] == resp, "BRESP changed under backpressure"
        assert held["s_axi_awready"] == 0 and held["s_axi_wready"] == 0, (
            "CSR accepted another write while its B response was pending"
        )

    accepted = await tick(dut, s_axi_bready=1)
    assert accepted["s_axi_bvalid"] == 1
    assert accepted["s_axi_bresp"] == resp
    assert (await tick(dut))["s_axi_bvalid"] == 0, "duplicate B response"
    return resp


async def read(dut: Any, address: int, *, stall_cycles: int = 0) -> tuple[int, int]:
    """Read one word, including optional response-channel backpressure."""

    for _ in range(TIMEOUT_CYCLES):
        seen = await tick(dut, s_axi_arvalid=1, s_axi_araddr=address)
        if seen["s_axi_arready"]:
            break
    else:
        raise TimeoutError(f"CSR AR handshake timed out: address={address:#06x}")

    for _ in range(TIMEOUT_CYCLES):
        seen = await tick(dut)
        if seen["s_axi_rvalid"]:
            break
    else:
        raise TimeoutError(f"CSR R response timed out: address={address:#06x}")

    result = seen["s_axi_rdata"], seen["s_axi_rresp"]
    for _ in range(stall_cycles):
        held = await tick(dut, s_axi_arvalid=1, s_axi_araddr=0x0000)
        assert held["s_axi_rvalid"] == 1, "RVALID dropped before RREADY"
        assert (held["s_axi_rdata"], held["s_axi_rresp"]) == result, (
            f"R response changed while stalled: address={address:#06x}"
        )
        assert held["s_axi_arready"] == 0, "ARREADY high with pending R response"

    accepted = await tick(dut, s_axi_rready=1)
    assert accepted["s_axi_rvalid"] == 1
    assert (accepted["s_axi_rdata"], accepted["s_axi_rresp"]) == result
    assert (await tick(dut))["s_axi_rvalid"] == 0, "duplicate R response"
    return result


async def check_read(dut: Any, address: int, expected: int,
                     resp: int = OKAY) -> None:
    data, actual_resp = await read(dut, address)
    assert (data, actual_resp) == (expected, resp), (
        f"CSR read {address:#06x}: got ({data:#010x}, {actual_resp}), "
        f"expected ({expected:#010x}, {resp})"
    )


@cocotb.test()
async def test_itch_csr_reset_and_register_map(dut: Any) -> None:
    """Read-only identification, reset defaults and illegal address responses."""

    await initialise(dut)
    await check_read(dut, ID, 0x49544348)
    await check_read(dut, VERSION, 0x00050001)
    for address in (*BASE_ADDRESSES, BBO_COUNT, BBO_STOCK, BBO_BID_PRICE,
                    BBO_BID_SHARES, BBO_ASK_PRICE, BBO_ASK_SHARES,
                    CAM_STATUS, RESET_STATUS):
        await check_read(dut, address, 0)

    for address in (0x0008, 0x000C, 0x0011, 0x001C, 0x0040, 0xFFFC):
        await check_read(dut, address, 0, SLVERR)

    for address in (ID, VERSION, BBO_COUNT, BBO_BID_PRICE, CAM_STATUS,
                    RESET_STATUS, 0x0008, 0xFFFC):
        assert await write(dut, address, 0xFFFFFFFF) == SLVERR, (
            f"write to read-only/unmapped CSR {address:#06x} was accepted"
        )
    await check_read(dut, ID, 0x49544348)
    await check_read(dut, VERSION, 0x00050001)


@cocotb.test()
async def test_itch_csr_base_price_writes_and_byte_strobes(dut: Any) -> None:
    """All three base prices support AW/W ordering and byte-lane updates."""

    await initialise(dut)
    for address, data, order in zip(
        BASE_ADDRESSES,
        (0x01234567, 0x89ABCDEF, 0xFEDCBA98),
        ("together", "aw_first", "w_first"),
    ):
        assert await write(dut, address, data, order=order) == OKAY
        await check_read(dut, address, data)

    value = 0x01234567
    for strobe, data in (
        (0x1, 0x000000AB), (0x2, 0x0000CD00),
        (0x4, 0x00EF0000), (0x8, 0x99000000),
        (0x0, 0xFFFFFFFF), (0x5, 0x44005566),
    ):
        mask = sum(0xFF << (8 * lane) for lane in range(4) if strobe & (1 << lane))
        value = (value & ~mask) | (data & mask)
        assert await write(dut, BASE_ADDRESSES[0], data, strobe=strobe) == OKAY
        await check_read(dut, BASE_ADDRESSES[0], value)

    # All 16 byte-strobe masks are small enough to cover exhaustively.
    for strobe in range(16):
        data = 0xA5C39678 ^ (strobe * 0x01020408)
        mask = sum(0xFF << (8 * lane) for lane in range(4) if strobe & (1 << lane))
        value = (value & ~mask) | (data & mask)
        assert await write(dut, BASE_ADDRESSES[0], data, strobe=strobe) == OKAY
        await check_read(dut, BASE_ADDRESSES[0], value)

    assert int(dut.base_price_stock0_o.value) == value
    assert int(dut.base_price_stock1_o.value) == 0x89ABCDEF
    assert int(dut.base_price_stock2_o.value) == 0xFEDCBA98


@cocotb.test()
async def test_itch_csr_write_and_read_backpressure(dut: Any) -> None:
    """Held B/R responses stay stable and block a second transaction."""

    await initialise(dut)
    address = BASE_ADDRESSES[0]
    assert await write(dut, address, 0x13579BDF, stall_cycles=7) == OKAY
    assert await read(dut, address, stall_cycles=7) == (0x13579BDF, OKAY)

    # AW without W must not perform a write or raise BVALID.
    await send_aw(dut, BASE_ADDRESSES[1])
    for _ in range(4):
        seen = await tick(dut, s_axi_awvalid=1, s_axi_awaddr=BASE_ADDRESSES[2])
        assert seen["s_axi_awready"] == 0
        assert seen["s_axi_wready"] == 1
        assert seen["s_axi_bvalid"] == 0
    await send_w(dut, 0x2468ACE0, 0xF)
    seen = await wait_b_response(dut, context="address/data completed")
    assert seen["s_axi_bresp"] == OKAY
    for _ in range(3):
        held = await tick(
            dut, s_axi_awvalid=1, s_axi_awaddr=BASE_ADDRESSES[2],
            s_axi_wvalid=1, s_axi_wdata=0xDEADBEEF, s_axi_wstrb=0xF,
        )
        assert held["s_axi_bvalid"] == 1
        assert held["s_axi_awready"] == 0 and held["s_axi_wready"] == 0
    await tick(dut, s_axi_bready=1)
    assert (await tick(dut))["s_axi_bvalid"] == 0
    await check_read(dut, BASE_ADDRESSES[1], 0x2468ACE0)
    await check_read(dut, BASE_ADDRESSES[2], 0)


@cocotb.test()
async def test_itch_csr_read_while_write_is_waiting_for_data(dut: Any) -> None:
    """AR/R are independent of an incomplete AW/W write pair."""

    await initialise(dut)
    await send_aw(dut, BASE_ADDRESSES[0])
    await check_read(dut, ID, 0x49544348)
    await check_read(dut, BASE_ADDRESSES[0], 0)
    assert (await tick(dut))["s_axi_bvalid"] == 0

    await send_w(dut, 0x55667788, 0xF)
    seen = await wait_b_response(dut, context="address/data completed")
    assert seen["s_axi_bresp"] == OKAY
    await check_read(dut, BASE_ADDRESSES[0], 0x55667788)
    seen = await tick(dut, s_axi_bready=1)
    assert seen["s_axi_bvalid"] == 1
    assert (await tick(dut))["s_axi_bvalid"] == 0


@cocotb.test()
async def test_itch_csr_bbo_snapshot_and_live_status(dut: Any) -> None:
    """BBO fields only latch on valid; live status reads are not snapshotted."""

    await initialise(dut)
    first = (3, 0x89ABCDEF, 0x12345678, 0xFEDCBA98, 0x76543210)
    second = (1, 111, 222, 333, 444)

    await tick(dut, bbo_data_i=pack_bbo(*first), bbo_valid_i=0)
    await check_read(dut, BBO_STOCK, 0)
    await tick(dut, bbo_valid_i=1)
    await tick(dut, bbo_valid_i=0, bbo_data_i=pack_bbo(*second))

    for address, expected in zip(
        (BBO_STOCK, BBO_BID_PRICE, BBO_BID_SHARES, BBO_ASK_PRICE, BBO_ASK_SHARES),
        first,
    ):
        await check_read(dut, address, expected)

    await tick(dut, bbo_count_i=0xDEADBEEF, cam_status_i=0b101,
               reset_status_i=0x80000001)
    await check_read(dut, BBO_COUNT, 0xDEADBEEF)
    await check_read(dut, CAM_STATUS, 0b101)
    await check_read(dut, RESET_STATUS, 0x80000001)

    await tick(dut, bbo_valid_i=1, bbo_data_i=pack_bbo(*second))
    await tick(dut, bbo_valid_i=0, bbo_count_i=17, cam_status_i=0b010,
               reset_status_i=3)
    for address, expected in zip(
        (BBO_STOCK, BBO_BID_PRICE, BBO_BID_SHARES, BBO_ASK_PRICE, BBO_ASK_SHARES),
        second,
    ):
        await check_read(dut, address, expected)
    await check_read(dut, BBO_COUNT, 17)
    await check_read(dut, CAM_STATUS, 0b010)
    await check_read(dut, RESET_STATUS, 3)

    # A pending AXI read retains the value captured at AR acceptance.
    seen = await tick(dut, s_axi_arvalid=1, s_axi_araddr=BBO_BID_PRICE)
    assert seen["s_axi_arready"] == 1
    await tick(dut, bbo_valid_i=1, bbo_data_i=pack_bbo(*first))
    seen = await tick(dut, bbo_valid_i=0)
    assert seen["s_axi_rvalid"] == 1
    assert (seen["s_axi_rdata"], seen["s_axi_rresp"]) == (second[1], OKAY)
    await tick(dut, s_axi_rready=1)
    await check_read(dut, BBO_BID_PRICE, first[1])


@cocotb.test()
async def test_itch_csr_reset_aborts_pending_transactions(dut: Any) -> None:
    """Reset clears writable state, snapshot and half-completed AXI writes."""

    await initialise(dut)
    assert await write(dut, BASE_ADDRESSES[0], 0x12345678) == OKAY
    await tick(dut, bbo_data_i=pack_bbo(2, 1, 2, 3, 4), bbo_valid_i=1)
    await tick(dut, bbo_valid_i=0)
    await send_aw(dut, BASE_ADDRESSES[1])
    await tick(dut, s_axi_aresetn=0)
    seen = await tick(dut, s_axi_aresetn=1)
    assert seen["s_axi_bvalid"] == 0 and seen["s_axi_rvalid"] == 0
    await send_w(dut, 0xCAFEBABE, 0xF)
    for _ in range(5):
        assert (await tick(dut))["s_axi_bvalid"] == 0, (
            "write data paired with an address from before reset"
        )
    # The W-only half-write must also be discarded by reset.
    await tick(dut, s_axi_aresetn=0)
    await tick(dut, s_axi_aresetn=1)

    for address in BASE_ADDRESSES:
        await check_read(dut, address, 0)
    for address in (BBO_STOCK, BBO_BID_PRICE, BBO_BID_SHARES,
                    BBO_ASK_PRICE, BBO_ASK_SHARES):
        await check_read(dut, address, 0)
    assert await write(dut, BASE_ADDRESSES[2], 0xBEEF) == OKAY
    await check_read(dut, BASE_ADDRESSES[2], 0xBEEF)

    # B and R response-valid flags must clear even with the sinks stalled.
    await send_aw(dut, BASE_ADDRESSES[1])
    await send_w(dut, 0xAABBCCDD, 0xF)
    seen = await wait_b_response(dut, context="reset with stalled responses")
    assert seen["s_axi_bresp"] == OKAY
    assert (await tick(dut, s_axi_arvalid=1, s_axi_araddr=ID))["s_axi_arready"] == 1
    seen = await tick(dut)
    assert seen["s_axi_bvalid"] == 1 and seen["s_axi_rvalid"] == 1
    await tick(dut, s_axi_aresetn=0)
    seen = await tick(dut, s_axi_aresetn=1)
    assert seen["s_axi_bvalid"] == 0 and seen["s_axi_rvalid"] == 0
    await check_read(dut, BASE_ADDRESSES[1], 0)


@cocotb.test()
async def test_itch_csr_deterministic_byte_write_campaign(dut: Any) -> None:
    """Replayable mixed address/data ordering and strobe combinations."""

    await initialise(dut)
    dut._log.info("CSR TEST_SEED=%d", TEST_SEED)
    rng = random.Random(TEST_SEED)
    expected = {address: 0 for address in BASE_ADDRESSES}
    for index in range(72):
        address = rng.choice(BASE_ADDRESSES)
        data = rng.getrandbits(32)
        strobe = rng.randrange(16)
        order = rng.choice(("together", "aw_first", "w_first"))
        mask = sum(0xFF << (8 * lane) for lane in range(4) if strobe & (1 << lane))
        expected[address] = (expected[address] & ~mask) | (data & mask)
        resp = await write(dut, address, data, strobe=strobe, order=order,
                           stall_cycles=rng.randrange(4))
        assert resp == OKAY, f"seed={TEST_SEED} write={index} unexpected BRESP={resp}"
        observed, rresp = await read(dut, address, stall_cycles=rng.randrange(4))
        assert (observed, rresp) == (expected[address], OKAY), (
            f"seed={TEST_SEED} write={index} address={address:#06x} "
            f"strobe={strobe:#x} order={order}: "
            f"observed={observed:#010x}, expected={expected[address]:#010x}"
        )

    for address, value in expected.items():
        await check_read(dut, address, value)
