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
 * 10G Ethernet PHY frame sync
 */
module taxi_eth_phy_10g_rx_frame_sync #
(
    parameter HDR_W = 2,
    parameter BITSLIP_HIGH_CYCLES = 1,
    parameter BITSLIP_LOW_CYCLES = 7
)
(
    input  wire logic              clk,
    input  wire logic              rst,

    /*
     * SERDES interface
     */
    input  wire logic [HDR_W-1:0]  serdes_rx_hdr,
    input  wire logic              serdes_rx_hdr_valid,
    output wire logic              serdes_rx_bitslip,

    /*
     * Status
     */
    output wire logic              rx_block_lock
);

localparam BITSLIP_MAX_CYCLES = BITSLIP_HIGH_CYCLES > BITSLIP_LOW_CYCLES ? BITSLIP_HIGH_CYCLES : BITSLIP_LOW_CYCLES;
localparam BITSLIP_COUNT_W = $clog2(BITSLIP_MAX_CYCLES);

// check configuration
if (HDR_W != 2)
    $fatal(0, "Error: HDR_W must be 2");

localparam [1:0]
    SYNC_DATA = 2'b10,
    SYNC_CTRL = 2'b01;

logic [5:0] sh_count_reg = 6'd0, sh_count_next;
logic [3:0] sh_invalid_count_reg = 4'd0, sh_invalid_count_next;
logic [BITSLIP_COUNT_W-1:0] bitslip_count_reg = '0, bitslip_count_next;

logic serdes_rx_bitslip_reg = 1'b0, serdes_rx_bitslip_next;

logic rx_block_lock_reg = 1'b0, rx_block_lock_next;

assign serdes_rx_bitslip = serdes_rx_bitslip_reg;
assign rx_block_lock = rx_block_lock_reg;

always_comb begin
    sh_count_next = sh_count_reg;
    sh_invalid_count_next = sh_invalid_count_reg;
    bitslip_count_next = bitslip_count_reg;

    serdes_rx_bitslip_next = serdes_rx_bitslip_reg;

    rx_block_lock_next = rx_block_lock_reg;

    if (bitslip_count_reg != 0) begin
        bitslip_count_next = bitslip_count_reg-1;
    end else if (serdes_rx_bitslip_reg) begin
        serdes_rx_bitslip_next = 1'b0;
        bitslip_count_next = BITSLIP_COUNT_W'(BITSLIP_LOW_CYCLES);
    end else if (!serdes_rx_hdr_valid) begin
        // wait for header
    end else if (serdes_rx_hdr == SYNC_CTRL || serdes_rx_hdr == SYNC_DATA) begin
        // valid header
        sh_count_next = sh_count_reg + 1;
        if (&sh_count_reg) begin
            // valid count overflow, reset
            sh_count_next = '0;
            sh_invalid_count_next = '0;
            if (sh_invalid_count_reg == 0) begin
                rx_block_lock_next = 1'b1;
            end
        end
    end else begin
        // invalid header
        sh_count_next = sh_count_reg + 1;
        sh_invalid_count_next = sh_invalid_count_reg + 1;
        if (!rx_block_lock_reg || &sh_invalid_count_reg) begin
            // invalid count overflow, lost block lock
            sh_count_next = '0;
            sh_invalid_count_next = '0;
            rx_block_lock_next = 1'b0;

            // slip one bit
            serdes_rx_bitslip_next = 1'b1;
            bitslip_count_next = BITSLIP_COUNT_W'(BITSLIP_HIGH_CYCLES);
        end else if (&sh_count_reg) begin
            // valid count overflow, reset
            sh_count_next = '0;
            sh_invalid_count_next = '0;
        end
    end
end

always_ff @(posedge clk) begin
    sh_count_reg <= sh_count_next;
    sh_invalid_count_reg <= sh_invalid_count_next;
    bitslip_count_reg <= bitslip_count_next;
    serdes_rx_bitslip_reg <= serdes_rx_bitslip_next;
    rx_block_lock_reg <= rx_block_lock_next;

    if (rst) begin
        sh_count_reg <= '0;
        sh_invalid_count_reg <= '0;
        bitslip_count_reg <= '0;
        serdes_rx_bitslip_reg <= 1'b0;
        rx_block_lock_reg <= 1'b0;
    end
end

endmodule

`resetall
