// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2014-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Arbiter module
 */
module taxi_arbiter #
(
    parameter PORTS = 4,
    // select round robin arbitration
    parameter logic ARB_ROUND_ROBIN = 1'b1,
    // blocking arbiter enable
    parameter logic ARB_BLOCK = 1'b1,
    // block on acknowledge assert when nonzero, request deassert when 0
    parameter logic ARB_BLOCK_ACK = 1'b0,
    // LSB priority selection
    parameter logic LSB_HIGH_PRIO = 1'b0
)
(
    input  wire logic                      clk,
    input  wire logic                      rst,

    input  wire logic [PORTS-1:0]          req,
    input  wire logic [PORTS-1:0]          ack,

    output wire logic                      grant_valid,
    output wire logic [PORTS-1:0]          grant,
    output wire logic [$clog2(PORTS)-1:0]  grant_index
);

localparam CL_PORTS = $clog2(PORTS);

logic [PORTS-1:0] grant_reg = 'd0, grant_next;
logic grant_valid_reg = 1'b0, grant_valid_next;
logic [CL_PORTS-1:0] grant_index_reg = 'd0, grant_index_next;

assign grant_valid = grant_valid_reg;
assign grant = grant_reg;
assign grant_index = grant_index_reg;

wire req_valid;
wire [CL_PORTS-1:0] req_index;
wire [PORTS-1:0] req_mask;

taxi_penc #(
    .WIDTH(PORTS),
    .LSB_HIGH_PRIO(LSB_HIGH_PRIO)
)
penc_inst (
    .input_mask(req),
    .output_valid(req_valid),
    .output_index(req_index),
    .output_mask(req_mask)
);

logic [PORTS-1:0] mask_reg = 'd0, mask_next;

wire masked_req_valid;
wire [CL_PORTS-1:0] masked_req_index;
wire [PORTS-1:0] masked_req_mask;

if (ARB_ROUND_ROBIN) begin

    taxi_penc #(
        .WIDTH(PORTS),
        .LSB_HIGH_PRIO(LSB_HIGH_PRIO)
    )
    penc_masked (
        .input_mask(req & mask_reg),
        .output_valid(masked_req_valid),
        .output_index(masked_req_index),
        .output_mask(masked_req_mask)
    );

end else begin

    assign masked_req_valid = 1'b0;
    assign masked_req_index = '0;
    assign masked_req_mask = '0;

end

always_comb begin
    grant_next = 'd0;
    grant_valid_next = 1'b0;
    grant_index_next = 'd0;
    mask_next = mask_reg;

    if (ARB_BLOCK && !ARB_BLOCK_ACK && ((grant_reg & req) != 0)) begin
        // granted req still asserted; hold it
        grant_valid_next = grant_valid_reg;
        grant_next = grant_reg;
        grant_index_next = grant_index_reg;
    end else if (ARB_BLOCK && ARB_BLOCK_ACK && grant_valid && ((grant_reg & ack) == 0)) begin
        // granted req not yet acknowledged; hold it
        grant_valid_next = grant_valid_reg;
        grant_next = grant_reg;
        grant_index_next = grant_index_reg;
    end else if (req_valid) begin
        if (ARB_ROUND_ROBIN) begin
            if (masked_req_valid) begin
                grant_valid_next = 1'b1;
                grant_next = masked_req_mask;
                grant_index_next = masked_req_index;
                if (LSB_HIGH_PRIO) begin
                    mask_next = {PORTS{1'b1}} << (masked_req_index + 1);
                end else begin
                    mask_next = {PORTS{1'b1}} >> ((CL_PORTS+1)'(PORTS) - masked_req_index);
                end
            end else begin
                grant_valid_next = 1;
                grant_next = req_mask;
                grant_index_next = req_index;
                if (LSB_HIGH_PRIO) begin
                    mask_next = {PORTS{1'b1}} << (req_index + 1);
                end else begin
                    mask_next = {PORTS{1'b1}} >> ((CL_PORTS+1)'(PORTS) - req_index);
                end
            end
        end else begin
            grant_valid_next = 1'b1;
            grant_next = req_mask;
            grant_index_next = req_index;
        end
    end
end

always_ff @(posedge clk) begin
    grant_reg <= grant_next;
    grant_valid_reg <= grant_valid_next;
    grant_index_reg <= grant_index_next;
    mask_reg <= mask_next;

    if (rst) begin
        grant_reg <= 'd0;
        grant_valid_reg <= 1'b0;
        grant_index_reg <= 'd0;
        mask_reg <= 'd0;
    end
end

endmodule

`resetall
