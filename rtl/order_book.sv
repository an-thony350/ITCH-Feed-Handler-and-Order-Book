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
parameter int  STOCK_W  = 16;
parameter int  MSG_W    = 8;
parameter int  HASH_W   = 14;
parameter int  FIFO_W   = 13;

// Struct for most data we will output - this isnt a complete list yet
// note that the struct is above the module declaration for the input port rdata

typedef struct packed {
    logic [MSG_W-1:0]       message_type;
    logic [STOCK_W-1:0]     stock_locate;
    logic [ORN_W-1:0]       orn;
    logic [ORN_W-1:0]       updated_orn;
    logic                   side;
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
} data_t;

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
    STOCK_W =   16,
    MSG_W   =   8,
    HASH_W  =   14,
    FIFO_W  =   13
)(
    input   logic               clk,
    input   logic               rst_n,

    // inputs from data handler
    input   data_t              rdata_i,
    input   logic               valid_i,

    // outputs to data handler
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

// local parameters

localparam int MAP_W = 1 << HASH_W;
localparam int FIFO_DEPTH = 1 << FIFO_W;

// internal hash map registers

logic       [HASH_W-1:0]    hash_idx;
hash_data_t book            [MAP_W-1:0];
logic                       is_clear;
logic       [HASH_W-1:0]    clear_idx;
logic       [HASH_W-1:0]    read_ptr;
hash_data_t                 bram_dout;
logic       [HASH_W-1:0]    rep_hash_idx;
logic                       rep_state; // 1'b0 = deleting old order, 1'b1 = adding new order
logic                       latched_side;
logic       [HASH_W-1:0]    target_idx;

// FIFO registers
logic       [HASH_W-1:0]    fifo    [FIFO_DEPTH-1:0];
logic       [FIFO_W-1:0]    fifo_cons;
logic       [FIFO_W-1:0]    fifo_prod;
logic       [HASH_W-1:0]    fifo_addr;




// state machine for order book states

typedef enum { CLEAR, IDLE, RD_MEM, EVAL_MEM, ALLOC, ADD, EDR, REP, DONE } state_t;

state_t current_state, next_state, ret_state;

// index assignment - based off orn

assign hash_idx = rdata_i.orn[13:0] ^ rdata_i.orn[27:14] ^ rdata_i.orn[41:28] ^
                  rdata_i.orn[55:42] ^ {6'b0, rdata_i.orn[63:56]};

assign rep_hash_idx = rdata_i.updated_orn[13:0]  ^ rdata_i.updated_orn[27:14] ^
                      rdata_i.updated_orn[41:28] ^ rdata_i.updated_orn[55:42] ^
                      {6'b0, rdata_i.updated_orn[63:56]};

assign target_idx = (rdata_i.message_type == 8'h55 && rep_state) ? rep_hash_idx : hash_idx;

// data packing assignment for book

assign hash_data.orn        = rdata_i.orn;
assign hash_data.side       = rdata_i.side;
assign hash_data.shares     = rdata_i.shares;
assign hash_data.price      = rdata_i.price;
assign hash_data.next_ptr   = '0; // this might be wrong

// case logic for next state
// 8'h41 = "A", 8'h43 = "C", 8'h44 = "D", 8'h45 = "E", 8'h55 = "U", 8'h58 = "X" - Maybe add local integers?

always_comb begin
    case(current_state)
    CLEAR:   next_state = is_clear   ?   IDLE    :   CLEAR;
    IDLE:    next_state = valid_i    ?   RD_MEM  :   IDLE;
    RD_MEM:  next_state =                EVAL_MEM;
    EVAL_MEM: begin
        if(!bram_dout.valid) begin
            next_state = ((rdata_i.message_type == 8'h41) || (rdata_i.message_type == 8'h55 && rep_state)) ? ADD : IDLE;
        end
        else if(bram_dout.valid && bram_dout.orn == hash_data.orn && rdata_i.message_type != 8'h55)  next_state = EDR;
        else if(bram_dout.valid && bram_dout.orn == hash_data.orn && (rdata_i.message_type == 8'h55 && !rep_state))  next_state = REP;
        else begin
                if((rdata_i.message_type == 8'h41) || (rdata_i.message_type == 8'h55 && rep_state)) begin
                    if(bram_dout.next_ptr == '0) next_state = ALLOC;
                    else next_state = RD_MEM;
                end
                else begin
                    next_state = (bram_dout.next_ptr != '0) ? RD_MEM : IDLE;
                end
        end
    end
    ALLOC:   next_state =                EVAL_MEM;
    ADD:     next_state = valid_i    ?   DONE           :   ADD;
    EDR:     next_state = valid_i    ?   DONE           :   EDR;
    REP:     next_state =                RD_MEM;
    DONE:    next_state = ready_i    ?   IDLE           :   DONE;
    default: next_state = current_state;
    endcase
end


// Sequential logic for Order Book - synchronous reset

always_ff @(posedge clk) begin
    if(!rst_n) begin
        ready_o         <=  1'b0;
        bbo_data_o      <=  '0;
        bbo_valid_o     <=  1'b0;
        current_state   <=  CLEAR;
        is_clear        <=  1'b0;
        clear_idx       <=  '0;
        read_ptr        <=  1'b0;
        fifo_cons       <=  '0;
        fifo_prod       <=  '0;
        ret_state       <=  IDLE;
    end
    else begin
        current_state   <=  next_state;
        bram_dout       <=  book[read_ptr];
        fifo_addr       <=  fifo[fifo_cons];

        if(current_state == CLEAR) begin
            book[clear_idx]     <=  '0;
            clear_idx           <=  clear_idx + 1;
            if(clear_idx >= FIFO_DEPTH) fifo[clear_idx - FIFO_DEPTH] <= clear_idx;
            if(clear_idx == MAP_W) is_clear <= 1'b1;
        end
        else if(current_state == RD_MEM) begin
            if (ret_state == EVAL_MEM) read_ptr <= bram_dout.next_ptr;
            else read_ptr   <=  target_idx;
        end
        else if(current_state == ALLOC) begin
            book[read_ptr].next_ptr <=  fifo_addr;
            read_ptr                <=  fifo_addr;
            fifo_cons               <=  fifo_cons   + 1;
            ret_state               <=  IDLE;
        end
        else if(current_state == EVAL_MEM) begin
            if(bram_dout.valid && bram_dout.orn != hash_data.orn) ret_state <= EVAL_MEM;
            else                                                  ret_state <= IDLE;
        end
        else if(current_state == ADD) begin
            if(valid_i) begin
                book[read_ptr].orn      <= (rdata_i.message_type == 8'h55) ? rdata_i.updated_orn : rdata_i.orn;
                book[read_ptr].side     <= (rdata_i.message_type == 8'h55) ? latched_side        : rdata_i.side;
                book[read_ptr].shares   <= rdata_i.shares;
                book[read_ptr].price    <= rdata_i.price;
                book[read_ptr].valid    <=  1'b1;
                rep_state               <=  1'b0;
            end
        end
        else if(current_state == EDR) begin
            if(valid_i) begin
                if(rdata_i.message_type == 8'h43 || rdata_i.message_type == 8'h45 ||
                   rdata_i.message_type == 8'h58) begin
                    book[read_ptr].shares       <= book[read_ptr].shares - hash_data.shares;
                end
                else if(rdata_i.message_type == 8'h44) begin
                    book[read_ptr]          <=  '0;
                    book[read_ptr].valid    <=  1'b0;
                    fifo[fifo_prod]         <=  read_ptr;
                    fifo_prod               <=  fifo_prod + 1;
                end
            end
        end
        else if(current_state == REP) begin // effectively a delete state (with some latched data)
            book[read_ptr]          <=  '0;
            book[read_ptr].valid    <=  1'b0;
            fifo[fifo_prod]         <=  read_ptr;
            fifo_prod               <=  fifo_prod + 1;
            latched_side            <=  bram_dout.side;
            rep_state               <=  1'b1;
            ret_state               <=  IDLE;
        end
    end
end

assign ready_o  =   (current_state == IDLE) && rst_n;

endmodule
