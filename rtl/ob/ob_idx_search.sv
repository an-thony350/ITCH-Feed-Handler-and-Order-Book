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
// Revision 0.02 - Timing Optimisations & Forwarding Logic
// Revision 1.00 - More forwarding and better use of stage for selection
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module ob_idx_search(
    // Control signals
    input logic                 clk,
    input logic                 rst_n,

    // Event Data I/O
    input   ob_event_t          event_i,
    output  ob_event_t          event_o,

    // Forwarding flags for Data Matching
    input logic [3:0]           hash_frwd_match_i,
    input logic [2:0]           cam_frwd_match_i,

    // Older events (for forwarding)
    input ob_event_t            upd_rd_tbl_event_i,
    input ob_event_t            issue_read_event_i,

    // Older buckets (for forwarding)
    input order_entry_t [2:0]   upd_rd_tbl_bucket;
    input order_entry_t [2:0]   updr_1_del_bucket;
    input order_entry_t [2:0]   updr_2_del_bucket;

    // Computed DataPath I/O
    input logic                 latched_cam_hit_i,
    input logic [5:0]           latched_cam_match_idx_i,
    input logic                 latched_cam_is_full_i,
    input logic [5:0]           latched_cam_free_lo_i,
    input logic [5:0]           latched_cam_free_hi_i,

    // CAM mask data
    input logic                 cam_wr_en_i,
    input logic [5:0]           cam_wr_slot_i,
    output logic [63:0]         cam_reserved_o,

    // External Memory I/O - BRAM dout pins
    input  order_entry_t [2:0]  read_bucket_i,
    output order_entry_t [2:0]  read_bucket_o
);

// Internal Registers

// internal bucket
order_entry_t [2:0] frwd_bucket;

// comb 3-way associative hash regs
logic [2:0] hash_match;
logic [2:0] free_slot;

// forwarded cam signals
logic       cam_hit_f;
logic [5:0] cam_idx_f;

logic [5:0] cam_pick;
logic       cam_full;

logic       found;
logic       use_cam;

logic       prev_event_low;

// idx search regs
logic [1:0] slot;
logic [5:0] cam_slot;

// Function to determine if an older event put an order into the CAM
function automatic logic cam_insert(ob_event_t e);
    return e.valid && e.is_add && e.is_found && e.use_cam;
endfunction

// combinational Forward Bucket matching & selection

always_comb begin
    frwd_bucket =   read_bucket_i;

    // priority encoder
    if(hash_frwd_match_i[3]) frwd_bucket    =   updr_2_del_bucket;
    if(hash_frwd_match_i[2]) frwd_bucket    =   updr_1_del_bucket;
    if(hash_frwd_match_i[1]) frwd_bucket    =   upd_rd_tbl_bucket;

    if(hash_frwd_match_i[0] && event_o.is_add && event_o.is_found && !event_o.use_cam) begin
        frwd_bucket[event_o.slot].valid     =   1'b1;
        frwd_bucket[event_o.slot].tombstone =   1'b0;
        frwd_bucket[event_o.slot].orn       =   event_o.rdata.orn;
    end

    // Search bucket for match/free slot
    for(int i = 0; i < 3; i++) begin
        hash_match[i]   =   frwd_bucket[i].valid && !frwd_bucket[i].tombstone && (frwd_bucket[i].orn == event_i.rdata.orn);
        free_slot[i]    =   !frwd_bucket[i].valid || frwd_bucket[i].tombstone;
    end
end

// Combinational Forward CAM matching & selection - priority encoder

always_comb begin
    cam_hit_f   =   latched_cam_hit_i;
    cam_idx_f   =   latched_cam_match_idx_i;

    // priority encoder
    if(cam_frwd_match_i[2] && cam_insert(issue_read_event_i)) begin
        cam_hit_f   =   1'b1;
        cam_idx_f   =   issue_read_event_i.cam_slot;
    end
    if(cam_frwd_match_i[1] && cam_insert(upd_rd_tbl_event_i)) begin
        cam_hit_f   =   1'b1;
        cam_idx_f   =   upd_rd_tbl_event_i.cam_slot;
    end
    if(cam_frwd_match_i[0] && cam_insert(event_o)) begin
        cam_hit_f   =   1'b1;
        cam_idx_f   =   event_o.cam_slot;
    end

    // Pick a free CAM slot
    prev_event_low  =   cam_insert(event_o) && (event_o.cam_slot == latched_cam_free_lo_i); // the previous event chose the lowest slot
    cam_pick        =   prev_event_low ? latched_cam_free_hi_i ? latched_cam_free_lo_i;
    cam_full        =   latched_cam_is_full_i || (prev_event_low && latched_cam_free_lo_i == latched_cam_free_hi_i);
end

// Combinational logic to chose between buckets or CAM

always_comb begin
    found   =   1'b0;
    use_cam =   1'b0;
    slot    =   '0;
    cam_slot=   '0;

    if(event_i.is_add) begin
        if(|free_slot) begin
            found   =   1'b1;
            slot    =   free_slot[0] ? 2'd0 : (free_slot[1] ? 2'd1 : 2'd2);
        end
        else if(!cam_full) begin
            found   =   1'b1;
            use_cam =   1'b1;
            cam_slot=   cam_pick;
        end
    end
    else begin
        if(|hash_match) begin
            found   =   1'b1;
            slot    =   hash_match[0] ? 2'd0 : (hash_match[1] ? 2'd1 : 2'd2);
        end
        else if(cam_hit_f) begin
            found   =   1'b1;
            use_cam =   1'b1;
            cam_slot=   cam_idx_f;
        end
    end
end


// seq logic
always_ff @(posedge clk) begin
    if(!rst_n) begin
        event_o.valid               <=  '0;
        cam_reserved_o              <=  '0;
    end
    else begin
        event_o          <= event_i;
        event_o.found    <= found;
        event_o.use_cam  <= use_cam;
        event_o.slot     <= slot;
        event_o.cam_slot <= cam_slot;
        read_bucket_o    <= frwd_bucket;

        if(cam_wr_en_i)                                         cam_reserved_o[cam_wr_slot_i]   <= 1'b0;
        if(event_i.valid && event_i.is_add && use_cam && found) cam_reserved_o[cam_slot]        <= 1'b1;
    end
end

endmodule
