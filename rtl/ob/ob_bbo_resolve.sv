`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 17.08.2026 01:38:47
// Design Name: Order Book BBO Resolve Block
// Module Name: ob_bbo_resolve
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module is used to determine the next bbo output price
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module ob_bbo_resolve(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input logic [PRICE_W-1:0]   latched_base_price_i,

    output logic                stage_valid_o,
    output logic [PRICE_W-1:0]  latched_base_price_o,

    // External Memory Input
    input logic [63:0]          target_bid_chunk_i,
    input logic [63:0]          target_ask_chunk_i,

    // BBO Search I/O
    input logic [BBO_W-1:0]     current_best_bid_i,
    input logic [BBO_W-1:0]     current_best_ask_i,
    input logic                 search_side_i,
    input logic                 new_bbo_i,
    input logic [(BBO_W-7):0]   target_chunk_idx_i,
    input logic                 bid_is_zero_i,
    input logic                 ask_is_zero_i,

    output logic [BBO_W-1:0]    next_best_bid_o,
    output logic [BBO_W-1:0]    next_best_ask_o,
    output logic [BBO_W-1:0]    bbo_rd_bid_addr_o,
    output logic [BBO_W-1:0]    bbo_rd_ask_addr_o,
    output logic                bid_is_zero_o,
    output logic                ask_is_zero_o
);

// Combinational BBO calculation
always_comb begin
    next_best_bid_o = current_best_bid_i;
    next_best_ask_o = current_best_ask_i;
    if(new_bbo_i) begin
        if(search_side_i) begin
            next_best_bid_o = bid_is_zero_i ? '0 : {target_chunk_idx_i, find_msb_bit(target_bid_chunk_i)};
        end
        else begin
            next_best_ask_o = ask_is_zero_i ? BBO_W'(BBO_DEPTH-1) : {target_chunk_idx_i, find_lsb_bit(target_ask_chunk_i)};
        end
    end
end


always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o           <=  1'b0;
        latched_base_price_o    <=  '0;

        bid_is_zero_o           <=  1'b0;
        ask_is_zero_o           <=  1'b0;
        bbo_rd_bid_addr_o       <=  '0;
        bbo_rd_ask_addr_o       <=  BBO_W'(BBO_DEPTH-1);
    end
    else begin
        stage_valid_o           <=  stage_valid_i;
        latched_base_price_o    <=  latched_base_price_i;

        bid_is_zero_o           <=  bid_is_zero_i;
        ask_is_zero_o           <=  ask_is_zero_i;
        bbo_rd_bid_addr_o       <=  next_best_bid_o;
        bbo_rd_ask_addr_o       <=  next_best_ask_o;
    end
end

endmodule
