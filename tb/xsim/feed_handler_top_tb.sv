`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module feed_handler_top_tb;

    localparam logic [MOLD_SESSION_W-1:0] TEST_SESSION  = 80'h49_54_43_48_54_45_53_54_30_31; // "ITCHTEST01"
    localparam logic [15:0]               TEST_SRC_PORT = 16'd40000;
    localparam logic [15:0]               TEST_DST_PORT = 16'd50000;

    // The PS notebook filters the selected symbol and rewrites its locate to 1.
    // Prices and base price are both in cents after the notebook's Price(4) / 100 conversion.
    localparam logic [STOCK_W-1:0] ROUTED_LOCATE = 16'd1;
    localparam logic [PRICE_W-1:0] BASE_PRICE    = 32'd28_000;

    logic       clk;
    logic       rst_n;

    logic [PRICE_W-1:0] base_price_i;

    axis_data_t s_frame_tdata_i;
    axis_keep_t s_frame_tkeep_i;
    logic       s_frame_tvalid_i;
    logic       s_frame_tlast_i;
    logic       s_frame_tready_o;

    bbo_t       bbo_data_o;
    logic       bbo_valid_o;

    logic [MOLD_SESSION_W-1:0] session_o;
    logic [MOLD_SEQ_W-1:0]     seq_o;
    logic [MOLD_COUNT_W-1:0]   count_o;
    logic [MOLD_SEQ_W-1:0]     expected_next_o;
    logic                      seq_valid_o;
    logic                      heartbeat_o;
    logic                      eos_o;
    logic                      in_order_o;
    logic                      duplicate_o;
    logic                      gap_o;
    logic                      stale_o;
    logic [MOLD_SEQ_W-1:0]     expected_seq_o;
    logic [MOLD_SEQ_W-1:0]     gap_start_o;
    logic [MOLD_SEQ_W-1:0]     gap_end_o;

    logic                      frame_drop_o;
    logic [FRAME_ERR_W-1:0]    frame_err_o;
    logic                      mold_drop_o;
    logic [MOLD_ERR_W-1:0]     mold_err_o;
    logic [REALIGN_ERR_W-1:0]  realign_err_o;

    int unsigned bbo_pulses;
    int unsigned duplicate_pulses;
    int unsigned gap_pulses;
    logic        error_seen;
    bbo_t        last_bbo;

    feed_handler_top #(
        .CHECK_DST_PORT    (1'b0),
        .EXPECTED_DST_PORT (16'd0)
    ) dut (
        .clk               (clk),
        .rst_n             (rst_n),

        .base_price_i      (base_price_i),

        .s_frame_tdata_i   (s_frame_tdata_i),
        .s_frame_tkeep_i   (s_frame_tkeep_i),
        .s_frame_tvalid_i  (s_frame_tvalid_i),
        .s_frame_tlast_i   (s_frame_tlast_i),
        .s_frame_tready_o  (s_frame_tready_o),

        .bbo_data_o        (bbo_data_o),
        .bbo_valid_o       (bbo_valid_o),

        .session_o         (session_o),
        .seq_o             (seq_o),
        .count_o           (count_o),
        .expected_next_o   (expected_next_o),
        .seq_valid_o       (seq_valid_o),
        .heartbeat_o       (heartbeat_o),
        .eos_o             (eos_o),
        .in_order_o        (in_order_o),
        .duplicate_o       (duplicate_o),
        .gap_o             (gap_o),
        .stale_o           (stale_o),
        .expected_seq_o    (expected_seq_o),
        .gap_start_o       (gap_start_o),
        .gap_end_o         (gap_end_o),

        .frame_drop_o      (frame_drop_o),
        .frame_err_o       (frame_err_o),
        .mold_drop_o       (mold_drop_o),
        .mold_err_o        (mold_err_o),
        .realign_err_o     (realign_err_o)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bbo_pulses       <= 0;
            duplicate_pulses <= 0;
            gap_pulses       <= 0;
            error_seen       <= 1'b0;
            last_bbo         <= '0;
        end
        else begin
            if (bbo_valid_o) begin
                bbo_pulses <= bbo_pulses + 1;
                last_bbo   <= bbo_data_o;
            end
            if (duplicate_o) begin
                duplicate_pulses <= duplicate_pulses + 1;
            end
            if (gap_o) begin
                gap_pulses <= gap_pulses + 1;
            end
            if (frame_drop_o || mold_drop_o || (realign_err_o != '0)) begin
                error_seen <= 1'b1;
            end
        end
    end

    task automatic reset_dut();
        int unsigned cycles;

        rst_n              = 1'b0;
        base_price_i       = BASE_PRICE;
        s_frame_tdata_i    = '0;
        s_frame_tkeep_i    = '0;
        s_frame_tvalid_i   = 1'b0;
        s_frame_tlast_i    = 1'b0;

        repeat (8) @(posedge clk);
        rst_n = 1'b1;

        // Wait for the order-book memory clear inside order_book_top before
        // injecting traffic. ready_o can be high for an invalid input while clear runs.
        cycles = 0;
        while (!dut.u_order_book_top.sr_ob_ready && (cycles < 5000)) begin
            cycles++;
            @(posedge clk);
        end
        if (!dut.u_order_book_top.sr_ob_ready) begin
            $fatal(1, "Timed out waiting for the order book to become ready");
        end

        repeat (2) @(posedge clk);
    endtask

    task automatic write_u16_be(
        ref byte unsigned data[],
        ref int unsigned  idx,
        input logic [15:0] value
    );
        data[idx] = value[15:8]; idx++;
        data[idx] = value[7:0];  idx++;
    endtask

    task automatic write_u32_be(
        ref byte unsigned data[],
        ref int unsigned  idx,
        input logic [31:0] value
    );
        for (int byte_idx = 3; byte_idx >= 0; byte_idx--) begin
            data[idx] = value[8*byte_idx +: 8];
            idx++;
        end
    endtask

    task automatic write_u48_be(
        ref byte unsigned data[],
        ref int unsigned  idx,
        input logic [47:0] value
    );
        for (int byte_idx = 5; byte_idx >= 0; byte_idx--) begin
            data[idx] = value[8*byte_idx +: 8];
            idx++;
        end
    endtask

    task automatic write_u64_be(
        ref byte unsigned data[],
        ref int unsigned  idx,
        input logic [63:0] value
    );
        for (int byte_idx = 7; byte_idx >= 0; byte_idx--) begin
            data[idx] = value[8*byte_idx +: 8];
            idx++;
        end
    endtask

    task automatic write_session(
        ref byte unsigned data[],
        ref int unsigned  idx,
        input logic [MOLD_SESSION_W-1:0] session
    );
        for (int byte_idx = 0; byte_idx < MOLD_SESSION_BYTES; byte_idx++) begin
            data[idx] = session[MOLD_SESSION_W-1-(8*byte_idx) -: 8];
            idx++;
        end
    endtask

    task automatic build_add_message(
        input  logic [STOCK_W-1:0]  locate,
        input  logic [ORN_W-1:0]    orn,
        input  logic                side,
        input  logic [SHARES_W-1:0] shares,
        input  logic [PRICE_W-1:0]  price,
        output byte unsigned        msg[]
    );
        int unsigned idx;

        msg = new[36];
        idx = 0;

        msg[idx] = 8'h41; idx++;             // Message type A
        write_u16_be(msg, idx, locate);      // Stock locate
        write_u16_be(msg, idx, 16'd1);       // Tracking number
        write_u48_be(msg, idx, 48'd1);       // Timestamp
        write_u64_be(msg, idx, orn);         // Order reference number
        msg[idx] = side ? 8'h42 : 8'h53;      // B or S
        idx++;
        write_u32_be(msg, idx, shares);

        // Eight-byte stock symbol: "TEST    "
        msg[idx] = 8'h54; idx++;
        msg[idx] = 8'h45; idx++;
        msg[idx] = 8'h53; idx++;
        msg[idx] = 8'h54; idx++;
        repeat (4) begin
            msg[idx] = 8'h20;
            idx++;
        end

        write_u32_be(msg, idx, price);

        if (idx != msg.size()) begin
            $fatal(1, "ITCH Add builder size mismatch: idx=%0d size=%0d", idx, msg.size());
        end
    endtask

    task automatic build_one_msg_dgram(
        input  logic [MOLD_SEQ_W-1:0] seq,
        input  byte unsigned          msg0[],
        output byte unsigned          dgram[]
    );
        int unsigned idx;

        dgram = new[MOLD_HDR_BYTES + 2 + msg0.size()];
        idx = 0;

        write_session(dgram, idx, TEST_SESSION);
        write_u64_be(dgram, idx, seq);
        write_u16_be(dgram, idx, 16'd1);
        write_u16_be(dgram, idx, 16'(msg0.size()));

        foreach (msg0[i]) begin
            dgram[idx] = msg0[i];
            idx++;
        end
    endtask

    task automatic build_two_msg_dgram(
        input  logic [MOLD_SEQ_W-1:0] seq,
        input  byte unsigned          msg0[],
        input  byte unsigned          msg1[],
        output byte unsigned          dgram[]
    );
        int unsigned idx;

        dgram = new[MOLD_HDR_BYTES + 2 + msg0.size() + 2 + msg1.size()];
        idx = 0;

        write_session(dgram, idx, TEST_SESSION);
        write_u64_be(dgram, idx, seq);
        write_u16_be(dgram, idx, 16'd2);
        write_u16_be(dgram, idx, 16'(msg0.size()));
        foreach (msg0[i]) begin
            dgram[idx] = msg0[i];
            idx++;
        end

        write_u16_be(dgram, idx, 16'(msg1.size()));
        foreach (msg1[i]) begin
            dgram[idx] = msg1[i];
            idx++;
        end
    endtask

    task automatic build_eth_ipv4_udp_frame(
        input  byte unsigned dgram[],
        output byte unsigned frame[]
    );
        int unsigned idx;
        logic [15:0] udp_len_v;
        logic [15:0] ip_total_len_v;

        udp_len_v      = UDP_HDR_BYTES + dgram.size();
        ip_total_len_v = IPV4_MIN_HDR_BYTES + udp_len_v;
        frame          = new[L2_L4_HDR_BYTES + dgram.size()];
        idx            = 0;

        // Ethernet II destination and source MACs.
        for (int i = 0; i < 6; i++) begin
            frame[idx] = 8'h01 + i;
            idx++;
        end
        for (int i = 0; i < 6; i++) begin
            frame[idx] = 8'h0a + i;
            idx++;
        end
        write_u16_be(frame, idx, ETHERTYPE_IPV4);

        // IPv4, IHL=5, unfragmented, protocol UDP. Checksums are zero.
        frame[idx] = 8'h45; idx++;
        frame[idx] = 8'h00; idx++;
        write_u16_be(frame, idx, ip_total_len_v);
        write_u16_be(frame, idx, 16'h0001);
        write_u16_be(frame, idx, 16'h0000);
        frame[idx] = 8'd64; idx++;
        frame[idx] = IP_PROTO_UDP; idx++;
        write_u16_be(frame, idx, 16'h0000);

        frame[idx] = 8'h0a; idx++;
        frame[idx] = 8'h00; idx++;
        frame[idx] = 8'h00; idx++;
        frame[idx] = 8'h01; idx++;
        frame[idx] = 8'h0a; idx++;
        frame[idx] = 8'h00; idx++;
        frame[idx] = 8'h00; idx++;
        frame[idx] = 8'h02; idx++;

        // UDP header.
        write_u16_be(frame, idx, TEST_SRC_PORT);
        write_u16_be(frame, idx, TEST_DST_PORT);
        write_u16_be(frame, idx, udp_len_v);
        write_u16_be(frame, idx, 16'h0000);

        foreach (dgram[i]) begin
            frame[idx] = dgram[i];
            idx++;
        end

        if (idx != frame.size()) begin
            $fatal(1, "Frame builder size mismatch: idx=%0d size=%0d", idx, frame.size());
        end
    endtask

    task automatic send_frame(input byte unsigned frame[]);
        int unsigned offset;
        int unsigned wait_cycles;
        axis_data_t  beat_data;
        axis_keep_t  beat_keep;

        offset = 0;

        while (offset < frame.size()) begin
            beat_data = '0;
            beat_keep = '0;

            for (int lane = 0; lane < AXIS_KEEP_W; lane++) begin
                if ((offset + lane) < frame.size()) begin
                    beat_data[AXIS_DATA_W-1-(8*lane) -: 8] = frame[offset+lane];
                    beat_keep[AXIS_KEEP_W-1-lane]          = 1'b1;
                end
            end

            @(negedge clk);
            s_frame_tdata_i  = beat_data;
            s_frame_tkeep_i  = beat_keep;
            s_frame_tlast_i  = ((offset + AXIS_KEEP_W) >= frame.size());
            s_frame_tvalid_i = 1'b1;

            wait_cycles = 0;
            do begin
                @(posedge clk);
                wait_cycles++;
                if (wait_cycles >= 10000) begin
                    $fatal(1, "Timed out waiting for s_frame_tready_o");
                end
            end while (!s_frame_tready_o);

            // tvalid and tready were both asserted on the rising edge above.
            offset += AXIS_KEEP_W;
        end

        @(negedge clk);
        s_frame_tvalid_i = 1'b0;
        s_frame_tlast_i  = 1'b0;
        s_frame_tdata_i  = '0;
        s_frame_tkeep_i  = '0;
    endtask

    task automatic wait_for_bbo_count(input int unsigned target);
        int unsigned cycles;

        cycles = 0;
        while ((bbo_pulses < target) && (cycles < 20000)) begin
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

    task automatic expect_no_errors();
        if (error_seen) begin
            $fatal(1,
                "Unexpected ingress error: frame_drop=%0b frame_err=0x%04x mold_drop=%0b mold_err=0x%04x realign_err=0x%04x",
                frame_drop_o, frame_err_o, mold_drop_o, mold_err_o, realign_err_o
            );
        end
    endtask

    initial begin
        byte unsigned bid_msg[];
        byte unsigned ask_msg[];
        byte unsigned non_target_msg[];
        byte unsigned higher_bid_msg[];
        byte unsigned dgram[];
        byte unsigned frame[];
        int unsigned  pulses_before;

        reset_dut();

        $display("TEST feed_handler_top frame -> ingress -> decoder -> order_book_top");
        build_add_message(ROUTED_LOCATE, 64'd100, 1'b1, 32'd500,
                          BASE_PRICE + 32'd1, bid_msg);
        build_add_message(ROUTED_LOCATE, 64'd101, 1'b0, 32'd250,
                          BASE_PRICE + 32'd2, ask_msg);
        build_two_msg_dgram(64'd100, bid_msg, ask_msg, dgram);
        build_eth_ipv4_udp_frame(dgram, frame);

        send_frame(frame);
        wait_for_bbo_count(2);
        expect_bbo(BASE_PRICE + 32'd1, 32'd500,
                   BASE_PRICE + 32'd2, 32'd250);
        expect_no_errors();

        $display("TEST feed_handler_top duplicate packet creates no extra book updates");
        pulses_before = bbo_pulses;
        send_frame(frame);
        repeat (200) @(posedge clk);
        if (bbo_pulses != pulses_before) begin
            $fatal(1, "Duplicate packet produced an extra BBO update");
        end
        if (duplicate_pulses != 1) begin
            $fatal(1, "Expected one duplicate pulse, saw %0d", duplicate_pulses);
        end

        $display("TEST feed_handler_top accepts but filters a non-1 symbol locate");
        build_add_message(16'd2, 64'd200, 1'b1, 32'd900,
                          BASE_PRICE + 32'd3, non_target_msg);
        build_one_msg_dgram(64'd102, non_target_msg, dgram);
        build_eth_ipv4_udp_frame(dgram, frame);

        send_frame(frame);
        repeat (300) @(posedge clk);
        if (bbo_pulses != pulses_before) begin
            $fatal(1, "Non-target ITCH message mutated the order book");
        end

        $display("TEST feed_handler_top continues after the filtered symbol");
        build_add_message(ROUTED_LOCATE, 64'd102, 1'b1, 32'd100,
                          BASE_PRICE + 32'd2, higher_bid_msg);
        build_one_msg_dgram(64'd103, higher_bid_msg, dgram);
        build_eth_ipv4_udp_frame(dgram, frame);

        send_frame(frame);
        wait_for_bbo_count(pulses_before + 1);
        expect_bbo(BASE_PRICE + 32'd2, 32'd100,
                   BASE_PRICE + 32'd2, 32'd250);

        if (expected_seq_o !== 64'd104) begin
            $fatal(1, "Expected next sequence 104, got %0d", expected_seq_o);
        end
        if (gap_pulses != 0 || stale_o) begin
            $fatal(1, "Clean smoke test unexpectedly entered gap/stale state");
        end
        expect_no_errors();

        $display("PASS: feed_handler_top_tb");
        $finish;
    end

endmodule

`default_nettype wire
