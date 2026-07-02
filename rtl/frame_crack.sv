// Contract:
// - Input is one complete Ethernet frame per AXI packet.
// - 64-bit AXIS uses big-endian byte order: byte lane 0 is tdata[63:56].
// - This phase assumes untagged Ethernet, IPv4 IHL=5, UDP, no fragmentation.
// - Output is the UDP payload, i.e. the MoldUDP64 datagram.
// - m_dgram_len_o is valid on the first output beat when m_dgram_start_o=1.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module frame_crack #(
  parameter bit          CHECK_DST_PORT    = 1'b0,
  parameter logic [15:0] EXPECTED_DST_PORT = 16'd0
) (
  input  logic       clk,
  input  logic       rst_n,

  // AXIS Ethernet frame input from DMA / testbench.
  input  axis_data_t s_axis_tdata_i,
  input  axis_keep_t s_axis_tkeep_i,
  input  logic       s_axis_tvalid_i,
  input  logic       s_axis_tlast_i,
  output logic       s_axis_tready_o,

  // AXIS MoldUDP64 datagram output.
  output axis_data_t m_axis_tdata_o,
  output axis_keep_t m_axis_tkeep_o,
  output logic       m_axis_tvalid_o,
  output logic       m_axis_tlast_o,
  input  logic       m_axis_tready_i,

  // Datagram metadata. Valid on the beat where m_dgram_start_o is asserted.
  output logic [DGRAM_LEN_W-1:0] m_dgram_len_o,
  output logic                   m_dgram_start_o,

  // One-cycle pulse when a frame is dropped, plus per-frame reason bits.
  output logic                   frame_drop_o,
  output logic [FRAME_ERR_W-1:0] frame_err_o
);

  // impl notes:
  // - latch EtherType at absolute bytes 12..13;
  // - latch IPv4 version/IHL at byte 14, total length at 16..17,
  //   flags/fragment offset at 20..21, protocol at 23;
  // - latch UDP dst port at 36..37 and UDP length at 38..39;
  // - validate fields, suppress output for bad frames, and forward bytes
  //   from absolute byte offset L2_L4_HDR_BYTES to frame end.

endmodule

`default_nettype wire
