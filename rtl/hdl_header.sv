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
    parameter int  ORN_W        =   64;
    parameter int  PRICE_W      =   32;
    parameter int  SHARES_W     =   32;
    parameter int  STOCK_W      =   16;
    parameter int  MSG_W        =   8;
    parameter int  HASH_W       =   10;
    parameter int  FIFO_W       =   11;
    parameter int  BBO_W        =   14;
    parameter int  CHUNK_W      =   6;
    parameter int  MAX_PROBES   =   2;

    localparam logic [MSG_W-1:0] MSG_ADD_A    = 8'h41; // A
    localparam logic [MSG_W-1:0] MSG_ADD_F    = 8'h46; // F
    localparam logic [MSG_W-1:0] MSG_EXEC     = 8'h45; // E
    localparam logic [MSG_W-1:0] MSG_EXEC_PX  = 8'h43; // C
    localparam logic [MSG_W-1:0] MSG_DELETE   = 8'h44; // D
    localparam logic [MSG_W-1:0] MSG_REPLACE  = 8'h55; // U
    localparam logic [MSG_W-1:0] MSG_CANCEL   = 8'h58; // X

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
    } o_data_raw_t;

    typedef struct packed {
        logic [MSG_W-1:0]       message_type;
        logic [ORN_W-1:0]       orn;
        logic                   side;
        logic [SHARES_W-1:0]    shares;
        logic [PRICE_W-1:0]     price;
    } o_data_t;

    typedef struct packed {
        logic [1:0]             stock_id;
        logic [PRICE_W-1:0]     bid_price;
        logic [SHARES_W-1:0]    bid_shares;
        logic [PRICE_W-1:0]     ask_price;
        logic [SHARES_W-1:0]    ask_shares;
    } bbo_t;

    typedef struct packed {
        logic                   valid;
        logic [ORN_W-1:0]       orn;
        logic                   side;
        logic [SHARES_W-1:0]    shares;
        logic [PRICE_W-1:0]     price;
        logic                   tombstone;
    } order_entry_t;

    // local params for order book

    localparam int HASH_DEPTH = (1 << HASH_W); // changed for Set_Associative Hashing
    localparam int BBO_DEPTH  = 1 << BBO_W;
    localparam int CHUNK_LEN  = 1 << (BBO_W-6);
    localparam int ENTRY_W    = $bits(order_entry_t);
    localparam int BUCKET_W   = 3 * ENTRY_W;

    // Relevant Order book functions

    function automatic logic is_add_msg(input logic [MSG_W-1:0] msg);
        return (msg == MSG_ADD_A) || (msg == MSG_ADD_F);
    endfunction

    function automatic logic is_reduce_msg(input logic [MSG_W-1:0] msg);
        return (msg == MSG_EXEC) || (msg == MSG_EXEC_PX) || (msg == MSG_CANCEL);
    endfunction

    // Hashing function
    function automatic logic [HASH_W-1:0] hash_orn(input logic [ORN_W-1:0] orn);
        logic [HASH_W-1:0] h;
        begin
            h = '0;
            for (int bit_i = 0; bit_i < ORN_W; bit_i++) begin
                h[bit_i % HASH_W] = h[bit_i % HASH_W] ^ orn[bit_i];
            end
            return h;
        end
    endfunction

    // Price logic (for price book) - Only works if delta < $164.83
    function automatic logic [BBO_W-1:0] price_to_idx(input logic [PRICE_W-1:0] price, input logic [PRICE_W-1:0] latched_base_price);
        (* use_dsp = "yes" *) logic [PRICE_W-1:0] delta;
        begin
            delta = price - latched_base_price;
            return delta[BBO_W-1:0];
        end
    endfunction

    function automatic logic [3:0] find_msb_16(input logic [15:0] v);
        casez (v)
            16'b1???????????????: return 4'd15;
            16'b01??????????????: return 4'd14;
            16'b001?????????????: return 4'd13;
            16'b0001????????????: return 4'd12;
            16'b00001???????????: return 4'd11;
            16'b000001??????????: return 4'd10;
            16'b0000001?????????: return 4'd9;
            16'b00000001????????: return 4'd8;
            16'b000000001???????: return 4'd7;
            16'b0000000001??????: return 4'd6;
            16'b00000000001?????: return 4'd5;
            16'b000000000001????: return 4'd4;
            16'b0000000000001???: return 4'd3;
            16'b00000000000001??: return 4'd2;
            16'b000000000000001?: return 4'd1;
            16'b0000000000000001: return 4'd0;
            default:              return 4'd0;
        endcase
    endfunction

    function automatic logic [3:0] find_lsb_16(input logic [15:0] v);
        casez(v)
            16'b???????????????1: return 4'd0;
            16'b??????????????10: return 4'd1;
            16'b?????????????100: return 4'd2;
            16'b????????????1000: return 4'd3;
            16'b???????????10000: return 4'd4;
            16'b??????????100000: return 4'd5;
            16'b?????????1000000: return 4'd6;
            16'b????????10000000: return 4'd7;
            16'b???????100000000: return 4'd8;
            16'b??????1000000000: return 4'd9;
            16'b?????10000000000: return 4'd10;
            16'b????100000000000: return 4'd11;
            16'b???1000000000000: return 4'd12;
            16'b??10000000000000: return 4'd13;
            16'b?100000000000000: return 4'd14;
            16'b1000000000000000: return 4'd15;
            default:              return 4'd0;
        endcase
    endfunction


    // Hierarchical Search: Level 1 (Find the 64-bit chunk)
    function automatic logic [(BBO_W-6)-1:0] find_msb_chunk(input logic [CHUNK_LEN-1:0] vec);
        logic [15:0] grp_nz;
        logic [3:0]  sub_idx [15:0];
        logic [3:0]  top_idx;
        for(int i = 0; i < 16; i++) begin
            grp_nz[i]   =   |vec[i*16 +: 16];
            sub_idx[i]  =   find_msb_16(vec[i*16 +: 16]);
        end

        top_idx = find_msb_16(grp_nz);

        return {top_idx, sub_idx[top_idx]};
    endfunction

    function automatic logic [(BBO_W-6)-1:0] find_lsb_chunk(input logic [CHUNK_LEN-1:0] vec);
        logic [15:0] grp_nz;
        logic [3:0]  sub_idx [15:0];
        logic [3:0]  top_idx;
        for(int i = 0; i < 16; i++) begin
            grp_nz[i]   =   |vec[i*16 +: 16];
            sub_idx[i]  =   find_lsb_16(vec[i*16 +: 16]);
        end

        top_idx = find_lsb_16(grp_nz);

        return {top_idx, sub_idx[top_idx]};
    endfunction

    // Hierarchical Search: Level 2 (Find the exact bit in the chunk)
    // Hierarchical Search: Level 2 (Find the exact bit in the 64-bit chunk)
    function automatic logic [5:0] find_msb_bit(input logic [63:0] vec);
        logic [3:0] grp_nz;
        logic [3:0] sub_idx [3:0];
        logic [1:0] top_idx;

        // Parallel 16-bit searches
        for (int i = 0; i < 4; i++) begin
            grp_nz[i]  = |vec[i*16 +: 16];
            sub_idx[i] = find_msb_16(vec[i*16 +: 16]);
        end

        casez (grp_nz)
            4'b1???: top_idx = 2'd3;
            4'b01??: top_idx = 2'd2;
            4'b001?: top_idx = 2'd1;
            4'b0001: top_idx = 2'd0;
            default: top_idx = 2'd0;
        endcase

        return {top_idx, sub_idx[top_idx]};
    endfunction

    function automatic logic [5:0] find_lsb_bit(input logic [63:0] vec);
        logic [3:0] grp_nz;
        logic [3:0] sub_idx [3:0];
        logic [1:0] top_idx;

        // Parallel 16-bit searches
        for (int i = 0; i < 4; i++) begin
            grp_nz[i]  = |vec[i*16 +: 16];
            sub_idx[i] = find_lsb_16(vec[i*16 +: 16]);
        end

        casez (grp_nz)
            4'b???1: top_idx = 2'd0;
            4'b??10: top_idx = 2'd1;
            4'b?100: top_idx = 2'd2;
            4'b1000: top_idx = 2'd3;
            default: top_idx = 2'd0;
        endcase

        return {top_idx, sub_idx[top_idx]};
    endfunction

    // Derived packed widths. These avoid overloading existing BBO_W, which is
    // currently 12 in the project package rather than the packed bbo_t width.
    localparam int DATA_T_W   = $bits(data_t);    // 217
    localparam int O_DATA_T_W = $bits(o_data_t);  // 201
    localparam int BBO_T_W    = $bits(bbo_t);     // 128

    // Phase-3 ingress AXI4-Stream conventions
    parameter int AXIS_DATA_W = 32;
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
