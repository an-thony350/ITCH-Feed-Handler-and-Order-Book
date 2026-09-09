// Vivado IP Integrator-facing Verilog shim for taxi_10gbe_frontend.
//
// The Taxi frontend itself is SystemVerilog and uses Taxi interfaces
// internally.  Keeping this thin Verilog wrapper as the block-design module
// reference gives IP Integrator a simple scalar/vector port boundary.

`timescale 1ns / 1ps
`default_nettype none

module taxi_10gbe_frontend_bd (
    // 125 MHz Taxi transceiver-control clock and active-high reset.
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ctrl_clk_i CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME ctrl_clk_i, ASSOCIATED_RESET ctrl_rst_i, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0" *)
    input  wire        ctrl_clk_i,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ctrl_rst_i RST" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME ctrl_rst_i, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
    input  wire        ctrl_rst_i,

    // ZCU106 SFP+ serial lanes.
    input  wire [1:0]  sfp_rx_p,
    input  wire [1:0]  sfp_rx_n,
    output wire [1:0]  sfp_tx_p,
    output wire [1:0]  sfp_tx_n,

    // 156.25 MHz SFP+ MGT reference clock.
    input  wire        sfp_mgt_refclk_p,
    input  wire        sfp_mgt_refclk_n,

    // Board-level active-low TX-disable controls.
    output wire [1:0]  sfp_tx_disable_b,

    // Native Taxi lane-0 RX/user clock domain.
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 rx_clk_o CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rx_clk_o, ASSOCIATED_RESET rx_rst_o, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0" *)
    output wire        rx_clk_o,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rx_rst_o RST" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rx_rst_o, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
    output wire        rx_rst_o,

    // Raw Taxi lane-0 RX stream.
    output wire [63:0] rx_data_o,
    output wire [7:0]  rx_keep_o,
    output wire        rx_valid_o,
    output wire        rx_last_o,
    output wire        rx_user_o,
    input  wire        rx_ready_i,

    // Lane-0 link/error status.
    output wire        gt_powergood_o,
    output wire        rx_status_o,
    output wire        rx_block_lock_o,
    output wire        rx_high_ber_o,
    output wire [6:0]  rx_error_count_o,
    output wire        rx_pkt_bad_o,
    output wire        rx_bad_fcs_o
);

    taxi_10gbe_frontend frontend_inst (
        .ctrl_clk_i       (ctrl_clk_i),
        .ctrl_rst_i       (ctrl_rst_i),
        .sfp_rx_p         (sfp_rx_p),
        .sfp_rx_n         (sfp_rx_n),
        .sfp_tx_p         (sfp_tx_p),
        .sfp_tx_n         (sfp_tx_n),
        .sfp_mgt_refclk_p (sfp_mgt_refclk_p),
        .sfp_mgt_refclk_n (sfp_mgt_refclk_n),
        .sfp_tx_disable_b (sfp_tx_disable_b),
        .rx_clk_o         (rx_clk_o),
        .rx_rst_o         (rx_rst_o),
        .rx_data_o        (rx_data_o),
        .rx_keep_o        (rx_keep_o),
        .rx_valid_o       (rx_valid_o),
        .rx_last_o        (rx_last_o),
        .rx_user_o        (rx_user_o),
        .rx_ready_i       (rx_ready_i),
        .gt_powergood_o   (gt_powergood_o),
        .rx_status_o      (rx_status_o),
        .rx_block_lock_o  (rx_block_lock_o),
        .rx_high_ber_o    (rx_high_ber_o),
        .rx_error_count_o (rx_error_count_o),
        .rx_pkt_bad_o     (rx_pkt_bad_o),
        .rx_bad_fcs_o     (rx_bad_fcs_o)
    );

endmodule

`default_nettype wire
