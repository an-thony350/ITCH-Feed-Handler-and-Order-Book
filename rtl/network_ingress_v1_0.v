`timescale 1 ns / 1 ps
`default_nettype none

module network_ingress_v1_0 #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Parameters of Axi Slave Bus Interface S00_AXIS
    parameter integer C_S00_AXIS_TDATA_WIDTH = 64,

    // Parameters of Axi Master Bus Interface M00_AXIS
    parameter integer C_M00_AXIS_TDATA_WIDTH = 64,
    parameter integer C_M00_AXIS_START_COUNT = 32
)
(
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line

    // Ports of Axi Slave Bus Interface S00_AXIS
    input  wire                                      s00_axis_aclk,
    input  wire                                      s00_axis_aresetn,
    output wire                                      s00_axis_tready,
    input  wire [C_S00_AXIS_TDATA_WIDTH-1 : 0]       s00_axis_tdata,
    input  wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0]   s00_axis_tkeep,
    input  wire                                      s00_axis_tlast,
    input  wire                                      s00_axis_tvalid,

    // Ports of Axi Master Bus Interface M00_AXIS
    input  wire                                      m00_axis_aclk,
    input  wire                                      m00_axis_aresetn,
    output wire                                      m00_axis_tvalid,
    output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0]       m00_axis_tdata,
    output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0]   m00_axis_tstrb,
    output wire                                      m00_axis_tlast,
    input  wire                                      m00_axis_tready
);

    // Clocking note:
    // This integration assumes S00_AXIS and M00_AXIS are on the same clock.

    wire ingress_rst_n;

    assign ingress_rst_n = s00_axis_aresetn & m00_axis_aresetn;

    // Byte qualifier:
    // S00_AXIS uses TKEEP because the upstream 32->64 AXIS Data Width Converter
    // preserves the valid-byte mask from AXI DMA.
    //
    // The native 64-bit ingress now also produces a valid-byte qualifier on its
    // output. The packaged M00_AXIS shell retains TSTRB, so the ingress TKEEP
    // mask is mapped directly onto TSTRB for the temporary 64->32 width
    // converter used during timing bring-up.

    wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m_itch_tkeep;

    ingress_top #(
        .CHECK_DST_PORT    (1'b0),
        .EXPECTED_DST_PORT (16'd0)
    ) ingress_top_inst (
        .clk                 (s00_axis_aclk),
        .rst_n               (ingress_rst_n),

        // AXIS Ethernet frame input.
        .s_frame_tdata_i     (s00_axis_tdata),
        .s_frame_tkeep_i     (s00_axis_tkeep),
        .s_frame_tvalid_i    (s00_axis_tvalid),
        .s_frame_tlast_i     (s00_axis_tlast),
        .s_frame_tready_o    (s00_axis_tready),

        // AXIS ITCH-message output.
        .m_itch_tdata_o      (m00_axis_tdata),
        .m_itch_tkeep_o      (m_itch_tkeep),
        .m_itch_tvalid_o     (m00_axis_tvalid),
        .m_itch_tlast_o      (m00_axis_tlast),
        .m_itch_tready_i     (m00_axis_tready),

        // MoldUDP64 sideband: left unconnected for initial board bring-up.
        .session_o           (),
        .seq_o               (),
        .count_o             (),
        .expected_next_o     (),
        .seq_valid_o         (),
        .heartbeat_o         (),
        .eos_o               (),
        .in_order_o          (),
        .duplicate_o         (),
        .gap_o               (),
        .stale_o             (),
        .expected_seq_o      (),
        .gap_start_o         (),
        .gap_end_o           (),

        // Status/debug outputs: expose later through dedicated CSRs/ILA.
        .frame_drop_o        (),
        .frame_err_o         (),
        .mold_drop_o         (),
        .mold_err_o          (),
        .realign_err_o       ()
    );

    // M00_AXIS retains TSTRB in the packaged interface shell. For this native
    // 64-bit timing build it carries the same byte-valid information as the
    // realign output TKEEP.
    assign m00_axis_tstrb = m_itch_tkeep;

endmodule

`default_nettype wire
