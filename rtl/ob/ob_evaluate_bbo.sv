import hdl_header::*;

module ob_evaluate_bbo(
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
    output logic [PRICE_W-1:0]  latched_base_price_o,

    // Computed DataPath I/O
    input logic [BBO_W-1:0]     latched_event_price_idx_i,
    input order_entry_t         latched_lookup_entry_i,
    input logic [BBO_W-1:0]     latched_lookup_price_idx_i,
    input logic [SHARES_W-1:0]  latched_book_shares_i,

    // BBO Search I/O
    input logic [BBO_W-1:0]     current_best_bid_i,
    input logic [BBO_W-1:0]     current_best_ask_i,
    input logic [CHUNK_LEN-1:0] bid_enc_valid_i,
    input logic [CHUNK_LEN-1:0] ask_enc_valid_i,

    output logic [BBO_W-1:0]    current_best_bid_o,
    output logic [BBO_W-1:0]    current_best_ask_o,
    output logic                search_side_o,
    output logic                new_bbo_o,
    output logic [(BBO_W-7):0]  target_chunk_idx_o,
    output logic                bid_is_zero_o,
    output logic                ask_is_zero_o
);

// internal registers

logic       is_better_bid;
logic       is_better_ask;
logic       bid_depleted;
logic       ask_depleted;
logic       level_depleted;
logic       new_bbo;
logic       bid_is_zero;
logic       ask_is_zero;

// combinational logic for bbo_evaluation
always_comb begin
    // Default assignmnets
    is_better_bid   =   1'b0;
    is_better_ask   =   1'b0;
    bid_depleted    =   1'b0;
    ask_depleted    =   1'b0;

    level_depleted = latched_is_reduce_i ?
                     (latched_book_shares_i == latched_rdata_i.shares) :
                     (latched_book_shares_i == latched_lookup_entry_i.shares);

    if(latched_is_add_i) begin
        if( latched_rdata_i.side && latched_event_price_idx_i > current_best_bid_i) is_better_bid  = 1'b1;
        if(!latched_rdata_i.side && latched_event_price_idx_i < current_best_ask_i) is_better_ask  = 1'b1;
    end
    else if(latched_is_replace_i) begin
        if( latched_lookup_entry_i.side && latched_event_price_idx_i > current_best_bid_i) is_better_bid = 1'b1;
        if(!latched_lookup_entry_i.side && latched_event_price_idx_i < current_best_ask_i) is_better_ask = 1'b1;
    end

    if(latched_is_reduce_i || latched_is_delete_i) begin
        if(level_depleted) begin
            if( latched_lookup_entry_i.side && latched_lookup_price_idx_i == current_best_bid_i) bid_depleted = 1'b1;
            if(!latched_lookup_entry_i.side && latched_lookup_price_idx_i == current_best_ask_i) ask_depleted = 1'b1;
        end
    end
    else if(latched_is_replace_i) begin
        if(level_depleted) begin
            if( latched_lookup_entry_i.side && latched_lookup_price_idx_i == current_best_bid_i && latched_lookup_price_idx_i != latched_event_price_idx_i)
            bid_depleted    =   1'b1;
            if(!latched_lookup_entry_i.side && latched_lookup_price_idx_i == current_best_ask_i && latched_lookup_price_idx_i != latched_event_price_idx_i)
            ask_depleted    =   1'b1;
        end
    end

    new_bbo     =   (bid_depleted && current_best_bid_i != '0) || (ask_depleted && current_best_ask_i != BBO_W'(BBO_DEPTH-1));
    bid_is_zero =   (bid_enc_valid_i == '0);
    ask_is_zero =   (ask_enc_valid_i == '0);
end

// Sequential Logic
always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o               <=  1'b0;
        latched_base_price_o        <=  '0;

        current_best_bid_o          <=  '0;
        current_best_ask_o          <=  BBO_W'(BBO_DEPTH-1);
        search_side_o               <=  1'b0;
        new_bbo_o                   <=  1'b0;
        target_chunk_idx_o          <=  '0;
        bid_is_zero_o               <=  1'b0;
        ask_is_zero_o               <=  1'b0;
    end
    else begin
        stage_valid_o               <=  stage_valid_i;
        latched_base_price_o        <=  latched_base_price_i;
        new_bbo_o                   <=  new_bbo;
        bid_is_zero_o               <=  bid_is_zero;
        ask_is_zero_o               <=  ask_is_zero;

        if(ask_depleted) begin
            target_chunk_idx_o      <=  find_lsb_chunk(ask_enc_valid_i);
            search_side_o           <=  1'b0;
        end
        else begin
            target_chunk_idx_o      <=  find_msb_chunk(bid_enc_valid_i);
            search_side_o           <=  1'b1;
        end

        if (is_better_bid)  current_best_bid_o <= latched_event_price_idx_i;
        else                current_best_bid_o <= current_best_bid_i;

        if (is_better_ask)  current_best_ask_o <= latched_event_price_idx_i;
        else                current_best_ask_o <= current_best_ask_i;
    end
end

endmodule
