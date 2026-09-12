// SPDX-License-Identifier: MIT
/*

Copyright (c) 2014-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA top-level module
 */
module fpga #
(
    // simulation (set to avoid vendor primitives)
    parameter logic SIM = 1'b0,
    // vendor ("GENERIC", "XILINX", "ALTERA")
    parameter string VENDOR = "XILINX",
    // device family
    parameter string FAMILY = "artix7",
    // Use 90 degree clock for RGMII transmit
    parameter logic USE_CLK90 = 1'b1
)
(
    /*
     * Clock: 200MHz
     * Reset: Push button, active high
     */
    input  wire logic        clk_200mhz_p,
    input  wire logic        clk_200mhz_n,
    input  wire logic        reset,

    /*
     * GPIO
     */
    input  wire logic        btnu,
    input  wire logic        btnl,
    input  wire logic        btnd,
    input  wire logic        btnr,
    input  wire logic        btnc,
    input  wire logic [3:0]  sw,
    output wire logic [3:0]  led,

    /*
     * UART: 115200 bps, 8N1
     */
    input  wire logic        uart_rxd,
    output wire logic        uart_txd,
    input  wire logic        uart_rts,
    output wire logic        uart_cts,

    /*
     * I2C
     */
    inout  wire logic        i2c_scl,
    inout  wire logic        i2c_sda,
    output wire logic        i2c_mux_reset,

    /*
     * Ethernet: SFP+
     */
    input  wire logic        sfp_rx_p,
    input  wire logic        sfp_rx_n,
    output wire logic        sfp_tx_p,
    output wire logic        sfp_tx_n,
    input  wire logic        sfp_mgt_refclk_0_p,
    input  wire logic        sfp_mgt_refclk_0_n,
    output wire logic [1:0]  sfp_mgt_clk_sel,

    output wire logic        sfp_tx_disable,
    input  wire logic        sfp_rx_los,

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    input  wire logic        phy_rx_clk,
    input  wire logic [3:0]  phy_rxd,
    input  wire logic        phy_rx_ctl,
    output wire logic        phy_tx_clk,
    output wire logic [3:0]  phy_txd,
    output wire logic        phy_tx_ctl,
    output wire logic        phy_reset_n
);

// Clock and reset

wire clk_200mhz_ibufg;

// Internal 125 MHz clock
wire clk_mmcm_out;
wire clk_int;
wire clk90_mmcm_out;
wire clk90_int;
wire rst_int;

wire clk_200mhz_mmcm_out;
wire clk_200mhz_int;

wire mmcm_rst = reset;
wire mmcm_locked;
wire mmcm_clkfb;

IBUFGDS
clk_200mhz_ibufgds_inst(
    .I(clk_200mhz_p),
    .IB(clk_200mhz_n),
    .O(clk_200mhz_ibufg)
);

// MMCM instance
MMCME2_BASE #(
    // 200 MHz input
    .CLKIN1_PERIOD(5.0),
    .REF_JITTER1(0.010),
    // 200 MHz input / 1 = 200 MHz PFD (range 10 MHz to 550 MHz)
    .DIVCLK_DIVIDE(1),
    // 200 MHz PFD * 5 = 1000 MHz VCO (range 600 MHz to 1200 MHz)
    .CLKFBOUT_MULT_F(5),
    .CLKFBOUT_PHASE(0),
    // 1000 MHz VCO / 8 = 125 MHz, 0 degrees
    .CLKOUT0_DIVIDE_F(8),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    // 1000 MHz VCO / 8 = 125 MHz, 90 degrees
    .CLKOUT1_DIVIDE(8),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(90),
    // 1000 MHz VCO / 5 = 200 MHz, 0 degrees
    .CLKOUT2_DIVIDE(5),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0),
    // Not used
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0),
    // Not used
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0),
    .CLKOUT4_CASCADE("FALSE"),
    // Not used
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0),
    // Not used
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT6_PHASE(0),

    // optimized bandwidth
    .BANDWIDTH("OPTIMIZED"),
    // don't wait for lock during startup
    .STARTUP_WAIT("FALSE")
)
clk_mmcm_inst (
    // 200 MHz input
    .CLKIN1(clk_200mhz_ibufg),
    // direct clkfb feeback
    .CLKFBIN(mmcm_clkfb),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    // 125 MHz, 0 degrees
    .CLKOUT0(clk_mmcm_out),
    .CLKOUT0B(),
    // 125 MHz, 90 degrees
    .CLKOUT1(clk90_mmcm_out),
    .CLKOUT1B(),
    // 200 MHz, 0 degrees
    .CLKOUT2(clk_200mhz_mmcm_out),
    .CLKOUT2B(),
    // Not used
    .CLKOUT3(),
    .CLKOUT3B(),
    // Not used
    .CLKOUT4(),
    // Not used
    .CLKOUT5(),
    // Not used
    .CLKOUT6(),
    // reset input
    .RST(mmcm_rst),
    // don't power down
    .PWRDWN(1'b0),
    // locked output
    .LOCKED(mmcm_locked)
);

BUFG
clk_bufg_inst (
    .I(clk_mmcm_out),
    .O(clk_int)
);

BUFG
clk90_bufg_inst (
    .I(clk90_mmcm_out),
    .O(clk90_int)
);

BUFG
clk_200mhz_bufg_inst (
    .I(clk_200mhz_mmcm_out),
    .O(clk_200mhz_int)
);

taxi_sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(clk_int),
    .rst(~mmcm_locked),
    .out(rst_int)
);

// GPIO
wire btnu_int;
wire btnl_int;
wire btnd_int;
wire btnr_int;
wire btnc_int;
wire [3:0] sw_int;

taxi_debounce_switch #(
    .WIDTH(9),
    .N(4),
    .RATE(125000)
)
debounce_switch_inst (
    .clk(clk_int),
    .rst(rst_int),
    .in({btnu,
        btnl,
        btnd,
        btnr,
        btnc,
        sw}),
    .out({btnu_int,
        btnl_int,
        btnd_int,
        btnr_int,
        btnc_int,
        sw_int})
);

wire uart_rxd_int;
wire uart_rts_int;

taxi_sync_signal #(
    .WIDTH(2),
    .N(2)
)
sync_signal_inst (
    .clk(clk_int),
    .in({uart_rxd, uart_rts}),
    .out({uart_rxd_int, uart_rts_int})
);

wire [3:0] led_int;

// I2C
wire i2c_scl_i;
wire i2c_scl_o;
wire i2c_sda_i;
wire i2c_sda_o;

assign i2c_scl_i = i2c_scl;
assign i2c_scl = i2c_scl_o ? 1'bz : 1'b0;
assign i2c_sda_i = i2c_sda;
assign i2c_sda = i2c_sda_o ? 1'bz : 1'b0;

// 1000BASE-X SFP
assign sfp_mgt_clk_sel = 2'b00;

wire sfp_gmii_clk_int;
wire sfp_gmii_rst_int;
wire sfp_gmii_clk_en_int;
wire [7:0] sfp_gmii_txd_int;
wire sfp_gmii_tx_en_int;
wire sfp_gmii_tx_er_int;
wire [7:0] sfp_gmii_rxd_int;
wire sfp_gmii_rx_dv_int;
wire sfp_gmii_rx_er_int;

wire sfp_gtrefclk;
wire sfp_gtrefclk_bufg;
wire sfp_txuserclk;
wire sfp_txuserclk2;
wire sfp_rxuserclk;
wire sfp_rxuserclk2;
wire sfp_pma_reset;
wire sfp_mmcm_locked;

wire sfp_resetdone;

assign sfp_gmii_clk_int = sfp_txuserclk2;

taxi_sync_reset #(
    .N(4)
)
sync_reset_sfp_inst (
    .clk(sfp_gmii_clk_int),
    .rst(rst_int || !sfp_resetdone),
    .out(sfp_gmii_rst_int)
);

wire [15:0] sfp_status_vect;

wire sfp_status_link_status              = sfp_status_vect[0];
wire sfp_status_link_synchronization     = sfp_status_vect[1];
wire sfp_status_rudi_c                   = sfp_status_vect[2];
wire sfp_status_rudi_i                   = sfp_status_vect[3];
wire sfp_status_rudi_invalid             = sfp_status_vect[4];
wire sfp_status_rxdisperr                = sfp_status_vect[5];
wire sfp_status_rxnotintable             = sfp_status_vect[6];
wire sfp_status_phy_link_status          = sfp_status_vect[7];
wire [1:0] sfp_status_remote_fault_encdg = sfp_status_vect[9:8];
wire [1:0] sfp_status_speed              = sfp_status_vect[11:10];
wire sfp_status_duplex                   = sfp_status_vect[12];
wire sfp_status_remote_fault             = sfp_status_vect[13];
wire [1:0] sfp_status_pause              = sfp_status_vect[15:14];

wire [4:0] sfp_config_vect;

assign sfp_config_vect[4] = 1'b0; // autonegotiation enable
assign sfp_config_vect[3] = 1'b0; // isolate
assign sfp_config_vect[2] = 1'b0; // power down
assign sfp_config_vect[1] = 1'b0; // loopback enable
assign sfp_config_vect[0] = 1'b0; // unidirectional enable

basex_pcs_pma_0
sfp_pcspma (
    // Transceiver Interface
    .gtrefclk_p(sfp_mgt_refclk_0_p),
    .gtrefclk_n(sfp_mgt_refclk_0_n),
    .gtrefclk_out(sfp_gtrefclk),
    .gtrefclk_bufg_out(sfp_gtrefclk_bufg),
    .txp(sfp_tx_p),
    .txn(sfp_tx_n),
    .rxp(sfp_rx_p),
    .rxn(sfp_rx_n),
    .resetdone(sfp_resetdone),
    .userclk_out(sfp_txuserclk),
    .userclk2_out(sfp_txuserclk2),
    .rxuserclk_out(sfp_rxuserclk),
    .rxuserclk2_out(sfp_rxuserclk2),
    .independent_clock_bufg(clk_int),
    .pma_reset_out(sfp_pma_reset),
    .mmcm_locked_out(sfp_mmcm_locked),
    .gt0_pll0outclk_out(),
    .gt0_pll0outrefclk_out(),
    .gt0_pll1outclk_out(),
    .gt0_pll1outrefclk_out(),
    .gt0_pll0lock_out(),
    .gt0_pll0refclklost_out(),
    // GMII Interface
    .gmii_txd(sfp_gmii_txd_int),
    .gmii_tx_en(sfp_gmii_tx_en_int),
    .gmii_tx_er(sfp_gmii_tx_er_int),
    .gmii_rxd(sfp_gmii_rxd_int),
    .gmii_rx_dv(sfp_gmii_rx_dv_int),
    .gmii_rx_er(sfp_gmii_rx_er_int),
    .gmii_isolate(),
    // Management: Alternative to MDIO Interface
    .configuration_vector(sfp_config_vect),
    .status_vector(sfp_status_vect),
    // General IO's
    .reset(rst_int),
    .signal_detect(1'b1)
);

assign sfp_gmii_clk_en_int = 1'b1;

// SGMII interface debug:
// SW4:1 (sw[3]) off for payload byte, on for status vector
// SW4:4 (sw[0]) off for LSB of status vector, on for MSB
// assign led = sw[3] ? (sw[0] ? sfp_status_vect[15:8] : sfp_status_vect[7:0]) : led_int;

wire [3:0] phy_rxd_int;
wire phy_rx_ctl_int;

// IODELAY elements for RGMII interface to PHY
IDELAYCTRL
idelayctrl_inst (
    .REFCLK(clk_200mhz_int),
    .RST(rst_int),
    .RDY()
);

for (genvar n = 0; n < 4; n = n + 1) begin : phy_rxd_idelay_bit

    IDELAYE2 #(
        .IDELAY_TYPE("FIXED")
    )
    idelay_inst (
        .IDATAIN(phy_rxd[n]),
        .DATAOUT(phy_rxd_int[n]),
        .DATAIN(1'b0),
        .C(1'b0),
        .CE(1'b0),
        .INC(1'b0),
        .CINVCTRL(1'b0),
        .CNTVALUEIN(5'd0),
        .CNTVALUEOUT(),
        .LD(1'b0),
        .LDPIPEEN(1'b0),
        .REGRST(1'b0)
    );

end

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rx_ctl_idelay (
    .IDATAIN(phy_rx_ctl),
    .DATAOUT(phy_rx_ctl_int),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

fpga_core #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .USE_CLK90(USE_CLK90)
)
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk(clk_int),
    .clk90(clk90_int),
    .rst(rst_int),

    /*
     * GPIO
     */
    .btnu(btnu_int),
    .btnl(btnl_int),
    .btnd(btnd_int),
    .btnr(btnr_int),
    .btnc(btnc_int),
    .sw(sw_int),
    .led(led),

    /*
     * UART: 115200 bps, 8N1
     */
    .uart_rxd(uart_rxd_int),
    .uart_txd(uart_txd),
    .uart_rts(uart_rts_int),
    .uart_cts(uart_cts),

    /*
     * I2C
     */
    .i2c_scl_i(i2c_scl_i),
    .i2c_scl_o(i2c_scl_o),
    .i2c_sda_i(i2c_sda_i),
    .i2c_sda_o(i2c_sda_o),

    /*
     * Ethernet: 1000BASE-X SFP
     */
    .sfp_gmii_clk(sfp_gmii_clk_int),
    .sfp_gmii_rst(sfp_gmii_rst_int),
    .sfp_gmii_clk_en(sfp_gmii_clk_en_int),
    .sfp_gmii_rxd(sfp_gmii_rxd_int),
    .sfp_gmii_rx_dv(sfp_gmii_rx_dv_int),
    .sfp_gmii_rx_er(sfp_gmii_rx_er_int),
    .sfp_gmii_txd(sfp_gmii_txd_int),
    .sfp_gmii_tx_en(sfp_gmii_tx_en_int),
    .sfp_gmii_tx_er(sfp_gmii_tx_er_int),
    .sfp_tx_disable(sfp_tx_disable),
    .sfp_rx_los(sfp_rx_los),

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    .phy_rx_clk(phy_rx_clk),
    .phy_rxd(phy_rxd_int),
    .phy_rx_ctl(phy_rx_ctl_int),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_ctl(phy_tx_ctl),
    .phy_reset_n(phy_reset_n)
);

endmodule

`resetall
