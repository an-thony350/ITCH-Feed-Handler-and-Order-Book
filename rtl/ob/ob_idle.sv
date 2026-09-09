`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 11.08.2026 15:45:04
// Design Name: Order Book Idle Block
// Module Name: ob_idle
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module represents the IDLE state in the old order book design
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module ob_idle(
    // Control signals
    input logic                 clk,
    input logic                 rst_n,
    input logic                 stall,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input o_data_t              rdata_i,
    input logic                 latched_rep_delete_i,
    input logic                 latched_rep_add_i,

    output logic                stage_valid_o,
    output o_data_t             latched_rdata_o,
    output logic                latched_is_add_o,
    output logic                latched_is_reduce_o,
    output logic                latched_is_delete_o,
    output logic                latched_rep_delete_o,
    output logic                latched_rep_add_o,
    output logic [HASH_W-1:0]   latched_hash_idx_o,
    // External Memory I/O - BRAM addr pins
    output logic [HASH_W-1:0]   hash_idx_o
);

assign hash_idx_o =  hash_orn(rdata_i.orn);

always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o           <=  1'b0;
    end
    else if(!stall) begin
        stage_valid_o           <=  stage_valid_i;
        latched_rdata_o         <=  rdata_i;
        latched_is_add_o        <=  is_add_msg(rdata_i.message_type);
        latched_is_reduce_o     <=  is_reduce_msg(rdata_i.message_type);
        latched_is_delete_o     <=  (rdata_i.message_type == MSG_DELETE);
        latched_rep_delete_o    <=  latched_rep_delete_i;
        latched_rep_add_o       <=  latched_rep_add_i;
        latched_hash_idx_o      <= hash_orn(rdata_i.orn);
    end
end


endmodule
