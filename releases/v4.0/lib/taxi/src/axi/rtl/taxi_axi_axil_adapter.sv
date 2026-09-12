// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2019-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4 to AXI4-Lite adapter
 */
module taxi_axi_axil_adapter #
(
    // When adapting to a wider bus, re-pack full-width burst instead of passing through narrow burst if possible
    parameter logic CONVERT_BURST = 1'b1,
    // When adapting to a wider bus, re-pack all bursts instead of passing through narrow burst if possible
    parameter logic CONVERT_NARROW_BURST = 1'b0
)
(
    input  wire logic    clk,
    input  wire logic    rst,

    /*
     * AXI4 slave interface
     */
    taxi_axi_if.wr_slv   s_axi_wr,
    taxi_axi_if.rd_slv   s_axi_rd,

    /*
     * AXI4-Lite master interface
     */
    taxi_axil_if.wr_mst  m_axil_wr,
    taxi_axil_if.rd_mst  m_axil_rd
);

taxi_axi_axil_adapter_wr #(
    .CONVERT_BURST(CONVERT_BURST),
    .CONVERT_NARROW_BURST(CONVERT_NARROW_BURST)
)
axi_axil_adapter_wr_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4 slave interface
     */
    .s_axi_wr(s_axi_wr),

    /*
     * AXI4-Lite master interface
     */
    .m_axil_wr(m_axil_wr)
);

taxi_axi_axil_adapter_rd #(
    .CONVERT_BURST(CONVERT_BURST),
    .CONVERT_NARROW_BURST(CONVERT_NARROW_BURST)
)
axi_axil_adapter_rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4 slave interface
     */
    .s_axi_rd(s_axi_rd),

    /*
     * AXI4-Lite master interface
     */
    .m_axil_rd(m_axil_rd)
);

endmodule

`resetall
