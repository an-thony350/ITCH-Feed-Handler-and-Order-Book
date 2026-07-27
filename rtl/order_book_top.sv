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
// Revision 1.00 - Intorduction of multiple base prices & thus order books - also fixed
//                 naming conventions (i.e. internal regs named source_dest_signal)
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;

module order_book_top(
    input   logic                   clk,
    input   logic                   rst_n,

    // base-price configuration from PS, normally driven by AXI GPIO
    input   logic   [PRICE_W-1:0]   base_price_stock0_i,
    input   logic   [PRICE_W-1:0]   base_price_stock1_i,
    input   logic   [PRICE_W-1:0]   base_price_stock2_i,

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

logic [3:0]         ob_sr_ready_bus;
o_data_t            sr_ob_rdata;
logic [PRICE_W-1:0] sr_ob_base_price;
logic               sr_ob_valid_stock0;
logic               sr_ob_valid_stock1;
logic               sr_ob_valid_stock2;

bbo_t               bbo_stock_0;
bbo_t               bbo_stock_1;
bbo_t               bbo_stock_2;
logic               bbo_valid_0;
logic               bbo_valid_1;
logic               bbo_valid_2;


// Internal registers for bbo output FIFOs

bbo_t fifo_0 [15:0]; // depth of 16, can be changed
bbo_t fifo_1 [15:0];
bbo_t fifo_2 [15:0];

logic [3:0] wr_ptr_0, wr_ptr_1, wr_ptr_2;
logic [3:0] rd_ptr_0, rd_ptr_1, rd_ptr_2;
logic       empty_0, empty_1, empty_2;

// RR scheduler counter
logic [2:0]   count;

// empty fifo assignment - no full condition done here, could be an issue, but using RR scheduler so shldn't be an issue

assign empty_0  =   (wr_ptr_0 == rd_ptr_0);
assign empty_1  =   (wr_ptr_1 == rd_ptr_1);
assign empty_2  =   (wr_ptr_2 == rd_ptr_2);

assign ob_sr_ready_bus[0]   =   1'b1;


// Data Handler -> Symbol Router

symbol_router router(
    .clk                    (clk),
    .rst_n                  (rst_n),

    .base_price_stock0_i    (base_price_stock0_i),
    .base_price_stock1_i    (base_price_stock1_i),
    .base_price_stock2_i    (base_price_stock2_i),

    .rdata_i                (rdata_i),
    .valid_i                (valid_i),
    .ready_o                (ready_o),

    .ready_i                (ob_sr_ready_bus),
    .rdata_o                (sr_ob_rdata),
    .base_price_o           (sr_ob_base_price),
    .valid_stock0_o         (sr_ob_valid_stock0),
    .valid_stock1_o         (sr_ob_valid_stock1),
    .valid_stock2_o         (sr_ob_valid_stock2)
);

// Symbol Router -> Order Book

order_book ob_stock0(
    .clk          (clk),
    .rst_n        (rst_n),
    .rdata_i      (sr_ob_rdata),
    .valid_i      (sr_ob_valid_stock0),
    .base_price_i (sr_ob_base_price),
    .ready_o      (ob_sr_ready_bus[1]),
    .bbo_data_o   (bbo_stock_0),
    .bbo_valid_o  (bbo_valid_0)
);

order_book ob_stock1(
    .clk          (clk),
    .rst_n        (rst_n),
    .rdata_i      (sr_ob_rdata),
    .valid_i      (sr_ob_valid_stock1),
    .base_price_i (sr_ob_base_price),
    .ready_o      (ob_sr_ready_bus[2]),
    .bbo_data_o   (bbo_stock_1),
    .bbo_valid_o  (bbo_valid_1)
);

order_book ob_stock2(
    .clk          (clk),
    .rst_n        (rst_n),
    .rdata_i      (sr_ob_rdata),
    .valid_i      (sr_ob_valid_stock2),
    .base_price_i (sr_ob_base_price),
    .ready_o      (ob_sr_ready_bus[3]),
    .bbo_data_o   (bbo_stock_2),
    .bbo_valid_o  (bbo_valid_2)
);

// FIFO write logic

always_ff @(posedge clk) begin
    if(!rst_n) begin
        wr_ptr_0    <=  '0;
        wr_ptr_1    <=  '0;
        wr_ptr_2    <=  '0;

    end
    else begin
        if(bbo_valid_0) begin
            fifo_0[wr_ptr_0]    <=  bbo_stock_0;
            wr_ptr_0            <=  wr_ptr_0 + 4'(1);
        end
        if(bbo_valid_1) begin
            fifo_1[wr_ptr_1]    <=  bbo_stock_1;
            wr_ptr_1            <=  wr_ptr_1 + 4'(1);
        end
        if(bbo_valid_2) begin
            fifo_2[wr_ptr_2]    <=  bbo_stock_2;
            wr_ptr_2            <=  wr_ptr_2 + 4'(1);
        end
    end
end

// FIFO read logic & RR scheduler

always_ff @(posedge clk) begin
    if(!rst_n) begin
        rd_ptr_0    <=  '0;
        rd_ptr_1    <=  '0;
        rd_ptr_2    <=  '0;
        count       <=  3'b001;
        bbo_valid_o <=  '0;
        bbo_data_o  <=  '0;
    end
    else begin
        bbo_valid_o <=  1'b0;
        count       <=  {count[1:0], count[2]};

        casez (count)
        3'b??1: begin
            if(~empty_0) begin
                bbo_valid_o         <=  1'b1;
                bbo_data_o          <=  fifo_0[rd_ptr_0];
                bbo_data_o.stock_id <=  2'b01;
                rd_ptr_0            <=  rd_ptr_0 + 1;
            end
        end

        3'b?10: begin
            if(~empty_1) begin
                bbo_valid_o         <=  1'b1;
                bbo_data_o          <=  fifo_1[rd_ptr_1];
                bbo_data_o.stock_id <=  2'b10;
                rd_ptr_1            <=  rd_ptr_1 + 1;
            end
        end

        3'b100: begin
            if(~empty_2) begin
                bbo_valid_o         <=  1'b1;
                bbo_data_o          <=  fifo_2[rd_ptr_2];
                bbo_data_o.stock_id <=  2'b11;
                rd_ptr_2            <=  rd_ptr_2 + 1;
            end
        end
        default: ;
        endcase
    end
end

endmodule
