// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * I2C slave testbench
 */
module test_taxi_i2c_slave #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter FILTER_LEN = 4
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

logic release_bus;
taxi_axis_if #(.DATA_W(8)) s_axis_tx();
taxi_axis_if #(.DATA_W(8)) m_axis_rx();

logic scl_i;
logic scl_o;
logic sda_i;
logic sda_o;

logic busy;
logic [6:0] bus_address;
logic bus_addressed;
logic bus_active;

logic [15:0] prescale;
logic stop_on_idle;

logic enable;
logic [6:0] device_address;
logic [6:0] device_address_mask;

taxi_i2c_slave #(
    .FILTER_LEN(FILTER_LEN)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * Host interface
     */
    .release_bus(release_bus),
    .s_axis_tx(s_axis_tx),
    .m_axis_rx(m_axis_rx),

    /*
     * I2C interface
     */
    .scl_i(scl_i),
    .scl_o(scl_o),
    .sda_i(sda_i),
    .sda_o(sda_o),

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
    .device_address(device_address),
    .device_address_mask(device_address_mask)
);

endmodule

`resetall
