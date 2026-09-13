// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2021-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * 10G Ethernet PHY serdes watchdog
 */
module taxi_eth_phy_10g_rx_watchdog #
(
    parameter HDR_W = 2,
    parameter COUNT_125US = 125000/6.4
)
(
    input  wire logic              clk,
    input  wire logic              rst,

    /*
     * SERDES interface
     */
    input  wire logic [HDR_W-1:0]  serdes_rx_hdr,
    input  wire logic              serdes_rx_hdr_valid,
    output wire logic              serdes_rx_reset_req,

    /*
     * Monitor inputs
     */
    input  wire logic              rx_bad_block,
    input  wire logic              rx_sequence_error,
    input  wire logic              rx_block_lock,
    input  wire logic              rx_high_ber,

    /*
     * Status
     */
    output wire logic              rx_status
);

// check configuration
if (HDR_W != 2)
    $fatal(0, "Error: HDR_W must be 2");

localparam COUNT_W = $clog2($rtoi(COUNT_125US)+1);
localparam logic [COUNT_W-1:0] COUNT_125US_INT = COUNT_W'($rtoi(COUNT_125US));

localparam [1:0]
    SYNC_DATA = 2'b10,
    SYNC_CTRL = 2'b01;

logic [COUNT_W-1:0] time_count_reg = '0, time_count_next;
logic [3:0] error_count_reg = '0, error_count_next;
logic [3:0] status_count_reg = '0, status_count_next;

logic saw_ctrl_sh_reg = 1'b0, saw_ctrl_sh_next;
logic [9:0] block_error_count_reg = '0, block_error_count_next;

logic serdes_rx_reset_req_reg = 1'b0, serdes_rx_reset_req_next;

logic rx_status_reg = 1'b0, rx_status_next;

assign serdes_rx_reset_req = serdes_rx_reset_req_reg;

assign rx_status = rx_status_reg;

always_comb begin
    error_count_next = error_count_reg;
    status_count_next = status_count_reg;

    saw_ctrl_sh_next = saw_ctrl_sh_reg;
    block_error_count_next = block_error_count_reg;

    serdes_rx_reset_req_next = 1'b0;

    rx_status_next = rx_status_reg;

    if (rx_block_lock) begin
        if (serdes_rx_hdr == SYNC_CTRL && serdes_rx_hdr_valid) begin
            saw_ctrl_sh_next = 1'b1;
        end
        if ((rx_bad_block || rx_sequence_error) && !(&block_error_count_reg)) begin
            block_error_count_next = block_error_count_reg + 1;
        end
    end else begin
        rx_status_next = 1'b0;
        status_count_next = '0;
    end

    if (time_count_reg != 0) begin
        time_count_next = time_count_reg-1;
    end else begin
        time_count_next = COUNT_125US_INT;

        if (!saw_ctrl_sh_reg || &block_error_count_reg) begin
            error_count_next = error_count_reg + 1;
            status_count_next = '0;
        end else begin
            error_count_next = '0;
            if (!(&status_count_reg)) begin
                status_count_next = status_count_reg + 1;
            end
        end

        if (&error_count_reg) begin
            error_count_next = '0;
            serdes_rx_reset_req_next = 1'b1;
        end

        if (&status_count_reg) begin
            rx_status_next = 1'b1;
        end

        saw_ctrl_sh_next = 1'b0;
        block_error_count_next = '0;
    end
end

always_ff @(posedge clk) begin
    time_count_reg <= time_count_next;
    error_count_reg <= error_count_next;
    status_count_reg <= status_count_next;
    saw_ctrl_sh_reg <= saw_ctrl_sh_next;
    block_error_count_reg <= block_error_count_next;
    rx_status_reg <= rx_status_next;

    if (rst) begin
        time_count_reg <= COUNT_125US_INT;
        error_count_reg <= '0;
        status_count_reg <= '0;
        saw_ctrl_sh_reg <= 1'b0;
        block_error_count_reg <= '0;
        rx_status_reg <= 1'b0;
    end
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        serdes_rx_reset_req_reg <= 1'b0;
    end else begin
        serdes_rx_reset_req_reg <= serdes_rx_reset_req_next;
    end
end

endmodule

`resetall
