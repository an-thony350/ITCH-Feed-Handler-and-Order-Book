import hdl_header::*;

module ob_issue_book_read(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,

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
    output logic [HASH_W-1:0]   latched_hash_idx_o,
    output logic [HASH_W-1:0]   latched_rep_hash_idx_o,
    output order_entry_t [2:0]  latched_read_bucket_o,
    output order_entry_t [2:0]  latched_rep_read_bucket_o,


    // External Memory I/O
    output logic [BBO_W-1:0]    bid_addr_a,
    output logic [BBO_W-1:0]    ask_addr_a,
    output logic [BBO_W-1:0]    bid_addr_b,
    output logic [BBO_W-1:0]    ask_addr_b
);

// Combinational bid/ask address writes
always_comb begin
    bid_addr_a  =   price_to_idx(latched_lookup_entry_i.price, latched_base_price_i);
    ask_addr_a  =   price_to_idx(latched_lookup_entry_i.price, latched_base_price_i);

    bid_addr_b  =   latched_event_price_idx_i;
    ask_addr_b  =   latched_event_price_idx_i;
end

// Sequential Logic
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
        latched_hash_idx_o          <=  '0;
        latched_rep_hash_idx_o      <=  '0;
        latched_read_bucket_o       <=  '0;
        latched_rep_read_bucket_o   <=  '0;
    end
    else begin
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
        latched_lookup_price_idx_o  <=  price_to_idx(latched_lookup_entry_i.price, latched_base_price_i);
        latched_hash_idx_o          <=  latched_hash_idx_i;
        latched_rep_hash_idx_o      <=  latched_rep_hash_idx_i;
        latched_read_bucket_o       <=  latched_read_bucket_i;
        latched_rep_read_bucket_o   <=  latched_rep_read_bucket_i;
    end
end

endmodule
