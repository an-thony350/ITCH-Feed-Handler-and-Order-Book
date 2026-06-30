parameter int  ORN_W    = 64;
parameter int  PRICE_W  = 32;
parameter int  SHARES_W = 32;
parameter int  MSG_W    = 8;
parameter int  HASH_W   = 12;
parameter int  FIFO_W   = 11;
parameter int  BBO_W    = 12;

// Struct for input data from data handler

typedef struct packed {
    logic [MSG_W-1:0]       message_type;
    logic [STOCK_W-1:0]     stock_locate;
    logic [ORN_W-1:0]       orn;
    logic [ORN_W-1:0]       updated_orn;
    logic                   side;
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
} data_t;

// Struct for relevant data in order book & output from symbol router

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

module order_book_top#(
    ORN_W   =   64,
    PRICE_W =   32,
    SHARES_W=   32,
    MSG_W   =   8,
    HASH_W  =   14,
    FIFO_W  =   12,
    BBO_W   =   11
)(
    input   logic               clk,
    input   logic               rst_n,

    // inputs from data handler
    input   data_t              rdata_i,
    input   logic               valid_i,

    // output to data handler - from symbol router
    input   logic               ready_o,

    // input from next block - from order book
    input   logic               ready_i,

    // output to next block
    output  bbo_t               bbo_data_o,
    output  logic               bbo_valid_o
);

// Internal registers
logic               sr_ob_ready;
o_data_t            ob_sr_rdata;
logic [PRICE_W-1:0] ob_sr_base_price;
logic               ob_sr_valid_stock0;
logic               ob_sr_valid_stock1;
logic               ob_sr_valid_stock2;
logic               ob_sr_valid_stock3;
bbo_t               bbo_stock_0;
bbo_t               bbo_stock_1;
bbo_t               bbo_stock_2;
bbo_t               bbo_stock_3;
logic               bbo_valid_0;
logic               bbo_valid_1;
logic               bbo_valid_2;
logic               bbo_valid_3;



// Data Handler -> Symbol Router

symbol_router router(
    .clk(clk),
    .rst_n(rst_n),
    .rdata_i(rdata_i),
    .valid_i(valid_i),
    .ready_o(ready_o),
    .ready_i(sr_ob_ready),
    .rdata_o(ob_sr_rdata),
    .base_price_o(ob_sr_base_price),
    .valid_stock0_o(ob_sr_valid_stock0),
    .valid_stock1_o(ob_sr_valid_stock1),
    .valid_stock2_o(ob_sr_valid_stock2),
    .valid_stock3_o(ob_sr_valid_stock3)
);

// Symbol Router -> Order Book - 4 Order books

// Stock 1

order_book ob_stock0(
    .clk(clk),
    .rst_n(rst_n),
    .rdata_i(ob_sr_rdata),
    .valid_i(ob_sr_valid_stock0),
    .base_price_i(ob_sr_base_price),
    .ready_o(sr_ob_ready),
    .ready_i(ready_i),
    .bbo_data_o(bbo_stock_0),
    .bbo_valid_o(bbo_valid_0)
);

// Stock 2

order_book ob_stock1(
    .clk(clk),
    .rst_n(rst_n),
    .rdata_i(ob_sr_rdata),
    .valid_i(ob_sr_valid_stock1),
    .base_price_i(ob_sr_base_price),
    .ready_o(sr_ob_ready),
    .ready_i(ready_i),
    .bbo_data_o(bbo_stock_1),
    .bbo_valid_o(bbo_valid_1)
);

// Stock 2

order_book ob_stock2(
    .clk(clk),
    .rst_n(rst_n),
    .rdata_i(ob_sr_rdata),
    .valid_i(ob_sr_valid_stock2),
    .base_price_i(ob_sr_base_price),
    .ready_o(sr_ob_ready),
    .ready_i(ready_i),
    .bbo_data_o(bbo_stock_2),
    .bbo_valid_o(bbo_valid_2)
);

// Stock 4

order_book ob_stock3(
    .clk(clk),
    .rst_n(rst_n),
    .rdata_i(ob_sr_rdata),
    .valid_i(ob_sr_valid_stock3),
    .base_price_i(ob_sr_base_price),
    .ready_o(sr_ob_ready),
    .ready_i(ready_i),
    .bbo_data_o(bbo_stock_3),
    .bbo_valid_o(bbo_valid_3)
);

always_comb begin
    if(bbo_valid_0) begin
        bbo_data_o  = bbo_stock_0;
        bbo_valid_o = bbo_valid_0;
    end
    else if(bbo_valid_1) begin
        bbo_data_o  = bbo_stock_1;
        bbo_valid_o = bbo_valid_1;
    end
    else if(bbo_valid_2) begin
        bbo_data_o  = bbo_stock_2;
        bbo_valid_o = bbo_valid_2;
    end
    else begin
        bbo_data_o  = bbo_stock_3;
        bbo_valid_o = bbo_valid_3;
    end
end


endmodule
