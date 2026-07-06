// Top-level wrapper for the ingress chain.


`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module ingress_top #(
  parameter bit          CHECK_DST_PORT    = 1'b0,
  parameter logic [15:0] EXPECTED_DST_PORT = 16'd0
) (
  input  wire       clk,
  input  wire       rst_n,

  // AXIS Ethernet frame input from PS->PL DMA or the cocotb/xsim driver.
  input  wire axis_data_t s_frame_tdata_i,
  input  wire axis_keep_t s_frame_tkeep_i,
  input  wire       s_frame_tvalid_i,
  input  wire       s_frame_tlast_i,
  output logic       s_frame_tready_o,

  // AXIS ITCH-message output to data_handler.
  output axis_data_t m_itch_tdata_o,
  output logic       m_itch_tvalid_o,
  output logic       m_itch_tlast_o,
  input  wire       m_itch_tready_i,

  // MoldUDP64 sideband for Phase-4 gap/A-B logic and debug registers.
  output logic [MOLD_SESSION_W-1:0] session_o,
  output logic [MOLD_SEQ_W-1:0]     seq_o,
  output logic [MOLD_COUNT_W-1:0]   count_o,
  output logic [MOLD_SEQ_W-1:0]     expected_next_o,
  output logic                      seq_valid_o,
  output logic                      heartbeat_o,
  output logic                      eos_o,

  // Status/error outputs. These can later be latched into AXI-Lite CSRs.
  output logic                      frame_drop_o,
  output logic [FRAME_ERR_W-1:0]    frame_err_o,
  output logic                      mold_drop_o,
  output logic [MOLD_ERR_W-1:0]     mold_err_o,
  output logic [REALIGN_ERR_W-1:0]  realign_err_o
);

  axis_data_t dgram_tdata;
  axis_keep_t dgram_tkeep;
  logic       dgram_tvalid;
  logic       dgram_tlast;
  logic       dgram_tready;
  logic [DGRAM_LEN_W-1:0] dgram_len;
  logic       dgram_start;

  axis_data_t payload_tdata;
  axis_keep_t payload_tkeep;
  logic       payload_tvalid;
  logic       payload_tlast;
  logic       payload_tready;

  logic [MOLD_MSG_LEN_W-1:0] msg_len;
  logic                      msg_len_valid;
  logic                      msg_len_ready;

  frame_crack #(
    .CHECK_DST_PORT    (CHECK_DST_PORT),
    .EXPECTED_DST_PORT (EXPECTED_DST_PORT)
  ) u_frame_crack (
    .clk              (clk),
    .rst_n            (rst_n),

    .s_axis_tdata_i   (s_frame_tdata_i),
    .s_axis_tkeep_i   (s_frame_tkeep_i),
    .s_axis_tvalid_i  (s_frame_tvalid_i),
    .s_axis_tlast_i   (s_frame_tlast_i),
    .s_axis_tready_o  (s_frame_tready_o),

    .m_axis_tdata_o   (dgram_tdata),
    .m_axis_tkeep_o   (dgram_tkeep),
    .m_axis_tvalid_o  (dgram_tvalid),
    .m_axis_tlast_o   (dgram_tlast),
    .m_axis_tready_i  (dgram_tready),

    .m_dgram_len_o    (dgram_len),
    .m_dgram_start_o  (dgram_start),

    .frame_drop_o     (frame_drop_o),
    .frame_err_o      (frame_err_o)
  );

  mold_deframe u_mold_deframe (
    .clk                 (clk),
    .rst_n               (rst_n),

    .s_axis_tdata_i      (dgram_tdata),
    .s_axis_tkeep_i      (dgram_tkeep),
    .s_axis_tvalid_i     (dgram_tvalid),
    .s_axis_tlast_i      (dgram_tlast),
    .s_axis_tready_o     (dgram_tready),

    .s_dgram_len_i       (dgram_len),
    .s_dgram_start_i     (dgram_start),

    .m_payload_tdata_o   (payload_tdata),
    .m_payload_tkeep_o   (payload_tkeep),
    .m_payload_tvalid_o  (payload_tvalid),
    .m_payload_tlast_o   (payload_tlast),
    .m_payload_tready_i  (payload_tready),

    .m_msg_len_o         (msg_len),
    .m_msg_len_valid_o   (msg_len_valid),
    .m_msg_len_ready_i   (msg_len_ready),

    .session_o           (session_o),
    .seq_o               (seq_o),
    .count_o             (count_o),
    .expected_next_o     (expected_next_o),
    .seq_valid_o         (seq_valid_o),
    .heartbeat_o         (heartbeat_o),
    .eos_o               (eos_o),

    .mold_drop_o         (mold_drop_o),
    .mold_err_o          (mold_err_o)
  );

  realign u_realign (
    .clk                 (clk),
    .rst_n               (rst_n),

    .s_payload_tdata_i   (payload_tdata),
    .s_payload_tkeep_i   (payload_tkeep),
    .s_payload_tvalid_i  (payload_tvalid),
    .s_payload_tlast_i   (payload_tlast),
    .s_payload_tready_o  (payload_tready),

    .s_msg_len_i         (msg_len),
    .s_msg_len_valid_i   (msg_len_valid),
    .s_msg_len_ready_o   (msg_len_ready),

    .m_axis_tdata_o      (m_itch_tdata_o),
    .m_axis_tvalid_o     (m_itch_tvalid_o),
    .m_axis_tlast_o      (m_itch_tlast_o),
    .m_axis_tready_i     (m_itch_tready_i),

    .realign_err_o       (realign_err_o)
  );

endmodule

`default_nettype wire
