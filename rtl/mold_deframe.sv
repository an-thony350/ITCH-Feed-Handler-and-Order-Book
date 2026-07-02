// contract:
// - Input is one MoldUDP64 datagram per AXI packet from frame_crack.
// - s_dgram_len_i is the UDP payload length, valid with s_dgram_start_i.
// - Output payload stream is the concatenation of ITCH message payload bytes;
//   MoldUDP64 2-byte length prefixes are stripped.
// - Message boundaries are carried on a separate length stream. A msg_len item
//   must be accepted before the first payload byte of that message is emitted.
// - m_payload_tlast_o marks end of MoldUDP64 datagram, not end of ITCH message.
// - session/seq/count sideband is extraction only; gap/A-B comparison is Phase 4.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module mold_deframe (
  input  logic       clk,
  input  logic       rst_n,

  // AXIS MoldUDP64 datagram input.
  input  axis_data_t s_axis_tdata_i,
  input  axis_keep_t s_axis_tkeep_i,
  input  logic       s_axis_tvalid_i,
  input  logic       s_axis_tlast_i,
  output logic       s_axis_tready_o,

  // Datagram metadata from frame_crack. Valid with s_dgram_start_i.
  input  logic [DGRAM_LEN_W-1:0] s_dgram_len_i,
  input  logic                   s_dgram_start_i,

  // AXIS ITCH payload byte stream, with MoldUDP64 length prefixes removed.
  output axis_data_t m_payload_tdata_o,
  output axis_keep_t m_payload_tkeep_o,
  output logic       m_payload_tvalid_o,
  output logic       m_payload_tlast_o,
  input  logic       m_payload_tready_i,

  // Per-message length stream to realign. One item per ITCH payload.
  output logic [MOLD_MSG_LEN_W-1:0] m_msg_len_o,
  output logic                      m_msg_len_valid_o,
  input  logic                      m_msg_len_ready_i,

  // MoldUDP64 header sideband. seq_valid_o pulses once per datagram after the
  // 20-byte MoldUDP64 header is accepted and decoded.
  output logic [MOLD_SESSION_W-1:0] session_o,
  output logic [MOLD_SEQ_W-1:0]     seq_o,
  output logic [MOLD_COUNT_W-1:0]   count_o,
  output logic [MOLD_SEQ_W-1:0]     expected_next_o,
  output logic                      seq_valid_o,
  output logic                      heartbeat_o,
  output logic                      eos_o,

  // Error/status.
  output logic                      mold_drop_o,
  output logic [MOLD_ERR_W-1:0]     mold_err_o
);

  // impl notes:
  // - latch session bytes 0..9, sequence bytes 10..17, count bytes 18..19;
  // - for count==MOLD_COUNT_HEARTBEAT, assert heartbeat_o with seq_valid_o and
  //   emit no payload;
  // - for count==MOLD_COUNT_EOS, assert eos_o with seq_valid_o and emit no
  //   payload;
  // - otherwise, for each message block, read 2-byte big-endian length, push
  //   that length to m_msg_len_*, then forward exactly that many payload bytes;
  // - compute expected_next_o = seq_o + count_o, but do not compare it yet.

endmodule

`default_nettype wire
