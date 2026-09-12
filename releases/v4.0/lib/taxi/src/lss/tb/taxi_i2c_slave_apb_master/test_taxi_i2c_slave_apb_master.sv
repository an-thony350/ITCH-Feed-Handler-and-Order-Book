// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025-2026 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * I2C slave APB master testbench
 */
module test_taxi_i2c_slave_apb_master #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter FILTER_LEN = 4,
    parameter APB_DATA_W = 32,
    parameter APB_ADDR_W = 16
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

logic i2c_scl_i;
logic i2c_scl_o;
logic i2c_sda_i;
logic i2c_sda_o;

taxi_apb_if #(
    .DATA_W(APB_DATA_W),
    .ADDR_W(APB_ADDR_W),
    .PAUSER_EN(0),
    .PWUSER_EN(0),
    .PRUSER_EN(0),
    .PBUSER_EN(0)
) m_apb();

logic busy;
logic [6:0] bus_address;
logic bus_addressed;
logic bus_active;

logic [15:0] prescale;
logic stop_on_idle;

logic enable;
logic [6:0] device_address;

taxi_i2c_slave_apb_master #(
    .FILTER_LEN(FILTER_LEN)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * I2C interface
     */
    .i2c_scl_i(i2c_scl_i),
    .i2c_scl_o(i2c_scl_o),
    .i2c_sda_i(i2c_sda_i),
    .i2c_sda_o(i2c_sda_o),

    /*
     * APB master interface
     */
    .m_apb(m_apb),

    /*
     * Status
     */
    .busy(busy),
    .bus_address(bus_address),
    .bus_addressed(bus_addressed),
    .bus_active(bus_active),

    /*
     * Configuration
     */
    .enable(enable),
    .device_address(device_address)
);

endmodule

`resetall
