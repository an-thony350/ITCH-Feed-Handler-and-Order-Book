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


module order_book_tb;

// input data structure

    typedef struct packed {
        logic [MSG_W-1:0]       message_type;
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
    parameter int  HASH_W   = 12;
    parameter int  FIFO_W   = 11;
    parameter int  BBO_W    = 12;

// I/O Ports

    logic               clk;
    logic               rst_n;
    data_t              rdata_i;
    logic               valid_i;
    logic [PRICE_W-1:0] base_price;
    logic               ready_o;
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
        .base_price_i(base_price),
        .ready_o(ready_o),
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

    #50;

    rst_n <= 1;
    $display("Waiting for Order Book to initialize memory...");
    wait(ready_o == 1'b1);
    $display("Order Book Initialized and Ready!");

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
            rdata_i.updated_orn         <=  64'h0;

            @(posedge clk);
            valid_i                     <=  1'b0;
        end
        wait(bbo_valid_o);
        #1;

        if(bbo_data_o.bid_price != 32'h0000445c) $display("Incorrect Price Value");
        else $display("Correct Price Value");

        @(posedge clk);

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
            rdata_i.updated_orn         <=  64'h0;

            @(posedge clk);
            valid_i                     <=  1'b0;
        end
        wait(bbo_valid_o);
        #1;

        if(bbo_data_o.ask_price != 32'h00004a6a) $display("Incorrect Price Value");
        else $display("Correct Price Value");

        @(posedge clk);

    endtask

// Actual tests now with base data added - focus on forming linked lists
// From here, only change price and shares

    task Test_Add_BID_To_Book();
    $display("Adding data to order book for bid prices...");
        begin
            @(posedge clk);
            valid_i                     <=  1'b1;
            base_price                  <=  32'h00_00_3A_98; // $150.00 base price
            rdata_i.message_type        <=  8'h41;
            rdata_i.orn                 <=  64'h00_00_00_00_00_00_40_65; // 100
            rdata_i.price               <=  32'h00_00_4A_38; // $190.00
            rdata_i.shares              <=  32'd40; // 40 shares
            rdata_i.side                <=  1'b1; // Buy
            rdata_i.updated_orn         <=  64'h0;

            @(posedge clk);
            valid_i                     <=  1'b0;
        end
        wait(bbo_valid_o);
        #1;



    endtask

    task Test_Add_ASK_To_Book([PRICE_W-1:0] price, [SHARES_W-1:0] shares);
    $display("Adding base data to order book for ask prices...");
        begin
            @(posedge clk);
            valid_i                     <=  1'b1;
            base_price                  <=  32'h00_00_3A_98; // $150.00 base price
            rdata_i.message_type        <=  8'h41;
            rdata_i.orn                 <=  64'h00_00_00_00_00_00_00_64; // 100
            rdata_i.price               <=  32'h00_00_4A_38;
            rdata_i.shares              <=  32'd40;
            rdata_i.side                <=  1'b0; // Sell
            rdata_i.updated_orn         <=  64'h0;

            @(posedge clk);
            valid_i                     <=  1'b0;
        end
        wait(bbo_valid_o);
        #1;



    endtask

    task Test_Order_Executed_MSG_BID();
    $display("Executing order message - taking away shares count...");
        begin
            @(posedge clk);
            valid_i                     <=  1'b1;
            base_price                  <=  32'h00_00_3A_98; // $150.00 base price
            rdata_i.message_type        <=  8'h43;
            rdata_i.orn                 <=  64'h00_00_00_00_00_00_40_65;
            rdata_i.price               <=  32'h00_00_4A_38;
            rdata_i.shares              <=  32'd20;
            rdata_i.side                <=  1'b1;
            rdata_i.updated_orn         <=  64'h0;

            @(posedge clk);
            valid_i                     <=  1'b0;
        end
        wait(bbo_valid_o);
        #1;


    endtask

    task Test_Same_Order_Replace();
    $display("Starting replace test...");
        begin
            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd166;
            rdata_i.price   <=  32'd10000;
            rdata_i.shares  <=  32'd100;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h55;
            rdata_i.orn <=  64'd166;
            rdata_i.price   <=  32'd10000;
            rdata_i.shares  <=  32'd30;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  64'd400;

            @(posedge clk);
            valid_i <=  1'b0;

            wait(bbo_valid_o);
            #1;
        end
        if(bbo_data_o.bid_shares != 32'd30) $display("Failed test");
        else $display("Passed Test");
    endtask

    task Test_Multi_Add_And_Del();
        begin
            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd3001;
            rdata_i.price   <=  32'd10000;
            rdata_i.shares  <=  32'd100;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd3002;
            rdata_i.price   <=  32'd10005;
            rdata_i.shares  <=  32'd50;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd3003;
            rdata_i.price   <=  32'd9995;
            rdata_i.shares  <=  32'd25;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd4001;
            rdata_i.price   <=  32'd10020;
            rdata_i.shares  <=  32'd70;
            rdata_i.side    <=  1'b0;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd4002;
            rdata_i.price   <=  32'd10015;
            rdata_i.shares  <=  32'd30;
            rdata_i.side    <=  1'b0;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd4003;
            rdata_i.price   <=  32'd10025;
            rdata_i.shares  <=  32'd10;
            rdata_i.side    <=  1'b0;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h44;
            rdata_i.orn <=  64'd3002;
            rdata_i.price   <=  32'd10000;
            rdata_i.shares  <=  32'd100;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h44;
            rdata_i.orn <=  64'd4002;
            rdata_i.price   <=  32'd10000;
            rdata_i.shares  <=  32'd100;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h44;
            rdata_i.orn <=  64'd3001;
            rdata_i.price   <=  32'd10000;
            rdata_i.shares  <=  32'd100;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h44;
            rdata_i.orn <=  64'd4001;
            rdata_i.price   <=  32'd10000;
            rdata_i.shares  <=  32'd100;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);
            #1;
        end
        if(bbo_data_o.ask_shares != 32'd10) $display("Test Failed");
        else $display("Test Passed");
    endtask

    task Test_Extreme_Vals();
        begin
            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd8001;
            rdata_i.price   <=  32'd9000;
            rdata_i.shares  <=  32'd10;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd8002;
            rdata_i.price   <=  32'd13095;
            rdata_i.shares  <=  32'd20;
            rdata_i.side    <=  1'b1;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd8003;
            rdata_i.price   <=  32'd13095;
            rdata_i.shares  <=  32'd30;
            rdata_i.side    <=  1'b0;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h41;
            rdata_i.orn <=  64'd8004;
            rdata_i.price   <=  32'd9001;
            rdata_i.shares  <=  32'd40;
            rdata_i.side    <=  1'b0;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);

            @(posedge clk);
            valid_i <=  1'b1;
            base_price  <=  32'd9000;
            rdata_i.message_type    <=  8'h44;
            rdata_i.orn <=  64'd8002;
            rdata_i.price   <=  32'd10015;
            rdata_i.shares  <=  32'd30;
            rdata_i.side    <=  1'b0;
            rdata_i.updated_orn <=  '0;

            @(posedge clk);
            valid_i <=      1'b0;

            wait(bbo_valid_o);
            #1;
        end
        if(bbo_data_o.ask_price != 32'd9001) $display("Test Failed");
        else $display("Test Complete");

    endtask


// Main

    initial begin

        reset();

        #20;
        Test_Extreme_Vals();
/*
        Test_Add_BID_To_Book_BASE();

        #20;

        //Test_Add_ASK_To_Book_BASE();

        //#20;

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
*/
        $finish;
    end

endmodule
