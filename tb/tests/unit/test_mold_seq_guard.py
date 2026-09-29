"""Unit regression for mold_seq_guard.sv.

Testing for the packet-level sequence policy from MoldUDP64 parsing

We check:
- idle outputs and reset/restart behaviour;
- first-packet and normal in-order progression;
- normal count arithmetic up to the largest non-control count;
- exact duplicate, older/late and partially-overlapping packet suppression;
- forward-gap acceptance, exact missing range and sticky stale state;
- explicit stale clearing without rewinding expected sequence;
- heartbeat and end-of-session status-only handling;
- control packets at, behind and ahead of the current expectation.

"""

from __future__ import annotations

from typing import Any

import cocotb
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

from itch_harness.axis import reset_dut
from itch_harness.perf import start_perf_clock
from itch_harness.scoreboard import signal_value_to_int


RESET_CYCLES = 5
COUNT_HEARTBEAT = 0x0000
COUNT_EOS = 0xFFFF
COUNT_MAX_NORMAL = 0xFFFE


async def _initialise(dut: Any) -> None:
    """Start the configured clock and reset the guard with inactive inputs."""

    await start_perf_clock(dut)

    dut.seq_valid_i.value = 0
    dut.seq_i.value = 0
    dut.count_i.value = 0
    dut.clear_stale_i.value = 0

    await reset_dut(dut, cycles=RESET_CYCLES)
    await ReadOnly()


def _sample_decision(dut: Any) -> dict[str, int]:
    """Sample the same-cycle combinational decision outputs."""

    return {
        "accept": signal_value_to_int(dut.accept_packet_o.value),
        "drop": signal_value_to_int(dut.drop_packet_o.value),
        "in_order": signal_value_to_int(dut.in_order_o.value),
        "duplicate": signal_value_to_int(dut.duplicate_o.value),
        "gap": signal_value_to_int(dut.gap_o.value),
        "heartbeat": signal_value_to_int(dut.heartbeat_o.value),
        "eos": signal_value_to_int(dut.eos_o.value),
    }


def _sample_state(dut: Any) -> dict[str, int]:
    """Sample the registered sequence state."""

    return {
        "stale": signal_value_to_int(dut.stale_o.value),
        "expected_seq": signal_value_to_int(dut.expected_seq_o.value),
        "gap_start": signal_value_to_int(dut.gap_start_o.value),
        "gap_end": signal_value_to_int(dut.gap_end_o.value),
    }


def _assert_decision(
    observed: dict[str, int],
    *,
    accept: int,
    drop: int,
    in_order: int = 0,
    duplicate: int = 0,
    gap: int = 0,
    heartbeat: int = 0,
    eos: int = 0,
    context: str,
) -> None:
    expected = {
        "accept": accept,
        "drop": drop,
        "in_order": in_order,
        "duplicate": duplicate,
        "gap": gap,
        "heartbeat": heartbeat,
        "eos": eos,
    }
    assert observed == expected, (
        f"{context}: decision mismatch\n"
        f"expected={expected}\n"
        f"observed={observed}"
    )


def _assert_state(
    observed: dict[str, int],
    *,
    stale: int,
    expected_seq: int,
    gap_start: int,
    gap_end: int,
    context: str,
) -> None:
    expected = {
        "stale": stale,
        "expected_seq": expected_seq,
        "gap_start": gap_start,
        "gap_end": gap_end,
    }
    assert observed == expected, (
        f"{context}: state mismatch\n"
        f"expected={expected}\n"
        f"observed={observed}"
    )


async def _apply_header(
    dut: Any,
    *,
    seq: int,
    count: int,
) -> tuple[dict[str, int], dict[str, int]]:
    """Present one parsed MoldUDP64 header for exactly one active edge."""

    await FallingEdge(dut.clk)

    dut.seq_i.value = seq
    dut.count_i.value = count
    dut.seq_valid_i.value = 1

    await ReadOnly()
    decision = _sample_decision(dut)

    await RisingEdge(dut.clk)
    await ReadOnly()
    state = _sample_state(dut)

    await FallingEdge(dut.clk)
    dut.seq_valid_i.value = 0
    dut.seq_i.value = 0
    dut.count_i.value = 0

    return decision, state


async def _clear_stale(dut: Any) -> dict[str, int]:
    """Pulse clear_stale_i without changing expected_seq_o."""

    await FallingEdge(dut.clk)
    dut.clear_stale_i.value = 1

    await RisingEdge(dut.clk)
    await ReadOnly()
    state = _sample_state(dut)

    await FallingEdge(dut.clk)
    dut.clear_stale_i.value = 0

    return state


async def _reset_active_guard(dut: Any) -> None:
    """Reset after activity while forcing all request inputs inactive."""

    await FallingEdge(dut.clk)
    dut.seq_valid_i.value = 0
    dut.seq_i.value = 0
    dut.count_i.value = 0
    dut.clear_stale_i.value = 0

    await reset_dut(dut, cycles=RESET_CYCLES)
    await ReadOnly()


@cocotb.test()
async def test_mold_seq_guard_idle_and_first_packet(dut: Any) -> None:
    """Idle outputs stay quiet and the first normal packet establishes state."""

    await _initialise(dut)

    _assert_decision(
        _sample_decision(dut),
        accept=0,
        drop=0,
        context="idle after reset",
    )
    _assert_state(
        _sample_state(dut),
        stale=0,
        expected_seq=0,
        gap_start=0,
        gap_end=0,
        context="state after reset",
    )

    # Changing the header fields without seq_valid must not create a decision.
    await FallingEdge(dut.clk)
    dut.seq_i.value = 1234
    dut.count_i.value = 7

    for cycle in range(4):
        await ReadOnly()
        _assert_decision(
            _sample_decision(dut),
            accept=0,
            drop=0,
            context=f"idle seq_valid=0 cycle={cycle}",
        )
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

    _assert_state(
        _sample_state(dut),
        stale=0,
        expected_seq=0,
        gap_start=0,
        gap_end=0,
        context="state remained idle without seq_valid",
    )

    decision, state = await _apply_header(dut, seq=100, count=3)
    _assert_decision(
        decision,
        accept=1,
        drop=0,
        in_order=1,
        context="first normal packet",
    )
    _assert_state(
        state,
        stale=0,
        expected_seq=103,
        gap_start=0,
        gap_end=0,
        context="after first normal packet",
    )


@cocotb.test()
async def test_mold_seq_guard_in_order_progression_and_count_arithmetic(
    dut: Any,
) -> None:
    """In-order packets advance by count across small and large legal counts."""

    await _initialise(dut)

    decision, state = await _apply_header(dut, seq=10, count=1)
    _assert_decision(
        decision,
        accept=1,
        drop=0,
        in_order=1,
        context="count=1 packet",
    )
    assert state["expected_seq"] == 11

    decision, state = await _apply_header(dut, seq=11, count=4)
    _assert_decision(
        decision,
        accept=1,
        drop=0,
        in_order=1,
        context="count=4 continuation",
    )
    assert state["expected_seq"] == 15

    await _reset_active_guard(dut)

    base_seq = 1000
    decision, state = await _apply_header(
        dut,
        seq=base_seq,
        count=COUNT_MAX_NORMAL,
    )
    _assert_decision(
        decision,
        accept=1,
        drop=0,
        in_order=1,
        context="largest normal Mold count",
    )
    _assert_state(
        state,
        stale=0,
        expected_seq=base_seq + COUNT_MAX_NORMAL,
        gap_start=0,
        gap_end=0,
        context="largest normal count arithmetic",
    )


@cocotb.test()
async def test_mold_seq_guard_suppresses_duplicate_late_and_overlap(
    dut: Any,
) -> None:
    """Any normal packet starting below expected_seq is dropped whole."""

    await _initialise(dut)

    _, state = await _apply_header(dut, seq=200, count=5)
    assert state["expected_seq"] == 205

    cases = [
        ("exact duplicate", 200, 5),
        ("older packet", 190, 2),
        ("partial overlap", 204, 8),
    ]

    for name, seq, count in cases:
        decision, state = await _apply_header(dut, seq=seq, count=count)

        _assert_decision(
            decision,
            accept=0,
            drop=1,
            duplicate=1,
            context=name,
        )
        _assert_state(
            state,
            stale=0,
            expected_seq=205,
            gap_start=0,
            gap_end=0,
            context=f"{name} must not mutate state",
        )

    decision, state = await _apply_header(dut, seq=205, count=2)
    _assert_decision(
        decision,
        accept=1,
        drop=0,
        in_order=1,
        context="recovery after duplicate/late traffic",
    )
    assert state["expected_seq"] == 207


@cocotb.test()
async def test_mold_seq_guard_gap_stale_and_clear(dut: Any) -> None:
    """A forward gap records the exact range while accepting the new packet."""

    await _initialise(dut)

    _, state = await _apply_header(dut, seq=20, count=2)
    assert state["expected_seq"] == 22

    decision, state = await _apply_header(dut, seq=25, count=2)
    _assert_decision(
        decision,
        accept=1,
        drop=0,
        gap=1,
        context="forward gap packet",
    )
    _assert_state(
        state,
        stale=1,
        expected_seq=27,
        gap_start=22,
        gap_end=24,
        context="gap state",
    )

    # Late traffic after the gap must not overwrite the recorded missing range.
    decision, state = await _apply_header(dut, seq=23, count=1)
    _assert_decision(
        decision,
        accept=0,
        drop=1,
        duplicate=1,
        context="late packet after gap",
    )
    _assert_state(
        state,
        stale=1,
        expected_seq=27,
        gap_start=22,
        gap_end=24,
        context="late traffic preserves gap state",
    )

    state = await _clear_stale(dut)
    _assert_state(
        state,
        stale=0,
        expected_seq=27,
        gap_start=22,
        gap_end=24,
        context="clear stale does not rewind sequence state",
    )

    decision, state = await _apply_header(dut, seq=27, count=1)
    _assert_decision(
        decision,
        accept=1,
        drop=0,
        in_order=1,
        context="in-order packet after stale clear",
    )
    _assert_state(
        state,
        stale=0,
        expected_seq=28,
        gap_start=22,
        gap_end=24,
        context="gap history remains available after recovery",
    )


@cocotb.test()
async def test_mold_seq_guard_heartbeat_control_matrix(dut: Any) -> None:
    """Heartbeats are status-only and only an ahead sequence records a gap."""

    await _initialise(dut)

    decision, state = await _apply_header(
        dut,
        seq=300,
        count=COUNT_HEARTBEAT,
    )
    _assert_decision(
        decision,
        accept=0,
        drop=1,
        heartbeat=1,
        context="first heartbeat",
    )
    _assert_state(
        state,
        stale=0,
        expected_seq=300,
        gap_start=0,
        gap_end=0,
        context="first heartbeat establishes expectation",
    )

    decision, state = await _apply_header(
        dut,
        seq=300,
        count=COUNT_HEARTBEAT,
    )
    _assert_decision(
        decision,
        accept=0,
        drop=1,
        heartbeat=1,
        context="heartbeat at current expectation",
    )
    assert state["expected_seq"] == 300
    assert state["stale"] == 0

    decision, state = await _apply_header(
        dut,
        seq=299,
        count=COUNT_HEARTBEAT,
    )
    _assert_decision(
        decision,
        accept=0,
        drop=1,
        heartbeat=1,
        context="heartbeat behind expectation",
    )
    _assert_state(
        state,
        stale=0,
        expected_seq=300,
        gap_start=0,
        gap_end=0,
        context="late heartbeat leaves state unchanged",
    )

    decision, state = await _apply_header(
        dut,
        seq=304,
        count=COUNT_HEARTBEAT,
    )
    _assert_decision(
        decision,
        accept=0,
        drop=1,
        gap=1,
        heartbeat=1,
        context="heartbeat ahead of expectation",
    )
    _assert_state(
        state,
        stale=1,
        expected_seq=304,
        gap_start=300,
        gap_end=303,
        context="heartbeat gap state",
    )


@cocotb.test()
async def test_mold_seq_guard_eos_control_matrix(dut: Any) -> None:
    """EOS is status-only and follows the same sequence-state comparison."""

    await _initialise(dut)

    decision, state = await _apply_header(dut, seq=500, count=2)
    _assert_decision(
        decision,
        accept=1,
        drop=0,
        in_order=1,
        context="normal packet before EOS",
    )
    assert state["expected_seq"] == 502

    decision, state = await _apply_header(dut, seq=502, count=COUNT_EOS)
    _assert_decision(
        decision,
        accept=0,
        drop=1,
        eos=1,
        context="EOS at expectation",
    )
    assert state["expected_seq"] == 502
    assert state["stale"] == 0

    decision, state = await _apply_header(dut, seq=500, count=COUNT_EOS)
    _assert_decision(
        decision,
        accept=0,
        drop=1,
        eos=1,
        context="EOS behind expectation",
    )
    assert state["expected_seq"] == 502
    assert state["stale"] == 0

    decision, state = await _apply_header(dut, seq=507, count=COUNT_EOS)
    _assert_decision(
        decision,
        accept=0,
        drop=1,
        gap=1,
        eos=1,
        context="EOS ahead of expectation",
    )
    _assert_state(
        state,
        stale=1,
        expected_seq=507,
        gap_start=502,
        gap_end=506,
        context="EOS gap state",
    )


@cocotb.test()
async def test_mold_seq_guard_reset_restarts_sequence_tracking(dut: Any) -> None:
    """Reset clears all sequence history and the next normal packet is first."""

    await _initialise(dut)

    await _apply_header(dut, seq=1000, count=3)
    _, state = await _apply_header(dut, seq=1010, count=2)
    assert state["stale"] == 1
    assert state["expected_seq"] == 1012

    await _reset_active_guard(dut)

    _assert_decision(
        _sample_decision(dut),
        accept=0,
        drop=0,
        context="decision outputs after reset",
    )
    _assert_state(
        _sample_state(dut),
        stale=0,
        expected_seq=0,
        gap_start=0,
        gap_end=0,
        context="all sequence state cleared by reset",
    )

    decision, state = await _apply_header(dut, seq=77, count=2)
    _assert_decision(
        decision,
        accept=1,
        drop=0,
        in_order=1,
        context="first packet after reset",
    )
    _assert_state(
        state,
        stale=0,
        expected_seq=79,
        gap_start=0,
        gap_end=0,
        context="fresh sequence state after reset",
    )
