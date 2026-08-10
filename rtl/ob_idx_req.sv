# import hdl_header::*;

module ob_idx_req(
    input logic                 clk,
    input logic                 rst_n,
    input logic                 stall,

    // comb inputs
    input logic [HASH_W-1:0]    idx_req_hash_idx,
    input logic [HASH_W-1:0]    idx_req_rep_hash_idx,

    // seq inputs
    input logic [BBO_W-1:0]     idx_req_event_price_idx,
    input logic                 idx_req_cam_hit,
    input logic [5:0]           idx_req_cam_match_idx,
    input logic                 idx_req_cam_is_full,
    input logic                 idx_req_cam_is_free,

    // comb outputs
    output logic [HASH_W-1:0]   addr_a,
    output logic [HASH_W-1:0]   addr_b,

    // seq outputs
    output logic [BBO_W-1:0]     latched_event_price_idx,
    output logic                 latched_cam_hit,
    output logic [5:0]           latched_cam_match_idx,
    output logic                 latched_cam_is_full,
    output logic                 latched_cam_is_free
);

always_comb begin
    addr_a  =   idx_req_hash_idx;
    addr_b  =   idx_req_rep_hash_idx;
end

always_ff @(posedge clk) begin
    if(!rst_n) begin
        latched_event_price_idx <=  '0;
        latched_cam_hit         <=  '0;
        latched_cam_match_idx   <=  '0;
        latched_cam_is_full     <=  '0;
        latched_cam_is_free     <=  '0;
    end
    else if(stall) begin
   // unsure
    end
    else begin
        latched_event_price_idx <=  idx_req_event_price_idx;
        latched_cam_hit         <=  idx_req_cam_hit;
        latched_cam_match_idx   <=  idx_req_cam_match_idx;
        latched_cam_is_full     <=  idx_req_cam_is_full;
        latched_cam_is_free     <=  idx_req_cam_is_free;
    end
end

endmodule
