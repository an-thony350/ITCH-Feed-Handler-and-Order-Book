`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 03.09.2026 00:33:56
// Design Name: URAM Block
// Module Name: ob_uram_block
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module acts as our URAM synthesiser
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Read latency included, acting as a delay stage to ensure reads
//                 are synchronised at correct stage in pipeline
// Revision 0.03 - extra signal added allowing for stall reads - overall synchronsing
// Revision 0.04 - WNS fixes
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
import hdl_header::*;

module ob_uram_block #(
    parameter int   ADDRESS_W,
    parameter int   DATA_W,
    parameter int   READ_LATENCY = 3
)(
    // Control Signals
    input logic                     clk,
    input logic                     rst_n,
    input logic                     stall,

    // Read ports
    input  logic [ADDRESS_W-1:0]    rd_addr_a,
    output logic [DATA_W-1:0]       rd_data_a,
    output logic [DATA_W-1:0]       bbo_rd_data_a,

    // Write ports
    input logic                     wr_we_a,
    input logic  [ADDRESS_W-1:0]    wr_addr_a,
    input logic  [DATA_W-1:0]       wr_data_a
);

// Local Parameters determining uram size
localparam int URAM_DEPTH = 1 << ADDRESS_W;

// Internal registers

logic [DATA_W-1:0] ram_q;
logic [DATA_W-1:0] held_q;
logic              stall_q;
logic [DATA_W-1:0] slot0;

// BRAM block
(* ram_style = "ultra", cascade_height = 1 *) logic [DATA_W-1:0] uram [URAM_DEPTH-1:0];

// DELAY BUFFERS (for latency writes)
logic [DATA_W-1:0] rd_buffer    [READ_LATENCY-1:1];
logic [DATA_W-1:0] bbo_buffer   [READ_LATENCY-1:1];

always_ff @(posedge clk) begin
    if (wr_we_a) uram[wr_addr_a] <= wr_data_a;
    ram_q <= uram[rd_addr_a];
end

always_ff @(posedge clk) begin
    if (!rst_n) stall_q <= 1'b0;
    else        stall_q <= stall;
end

always_ff @(posedge clk) begin
    if (!stall_q) held_q <= ram_q;
end

assign slot0 = stall_q ? held_q : ram_q;

always_ff @(posedge clk) begin
    if (!stall) begin
        rd_buffer[1] <= slot0;
        for (int i = 2; i < READ_LATENCY; i++) rd_buffer[i] <= rd_buffer[i-1];
    end

    bbo_buffer[1] <= ram_q;
    for (int i = 2; i < READ_LATENCY; i++) bbo_buffer[i] <= bbo_buffer[i-1];
end

assign rd_data_a     = rd_buffer[READ_LATENCY-1];
assign bbo_rd_data_a = bbo_buffer[READ_LATENCY-1];

endmodule
