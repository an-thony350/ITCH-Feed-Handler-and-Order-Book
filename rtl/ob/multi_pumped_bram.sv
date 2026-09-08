import hdl_header::*;

module multi_pumped_bram #(
    parameter int       ADDRESS_W,
    parameter int       DATA_W
) (
    input logic                     clk,
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

localparam int BRAM_DEPTH = 1 << ADDRESS_W;

(* ram_style = "block", cascade_height = 2 *) logic [DATA_W-1:0] bram [BRAM_DEPTH-1:0];

initial begin
    for(int i = 0; i < BRAM_DEPTH; i++) bram[i] = '0;
end

// Port A: write if we, else read
always_ff @(posedge clk) begin
    if(wr_we_a) bram[wr_addr_a] <= wr_data_a;
    else        rd_data_a       <= bram[rd_addr_a];
end

// Port B: write if we, else read
always_ff @(posedge clk) begin
    if(wr_we_b) bram[wr_addr_b] <= wr_data_b;
    else        rd_data_b       <= bram[rd_addr_b];
end

endmodule
