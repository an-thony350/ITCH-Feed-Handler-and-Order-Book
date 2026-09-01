`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 29.06.2026 15:15:19
// Design Name: Order Book
// Module Name: order_book
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: The order book carries both combinational and sequential logic
// through a Mealy model state machne of 14 states allowing for both accurate data
// capture of orders for a specific stock, as well as two price books determining the
// best buy and sell prices
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created & base structure formed
// Revision 0.02 - All instructions except for Replace
// Revision 0.10 - Valid/ready handshake & replacement state added
// Revision 1.00 - Addition of base price logic (with symbol router) & pipelined
//                 registers for the price books
// Revision 1.01 - Addition of delta price functions, and explicit bit specification
//                 to remove verilator warinings
// Revision 1.02 - Latching of multiple registers, avoiding hash collisions
// Revision 1.10 - Compatibility with symbol router & top module
// Revision 2.00 - Change of hash collision traversal - using probe searching
//                 rather than linked list traversal (see note [1] in comments)
// Revision 2.01 - Addition of header package file (hdl_header), cleaning up data IO
// Revision 2.10 - Chunk/bit priority encoders for BBO output traversal & tombstone
//                 additions in probe searching logic to fix key hashing collision
//                 faults introduced with probe searching
// Revision 2.11 - debug & cleanup
// Revision 3.00 - Change of how three books are written to, implemented as True-Port
//                 BRAM, ensuring design is synthesizable in Vivado w/o high LUT use
// Revision 3.10 - Pipelining and replicating registers to optimise timing
// Revision 3.11 - Increasing price window by increasing BBO_W and relevent logic
// Revision 3.20 - Increased Hash Width to help track stocks better by losing less
//                 orders
// Revision 3.21 - Reverted Hash Width change, and increased MAX_PROBES to use less
//                 BRAM
// Revision 4.00 - Changed order & price books to use 3-way Set Assocciative Hashing
//                 rather than 1-way - reducing no. hash collisions, also reduced
//                 probe number to 3 instead of 32 reducing max clock cycle latency
// Revision 4.10 - Added Content Addressable Memory to remove probing
// Revision 5.00 - Order book now fully pipelined, this module now acts as a top
//                 top module, holding all the blocks which are similar to that of
//                 the Mealy state machine
// Additional Comments:
// [1]: In the previous design, a Linked List was formed to determine hash entries
//      and indexes. If a hash index was already in use, it would have a reference
//      index which pointed to another index in the order book. This would allow
//      the traversal of indexes until the correct ORN is found. Given the heavy
//      data requirement, we have chosen to change this to a probe seaching method
//      this method effectively works on spacial locality, where in a hash collision
//      the index will increase by 1 and look into the new address to se if a slot
//      is free. If so, the hash index for that ORN is updated accordingly. This is
//      less heavy on resources and faster, but will cause data to be lost if there
//      are no free slots in range [hash_idx, hash_idx + MAX_PROBES)
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module order_book(
    input logic                 clk,
    input logic                 bram_clk,
    input logic                 rst_n,

    // input from symbol router
    input o_data_t              rdata_i,
    input logic                 valid_i,
    input logic [PRICE_W-1:0]   base_price_i,

    // output to symbol router
    output logic                ready_o,

    // BBO output
    output bbo_t                bbo_data_o,
    output logic                bbo_valid_o
);

// Internal registers

// Top-level Memory Blocks

order_entry_t [63:0]    cam;
logic [63:0]            bid_active_chunks [CHUNK_LEN-1:0];
logic [63:0]            ask_active_chunks [CHUNK_LEN-1:0];
logic [CHUNK_LEN-1:0]   bid_enc_valid;
logic [CHUNK_LEN-1:0]   ask_enc_valid;

logic [63:0]            current_bid_chunk;
logic [63:0]            current_ask_chunk;

// prefetched chunk words (BRAM read data, 2 stages ahead of UPDATE_WRITE)
logic [63:0]            bid_chunk_a, bid_chunk_b;
logic [63:0]            ask_chunk_a, ask_chunk_b;
logic [63:0]            q_bid_chunk_a, q_bid_chunk_b;
logic [63:0]            q_ask_chunk_a, q_ask_chunk_b;

// full-word write signals for the chunk BRAMs
logic                   cw_we_bid,  cw2_we_bid,  cw_we_ask,  cw2_we_ask;
logic [BBO_W-7:0]       cw_row_bid, cw2_row_bid, cw_row_ask, cw2_row_ask;
logic [63:0]            cw_dat_bid, cw2_dat_bid, cw_dat_ask, cw2_dat_ask;
logic                   same_word;

// combinational chunk index for the shadow read (one cycle ahead of the registered one)
logic [BBO_W-7:0]       next_target_chunk_idx;

logic [BBO_W-1:0]       current_best_bid;
logic [BBO_W-1:0]       current_best_ask;

// Dual-Port (A & B) BRAM ports - data, write-enable, & address pointer registers

// order table ports
logic [HASH_W-1:0]      ot_addr_a; // hash_idx
logic [HASH_W-1:0]      ot_addr_b; // rep_hash_idx
order_entry_t [2:0]     ot_din_a;
order_entry_t [2:0]     ot_din_b;

logic                   ot_we_a;
logic                   ot_we_b;
logic [HASH_W-1:0]      ot_wr_addr_a;
logic [HASH_W-1:0]      ot_wr_addr_b;
order_entry_t [2:0]     ot_dout_a;
order_entry_t [2:0]     ot_dout_b;

// bid price book registers
logic [BBO_W-1:0]       bid_addr_a;
logic [BBO_W-1:0]       bid_addr_b;
logic [SHARES_W-1:0]    bid_din_a;
logic [SHARES_W-1:0]    bid_din_b;

logic                   bid_we_a;
logic                   bid_we_b;
logic [BBO_W-1:0]       bid_wr_addr_a;
logic [BBO_W-1:0]       bid_wr_addr_b;
logic [SHARES_W-1:0]    bid_dout_a;
logic [SHARES_W-1:0]    bid_dout_b;

// ask price book registers
logic [BBO_W-1:0]       ask_addr_a;
logic [BBO_W-1:0]       ask_addr_b;
logic [SHARES_W-1:0]    ask_din_a;
logic [SHARES_W-1:0]    ask_din_b;

logic                   ask_we_a;
logic                   ask_we_b;
logic [BBO_W-1:0]       ask_wr_addr_a;
logic [BBO_W-1:0]       ask_wr_addr_b;
logic [SHARES_W-1:0]    ask_dout_a;
logic [SHARES_W-1:0]    ask_dout_b;

// replicate price book output registers
logic [SHARES_W-1:0]    bbo_bid_dout;
logic [SHARES_W-1:0]    bbo_ask_dout;
logic [BBO_W-1:0]       next_best_bid;
logic [BBO_W-1:0]       next_best_ask;
logic [BBO_W-1:0]       bbo_rd_bid_addr;
logic [BBO_W-1:0]       bbo_rd_ask_addr;

// MUXed write register outputs for book write ports - used to differentiate between CLEAR state and other states
logic                   ot_we_a_m;
logic [HASH_W-1:0]      ot_wr_addr_a_m;
order_entry_t [2:0]     ot_din_a_m;
logic                   bid_we_a_m;
logic [BBO_W-1:0]       bid_wr_addr_a_m;
logic [SHARES_W-1:0]    bid_din_a_m;
logic                   ask_we_a_m;
logic [BBO_W-1:0]       ask_wr_addr_a_m;
logic [SHARES_W-1:0]    ask_din_a_m;

// registers controlling the CLEAR state
logic               clearing;
logic [BBO_W-1:0]   clear_idx;

// CAM control pins
logic                   cam_we;
logic [5:0]             cam_idx;
order_entry_t           cam_data;

// Active Chunks control pins
logic                   chunk_we;
logic                   chunk_side;
logic [BBO_W-1:0]       chunk_row;
logic                   chunk_val;

logic                   chunk2_we;
logic                   chunk2_side;
logic [BBO_W-1:0]       chunk2_row;
logic                   chunk2_val;

// IDLE State registers - outputs
logic                   IDLE_IDXREQ_stage_valid;
o_data_t                IDLE_IDXREQ_latched_rdata;
logic [PRICE_W-1:0]     IDLE_IDXREQ_base_price;
logic                   IDLE_IDXREQ_is_add;
logic                   IDLE_IDXREQ_is_reduce;
logic                   IDLE_IDXREQ_is_replace;
logic                   IDLE_IDXREQ_is_delete;

// IDX_REQ State registers - outputs
logic                   IDXREQ_IDXSEARCH_stage_valid;
o_data_t                IDXREQ_IDXSEARCH_latched_rdata;
logic [PRICE_W-1:0]     IDXREQ_IDXSEARCH_base_price;
logic                   IDXREQ_IDXSEARCH_is_add;
logic                   IDXREQ_IDXSEARCH_is_reduce;
logic                   IDXREQ_IDXSEARCH_is_replace;
logic                   IDXREQ_IDXSEARCH_is_delete;
logic [BBO_W-1:0]       IDXREQ_IDXSEARCH_latched_event_price_idx;
logic                   IDXREQ_IDXSEARCH_cam_hit;
logic [5:0]             IDXREQ_IDXSEARCH_cam_match_idx;
logic                   IDXREQ_IDXSEARCH_cam_is_full;
logic [5:0]             IDXREQ_IDXSEARCH_cam_free_idx;
logic [HASH_W-1:0]      IDXREQ_IDXSEARCH_hash_idx;
logic [HASH_W-1:0]      IDXREQ_IDXSEARCH_rep_hash_idx;

// IDX_SEARCH State registers - outputs
logic                   IDXSEARCH_UPDATERDTBL_stage_valid;
o_data_t                IDXSEARCH_UPDATERDTBL_latched_rdata;
logic [PRICE_W-1:0]     IDXSEARCH_UPDATERDTBL_base_price;
logic                   IDXSEARCH_UPDATERDTBL_is_add;
logic                   IDXSEARCH_UPDATERDTBL_is_reduce;
logic                   IDXSEARCH_UPDATERDTBL_is_replace;
logic                   IDXSEARCH_UPDATERDTBL_is_delete;
logic [BBO_W-1:0]       IDXSEARCH_UPDATERDTBL_latched_event_price_idx;
logic                   IDXSEARCH_UPDATERDTBL_cam_hit;
logic [5:0]             IDXSEARCH_UPDATERDTBL_cam_match_idx;
logic [5:0]             IDXSEARCH_UPDATERDTBL_cam_free_idx;
logic [1:0]             IDXSEARCH_UPDATERDTBL_latched_slot_idx;
logic [1:0]             IDXSEARCH_UPDATERDTBL_latched_rep_slot_idx;
logic [2:0]             IDXSEARCH_UPDATERDTBL_latched_free_slot;
logic [2:0]             IDXSEARCH_UPDATERDTBL_latched_hash_match;
logic [HASH_W-1:0]      IDXSEARCH_UPDATERDTBL_hash_idx;
logic [HASH_W-1:0]      IDXSEARCH_UPDATERDTBL_rep_hash_idx;
order_entry_t [2:0]     IDXSEARCH_UPDATERDTBL_read_bucket;
order_entry_t [2:0]     IDXSEARCH_UPDATERDTBL_rep_read_bucket;

// UPDATE_READ_TABLE State registers - outputs
logic                   UPDATERDTBL_ISSUEBKRD_stage_valid;
o_data_t                UPDATERDTBL_ISSUEBKRD_latched_rdata;
logic [PRICE_W-1:0]     UPDATERDTBL_ISSUEBKRD_base_price;
logic                   UPDATERDTBL_ISSUEBKRD_is_add;
logic                   UPDATERDTBL_ISSUEBKRD_is_reduce;
logic                   UPDATERDTBL_ISSUEBKRD_is_replace;
logic                   UPDATERDTBL_ISSUEBKRD_is_delete;
logic [BBO_W-1:0]       UPDATERDTBL_ISSUEBKRD_latched_event_price_idx;
logic                   UPDATERDTBL_ISSUEBKRD_is_cam_entry;
logic [5:0]             UPDATERDTBL_ISSUEBKRD_latched_cam_idx;
logic [1:0]             UPDATERDTBL_ISSUEBKRD_latched_slot_idx;
logic [1:0]             UPDATERDTBL_ISSUEBKRD_latched_rep_slot_idx;
order_entry_t           UPDATERDTBL_ISSUEBKRD_latched_lookup_entry;
logic [HASH_W-1:0]      UPDATERDTBL_ISSUEBKRD_hash_idx;
logic [HASH_W-1:0]      UPDATERDTBL_ISSUEBKRD_rep_hash_idx;
order_entry_t [2:0]     UPDATERDTBL_ISSUEBKRD_read_bucket;
order_entry_t [2:0]     UPDATERDTBL_ISSUEBKRD_rep_read_bucket;

// ISSUE_BOOK_READ State registers - outputs
logic                   ISSUEBKRD_UPDATERDBK_stage_valid;
o_data_t                ISSUEBKRD_UPDATERDBK_latched_rdata;
logic [PRICE_W-1:0]     ISSUEBKRD_UPDATERDBK_base_price;
logic                   ISSUEBKRD_UPDATERDBK_is_add;
logic                   ISSUEBKRD_UPDATERDBK_is_reduce;
logic                   ISSUEBKRD_UPDATERDBK_is_replace;
logic                   ISSUEBKRD_UPDATERDBK_is_delete;
logic [BBO_W-1:0]       ISSUEBKRD_UPDATERDBK_latched_event_price_idx;
logic                   ISSUEBKRD_UPDATERDBK_is_cam_entry;
logic [5:0]             ISSUEBKRD_UPDATERDBK_latched_cam_idx;
logic [1:0]             ISSUEBKRD_UPDATERDBK_latched_slot_idx;
logic [1:0]             ISSUEBKRD_UPDATERDBK_latched_rep_slot_idx;
order_entry_t           ISSUEBKRD_UPDATERDBK_latched_lookup_entry;
logic [BBO_W-1:0]       ISSUEBKRD_UPDATERDBK_latched_lookup_price_idx;
logic [HASH_W-1:0]      ISSUEBKRD_UPDATERDBK_hash_idx;
logic [HASH_W-1:0]      ISSUEBKRD_UPDATERDBK_rep_hash_idx;
order_entry_t [2:0]     ISSUEBKRD_UPDATERDBK_read_bucket;
order_entry_t [2:0]     ISSUEBKRD_UPDATERDBK_rep_read_bucket;

// UPDATE_READ_BOOK State registers - outputs
logic                   UPDATERDBK_UPDATEWR_stage_valid;
o_data_t                UPDATERDBK_UPDATEWR_latched_rdata;
logic [PRICE_W-1:0]     UPDATERDBK_UPDATEWR_base_price;
logic                   UPDATERDBK_UPDATEWR_is_add;
logic                   UPDATERDBK_UPDATEWR_is_reduce;
logic                   UPDATERDBK_UPDATEWR_is_replace;
logic                   UPDATERDBK_UPDATEWR_is_delete;
logic [BBO_W-1:0]       UPDATERDBK_UPDATEWR_latched_event_price_idx;
logic                   UPDATERDBK_UPDATEWR_is_cam_entry;
logic [5:0]             UPDATERDBK_UPDATEWR_latched_cam_idx;
logic [1:0]             UPDATERDBK_UPDATEWR_latched_slot_idx;
logic [1:0]             UPDATERDBK_UPDATEWR_latched_rep_slot_idx;
order_entry_t           UPDATERDBK_UPDATEWR_latched_lookup_entry;
logic [BBO_W-1:0]       UPDATERDBK_UPDATEWR_latched_lookup_price_idx;
logic [SHARES_W-1:0]    UPDATERDBK_UPDATEWR_reduced_shares;
logic                   UPDATERDBK_UPDATEWR_full_exec;
logic [SHARES_W-1:0]    UPDATERDBK_UPDATEWR_latched_book_shares;
logic [SHARES_W-1:0]    UPDATERDBK_UPDATEWR_latched_event_shares;
logic [HASH_W-1:0]      UPDATERDBK_UPDATEWR_hash_idx;
logic [HASH_W-1:0]      UPDATERDBK_UPDATEWR_rep_hash_idx;
order_entry_t [2:0]     UPDATERDBK_UPDATEWR_read_bucket;
order_entry_t [2:0]     UPDATERDBK_UPDATEWR_rep_read_bucket;

// UPDATE_WRITE (& REPLACE_ADD) State registers - outputs
logic                   UPDATEWR_BBOEVAL_stage_valid;
o_data_t                UPDATEWR_BBOEVAL_latched_rdata;
logic [PRICE_W-1:0]     UPDATEWR_BBOEVAL_base_price;
logic                   UPDATEWR_BBOEVAL_is_add;
logic                   UPDATEWR_BBOEVAL_is_reduce;
logic                   UPDATEWR_BBOEVAL_is_replace;
logic                   UPDATEWR_BBOEVAL_is_delete;
logic [BBO_W-1:0]       UPDATEWR_BBOEVAL_latched_event_price_idx;
order_entry_t           UPDATEWR_BBOEVAL_latched_lookup_entry;
logic [BBO_W-1:0]       UPDATEWR_BBOEVAL_latched_lookup_price_idx;
logic [SHARES_W-1:0]    UPDATEWR_BBOEVAL_latched_book_shares;

// BBO Evaluation (EVALUATE_BBO & BBO_SEARCH_REQ) State registers - outputs
logic                   BBOEVAL_BBORESOLVE_stage_valid;
logic [PRICE_W-1:0]     BBOEVAL_BBORESOLVE_base_price;
logic [BBO_W-1:0]       BBOEVAL_BBORESOLVE_latched_event_price_idx;
order_entry_t           BBOEVAL_BBORESOLVE_latched_lookup_entry;
logic [BBO_W-1:0]       BBOEVAL_BBORESOLVE_latched_lookup_price_idx;
logic [SHARES_W-1:0]    BBOEVAL_BBORESOLVE_latched_book_shares;
logic [BBO_W-1:0]       BBOEVAL_BBORESOLVE_current_best_bid;
logic [BBO_W-1:0]       BBOEVAL_BBORESOLVE_current_best_ask;
logic                   BBOEVAL_BBORESOLVE_search_side;
logic                   BBOEVAL_BBORESOLVE_new_bbo;
logic [(BBO_W-7):0]     BBOEVAL_BBORESOLVE_target_chunk_idx;
logic                   BBOEVAL_BBORESOLVE_bid_is_zero;
logic                   BBOEVAL_BBORESOLVE_ask_is_zero;

// BBO Resolution (BBO_SEARCH_EVAL & FETCH_BBO) State registers - outputs
logic                   BBORESOLVE_BBOOUT_stage_valid;
logic [PRICE_W-1:0]     BBORESOLVE_BBOOUT_base_price;
logic [BBO_W-1:0]       FEEDBACK_current_best_bid;
logic [BBO_W-1:0]       FEEDBACK_current_best_ask;
logic                   BBORESOLVE_BBOOUT_bid_is_zero;
logic                   BBORESOLVE_BBOOUT_ask_is_zero;

// Sequential Logic handling the CLEAR state
always_ff @(posedge clk) begin
    if(!rst_n) begin
        clearing  <= 1'b1;
        clear_idx <= '0;
    end
    else if(clearing) begin
        if(clear_idx == BBO_W'(BBO_DEPTH-1)) begin
            clearing  <= 1'b0;
            clear_idx <= '0;
        end
        else clear_idx <= clear_idx + 1'b1;
    end
end

// Extended MUX (with claering select bit) ensuring complete clearing of books in a clear state

always_comb begin
    if(clearing) begin
        ot_we_a_m       = 1'b1;
        ot_wr_addr_a_m  = clear_idx[HASH_W-1:0];
        ot_din_a_m      = '0;
        bid_we_a_m      = 1'b1;
        bid_wr_addr_a_m = clear_idx;
        bid_din_a_m     = '0;
        ask_we_a_m      = 1'b1;
        ask_wr_addr_a_m = clear_idx;
        ask_din_a_m     = '0;
    end
    else begin
        ot_we_a_m       = ot_we_a;
        ot_wr_addr_a_m  = ot_wr_addr_a;
        ot_din_a_m      = ot_din_a;
        bid_we_a_m      = bid_we_a;
        bid_wr_addr_a_m = bid_wr_addr_a;
        bid_din_a_m     = bid_din_a;
        ask_we_a_m      = ask_we_a;
        ask_wr_addr_a_m = ask_wr_addr_a;
        ask_din_a_m     = ask_din_a;
    end
end

assign ready_o = rst_n && !clearing;

// Sequential BBO Logic - handles feedback within bbo blocks used in previous order book
always_ff @(posedge clk) begin
    if(!rst_n) begin
        current_best_bid <= '0;
        current_best_ask <= BBO_W'(BBO_DEPTH-1);
    end
    else if(BBOEVAL_BBORESOLVE_stage_valid) begin
        current_best_bid <= next_best_bid;
        current_best_ask <= next_best_ask;
    end
end

always_ff @(posedge clk) begin
    q_bid_chunk_a <= bid_chunk_a;
    q_bid_chunk_b <= bid_chunk_b;
    q_ask_chunk_a <= ask_chunk_a;
    q_ask_chunk_b <= ask_chunk_b;
end

assign same_word = chunk_we && chunk2_we && (chunk_side == chunk2_side) &&
                   (chunk_row[BBO_W-1:6] == chunk2_row[BBO_W-1:6]);

always_comb begin
    // defaults: channel 1 edits the lookup word (event word for adds), channel 2 the event word
    cw_we_bid  = 1'b0;
    cw_row_bid = chunk_row[BBO_W-1:6];
    cw_dat_bid = UPDATERDBK_UPDATEWR_is_add ? q_bid_chunk_b : q_bid_chunk_a;

    cw_we_ask  = 1'b0;
    cw_row_ask = chunk_row[BBO_W-1:6];
    cw_dat_ask = UPDATERDBK_UPDATEWR_is_add ? q_ask_chunk_b : q_ask_chunk_a;

    cw2_we_bid = 1'b0;  cw2_row_bid = chunk2_row[BBO_W-1:6];  cw2_dat_bid = q_bid_chunk_b;
    cw2_we_ask = 1'b0;  cw2_row_ask = chunk2_row[BBO_W-1:6];  cw2_dat_ask = q_ask_chunk_b;

    if(clearing) begin
        cw_we_bid  = 1'b1;  cw_row_bid = clear_idx[BBO_W-7:0];  cw_dat_bid = '0;
        cw_we_ask  = 1'b1;  cw_row_ask = clear_idx[BBO_W-7:0];  cw_dat_ask = '0;
    end
    else begin
        if(chunk_we) begin
            if(chunk_side) begin
                cw_we_bid = 1'b1;
                cw_dat_bid[chunk_row[5:0]] = chunk_val;
                if(same_word) cw_dat_bid[chunk2_row[5:0]] = chunk2_val;
            end
            else begin
                cw_we_ask = 1'b1;
                cw_dat_ask[chunk_row[5:0]] = chunk_val;
                if(same_word) cw_dat_ask[chunk2_row[5:0]] = chunk2_val;
            end
        end

        if(chunk2_we && !same_word) begin
            if(chunk2_side) begin
                cw2_we_bid = 1'b1;
                cw2_dat_bid[chunk2_row[5:0]] = chunk2_val;
            end
            else begin
                cw2_we_ask = 1'b1;
                cw2_dat_ask[chunk2_row[5:0]] = chunk2_val;
            end
        end
    end
end

// Sequential Logic dealing with clear state and clock synchronisation
always_ff @(posedge clk) begin
    if(!rst_n) begin
        bid_enc_valid <= '0;
        ask_enc_valid <= '0;
    end
    else if(clearing) begin
        if (clear_idx < BBO_W'(64)) begin
            cam[clear_idx[5:0]] <= '0;
        end
    end
    else begin
      if(cam_we) cam[cam_idx] <= cam_data;

      if(chunk_we) begin
        if(chunk_side) begin
            if(chunk_val) bid_enc_valid[chunk_row[BBO_W-1:6]] <= 1'b1;
            else if(q_bid_chunk_a == (64'h1 << chunk_row[5:0]))
                bid_enc_valid[chunk_row[BBO_W-1:6]] <= 1'b0;
        end
        else begin
            if(chunk_val) ask_enc_valid[chunk_row[BBO_W-1:6]] <= 1'b1;
            else if(q_ask_chunk_a == (64'h1 << chunk_row[5:0]))
                ask_enc_valid[chunk_row[BBO_W-1:6]] <= 1'b0;
        end
      end

      if(chunk2_we) begin
        if(chunk2_side) bid_enc_valid[chunk2_row[BBO_W-1:6]] <= 1'b1;
        else            ask_enc_valid[chunk2_row[BBO_W-1:6]] <= 1'b1;
      end
    end
end

// Order Book Pipelined Blocks

ob_idle idle_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(valid_i && !clearing),
    .rdata_i(rdata_i),
    .base_price_i(base_price_i),
    .stage_valid_o(IDLE_IDXREQ_stage_valid),
    .latched_rdata_o(IDLE_IDXREQ_latched_rdata),
    .latched_base_price_o(IDLE_IDXREQ_base_price),
    .latched_is_add_o(IDLE_IDXREQ_is_add),
    .latched_is_reduce_o(IDLE_IDXREQ_is_reduce),
    .latched_is_replace_o(IDLE_IDXREQ_is_replace),
    .latched_is_delete_o(IDLE_IDXREQ_is_delete),
    .hash_idx_o(ot_addr_a),
    .rep_hash_idx_o(ot_addr_b)
);

ob_idx_req idx_req_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(IDLE_IDXREQ_stage_valid),
    .latched_rdata_i(IDLE_IDXREQ_latched_rdata),
    .latched_base_price_i(IDLE_IDXREQ_base_price),
    .latched_is_add_i(IDLE_IDXREQ_is_add),
    .latched_is_reduce_i(IDLE_IDXREQ_is_reduce),
    .latched_is_replace_i(IDLE_IDXREQ_is_replace),
    .latched_is_delete_i(IDLE_IDXREQ_is_delete),
    .stage_valid_o(IDXREQ_IDXSEARCH_stage_valid),
    .latched_rdata_o(IDXREQ_IDXSEARCH_latched_rdata),
    .latched_base_price_o(IDXREQ_IDXSEARCH_base_price),
    .latched_is_add_o(IDXREQ_IDXSEARCH_is_add),
    .latched_is_reduce_o(IDXREQ_IDXSEARCH_is_reduce),
    .latched_is_replace_o(IDXREQ_IDXSEARCH_is_replace),
    .latched_is_delete_o(IDXREQ_IDXSEARCH_is_delete),
    .hash_idx_i(ot_addr_a),
    .rep_hash_idx_i(ot_addr_b),
    .latched_event_price_idx_o(IDXREQ_IDXSEARCH_latched_event_price_idx),
    .latched_cam_hit_o(IDXREQ_IDXSEARCH_cam_hit),
    .latched_cam_match_idx_o(IDXREQ_IDXSEARCH_cam_match_idx),
    .latched_cam_is_full_o(IDXREQ_IDXSEARCH_cam_is_full),
    .latched_cam_free_idx_o(IDXREQ_IDXSEARCH_cam_free_idx),
    .latched_hash_idx_o(IDXREQ_IDXSEARCH_hash_idx),
    .latched_rep_hash_idx_o(IDXREQ_IDXSEARCH_rep_hash_idx),
    .cam(cam)
);

ob_idx_search idx_search_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(IDXREQ_IDXSEARCH_stage_valid),
    .latched_rdata_i(IDXREQ_IDXSEARCH_latched_rdata),
    .latched_base_price_i(IDXREQ_IDXSEARCH_base_price),
    .latched_is_add_i(IDXREQ_IDXSEARCH_is_add),
    .latched_is_reduce_i(IDXREQ_IDXSEARCH_is_reduce),
    .latched_is_replace_i(IDXREQ_IDXSEARCH_is_replace),
    .latched_is_delete_i(IDXREQ_IDXSEARCH_is_delete),
    .stage_valid_o(IDXSEARCH_UPDATERDTBL_stage_valid),
    .latched_rdata_o(IDXSEARCH_UPDATERDTBL_latched_rdata),
    .latched_base_price_o(IDXSEARCH_UPDATERDTBL_base_price),
    .latched_is_add_o(IDXSEARCH_UPDATERDTBL_is_add),
    .latched_is_reduce_o(IDXSEARCH_UPDATERDTBL_is_reduce),
    .latched_is_replace_o(IDXSEARCH_UPDATERDTBL_is_replace),
    .latched_is_delete_o(IDXSEARCH_UPDATERDTBL_is_delete),
    .latched_event_price_idx_i(IDXREQ_IDXSEARCH_latched_event_price_idx),
    .latched_cam_hit_i(IDXREQ_IDXSEARCH_cam_hit),
    .latched_cam_match_idx_i(IDXREQ_IDXSEARCH_cam_match_idx),
    .latched_cam_free_idx_i(IDXREQ_IDXSEARCH_cam_free_idx),
    .latched_hash_idx_i(IDXREQ_IDXSEARCH_hash_idx),
    .latched_rep_hash_idx_i(IDXREQ_IDXSEARCH_rep_hash_idx),
    .latched_event_price_idx_o(IDXSEARCH_UPDATERDTBL_latched_event_price_idx),
    .latched_cam_hit_o(IDXSEARCH_UPDATERDTBL_cam_hit),
    .latched_cam_match_idx_o(IDXSEARCH_UPDATERDTBL_cam_match_idx),
    .latched_cam_free_idx_o(IDXSEARCH_UPDATERDTBL_cam_free_idx),
    .latched_slot_idx_o(IDXSEARCH_UPDATERDTBL_latched_slot_idx),
    .latched_rep_slot_idx_o(IDXSEARCH_UPDATERDTBL_latched_rep_slot_idx),
    .latched_free_slot_o(IDXSEARCH_UPDATERDTBL_latched_free_slot),
    .latched_hash_match_o(IDXSEARCH_UPDATERDTBL_latched_hash_match),
    .latched_hash_idx_o(IDXSEARCH_UPDATERDTBL_hash_idx),
    .latched_rep_hash_idx_o(IDXSEARCH_UPDATERDTBL_rep_hash_idx),
    .read_bucket_o(IDXSEARCH_UPDATERDTBL_read_bucket),
    .rep_read_bucket_o(IDXSEARCH_UPDATERDTBL_rep_read_bucket),
    .read_bucket_i(ot_dout_a),
    .rep_read_bucket_i(ot_dout_b)
);

ob_update_read_tbl update_read_tbl_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(IDXSEARCH_UPDATERDTBL_stage_valid),
    .latched_rdata_i(IDXSEARCH_UPDATERDTBL_latched_rdata),
    .latched_base_price_i(IDXSEARCH_UPDATERDTBL_base_price),
    .latched_is_add_i(IDXSEARCH_UPDATERDTBL_is_add),
    .latched_is_reduce_i(IDXSEARCH_UPDATERDTBL_is_reduce),
    .latched_is_replace_i(IDXSEARCH_UPDATERDTBL_is_replace),
    .latched_is_delete_i(IDXSEARCH_UPDATERDTBL_is_delete),
    .stage_valid_o(UPDATERDTBL_ISSUEBKRD_stage_valid),
    .latched_rdata_o(UPDATERDTBL_ISSUEBKRD_latched_rdata),
    .latched_base_price_o(UPDATERDTBL_ISSUEBKRD_base_price),
    .latched_is_add_o(UPDATERDTBL_ISSUEBKRD_is_add),
    .latched_is_reduce_o(UPDATERDTBL_ISSUEBKRD_is_reduce),
    .latched_is_replace_o(UPDATERDTBL_ISSUEBKRD_is_replace),
    .latched_is_delete_o(UPDATERDTBL_ISSUEBKRD_is_delete),
    .latched_event_price_idx_i(IDXSEARCH_UPDATERDTBL_latched_event_price_idx),
    .latched_cam_hit_i(IDXSEARCH_UPDATERDTBL_cam_hit),
    .latched_cam_match_idx_i(IDXSEARCH_UPDATERDTBL_cam_match_idx),
    .latched_cam_free_idx_i(IDXSEARCH_UPDATERDTBL_cam_free_idx),
    .latched_slot_idx_i(IDXSEARCH_UPDATERDTBL_latched_slot_idx),
    .latched_rep_slot_idx_i(IDXSEARCH_UPDATERDTBL_latched_rep_slot_idx),
    .latched_hash_match_i(IDXSEARCH_UPDATERDTBL_latched_hash_match),
    .latched_free_slot_i(IDXSEARCH_UPDATERDTBL_latched_free_slot),
    .latched_hash_idx_i(IDXSEARCH_UPDATERDTBL_hash_idx),
    .latched_rep_hash_idx_i(IDXSEARCH_UPDATERDTBL_rep_hash_idx),
    .latched_read_bucket_i(IDXSEARCH_UPDATERDTBL_read_bucket),
    .latched_rep_read_bucket_i(IDXSEARCH_UPDATERDTBL_rep_read_bucket),
    .latched_event_price_idx_o(UPDATERDTBL_ISSUEBKRD_latched_event_price_idx),
    .latched_is_cam_entry_o(UPDATERDTBL_ISSUEBKRD_is_cam_entry),
    .latched_cam_idx_o(UPDATERDTBL_ISSUEBKRD_latched_cam_idx),
    .latched_slot_idx_o(UPDATERDTBL_ISSUEBKRD_latched_slot_idx),
    .latched_rep_slot_idx_o(UPDATERDTBL_ISSUEBKRD_latched_rep_slot_idx),
    .latched_lookup_entry_o(UPDATERDTBL_ISSUEBKRD_latched_lookup_entry),
    .latched_hash_idx_o(UPDATERDTBL_ISSUEBKRD_hash_idx),
    .latched_rep_hash_idx_o(UPDATERDTBL_ISSUEBKRD_rep_hash_idx),
    .latched_read_bucket_o(UPDATERDTBL_ISSUEBKRD_read_bucket),
    .latched_rep_read_bucket_o(UPDATERDTBL_ISSUEBKRD_rep_read_bucket),
    .cam(cam)
);

ob_issue_book_read issue_book_read_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(UPDATERDTBL_ISSUEBKRD_stage_valid),
    .latched_rdata_i(UPDATERDTBL_ISSUEBKRD_latched_rdata),
    .latched_base_price_i(UPDATERDTBL_ISSUEBKRD_base_price),
    .latched_is_add_i(UPDATERDTBL_ISSUEBKRD_is_add),
    .latched_is_reduce_i(UPDATERDTBL_ISSUEBKRD_is_reduce),
    .latched_is_replace_i(UPDATERDTBL_ISSUEBKRD_is_replace),
    .latched_is_delete_i(UPDATERDTBL_ISSUEBKRD_is_delete),
    .stage_valid_o(ISSUEBKRD_UPDATERDBK_stage_valid),
    .latched_rdata_o(ISSUEBKRD_UPDATERDBK_latched_rdata),
    .latched_base_price_o(ISSUEBKRD_UPDATERDBK_base_price),
    .latched_is_add_o(ISSUEBKRD_UPDATERDBK_is_add),
    .latched_is_reduce_o(ISSUEBKRD_UPDATERDBK_is_reduce),
    .latched_is_replace_o(ISSUEBKRD_UPDATERDBK_is_replace),
    .latched_is_delete_o(ISSUEBKRD_UPDATERDBK_is_delete),
    .latched_event_price_idx_i(UPDATERDTBL_ISSUEBKRD_latched_event_price_idx),
    .latched_is_cam_entry_i(UPDATERDTBL_ISSUEBKRD_is_cam_entry),
    .latched_cam_idx_i(UPDATERDTBL_ISSUEBKRD_latched_cam_idx),
    .latched_slot_idx_i(UPDATERDTBL_ISSUEBKRD_latched_slot_idx),
    .latched_rep_slot_idx_i(UPDATERDTBL_ISSUEBKRD_latched_rep_slot_idx),
    .latched_lookup_entry_i(UPDATERDTBL_ISSUEBKRD_latched_lookup_entry),
    .latched_hash_idx_i(UPDATERDTBL_ISSUEBKRD_hash_idx),
    .latched_rep_hash_idx_i(UPDATERDTBL_ISSUEBKRD_rep_hash_idx),
    .latched_read_bucket_i(UPDATERDTBL_ISSUEBKRD_read_bucket),
    .latched_rep_read_bucket_i(UPDATERDTBL_ISSUEBKRD_rep_read_bucket),
    .latched_event_price_idx_o(ISSUEBKRD_UPDATERDBK_latched_event_price_idx),
    .latched_is_cam_entry_o(ISSUEBKRD_UPDATERDBK_is_cam_entry),
    .latched_cam_idx_o(ISSUEBKRD_UPDATERDBK_latched_cam_idx),
    .latched_slot_idx_o(ISSUEBKRD_UPDATERDBK_latched_slot_idx),
    .latched_rep_slot_idx_o(ISSUEBKRD_UPDATERDBK_latched_rep_slot_idx),
    .latched_lookup_entry_o(ISSUEBKRD_UPDATERDBK_latched_lookup_entry),
    .latched_lookup_price_idx_o(ISSUEBKRD_UPDATERDBK_latched_lookup_price_idx),
    .latched_hash_idx_o(ISSUEBKRD_UPDATERDBK_hash_idx),
    .latched_rep_hash_idx_o(ISSUEBKRD_UPDATERDBK_rep_hash_idx),
    .latched_read_bucket_o(ISSUEBKRD_UPDATERDBK_read_bucket),
    .latched_rep_read_bucket_o(ISSUEBKRD_UPDATERDBK_rep_read_bucket),
    .bid_addr_a(bid_addr_a),
    .ask_addr_a(ask_addr_a),
    .bid_addr_b(bid_addr_b),
    .ask_addr_b(ask_addr_b)
);

ob_update_read_book update_read_book_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(ISSUEBKRD_UPDATERDBK_stage_valid),
    .latched_rdata_i(ISSUEBKRD_UPDATERDBK_latched_rdata),
    .latched_base_price_i(ISSUEBKRD_UPDATERDBK_base_price),
    .latched_is_add_i(ISSUEBKRD_UPDATERDBK_is_add),
    .latched_is_reduce_i(ISSUEBKRD_UPDATERDBK_is_reduce),
    .latched_is_replace_i(ISSUEBKRD_UPDATERDBK_is_replace),
    .latched_is_delete_i(ISSUEBKRD_UPDATERDBK_is_delete),
    .stage_valid_o(UPDATERDBK_UPDATEWR_stage_valid),
    .latched_rdata_o(UPDATERDBK_UPDATEWR_latched_rdata),
    .latched_base_price_o(UPDATERDBK_UPDATEWR_base_price),
    .latched_is_add_o(UPDATERDBK_UPDATEWR_is_add),
    .latched_is_reduce_o(UPDATERDBK_UPDATEWR_is_reduce),
    .latched_is_replace_o(UPDATERDBK_UPDATEWR_is_replace),
    .latched_is_delete_o(UPDATERDBK_UPDATEWR_is_delete),
    .latched_event_price_idx_i(ISSUEBKRD_UPDATERDBK_latched_event_price_idx),
    .latched_is_cam_entry_i(ISSUEBKRD_UPDATERDBK_is_cam_entry),
    .latched_cam_idx_i(ISSUEBKRD_UPDATERDBK_latched_cam_idx),
    .latched_slot_idx_i(ISSUEBKRD_UPDATERDBK_latched_slot_idx),
    .latched_rep_slot_idx_i(ISSUEBKRD_UPDATERDBK_latched_rep_slot_idx),
    .latched_lookup_entry_i(ISSUEBKRD_UPDATERDBK_latched_lookup_entry),
    .latched_lookup_price_idx_i(ISSUEBKRD_UPDATERDBK_latched_lookup_price_idx),
    .latched_hash_idx_i(ISSUEBKRD_UPDATERDBK_hash_idx),
    .latched_rep_hash_idx_i(ISSUEBKRD_UPDATERDBK_rep_hash_idx),
    .latched_read_bucket_i(ISSUEBKRD_UPDATERDBK_read_bucket),
    .latched_rep_read_bucket_i(ISSUEBKRD_UPDATERDBK_rep_read_bucket),
    .latched_event_price_idx_o(UPDATERDBK_UPDATEWR_latched_event_price_idx),
    .latched_is_cam_entry_o(UPDATERDBK_UPDATEWR_is_cam_entry),
    .latched_cam_idx_o(UPDATERDBK_UPDATEWR_latched_cam_idx),
    .latched_slot_idx_o(UPDATERDBK_UPDATEWR_latched_slot_idx),
    .latched_rep_slot_idx_o(UPDATERDBK_UPDATEWR_latched_rep_slot_idx),
    .latched_lookup_entry_o(UPDATERDBK_UPDATEWR_latched_lookup_entry),
    .latched_lookup_price_idx_o(UPDATERDBK_UPDATEWR_latched_lookup_price_idx),
    .latched_reduced_shares_o(UPDATERDBK_UPDATEWR_reduced_shares),
    .latched_full_exec_o(UPDATERDBK_UPDATEWR_full_exec),
    .latched_book_shares_o(UPDATERDBK_UPDATEWR_latched_book_shares),
    .latched_event_shares_o(UPDATERDBK_UPDATEWR_latched_event_shares),
    .latched_hash_idx_o(UPDATERDBK_UPDATEWR_hash_idx),
    .latched_rep_hash_idx_o(UPDATERDBK_UPDATEWR_rep_hash_idx),
    .latched_read_bucket_o(UPDATERDBK_UPDATEWR_read_bucket),
    .latched_rep_read_bucket_o(UPDATERDBK_UPDATEWR_rep_read_bucket),
    .bid_dout_a(bid_dout_a),
    .bid_dout_b(bid_dout_b),
    .ask_dout_a(ask_dout_a),
    .ask_dout_b(ask_dout_b)
);

ob_update_write update_write_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(UPDATERDBK_UPDATEWR_stage_valid),
    .latched_rdata_i(UPDATERDBK_UPDATEWR_latched_rdata),
    .latched_base_price_i(UPDATERDBK_UPDATEWR_base_price),
    .latched_is_add_i(UPDATERDBK_UPDATEWR_is_add),
    .latched_is_reduce_i(UPDATERDBK_UPDATEWR_is_reduce),
    .latched_is_replace_i(UPDATERDBK_UPDATEWR_is_replace),
    .latched_is_delete_i(UPDATERDBK_UPDATEWR_is_delete),
    .stage_valid_o(UPDATEWR_BBOEVAL_stage_valid),
    .latched_rdata_o(UPDATEWR_BBOEVAL_latched_rdata),
    .latched_base_price_o(UPDATEWR_BBOEVAL_base_price),
    .latched_is_add_o(UPDATEWR_BBOEVAL_is_add),
    .latched_is_reduce_o(UPDATEWR_BBOEVAL_is_reduce),
    .latched_is_replace_o(UPDATEWR_BBOEVAL_is_replace),
    .latched_is_delete_o(UPDATEWR_BBOEVAL_is_delete),
    .latched_event_price_idx_i(UPDATERDBK_UPDATEWR_latched_event_price_idx),
    .latched_is_cam_entry_i(UPDATERDBK_UPDATEWR_is_cam_entry),
    .latched_cam_idx_i(UPDATERDBK_UPDATEWR_latched_cam_idx),
    .latched_slot_idx_i(UPDATERDBK_UPDATEWR_latched_slot_idx),
    .latched_rep_slot_idx_i(UPDATERDBK_UPDATEWR_latched_rep_slot_idx),
    .latched_lookup_entry_i(UPDATERDBK_UPDATEWR_latched_lookup_entry),
    .latched_lookup_price_idx_i(UPDATERDBK_UPDATEWR_latched_lookup_price_idx),
    .latched_reduced_shares_i(UPDATERDBK_UPDATEWR_reduced_shares),
    .latched_full_exec_i(UPDATERDBK_UPDATEWR_full_exec),
    .latched_book_shares_i(UPDATERDBK_UPDATEWR_latched_book_shares),
    .latched_event_shares_i(UPDATERDBK_UPDATEWR_latched_event_shares),
    .latched_hash_idx_i(UPDATERDBK_UPDATEWR_hash_idx),
    .latched_rep_hash_idx_i(UPDATERDBK_UPDATEWR_rep_hash_idx),
    .latched_read_bucket_i(UPDATERDBK_UPDATEWR_read_bucket),
    .latched_rep_read_bucket_i(UPDATERDBK_UPDATEWR_rep_read_bucket),
    .latched_event_price_idx_o(UPDATEWR_BBOEVAL_latched_event_price_idx),
    .latched_lookup_entry_o(UPDATEWR_BBOEVAL_latched_lookup_entry),
    .latched_lookup_price_idx_o(UPDATEWR_BBOEVAL_latched_lookup_price_idx),
    .latched_book_shares_o(UPDATEWR_BBOEVAL_latched_book_shares),
    .cam_we_o(cam_we),
    .cam_idx_o(cam_idx),
    .cam_data_o(cam_data),
    .chunk_we_o(chunk_we),
    .chunk_side_o(chunk_side),
    .chunk_row_o(chunk_row),
    .chunk_val_o(chunk_val),
    .chunk2_we_o(chunk2_we),
    .chunk2_side_o(chunk2_side),
    .chunk2_row_o(chunk2_row),
    .chunk2_val_o(chunk2_val),
    .we_a(ot_we_a),
    .addr_a(ot_wr_addr_a),
    .din_a(ot_din_a),
    .bid_we_a(bid_we_a),
    .bid_addr_a(bid_wr_addr_a),
    .bid_din_a(bid_din_a),
    .ask_we_a(ask_we_a),
    .ask_addr_a(ask_wr_addr_a),
    .ask_din_a(ask_din_a),
    .we_b(ot_we_b),
    .addr_b(ot_wr_addr_b),
    .din_b(ot_din_b),
    .bid_we_b(bid_we_b),
    .bid_addr_b(bid_wr_addr_b),
    .bid_din_b(bid_din_b),
    .ask_we_b(ask_we_b),
    .ask_addr_b(ask_wr_addr_b),
    .ask_din_b(ask_din_b)
);

ob_evaluate_bbo evaluate_bbo_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(UPDATEWR_BBOEVAL_stage_valid),
    .latched_rdata_i(UPDATEWR_BBOEVAL_latched_rdata),
    .latched_base_price_i(UPDATEWR_BBOEVAL_base_price),
    .latched_is_add_i(UPDATEWR_BBOEVAL_is_add),
    .latched_is_reduce_i(UPDATEWR_BBOEVAL_is_reduce),
    .latched_is_replace_i(UPDATEWR_BBOEVAL_is_replace),
    .latched_is_delete_i(UPDATEWR_BBOEVAL_is_delete),
    .stage_valid_o(BBOEVAL_BBORESOLVE_stage_valid),
    .latched_base_price_o(BBOEVAL_BBORESOLVE_base_price),
    .latched_event_price_idx_i(UPDATEWR_BBOEVAL_latched_event_price_idx),
    .latched_lookup_entry_i(UPDATEWR_BBOEVAL_latched_lookup_entry),
    .latched_lookup_price_idx_i(UPDATEWR_BBOEVAL_latched_lookup_price_idx),
    .latched_book_shares_i(UPDATEWR_BBOEVAL_latched_book_shares),
    .current_best_bid_i(current_best_bid),
    .current_best_ask_i(current_best_ask),
    .bid_enc_valid_i(bid_enc_valid),
    .ask_enc_valid_i(ask_enc_valid),
    .current_best_bid_o(BBOEVAL_BBORESOLVE_current_best_bid),
    .current_best_ask_o(BBOEVAL_BBORESOLVE_current_best_ask),
    .search_side_o(BBOEVAL_BBORESOLVE_search_side),
    .new_bbo_o(BBOEVAL_BBORESOLVE_new_bbo),
    .target_chunk_idx_o(BBOEVAL_BBORESOLVE_target_chunk_idx),
    .next_target_chunk_idx_o(next_target_chunk_idx),
    .bid_is_zero_o(BBOEVAL_BBORESOLVE_bid_is_zero),
    .ask_is_zero_o(BBOEVAL_BBORESOLVE_ask_is_zero)
);

ob_bbo_resolve bbo_resolve_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(BBOEVAL_BBORESOLVE_stage_valid),
    .latched_base_price_i(BBOEVAL_BBORESOLVE_base_price),
    .stage_valid_o(BBORESOLVE_BBOOUT_stage_valid),
    .latched_base_price_o(BBORESOLVE_BBOOUT_base_price),
    .target_bid_chunk_i(current_bid_chunk),
    .target_ask_chunk_i(current_ask_chunk),
    .current_best_bid_i(BBOEVAL_BBORESOLVE_current_best_bid),
    .current_best_ask_i(BBOEVAL_BBORESOLVE_current_best_ask),
    .search_side_i(BBOEVAL_BBORESOLVE_search_side),
    .new_bbo_i(BBOEVAL_BBORESOLVE_new_bbo),
    .target_chunk_idx_i(BBOEVAL_BBORESOLVE_target_chunk_idx),
    .bid_is_zero_i(BBOEVAL_BBORESOLVE_bid_is_zero),
    .ask_is_zero_i(BBOEVAL_BBORESOLVE_ask_is_zero),
    .next_best_bid_o(next_best_bid),
    .next_best_ask_o(next_best_ask),
    .bbo_rd_bid_addr_o(bbo_rd_bid_addr),
    .bbo_rd_ask_addr_o(bbo_rd_ask_addr),
    .bid_is_zero_o(BBORESOLVE_BBOOUT_bid_is_zero),
    .ask_is_zero_o(BBORESOLVE_BBOOUT_ask_is_zero)
);

ob_bbo_out bbo_out_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(BBORESOLVE_BBOOUT_stage_valid),
    .latched_base_price_i(BBORESOLVE_BBOOUT_base_price),
    .bid_dout_a(bbo_bid_dout),
    .ask_dout_a(bbo_ask_dout),
    .current_best_bid_i(current_best_bid),
    .current_best_ask_i(current_best_ask),
    .bid_is_zero_i(BBORESOLVE_BBOOUT_bid_is_zero),
    .ask_is_zero_i(BBORESOLVE_BBOOUT_ask_is_zero),
    .bbo_data_o(bbo_data_o),
    .bbo_valid_o(bbo_valid_o)
);

// Multi Pumped BRAM blocks for the 3 books

multi_pumped_bram #(
    .ADDRESS_W(HASH_W),
    .DATA_W(BUCKET_W)
) order_table(
    .bram_clk(bram_clk),
    .rst_n(rst_n),
    .rd_addr_a(ot_addr_a),
    .rd_addr_b(ot_addr_b),
    .rd_data_a(ot_dout_a),
    .rd_data_b(ot_dout_b),
    .wr_we_a(ot_we_a_m),
    .wr_we_b(ot_we_b),
    .wr_addr_a(ot_wr_addr_a_m),
    .wr_addr_b(ot_wr_addr_b),
    .wr_data_a(ot_din_a_m),
    .wr_data_b(ot_din_b)
);

multi_pumped_bram #(
    .ADDRESS_W(BBO_W),
    .DATA_W(SHARES_W)
) bid_price_book(
    .bram_clk(bram_clk),
    .rst_n(rst_n),
    .rd_addr_a(bid_addr_a),
    .rd_addr_b(bid_addr_b),
    .rd_data_a(bid_dout_a),
    .rd_data_b(bid_dout_b),
    .wr_we_a(bid_we_a_m),
    .wr_we_b(bid_we_b),
    .wr_addr_a(bid_wr_addr_a_m),
    .wr_addr_b(bid_wr_addr_b),
    .wr_data_a(bid_din_a_m),
    .wr_data_b(bid_din_b)
);

multi_pumped_bram #(
    .ADDRESS_W(BBO_W),
    .DATA_W(SHARES_W)
) ask_price_book(
    .bram_clk(bram_clk),
    .rst_n(rst_n),
    .rd_addr_a(ask_addr_a),
    .rd_addr_b(ask_addr_b),
    .rd_data_a(ask_dout_a),
    .rd_data_b(ask_dout_b),
    .wr_we_a(ask_we_a_m),
    .wr_we_b(ask_we_b),
    .wr_addr_a(ask_wr_addr_a_m),
    .wr_addr_b(ask_wr_addr_b),
    .wr_data_a(ask_din_a_m),
    .wr_data_b(ask_din_b)
);

// Multi-pumped BRAM blocks to replicate price books
// This is because the there are 3 simultaneous read requests in the pipeline

multi_pumped_bram #(
    .ADDRESS_W(BBO_W),
    .DATA_W(SHARES_W)
) shadow_bid_price_book(
    .bram_clk(bram_clk),
    .rst_n(rst_n),
    .rd_addr_a(next_best_bid),
    .rd_addr_b('0),
    .rd_data_a(bbo_bid_dout),
    .rd_data_b(),
    .wr_we_a(bid_we_a_m),
    .wr_we_b(bid_we_b),
    .wr_addr_a(bid_wr_addr_a_m),
    .wr_addr_b(bid_wr_addr_b),
    .wr_data_a(bid_din_a_m),
    .wr_data_b(bid_din_b)
);

multi_pumped_bram #(
    .ADDRESS_W(BBO_W),
    .DATA_W(SHARES_W)
) shadow_ask_price_book(
    .bram_clk(bram_clk),
    .rst_n(rst_n),
    .rd_addr_a(next_best_ask),
    .rd_addr_b('0),
    .rd_data_a(bbo_ask_dout),
    .rd_data_b(),
    .wr_we_a(ask_we_a_m),
    .wr_we_b(ask_we_b),
    .wr_addr_a(ask_wr_addr_a_m),
    .wr_addr_b(ask_wr_addr_b),
    .wr_data_a(ask_din_a_m),
    .wr_data_b(ask_din_b)
);

multi_pumped_bram #(
    .ADDRESS_W(BBO_W-6),
    .DATA_W(64)
) bid_chunks(
    .bram_clk(bram_clk),
    .rst_n(rst_n),
    .rd_addr_a(bid_addr_a[BBO_W-1:6]),
    .rd_addr_b(bid_addr_b[BBO_W-1:6]),
    .rd_data_a(bid_chunk_a),
    .rd_data_b(bid_chunk_b),
    .wr_we_a(cw_we_bid),
    .wr_addr_a(cw_row_bid),
    .wr_data_a(cw_dat_bid),
    .wr_we_b(cw2_we_bid),
    .wr_addr_b(cw2_row_bid),
    .wr_data_b(cw2_dat_bid)
);

multi_pumped_bram #(
    .ADDRESS_W(BBO_W-6),
    .DATA_W(64)
) ask_chunks (
    .bram_clk(bram_clk),
    .rst_n(rst_n),
    .rd_addr_a(ask_addr_a[BBO_W-1:6]),
    .rd_addr_b(ask_addr_b[BBO_W-1:6]),
    .rd_data_a(ask_chunk_a),
    .rd_data_b(ask_chunk_b),
    .wr_we_a(cw_we_ask),
    .wr_addr_a(cw_row_ask),
    .wr_data_a(cw_dat_ask),
    .wr_we_b(cw2_we_ask),
    .wr_addr_b(cw2_row_ask),
    .wr_data_b(cw2_dat_ask)
);

multi_pumped_bram #(
    .ADDRESS_W(BBO_W-6),
    .DATA_W(64)
) shadow_bid_chunks (
    .bram_clk(bram_clk),
    .rst_n(rst_n),
    .rd_addr_a(next_target_chunk_idx),
    .rd_addr_b('0),
    .rd_data_a(current_bid_chunk),
    .rd_data_b(),
    .wr_we_a(cw_we_bid),
    .wr_addr_a(cw_row_bid),
    .wr_data_a(cw_dat_bid),
    .wr_we_b(cw2_we_bid),
    .wr_addr_b(cw2_row_bid),
    .wr_data_b(cw2_dat_bid)
);

multi_pumped_bram #(
    .ADDRESS_W(BBO_W-6),
    .DATA_W(64)
) shadow_ask_chunks (
    .bram_clk(bram_clk),
    .rst_n(rst_n),
    .rd_addr_a(next_target_chunk_idx),
    .rd_addr_b('0),
    .rd_data_a(current_ask_chunk),
    .rd_data_b(),
    .wr_we_a(cw_we_ask),
    .wr_addr_a(cw_row_ask),
    .wr_data_a(cw_dat_ask),
    .wr_we_b(cw2_we_ask),
    .wr_addr_b(cw2_row_ask),
    .wr_data_b(cw2_dat_ask)
);

endmodule
