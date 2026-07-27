// Simulation-only probe wrapper for ingress_top latency/throughput tests.
//
// This module does not modify the production ingress RTL. It mirrors the
// ingress_top interface and exposes internal ready/valid boundaries so cocotb
// can timestamp real handshakes at each stage.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module ingress_top_perf_probe #(
  parameter bit          CHECK_DST_PORT    = 1'b0,
  parameter logic [15:0] EXPECTED_DST_PORT = 16'd0
) (
  input  wire       clk,
  input  wire       rst_n,

  // AXIS Ethernet frame input.
  input  wire axis_data_t s_frame_tdata_i,
  input  wire axis_keep_t s_frame_tkeep_i,
  input  wire       s_frame_tvalid_i,
  input  wire       s_frame_tlast_i,
  output logic      s_frame_tready_o,

  // AXIS aligned ITCH-message output.
  output axis_data_t m_itch_tdata_o,
  output logic       m_itch_tvalid_o,
  output logic       m_itch_tlast_o,
  input  wire        m_itch_tready_i,

  // MoldUDP64 sideband and A/B + gap status.
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

  // Status/error outputs.
  output logic                     frame_drop_o,
  output logic [FRAME_ERR_W-1:0]   frame_err_o,
  output logic                     mold_drop_o,
  output logic [MOLD_ERR_W-1:0]    mold_err_o,
  output logic [REALIGN_ERR_W-1:0] realign_err_o,

  // Simulation-only handshake probes.
  output wire       probe_frame_fire_o,

  output wire       probe_dgram_tvalid_o,
  output wire       probe_dgram_tready_o,
  output axis_keep_t probe_dgram_tkeep_o,
  output wire       probe_dgram_tlast_o,
  output wire       probe_dgram_start_o,
  output wire       probe_dgram_fire_o,

  output wire       probe_payload_tvalid_o,
  output wire       probe_payload_tready_o,
  output axis_keep_t probe_payload_tkeep_o,
  output wire       probe_payload_tlast_o,
  output wire       probe_payload_fire_o,

  output wire       probe_msg_len_valid_o,
  output wire       probe_msg_len_ready_o,
  output wire       probe_msg_len_fire_o,

  output wire       probe_itch_fire_o,
  output wire       probe_itch_last_fire_o
);

  ingress_top #(
    .CHECK_DST_PORT    (CHECK_DST_PORT),
    .EXPECTED_DST_PORT (EXPECTED_DST_PORT)
  ) dut (
    .clk               (clk),
    .rst_n             (rst_n),

    .s_frame_tdata_i   (s_frame_tdata_i),
    .s_frame_tkeep_i   (s_frame_tkeep_i),
    .s_frame_tvalid_i  (s_frame_tvalid_i),
    .s_frame_tlast_i   (s_frame_tlast_i),
    .s_frame_tready_o  (s_frame_tready_o),

    .m_itch_tdata_o    (m_itch_tdata_o),
    .m_itch_tvalid_o   (m_itch_tvalid_o),
    .m_itch_tlast_o    (m_itch_tlast_o),
    .m_itch_tready_i   (m_itch_tready_i),

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

  // Input-side acceptance.
  assign probe_frame_fire_o = s_frame_tvalid_i && s_frame_tready_o;

  // frame_crack -> mold_deframe boundary.
  assign probe_dgram_tvalid_o = dut.dgram_tvalid;
  assign probe_dgram_tready_o = dut.dgram_tready;
  assign probe_dgram_tkeep_o  = dut.dgram_tkeep;
  assign probe_dgram_tlast_o  = dut.dgram_tlast;
  assign probe_dgram_start_o  = dut.dgram_start;
  assign probe_dgram_fire_o   = dut.dgram_tvalid && dut.dgram_tready;

  // mold_deframe -> realign payload boundary.
  assign probe_payload_tvalid_o = dut.payload_tvalid;
  assign probe_payload_tready_o = dut.payload_tready;
  assign probe_payload_tkeep_o  = dut.payload_tkeep;
  assign probe_payload_tlast_o  = dut.payload_tlast;
  assign probe_payload_fire_o   = dut.payload_tvalid && dut.payload_tready;

  // MoldUDP64 message-length side channel.
  assign probe_msg_len_valid_o = dut.msg_len_valid;
  assign probe_msg_len_ready_o = dut.msg_len_ready;
  assign probe_msg_len_fire_o  = dut.msg_len_valid && dut.msg_len_ready;

  // Aligned ITCH output acceptance.
  assign probe_itch_fire_o =
      m_itch_tvalid_o && m_itch_tready_i;

  assign probe_itch_last_fire_o =
      m_itch_tvalid_o && m_itch_tready_i && m_itch_tlast_o;

endmodule

`default_nettype wire
