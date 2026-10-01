`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 08.09.2026 23:42:04
// Design Name: Order Book Replace Check Block
// Module Name: ob_replace_check
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module is used to check if we have a replace instruction
//              entering our system. If so, we will separate this instruction into
//              a delete and then an add instruction
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Timing Optimisations
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module ob_replace_check(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,

    output logic                ready_o

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input o_data_raw_t          input_rdata,

    output ob_event_t           event_o
);

logic        call_replace;

o_data_raw_t held_rdata;
o_data_t     passed_data;
logic        rep_add_valid;
logic        rep_delete;
logic        rep_add;
logic        send_bbo; // ensures we only send one bbo update for a replace instruction

assign ready_o = !call_replace;


// Combinational checking of replace instruction
always_comb begin
    passed_data     = '0;
    rep_delete      = 1'b0;
    rep_add         = 1'b0;
    rep_add_valid   = 1'b0;
    send_bbo        = 1'b1;

    if(call_replace) begin
        passed_data.message_type = MSG_ADD_A;
        passed_data.orn          = held_rdata.updated_orn;
        passed_data.side         = held_rdata.side;
        passed_data.shares       = held_rdata.shares;
        passed_data.price        = held_rdata.price;
        rep_add_valid            = 1'b1;
        rep_add                  = 1'b1;
    end
    else if(stage_valid_i && input_rdata.message_type == MSG_REPLACE && !call_replace) begin
        passed_data.orn          = input_rdata.orn;
        passed_data.message_type = MSG_DELETE;
        passed_data.side         = input_rdata.side;
        passed_data.shares       = input_rdata.shares;
        passed_data.price        = input_rdata.price;
        rep_delete               = 1'b1;
        rep_add_valid            = 1'b1;
        send_bbo                 = 1'b0;
    end
    else if(!call_replace) begin
        passed_data.message_type = input_rdata.message_type;
        passed_data.orn          = input_rdata.orn;
        passed_data.side         = input_rdata.side;
        passed_data.shares       = input_rdata.shares;
        passed_data.price        = input_rdata.price;
        rep_add_valid            = stage_valid_i;
    end
end

// Sequential logic handling replace instructions
always_ff @(posedge clk) begin
    if(!rst_n) begin
        call_replace  <= '0;
    end
    else begin
        call_replace    <=  1'b0;
        if(stage_valid_i && input_rdata.message_type == MSG_REPLACE && !call_replace) begin
            call_replace     <= 1'b1;
            held_rdata       <= input_rdata;
        end
    end
end

// Default sequential logic
always_ff @(posedge clk) begin
    if(!rst_n) begin
        event_o.valid           <=  1'b0;
    end
    else begin
        event_o.valid           <=  rep_add_valid;
        event_o.rdata           <=  passed_data;
        event_o.rep_delete      <=  rep_delete;
        event_o.rep_add         <=  rep_add;
        event_o.emit_bbo        <=  send_bbo;
        event_o.hash_idx        <=  hash_orn(passed_data.orn);
    end
end
endmodule
