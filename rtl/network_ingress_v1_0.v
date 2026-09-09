`timescale 1 ns / 1 ps
`default_nettype none

module network_ingress_v1_0 #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Parameters of Axi Slave Bus Interface S00_AXIS
    parameter integer C_S00_AXIS_TDATA_WIDTH = 64
)
(
    // Users to add ports here

    // Normalised ITCH event interface.
    //
    // This replaces the old M00_AXIS aligned-message output. data_realign now
    // decodes directly from the packed MoldUDP64 payload stream and emits the
    // existing 217-bit data_t event contract.
    input  wire                                      ready_i,
    output wire [216:0]                              rdata_o,
    output wire                                      valid_o,

    // User ports ends
    // Do not modify the ports beyond this line

    // Ports of Axi Slave Bus Interface S00_AXIS
    input  wire                                      s00_axis_aclk,
    input  wire                                      s00_axis_aresetn,
    output wire                                      s00_axis_tready,
    input  wire [C_S00_AXIS_TDATA_WIDTH-1 : 0]       s00_axis_tdata,
    input  wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0]   s00_axis_tkeep,
    input  wire                                      s00_axis_tlast,
    input  wire                                      s00_axis_tvalid
);

    // The ingress network path is native 64-bit and runs entirely in the
    // S00_AXIS / 156.25 MHz network clock domain. The event_async_fifo in the
    // block design performs the CDC after data_realign.
    initial begin
        if (C_S00_AXIS_TDATA_WIDTH != 64) begin
            $error("network_ingress_v1_0 requires C_S00_AXIS_TDATA_WIDTH == 64");
        end
    end

    ingress_data_realign_top #(
        .CHECK_DST_PORT    (1'b0),
        .EXPECTED_DST_PORT (16'd0)
    ) ingress_data_realign_top_inst (
        .clk                 (s00_axis_aclk),
        .rst_n               (s00_axis_aresetn),

        // AXIS Ethernet frame input.
        .s_frame_tdata_i     (s00_axis_tdata),
        .s_frame_tkeep_i     (s00_axis_tkeep),
        .s_frame_tvalid_i    (s00_axis_tvalid),
        .s_frame_tlast_i     (s00_axis_tlast),
        .s_frame_tready_o    (s00_axis_tready),

        // Normalised 217-bit event output.
        //
        // data_t is a packed 217-bit SystemVerilog struct inside the RTL.
        // Connecting it directly to rdata_o is purely wiring: no register,
        // adapter, or additional pipeline latency is introduced here.
        .m_event_data_o      (rdata_o),
        .m_event_valid_o     (valid_o),
        .m_event_ready_i     (ready_i),

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

endmodule

`default_nettype wire
