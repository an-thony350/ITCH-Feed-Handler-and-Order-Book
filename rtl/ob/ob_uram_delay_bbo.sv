`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 03.09.2026 01:56:35
// Design Name: Order Book BBO URAM delay Block
// Module Name: ob_uram_delay_bbo
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module is a pipeline delay for reads of price books using URAM
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
import hdl_header::*;

module ob_uram_delay_bbo(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input logic [PRICE_W-1:0]   latched_base_price_i,
    input logic                 latched_rep_delete_i,

    output logic                stage_valid_o,
    output logic [PRICE_W-1:0]  latched_base_price_o,
    output logic                latched_rep_delete_o,

    // BBO Search I/O
    input logic                 bid_is_zero_i,
    input logic                 ask_is_zero_i,

    output logic                bid_is_zero_o,
    output logic                ask_is_zero_o
);

always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o           <=  1'b0;
        latched_base_price_o    <=  '0;
        bid_is_zero_o           <=  '0;
        ask_is_zero_o           <=  '0;
        latched_rep_delete_o    <=  1'b0;
    end
    else begin
        stage_valid_o           <=  stage_valid_i;
        latched_base_price_o    <=  latched_base_price_i;
        bid_is_zero_o           <=  bid_is_zero_i;
        ask_is_zero_o           <=  ask_is_zero_i;
        latched_rep_delete_o    <=  latched_rep_delete_i;
    end
end
endmodule
