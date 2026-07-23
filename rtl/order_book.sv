`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 29.06.2026 15:15:19
// Design Name: Order Book
// Module Name: order_book
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2023.2
//
// Description: The order book carries both combinational and sequential logic
// through a Mealy model state machne of 14 states allowing for both accurate data
// capture of orders for a specific stock, as well as two price books determining the
// best buy and sell prices
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created & base structure formed
// Revision 0.02 - All instructions except for Replace
// Revision 0.10 - Valid/ready handshake & replacement state added
// Revision 1.00 - Addition of base price logic (with symbol router) & pipelined
//                 registers for the price books
// Revision 1.01 - Addition of delta price functions, and explicit bit specification
//                 to remove verilator warinings
// Revision 1.02 - Latching of multiple registers, avoiding hash collisions
// Revision 1.10 - Compatibility with symbol router & top module
// Revision 2.00 - Change of hash collision traversal - using probe searching
//                 rather than linked list traversal (see note [1] in comments)
// Revision 2.01 - Addition of header package file (hdl_header), cleaning up data IO
// Revision 2.10 - Chunk/bit priority encoders for BBO output traversal & tombstone
//                 additions in probe searching logic to fix key hashing collision
//                 faults introduced with probe searching
// Revision 2.11 - debug & cleanup
// Revision 3.00 - Change of how three books are written to, implemented as True-Port
//                 BRAM, ensuring design is synthesizable in Vivado w/o high LUT use
// Revision 3.10 - Pipelining and replicating registers to optimise timing
// Revision 3.11 - Increasing price window by increasing BBO_W and relevent logic
//
// Additional Comments:
// [1]: In the previous design, a Linked List was formed to determine hash entries
//      and indexes. If a hash index was already in use, it would have a reference
//      index which pointed to another index in the order book. This would allow
//      the traversal of indexes until the correct ORN is found. Given the heavy
//      data requirement, we have chosen to change this to a probe seaching method
//      this method effectively works on spacial locality, where in a hash collision
//      the index will increase by 1 and look into the new address to se if a slot
//      is free. If so, the hash index for that ORN is updated accordingly. This is
//      less heavy on resources and faster, but will cause data to be lost if there
//      are no free slots in range [hash_idx, hash_idx + MAX_PROBES)
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module order_book(
    input  logic               clk,
    input  logic               rst_n,

    // input from symbol router
    input  o_data_t            rdata_i,
    input  logic               valid_i,
    input  logic [PRICE_W-1:0] base_price_i,

    // output to symbol router
    output logic               ready_o,

    // BBO output
    output bbo_t               bbo_data_o,
    output logic               bbo_valid_o
);

// Struct for data inputted to order book

typedef struct packed {
    logic                   valid;
    logic [ORN_W-1:0]       orn;
    logic                   side;
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
    logic                   tombstone;
} order_entry_t;



// local parameters for tables and ASCII message types

localparam int HASH_DEPTH = 1 << HASH_W;
localparam int BBO_DEPTH  = 1 << BBO_W;
localparam int CHUNK_LEN  = 1 << (BBO_W-6);
localparam int ENTRY_W    = $bits(order_entry_t);


localparam logic [MSG_W-1:0] MSG_ADD_A    = 8'h41; // A
localparam logic [MSG_W-1:0] MSG_ADD_F    = 8'h46; // F
localparam logic [MSG_W-1:0] MSG_EXEC     = 8'h45; // E
localparam logic [MSG_W-1:0] MSG_EXEC_PX  = 8'h43; // C
localparam logic [MSG_W-1:0] MSG_DELETE   = 8'h44; // D
localparam logic [MSG_W-1:0] MSG_REPLACE  = 8'h55; // U
localparam logic [MSG_W-1:0] MSG_CANCEL   = 8'h58; // X



// internal registers

// BRAM Blocks
(* ram_style = "block" *) logic [ENTRY_W-1:0]   order_table    [HASH_DEPTH-1:0];
(* ram_style = "block" *) logic [SHARES_W-1:0]  bid_price_book [BBO_DEPTH-1:0];
(* ram_style = "block" *) logic [SHARES_W-1:0]  ask_price_book [BBO_DEPTH-1:0];


// Dual-Port (A & B) BRAM registers - data, write-enable, & address pointer registers

// order table registers
logic               we_a;
logic [HASH_W-1:0]  addr_a;
order_entry_t       din_a;
order_entry_t       dout_a;

logic               we_b;
logic [HASH_W-1:0]  addr_b;
order_entry_t       din_b;
order_entry_t       dout_b;

logic [ENTRY_W-1:0] ram_din_a;
logic [ENTRY_W-1:0] ram_dout_a;
logic [ENTRY_W-1:0] ram_din_b;
logic [ENTRY_W-1:0] ram_dout_b;

// bid price book registers
logic                bid_we_a;
logic [BBO_W-1:0]    bid_addr_a;
logic [SHARES_W-1:0] bid_din_a;
logic [SHARES_W-1:0] bid_dout_a;

logic                bid_we_b;
logic [BBO_W-1:0]    bid_addr_b;
logic [SHARES_W-1:0] bid_din_b;
logic [SHARES_W-1:0] bid_dout_b;

// ask price book registers
logic                ask_we_a;
logic [BBO_W-1:0]    ask_addr_a;
logic [SHARES_W-1:0] ask_din_a;
logic [SHARES_W-1:0] ask_dout_a;

logic                ask_we_b;
logic [BBO_W-1:0]    ask_addr_b;
logic [SHARES_W-1:0] ask_din_b;
logic [SHARES_W-1:0] ask_dout_b;


// IDX registers
logic [BBO_W-1:0]   clear_idx;
logic [HASH_W-1:0]  lookup_idx;
logic [HASH_W-1:0]  hash_idx;
logic [HASH_W-1:0]  rep_hash_idx;
logic [BBO_W-1:0]   lookup_p_idx_wire;
logic [HASH_W-1:0]  insert_idx;


// Found signals
logic idx_found;
logic rep_idx_found;


// IDX Search registers
int           probe;
int           rep_probe;
order_entry_t h_entry;
order_entry_t rep_h_entry;


// Replacement Add registers
logic                rep_same_price;
logic [SHARES_W-1:0] base_add_shares;
logic [SHARES_W-1:0] tmp_base_shares;


// Latched registers
o_data_t                latched_rdata;
order_entry_t           latched_lookup_entry;
logic [PRICE_W-1:0]     latched_base_price;
logic [SHARES_W-1:0]    latched_book_shares;
logic [SHARES_W-1:0]    latched_event_shares;
logic [BBO_W-1:0]       latched_lookup_price_idx;
logic [BBO_W-1:0]       latched_event_price_idx;
logic                   latched_bid_valid_rst;
logic                   latched_ask_valid_rst;

(* max_fanout = 32 *) logic latched_is_add;
(* max_fanout = 32 *) logic latched_is_reduce;
(* max_fanout = 32 *) logic latched_is_replace;
(* max_fanout = 32 *) logic latched_is_delete;


// Price book & BBO output registers
logic [CHUNK_LEN-1:0]    bid_enc_valid;
logic [CHUNK_LEN-1:0]    ask_enc_valid;
logic [63:0]             bid_active_chunks [CHUNK_LEN-1:0];
logic [63:0]             ask_active_chunks [CHUNK_LEN-1:0];
logic [(BBO_W-6)-1:0]    target_chunk_idx;


logic [BBO_W-1:0]           current_best_bid;
logic [BBO_W-1:0]           current_best_ask;
logic [BBO_W-1:0]           search_idx;
logic                       search_side;

logic                       is_better_bid;
logic                       is_better_ask;
logic                       bid_depleted;
logic                       ask_depleted;


// registers heping reduce fanout in state calculation
logic   [BBO_W-1:0]        chosen_row;
logic                      target_val;
logic                      target_side;
logic                      we_en;
logic                      level_depleted;



// state machine for order book data

typedef enum logic [3:0]{
    CLEAR,
    IDLE,
    IDX_REQ,
    IDX_SEARCH,
    UPDATE_READ_TBL,
    UPDATE_READ_BOOK,
    UPDATE_WRITE,
    REPLACE_ADD,
    EVALUATE_BBO,
    BBO_SEARCH_REQ,
    BBO_SEARCH_EVAL,
    FETCH_BBO,
    FETCH_BBO_WAIT,
    EMIT
} state_t;

(* max_fanout = 32 *) state_t current_state, next_state;



// functions to determine type of message - ADD and EXECUTE messages have multiple calls

function automatic logic is_add_msg(input logic [MSG_W-1:0] msg);
    return (msg == MSG_ADD_A) || (msg == MSG_ADD_F);
endfunction

function automatic logic is_reduce_msg(input logic [MSG_W-1:0] msg);
    return (msg == MSG_EXEC) || (msg == MSG_EXEC_PX) || (msg == MSG_CANCEL);
endfunction

// Hashing function
function automatic logic [HASH_W-1:0] hash_orn(input logic [ORN_W-1:0] orn);
    logic [HASH_W-1:0] h;
    begin
        h = '0;
        for (int bit_i = 0; bit_i < ORN_W; bit_i++) begin
            h[bit_i % HASH_W] = h[bit_i % HASH_W] ^ orn[bit_i];
        end
        return h;
    end
endfunction

// Price logic (for price book) - Only works if delta < $164.83
function automatic logic [BBO_W-1:0] price_to_idx(input logic [PRICE_W-1:0] price);
    logic [PRICE_W-1:0] delta;
    begin
        delta = price - latched_base_price;
        return delta[BBO_W-1:0];
    end
endfunction

// Hierarchical Search: Level 1 (Find the 64-bit chunk)
function automatic logic [(BBO_W-6)-1:0] find_msb_chunk(input logic [CHUNK_LEN-1:0] vec);
    for (int i = CHUNK_LEN-1; i >= 0; i--) begin
        if (vec[i]) return (BBO_W-6)'(i);
    end
    return '0;
endfunction

function automatic logic [(BBO_W-6)-1:0] find_lsb_chunk(input logic [CHUNK_LEN-1:0] vec);
    for (int i = 0; i < CHUNK_LEN; i++) begin
        if (vec[i]) return (BBO_W-6)'(i);
    end
    return '0;
endfunction

// Hierarchical Search: Level 2 (Find the exact bit in the chunk)
function automatic logic [5:0] find_msb_bit(input logic [63:0] vec);
    for (int i = 63; i >= 0; i--) begin
        if (vec[i]) return 6'(i);
    end
    return '0;
endfunction

function automatic logic [5:0] find_lsb_bit(input logic [63:0] vec);
    for (int i = 0; i < 64; i++) begin
        if (vec[i]) return 6'(i);
    end
    return '0;
endfunction



// Combinational assignments

// idx assignments
assign lookup_p_idx_wire        =   price_to_idx(dout_a.price);

// hashed data assignments
assign h_entry                  =   dout_a;
assign rep_h_entry              =   dout_b;

// Combinational State machine logic

always_comb begin
    // default assignments

    next_state = current_state;

    we_a       = 1'b0;
    addr_a     = clear_idx[HASH_W-1:0];
    din_a      = '0;

    we_b       = 1'b0;
    addr_b     = clear_idx[HASH_W-1:0];
    din_b      = '0;

    bid_we_a   = 1'b0;
    bid_addr_a = clear_idx;
    bid_din_a  = '0;

    bid_we_b   = 1'b0;
    bid_addr_b = clear_idx;
    bid_din_b  = '0;

    ask_we_a   = 1'b0;
    ask_addr_a = clear_idx;
    ask_din_a  = '0;

    ask_we_b   = 1'b0;
    ask_addr_b = clear_idx;
    ask_din_b  = '0;


    is_better_ask   =   1'b0;
    is_better_bid   =   1'b0;
    ask_depleted    =   1'b0;
    bid_depleted    =   1'b0;

    level_depleted = latched_is_reduce ?
                     (latched_book_shares == latched_rdata.shares) :
                     (latched_book_shares == latched_lookup_entry.shares);

    tmp_base_shares = (latched_event_price_idx == latched_lookup_price_idx) ?
                      (latched_book_shares - latched_lookup_entry.shares) :
                      latched_event_shares;

    if(current_state == UPDATE_WRITE && latched_is_add) begin
        target_val  =       1'b1;
        chosen_row  =       latched_event_price_idx;
        target_side =       latched_rdata.side;
        we_en       =       1'b1;
    end
    else if(current_state == REPLACE_ADD) begin
        target_val  =       1'b1;
        chosen_row  =       latched_event_price_idx;
        target_side =       latched_lookup_entry.side;
        we_en       =       1'b1;
    end
    else if(current_state == UPDATE_WRITE && (latched_is_delete || latched_is_reduce || latched_is_replace))begin
        target_val  =       1'b0;
        chosen_row  =       latched_lookup_price_idx;
        target_side =       latched_lookup_entry.side;
        we_en       =       level_depleted;
    end
    else begin
        target_val  =       1'b0;
        chosen_row  =       '0;
        target_side =       '0;
        we_en       =       1'b0;
    end




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

    case (current_state)
        CLEAR: begin
            next_state = (int'(clear_idx) == (BBO_DEPTH - 1)) ? IDLE : CLEAR;

            we_a       = 1'b1;
            addr_a     = clear_idx[HASH_W-1:0];
            din_a      = '0;

            bid_we_a   = 1'b1;
            bid_addr_a = clear_idx;
            bid_din_a  = '0;

            ask_we_a   = 1'b1;
            ask_addr_a = clear_idx;
            ask_din_a  = '0;
        end

        IDLE: begin
            next_state = valid_i ? IDX_REQ : IDLE;

            addr_a     = valid_i ? hash_orn(rdata_i.orn)         : '0;
            addr_b     = valid_i ? hash_orn(rdata_i.updated_orn) : '0;
        end

        IDX_REQ: begin
            next_state = IDX_SEARCH;

            addr_a     = hash_idx;
            addr_b     = rep_hash_idx;
        end

        IDX_SEARCH: begin
            addr_a     = hash_idx;
            addr_b     = rep_hash_idx;

            if(probe < MAX_PROBES && rep_probe < MAX_PROBES) begin
                if(latched_rdata.message_type == MSG_REPLACE) begin
                    if(!idx_found && !h_entry.valid) next_state =   FETCH_BBO;
                    else if( (idx_found || (h_entry.valid && h_entry.orn == latched_rdata.orn && !h_entry.tombstone)) && ( rep_idx_found || (!rep_h_entry.valid || rep_h_entry.tombstone))) begin
                        next_state  =   UPDATE_READ_TBL;
                    end
                    else begin
                        next_state  =   IDX_REQ;
                    end
                end
                else if(latched_is_add) begin
                    if(!h_entry.valid || h_entry.tombstone) begin
                        next_state  =   UPDATE_READ_TBL;
                    end
                    else begin
                        next_state  =   IDX_REQ;
                    end
                end
                else begin
                    if(h_entry.valid && h_entry.orn == latched_rdata.orn && !h_entry.tombstone) begin
                        next_state  =   UPDATE_READ_TBL;
                    end
                    else if(!h_entry.valid) begin
                        next_state  =   FETCH_BBO;
                    end
                    else begin
                        next_state  =   IDX_REQ;
                    end
                end
            end
            else next_state =   FETCH_BBO;
        end

        UPDATE_READ_TBL: begin
            next_state  =   UPDATE_READ_BOOK;

            addr_a      =   lookup_idx;

            bid_addr_a  = lookup_p_idx_wire;
            ask_addr_a  = lookup_p_idx_wire;

            bid_addr_b  = latched_event_price_idx;
            ask_addr_b  = latched_event_price_idx;
        end

        UPDATE_READ_BOOK: begin
            next_state      =   UPDATE_WRITE;
        end

        UPDATE_WRITE: begin
            next_state = (latched_is_replace) ? REPLACE_ADD : EVALUATE_BBO;
            we_a       = 1'b1;

            if(latched_is_add) begin
                addr_a          = insert_idx;

                din_a.valid     = 1'b1;
                din_a.orn       = latched_rdata.orn;
                din_a.side      = latched_rdata.side;
                din_a.shares    = latched_rdata.shares;
                din_a.price     = latched_rdata.price;
                din_a.tombstone = 1'b0;

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
            else if(latched_is_delete|| latched_is_replace) begin
                addr_a          = lookup_idx;
                din_a           = latched_lookup_entry;
                din_a.tombstone = 1'b1;

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
                addr_a = lookup_idx;
                din_a  = latched_lookup_entry;

                if(latched_rdata.shares >= latched_lookup_entry.shares) begin
                    din_a.tombstone = 1'b1;
                end
                else begin
                    din_a.shares = latched_lookup_entry.shares - latched_rdata.shares;
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
            next_state = EVALUATE_BBO;


            we_b            = 1'b1;
            addr_b          = insert_idx;

            din_b.valid     = 1'b1;
            din_b.orn       = latched_rdata.updated_orn;
            din_b.side      = latched_lookup_entry.side;
            din_b.shares    = latched_rdata.shares;
            din_b.price     = latched_rdata.price;
            din_b.tombstone = 1'b0;

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
            next_state  = EMIT;
        end

        EMIT: begin
            next_state = IDLE;
        end

        default: begin
            next_state = CLEAR;
        end
    endcase
end

// Combinational ram asssignments - split allows for vivado synthesis

assign ram_din_a = din_a;
assign dout_a    = ram_dout_a;

assign ram_din_b = din_b;
assign dout_b    = ram_dout_b;

// Sequential Dual-Port BRAM writes

// order table writes
always_ff @(posedge clk) begin
    if(we_a) begin
        order_table[addr_a] <= ram_din_a;
    end
    ram_dout_a <= order_table[addr_a];
end

always_ff @(posedge clk) begin
    if(we_b) begin
        order_table[addr_b] <= ram_din_b;
    end
    ram_dout_b <= order_table[addr_b];
end

// bid price book writes
always_ff @(posedge clk) begin
    if(bid_we_a) begin
        bid_price_book[bid_addr_a] <= bid_din_a;
    end
    bid_dout_a <= bid_price_book[bid_addr_a];
end

always_ff @(posedge clk) begin
    if(bid_we_b) begin
        bid_price_book[bid_addr_b] <= bid_din_b;
    end
    bid_dout_b <= bid_price_book[bid_addr_b];
end

// ask price book writes
always_ff @(posedge clk) begin
    if(ask_we_a) begin
        ask_price_book[ask_addr_a] <= ask_din_a;
    end
    ask_dout_a <= ask_price_book[ask_addr_a];
end

always_ff @(posedge clk) begin
    if(ask_we_b) begin
        ask_price_book[ask_addr_b] <= ask_din_b;
    end
    ask_dout_b <= ask_price_book[ask_addr_b];
end

// Sequential Logic for both order book and price book with states
always_ff @(posedge clk) begin

    if (!rst_n) begin
        current_state       <= CLEAR;
        latched_rdata       <= '0;
        latched_base_price  <= '0;
        clear_idx           <= '0;
        bbo_data_o          <= '0;
        bbo_valid_o         <= 1'b0;
        probe               <= '0;
        rep_probe           <= '0;
        idx_found           <= 1'b0;
        rep_idx_found       <= 1'b0;
        current_best_bid    <= '0;
        current_best_ask    <= BBO_W'(BBO_DEPTH-1);
    end
    else begin
        current_state   <= next_state;
        bbo_valid_o     <= 1'b0;

        case (current_state)
            CLEAR: begin
                if (int'(clear_idx) < CHUNK_LEN) begin
                    bid_active_chunks[clear_idx[(BBO_W-6)-1:0]] <= '0;
                    ask_active_chunks[clear_idx[(BBO_W-6)-1:0]] <= '0;
                end

                if(int'(clear_idx) == 0) begin
                    bid_enc_valid <= '0;
                    ask_enc_valid <= '0;
                end

                if (int'(clear_idx) != BBO_DEPTH - 1) begin
                    clear_idx <= clear_idx + 1'b1;
                end
                else clear_idx  <=  '0;
            end

            IDLE: begin
                if (valid_i) begin
                    latched_rdata         <= rdata_i;
                    latched_base_price    <= base_price_i;
                    probe                 <= '0;
                    rep_probe             <= '0;
                    hash_idx              <= hash_orn(rdata_i.orn);
                    rep_hash_idx          <= hash_orn(rdata_i.updated_orn);
                    idx_found             <= 1'b0;
                    rep_idx_found         <= 1'b0;
                    latched_is_add         <= is_add_msg(rdata_i.message_type);
                    latched_is_reduce      <= is_reduce_msg(rdata_i.message_type);
                    latched_is_replace     <= (rdata_i.message_type == MSG_REPLACE);
                    latched_is_delete      <= (rdata_i.message_type == MSG_DELETE);
                end
            end

            IDX_REQ: begin
                latched_event_price_idx     <=      price_to_idx(latched_rdata.price);
            end

            IDX_SEARCH: begin
                if(probe < MAX_PROBES || rep_probe < MAX_PROBES) begin
                    if(is_add_msg(latched_rdata.message_type)) begin
                        if(!h_entry.valid || h_entry.tombstone) begin
                            insert_idx      <=      hash_idx;
                            idx_found       <=      1'b1;
                            rep_idx_found   <=      1'b1;
                        end
                        else begin
                            hash_idx        <=      hash_idx + 1'b1;
                            probe           <=      probe    + 1'b1;
                        end
                    end
                    else if(latched_rdata.message_type == MSG_REPLACE) begin
                        // original idx
                        if(!idx_found) begin
                            if(h_entry.valid && h_entry.orn == latched_rdata.orn && !h_entry.tombstone) begin
                                lookup_idx      <=      hash_idx;
                                idx_found       <=      1'b1;
                            end
                            else begin
                                hash_idx        <=      hash_idx + 1'b1;
                                probe           <=      probe    + 1'b1;
                            end
                        end
                        // updated idx
                        if(!rep_idx_found) begin
                            if(!rep_h_entry.valid || rep_h_entry.tombstone) begin
                                insert_idx      <=      rep_hash_idx;
                                rep_idx_found   <=      1'b1;
                            end
                            else begin
                                rep_hash_idx    <=      rep_hash_idx + 1'b1;
                                rep_probe       <=      rep_probe    + 1'b1;
                            end
                        end
                    end
                    else begin
                        if(h_entry.valid && h_entry.orn == latched_rdata.orn && !h_entry.tombstone) begin
                            lookup_idx      <=      hash_idx;
                            idx_found       <=      1'b1;
                            rep_idx_found   <=      1'b1;
                        end
                        else begin
                            hash_idx        <=      hash_idx + 1'b1;
                            probe           <=      probe    + 1'b1;
                        end
                    end
                end
            end

            UPDATE_READ_TBL: begin
                latched_lookup_entry        <=      dout_a;
                latched_lookup_price_idx    <=      price_to_idx(dout_a.price);
            end

            UPDATE_READ_BOOK: begin
                rep_same_price              <=      (latched_event_price_idx == latched_lookup_price_idx);
                latched_bid_valid_rst       <=      (bid_active_chunks[latched_lookup_price_idx[BBO_W-1:6]] == (64'h1 << latched_lookup_price_idx[5:0]));
                latched_ask_valid_rst       <=      (ask_active_chunks[latched_lookup_price_idx[BBO_W-1:6]] == (64'h1 << latched_lookup_price_idx[5:0]));

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

                if(we_en) begin
                    if(target_side) begin
                        bid_active_chunks[chosen_row[BBO_W-1:6]][chosen_row[5:0]]   <=  target_val;

                        if(target_val) bid_enc_valid[chosen_row[BBO_W-1:6]] <=  1'b1;
                        else if(latched_bid_valid_rst) bid_enc_valid[chosen_row[BBO_W-1:6]] <=  1'b0;
                    end
                    else begin
                        ask_active_chunks[chosen_row[BBO_W-1:6]][chosen_row[5:0]]   <=  target_val;

                        if(target_val) ask_enc_valid[chosen_row[BBO_W-1:6]] <=  1'b1;
                        else if(latched_ask_valid_rst) ask_enc_valid[chosen_row[BBO_W-1:6]] <=  1'b0;
                    end
                end
            end

            REPLACE_ADD: begin

                if(we_en) begin
                    if(target_side) begin
                        bid_active_chunks[chosen_row[BBO_W-1:6]][chosen_row[5:0]]   <=  target_val;

                        if(target_val) bid_enc_valid[chosen_row[BBO_W-1:6]] <=  1'b1;
                        else if(latched_bid_valid_rst) bid_enc_valid[chosen_row[BBO_W-1:6]] <=  1'b0;
                    end
                    else begin
                        ask_active_chunks[chosen_row[BBO_W-1:6]][chosen_row[5:0]]   <=  target_val;

                        if(target_val) ask_enc_valid[chosen_row[BBO_W-1:6]] <=  1'b1;
                        else if(latched_ask_valid_rst) ask_enc_valid[chosen_row[BBO_W-1:6]] <=  1'b0;
                    end
                end
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
                bbo_data_o.bid_price  <= (bid_dout_a > 0) ? latched_base_price + PRICE_W'(current_best_bid) : '0;
                bbo_data_o.bid_shares <= (bid_dout_a > 0) ? bid_dout_a : '0;

                bbo_data_o.ask_price  <= (ask_dout_a > 0) ? latched_base_price + PRICE_W'(current_best_ask) : '0;
                bbo_data_o.ask_shares <= (ask_dout_a > 0) ? ask_dout_a : '0;
            end

            EMIT: begin
                bbo_valid_o <= 1'b1;
            end

            default: ;
        endcase
    end
end

assign ready_o = (current_state == IDLE) && rst_n;

endmodule
