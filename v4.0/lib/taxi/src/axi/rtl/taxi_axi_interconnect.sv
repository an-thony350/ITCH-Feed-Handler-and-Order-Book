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
 * AXI4 interconnect
 */
module taxi_axi_interconnect #
(
    // Number of AXI inputs (slave interfaces)
    parameter S_COUNT = 4,
    // Number of AXI outputs (master interfaces)
    parameter M_COUNT = 4,
    // Address width in bits for address decoding
    parameter ADDR_W = 32,
    // TODO fix parametrization once verilator issue 5890 is fixed
    // Number of regions per master interface
    parameter M_REGIONS = 1,
    // Master interface base addresses
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of ADDR_W bits
    // set to zero for default addressing based on M_ADDR_W
    parameter M_BASE_ADDR = '0,
    // Master interface address widths
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of 32 bits
    parameter M_ADDR_W = {M_COUNT{{M_REGIONS{32'd24}}}},
    // Read connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT_RD = {M_COUNT{{S_COUNT{1'b1}}}},
    // Write connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT_WR = {M_COUNT{{S_COUNT{1'b1}}}},
    // Secure master (fail operations based on awprot/arprot)
    // M_COUNT bits
    parameter M_SECURE = {M_COUNT{1'b0}}
)
(
    input  wire logic   clk,
    input  wire logic   rst,

    /*
     * AXI4 slave interfaces
     */
    taxi_axi_if.wr_slv  s_axi_wr[S_COUNT],
    taxi_axi_if.rd_slv  s_axi_rd[S_COUNT],

    /*
     * AXI4 master interfaces
     */
    taxi_axi_if.wr_mst  m_axi_wr[M_COUNT],
    taxi_axi_if.rd_mst  m_axi_rd[M_COUNT]
);

taxi_axi_interconnect_wr #(
    .S_COUNT(S_COUNT),
    .M_COUNT(M_COUNT),
    .ADDR_W(ADDR_W),
    .M_REGIONS(M_REGIONS),
    .M_BASE_ADDR(M_BASE_ADDR),
    .M_ADDR_W(M_ADDR_W),
    .M_CONNECT(M_CONNECT_WR),
    .M_SECURE(M_SECURE)
)
wr_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4 slave interfaces
     */
    .s_axi_wr(s_axi_wr),

    /*
     * AXI4 master interfaces
     */
    .m_axi_wr(m_axi_wr)
);

taxi_axi_interconnect_rd #(
    .S_COUNT(S_COUNT),
    .M_COUNT(M_COUNT),
    .ADDR_W(ADDR_W),
    .M_REGIONS(M_REGIONS),
    .M_BASE_ADDR(M_BASE_ADDR),
    .M_ADDR_W(M_ADDR_W),
    .M_CONNECT(M_CONNECT_RD),
    .M_SECURE(M_SECURE)
)
rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4 slave interfaces
     */
    .s_axi_rd(s_axi_rd),

    /*
     * AXI4 master interfaces
     */
    .m_axi_rd(m_axi_rd)
);

endmodule

`resetall
