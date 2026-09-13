// SPDX-License-Identifier: MIT
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream null source
 */
module taxi_axis_null_src
(
    /*
     * AXI4-Stream output (source)
     */
    taxi_axis_if.src  m_axis
);

assign m_axis.tdata  = '0;
assign m_axis.tkeep  = '1;
assign m_axis.tstrb  = m_axis.tkeep;
assign m_axis.tvalid = 1'b0;
assign m_axis.tlast  = 1'b1;
assign m_axis.tid    = '0;
assign m_axis.tdest  = '0;
assign m_axis.tuser  = '0;

endmodule

`resetall
