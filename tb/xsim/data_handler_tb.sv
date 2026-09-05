`timescale 1ns / 1ps
`default_nettype none

import hdl_header::*;

module data_handler_tb;

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
        if(PACKET_W != 64) begin
            $fatal(1, "data_handler_tb requires PACKET_W=64");
        end

        clk = 0;
        forever #5 clk = ~ clk; // Simulates clock with 100MHz freq if using the timescale 1ns/1ps thing
    end

// Reset function

    task automatic reset();
        rst_n       <= 0;
        s_tdata_i   <= 0;
        s_tvalid_i  <= 0;
        s_tlast_i   <= 0;
        ready_i     <= 1;

        repeat(5) @(posedge clk);

        rst_n <= 1;

        repeat(2) @(posedge clk);
    endtask

// Common AXI/input helpers

    task automatic send_beat(
        input logic [63:0] data,
        input logic        last
    );
        @(negedge clk);
        s_tdata_i  <= data;
        s_tlast_i  <= last;
        s_tvalid_i <= 1'b1;

        do begin
            @(posedge clk);
        end while(!s_tready_o);

        @(negedge clk);
        s_tvalid_i <= 1'b0;
        s_tlast_i  <= 1'b0;
        s_tdata_i  <= '0;
    endtask

    task automatic wait_for_event();
        int timeout;

        timeout = 0;
        while(!valid_o && timeout < 100) begin
            @(negedge clk);
            timeout++;
        end

        if(!valid_o) begin
            $fatal(1, "Timed out waiting for data_handler event");
        end
    endtask

    task automatic expect_common(
        input logic [7:0]  message_type,
        input logic [15:0] stock_locate,
        input logic [63:0] orn
    );
        if(rdata_o.message_type !== message_type)
            $fatal(1, "message_type mismatch: got %02h expected %02h",
                   rdata_o.message_type, message_type);

        if(rdata_o.stock_locate !== stock_locate)
            $fatal(1, "stock_locate mismatch: got %04h expected %04h",
                   rdata_o.stock_locate, stock_locate);

        if(rdata_o.orn !== orn)
            $fatal(1, "ORN mismatch: got %016h expected %016h",
                   rdata_o.orn, orn);
    endtask

    task automatic consume_event();
        @(negedge clk);
        ready_i <= 1'b1;

        @(posedge clk);
        @(negedge clk);

        if(valid_o)
            $fatal(1, "valid_o remained asserted after ready_i handshake");
    endtask

// Test 1 - Add Order A

    task automatic Test_Add_Order_A();
        $display("TEST Add Order A");

        ready_i <= 1'b0;

        // Bytes:
        // type=A, locate=0x1234, tracking=0x5678,
        // timestamp=0x010203040506, ORN=0x1122334455667788,
        // side=B, shares=500, stock="AAPL    ", price=1500000.
        send_beat(64'h41_12_34_56_78_01_02_03, 1'b0);
        send_beat(64'h04_05_06_11_22_33_44_55, 1'b0);
        send_beat(64'h66_77_88_42_00_00_01_F4, 1'b0);
        send_beat(64'h41_41_50_4C_20_20_20_20, 1'b0);
        send_beat(64'h00_16_E3_60_00_00_00_00, 1'b1);

        wait_for_event();

        expect_common(8'h41, 16'h1234, 64'h1122334455667788);

        if(rdata_o.side !== 1'b1)
            $fatal(1, "ADD A side mismatch");

        if(rdata_o.shares !== 32'd500)
            $fatal(1, "ADD A shares mismatch: got %0d", rdata_o.shares);

        if(rdata_o.price !== 32'h0016E360)
            $fatal(1, "ADD A price mismatch: got %08h", rdata_o.price);

        if(rdata_o.updated_orn !== '0)
            $fatal(1, "ADD A updated_orn should be zero");

        consume_event();
    endtask

// Test 2 - Add Order F

    task automatic Test_Add_Order_F();
        $display("TEST Add Order F");

        ready_i <= 1'b0;

        send_beat(64'h46_12_34_56_78_01_02_03, 1'b0);
        send_beat(64'h04_05_06_11_22_33_44_55, 1'b0);
        send_beat(64'h66_77_88_53_00_00_00_64, 1'b0); // side=S, shares=100
        send_beat(64'h4D_53_46_54_20_20_20_20, 1'b0);
        send_beat(64'h00_0F_42_40_41_42_43_44, 1'b1); // price + ignored MPID "ABCD"

        wait_for_event();

        expect_common(8'h46, 16'h1234, 64'h1122334455667788);

        if(rdata_o.side !== 1'b0)
            $fatal(1, "ADD F side mismatch");

        if(rdata_o.shares !== 32'd100)
            $fatal(1, "ADD F shares mismatch");

        if(rdata_o.price !== 32'h000F4240)
            $fatal(1, "ADD F price mismatch");

        consume_event();
    endtask

// Test 3 - Order Executed

    task automatic Test_Executed();
        $display("TEST Order Executed E");

        ready_i <= 1'b0;

        send_beat(64'h45_12_34_56_78_01_02_03, 1'b0);
        send_beat(64'h04_05_06_11_22_33_44_55, 1'b0);
        send_beat(64'h66_77_88_00_00_00_64_AA, 1'b0); // shares=100, then match byte 0
        send_beat(64'hBB_CC_DD_EE_FF_00_11_00, 1'b1);

        wait_for_event();

        expect_common(8'h45, 16'h1234, 64'h1122334455667788);

        if(rdata_o.shares !== 32'd100)
            $fatal(1, "E shares mismatch: got %0d", rdata_o.shares);

        consume_event();
    endtask

// Test 4 - Order Executed With Price

    task automatic Test_Executed_With_Price();
        $display("TEST Order Executed With Price C");

        ready_i <= 1'b0;

        send_beat(64'h43_12_34_56_78_01_02_03, 1'b0);
        send_beat(64'h04_05_06_11_22_33_44_55, 1'b0);
        send_beat(64'h66_77_88_00_00_00_32_01, 1'b0); // shares=50, then match byte 0
        send_beat(64'h02_03_04_05_06_07_08_59, 1'b0); // remaining match + printable='Y'
        send_beat(64'h00_AB_CD_EF_00_00_00_00, 1'b1);

        wait_for_event();

        expect_common(8'h43, 16'h1234, 64'h1122334455667788);

        if(rdata_o.shares !== 32'd50)
            $fatal(1, "C shares mismatch");

        // The order book does not currently use execution price, but preserve
        // the existing decoder behaviour for C messages.
        if(rdata_o.price !== 32'h00ABCDEF)
            $fatal(1, "C execution price mismatch: got %08h", rdata_o.price);

        consume_event();
    endtask

// Test 5 - Order Cancel

    task automatic Test_Cancel();
        $display("TEST Order Cancel X");

        ready_i <= 1'b0;

        send_beat(64'h58_12_34_56_78_01_02_03, 1'b0);
        send_beat(64'h04_05_06_11_22_33_44_55, 1'b0);
        send_beat(64'h66_77_88_00_00_00_19_00, 1'b1);

        wait_for_event();

        expect_common(8'h58, 16'h1234, 64'h1122334455667788);

        if(rdata_o.shares !== 32'd25)
            $fatal(1, "X shares mismatch");

        consume_event();
    endtask

// Test 6 - Order Delete

    task automatic Test_Delete();
        $display("TEST Order Delete D");

        ready_i <= 1'b0;

        send_beat(64'h44_12_34_56_78_01_02_03, 1'b0);
        send_beat(64'h04_05_06_11_22_33_44_55, 1'b0);
        send_beat(64'h66_77_88_00_00_00_00_00, 1'b1);

        wait_for_event();

        expect_common(8'h44, 16'h1234, 64'h1122334455667788);

        consume_event();
    endtask

// Test 7 - Order Replace

    task automatic Test_Replace();
        $display("TEST Order Replace U");

        ready_i <= 1'b0;

        send_beat(64'h55_12_34_56_78_01_02_03, 1'b0);
        send_beat(64'h04_05_06_11_22_33_44_55, 1'b0);
        send_beat(64'h66_77_88_99_AA_BB_CC_DD, 1'b0);
        send_beat(64'hEE_FF_00_00_00_00_C8_00, 1'b0);
        send_beat(64'h12_34_56_00_00_00_00_00, 1'b1);

        wait_for_event();

        expect_common(8'h55, 16'h1234, 64'h1122334455667788);

        if(rdata_o.updated_orn !== 64'h99AABBCCDDEEFF00)
            $fatal(1, "U updated_orn mismatch: got %016h", rdata_o.updated_orn);

        if(rdata_o.shares !== 32'd200)
            $fatal(1, "U shares mismatch: got %0d", rdata_o.shares);

        if(rdata_o.price !== 32'h00123456)
            $fatal(1, "U price mismatch: got %08h", rdata_o.price);

        consume_event();
    endtask

// Test 8 - Unsupported messages are skipped

    task automatic Test_Unsupported();
        $display("TEST unsupported message is skipped");

        ready_i <= 1'b1;

        send_beat(64'h52_00_01_00_02_00_00_00, 1'b0); // Stock Directory 'R'
        send_beat(64'h00_00_00_41_41_50_4C_20, 1'b1);

        repeat(3) @(negedge clk);

        if(valid_o)
            $fatal(1, "Unsupported message produced an event");
    endtask

// Test 9 - Output backpressure

    task automatic Test_Backpressure();
        logic [DATA_T_W-1:0] held_data;

        $display("TEST output backpressure holds event stable");

        ready_i <= 1'b0;

        send_beat(64'h41_12_34_56_78_01_02_03, 1'b0);
        send_beat(64'h04_05_06_11_22_33_44_55, 1'b0);
        send_beat(64'h66_77_88_42_00_00_01_F4, 1'b0);
        send_beat(64'h41_41_50_4C_20_20_20_20, 1'b0);
        send_beat(64'h00_16_E3_60_00_00_00_00, 1'b1);

        wait_for_event();

        held_data = rdata_o;

        repeat(5) begin
            @(negedge clk);

            if(!valid_o)
                $fatal(1, "valid_o dropped under backpressure");

            if(s_tready_o)
                $fatal(1, "s_tready_o asserted while SEND is backpressured");

            if(rdata_o !== held_data)
                $fatal(1, "rdata_o changed under backpressure");
        end

        consume_event();
    endtask


    // "Main" Running and evaluation of tests

    initial begin
        reset();

        Test_Add_Order_A();
        Test_Add_Order_F();
        Test_Executed();
        Test_Executed_With_Price();
        Test_Cancel();
        Test_Delete();
        Test_Replace();
        Test_Unsupported();
        Test_Backpressure();

        $display("data_handler_tb PASS");
        $finish;
    end


endmodule

`default_nettype wire
