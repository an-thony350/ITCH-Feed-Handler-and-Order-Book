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
    HASH_W  =   12,
    FIFO_W  =   11,
    BBO_W   =   12
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

// Internal registers sr + ob regs
logic [3:0]         sr_ob_ready_bus;
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

// Internal registers for 4 FIFOs

bbo_t fifo_0 [15:0];
bbo_t fifo_1 [15:0];
bbo_t fifo_2 [15:0];
bbo_t fifo_3 [15:0];

logic [3:0] wr_ptr [4];
logic [3:0] rd_ptr [4];
logic       fifo_empty [4];
logic [1:0] sched_count

// fifo assignment
assign fifo_empty[0] = (wr_ptr[0] == rd_ptr[0]);
assign fifo_empty[1] = (wr_ptr[1] == rd_ptr[1]);
assign fifo_empty[2] = (wr_ptr[2] == rd_ptr[2]);
assign fifo_empty[3] = (wr_ptr[3] == rd_ptr[3]);



// Data Handler -> Symbol Router

symbol_router router(
    .clk(clk),
    .rst_n(rst_n),
    .rdata_i(rdata_i),
    .valid_i(valid_i),
    .ready_o(ready_o),
    .ready_i(sr_ob_ready_bus),
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
    .ready_o(sr_ob_ready_bus[0]),
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
    .ready_o(sr_ob_ready_bus[1]),
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
    .ready_o(sr_ob_ready_bus[2]),
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
    .ready_o(sr_ob_ready_bus[3]),
    .ready_i(ready_i),
    .bbo_data_o(bbo_stock_3),
    .bbo_valid_o(bbo_valid_3)
);

// FIFO write logic

always_ff @(posedge clk) begin
    if (!rst_n) begin
        wr_ptr[0]   <=  '0;
        wr_ptr[1]   <=  '0;
        wr_ptr[2]   <=  '0;
        wr_ptr[3]   <=  '0;
    end
    else begin
        if(bbo_valid_0) begin
            fifo_0[wr_ptr[0]] <= bbo_stock_0;
            wr_ptr[0] <= wr_ptr[0] + 1'b1;
        end
        if(bbo_valid_1) begin
            fifo_1[wr_ptr[1]] <= bbo_stock_1;
            wr_ptr[1] <= wr_ptr[1] + 1'b1;
        end
        if(bbo_valid_2) begin
            fifo_2[wr_ptr[2]] <= bbo_stock_2;
            wr_ptr[2] <= wr_ptr[2] + 1'b1;
        end
        if(bbo_valid_3) begin
            fifo_3[wr_ptr[3]] <= bbo_stock_3;
            wr_ptr[3] <= wr_ptr[3] + 1'b1;
        end
    end
end

// RR scheduler and read logic from fifo

always_ff @(posedge clk) begin
    if (!rst_n) begin
        sched_count <= '0;
        rd_ptr[0]   <= '0;
        rd_ptr[1]   <= '0;
        rd_ptr[2]   <= '0;
        rd_ptr[3]   <= '0;
        bbo_valid_o <= 1'b0;
        bbo_data_o  <= '0;
    end
    else begin
        bbo_valid_o <= 1'b0;
        sched_count <= sched_count + 1'b1;

        case (sched_count)

            2'd0: begin
                if (!fifo_empty[0]) begin
                    bbo_data_o  <= fifo_0[rd_ptr[0]];
                    bbo_valid_o <= 1'b1;
                    rd_ptr[0]   <= rd_ptr[0] + 1'b1;
                end
            end
            2'd1: begin
                if (!fifo_empty[1]) begin
                    bbo_data_o  <= fifo_1[rd_ptr[1]];
                    bbo_valid_o <= 1'b1;
                    rd_ptr[1]   <= rd_ptr[1] + 1'b1;
                end
            end
            2'd2: begin
                if (!fifo_empty[2]) begin
                    bbo_data_o  <= fifo_2[rd_ptr[2]];
                    bbo_valid_o <= 1'b1;
                    rd_ptr[2]   <= rd_ptr[2] + 1'b1;
                end
            end
            2'd3: begin
                if (!fifo_empty[3]) begin
                    bbo_data_o  <= fifo_3[rd_ptr[3]];
                    bbo_valid_o <= 1'b1;
                    rd_ptr[3]   <= rd_ptr[3] + 1'b1;
                end
            end
        endcase
    end
end

endmodule
