import hdl_header::*;

module ob_idx_req(
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
    output o_data_t             latched_rdata_o,
    output logic [PRICE_W-1:0]  latched_base_price_o,
    output logic                latched_is_add_o,
    output logic                latched_is_reduce_o,
    output logic                latched_is_replace_o,
    output logic                latched_is_delete_o,

    // Computed Datapath I/O
    input logic [HASH_W-1:0]    hash_idx_i,
    input logic [HASH_W-1:0]    rep_hash_idx_i,

    output logic [BBO_W-1:0]    latched_event_price_idx_o,
    output logic                latched_cam_hit_o,
    output logic [5:0]          latched_cam_match_idx_o,
    output logic                latched_cam_is_full_o,
    output logic [5:0]          latched_cam_free_idx_o,
    output logic [HASH_W-1:0]   latched_hash_idx_o,
    output logic [HASH_W-1:0]   latched_rep_hash_idx_o,

    // External Memory I/O
    input order_entry_t [63:0]  cam
);

// internal registers

// CAM signals

logic           cam_hit;
logic [5:0]     cam_match_idx;
logic           cam_is_full;
logic [5:0]     cam_free_idx;
logic [63:0]    cam_match_vec;

// Comb. Logic for CAM
always_comb begin
    // Default Assignments
    cam_match_idx   =   '0;
    cam_is_full     =   1'b1;
    cam_free_idx    =   '0;

    // CAM hit logic
    for(int i = 0; i < 64; i++) begin
        cam_match_vec[i]    =   (cam[i].valid && ~cam[i].tombstone && (cam[i].orn == latched_rdata_i.orn))
    end

    cam_hit = |cam_match_vec;

    // CAM matching logic
    for(int i = 0; i < 64; i++) begin
        if(cam_match_vec[i]) cam_match_idx = cam_match_idx | 6'(i);
    end

    // Free slot finder (priority encoder)
    for(int i = 63; i >= 0; i--) begin
        if(~cam[i].valid || cam[i].tombstone) begin
            cam_is_full     =   1'b0;
            cam_free_idx    =   6'(i);
        end
    end
end

// Sequential logic

always_ff @(posedge clk) begin
    if(!rst_n) begin
        latched_rdata_o             <=  '0;
        latched_base_price_o        <=  '0;
        latched_is_add_o            <=  1'b0;
        latched_is_reduce_o         <=  1'b0;
        latched_is_replace_o        <=  1'b0;
        latched_is_delete_o         <=  1'b0;

        latched_event_price_idx_o   <=  '0;
        latched_cam_hit_o           <=  '0;
        latched_cam_match_idx_o     <=  '0;
        latched_cam_is_full_o       <=  '0;
        latched_cam_free_idx_o      <=  '0;
        latched_hash_idx_o          <=  '0;
        latched_rep_hash_idx_o      <=  '0;
    end
    else begin
        stage_valid_o               <=  stage_valid_i;
        latched_rdata_o             <=  latched_rdata_i;
        latched_base_price_o        <=  latched_base_price_i;
        latched_is_add_o            <=  latched_is_add_i;
        latched_is_reduce_o         <=  latched_is_reduce_i;
        latched_is_replace_o        <=  latched_is_replace_i;
        latched_is_delete_o         <=  latched_is_delete_i;

        latched_event_price_idx_o   <=  price_to_idx(latched_rdata_i.price);
        latched_cam_hit_o           <=  cam_hit;
        latched_cam_match_idx_o     <=  cam_match_idx;
        latched_cam_is_full_o       <=  cam_is_full;
        latched_cam_is_free_o       <=  cam_free_idx;
        latched_hash_idx_o          <=  hash_idx_i;
        latched_rep_hash_idx_o      <=  rep_hash_idx_i
    end
end

endmodule
