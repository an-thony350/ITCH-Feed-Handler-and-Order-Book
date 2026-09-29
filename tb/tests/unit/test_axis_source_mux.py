"""Directed cocotb regression for axis_source_mux.sv.

This isolates the static DMA/Taxi source selection before frame_crack.

Covered:
- DMA selected;
- Taxi selected;
- inactive source cannot leak valid/data;
- downstream backpressure reaches only the selected source;
- tdata/tkeep/tvalid/tlast selection;
- source selection while idle.
"""

from __future__ import annotations

from typing import Any

import cocotb
from cocotb.triggers import Timer


async def settle() -> None:
    """Allow combinational assignments to settle."""

    await Timer(1, unit="ns")


def drive_dma(
    dut: Any,
    *,
    data: int,
    keep: int,
    valid: int,
    last: int,
) -> None:
    """Drive the DMA-side AXIS source."""

    dut.dma_tdata_i.value = data
    dut.dma_tkeep_i.value = keep
    dut.dma_tvalid_i.value = valid
    dut.dma_tlast_i.value = last


def drive_taxi(
    dut: Any,
    *,
    data: int,
    keep: int,
    valid: int,
    last: int,
) -> None:
    """Drive the Taxi-side AXIS source."""

    dut.taxi_tdata_i.value = data
    dut.taxi_tkeep_i.value = keep
    dut.taxi_tvalid_i.value = valid
    dut.taxi_tlast_i.value = last


@cocotb.test()
async def test_axis_source_mux_dma_selected(dut: Any) -> None:
    """DMA fields drive the output and Taxi is held not-ready."""

    drive_dma(
        dut,
        data=0x0011223344556677,
        keep=0xF8,
        valid=1,
        last=1,
    )
    drive_taxi(
        dut,
        data=0x8899AABBCCDDEEFF,
        keep=0x0F,
        valid=1,
        last=0,
    )

    dut.select_taxi_i.value = 0
    dut.m_tready_i.value = 1

    await settle()

    assert int(dut.m_tdata_o.value) == 0x0011223344556677
    assert int(dut.m_tkeep_o.value) == 0xF8
    assert int(dut.m_tvalid_o.value) == 1
    assert int(dut.m_tlast_o.value) == 1
    assert int(dut.dma_tready_o.value) == 1
    assert int(dut.taxi_tready_o.value) == 0


@cocotb.test()
async def test_axis_source_mux_taxi_selected(dut: Any) -> None:
    """Taxi fields drive the output and DMA is held not-ready."""

    drive_dma(
        dut,
        data=0x0011223344556677,
        keep=0xF8,
        valid=1,
        last=1,
    )
    drive_taxi(
        dut,
        data=0x8899AABBCCDDEEFF,
        keep=0x0F,
        valid=1,
        last=0,
    )

    dut.select_taxi_i.value = 1
    dut.m_tready_i.value = 1

    await settle()

    assert int(dut.m_tdata_o.value) == 0x8899AABBCCDDEEFF
    assert int(dut.m_tkeep_o.value) == 0x0F
    assert int(dut.m_tvalid_o.value) == 1
    assert int(dut.m_tlast_o.value) == 0
    assert int(dut.dma_tready_o.value) == 0
    assert int(dut.taxi_tready_o.value) == 1


@cocotb.test()
async def test_axis_source_mux_inactive_valid_does_not_leak(dut: Any) -> None:
    """An asserting inactive source cannot make the output valid."""

    drive_dma(
        dut,
        data=0x1111111111111111,
        keep=0xFF,
        valid=0,
        last=0,
    )
    drive_taxi(
        dut,
        data=0x2222222222222222,
        keep=0xFF,
        valid=1,
        last=1,
    )

    dut.select_taxi_i.value = 0
    dut.m_tready_i.value = 1

    await settle()

    assert int(dut.m_tvalid_o.value) == 0
    assert int(dut.dma_tready_o.value) == 1
    assert int(dut.taxi_tready_o.value) == 0

    drive_dma(
        dut,
        data=0x1111111111111111,
        keep=0xFF,
        valid=1,
        last=1,
    )
    drive_taxi(
        dut,
        data=0x2222222222222222,
        keep=0xFF,
        valid=0,
        last=0,
    )

    dut.select_taxi_i.value = 1

    await settle()

    assert int(dut.m_tvalid_o.value) == 0
    assert int(dut.dma_tready_o.value) == 0
    assert int(dut.taxi_tready_o.value) == 1


@cocotb.test()
async def test_axis_source_mux_backpressure(dut: Any) -> None:
    """Backpressure is returned only to the selected source."""

    drive_dma(
        dut,
        data=0,
        keep=0xFF,
        valid=1,
        last=0,
    )
    drive_taxi(
        dut,
        data=0,
        keep=0xFF,
        valid=1,
        last=0,
    )

    dut.m_tready_i.value = 0

    dut.select_taxi_i.value = 0
    await settle()

    assert int(dut.dma_tready_o.value) == 0
    assert int(dut.taxi_tready_o.value) == 0

    dut.m_tready_i.value = 1
    await settle()

    assert int(dut.dma_tready_o.value) == 1
    assert int(dut.taxi_tready_o.value) == 0

    dut.m_tready_i.value = 0
    dut.select_taxi_i.value = 1
    await settle()

    assert int(dut.dma_tready_o.value) == 0
    assert int(dut.taxi_tready_o.value) == 0

    dut.m_tready_i.value = 1
    await settle()

    assert int(dut.dma_tready_o.value) == 0
    assert int(dut.taxi_tready_o.value) == 1


@cocotb.test()
async def test_axis_source_mux_idle_source_selection(dut: Any) -> None:
    """Selection may be changed safely while both sources are idle."""

    drive_dma(
        dut,
        data=0x0123456789ABCDEF,
        keep=0xAA,
        valid=0,
        last=1,
    )
    drive_taxi(
        dut,
        data=0xFEDCBA9876543210,
        keep=0x55,
        valid=0,
        last=0,
    )
    dut.m_tready_i.value = 1

    dut.select_taxi_i.value = 0
    await settle()

    assert int(dut.m_tdata_o.value) == 0x0123456789ABCDEF
    assert int(dut.m_tkeep_o.value) == 0xAA
    assert int(dut.m_tvalid_o.value) == 0
    assert int(dut.m_tlast_o.value) == 1

    dut.select_taxi_i.value = 1
    await settle()

    assert int(dut.m_tdata_o.value) == 0xFEDCBA9876543210
    assert int(dut.m_tkeep_o.value) == 0x55
    assert int(dut.m_tvalid_o.value) == 0
    assert int(dut.m_tlast_o.value) == 0
