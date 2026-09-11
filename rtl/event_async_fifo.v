`timescale 1ns / 1ps
`default_nettype none

// Asynchronous FIFO for transferring one complete normalised ITCH event from
// the network clock domain into the order-book/data clock domain.
//
// Write side:
//   data_realign @ ingress clock
//
// Read side:
//   order_book_top @ data_clk
//
// The FIFO implementation itself is provided by AMD/Xilinx xpm_fifo_async.
// This wrapper only maps the existing valid/ready event interface onto the
// FIFO write/read enables.
module event_async_fifo (
    // Network / producer clock domain
    input  wire           wr_clk_i,
    input  wire           rst_i,

    input  wire [216:0]   s_data_i,
    input  wire           s_valid_i,
    output wire           s_ready_o,

    // Order-book / consumer clock domain
    input  wire           rd_clk_i,

    output wire [216:0]   m_data_o,
    output wire           m_valid_o,
    input  wire           m_ready_i
);

    localparam integer EVENT_W    = 217;
    localparam integer FIFO_DEPTH = 16;

    wire [EVENT_W-1:0] fifo_dout;

    wire fifo_full;
    wire fifo_empty;

    wire wr_rst_busy;
    wire rd_rst_busy;

    wire fifo_wr_en;
    wire fifo_rd_en;

    // Backpressure the data handler whenever the FIFO cannot safely accept a
    // complete event. full and wr_rst_busy are both synchronous to wr_clk_i.
    assign s_ready_o = !fifo_full && !wr_rst_busy;
    assign fifo_wr_en = s_valid_i && s_ready_o;

    // FWFT keeps the oldest queued event continuously visible on fifo_dout.
    // The event is removed only after a downstream valid/ready handshake.
    assign m_data_o  = fifo_dout;
    assign m_valid_o = !fifo_empty && !rd_rst_busy;
    assign fifo_rd_en = m_valid_o && m_ready_i;

    xpm_fifo_async #(
        .CDC_SYNC_STAGES     (2),
        .DOUT_RESET_VALUE    ("0"),
        .ECC_MODE            ("no_ecc"),
        .FIFO_MEMORY_TYPE    ("auto"),
        .FIFO_READ_LATENCY   (0),
        .FIFO_WRITE_DEPTH    (FIFO_DEPTH),
        .FULL_RESET_VALUE    (0),
        .PROG_EMPTY_THRESH   (10),
        .PROG_FULL_THRESH    (10),
        .RD_DATA_COUNT_WIDTH (5),
        .READ_DATA_WIDTH     (EVENT_W),
        .READ_MODE           ("fwft"),
        .RELATED_CLOCKS      (0),
        .SIM_ASSERT_CHK      (1),
        .USE_ADV_FEATURES    ("0000"),
        .WAKEUP_TIME         (0),
        .WRITE_DATA_WIDTH    (EVENT_W),
        .WR_DATA_COUNT_WIDTH (5)
    ) u_event_fifo (
        .almost_empty   (),
        .almost_full    (),
        .data_valid     (),
        .dbiterr        (),
        .dout           (fifo_dout),
        .empty          (fifo_empty),
        .full           (fifo_full),
        .overflow       (),
        .prog_empty     (),
        .prog_full      (),
        .rd_data_count  (),
        .rd_rst_busy    (rd_rst_busy),
        .sbiterr        (),
        .underflow      (),
        .wr_ack         (),
        .wr_data_count  (),
        .wr_rst_busy    (wr_rst_busy),

        .din            (s_data_i),
        .injectdbiterr  (1'b0),
        .injectsbiterr  (1'b0),
        .rd_clk         (rd_clk_i),
        .rd_en          (fifo_rd_en),
        .rst            (rst_i),
        .sleep          (1'b0),
        .wr_clk         (wr_clk_i),
        .wr_en          (fifo_wr_en)
    );

endmodule

`default_nettype wire
