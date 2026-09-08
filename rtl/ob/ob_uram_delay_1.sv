`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 02.09.2026 22:46:51
// Design Name: Order Book 1st URAM delay block Block
// Module Name: ob_uram_delay_1
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

module ob_uram_delay_1(
    // Control Signals
    input logic                 clk,
    input logic                 rst_n,
    input logic                 stall,

    // Instruction Data I/O
    input logic                 stage_valid_i,
    input o_data_t              latched_rdata_i,
    input logic [PRICE_W-1:0]   latched_base_price_i,
    input logic                 latched_is_add_i,
    input logic                 latched_is_reduce_i,
    input logic                 latched_is_delete_i,
    input logic                 latched_rep_delete_i,
    input logic                 latched_rep_add_i,

    output logic                stage_valid_o,
    output o_data_t             latched_rdata_o,
    output logic [PRICE_W-1:0]  latched_base_price_o,
    output logic                latched_is_add_o,
    output logic                latched_is_reduce_o,
    output logic                latched_is_delete_o,
    output logic                latched_rep_delete_o,
    output logic                latched_rep_add_o,

    // Computed DataPath I/O
    input logic [BBO_W-1:0]     latched_event_price_idx_i,
    input logic                 latched_is_cam_entry_i,
    input logic [5:0]           latched_cam_idx_i,
    input logic [1:0]           latched_slot_idx_i,
    input order_entry_t         latched_lookup_entry_i,
    input logic [BBO_W-1:0]     latched_lookup_price_idx_i,
    input logic [HASH_W-1:0]    latched_hash_idx_i,
    input order_entry_t [2:0]   latched_read_bucket_i,

    output logic [BBO_W-1:0]    latched_event_price_idx_o,
    output logic                latched_is_cam_entry_o,
    output logic [5:0]          latched_cam_idx_o,
    output logic [1:0]          latched_slot_idx_o,
    output order_entry_t        latched_lookup_entry_o,
    output logic [BBO_W-1:0]    latched_lookup_price_idx_o,
    output logic [HASH_W-1:0]   latched_hash_idx_o,
    output order_entry_t [2:0]  latched_read_bucket_o
);

always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o               <=  1'b0;
        latched_rdata_o             <=  '0;
        latched_base_price_o        <=  '0;
        latched_is_add_o            <=  1'b0;
        latched_is_reduce_o         <=  1'b0;
        latched_is_delete_o         <=  1'b0;
        latched_rep_delete_o        <=  1'b0;
        latched_rep_add_o           <=  1'b0;

        latched_event_price_idx_o   <=  '0;
        latched_is_cam_entry_o      <=  1'b0;
        latched_cam_idx_o           <=  '0;
        latched_slot_idx_o          <=  '0;
        latched_lookup_entry_o      <=  '0;
        latched_lookup_price_idx_o  <=  '0;
        latched_hash_idx_o          <=  '0;
        latched_read_bucket_o       <=  '0;
    end
    else if(!stall) begin
        stage_valid_o               <=  stage_valid_i;
        latched_rdata_o             <=  latched_rdata_i;
        latched_base_price_o        <=  latched_base_price_i;
        latched_is_add_o            <=  latched_is_add_i;
        latched_is_reduce_o         <=  latched_is_reduce_i;
        latched_is_delete_o         <=  latched_is_delete_i;
        latched_rep_delete_o        <=  latched_rep_delete_i;
        latched_rep_add_o           <=  latched_rep_add_i;

        latched_event_price_idx_o   <=  latched_event_price_idx_i;
        latched_is_cam_entry_o      <=  latched_is_cam_entry_i;
        latched_cam_idx_o           <=  latched_cam_idx_i;
        latched_slot_idx_o          <=  latched_slot_idx_i;
        latched_lookup_entry_o      <=  latched_lookup_entry_i;
        latched_lookup_price_idx_o  <=  latched_lookup_price_idx_i;
        latched_hash_idx_o          <=  latched_hash_idx_i;
        latched_read_bucket_o       <=  latched_read_bucket_i;
    end
end

endmodule
