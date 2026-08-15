import hdl_header::*;

module ob_evaluate_bbo(
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
    output logic [PRICE_W-1:0]  latched_base_price_o,

    // Computed DataPath I/O
    input logic [BBO_W-1:0]     latched_event_price_idx_i,
    input order_entry_t         latched_lookup_entry_i,
    input logic [BBO_W-1:0]     latched_lookup_price_idx_i,
    input logic                 reg_target_val_i,
    input logic [BBO_W-1:0]     reg_chosen_row_i,
    input logic                 reg_target_side_i,
    input logic                 reg_we_en_i,
    input logic [BBO_W-1:0]     current_best_bid_i,
    input logic [BBO_W-1:0]     current_best_ask_i,


);

// internal registers

logic       is_better_bid;
logic       is_better_ask;
logic       bid_depleted;
logic       ask_depleted;

endmodule
