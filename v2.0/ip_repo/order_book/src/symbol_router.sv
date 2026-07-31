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
// Revision 1.00 - Intorduction of multiple base prices & thus order books
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


import hdl_header::*;


module symbol_router(
    input   logic                   clk,
    input   logic                   rst_n,

    // base-price configuration from PS, normally driven by AXI GPIO
    input   logic   [PRICE_W-1:0]   base_price_stock0_i,
    input   logic   [PRICE_W-1:0]   base_price_stock1_i,
    input   logic   [PRICE_W-1:0]   base_price_stock2_i,

    // inputs from data handler
    input   data_t                  rdata_i,
    input   logic                   valid_i,

    // output to data handler
    output  logic                   ready_o,

    // input from order_book
    input   logic [3:0]             ready_i,

    // outputs to order book
    output  o_data_t                rdata_o,
    output  logic   [PRICE_W-1:0]   base_price_o,

    // stock output to order book
    output  logic                   valid_stock0_o,
    output  logic                   valid_stock1_o,
    output  logic                   valid_stock2_o
);

logic [1:0] target_idx;
logic [PRICE_W-1:0] target_base_price;
logic       is_price_msg;
logic       in_bounds;

always_comb begin
    target_idx  =   2'b00;
    case(rdata_i.stock_locate)
    16'd1:  target_idx  =   2'b01;
    16'd2:  target_idx  =   2'b10;
    16'd3:  target_idx  =   2'b11;
    default: ;
    endcase

    case(target_idx)
    2'd1:   target_base_price = base_price_stock0_i;
    2'd2:   target_base_price = base_price_stock1_i;
    2'd3:   target_base_price = base_price_stock2_i;
    default: target_base_price = '0;
    endcase

    is_price_msg = (rdata_i.message_type == 8'h41) ||
                   (rdata_i.message_type == 8'h46) ||
                   (rdata_i.message_type == 8'h55);

    in_bounds = (rdata_i.price >= target_base_price) &&
                ((rdata_i.price - target_base_price) < (1 << BBO_W));

end



assign ready_o = (!valid_i)  || ready_i[target_idx];

always_ff@(posedge clk) begin
    if(!rst_n) begin
        valid_stock0_o          <=  1'b0;
        valid_stock1_o          <=  1'b0;
        valid_stock2_o          <=  1'b0;
        base_price_o            <=  '0;
        rdata_o                 <=  '0;
    end
    else begin
        valid_stock0_o  <=  1'b0;
        valid_stock1_o  <=  1'b0;
        valid_stock2_o  <=  1'b0;

        if(valid_i && ready_o) begin
            rdata_o.message_type     <=      rdata_i.message_type;
            rdata_o.orn              <=      rdata_i.orn;
            rdata_o.price            <=      rdata_i.price;
            rdata_o.shares           <=      rdata_i.shares;
            rdata_o.side             <=      rdata_i.side;
            rdata_o.updated_orn      <=      rdata_i.updated_orn;

            if(is_price_msg && ~in_bounds) begin
                valid_stock0_o  <=  1'b0;
                valid_stock1_o  <=  1'b0;
                valid_stock2_o  <=  1'b0;
                base_price_o    <=  target_base_price;
            end
            else begin
                case(target_idx)

                2'd1: begin
                    valid_stock0_o  <=  1'b1;
                    base_price_o    <=  base_price_stock0_i;
                end

                2'd2: begin
                    valid_stock1_o  <=  1'b1;
                    base_price_o    <=  base_price_stock1_i;
                end
                2'd3: begin
                    valid_stock2_o  <=  1'b1;
                    base_price_o    <=  base_price_stock2_i;
                end

                default: begin
                    valid_stock0_o  <=  1'b0;
                    valid_stock1_o  <=  1'b0;
                    valid_stock2_o  <=  1'b0;
                end
                endcase
            end
        end
    end
end

endmodule
