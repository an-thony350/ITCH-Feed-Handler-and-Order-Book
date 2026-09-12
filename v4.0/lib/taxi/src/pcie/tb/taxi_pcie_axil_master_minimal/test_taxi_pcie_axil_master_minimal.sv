// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * PCIe AXI Lite Master (minimal) testbench
 */
module test_taxi_pcie_axil_master_minimal #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter TLP_SEG_DATA_W = 64,
    parameter TLP_SEGS = 1,
    parameter AXIL_DATA_W = 32,
    parameter AXIL_ADDR_W = 64,
    parameter logic TLP_FORCE_64_BIT_ADDR = 1'b0
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_pcie_tlp_if #(
    .SEGS(TLP_SEGS),
    .SEG_DATA_W(TLP_SEG_DATA_W),
    .FUNC_NUM_W(8)
) rx_req_tlp(), tx_cpl_tlp();

taxi_axil_if #(
    .DATA_W(AXIL_DATA_W),
    .ADDR_W(AXIL_ADDR_W),
    .AWUSER_EN(1'b0),
    .WUSER_EN(1'b0),
    .BUSER_EN(1'b0),
    .ARUSER_EN(1'b0),
    .RUSER_EN(1'b0)
) m_axil();

logic [7:0] bus_num;

logic stat_err_cor;
logic stat_err_uncor;

taxi_pcie_axil_master_minimal #(
    .TLP_FORCE_64_BIT_ADDR(TLP_FORCE_64_BIT_ADDR)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * TLP input (request)
     */
    .rx_req_tlp(rx_req_tlp),

    /*
     * TLP output (completion)
     */
    .tx_cpl_tlp(tx_cpl_tlp),

    /*
     * AXI Lite Master output
     */
    .m_axil_wr(m_axil),
    .m_axil_rd(m_axil),

    /*
     * Configuration
     */
    .bus_num(bus_num),

    /*
     * Status
     */
    .stat_err_cor(stat_err_cor),
    .stat_err_uncor(stat_err_uncor)
);

endmodule

`resetall
