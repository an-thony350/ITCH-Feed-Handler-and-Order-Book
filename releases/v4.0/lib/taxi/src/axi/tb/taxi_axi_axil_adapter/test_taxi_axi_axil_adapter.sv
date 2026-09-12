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
 * AXI4 to AXI4-Lite adapter testbench
 */
module test_taxi_axi_axil_adapter #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter ADDR_W = 32,
    parameter AXI_DATA_W = 32,
    parameter AXI_STRB_W = (AXI_DATA_W/8),
    parameter AXI_ID_W = 8,
    parameter AXIL_DATA_W = 32,
    parameter AXIL_STRB_W = (AXIL_DATA_W/8),
    parameter logic AWUSER_EN = 1'b0,
    parameter AWUSER_W = 1,
    parameter logic WUSER_EN = 1'b0,
    parameter WUSER_W = 1,
    parameter logic BUSER_EN = 1'b0,
    parameter BUSER_W = 1,
    parameter logic ARUSER_EN = 1'b0,
    parameter ARUSER_W = 1,
    parameter logic RUSER_EN = 1'b0,
    parameter RUSER_W = 1,
    parameter logic CONVERT_BURST = 1'b1,
    parameter logic CONVERT_NARROW_BURST = 1'b0
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axi_if #(
    .DATA_W(AXI_DATA_W),
    .ADDR_W(ADDR_W),
    .STRB_W(AXI_STRB_W),
    .ID_W(AXI_ID_W),
    .AWUSER_EN(AWUSER_EN),
    .AWUSER_W(AWUSER_W),
    .WUSER_EN(WUSER_EN),
    .WUSER_W(WUSER_W),
    .BUSER_EN(BUSER_EN),
    .BUSER_W(BUSER_W),
    .ARUSER_EN(ARUSER_EN),
    .ARUSER_W(ARUSER_W),
    .RUSER_EN(RUSER_EN),
    .RUSER_W(RUSER_W)
) s_axi();

taxi_axil_if #(
    .DATA_W(AXIL_DATA_W),
    .ADDR_W(ADDR_W),
    .STRB_W(AXIL_STRB_W),
    .AWUSER_EN(AWUSER_EN),
    .AWUSER_W(AWUSER_W),
    .WUSER_EN(WUSER_EN),
    .WUSER_W(WUSER_W),
    .BUSER_EN(BUSER_EN),
    .BUSER_W(BUSER_W),
    .ARUSER_EN(ARUSER_EN),
    .ARUSER_W(ARUSER_W),
    .RUSER_EN(RUSER_EN),
    .RUSER_W(RUSER_W)
) m_axil();

taxi_axi_axil_adapter #(
    .CONVERT_BURST(CONVERT_BURST),
    .CONVERT_NARROW_BURST(CONVERT_NARROW_BURST)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4 slave interface
     */
    .s_axi_wr(s_axi),
    .s_axi_rd(s_axi),

    /*
     * AXI4-Lite master interface
     */
    .m_axil_wr(m_axil),
    .m_axil_rd(m_axil)
);

endmodule

`resetall
