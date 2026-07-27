// TB is complete for final version



module data_handler_tb;

// data structure
    typedef struct packed {
        logic [MSG_W-1:0]       message_type;
        logic [STOCK_W-1:0]     stock_locate;
        logic [ORN_W-1:0]       orn;
        logic [ORN_W-1:0]       updated_orn;
        logic                   side;
        logic [SHARES_W-1:0]    shares;
        logic [PRICE_W-1:0]     price;
    } data_t;

// Parameters

    parameter int  ORN_W    = 64;
    parameter int  PRICE_W  = 32;
    parameter int  SHARES_W = 32;
    parameter int  PACKET_W = 64;
    parameter int  STOCK_W  = 16;
    parameter int  MSG_W    = 8;

// I/O ports

    logic                                     clk;
    logic                                     rst_n;
    logic [PACKET_W-1:0]                      s_tdata_i;
    logic                                     s_tvalid_i;
    logic                                     s_tlast_i;
    logic                                     s_tready_o;
    logic                                     ready_i;
    data_t                                    rdata_o;
    logic                                     valid_o;


// Device Under Test (dut)

    data_handler#(
        .ORN_W(ORN_W),
        .PRICE_W(PRICE_W),
        .SHARES_W(SHARES_W),
        .PACKET_W(PACKET_W),
        .STOCK_W(STOCK_W),
        .MSG_W(MSG_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_tdata_i(s_tdata_i),
        .s_tvalid_i(s_tvalid_i),
        .s_tlast_i(s_tlast_i),
        .s_tready_o(s_tready_o),
        .ready_i(ready_i),
        .rdata_o(rdata_o),
        .valid_o(valid_o)
    );

// Initialise clock

    initial begin
        clk = 0;
        forever #5 clk = ~ clk; // Simulates clock with 100MHz freq if using the timescale 1ns/1ps thing
    end

// Reset function

    task reset();
    @(posedge clk);
    rst_n       = 0;
    s_tdata_i   = 0;
    s_tvalid_i  = 0;
    s_tlast_i   = 0;
    ready_i     = 0;

    #10;

    rst_n = 1;

    endtask

// Tests - written as "tasks" for a specific test
// TEXT EVALUATION ($display) still needs to be added (unless reading from wave sim)

// Test 1 - Add Order Test

    task Test_Add_Order();
    $display("Test 1, Add Order, Expected Price value = 150 (decimal): ");
        begin
            @(posedge clk);
            s_tvalid_i      <= 1'b1;
            s_tlast_i       <= 1'b0;
            s_tdata_i       <= 64'h41_00_01_00_01_12_34_56; //split in bytes for simple checking

            @(posedge clk);
            s_tdata_i       <= 64'h78_00_00_00_00_00_00_00;

            @(posedge clk);
            s_tdata_i       <= 64'h00_00_64_42_00_00_01_F4;

            @(posedge clk);
            s_tdata_i       <= 64'h41_41_50_4C_20_20_20_20;

            @(posedge clk);
            s_tdata_i       <= 64'h00_16_E3_60_00_00_00_00;
            s_tlast_i       <= 1'b1;

            @(posedge clk);
            s_tvalid_i      <= 1'b0;
            s_tlast_i       <= 1'b0;
            ready_i         <= 1'b1;

        end
        wait(valid_o);
        #1;

        if(rdata_o.price != 32'h0016e360) $display("Incorrect Price value and parsing.");

        @(posedge clk);
        ready_i <= 1'b0;

        reset();

    endtask

    task Test_Exc_Price();
        $display("Test 2, Executed With Price Message, Expected Price value =  (decimal)");
        begin
            @(posedge clk);
            s_tvalid_i  <= 1'b1;
            s_tlast_i   <= 1'b0;
            s_tdata_i   <= 64'h45_00_01_00_01_12_34_56;

            @(posedge clk);
            s_tdata_i   <= 64'h78_00_00_00_00_00_00_00;

            @(posedge clk);
            s_tdata_i   <= 64'h00_00_84_42_30_00_01_F4;

            @(posedge clk);
            s_tdata_i   <= 64'h41_41_50_4C_20_20_20_20;

            @(posedge clk);
            s_tdata_i   <= 64'h00_06_E3_60_00_00_00_00;
            s_tlast_i       <= 1'b1;

            @(posedge clk);
            s_tvalid_i      <= 1'b0;
            s_tlast_i       <= 1'b0;
            ready_i         <= 1'b1;

        end
        wait(valid_o)
        #1;

        @(posedge clk);
        ready_i <= 1'b0;

        reset();

    endtask

    task Test_Cnl_Price();
        $display("Test 3, Cancel Message");
        begin
            @(posedge clk);
            s_tvalid_i  <= 1'b1;
            s_tlast_i   <= 1'b0;
            s_tdata_i   <= 64'h58_00_01_00_01_12_34_56;

            @(posedge clk);
            s_tdata_i   <= 64'h00_00_00_00_00_00_00_23;

            @(posedge clk);
            s_tdata_i   <= 64'h00_00_49_00_00_1A_00_02;
            s_tlast_i   <= 1'b1;

            @(posedge clk);
            s_tvalid_i  <= 1'b0;
            s_tlast_i   <= 1'b0;
            ready_i     <= 1'b1;

        end
        wait(valid_o);
        #1;

        @(posedge clk);
        ready_i <= 1'b0;

        reset();

    endtask

    task Test_Del_Price();
        $display("Test 4, Delete Message");
        begin
            @(posedge clk);
            s_tvalid_i  <= 1'b1;
            s_tlast_i   <= 1'b0;
            s_tdata_i   <= 64'h44_00_01_00_01_12_34_56;

            @(posedge clk);
            s_tdata_i   <= 64'h00_00_00_00_00_00_00_52;

            @(posedge clk);
            s_tdata_i   <= 64'h00_00_10_00_00_00_00_00;
            s_tlast_i   <= 1'b1;

            @(posedge clk);
            s_tvalid_i  <= 1'b0;
            s_tlast_i   <= 1'b0;
            ready_i     <= 1'b1;

        end

        wait(valid_o);
        #1;

        @(posedge clk);
        ready_i <= 1'b0;

        reset();

    endtask

    task Test_Rep_Price();
        begin
            @(posedge clk);
            s_tvalid_i  <= 1'b1;
            s_tlast_i   <= 1'b0;
            s_tdata_i   <= 64'h55_00_01_00_01_12_34_56;

            @(posedge clk);
            s_tdata_i   <= 64'h78_00_00_00_00_00_00_00;

            @(posedge clk);
            s_tdata_i   <= 64'h00_00_32_00_00_00_00_00;

            @(posedge clk);
            s_tdata_i   <= 64'h00_00_64_00_00_02_E3_00;

            @(posedge clk);
            s_tdata_i   <= 64'h00_02_3D_00_00_00_00_00;
            s_tlast_i   <= 1'b1;

            @(posedge clk);
            s_tvalid_i  <= 1'b0;
            s_tlast_i   <= 1'b0;
            ready_i     <= 1'b1;
        end

        wait(valid_o);
        #1;

        @(posedge clk);
        ready_i <= 1'b0;

        reset();

    endtask


    // "Main" Running and evaluation of tests

    initial begin
        reset();

        #20;

        Test_Add_Order();

        #20;

        Test_Exc_Price();

        #20;

        Test_Cnl_Price();

        #20;

        Test_Del_Price();

        #20;

        Test_Rep_Price();

        $finish;

    end


endmodule
