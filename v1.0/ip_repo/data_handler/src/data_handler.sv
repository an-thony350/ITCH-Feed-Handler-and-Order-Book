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
// Revision 0.02 - Fix IDLE decode for A/F and use tlast for message completion
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


/*
This module has the following assumptions (which we can fix later depending on what we decide)

- Assumes that we are taking in data using the MoldUDP64 Protocal - More specifcally we are taking in data in 8-byte packets
- Assumes we have a block before this, that slices out Ethernet/UDP/IPV4 bytes and the only inputed bytes are the ITCH bytes
- We are only parsing data from sections 1.3 & 1.4 - all other data is irrelevant
- For adding orders to the book, we now treat both A and F as ADD. F's MPID field is ignored for book state.
- For order executed, we are including price message - (using section 1.4.2)


- Test bench must be updated

*/
import hdl_header::*;


module data_handler#(
    ORN_W    = 64,
    PRICE_W  = 32,
    SHARES_W = 32,
    PACKET_W = 32,
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

logic [3:0] word_count;
data_t data;
logic input_fire;

// State Machine for state data is recieved in

typedef enum {  IDLE, ADD_CAP, MOD_CAP, SKIP, SEND } state_t;

state_t current_state, next_state;

localparam logic [MSG_W-1:0] MSG_ADD_A    = 8'h41; // A
localparam logic [MSG_W-1:0] MSG_ADD_F    = 8'h46; // F
localparam logic [MSG_W-1:0] MSG_EXEC     = 8'h45; // E
localparam logic [MSG_W-1:0] MSG_EXEC_PX  = 8'h43; // C
localparam logic [MSG_W-1:0] MSG_DELETE   = 8'h44; // D
localparam logic [MSG_W-1:0] MSG_REPLACE  = 8'h55; // U
localparam logic [MSG_W-1:0] MSG_CANCEL   = 8'h58; // X

function automatic logic is_add_msg(input logic [MSG_W-1:0] msg);
    return (msg == MSG_ADD_A) || (msg == MSG_ADD_F);
endfunction

function automatic logic is_modify_msg(input logic [MSG_W-1:0] msg);
    return (msg == MSG_EXEC) || (msg == MSG_EXEC_PX) ||
           (msg == MSG_DELETE) || (msg == MSG_REPLACE) ||
           (msg == MSG_CANCEL);
endfunction

assign input_fire = s_tvalid_i && s_tready_o;

// Case logic for next state

always_comb begin
    next_state = current_state;

    case(current_state)
        IDLE: begin
            if(input_fire) begin
                if(is_add_msg(s_tdata_i[31:24])) begin
                    next_state = s_tlast_i ? SEND : ADD_CAP;
                end
                else if(is_modify_msg(s_tdata_i[31:24])) begin
                    next_state = s_tlast_i ? SEND : MOD_CAP;
                end
                else begin
                    next_state = s_tlast_i ? IDLE : SKIP;
                end
            end
        end

        ADD_CAP: begin
            if(input_fire && s_tlast_i) begin
                next_state = SEND;
            end
        end

        MOD_CAP: begin
            if(input_fire && s_tlast_i) begin
                next_state = SEND;
            end
        end

        SKIP: begin
            if(input_fire && s_tlast_i) begin
                next_state = IDLE;
            end
        end

        SEND: begin
            if(ready_i) begin
                next_state = IDLE;
            end
        end

        default: next_state = IDLE;
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
            if(input_fire) begin
                data.message_type <= s_tdata_i[31:24];
                data.stock_locate <= { s_tdata_i[23:16], s_tdata_i[15:8] };
                word_count        <= '0;

                if(s_tdata_i[31:24] != MSG_REPLACE) begin
                    data.updated_orn <= '0;
                end

                if(!is_add_msg(s_tdata_i[31:24])) begin
                    data.side   <= '0;
                    data.price  <= '0;
                end
            end
        end
        else if(current_state == ADD_CAP) begin
            if(input_fire) begin
                word_count <= word_count + 1;
                case(word_count)

                    4'd1: data.orn[63:56]   <= s_tdata_i[7:0];

                    4'd2: data.orn[55:24]   <= { s_tdata_i };

                    4'd3: begin
                        data.orn[23:0]      <= { s_tdata_i[31:8] };
                        data.side           <= (s_tdata_i[7:0] == 8'h42) ? 1'b1 : 1'b0; // if = "B" assert buy
                    end

                    4'd4: data.shares       <=  s_tdata_i;

                    4'd7: data.price        <= { s_tdata_i };

                    default: ; // do nothing
                endcase
            end
        end
        else if(current_state == MOD_CAP) begin
            if(input_fire) begin
                word_count <= word_count + 1;
                case(word_count)

                    4'd1: data.orn[63:56] <= { s_tdata_i[7:0] };

                    4'd2: data.orn[55:24] <= { s_tdata_i };

                    4'd3: begin
                        data.orn[23:0]  <=  s_tdata_i[31:8];
                        if(data.message_type == MSG_REPLACE) data.updated_orn[63:56]  <= { s_tdata_i[7:0] };
                        else if (data.message_type != MSG_DELETE) data.shares[31:24] <= { s_tdata_i[7:0] };
                    end
                    4'd4: begin
                        if(data.message_type == MSG_REPLACE) data.updated_orn[55:24]  <= { s_tdata_i };
                        else if (data.message_type != MSG_DELETE) data.shares[23:0]  <= { s_tdata_i[31:8] };
                    end
                    4'd5: begin
                        if(data.message_type == MSG_REPLACE) begin
                            data.updated_orn[23:0]   <= { s_tdata_i[31:8] };
                            data.shares[31:24]       <= { s_tdata_i[7:0]  };
                        end
                    end
                    4'd6: begin
                        if(data.message_type == MSG_REPLACE) begin
                            data.shares[23:0]        <= { s_tdata_i[31:8] };
                            data.price[31:24]        <= { s_tdata_i[7:0] };
                        end
                    end
                    4'd7: begin
                        if(data.message_type == MSG_REPLACE)      data.price[23:0] <= { s_tdata_i[31:8] };
                        else if(data.message_type == MSG_EXEC_PX) data.price       <= { s_tdata_i };
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
