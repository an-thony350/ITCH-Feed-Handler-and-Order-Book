// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2018-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * 10G Ethernet PHY BER monitor
 */
module taxi_eth_phy_10g_rx_ber_mon #
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

    /*
     * Status
     */
    output wire logic              rx_high_ber
);

// check configuration
if (HDR_W != 2)
    $fatal(0, "Error: HDR_W must be 2");

localparam COUNT_W = $clog2($rtoi(COUNT_125US)+1);
localparam logic [COUNT_W-1:0] COUNT_125US_INT = COUNT_W'($rtoi(COUNT_125US));

localparam [1:0]
    SYNC_DATA = 2'b10,
    SYNC_CTRL = 2'b01;

logic [COUNT_W-1:0] time_count_reg = COUNT_125US_INT, time_count_next;
logic [3:0] ber_count_reg = 4'd0, ber_count_next;

logic rx_high_ber_reg = 1'b0, rx_high_ber_next;

assign rx_high_ber = rx_high_ber_reg;

always_comb begin
    if (time_count_reg > 0) begin
        time_count_next = time_count_reg-1;
    end else begin
        time_count_next = time_count_reg;
    end
    ber_count_next = ber_count_reg;

    rx_high_ber_next = rx_high_ber_reg;

    if (!serdes_rx_hdr_valid) begin
        // wait for header
    end else if (serdes_rx_hdr == SYNC_CTRL || serdes_rx_hdr == SYNC_DATA) begin
        // valid header
        if (ber_count_reg != 4'd15) begin
            if (time_count_reg == 0) begin
                rx_high_ber_next = 1'b0;
            end
        end
    end else begin
        // invalid header
        if (ber_count_reg == 4'd15) begin
            rx_high_ber_next = 1'b1;
        end else begin
            ber_count_next = ber_count_reg + 1;
            if (time_count_reg == 0) begin
                rx_high_ber_next = 1'b0;
            end
        end
    end
    if (time_count_reg == 0 && serdes_rx_hdr_valid) begin
        // 125 us timer expired
        ber_count_next = 4'd0;
        time_count_next = COUNT_125US_INT;
    end
end

always_ff @(posedge clk) begin
    time_count_reg <= time_count_next;
    ber_count_reg <= ber_count_next;
    rx_high_ber_reg <= rx_high_ber_next;

    if (rst) begin
        time_count_reg <= COUNT_125US_INT;
        ber_count_reg <= 4'd0;
        rx_high_ber_reg <= 1'b0;
    end
end

endmodule

`resetall
