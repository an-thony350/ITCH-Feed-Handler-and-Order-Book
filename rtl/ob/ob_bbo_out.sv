import hdl_header::*;

module ob_bbo_out(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,

    // Instruction Data Inputs
    input logic                 stage_valid_i,
    input logic [PRICE_W-1:0]   latched_base_price_i,

    // External Memory Inputs
    input logic [SHARES_W-1:0]  bid_dout_a,
    input logic [SHARES_W-1:0]  ask_dout_a,

    // BBO Search inputs
    input logic [BBO_W-1:0]     current_best_bid_i,
    input logic [BBO_W-1:0]     current_best_ask_i,
    input logic                 bid_is_zero_i,
    input logic                 ask_is_zero_i,

    // BBO Outputs
    output bbo_t                bbo_data_o,
    output logic                bbo_valid_o
);

always_ff @(posedge clk) begin
    if(!rst_n) begin
        bbo_data_o      <=  '0;
        bbo_valid_o     <=  1'b0;
    end
    else begin
        bbo_valid_o     <=  stage_valid_i;

        if(bid_is_zero_i) begin
            bbo_data_o.bid_price  <= '0;
            bbo_data_o.bid_shares <= '0;
        end
        else begin
            bbo_data_o.bid_price  <= latched_base_price_i + PRICE_W'(current_best_bid_i);
            bbo_data_o.bid_shares <= bid_dout_a;
        end

        if(ask_is_zero_i) begin
            bbo_data_o.ask_price  <= '0;
            bbo_data_o.ask_shares <= '0;
        end
        else begin
            bbo_data_o.ask_price  <= latched_base_price_i + PRICE_W'(current_best_ask_i);
            bbo_data_o.ask_shares <= ask_dout_a;
        end
    end
end

endmodule
