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


parameter int  ORN_W    = 64;
parameter int  PRICE_W  = 32;
parameter int  SHARES_W = 32;
parameter int  MSG_W    = 8;
parameter int  HASH_W   = 12;
parameter int  FIFO_W   = 11;
parameter int  BBO_W    = 12;

// Struct for most data we will output - this isnt a complete list yet
// note that the struct is above the module declaration for the input port rdata

typedef struct packed {
    logic [MSG_W-1:0]       message_type;
    logic [ORN_W-1:0]       orn;
    logic [ORN_W-1:0]       updated_orn;
    logic                   side;
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
} o_data_t;

// Struct for BBO

typedef struct packed {
    logic [PRICE_W-1:0]     bid_price;
    logic [SHARES_W-1:0]    bid_shares;
    logic [PRICE_W-1:0]     ask_price;
    logic [SHARES_W-1:0]    ask_shares;
} bbo_t;

module order_book#(
    ORN_W   =   64,
    PRICE_W =   32,
    SHARES_W=   32,
    MSG_W   =   8,
    HASH_W  =   14,
    FIFO_W  =   13,
    BBO_W   =   12
)(
    input   logic               clk,
    input   logic               rst_n,

    // inputs from sybmol router
    input   o_data_t            rdata_i,
    input   logic               valid_i,
    input   [PRICE_W-1:0]       base_price_i,

    // outputs to symbol router
    output  logic               ready_o,

    // input from next block
    input   logic               ready_i,

    // outputs to ??
    output  bbo_t               bbo_data_o,
    output  logic               bbo_valid_o
);

// struct for relevant data stored in hash map

typedef struct packed {
    logic [ORN_W-1:0]    orn;
    logic                side;
    logic [SHARES_W-1:0] shares;
    logic [PRICE_W-1:0]  price;
    logic                valid;
    logic [HASH_W-1:0]   next_ptr;
} hash_data_t;

hash_data_t hash_data;
o_data_t event_q;

logic [ORN_W-1:0] target_orn;
logic [PRICE_W-1:0] price_delta_raw;

logic update_done;
logic update_done_d1;
logic update_done_d2;

// local parameters

localparam int HASH_DEPTH = 1 << HASH_W;
localparam int FIFO_DEPTH = 1 << FIFO_W;
localparam int BBO_DEPTH  = 1 << BBO_W;

// internal hash map registers

logic       [HASH_W-1:0]    hash_idx;
hash_data_t book            [HASH_DEPTH-1:0];
logic                       is_clear;
logic       [HASH_W-1:0]    clear_idx;
logic       [HASH_W-1:0]    read_ptr;
hash_data_t                 bram_dout;
logic       [HASH_W-1:0]    rep_hash_idx;
logic                       rep_state; // 1'b0 = deleting old order, 1'b1 = adding new order
logic                       latched_side;
logic       [HASH_W-1:0]    target_idx;
logic                       target_side;
logic       [HASH_W-1:0]    input_hash_idx;
logic       [HASH_W-1:0]    input_rep_hash_idx;
logic       [HASH_W-1:0]    input_target_idx;

// FIFO registers
logic       [HASH_W-1:0]    fifo    [FIFO_DEPTH-1:0];
logic       [FIFO_W-1:0]    fifo_cons;
logic       [FIFO_W-1:0]    fifo_prod;
logic       [HASH_W-1:0]    fifo_addr;

// internal price book registers

logic       [SHARES_W-1:0]  price_book  [BBO_DEPTH-1:0];
logic       [BBO_DEPTH-1:0] active_bid;
logic       [BBO_DEPTH-1:0] active_ask;
logic       [BBO_W-1:0]     price_idx;



// state machine for order book states

typedef enum { CLEAR, IDLE, RD_MEM, EVAL_MEM, ALLOC, ADD, EDR, REP, DONE } state_t;

state_t current_state, next_state, ret_state;

// index assignment

assign input_hash_idx = rdata_i.orn[11:0] ^ rdata_i.orn[23:12] ^ rdata_i.orn[35:24] ^
                        rdata_i.orn[47:36] ^ rdata_i.orn[59:48] ^ {8'b0, rdata_i.orn[63:60]};

assign input_rep_hash_idx = rdata_i.updated_orn[11:0]  ^ rdata_i.updated_orn[23:12] ^
                            rdata_i.updated_orn[35:24] ^ rdata_i.updated_orn[47:36] ^
                            rdata_i.updated_orn[59:48] ^ {8'b0, rdata_i.updated_orn[63:60]};

assign input_target_idx = (rdata_i.message_type == 8'h55 && rep_state)
                        ? input_rep_hash_idx
                        : input_hash_idx;

assign hash_idx = event_q.orn[11:0] ^ event_q.orn[23:12] ^ event_q.orn[35:24] ^
                  event_q.orn[47:36] ^ event_q.orn[59:48] ^ {8'b0, event_q.orn[63:60]};

assign rep_hash_idx = event_q.updated_orn[11:0]  ^ event_q.updated_orn[23:12] ^
                      event_q.updated_orn[35:24] ^ event_q.updated_orn[47:36] ^
                      event_q.updated_orn[59:48] ^ {8'b0, event_q.updated_orn[63:60]};

assign target_orn = (event_q.message_type == 8'h55 && rep_state)
                  ? event_q.updated_orn
                  : event_q.orn;

assign target_idx = (event_q.message_type == 8'h55 && rep_state)
                  ? rep_hash_idx
                  : hash_idx;

assign price_delta_raw = (current_state == ADD)
                       ? (event_q.price - base_price)
                       : (bram_dout.price - base_price);

assign price_idx = price_delta_raw[BBO_W-1:0];

// data packing assignment for book

assign hash_data.orn        = target_orn;
assign hash_data.side       = event_q.side;
assign hash_data.shares     = event_q.shares;
assign hash_data.price      = event_q.price;
assign hash_data.next_ptr   = '0; // this might be wrong
assign target_side          = (event_q.message_type == 8'h55) ? latched_side : event_q.side;

// case logic for next state
// 8'h41 = "A", 8'h43 = "C", 8'h44 = "D", 8'h45 = "E", 8'h55 = "U", 8'h58 = "X" - Maybe add local integers?

always_comb begin
    case(current_state)
    CLEAR:   next_state = is_clear   ?   IDLE    :   CLEAR;
    IDLE:    next_state = valid_i    ?   RD_MEM  :   IDLE;
    RD_MEM:  next_state =                EVAL_MEM;
    EVAL_MEM: begin
        if(!bram_dout.valid) begin
            next_state = ((event_q.message_type == 8'h41) ||
                         (event_q.message_type == 8'h55 && rep_state))
                       ? ADD
                       : IDLE;
        end
        else if(bram_dout.valid && bram_dout.orn == target_orn) begin
            if(event_q.message_type == 8'h55 && !rep_state) begin
                next_state = REP;
            end
            else if((event_q.message_type == 8'h41) ||
                    (event_q.message_type == 8'h55 && rep_state)) begin
                next_state = ALLOC;
            end
            else begin
                next_state = EDR;
            end
        end
        else begin
                if((event_q.message_type == 8'h41) || (event_q.message_type == 8'h55 && rep_state)) begin
                    if(bram_dout.next_ptr == '0) next_state = ALLOC;
                    else next_state = RD_MEM;
                end
                else begin
                    next_state = (bram_dout.next_ptr != '0) ? RD_MEM : IDLE;
                end
        end
    end
    ALLOC:   next_state =                EVAL_MEM;
    ADD:     next_state =                DONE;
    EDR:     next_state =                DONE;
    REP:     next_state =                RD_MEM;
    DONE:    next_state = ready_i    ?   IDLE           :   DONE;
    default: next_state = current_state;
    endcase
end


// Sequential logic for Order Book - synchronous reset

always_ff @(posedge clk) begin
    if(!rst_n) begin
        current_state   <=  CLEAR;
        is_clear        <=  1'b0;
        clear_idx       <=  '0;
        read_ptr        <=  '0;
        fifo_cons       <=  '0;
        fifo_prod       <=  '0;
        fifo_addr       <=  '0;
        active_bid      <=  '0;
        active_ask      <=  '0;
        bram_dout       <=  '0;
        rep_state       <=  1'b0;
        latched_side    <=  1'b0;
        ret_state       <=  IDLE;
        event_q         <=  '0;
    end
    else begin
        current_state   <=  next_state;
        if(current_state == IDLE && valid_i) begin
            event_q     <=  rdata_i;
            read_ptr    <=  input_target_idx;
        end
        bram_dout       <=  book[read_ptr];
        fifo_addr       <=  fifo[fifo_cons];

        if(current_state == CLEAR) begin
            book[clear_idx] <= '0;

            if(clear_idx < HASH_W'(BBO_DEPTH)) begin
                price_book[clear_idx[BBO_W-1:0]] <= '0;
            end

            if(clear_idx >= HASH_W'(FIFO_DEPTH)) begin
                fifo[clear_idx[FIFO_W-1:0]] <= clear_idx;
            end

            if(clear_idx == HASH_W'(HASH_DEPTH - 1)) begin
                is_clear <= 1'b1;
            end
            else begin
                clear_idx <= clear_idx + HASH_W'(1);
            end
        end
        else if(current_state == RD_MEM) begin
            if (ret_state == EVAL_MEM) read_ptr <= bram_dout.next_ptr;
            else read_ptr   <=  target_idx;
        end
        else if(current_state == ALLOC) begin
            book[read_ptr].next_ptr <=  fifo_addr;
            read_ptr                <=  fifo_addr;
            fifo_cons               <=  fifo_cons + FIFO_W'(1);
            ret_state               <=  IDLE;
        end
        else if(current_state == EVAL_MEM) begin
            if(bram_dout.valid && bram_dout.orn != hash_data.orn) ret_state <= EVAL_MEM;
            else                                                  ret_state <= IDLE;
        end
        else if(current_state == ADD) begin
            book[read_ptr].orn      <= target_orn;
            book[read_ptr].side     <= target_side;
            book[read_ptr].shares   <= event_q.shares;
            book[read_ptr].price    <= event_q.price;
            book[read_ptr].valid    <= 1'b1;

            rep_state               <= 1'b0;

            price_book[price_idx]   <= price_book[price_idx] + event_q.shares;

            if(target_side == 1'b1) active_bid[price_idx] <= 1'b1;
            else                    active_ask[price_idx] <= 1'b1;
        end
        else if(current_state == EDR) begin
            if(event_q.message_type == 8'h43 || event_q.message_type == 8'h45 ||
               event_q.message_type == 8'h58) begin
                book[read_ptr].shares       <= book[read_ptr].shares - event_q.shares;
                price_book[price_idx]       <= price_book[price_idx] - event_q.shares;
                if((price_book[price_idx] - event_q.shares) == 0) begin
                    if(bram_dout.side == 1'b1) active_bid[price_idx] <= 1'b0;
                    else                       active_ask[price_idx] <= 1'b0;
                end
            end
            else if(event_q.message_type == 8'h44) begin
                book[read_ptr]          <=  '0;
                book[read_ptr].valid    <=  1'b0;
                fifo[fifo_prod]         <=  read_ptr;
                fifo_prod               <=  fifo_prod + FIFO_W'(1);
                price_book[price_idx]   <=  price_book[price_idx] - bram_dout.shares;
                if((price_book[price_idx] - bram_dout.shares) == 0) begin
                    if(bram_dout.side == 1'b1) active_bid[price_idx] <= 1'b0;
                    else                       active_ask[price_idx] <= 1'b0;
                end
            end
        end
        else if(current_state == REP) begin // effectively a delete state (with some latched data)
            book[read_ptr]          <=  '0;
            book[read_ptr].valid    <=  1'b0;
            fifo[fifo_prod]         <=  read_ptr;
            fifo_prod               <=  fifo_prod + FIFO_W'(1);
            latched_side            <=  bram_dout.side;
            rep_state               <=  1'b1;
            ret_state               <=  IDLE;
            price_book[price_idx]   <=  price_book[price_idx] - bram_dout.shares;
            if((price_book[price_idx] - bram_dout.shares) == 0) begin
                if(bram_dout.side == 1'b1) active_bid[price_idx] <= 1'b0;
                else                       active_ask[price_idx] <= 1'b0;
            end
        end
    end
end

// Combinational logic for BBO calculation

logic [BBO_W-1:0] best_bid_idx_comb, best_ask_idx_comb;
logic bid_found_comb, ask_found_comb;

always_comb begin
    best_bid_idx_comb = '0;
    bid_found_comb = 1'b0;
    for(int i = BBO_DEPTH - 1; i >= 0; i--) begin
        if(active_bid[i]) begin
            best_bid_idx_comb = i[BBO_W-1:0];
            bid_found_comb = 1'b1;
            break;
        end
    end
end

always_comb begin
    best_ask_idx_comb = '0;
    ask_found_comb = 1'b0;
    for(int j = 0; j < BBO_DEPTH; j++) begin
        if(active_ask[j]) begin
            best_ask_idx_comb = j[BBO_W-1:0];
            ask_found_comb = 1'b1;
            break;
        end
    end
end

// Pipeline registers
logic [BBO_W-1:0] reg_bid_idx, reg_ask_idx;
logic reg_bid_valid, reg_ask_valid;
logic [SHARES_W-1:0] reg_bid_shares, reg_ask_shares;
logic               latch_bbo_valid;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        reg_bid_idx     <= '0;
        reg_ask_idx     <= '0;
        reg_bid_valid   <= 1'b0;
        reg_ask_valid   <= 1'b0;
        reg_bid_shares  <= '0;
        reg_ask_shares  <= '0;
    end else begin
        reg_bid_idx     <= best_bid_idx_comb;
        reg_ask_idx     <= best_ask_idx_comb;
        reg_bid_valid   <= bid_found_comb;
        reg_ask_valid   <= ask_found_comb;

        reg_bid_shares  <= price_book[best_bid_idx_comb];
        reg_ask_shares  <= price_book[best_ask_idx_comb];
    end
end

assign update_done = (current_state == ADD) || (current_state == EDR);

always_ff @(posedge clk) begin
    if(!rst_n) begin
        update_done_d1  <= 1'b0;
        update_done_d2  <= 1'b0;
        latch_bbo_valid <= 1'b0;
        bbo_data_o      <= '0;
    end
    else begin
        update_done_d1 <= update_done;
        update_done_d2 <= update_done_d1;

        bbo_data_o.bid_price  <= reg_bid_valid ? (base_price + PRICE_W'(reg_bid_idx)) : '0;
        bbo_data_o.bid_shares <= reg_bid_valid ? reg_bid_shares : '0;

        bbo_data_o.ask_price  <= reg_ask_valid ? (base_price + PRICE_W'(reg_ask_idx)) : '0;
        bbo_data_o.ask_shares <= reg_ask_valid ? reg_ask_shares : '0;

        latch_bbo_valid <= update_done_d2;
    end
end


assign ready_o  =   (current_state == IDLE) && rst_n;
assign bbo_valid_o = latch_bbo_valid && rst_n;

endmodule
