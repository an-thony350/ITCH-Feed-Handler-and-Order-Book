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
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


import hdl_header::*;


module symbol_router(
    input   logic                   clk,
    input   logic                   rst_n,

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

    // stock outputs to order book - names will change
    output  logic                   valid_stock0_o
);

logic   [PRICE_W-1:0]   bp_list;
logic   [1:0]           target_idx;

// Temporarily initialised ROM here, we can change this later with a .mem file
initial begin
    bp_list = 32'h00_00_3A_98; // Stock 0: $150.00
end

assign ready_o = (!valid_i) || ready_i;

always_ff@(posedge clk) begin
    if(!rst_n) begin
        valid_stock0_o  <=  1'b0;
    end
    else begin
        valid_stock0_o  <=  1'b0;
        if(valid_i && ready_o) begin
            rdata_o.message_type     <=      rdata_i.message_type;
            rdata_o.orn              <=      rdata_i.orn;
            rdata_o.price            <=      rdata_i.price;
            rdata_o.shares           <=      rdata_i.shares;
            rdata_o.side             <=      rdata_i.side;
            rdata_o.updated_orn      <=      rdata_i.updated_orn;
            case(rdata_i.stock_locate) // actual values not added yet as stocks undecided
                16'd1:  begin
                    valid_stock0_o  <=  1'b1;
                    base_price_o    <=  bp_list;
                end
                default:    ;
            endcase
        end
    end
end

endmodule
