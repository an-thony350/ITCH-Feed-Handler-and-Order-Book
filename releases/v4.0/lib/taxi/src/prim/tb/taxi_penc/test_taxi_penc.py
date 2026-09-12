#!/usr/bin/env python
# SPDX-License-Identifier: CERN-OHL-S-2.0
"""

Copyright (c) 2020-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

"""

import logging
import os

import cocotb_test.simulator
import pytest

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def run_single_bit(dut):

    log = logging.getLogger("cocotb.tb")
    log.setLevel(logging.DEBUG)

    for i in range(32):
        in_val = 1 << i

        log.info("In: 0x%08x", in_val)
        dut.input_mask.value = in_val

        await Timer(1, "ns")

        log.info("Out (index): %d", int(dut.output_index.value))
        log.info("Out (mask): 0x%08x", int(dut.output_mask.value))

        assert int(dut.output_valid.value)
        assert int(dut.output_index.value) == i
        assert int(dut.output_mask.value) == 1 << i


@cocotb.test()
async def run_two_bits(dut):

    lsb_high_prio = bool(int(dut.LSB_HIGH_PRIO.value))

    log = logging.getLogger("cocotb.tb")
    log.setLevel(logging.DEBUG)

    for i in range(32):
        for j in range(32):
            in_val = (1 << i) | (1 << j)

            log.info("In: 0x%08x", in_val)
            dut.input_mask.value = in_val

            await Timer(1, "ns")

            log.info("Out (index): %d", int(dut.output_index.value))
            log.info("Out (mask): 0x%08x", int(dut.output_mask.value))

            assert int(dut.output_valid.value)
            if lsb_high_prio:
                assert int(dut.output_index.value) == min(i, j)
                assert int(dut.output_mask.value) == 1 << min(i, j)
            else:
                assert int(dut.output_index.value) == max(i, j)
                assert int(dut.output_mask.value) == 1 << max(i, j)


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))
src_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', '..'))


def process_f_files(files):
    lst = {}
    for f in files:
        if f[-2:].lower() == '.f':
            with open(f, 'r') as fp:
                l = fp.read().split()
            for f in process_f_files([os.path.join(os.path.dirname(f), x) for x in l]):
                lst[os.path.basename(f)] = f
        else:
            lst[os.path.basename(f)] = f
    return list(lst.values())


@pytest.mark.parametrize("lsb_high_prio", [0, 1])
def test_taxi_penc(request, lsb_high_prio):
    dut = "taxi_penc"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.sv"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['WIDTH'] = 32
    parameters['LSB_HIGH_PRIO'] = f"1'b{lsb_high_prio}"

    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    sim_build = os.path.join(tests_dir, "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        simulator="verilator",
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        parameters=parameters,
        sim_build=sim_build,
        extra_env=extra_env,
    )
