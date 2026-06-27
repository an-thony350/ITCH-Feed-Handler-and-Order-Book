`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.06.2026 16:18:27
// Design Name:
// Module Name: data_handler
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


/*
This module has the following assumptions (which we can fix later depending on what we decide)

- Assumes that we are taking in data using the MoldUDP64 Protocal - More specifcally we are taking in data in 8-byte packets
- Assumes we have a block before this, that slices out Ethernet/UDP/IPV4 bytes and the only inputed bytes are the ITCH bytes
- We are only parsing data from sections 1.3 & 1.4 - all other data is irrelevant
- For adding orders to the book, we are using No MPID attribution (section 1.3.1) - extra byte is unecessary & wastes logic
- For order executed, we are including price message - (using section 1.4.2)


- Test bench must be updated

*/

parameter int  ORN_W    = 64;
parameter int  PRICE_W  = 32;
parameter int  SHARES_W = 32;
parameter int  PACKET_W = 64;
parameter int  STOCK_W  = 16;
parameter int  MSG_W    = 8;

// Struct for most data we will output - this isnt a complete list yet
// note that the struct is above the module declaration for the output port rdata

typedef struct packed {
    logic [MSG_W-1:0]       message_type;
    logic [STOCK_W-1:0]     stock_locate;
    logic [ORN_W-1:0]       orn;
    logic [ORN_W-1:0]       updated_orn;
    logic                   side;
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
} data_t;

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
    input  logic [PACKET_W-1:0]                                     s_tdata_i, // This isnt fixed, but assumed data is inputed as 8 bytes for now
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

logic [2:0] word_count;
data_t data;

// State Machine for state data is recieved in

typedef enum {  IDLE, ADD_CAP, MOD_CAP, SEND } state_t;

state_t current_state, next_state;

// Case logic for next state

// 8'h41 = "A", 8'h43 = "C", 8'h44 = "D", 8'h45 = "E", 8'h55 = "U", 8'h58 = "X" - Maybe add local integers?

always_comb begin
    case(current_state)
    IDLE:           next_state = s_tvalid_i                ? (  (s_tdata_i[63:56] == 8'h41) ? ADD_CAP:
                                                                (s_tdata_i[63:56] == 8'h43 || s_tdata_i[63:56] == 8'h55 ||
                                                                 s_tdata_i[63:56] == 8'h44 || s_tdata_i[63:56] == 8'h58 ||
                                                                 s_tdata_i[63:56] == 8'h45)
                                                                ? MOD_CAP: IDLE) : IDLE;
    ADD_CAP:        next_state = (s_tvalid_i && s_tlast_i) ? SEND       : ADD_CAP;
    MOD_CAP:        next_state = (s_tvalid_i && s_tlast_i) ? SEND       : MOD_CAP;
    SEND:           next_state = ready_i                   ? IDLE       : SEND;
    default:        next_state = IDLE;
    endcase
end

// Sequential logic for data handlng, synchronous reset

always_ff @(posedge clk) begin
    if(!rst_n) begin
        current_state      <= IDLE;
        data               <= '0;
        word_count         <= '0;
    end

    else begin
        current_state <= next_state;

        if(current_state == IDLE) begin
            if(s_tvalid_i) begin
                data.message_type <= s_tdata_i[63:56];
                data.stock_locate <= { s_tdata_i[55:48], s_tdata_i[47:40] };
                word_count        <= '0;

                if(s_tdata_i[63:56] != 8'h55) data.updated_orn <= '0;
                if(s_tdata_i[63:56] != 8'h41) begin
                    data.side   <= '0;
                    data.price  <= '0;
                end
            end
        end
        else if(current_state == ADD_CAP) begin
            if(s_tvalid_i) begin
                word_count <= word_count + 1;
                case(word_count)

                    3'd0: data.orn[63:24] <= { s_tdata_i[39:32], s_tdata_i[31:24], s_tdata_i[23:16],
                                               s_tdata_i[15:8], s_tdata_i[7:0] };

                    3'd1: begin
                        data.orn[23:0]    <= { s_tdata_i[63:56], s_tdata_i[55:48], s_tdata_i[47:40] };
                        data.side         <= (s_tdata_i[39:32] == 8'h42) ? 1'b1 : 1'b0; // if = "B" assert buy
                        data.shares       <= { s_tdata_i[31:24], s_tdata_i[23:16], s_tdata_i[15:8],
                                               s_tdata_i[7:0] };
                    end

                    3'd3: data.price      <= { s_tdata_i[63:56], s_tdata_i[55:48], s_tdata_i[47:40],
                                               s_tdata_i[39:32] };

                    default: ; // do nothing
                endcase
            end
        end
        else if(current_state == MOD_CAP) begin
            if(s_tvalid_i) begin
                word_count <= word_count + 1;
                case(word_count)

                    3'd0: data.orn[63:24] <=  { s_tdata_i[39:32], s_tdata_i[31:24], s_tdata_i[23:16],
                                               s_tdata_i[15:8], s_tdata_i[7:0] };

                    3'd1: begin
                        data.orn[23:0]    <= { s_tdata_i[63:56], s_tdata_i[55:48], s_tdata_i[47:40] };
                        if(data.message_type == 8'h55)       data.updated_orn[63:24]  <= { s_tdata_i[39:32], s_tdata_i[31:24], s_tdata_i[23:16],
                                                                                           s_tdata_i[15:8], s_tdata_i[7:0] };
                        else if (data.message_type != 8'h44) data.shares              <= { s_tdata_i[39:32], s_tdata_i[31:24], s_tdata_i[23:16],
                                                                                           s_tdata_i[15:8] };
                    end

                    3'd2: begin
                        if(data.message_type == 8'h55) begin
                            data.updated_orn[23:0]  <= { s_tdata_i[63:56], s_tdata_i[55:48], s_tdata_i[47:40] };
                            data.shares             <= { s_tdata_i[39:32], s_tdata_i[31:24], s_tdata_i[23:16],
                                                         s_tdata_i[15:8] };
                            data.price[31:24]       <=   s_tdata_i[7:0];
                        end
                    end

                    3'd3: begin
                        if(data.message_type == 8'h55)      data.price[23:0] <= { s_tdata_i[63:56], s_tdata_i[55:48], s_tdata_i[47:40] };
                        else if(data.message_type == 8'h45) data.price       <= { s_tdata_i[63:56], s_tdata_i[55:48], s_tdata_i[47:40],
                                                                                  s_tdata_i[39:32] };
                    end

                    default: ;
                endcase
            end
        end
    end

end

// Final output assignments

assign rdata_o    = data;
assign s_tready_o = (current_state != SEND) && rst_n;
assign valid_o    = (current_state == SEND);

endmodule
