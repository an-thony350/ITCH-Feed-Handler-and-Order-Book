// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2018-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4 lite width adapter
 */
module taxi_axil_adapter
(
    input  wire logic    clk,
    input  wire logic    rst,

    /*
     * AXI4-Lite slave interface
     */
    taxi_axil_if.wr_slv  s_axil_wr,
    taxi_axil_if.rd_slv  s_axil_rd,

    /*
     * AXI4-Lite master interface
     */
    taxi_axil_if.wr_mst  m_axil_wr,
    taxi_axil_if.rd_mst  m_axil_rd
);

taxi_axil_adapter_wr
axil_adapter_wr_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Lite slave interface
     */
    .s_axil_wr(s_axil_wr),

    /*
     * AXI4-Lite master interface
     */
    .m_axil_wr(m_axil_wr)
);

taxi_axil_adapter_rd
axil_adapter_rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Lite slave interface
     */
    .s_axil_rd(s_axil_rd),

    /*
     * AXI4-Lite master interface
     */
    .m_axil_rd(m_axil_rd)
);

endmodule

`resetall
