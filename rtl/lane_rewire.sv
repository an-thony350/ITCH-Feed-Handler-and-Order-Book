// Rewire Taxi AXIS byte lanes into the project's byte-lane convention.

`timescale 1ns/1ps
`default_nettype none

module lane_rewire (
  input  logic [63:0] s_tdata_i,
  input  logic [7:0]  s_tkeep_i,
  input  logic        s_tvalid_i,
  input  logic        s_tlast_i,
  output logic        s_tready_o,

  output logic [63:0] m_tdata_o,
  output logic [7:0]  m_tkeep_o,
  output logic        m_tvalid_o,
  output logic        m_tlast_o,
  input  logic        m_tready_i
);

  // Taxi places the earliest byte in the lowest lane; the project uses the
  // highest lane. Reverse the eight byte lanes without adding state/latency.
  assign m_tdata_o = {
    s_tdata_i[7:0],
    s_tdata_i[15:8],
    s_tdata_i[23:16],
    s_tdata_i[31:24],
    s_tdata_i[39:32],
    s_tdata_i[47:40],
    s_tdata_i[55:48],
    s_tdata_i[63:56]
  };

  // tkeep follows the same lane reversal as tdata.
  assign m_tkeep_o = {
    s_tkeep_i[0],
    s_tkeep_i[1],
    s_tkeep_i[2],
    s_tkeep_i[3],
    s_tkeep_i[4],
    s_tkeep_i[5],
    s_tkeep_i[6],
    s_tkeep_i[7]
  };

  // AXIS control/handshake signals are unchanged by the lane conversion.
  assign m_tvalid_o = s_tvalid_i;
  assign m_tlast_o  = s_tlast_i;
  assign s_tready_o = m_tready_i;

endmodule

`default_nettype wire
