import hdl_header::*;

// FETCH_BBO_WAIT pipeline stage
// captures sync bid/ask book read results from FETCH_BBO
// constructs BBO output data

module ob_fetch_bbo_wait(
    // control signals
    input logic clk,
    input logic rst_n,
    input logic stall,

    // instruction data io
    input logic stage_valid_i,
    input logic [PRICE_W-1:0] latched_base_price_i,

    output logic stage_valid_o,
    output bbo_t bbo_data_o,

    // computed datapath io
    input logic [BBO_W-1:0] current_best_bid_i,
    input logic [BBO_W-1:0] current_best_ask_i,
    input logic bid_empty_i,
    input logic ask_empty_i,

    // external mem io
    input logic [SHARES_W-1:0] bid_dout_a_i,
    input logic [SHARES_W-1:0] ask_dout_a_i,
);

// seq logic
always_ff @(posedge clk) begin
    if (!rst_n) begin
        stage_valid_o <= 1'b0;
        bbo_data_o <= '0;
    end else if (!stall) begin
        stage_valid_o <= stage_valid_i;

        if(stage_valid_i) begin
            if(bid_empty_i) begin
                bbo_data_o.bid_price <= '0;
                bbo_data_o.bid_shares <= '0;
            end else begin
                bbo_data_o.bid_price <= latched_base_price_i + PRICE_W'(current_best_bid_i);
                bbo_data_o.bid_shares <= bid_dout_a_i;
            end

            if (ask_empty_i) begin
                bbo_data_o.ask_price <= '0;
                bbo_data_o.ask_shares <= '0;
            end else begin
                bbo_data_o.ask_price <= latched_base_price_i + PRICE_W'(current_best_ask_i);
                bbo_data_o.ask_shares <= ask_dout_a_i;
            end
        end
    end
end
endmodule
