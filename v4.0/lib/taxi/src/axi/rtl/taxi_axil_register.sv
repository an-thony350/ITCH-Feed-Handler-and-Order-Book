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
 * AXI4 lite register
 */
module taxi_axil_register #
(
    // AW channel register type
    // 0 to bypass, 1 for simple buffer
    parameter AW_REG_TYPE = 1,
    // W channel register type
    // 0 to bypass, 1 for simple buffer
    parameter W_REG_TYPE = 1,
    // B channel register type
    // 0 to bypass, 1 for simple buffer
    parameter B_REG_TYPE = 1,
    // AR channel register type
    // 0 to bypass, 1 for simple buffer
    parameter AR_REG_TYPE = 1,
    // R channel register type
    // 0 to bypass, 1 for simple buffer
    parameter R_REG_TYPE = 1
)
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

taxi_axil_register_wr #(
    .AW_REG_TYPE(AW_REG_TYPE),
    .W_REG_TYPE(W_REG_TYPE),
    .B_REG_TYPE(B_REG_TYPE)
)
axil_register_wr_inst (
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

taxi_axil_register_rd #(
    .AR_REG_TYPE(AR_REG_TYPE),
    .R_REG_TYPE(R_REG_TYPE)
)
axil_register_rd_inst (
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
