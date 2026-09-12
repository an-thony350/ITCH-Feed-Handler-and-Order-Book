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
 * AXI4 FIFO
 */
module taxi_axi_fifo #
(
    // Write data FIFO depth (cycles)
    parameter WRITE_FIFO_DEPTH = 32,
    // Read data FIFO depth (cycles)
    parameter READ_FIFO_DEPTH = 32,
    // Hold write address until write data in FIFO, if possible
    parameter logic WRITE_FIFO_DELAY = 1'b0,
    // Hold read address until space available in FIFO for data, if possible
    parameter logic READ_FIFO_DELAY = 1'b0
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

taxi_axi_fifo_wr #(
    .FIFO_DEPTH(WRITE_FIFO_DEPTH),
    .FIFO_DELAY(WRITE_FIFO_DELAY)
)
axi_fifo_wr_inst (
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

taxi_axi_fifo_rd #(
    .FIFO_DEPTH(READ_FIFO_DEPTH),
    .FIFO_DELAY(READ_FIFO_DELAY)
)
axi_fifo_rd_inst (
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
