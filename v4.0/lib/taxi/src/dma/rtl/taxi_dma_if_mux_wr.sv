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
 * DMA interface mux (write)
 */
module taxi_dma_if_mux_wr #
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
    taxi_dma_desc_if.req_snk  client_req[PORTS],
    taxi_dma_desc_if.sts_src  client_sts[PORTS],

    /*
     * DMA descriptors to DMA engine
     */
    taxi_dma_desc_if.req_src  dma_req,
    taxi_dma_desc_if.sts_snk  dma_sts,

    /*
     * RAM interface (from DMA interface)
     */
    taxi_dma_ram_if.rd_slv    dma_ram_rd,

    /*
     * RAM interface (towards client RAMs)
     */
    taxi_dma_ram_if.rd_mst    client_ram_rd[PORTS]
);

// check configuration
if (dma_ram_rd.SEL_W != dma_req.SRC_SEL_W)
    $error("Error: Select signal width mismatch (instance %m)");

if (!dma_req.SRC_SEL_EN)
    $error("Error: Select signal must be enabled (instance %m)");

taxi_dma_desc_mux #(
    .PORTS(PORTS),
    .EXTEND_SEL(1),
    .ARB_ROUND_ROBIN(ARB_ROUND_ROBIN),
    .ARB_LSB_HIGH_PRIO(ARB_LSB_HIGH_PRIO)
)
desc_mux_inst (
    .clk(clk),
    .rst(rst),

    /*
     * DMA descriptors from clients
     */
    .client_req(client_req),
    .client_sts(client_sts),

    /*
     * DMA descriptors to DMA engines
     */
    .dma_req(dma_req),
    .dma_sts(dma_sts)
);

taxi_dma_ram_demux_rd #(
    .PORTS(PORTS)
)
ram_demux_inst (
    .clk(clk),
    .rst(rst),

    /*
     * RAM interface (from DMA client/interface)
     */
    .dma_ram_rd(dma_ram_rd),

    /*
     * RAM interface (towards RAM)
     */
    .ram_rd(client_ram_rd)
);

endmodule

`resetall
