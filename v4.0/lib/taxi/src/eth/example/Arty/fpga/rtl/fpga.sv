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
    parameter string FAMILY = "artix7"
)
(
    /*
     * Clock: 100MHz
     * Reset: Push button, active low
     */
    input  wire logic        clk,
    input  wire logic        reset_n,

    /*
     * GPIO
     */
    input  wire logic [3:0]  sw,
    input  wire logic [3:0]  btn,
    output wire logic        led0_r,
    output wire logic        led0_g,
    output wire logic        led0_b,
    output wire logic        led1_r,
    output wire logic        led1_g,
    output wire logic        led1_b,
    output wire logic        led2_r,
    output wire logic        led2_g,
    output wire logic        led2_b,
    output wire logic        led3_r,
    output wire logic        led3_g,
    output wire logic        led3_b,
    output wire logic        led4,
    output wire logic        led5,
    output wire logic        led6,
    output wire logic        led7,

    /*
     * UART: 115200 bps, 8N1
     */
    input  wire logic        uart_rxd,
    output wire logic        uart_txd,

    /*
     * Ethernet: 100BASE-T MII
     */
    output wire logic        phy_ref_clk,
    input  wire logic        phy_rx_clk,
    input  wire logic [3:0]  phy_rxd,
    input  wire logic        phy_rx_dv,
    input  wire logic        phy_rx_er,
    input  wire logic        phy_tx_clk,
    output wire logic [3:0]  phy_txd,
    output wire logic        phy_tx_en,
    input  wire logic        phy_col,
    input  wire logic        phy_crs,
    output wire logic        phy_reset_n
);

// Clock and reset

wire clk_ibufg;

// Internal 125 MHz clock
wire clk_mmcm_out;
wire clk_int;
wire rst_int;

wire mmcm_rst = ~reset_n;
wire mmcm_locked;
wire mmcm_clkfb;

IBUFG
clk_ibufg_inst(
    .I(clk),
    .O(clk_ibufg)
);

wire clk_25mhz_mmcm_out;
wire clk_25mhz_int;

// MMCM instance
MMCME2_BASE #(
    // 100 MHz input
    .CLKIN1_PERIOD(10.0),
    .REF_JITTER1(0.010),
    // 100 MHz input / 1 = 100 MHz PFD (range 10 MHz to 550 MHz)
    .DIVCLK_DIVIDE(1),
    // 100 MHz PFD * 10 = 1000 MHz VCO (range 600 MHz to 1200 MHz)
    .CLKFBOUT_MULT_F(10),
    .CLKFBOUT_PHASE(0),
    // 1250 MHz VCO / 8 = 128 MHz, 0 degrees
    .CLKOUT0_DIVIDE_F(8),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    // 1250 MHz VCO / 40 = 25 MHz, 0 degrees
    .CLKOUT1_DIVIDE(40),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(0),
    // Not used
    .CLKOUT2_DIVIDE(1),
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
    // 100 MHz input
    .CLKIN1(clk_ibufg),
    // direct clkfb feedback
    .CLKFBIN(mmcm_clkfb),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    // 125 MHz, 0 degrees
    .CLKOUT0(clk_mmcm_out),
    .CLKOUT0B(),
    // 25 MHz, 0 degrees
    .CLKOUT1(clk_25mhz_mmcm_out),
    .CLKOUT1B(),
    // Not used
    .CLKOUT2(),
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
clk_25mhz_bufg_inst (
    .I(clk_25mhz_mmcm_out),
    .O(clk_25mhz_int)
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
wire [3:0] btn_int;
wire [3:0] sw_int;

taxi_debounce_switch #(
    .WIDTH(8),
    .N(4),
    .RATE(125000)
)
debounce_switch_inst (
    .clk(clk_int),
    .rst(rst_int),
    .in({btn,
        sw}),
    .out({btn_int,
        sw_int})
);

wire uart_rxd_int;

taxi_sync_signal #(
    .WIDTH(1),
    .N(2)
)
sync_signal_inst (
    .clk(clk_int),
    .in({uart_rxd}),
    .out({uart_rxd_int})
);

assign phy_ref_clk = clk_25mhz_int;

fpga_core #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY)
)
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk(clk_int),
    .rst(rst_int),

    /*
     * GPIO
     */
    .btn(btn_int),
    .sw(sw_int),
    .led0_r(led0_r),
    .led0_g(led0_g),
    .led0_b(led0_b),
    .led1_r(led1_r),
    .led1_g(led1_g),
    .led1_b(led1_b),
    .led2_r(led2_r),
    .led2_g(led2_g),
    .led2_b(led2_b),
    .led3_r(led3_r),
    .led3_g(led3_g),
    .led3_b(led3_b),
    .led4(led4),
    .led5(led5),
    .led6(led6),
    .led7(led7),

    /*
     * UART: 115200 bps, 8N1
     */
    .uart_rxd(uart_rxd_int),
    .uart_txd(uart_txd),

    /*
     * Ethernet: 100BASE-T MII
     */
    .phy_rx_clk(phy_rx_clk),
    .phy_rxd(phy_rxd),
    .phy_rx_dv(phy_rx_dv),
    .phy_rx_er(phy_rx_er),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_en(phy_tx_en),
    .phy_col(phy_col),
    .phy_crs(phy_crs),
    .phy_reset_n(phy_reset_n)
);

endmodule

`resetall
