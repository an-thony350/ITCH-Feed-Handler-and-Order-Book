`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 02.07.2026 15:13:38
// Design Name: Symbol Router
// Module Name: symbol_router
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2023.2
//
// Description: The symbol router holds the data handler signals as they are passed
// directly from the top module. It also takes the base values of all the relevant
// stocks that we track (note that this base price is pre-determined in the PS, and
// delivered through AXI GPIO).
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Make target locate and base price configurable from the top level
// Revision 0.03 - Restore fixed locate-1 routing and keep only PS-configurable base price
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


import hdl_header::*;


module symbol_router(
    input   logic                   clk,
    input   logic                   rst_n,

    // base-price configuration from PS, normally driven by AXI GPIO
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

localparam logic [STOCK_W-1:0] ROUTED_LOCATE = STOCK_W'(1);

logic locate_match;

assign locate_match = (rdata_i.stock_locate == ROUTED_LOCATE);

// Non-target messages are consumed and dropped without inheriting order-book
// backpressure. The notebook rewrites the selected symbol's locate to 1.
assign ready_o = (!valid_i) || (!locate_match) || ready_i;

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
