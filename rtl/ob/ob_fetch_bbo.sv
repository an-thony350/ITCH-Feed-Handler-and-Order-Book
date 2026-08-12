import hdl_header::*;

// FETCH_BBO pipeline stage
// issues sync bid/ask book reads for current BBO indices
// FETCH_BBO_WAIT can interpret the BRAM outputs on the following cycle

module ob_fetch_bbo(
    // Control signals
    input logic clk,
    input logic rst_n,
    input logic stall,

    // Istruction data io
    input logic stage_valid_i,
    input logic [PRICE_W-1:0] latched_base_price_i,

    output logic stage_valid_o,
    output logic [PRICE_W-1:0] latched_base_price_o,

    // computed datapath io
    input logic [BBO_W-1:0] current_best_bid_i,
    input logic [BBO_W-1:0] current_best_ask_i,
    input logic [CHUNK_LEN-1:0] bid_enc_valid_i,
    input logic [CHUNK_LEN-1:0] ask_enc_valid_i,

    output logic [BBO_W-1:0] current_best_bid_o,
    output logic [BBO_W-1:0] current_best_ask_o,
    output logic bid_empty_o,
    output logic ask_empty_o,

    // externam mem io
    output logic [BBO_W-1] bid_addr_a,
    output logic [BBO_W-1:0] ask_addr_a
);

// BRAM read addresses
always_comb begin
    bid_addr_a = current_best_bid_i;
    ask_addr_a = current_best_ask_i;
end

// seq logic
always_ff @(posedge clk) begin
    if (!rst_n) begin
        stage_valid_o <= 1'b0;
        latched_base_price_o <= '0;
        current_best_bid_o <= '0;
        current_best_ask_o <= '0;
        bid_empty_o <= 1'b1;
        ask_empty_o <= 1'b1;
    end else if (!stall) begin
        stage_valid_o <= stage_valid_i;
        latched_base_price_o <= latched_base_price_i;
        current_best_bid_o <= current_best_bid_i;
        current_best_ask_o <= current_best_ask_i;
        bid_empty_o <= (bid_enc_valid_i == '0);
        ask_empty_o <= (ask_enc_valid_i == '0);
    end
end

endmodule
