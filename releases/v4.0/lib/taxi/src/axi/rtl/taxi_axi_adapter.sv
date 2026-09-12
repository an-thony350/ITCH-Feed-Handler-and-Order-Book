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
 * AXI4 width adapter
 */
module taxi_axi_adapter #
(
    // When adapting to a wider bus, re-pack full-width burst instead of passing through narrow burst if possible
    parameter logic CONVERT_BURST = 1'b1,
    // When adapting to a wider bus, re-pack all bursts instead of passing through narrow burst if possible
    parameter logic CONVERT_NARROW_BURST = 1'b0
)
(
    input  wire logic   clk,
    input  wire logic   rst,

    /*
     * AXI4 slave interface
     */
    taxi_axi_if.wr_slv  s_axi_wr,
    taxi_axi_if.rd_slv  s_axi_rd,

    /*
     * AXI4 master interface
     */
    taxi_axi_if.wr_mst  m_axi_wr,
    taxi_axi_if.rd_mst  m_axi_rd
);

taxi_axi_adapter_wr #(
    .CONVERT_BURST(CONVERT_BURST),
    .CONVERT_NARROW_BURST(CONVERT_NARROW_BURST)
)
axi_adapter_wr_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4 slave interface
     */
    .s_axi_wr(s_axi_wr),

    /*
     * AXI4 master interface
     */
    .m_axi_wr(m_axi_wr)
);

taxi_axi_adapter_rd #(
    .CONVERT_BURST(CONVERT_BURST),
    .CONVERT_NARROW_BURST(CONVERT_NARROW_BURST)
)
axi_adapter_rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4 slave interface
     */
    .s_axi_rd(s_axi_rd),

    /*
     * AXI4 master interface
     */
    .m_axi_rd(m_axi_rd)
);

endmodule

`resetall
