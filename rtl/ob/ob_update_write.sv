import hdl_header::*;

module ob_update_write(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,
    input logic                 stall,

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
    input logic                 latched_is_cam_entry_i,
    input logic [5:0]           latched_cam_idx_i,
    input logic [1:0]           latched_slot_idx_i,
    input logic [1:0]           latched_rep_slot_idx_i,
    input order_entry_t         latched_lookup_entry_i,
    input logic [BBO_W-1:0]     latched_lookup_price_idx_i,
    input logic                 reg_target_val_i,
    input logic                 reg_chosen_row_i,
    input logic                 reg_target_side_i,
    input logic                 reg_we_en_i,
    input logic [SHARES_W-1:0]  latched_book_shares_i,
    input logic [SHARES_W-1:0]  latched_event_shares_i,
    input logic [HASH_W-1:0]    latched_hash_idx_i,
    input logic [HASH_W-1:0]    latched_rep_hash_idx_i,
    input order_entry_t [2:0]   latched_read_bucket_i,
    input order_entry_t [2:0]   latched_rep_read_bucket_i,

    output logic [BBO_W-1:0]    latched_event_price_idx_o,
    output order_entry_t        latched_lookup_entry_o,
    output logic [BBO_W-1:0]    latched_lookup_price_idx_o,
    output logic                reg_target_val_o,
    output logic [BBO_W-1:0]    reg_chosen_row_o,
    output logic                reg_target_side_o,
    output logic                reg_we_en_o,

    // External Memory I/O

    // CAM control pins
    output logic                cam_we_o,
    output logic [5:0]          cam_idx_o,
    output order_entry_t        cam_data_o,

    // Active Chunks control pins
    output logic                chunk_we_o,
    output logic                chunk_side_o, // allows us to only write to 1 active chunks
    output logic [BBO_W-1:0]    chunk_row_o,
    output logic                chunk_val_o,

    output logic                we_a,
    output logic [HASH_W-1:0]   addr_a,
    output order_entry_t [2:0]  din_a,
    output logic                bid_we_a,
    output logic [BBO_W-1:0]    bid_addr_a,
    output logic [SHARES_W-1:0] bid_din_a,
    output logic                ask_we_a,
    output logic [BBO_W-1:0]    ask_addr_a,
    output logic [SHARES_W-1:0] ask_din_a,

    output logic                we_b,
    output logic [HASH_W-1:0]   addr_b,
    output order_entry_t [2:0]  din_b,
    output logic                bid_we_b,
    output logic [BBO_W-1:0]    bid_addr_b,
    output logic [SHARES_W-1:0] bid_din_b,
    output logic                ask_we_b,
    output logic [BBO_W-1:0]    ask_addr_b,
    output logic [SHARES_W-1:0] ask_din_b
);

// state machine used if we enter the REPLACE_ADD State (i.e. a repl ins)
typedef enum logic{REPLACE_CYCLE_1, REPLACE_CYCLE_2} replace_t;

replace_t replace_state;

// Internal Registers
logic [SHARES_W-1:0] tmp_base_shares;

assign tmp_base_shares = (latched_event_price_idx_i == latched_lookup_price_idx_i) ?
                         (latched_book_shares_i - latched_lookup_entry_i.shares) :
                         latched_event_shares_i;

// Combinational UPDATE_WRITE logic
always_comb begin
    // default assignments

    we_a        =   '0;
    bid_we_a    =   '0;
    ask_we_a    =   '0;
    cam_we_o    =   '0;
    chunk_we_o  =   '0;

    addr_a      =   latched_hash_idx_i;
    din_a       =   latched_read_bucket_i;

    bid_addr_a  =   '0;
    bid_din_a   =   '0;
    ask_addr_a  =   '0;
    ask_din_a   =   '0;

    cam_idx_o   =   latched_cam_idx_i;
    cam_data_o  =   '0;
    chunk_side_o=   reg_target_side_i;
    chunk_row_o =   reg_chosen_row_i;
    chunk_val_o =   reg_target_val_i;

    if(stage_valid_i) begin

        if(replace_state == REPLACE_CYCLE_1) begin

            chunk_we_o  =   reg_we_en_i;

            if(latched_is_cam_entry_i) begin
                cam_we_o    =   1'b1;
                if(latched_is_add_i) begin
                    cam_data_o.valid        =   1'b1;
                    cam_data_o.orn          =   latched_rdata_i.orn;
                    cam_data_o.side         =   latched_rdata_i.side;
                    cam_data_o.shares       =   latched_rdata_i.shares;
                    cam_data_o.price        =   latched_rdata_i.price;
                    cam_data_o.tombstone    =   1'b0;
                end
                else if(latched_is_delete_i || latched_is_replace_i) cam_data_o.tombstone   =   1'b1;
                else begin
                    if(latched_rdata_i.shares >= latched_lookup_entry_i.shares) begin
                        cam_data_o.tombstone = 1'b1;
                    end
                    else begin
                        cam_data_o.shares = latched_lookup_entry_i.shares - latched_rdata_i.shares;
                    end
                end
            end

            we_a    =   !latched_is_cam_entry_i;

            if(latched_is_add_i) begin
                din_a[latched_slot_idx_i].valid         =   1'b1;
                din_a[latched_slot_idx_i].orn           =   latched_rdata_i.orn;
                din_a[latched_slot_idx_i].side          =   latched_rdata_i.side;
                din_a[latched_slot_idx_i].shares        =   latched_rdata_i.shares;
                din_a[latched_slot_idx_i].price         =   latched_rdata_i.price;
                din_a[latched_slot_idx_i].tombstone     =   1'b0;

                if(latched_rdata.side) begin
                    bid_we_a    =   1'b1;
                    bid_addr_a  =   latched_event_price_idx_i;
                    bid_din_a   =   latched_event_shares_i + latched_rdata_i.shares;
                end
                else begin
                    ask_we_a    =   1'b1;
                    ask_addr_a  =   latched_event_price_idx_i;
                    ask_din_a   =   latched_event_shares_i + latched_rdata_i.shares;
                end
            end
            else if(latched_is_delete_i || latched_is_replace_i) begin
                din_a                               =   read_bucket_i;
                din_a[latched_slot_idx_i].tombstone =   1'b1;

                if(latched_lookup_entry_i.side) begin
                    bid_we_a    =   1'b1;
                    bid_addr_a  =   latched_lookup_price_idx_i;
                    bid_din_a   =   latched_book_shares_i - latched_lookup_entry_i.shares;
                end
                else begin
                    ask_we_a    =   1'b1;
                    ask_addr_a  =   latched_lookup_price_idx_i;
                    ask_din_a   =   latched_book_shares_i - latched_lookup_entry_i.shares;
                end
            end
            else begin
                din_a   =   read_bucket_i;

                if(latched_rdata_i.shares >= latched_lookup_entry_i.shares) begin
                    din_a[latched_slot_idx_i].tombstone =   1'b1;
                end
                else begin
                    din_a[latched_slot_idx_i].shares    =  latched_lookup_entry_i.shares - latched_rdata_i.shares;
                end

                if(latched_lookup_entry_i.side) begin
                    bid_we_a    =   1'b1;
                    bid_addr_a  =   latched_lookup_price_idx_i;
                    bid_din_a   =   latched_book_shares_i - latched_lookup_entry_i.shares;
                end
                else begin
                    ask_we_a    =   1'b1;
                    ask_addr_a  =   latched_lookup_price_idx_i;
                    ask_din_a   =   latched_book_shares_i - latched_lookup_entry_i.shares;
                end
            end
        end
    end
end

// Combinational REPLACE_ADD Logic
always_comb begin
    // default assignments
    we_b        =   '0;
    bid_we_b    =   '0;
    ask_we_b    =   '0;

    addr_b      =   '0;
    din_b       =   latched_rep_read_bucket_i;

    bid_addr_b  =   '0;
    bid_din_b   =   '0;
    ask_addr_b  =   '0;
    ask_din_b   =   '0;


    if(stage_valid_i) begin

        if(replace_state == REPLACE_CYCLE_2) begin

            we_b    =   !latched_is_cam_entry_i;

            if(latched_hash_idx_i == latched_rep_hash_idx_i) begin
                din_b[latched_slot_idx_i].tombstone =   1'b1;
            end

            din_b[rep_latched_slot_idx_i].valid         =   1'b1;
            din_b[rep_latched_slot_idx_i].orn           =   latched_rdata_i.updated_orn;
            din_b[rep_latched_slot_idx_i].side          =   latched_lookup_entry_i.side;
            din_b[rep_latched_slot_idx_i].shares        =   latched_rdata_i.shares;
            din_b[rep_latched_slot_idx_i].price         =   latched_rdata_i.price;
            din_b[rep_latched_slot_idx_i].tombstone     =   1'b0;

            if(latched_lookup_entry_i.side) begin
                bid_we_b    =   1'b1;
                bid_addr_b  =   latched_event_price_idx_i;
                bid_din_b   =   tmp_base_shares + latched_rdata_i.shares;
            end
            else begin
                ask_we_b    =   1'b1;
                ask_addr_b  =   latched_event_price_idx_i;
                ask_din_b   =   tmp_base_shares + latched_rdata_i.shares;
            end
        end
    end
end

assign stall = latched_is_replace_i ? (replace_state == REPLACE_CYCLE_1) : 1'b0;

// SEQUENTIAL LOGIC
always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o               <=  1'b0;
        latched_rdata_o             <=  '0;
        latched_base_price_o        <=  '0;
        latched_is_add_o            <=  1'b0;
        latched_is_reduce_o         <=  1'b0;
        latched_is_replace_o        <=  1'b0;
        latched_is_delete_o         <=  1'b0;

        latched_event_price_idx_o   <=  '0;
        latched_is_cam_entry_o      <=  1'b0;
        latched_cam_idx_o           <=  '0;
        latched_slot_idx_o          <=  '0;
        latched_rep_slot_idx_o      <=  '0;
        latched_lookup_entry_o      <=  '0;
        latched_lookup_price_idx_o  <=  '0;
        reg_target_val_o            <=  1'b0;
        reg_chosen_row              <=  '0;
        reg_target_side_o           <=  1'b0;
        latched_book_shares_o       <=  '0;
        latched_event_shares_o      <=  '0;
        replace_state               <=  REPLACE_CYCLE_1;
    end
    else begin
        if(replace_state == REPLACE_CYCLE_1 && stage_valid_i && latched_is_replace_i) begin
            replace_state   <=  REPLACE_CYCLE_2;
            stage_valid_o   <=  1'b0;
        end
        else begin
            replace_state               <=  REPLACE_CYCLE_1;
            stage_valid_o               <=  stage_valid_i;
            latched_rdata_o             <=  latched_rdata_i;
            latched_base_price_o        <=  latched_base_price_i;
            latched_is_add_o            <=  latched_is_add_i;
            latched_is_reduce_o         <=  latched_is_reduce_i;
            latched_is_replace_o        <=  latched_is_replace_i;
            latched_is_delete_o         <=  latched_is_delete_i;

            latched_event_price_idx_o   <=  latched_event_price_idx_i;
            latched_is_cam_entry_o      <=  latched_is_cam_entry_i;
            latched_cam_idx_o           <=  latched_cam_idx_i;
            latched_slot_idx_o          <=  latched_slot_idx_i;
            latched_rep_slot_idx_o      <=  latched_rep_slot_idx_i;
            latched_lookup_entry_o      <=  latched_lookup_entry_i;
            latched_lookup_price_idx_o  <=  latched_lookup_price_idx_i;

            if(latched_is_replace_i) begin
                reg_target_val_o    <=  1'b1;
                reg_chosen_row_o    <=  latched_event_price_idx_i;
                reg_we_en_o         <=  1'b1;
                reg_target_side_o   <=  reg_target_side_i;
            end
            else begin
                reg_target_val_o    <=  reg_target_val_i;
                reg_chosen_row_o    <=  reg_chosen_row_i;
                reg_we_en_o         <=  reg_we_en_i;
                reg_target_side_o   <=  reg_target_side_i;
            end
        end
    end
end
