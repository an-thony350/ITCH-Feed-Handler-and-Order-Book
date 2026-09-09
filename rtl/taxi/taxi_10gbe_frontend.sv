// Thin Taxi 10GbE frontend for the ZCU106 SFP+ interface.
//
// This wrapper preserves the proven two-channel ZCU106 Taxi transceiver
// topology, while exposing only lane 0's RX stream to the ITCH ingress.
// No FIFO or additional packet-path pipeline stage is inserted here.
//
// The downstream ingress_source_boundary performs the byte-lane rewire and
// DMA/Taxi source selection.

`timescale 1ns / 1ps
`default_nettype none

module taxi_10gbe_frontend (
    // 125 MHz Taxi transceiver-control clock and active-high reset.
    input  wire        ctrl_clk_i,
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
    output wire        rx_clk_o,
    output wire        rx_rst_o,

    // Raw Taxi lane-0 RX stream. Taxi places the earliest byte in data[7:0].
    output wire [63:0] rx_data_o,
    output wire [7:0]  rx_keep_o,
    output wire        rx_valid_o,
    output wire        rx_last_o,
    output wire        rx_user_o,
    input  wire        rx_ready_i,

    // Lane-0 link/error status for bring-up and later hardware validation.
    output wire        gt_powergood_o,
    output wire        rx_status_o,
    output wire        rx_block_lock_o,
    output wire        rx_high_ber_o,
    output wire [6:0]  rx_error_count_o,
    output wire        rx_pkt_bad_o,
    output wire        rx_bad_fcs_o
);

    localparam integer CNT = 2;

    wire sfp_tx_clk[CNT];
    wire sfp_tx_rst[CNT];
    wire sfp_rx_clk[CNT];
    wire sfp_rx_rst[CNT];

    wire sfp_rx_status[CNT];
    wire sfp_rx_block_lock[CNT];
    wire sfp_rx_high_ber[CNT];
    wire [6:0] sfp_rx_error_count[CNT];
    wire sfp_stat_rx_pkt_bad[CNT];
    wire sfp_stat_rx_err_bad_fcs[CNT];

    wire sfp_gtpowergood;

    wire sfp_mgt_refclk;
    wire sfp_mgt_refclk_int;
    wire sfp_mgt_refclk_bufg;

    wire sfp_rst;

    wire xcvr_txp[CNT];
    wire xcvr_txn[CNT];
    wire xcvr_rxp[CNT];
    wire xcvr_rxn[CNT];

    // Taxi AXIS interfaces used by the MAC.
    taxi_axis_if #(
        .DATA_W  (64),
        .ID_W    (8),
        .USER_EN (1),
        .USER_W  (1)
    )
    axis_sfp_tx[CNT]();

    taxi_axis_if #(
        .DATA_W (96),
        .KEEP_W (1),
        .ID_W   (8)
    )
    axis_sfp_tx_cpl[CNT]();

    taxi_axis_if #(
        .DATA_W  (64),
        .ID_W    (8),
        .USER_EN (1),
        .USER_W  (1)
    )
    axis_sfp_rx[CNT]();

    taxi_axis_if #(
        .DATA_W  (16),
        .KEEP_W  (1),
        .KEEP_EN (0),
        .LAST_EN (0),
        .USER_EN (1),
        .USER_W  (1),
        .ID_EN   (1),
        .ID_W    (10)
    )
    axis_eth_stat();

    // Taxi's GT APB interface is retained but left idle for the initial
    // integration. Dynamic GT control is not required for basic RX bring-up.
    taxi_apb_if #(
        .ADDR_W (18),
        .DATA_W (16)
    )
    gt_apb_ctrl();

    assign gt_apb_ctrl.paddr   = '0;
    assign gt_apb_ctrl.pprot   = '0;
    assign gt_apb_ctrl.psel    = 1'b0;
    assign gt_apb_ctrl.penable = 1'b0;
    assign gt_apb_ctrl.pwrite  = 1'b0;
    assign gt_apb_ctrl.pwdata  = '0;
    assign gt_apb_ctrl.pstrb   = '0;
    assign gt_apb_ctrl.pauser  = '0;
    assign gt_apb_ctrl.pwuser  = '0;

    // Physical lane connections.
    assign xcvr_rxp[0] = sfp_rx_p[0];
    assign xcvr_rxn[0] = sfp_rx_n[0];
    assign xcvr_rxp[1] = sfp_rx_p[1];
    assign xcvr_rxn[1] = sfp_rx_n[1];

    assign sfp_tx_p[0] = xcvr_txp[0];
    assign sfp_tx_n[0] = xcvr_txn[0];
    assign sfp_tx_p[1] = xcvr_txp[1];
    assign sfp_tx_n[1] = xcvr_txn[1];

    // Match the known-good Taxi ZCU106 example.
    assign sfp_tx_disable_b = 2'b11;

    // The ITCH design is receive-only. Keep both Taxi TX sources idle.
    for (genvar n = 0; n < CNT; n = n + 1) begin : tx_idle
        assign axis_sfp_tx[n].tdata  = '0;
        assign axis_sfp_tx[n].tkeep  = '0;
        assign axis_sfp_tx[n].tstrb  = '0;
        assign axis_sfp_tx[n].tid    = '0;
        assign axis_sfp_tx[n].tdest  = '0;
        assign axis_sfp_tx[n].tuser  = '0;
        assign axis_sfp_tx[n].tlast  = 1'b0;
        assign axis_sfp_tx[n].tvalid = 1'b0;

        // Completion streams are unused during receive-only bring-up.
        assign axis_sfp_tx_cpl[n].tready = 1'b1;
    end

    // Statistics are disabled, but keep the stream sink ready.
    assign axis_eth_stat.tready = 1'b1;

    // MGT reference-clock handling copied from the proven Taxi ZCU106 example.
    IBUFDS_GTE4 ibufds_gte4_sfp_mgt_refclk_inst (
        .I     (sfp_mgt_refclk_p),
        .IB    (sfp_mgt_refclk_n),
        .CEB   (1'b0),
        .O     (sfp_mgt_refclk),
        .ODIV2 (sfp_mgt_refclk_int)
    );

    BUFG_GT bufg_gt_sfp_mgt_refclk_inst (
        .CE      (sfp_gtpowergood),
        .CEMASK  (1'b1),
        .CLR     (1'b0),
        .CLRMASK (1'b1),
        .DIV     (3'd0),
        .I       (sfp_mgt_refclk_int),
        .O       (sfp_mgt_refclk_bufg)
    );

    taxi_sync_reset #(
        .N (4)
    )
    sfp_sync_reset_inst (
        .clk (sfp_mgt_refclk_bufg),
        .rst (ctrl_rst_i),
        .out (sfp_rst)
    );

    taxi_eth_mac_25g_us #(
        .SIM                  (1'b0),
        .VENDOR               ("XILINX"),
        .FAMILY               ("zynquplus"),
        .CNT                  (CNT),
        .CFG_LOW_LATENCY      (1'b1),
        .GT_TYPE              ("GTH"),
        .COMBINED_MAC_PCS     (1'b1),
        .DATA_W               (64),
        .USXGMII_EN           (1'b1),
        .DIC_EN               (1'b1),
        .PTP_TS_EN            (1'b0),
        .PTP_TD_EN            (1'b0),
        .PTP_TS_FMT_TOD       (1'b1),
        .PTP_TS_W             (96),
        .PTP_TD_SDI_PIPELINE  (2),
        .PRBS31_EN            (1'b0),
        .TX_SERDES_PIPELINE   (1),
        .RX_SERDES_PIPELINE   (1),
        .COUNT_125US          (125000/6.4),
        .STAT_EN              (1'b0)
    )
    sfp_mac_inst (
        .xcvr_ctrl_clk (ctrl_clk_i),
        .xcvr_ctrl_rst (sfp_rst),

        // Transceiver control.
        .s_apb_ctrl (gt_apb_ctrl),

        // Common GT resources.
        .xcvr_gtpowergood_out    (sfp_gtpowergood),
        .xcvr_gtrefclk00_in      (sfp_mgt_refclk),
        .xcvr_qpll0pd_in         (1'b0),
        .xcvr_qpll0reset_in      (1'b0),
        .xcvr_qpll0pcierate_in   (3'd0),
        .xcvr_qpll0lock_out      (),
        .xcvr_qpll0clk_out       (),
        .xcvr_qpll0refclk_out    (),
        .xcvr_gtrefclk01_in      (sfp_mgt_refclk),
        .xcvr_qpll1pd_in         (1'b0),
        .xcvr_qpll1reset_in      (1'b0),
        .xcvr_qpll1pcierate_in   (3'd0),
        .xcvr_qpll1lock_out      (),
        .xcvr_qpll1clk_out       (),
        .xcvr_qpll1refclk_out    (),

        // Serial data.
        .xcvr_txp (xcvr_txp),
        .xcvr_txn (xcvr_txn),
        .xcvr_rxp (xcvr_rxp),
        .xcvr_rxn (xcvr_rxn),

        // MAC clocks.
        .rx_clk     (sfp_rx_clk),
        .rx_rst_in  ('{2{1'b0}}),
        .rx_rst_out (sfp_rx_rst),
        .tx_clk     (sfp_tx_clk),
        .tx_rst_in  ('{2{1'b0}}),
        .tx_rst_out (sfp_tx_rst),

        // AXI4-Stream interfaces.
        .s_axis_tx     (axis_sfp_tx),
        .m_axis_tx_cpl (axis_sfp_tx_cpl),
        .m_axis_rx     (axis_sfp_rx),

        // USXGMII autonegotiation. 10GBASE-R is used, so USXGMII AN is off.
        .an_en                 ('{2{1'b1}}),
        .an_restart            ('{2{1'b0}}),
        .an_speedup            ('{2{1'b0}}),
        .an_timeout_en         ('{2{1'b1}}),
        .an_usxgmii_en         ('{2{1'b0}}),
        .an_usxgmii_auto       ('{2{1'b1}}),
        .an_intr               (),
        .an_running            (),
        .an_complete           (),
        .an_timeout            (),
        .an_usxgmii_mode       (),
        .an_adv_ability_usxgmii('{2{16'h1601}}),
        .an_lp_adv_ability     (),
        .an_lp_usxgmii_link    (),
        .an_lp_usxgmii_speed   (),
        .an_res_full_duplex    (),

        // PTP disabled.
        .ptp_clk            (1'b0),
        .ptp_rst            (1'b0),
        .ptp_sample_clk     (1'b0),
        .ptp_td_sdi         (1'b0),
        .tx_ptp_ts_in       ('{2{'0}}),
        .tx_ptp_ts_out      (),
        .tx_ptp_ts_step_out (),
        .tx_ptp_locked      (),
        .rx_ptp_ts_in       ('{2{'0}}),
        .rx_ptp_ts_out      (),
        .rx_ptp_ts_step_out (),
        .rx_ptp_locked      (),

        // Link-level flow control disabled.
        .tx_lfc_req    ('{2{1'b0}}),
        .tx_lfc_resend ('{2{1'b0}}),
        .rx_lfc_en     ('{2{1'b0}}),
        .rx_lfc_req    (),
        .rx_lfc_ack    ('{2{1'b0}}),

        // Priority flow control disabled.
        .tx_pfc_req    ('{2{'0}}),
        .tx_pfc_resend ('{2{1'b0}}),
        .rx_pfc_en     ('{2{'0}}),
        .rx_pfc_req    (),
        .rx_pfc_ack    ('{2{'0}}),

        // Pause disabled.
        .tx_lfc_pause_en ('{2{1'b0}}),
        .tx_pause_req    ('{2{1'b0}}),
        .tx_pause_ack    (),

        // Statistics stream disabled; selected status outputs remain exposed.
        .stat_clk    (ctrl_clk_i),
        .stat_rst    (sfp_rst),
        .m_axis_stat (axis_eth_stat),

        .tx_start_packet          (),
        .stat_tx_byte             (),
        .stat_tx_pkt_len          (),
        .stat_tx_pkt_ucast        (),
        .stat_tx_pkt_mcast        (),
        .stat_tx_pkt_bcast        (),
        .stat_tx_pkt_vlan         (),
        .stat_tx_pkt_good         (),
        .stat_tx_pkt_bad          (),
        .stat_tx_pad_frame        (),
        .stat_tx_err_oversize     (),
        .stat_tx_err_user         (),
        .stat_tx_err_underflow    (),
        .rx_start_packet          (),
        .rx_error_count           (sfp_rx_error_count),
        .rx_block_lock            (sfp_rx_block_lock),
        .rx_high_ber              (sfp_rx_high_ber),
        .rx_status                (sfp_rx_status),
        .stat_rx_byte             (),
        .stat_rx_pkt_len          (),
        .stat_rx_pkt_fragment     (),
        .stat_rx_pkt_jabber       (),
        .stat_rx_pkt_ucast        (),
        .stat_rx_pkt_mcast        (),
        .stat_rx_pkt_bcast        (),
        .stat_rx_pkt_vlan         (),
        .stat_rx_pkt_good         (),
        .stat_rx_pkt_bad          (sfp_stat_rx_pkt_bad),
        .stat_rx_err_oversize     (),
        .stat_rx_err_bad_fcs      (sfp_stat_rx_err_bad_fcs),
        .stat_rx_err_bad_block    (),
        .stat_rx_err_framing      (),
        .stat_rx_err_preamble     (),
        .stat_rx_fifo_drop        ('{2{1'b0}}),
        .stat_tx_mcf              (),
        .stat_rx_mcf              (),
        .stat_tx_lfc_pkt          (),
        .stat_tx_lfc_xon          (),
        .stat_tx_lfc_xoff         (),
        .stat_tx_lfc_paused       (),
        .stat_tx_pfc_pkt          (),
        .stat_tx_pfc_xon          (),
        .stat_tx_pfc_xoff         (),
        .stat_tx_pfc_paused       (),
        .stat_rx_lfc_pkt          (),
        .stat_rx_lfc_xon          (),
        .stat_rx_lfc_xoff         (),
        .stat_rx_lfc_paused       (),
        .stat_rx_pfc_pkt          (),
        .stat_rx_pfc_xon          (),
        .stat_rx_pfc_xoff         (),
        .stat_rx_pfc_paused       (),

        // MAC configuration. These are explicit so Vivado 2023.2 does not
        // need to rely on Taxi's unpacked-array port default initializers.
        .cfg_tx_pad_en                 ('{2{1'b1}}),
        .cfg_tx_min_pkt_len            ('{2{8'd60-1}}),
        .cfg_tx_max_pkt_len            ('{2{16'd9218-1}}),
        .cfg_tx_ifg                    ('{2{8'd12}}),
        .cfg_tx_enable                 ('{2{1'b1}}),
        .cfg_rx_max_pkt_len            ('{2{16'd9218-1}}),
        .cfg_rx_enable                 ('{2{1'b1}}),
        .cfg_ifg                       ('{2{8'd12}}),
        .cfg_tx_prbs31_enable          ('{2{1'b0}}),
        .cfg_rx_prbs31_enable          ('{2{1'b0}}),
        .cfg_mcf_rx_eth_dst_mcast      ('{2{48'h01_80_C2_00_00_01}}),
        .cfg_mcf_rx_check_eth_dst_mcast('{2{1'b1}}),
        .cfg_mcf_rx_eth_dst_ucast      ('{2{48'd0}}),
        .cfg_mcf_rx_check_eth_dst_ucast('{2{1'b0}}),
        .cfg_mcf_rx_eth_src            ('{2{48'd0}}),
        .cfg_mcf_rx_check_eth_src      ('{2{1'b0}}),
        .cfg_mcf_rx_eth_type           ('{2{16'h8808}}),
        .cfg_mcf_rx_opcode_lfc         ('{2{16'h0001}}),
        .cfg_mcf_rx_check_opcode_lfc   ('{2{1'b1}}),
        .cfg_mcf_rx_opcode_pfc         ('{2{16'h0101}}),
        .cfg_mcf_rx_check_opcode_pfc   ('{2{1'b1}}),
        .cfg_mcf_rx_forward            ('{2{1'b0}}),
        .cfg_mcf_rx_enable             ('{2{1'b0}}),
        .cfg_tx_lfc_eth_dst            ('{2{48'h01_80_C2_00_00_01}}),
        .cfg_tx_lfc_eth_src            ('{2{48'h80_23_31_43_54_4C}}),
        .cfg_tx_lfc_eth_type           ('{2{16'h8808}}),
        .cfg_tx_lfc_opcode             ('{2{16'h0001}}),
        .cfg_tx_lfc_en                 ('{2{1'b0}}),
        .cfg_tx_lfc_quanta             ('{2{16'hffff}}),
        .cfg_tx_lfc_refresh            ('{2{16'h7fff}}),
        .cfg_tx_pfc_eth_dst            ('{2{48'h01_80_C2_00_00_01}}),
        .cfg_tx_pfc_eth_src            ('{2{48'h80_23_31_43_54_4C}}),
        .cfg_tx_pfc_eth_type           ('{2{16'h8808}}),
        .cfg_tx_pfc_opcode             ('{2{16'h0101}}),
        .cfg_tx_pfc_en                 ('{2{1'b0}}),
        .cfg_tx_pfc_quanta             ('{2{'{8{16'hffff}}}}),
        .cfg_tx_pfc_refresh            ('{2{'{8{16'h7fff}}}}),
        .cfg_rx_lfc_opcode             ('{2{16'h0001}}),
        .cfg_rx_lfc_en                 ('{2{1'b0}}),
        .cfg_rx_pfc_opcode             ('{2{16'h0101}}),
        .cfg_rx_pfc_en                 ('{2{1'b0}})
    );

    // Raw lane-0 Taxi RX stream and clock/reset.
    assign rx_clk_o   = sfp_rx_clk[0];
    assign rx_rst_o   = sfp_rx_rst[0];

    assign rx_data_o  = axis_sfp_rx[0].tdata;
    assign rx_keep_o  = axis_sfp_rx[0].tkeep;
    assign rx_valid_o = axis_sfp_rx[0].tvalid;
    assign rx_last_o  = axis_sfp_rx[0].tlast;
    assign rx_user_o  = axis_sfp_rx[0].tuser[0];

    assign axis_sfp_rx[0].tready = rx_ready_i;

    // Lane 1 is instantiated to preserve the proven two-channel GT topology,
    // but it is not consumed by the ITCH datapath.
    assign axis_sfp_rx[1].tready = 1'b1;

    // Lane-0 bring-up/status outputs.
    assign gt_powergood_o   = sfp_gtpowergood;
    assign rx_status_o      = sfp_rx_status[0];
    assign rx_block_lock_o  = sfp_rx_block_lock[0];
    assign rx_high_ber_o    = sfp_rx_high_ber[0];
    assign rx_error_count_o = sfp_rx_error_count[0];
    assign rx_pkt_bad_o     = sfp_stat_rx_pkt_bad[0];
    assign rx_bad_fcs_o     = sfp_stat_rx_err_bad_fcs[0];

endmodule

`default_nettype wire
