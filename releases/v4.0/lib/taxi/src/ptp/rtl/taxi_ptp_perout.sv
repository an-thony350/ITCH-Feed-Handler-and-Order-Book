// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2019-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * PTP period out module
 */
module taxi_ptp_perout #
(
    parameter logic FNS_EN = 1'b1,
    parameter OUT_START_S = 48'h0,
    parameter OUT_START_NS = 30'h0,
    parameter OUT_START_FNS = 16'h0000,
    parameter OUT_PERIOD_S = 48'd1,
    parameter OUT_PERIOD_NS = 30'd0,
    parameter OUT_PERIOD_FNS = 16'h0000,
    parameter OUT_WIDTH_S = 48'h0,
    parameter OUT_WIDTH_NS = 30'd1000,
    parameter OUT_WIDTH_FNS = 16'h0000
)
(
    input  wire logic         clk,
    input  wire logic         rst,

    /*
     * Timestamp input from PTP clock
     */
    input  wire logic [95:0]  input_ts_tod,
    input  wire logic         input_ts_tod_step,

    /*
     * Control
     */
    input  wire logic         enable,
    input  wire logic [95:0]  input_start,
    input  wire logic         input_start_valid,
    input  wire logic [95:0]  input_period,
    input  wire logic         input_period_valid,
    input  wire logic [95:0]  input_width,
    input  wire logic         input_width_valid,

    /*
     * Status
     */
    output wire logic         locked,
    output wire logic         error,

    /*
     * Pulse output
     */
    output wire logic         output_pulse
);

localparam [1:0]
    STATE_IDLE = 2'd0,
    STATE_UPDATE_RISE = 2'd1,
    STATE_UPDATE_FALL = 2'd2;

logic [1:0] state_reg = STATE_IDLE, state_next;

logic [47:0] time_s_reg = '0;
logic [29:0] time_ns_reg = '0;
logic [15:0] time_fns_reg = '0;

logic [47:0] next_rise_s_reg = '0, next_rise_s_next;
logic [29:0] next_rise_ns_reg = '0, next_rise_ns_next;
logic [15:0] next_rise_fns_reg = '0, next_rise_fns_next;

logic [47:0] next_edge_s_reg = '0, next_edge_s_next;
logic [29:0] next_edge_ns_reg = '0, next_edge_ns_next;
logic [15:0] next_edge_fns_reg = '0, next_edge_fns_next;

logic [47:0] start_s_reg = 48'(OUT_START_S);
logic [29:0] start_ns_reg = 30'(OUT_START_NS);
logic [15:0] start_fns_reg = 16'(OUT_START_FNS);

logic [47:0] period_s_reg = 48'(OUT_PERIOD_S);
logic [29:0] period_ns_reg = 30'(OUT_PERIOD_NS);
logic [15:0] period_fns_reg = 16'(OUT_PERIOD_FNS);

logic [47:0] width_s_reg = 48'(OUT_WIDTH_S);
logic [29:0] width_ns_reg = 30'(OUT_WIDTH_NS);
logic [15:0] width_fns_reg = 16'(OUT_WIDTH_FNS);

logic [29:0] ts_tod_ns_inc_reg = '0, ts_tod_ns_inc_next;
logic [15:0] ts_tod_fns_inc_reg = '0, ts_tod_fns_inc_next;
logic [30:0] ts_tod_ns_ovf_reg = '0, ts_tod_ns_ovf_next;
logic [15:0] ts_tod_fns_ovf_reg = '0, ts_tod_fns_ovf_next;

logic restart_reg = 1'b1;
logic locked_reg = 1'b0, locked_next;
logic error_reg = 1'b0, error_next;
logic ffwd_reg = 1'b0, ffwd_next;
logic level_reg = 1'b0, level_next;
logic output_reg = 1'b0, output_next;

assign locked = locked_reg;
assign error = error_reg;
assign output_pulse = output_reg;

always_comb begin
    state_next = STATE_IDLE;

    next_rise_s_next = next_rise_s_reg;
    next_rise_ns_next = next_rise_ns_reg;
    next_rise_fns_next = next_rise_fns_reg;

    next_edge_s_next = next_edge_s_reg;
    next_edge_ns_next = next_edge_ns_reg;
    next_edge_fns_next = next_edge_fns_reg;

    ts_tod_ns_inc_next = ts_tod_ns_inc_reg;
    ts_tod_fns_inc_next = ts_tod_fns_inc_reg;

    ts_tod_ns_ovf_next = ts_tod_ns_ovf_reg;
    ts_tod_fns_ovf_next = ts_tod_fns_ovf_reg;

    locked_next = locked_reg;
    error_next = error_reg;
    ffwd_next = ffwd_reg;
    level_next = level_reg;
    output_next = output_reg;

    case (state_reg)
        STATE_IDLE: begin
            if (ffwd_reg || level_reg) begin
                // fast forward or falling edge, set up for next rising edge
                // set next rise time to previous rise time plus period
                {ts_tod_ns_inc_next, ts_tod_fns_inc_next} = {next_rise_ns_reg, next_rise_fns_reg} + {period_ns_reg, period_fns_reg};
                {ts_tod_ns_ovf_next, ts_tod_fns_ovf_next} = {next_rise_ns_reg, next_rise_fns_reg} + {period_ns_reg, period_fns_reg} - {30'd1_000_000_000, 16'd0};
            end else begin
                // rising edge; set up for next falling edge
                // set next fall time to previous rise time plus width
                {ts_tod_ns_inc_next, ts_tod_fns_inc_next} = {next_rise_ns_reg, next_rise_fns_reg} + {width_ns_reg, width_fns_reg};
                {ts_tod_ns_ovf_next, ts_tod_fns_ovf_next} = {next_rise_ns_reg, next_rise_fns_reg} + {width_ns_reg, width_fns_reg} - {30'd1_000_000_000, 16'd0};
            end

            // wait for edge
            if ((time_s_reg > next_edge_s_reg) || (time_s_reg == next_edge_s_reg && {time_ns_reg, time_fns_reg} > {next_edge_ns_reg, next_edge_fns_reg})) begin
                if (ffwd_reg || level_reg) begin
                    // fast forward or falling edge, set up for next rising edge
                    output_next = 1'b0;
                    level_next = 1'b0;
                    state_next = STATE_UPDATE_RISE;
                end else begin
                    // rising edge; set up for next falling edge
                    locked_next = 1'b1;
                    error_next = 1'b0;
                    output_next = enable;
                    level_next = 1'b1;
                    state_next = STATE_UPDATE_FALL;
                end
            end else begin
                ffwd_next = 1'b0;
                state_next = STATE_IDLE;
            end
        end
        STATE_UPDATE_RISE: begin
            if (!ts_tod_ns_ovf_reg[30]) begin
                // if the overflow lookahead did not borrow, one second has elapsed
                next_edge_s_next = next_rise_s_reg + period_s_reg + 1;
                next_edge_ns_next = ts_tod_ns_ovf_reg[29:0];
                next_edge_fns_next = ts_tod_fns_ovf_reg;
            end else begin
                // no increment seconds field
                next_edge_s_next = next_rise_s_reg + period_s_reg;
                next_edge_ns_next = ts_tod_ns_inc_reg;
                next_edge_fns_next = ts_tod_fns_inc_reg;
            end
            next_rise_s_next = next_edge_s_next;
            next_rise_ns_next = next_edge_ns_next;
            next_rise_fns_next = next_edge_fns_next;
            state_next = STATE_IDLE;
        end
        STATE_UPDATE_FALL: begin
            if (!ts_tod_ns_ovf_reg[30]) begin
                // if the overflow lookahead did not borrow, one second has elapsed
                next_edge_s_next = next_rise_s_reg + width_s_reg + 1;
                next_edge_ns_next = ts_tod_ns_ovf_reg[29:0];
                next_edge_fns_next = ts_tod_fns_ovf_reg;
            end else begin
                // no increment seconds field
                next_edge_s_next = next_rise_s_reg + width_s_reg;
                next_edge_ns_next = ts_tod_ns_inc_reg;
                next_edge_fns_next = ts_tod_fns_inc_reg;
            end
            state_next = STATE_IDLE;
        end
        default: begin
            state_next = STATE_IDLE;
        end
    endcase

    if (restart_reg || input_ts_tod_step) begin
        // set next rise and next edge to start time
        next_rise_s_next = start_s_reg;
        next_rise_ns_next = start_ns_reg;
        if (FNS_EN) begin
            next_rise_fns_next = start_fns_reg;
        end
        next_edge_s_next = start_s_reg;
        next_edge_ns_next = start_ns_reg;
        if (FNS_EN) begin
            next_edge_fns_next = start_fns_reg;
        end
        locked_next = 1'b0;
        ffwd_next = 1'b1;
        output_next = 1'b0;
        level_next = 1'b0;
        error_next = input_ts_tod_step;
        state_next = STATE_IDLE;
    end
end

always_ff @(posedge clk) begin
    state_reg <= state_next;
    restart_reg <= 1'b0;

    time_s_reg <= input_ts_tod[95:48];
    time_ns_reg <= input_ts_tod[45:16];
    if (FNS_EN) begin
        time_fns_reg <= input_ts_tod[15:0];
    end

    if (input_start_valid) begin
        start_s_reg <= input_start[95:48];
        start_ns_reg <= input_start[45:16];
        if (FNS_EN) begin
            start_fns_reg <= input_start[15:0];
        end
        restart_reg <= 1'b1;
    end

    if (input_period_valid) begin
        period_s_reg <= input_period[95:48];
        period_ns_reg <= input_period[45:16];
        if (FNS_EN) begin
            period_fns_reg <= input_period[15:0];
        end
        restart_reg <= 1'b1;
    end

    if (input_width_valid) begin
        width_s_reg <= input_width[95:48];
        width_ns_reg <= input_width[45:16];
        if (FNS_EN) begin
            width_fns_reg <= input_width[15:0];
        end
    end

    next_rise_s_reg <= next_rise_s_next;
    next_rise_ns_reg <= next_rise_ns_next;
    if (FNS_EN) begin
        next_rise_fns_reg <= next_rise_fns_next;
    end

    next_edge_s_reg <= next_edge_s_next;
    next_edge_ns_reg <= next_edge_ns_next;
    if (FNS_EN) begin
        next_edge_fns_reg <= next_edge_fns_next;
    end

    ts_tod_ns_inc_reg <= ts_tod_ns_inc_next;
    if (FNS_EN) begin
        ts_tod_fns_inc_reg <= ts_tod_fns_inc_next;
    end

    ts_tod_ns_ovf_reg <= ts_tod_ns_ovf_next;
    if (FNS_EN) begin
        ts_tod_fns_ovf_reg <= ts_tod_fns_ovf_next;
    end

    locked_reg <= locked_next;
    error_reg <= error_next;
    ffwd_reg <= ffwd_next;
    level_reg <= level_next;
    output_reg <= output_next;

    if (rst) begin
        state_reg <= STATE_IDLE;

        start_s_reg <= 48'(OUT_START_S);
        start_ns_reg <= 30'(OUT_START_NS);
        start_fns_reg <= 16'(OUT_START_FNS);

        period_s_reg <= 48'(OUT_PERIOD_S);
        period_ns_reg <= 30'(OUT_PERIOD_NS);
        period_fns_reg <= 16'(OUT_PERIOD_FNS);

        width_s_reg <= 48'(OUT_WIDTH_S);
        width_ns_reg <= 30'(OUT_WIDTH_NS);
        width_fns_reg <= 16'(OUT_WIDTH_FNS);

        restart_reg <= 1'b1;
        locked_reg <= 1'b0;
        error_reg <= 1'b0;
        output_reg <= 1'b0;
    end
end

endmodule

`resetall
