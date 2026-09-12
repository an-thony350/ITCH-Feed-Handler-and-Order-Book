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
 * AXI4 lite to AXI4 adapter
 */
module taxi_axil_axi_adapter
(
    input  wire logic    clk,
    input  wire logic    rst,

    /*
     * AXI4 lite slave interface
     */
    taxi_axil_if.wr_slv  s_axil_wr,
    taxi_axil_if.rd_slv  s_axil_rd,

    /*
     * AXI4 master interface
     */
    taxi_axi_if.wr_mst   m_axi_wr,
    taxi_axi_if.rd_mst   m_axi_rd
);

taxi_axil_axi_adapter_wr
axil_axi_adapter_wr_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4 lite slave interface
     */
    .s_axil_wr(s_axil_wr),

    /*
     * AXI4 master interface
     */
    .m_axi_wr(m_axi_wr)
);

taxi_axil_axi_adapter_rd
axil_axi_adapter_rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4 lite slave interface
     */
    .s_axil_rd(s_axil_rd),

    /*
     * AXI4 master interface
     */
    .m_axi_rd(m_axi_rd)
);

endmodule

`resetall
