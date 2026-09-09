`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 12.08.2026 01:50:22
// Design Name: Order Book Update Read Book Block
// Module Name: ob_update_read_book
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module acts as a pipelined state allowing for the 1-cycle read
//              latency of BRAM for the order and price books
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Timing Optimisations & Forwarding Logic
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module ob_update_read_book(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,
    input logic                 stall,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input o_data_t              latched_rdata_i,
    input logic                 latched_is_add_i,
    input logic                 latched_is_reduce_i,
    input logic                 latched_is_delete_i,
    input logic                 latched_rep_delete_i,
    input logic                 latched_rep_add_i,
    input logic                 rep_side_i,

    output logic                stage_valid_o,
    output o_data_t             latched_rdata_o,
    output logic                latched_is_add_o,
    output logic                latched_is_reduce_o,
    output logic                latched_is_delete_o,
    output logic                latched_rep_delete_o,
    output logic                latched_rep_add_o,

    // Computed DataPath I/O
    input logic [BBO_W-1:0]     latched_event_price_idx_i,
    input logic                 latched_is_cam_entry_i,
    input logic [5:0]           latched_cam_idx_i,
    input logic [1:0]           latched_slot_idx_i,
    input order_entry_t         latched_lookup_entry_i,
    input logic [BBO_W-1:0]     latched_lookup_price_idx_i,
    input logic [HASH_W-1:0]    latched_hash_idx_i,
    input order_entry_t [2:0]   latched_read_bucket_i,

    output logic [BBO_W-1:0]    latched_event_price_idx_o,
    output logic                latched_is_cam_entry_o,
    output logic [5:0]          latched_cam_idx_o,
    output logic [1:0]          latched_slot_idx_o,
    output order_entry_t        latched_lookup_entry_o,
    output logic [BBO_W-1:0]    latched_lookup_price_idx_o,
    output logic [SHARES_W-1:0] latched_book_shares_o,
    output logic [HASH_W-1:0]   latched_hash_idx_o,
    output order_entry_t [2:0]  latched_read_bucket_o,
    output logic [SHARES_W-1:0] latched_reduced_shares_o,
    output logic                latched_full_exec_o,

    // External Memory I/O
    input logic [SHARES_W-1:0]  bid_dout_a,
    input logic [SHARES_W-1:0]  ask_dout_a,

    // Forwarding Inputs from Update Write block
    input logic                   wr0_valid,
    input logic                   wr0_side,
    input logic [BBO_W-1:0]       wr0_addr,
    input logic [SHARES_W-1:0]    wr0_data,

    // Forwarding Inputs used for specific r/w collisions
    input logic                wrc_valid,
    input logic                wrc_side,
    input logic [BBO_W-1:0]    wrc_addr,
    input logic [SHARES_W-1:0] wrc_data
);

// Internal registers used as snapshots for edge case price book condition (multiple shares change at a price level)
logic                   wr1_valid;
logic                   wr1_side;
logic [BBO_W-1:0]       wr1_addr;
logic [SHARES_W-1:0]    wr1_data;
logic                   wr2_valid;
logic                   wr2_side;
logic [BBO_W-1:0]       wr2_addr;
logic [SHARES_W-1:0]    wr2_data;
logic                   wr3_valid;
logic                   wr3_side;
logic [BBO_W-1:0]       wr3_addr;
logic [SHARES_W-1:0]    wr3_data;
logic                   wr4_valid;
logic                   wr4_side;
logic [BBO_W-1:0]       wr4_addr;
logic [SHARES_W-1:0]    wr4_data;

logic [4:0]             frwd_match;

logic                   capture_side;
logic [BBO_W-1:0]       capture_addr;

logic [SHARES_W-1:0]    mem_addr;
logic [SHARES_W-1:0]    chosen_addr;

logic                   frwd_match_c;

// combinational forward matching determination
always_comb begin
    // default assignments
    if(latched_is_add_i) begin
        capture_side    =   latched_rep_add_i ? rep_side_i : latched_rdata_i.side;
        capture_addr    =   latched_event_price_idx_i;
    end
    else begin
        capture_side    =   latched_lookup_entry_i.side;
        capture_addr    =   latched_lookup_price_idx_i;
    end
    frwd_match_c    =       wrc_valid && (wrc_side == capture_side) && (wrc_addr == capture_addr);
    mem_addr        =       capture_side ? bid_dout_a : ask_dout_a;
    frwd_match      =       5'b0;


    // Determining if we have a match for forwarding before capturing data
    frwd_match[0]   =   wr0_valid && (wr0_side == capture_side) && (wr0_addr == capture_addr);
    frwd_match[1]   =   wr1_valid && (wr1_side == capture_side) && (wr1_addr == capture_addr);
    frwd_match[2]   =   wr2_valid && (wr2_side == capture_side) && (wr2_addr == capture_addr);
    frwd_match[3]   =   wr3_valid && (wr3_side == capture_side) && (wr3_addr == capture_addr);
    frwd_match[4]   =   wr4_valid && (wr4_side == capture_side) && (wr4_addr == capture_addr);

    // priority chain for the forwarding values
    if     (frwd_match_c)  chosen_addr = wrc_data;
    else if(frwd_match[0]) chosen_addr = wr0_data;
    else if(frwd_match[1]) chosen_addr = wr1_data;
    else if(frwd_match[2]) chosen_addr = wr2_data;
    else if(frwd_match[3]) chosen_addr = wr3_data;
    else if(frwd_match[4]) chosen_addr = wr4_data;
    else                   chosen_addr = mem_addr;

end

// Seq. Logic
always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o               <=  1'b0;
    end
    else if(!stall) begin
        stage_valid_o               <=  stage_valid_i;
        latched_rdata_o             <=  latched_rdata_i;
        latched_is_add_o            <=  latched_is_add_i;
        latched_is_reduce_o         <=  latched_is_reduce_i;
        latched_is_delete_o         <=  latched_is_delete_i;
        latched_rep_delete_o        <=  latched_rep_delete_i;
        latched_rep_add_o           <=  latched_rep_add_i;

        latched_event_price_idx_o   <=  latched_event_price_idx_i;
        latched_is_cam_entry_o      <=  latched_is_cam_entry_i;
        latched_cam_idx_o           <=  latched_cam_idx_i;
        latched_slot_idx_o          <=  latched_slot_idx_i;
        latched_lookup_entry_o      <=  latched_lookup_entry_i;
        latched_lookup_price_idx_o  <=  latched_lookup_price_idx_i;
        latched_hash_idx_o          <=  latched_hash_idx_i;
        latched_read_bucket_o       <=  latched_read_bucket_i;
        latched_reduced_shares_o    <=  latched_lookup_entry_i.shares - latched_rdata_i.shares;
        latched_full_exec_o         <= (latched_rdata_i.shares >= latched_lookup_entry_i.shares);
        latched_book_shares_o       <=  chosen_addr;

        wr1_valid   <=  wr0_valid;
        wr1_side    <=  wr0_side;
        wr1_addr    <=  wr0_addr;
        wr1_data    <=  wr0_data;

        wr2_valid   <=  wr1_valid;
        wr2_side    <=  wr1_side;
        wr2_addr    <=  wr1_addr;
        wr2_data    <=  wr1_data;

        wr3_valid   <=  wr2_valid;
        wr3_side    <=  wr2_side;
        wr3_addr    <=  wr2_addr;
        wr3_data    <=  wr2_data;

        wr4_valid   <=  wr3_valid;
        wr4_side    <=  wr3_side;
        wr4_addr    <=  wr3_addr;
        wr4_data    <=  wr3_data;
    end
end

endmodule
