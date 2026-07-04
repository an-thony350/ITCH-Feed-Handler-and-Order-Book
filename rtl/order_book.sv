`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 29.06.2026 15:15:19
// Design Name:
// Module Name: order_book
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


// To do list:
// - BBO  & Price Level Memory Block
// - test bench

/*
Notes about the states:

- RD_MEM - 1st bram cycle for reading hash id
- EVAL_MEM - 2nd bram cycle determining the ITCH type byte
- ALLOC - used for the specific case where we need to use fifo to assign a hash id in an Add ITCH type
- EDR - For 'E' 'D' 'C' and 'X' ITCH types (stands for execute, delete, remove)
- REP - For 'U' ITCH type (replace)

- Fifo starts at address 8912 of the book because the hash ids are all 13 bit integers, hence extra space is
used for the "overflow" when another node is needed in the linked list (also kept separate which is great)

- (Linked List) structure where read_ptr points to the nodes of value orn
- all nodes have a next_ptr value as a link to another node which can create a list of nodes in this case


- v1 - order book structure
- v2 - valid/ready handshake + rep state completion
*/

import hdl_header::*;

module order_book #(
    parameter int ORN_W    = 64,
    parameter int PRICE_W  = 32,
    parameter int SHARES_W = 32,
    parameter int STOCK_W  = 16,
    parameter int MSG_W    = 8,
    parameter int HASH_W   = 12,
    parameter int FIFO_W   = 11,
    parameter int BBO_W    = 12,
    parameter int MAX_PROBES = 16
)(
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

// local parameters for tables and ASCII message types

localparam int HASH_DEPTH = 1 << HASH_W;
localparam int BBO_DEPTH  = 1 << BBO_W;
localparam int CHUNK_LEN  = BBO_DEPTH >> 6; // BBO_DEPTH dvided by 64

localparam logic [MSG_W-1:0] MSG_ADD_A    = 8'h41; // A
localparam logic [MSG_W-1:0] MSG_ADD_F    = 8'h46; // F
localparam logic [MSG_W-1:0] MSG_EXEC     = 8'h45; // E
localparam logic [MSG_W-1:0] MSG_EXEC_PX  = 8'h43; // C
localparam logic [MSG_W-1:0] MSG_DELETE   = 8'h44; // D
localparam logic [MSG_W-1:0] MSG_REPLACE  = 8'h55; // U
localparam logic [MSG_W-1:0] MSG_CANCEL   = 8'h58; // X

// Struct for data inputted to order book

typedef struct packed {
    logic                   valid;
    logic [ORN_W-1:0]       orn;
    logic                   side;
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
    logic                   tombstone;
} order_entry_t;

// state machine for order book data

typedef enum {
    CLEAR,
    IDLE,
    IDX_REQ,
    IDX_SEARCH,
    UPDATE,
    REPLACE_ADD,
    BBO_CHUNK_PRIORITY,
    BBO_BIT_PRIORITY,
    EMIT
} state_t;

state_t current_state, next_state;

// internal registers

order_entry_t order_table [HASH_DEPTH-1:0];
logic [SHARES_W-1:0] bid_price_book [BBO_DEPTH-1:0];
logic [SHARES_W-1:0] ask_price_book [BBO_DEPTH-1:0];

o_data_t latched_rdata;
logic [PRICE_W-1:0] latched_base_price;
logic [HASH_W-1:0] clear_idx;

logic [HASH_W-1:0] lookup_idx;
logic lookup_found;
order_entry_t lookup_entry;
logic                       idx_found;
logic                       rep_idx_found;
int                         probe;
int                         rep_probe;
logic [HASH_W-1:0]          hash_idx;
logic [HASH_W-1:0]          rep_hash_idx;
logic                       h_valid;
logic                       rep_h_valid;
logic [ORN_W-1:0]           h_orn;
logic                       h_tombstone;
logic                       rep_h_tombstone;

logic [HASH_W-1:0] insert_idx;
logic insert_found;
logic insert_existing_found;

logic [BBO_W-1:0] event_price_idx;
logic [BBO_W-1:0] lookup_price_idx;

logic [BBO_W-1:0] best_bid_idx;
logic [BBO_W-1:0] best_ask_idx;
logic bid_found_comb;
logic ask_found_comb;
logic bid_chunk_found;
logic ask_chunk_found;
logic bid_bit_found;
logic ask_bit_found;
logic [63:0]    bid_enc_valid;
logic [63:0]    ask_enc_valid;
logic [5:0]    bid_multiple;
logic [5:0]    ask_multiple;
logic [BBO_DEPTH-1:0] bid_active_bits;
logic [BBO_DEPTH-1:0] ask_active_bits;
logic [63:0]    bid_chunk_bits;
logic [63:0]    ask_chunk_bits;
logic [63:0]    active_bid_lookup_chunk;
logic [63:0]    active_ask_lookup_chunk;

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

// Price logic (for price book) - Only works if delta < $40.96 - look into dropping the signal if it has this issue

function automatic logic [BBO_W-1:0] price_to_idx(input logic [PRICE_W-1:0] price);
    logic [PRICE_W-1:0] delta;
    begin
        delta = price - latched_base_price;
        return delta[BBO_W-1:0];
    end
endfunction

assign lookup_entry = order_table[lookup_idx];
assign event_price_idx = price_to_idx(latched_rdata.price);
assign lookup_price_idx = price_to_idx(lookup_entry.price);
assign bid_chunk_bits   =   bid_active_bits[ (bid_multiple * 64) +: 64];
assign ask_chunk_bits   =   ask_active_bits[ (ask_multiple * 64) +: 64];
assign active_bid_lookup_chunk  =   bid_active_bits[{lookup_price_idx[11:6], 6'd0} +: 64];
assign active_ask_lookup_chunk  =   ask_active_bits[{lookup_price_idx[11:6], 6'd0} +: 64];

// State machine logic - Next state determination

always_comb begin
    next_state = current_state;

    case (current_state)
        CLEAR: begin
            next_state = (int'(clear_idx) == (HASH_DEPTH - 1)) ? IDLE : CLEAR;
        end

        IDLE: begin
            next_state = valid_i ? IDX_REQ : IDLE;
        end

        IDX_REQ: begin
            next_state = IDX_SEARCH;
        end

        IDX_SEARCH: begin
            if(latched_rdata.message_type == MSG_REPLACE) begin
                if( (idx_found || (h_valid && h_orn == latched_rdata.orn && !h_tombstone)) && ( rep_idx_found || (!rep_h_valid || rep_h_tombstone))) begin
                    next_state  =   UPDATE;
                end
                else begin
                    next_state  =   IDX_REQ;
                end
            end
            else if(is_add_msg(latched_rdata.message_type)) begin
                if(!h_valid || h_tombstone) begin
                    next_state  =   UPDATE;
                end
                else begin
                    next_state  =   IDX_REQ;
                end
            end
            else begin
                if(h_valid && h_orn == latched_rdata.orn && !h_tombstone) begin
                    next_state  =   UPDATE;
                end
                else if(!h_valid) begin
                    next_state  =   IDLE; // not really necessary
                end
                else begin
                    next_state  =   IDX_REQ;
                end
            end
        end

        UPDATE: begin
            next_state = (latched_rdata.message_type == MSG_REPLACE) ? REPLACE_ADD : BBO_CHUNK_PRIORITY;
        end

        REPLACE_ADD: begin
            next_state = BBO_CHUNK_PRIORITY;
        end

        BBO_CHUNK_PRIORITY: begin
            next_state = (bid_chunk_found && ask_chunk_found) ? BBO_BIT_PRIORITY : BBO_CHUNK_PRIORITY;
        end

        BBO_BIT_PRIORITY: begin
            next_state = (bid_bit_found && ask_bit_found) ? EMIT : BBO_BIT_PRIORITY;
        end

        EMIT: begin
            next_state = IDLE;
        end

        default: begin
            next_state = CLEAR;
        end
    endcase
end

// Sequential Logic for both order book and price book - Maybe split this into two clocks?
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
        bid_chunk_found     <= 1'b0;
        bid_bit_found       <= 1'b0;
        ask_chunk_found     <= 1'b0;
        ask_bit_found       <= 1'b0;
        bid_found_comb      <= 1'b0;
        ask_found_comb      <= 1'b0;
    end
    else begin
        current_state <= next_state;
        bbo_valid_o <= 1'b0;

        case (current_state)
            CLEAR: begin
                order_table[clear_idx] <= '0;

                if (int'(clear_idx) < BBO_DEPTH) begin
                    bid_price_book[clear_idx[BBO_W-1:0]] <= '0;
                    ask_price_book[clear_idx[BBO_W-1:0]] <= '0;
                    bid_active_bits[clear_idx[BBO_W-1:0]] <= '0;
                    ask_active_bits[clear_idx[BBO_W-1:0]] <= '0;
                end

                if(int'(clear_idx) == 0) begin
                    bid_enc_valid <= '0;
                    ask_enc_valid <= '0;
                end

                if (int'(clear_idx) != HASH_DEPTH - 1) begin
                    clear_idx <= clear_idx + HASH_W'(1);
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
                    bid_chunk_found       <= 1'b0;
                    bid_bit_found         <= 1'b0;
                    ask_chunk_found       <= 1'b0;
                    ask_bit_found         <= 1'b0;
                    bid_found_comb        <= 1'b0;
                    ask_found_comb        <= 1'b0;
                end
            end

            IDX_REQ: begin
               // $display("TIME=%t, STATE=%s, READY=%b, IDX=%d", $time, current_state.name(), ready_o, clear_idx);
                h_orn           <=  order_table[hash_idx].orn;
                h_valid         <=  order_table[hash_idx].valid;
                rep_h_valid     <=  order_table[rep_hash_idx].valid;
                h_tombstone     <=  order_table[hash_idx].tombstone;
                rep_h_tombstone <=  order_table[rep_hash_idx].tombstone;
            end

            IDX_SEARCH: begin
               // $display("TIME=%t, STATE=%s, READY=%b, IDX=%d", $time, current_state.name(), ready_o, clear_idx);
                if(probe < MAX_PROBES || rep_probe < MAX_PROBES) begin
                    if(is_add_msg(latched_rdata.message_type)) begin
                        if(!h_valid || h_tombstone) begin
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
                            if(h_valid && h_orn == latched_rdata.orn && !h_tombstone) begin
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
                            if(!rep_h_valid || rep_h_tombstone) begin
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
                        if(h_valid && h_orn == latched_rdata.orn && !h_tombstone) begin
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

            UPDATE: begin
               // $display("TIME=%t, STATE=%s, READY=%b, IDX=%d", $time, current_state.name(), ready_o, clear_idx);
                if (is_add_msg(latched_rdata.message_type)) begin
                    order_table[insert_idx].valid       <=  1'b1;
                    order_table[insert_idx].orn         <=  latched_rdata.orn;
                    order_table[insert_idx].side        <=  latched_rdata.side;
                    order_table[insert_idx].shares      <=  latched_rdata.shares;
                    order_table[insert_idx].price       <=  latched_rdata.price;
                    order_table[insert_idx].tombstone   <=  1'b0;

                    if (latched_rdata.side) begin
                        bid_price_book[event_price_idx]         <=  bid_price_book[event_price_idx] + latched_rdata.shares;
                        bid_enc_valid[event_price_idx[11:6]]    <=  1'b1;
                        bid_active_bits[event_price_idx]        <=  1'b1;
                    end else begin
                        ask_price_book[event_price_idx]         <=  ask_price_book[event_price_idx] + latched_rdata.shares;
                        ask_enc_valid[event_price_idx[11:6]]    <=  1'b1;
                        ask_active_bits[event_price_idx]        <=  1'b1;
                    end
                end
                else if (is_reduce_msg(latched_rdata.message_type)) begin
                    if (lookup_entry.side) begin
                        bid_price_book[lookup_price_idx] <= bid_price_book[lookup_price_idx] - latched_rdata.shares;
                        if(bid_price_book[lookup_price_idx] == latched_rdata.shares) begin
                            bid_active_bits[lookup_price_idx]       <=  1'b0;
                        end
                    end
                    else begin
                        ask_price_book[lookup_price_idx] <= ask_price_book[lookup_price_idx] - latched_rdata.shares;
                        if(ask_price_book[lookup_price_idx] == latched_rdata.shares) begin
                            ask_active_bits[lookup_price_idx]       <=  1'b0;
                        end
                    end

                    if (latched_rdata.shares >= lookup_entry.shares) begin
                        order_table[lookup_idx].tombstone   <=  1'b1;
                    end
                    else begin
                        order_table[lookup_idx].shares <= lookup_entry.shares - latched_rdata.shares;
                    end
                end
                else if(latched_rdata.message_type == MSG_DELETE) begin
                    if (lookup_entry.side) begin
                        bid_price_book[lookup_price_idx] <= bid_price_book[lookup_price_idx] - lookup_entry.shares;
                        if(bid_price_book[lookup_price_idx] == lookup_entry.shares) begin
                            bid_active_bits[lookup_price_idx]       <=  1'b0;
                            if(active_bid_lookup_chunk == (64'h1 << lookup_price_idx[5:0])) begin
                                bid_enc_valid[lookup_price_idx[11:6]]   <=  1'b0;
                            end
                        end
                    end
                    else begin
                        ask_price_book[lookup_price_idx] <= ask_price_book[lookup_price_idx] - lookup_entry.shares;
                        if(ask_price_book[lookup_price_idx] == lookup_entry.shares) begin
                            ask_active_bits[lookup_price_idx]       <=  1'b0;
                            if(active_ask_lookup_chunk == (64'h1 << lookup_price_idx[5:0])) begin
                                ask_enc_valid[lookup_price_idx[11:6]]   <=  1'b0;
                            end
                        end
                    end

                    order_table[lookup_idx].tombstone   <=  1'b1;
                end
                else if (latched_rdata.message_type == MSG_REPLACE) begin
                  //  $display("DEBUG REPLACE: old_ref=%d, new_ref=%d, price=%d, shares=%d",
             // lookup_idx, insert_idx, latched_rdata.price, latched_rdata.shares);
                    if (lookup_entry.side) begin
                        bid_price_book[lookup_price_idx] <= bid_price_book[lookup_price_idx] - lookup_entry.shares;
                        if(bid_price_book[lookup_price_idx] == lookup_entry.shares) begin
                            bid_active_bits[lookup_price_idx]       <=  1'b0;
                            if(active_bid_lookup_chunk == (64'h1 << lookup_price_idx[5:0])) begin
                                bid_enc_valid[lookup_price_idx[11:6]]   <=  1'b0;
                            end
                        end
                    end
                    else begin
                        ask_price_book[lookup_price_idx] <= ask_price_book[lookup_price_idx] - lookup_entry.shares;
                        if(ask_price_book[lookup_price_idx] == lookup_entry.shares) begin
                            ask_active_bits[lookup_price_idx]       <=  1'b0;
                            if(active_bid_lookup_chunk == (64'h1 << lookup_price_idx[5:0])) begin
                                bid_enc_valid[lookup_price_idx[11:6]]   <=  1'b0;
                            end
                        end
                    end

                    // Keep the inherited side in latched_rdata for the add-new half.
                    latched_rdata.side <= lookup_entry.side;
                    order_table[lookup_idx].tombstone   <=  1'b1;
                end
            end

            REPLACE_ADD: begin
              //  $display("TIME=%t, STATE=%s, READY=%b, IDX=%d", $time, current_state.name(), ready_o, clear_idx);
              //  $display("DEBUG REPLACE: old_ref=%d, new_ref=%d, price=%d, shares=%d, event_price_idx=%d",
            //  hash_idx, insert_idx, latched_rdata.price, latched_rdata.shares, event_price_idx);
                order_table[insert_idx].valid       <=  1'b1;
                order_table[insert_idx].orn         <=  latched_rdata.updated_orn;
                order_table[insert_idx].side        <=  latched_rdata.side;
                order_table[insert_idx].shares      <=  latched_rdata.shares;
                order_table[insert_idx].price       <=  latched_rdata.price;
                order_table[insert_idx].tombstone   <=  1'b0;

                if (latched_rdata.side) begin
                    bid_price_book[event_price_idx] <= bid_price_book[event_price_idx] + latched_rdata.shares;
                    bid_enc_valid[event_price_idx[11:6]]    <=  1'b1;
                    bid_active_bits[event_price_idx]        <=  1'b1;
                end
                else begin
                    ask_price_book[event_price_idx] <= ask_price_book[event_price_idx] + latched_rdata.shares;
                    ask_enc_valid[event_price_idx[11:6]]    <=  1'b1;
                    ask_active_bits[event_price_idx]        <=  1'b1;
                end
            end

            BBO_CHUNK_PRIORITY: begin

             //   $display("TIME=%t, STATE=%s, READY=%b, IDX=%d", $time, current_state.name(), ready_o, clear_idx);
                for(int i = 0; i < CHUNK_LEN; i++) begin
                    if(bid_enc_valid[i] != 0) begin
                        bid_multiple   <=  6'(i);
                    end
                end
                for(int j = 63; j >= 0; j--) begin
                    if(ask_enc_valid[j] != 0) begin
                        ask_multiple   <=  6'(j);
                    end
                end
                bid_chunk_found     <=  1'b1;
                ask_chunk_found     <=  1'b1;
            end

            BBO_BIT_PRIORITY: begin
              //  $display("TIME=%t, STATE=%s, READY=%b, IDX=%d", $time, current_state.name(), ready_o, clear_idx);
                for(int i = 0; i < CHUNK_LEN; i++) begin
                    if(bid_chunk_bits[i] != 0) begin
                        bid_found_comb      <=  1'b1;
                        best_bid_idx        <=  BBO_W'(i);
                //        $display("DEBUG BBO: chunk=%d, mask=%b, active_bit_1010=%b",
       //   i, bid_enc_valid[i], bid_active_bits[1010]);
                    end
                end
                for(int j = 63; j >= 0; j--) begin
                    if(ask_chunk_bits[j] != 0) begin
                        ask_found_comb      <=  1'b1;
                        best_ask_idx        <=  BBO_W'(j);
                    end
                end
                bid_bit_found       <=  1'b1;
                ask_bit_found       <=  1'b1;
            end

            EMIT: begin
            //    $display("TIME=%t, STATE=%s, READY=%b, IDX=%d", $time, current_state.name(), ready_o, clear_idx);
                bbo_valid_o <= 1'b1;

                bbo_data_o.bid_price  <= bid_found_comb ? (latched_base_price + PRICE_W'((bid_multiple * 64) + best_bid_idx)) : '0;
                bbo_data_o.bid_shares <= bid_found_comb ? bid_price_book[(bid_multiple * 64) + best_bid_idx] : '0;
                bbo_data_o.ask_price  <= ask_found_comb ? (latched_base_price + PRICE_W'((ask_multiple * 64) + best_ask_idx)) : '0;
                bbo_data_o.ask_shares <= ask_found_comb ? ask_price_book[(ask_multiple * 64) + best_ask_idx] : '0;
            end

            default: begin
                // No memory update.
            end
        endcase
    end
end

assign ready_o = (current_state == IDLE) && rst_n;

endmodule
