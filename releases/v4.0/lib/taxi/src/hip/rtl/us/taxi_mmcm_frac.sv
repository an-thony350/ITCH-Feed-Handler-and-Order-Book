// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2024-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Fractional MMCM
 */
module taxi_mmcm_frac #(
    parameter MMCM_INPUT_CLK_PERIOD = 8.0,
    parameter MMCM_INPUT_REF_JITTER = 0.010,
    parameter MMCM_INPUT_DIV = 1,
    parameter MMCM_MULT = 8,
    parameter MMCM_OUTPUT_DIV = MMCM_MULT,
    parameter logic PSCLK_EN = 1'b0,
    parameter PSCLK_DIV = MMCM_OUTPUT_DIV,
    parameter logic EXTRA_MMCM = 1'b1,
    parameter MMCM2_CASC_DIV = MMCM_OUTPUT_DIV,
    parameter MMCM2_INPUT_DIV = 1,
    parameter MMCM2_MULT = MMCM_OUTPUT_DIV,
    parameter MMCM2_OUTPUT_DIV = MMCM2_MULT,
    parameter OFFSET_NUM = 1,
    parameter OFFSET_DENOM = 65536
)
(
    input  wire  input_clk,
    input  wire  input_rst,

    output wire  output_clk,
    output wire  output_offset_clk,
    output wire  locked
);

localparam MMCM_OUTPUT_CLK_PERIOD = MMCM_INPUT_CLK_PERIOD*MMCM_INPUT_DIV/MMCM_MULT*MMCM_OUTPUT_DIV;
localparam MMCM2_INPUT_CLK_PERIOD = MMCM_INPUT_CLK_PERIOD*MMCM_INPUT_DIV/MMCM_MULT*MMCM2_CASC_DIV;

localparam PSCLK_DIV_INT = PSCLK_EN ? PSCLK_DIV : MMCM_OUTPUT_DIV;

// 1 phase shifter tap is 1/56th of the VCO period
// To shift the frequency by OFFSET_NUM/OFFSET_DENOM, we need to shift the VCO output
// by OFFSET_NUM VCO periods (56*OFFSET_NUM taps) every OFFSET_DENOM VCO periods.
// Since the PSCLK is divided with respect to the VCO, rescale numerator by division factor
localparam DIR = OFFSET_NUM >= 0;
localparam NUM_1 = (DIR ? OFFSET_NUM : -OFFSET_NUM)*56*PSCLK_DIV_INT;
localparam DENOM_1 = OFFSET_DENOM;

localparam MMCM_MIN_PSCLK_CYCLES = 12;

if (DENOM_1 / NUM_1 < MMCM_MIN_PSCLK_CYCLES)
    $fatal(0, "Error: requested offset is too large for MMCM dynamic phase shifter");

localparam CNT_W = $clog2(DENOM_1)+1;

wire mmcm_locked;
wire mmcm2_locked;

wire mmcm_clkfb;
wire mmcm_clk_out;
wire mmcm_clk_bufg;
wire mmcm_offset_clk_out;
wire mmcm_offset_clk_bufg;
wire mmcm_ps_clk_out;
wire mmcm_ps_clk_bufg;

wire mmcm2_clkfb;
wire mmcm2_offset_clk_out;
wire mmcm2_offset_clk_bufg;

assign locked = mmcm_locked && mmcm2_locked;

assign output_clk = mmcm_clk_bufg;
assign output_offset_clk = EXTRA_MMCM ? mmcm2_offset_clk_bufg : mmcm_offset_clk_bufg;

wire ps_clk = PSCLK_EN ? mmcm_ps_clk_bufg : output_clk;

logic [CNT_W-1:0] cnt_reg = '0;

logic ps_en_reg = 1'b0;

always_ff @(posedge ps_clk) begin
    ps_en_reg <= 1'b0;

    if (cnt_reg + NUM_1 >= DENOM_1) begin
        cnt_reg <= cnt_reg + NUM_1 - DENOM_1;
        ps_en_reg <= 1'b1;
    end else begin
        cnt_reg <= cnt_reg + NUM_1;
    end
end

MMCME3_ADV #(
    // input clocks
    .CLKIN1_PERIOD(MMCM_INPUT_CLK_PERIOD),
    .REF_JITTER1(MMCM_INPUT_REF_JITTER),
    .CLKIN2_PERIOD(0.000),
    .REF_JITTER2(0.010),
    // divide for PFD input
    // US/US+: range 10 MHz to 500 MHz
    .DIVCLK_DIVIDE(MMCM_INPUT_DIV),
    // multiply for VCO output
    // US: range 600 MHz to 1440 MHz
    // US+: range 800 MHz to 1600 MHz
    .CLKFBOUT_MULT_F(MMCM_MULT),
    .CLKFBOUT_PHASE(0),
    .CLKFBOUT_USE_FINE_PS("FALSE"),
    // divide
    .CLKOUT0_DIVIDE_F(MMCM_OUTPUT_DIV),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    .CLKOUT0_USE_FINE_PS("FALSE"),
    // divide and phase shift
    .CLKOUT1_DIVIDE(EXTRA_MMCM ? MMCM2_CASC_DIV : MMCM_OUTPUT_DIV),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(0),
    .CLKOUT1_USE_FINE_PS("TRUE"),
    // phase shifter clock
    .CLKOUT2_DIVIDE(PSCLK_EN ? PSCLK_DIV : 1),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0),
    .CLKOUT2_USE_FINE_PS("FALSE"),
    // Not used
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0),
    .CLKOUT3_USE_FINE_PS("FALSE"),
    // Not used
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0),
    .CLKOUT4_USE_FINE_PS("FALSE"),
    .CLKOUT4_CASCADE("FALSE"),
    // Not used
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0),
    .CLKOUT5_USE_FINE_PS("FALSE"),
    // Not used
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT6_PHASE(0),
    .CLKOUT6_USE_FINE_PS("FALSE"),
    // no spread spectrum
    .SS_EN("FALSE"),
    .SS_MODE("CENTER_HIGH"),
    .SS_MOD_PERIOD(10000),

    .COMPENSATION("AUTO"),
    // optimized bandwidth
    .BANDWIDTH("OPTIMIZED"),
    // don't wait for lock during startup
    .STARTUP_WAIT("FALSE")
)
clk_mmcm_inst (
    // input clocks
    .CLKIN1(input_clk),
    .CLKIN2(1'b0),
    // select CLKIN1
    .CLKINSEL(1'b1),
    // direct clkfb feedback
    .CLKFBIN(mmcm_clkfb),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    // output (no offset)
    .CLKOUT0(mmcm_clk_out),
    .CLKOUT0B(),
    // offset output
    .CLKOUT1(mmcm_offset_clk_out),
    .CLKOUT1B(),
    // phase shifter clock
    .CLKOUT2(mmcm_ps_clk_out),
    .CLKOUT2B(),
    // Not used
    .CLKOUT3(),
    .CLKOUT3B(),
    // Not used
    .CLKOUT4(),
    // Not used
    .CLKOUT5(),
    // Not used
    .CLKOUT6(),
    // reset input
    .RST(input_rst),
    // don't power down
    .PWRDWN(1'b0),
    // DRP
    .DADDR(7'd0),
    .DI(16'd0),
    .DWE(1'b0),
    .DEN(1'b0),
    .DCLK(1'b0),
    .DO(),
    // dynamic phase shift
    .PSINCDEC(DIR ? 1'b0 : 1'b1),
    .PSEN(ps_en_reg),
    .PSCLK(ps_clk),
    .PSDONE(),
    // locked output
    .LOCKED(mmcm_locked),
    // input status
    .CLKINSTOPPED(),
    .CLKFBSTOPPED(),
    // CDDC
    .CDDCREQ(1'b0),
    .CDDCDONE()
);

BUFG
mmcm_clk_bufg_inst (
    .I(mmcm_clk_out),
    .O(mmcm_clk_bufg)
);

BUFG
mmcm_offset_clk_bufg_inst (
    .I(mmcm_offset_clk_out),
    .O(mmcm_offset_clk_bufg)
);

BUFG
mmcm_ps_clk_bufg_inst (
    .I(mmcm_ps_clk_out),
    .O(mmcm_ps_clk_bufg)
);

if (EXTRA_MMCM) begin : extra_mmcm

    // MMCM instance
    MMCME3_BASE #(
        // 125 MHz input
        .CLKIN1_PERIOD(MMCM2_INPUT_CLK_PERIOD),
        .REF_JITTER1(MMCM_INPUT_REF_JITTER),
        // divide for PFD input
        // US/US+: range 10 MHz to 500 MHz
        .DIVCLK_DIVIDE(MMCM2_INPUT_DIV),
        // multiply for VCO output
        // US: range 600 MHz to 1440 MHz
        // US+: range 800 MHz to 1600 MHz
        .CLKFBOUT_MULT_F(MMCM2_MULT),
        .CLKFBOUT_PHASE(0),
        // divide
        .CLKOUT0_DIVIDE_F(MMCM2_OUTPUT_DIV),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0),
        // Not used
        .CLKOUT1_DIVIDE(1),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0),
        // Not used
        .CLKOUT2_DIVIDE(1),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE(0),
        // Not used
        .CLKOUT3_DIVIDE(1),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE(0),
        // Not used
        .CLKOUT4_DIVIDE(1),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT4_PHASE(0),
        .CLKOUT4_CASCADE("FALSE"),
        // Not used
        .CLKOUT5_DIVIDE(1),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT5_PHASE(0),
        // Not used
        .CLKOUT6_DIVIDE(1),
        .CLKOUT6_DUTY_CYCLE(0.5),
        .CLKOUT6_PHASE(0),

        // optimized bandwidth
        .BANDWIDTH("OPTIMIZED"),
        // don't wait for lock during startup
        .STARTUP_WAIT("FALSE")
    )
    clk_mmcm2_inst (
        // 125 MHz input
        .CLKIN1(mmcm_offset_clk_bufg),
        // direct clkfb feeback
        .CLKFBIN(mmcm2_clkfb),
        .CLKFBOUT(mmcm2_clkfb),
        .CLKFBOUTB(),
        // 125 MHz, 0 degrees
        .CLKOUT0(mmcm2_offset_clk_out),
        .CLKOUT0B(),
        // Not used
        .CLKOUT1(),
        .CLKOUT1B(),
        // Not used
        .CLKOUT2(),
        .CLKOUT2B(),
        // Not used
        .CLKOUT3(),
        .CLKOUT3B(),
        // Not used
        .CLKOUT4(),
        // Not used
        .CLKOUT5(),
        // Not used
        .CLKOUT6(),
        // reset input
        .RST(input_rst || !mmcm_locked),
        // don't power down
        .PWRDWN(1'b0),
        // locked output
        .LOCKED(mmcm2_locked)
    );

    BUFG
    mmcm2_offset_clk_bufg_inst (
        .I(mmcm2_offset_clk_out),
        .O(mmcm2_offset_clk_bufg)
    );

end else begin

    assign mmcm2_locked = mmcm_locked;
    assign mmcm2_offset_clk_bufg = mmcm_offset_clk_bufg;

end

endmodule

`resetall
