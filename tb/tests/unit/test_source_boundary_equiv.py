"""Source-boundary equivalence regression for DMA and Taxi ingress.

The production blocks are tested together exactly as they will sit before
frame_crack:

    DMA ----------------------+
                              +--> axis_source_mux --> common AXIS
    Taxi --> lane_rewire -----+

The test proves that the same Ethernet-frame bytes presented in each source's
native lane convention produce byte-identical common AXIS beats.

Covered:
- every possible legal final tkeep width (1..8 bytes);
- beat-for-beat DMA/Taxi output equivalence;
- Taxi raw low-byte-first to project high-byte-first conversion;
- inactive-source isolation while both sources assert valid;
- downstream backpressure through both complete source paths.
"""

from __future__ import annotations

from typing import Any

import cocotb
from cocotb.triggers import Timer


WORD_BYTES = 8


async def settle() -> None:
    """Allow combinational source-boundary logic to settle."""

    await Timer(1, unit="ns")


def make_ethernet_like_frame(length: int) -> bytes:
    """Build a deterministic Ethernet-II-like frame without preamble/FCS."""

    if length < 14:
        raise ValueError("frame length must include the 14-byte Ethernet header")

    dst = bytes.fromhex("001122334455")
    src = bytes.fromhex("66778899aabb")
    ethertype = bytes.fromhex("0800")
    payload_len = length - 14
    payload = bytes(((index * 37) + 11) & 0xFF for index in range(payload_len))

    return dst + src + ethertype + payload


def project_words(frame: bytes) -> list[tuple[int, int, int]]:
    """Pack bytes using the project's MSB-first lane convention."""

    words: list[tuple[int, int, int]] = []

    for offset in range(0, len(frame), WORD_BYTES):
        chunk = frame[offset : offset + WORD_BYTES]
        valid_bytes = len(chunk)

        data = int.from_bytes(
            chunk.ljust(WORD_BYTES, b"\x00"),
            byteorder="big",
        )
        keep = ((1 << valid_bytes) - 1) << (WORD_BYTES - valid_bytes)
        last = int(offset + WORD_BYTES >= len(frame))

        words.append((data, keep, last))

    return words


def taxi_words(frame: bytes) -> list[tuple[int, int, int]]:
    """Pack bytes using Taxi's low-byte-first AXIS lane convention."""

    words: list[tuple[int, int, int]] = []

    for offset in range(0, len(frame), WORD_BYTES):
        chunk = frame[offset : offset + WORD_BYTES]
        valid_bytes = len(chunk)

        data = int.from_bytes(
            chunk.ljust(WORD_BYTES, b"\x00"),
            byteorder="little",
        )
        keep = (1 << valid_bytes) - 1
        last = int(offset + WORD_BYTES >= len(frame))

        words.append((data, keep, last))

    return words


def poison_dma(dut: Any) -> None:
    """Assert deliberately different traffic on the inactive DMA source."""

    dut.dma_tdata_i.value = 0xDEADBEEF01234567
    dut.dma_tkeep_i.value = 0xA5
    dut.dma_tvalid_i.value = 1
    dut.dma_tlast_i.value = 0


def poison_taxi(dut: Any) -> None:
    """Assert deliberately different traffic on the inactive Taxi source."""

    dut.taxi_tdata_i.value = 0x89ABCDEFCAFEBABE
    dut.taxi_tkeep_i.value = 0x5A
    dut.taxi_tvalid_i.value = 1
    dut.taxi_tlast_i.value = 0


def common_output(dut: Any) -> tuple[int, int, int, int]:
    """Return one fully-settled common AXIS beat."""

    return (
        int(dut.m_tdata_o.value),
        int(dut.m_tkeep_o.value),
        int(dut.m_tvalid_o.value),
        int(dut.m_tlast_o.value),
    )


async def observe_dma_frame(
    dut: Any,
    frame: bytes,
) -> list[tuple[int, int, int, int]]:
    """Present one frame on DMA while Taxi asserts unrelated valid traffic."""

    dut.select_taxi_i.value = 0
    dut.m_tready_i.value = 1

    observed: list[tuple[int, int, int, int]] = []

    for data, keep, last in project_words(frame):
        dut.dma_tdata_i.value = data
        dut.dma_tkeep_i.value = keep
        dut.dma_tvalid_i.value = 1
        dut.dma_tlast_i.value = last
        poison_taxi(dut)

        await settle()

        assert int(dut.dma_tready_o.value) == 1
        assert int(dut.taxi_tready_o.value) == 0

        observed.append(common_output(dut))

    return observed


async def observe_taxi_frame(
    dut: Any,
    frame: bytes,
) -> list[tuple[int, int, int, int]]:
    """Present the same frame in raw Taxi order while DMA asserts valid."""

    dut.select_taxi_i.value = 1
    dut.m_tready_i.value = 1

    observed: list[tuple[int, int, int, int]] = []

    for data, keep, last in taxi_words(frame):
        poison_dma(dut)
        dut.taxi_tdata_i.value = data
        dut.taxi_tkeep_i.value = keep
        dut.taxi_tvalid_i.value = 1
        dut.taxi_tlast_i.value = last

        await settle()

        assert int(dut.dma_tready_o.value) == 0
        assert int(dut.taxi_tready_o.value) == 1

        observed.append(common_output(dut))

    return observed


@cocotb.test()
async def test_source_boundary_frame_equivalence_all_final_keeps(
    dut: Any,
) -> None:
    """DMA and Taxi produce identical common beats for final keeps 1..8."""

    # 65..72 bytes gives final valid-byte counts 1..8 respectively.
    for frame_length in range(65, 73):
        frame = make_ethernet_like_frame(frame_length)

        expected = [
            (data, keep, 1, last)
            for data, keep, last in project_words(frame)
        ]

        dma_observed = await observe_dma_frame(dut, frame)
        taxi_observed = await observe_taxi_frame(dut, frame)

        assert dma_observed == expected, (
            f"DMA output mismatch for frame length {frame_length}"
        )
        assert taxi_observed == expected, (
            f"Taxi output mismatch for frame length {frame_length}"
        )
        assert taxi_observed == dma_observed, (
            f"source-boundary mismatch for frame length {frame_length}"
        )


@cocotb.test()
async def test_source_boundary_backpressure_dma_path(dut: Any) -> None:
    """Common backpressure reaches DMA only when DMA is selected."""

    frame = make_ethernet_like_frame(69)
    data, keep, last = project_words(frame)[0]

    dut.select_taxi_i.value = 0
    dut.dma_tdata_i.value = data
    dut.dma_tkeep_i.value = keep
    dut.dma_tvalid_i.value = 1
    dut.dma_tlast_i.value = last
    poison_taxi(dut)

    dut.m_tready_i.value = 0
    await settle()

    stalled_output = common_output(dut)
    assert stalled_output == (data, keep, 1, last)
    assert int(dut.dma_tready_o.value) == 0
    assert int(dut.taxi_tready_o.value) == 0

    dut.m_tready_i.value = 1
    await settle()

    assert common_output(dut) == stalled_output
    assert int(dut.dma_tready_o.value) == 1
    assert int(dut.taxi_tready_o.value) == 0


@cocotb.test()
async def test_source_boundary_backpressure_taxi_path(dut: Any) -> None:
    """Common backpressure propagates through mux and lane_rewire to Taxi."""

    frame = make_ethernet_like_frame(71)
    taxi_data, taxi_keep, taxi_last = taxi_words(frame)[0]
    expected_data, expected_keep, expected_last = project_words(frame)[0]

    dut.select_taxi_i.value = 1
    poison_dma(dut)
    dut.taxi_tdata_i.value = taxi_data
    dut.taxi_tkeep_i.value = taxi_keep
    dut.taxi_tvalid_i.value = 1
    dut.taxi_tlast_i.value = taxi_last

    dut.m_tready_i.value = 0
    await settle()

    stalled_output = common_output(dut)
    assert stalled_output == (
        expected_data,
        expected_keep,
        1,
        expected_last,
    )
    assert int(dut.dma_tready_o.value) == 0
    assert int(dut.taxi_tready_o.value) == 0

    dut.m_tready_i.value = 1
    await settle()

    assert common_output(dut) == stalled_output
    assert int(dut.dma_tready_o.value) == 0
    assert int(dut.taxi_tready_o.value) == 1


@cocotb.test()
async def test_source_boundary_representative_back_to_back_frames(
    dut: Any,
) -> None:
    """Consecutive frames remain equivalent across both source paths."""

    frames = [
        make_ethernet_like_frame(65),
        make_ethernet_like_frame(72),
        make_ethernet_like_frame(67),
    ]

    for frame in frames:
        dma_observed = await observe_dma_frame(dut, frame)
        taxi_observed = await observe_taxi_frame(dut, frame)

        assert taxi_observed == dma_observed
