// SPDX-License-Identifier: MIT
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

interface taxi_axis_if #(
    // Width of AXI stream interfaces in bits
    parameter DATA_W = 8,
    // tkeep signal width (bytes per cycle)
    parameter KEEP_W = ((DATA_W+7)/8),
    // Use tkeep signal
    parameter logic KEEP_EN = KEEP_W > 1,
    // Use tstrb signal
    parameter logic STRB_EN = 1'b0,
    // Use tlast signal
    parameter logic LAST_EN = 1'b1,
    // Use tid signal
    parameter logic ID_EN = 0,
    // tid signal width
    parameter ID_W = 8,
    // Use tdest signal
    parameter logic DEST_EN = 0,
    // tdest signal width
    parameter DEST_W = 8,
    // Use tuser signal
    parameter logic USER_EN = 0,
    // tuser signal width
    parameter USER_W = 1
)
();
    logic [DATA_W-1:0] tdata;
    logic [KEEP_W-1:0] tkeep;
    logic [KEEP_W-1:0] tstrb;
    logic [ID_W-1:0] tid;
    logic [DEST_W-1:0] tdest;
    logic [USER_W-1:0] tuser;
    logic tlast;
    logic tvalid;
    logic tready;

    modport src (
        output tdata,
        output tkeep,
        output tstrb,
        output tid,
        output tdest,
        output tuser,
        output tlast,
        output tvalid,
        input  tready
    );

    modport snk (
        input  tdata,
        input  tkeep,
        input  tstrb,
        input  tid,
        input  tdest,
        input  tuser,
        input  tlast,
        input  tvalid,
        output tready
    );

    modport mon (
        input  tdata,
        input  tkeep,
        input  tstrb,
        input  tid,
        input  tdest,
        input  tuser,
        input  tlast,
        input  tvalid,
        input  tready
    );

endinterface
