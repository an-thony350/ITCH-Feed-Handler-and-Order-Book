import hdl_header::*;


module ob_calc_block(
    // Control Signals
    input logic                     clk,
    input logic                     rst_n,
    output logic                    stall,

    // Instruction Data inputs
    input logic                     stage_valid_i,
    input o_data_t                  latched_rdata,
    input logic [PRICE_W-1:0]       latched_base_price,
    input logic                     latched_is_add,
    input logic                     latched_is_reduce,
    input logic                     latched_is_replace,
    input logic                     latched_is_delete,

    // Computed DataPath inputs
    input logic [BBO_W-1:0]         latched_event_price_idx,
    input logic                     latched_is_cam_entry,
    input logic [5:0]               latched_cam_idx,
    input logic [1:0]               latched_slot_idx,
    input logic [1:0]               latched_rep_slot_idx,
    input order_entry_t             latched_lookup_entry,
    input logic [BBO_W-1:0]         latched_lookup_price_idx,
    input logic [HASH_W-1:0]        latched_hash_idx,
    input logic [HASH_W-1:0]        latched_rep_hash_idx,
    input order_entry_t [2:0]       latched_read_bucket,
    input order_entry_t [2:0]       latched_rep_read_bucket,


    // External Memory inputs
    input logic [SHARES_W-1:0]  bid_dout_a,
    input logic [SHARES_W-1:0]  bid_dout_b,
    input logic [SHARES_W-1:0]  ask_dout_a,
    input logic [SHARES_W-1:0]  ask_dout_b,

    input logic [CHUNK_LEN-1:0] bid_enc_valid,
    input logic [CHUNK_LEN-1:0] ask_enc_valid,
    input logic [63:0]          bid_active_chunks [CHUNK_LEN-1:0],
    input logic [63:0]          ask_active_chunks [CHUNK_LEN-1:0],

    // External Memory outputs
    output logic                cam_we,
    output logic [5:0]          cam_idx,
    output order_entry_t        cam_data,

    // Active Chunks control pins
    output logic                chunk_we,
    output logic                chunk_side, // allows us to only write to 1 active chunks
    output logic [BBO_W-1:0]    chunk_row,
    output logic                chunk_val,

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
    output logic [SHARES_W-1:0] ask_din_b,

    // BBO outputs
    output bbo_t                bbo_data_o,
    output logic                bbo_valid_o,

    // backpressure ready signal
);

// state machine for the backend states

typedef enum logic [2:0] { // see if one state can be removed
    UPDATE_READ_BOOK,
    UPDATE_WRITE,
    REPLACE_ADD,
    EVALUATE_BBO,
    BBO_SEARCH_REQ,
    BBO_SEARCH_EVAL,
    FETCH_BBO,
    FETCH_BBO_WAIT
} backend_state_t;

backend_state_t current_state, next_state;

// Internal registers

logic [SHARES_W-1:0]    immediate_book_shares;
logic                   immediate_level_depleted;

logic [SHARES_W-1:0]    tmp_base_shares;

logic                   reg_we_en;
logic                   reg_target_val;
logic                   reg_target_side;
logic [BBO_W-1:0]       reg_chosen_row;

// Data latched during UPDATE_READ_BOOK
logic [SHARES_W-1:0]    latched_book_shares;
logic [SHARES_W-1:0]    latched_event_shares;
logic                   latched_bid_valid_rst;
logic                   latched_ask_valid_rst;

// BBO Tracking Registers
logic [BBO_W-1:0]       current_best_bid;
logic [BBO_W-1:0]       current_best_ask;
logic [BBO_W-1:0]       search_idx;
logic                   search_side;
logic [(BBO_W-6)-1:0]   target_chunk_idx;

// Combinational BBO Evaluation Wires
logic                   is_better_ask;
logic                   is_better_bid;
logic                   ask_depleted;
logic                   bid_depleted;

// Combinational logic for state assignments

always_comb begin

    next_state = current_state;

    we_a        =   1'b0;
    bid_we_a    =   '0;
    ask_we_a    =   '0;

    we_b        =   1'b0;
    bid_we_b    =   '0;
    ask_we_b    =   '0;

    addr_a      =   latched_hash_idx;
    din_a       =   latched_read_bucket;

    addr_b      =   '0;
    din_b       =   latched_rep_read_bucket;

    bid_addr_a  =   '0;
    bid_din_a   =   '0;
    ask_addr_a  =   '0;
    ask_din_a   =   '0;

    bid_addr_b  =   '0;
    bid_din_b   =   '0;
    ask_addr_b  =   '0;
    ask_din_b   =   '0;

    cam_we    =   '0;
    chunk_we  =   '0;

    cam_idx   =   latched_cam_idx;
    cam_data  =   '0;
    chunk_side=   reg_target_side;
    chunk_row =   reg_chosen_row;
    chunk_val =   reg_target_val;


    is_better_ask   =   1'b0;
    is_better_bid   =   1'b0;
    ask_depleted    =   1'b0;
    bid_depleted    =   1'b0;



    stall           =   !(!stage_valid_i && current_state == UPDATE_READ_BOOK);

    case(current_state)

        UPDATE_READ_BOOK: begin
                next_state                  =   (stage_valid_i) ? UPDATE_WRITE : UPDATE_READ_BOOK;
                immediate_book_shares       =   latched_lookup_entry.side ? bid_dout_a : bid_dout_b;
                immediate_level_depleted    =   latched_is_reduce ?
                                                (immediate_book_shares == latched_rdata.shares) :
                                                (immediate_book_shares == latched_lookup_entry.shares);
            end

            UPDATE_WRITE: begin
                next_state = (latched_is_replace) ? REPLACE_ADD : EVALUATE_BBO;
                we_a        =   !latched_is_cam_entry;
                chunk_we    =   reg_we_en;

                if(latched_is_cam_entry) begin
                    cam_we    =   1'b1;
                    if(latched_is_add) begin
                        cam_data.valid        =   1'b1;
                        cam_data.orn          =   latched_rdata.orn;
                        cam_data.side         =   latched_rdata.side;
                        cam_data.shares       =   latched_rdata.shares;
                        cam_data.price        =   latched_rdata.price;
                        cam_data.tombstone    =   1'b0;
                    end
                    else if(latched_is_delete || latched_is_replace) cam_data.tombstone   =   1'b1;
                    else begin
                        if(latched_rdata.shares >= latched_lookup_entry.shares) begin
                            cam_data.tombstone = 1'b1;
                        end
                        else begin
                            cam_data.shares = latched_lookup_entry.shares - latched_rdata.shares;
                        end
                    end
                end

                if(latched_is_add) begin

                    din_a[latched_slot_idx].valid     = 1'b1;
                    din_a[latched_slot_idx].orn       = latched_rdata.orn;
                    din_a[latched_slot_idx].side      = latched_rdata.side;
                    din_a[latched_slot_idx].shares    = latched_rdata.shares;
                    din_a[latched_slot_idx].price     = latched_rdata.price;
                    din_a[latched_slot_idx].tombstone = 1'b0;

                    if(latched_rdata.side) begin
                        bid_we_a   = 1'b1;
                        bid_addr_a = latched_event_price_idx;
                        bid_din_a  = latched_event_shares + latched_rdata.shares;
                    end
                    else begin
                        ask_we_a   = 1'b1;
                        ask_addr_a = latched_event_price_idx;
                        ask_din_a  = latched_event_shares + latched_rdata.shares;
                    end
                end
                else if(latched_is_delete || latched_is_replace) begin
                    din_a                               = read_bucket;
                    din_a[latched_slot_idx].tombstone   = 1'b1;

                    if(latched_lookup_entry.side) begin
                        bid_we_a   = 1'b1;
                        bid_addr_a = latched_lookup_price_idx;
                        bid_din_a  = latched_book_shares - latched_lookup_entry.shares;
                    end
                    else begin
                        ask_we_a   = 1'b1;
                        ask_addr_a = latched_lookup_price_idx;
                        ask_din_a  = latched_book_shares - latched_lookup_entry.shares;
                    end
                end
                else begin
                    din_a  = read_bucket;

                    if(latched_rdata.shares >= latched_lookup_entry.shares) begin
                        din_a[latched_slot_idx].tombstone = 1'b1;
                    end
                    else begin
                        din_a[latched_slot_idx].shares = latched_lookup_entry.shares - latched_rdata.shares;
                    end
                    if(latched_lookup_entry.side) begin
                        bid_we_a   = 1'b1;
                        bid_addr_a = latched_lookup_price_idx;
                        bid_din_a  = latched_book_shares - latched_rdata.shares;
                    end
                    else begin
                        ask_we_a   = 1'b1;
                        ask_addr_a = latched_lookup_price_idx;
                        ask_din_a  = latched_book_shares - latched_rdata.shares;
                    end
                end
            end

            REPLACE_ADD: begin
                next_state      = EVALUATE_BBO;
                we_b            = !latched_is_cam_entry;

                tmp_base_shares =   (latched_event_price_idx == latched_lookup_price_idx) ?
                                    (latched_book_shares - latched_lookup_entry.shares) :
                                    latched_event_shares;

                if (hash_idx == rep_hash_idx) begin
                    din_b[latched_slot_idx].tombstone = 1'b1;
                end

                din_b[rep_latched_slot_idx].valid     = 1'b1;
                din_b[rep_latched_slot_idx].orn       = latched_rdata.updated_orn;
                din_b[rep_latched_slot_idx].side      = latched_lookup_entry.side;
                din_b[rep_latched_slot_idx].shares    = latched_rdata.shares;
                din_b[rep_latched_slot_idx].price     = latched_rdata.price;
                din_b[rep_latched_slot_idx].tombstone = 1'b0;

                if(latched_lookup_entry.side) begin
                    bid_we_b   = 1'b1;
                    bid_addr_b = latched_event_price_idx;
                    bid_din_b  = tmp_base_shares + latched_rdata.shares;
                end
                else begin
                    ask_we_b   = 1'b1;
                    ask_addr_b = latched_event_price_idx;
                    ask_din_b  = tmp_base_shares + latched_rdata.shares;
                end
            end

            EVALUATE_BBO: begin
                if(latched_is_add) begin
                    if( latched_rdata.side && latched_event_price_idx > current_best_bid) is_better_bid  = 1'b1;
                    if(~latched_rdata.side && latched_event_price_idx < current_best_ask) is_better_ask  = 1'b1;
                end
                else if(latched_is_replace) begin
                    if( latched_lookup_entry.side && latched_event_price_idx > current_best_bid) is_better_bid  = 1'b1;
                    if(~latched_lookup_entry.side && latched_event_price_idx < current_best_ask) is_better_ask  = 1'b1;
                end

                if(latched_is_reduce || latched_is_delete) begin
                    if(level_depleted) begin
                        if( latched_lookup_entry.side && latched_lookup_price_idx == current_best_bid) bid_depleted = 1'b1;
                        if(~latched_lookup_entry.side && latched_lookup_price_idx == current_best_ask) ask_depleted = 1'b1;
                    end
                end
                else if(latched_is_replace) begin
                    if(level_depleted) begin
                        if( latched_lookup_entry.side && latched_lookup_price_idx == current_best_bid && latched_lookup_price_idx != latched_event_price_idx)
                        bid_depleted = 1'b1;
                        if(~latched_lookup_entry.side && latched_lookup_price_idx == current_best_ask && latched_lookup_price_idx != latched_event_price_idx)
                        ask_depleted = 1'b1;
                    end
                end

                if(is_better_bid || is_better_ask)      next_state =   FETCH_BBO;
                else if((bid_depleted && current_best_bid != '0) ||(ask_depleted && current_best_ask != BBO_W'(BBO_DEPTH-1)))
                                                        next_state =   BBO_SEARCH_REQ;
                else                                    next_state =   FETCH_BBO;
            end

            BBO_SEARCH_REQ: begin
                next_state  =   BBO_SEARCH_EVAL;
            end

            BBO_SEARCH_EVAL: begin
                next_state  =   FETCH_BBO;
            end

            FETCH_BBO: begin
                next_state  =   FETCH_BBO_WAIT;
                bid_addr_a  =   current_best_bid;
                ask_addr_a  =   current_best_ask;
            end

            FETCH_BBO_WAIT: begin
                bid_addr_a  = current_best_bid;
                ask_addr_a  = current_best_ask;
                next_state  = UPDATE_READ_BOOK;
            end
    endcase
end



always_ff @(posedge clk) begin
    if(!rst_n) begin
        current_state   <=  UPDATE_READ_BOOK;
        bbo_valid_o     <=  1'b0;
        current_best_bid<=  '0;
        current_best_ask<=  BBO_W'(BBO_DEPTH-1);
    end
    else begin
        current_state   <=  next_state;
        bbo_valid_o     <=  1'b0;

        case(current_state)
            UPDATE_READ_BOOK: begin
                if(stage_valid_i) begin
                    latched_bid_valid_rst       <=      (bid_active_chunks[latched_lookup_price_idx[BBO_W-1:6]] == (64'h1 << latched_lookup_price_idx[5:0]));
                    latched_ask_valid_rst       <=      (ask_active_chunks[latched_lookup_price_idx[BBO_W-1:6]] == (64'h1 << latched_lookup_price_idx[5:0]));

                    if(latched_is_add) begin
                    reg_target_val  <= 1'b1;
                    reg_chosen_row  <= latched_event_price_idx;
                    reg_target_side <= latched_rdata.side;
                    reg_we_en       <= 1'b1;
                    end
                    else if(latched_is_replace || latched_is_delete || latched_is_reduce) begin
                        reg_target_val  <= 1'b0;
                        reg_chosen_row  <= latched_lookup_price_idx;
                        reg_target_side <= latched_lookup_entry.side;
                        reg_we_en       <= immediate_level_depleted;
                    end

                    if(latched_lookup_entry.side) begin
                        latched_book_shares  <= bid_dout_a;
                    end
                    else begin
                        latched_book_shares  <= ask_dout_a;
                    end

                    if(latched_rdata.message_type == MSG_REPLACE ? latched_lookup_entry.side : latched_rdata.side) begin
                        latched_event_shares <= bid_dout_b;
                    end
                    else begin
                        latched_event_shares <= ask_dout_b;
                    end
                end

                UPDATE_WRITE: begin
                    if(latched_is_replace) begin
                        reg_target_val    <=  1'b1;
                        reg_chosen_row    <=  latched_event_price_idx;
                        reg_we_en         <=  1'b1;
                        reg_target_side   <=  reg_target_side;
                    end
                    else begin
                        reg_target_val    <=  reg_target_val;
                        reg_chosen_row    <=  reg_chosen_row;
                        reg_we_en         <=  reg_we_en;
                        reg_target_side   <=  reg_target_side;
                    end
                end
            end

            REPLACE_ADD: begin
            end

            EVALUATE_BBO: begin
                if(is_better_bid) current_best_bid  <=  latched_event_price_idx;
                else if(bid_depleted && current_best_bid != '0) begin
                    search_idx  <=  current_best_bid    -   1'b1;
                    search_side <=  1'b1;
                end

                if(is_better_ask) current_best_ask  <=  latched_event_price_idx;
                else if(ask_depleted && current_best_ask != BBO_W'(BBO_DEPTH-1)) begin
                    search_idx  <=  current_best_ask    +   1'b1;
                    search_side <=  1'b0;
                end
            end

            BBO_SEARCH_REQ: begin
                if(search_side) target_chunk_idx    <=  find_msb_chunk(bid_enc_valid);
                else            target_chunk_idx    <=  find_lsb_chunk(ask_enc_valid);
            end

            BBO_SEARCH_EVAL: begin
                if(search_side) begin
                    if(bid_enc_valid == '0) begin
                        current_best_bid    <=  '0;
                    end
                    else begin
                        current_best_bid    <=  {target_chunk_idx, find_msb_bit(bid_active_chunks[target_chunk_idx])};
                    end
                end
                else begin
                    if(ask_enc_valid == '0) begin
                        current_best_ask    <=  BBO_W'(BBO_DEPTH-1);
                    end
                    else begin
                        current_best_ask    <=  {target_chunk_idx, find_lsb_bit(ask_active_chunks[target_chunk_idx])};
                    end
                end
            end

            FETCH_BBO_WAIT: begin

                bbo_valid_o <=  1'b1;
                if (bid_enc_valid == '0) begin
                    bbo_data_o.bid_price  <= '0;
                    bbo_data_o.bid_shares <= '0;
                end
                else begin
                    bbo_data_o.bid_price  <= latched_base_price + PRICE_W'(current_best_bid);

                    if(bid_we_a && (bid_addr_a == current_best_bid)) begin
                        bbo_data_o.bid_shares   <=  bid_din_a;
                    end
                    else if(bid_we_b && (bid_addr_b == current_best_bid)) begin
                        bbo_data_o.bid_shares   <=  bid_din_b;
                    end
                    else bbo_data_o.bid_shares  <=  bid_dout_a;
                end

                if (ask_enc_valid == '0) begin
                    bbo_data_o.ask_price  <= '0;
                    bbo_data_o.ask_shares <= '0;
                end
                else begin
                    bbo_data_o.ask_price  <= latched_base_price + PRICE_W'(current_best_ask);

                    if(ask_we_a && (ask_addr_a == current_best_ask)) begin
                        bbo_data_o.ask_shares   <=  ask_din_a;
                    end
                    else if(ask_we_b && (ask_addr_b == current_best_ask)) begin
                        bbo_data_o.ask_shares   <=  ask_din_b;
                    end
                    else bbo_data_o.ask_shares  <=  ask_dout_a;
                end
            end
        endcase
    end
end


endmodule
