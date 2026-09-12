// SPDX-License-Identifier: MIT
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

interface taxi_axi_if #(
    // Width of data bus in bits
    parameter DATA_W = 32,
    // Width of address bus in bits
    parameter ADDR_W = 32,
    // Width of wstrb (width of data bus in words)
    parameter STRB_W = (DATA_W/8),
    // Width of ID signal
    parameter ID_W = 8,
    // Use awuser signal
    parameter logic AWUSER_EN = 1'b0,
    // Width of awuser signal
    parameter AWUSER_W = 1,
    // Use wuser signal
    parameter logic WUSER_EN = 1'b0,
    // Width of wuser signal
    parameter WUSER_W = 1,
    // Use buser signal
    parameter logic BUSER_EN = 1'b0,
    // Width of buser signal
    parameter BUSER_W = 1,
    // Use aruser signal
    parameter logic ARUSER_EN = 1'b0,
    // Width of aruser signal
    parameter ARUSER_W = 1,
    // Use ruser signal
    parameter logic RUSER_EN = 1'b0,
    // Width of ruser signal
    parameter RUSER_W = 1,
    // Maximum AXI burst length supported
    parameter MAX_BURST_LEN = 256,
    // Narrow bursts are supported
    parameter logic NARROW_BURST_EN = 1'b1
)
();
    // AW
    logic [ID_W-1:0]      awid;
    logic [ADDR_W-1:0]    awaddr;
    logic [7:0]           awlen;
    logic [2:0]           awsize;
    logic [1:0]           awburst;
    logic                 awlock;
    logic [3:0]           awcache;
    logic [2:0]           awprot;
    logic [3:0]           awqos;
    logic [3:0]           awregion;
    logic [AWUSER_W-1:0]  awuser;
    logic                 awvalid;
    logic                 awready;
    // W
    logic [DATA_W-1:0]    wdata;
    logic [STRB_W-1:0]    wstrb;
    logic                 wlast;
    logic [WUSER_W-1:0]   wuser;
    logic                 wvalid;
    logic                 wready;
    // B
    logic [ID_W-1:0]      bid;
    logic [1:0]           bresp;
    logic [BUSER_W-1:0]   buser;
    logic                 bvalid;
    logic                 bready;
    // AR
    logic [ID_W-1:0]      arid;
    logic [ADDR_W-1:0]    araddr;
    logic [7:0]           arlen;
    logic [2:0]           arsize;
    logic [1:0]           arburst;
    logic                 arlock;
    logic [3:0]           arcache;
    logic [2:0]           arprot;
    logic [3:0]           arqos;
    logic [3:0]           arregion;
    logic [ARUSER_W-1:0]  aruser;
    logic                 arvalid;
    logic                 arready;
    // R
    logic [ID_W-1:0]      rid;
    logic [DATA_W-1:0]    rdata;
    logic [1:0]           rresp;
    logic                 rlast;
    logic [RUSER_W-1:0]   ruser;
    logic                 rvalid;
    logic                 rready;

    modport wr_mst (
        // AW
        output awid,
        output awaddr,
        output awlen,
        output awsize,
        output awburst,
        output awlock,
        output awcache,
        output awprot,
        output awqos,
        output awregion,
        output awuser,
        output awvalid,
        input  awready,
        // W
        output wdata,
        output wstrb,
        output wlast,
        output wuser,
        output wvalid,
        input  wready,
        // B
        input  bid,
        input  bresp,
        input  buser,
        input  bvalid,
        output bready
    );

    modport rd_mst (
        // AR
        output arid,
        output araddr,
        output arlen,
        output arsize,
        output arburst,
        output arlock,
        output arcache,
        output arprot,
        output arqos,
        output arregion,
        output aruser,
        output arvalid,
        input  arready,
        // R
        input  rid,
        input  rdata,
        input  rresp,
        input  rlast,
        input  ruser,
        input  rvalid,
        output rready
    );

    modport wr_slv (
        // AW
        input  awid,
        input  awaddr,
        input  awlen,
        input  awsize,
        input  awburst,
        input  awlock,
        input  awcache,
        input  awprot,
        input  awqos,
        input  awregion,
        input  awuser,
        input  awvalid,
        output awready,
        // W
        input  wdata,
        input  wstrb,
        input  wlast,
        input  wuser,
        input  wvalid,
        output wready,
        // B
        output bid,
        output bresp,
        output buser,
        output bvalid,
        input  bready
    );

    modport rd_slv (
        // AR
        input  arid,
        input  araddr,
        input  arlen,
        input  arsize,
        input  arburst,
        input  arlock,
        input  arcache,
        input  arprot,
        input  arqos,
        input  arregion,
        input  aruser,
        input  arvalid,
        output arready,
        // R
        output rid,
        output rdata,
        output rresp,
        output rlast,
        output ruser,
        output rvalid,
        input  rready
    );

    modport wr_mon (
        // AW
        input  awid,
        input  awaddr,
        input  awlen,
        input  awsize,
        input  awburst,
        input  awlock,
        input  awcache,
        input  awprot,
        input  awqos,
        input  awregion,
        input  awuser,
        input  awvalid,
        input  awready,
        // W
        input  wdata,
        input  wstrb,
        input  wlast,
        input  wuser,
        input  wvalid,
        input  wready,
        // B
        input  bid,
        input  bresp,
        input  buser,
        input  bvalid,
        input  bready
    );

    modport rd_mon (
        // AR
        input  arid,
        input  araddr,
        input  arlen,
        input  arsize,
        input  arburst,
        input  arlock,
        input  arcache,
        input  arprot,
        input  arqos,
        input  arregion,
        input  aruser,
        input  arvalid,
        input  arready,
        // R
        input  rid,
        input  rdata,
        input  rresp,
        input  rlast,
        input  ruser,
        input  rvalid,
        input  rready
    );

endinterface
