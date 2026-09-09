`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 17.08.2026 01:38:47
// Design Name: Order Book BBO Evaluate Block
// Module Name: ob_bbo_evaluate
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module is used as the bit search of the bbo outputs
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module ob_evaluate_bbo(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,

    output logic                stall,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input o_data_t              latched_rdata_i,
    input logic                 latched_is_add_i,
    input logic                 latched_is_reduce_i,
    input logic                 latched_is_delete_i,
    input logic                 latched_rep_delete_i,
    input logic                 latched_rep_add_i,

    output logic                stage_valid_o,
    output logic                latched_rep_delete_o,

    // Computed DataPath I/O
    input logic [BBO_W-1:0]     latched_event_price_idx_i,
    input order_entry_t         latched_lookup_entry_i,
    input logic [BBO_W-1:0]     latched_lookup_price_idx_i,
    input logic [SHARES_W-1:0]  latched_book_shares_i,

    // BBO Search I/O
    input logic [BBO_W-1:0]     current_best_bid_i,
    input logic [BBO_W-1:0]     current_best_ask_i,
    input logic [CHUNK_LEN-1:0] bid_enc_valid_i,
    input logic [CHUNK_LEN-1:0] ask_enc_valid_i,

    output logic [BBO_W-1:0]    current_best_bid_o,
    output logic [BBO_W-1:0]    current_best_ask_o,
    output logic                search_side_o,
    output logic                new_bbo_o,
    output logic [(BBO_W-7):0]  target_chunk_idx_o,
    output logic [(BBO_W-7):0]  next_target_chunk_idx_o,
    output logic                bid_is_zero_o,
    output logic                ask_is_zero_o
);

// internal registers

logic       is_better_bid;
logic       is_better_ask;
logic       bid_depleted;
logic       ask_depleted;
logic       level_depleted;
logic       new_bbo;
logic       bid_is_zero;
logic       ask_is_zero;
logic       stall_edge_detector;

logic rep_add_needs_read;
assign rep_add_needs_read = latched_is_add_i && latched_rep_add_i &&
                            (latched_event_price_idx_i != current_best_ask_i) &&
                            (latched_event_price_idx_i != current_best_bid_i);

// combinational logic for bbo_evaluation
always_comb begin
    // Default assignmnets
    is_better_bid   =   1'b0;
    is_better_ask   =   1'b0;
    bid_depleted    =   1'b0;
    ask_depleted    =   1'b0;

    level_depleted = latched_is_reduce_i ?
                     (latched_book_shares_i == latched_rdata_i.shares) :
                     (latched_book_shares_i == latched_lookup_entry_i.shares);

    if(latched_is_add_i) begin
        if( latched_rdata_i.side && latched_event_price_idx_i > current_best_bid_i) is_better_bid  = 1'b1;
        if(!latched_rdata_i.side && latched_event_price_idx_i < current_best_ask_i) is_better_ask  = 1'b1;
    end

    if(latched_is_reduce_i || latched_is_delete_i) begin
        if(level_depleted) begin
            if( latched_lookup_entry_i.side && latched_lookup_price_idx_i == current_best_bid_i) bid_depleted = 1'b1;
            if(!latched_lookup_entry_i.side && latched_lookup_price_idx_i == current_best_ask_i) ask_depleted = 1'b1;
        end
    end

    new_bbo     =   (bid_depleted && current_best_bid_i != '0) || (ask_depleted && current_best_ask_i != BBO_W'(BBO_DEPTH-1));
    bid_is_zero =   (bid_enc_valid_i == '0);
    ask_is_zero =   (ask_enc_valid_i == '0);

    if(ask_depleted) next_target_chunk_idx_o = find_lsb_chunk(ask_enc_valid_i);
    else             next_target_chunk_idx_o = find_msb_chunk(bid_enc_valid_i);
end

// Sequential Logic
always_ff @(posedge clk) begin
    if(!rst_n) begin
        stall                       <=  1'b0;
        stall_edge_detector         <=  1'b0;
        stage_valid_o               <=  1'b0;
    end
    else begin
        stall_edge_detector         <=  stall;
        stall                       <=  stage_valid_i && (rep_add_needs_read || bid_depleted || ask_depleted) && !stall_edge_detector && !latched_rep_delete_i;
        stage_valid_o               <=  stage_valid_i;
        latched_rep_delete_o        <=  latched_rep_delete_i;
        new_bbo_o                   <=  new_bbo;
        bid_is_zero_o               <=  bid_is_zero;
        ask_is_zero_o               <=  ask_is_zero;
        target_chunk_idx_o          <=  next_target_chunk_idx_o;

        if(ask_depleted) begin
            target_chunk_idx_o      <=  next_target_chunk_idx_o;
            search_side_o           <=  1'b0;
        end
        else begin
            target_chunk_idx_o      <=  next_target_chunk_idx_o;
            search_side_o           <=  1'b1;
        end

        if (is_better_bid)  current_best_bid_o <= latched_event_price_idx_i;
        else                current_best_bid_o <= current_best_bid_i;

        if (is_better_ask)  current_best_ask_o <= latched_event_price_idx_i;
        else                current_best_ask_o <= current_best_ask_i;
    end
end

endmodule
