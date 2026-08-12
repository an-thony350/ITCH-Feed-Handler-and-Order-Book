import hdl_header::*;

module ob_update_write(
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

    // Computed DataPath I/O
    input logic [BBO_W-1:0]     latched_event_price_idx_i,
    input logic                 latched_is_cam_entry_i,
    input logic [5:0]           latched_cam_idx_i,
    input logic [1:0]           latched_slot_idx_i,
    input logic [1:0]           latched_rep_slot_idx_i,
    input order_entry_t         latched_lookup_entry_i,
    input logic [BBO_W-1:0]     latched_lookup_price_idx_i,
    input logic                 latched_bid_valid_rst_i,
    input logic                 latched_ask_valid_rst_i,
    input logic                 reg_target_val_i,
    input logic                 reg_chosen_row_i,
    input logic                 reg_target_side_i,
    input logic                 reg_we_en_i,
    input logic [SHARES_W-1:0]  latched_book_shares_i,
    input logic [SHARES_W-1:0]  latched_event_shares_i,
    input logic [HASH_W-1:0]    latched_hash_idx_i,
    input logic [HASH_W-1:0]    latched_rep_hash_idx_i,
    input order_entry_t [2:0]   latched_read_bucket_i,
    input order_entry_t [2:0]   latched_rep_read_bucket_i,

    output logic [BBO_W-1:0]    latched_event_price_idx_o,
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
    input order_entry_t [63:0]  cam,

    output logic                we_a,
    output logic                din_a,
    output logic                bid_we_a,
    output logic [BBO_W-1:0]    bid_addr_a,
    output logic [SHARES_W-1:0] bid_din_a,
    output logic                ask_we_a,
    output logic [BBO_W-1:0]    ask_addr_a,
    output logic [SHARES_W-1:0] ask_din_a,

    output logic                we_b,
    output logic                din_b,
    output logic                bid_we_b,
    output logic [BBO_W-1:0]    bid_addr_b,
    output logic [SHARES_W-1:0] bid_din_b,
    output logic                ask_we_b,
    output logic [BBO_W-1:0]    ask_addr_b,
    output logic [SHARES_W-1:0] ask_din_b,
);

// state machine used if we enter the REPLACE_ADD State (i.e. a repl ins)
typedef enum logic{REPLACE_CYCLE_1, REPLACE_CYCLE_2} replace_t;

replace_t replace_state;

// Combinational UPDATE_WRITE logic
always_comb begin
    we_a    =   !latched_is_cam_entry_i;
    din_a   =   latched_read_bucket_i;

    if(latched_is_add_i) begin
        din_a[latched_slot_idx_i].valid         =   1'b1;
    end
end

endmodule
