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


parameter int ORN_W    = 64;
parameter int PRICE_W  = 32;
parameter int SHARES_W = 32;
parameter int STOCK_W  = 16;
parameter int MSG_W    = 8;
parameter int HASH_W   = 14;
parameter int FIFO_W   = 13;
parameter int BBO_W    = 12;

typedef struct packed {
    logic [MSG_W-1:0]       message_type;
    logic [STOCK_W-1:0]     stock_locate;
    logic [ORN_W-1:0]       orn;
    logic [ORN_W-1:0]       updated_orn;
    logic                   side;          // 1 = bid/buy, 0 = ask/sell
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
} o_data_t;

typedef struct packed {
    logic [PRICE_W-1:0]     bid_price;
    logic [SHARES_W-1:0]    bid_shares;
    logic [PRICE_W-1:0]     ask_price;
    logic [SHARES_W-1:0]    ask_shares;
} bbo_t;

module order_book #(
    parameter int ORN_W    = 64,
    parameter int PRICE_W  = 32,
    parameter int SHARES_W = 32,
    parameter int STOCK_W  = 16,
    parameter int MSG_W    = 8,
    parameter int HASH_W   = 14,
    parameter int FIFO_W   = 13,
    parameter int BBO_W    = 12,
    parameter int MAX_PROBES = 16
)(
    input  logic               clk,
    input  logic               rst_n,

    // input from symbol router / normalised-event harness
    input  o_data_t            rdata_i,
    input  logic               valid_i,
    input  logic [PRICE_W-1:0] base_price_i,

    // output to upstream block
    output logic               ready_o,

    // input from downstream block
    input  logic               ready_i,

    // BBO output
    output bbo_t               bbo_data_o,
    output logic               bbo_valid_o
);

localparam int HASH_DEPTH = 1 << HASH_W;
localparam int BBO_DEPTH  = 1 << BBO_W;

localparam logic [MSG_W-1:0] MSG_ADD_A    = 8'h41; // A
localparam logic [MSG_W-1:0] MSG_ADD_F    = 8'h46; // F
localparam logic [MSG_W-1:0] MSG_EXEC     = 8'h45; // E
localparam logic [MSG_W-1:0] MSG_EXEC_PX  = 8'h43; // C
localparam logic [MSG_W-1:0] MSG_DELETE   = 8'h44; // D
localparam logic [MSG_W-1:0] MSG_REPLACE  = 8'h55; // U
localparam logic [MSG_W-1:0] MSG_CANCEL   = 8'h58; // X

typedef struct packed {
    logic                   valid;
    logic [ORN_W-1:0]       orn;
    logic                   side;
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
} order_entry_t;

typedef enum logic [2:0] {
    CLEAR,
    IDLE,
    UPDATE,
    REPLACE_ADD,
    EMIT,
    WAIT_DOWNSTREAM
} state_t;

state_t current_state, next_state;

order_entry_t order_table [HASH_DEPTH-1:0];
logic [SHARES_W-1:0] bid_price_book [BBO_DEPTH-1:0];
logic [SHARES_W-1:0] ask_price_book [BBO_DEPTH-1:0];

o_data_t event_q;
logic [PRICE_W-1:0] base_price_q;
logic [HASH_W-1:0] clear_idx;

logic [HASH_W-1:0] lookup_idx;
logic lookup_found;
order_entry_t lookup_entry;

logic [HASH_W-1:0] insert_idx;
logic insert_found;
logic insert_existing_found;

logic [BBO_W-1:0] event_price_idx;
logic [BBO_W-1:0] lookup_price_idx;

logic [BBO_W-1:0] best_bid_idx_comb;
logic [BBO_W-1:0] best_ask_idx_comb;
logic bid_found_comb;
logic ask_found_comb;

function automatic logic is_add_msg(input logic [MSG_W-1:0] msg);
    return (msg == MSG_ADD_A) || (msg == MSG_ADD_F);
endfunction

function automatic logic is_reduce_msg(input logic [MSG_W-1:0] msg);
    return (msg == MSG_EXEC) || (msg == MSG_EXEC_PX) || (msg == MSG_CANCEL);
endfunction

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

function automatic logic [BBO_W-1:0] price_to_idx(input logic [PRICE_W-1:0] price);
    logic [PRICE_W-1:0] delta;
    begin
        delta = price - base_price_q;
        return delta[BBO_W-1:0];
    end
endfunction

assign lookup_entry = order_table[lookup_idx];
assign event_price_idx = price_to_idx(event_q.price);
assign lookup_price_idx = price_to_idx(lookup_entry.price);

// Next-state logic.
always_comb begin
    next_state = current_state;

    case (current_state)
        CLEAR: begin
            next_state = (clear_idx == HASH_W'(HASH_DEPTH - 1)) ? IDLE : CLEAR;
        end

        IDLE: begin
            next_state = valid_i ? UPDATE : IDLE;
        end

        UPDATE: begin
            next_state = (event_q.message_type == MSG_REPLACE) ? REPLACE_ADD : EMIT;
        end

        REPLACE_ADD: begin
            next_state = EMIT;
        end

        EMIT: begin
            next_state = ready_i ? IDLE : WAIT_DOWNSTREAM;
        end

        WAIT_DOWNSTREAM: begin
            next_state = ready_i ? IDLE : WAIT_DOWNSTREAM;
        end

        default: begin
            next_state = CLEAR;
        end
    endcase
end

// Bounded lookup for the current event's original order reference.
always_comb begin
    logic [HASH_W-1:0] base_idx;
    logic [HASH_W-1:0] probe_idx;

    lookup_idx = '0;
    lookup_found = 1'b0;
    base_idx = hash_orn(event_q.orn);

    for (int probe = 0; probe < MAX_PROBES; probe++) begin
        probe_idx = base_idx + HASH_W'(probe);
        if (!lookup_found && order_table[probe_idx].valid &&
            order_table[probe_idx].orn == event_q.orn) begin
            lookup_found = 1'b1;
            lookup_idx = probe_idx;
        end
    end
end

// Bounded insert search for ADD, or for the new reference during REPLACE_ADD.
always_comb begin
    logic [ORN_W-1:0] insert_orn;
    logic [HASH_W-1:0] base_idx;
    logic [HASH_W-1:0] probe_idx;

    insert_idx = '0;
    insert_found = 1'b0;
    insert_existing_found = 1'b0;
    insert_orn = (current_state == REPLACE_ADD) ? event_q.updated_orn : event_q.orn;
    base_idx = hash_orn(insert_orn);

    for (int probe = 0; probe < MAX_PROBES; probe++) begin
        probe_idx = base_idx + HASH_W'(probe);

        if (!insert_existing_found && order_table[probe_idx].valid &&
            order_table[probe_idx].orn == insert_orn) begin
            insert_existing_found = 1'b1;
            insert_idx = probe_idx;
        end

        if (!insert_found && !order_table[probe_idx].valid) begin
            insert_found = 1'b1;
            insert_idx = probe_idx;
        end
    end
end

// BBO recompute from separate bid/ask aggregate memories.
always_comb begin
    best_bid_idx_comb = '0;
    bid_found_comb = 1'b0;

    for (int i = 0; i < BBO_DEPTH; i++) begin
        if (bid_price_book[i] != '0) begin
            best_bid_idx_comb = BBO_W'(i);
            bid_found_comb = 1'b1;
        end
    end
end

always_comb begin
    best_ask_idx_comb = '0;
    ask_found_comb = 1'b0;

    for (int j = 0; j < BBO_DEPTH; j++) begin
        if (!ask_found_comb && ask_price_book[j] != '0) begin
            best_ask_idx_comb = BBO_W'(j);
            ask_found_comb = 1'b1;
        end
    end
end

// State and memory updates.
always_ff @(posedge clk) begin
    if (!rst_n) begin
        current_state <= CLEAR;
        event_q <= '0;
        base_price_q <= '0;
        clear_idx <= '0;
        bbo_data_o <= '0;
        bbo_valid_o <= 1'b0;
    end else begin
        current_state <= next_state;
        bbo_valid_o <= 1'b0;

        case (current_state)
            CLEAR: begin
                order_table[clear_idx] <= '0;

                if (clear_idx < HASH_W'(BBO_DEPTH)) begin
                    bid_price_book[clear_idx[BBO_W-1:0]] <= '0;
                    ask_price_book[clear_idx[BBO_W-1:0]] <= '0;
                end

                if (clear_idx != HASH_W'(HASH_DEPTH - 1)) begin
                    clear_idx <= clear_idx + HASH_W'(1);
                end
            end

            IDLE: begin
                if (valid_i) begin
                    event_q <= rdata_i;
                    base_price_q <= base_price_i;
                end
            end

            UPDATE: begin
                if (is_add_msg(event_q.message_type)) begin
                    if (insert_found && !insert_existing_found) begin
                        order_table[insert_idx].valid  <= 1'b1;
                        order_table[insert_idx].orn    <= event_q.orn;
                        order_table[insert_idx].side   <= event_q.side;
                        order_table[insert_idx].shares <= event_q.shares;
                        order_table[insert_idx].price  <= event_q.price;

                        if (event_q.side) begin
                            bid_price_book[event_price_idx] <= bid_price_book[event_price_idx] + event_q.shares;
                        end else begin
                            ask_price_book[event_price_idx] <= ask_price_book[event_price_idx] + event_q.shares;
                        end
                    end
                end else if (is_reduce_msg(event_q.message_type)) begin
                    if (lookup_found) begin
                        if (lookup_entry.side) begin
                            bid_price_book[lookup_price_idx] <= bid_price_book[lookup_price_idx] - event_q.shares;
                        end else begin
                            ask_price_book[lookup_price_idx] <= ask_price_book[lookup_price_idx] - event_q.shares;
                        end

                        if (event_q.shares >= lookup_entry.shares) begin
                            order_table[lookup_idx] <= '0;
                        end else begin
                            order_table[lookup_idx].shares <= lookup_entry.shares - event_q.shares;
                        end
                    end
                end else if (event_q.message_type == MSG_DELETE) begin
                    if (lookup_found) begin
                        if (lookup_entry.side) begin
                            bid_price_book[lookup_price_idx] <= bid_price_book[lookup_price_idx] - lookup_entry.shares;
                        end else begin
                            ask_price_book[lookup_price_idx] <= ask_price_book[lookup_price_idx] - lookup_entry.shares;
                        end

                        order_table[lookup_idx] <= '0;
                    end
                end else if (event_q.message_type == MSG_REPLACE) begin
                    if (lookup_found) begin
                        if (lookup_entry.side) begin
                            bid_price_book[lookup_price_idx] <= bid_price_book[lookup_price_idx] - lookup_entry.shares;
                        end else begin
                            ask_price_book[lookup_price_idx] <= ask_price_book[lookup_price_idx] - lookup_entry.shares;
                        end

                        // Keep the inherited side in event_q for the add-new half.
                        event_q.side <= lookup_entry.side;
                        order_table[lookup_idx] <= '0;
                    end
                end
            end

            REPLACE_ADD: begin
                if (insert_found && !insert_existing_found) begin
                    order_table[insert_idx].valid  <= 1'b1;
                    order_table[insert_idx].orn    <= event_q.updated_orn;
                    order_table[insert_idx].side   <= event_q.side;
                    order_table[insert_idx].shares <= event_q.shares;
                    order_table[insert_idx].price  <= event_q.price;

                    if (event_q.side) begin
                        bid_price_book[event_price_idx] <= bid_price_book[event_price_idx] + event_q.shares;
                    end else begin
                        ask_price_book[event_price_idx] <= ask_price_book[event_price_idx] + event_q.shares;
                    end
                end
            end

            EMIT: begin
                bbo_valid_o <= 1'b1;

                bbo_data_o.bid_price  <= bid_found_comb ? (base_price_q + PRICE_W'(best_bid_idx_comb)) : '0;
                bbo_data_o.bid_shares <= bid_found_comb ? bid_price_book[best_bid_idx_comb] : '0;
                bbo_data_o.ask_price  <= ask_found_comb ? (base_price_q + PRICE_W'(best_ask_idx_comb)) : '0;
                bbo_data_o.ask_shares <= ask_found_comb ? ask_price_book[best_ask_idx_comb] : '0;
            end

            default: begin
                // No memory update.
            end
        endcase
    end
end

assign ready_o = (current_state == IDLE) && rst_n;

endmodule
