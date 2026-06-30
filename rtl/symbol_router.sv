parameter int  ORN_W    = 64;
parameter int  PRICE_W  = 32;
parameter int  SHARES_W = 32;
parameter int  PACKET_W = 64;
parameter int  STOCK_W  = 16;
parameter int  MSG_W    = 8;


typedef struct packed {
    logic [MSG_W-1:0]       message_type;
    logic [STOCK_W-1:0]     stock_locate;
    logic [ORN_W-1:0]       orn;
    logic [ORN_W-1:0]       updated_orn;
    logic                   side;
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
} data_t;

typedef struct packed {
    logic [MSG_W-1:0]       message_type;
    logic [ORN_W-1:0]       orn;
    logic [ORN_W-1:0]       updated_orn;
    logic                   side;
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
} o_data_t;

module symbol_router#(
    ORN_W    = 64,
    PRICE_W  = 32,
    SHARES_W = 32,
    PACKET_W = 64,
    STOCK_W  = 16,
    MSG_W    = 8
)(
    input   logic                   clk,
    input   logic                   rst_n,

    // inputs from data handler
    input   data_t                  rdata_i,
    input   logic                   valid_i,

    // output to data handler
    output  logic                   ready_o,

    // input from order_book
    input   logic                   ready_i,

    // outputs to order book
    output  o_data_t                rdata_o,
    output  logic                   valid_o,
    output  logic   [PRICE_W-1:0]   base_price_o
);

logic   [PRICE_W-1:0]   bp_list [31:0];
logic   [31:0]          bp_idx

always_comb begin
    if(valid_i) begin
        case(rdata_i.stock_locate)
        // select stocks (havent decided yet)
        // will have form bp_idx = fixed value for that stock e.g. appl = 0, msft = 1...

        default: ;
        endcase
    end
end

always_ff@(posedge clk) begin
    if(!rst_n) begin
        // clear state probably
    end
    else begin
        if(ready_i) begin
            base_price_o            <=  bp_list[bp_idx];
            rdata_i.message_type    <=  rdata_o.message_type;
            rdata_i.orn             <=  rdata_o.orn;
            rdata_i.price           <=  rdata_o.price;
            rdata_i.shares          <=  rdata_o.shares;
            rdata_i.side            <=  rdata_o.side;
            rdata_i.updated_orn     <=  rdata_o.updated_orn;
            valid_o                 <=  1'b1;
        end
    end
end

endmodule
