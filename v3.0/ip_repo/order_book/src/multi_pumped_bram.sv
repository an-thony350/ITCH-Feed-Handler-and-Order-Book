import hdl_header::*;

module multi_pumped_bram #(
    parameter int       ADDRESS_W,
    parameter int       DATA_W
) (
    // Control Signals
    input logic                     bram_clk, // this clock has freq = 2*(clk freq)
    input logic                     rst_n,

    // Read ports
    input logic  [ADDRESS_W-1:0]    rd_addr_a,
    input logic  [ADDRESS_W-1:0]    rd_addr_b,
    output logic [DATA_W-1:0]       rd_data_a,
    output logic [DATA_W-1:0]       rd_data_b,

    // Write ports
    input logic                     wr_we_a,
    input logic                     wr_we_b,
    input logic  [ADDRESS_W-1:0]    wr_addr_a,
    input logic  [ADDRESS_W-1:0]    wr_addr_b,
    input logic  [DATA_W-1:0]       wr_data_a,
    input logic  [DATA_W-1:0]       wr_data_b
);

// Local Parameters determining bram size
localparam int BRAM_DEPTH = 1 << ADDRESS_W;

// Internal registers

// BRAM block
(* ram_style = "block", cascade_height = 2 *) logic [DATA_W-1:0] bram [BRAM_DEPTH-1:0];

// phase signal for bram_clk
logic clk_phase;

// Internal BRAM ports (used  for easier writing)
logic [ADDRESS_W-1:0] bram_addr_a;
logic [ADDRESS_W-1:0] bram_addr_b;
logic [DATA_W-1:0]    bram_data_a;
logic [DATA_W-1:0]    bram_data_b;
logic                 bram_we_a;
logic                 bram_we_b;
logic                 bram_en_a;
logic                 bram_en_b;

logic [DATA_W-1:0]    bram_dout_a;
logic [DATA_W-1:0]    bram_dout_b;

// Reset logic for specific BRAM at CLEAR (initial reset)
initial begin
    for(int i = 0; i < BRAM_DEPTH; i++) begin
        bram[i] =   '0;
    end
end

// Combinational BRAM writes depending on clock phase
always_comb begin
    if(!clk_phase) begin // we are reading first
        bram_en_a   =   1'b1;
        bram_en_b   =   1'b1;
        bram_addr_a =   rd_addr_a;
        bram_addr_b =   rd_addr_b;
        bram_data_a =   '0;
        bram_data_b =   '0;
        bram_we_a   =   1'b0;
        bram_we_b   =   1'b0;
    end
    else begin
        bram_en_a   =   wr_we_a;
        bram_en_b   =   wr_we_b;
        bram_addr_a =   wr_addr_a;
        bram_addr_b =   wr_addr_b;
        bram_data_a =   wr_data_a;
        bram_data_b =   wr_data_b;
        bram_we_a   =   wr_we_a;
        bram_we_b   =   wr_we_b;
    end
end

// Sequential clock phase logic
always_ff @(posedge bram_clk) begin
    if(!rst_n) clk_phase    <=  1'b1;
    else       clk_phase    <=  ~clk_phase;
end

// Sequential BRAM read/write for port A
always_ff @(posedge bram_clk) begin
    if(bram_en_a) begin
        if(bram_we_a) begin
            bram[bram_addr_a]   <=  bram_data_a;
        end
        bram_dout_a <=  bram[bram_addr_a];
    end
end

// Sequential BRAM read/write for port B
always_ff @(posedge bram_clk) begin
    if(bram_en_b) begin
        if(bram_we_b) begin
            bram[bram_addr_b]   <=  bram_data_b;
        end
        bram_dout_b <=  bram[bram_addr_b];
    end
end

// combinational output assignment
assign rd_data_a    =   bram_dout_a;
assign rd_data_b    =   bram_dout_b;


endmodule
