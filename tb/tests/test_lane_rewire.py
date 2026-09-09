"""Directed cocotb regression for lane_rewire.sv.

This isolates the Taxi-to-project byte-lane conversion before the source mux
and feed-handler ingress are involved.

Covered:
- all eight byte lanes;
- all legal final-beat tkeep patterns;
- arbitrary tkeep bit reversal;
- tvalid/tlast pass-through;
- tready pass-through.
"""

from __future__ import annotations

from typing import Any

import cocotb
from cocotb.triggers import Timer


def reverse_bytes_64(value: int) -> int:
    """Reverse the eight byte lanes of a 64-bit value."""

    result = 0
    for lane in range(8):
        byte = (value >> (8 * lane)) & 0xFF
        result |= byte << (8 * (7 - lane))
    return result


def reverse_bits_8(value: int) -> int:
    """Reverse the eight lane-valid bits in tkeep."""

    result = 0
    for lane in range(8):
        bit = (value >> lane) & 0x1
        result |= bit << (7 - lane)
    return result


async def settle() -> None:
    """Allow combinational assignments to settle."""

    await Timer(1, unit="ns")


@cocotb.test()
async def test_lane_rewire_data_mapping(dut: Any) -> None:
    """Taxi low-byte-first data is rewired to project high-byte-first data."""

    dut.s_tdata_i.value = 0x0706050403020100
    dut.s_tkeep_i.value = 0xFF
    dut.s_tvalid_i.value = 1
    dut.s_tlast_i.value = 0
    dut.m_tready_i.value = 1

    await settle()

    assert int(dut.m_tdata_o.value) == 0x0001020304050607
    assert int(dut.m_tkeep_o.value) == 0xFF
    assert int(dut.m_tvalid_o.value) == 1
    assert int(dut.m_tlast_o.value) == 0
    assert int(dut.s_tready_o.value) == 1

    # Use a non-symmetric pattern so every byte-lane mapping is checked.
    value = 0xD7C6B5A493827160
    dut.s_tdata_i.value = value

    await settle()

    assert int(dut.m_tdata_o.value) == reverse_bytes_64(value)


@cocotb.test()
async def test_lane_rewire_legal_tkeep_patterns(dut: Any) -> None:
    """Every legal Taxi final tkeep becomes the project MSB-contiguous form."""

    dut.s_tdata_i.value = 0
    dut.s_tvalid_i.value = 1
    dut.s_tlast_i.value = 1
    dut.m_tready_i.value = 1

    for valid_bytes in range(1, 9):
        taxi_keep = (1 << valid_bytes) - 1
        project_keep = ((1 << valid_bytes) - 1) << (8 - valid_bytes)

        dut.s_tkeep_i.value = taxi_keep
        await settle()

        assert int(dut.m_tkeep_o.value) == project_keep


@cocotb.test()
async def test_lane_rewire_arbitrary_tkeep_mapping(dut: Any) -> None:
    """The module is a pure bit reversal even for non-canonical tkeep values."""

    dut.s_tdata_i.value = 0
    dut.s_tvalid_i.value = 0
    dut.s_tlast_i.value = 0
    dut.m_tready_i.value = 0

    for keep in range(256):
        dut.s_tkeep_i.value = keep
        await settle()

        assert int(dut.m_tkeep_o.value) == reverse_bits_8(keep)


@cocotb.test()
async def test_lane_rewire_handshake_passthrough(dut: Any) -> None:
    """The lane conversion does not alter AXIS control or handshake state."""

    dut.s_tdata_i.value = 0
    dut.s_tkeep_i.value = 0xFF

    for valid in (0, 1):
        for last in (0, 1):
            for ready in (0, 1):
                dut.s_tvalid_i.value = valid
                dut.s_tlast_i.value = last
                dut.m_tready_i.value = ready

                await settle()

                assert int(dut.m_tvalid_o.value) == valid
                assert int(dut.m_tlast_o.value) == last
                assert int(dut.s_tready_o.value) == ready
