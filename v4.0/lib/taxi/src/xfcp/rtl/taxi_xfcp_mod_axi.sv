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
 * XFCP AXI module
 */
module taxi_xfcp_mod_axi #
(
    parameter logic [15:0] XFCP_ID_TYPE = 16'h8001,
    parameter XFCP_ID_STR = "AXI Master",
    parameter logic [8*16-1:0] XFCP_EXT_ID = 0,
    parameter XFCP_EXT_ID_STR = "",
    parameter COUNT_SIZE = 16
)
(
    input  wire logic   clk,
    input  wire logic   rst,

    /*
     * XFCP upstream port
     */
    taxi_axis_if.snk    xfcp_usp_ds,
    taxi_axis_if.src    xfcp_usp_us,

    /*
     * AXI master interface
     */
    taxi_axi_if.wr_mst  m_axi_wr,
    taxi_axi_if.rd_mst  m_axi_rd
);

taxi_axil_if #(
    .DATA_W(m_axi_wr.DATA_W),
    .ADDR_W(m_axi_wr.ADDR_W),
    .STRB_W(m_axi_wr.STRB_W)
) axil_if();

// AW
assign m_axi_wr.awid = '0;
assign m_axi_wr.awaddr = axil_if.awaddr;
assign m_axi_wr.awlen = '0;
assign m_axi_wr.awsize = 3'($clog2(m_axi_wr.STRB_W));
assign m_axi_wr.awburst = 2'b01;
assign m_axi_wr.awlock = 1'b0;
assign m_axi_wr.awcache = 4'b0011;
assign m_axi_wr.awprot = axil_if.awprot;
assign m_axi_wr.awqos = 4'd0;
assign m_axi_wr.awregion = 4'd0;
assign m_axi_wr.awuser = axil_if.awuser;
assign m_axi_wr.awvalid = axil_if.awvalid;
assign axil_if.awready = m_axi_wr.awready;
// W
assign m_axi_wr.wdata = axil_if.wdata;
assign m_axi_wr.wstrb = axil_if.wstrb;
assign m_axi_wr.wlast = 1'b1;
assign m_axi_wr.wuser = axil_if.wuser;
assign m_axi_wr.wvalid = axil_if.wvalid;
assign axil_if.wready = m_axi_wr.wready;
// B
assign axil_if.bresp = m_axi_wr.bresp;
assign axil_if.buser = m_axi_wr.buser;
assign axil_if.bvalid = m_axi_wr.bvalid;
assign m_axi_wr.bready = axil_if.bready;
// AR
assign m_axi_rd.arid = '0;
assign m_axi_rd.araddr = axil_if.araddr;
assign m_axi_rd.arlen = '0;
assign m_axi_rd.arsize = 3'($clog2(m_axi_wr.STRB_W));
assign m_axi_rd.arburst = 2'b01;
assign m_axi_rd.arlock = 1'b0;
assign m_axi_rd.arcache = 4'b0011;
assign m_axi_rd.arprot = axil_if.arprot;
assign m_axi_rd.arqos = 4'd0;
assign m_axi_rd.arregion = 4'd0;
assign m_axi_rd.aruser = axil_if.aruser;
assign m_axi_rd.arvalid = axil_if.arvalid;
assign axil_if.arready = m_axi_rd.arready;
// R
assign axil_if.rdata = m_axi_rd.rdata;
assign axil_if.rresp = m_axi_rd.rresp;
assign axil_if.ruser = m_axi_rd.ruser;
assign axil_if.rvalid = m_axi_rd.rvalid;
assign m_axi_rd.rready = axil_if.rready;

taxi_xfcp_mod_axil #(
    .XFCP_ID_TYPE(XFCP_ID_TYPE),
    .XFCP_ID_STR(XFCP_ID_STR),
    .XFCP_EXT_ID(XFCP_EXT_ID),
    .XFCP_EXT_ID_STR(XFCP_EXT_ID_STR),
    .COUNT_SIZE(COUNT_SIZE)
)
xfcp_mod_axil_inst (
    .clk(clk),
    .rst(rst),

    /*
     * XFCP upstream port
     */
    .xfcp_usp_ds(xfcp_usp_ds),
    .xfcp_usp_us(xfcp_usp_us),

    /*
     * AXI lite master interface
     */
    .m_axil_wr(axil_if),
    .m_axil_rd(axil_if)
);

endmodule

`resetall
