`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineers: Anthony Bartlett & Denzil Erza-Essien
//
// Create Date: 27.06.2026 16:18:27
// Design Name: Data Handler
// Module Name: data_handler
// Project Name: Nasdaq-ITCH Feed Handler & Order Book
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2023.2
//
// Description: The Data Handler parses the data taken in the form detailled in the
//              Nasdaq TotalView-ITCH 5.0 specification
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Fix IDLE decode for A/F and use tlast for message completion
// Revision 0.03 - Migrate ITCH input datapath from 32-bit to native 64-bit words
// Revision 0.04 - Overlap SEND with acceptance of the next ITCH message
// Revision 0.05 - Decouple event output from message capture with an elastic register
// Additional Comments:
// This module has the following assumptions (which we can fix later
// depending on what we decide)
//
// - Assumes that upstream realign presents one ITCH message per AXI packet,
//   left-aligned into 64-bit words with the first message byte at [63:56]
// - Assumes we have a block before this, that slices out Ethernet/UDP/IPV4 bytes and
//   the only inputed bytes are the ITCH bytes
// - We are only parsing data from sections 1.3 & 1.4 - all other data is irrelevant
// - For adding orders to the book, we now treat both A and F as ADD. F's MPID field
//   is ignored for book state.
// - For order executed, we are including price message - (using section 1.4.2)
//
//////////////////////////////////////////////////////////////////////////////////

import hdl_header::*;


module data_handler#(
    ORN_W    = 64,
    PRICE_W  = 32,
    SHARES_W = 32,
    PACKET_W = 64,
    STOCK_W  = 16,
    MSG_W    = 8
)(
    input  logic                                                    clk,
    input  logic                                                    rst_n,

    // input from AXI-4 Stream
    input  logic [PACKET_W-1:0]                                     s_tdata_i,
    input  logic                                                    s_tvalid_i,
    input  logic                                                    s_tlast_i,

    // output to AXI-4 Stream
    output logic                                                    s_tready_o,

    // input from Order Book
    input  logic                                                    ready_i,

    // output to Order Book
    output data_t                                                   rdata_o,
    output logic                                                    valid_o
);

// Internal Variables

logic [3:0] word_count;
logic [3:0] word_count_next;

data_t data;
data_t data_next;

data_t output_data;
logic  output_valid;

logic input_fire;
logic event_complete;

// State Machine for state data is recieved in

typedef enum {  IDLE, ADD_CAP, MOD_CAP, SKIP } state_t;

state_t current_state, next_state;

localparam logic [MSG_W-1:0] MSG_ADD_A    = 8'h41; // A
localparam logic [MSG_W-1:0] MSG_ADD_F    = 8'h46; // F
localparam logic [MSG_W-1:0] MSG_EXEC     = 8'h45; // E
localparam logic [MSG_W-1:0] MSG_EXEC_PX  = 8'h43; // C
localparam logic [MSG_W-1:0] MSG_DELETE   = 8'h44; // D
localparam logic [MSG_W-1:0] MSG_REPLACE  = 8'h55; // U
localparam logic [MSG_W-1:0] MSG_CANCEL   = 8'h58; // X

initial begin
    if(PACKET_W != 64) begin
        $error("data_handler native parser requires PACKET_W == 64");
    end
end

function automatic logic is_add_msg(input logic [MSG_W-1:0] msg);
    return (msg == MSG_ADD_A) || (msg == MSG_ADD_F);
endfunction

function automatic logic is_modify_msg(input logic [MSG_W-1:0] msg);
    return (msg == MSG_EXEC) || (msg == MSG_EXEC_PX) ||
           (msg == MSG_DELETE) || (msg == MSG_REPLACE) ||
           (msg == MSG_CANCEL);
endfunction

// The output register is a one-entry elastic buffer. When it is empty, or when
// its current event is being consumed on this edge, the input parser may
// continue immediately. If the downstream event path stalls, stop the input
// parser so that no second completed event can overwrite the held output.
assign s_tready_o = rst_n && (!output_valid || ready_i);
assign input_fire = s_tvalid_i && s_tready_o;

// Case logic for next state

always_comb begin
    next_state = current_state;

    case(current_state)
        IDLE: begin
            if(input_fire) begin
                if(is_add_msg(s_tdata_i[63:56])) begin
                    next_state = s_tlast_i ? IDLE : ADD_CAP;
                end
                else if(is_modify_msg(s_tdata_i[63:56])) begin
                    next_state = s_tlast_i ? IDLE : MOD_CAP;
                end
                else begin
                    next_state = s_tlast_i ? IDLE : SKIP;
                end
            end
        end

        ADD_CAP: begin
            if(input_fire && s_tlast_i) begin
                next_state = IDLE;
            end
        end

        MOD_CAP: begin
            if(input_fire && s_tlast_i) begin
                next_state = IDLE;
            end
        end

        SKIP: begin
            if(input_fire && s_tlast_i) begin
                next_state = IDLE;
            end
        end

        default: next_state = IDLE;
    endcase
end

// Build the next parser state from the accepted input beat. Keeping this
// combinational copy lets the completed event include fields captured from the
// final beat before it is written into the elastic output register.

always_comb begin
    data_next       = data;
    word_count_next = word_count;
    event_complete  = 1'b0;

    if(input_fire) begin
        if(current_state == IDLE) begin
            // ITCH bytes 0..7:
            //   [63:56] message type
            //   [55:40] stock locate
            //   remaining bytes are tracking number/timestamp
            data_next.message_type = s_tdata_i[63:56];
            data_next.stock_locate = s_tdata_i[55:40];
            word_count_next        = '0;

            if(s_tdata_i[63:56] != MSG_REPLACE) begin
                data_next.updated_orn = '0;
            end

            if(!is_add_msg(s_tdata_i[63:56])) begin
                data_next.side  = '0;
                data_next.price = '0;
            end

            if(s_tlast_i &&
               (is_add_msg(s_tdata_i[63:56]) ||
                is_modify_msg(s_tdata_i[63:56]))) begin
                event_complete = 1'b1;
            end
        end
        else if(current_state == ADD_CAP) begin
            word_count_next = word_count + 1'b1;

            case(word_count)

                // Beat 1, ITCH bytes 8..15. The final five bytes are the
                // upper 40 bits of the order reference number.
                4'd0: data_next.orn[63:24] = s_tdata_i[39:0];

                // Beat 2, ITCH bytes 16..23:
                //   bytes 16..18 = lower ORN
                //   byte  19     = side
                //   bytes 20..23 = shares
                4'd1: begin
                    data_next.orn[23:0] = s_tdata_i[63:40];
                    data_next.side      =
                        (s_tdata_i[39:32] == 8'h42) ? 1'b1 : 1'b0; // if = "B" assert buy
                    data_next.shares    = s_tdata_i[31:0];
                end

                // Beat 3 contains the eight-byte stock symbol, which the
                // current order-book contract does not need.

                // Beat 4, ITCH bytes 32..39. A ends after price and F uses
                // the lower four lanes for its ignored MPID attribution.
                4'd3: data_next.price = s_tdata_i[63:32];

                default: ; // do nothing
            endcase

            if(s_tlast_i) begin
                event_complete = 1'b1;
            end
        end
        else if(current_state == MOD_CAP) begin
            word_count_next = word_count + 1'b1;

            case(word_count)

                // Beat 1, ITCH bytes 8..15.
                4'd0: data_next.orn[63:24] = s_tdata_i[39:0];

                // Beat 2, ITCH bytes 16..23.
                4'd1: begin
                    data_next.orn[23:0] = s_tdata_i[63:40];

                    if(data.message_type == MSG_REPLACE) begin
                        // Replacement ORN starts at byte 19.
                        data_next.updated_orn[63:24] = s_tdata_i[39:0];
                    end
                    else if(data.message_type != MSG_DELETE) begin
                        // E/C/X shares occupy bytes 19..22.
                        data_next.shares = s_tdata_i[39:8];
                    end
                end

                // Beat 3, ITCH bytes 24..31.
                4'd2: begin
                    if(data.message_type == MSG_REPLACE) begin
                        // U:
                        //   bytes 24..26 = replacement ORN low 24 bits
                        //   bytes 27..30 = shares
                        //   byte  31     = price high byte
                        data_next.updated_orn[23:0] = s_tdata_i[63:40];
                        data_next.shares            = s_tdata_i[39:8];
                        data_next.price[31:24]       = s_tdata_i[7:0];
                    end
                end

                // Beat 4, ITCH bytes 32..39.
                4'd3: begin
                    if(data.message_type == MSG_REPLACE) begin
                        // U price bytes 32..34 complete the value started
                        // in byte 31 of the previous beat.
                        data_next.price[23:0] = s_tdata_i[63:40];
                    end
                    else if(data.message_type == MSG_EXEC_PX) begin
                        // C execution price occupies bytes 32..35.
                        data_next.price = s_tdata_i[63:32];
                    end
                end

                default: ;
            endcase

            if(s_tlast_i) begin
                event_complete = 1'b1;
            end
        end
    end
end

// Sequential parser/output state, synchronous reset

always_ff @(posedge clk) begin
    if(!rst_n) begin
        current_state <= IDLE;
        data          <= '0;
        word_count    <= '0;
        output_data   <= '0;
        output_valid  <= 1'b0;
    end

    else begin
        current_state <= next_state;
        data          <= data_next;
        word_count    <= word_count_next;

        // Retire the current output event when the downstream accepts it.
        if(output_valid && ready_i) begin
            output_valid <= 1'b0;
        end

        // A newly completed event replaces an output that is being consumed on
        // this same edge. s_tready_o prevents this path when the old event is
        // stalled, so output_data cannot be overwritten under backpressure.
        if(event_complete) begin
            output_data  <= data_next;
            output_valid <= 1'b1;
        end
    end
end

// Final output assignments

assign rdata_o = output_data;
assign valid_o = output_valid;

endmodule
