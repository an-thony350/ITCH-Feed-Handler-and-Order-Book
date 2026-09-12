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
 * AXI4-Stream UART (RX)
 */
module taxi_uart_rx
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * AXI4-Stream output (source)
     */
    taxi_axis_if.src   m_axis_rx,

    /*
     * UART interface
     */
    input  wire logic  rxd,

    /*
     * Status
     */
    output wire logic  busy,
    output wire logic  overrun_error,
    output wire logic  frame_error,

    /*
     * Baud rate pulse in
     */
    input  wire logic  baud_clk

);

localparam DATA_W = m_axis_rx.DATA_W;

logic [DATA_W-1:0] m_axis_tdata_reg = 0;
logic m_axis_tvalid_reg = 1'b0;

logic rxd_reg = 1'b1;

logic overrun_error_reg = 1'b0;
logic frame_error_reg = 1'b0;

logic [DATA_W-1:0] data_reg = 0;
logic [2:0] baud_cnt_reg = 0;
logic run_reg = 1'b0;
logic start_reg = 1'b0;
logic stop_reg = 1'b0;

assign m_axis_rx.tdata = m_axis_tdata_reg;
assign m_axis_rx.tkeep = 1'b1;
assign m_axis_rx.tstrb = m_axis_rx.tkeep;
assign m_axis_rx.tvalid = m_axis_tvalid_reg;
assign m_axis_rx.tlast = 1'b1;
assign m_axis_rx.tid = '0;
assign m_axis_rx.tdest = '0;
assign m_axis_rx.tuser = '0;

assign busy = run_reg;
assign overrun_error = overrun_error_reg;
assign frame_error = frame_error_reg;

always_ff @(posedge clk) begin
    rxd_reg <= rxd;
    overrun_error_reg <= 1'b0;
    frame_error_reg <= 1'b0;

    if (m_axis_rx.tvalid && m_axis_rx.tready) begin
        m_axis_tvalid_reg <= 1'b0;
    end

    if (!baud_clk) begin
        // wait
    end else if (baud_cnt_reg != 0) begin
        baud_cnt_reg <= baud_cnt_reg - 1;
    end else if (run_reg) begin
        start_reg <= 1'b0;
        if (start_reg) begin
            // wait bit period for start bit
            baud_cnt_reg <= '1;
            if (rxd_reg) begin
                // start bit high, clear run bit
                run_reg <= 1'b0;
                frame_error_reg <= 1'b1;
            end
        end else begin
            {data_reg, stop_reg} <= {rxd_reg, data_reg};
            if (stop_reg) begin
                run_reg <= 1'b0;
                if (rxd_reg) begin
                    // stop bit high, transfer data
                    m_axis_tdata_reg <= data_reg;
                    m_axis_tvalid_reg <= 1'b1;
                    overrun_error_reg <= m_axis_tvalid_reg;
                end else begin
                    // stop bit low
                    frame_error_reg <= 1'b1;
                end
            end else begin
                baud_cnt_reg <= '1;
            end
        end
    end else begin
        data_reg <= {1'b1, {DATA_W-1{1'b0}}}; // marker bit
        start_reg <= 1'b1;
        stop_reg <= 1'b0;
        if (!rxd_reg) begin
            // falling edge of start bit
            // wait half bit period
            baud_cnt_reg <= 3'b011;
            run_reg <= 1'b1;
        end
    end

    if (rst) begin
        m_axis_tvalid_reg <= 1'b0;
        rxd_reg <= 1'b1;
        run_reg <= 1'b0;
        overrun_error_reg <= 1'b0;
        frame_error_reg <= 1'b0;
    end
end

endmodule

`resetall
