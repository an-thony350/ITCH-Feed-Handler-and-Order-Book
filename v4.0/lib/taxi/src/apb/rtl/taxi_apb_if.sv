// SPDX-License-Identifier: MIT
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

interface taxi_apb_if #(
    // Width of data bus in bits
    parameter DATA_W = 32,
    // Width of address bus in bits
    parameter ADDR_W = 32,
    // Width of pstrb (width of data bus in words)
    parameter STRB_W = (DATA_W/8),
    // Use pauser signal
    parameter logic PAUSER_EN = 1'b0,
    // Width of pauser signal
    parameter PAUSER_W = 1,
    // Use pwuser signal
    parameter logic PWUSER_EN = 1'b0,
    // Width of pwuser signal
    parameter PWUSER_W = 1,
    // Use pruser signal
    parameter logic PRUSER_EN = 1'b0,
    // Width of pruser signal
    parameter PRUSER_W = 1,
    // Use pbuser signal
    parameter logic PBUSER_EN = 1'b0,
    // Width of pbuser signal
    parameter PBUSER_W = 1
)
();
    logic [ADDR_W-1:0]    paddr;
    logic [2:0]           pprot;
    logic                 psel;
    logic                 penable;
    logic                 pwrite;
    logic [DATA_W-1:0]    pwdata;
    logic [STRB_W-1:0]    pstrb;
    logic                 pready;
    logic [DATA_W-1:0]    prdata;
    logic                 pslverr;
    logic [PAUSER_W-1:0]  pauser;
    logic [PWUSER_W-1:0]  pwuser;
    logic [PRUSER_W-1:0]  pruser;
    logic [PBUSER_W-1:0]  pbuser;

    modport mst (
        output paddr,
        output pprot,
        output psel,
        output penable,
        output pwrite,
        output pwdata,
        output pstrb,
        input  pready,
        input  prdata,
        input  pslverr,
        output pauser,
        output pwuser,
        input  pruser,
        input  pbuser
    );

    modport slv (
        input  paddr,
        input  pprot,
        input  psel,
        input  penable,
        input  pwrite,
        input  pwdata,
        input  pstrb,
        output pready,
        output prdata,
        output pslverr,
        input  pauser,
        input  pwuser,
        output pruser,
        output pbuser
    );

endinterface
