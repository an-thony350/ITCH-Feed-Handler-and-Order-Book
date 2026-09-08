`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 07.09.2026 17:20:09
// Design Name: Hazard Unit
// Module Name: ob_hazard_unit
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module acts as a hazard unit, allowing for stalls to be asserted
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module ob_hazard_unit #(
    parameter int CHECK_LEN = 9
)(
    input  logic                clk,
    input  logic                rst_n,

    input  logic                new_msg_valid,
    input  logic [HASH_W-1:0]   new_msg_hash,
    input  logic                wr_valid,
    input  logic [HASH_W-1:0]   wr_hash,
    output logic                hazard_stall
);

typedef struct packed {
    logic               valid;
    logic [HASH_W-1:0]  hash;
} hash_data_t;

hash_data_t [CHECK_LEN-1:0] hash_history;
logic                       match;

always_comb begin
    match = 1'b0;
    for(int i = 0; i < CHECK_LEN; i++) begin
        if(hash_history[i].valid && (hash_history[i].hash == new_msg_hash))
            match = 1'b1;
    end
end

assign hazard_stall = new_msg_valid && match;

always_ff @(posedge clk) begin
    if(!rst_n)
        hash_history <= '0;
    else
        hash_history <= {hash_history[CHECK_LEN-2:0], {wr_valid, wr_hash}};
end

endmodule
