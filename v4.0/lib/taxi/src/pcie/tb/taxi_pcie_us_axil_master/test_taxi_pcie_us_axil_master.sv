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
 * UltraScale PCIe AXI Lite Master testbench
 */
module test_taxi_pcie_us_axil_master #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter AXIS_PCIE_DATA_W = 64,
    parameter AXIS_PCIE_CQ_USER_W = AXIS_PCIE_DATA_W < 512 ? 85 : 183,
    parameter AXIS_PCIE_CC_USER_W = AXIS_PCIE_DATA_W < 512 ? 33 : 81,
    parameter AXIL_DATA_W = 32,
    parameter AXIL_ADDR_W = 64
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam AXIS_PCIE_KEEP_W = (AXIS_PCIE_DATA_W/32);

logic clk;
logic rst;

taxi_axis_if #(
    .DATA_W(AXIS_PCIE_DATA_W),
    .KEEP_EN(1),
    .KEEP_W(AXIS_PCIE_KEEP_W),
    .USER_EN(1),
    .USER_W(AXIS_PCIE_CQ_USER_W)
) s_axis_cq();

taxi_axis_if #(
    .DATA_W(AXIS_PCIE_DATA_W),
    .KEEP_EN(1),
    .KEEP_W(AXIS_PCIE_KEEP_W),
    .USER_EN(1),
    .USER_W(AXIS_PCIE_CC_USER_W)
) m_axis_cc();

taxi_axil_if #(
    .DATA_W(AXIL_DATA_W),
    .ADDR_W(AXIL_ADDR_W),
    .AWUSER_EN(1'b0),
    .WUSER_EN(1'b0),
    .BUSER_EN(1'b0),
    .ARUSER_EN(1'b0),
    .RUSER_EN(1'b0)
) m_axil();

logic [15:0] completer_id;
logic completer_id_en;

logic stat_err_cor;
logic stat_err_uncor;

taxi_pcie_us_axil_master
uut (
    .clk(clk),
    .rst(rst),

    /*
     * UltraScale PCIe interface
     */
    .s_axis_cq(s_axis_cq),
    .m_axis_cc(m_axis_cc),

    /*
     * AXI Lite Master output
     */
    .m_axil_wr(m_axil),
    .m_axil_rd(m_axil),

    /*
     * Configuration
     */
    .completer_id(completer_id),
    .completer_id_en(completer_id_en),

    /*
     * Status
     */
    .stat_err_cor(stat_err_cor),
    .stat_err_uncor(stat_err_uncor)
);

endmodule

`resetall
