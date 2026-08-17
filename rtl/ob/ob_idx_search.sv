import hdl_header::*;

module ob_idx_search(
    // Control signals
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

    // Computed DataPath I/O
    input logic [BBO_W-1:0]     latched_event_price_idx_i,
    input logic                 latched_cam_hit_i,
    input logic [5:0]           latched_cam_match_idx_i,
    input logic [5:0]           latched_cam_free_idx_i,
    input logic [HASH_W-1:0]    latched_hash_idx_i,
    input logic [HASH_W-1:0]    latched_rep_hash_idx_i,

    output logic [BBO_W-1:0]    latched_event_price_idx_o,
    output logic                latched_cam_hit_o,
    output logic [5:0]          latched_cam_match_idx_o,
    output logic [5:0]          latched_cam_free_idx_o,
    output logic [1:0]          latched_slot_idx_o,
    output logic [1:0]          latched_rep_slot_idx_o,
    output logic [2:0]          latched_hash_match_o,
    output logic [2:0]          latched_free_slot_o,
    output logic [HASH_W-1:0]   latched_hash_idx_o,
    output logic [HASH_W-1:0]   latched_rep_hash_idx_o,
    output order_entry_t [2:0]  read_bucket_o,
    output order_entry_t [2:0]  rep_read_bucket_o,

    // External Memory I/O - BRAM dout pins
    input order_entry_t [2:0]   read_bucket_i,
    input order_entry_t [2:0]   rep_read_bucket_i
);

// Internal Registers

// comb 3-way associative hash regs
logic [2:0] hash_match;
logic [2:0] free_slot;
logic [2:0] rep_hash_match;
logic [2:0] rep_free_slot;

// idx search regs
logic [1:0] comb_slot_idx;
logic [1:0] rep_comb_slot_idx;

// combinational logic determing hash matches and free slots
always_comb begin
    // Default Assignments
    hash_match      =   '0;
    free_slot       =   '0;
    rep_hash_match  =   '0;
    rep_free_slot   =   '0;

    hash_match[0]        =   (read_bucket_i[0].valid && read_bucket_i[0].orn == latched_rdata.orn && ~read_bucket_i[0].tombstone);
    hash_match[1]        =   (read_bucket_i[1].valid && read_bucket_i[1].orn == latched_rdata.orn && ~read_bucket_i[1].tombstone);
    hash_match[2]        =   (read_bucket_i[2].valid && read_bucket_i[2].orn == latched_rdata.orn && ~read_bucket_i[2].tombstone);

    free_slot[0]         = (!read_bucket_i[0].valid || read_bucket_i[0].tombstone);
    free_slot[1]         = (!read_bucket_i[1].valid || read_bucket_i[1].tombstone);
    free_slot[2]         = (!read_bucket_i[2].valid || read_bucket_i[2].tombstone);

    rep_hash_match[0]    =   (rep_read_bucket_i[0].valid && rep_read_bucket_i[0].orn == latched_rdata.orn && ~rep_read_bucket_i[0].tombstone);
    rep_hash_match[1]    =   (rep_read_bucket_i[1].valid && rep_read_bucket_i[1].orn == latched_rdata.orn && ~rep_read_bucket_i[1].tombstone);
    rep_hash_match[2]    =   (rep_read_bucket_i[2].valid && rep_read_bucket_i[2].orn == latched_rdata.orn && ~rep_read_bucket_i[2].tombstone);

    rep_free_slot[0]    = (!rep_read_bucket_i[0].valid || rep_read_bucket_i[0].tombstone);
    rep_free_slot[1]    = (!rep_read_bucket_i[1].valid || rep_read_bucket_i[1].tombstone);
    rep_free_slot[2]    = (!rep_read_bucket_i[2].valid || rep_read_bucket_i[2].tombstone);
end


// combinational logic determining if forwarding is required

always_comb begin
    comb_slot_idx       =   '0;
    rep_comb_slot_idx   =   '0;

    if(latched_is_add_i) begin
        if(free_slot != 3'b000) begin
            if      (free_slot[0]) comb_slot_idx = 2'd0;
            else if (free_slot[1]) comb_slot_idx = 2'd1;
            else                   comb_slot_idx = 2'd2;
        end
    end
    else if(latched_is_delete_i || latched_is_reduce_i || latched_is_replace_i) begin
        if(hash_match != 3'b000) begin
            if      (hash_match[0]) comb_slot_idx = 2'd0;
            else if (hash_match[1]) comb_slot_idx = 2'd1;
            else                    comb_slot_idx = 2'd2;

            if(latched_is_replace_i) begin
                if(rep_free_slot != 3'b000) begin
                    if      (rep_free_slot[0]) rep_comb_slot_idx = 2'd0;
                    else if (rep_free_slot[1]) rep_comb_slot_idx = 2'd1;
                    else                       rep_comb_slot_idx = 2'd2;
                end
            end
        end
    end
end

// seq logic
always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o               <=  '0;
        latched_rdata_o             <=  '0;
        latched_base_price_o        <=  '0;
        latched_is_add_o            <=  1'b0;
        latched_is_reduce_o         <=  1'b0;
        latched_is_replace_o        <=  1'b0;
        latched_is_delete_o         <=  1'b0;

        latched_event_price_idx_o   <=  '0;
        latched_cam_hit_o           <=  1'b0;
        latched_cam_match_idx_o     <=  '0;
        latched_cam_free_idx_o      <=  '0;
        latched_slot_idx_o          <=  '0;
        latched_rep_slot_idx_o      <=  '0;
        latched_hash_match_o        <=  '0;
        latched_free_slot_o         <=  '0;
        latched_hash_idx_o          <=  '0;
        latched_rep_hash_idx_o      <=  '0;
        read_bucket_o               <=  '0;
        rep_read_bucket_o           <=  '0;
    end
    else begin
        // deals with immediate return to FETCH_BBO state in old design
        if(hash_match == 3'b000 && !latched_cam_hit_i) begin
            stage_valid_o   <=  1'b0;
        end
        else begin
            stage_valid_o   <=  stage_valid_i;
        end

        latched_rdata_o             <=  latched_rdata_i;
        latched_base_price_o        <=  latched_base_price_i;
        latched_is_add_o            <=  latched_is_add_i;
        latched_is_reduce_o         <=  latched_is_reduce_i;
        latched_is_replace_o        <=  latched_is_replace_i;
        latched_is_delete_o         <=  latched_is_delete_i;

        latched_event_price_idx_o   <=  latched_event_price_idx_i;
        latched_cam_hit_o           <=  latched_cam_hit_i;
        latched_cam_match_idx_o     <=  latched_cam_match_idx_i;
        latched_cam_free_idx_o      <=  latched_cam_free_idx_i;
        latched_slot_idx_o          <=  comb_slot_idx;
        latched_rep_slot_idx_o      <=  rep_comb_slot_idx;
        latched_hash_match_o        <=  hash_match;
        latched_free_slot_o         <=  free_slot;
        latched_hash_idx_o          <=  latched_hash_idx_i;
        latched_rep_hash_idx_o      <=  latched_rep_hash_idx_i;
        read_bucket_o               <=  read_bucket_i;
        rep_read_bucket_o           <=  rep_read_bucket_i;
    end
end

endmodule
