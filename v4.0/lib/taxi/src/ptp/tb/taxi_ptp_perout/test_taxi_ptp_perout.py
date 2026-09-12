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

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

from cocotbext.eth import PtpClock


class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 6.4, units="ns").start())

        self.ptp_clock = PtpClock(
            ts_tod=dut.input_ts_tod,
            ts_step=dut.input_ts_tod_step,
            clock=dut.clk,
            reset=dut.rst,
            period_ns=6.4
        )

        dut.enable.setimmediatevalue(0)
        dut.input_start.setimmediatevalue(0)
        dut.input_start_valid.setimmediatevalue(0)
        dut.input_period.setimmediatevalue(0)
        dut.input_period_valid.setimmediatevalue(0)
        dut.input_width.setimmediatevalue(0)
        dut.input_width_valid.setimmediatevalue(0)

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
async def run_test(dut):

    tb = TB(dut)

    await tb.reset()

    dut.enable.value = 1

    await RisingEdge(dut.clk)

    dut.input_start.value = 100 << 16
    dut.input_start_valid.value = 1
    dut.input_period.value = 100 << 16
    dut.input_period_valid.value = 1
    dut.input_width.value = 50 << 16
    dut.input_width_valid.value = 1

    await RisingEdge(dut.clk)

    dut.input_start_valid.value = 0
    dut.input_period_valid.value = 0
    dut.input_width_valid.value = 0

    await Timer(10000, 'ns')

    await RisingEdge(dut.clk)

    dut.input_start.value = 0 << 16
    dut.input_start_valid.value = 1
    dut.input_period.value = 100 << 16
    dut.input_period_valid.value = 1
    dut.input_width.value = 50 << 16
    dut.input_width_valid.value = 1

    await RisingEdge(dut.clk)

    dut.input_start_valid.value = 0
    dut.input_period_valid.value = 0
    dut.input_width_valid.value = 0

    await Timer(10000, 'ns')

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


def test_taxi_ptp_perout(request):
    dut = "taxi_ptp_perout"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.sv"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['FNS_EN'] = "1'b1"
    parameters['OUT_START_S'] = 0
    parameters['OUT_START_NS'] = 0
    parameters['OUT_START_FNS'] = 0x0000
    parameters['OUT_PERIOD_S'] = 1
    parameters['OUT_PERIOD_NS'] = 0
    parameters['OUT_PERIOD_FNS'] = 0x0000
    parameters['OUT_WIDTH_S'] = 0
    parameters['OUT_WIDTH_NS'] = 1000
    parameters['OUT_WIDTH_FNS'] = 0x0000

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
