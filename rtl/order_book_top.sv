`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 02.07.2026 15:13:38
// Design Name: Order Book Top
// Module Name: order_book_top
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2023.2
//
// Description: The top module for the order book takes signals from the data handler.
// It then passes it to the symbol router and then to the correct order books. The data
// is sent to each order book, but is only passed in these modules if they have an
// asserted valid signal.
// Each order book held its own fifo in the top module, storing the output bbo data
// (i.e. `bbo_data_o` and `bbo_valid_o`), and a round-robin scheduler allowing for a fair
// output of bbo data from fifo to DMA.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Add configurable target locate/base price and align router ports
// Revision 0.03 - Restore fixed locate-1 routing and retain only base-price control
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module order_book_top(
    input   logic                   clk,
    input   logic                   rst_n,

    // base-price configuration from PS, normally driven by AXI GPIO
    input   logic   [PRICE_W-1:0]   base_price_i,

    // inputs from data handler
    input   data_t                  rdata_i,
    input   logic                   valid_i,

    // output to data handler - from symbol router
    output  logic                   ready_o,

    // output to next block
    output  bbo_t                   bbo_data_o,
    output  logic                   bbo_valid_o
);

// Internal registers sr + ob regs

logic               sr_ob_ready;
o_data_t            ob_sr_rdata;
logic [PRICE_W-1:0] ob_sr_base_price;
logic               ob_sr_valid_stock0;

// Data Handler -> Symbol Router

symbol_router router(
    .clk             (clk),
    .rst_n           (rst_n),

    .base_price_i    (base_price_i),

    .rdata_i         (rdata_i),
    .valid_i         (valid_i),
    .ready_o         (ready_o),

    .ready_i         (sr_ob_ready),
    .rdata_o         (ob_sr_rdata),
    .base_price_o    (ob_sr_base_price),
    .valid_stock0_o  (ob_sr_valid_stock0)
);

// Symbol Router -> Order Book

order_book ob_stock0(
    .clk          (clk),
    .rst_n        (rst_n),
    .rdata_i      (ob_sr_rdata),
    .valid_i      (ob_sr_valid_stock0),
    .base_price_i (ob_sr_base_price),
    .ready_o      (sr_ob_ready),
    .bbo_data_o   (bbo_data_o),
    .bbo_valid_o  (bbo_valid_o)
);

endmodule
