// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2016-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Generic source synchronous SDR input
 */
module ssio_sdr_in_diff #
(
    // simulation (set to avoid vendor primitives)
    parameter logic SIM = 1'b0,
    // vendor ("GENERIC", "XILINX", "ALTERA")
    parameter string VENDOR = "XILINX",
    // device family
    parameter string FAMILY = "virtex7",
    // Width of register in bits
    parameter WIDTH = 1
)
(
    input  wire logic              input_clk_p,
    input  wire logic              input_clk_n,

    input  wire logic [WIDTH-1:0]  input_d_p,
    input  wire logic [WIDTH-1:0]  input_d_n,

    output wire logic              output_clk,

    output wire logic [WIDTH-1:0]  output_q
);

wire input_clk;
wire [WIDTH-1:0] input_d;

if (!SIM && VENDOR == "XILINX") begin
    // Xilinx/AMD device support

    IBUFDS
    clk_ibufds_inst (
        .I(input_clk_p),
        .IB(input_clk_n),
        .O(input_clk)
    );

    for (genvar n = 0; n < WIDTH; n = n + 1) begin
        IBUFDS
        data_ibufds_inst (
            .I(input_d_p[n]),
            .IB(input_d_n[n]),
            .O(input_d[n])
        );
    end

end else if (!SIM && VENDOR == "ALTERA") begin
    // Altera/Intel/Altera device support

    ALT_INBUF_DIFF
    clk_inbuf_diff_inst (
        .i(input_clk_p),
        .ibar(input_clk_n),
        .o(input_clk)
    );

    for (genvar n = 0; n < WIDTH; n = n + 1) begin
        ALT_INBUF_DIFF
        data_inbuf_diff_inst (
            .i(input_d_p[n]),
            .ibar(input_d_n[n]),
            .o(input_d[n])
        );
    end

end else begin
    // generic/simulation implementation (no vendor primitives)

    assign input_clk = input_clk_p;
    assign input_d = input_d_p;

end

taxi_ssio_sdr_in #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .WIDTH(WIDTH)
)
ssio_ddr_in_inst(
    .input_clk(input_clk),
    .input_d(input_d),
    .output_clk(output_clk),
    .output_q(output_q)
);

endmodule

`resetall
