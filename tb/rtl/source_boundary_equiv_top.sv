// Simulation-only wrapper for the DMA/Taxi source-boundary equivalence test.
//
// Taxi RX passes through lane_rewire before entering the same static source mux
// used by the already-project-ordered DMA stream.

`timescale 1ns/1ps
`default_nettype none

module source_boundary_equiv_top (
  input  logic        select_taxi_i,

  // Existing project-ordered DMA AXIS source.
  input  logic [63:0] dma_tdata_i,
  input  logic [7:0]  dma_tkeep_i,
  input  logic        dma_tvalid_i,
  input  logic        dma_tlast_i,
  output logic        dma_tready_o,

  // Raw Taxi AXIS source: earliest byte is in tdata[7:0].
  input  logic [63:0] taxi_tdata_i,
  input  logic [7:0]  taxi_tkeep_i,
  input  logic        taxi_tvalid_i,
  input  logic        taxi_tlast_i,
  output logic        taxi_tready_o,

  // Common project-ordered AXIS stream that will feed frame_crack.
  output logic [63:0] m_tdata_o,
  output logic [7:0]  m_tkeep_o,
  output logic        m_tvalid_o,
  output logic        m_tlast_o,
  input  logic        m_tready_i
);

  logic [63:0] taxi_rewired_tdata;
  logic [7:0]  taxi_rewired_tkeep;
  logic        taxi_rewired_tvalid;
  logic        taxi_rewired_tlast;
  logic        taxi_rewired_tready;

  lane_rewire lane_rewire_inst (
    .s_tdata_i  (taxi_tdata_i),
    .s_tkeep_i  (taxi_tkeep_i),
    .s_tvalid_i (taxi_tvalid_i),
    .s_tlast_i  (taxi_tlast_i),
    .s_tready_o (taxi_tready_o),

    .m_tdata_o  (taxi_rewired_tdata),
    .m_tkeep_o  (taxi_rewired_tkeep),
    .m_tvalid_o (taxi_rewired_tvalid),
    .m_tlast_o  (taxi_rewired_tlast),
    .m_tready_i (taxi_rewired_tready)
  );

  axis_source_mux axis_source_mux_inst (
    .select_taxi_i (select_taxi_i),

    .dma_tdata_i   (dma_tdata_i),
    .dma_tkeep_i   (dma_tkeep_i),
    .dma_tvalid_i  (dma_tvalid_i),
    .dma_tlast_i   (dma_tlast_i),
    .dma_tready_o  (dma_tready_o),

    .taxi_tdata_i  (taxi_rewired_tdata),
    .taxi_tkeep_i  (taxi_rewired_tkeep),
    .taxi_tvalid_i (taxi_rewired_tvalid),
    .taxi_tlast_i  (taxi_rewired_tlast),
    .taxi_tready_o (taxi_rewired_tready),

    .m_tdata_o     (m_tdata_o),
    .m_tkeep_o     (m_tkeep_o),
    .m_tvalid_o    (m_tvalid_o),
    .m_tlast_o     (m_tlast_o),
    .m_tready_i    (m_tready_i)
  );

endmodule

`default_nettype wire
