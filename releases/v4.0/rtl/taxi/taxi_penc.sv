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
 * Priority encoder module
 */
module taxi_penc #
(
    parameter WIDTH = 4,
    // LSB priority selection
    parameter logic LSB_HIGH_PRIO = 1'b0
)
(
    input  wire logic [WIDTH-1:0]          input_mask,
    output wire logic                      output_valid,
    output wire logic [$clog2(WIDTH)-1:0]  output_index,
    output wire logic [WIDTH-1:0]          output_mask
);

// hopefully a temporary workaround
// verilator lint_off UNOPTFLAT

localparam CL_WIDTH = $clog2(WIDTH);
localparam LEVELS = WIDTH > 2 ? CL_WIDTH : 1;
localparam W = 2**LEVELS;

// pad input to even power of two
wire [W-1:0] mask = {{W-WIDTH{1'b0}}, input_mask};

wire [W/2-1:0] stage_valid[LEVELS];
wire [W/2-1:0] stage_enc[LEVELS];

// process input bits; generate valid bit and encoded bit for each pair
for (genvar n = 0; n < W/2; n = n + 1) begin : loop_in
    assign stage_valid[0][n] = |mask[n*2+1:n*2];
    if (LSB_HIGH_PRIO) begin
        // bit 0 is highest priority
        assign stage_enc[0][n] = !mask[n*2+0];
    end else begin
        // bit 0 is lowest priority
        assign stage_enc[0][n] = mask[n*2+1];
    end
end

// compress down to single valid bit and encoded bus
for (genvar l = 1; l < LEVELS; l = l + 1) begin : loop_levels
    for (genvar n = 0; n < W/(2*2**l); n = n + 1) begin : loop_compress
        assign stage_valid[l][n] = |stage_valid[l-1][n*2+1:n*2];
        if (LSB_HIGH_PRIO) begin
            // bit 0 is highest priority
            assign stage_enc[l][(n+1)*(l+1)-1:n*(l+1)] = stage_valid[l-1][n*2+0] ? {1'b0, stage_enc[l-1][(n*2+1)*l-1:(n*2+0)*l]} : {1'b1, stage_enc[l-1][(n*2+2)*l-1:(n*2+1)*l]};
        end else begin
            // bit 0 is lowest priority
            assign stage_enc[l][(n+1)*(l+1)-1:n*(l+1)] = stage_valid[l-1][n*2+1] ? {1'b1, stage_enc[l-1][(n*2+2)*l-1:(n*2+1)*l]} : {1'b0, stage_enc[l-1][(n*2+1)*l-1:(n*2+0)*l]};
        end
    end
end

assign output_valid = stage_valid[LEVELS-1][0];
assign output_index = CL_WIDTH'(stage_enc[LEVELS-1]);
assign output_mask = WIDTH'(output_valid) << output_index;

endmodule

`resetall
