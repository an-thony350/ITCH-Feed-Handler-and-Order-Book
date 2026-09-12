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
    parameter string FAMILY = "virtex7",
    // 10G MAC configuration
    parameter logic CFG_LOW_LATENCY = 1'b1,
    parameter logic COMBINED_MAC_PCS = 1'b1
)
(
    /*
     * Clock: 200MHz LVDS
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
    input  wire logic [7:0]  sw,
    output wire logic [7:0]  led,

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
    input  wire logic        sfp_rx_p[4],
    input  wire logic        sfp_rx_n[4],
    output wire logic        sfp_tx_p[4],
    output wire logic        sfp_tx_n[4],
    input  wire logic        sfp_mgt_refclk_p,
    input  wire logic        sfp_mgt_refclk_n,
    // input  wire logic        sma_mgt_refclk_p,
    // input  wire logic        sma_mgt_refclk_n,
    // input  wire logic        sfp_recclk_p,
    // input  wire logic        sfp_recclk_n,

    output wire logic        si5324_rst,
    input  wire logic        si5324_int,

    input  wire logic        sfp_mod_detect[4],
    output wire logic [1:0]  sfp_rs[4],
    input  wire logic        sfp_los[4],
    output wire logic        sfp_tx_disable[4],
    input  wire logic        sfp_tx_fault[4]
);

// Clock and reset

wire clk_200mhz_ibufg;

// Internal 125 MHz clock
wire clk_125mhz_mmcm_out;
wire clk_125mhz_int;
wire rst_125mhz_int;

wire mmcm_rst = reset;
wire mmcm_locked;
wire mmcm_clkfb;

IBUFGDS
clk_200mhz_ibufgds_inst (
    .I(clk_200mhz_p),
    .IB(clk_200mhz_n),
    .O(clk_200mhz_ibufg)
);

// MMCM instance
MMCME2_BASE #(
    // 200 MHz input
    .CLKIN1_PERIOD(5.0),
    .REF_JITTER1(0.010),
    // 200 MHz input / 1 = 200 MHz PFD (range 10 MHz to 500 MHz)
    .DIVCLK_DIVIDE(1),
    // 200 MHz PFD * 5 = 1000 MHz VCO (range 600 MHz to 1440 MHz)
    .CLKFBOUT_MULT_F(5),
    .CLKFBOUT_PHASE(0),
    // 1000 MHz VCO / 8 = 125 MHz, 0 degrees
    .CLKOUT0_DIVIDE_F(8),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    // Not used
    .CLKOUT1_DIVIDE(1),
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
    // 200 MHz input
    .CLKIN1(clk_200mhz_ibufg),
    // direct clkfb feeback
    .CLKFBIN(mmcm_clkfb),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    // 125 MHz, 0 degrees
    .CLKOUT0(clk_125mhz_mmcm_out),
    .CLKOUT0B(),
    // Not used
    .CLKOUT1(),
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
    .I(clk_125mhz_mmcm_out),
    .O(clk_125mhz_int)
);

taxi_sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(clk_125mhz_int),
    .rst(~mmcm_locked),
    .out(rst_125mhz_int)
);

// GPIO
wire btnu_int;
wire btnl_int;
wire btnd_int;
wire btnr_int;
wire btnc_int;
wire [7:0] sw_int;

taxi_debounce_switch #(
    .WIDTH(5+8),
    .N(4),
    .RATE(125000)
)
debounce_switch_inst (
    .clk(clk_125mhz_int),
    .rst(rst_125mhz_int),
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
    .clk(clk_125mhz_int),
    .in({uart_rxd, uart_rts}),
    .out({uart_rxd_int, uart_rts_int})
);

wire [7:0] led_int;

// I2C
wire i2c_scl_i;
wire i2c_scl_o;
wire i2c_sda_i;
wire i2c_sda_o;

assign i2c_scl_i = i2c_scl;
assign i2c_scl = i2c_scl_o ? 1'bz : 1'b0;
assign i2c_sda_i = i2c_sda;
assign i2c_sda = i2c_sda_o ? 1'bz : 1'b0;

wire i2c_init_scl_i = i2c_scl_i;
wire i2c_init_scl_o;
wire i2c_init_sda_i = i2c_sda_i;
wire i2c_init_sda_o;

wire i2c_int_scl_i = i2c_scl_i;
wire i2c_int_scl_o;
wire i2c_int_sda_i = i2c_sda_i;
wire i2c_int_sda_o;

assign i2c_scl_o = i2c_init_scl_o & i2c_int_scl_o;
assign i2c_sda_o = i2c_init_sda_o & i2c_int_sda_o;

// Si5324 init
taxi_axis_if #(.DATA_W(12)) si5324_i2c_cmd();
taxi_axis_if #(.DATA_W(8)) si5324_i2c_tx();
taxi_axis_if #(.DATA_W(8)) si5324_i2c_rx();

assign si5324_i2c_rx.tready = 1'b1;

wire si5324_i2c_busy;

assign si5324_rst = ~rst_125mhz_int;

taxi_i2c_master
si5324_i2c_master_inst (
    .clk(clk_125mhz_int),
    .rst(rst_125mhz_int),

    /*
     * Host interface
     */
    .s_axis_cmd(si5324_i2c_cmd),
    .s_axis_tx(si5324_i2c_tx),
    .m_axis_rx(si5324_i2c_rx),

    /*
     * I2C interface
     */
    .scl_i(i2c_init_scl_i),
    .scl_o(i2c_init_scl_o),
    .sda_i(i2c_init_sda_i),
    .sda_o(i2c_init_sda_o),

    /*
     * Status
     */
    .busy(),
    .bus_control(),
    .bus_active(),
    .missed_ack(),

    /*
     * Configuration
     */
    .prescale(SIM ? 32 : 312),
    .stop_on_idle(1)
);

si5324_i2c_init #(
    .SIM_SPEEDUP(SIM)
)
si5324_i2c_init_inst (
    .clk(clk_125mhz_int),
    .rst(rst_125mhz_int),

    /*
     * I2C master interface
     */
    .m_axis_cmd(si5324_i2c_cmd),
    .m_axis_tx(si5324_i2c_tx),

    /*
     * Status
     */
    .busy(si5324_i2c_busy),

    /*
     * Configuration
     */
    .start(1'b1)
);

fpga_core #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .CFG_LOW_LATENCY(CFG_LOW_LATENCY),
    .COMBINED_MAC_PCS(COMBINED_MAC_PCS)
)
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk_125mhz(clk_125mhz_int),
    .rst_125mhz(rst_125mhz_int),

    /*
     * GPIO
     */
    .btnu(btnu_int),
    .btnl(btnl_int),
    .btnd(btnd_int),
    .btnr(btnr_int),
    .btnc(btnc_int),
    .sw(sw_int),
    .led(led_int),

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
    .i2c_scl_i(i2c_int_scl_i),
    .i2c_scl_o(i2c_int_scl_o),
    .i2c_sda_i(i2c_int_sda_i),
    .i2c_sda_o(i2c_int_sda_o),

    /*
     * Ethernet: SFP+
     */
    .sfp_rx_p(sfp_rx_p),
    .sfp_rx_n(sfp_rx_n),
    .sfp_tx_p(sfp_tx_p),
    .sfp_tx_n(sfp_tx_n),
    .sfp_mgt_refclk_p(sfp_mgt_refclk_p),
    .sfp_mgt_refclk_n(sfp_mgt_refclk_n),
    // .sma_mgt_refclk_p(sma_mgt_refclk_p),
    // .sma_mgt_refclk_n(sma_mgt_refclk_n),
    // .sfp_recclk_p(sfp_recclk_p),
    // .sfp_recclk_n(sfp_recclk_n),

    .sfp_mod_detect(sfp_mod_detect),
    .sfp_rs(sfp_rs),
    .sfp_los(sfp_los),
    .sfp_tx_disable(sfp_tx_disable),
    .sfp_tx_fault(sfp_tx_fault)
);

endmodule

`resetall
