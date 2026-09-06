// Simulation-only dual-clock performance probe for the pre-Taxi datapath.
//
// This wrapper mirrors the current ZCU106 clock partition:
//   ingress + data_handler : network clk
//   normalised event FIFO  : asynchronous CDC
//   order_book_top         : data clk
//   order-book BRAM        : 2x data clk
//
// Production RTL is instantiated unchanged. The only non-production block is
// event_async_fifo_sim, which replaces the Xilinx XPM primitive for Verilator.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module line_rate_perf_probe #(
    parameter bit          CHECK_DST_PORT    = 1'b0,
    parameter logic [15:0] EXPECTED_DST_PORT = 16'd0
) (
    // Keep the network clock named clk so the existing continuous AXI driver can
    // be reused without adding a second source driver implementation.
    input  logic       clk,
    input  logic       data_clk,
    input  logic       bram_clk,
    input  logic       rst_n,

    input  logic [PRICE_W-1:0] base_price_stock0_i,
    input  logic [PRICE_W-1:0] base_price_stock1_i,
    input  logic [PRICE_W-1:0] base_price_stock2_i,

    input  axis_data_t s_frame_tdata_i,
    input  axis_keep_t s_frame_tkeep_i,
    input  logic       s_frame_tvalid_i,
    input  logic       s_frame_tlast_i,
    output logic       s_frame_tready_o,

    output bbo_t       bbo_data_o,
    output logic       bbo_valid_o,

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

    output logic                     frame_drop_o,
    output logic [FRAME_ERR_W-1:0]   frame_err_o,
    output logic                     mold_drop_o,
    output logic [MOLD_ERR_W-1:0]    mold_err_o,
    output logic [REALIGN_ERR_W-1:0] realign_err_o,

    // Direct ready/valid visibility for stall attribution.
    output wire probe_dgram_tvalid_o,
    output wire probe_dgram_tready_o,
    output wire probe_payload_tvalid_o,
    output wire probe_payload_tready_o,
    output wire probe_msg_len_valid_o,
    output wire probe_msg_len_ready_o,
    output wire probe_itch_tvalid_o,
    output wire probe_itch_tready_o,
    output wire probe_decoded_valid_o,
    output wire probe_decoded_ready_o,
    output wire probe_fifo_m_valid_o,
    output wire probe_fifo_m_ready_o,

    output wire probe_book_ready_stock0_o,
    output wire probe_book_ready_stock1_o,
    output wire probe_book_ready_stock2_o,
    output wire probe_books_ready_o,

    output wire probe_internal_bbo_valid_stock0_o,
    output wire probe_internal_bbo_valid_stock1_o,
    output wire probe_internal_bbo_valid_stock2_o,
    output wire [1:0] probe_external_stock_id_o,

    output wire [4:0] probe_event_fifo_wr_level_o,
    output wire       probe_event_fifo_full_o,
    output wire       probe_event_fifo_empty_o,

    output wire probe_bbo_fifo_empty_stock0_o,
    output wire probe_bbo_fifo_empty_stock1_o,
    output wire probe_bbo_fifo_empty_stock2_o,

    // Registered network-domain handshakes.
    output logic       probe_frame_fire_o,
    output axis_keep_t probe_frame_keep_o,
    output logic       probe_frame_last_fire_o,

    output logic       probe_dgram_fire_o,
    output axis_keep_t probe_dgram_keep_o,
    output logic       probe_payload_fire_o,
    output axis_keep_t probe_payload_keep_o,
    output logic       probe_msg_len_fire_o,
    output logic       probe_itch_fire_o,
    output axis_keep_t probe_itch_keep_o,
    output logic       probe_itch_last_fire_o,
    output logic       probe_decoded_fire_o,
    output logic [MSG_W-1:0] probe_decoded_message_type_o,

    // Registered data-domain event-FIFO consumption.
    output logic probe_fifo_read_fire_o
);

    // ingress_top -> data_handler
    axis_data_t itch_tdata;
    axis_keep_t itch_tkeep;
    logic       itch_tvalid;
    logic       itch_tlast;
    logic       itch_tready;

    // data_handler -> event FIFO
    data_t decoded_data;
    logic  decoded_valid;
    logic  decoded_ready;

    // event FIFO -> order_book_top
    data_t fifo_data;
    logic  fifo_valid;
    logic  fifo_ready;

    ingress_top #(
        .CHECK_DST_PORT    (CHECK_DST_PORT),
        .EXPECTED_DST_PORT (EXPECTED_DST_PORT)
    ) u_ingress_top (
        .clk               (clk),
        .rst_n             (rst_n),

        .s_frame_tdata_i   (s_frame_tdata_i),
        .s_frame_tkeep_i   (s_frame_tkeep_i),
        .s_frame_tvalid_i  (s_frame_tvalid_i),
        .s_frame_tlast_i   (s_frame_tlast_i),
        .s_frame_tready_o  (s_frame_tready_o),

        .m_itch_tdata_o    (itch_tdata),
        .m_itch_tkeep_o    (itch_tkeep),
        .m_itch_tvalid_o   (itch_tvalid),
        .m_itch_tlast_o    (itch_tlast),
        .m_itch_tready_i   (itch_tready),

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

    data_handler #(
        .PACKET_W (AXIS_DATA_W)
    ) u_data_handler (
        .clk        (clk),
        .rst_n      (rst_n),

        .s_tdata_i  (itch_tdata),
        .s_tvalid_i (itch_tvalid),
        .s_tlast_i  (itch_tlast),
        .s_tready_o (itch_tready),

        .ready_i    (decoded_ready),
        .rdata_o    (decoded_data),
        .valid_o    (decoded_valid)
    );

    event_async_fifo_sim #(
        .EVENT_W    (217),
        .FIFO_DEPTH (16)
    ) u_event_fifo (
        .wr_clk_i    (clk),
        .rst_i       (!rst_n),
        .s_data_i    (decoded_data),
        .s_valid_i   (decoded_valid),
        .s_ready_o   (decoded_ready),

        .rd_clk_i    (data_clk),
        .m_data_o    (fifo_data),
        .m_valid_o   (fifo_valid),
        .m_ready_i   (fifo_ready),

        .wr_level_o  (probe_event_fifo_wr_level_o),
        .full_o      (probe_event_fifo_full_o),
        .empty_o     (probe_event_fifo_empty_o)
    );

    order_book_top u_order_book_top (
        .clk                   (data_clk),
        .bram_clk              (bram_clk),
        .rst_n                 (rst_n),

        .base_price_stock0_i   (base_price_stock0_i),
        .base_price_stock1_i   (base_price_stock1_i),
        .base_price_stock2_i   (base_price_stock2_i),

        .rdata_i               (fifo_data),
        .valid_i               (fifo_valid),
        .ready_o               (fifo_ready),

        .bbo_data_o            (bbo_data_o),
        .bbo_valid_o           (bbo_valid_o)
    );

    // Ingress internal boundaries.
    assign probe_dgram_tvalid_o  = u_ingress_top.dgram_tvalid;
    assign probe_dgram_tready_o  = u_ingress_top.dgram_tready;
    assign probe_payload_tvalid_o = u_ingress_top.payload_tvalid;
    assign probe_payload_tready_o = u_ingress_top.payload_tready;
    assign probe_msg_len_valid_o  = u_ingress_top.msg_len_valid;
    assign probe_msg_len_ready_o  = u_ingress_top.msg_len_ready;

    assign probe_itch_tvalid_o    = itch_tvalid;
    assign probe_itch_tready_o    = itch_tready;
    assign probe_decoded_valid_o  = decoded_valid;
    assign probe_decoded_ready_o  = decoded_ready;
    assign probe_fifo_m_valid_o   = fifo_valid;
    assign probe_fifo_m_ready_o   = fifo_ready;

    assign probe_book_ready_stock0_o =
        u_order_book_top.ob_sr_ready_bus[1];
    assign probe_book_ready_stock1_o =
        u_order_book_top.ob_sr_ready_bus[2];
    assign probe_book_ready_stock2_o =
        u_order_book_top.ob_sr_ready_bus[3];
    assign probe_books_ready_o =
        &u_order_book_top.ob_sr_ready_bus[3:1];

    assign probe_internal_bbo_valid_stock0_o = u_order_book_top.bbo_valid_0;
    assign probe_internal_bbo_valid_stock1_o = u_order_book_top.bbo_valid_1;
    assign probe_internal_bbo_valid_stock2_o = u_order_book_top.bbo_valid_2;
    assign probe_external_stock_id_o = bbo_data_o.stock_id;

    assign probe_bbo_fifo_empty_stock0_o = u_order_book_top.empty_0;
    assign probe_bbo_fifo_empty_stock1_o = u_order_book_top.empty_1;
    assign probe_bbo_fifo_empty_stock2_o = u_order_book_top.empty_2;

    // Register pre-edge network-domain transfer results so the monitor sees the
    // handshake even if the destination changes state on the same active edge.
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            probe_frame_fire_o           <= 1'b0;
            probe_frame_keep_o           <= '0;
            probe_frame_last_fire_o      <= 1'b0;
            probe_dgram_fire_o           <= 1'b0;
            probe_dgram_keep_o           <= '0;
            probe_payload_fire_o         <= 1'b0;
            probe_payload_keep_o         <= '0;
            probe_msg_len_fire_o         <= 1'b0;
            probe_itch_fire_o            <= 1'b0;
            probe_itch_keep_o            <= '0;
            probe_itch_last_fire_o       <= 1'b0;
            probe_decoded_fire_o         <= 1'b0;
            probe_decoded_message_type_o <= '0;
        end
        else begin
            probe_frame_fire_o <= s_frame_tvalid_i && s_frame_tready_o;
            probe_frame_last_fire_o <=
                s_frame_tvalid_i && s_frame_tready_o && s_frame_tlast_i;
            if(s_frame_tvalid_i && s_frame_tready_o) begin
                probe_frame_keep_o <= s_frame_tkeep_i;
            end

            probe_dgram_fire_o <=
                u_ingress_top.dgram_tvalid && u_ingress_top.dgram_tready;
            if(u_ingress_top.dgram_tvalid && u_ingress_top.dgram_tready) begin
                probe_dgram_keep_o <= u_ingress_top.dgram_tkeep;
            end

            probe_payload_fire_o <=
                u_ingress_top.payload_tvalid && u_ingress_top.payload_tready;
            if(u_ingress_top.payload_tvalid && u_ingress_top.payload_tready) begin
                probe_payload_keep_o <= u_ingress_top.payload_tkeep;
            end

            probe_msg_len_fire_o <=
                u_ingress_top.msg_len_valid && u_ingress_top.msg_len_ready;

            probe_itch_fire_o <= itch_tvalid && itch_tready;
            probe_itch_last_fire_o <= itch_tvalid && itch_tready && itch_tlast;
            if(itch_tvalid && itch_tready) begin
                probe_itch_keep_o <= itch_tkeep;
            end

            probe_decoded_fire_o <= decoded_valid && decoded_ready;
            if(decoded_valid && decoded_ready) begin
                probe_decoded_message_type_o <= decoded_data.message_type;
            end
        end
    end

    always_ff @(posedge data_clk) begin
        if(!rst_n) begin
            probe_fifo_read_fire_o <= 1'b0;
        end
        else begin
            probe_fifo_read_fire_o <= fifo_valid && fifo_ready;
        end
    end

endmodule

`default_nettype wire
