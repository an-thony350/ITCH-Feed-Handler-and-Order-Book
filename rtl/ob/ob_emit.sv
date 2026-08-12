import hdl_header::*;

// EMIT pipeline stage
// registers the completed bbo from fetch_bbo_wait
// also asserts bbo_valid_o for one cycle

module ob_emit(
    // control signals
    input logic clk,
    input logic rst_n,
    input logic stall,

    // boo data io
    input logic stage_valid_i,
    input bbo_t bbo_data_i,

    output bbo_t bbo_data_o,
    output logic bbo_valid_o
);

// seq logic

always_ff @(posedge clk) begin
    if (!rst_n) begin
        bbo_data_o <= '0;
        bbo_valid_o <= 1'b0;
    end else begin
        bbo_valid_o <= 1'b0;

        if (!stall) begin
            bbo_valid_o <= stage_valid_i;
            if(stage_valid_i) begin
                bbo_data_o <= bbo_data_i;
            end
        end
    end
end

endmodule
