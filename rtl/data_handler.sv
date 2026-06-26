/*
This module has the following assumptions (which we can fix later depending on what we decide)

- Assumes that we are taking in Ethernet/UDP packets as 16-byte (64-bit) packets
- Assumes that incoming test packets are exactly 3 clock cycles (i.e. 3 packet bursts) long - will require
a byte-counter if not (should probably add anyway as it would be much more clean)
- Assumes the packet data will come in the form below:

Cycle 1: ORN number (64 bits)
Cycle 2: Price number (Top 32 bits) & No. Shares (Bottom 32 bits)
Cycle 3: Side value (last bit)

*/



module data_handler#(
    parameter int  ORN_W    = 64,
    parameter int  PRICE_W  = 32,
    parameter int  SHARES_W = 32,
    parameter int  PACKET_W = 64
)(
    input  logic                                     clk,
    input  logic                                     rst_n,

    // input from AXI-4 Stream
    input  logic [PACKET_W-1:0]                      s_tdata_i, // This isnt fixed, but assumed data is inputed as 16 bytes for now
    input  logic                                     s_tvalid_i,
    input  logic                                     s_tlast_i,

    // output to AXI-4 Stream
    output logic                                     s_tready_o,

    // input from Order Book
    input  logic                                     ready_i,

    // output to Order Book
    output logic [(ORN_W + PRICE_W + SHARES_W):0]    rdata_o,
    output logic                                     valid_o
);

// Bit definition for packet data

localparam int SIDE_BIT     = 0;

localparam int SHARES_BIT   = 0;
localparam int PRICE_BIT    = SHARES_BIT + SHARES_W;

// Struct for all relevant pieces of data

typedef struct packed {
    logic [ORN_W-1:0]       orn;
    logic [PRICE_W-1:0]     price;
    logic [SHARES_W-1:0]    shares;
    logic                   side;
} data_t;

data_t data;

// State Machine for state data is recieved in

typedef enum { IDLE, DATA_CAP_0, DATA_CAP_1, SEND } state_t;

state_t current_state, next_state;

// Case logic for next state

always_comb begin
    case(current_state)
    IDLE:           next_state = s_tvalid_i                ? DATA_CAP_0 : IDLE;
    DATA_CAP_0:     next_state = s_tvalid_i                ? DATA_CAP_1 : DATA_CAP_0;
    DATA_CAP_1:     next_state = (s_tvalid_i && s_tlast_i) ? SEND       : DATA_CAP_1;
    SEND:           next_state = ready_i                   ? IDLE       : SEND;
    default:        next_state = IDLE;
    endcase
end

// Sequential logic for data handlng, synchronous reset

always_ff @(posedge clk) begin
    if(!rst_n) begin
        current_state      <= IDLE;
        data               <= '0;
    end
    
    else begin
        current_state <= next_state;

        if(current_state == IDLE) begin
            if(s_tvalid_i) data.orn <= s_tdata_i;
        end
        else if(current_state == DATA_CAP_0) begin
            if(s_tvalid_i) begin
                data.price  <= s_tdata_i[PRICE_BIT +: PRICE_W];
                data.shares <= s_tdata_i[SHARES_BIT +: SHARES_W];
            end
        end
        else if (current_state == DATA_CAP_1) begin
            if(s_tvalid_i) data.side  <= s_tdata_i[SIDE_BIT];
        end
    end
    
end

assign rdata_o    = data;
assign s_tready_o = (current_state != SEND) && rst_n;
assign valid_o    = (current_state == SEND);

endmodule
