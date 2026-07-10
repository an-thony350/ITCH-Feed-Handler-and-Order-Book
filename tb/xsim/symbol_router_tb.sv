`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module symbol_router_tb;

    localparam logic [STOCK_W-1:0] TARGET_LOCATE = 16'd42;
    localparam logic [PRICE_W-1:0] BASE_PRICE    = 32'd1_500_000;

    logic                   clk;
    logic                   rst_n;
    logic [STOCK_W-1:0]     target_locate_i;
    logic [PRICE_W-1:0]     base_price_i;
    data_t                  rdata_i;
    logic                   valid_i;
    logic                   ready_o;
    logic                   ready_i;
    o_data_t                rdata_o;
    logic [PRICE_W-1:0]     base_price_o;
    logic                   valid_stock0_o;

    symbol_router dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .target_locate_i (target_locate_i),
        .base_price_i    (base_price_i),
        .rdata_i         (rdata_i),
        .valid_i         (valid_i),
        .ready_o         (ready_o),
        .ready_i         (ready_i),
        .rdata_o         (rdata_o),
        .base_price_o    (base_price_o),
        .valid_stock0_o  (valid_stock0_o)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic reset_dut();
        rst_n           = 1'b0;
        target_locate_i = TARGET_LOCATE;
        base_price_i    = BASE_PRICE;
        rdata_i         = '0;
        valid_i         = 1'b0;
        ready_i         = 1'b1;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
    endtask

    task automatic load_test_event(input logic [STOCK_W-1:0] locate);
        rdata_i.message_type = 8'h41;
        rdata_i.stock_locate = locate;
        rdata_i.orn          = 64'd100;
        rdata_i.updated_orn  = 64'd200;
        rdata_i.side         = 1'b1;
        rdata_i.shares       = 32'd500;
        rdata_i.price        = 32'd1_500_100;
    endtask

    task automatic expect_forwarded_event(input logic [PRICE_W-1:0] expected_base_price);
        #1;
        if (!valid_stock0_o) begin
            $fatal(1, "Expected one routed valid pulse");
        end
        if (base_price_o !== expected_base_price) begin
            $fatal(1, "Base price mismatch: got %0d expected %0d", base_price_o, expected_base_price);
        end
        if ((rdata_o.message_type !== rdata_i.message_type) ||
            (rdata_o.orn          !== rdata_i.orn)          ||
            (rdata_o.updated_orn  !== rdata_i.updated_orn)  ||
            (rdata_o.side         !== rdata_i.side)         ||
            (rdata_o.shares       !== rdata_i.shares)       ||
            (rdata_o.price        !== rdata_i.price)) begin
            $fatal(1, "Routed event fields did not match the accepted input event");
        end
    endtask

    task automatic test_matching_locate();
        $display("TEST symbol_router forwards a matching locate");

        @(negedge clk);
        load_test_event(TARGET_LOCATE);
        ready_i = 1'b1;
        valid_i = 1'b1;

        #1;
        if (!ready_o) begin
            $fatal(1, "Matching event was not accepted while downstream was ready");
        end

        @(posedge clk);
        expect_forwarded_event(BASE_PRICE);

        @(negedge clk);
        valid_i = 1'b0;

        @(posedge clk);
        #1;
        if (valid_stock0_o) begin
            $fatal(1, "Routed valid was not a single-cycle pulse");
        end
    endtask

    task automatic test_non_matching_locate_drops_without_stall();
        $display("TEST symbol_router drops a non-matching locate without stalling ingress");

        @(negedge clk);
        load_test_event(TARGET_LOCATE + 16'd1);
        ready_i = 1'b0;
        valid_i = 1'b1;

        #1;
        if (!ready_o) begin
            $fatal(1, "Non-matching event incorrectly inherited downstream backpressure");
        end

        @(posedge clk);
        #1;
        if (valid_stock0_o) begin
            $fatal(1, "Non-matching event was incorrectly routed");
        end

        @(negedge clk);
        valid_i = 1'b0;
        ready_i = 1'b1;
    endtask

    task automatic test_matching_locate_honours_backpressure();
        $display("TEST symbol_router holds a matching event until downstream is ready");

        @(negedge clk);
        load_test_event(TARGET_LOCATE);
        ready_i = 1'b0;
        valid_i = 1'b1;

        repeat (3) begin
            #1;
            if (ready_o) begin
                $fatal(1, "Matching event was accepted while downstream was blocked");
            end
            @(posedge clk);
            #1;
            if (valid_stock0_o) begin
                $fatal(1, "Matching event was emitted before downstream became ready");
            end
            @(negedge clk);
        end

        ready_i = 1'b1;
        #1;
        if (!ready_o) begin
            $fatal(1, "Matching event did not become ready after downstream was released");
        end

        @(posedge clk);
        expect_forwarded_event(BASE_PRICE);

        @(negedge clk);
        valid_i = 1'b0;

        @(posedge clk);
        #1;
        if (valid_stock0_o) begin
            $fatal(1, "Backpressured event was emitted more than once");
        end
    endtask

    task automatic test_new_gpio_configuration_after_reset();
        logic [STOCK_W-1:0] new_locate;
        logic [PRICE_W-1:0] new_base_price;

        $display("TEST symbol_router uses a new AXI-GPIO configuration after reset");

        new_locate     = 16'd77;
        new_base_price = 32'd2_000_000;

        rst_n = 1'b0;
        valid_i = 1'b0;
        repeat (2) @(posedge clk);

        target_locate_i = new_locate;
        base_price_i    = new_base_price;
        rst_n           = 1'b1;
        repeat (2) @(posedge clk);

        @(negedge clk);
        load_test_event(new_locate);
        valid_i = 1'b1;
        ready_i = 1'b1;

        @(posedge clk);
        expect_forwarded_event(new_base_price);

        @(negedge clk);
        valid_i = 1'b0;
    endtask

    initial begin
        reset_dut();
        test_matching_locate();
        test_non_matching_locate_drops_without_stall();
        test_matching_locate_honours_backpressure();
        test_new_gpio_configuration_after_reset();

        repeat (3) @(posedge clk);
        $display("PASS: symbol_router_tb");
        $finish;
    end

endmodule

`default_nettype wire
