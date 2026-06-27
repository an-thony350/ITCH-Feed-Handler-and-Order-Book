/*
This module has the following assumptions (which we can fix later depending on what we decide)

- Assumes that we are taking in data using the MoldUDP64 Protocal - More specifcally we are taking in data in 8-byte packets
- Assumes we have a block before this, that slices out Ethernet/UDP/IPV4 bytes and the only inputted bytes are the ITCH bytes
- For adding orders to the book, we are using No MPID attribution (section 1.3.1) - extra byte is unecessary & wastes logic
- For order executed, we are not including price message - (using section 1.4.1) - unsure about this - can be changed
- Other orders still in process of being added

- Test bench must be updated

*/

// Struct for most data we will output - this isnt a complete list yet
// note that the struct is above the module declaration for the output port rdata

typedef struct packed {
    logic [MSG_W-1:0]       message_type;
    logic [STOCK_W-1:0]     stock_locate;  
    logic [ORN_W-1:0]       orn;
    logic                   side;
    logic [SHARES_W-1:0]    shares;
    logic [PRICE_W-1:0]     price;
} data_t;

module data_handler#(
    parameter int  ORN_W    = 64,
    parameter int  PRICE_W  = 32,
    parameter int  SHARES_W = 32,
    parameter int  PACKET_W = 64,
    parameter int  STOCK_W  = 16,
    parameter int  MSG_W    = 8
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

logic [2:0] word_count; // may need to change this
data_t data;

// State Machine for state data is recieved in

typedef enum {  IDLE, ADD_CAP, EXC_CAP, SEND } state_t;

state_t current_state, next_state;

// Case logic for next state

always_comb begin
    case(current_state)
    IDLE:           next_state = s_tvalid_i                ? (  (s_tdata_i[7:0] == 8'h41) ? ADD_CAP:
                                                                (s_tdata_i[7:0] == 8'h45) ? EXC_CAP : IDLE) : IDLE;
    ADD_CAP:        next_state = (s_tvalid_i && s_tlast_i) ? SEND       : ADD_CAP;
    EXC_CAP:        next_state = (s_tvalid_i && s_tlast_i) ? SEND       : EXC_CAP;
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
                data.message_type <= s_tdata_i[7:0];
                data.stock_locate <= s_tdata_i[23:8];
                word_count        <= '0;

                if(s_tdata_i[7:0] == 8'45) begin // may be changed with other orders
                    data.price <= '0;
                    data.side  <= '0;
                end
            end
        end
        else if(current_state == ADD_CAP) begin
            if(s_tvalid_i) begin
                word_count <= word_count + 1;
                case(word_count)

                    3'd0: data.orn[63:24] <= s_tdata_i[63:24];

                    3'd1: begin
                        data.orn[23:0]    <= s_tdata_i[23:0];
                        data.side         <= (s_tdata_i[31:24] == 8'h42) ? 1'b1 : 1'b0; // if = "B" assert buy
                        data.shares       <= s_tdata_i[63:32];
                    end

                    3'd3: data.price      <= s_tdata_i[31:0];

                    default: ; // do nothing
                endcase
            end
        end
        else if(current_state == EXC_CAP) begin
            if(s_tvalid_i) begin
                word_count <= word_count + 1;
                case(word_count)

                    3'd0: data.orn[63:24] <= s_tdata_i[63:24];

                    3'd1: begin
                        data.orn[23:0]    <= s_tdata_i[23:0];
                        data.shares       <= s_tdata_i[55:24];
                    end

                    default: ;
                endcase
            end
        end
    end
    
end

assign rdata_o    = data;
assign s_tready_o = (current_state != SEND) && rst_n;
assign valid_o    = (current_state == SEND);

endmodule
