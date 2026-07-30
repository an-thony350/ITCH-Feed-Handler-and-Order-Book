"""cocotb golden-replay tests for data_handler.sv.

Scope:
- Drive ITCH BinaryFILE payloads, without their two-byte length prefixes, into
  data_handler.sv.
- Compare every emitted 217-bit data_t word against build/golden/events.jsonl.
- Prove unsupported source messages do not produce decoder events.
- Prove output backpressure holds one stable event without accepting new input.

This is the G1 decoder-isolation gate. It intentionally does not instantiate the
symbol router or order book, so any mismatch is local to the decoder boundary.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import cocotb
from cocotb.triggers import FallingEdge, RisingEdge

from golden.itch_parser import iter_binaryfile_payloads
from itch_harness.axis import (
    drive_data_handler_payload,
    reset_data_handler,
    start_clock,
)
from itch_harness.oracle import GoldenOracle, load_oracle
from itch_harness.scoreboard import (
    assert_data_t_matches_word,
    signal_value_to_int,
)


SYNTHETIC_INPUT_FILENAME = "itch_synthetic.bin"


def golden_input_path(oracle: GoldenOracle) -> Path:
    """Return the BinaryFILE input paired with the loaded golden JSONL files."""

    input_path = oracle.events_path.parent / SYNTHETIC_INPUT_FILENAME
    if not input_path.exists():
        raise FileNotFoundError(
            f"golden BinaryFILE input not found: {input_path}\n"
            "Run scripts/run_golden.sh from the repository root first."
        )
    return input_path


async def initialise_data_handler(dut: Any) -> None:
    """Start the clock and place data_handler in its idle post-reset state."""

    await start_clock(dut)
    await reset_data_handler(dut, cycles=5)
    await FallingEdge(dut.clk)

    assert signal_value_to_int(dut.s_tready_o.value) == 1
    assert signal_value_to_int(dut.valid_o.value) == 0


async def assert_no_decoder_output(dut: Any, *, cycles: int = 2) -> None:
    """Prove that no decoder event is emitted over the requested idle window."""

    for _ in range(cycles):
        await FallingEdge(dut.clk)
        assert signal_value_to_int(dut.valid_o.value) == 0, (
            "data_handler emitted an unexpected event for a source message that "
            "is absent from events.jsonl"
        )


@cocotb.test()
async def test_data_handler_replays_binaryfile_against_events_jsonl(dut: Any) -> None:
    """Replay the complete synthetic BinaryFILE and match every golden event."""

    oracle = load_oracle()
    input_path = golden_input_path(oracle)
    input_data = input_path.read_bytes()

    await initialise_data_handler(dut)

    expected_index = 0
    source_messages = 0

    for msg_index, payload in iter_binaryfile_payloads(input_data):
        source_messages += 1
        expected_event = (
            oracle.events[expected_index]
            if expected_index < oracle.count
            else None
        )

        if expected_event is not None and int(expected_event["msg_index"]) < msg_index:
            raise AssertionError(
                "decoder missed an expected golden event before the current "
                f"source message: expected msg_index={expected_event['msg_index']}, "
                f"current source msg_index={msg_index}"
            )

        if expected_event is None or int(expected_event["msg_index"]) != msg_index:
            await drive_data_handler_payload(
                dut,
                payload,
                wait_for_output=False,
            )
            await assert_no_decoder_output(dut)
            continue

        rtl_word = await drive_data_handler_payload(dut, payload)
        assert rtl_word is not None
        assert_data_t_matches_word(rtl_word, expected_event)

        dut._log.info(
            "matched oracle row=%d msg_index=%d op=%s message_type=0x%02x",
            expected_index,
            msg_index,
            expected_event["op"],
            bytes(payload)[0],
        )
        expected_index += 1

    assert expected_index == oracle.count, (
        f"decoder emitted/matched {expected_index} events, "
        f"but events.jsonl contains {oracle.count}"
    )

    await assert_no_decoder_output(dut, cycles=4)

    dut._log.info(
        "G1 replay passed: source_messages=%d matched_events=%d input=%s",
        source_messages,
        expected_index,
        input_path,
    )


@cocotb.test()
async def test_data_handler_holds_event_stable_under_output_backpressure(
    dut: Any,
) -> None:
    """Hold ready_i low and prove SEND data remains valid and stable."""

    oracle = load_oracle()
    input_path = golden_input_path(oracle)
    input_data = input_path.read_bytes()

    assert oracle.count > 0, "events.jsonl contains no decoder events"
    expected_event = oracle.events[0]
    expected_msg_index = int(expected_event["msg_index"])

    payload = None
    for msg_index, candidate in iter_binaryfile_payloads(input_data):
        if msg_index == expected_msg_index:
            payload = bytes(candidate)
            break

    assert payload is not None, (
        f"could not find msg_index={expected_msg_index} in {input_path}"
    )

    await initialise_data_handler(dut)

    dut.ready_i.value = 0
    await drive_data_handler_payload(
        dut,
        payload,
        wait_for_output=False,
    )

    assert signal_value_to_int(dut.valid_o.value) == 1
    assert signal_value_to_int(dut.s_tready_o.value) == 0

    held_word = signal_value_to_int(dut.rdata_o.value)
    assert_data_t_matches_word(held_word, expected_event)

    for _ in range(8):
        await FallingEdge(dut.clk)
        assert signal_value_to_int(dut.valid_o.value) == 1
        assert signal_value_to_int(dut.s_tready_o.value) == 0
        assert signal_value_to_int(dut.rdata_o.value) == held_word

    # Release backpressure with half a cycle of setup before the active edge.
    dut.ready_i.value = 1
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)

    assert signal_value_to_int(dut.valid_o.value) == 0
    assert signal_value_to_int(dut.s_tready_o.value) == 1

    dut._log.info(
        "backpressure hold passed for msg_index=%d op=%s",
        expected_msg_index,
        expected_event["op"],
    )
