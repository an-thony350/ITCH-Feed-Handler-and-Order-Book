// Simulation-only asynchronous FIFO used by the line-rate performance probe.
//
// The production ZCU106 design uses rtl/event_async_fifo.v, which wraps
// xpm_fifo_async. Verilator does not provide the Xilinx XPM simulation library,
// so this model reproduces the relevant 16-entry valid/ready CDC behaviour for
// throughput and occupancy measurement without changing production RTL.

`timescale 1ns/1ps
`default_nettype none

module event_async_fifo_sim #(
    parameter integer EVENT_W    = 217,
    parameter integer FIFO_DEPTH = 16
) (
    input  wire                   wr_clk_i,
    input  wire                   rst_i,

    input  wire [EVENT_W-1:0]     s_data_i,
    input  wire                   s_valid_i,
    output wire                   s_ready_o,

    input  wire                   rd_clk_i,

    output wire [EVENT_W-1:0]     m_data_o,
    output wire                   m_valid_o,
    input  wire                   m_ready_i,

    // Test-only visibility. wr_level_o is the write-domain occupancy estimate
    // after the same two-flop pointer synchronisation used for full detection.
    output wire [$clog2(FIFO_DEPTH):0] wr_level_o,
    output wire                       full_o,
    output wire                       empty_o
);

    localparam integer ADDR_W = $clog2(FIFO_DEPTH);
    localparam integer PTR_W  = ADDR_W + 1;

    logic [EVENT_W-1:0] mem [0:FIFO_DEPTH-1];

    logic [PTR_W-1:0] wr_bin;
    logic [PTR_W-1:0] wr_gray;
    logic [PTR_W-1:0] rd_bin;
    logic [PTR_W-1:0] rd_gray;

    logic [PTR_W-1:0] rd_gray_sync1_wr;
    logic [PTR_W-1:0] rd_gray_sync2_wr;
    logic [PTR_W-1:0] wr_gray_sync1_rd;
    logic [PTR_W-1:0] wr_gray_sync2_rd;

    logic wr_full;
    logic rd_empty;

    wire wr_fire;
    wire rd_fire;

    wire [PTR_W-1:0] wr_bin_next;
    wire [PTR_W-1:0] wr_gray_next;
    wire [PTR_W-1:0] rd_bin_next;
    wire [PTR_W-1:0] rd_gray_next;

    wire wr_full_next;
    wire rd_empty_next;

    function automatic [PTR_W-1:0] bin_to_gray(input [PTR_W-1:0] value);
        bin_to_gray = (value >> 1) ^ value;
    endfunction

    function automatic [PTR_W-1:0] gray_to_bin(input [PTR_W-1:0] value);
        integer idx;
        begin
            gray_to_bin[PTR_W-1] = value[PTR_W-1];
            for(idx = PTR_W-2; idx >= 0; idx = idx - 1) begin
                gray_to_bin[idx] = gray_to_bin[idx+1] ^ value[idx];
            end
        end
    endfunction

    assign s_ready_o = !rst_i && !wr_full;
    assign m_valid_o = !rst_i && !rd_empty;
    assign m_data_o  = mem[rd_bin[ADDR_W-1:0]];

    assign wr_fire = s_valid_i && s_ready_o;
    assign rd_fire = m_valid_o && m_ready_i;

    assign wr_bin_next  = wr_bin + wr_fire;
    assign wr_gray_next = bin_to_gray(wr_bin_next);
    assign rd_bin_next  = rd_bin + rd_fire;
    assign rd_gray_next = bin_to_gray(rd_bin_next);

    // Standard asynchronous-FIFO full test: the next write pointer is full
    // when it equals the synchronised read pointer with the two MSBs inverted.
    assign wr_full_next =
        wr_gray_next == {
            ~rd_gray_sync2_wr[PTR_W-1:PTR_W-2],
             rd_gray_sync2_wr[PTR_W-3:0]
        };

    assign rd_empty_next = (rd_gray_next == wr_gray_sync2_rd);

    assign wr_level_o = wr_bin - gray_to_bin(rd_gray_sync2_wr);
    assign full_o     = wr_full;
    assign empty_o    = rd_empty;

    always_ff @(posedge wr_clk_i or posedge rst_i) begin
        if(rst_i) begin
            wr_bin  <= '0;
            wr_gray <= '0;
            wr_full <= 1'b0;
        end
        else begin
            if(wr_fire) begin
                mem[wr_bin[ADDR_W-1:0]] <= s_data_i;
            end

            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
            wr_full <= wr_full_next;
        end
    end

    always_ff @(posedge rd_clk_i or posedge rst_i) begin
        if(rst_i) begin
            rd_bin   <= '0;
            rd_gray  <= '0;
            rd_empty <= 1'b1;
        end
        else begin
            rd_bin   <= rd_bin_next;
            rd_gray  <= rd_gray_next;
            rd_empty <= rd_empty_next;
        end
    end

    // Read pointer synchronised into the write domain.
    always_ff @(posedge wr_clk_i or posedge rst_i) begin
        if(rst_i) begin
            rd_gray_sync1_wr <= '0;
            rd_gray_sync2_wr <= '0;
        end
        else begin
            rd_gray_sync1_wr <= rd_gray;
            rd_gray_sync2_wr <= rd_gray_sync1_wr;
        end
    end

    // Write pointer synchronised into the read domain.
    always_ff @(posedge rd_clk_i or posedge rst_i) begin
        if(rst_i) begin
            wr_gray_sync1_rd <= '0;
            wr_gray_sync2_rd <= '0;
        end
        else begin
            wr_gray_sync1_rd <= wr_gray;
            wr_gray_sync2_rd <= wr_gray_sync1_rd;
        end
    end

endmodule

`default_nettype wire
