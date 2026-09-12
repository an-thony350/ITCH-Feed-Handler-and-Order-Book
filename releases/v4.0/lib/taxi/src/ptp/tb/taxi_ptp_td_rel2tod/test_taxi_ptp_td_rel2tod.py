#!/usr/bin/env python
# SPDX-License-Identifier: CERN-OHL-S-2.0
"""

Copyright (c) 2024-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

"""

import logging
import os
import sys
from decimal import Decimal

import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from cocotbext.axi import AxiStreamBus, AxiStreamFrame, AxiStreamSource, AxiStreamSink

try:
    from ptp_td import PtpTdSource
except ImportError:
    # attempt import from current directory
    sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
    try:
        from ptp_td import PtpTdSource
    finally:
        del sys.path[0]


class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.ptp_clk, 6.4, units="ns").start())
        cocotb.start_soon(Clock(dut.clk, 6.4, units="ns").start())

        self.ptp_td_source = PtpTdSource(
            data=dut.ptp_td_sdi,
            clock=dut.ptp_clk,
            reset=dut.ptp_rst,
            period_ns=6.4
        )

        self.ts_source = AxiStreamSource(AxiStreamBus.from_entity(dut.s_axis_ts_rel), dut.clk, dut.rst)
        self.ts_sink = AxiStreamSink(AxiStreamBus.from_entity(dut.m_axis_ts_tod), dut.clk, dut.rst)

    async def reset(self):
        self.dut.ptp_rst.setimmediatevalue(0)
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.ptp_clk)
        await RisingEdge(self.dut.ptp_clk)
        self.dut.ptp_rst.value = 1
        self.dut.rst.value = 1
        for k in range(10):
            await RisingEdge(self.dut.ptp_clk)
        self.dut.ptp_rst.value = 0
        self.dut.rst.value = 0
        for k in range(10):
            await RisingEdge(self.dut.ptp_clk)


@cocotb.test()
async def run_test(dut):

    tb = TB(dut)

    await tb.reset()

    for start_rel, start_tod in [
                ('1234', '123456789.987654321'),
                ('1234', '123456788.987654321'),
                ('1234.9', '123456789.987654321'),
                ('1234.9', '123456788.987654321'),
                ('1234', '123456789.907654321'),
                ('1234', '123456788.907654321'),
                ('1234.9', '123456789.907654321'),
                ('1234.9', '123456788.907654321'),
            ]:

        tb.log.info(f"Start rel ts: {start_rel} ns")
        tb.log.info(f"Start ToD ts: {start_tod} ns")

        tb.ptp_td_source.set_ts_rel_s(start_rel)
        tb.ptp_td_source.set_ts_tod_s(start_tod)

        for k in range(256*6):
            await RisingEdge(dut.clk)

        for offset in ['0', '0.05', '-0.9']:

            tb.log.info(f"Offset {offset} sec")
            ts_rel = tb.ptp_td_source.get_ts_rel_ns()
            ts_tod = tb.ptp_td_source.get_ts_tod_ns()

            tb.log.info(f"Current rel ts: {ts_rel} ns")
            tb.log.info(f"Current ToD ts: {ts_tod} ns")

            ts_rel += Decimal(offset).scaleb(9)
            ts_tod += Decimal(offset).scaleb(9)
            rel = int(ts_rel*2**16) & 0xffffffffffff

            tb.log.info(f"Input rel ts: {ts_rel} ns")
            tb.log.info(f"Input ToD ts: {ts_tod} ns")
            tb.log.info(f"Input relative ts raw: {rel} ({rel:#x})")

            await tb.ts_source.send(AxiStreamFrame(tdata=[rel], tid=0))
            out_ts = await tb.ts_sink.recv()

            tod = out_ts.tdata[0]
            tb.log.info(f"Output ToD ts raw: {tod} ({tod:#x})")
            ns = Decimal(tod & 0xffff) / Decimal(2**16)
            ns = tb.ptp_td_source.ctx.add(ns, Decimal((tod >> 16) & 0xffffffff))
            tod = tb.ptp_td_source.ctx.add(ns, Decimal(tod >> 48).scaleb(9))
            tb.log.info(f"Output ToD ts: {tod} ns")

            tb.log.info(f"Output ns portion only: {ns} ns")

            diff = tod - ts_tod
            tb.log.info(f"Difference: {diff} ns")

            assert abs(diff) < 1e-3
            assert ns < 1000000000

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


def test_taxi_ptp_td_rel2tod(request):
    dut = "taxi_ptp_td_rel2tod"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = module

    verilog_sources = [
        os.path.join(tests_dir, f"{toplevel}.sv"),
        os.path.join(rtl_dir, f"{dut}.sv"),
        os.path.join(taxi_src_dir, "axis", "rtl", "taxi_axis_if.sv"),
    ]

    verilog_sources = process_f_files(verilog_sources)

    parameters = {}

    parameters['TS_FNS_W'] = 16
    parameters['TS_REL_NS_W'] = 32
    parameters['TS_TOD_S_W'] = 48
    parameters['TD_SDI_PIPELINE'] = 2

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
