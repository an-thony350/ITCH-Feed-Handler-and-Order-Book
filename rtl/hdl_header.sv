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
//   Shared package for the ITCH decoder/order-book RTL and Phase-3 ingress chain.
//
//   Existing decoder/order-book types are preserved. Ingress-specific AXIS,
//   protocol, and error/status constants have been appended so the new ingress
//   modules can import this same package rather than introducing a second one.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Added ingress AXIS/protocol constants and derived type widths
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

package hdl_header;

    // Existing decoder/order-book contract widths
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

    // Derived packed widths. These avoid overloading existing BBO_W, which is
    // currently 12 in the project package rather than the packed bbo_t width.
    localparam int DATA_T_W   = $bits(data_t);    // 217
    localparam int O_DATA_T_W = $bits(o_data_t);  // 201
    localparam int BBO_T_W    = $bits(bbo_t);     // 128

    // Phase-3 ingress AXI4-Stream conventions
    parameter int AXIS_DATA_W = 64;
    parameter int AXIS_KEEP_W = AXIS_DATA_W / 8;

    typedef logic [AXIS_DATA_W-1:0] axis_data_t;
    typedef logic [AXIS_KEEP_W-1:0] axis_keep_t;

    // Byte-lane convention used by the ingress chain:
    //   lane 0 = tdata[63:56]
    //   lane 1 = tdata[55:48]
    //   ...
    //   lane 7 = tdata[7:0]
    // tkeep[7] corresponds to lane 0 / tdata[63:56].

    // Ethernet / IPv4 / UDP constants for the fixed-prefix frame cracker
    parameter int ETH_HDR_BYTES      = 14;
    parameter int IPV4_MIN_HDR_BYTES = 20;
    parameter int UDP_HDR_BYTES      = 8;
    parameter int L2_L4_HDR_BYTES    = ETH_HDR_BYTES
                                     + IPV4_MIN_HDR_BYTES
                                     + UDP_HDR_BYTES;  // 42

    parameter logic [15:0] ETHERTYPE_IPV4 = 16'h0800;
    parameter logic [7:0]  IP_PROTO_UDP   = 8'd17;
    parameter logic [3:0]  IPV4_IHL_MIN   = 4'd5;

    parameter int UDP_LEN_W   = 16;
    parameter int DGRAM_LEN_W = 16;  // UDP payload length = UDP length - 8

    // MoldUDP64 constants
    parameter int MOLD_SESSION_BYTES = 10;
    parameter int MOLD_SEQ_BYTES     = 8;
    parameter int MOLD_COUNT_BYTES   = 2;
    parameter int MOLD_HDR_BYTES     = MOLD_SESSION_BYTES
                                     + MOLD_SEQ_BYTES
                                     + MOLD_COUNT_BYTES; // 20

    parameter int MOLD_SESSION_W = 8 * MOLD_SESSION_BYTES; // 80
    parameter int MOLD_SEQ_W     = 8 * MOLD_SEQ_BYTES;     // 64
    parameter int MOLD_COUNT_W   = 8 * MOLD_COUNT_BYTES;   // 16
    parameter int MOLD_MSG_LEN_W = 16;

    parameter logic [MOLD_COUNT_W-1:0] MOLD_COUNT_HEARTBEAT = 16'h0000;
    parameter logic [MOLD_COUNT_W-1:0] MOLD_COUNT_EOS       = 16'hffff;

    // Status/error bit maps
    parameter int FRAME_ERR_W = 16;

    parameter int FRAME_ERR_BAD_ETHERTYPE = 0;
    parameter int FRAME_ERR_BAD_IP_VER    = 1;
    parameter int FRAME_ERR_BAD_IHL       = 2;
    parameter int FRAME_ERR_FRAGMENT      = 3;
    parameter int FRAME_ERR_BAD_PROTO     = 4;
    parameter int FRAME_ERR_BAD_UDP_PORT  = 5;
    parameter int FRAME_ERR_BAD_UDP_LEN   = 6;
    parameter int FRAME_ERR_RUNT_FRAME    = 7;
    parameter int FRAME_ERR_BAD_TKEEP     = 8;

    parameter int MOLD_ERR_W = 16;

    parameter int MOLD_ERR_SHORT_DGRAM    = 0;
    parameter int MOLD_ERR_LEN_OVERRUN    = 1;
    parameter int MOLD_ERR_COUNT_OVERRUN  = 2;
    parameter int MOLD_ERR_BAD_TKEEP      = 3;
    parameter int MOLD_ERR_EOS_PAYLOAD    = 4;

    parameter int REALIGN_ERR_W = 16;

    parameter int REALIGN_ERR_LEN_ZERO          = 0;
    parameter int REALIGN_ERR_PAYLOAD_UNDERFLOW = 1;
    parameter int REALIGN_ERR_PAYLOAD_OVERFLOW  = 2;
    parameter int REALIGN_ERR_BAD_TKEEP         = 3;

endpackage
