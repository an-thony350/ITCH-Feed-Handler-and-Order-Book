// Static 2:1 AXIS source mux for selecting DMA replay or Taxi RX.

`timescale 1ns/1ps
`default_nettype none

module axis_source_mux (
  input  logic        select_taxi_i,

  input  logic [63:0] dma_tdata_i,
  input  logic [7:0]  dma_tkeep_i,
  input  logic        dma_tvalid_i,
  input  logic        dma_tlast_i,
  output logic        dma_tready_o,

  input  logic [63:0] taxi_tdata_i,
  input  logic [7:0]  taxi_tkeep_i,
  input  logic        taxi_tvalid_i,
  input  logic        taxi_tlast_i,
  output logic        taxi_tready_o,

  output logic [63:0] m_tdata_o,
  output logic [7:0]  m_tkeep_o,
  output logic        m_tvalid_o,
  output logic        m_tlast_o,
  input  logic        m_tready_i
);

  // Source selection is static while the ingress is active:
  //   0 = DMA replay
  //   1 = Taxi Ethernet RX
  assign m_tdata_o  = select_taxi_i ? taxi_tdata_i  : dma_tdata_i;
  assign m_tkeep_o  = select_taxi_i ? taxi_tkeep_i  : dma_tkeep_i;
  assign m_tvalid_o = select_taxi_i ? taxi_tvalid_i : dma_tvalid_i;
  assign m_tlast_o  = select_taxi_i ? taxi_tlast_i  : dma_tlast_i;

  // Only the selected source participates in the AXIS handshake.
  assign dma_tready_o  = select_taxi_i ? 1'b0 : m_tready_i;
  assign taxi_tready_o = select_taxi_i ? m_tready_i : 1'b0;

endmodule

`default_nettype wire
