`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module order_book_top_tb;

    localparam logic [STOCK_W-1:0] TARGET_LOCATE = 16'd42;
    localparam logic [PRICE_W-1:0] BASE_PRICE    = 32'd1_500_000;

    logic                   clk;
    logic                   rst_n;
    logic [STOCK_W-1:0]     target_locate_i;
    logic [PRICE_W-1:0]     base_price_i;
    data_t                  rdata_i;
    logic                   valid_i;
    logic                   ready_o;
    bbo_t                   bbo_data_o;
    logic                   bbo_valid_o;

    int unsigned bbo_pulses;
    bbo_t       last_bbo;

    order_book_top dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .target_locate_i (target_locate_i),
        .base_price_i    (base_price_i),
        .rdata_i         (rdata_i),
        .valid_i         (valid_i),
        .ready_o         (ready_o),
        .bbo_data_o      (bbo_data_o),
        .bbo_valid_o     (bbo_valid_o)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bbo_pulses <= 0;
            last_bbo   <= '0;
        end
        else if (bbo_valid_o) begin
            bbo_pulses <= bbo_pulses + 1;
            last_bbo   <= bbo_data_o;
        end
    end

    task automatic reset_dut();
        int unsigned cycles;

        rst_n           = 1'b0;
        target_locate_i = TARGET_LOCATE;
        base_price_i    = BASE_PRICE;
        rdata_i         = '0;
        valid_i         = 1'b0;

        repeat (6) @(posedge clk);
        rst_n = 1'b1;

        // order_book_top.ready_o may be high while valid_i is low even though the
        // book is still clearing. Wait for the actual downstream book-ready signal.
        cycles = 0;
        while (!dut.sr_ob_ready && (cycles < 5000)) begin
            cycles++;
            @(posedge clk);
        end
        if (!dut.sr_ob_ready) begin
            $fatal(1, "Timed out waiting for the order book to finish clearing");
        end

        repeat (2) @(posedge clk);
    endtask

    task automatic make_add_event(
        input logic [STOCK_W-1:0]  locate,
        input logic [ORN_W-1:0]    orn,
        input logic                side,
        input logic [SHARES_W-1:0] shares,
        input logic [PRICE_W-1:0]  price,
        output data_t              evt
    );
        evt.message_type = 8'h41;
        evt.stock_locate = locate;
        evt.orn          = orn;
        evt.updated_orn  = '0;
        evt.side         = side;
        evt.shares       = shares;
        evt.price        = price;
    endtask

    task automatic send_event(input data_t evt);
        int unsigned cycles;

        @(negedge clk);
        rdata_i = evt;
        valid_i = 1'b1;

        cycles = 0;
        do begin
            @(posedge clk);
            cycles++;
            if (cycles >= 5000) begin
                $fatal(1, "Timed out waiting for order_book_top.ready_o");
            end
        end while (!ready_o);

        // valid_i and ready_o were both asserted on the rising edge above.
        @(negedge clk);
        valid_i = 1'b0;
        rdata_i = '0;
    endtask

    task automatic wait_for_bbo_count(input int unsigned target);
        int unsigned cycles;

        cycles = 0;
        while ((bbo_pulses < target) && (cycles < 5000)) begin
            cycles++;
            @(posedge clk);
        end
        if (bbo_pulses < target) begin
            $fatal(1, "Timed out waiting for BBO pulse %0d; saw %0d", target, bbo_pulses);
        end
        #1;
    endtask

    task automatic expect_bbo(
        input logic [PRICE_W-1:0]  bid_price,
        input logic [SHARES_W-1:0] bid_shares,
        input logic [PRICE_W-1:0]  ask_price,
        input logic [SHARES_W-1:0] ask_shares
    );
        if ((last_bbo.bid_price  !== bid_price)  ||
            (last_bbo.bid_shares !== bid_shares) ||
            (last_bbo.ask_price  !== ask_price)  ||
            (last_bbo.ask_shares !== ask_shares)) begin
            $fatal(1,
                "BBO mismatch: got bid=%0d@%0d ask=%0d@%0d expected bid=%0d@%0d ask=%0d@%0d",
                last_bbo.bid_shares, last_bbo.bid_price,
                last_bbo.ask_shares, last_bbo.ask_price,
                bid_shares, bid_price, ask_shares, ask_price
            );
        end
    endtask

    initial begin
        data_t evt;
        int unsigned pulses_before;

        reset_dut();

        $display("TEST order_book_top drops non-target symbols");
        make_add_event(16'd99, 64'd1, 1'b1, 32'd900, BASE_PRICE + 32'd50, evt);
        pulses_before = bbo_pulses;
        send_event(evt);
        repeat (100) @(posedge clk);
        if (bbo_pulses != pulses_before) begin
            $fatal(1, "Non-target event mutated the order book");
        end

        $display("TEST order_book_top forwards configured base price for a target bid");
        make_add_event(TARGET_LOCATE, 64'd100, 1'b1, 32'd500, BASE_PRICE + 32'd100, evt);
        send_event(evt);
        wait_for_bbo_count(pulses_before + 1);
        expect_bbo(BASE_PRICE + 32'd100, 32'd500, 32'd0, 32'd0);

        $display("TEST order_book_top routes a target ask into the same book");
        make_add_event(TARGET_LOCATE, 64'd101, 1'b0, 32'd250, BASE_PRICE + 32'd200, evt);
        send_event(evt);
        wait_for_bbo_count(pulses_before + 2);
        expect_bbo(BASE_PRICE + 32'd100, 32'd500,
                   BASE_PRICE + 32'd200, 32'd250);

        $display("PASS: order_book_top_tb");
        $finish;
    end

endmodule

`default_nettype wire
