"""Directed cocotb regression for mold_seq_guard.sv.

This isolates the packet-level sequence policy from Ethernet parsing and the
order book so sequence failures can be diagnosed quickly.

Covered:
- first packet;
- in-order continuation;
- duplicate/late packet suppression;
- gap acceptance and exact gap range;
- sticky stale state and explicit clear;
- heartbeat and EOS status-only decisions;
- reset of all sequence state.
"""

from __future__ import annotations

from typing import Any

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from itch_harness.axis import reset_dut, start_clock
from itch_harness.scoreboard import signal_value_to_int


RESET_CYCLES = 5


async def initialise_guard(dut: Any) -> None:
    """Start and reset mold_seq_guard with inactive inputs."""

    await start_clock(dut)

    dut.seq_valid_i.value = 0
    dut.seq_i.value = 0
    dut.count_i.value = 0
    dut.clear_stale_i.value = 0

    await reset_dut(dut, cycles=RESET_CYCLES)
    await ReadOnly()


def sample_decision(dut: Any) -> dict[str, int]:
    """Sample same-cycle combinational decisions."""

    return {
        "accept": signal_value_to_int(dut.accept_packet_o.value),
        "drop": signal_value_to_int(dut.drop_packet_o.value),
        "in_order": signal_value_to_int(dut.in_order_o.value),
        "duplicate": signal_value_to_int(dut.duplicate_o.value),
        "gap": signal_value_to_int(dut.gap_o.value),
        "heartbeat": signal_value_to_int(dut.heartbeat_o.value),
        "eos": signal_value_to_int(dut.eos_o.value),
    }


def sample_state(dut: Any) -> dict[str, int]:
    """Sample registered sequence state."""

    return {
        "stale": signal_value_to_int(dut.stale_o.value),
        "expected_seq": signal_value_to_int(dut.expected_seq_o.value),
        "gap_start": signal_value_to_int(dut.gap_start_o.value),
        "gap_end": signal_value_to_int(dut.gap_end_o.value),
    }


async def apply_header(
    dut: Any,
    *,
    seq: int,
    count: int,
) -> tuple[dict[str, int], dict[str, int]]:
    """Present one parsed MoldUDP64 header for exactly one clock edge."""

    await FallingEdge(dut.clk)

    dut.seq_i.value = seq
    dut.count_i.value = count
    dut.seq_valid_i.value = 1

    await ReadOnly()
    decision = sample_decision(dut)

    await RisingEdge(dut.clk)
    await ReadOnly()
    state = sample_state(dut)

    await FallingEdge(dut.clk)
    dut.seq_valid_i.value = 0
    dut.seq_i.value = 0
    dut.count_i.value = 0

    return decision, state


async def clear_stale(dut: Any) -> dict[str, int]:
    """Pulse clear_stale_i without changing expected_seq_o."""

    await FallingEdge(dut.clk)
    dut.clear_stale_i.value = 1

    await RisingEdge(dut.clk)
    await ReadOnly()
    state = sample_state(dut)

    await FallingEdge(dut.clk)
    dut.clear_stale_i.value = 0

    return state


@cocotb.test()
async def test_mold_seq_guard_first_in_order_and_duplicate(dut: Any) -> None:
    """First/in-order packets advance; a late copy is dropped."""

    await initialise_guard(dut)

    decision, state = await apply_header(dut, seq=100, count=3)
    assert decision == {
        "accept": 1,
        "drop": 0,
        "in_order": 1,
        "duplicate": 0,
        "gap": 0,
        "heartbeat": 0,
        "eos": 0,
    }
    assert state == {
        "stale": 0,
        "expected_seq": 103,
        "gap_start": 0,
        "gap_end": 0,
    }

    decision, state = await apply_header(dut, seq=103, count=2)
    assert decision["accept"] == 1
    assert decision["drop"] == 0
    assert decision["in_order"] == 1
    assert decision["duplicate"] == 0
    assert decision["gap"] == 0
    assert state["expected_seq"] == 105
    assert state["stale"] == 0

    decision, state = await apply_header(dut, seq=103, count=2)
    assert decision["accept"] == 0
    assert decision["drop"] == 1
    assert decision["in_order"] == 0
    assert decision["duplicate"] == 1
    assert decision["gap"] == 0
    assert state["expected_seq"] == 105
    assert state["stale"] == 0


@cocotb.test()
async def test_mold_seq_guard_gap_stale_and_clear(dut: Any) -> None:
    """A post-gap packet advances immediately and stale clears explicitly."""

    await initialise_guard(dut)

    _, state = await apply_header(dut, seq=20, count=2)
    assert state["expected_seq"] == 22

    decision, state = await apply_header(dut, seq=25, count=2)
    assert decision["accept"] == 1
    assert decision["drop"] == 0
    assert decision["in_order"] == 0
    assert decision["duplicate"] == 0
    assert decision["gap"] == 1
    assert state == {
        "stale": 1,
        "expected_seq": 27,
        "gap_start": 22,
        "gap_end": 24,
    }

    decision, state = await apply_header(dut, seq=23, count=1)
    assert decision["accept"] == 0
    assert decision["drop"] == 1
    assert decision["duplicate"] == 1
    assert decision["gap"] == 0
    assert state == {
        "stale": 1,
        "expected_seq": 27,
        "gap_start": 22,
        "gap_end": 24,
    }

    state = await clear_stale(dut)
    assert state == {
        "stale": 0,
        "expected_seq": 27,
        "gap_start": 22,
        "gap_end": 24,
    }

    decision, state = await apply_header(dut, seq=27, count=1)
    assert decision["accept"] == 1
    assert decision["in_order"] == 1
    assert decision["gap"] == 0
    assert state["stale"] == 0
    assert state["expected_seq"] == 28
    assert state["gap_start"] == 22
    assert state["gap_end"] == 24


@cocotb.test()
async def test_mold_seq_guard_heartbeat_eos_and_reset(dut: Any) -> None:
    """Heartbeat/EOS are status-only; future heartbeat records a gap."""

    await initialise_guard(dut)

    decision, state = await apply_header(dut, seq=300, count=0)
    assert decision == {
        "accept": 0,
        "drop": 1,
        "in_order": 0,
        "duplicate": 0,
        "gap": 0,
        "heartbeat": 1,
        "eos": 0,
    }
    assert state == {
        "stale": 0,
        "expected_seq": 300,
        "gap_start": 0,
        "gap_end": 0,
    }

    decision, state = await apply_header(dut, seq=300, count=0xFFFF)
    assert decision == {
        "accept": 0,
        "drop": 1,
        "in_order": 0,
        "duplicate": 0,
        "gap": 0,
        "heartbeat": 0,
        "eos": 1,
    }
    assert state["stale"] == 0
    assert state["expected_seq"] == 300

    decision, state = await apply_header(dut, seq=304, count=0)
    assert decision["accept"] == 0
    assert decision["drop"] == 1
    assert decision["heartbeat"] == 1
    assert decision["gap"] == 1
    assert decision["duplicate"] == 0
    assert state == {
        "stale": 1,
        "expected_seq": 304,
        "gap_start": 300,
        "gap_end": 303,
    }

    await reset_dut(dut, cycles=RESET_CYCLES)
    await ReadOnly()

    assert sample_state(dut) == {
        "stale": 0,
        "expected_seq": 0,
        "gap_start": 0,
        "gap_end": 0,
    }
    assert sample_decision(dut) == {
        "accept": 0,
        "drop": 0,
        "in_order": 0,
        "duplicate": 0,
        "gap": 0,
        "heartbeat": 0,
        "eos": 0,
    }
