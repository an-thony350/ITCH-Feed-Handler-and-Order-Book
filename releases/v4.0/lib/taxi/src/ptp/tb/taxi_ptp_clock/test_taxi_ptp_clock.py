#!/usr/bin/env python
# SPDX-License-Identifier: CERN-OHL-S-2.0
"""

Copyright (c) 2020-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

"""

import logging
import os
from decimal import Decimal

import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.utils import get_sim_time


class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 6.4, units="ns").start())

        dut.input_ts_tod.setimmediatevalue(0)
        dut.input_ts_tod_valid.setimmediatevalue(0)
        dut.input_ts_rel.setimmediatevalue(0)
        dut.input_ts_rel_valid.setimmediatevalue(0)

        dut.input_period_ns.setimmediatevalue(0)
        dut.input_period_fns.setimmediatevalue(0)
        dut.input_period_valid.setimmediatevalue(0)

        dut.input_adj_ns.setimmediatevalue(0)
        dut.input_adj_fns.setimmediatevalue(0)
        dut.input_adj_count.setimmediatevalue(0)
        dut.input_adj_valid.setimmediatevalue(0)
        dut.input_adj_active.setimmediatevalue(0)

        dut.input_drift_num.setimmediatevalue(0)
        dut.input_drift_denom.setimmediatevalue(0)
        dut.input_drift_valid.setimmediatevalue(0)

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

    def get_output_ts_tod_ns(self):
        ts = int(self.dut.output_ts_tod.value)
        return Decimal(ts >> 48).scaleb(9) + (Decimal(ts & 0xffffffffffff) / Decimal(2**16))

    def get_output_ts_tod_s(self):
        return self.get_output_ts_tod_ns().scaleb(-9)

    def get_output_ts_rel_ns(self):
        ts = int(self.dut.output_ts_rel.value)
        return Decimal(ts) / Decimal(2**16)

    def get_output_ts_rel_s(self):
        return self.get_output_ts_rel_ns().scaleb(-9)


@cocotb.test()
async def run_default_rate(dut):

    tb = TB(dut)

    await tb.reset()

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    start_time = Decimal(get_sim_time('fs')).scaleb(-6)
    start_ts_tod = tb.get_output_ts_tod_ns()
    start_ts_rel = tb.get_output_ts_rel_ns()

    for k in range(10000):
        await RisingEdge(dut.clk)

    stop_time = Decimal(get_sim_time('fs')).scaleb(-6)
    stop_ts_tod = tb.get_output_ts_tod_ns()
    stop_ts_rel = tb.get_output_ts_rel_ns()

    time_delta = stop_time-start_time
    ts_tod_delta = stop_ts_tod-start_ts_tod
    ts_rel_delta = stop_ts_rel-start_ts_rel

    tb.log.info("sim time delta : %s ns", time_delta)
    tb.log.info("ToD ts delta   : %s ns", ts_tod_delta)
    tb.log.info("Rel ts delta   : %s ns", ts_rel_delta)

    ts_tod_diff = time_delta - ts_tod_delta
    ts_rel_diff = time_delta - ts_rel_delta

    tb.log.info("ToD ts diff    : %s ns", ts_tod_diff)
    tb.log.info("Rel ts diff    : %s ns", ts_rel_diff)

    assert abs(ts_tod_diff) < 1e-3
    assert abs(ts_rel_diff) < 1e-3

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


@cocotb.test()
async def run_load_timestamps(dut):

    tb = TB(dut)

    await tb.reset()

    await RisingEdge(dut.clk)

    dut.input_ts_tod.value = 12345678
    dut.input_ts_tod_valid.value = 1
    dut.input_ts_rel.value = 12345678
    dut.input_ts_rel_valid.value = 1

    await RisingEdge(dut.clk)

    dut.input_ts_tod_valid.value = 0
    dut.input_ts_rel_valid.value = 0

    await RisingEdge(dut.clk)

    assert int(dut.output_ts_tod.value) == 12345678
    assert int(dut.output_ts_tod_step.value) == 1
    assert int(dut.output_ts_rel.value) == 12345678
    assert int(dut.output_ts_rel_step.value) == 1

    await RisingEdge(dut.clk)

    start_time = Decimal(get_sim_time('fs')).scaleb(-6)
    start_ts_tod = tb.get_output_ts_tod_ns()
    start_ts_rel = tb.get_output_ts_rel_ns()

    for k in range(2000):
        await RisingEdge(dut.clk)

    stop_time = Decimal(get_sim_time('fs')).scaleb(-6)
    stop_ts_tod = tb.get_output_ts_tod_ns()
    stop_ts_rel = tb.get_output_ts_rel_ns()

    time_delta = stop_time-start_time
    ts_tod_delta = stop_ts_tod-start_ts_tod
    ts_rel_delta = stop_ts_rel-start_ts_rel

    tb.log.info("sim time delta : %s ns", time_delta)
    tb.log.info("ToD ts delta   : %s ns", ts_tod_delta)
    tb.log.info("Rel ts delta   : %s ns", ts_rel_delta)

    ts_tod_diff = time_delta - ts_tod_delta
    ts_rel_diff = time_delta - ts_rel_delta

    tb.log.info("ToD ts diff    : %s ns", ts_tod_diff)
    tb.log.info("Rel ts diff    : %s ns", ts_rel_diff)

    assert abs(ts_tod_diff) < 1e-3
    assert abs(ts_rel_diff) < 1e-3

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


@cocotb.test()
async def run_seconds_increment(dut):

    tb = TB(dut)

    await tb.reset()

    await RisingEdge(dut.clk)

    dut.input_ts_tod.value = 999990000 << 16
    dut.input_ts_tod_valid.value = 1
    dut.input_ts_rel.value = 999990000 << 16
    dut.input_ts_rel_valid.value = 1

    await RisingEdge(dut.clk)

    dut.input_ts_tod_valid.value = 0
    dut.input_ts_rel_valid.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    start_time = Decimal(get_sim_time('fs')).scaleb(-6)
    start_ts_tod = tb.get_output_ts_tod_ns()
    start_ts_rel = tb.get_output_ts_rel_ns()

    saw_pps = False

    for k in range(3000):
        await RisingEdge(dut.clk)

        if int(dut.output_pps.value):
            saw_pps = True
            tb.log.info("Got PPS with sink ToD TS %s", tb.get_output_ts_tod_ns())
            assert (tb.get_output_ts_tod_s() - 1) < 6.4e-9

    assert saw_pps

    stop_time = Decimal(get_sim_time('fs')).scaleb(-6)
    stop_ts_tod = tb.get_output_ts_tod_ns()
    stop_ts_rel = tb.get_output_ts_rel_ns()

    time_delta = stop_time-start_time
    ts_tod_delta = stop_ts_tod-start_ts_tod
    ts_rel_delta = stop_ts_rel-start_ts_rel

    tb.log.info("sim time delta : %s ns", time_delta)
    tb.log.info("ToD ts delta   : %s ns", ts_tod_delta)
    tb.log.info("Rel ts delta   : %s ns", ts_rel_delta)

    ts_tod_diff = time_delta - ts_tod_delta
    ts_rel_diff = time_delta - ts_rel_delta

    tb.log.info("ToD ts diff    : %s ns", ts_tod_diff)
    tb.log.info("Rel ts diff    : %s ns", ts_rel_diff)

    assert abs(ts_tod_diff) < 1e-3
    assert abs(ts_rel_diff) < 1e-3

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


@cocotb.test()
async def run_frequency_adjustment(dut):

    tb = TB(dut)

    await tb.reset()

    await RisingEdge(dut.clk)

    dut.input_period_ns.value = 0x6
    dut.input_period_fns.value = 0x6624
    dut.input_period_valid.value = 1

    await RisingEdge(dut.clk)

    dut.input_period_valid.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)
    start_time = Decimal(get_sim_time('fs')).scaleb(-6)
    start_ts_tod = tb.get_output_ts_tod_ns()
    start_ts_rel = tb.get_output_ts_rel_ns()

    for k in range(10000):
        await RisingEdge(dut.clk)

    stop_time = Decimal(get_sim_time('fs')).scaleb(-6)
    stop_ts_tod = tb.get_output_ts_tod_ns()
    stop_ts_rel = tb.get_output_ts_rel_ns()

    time_delta = stop_time-start_time
    ts_tod_delta = stop_ts_tod-start_ts_tod
    ts_rel_delta = stop_ts_rel-start_ts_rel

    tb.log.info("sim time delta : %s ns", time_delta)
    tb.log.info("ToD ts delta   : %s ns", ts_tod_delta)
    tb.log.info("Rel ts delta   : %s ns", ts_rel_delta)

    ts_tod_diff = time_delta - ts_tod_delta * Decimal(6.4/(6+(0x6624+2/5)/2**16))
    ts_rel_diff = time_delta - ts_rel_delta * Decimal(6.4/(6+(0x6624+2/5)/2**16))

    tb.log.info("ToD ts diff    : %s ns", ts_tod_diff)
    tb.log.info("Rel ts diff    : %s ns", ts_rel_diff)

    assert abs(ts_tod_diff) < 1e-3
    assert abs(ts_rel_diff) < 1e-3

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


@cocotb.test()
async def run_drift_adjustment(dut):

    tb = TB(dut)

    await tb.reset()

    dut.input_drift_num.value = 20
    dut.input_drift_denom.value = 5
    dut.input_drift_valid.value = 1

    await RisingEdge(dut.clk)

    dut.input_drift_valid.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)
    start_time = Decimal(get_sim_time('fs')).scaleb(-6)
    start_ts_tod = tb.get_output_ts_tod_ns()
    start_ts_rel = tb.get_output_ts_rel_ns()

    for k in range(10000):
        await RisingEdge(dut.clk)

    stop_time = Decimal(get_sim_time('fs')).scaleb(-6)
    stop_ts_tod = tb.get_output_ts_tod_ns()
    stop_ts_rel = tb.get_output_ts_rel_ns()

    time_delta = stop_time-start_time
    ts_tod_delta = stop_ts_tod-start_ts_tod
    ts_rel_delta = stop_ts_rel-start_ts_rel

    tb.log.info("sim time delta : %s ns", time_delta)
    tb.log.info("ToD ts delta   : %s ns", ts_tod_delta)
    tb.log.info("Rel ts delta   : %s ns", ts_rel_delta)

    ts_tod_diff = time_delta - ts_tod_delta * Decimal(6.4/(6+(0x6666+20/5)/2**16))
    ts_rel_diff = time_delta - ts_rel_delta * Decimal(6.4/(6+(0x6666+20/5)/2**16))

    tb.log.info("ToD ts diff    : %s ns", ts_tod_diff)
    tb.log.info("Rel ts diff    : %s ns", ts_rel_diff)

    assert abs(ts_tod_diff) < 1e-3
    assert abs(ts_rel_diff) < 1e-3

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))
lib_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'lib'))
taxi_src_dir = os.path.abspath(os.path.join(lib_dir, 'taxi', 'src'))


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


def test_taxi_ptp_clock(request):
    dut = "taxi_ptp_clock"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.sv"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['PERIOD_NS_W'] = 4
    parameters['OFFSET_NS_W'] = 4
    parameters['FNS_W'] = 16
    parameters['PERIOD_NS_NUM'] = 32
    parameters['PERIOD_NS_DENOM'] = 5
    parameters['PIPELINE_OUTPUT'] = 0

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
