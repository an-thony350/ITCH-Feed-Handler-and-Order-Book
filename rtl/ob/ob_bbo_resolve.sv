import hdl_header::*;

module ob_bbo_resolve(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input logic [PRICE_W-1:0]   latched_base_price_i,

    output logic                stage_valid_o,
    output logic [PRICE_W-1:0]  latched_base_price_o,

    // External Memory Input
    input logic [63:0]          bid_active_chunks [CHUNK_LEN-1:0],
    input logic [63:0]          ask_active_chunks [CHUNK_LEN-1:0],

    // BBO Search I/O
    input logic [BBO_W-1:0]     current_best_bid_i,
    input logic [BBO_W-1:0]     current_best_ask_i,
    input logic                 search_side_i,
    input logic                 new_bbo_i,
    input logic [(BBO_W-7):0]   target_chunk_idx_i,
    input logic                 bid_is_zero_i,
    input logic                 ask_is_zero_i,

    output logic [BBO_W-1:0]    current_best_bid_o,
    output logic [BBO_W-1:0]    current_best_ask_o,
    output logic                bid_is_zero_o,
    output logic                ask_is_zero_o
);


always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o           <=  1'b0;
        latched_base_price_o    <=  '0;

        current_best_bid_o      <=  '0;
        current_best_ask_o      <=  '0;
        bid_is_zero_o           <=  1'b0;
        ask_is_zero_o           <=  1'b0;
    end
    else begin
        stage_valid_o           <=  stage_valid_i;
        latched_base_price_o    <=  latched_base_price_i;

        current_best_bid_o      <=  current_best_bid_i;
        current_best_ask_o      <=  current_best_ask_i;
        bid_is_zero_o           <=  bid_is_zero_i;
        ask_is_zero_o           <=  ask_is_zero_i;

        if(new_bbo_i) begin
            if(search_side_i) begin
                current_best_bid_o  <=  (bid_is_zero_i) ? '0                  : {target_chunk_idx_i, find_msb_bit(bid_active_chunks[target_chunk_idx_i])};
            end
            else begin
                current_best_ask_o  <=  (ask_is_zero_i) ? BBO_W'(BBO_DEPTH-1) : {target_chunk_idx_i, find_lsb_bit(ask_active_chunks[target_chunk_idx_i])};
            end
        end
    end
end

endmodule
