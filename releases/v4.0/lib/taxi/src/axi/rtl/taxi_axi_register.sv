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
 * AXI4 register
 */
module taxi_axi_register #
(
    // AW channel register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter AW_REG_TYPE = 1,
    // W channel register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter W_REG_TYPE = 2,
    // B channel register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter B_REG_TYPE = 1,
    // AR channel register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter AR_REG_TYPE = 1,
    // R channel register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter R_REG_TYPE = 2
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

taxi_axi_register_wr #(
    .AW_REG_TYPE(AW_REG_TYPE),
    .W_REG_TYPE(W_REG_TYPE),
    .B_REG_TYPE(B_REG_TYPE)
)
axi_register_wr_inst (
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

taxi_axi_register_rd #(
    .AR_REG_TYPE(AR_REG_TYPE),
    .R_REG_TYPE(R_REG_TYPE)
)
axi_register_rd_inst (
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
