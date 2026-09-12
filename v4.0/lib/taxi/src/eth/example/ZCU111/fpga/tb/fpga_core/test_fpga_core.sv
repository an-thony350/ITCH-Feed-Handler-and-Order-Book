// SPDX-License-Identifier: MIT
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA core logic testbench
 */
module test_fpga_core #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter logic SIM = 1'b1,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "zynquplusRFSOC",
    parameter ADC_CNT = 8,
    parameter ADC_SAMPLE_W = 16,
    parameter ADC_SAMPLE_CNT = 4,
    parameter DAC_CNT = ADC_CNT,
    parameter DAC_SAMPLE_W = ADC_SAMPLE_W,
    parameter DAC_SAMPLE_CNT = ADC_SAMPLE_CNT,
    parameter logic CFG_LOW_LATENCY = 1'b1,
    parameter logic COMBINED_MAC_PCS = 1'b1,
    parameter MAC_DATA_W = 64
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam ADC_DATA_W = ADC_SAMPLE_W*ADC_SAMPLE_CNT;
localparam DAC_DATA_W = DAC_SAMPLE_W*DAC_SAMPLE_CNT;

logic clk_125mhz;
logic rst_125mhz;
logic fpga_refclk;
logic fpga_sysref;

logic btnu;
logic btnl;
logic btnd;
logic btnr;
logic btnc;
logic [7:0] sw;
logic [7:0] led;

logic i2c0_scl_i;
logic i2c0_scl_o;
logic i2c0_sda_i;
logic i2c0_sda_o;
logic i2c1_scl_i;
logic i2c1_scl_o;
logic i2c1_sda_i;
logic i2c1_sda_o;

logic uart_rxd;
logic uart_txd;
logic uart_rts;
logic uart_cts;

logic sfp_rx_p[4];
logic sfp_rx_n[4];
logic sfp_tx_p[4];
logic sfp_tx_n[4];
logic sfp_mgt_refclk_0_p;
logic sfp_mgt_refclk_0_n;

logic [3:0] sfp_tx_disable_b;

logic axil_rfdc_clk;
logic axil_rfdc_rst;

taxi_axil_if #(
    .DATA_W(32),
    .ADDR_W(18)
) m_axil_rfdc();

logic axis_rfdc_clk;
logic axis_rfdc_rst;

taxi_axis_if #(
    .DATA_W(ADC_DATA_W),
    .KEEP_EN(1),
    .KEEP_W(ADC_SAMPLE_CNT),
    .LAST_EN(0),
    .USER_EN(0),
    .ID_EN(0),
    .DEST_EN(0)
) s_axis_adc[ADC_CNT]();

taxi_axis_if #(
    .DATA_W(DAC_DATA_W),
    .KEEP_EN(1),
    .KEEP_W(DAC_SAMPLE_CNT),
    .LAST_EN(0),
    .USER_EN(0),
    .ID_EN(0),
    .DEST_EN(0)
) m_axis_dac[DAC_CNT]();

fpga_core #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .ADC_CNT(ADC_CNT),
    .DAC_CNT(DAC_CNT),
    .CFG_LOW_LATENCY(CFG_LOW_LATENCY),
    .COMBINED_MAC_PCS(COMBINED_MAC_PCS),
    .MAC_DATA_W(MAC_DATA_W)
)
uut (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk_125mhz(clk_125mhz),
    .rst_125mhz(rst_125mhz),
    .fpga_refclk(fpga_refclk),
    .fpga_sysref(fpga_sysref),

    /*
     * GPIO
     */
    .btnu(btnu),
    .btnl(btnl),
    .btnd(btnd),
    .btnr(btnr),
    .btnc(btnc),
    .sw(sw),
    .led(led),

    /*
     * I2C for board management
     */
    .i2c0_scl_i(i2c0_scl_i),
    .i2c0_scl_o(i2c0_scl_o),
    .i2c0_sda_i(i2c0_sda_i),
    .i2c0_sda_o(i2c0_sda_o),
    .i2c1_scl_i(i2c1_scl_i),
    .i2c1_scl_o(i2c1_scl_o),
    .i2c1_sda_i(i2c1_sda_i),
    .i2c1_sda_o(i2c1_sda_o),

    /*
     * UART: 115200 bps, 8N1
     */
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd),
    .uart_rts(uart_rts),
    .uart_cts(uart_cts),

    /*
     * Ethernet: SFP+
     */
    .sfp_rx_p(sfp_rx_p),
    .sfp_rx_n(sfp_rx_n),
    .sfp_tx_p(sfp_tx_p),
    .sfp_tx_n(sfp_tx_n),
    .sfp_mgt_refclk_0_p(sfp_mgt_refclk_0_p),
    .sfp_mgt_refclk_0_n(sfp_mgt_refclk_0_n),

    .sfp_tx_disable_b(sfp_tx_disable_b),

    /*
     * RFDC
     */
    .axil_rfdc_clk(axil_rfdc_clk),
    .axil_rfdc_rst(axil_rfdc_rst),
    .m_axil_rfdc_wr(m_axil_rfdc),
    .m_axil_rfdc_rd(m_axil_rfdc),

    .axis_rfdc_clk(axis_rfdc_clk),
    .axis_rfdc_rst(axis_rfdc_rst),
    .s_axis_adc(s_axis_adc),
    .m_axis_dac(m_axis_dac)
);

endmodule

`resetall
