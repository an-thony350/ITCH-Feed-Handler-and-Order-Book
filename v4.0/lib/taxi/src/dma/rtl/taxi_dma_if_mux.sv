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
 * DMA interface mux
 */
module taxi_dma_if_mux #
(
    // Number of ports
    parameter PORTS = 2,
    // select round robin arbitration
    parameter logic ARB_ROUND_ROBIN = 1'b0,
    // LSB priority selection
    parameter logic ARB_LSB_HIGH_PRIO = 1'b1
)
(
    input  wire logic         clk,
    input  wire logic         rst,

    /*
     * DMA descriptors from clients
     */
    taxi_dma_desc_if.req_snk  client_rd_req[PORTS],
    taxi_dma_desc_if.sts_src  client_rd_sts[PORTS],
    taxi_dma_desc_if.req_snk  client_wr_req[PORTS],
    taxi_dma_desc_if.sts_src  client_wr_sts[PORTS],

    /*
     * DMA descriptors to DMA engine
     */
    taxi_dma_desc_if.req_src  dma_rd_req,
    taxi_dma_desc_if.sts_snk  dma_rd_sts,
    taxi_dma_desc_if.req_src  dma_wr_req,
    taxi_dma_desc_if.sts_snk  dma_wr_sts,

    /*
     * RAM interface (from DMA interface)
     */
    taxi_dma_ram_if.wr_slv    dma_ram_wr,
    taxi_dma_ram_if.rd_slv    dma_ram_rd,

    /*
     * RAM interface (towards client RAMs)
     */
    taxi_dma_ram_if.wr_mst    client_ram_wr[PORTS],
    taxi_dma_ram_if.rd_mst    client_ram_rd[PORTS]
);

taxi_dma_if_mux_rd #(
    .PORTS(PORTS),
    .ARB_ROUND_ROBIN(ARB_ROUND_ROBIN),
    .ARB_LSB_HIGH_PRIO(ARB_LSB_HIGH_PRIO)
)
rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * DMA descriptors from clients
     */
    .client_req(client_rd_req),
    .client_sts(client_rd_sts),

    /*
     * DMA descriptors to DMA engines
     */
    .dma_req(dma_rd_req),
    .dma_sts(dma_rd_sts),

    /*
     * RAM interface (from DMA interface)
     */
    .dma_ram_wr(dma_ram_wr),

    /*
     * RAM interface (towards RAM)
     */
    .client_ram_wr(client_ram_wr)
);

taxi_dma_if_mux_wr #(
    .PORTS(PORTS),
    .ARB_ROUND_ROBIN(ARB_ROUND_ROBIN),
    .ARB_LSB_HIGH_PRIO(ARB_LSB_HIGH_PRIO)
)
wr_inst (
    .clk(clk),
    .rst(rst),

    /*
     * DMA descriptors from clients
     */
    .client_req(client_wr_req),
    .client_sts(client_wr_sts),

    /*
     * DMA descriptors to DMA engines
     */
    .dma_req(dma_wr_req),
    .dma_sts(dma_wr_sts),

    /*
     * RAM interface (from DMA interface)
     */
    .dma_ram_rd(dma_ram_rd),

    /*
     * RAM interface (towards RAM)
     */
    .client_ram_rd(client_ram_rd)
);

endmodule

`resetall
