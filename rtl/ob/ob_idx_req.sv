`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 11.08.2026 15:45:04
// Design Name: Order Book Index Request Block
// Module Name: ob_idx_req
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: ZCU106
// Tool Versions: Vivado 2023.2
//
// Description: This module represents the IDX_REQ state in the old order book
//              design. This is mostly handling cam conditions
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Timing Optimisations
// Revision 1.00 - Forwading added for the CAM as well as event struct
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module ob_idx_req(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,

    // Event Data I/O
    input  ob_event_t           event_i,

    output ob_event_t           event_o,

    // Forwarded Event Data

    input  ob_event_t           idx_search_event_i,
    input  ob_event_t           upd_rd_tbl_event_i,

    output logic [2:0]          cam_frwd_match_o,

    // Computed Datapath I/O
    input  logic [63:0]         cam_reserved_i,

    output logic                latched_cam_hit_o,
    output logic [5:0]          latched_cam_match_idx_o,
    output logic                latched_cam_is_full_o,
    output logic [5:0]          latched_cam_free_idx_o,

    // External Memory I/O
    input order_entry_t [63:0]  cam
);

// internal registers

// CAM signals

logic           cam_hit;
logic [5:0]     cam_match_idx;
logic           cam_is_full;
logic [5:0]     cam_free_idx;
logic [63:0]    cam_match_vec;

// Comb. Logic for CAM
always_comb begin
    // Default Assignments
    cam_match_idx   =   '0;
    cam_is_full     =   1'b1;
    cam_free_idx    =   '0;

    // CAM hit logic
    for(int i = 0; i < 64; i++) begin
        cam_match_vec[i]    =   (cam[i].valid && ~cam[i].tombstone && (cam[i].orn == event_i.rdata.orn));
    end

    cam_hit = |cam_match_vec;

    // CAM matching logic
    for(int i = 0; i < 64; i++) begin
        if(cam_match_vec[i]) cam_match_idx = cam_match_idx | 6'(i);
    end

    // Free slot finder (priority encoder)
    for(int i = 63; i >= 0; i--) begin
        if((~cam[i].valid || cam[i].tombstone) && ~cam_reserved_i[i]) begin
            cam_is_full     =   1'b0;
            cam_free_idx    =   6'(i);
        end
    end
end

// Forwarding Logic

always_ff @(posedge clk) begin
    if(!rst_n) cam_frwd_match_o <=  '0;
    else begin
        cam_frwd_match_o[0] <= event_o.valid            && (event_o.rdata.orn            == event_i.rdata.orn);
        cam_frwd_match_o[1] <= idx_search_event_i.valid && (idx_search_event_i.rdata.orn == event_i.rdata.orn);
        cam_frwd_match_o[2] <= upd_rd_tbl_event_i.valid && (upd_rd_tbl_event_i.rdata.orn == event_i.rdata.orn);
    end
end

// Sequential logic

always_ff @(posedge clk) begin
    if(!rst_n) begin
        event_o.valid               <=  1'b0;
    end
    else begin
        event_o.valid               <=  event_i.valid;
        event_o.rdata               <=  event_i.rdata;
        event_o.is_add              <=  event_i.is_add;
        event_o.is_reduce           <=  event_i.is_reduce;
        event_o.is_delete           <=  event_i.is_delete;
        event_o.rep_delete          <=  event_i.rep_delete;
        event_o.rep_add             <=  event_i.rep_add;
        event_o.hash_idx            <=  event_i.hash_idx;

        latched_cam_hit_o           <=  cam_hit;
        latched_cam_match_idx_o     <=  cam_match_idx;
        latched_cam_is_full_o       <=  cam_is_full;
        latched_cam_free_idx_o      <=  cam_free_idx;
    end
end

endmodule
