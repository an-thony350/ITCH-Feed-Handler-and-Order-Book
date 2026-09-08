`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 11.08.2026 18:28:31
// Design Name: Order Book Index Search Block
// Module Name: ob_idx_search
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module represents the IDX_SEARCH state in the old order book
//              design. This block uses thee 3-way associative hashing to determine
//              a hash entry/use the CAM if entries are full
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module ob_idx_search(
    // Control signals
    input logic                 clk,
    input logic                 rst_n,
    input logic                 stall,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input o_data_t              latched_rdata_i,
    input logic [PRICE_W-1:0]   latched_base_price_i,
    input logic                 latched_is_add_i,
    input logic                 latched_is_reduce_i,
    input logic                 latched_is_delete_i,
    input logic                 latched_rep_delete_i,
    input logic                 latched_rep_add_i,

    output logic                stage_valid_o,
    output o_data_t             latched_rdata_o,
    output logic [PRICE_W-1:0]  latched_base_price_o,
    output logic                latched_is_add_o,
    output logic                latched_is_reduce_o,
    output logic                latched_is_delete_o,
    output logic                latched_rep_delete_o,
    output logic                latched_rep_add_o,

    // Computed DataPath I/O
    input logic [BBO_W-1:0]     latched_event_price_idx_i,
    input logic                 latched_cam_hit_i,
    input logic [5:0]           latched_cam_match_idx_i,
    input logic [5:0]           latched_cam_free_idx_i,
    input logic [HASH_W-1:0]    latched_hash_idx_i,

    output logic [BBO_W-1:0]    latched_event_price_idx_o,
    output logic                latched_cam_hit_o,
    output logic [5:0]          latched_cam_match_idx_o,
    output logic [5:0]          latched_cam_free_idx_o,
    output logic [1:0]          latched_slot_idx_o,
    output logic [2:0]          latched_hash_match_o,
    output logic [2:0]          latched_free_slot_o,
    output logic [HASH_W-1:0]   latched_hash_idx_o,
    output order_entry_t [2:0]  read_bucket_o,

    // External Memory I/O - BRAM dout pins
    input order_entry_t [2:0]   read_bucket_i,

    // Inputs from Update Write block
    input logic                   wr0_we,
    input logic [HASH_W-1:0]      wr0_addr,
    input logic [1:0]             wr0_slot,
    input order_entry_t           wr0_data
);

// Internal Registers

// comb 3-way associative hash regs
logic [2:0] hash_match;
logic [2:0] free_slot;

// idx search regs
logic [1:0] comb_slot_idx;


// Internal registers used as snapshots for edge case order book condition (consecutive entries at same index/hash bucket)
logic                   wr1_we;
logic [HASH_W-1:0]      wr1_addr;
logic [1:0]             wr1_slot;
order_entry_t           wr1_data;
logic                   wr2_we;
logic [HASH_W-1:0]      wr2_addr;
logic [1:0]             wr2_slot;
order_entry_t           wr2_data;
logic                   wr3_we;
logic [HASH_W-1:0]      wr3_addr;
logic [1:0]             wr3_slot;
order_entry_t           wr3_data;
logic                   wr4_we;
logic [HASH_W-1:0]      wr4_addr;
logic [1:0]             wr4_slot;
order_entry_t           wr4_data;
logic                   wr5_we;
logic [HASH_W-1:0]      wr5_addr;
logic [1:0]             wr5_slot;
order_entry_t           wr5_data;
logic                   wr6_we;
logic [HASH_W-1:0]      wr6_addr;
logic [1:0]             wr6_slot;
order_entry_t           wr6_data;
logic                   wr7_we;
logic [HASH_W-1:0]      wr7_addr;
logic [1:0]             wr7_slot;
order_entry_t           wr7_data;
logic                   wr8_we;
logic [HASH_W-1:0]      wr8_addr;
logic [1:0]             wr8_slot;
order_entry_t           wr8_data;

logic [HASH_W-1:0]      capture_addr;
order_entry_t [2:0]     frwd_bucket;

// combinational forward matching determination
always_comb begin
    // Default Assignments
    frwd_bucket     =       read_bucket_i;
    capture_addr    =       latched_hash_idx_i;

    // Determining if we have a match for forwarding before capturing data
    if(wr8_we && (capture_addr == wr8_addr))    frwd_bucket[wr8_slot]   =   wr8_data;
    if(wr7_we && (capture_addr == wr7_addr))    frwd_bucket[wr7_slot]   =   wr7_data;
    if(wr6_we && (capture_addr == wr6_addr))    frwd_bucket[wr6_slot]   =   wr6_data;
    if(wr5_we && (capture_addr == wr5_addr))    frwd_bucket[wr5_slot]   =   wr5_data;
    if(wr4_we && (capture_addr == wr4_addr))    frwd_bucket[wr4_slot]   =   wr4_data;
    if(wr3_we && (capture_addr == wr3_addr))    frwd_bucket[wr3_slot]   =   wr3_data;
    if(wr2_we && (capture_addr == wr2_addr))    frwd_bucket[wr2_slot]   =   wr2_data;
    if(wr1_we && (capture_addr == wr1_addr))    frwd_bucket[wr1_slot]   =   wr1_data;
    if(wr0_we && (capture_addr == wr0_addr))    frwd_bucket[wr0_slot]   =   wr0_data;

end

// combinational logic determing hash matches and free slots
always_comb begin
    // Default Assignments
    hash_match      =   '0;
    free_slot       =   '0;

    hash_match[0]        =   (frwd_bucket[0].valid && frwd_bucket[0].orn == latched_rdata_i.orn && ~frwd_bucket[0].tombstone);
    hash_match[1]        =   (frwd_bucket[1].valid && frwd_bucket[1].orn == latched_rdata_i.orn && ~frwd_bucket[1].tombstone);
    hash_match[2]        =   (frwd_bucket[2].valid && frwd_bucket[2].orn == latched_rdata_i.orn && ~frwd_bucket[2].tombstone);

    free_slot[0]         = (!frwd_bucket[0].valid || frwd_bucket[0].tombstone);
    free_slot[1]         = (!frwd_bucket[1].valid || frwd_bucket[1].tombstone);
    free_slot[2]         = (!frwd_bucket[2].valid || frwd_bucket[2].tombstone);

end


// combinational logic determining if forwarding is required

always_comb begin
    comb_slot_idx       =   '0;

    if(latched_is_add_i) begin
        if(free_slot != 3'b000) begin
            if      (free_slot[0]) comb_slot_idx = 2'd0;
            else if (free_slot[1]) comb_slot_idx = 2'd1;
            else                   comb_slot_idx = 2'd2;
        end
    end
    else begin
        if(hash_match != 3'b000) begin
            if      (hash_match[0]) comb_slot_idx = 2'd0;
            else if (hash_match[1]) comb_slot_idx = 2'd1;
            else                    comb_slot_idx = 2'd2;
        end
    end
end

// seq logic
always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o               <=  '0;
        latched_rdata_o             <=  '0;
        latched_base_price_o        <=  '0;
        latched_is_add_o            <=  1'b0;
        latched_is_reduce_o         <=  1'b0;
        latched_is_delete_o         <=  1'b0;
        latched_rep_delete_o        <=  1'b0;
        latched_rep_add_o           <=  1'b0;

        latched_event_price_idx_o   <=  '0;
        latched_cam_hit_o           <=  1'b0;
        latched_cam_match_idx_o     <=  '0;
        latched_cam_free_idx_o      <=  '0;
        latched_slot_idx_o          <=  '0;
        latched_hash_match_o        <=  '0;
        latched_free_slot_o         <=  '0;
        latched_hash_idx_o          <=  '0;
        read_bucket_o               <=  '0;

        wr1_we <= 1'b0;
        wr2_we <= 1'b0;
        wr3_we <= 1'b0;
        wr4_we <= 1'b0;
        wr5_we <= 1'b0;
        wr6_we <= 1'b0;
        wr7_we <= 1'b0;
        wr8_we <= 1'b0;
    end
    else if(!stall) begin
        // deals with immediate return to FETCH_BBO state in old design
        if(!latched_is_add_i && hash_match == 3'b000 && !latched_cam_hit_i) begin
            stage_valid_o   <=  1'b0;
        end
        else begin
            stage_valid_o   <=  stage_valid_i;
        end

        latched_rdata_o             <=  latched_rdata_i;
        latched_base_price_o        <=  latched_base_price_i;
        latched_is_add_o            <=  latched_is_add_i;
        latched_is_reduce_o         <=  latched_is_reduce_i;
        latched_is_delete_o         <=  latched_is_delete_i;
        latched_rep_delete_o        <=  latched_rep_delete_i;
        latched_rep_add_o           <=  latched_rep_add_i;

        latched_event_price_idx_o   <=  latched_event_price_idx_i;
        latched_cam_hit_o           <=  latched_cam_hit_i;
        latched_cam_match_idx_o     <=  latched_cam_match_idx_i;
        latched_cam_free_idx_o      <=  latched_cam_free_idx_i;
        latched_slot_idx_o          <=  comb_slot_idx;
        latched_hash_match_o        <=  hash_match;
        latched_free_slot_o         <=  free_slot;
        latched_hash_idx_o          <=  latched_hash_idx_i;
        read_bucket_o               <=  frwd_bucket;

        wr1_we                      <=  wr0_we;
        wr1_addr                    <=  wr0_addr;
        wr1_slot                    <=  wr0_slot;
        wr1_data                    <=  wr0_data;

        wr2_we                      <=  wr1_we;
        wr2_addr                    <=  wr1_addr;
        wr2_slot                    <=  wr1_slot;
        wr2_data                    <=  wr1_data;

        wr3_we                      <=  wr2_we;
        wr3_addr                    <=  wr2_addr;
        wr3_slot                    <=  wr2_slot;
        wr3_data                    <=  wr2_data;

        wr4_we                      <=  wr3_we;
        wr4_addr                    <=  wr3_addr;
        wr4_slot                    <=  wr3_slot;
        wr4_data                    <=  wr3_data;

        wr5_we                      <=  wr4_we;
        wr5_addr                    <=  wr4_addr;
        wr5_slot                    <=  wr4_slot;
        wr5_data                    <=  wr4_data;

        wr6_we                      <=  wr5_we;
        wr6_addr                    <=  wr5_addr;
        wr6_slot                    <=  wr5_slot;
        wr6_data                    <=  wr5_data;

        wr7_we                      <=  wr6_we;
        wr7_addr                    <=  wr6_addr;
        wr7_slot                    <=  wr6_slot;
        wr7_data                    <=  wr6_data;

        wr8_we                      <=  wr7_we;
        wr8_addr                    <=  wr7_addr;
        wr8_slot                    <=  wr7_slot;
        wr8_data                    <=  wr7_data;
    end
end

endmodule
