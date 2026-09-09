`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 03.09.2026 13:23:01
// Design Name: Order Book BBO URAM delay Block 2
// Module Name: ob_uram_delay_bbo_2
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

module ob_uram_delay_bbo_2(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input logic                 latched_rep_delete_i,

    output logic                stage_valid_o,
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
        bid_is_zero_o           <=  '0;
        ask_is_zero_o           <=  '0;
    end
    else begin
        stage_valid_o           <=  stage_valid_i;
        bid_is_zero_o           <=  bid_is_zero_i;
        ask_is_zero_o           <=  ask_is_zero_i;
        latched_rep_delete_o    <=  latched_rep_delete_i;
    end
end

endmodule
