`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02.07.2026 15:32:56
// Design Name:
// Module Name: hdl_header
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


package hdl_header;

    parameter int  ORN_W    = 64;
    parameter int  PRICE_W  = 32;
    parameter int  SHARES_W = 32;
    parameter int  STOCK_W  = 16;
    parameter int  MSG_W    = 8;
    parameter int  HASH_W   = 12;
    parameter int  FIFO_W   = 11;
    parameter int  BBO_W    = 12;

    typedef struct packed {
        logic [MSG_W-1:0]       message_type;
        logic [STOCK_W-1:0]     stock_locate;
        logic [ORN_W-1:0]       orn;
        logic [ORN_W-1:0]       updated_orn;
        logic                   side;
        logic [SHARES_W-1:0]    shares;
        logic [PRICE_W-1:0]     price;
    } data_t;

    typedef struct packed {
        logic [MSG_W-1:0]       message_type;
        logic [ORN_W-1:0]       orn;
        logic [ORN_W-1:0]       updated_orn;
        logic                   side;
        logic [SHARES_W-1:0]    shares;
        logic [PRICE_W-1:0]     price;
    } o_data_t;

    typedef struct packed {
        logic [PRICE_W-1:0]     bid_price;
        logic [SHARES_W-1:0]    bid_shares;
        logic [PRICE_W-1:0]     ask_price;
        logic [SHARES_W-1:0]    ask_shares;
    } bbo_t;

endpackage
