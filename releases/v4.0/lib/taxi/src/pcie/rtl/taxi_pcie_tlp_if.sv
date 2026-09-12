// SPDX-License-Identifier: MIT
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

interface taxi_pcie_tlp_if #(
    parameter SEGS = 1,
    parameter SEG_DATA_W = 256,
    parameter SEG_EMPTY_W = $clog2(SEG_DATA_W/32),
    parameter HDR_W = 128,
    parameter FUNC_NUM_W = 8,
    parameter SEQ_NUM_W = 6
)
();
    logic [SEGS-1:0][SEG_DATA_W-1:0]   data;
    logic [SEGS-1:0][SEG_EMPTY_W-1:0]  empty;
    logic [SEGS-1:0][HDR_W-1:0]        hdr;
    logic [SEGS-1:0][SEQ_NUM_W-1:0]    seq;
    logic [SEGS-1:0][2:0]              bar_id;
    logic [SEGS-1:0][FUNC_NUM_W-1:0]   func_num;
    logic [SEGS-1:0][3:0]              error;
    logic [SEGS-1:0]                   valid;
    logic [SEGS-1:0]                   sop;
    logic [SEGS-1:0]                   eop;
    logic                              ready;

    modport src (
        output data,
        output empty,
        output hdr,
        output seq,
        output bar_id,
        output func_num,
        output error,
        output valid,
        output sop,
        output eop,
        input  ready
    );

    modport snk (
        input  data,
        input  empty,
        input  hdr,
        input  seq,
        input  bar_id,
        input  func_num,
        input  error,
        input  valid,
        input  sop,
        input  eop,
        output ready
    );

    modport mon (
        input  data,
        input  empty,
        input  hdr,
        input  seq,
        input  bar_id,
        input  func_num,
        input  error,
        input  valid,
        input  sop,
        input  eop,
        input  ready
    );

endinterface
