// Sim-onlt top for eth -> bbo testing
// we use our own async fifo not the vivado xpm stuff

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module ethernet_to_bbo_top #(
    parameter bit          CHECK_DST_PORT    = 1'b0,
    parameter logic [15:0] EXPECTED_DST_PORT = 16'd0
) (
    // Network / ingress clock domain.
    input  logic       clk,

    // Order-book clock domain.
    input  logic       data_clk,
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

    // Test-only observation at the CDC output / order-book input boundary.
    output data_t probe_event_data_o,
    output logic  probe_event_valid_o,
    output logic  probe_event_ready_o
);

    // ingress_data_realign_top -> async event FIFO
    data_t ingress_event_data;
    logic  ingress_event_valid;
    logic  ingress_event_ready;

    // async event FIFO -> order_book_top
    data_t fifo_event_data;
    logic  fifo_event_valid;
    logic  fifo_event_ready;

    logic fifo_rst;

    assign fifo_rst = !rst_n;

    ingress_data_realign_top #(
        .CHECK_DST_PORT    (CHECK_DST_PORT),
        .EXPECTED_DST_PORT (EXPECTED_DST_PORT)
    ) u_ingress (
        .clk               (clk),
        .rst_n             (rst_n),

        .s_frame_tdata_i   (s_frame_tdata_i),
        .s_frame_tkeep_i   (s_frame_tkeep_i),
        .s_frame_tvalid_i  (s_frame_tvalid_i),
        .s_frame_tlast_i   (s_frame_tlast_i),
        .s_frame_tready_o  (s_frame_tready_o),

        .m_event_data_o    (ingress_event_data),
        .m_event_valid_o   (ingress_event_valid),
        .m_event_ready_i   (ingress_event_ready),

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

    event_async_fifo_sim #(
        .EVENT_W ($bits(data_t))
    ) u_event_fifo (
        .wr_clk_i   (clk),
        .rst_i      (fifo_rst),

        .s_data_i   (ingress_event_data),
        .s_valid_i  (ingress_event_valid),
        .s_ready_o  (ingress_event_ready),

        .rd_clk_i   (data_clk),

        .m_data_o   (fifo_event_data),
        .m_valid_o  (fifo_event_valid),
        .m_ready_i  (fifo_event_ready),

        .wr_level_o (),
        .full_o     (),
        .empty_o    ()
    );

    order_book_top u_order_book_top (
        .clk                 (data_clk),
        .rst_n               (rst_n),

        .base_price_stock0_i (base_price_stock0_i),
        .base_price_stock1_i (base_price_stock1_i),
        .base_price_stock2_i (base_price_stock2_i),

        .rdata_i             (fifo_event_data),
        .valid_i             (fifo_event_valid),
        .ready_o             (fifo_event_ready),

        .bbo_data_o          (bbo_data_o),
        .bbo_valid_o         (bbo_valid_o)
    );

    assign probe_event_data_o  = fifo_event_data;
    assign probe_event_valid_o = fifo_event_valid;
    assign probe_event_ready_o = fifo_event_ready;

endmodule

`default_nettype wire
