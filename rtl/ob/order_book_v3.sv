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
order_entry_t           ot_dout_a;
order_entry_t           ot_dout_b;

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

// CAM control pins
logic                   cam_we;
logic [5:0]             cam_idx;
order_entry_t           cam_data;

// Active Chunks control pins
logic                   chunk_we;
logic                   chunk_side;
logic [BBO_W-1:0]       chunk_row;
logic                   chunk_val;

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
logic                   UPDATERDBK_UPDATEWR_reg_target_val;
logic [BBO_W-1:0]       UPDATERDBK_UPDATEWR_reg_chosen_row;
logic                   UPDATERDBK_UPDATEWR_reg_target_side;
logic                   UPDATERDBK_UPDATEWR_reg_we_en;
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
logic                   UPDATEWR_BBOEVAL_reg_target_val;
logic [BBO_W-1:0]       UPDATEWR_BBOEVAL_reg_chosen_row;
logic                   UPDATEWR_BBOEVAL_reg_target_side;
logic                   UPDATEWR_BBOEVAL_reg_we_en;
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


// Sequential Logic dealing with clear state and clock synchronisation
always_ff @(posedge clk) begin
    if(!rst_n) begin
        for(int i = 0; i < CHUNK_LEN; i++) begin
            bid_active_chunks[i] <= '0;
            ask_active_chunks[i] <= '0;
        end
        bid_enc_valid   <=  '0;
        ask_enc_valid   <=  '0;
        for(int i = 0; i < 64; i++) cam[i]  <=  '0;

        ready_o <=  1'b0;
    end
    else begin
      ready_o   <=  1'b1;
      // REMEMBER TO HAVE TO CAM UPDATE LOGIC & ACTIVE CHUNKS UPDATE LOGIC HERE
      if(cam_we) cam[cam_idx]   <=    cam_data;

      if(chunk_we) begin
        if(chunk_side) begin
            bid_active_chunks[chunk_row[BBO_W-1:6]][chunk_row[5:0]] <=  chunk_val;
            if(chunk_val) bid_enc_valid[chunk_row[BBO_W-1:6]]   <=  1'b1;
            else if(bid_active_chunks[chunk_row[BBO_W-1:6]] == (64'h1 << chunk_row[5:0]))
            bid_enc_valid[chunk_row[BBO_W-1:6]] <=  1'b0;
        end
        else begin
            ask_active_chunks[chunk_row[BBO_W-1:6]][chunk_row[5:0]] <=  chunk_val;
            if(chunk_val) ask_enc_valid[chunk_row[BBO_W-1:6]]   <=  1'b1;
            else if(ask_active_chunks[chunk_row[BBO_W-1:6]] == (64'h1 << chunk_row[5:0]))
            ask_enc_valid[chunk_row[BBO_W-1:6]] <=  1'b0;
        end
      end
    end
end

// Order Book Pipelined Blocks


ob_idle idle_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(valid_i),
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
    .stage_valid_i(IDLE_IDXREQ_stage_valid),
    .latched_rdata_i(IDLE_IDXREQ_latched_rdata),
    .latched_base_price_i(IDLE_IDXREQ_base_price),
    .latched_is_add_i(IDLE_IDXREQ_is_add),
    .latched_is_reduce_i(IDLE_IDXREQ_is_reduce),
    .latched_is_replace_i(IDLE_IDXREQ_is_replace),
    .latched_is_delete_i(IDLE_IDXREQ_is_delete),
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
    .read_bucket_i(ot_din_a),
    .rep_read_bucket_i(ot_din_b)
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
    .latched_cam_idx_o(UPDATERDTBL_ISSUEBKRD_cam_match_idx),
    .latched_slot_idx_o(UPDATERDTBL_ISSUEBKRD_latched_slot_idx),
    .latched_rep_slot_idx_o(UPDATERDTBL_ISSUEBKRD_latched_rep_slot_idx),
    .latched_lookup_entry_o(UPDATERDTBL_ISSUEBKRD_latched_lookup_entry),
    .latched_hash_idx_o(UPDATERDTBL_ISSUEBKRD_hash_idx),
    .latched_rep_hash_idx_o(UPDATERDTBL_ISSUEBKRD_rep_hash_idx),
    .latched_read_bucket_o(UPDATERDTBL_ISSUEBKRD_read_bucket),
    .latched_rep_read_bucket_o(UPDATERDTBL_ISSUEBKRD_rep_read_bucket),
    .dout_a(ot_dout_a),
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
    .latched_slot_idx_i(UPDATERDTBL_ISSUEBKRD_latched_slot_idx),
    .latched_rep_slot_idx_i(UPDATERDTBL_ISSUEBKRD_latched_rep_slot_idx),
    .latched_lookup_entry_i(UPDATERDTBL_ISSUEBKRD_latched_lookup_entry),
    .latched_hash_idx_i(UPDATERDTBL_ISSUEBKRD_hash_idx),
    .latched_rep_hash_idx_i(UPDATERDTBL_ISSUEBKRD_rep_hash_idx),
    .latched_read_bucket_i(UPDATERDTBL_ISSUEBKRD_read_bucket),
    .latched_rep_read_bucket_i(UPDATERDTBL_ISSUEBKRD_rep_read_bucket),
    .latched_event_price_idx_o(ISSUEBKRD_UPDATERDBK_latched_event_price_idx),
    .latched_is_cam_entry_o(ISSUEBKRD_UPDATERDBK_is_cam_entry),
    .latched_cam_idx_o(ISSUEBKRD_UPDATERDBK_cam_match_idx),
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
    .reg_target_val_o(UPDATERDBK_UPDATEWR_reg_target_val),
    .reg_chosen_row_o(UPDATERDBK_UPDATEWR_reg_chosen_row),
    .reg_target_side_o(UPDATERDBK_UPDATEWR_reg_target_side),
    .reg_we_en_o(UPDATERDBK_UPDATEWR_reg_we_en),
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
    .reg_target_val_i(UPDATERDBK_UPDATEWR_reg_target_val),
    .reg_chosen_row_i(UPDATERDBK_UPDATEWR_reg_chosen_row),
    .reg_target_side_i(UPDATERDBK_UPDATEWR_reg_target_side),
    .reg_we_en_i(UPDATERDBK_UPDATEWR_reg_we_en),
    .latched_book_shares_i(UPDATERDBK_UPDATEWR_latched_book_shares),
    .latched_event_shares_i(UPDATERDBK_UPDATEWR_latched_event_shares),
    .latched_hash_idx_i(UPDATERDBK_UPDATEWR_hash_idx),
    .latched_rep_hash_idx_i(UPDATERDBK_UPDATEWR_rep_hash_idx),
    .latched_read_bucket_i(UPDATERDBK_UPDATEWR_read_bucket),
    .latched_rep_read_bucket_i(UPDATERDBK_UPDATEWR_rep_read_bucket),
    .latched_event_price_idx_o(UPDATEWR_BBOEVAL_latched_event_price_idx),
    .latched_is_cam_entry_o(UPDATEWR_BBOEVAL_is_cam_entry),
    .latched_lookup_entry_o(UPDATEWR_BBOEVAL_latched_lookup_entry),
    .latched_lookup_price_idx_o(UPDATEWR_BBOEVAL_latched_lookup_price_idx),
    .reg_target_val_o(UPDATEWR_BBOEVAL_reg_target_val),
    .reg_chosen_row_o(UPDATEWR_BBOEVAL_reg_chosen_row),
    .reg_target_side_o(UPDATEWR_BBOEVAL_reg_target_side),
    .reg_we_en_o(UPDATEWR_BBOEVAL_reg_we_en),
    .latched_book_shares_o(UPDATEWR_BBOEVAL_latched_book_shares),
    .cam_we_o(cam_we),
    .cam_idx_o(cam_idx),
    .cam_data_o(cam_data),
    .chunk_we_o(chunk_we),
    .chunk_side_o(chunk_side),
    .chunk_row_o(chunk_row),
    .chunk_val_o(chunk_val),
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
    .current_best_bid_i(FEEDBACK_current_best_bid),
    .current_best_ask_i(FEEDBACK_current_best_ask),
    .bid_enc_valid_i(bid_enc_valid),
    .ask_enc_valid_i(ask_enc_valid),
    .current_best_bid_o(BBOEVAL_BBORESOLVE_current_best_bid),
    .current_best_ask_o(BBOEVAL_BBORESOLVE_current_best_ask),
    .search_side_o(BBOEVAL_BBORESOLVE_search_side),
    .new_bbo_o(BBOEVAL_BBORESOLVE_new_bbo),
    .target_chunk_idx_o(BBOEVAL_BBORESOLVE_target_chunk_idx),
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
    .bid_active_chunks(bid_active_chunks),
    .ask_active_chunks(ask_active_chunks),
    .current_best_bid_i(BBOEVAL_BBORESOLVE_current_best_bid),
    .current_best_ask_i(BBOEVAL_BBORESOLVE_current_best_ask),
    .search_side_i(BBOEVAL_BBORESOLVE_search_side),
    .new_bbo_i(BBOEVAL_BBORESOLVE_new_bbo),
    .target_chunk_idx_i(BBOEVAL_BBORESOLVE_target_chunk_idx),
    .bid_is_zero_i(BBOEVAL_BBORESOLVE_bid_is_zero),
    .ask_is_zero_i(BBOEVAL_BBORESOLVE_ask_is_zero),
    .current_best_bid_o(FEEDBACK_current_best_bid),
    .current_best_ask_o(FEEDBACK_current_best_ask),
    .bid_is_zero_o(BBORESOLVE_BBOOUT_bid_is_zero),
    .ask_is_zero_o(BBORESOLVE_BBOOUT_ask_is_zero)
);

ob_bbo_out bbo_out_block(
    .clk(clk),
    .rst_n(rst_n),
    .stage_valid_i(BBORESOLVE_BBOOUT_stage_valid),
    .latched_base_price_i(BBORESOLVE_BBOOUT_base_price),
    .bid_we_a(bid_we_a),
    .bid_addr_a(bid_wr_addr_a),
    .bid_din_a(bid_din_a),
    .bid_dout_a(bbo_bid_dout),
    .bid_we_b(bid_we_b),
    .bid_addr_b(bid_wr_addr_b),
    .bid_din_b(bid_din_b),
    .ask_we_a(ask_we_a),
    .ask_addr_a(ask_wr_addr_a),
    .ask_din_a(ask_din_a),
    .ask_dout_a(bbo_ask_dout),
    .ask_we_b(ask_we_b),
    .ask_addr_b(ask_wr_addr_b),
    .ask_din_b(ask_din_b),
    .current_best_bid_i(FEEDBACK_current_best_bid),
    .current_best_ask_i(FEEDBACK_current_best_ask),
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
    .wr_we_a(ot_we_a),
    .wr_we_b(ot_we_b),
    .wr_addr_a(ot_wr_addr_a),
    .wr_addr_b(ot_wr_addr_b),
    .wr_data_a(ot_din_a),
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
    .wr_we_a(bid_we_a),
    .wr_we_b(bid_we_b),
    .wr_addr_a(bid_wr_addr_a),
    .wr_addr_b(bid_wr_addr_b),
    .wr_data_a(bid_din_a),
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
    .wr_we_a(ask_we_a),
    .wr_we_b(ask_we_b),
    .wr_addr_a(ask_wr_addr_a),
    .wr_addr_b(ask_wr_addr_b),
    .wr_data_a(ask_din_a),
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
    .rd_addr_a(FEEDBACK_current_best_bid),
    .rd_addr_b('0),
    .rd_data_a(bbo_bid_dout),
    .rd_data_b(),
    .wr_we_a(bid_we_a),
    .wr_we_b(bid_we_b),
    .wr_addr_a(bid_wr_addr_a),
    .wr_addr_b(bid_wr_addr_b),
    .wr_data_a(bid_din_a),
    .wr_data_b(bid_din_b)
);

multi_pumped_bram #(
    .ADDRESS_W(BBO_W),
    .DATA_W(SHARES_W)
) shadow_ask_price_book(
    .bram_clk(bram_clk),
    .rst_n(rst_n),
    .rd_addr_a(FEEDBACK_current_best_ask),
    .rd_addr_b('0),
    .rd_data_a(bbo_ask_dout),
    .rd_data_b(),
    .wr_we_a(ask_we_a),
    .wr_we_b(ask_we_b),
    .wr_addr_a(ask_wr_addr_a),
    .wr_addr_b(ask_wr_addr_b),
    .wr_data_a(ask_din_a),
    .wr_data_b(ask_din_b)
);

endmodule
