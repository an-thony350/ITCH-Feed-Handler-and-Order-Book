`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 15.08.2026 11:57:10
// Design Name: Order Book Update Write Block
// Module Name: ob_update_write
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module combinationally writes data and index values into registers
//              used in sequential logic for BRAM ports to write into order table & CAM
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

module ob_update_write(
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
    input logic [SHARES_W-1:0]  latched_book_shares_i,
    input logic [HASH_W-1:0]    latched_hash_idx_i,
    input order_entry_t [2:0]   latched_read_bucket_i,
    input logic [SHARES_W-1:0]  latched_reduced_shares_i,
    input logic                 latched_full_exec_i,

    output logic [BBO_W-1:0]    latched_event_price_idx_o,
    output order_entry_t        latched_lookup_entry_o,
    output logic [BBO_W-1:0]    latched_lookup_price_idx_o,
    output logic [SHARES_W-1:0] latched_book_shares_o,

    // External Memory I/O

    // CAM control pins
    output logic                cam_we_o,
    output logic [5:0]          cam_idx_o,
    output order_entry_t        cam_data_o,

    // Active Chunks control pins
    output logic                chunk_we_o,
    output logic                chunk_side_o, // allows us to only write to 1 active chunks
    output logic [BBO_W-1:0]    chunk_row_o,
    output logic                chunk_val_o,

    output logic                we_a,
    output logic [HASH_W-1:0]   addr_a,
    output order_entry_t [2:0]  din_a,
    output logic                bid_we_a,
    output logic [BBO_W-1:0]    bid_addr_a,
    output logic [SHARES_W-1:0] bid_din_a,
    output logic                ask_we_a,
    output logic [BBO_W-1:0]    ask_addr_a,
    output logic [SHARES_W-1:0] ask_din_a,

    // Outputs to idx_search block
    output logic                  idx_search_wr0_we,
    output logic [HASH_W-1:0]     idx_search_wr0_addr,
    output logic [1:0]            idx_search_wr0_slot,
    output order_entry_t          idx_search_wr0_data,

    // Outputs to update_read_book block
    output logic                  update_read_book_wr0_valid,
    output logic                  update_read_book_wr0_side,
    output logic [BBO_W-1:0]      update_read_book_wr0_addr,
    output logic [SHARES_W-1:0]   update_read_book_wr0_data,

    // Outputs for forward ports - due to price book r/w collisions
    output logic                  wrc_valid,
    output logic                  wrc_side,
    output logic [BBO_W-1:0]      wrc_addr,
    output logic [SHARES_W-1:0]   wrc_data
);

// Internal Registers
logic                   level_depleted_w;
logic                   chosen_side;
logic                   side_option;

// ports used to handle specific edge cases with forwarding issues (latches previous vals)
logic                   prev_we;
logic [HASH_W-1:0]      prev_addr;
logic [1:0]             prev_slot;
order_entry_t           prev_data;


// combinational assigns for potential bbo changes (and replace instruction fixes)

assign level_depleted_w = latched_is_reduce_i ?
                          (latched_book_shares_i == latched_rdata_i.shares) :
                          (latched_book_shares_i == latched_lookup_entry_i.shares);
assign side_option      = latched_rep_add_i ? rep_side_i : latched_rdata_i.side;

// sequential logic lathcing previous values (inputs) - allows us to know if forwarding required

always_ff @(posedge clk) begin
    if(!rst_n) prev_we <= 1'b0;
    else if(!stall) begin
        prev_we   <= we_a && stage_valid_i;
        prev_addr <= addr_a;
        prev_slot <= latched_slot_idx_i;
        prev_data <= din_a[latched_slot_idx_i];
    end
end

// Combinational UPDATE_WRITE logic
always_comb begin
    // default assignments

    we_a        =   '0;
    bid_we_a    =   '0;
    ask_we_a    =   '0;
    cam_we_o    =   '0;
    chunk_we_o  =   '0;

    addr_a      =   latched_hash_idx_i;
    din_a       =   latched_read_bucket_i;
    if(prev_we && (prev_addr == latched_hash_idx_i))
    din_a[prev_slot] = prev_data;

    bid_addr_a  =   '0;
    bid_din_a   =   '0;
    ask_addr_a  =   '0;
    ask_din_a   =   '0;

    cam_idx_o       =   latched_cam_idx_i;
    cam_data_o      =   latched_lookup_entry_i;
    chunk_side_o    =   latched_is_add_i ? side_option                : latched_lookup_entry_i.side;
    chunk_row_o     =   latched_is_add_i ? latched_event_price_idx_i  : latched_lookup_price_idx_i;
    chunk_val_o     =   latched_is_add_i;

    chosen_side     =   1'b0;

    if(stage_valid_i) begin

        chunk_we_o  =   stage_valid_i && (latched_is_add_i ? 1'b1 : level_depleted_w);

        if(latched_is_cam_entry_i) begin
            cam_we_o    =   1'b1;
            if(latched_is_add_i) begin
                cam_data_o.valid        =   1'b1;
                cam_data_o.orn          =   latched_rdata_i.orn;
                cam_data_o.side         =   side_option;
                cam_data_o.shares       =   latched_rdata_i.shares;
                cam_data_o.price        =   latched_rdata_i.price;
                cam_data_o.tombstone    =   1'b0;
            end
            else if(latched_is_delete_i) cam_data_o.tombstone   =   1'b1;
            else begin
                if(latched_full_exec_i) begin
                    cam_data_o.tombstone = 1'b1;
                end
                else begin
                    cam_data_o.shares = latched_reduced_shares_i;
                end
            end
        end

        we_a    =   !latched_is_cam_entry_i;

        if(latched_is_add_i) begin
            din_a[latched_slot_idx_i].valid         =   1'b1;
            din_a[latched_slot_idx_i].orn           =   latched_rdata_i.orn;
            din_a[latched_slot_idx_i].side          =   side_option;
            din_a[latched_slot_idx_i].shares        =   latched_rdata_i.shares;
            din_a[latched_slot_idx_i].price         =   latched_rdata_i.price;
            din_a[latched_slot_idx_i].tombstone     =   1'b0;

            if(side_option) begin
                bid_we_a    =   1'b1;
                bid_addr_a  =   latched_event_price_idx_i;
                bid_din_a   =   latched_book_shares_i + latched_rdata_i.shares;
                chosen_side =   1'b1;
            end
            else begin
                ask_we_a    =   1'b1;
                ask_addr_a  =   latched_event_price_idx_i;
                ask_din_a   =   latched_book_shares_i + latched_rdata_i.shares;
            end
        end
        else if(latched_is_delete_i) begin
            din_a[latched_slot_idx_i].tombstone =   1'b1;

            if(latched_lookup_entry_i.side) begin
                bid_we_a    =   1'b1;
                bid_addr_a  =   latched_lookup_price_idx_i;
                bid_din_a   =   latched_book_shares_i - latched_lookup_entry_i.shares;
                chosen_side =   1'b1;
            end
            else begin
                ask_we_a    =   1'b1;
                ask_addr_a  =   latched_lookup_price_idx_i;
                ask_din_a   =   latched_book_shares_i - latched_lookup_entry_i.shares;
            end
        end
        else begin
            if(latched_full_exec_i) din_a[latched_slot_idx_i].tombstone = 1'b1;
            else                    din_a[latched_slot_idx_i].shares    = latched_reduced_shares_i;

            if(latched_lookup_entry_i.side) begin
                bid_we_a    =   1'b1;
                bid_addr_a  =   latched_lookup_price_idx_i;
                bid_din_a   =   latched_book_shares_i - latched_rdata_i.shares;
                chosen_side =   1'b1;
            end
            else begin
                ask_we_a    =   1'b1;
                ask_addr_a  =   latched_lookup_price_idx_i;
                ask_din_a   =   latched_book_shares_i - latched_rdata_i.shares;
            end
        end
    end
end

// combinational forwarding assignments

assign wrc_valid = stage_valid_i && !stall && (bid_we_a || ask_we_a);
assign wrc_side  = chosen_side;
assign wrc_addr  = latched_is_add_i ? latched_event_price_idx_i : latched_lookup_price_idx_i;
assign wrc_data  = chosen_side ? bid_din_a : ask_din_a;

// SEQUENTIAL LOGIC
always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o                <=  1'b0;

        idx_search_wr0_we            <=  1'b0;
        update_read_book_wr0_valid   <=  1'b0;
    end
    else if(!stall) begin
        stage_valid_o               <=  stage_valid_i;
        latched_rdata_o             <=  latched_rdata_i;
        latched_rdata_o.side        <=  side_option;
        latched_is_add_o            <=  latched_is_add_i;
        latched_is_reduce_o         <=  latched_is_reduce_i;
        latched_is_delete_o         <=  latched_is_delete_i;
        latched_rep_delete_o        <=  latched_rep_delete_i;
        latched_rep_add_o           <=  latched_rep_add_i;

        latched_event_price_idx_o   <=  latched_event_price_idx_i;
        latched_lookup_entry_o      <=  latched_lookup_entry_i;
        latched_lookup_price_idx_o  <=  latched_lookup_price_idx_i;
        latched_book_shares_o       <=  latched_book_shares_i;

        idx_search_wr0_we           <=  !latched_is_cam_entry_i && stage_valid_i;
        idx_search_wr0_addr         <=  latched_hash_idx_i;
        idx_search_wr0_slot         <=  latched_slot_idx_i;
        idx_search_wr0_data         <=  din_a[latched_slot_idx_i];

        update_read_book_wr0_valid  <=  stage_valid_i && (bid_we_a || ask_we_a);
        update_read_book_wr0_side   <=  chosen_side;
        update_read_book_wr0_addr   <=  latched_is_add_i ? latched_event_price_idx_i : latched_lookup_price_idx_i;
        update_read_book_wr0_data   <=  (chosen_side) ? bid_din_a : ask_din_a;
    end
end

endmodule
