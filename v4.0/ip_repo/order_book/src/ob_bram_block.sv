`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 03.09.2026 00:28:11
// Design Name: BRAM Block
// Module Name: ob_bram_block
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module acts as our BRAM synthesiser
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Read latency included, acting as a delay stage to ensure reads
//                 are synchronised at correct stage in pipeline
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
import hdl_header::*;

module ob_bram_block#(
    parameter int   ADDRESS_W,
    parameter int   DATA_W,
    parameter int   READ_LATENCY
)(
    // Control Signals
    input logic                     clk,
    input logic                     rst_n,
    input logic                     stall,

    // Read ports
    input logic  [ADDRESS_W-1:0]    rd_addr_a,
    output logic [DATA_W-1:0]       rd_data_a,

    // Write ports
    input logic                     wr_we_a,
    input logic  [ADDRESS_W-1:0]    wr_addr_a,
    input logic  [DATA_W-1:0]       wr_data_a
);

// Local Parameters determining bram size
localparam int BRAM_DEPTH = 1 << ADDRESS_W;

// Internal registers

// BRAM block
(* ram_style = "block", cascade_height = 2 *) logic [DATA_W-1:0] bram [BRAM_DEPTH-1:0];

// DELAY BUFFER (for latency writes)
logic [DATA_W-1:0] rd_buffer    [READ_LATENCY-1:0];

// Sequential read/write
always_ff @(posedge clk) begin
    if(wr_we_a) begin
        bram[wr_addr_a]     <=  wr_data_a;
    end
    if(!stall) begin
        rd_buffer[0]                                       <=  bram[rd_addr_a];
        for(int i = 1; i < READ_LATENCY; i++) rd_buffer[i] <= rd_buffer[i-1];
    end
end

assign rd_data_a = rd_buffer[READ_LATENCY-1];
endmodule
