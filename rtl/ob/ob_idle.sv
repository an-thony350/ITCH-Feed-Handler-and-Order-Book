import hdl_header::*;

// Stage 0

module ob_idle(
    // Control signals
    input logic                 clk,
    input logic                 rst_n,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input o_data_t              rdata_i,
    input logic [PRICE_W-1:0]   base_price_i,

    output logic                stage_valid_o,
    output o_data_t             latched_rdata_o,
    output logic [PRICE_W-1:0]  latched_base_price_o,
    output logic                latched_is_add_o,
    output logic                latched_is_reduce_o,
    output logic                latched_is_replace_o,
    output logic                latched_is_delete_o,

    // External Memory I/O - BRAM addr pins
    output logic [HASH_W-1:0]   hash_idx_o,
    output logic [HASH_W-1:0]   rep_hash_idx_o,
);

always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o           <=  1'b0;
        latched_rdata_o         <=  '0;
        latched_base_price_o    <=  '0;
        hash_idx_o              <=  '0;
        rep_hash_idx_o          <=  '0;
        latched_is_add_o        <=  1'b0;
        latched_is_reduce_o     <=  1'b0;
        latched_is_replace_o    <=  1'b0;
        latched_is_delete_o     <=  1'b0;
    end
    else begin
        stage_valid_o           <=  stage_valid_i;
        latched_rdata_o         <=  rdata_i;
        latched_base_price_o    <=  base_price_i;
        hash_idx_o              <=  hash_orn(rdata_i.orn);
        rep_hash_idx_o          <=  hash_orn(rdata_i.updated_orn);
        latched_is_add_o        <=  is_add_msg(rdata_i.message_type);
        latched_is_reduce_o     <=  is_reduce_msg(rdata_i.message_type);
        latched_is_replace_o    <=  (rdata_i.message_type == MSG_REPLACE);
        latched_is_delete_o     <=  (rdata_i.message_type == MSG_DELETE);
    end
end


endmodule
