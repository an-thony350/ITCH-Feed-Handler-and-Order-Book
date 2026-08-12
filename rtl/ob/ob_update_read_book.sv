import hdl_header::*;

module ob_update_read_book(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,
    input logic                 stall,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input o_data_t              latched_rdata_i,
    input logic [PRICE_W-1:0]   latched_base_price_i,
    input logic                 latched_is_add_i,
    input logic                 latched_is_reduce_i,
    input logic                 latched_is_replace_i,
    input logic                 latched_is_delete_i,

    output logic                stage_valid_o,
    output o_data_t             latched_rdata_o,
    output logic [PRICE_W-1:0]  latched_base_price_o,
    output logic                latched_is_add_o,
    output logic                latched_is_reduce_o,
    output logic                latched_is_replace_o,
    output logic                latched_is_delete_o,

    // Computed DataPath I/O
    input logic [BBO_W-1:0]     latched_event_price_idx_i,
    input logic                 latched_is_cam_entry_i,
    input logic [5:0]           latched_cam_idx_i,
    input logic [1:0]           latched_slot_idx_i,
    input logic [1:0]           latched_rep_slot_idx_i,
    input order_entry_t         latched_lookup_entry_i,
    input logic [BBO_W-1:0]     latched_lookup_price_idx_i,
    input logic [HASH_W-1:0]    latched_hash_idx_i,
    input logic [HASH_W-1:0]    latched_rep_hash_idx_i,
    input order_entry_t [2:0]   latched_read_bucket_i,
    input order_entry_t [2:0]   latched_rep_read_bucket_i,

    output logic [BBO_W-1:0]    latched_event_price_idx_o,
    output logic                latched_is_cam_entry_o,
    output logic [5:0]          latched_cam_idx_o,
    output logic [1:0]          latched_slot_idx_o,
    output logic [1:0]          latched_rep_slot_idx_o,
    output order_entry_t        latched_lookup_entry_o,
    output logic [BBO_W-1:0]    latched_lookup_price_idx_o,
    output logic                latched_bid_valid_rst_o,
    output logic                latched_ask_valid_rst_o,
    output logic                reg_target_val_o,
    output logic [BBO_W-1:0]    reg_chosen_row_o,
    output logic                reg_target_side_o,
    output logic                reg_we_en_o,
    output logic [SHARES_W-1:0] latched_book_shares_o,
    output logic [SHARES_W-1:0] latched_event_shares_o,
    output logic [HASH_W-1:0]   latched_hash_idx_o,
    output logic [HASH_W-1:0]   latched_rep_hash_idx_o,
    output order_entry_t [2:0]  latched_read_bucket_o,
    output order_entry_t [2:0]  latched_rep_read_bucket_o,

    // External Memory I/O
    input logic [SHARES_W-1:0]  bid_dout_a,
    input logic [SHARES_W-1:0]  bid_dout_b,
    input logic [SHARES_W-1:0]  ask_dout_a,
    input logic [SHARES_W-1:0]  ask_dout_b
);

// Internal Regs
logic [SHARES_W-1:0]    immediate_book_shares;
logic                   immediate_level_depleted;

// Comb. Logic
always_comb begin
    immediate_book_shares       =   latched_lookup_entry_i.side ? bid_dout_a : bid_dout_b;
    immediate_level_depleted    =   latched_is_reduce_i ?
                                    (immediate_book_shares == latched_rdata_i.shares) :
                                    (immediate_book_shares == latched_lookup_entry_i.shares);
end

// Seq. Logic
always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o               <=  1'b0;
        latched_rdata_o             <=  '0;
        latched_base_price_o        <=  '0;
        latched_is_add_o            <=  1'b0;
        latched_is_reduce_o         <=  1'b0;
        latched_is_replace_o        <=  1'b0;
        latched_is_delete_o         <=  1'b0;

        latched_event_price_idx_o   <=  '0;
        latched_is_cam_entry_o      <=  1'b0;
        latched_cam_idx_o           <=  '0;
        latched_slot_idx_o          <=  '0;
        latched_rep_slot_idx_o      <=  '0;
        latched_lookup_entry_o      <=  '0;
        latched_lookup_price_idx_o  <=  '0;
        latched_bid_valid_rst_o     <=  1'b0;
        latched_ask_valid_rst_o     <=  1'b0;
        reg_target_val_o            <=  1'b0;
        reg_chosen_row              <=  '0;
        reg_target_side_o           <=  1'b0;
        latched_book_shares_o       <=  '0;
        latched_event_shares_o      <=  '0;
        latched_hash_idx_o          <=  '0;
        latched_rep_hash_idx_o      <=  '0;
        latched_read_bucket_o       <=  '0;
        latched_rep_read_bucket_o   <=  '0;
    end
    else if(!stall) begin
        stage_valid_o               <=  stage_valid_i;
        latched_rdata_o             <=  latched_rdata_i;
        latched_base_price_o        <=  latched_base_price_i;
        latched_is_add_o            <=  latched_is_add_i;
        latched_is_reduce_o         <=  latched_is_reduce_i;
        latched_is_replace_o        <=  latched_is_replace_i;
        latched_is_delete_o         <=  latched_is_delete_i;

        latched_event_price_idx_o   <=  latched_event_price_idx_i;
        latched_is_cam_entry_o      <=  latched_is_cam_entry_i;
        latched_cam_idx_o           <=  latched_cam_idx_i;
        latched_slot_idx_o          <=  latched_slot_idx_i;
        latched_rep_slot_idx_o      <=  latched_rep_slot_idx_i;
        latched_lookup_entry_o      <=  latched_lookup_entry_i;
        latched_lookup_price_idx_o  <=  latched_lookup_price_idx_i;
        latched_hash_idx_o          <=  latched_hash_idx_i;
        latched_rep_hash_idx_o      <=  latched_rep_hash_idx_i;
        latched_read_bucket_o       <=  read_bucket_i;
        latched_rep_read_bucket_o   <=  rep_read_bucket_i;

        if(latched_is_add_i) begin
            reg_target_val_o    <=  1'b1;
            reg_chosen_row_o    <=  latched_event_price_idx_i;
            reg_target_side_o   <=  latched_rdata_i.side;
            reg_we_en_o         <=  1'b1;
        end
        else if(latched_is_replace_i || latched_is_delete_i || latched_is_reduce_i) begin
            reg_target_val_o    <=  1'b0;
            reg_chosen_row_o    <=  latched_lookup_price_idx_i;
            reg_target_side_o   <=  latched_lookup_entry_i.side;
            reg_we_en_o         <=  immediate_level_depleted;
        end

        if(latched_lookup_entry_i.side) latched_book_shares_o   <=  bid_dout_a;
        else                            latched_book_shares_o   <=  ask_dout_a;

        if(latched_is_replace_i ? latched_lookup_entry_i.side : latched_rdata_i.side) begin
            latched_event_shares_o  <=  bid_dout_b;
        end
        else latched_event_shares_o <=  ask_dout_b;
    end
end

endmodule
