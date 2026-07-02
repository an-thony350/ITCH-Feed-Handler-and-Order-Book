// Simple one-deep AXIS register slice for breaking ready paths.

`timescale 1ns/1ps
`default_nettype none

module axis_skid_buffer #(
  parameter int DATA_W = 64,
  parameter int KEEP_W = DATA_W / 8
) (
  input  logic              clk,
  input  logic              rst_n,

  input  logic [DATA_W-1:0] s_tdata_i,
  input  logic [KEEP_W-1:0] s_tkeep_i,
  input  logic              s_tvalid_i,
  input  logic              s_tlast_i,
  output logic              s_tready_o,

  output logic [DATA_W-1:0] m_tdata_o,
  output logic [KEEP_W-1:0] m_tkeep_o,
  output logic              m_tvalid_o,
  output logic              m_tlast_o,
  input  logic              m_tready_i
);

  assign s_tready_o = (!m_tvalid_o) || m_tready_i;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      m_tdata_o  <= '0;
      m_tkeep_o  <= '0;
      m_tvalid_o <= 1'b0;
      m_tlast_o  <= 1'b0;
    end else if (s_tready_o) begin
      m_tvalid_o <= s_tvalid_i;
      if (s_tvalid_i) begin
        m_tdata_o <= s_tdata_i;
        m_tkeep_o <= s_tkeep_i;
        m_tlast_o <= s_tlast_i;
      end
    end
  end

endmodule

`default_nettype wire
