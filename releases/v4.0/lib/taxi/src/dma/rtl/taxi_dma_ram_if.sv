// SPDX-License-Identifier: MIT
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

interface taxi_dma_ram_if #(
    // RAM segment count
    parameter SEGS = 2,
    // RAM segment address width
    parameter SEG_ADDR_W = 10,
    // RAM segment data width
    parameter SEG_DATA_W = 128,
    // RAM segment byte enable width
    parameter SEG_BE_W = SEG_DATA_W/8,
    // RAM select signal
    parameter SEL_W = 2
)
();
    logic [SEGS-1:0][SEL_W-1:0]       wr_cmd_sel;
    logic [SEGS-1:0][SEG_ADDR_W-1:0]  wr_cmd_addr;
    logic [SEGS-1:0][SEG_DATA_W-1:0]  wr_cmd_data;
    logic [SEGS-1:0][SEG_BE_W-1:0]    wr_cmd_be;
    logic [SEGS-1:0]                  wr_cmd_valid;
    logic [SEGS-1:0]                  wr_cmd_ready;
    logic [SEGS-1:0]                  wr_done;

    logic [SEGS-1:0][SEL_W-1:0]       rd_cmd_sel;
    logic [SEGS-1:0][SEG_ADDR_W-1:0]  rd_cmd_addr;
    logic [SEGS-1:0]                  rd_cmd_valid;
    logic [SEGS-1:0]                  rd_cmd_ready;
    logic [SEGS-1:0][SEG_DATA_W-1:0]  rd_resp_data;
    logic [SEGS-1:0]                  rd_resp_valid;
    logic [SEGS-1:0]                  rd_resp_ready;

    modport wr_mst (
        output wr_cmd_sel,
        output wr_cmd_addr,
        output wr_cmd_data,
        output wr_cmd_be,
        output wr_cmd_valid,
        input  wr_cmd_ready,
        input  wr_done
    );

    modport rd_mst (
        output rd_cmd_sel,
        output rd_cmd_addr,
        output rd_cmd_valid,
        input  rd_cmd_ready,
        input  rd_resp_data,
        input  rd_resp_valid,
        output rd_resp_ready
    );

    modport wr_slv (
        input  wr_cmd_sel,
        input  wr_cmd_addr,
        input  wr_cmd_data,
        input  wr_cmd_be,
        input  wr_cmd_valid,
        output wr_cmd_ready,
        output wr_done
    );

    modport rd_slv (
        input  rd_cmd_sel,
        input  rd_cmd_addr,
        input  rd_cmd_valid,
        output rd_cmd_ready,
        output rd_resp_data,
        output rd_resp_valid,
        input  rd_resp_ready
    );

endinterface
