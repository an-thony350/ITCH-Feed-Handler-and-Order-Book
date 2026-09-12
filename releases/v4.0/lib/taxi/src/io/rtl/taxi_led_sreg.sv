// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2020-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * LED shift register driver
 */
module taxi_led_sreg #(
    // number of LEDs
    parameter COUNT = 8,
    // invert output
    parameter logic INVERT = 1'b0,
    // reverse order
    parameter logic REVERSE = 1'b0,
    // interleave A and B inputs, otherwise only use A
    parameter logic INTERLEAVE = 1'b0,
    // clock prescale
    parameter PRESCALE = 31
)
(
    input  wire logic              clk,
    input  wire logic              rst,

    input  wire logic [COUNT-1:0]  led_a,
    input  wire logic [COUNT-1:0]  led_b,

    output wire logic              sreg_d,
    output wire logic              sreg_ld,
    output wire logic              sreg_clk
);

localparam COUNT_INT = INTERLEAVE ? COUNT*2 : COUNT;
localparam CL_COUNT = $clog2(COUNT_INT);
localparam CL_PRESCALE = $clog2(PRESCALE+1);

logic [CL_COUNT+1-1:0] count_reg = 0;
logic [CL_PRESCALE-1:0] prescale_count_reg = 0;
logic enable_reg = 1'b0;
logic update_reg = 1'b1;
logic cycle_reg = 1'b0;

logic [COUNT_INT-1:0] led_sync_reg_1 = 0;
logic [COUNT_INT-1:0] led_sync_reg_2 = 0;
logic [COUNT_INT-1:0] led_reg = 0;

logic sreg_d_reg = 1'b0;
logic sreg_ld_reg = 1'b0;
logic sreg_clk_reg = 1'b0;

assign sreg_d = INVERT ? !sreg_d_reg : sreg_d_reg;
assign sreg_ld = sreg_ld_reg;
assign sreg_clk = sreg_clk_reg;

wire [COUNT_INT-1:0] led_in;
wire [COUNT_INT-1:0] led_sync;

if (INTERLEAVE) begin
    for (genvar i = 0; i < COUNT; i = i + 1) begin
        assign led_in[i*2 +: 2] = {led_b[i], led_a[i]};
    end
end else begin
    assign led_in = led_a;
end

taxi_sync_signal #(
    .WIDTH(COUNT_INT),
    .N(2)
)
sync_inst (
    .clk(clk),
    .in(led_in),
    .out(led_sync)
);

always_ff @(posedge clk) begin
    enable_reg <= 1'b0;

    if (prescale_count_reg != 0) begin
        prescale_count_reg <= prescale_count_reg - 1;
    end else begin
        enable_reg <= 1'b1;
        prescale_count_reg <= PRESCALE;
    end

    if (enable_reg) begin
        if (cycle_reg) begin
            cycle_reg <= 1'b0;
            sreg_clk_reg <= 1'b1;
        end else if (count_reg != 0) begin
            sreg_clk_reg <= 1'b0;
            sreg_ld_reg <= 1'b0;

            if (count_reg < COUNT_INT) begin
                count_reg <= count_reg + 1;
                cycle_reg <= 1'b1;
                if (REVERSE) begin
                    sreg_d_reg <= led_reg[CL_COUNT'(COUNT_INT-1-count_reg)];
                end else begin
                    sreg_d_reg <= led_reg[CL_COUNT'(count_reg)];
                end
            end else begin
                count_reg <= 0;
                cycle_reg <= 1'b0;
                sreg_d_reg <= 1'b0;
                sreg_ld_reg <= 1'b1;
            end
        end else begin
            sreg_clk_reg <= 1'b0;
            sreg_ld_reg <= 1'b0;

            if (update_reg) begin
                update_reg <= 1'b0;

                count_reg <= 1;
                cycle_reg <= 1'b1;
                if (REVERSE) begin
                    sreg_d_reg <= led_reg[COUNT_INT-1];
                end else begin
                    sreg_d_reg <= led_reg[0];
                end
            end
        end
    end

    if (led_sync != led_reg) begin
        led_reg <= led_sync;
        update_reg <= 1'b1;
    end

    if (rst) begin
        count_reg <= 0;
        prescale_count_reg <= 0;
        enable_reg <= 1'b0;
        update_reg <= 1'b1;
        cycle_reg <= 1'b0;
        led_reg <= 0;
        sreg_d_reg <= 1'b0;
        sreg_ld_reg <= 1'b0;
        sreg_clk_reg <= 1'b0;
    end
end

endmodule

`resetall
