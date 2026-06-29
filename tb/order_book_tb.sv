`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 29.06.2026 16:12:08
// Design Name:
// Module Name: order_book_tb
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



/*

Note that the price data is written as the value in pounds shifted by 100

e.g. $140.50 = 14050 in decimal
     $170.00 = 17000 in decimal


*/
module order_book_tb;

// input data structure

    typedef struct packed {
        logic [MSG_W-1:0]       message_type;
        logic [STOCK_W-1:0]     stock_locate;
        logic [ORN_W-1:0]       orn;
        logic [ORN_W-1:0]       updated_orn;
        logic                   side;
        logic [SHARES_W-1:0]    shares;
        logic [PRICE_W-1:0]     price;
    } data_t;

// output data structure

    typedef struct packed {
        logic [PRICE_W-1:0]     bid_price;
        logic [SHARES_W-1:0]    bid_shares;
        logic [PRICE_W-1:0]     ask_price;
        logic [SHARES_W-1:0]    ask_shares;
    } bbo_t;

// Parameters

    parameter int  ORN_W    = 64;
    parameter int  PRICE_W  = 32;
    parameter int  SHARES_W = 32;
    parameter int  PACKET_W = 64;
    parameter int  STOCK_W  = 16;
    parameter int  MSG_W    = 8;
    parameter int  HASH_W   = 14;
    parameter int  FIFO_W   = 13;
    parameter int  BBO_W    = 12;

// I/O Ports

    logic               clk;
    logic               rst_n;
    data_t              rdata_i;
    logic               valid_i;
    logic [PRICE_W-1:0] base_price;
    logic               ready_o;
    logic               ready_i;
    bbo_t               bbo_data_o;
    logic               bbo_valid_o;

// Device Under Test (dut)

    order_book#(
        .ORN_W(ORN_W),
        .PRICE_W(PRICE_W),
        .SHARES_W(SHARES_W),
        .STOCK_W(STOCK_W),
        .MSG_W(MSG_W),
        .HASH_W(HASH_W),
        .FIFO_W(FIFO_W),
        .BBO_W(BBO_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rdata_i(rdata_i),
        .valid_i(valid_i),
        .base_price(base_price),
        .ready_o(ready_o),
        .ready_i(ready_i),
        .bbo_data_o(bbo_data_o),
        .bbo_valid_o(bbo_valid_o)
    );

// Initialise clock

    initial begin
        clk = 0;
        forever #5 clk = ~ clk;
    end

// Reset function

    task reset();
    @(posedge clk);
    rst_n       <= 0;
    rdata_i     <= '0;
    valid_i     <= 0;
    ready_i     <= 0;

    #50;

    rst_n <= 1;
    $display("Waiting for Order Book to initialise memory...");
    wait(ready_o == 1'b1);
    $display("Order Book Initialised");

    @(posedge clk);

    endtask

// Default additions to allow for next tests - still act as tests on their own

    task Test_Add_BID_To_Book_BASE();
    $display("Adding base data to order book for bid prices...");
        begin
            @(posedge clk);
            valid_i                     <=  1'b1;
            base_price                  <=  32'h00_00_3A_98; // $150.00 base price
            rdata_i.message_type        <=  8'h41;
            rdata_i.orn                 <=  64'h00_00_00_00_00_00_00_64; // 100
            rdata_i.price               <=  32'h00_00_44_5C; // $175.00 price value
            rdata_i.shares              <=  32'h00_00_01_F4; // 500 shares
            rdata_i.side                <=  1'b1; // Buy
            rdata_i.stock_locate        <=  16'h00_64; // not relevant currently - may actuaally remove in order book???
            rdata_i.updated_orn         <=  64'h0;

            @(posedge clk);
            ready_i                     <=  1'b1;
        end
        wait(bbo_valid_o);
        valid_i <=  1'b0;
        #1;

        if(bbo_data_o.bid_price != 32'h0000445c) $display("Incorrect Price Value");
        else $display("Correct Price Value");

        @(posedge clk);
        ready_i     <=   1'b0;

    endtask

    task Test_Add_ASK_To_Book_BASE();
    $display("Adding base data to order book for ask prices...");
        begin
            @(posedge clk);
            valid_i                     <=  1'b1;
            base_price                  <=  32'h00_00_3A_98; // $150.00 base price
            rdata_i.message_type        <=  8'h41;
            rdata_i.orn                 <=  64'h00_00_00_00_00_00_00_64; // 100
            rdata_i.price               <=  32'h00_00_4A_6A; // $200.00 price value
            rdata_i.shares              <=  32'h00_00_00_32; // 50 shares
            rdata_i.side                <=  1'b0; // Sell
            rdata_i.stock_locate        <=  16'h00_64; // not relevant currently - may actuaally remove in order book???
            rdata_i.updated_orn         <=  64'h0;

            @(posedge clk);
            ready_i                     <=  1'b1;
        end
        wait(bbo_valid_o);
        valid_i <=  1'b0;
        #1;

        if(bbo_data_o.ask_price != 32'h00004a6a) $display("Incorrect Price Value");
        else $display("Correct Price Value");

        @(posedge clk);
        ready_i     <=   1'b0;

    endtask

// Actual tests now with base data added - focus on forming linked lists
// From here, only change price and shares

    task Test_Add_BID_To_Book([PRICE_W-1:0] price_i, [SHARES_W-1:0] shares_i);
    $display("Adding data to order book for bid prices...");
        begin
            @(posedge clk);
            valid_i                     <=  1'b1;
            base_price                  <=  32'h00_00_3A_98; // $150.00 base price
            rdata_i.message_type        <=  8'h41;
            rdata_i.orn                 <=  64'h00_00_00_00_00_00_00_64; // 100
            rdata_i.price               <=  price_i;
            rdata_i.shares              <=  shares_i;
            rdata_i.side                <=  1'b1; // Buy
            rdata_i.stock_locate        <=  16'h00_64; // not relevant currently - may actuaally remove in order book???
            rdata_i.updated_orn         <=  64'h0;

            @(posedge clk);
            ready_i                     <=  1'b1;
        end
        wait(bbo_valid_o);
        valid_i <=  1'b0;
        #1;


        @(posedge clk);
        ready_i     <=   1'b0;

    endtask

    task Test_Add_ASK_To_Book([PRICE_W-1:0] price, [SHARES_W-1:0] shares);
    $display("Adding base data to order book for ask prices...");
        begin
            @(posedge clk);
            valid_i                     <=  1'b1;
            base_price                  <=  32'h00_00_3A_98; // $150.00 base price
            rdata_i.message_type        <=  8'h41;
            rdata_i.orn                 <=  64'h00_00_00_00_00_00_00_64; // 100
            rdata_i.price               <=  price;
            rdata_i.shares              <=  shares;
            rdata_i.side                <=  1'b0; // Sell
            rdata_i.stock_locate        <=  16'h00_64; // not relevant currently - may actuaally remove in order book???
            rdata_i.updated_orn         <=  64'h0;

            @(posedge clk);
            ready_i                     <=  1'b1;
        end
        wait(bbo_valid_o);
        valid_i <=  1'b0;
        #1;


        @(posedge clk);
        ready_i     <=   1'b0;

    endtask

// Main

    initial begin

        reset();

        #20;

        Test_Add_BID_To_Book_BASE();

        #20;

        Test_Add_ASK_To_Book_BASE();

        #20;

        Test_Add_BID_To_Book(32'h00_00_4A_38, 32'd40); // $190.00, 40 shares
        if(bbo_data_o.bid_price != 32'h00004a38) $display("Incorrect Price Value");
        else $display("Correct Price Value");

        #20;

        Test_Add_BID_To_Book(32'h00_00_46_50, 32'd20); // $180.00, 40 shares
        if(bbo_data_o.bid_price != 32'h00004a38) $display("Incorrect Price Value");
        else $display("Correct Price Value");


        #20;

        Test_Add_ASK_To_Book(32'h00_00_48_44, 32'd199); // $185.00, 199 shares
        if(bbo_data_o.ask_price != 32'h00004844) $display("Incorrect Price Value");
        else $display("Correct Price Value");

        $finish;
    end

endmodule
