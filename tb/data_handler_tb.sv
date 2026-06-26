// Skeleton for tests on the data handler
// Not actualy written in any valid values for test 1
// TB is for v1



module data_handler_tb;

// Parameters

    parameter int  ORN_W    = 64;
    parameter int  PRICE_W  = 32;
    parameter int  SHARES_W = 32;
    parameter int  PACKET_W = 64;

// I/O ports

    logic                                     clk;
    logic                                     rst_n;
    logic [PACKET_W-1:0]                      s_tdata_i;
    logic                                     s_tvalid_i;
    logic                                     s_tlast_i;
    logic                                     s_tready_o;
    logic                                     ready_i;
    logic [(ORN_W + PRICE_W + SHARES_W):0]    rdata_o;
    logic                                     valid_o;


// Device Under Test (dut)

    data_handler#(
        .ORN_W(ORN_W),
        .PRICE_W(PRICE_W),
        .SHARES_W(SHARES_W),
        .PACKET_W(PACKET_W)
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

// Test 1 - Standard test with ideal conditions - data not added in tbs yet

    task Test_1();
        begin
            @(posedge clk);
            s_tdata_i       <= '0;
            s_tvalid_i      <= '0;
            s_tlast_i       <= '0;
            ready_i         <= 1'b1;
        end
        wait(valid_o);
        reset();

    endtask



    // "Main" Running and evaluation of tests

    initial begin
        reset();

        #20;

        Test_1();

        #20;

        $finish;

    end


endmodule
