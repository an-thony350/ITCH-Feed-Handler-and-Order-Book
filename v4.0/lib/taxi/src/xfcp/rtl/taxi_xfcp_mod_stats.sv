// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * XFCP statistics counter module
 */
module taxi_xfcp_mod_stats #
(
    parameter XFCP_ID_STR = "Statistics",
    parameter logic [8*16-1:0] XFCP_EXT_ID = 0,
    parameter XFCP_EXT_ID_STR = "",
    parameter STAT_COUNT_W = 32,
    parameter logic STAT_STR_EN = 1'b1,
    parameter STAT_PIPELINE = 2
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * XFCP upstream port
     */
    taxi_axis_if.snk   xfcp_usp_ds,
    taxi_axis_if.src   xfcp_usp_us,

    /*
     * Statistics increment input
     */
    taxi_axis_if.snk   s_axis_stat
);

taxi_axis_if #(.DATA_W(8), .USER_EN(1), .USER_W(1)) xfcp_sw_ds[STAT_STR_EN ? 2 : 1](), xfcp_sw_us[STAT_STR_EN ? 2 : 1]();

taxi_xfcp_switch #(
    .XFCP_ID_STR(XFCP_ID_STR),
    .XFCP_EXT_ID(XFCP_EXT_ID),
    .XFCP_EXT_ID_STR(XFCP_EXT_ID_STR),
    .PORTS($size(xfcp_sw_us))
)
xfcp_sw_inst (
    .clk(clk),
    .rst(rst),

    /*
     * XFCP upstream port
     */
    .xfcp_usp_ds(xfcp_usp_ds),
    .xfcp_usp_us(xfcp_usp_us),

    /*
     * XFCP downstream ports
     */
    .xfcp_dsp_ds(xfcp_sw_ds),
    .xfcp_dsp_us(xfcp_sw_us)
);

taxi_axil_if #(
    .DATA_W(32),
    .ADDR_W(s_axis_stat.ID_W+$clog2(((STAT_COUNT_W+31)/32)*4))
) axil_if_stats();

taxi_stats_counter #(
    .STAT_COUNT_W(STAT_COUNT_W),
    .PIPELINE(STAT_PIPELINE)
)
stats_counter_inst (
    .clk(clk),
    .rst(rst),

    /*
     * Statistics increment input
     */
    .s_axis_stat(s_axis_stat),

    /*
     * AXI Lite register interface
     */
    .s_axil_wr(axil_if_stats),
    .s_axil_rd(axil_if_stats)
);

taxi_xfcp_mod_axil #(
    .XFCP_ID_TYPE(16'h8080),
    .XFCP_ID_STR("Statistics"),
    .XFCP_EXT_ID(XFCP_EXT_ID),
    .XFCP_EXT_ID_STR(XFCP_EXT_ID_STR),
    .COUNT_SIZE(16)
)
xfcp_mod_axil_inst (
    .clk(clk),
    .rst(rst),

    /*
     * XFCP upstream port
     */
    .xfcp_usp_ds(xfcp_sw_ds[0]),
    .xfcp_usp_us(xfcp_sw_us[0]),

    /*
     * AXI lite master interface
     */
    .m_axil_wr(axil_if_stats),
    .m_axil_rd(axil_if_stats)
);

if (STAT_STR_EN) begin

    taxi_axis_if #(
        .DATA_W(s_axis_stat.DATA_W),
        .KEEP_W(1),
        .LAST_EN(0),
        .ID_W(s_axis_stat.ID_W),
        .ID_EN(s_axis_stat.ID_EN),
        .USER_W(1),
        .USER_EN(s_axis_stat.USER_EN)
    )
    axis_stat_int();

    assign axis_stat_int.tdata = s_axis_stat.tdata;
    assign axis_stat_int.tvalid = s_axis_stat.tvalid;
    assign axis_stat_int.tready = s_axis_stat.tready;
    assign axis_stat_int.tid = s_axis_stat.tid;
    assign axis_stat_int.tuser = s_axis_stat.tuser;

    taxi_axil_if #(
        .DATA_W(32),
        .ADDR_W(s_axis_stat.ID_W+4)
    ) axil_if_strings();

    taxi_stats_strings_full #(
        .PIPELINE(STAT_PIPELINE)
    )
    stats_strings_inst (
        .clk(clk),
        .rst(rst),

        /*
         * Statistics increment input
         */
        .s_axis_stat(axis_stat_int),

        /*
         * AXI Lite register interface
         */
        .s_axil_wr(axil_if_strings),
        .s_axil_rd(axil_if_strings)
    );

    taxi_xfcp_mod_axil #(
        .XFCP_ID_TYPE(16'h8081),
        .XFCP_ID_STR("Stats Strings"),
        .XFCP_EXT_ID(XFCP_EXT_ID),
        .XFCP_EXT_ID_STR(XFCP_EXT_ID_STR),
        .COUNT_SIZE(16)
    )
    xfcp_mod_axil_inst (
        .clk(clk),
        .rst(rst),

        /*
         * XFCP upstream port
         */
        .xfcp_usp_ds(xfcp_sw_ds[1]),
        .xfcp_usp_us(xfcp_sw_us[1]),

        /*
         * AXI lite master interface
         */
        .m_axil_wr(axil_if_strings),
        .m_axil_rd(axil_if_strings)
    );

end

endmodule

`resetall
