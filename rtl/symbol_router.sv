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
    output  logic   [PRICE_W-1:0]   base_price_o,

    // stock outputs to order book - names will change
    output  logic                   valid_stock0_o,
    output  logic                   valid_stock1_o,
    output  logic                   valid_stock2_o,
    output  logic                   valid_stock3_o

);

logic   [PRICE_W-1:0]   bp_list [4];

// Temporarily initialised ROM here, we can change this later with a .mem file
initial begin
    bp_list[0] = 32'h00_00_3A_98; // Stock 0: $150.00
    bp_list[1] = 32'h00_00_4E_20; // Stock 1: $200.00
    bp_list[2] = 32'h00_00_27_10; // Stock 2: $100.00
    bp_list[3] = 32'h00_00_13_88; // Stock 3: $50.00
end

// combination I/O assignment
assign rdata_o.message_type = rdata_i.message_type;
assign rdata_o.orn          = rdata_i.orn;
assign rdata_o.updated_orn  = rdata_i.updated_orn;
assign rdata_o.side         = rdata_i.side;
assign rdata_o.shares       = rdata_i.shares;
assign rdata_o.price        = rdata_i.price;

always_ff@(posedge clk) begin
    if(!rst_n) begin
        valid_stock0_o  <=  1'b0;
        valid_stock1_o  <=  1'b0;
        valid_stock2_o  <=  1'b0;
        valid_stock3_o  <=  1'b0;
    end
    else begin
        valid_stock0_o  <=  1'b0;
        valid_stock1_o  <=  1'b0;
        valid_stock2_o  <=  1'b0;
        valid_stock3_o  <=  1'b0;
        ready_o         <=  1'b1;
        if(valid_i && ready_i) begin
            case(rdata_i.stock_locate) // actual values not added yet as stocks undecided
                16'd0:  begin
                    valid_stock0_o  <=  1'b1;
                    base_price_o    <=  bp_list[0];
                end
                16'd1:  begin
                    valid_stock1_o  <=  1'b1;
                    base_price_o    <=  bp_list[1];
                end
                16'd2:  begin
                    valid_stock2_o  <=  1'b1;
                    base_price_o    <=  bp_list[2];
                end
                16'd3:  begin
                    valid_stock3_o  <=  1'b1;
                    base_price_o    <=  bp_list[3];
                end
                default:    ;
            endcase
        end
    end
end

endmodule
