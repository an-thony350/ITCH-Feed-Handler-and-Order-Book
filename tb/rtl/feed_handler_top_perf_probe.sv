// Simulation-only probe wrapper for complete feed-handler performance tests.
//
// This module does not modify the production feed-handler RTL. It mirrors the
// feed_handler_top interface and exposes registered handshake pulses plus the
// internal book/FIFO boundaries required for cycle-accurate latency attribution.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module feed_handler_top_perf_probe #(
    parameter bit          CHECK_DST_PORT    = 1'b0,
    parameter logic [15:0] EXPECTED_DST_PORT = 16'd0
) (
    input  logic       clk,
    input  logic       rst_n,

    // Order-book base-price configuration.
    input  logic [PRICE_W-1:0] base_price_stock0_i,
    input  logic [PRICE_W-1:0] base_price_stock1_i,
    input  logic [PRICE_W-1:0] base_price_stock2_i,

    // AXI4-Stream Ethernet frame input.
    input  axis_data_t s_frame_tdata_i,
    input  axis_keep_t s_frame_tkeep_i,
    input  logic       s_frame_tvalid_i,
    input  logic       s_frame_tlast_i,
    output logic       s_frame_tready_o,

    // External BBO output.
    output bbo_t       bbo_data_o,
    output logic       bbo_valid_o,

    // MoldUDP64 metadata and sequence status.
    output logic [MOLD_SESSION_W-1:0] session_o,
    output logic [MOLD_SEQ_W-1:0]     seq_o,
    output logic [MOLD_COUNT_W-1:0]   count_o,
    output logic [MOLD_SEQ_W-1:0]     expected_next_o,
    output logic                      seq_valid_o,
    output logic                      heartbeat_o,
    output logic                      eos_o,
    output logic                      in_order_o,
    output logic                      duplicate_o,
    output logic                      gap_o,
    output logic                      stale_o,
    output logic [MOLD_SEQ_W-1:0]     expected_seq_o,
    output logic [MOLD_SEQ_W-1:0]     gap_start_o,
    output logic [MOLD_SEQ_W-1:0]     gap_end_o,

    // Ingress error/status outputs.
    output logic                     frame_drop_o,
    output logic [FRAME_ERR_W-1:0]   frame_err_o,
    output logic                     mold_drop_o,
    output logic [MOLD_ERR_W-1:0]    mold_err_o,
    output logic [REALIGN_ERR_W-1:0] realign_err_o,

    // Registered transfer pulses. Registering the pre-edge ready/valid result
    // avoids losing a handshake when the destination state changes on that edge.
    output logic       probe_frame_fire_o,
    output axis_keep_t probe_frame_keep_o,
    output logic       probe_frame_last_fire_o,

    output logic       probe_itch_fire_o,
    output logic       probe_itch_last_fire_o,

    output logic                    probe_decoded_fire_o,
    output logic [MSG_W-1:0]        probe_decoded_message_type_o,
    output logic [STOCK_W-1:0]      probe_decoded_stock_locate_o,
    output logic [ORN_W-1:0]        probe_decoded_orn_o,
    output logic [ORN_W-1:0]        probe_decoded_updated_orn_o,

    output logic probe_book_fire_stock0_o,
    output logic probe_book_fire_stock1_o,
    output logic probe_book_fire_stock2_o,

    // Direct stage state used for stall/busy accounting.
    output wire probe_itch_tvalid_o,
    output wire probe_itch_tready_o,
    output wire probe_decoded_valid_o,
    output wire probe_decoded_ready_o,
    output wire probe_book_ready_stock0_o,
    output wire probe_book_ready_stock1_o,
    output wire probe_book_ready_stock2_o,
    output wire probe_books_ready_o,

    // Individual-book completion and external scheduler/FIFO observation.
    output wire probe_internal_bbo_valid_stock0_o,
    output wire probe_internal_bbo_valid_stock1_o,
    output wire probe_internal_bbo_valid_stock2_o,
    output wire [1:0] probe_external_stock_id_o,

    output wire [3:0] probe_fifo_wr_ptr_stock0_o,
    output wire [3:0] probe_fifo_wr_ptr_stock1_o,
    output wire [3:0] probe_fifo_wr_ptr_stock2_o,
    output wire [3:0] probe_fifo_rd_ptr_stock0_o,
    output wire [3:0] probe_fifo_rd_ptr_stock1_o,
    output wire [3:0] probe_fifo_rd_ptr_stock2_o,
    output wire [2:0] probe_scheduler_count_o
);

    feed_handler_top #(
        .CHECK_DST_PORT    (CHECK_DST_PORT),
        .EXPECTED_DST_PORT (EXPECTED_DST_PORT)
    ) dut (
        .clk                     (clk),
        .rst_n                   (rst_n),

        .base_price_stock0_i     (base_price_stock0_i),
        .base_price_stock1_i     (base_price_stock1_i),
        .base_price_stock2_i     (base_price_stock2_i),

        .s_frame_tdata_i         (s_frame_tdata_i),
        .s_frame_tkeep_i         (s_frame_tkeep_i),
        .s_frame_tvalid_i        (s_frame_tvalid_i),
        .s_frame_tlast_i         (s_frame_tlast_i),
        .s_frame_tready_o        (s_frame_tready_o),

        .bbo_data_o              (bbo_data_o),
        .bbo_valid_o             (bbo_valid_o),

        .session_o               (session_o),
        .seq_o                   (seq_o),
        .count_o                 (count_o),
        .expected_next_o         (expected_next_o),
        .seq_valid_o             (seq_valid_o),
        .heartbeat_o             (heartbeat_o),
        .eos_o                   (eos_o),
        .in_order_o              (in_order_o),
        .duplicate_o             (duplicate_o),
        .gap_o                   (gap_o),
        .stale_o                 (stale_o),
        .expected_seq_o          (expected_seq_o),
        .gap_start_o             (gap_start_o),
        .gap_end_o               (gap_end_o),

        .frame_drop_o            (frame_drop_o),
        .frame_err_o             (frame_err_o),
        .mold_drop_o             (mold_drop_o),
        .mold_err_o              (mold_err_o),
        .realign_err_o           (realign_err_o)
    );

    // Ready/valid and book state are observed only; no probe drives the DUT.
    assign probe_itch_tvalid_o   = dut.itch_tvalid;
    assign probe_itch_tready_o   = dut.itch_tready;
    assign probe_decoded_valid_o = dut.decoded_valid;
    assign probe_decoded_ready_o = dut.decoded_ready;

    assign probe_book_ready_stock0_o =
        dut.u_order_book_top.ob_sr_ready_bus[1];
    assign probe_book_ready_stock1_o =
        dut.u_order_book_top.ob_sr_ready_bus[2];
    assign probe_book_ready_stock2_o =
        dut.u_order_book_top.ob_sr_ready_bus[3];
    assign probe_books_ready_o =
        &dut.u_order_book_top.ob_sr_ready_bus[3:1];

    assign probe_internal_bbo_valid_stock0_o =
        dut.u_order_book_top.bbo_valid_0;
    assign probe_internal_bbo_valid_stock1_o =
        dut.u_order_book_top.bbo_valid_1;
    assign probe_internal_bbo_valid_stock2_o =
        dut.u_order_book_top.bbo_valid_2;

    assign probe_external_stock_id_o = bbo_data_o.stock_id;

    assign probe_fifo_wr_ptr_stock0_o = dut.u_order_book_top.wr_ptr_0;
    assign probe_fifo_wr_ptr_stock1_o = dut.u_order_book_top.wr_ptr_1;
    assign probe_fifo_wr_ptr_stock2_o = dut.u_order_book_top.wr_ptr_2;
    assign probe_fifo_rd_ptr_stock0_o = dut.u_order_book_top.rd_ptr_0;
    assign probe_fifo_rd_ptr_stock1_o = dut.u_order_book_top.rd_ptr_1;
    assign probe_fifo_rd_ptr_stock2_o = dut.u_order_book_top.rd_ptr_2;
    assign probe_scheduler_count_o    = dut.u_order_book_top.count;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            probe_frame_fire_o             <= 1'b0;
            probe_frame_keep_o             <= '0;
            probe_frame_last_fire_o        <= 1'b0;
            probe_itch_fire_o              <= 1'b0;
            probe_itch_last_fire_o         <= 1'b0;
            probe_decoded_fire_o           <= 1'b0;
            probe_decoded_message_type_o   <= '0;
            probe_decoded_stock_locate_o   <= '0;
            probe_decoded_orn_o            <= '0;
            probe_decoded_updated_orn_o    <= '0;
            probe_book_fire_stock0_o       <= 1'b0;
            probe_book_fire_stock1_o       <= 1'b0;
            probe_book_fire_stock2_o       <= 1'b0;
        end
        else begin
            probe_frame_fire_o <=
                s_frame_tvalid_i && s_frame_tready_o;
            probe_frame_last_fire_o <=
                s_frame_tvalid_i && s_frame_tready_o && s_frame_tlast_i;

            if(s_frame_tvalid_i && s_frame_tready_o) begin
                probe_frame_keep_o <= s_frame_tkeep_i;
            end

            probe_itch_fire_o <=
                dut.itch_tvalid && dut.itch_tready;
            probe_itch_last_fire_o <=
                dut.itch_tvalid && dut.itch_tready && dut.itch_tlast;

            probe_decoded_fire_o <=
                dut.decoded_valid && dut.decoded_ready;

            if(dut.decoded_valid && dut.decoded_ready) begin
                probe_decoded_message_type_o <=
                    dut.decoded_data.message_type;
                probe_decoded_stock_locate_o <=
                    dut.decoded_data.stock_locate;
                probe_decoded_orn_o <=
                    dut.decoded_data.orn;
                probe_decoded_updated_orn_o <=
                    dut.decoded_data.updated_orn;
            end

            probe_book_fire_stock0_o <=
                dut.u_order_book_top.sr_ob_valid_stock0 &&
                dut.u_order_book_top.ob_sr_ready_bus[1];
            probe_book_fire_stock1_o <=
                dut.u_order_book_top.sr_ob_valid_stock1 &&
                dut.u_order_book_top.ob_sr_ready_bus[2];
            probe_book_fire_stock2_o <=
                dut.u_order_book_top.sr_ob_valid_stock2 &&
                dut.u_order_book_top.ob_sr_ready_bus[3];
        end
    end

endmodule

`default_nettype wire
