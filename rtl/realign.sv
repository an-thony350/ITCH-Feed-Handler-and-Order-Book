// Contract:
// - Consumes a continuous byte stream of ITCH payload bytes from mold_deframe.
// - Consumes one msg_len item per ITCH message.
// - Emits one AXIS packet per ITCH message into data_handler.
// - Output has no tkeep because data_handler's current contract does not use it.
// - Output byte order is big-endian: the ITCH message_type byte is in [63:56].
// - Final beat is right-zero-padded and m_axis_tlast_o marks the last beat of
//   that ITCH message.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module realign (
  input  logic       clk,
  input  logic       rst_n,

  // AXIS ITCH payload byte stream from mold_deframe. This stream may contain
  // several messages per beat or messages straddling several beats.
  input  axis_data_t s_payload_tdata_i,
  input  axis_keep_t s_payload_tkeep_i,
  input  logic       s_payload_tvalid_i,
  input  logic       s_payload_tlast_i,   // end of datagram, not message
  output logic       s_payload_tready_o,

  // Per-message length stream from mold_deframe.
  input  logic [MOLD_MSG_LEN_W-1:0] s_msg_len_i,
  input  logic                      s_msg_len_valid_i,
  output logic                      s_msg_len_ready_o,

  // AXIS output to existing data_handler.s_tdata_i/s_tvalid_i/s_tlast_i.
  output axis_data_t m_axis_tdata_o,
  output logic       m_axis_tvalid_o,
  output logic       m_axis_tlast_o,
  input  logic       m_axis_tready_i,

  // Error/status.
  output logic [REALIGN_ERR_W-1:0] realign_err_o
);

  // for impl
  // - hold output data stable while m_axis_tvalid_o && !m_axis_tready_i;
  // - consume exactly s_msg_len_i bytes for each message;
  // - emit a beat whenever 8 message bytes are staged;
  // - when the message length is reached, emit final partial beat padded with
  //   zeros on the right and assert m_axis_tlast_o;
  // - propagate backpressure upstream with no dropped/duplicated bytes.

endmodule

`default_nettype wire
