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
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

        dut.req.setimmediatevalue(0)
        dut.ack.setimmediatevalue(0)

    async def reset(self):
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)


@cocotb.test()
async def run_single_bit(dut):

    tb = TB(dut)

    round_robin = bool(int(dut.ARB_ROUND_ROBIN.value))
    lsb_high_prio = bool(int(dut.LSB_HIGH_PRIO.value))

    await tb.reset()

    if lsb_high_prio:
        prev_index = 31
    else:
        prev_index = 0

    for i in range(32):
        lst = [i]
        k = 0
        for y in lst:
            k = k | 1 << y

        tb.log.info("Request: 0x%08x", k)

        dut.req.value = k
        await RisingEdge(dut.clk)
        dut.req.value = 0
        await RisingEdge(dut.clk)

        if round_robin:
            if lsb_high_prio:
                # emulate round robin
                lst2 = [x for x in lst if x > prev_index]
                if len(lst2) == 0:
                    lst2 = lst
                g = min(lst2)
            else:
                # emulate round robin
                lst2 = [x for x in lst if x < prev_index]
                if len(lst2) == 0:
                    lst2 = lst
                g = max(lst2)
        else:
            if lsb_high_prio:
                g = min(lst)
            else:
                g = max(lst)

        tb.log.info("Grant (mask): 0x%08x", int(dut.grant.value))
        tb.log.info("Grant (index): %d", int(dut.grant_index.value))

        assert int(dut.grant.value) == 1 << g
        assert int(dut.grant_index.value) == g

        prev_index = int(g)

        await RisingEdge(dut.clk)


@cocotb.test()
async def run_cycle(dut):

    tb = TB(dut)

    round_robin = bool(int(dut.ARB_ROUND_ROBIN.value))
    lsb_high_prio = bool(int(dut.LSB_HIGH_PRIO.value))

    await tb.reset()

    if lsb_high_prio:
        prev_index = 31
    else:
        prev_index = 0

    for i in range(32):
        lst = [0, 5, 10, 15, 20, 25, 30]
        k = 0
        for y in lst:
            k = k | 1 << y

        tb.log.info("Request: 0x%08x", k)

        dut.req.value = k
        await RisingEdge(dut.clk)
        dut.req.value = 0
        await RisingEdge(dut.clk)

        if round_robin:
            if lsb_high_prio:
                # emulate round robin
                lst2 = [x for x in lst if x > prev_index]
                if len(lst2) == 0:
                    lst2 = lst
                g = min(lst2)
            else:
                # emulate round robin
                lst2 = [x for x in lst if x < prev_index]
                if len(lst2) == 0:
                    lst2 = lst
                g = max(lst2)
        else:
            if lsb_high_prio:
                g = min(lst)
            else:
                g = max(lst)

        tb.log.info("Grant (mask): 0x%08x", int(dut.grant.value))
        tb.log.info("Grant (index): %d", int(dut.grant_index.value))

        assert int(dut.grant.value) == 1 << g
        assert int(dut.grant_index.value) == g

        prev_index = int(g)

        await RisingEdge(dut.clk)


@cocotb.test()
async def run_two_bits(dut):

    tb = TB(dut)

    round_robin = bool(int(dut.ARB_ROUND_ROBIN.value))
    lsb_high_prio = bool(int(dut.LSB_HIGH_PRIO.value))

    await tb.reset()

    if lsb_high_prio:
        prev_index = 31
    else:
        prev_index = 0

    for i in range(32):
        for j in range(32):
            lst = [i, j]
            k = 0
            for y in lst:
                k = k | 1 << y

            tb.log.info("Request: 0x%08x", k)

            dut.req.value = k
            await RisingEdge(dut.clk)
            dut.req.value = 0
            await RisingEdge(dut.clk)

            if round_robin:
                if lsb_high_prio:
                    # emulate round robin
                    lst2 = [x for x in lst if x > prev_index]
                    if len(lst2) == 0:
                        lst2 = lst
                    g = min(lst2)
                else:
                    # emulate round robin
                    lst2 = [x for x in lst if x < prev_index]
                    if len(lst2) == 0:
                        lst2 = lst
                    g = max(lst2)
            else:
                if lsb_high_prio:
                    g = min(lst)
                else:
                    g = max(lst)

            tb.log.info("Grant (mask): 0x%08x", int(dut.grant.value))
            tb.log.info("Grant (index): %d", int(dut.grant_index.value))

            assert int(dut.grant.value) == 1 << g
            assert int(dut.grant_index.value) == g

            prev_index = int(g)

            await RisingEdge(dut.clk)


@cocotb.test()
async def run_five_bits(dut):

    tb = TB(dut)

    round_robin = bool(int(dut.ARB_ROUND_ROBIN.value))
    lsb_high_prio = bool(int(dut.LSB_HIGH_PRIO.value))

    await tb.reset()

    if lsb_high_prio:
        prev_index = 31
    else:
        prev_index = 0

    for i in range(32):
        lst = [(i*x) % 32 for x in [1, 3, 5, 7, 11]]
        k = 0
        for y in lst:
            k = k | 1 << y

        tb.log.info("Request: 0x%08x", k)

        dut.req.value = k
        await RisingEdge(dut.clk)
        dut.req.value = 0
        await RisingEdge(dut.clk)

        if round_robin:
            if lsb_high_prio:
                # emulate round robin
                lst2 = [x for x in lst if x > prev_index]
                if len(lst2) == 0:
                    lst2 = lst
                g = min(lst2)
            else:
                # emulate round robin
                lst2 = [x for x in lst if x < prev_index]
                if len(lst2) == 0:
                    lst2 = lst
                g = max(lst2)
        else:
            if lsb_high_prio:
                g = min(lst)
            else:
                g = max(lst)

        tb.log.info("Grant (mask): 0x%08x", int(dut.grant.value))
        tb.log.info("Grant (index): %d", int(dut.grant_index.value))

        assert int(dut.grant.value) == 1 << g
        assert int(dut.grant_index.value) == g

        prev_index = int(g)

        await RisingEdge(dut.clk)


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
@pytest.mark.parametrize("round_robin", [0, 1])
def test_taxi_arbiter(request, round_robin, lsb_high_prio):
    dut = "taxi_arbiter"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.sv"),
        os.path.join(rtl_dir, "taxi_penc.sv"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['PORTS'] = 32
    parameters['ARB_ROUND_ROBIN'] = f"1'b{round_robin}"
    parameters['ARB_BLOCK'] = "1'b1"
    parameters['ARB_BLOCK_ACK'] = "1'b0"
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
