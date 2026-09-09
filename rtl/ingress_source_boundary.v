// DMA/Taxi source boundary immediately before the existing network ingress.
//
// DMA replay is already in the project's byte-lane convention. Taxi RX is
// rewired from low-byte-first into the project convention before the static
// source mux.
//
// aclk/aresetn are present so Vivado can associate the AXI4-Stream interfaces
// with the existing ingress-domain clock/reset. The datapath itself is fully
// combinational and therefore adds zero clock cycles of latency.

`timescale 1ns / 1ps
`default_nettype none

module ingress_source_boundary (
    // Common ingress-domain clock/reset.
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aclk, ASSOCIATED_BUSIF S_DMA_AXIS:M_AXIS, ASSOCIATED_RESET aresetn, FREQ_HZ 156250000" *)
    input  wire        aclk,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aresetn, POLARITY ACTIVE_LOW" *)
    input  wire        aresetn,

    // Static source selection:
    //   0 = DMA replay
    //   1 = Taxi Ethernet RX
    // Change only while ingress is held in reset/disabled.
    input  wire        select_taxi_i,

    // Existing DMA AXIS source, already in project byte order.
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_DMA_AXIS TDATA" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_DMA_AXIS, FREQ_HZ 156250000, TDATA_NUM_BYTES 8, HAS_TKEEP 1, HAS_TLAST 1" *)
    input  wire [63:0] s_dma_axis_tdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_DMA_AXIS TKEEP" *)
    input  wire [7:0]  s_dma_axis_tkeep,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_DMA_AXIS TVALID" *)
    input  wire        s_dma_axis_tvalid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_DMA_AXIS TLAST" *)
    input  wire        s_dma_axis_tlast,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_DMA_AXIS TREADY" *)
    output wire        s_dma_axis_tready,

    // Raw Taxi AXIS source. Taxi places the earliest byte in tdata[7:0].
    // These remain scalar BD pins for the initial DMA-only integration check.
    (* X_INTERFACE_IGNORE = "true" *)
    input  wire [63:0] taxi_tdata_i,

    (* X_INTERFACE_IGNORE = "true" *)
    input  wire [7:0]  taxi_tkeep_i,

    (* X_INTERFACE_IGNORE = "true" *)
    input  wire        taxi_tvalid_i,

    (* X_INTERFACE_IGNORE = "true" *)
    input  wire        taxi_tlast_i,

    (* X_INTERFACE_IGNORE = "true" *)
    output wire        taxi_tready_o,

    // Common project-ordered AXIS stream into network_ingress_top.
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXIS, FREQ_HZ 156250000, TDATA_NUM_BYTES 8, HAS_TKEEP 1, HAS_TLAST 1" *)
    output wire [63:0] m_axis_tdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TKEEP" *)
    output wire [7:0]  m_axis_tkeep,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
    output wire        m_axis_tvalid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TLAST" *)
    output wire        m_axis_tlast,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
    input  wire        m_axis_tready
);

    wire [63:0] taxi_rewired_tdata;
    wire [7:0]  taxi_rewired_tkeep;
    wire        taxi_rewired_tvalid;
    wire        taxi_rewired_tlast;
    wire        taxi_rewired_tready;

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

        .dma_tdata_i   (s_dma_axis_tdata),
        .dma_tkeep_i   (s_dma_axis_tkeep),
        .dma_tvalid_i  (s_dma_axis_tvalid),
        .dma_tlast_i   (s_dma_axis_tlast),
        .dma_tready_o  (s_dma_axis_tready),

        .taxi_tdata_i  (taxi_rewired_tdata),
        .taxi_tkeep_i  (taxi_rewired_tkeep),
        .taxi_tvalid_i (taxi_rewired_tvalid),
        .taxi_tlast_i  (taxi_rewired_tlast),
        .taxi_tready_o (taxi_rewired_tready),

        .m_tdata_o     (m_axis_tdata),
        .m_tkeep_o     (m_axis_tkeep),
        .m_tvalid_o    (m_axis_tvalid),
        .m_tlast_o     (m_axis_tlast),
        .m_tready_i    (m_axis_tready)
    );

endmodule

`default_nettype wire
