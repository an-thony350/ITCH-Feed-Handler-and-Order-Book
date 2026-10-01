`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 11.08.2026 15:45:04
// Design Name: Order Book Idle Block
// Module Name: ob_idle
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module represents the IDLE state in the old order book design
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Timing Optimisations
// Revision 0.10 - ob event struct
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module ob_idle(
    // Control signals
    input logic                 clk,
    input logic                 rst_n,

    // Event Data I/O
    input  ob_event_t           event_i,

    output ob_event_t           event_o,

    // External Memory I/O - BRAM addr pins
    output logic [HASH_W-1:0]   hash_idx_o
);

assign hash_idx_o =  event_i.hash_idx;

always_ff @(posedge clk) begin
    if(!rst_n) begin
        event_o.valid           <=  1'b0;
    end
    else begin
        event_o.valid           <=  event_i.valid;
        event_o.rdata           <=  event_i.rdata;
        event_o.is_add          <=  is_add_msg(event_i.rdata.message_type);
        event_o.is_reduce       <=  is_reduce_msg(event_i.rdata.message_type);
        event_o.is_delete       <=  (event_i.rdata.message_type == MSG_DELETE);
        event_o.rep_delete      <=  event_i.rep_delete;
        event_o.rep_add         <=  event_i.rep_add;
        event_o.hash_idx        <=  event_i.hash_idx;
    end
end


endmodule
