`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02.07.2026 15:13:38
// Design Name:
// Module Name: symbol_router
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Make target locate and base price configurable from the top level
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


import hdl_header::*;


module symbol_router(
    input   logic                   clk,
    input   logic                   rst_n,

    // configuration inputs from PS, normally driven by AXI GPIO
    input   logic   [STOCK_W-1:0]   target_locate_i,
    input   logic   [PRICE_W-1:0]   base_price_i,

    // inputs from data handler
    input   data_t                  rdata_i,
    input   logic                   valid_i,

    // output to data handler
    output  logic                   ready_o,

    // input from order_book
    input   logic                   ready_i,

    // outputs to order book
    output  o_data_t                rdata_o,
    output  logic   [PRICE_W-1:0]   base_price_o,

    // stock output to order book
    output  logic                   valid_stock0_o
);

logic locate_match;

assign locate_match = (rdata_i.stock_locate == target_locate_i);
assign ready_o      = (!valid_i) || (!locate_match) || ready_i;

always_ff@(posedge clk) begin
    if(!rst_n) begin
        valid_stock0_o  <=  1'b0;
        base_price_o    <=  '0;
        rdata_o         <=  '0;
    end
    else begin
        valid_stock0_o  <=  1'b0;
        if(valid_i && ready_o && locate_match) begin
            rdata_o.message_type     <=      rdata_i.message_type;
            rdata_o.orn              <=      rdata_i.orn;
            rdata_o.price            <=      rdata_i.price;
            rdata_o.shares           <=      rdata_i.shares;
            rdata_o.side             <=      rdata_i.side;
            rdata_o.updated_orn      <=      rdata_i.updated_orn;

            valid_stock0_o  <=  1'b1;
            base_price_o    <=  base_price_i;
        end
    end
end

endmodule
