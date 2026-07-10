// Top-level wrapper for the complete ITCH feed-handler datapath.
//
// Ethernet frame input
//   -> ingress_top
//   -> data_handler
//   -> symbol_router
//   -> order_book
//   -> BBO output

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module feed_handler_top #(
    parameter bit          CHECK_DST_PORT    = 1'b0,
    parameter logic [15:0] EXPECTED_DST_PORT = 16'd0
) (
    input  logic       clk,
    input  logic       rst_n,

    // AXI4-Stream Ethernet frame input from PS->PL DMA or a testbench.
    input  axis_data_t s_frame_tdata_i,
    input  axis_keep_t s_frame_tkeep_i,
    input  logic       s_frame_tvalid_i,
    input  logic       s_frame_tlast_i,
    output logic       s_frame_tready_o,

    // Order-book best bid and offer output.
    output bbo_t       bbo_data_o,
    output logic       bbo_valid_o,

    // MoldUDP64 packet metadata.
    output logic [MOLD_SESSION_W-1:0] session_o,
    output logic [MOLD_SEQ_W-1:0]     seq_o,
    output logic [MOLD_COUNT_W-1:0]   count_o,
    output logic [MOLD_SEQ_W-1:0]     expected_next_o,
    output logic                      seq_valid_o,

    // A/B arbitration and gap status.
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
    output logic                      frame_drop_o,
    output logic [FRAME_ERR_W-1:0]    frame_err_o,
    output logic                      mold_drop_o,
    output logic [MOLD_ERR_W-1:0]     mold_err_o,
    output logic [REALIGN_ERR_W-1:0]  realign_err_o
);

    // ingress_top -> data_handler
    axis_data_t itch_tdata;
    logic       itch_tvalid;
    logic       itch_tlast;
    logic       itch_tready;

    // data_handler -> symbol_router
    data_t decoded_data;
    logic  decoded_valid;
    logic  decoded_ready;

    // symbol_router -> order_book
    o_data_t            routed_data;
    logic [PRICE_W-1:0] routed_base_price;
    logic               routed_valid;
    logic               book_ready;

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

    symbol_router u_symbol_router (
        .clk             (clk),
        .rst_n           (rst_n),

        .rdata_i         (decoded_data),
        .valid_i         (decoded_valid),
        .ready_o         (decoded_ready),

        .ready_i         (book_ready),
        .rdata_o         (routed_data),
        .base_price_o    (routed_base_price),
        .valid_stock0_o  (routed_valid)
    );

    order_book u_order_book (
        .clk          (clk),
        .rst_n        (rst_n),

        .rdata_i      (routed_data),
        .valid_i      (routed_valid),
        .base_price_i (routed_base_price),
        .ready_o      (book_ready),

        .bbo_data_o   (bbo_data_o),
        .bbo_valid_o  (bbo_valid_o)
    );

endmodule

`default_nettype wire
