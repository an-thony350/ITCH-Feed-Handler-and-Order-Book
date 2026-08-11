import hdl_header::*

module ob_idx_search(
    // Control signals
    input logic             clk,
    input logic             rst_n,
    input logic             stall,

    // Instruction Data I/O
    input o_data_t          rdata_i,
    input logic             is_add_i,
    input logic             is_delete_i,
    input logic             is_reduce_i,
    input logic             is_replace_i,

    // Computed DataPath I/O
    input logic [1:0]       comb_slot_idx_i,
    input logic [1:0]       rep_comb_slot_idx_i
);

endmodule
