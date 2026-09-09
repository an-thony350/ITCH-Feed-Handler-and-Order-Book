// Simulation-only probe for the candidate merged ingress/decode architecture.
//
// Production/candidate RTL is instantiated unchanged. The wrapper only exposes
// internal ready/valid boundaries and registers pre-edge handshakes so cocotb
// cannot lose a transfer when ready changes on the same active edge.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module ingress_data_realign_perf_probe #(
  parameter bit          CHECK_DST_PORT    = 1'b0,
  parameter logic [15:0] EXPECTED_DST_PORT = 16'd0
) (
  input  wire       clk,
  input  wire       rst_n,

  input  wire axis_data_t s_frame_tdata_i,
  input  wire axis_keep_t s_frame_tkeep_i,
  input  wire             s_frame_tvalid_i,
  input  wire             s_frame_tlast_i,
  output logic            s_frame_tready_o,

  output data_t m_event_data_o,
  output logic  m_event_valid_o,
  input  wire   m_event_ready_i,

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
  output wire probe_event_tvalid_o,
  output wire probe_event_tready_o,

  // Registered handshakes and associated byte qualifiers.
  output logic       probe_frame_fire_o,
  output axis_keep_t probe_frame_keep_o,
  output logic       probe_frame_last_fire_o,

  output logic       probe_dgram_fire_o,
  output axis_keep_t probe_dgram_keep_o,
  output logic       probe_dgram_last_fire_o,
  output logic       probe_dgram_start_fire_o,

  output logic       probe_payload_fire_o,
  output axis_keep_t probe_payload_keep_o,
  output logic       probe_payload_last_fire_o,

  output logic       probe_msg_len_fire_o,

  output logic       probe_event_fire_o,
  output data_t      probe_event_data_o
);

  ingress_data_realign_top #(
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

    .m_event_data_o    (m_event_data_o),
    .m_event_valid_o   (m_event_valid_o),
    .m_event_ready_i   (m_event_ready_i),

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

  assign probe_dgram_tvalid_o  = dut.dgram_tvalid;
  assign probe_dgram_tready_o  = dut.dgram_tready;
  assign probe_payload_tvalid_o = dut.payload_tvalid;
  assign probe_payload_tready_o = dut.payload_tready;
  assign probe_msg_len_valid_o  = dut.msg_len_valid;
  assign probe_msg_len_ready_o  = dut.msg_len_ready;
  assign probe_event_tvalid_o    = m_event_valid_o;
  assign probe_event_tready_o    = m_event_ready_i;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      probe_frame_fire_o        <= 1'b0;
      probe_frame_keep_o        <= '0;
      probe_frame_last_fire_o   <= 1'b0;

      probe_dgram_fire_o        <= 1'b0;
      probe_dgram_keep_o        <= '0;
      probe_dgram_last_fire_o   <= 1'b0;
      probe_dgram_start_fire_o  <= 1'b0;

      probe_payload_fire_o      <= 1'b0;
      probe_payload_keep_o      <= '0;
      probe_payload_last_fire_o <= 1'b0;

      probe_msg_len_fire_o      <= 1'b0;

      probe_event_fire_o        <= 1'b0;
      probe_event_data_o        <= '0;
    end else begin
      probe_frame_fire_o <= s_frame_tvalid_i && s_frame_tready_o;
      probe_frame_last_fire_o <=
          s_frame_tvalid_i && s_frame_tready_o && s_frame_tlast_i;
      if (s_frame_tvalid_i && s_frame_tready_o) begin
        probe_frame_keep_o <= s_frame_tkeep_i;
      end

      probe_dgram_fire_o <= dut.dgram_tvalid && dut.dgram_tready;
      probe_dgram_last_fire_o <=
          dut.dgram_tvalid && dut.dgram_tready && dut.dgram_tlast;
      probe_dgram_start_fire_o <=
          dut.dgram_tvalid && dut.dgram_tready && dut.dgram_start;
      if (dut.dgram_tvalid && dut.dgram_tready) begin
        probe_dgram_keep_o <= dut.dgram_tkeep;
      end

      probe_payload_fire_o <= dut.payload_tvalid && dut.payload_tready;
      probe_payload_last_fire_o <=
          dut.payload_tvalid && dut.payload_tready && dut.payload_tlast;
      if (dut.payload_tvalid && dut.payload_tready) begin
        probe_payload_keep_o <= dut.payload_tkeep;
      end

      probe_msg_len_fire_o <= dut.msg_len_valid && dut.msg_len_ready;

      probe_event_fire_o <= m_event_valid_o && m_event_ready_i;
      if (m_event_valid_o && m_event_ready_i) begin
        probe_event_data_o <= m_event_data_o;
      end
    end
  end

endmodule

`default_nettype wire
