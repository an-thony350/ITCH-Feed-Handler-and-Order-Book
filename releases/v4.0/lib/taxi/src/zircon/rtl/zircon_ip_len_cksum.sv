// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Zircon IP stack - Length and checksum computation
 */
module zircon_ip_len_cksum #
(
    parameter START_OFFSET = 14
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * Packet passthrough
     */
    taxi_axis_if.snk   s_axis_pkt,
    taxi_axis_if.src   m_axis_pkt,

    /*
     * Packet metadata output
     */
    taxi_axis_if.src   m_axis_meta
);

localparam DATA_W = s_axis_pkt.DATA_W;
localparam KEEP_W = s_axis_pkt.KEEP_W;
localparam META_W = m_axis_meta.DATA_W;

localparam BYTE_LANES = KEEP_W;
localparam BYTE_W = DATA_W/BYTE_LANES;

localparam ID_W = s_axis_pkt.ID_W;
localparam ID_EN = s_axis_pkt.ID_EN && m_axis_pkt.ID_EN;
localparam META_ID_EN = s_axis_pkt.ID_EN && m_axis_meta.ID_EN;
localparam DEST_W = s_axis_pkt.DEST_W;
localparam DEST_EN = s_axis_pkt.DEST_EN && m_axis_pkt.DEST_EN;
localparam META_DEST_EN = s_axis_pkt.DEST_EN && m_axis_meta.DEST_EN;
localparam USER_W = s_axis_pkt.USER_W;
localparam USER_EN = s_axis_pkt.USER_EN && m_axis_pkt.USER_EN;
localparam META_USER_EN = s_axis_pkt.USER_EN && m_axis_meta.USER_EN;

parameter LEVELS = $clog2(BYTE_LANES);
parameter OFFSET_W = START_OFFSET/BYTE_LANES > 1 ? $clog2(START_OFFSET/BYTE_LANES) : 1;

// check configuration
if (KEEP_W * 8 != DATA_W)
    $fatal(0, "Error: Interface requires byte (8-bit) granularity (instance %m)");

if (META_W != 32)
    $fatal(0, "Error: Interface width must be 32 (instance %m)");

if (m_axis_meta.KEEP_W * 8 != META_W)
    $fatal(0, "Error: Interface requires byte (8-bit) granularity (instance %m)");

logic [OFFSET_W-1:0] offset_reg = OFFSET_W'(START_OFFSET/BYTE_LANES);
logic [BYTE_LANES-1:0] mask_reg = {BYTE_LANES{1'b1}} << START_OFFSET;

logic [(BYTE_LANES/4)*17-1:0] sum_reg[LEVELS-2:0];
logic [(BYTE_LANES/4)*3-1:0] len_reg[LEVELS-2:0];
logic [ID_W-1:0] id_reg[LEVELS-2:0];
logic [DEST_W-1:0] dest_reg[LEVELS-2:0];
logic [USER_W-1:0] user_reg[LEVELS-2:0];
logic [LEVELS-2:0] sum_valid_reg = '0;
logic [LEVELS-2:0] sum_last_reg = '0;

logic [16+LEVELS-1:0] sum_acc_temp;
logic [15:0] sum_acc_reg = '0;
logic [15:0] len_acc_reg = '0;

logic [15:0] m_axis_meta_len_reg = '0;
logic [15:0] m_axis_meta_csum_reg = '0;
logic m_axis_meta_valid_reg = 1'b0;
logic [ID_W-1:0] m_axis_meta_id_reg = '0;
logic [DEST_W-1:0] m_axis_meta_dest_reg = '0;
logic [USER_W-1:0] m_axis_meta_user_reg = '0;

taxi_axis_tie
axis_tie_pkt_inst (
    .s_axis(s_axis_pkt),
    .m_axis(m_axis_pkt)
);

assign m_axis_meta.tdata = {m_axis_meta_csum_reg, m_axis_meta_len_reg};
assign m_axis_meta.tkeep = '1;
assign m_axis_meta.tstrb = m_axis_meta.tkeep;
if (META_ID_EN) begin
    assign m_axis_meta.tid = m_axis_meta_id_reg;
end else begin
    assign m_axis_meta.tid = '0;
end
if (META_DEST_EN) begin
    assign m_axis_meta.tdest = m_axis_meta_dest_reg;
end else begin
    assign m_axis_meta.tdest = '0;
end
if (META_USER_EN) begin
    assign m_axis_meta.tuser = m_axis_meta_user_reg;
end else begin
    assign m_axis_meta.tuser = '0;
end
assign m_axis_meta.tlast = 1'b1;
assign m_axis_meta.tvalid = m_axis_meta_valid_reg;

// Mask input data
wire [BYTE_LANES-1:0][BYTE_W-1:0] pkt_data_masked;

for (genvar j = 0; j < BYTE_LANES; j = j + 1) begin
    assign pkt_data_masked[j] = (s_axis_pkt.tkeep[j] && mask_reg[j]) ? s_axis_pkt.tdata[j*8 +: 8] : 8'd0;
end

always_ff @(posedge clk) begin
    sum_valid_reg[0] <= 1'b0;

    if (s_axis_pkt.tvalid && s_axis_pkt.tready) begin
        for (integer i = 0; i < BYTE_LANES/4; i = i + 1) begin
            sum_reg[0][i*17 +: 17] <= {pkt_data_masked[4*i+0], pkt_data_masked[4*i+1]} + {pkt_data_masked[4*i+2], pkt_data_masked[4*i+3]};
            len_reg[0][i*3 +: 3] <= 3'(s_axis_pkt.tkeep[4*i+0]) + 3'(s_axis_pkt.tkeep[4*i+1]) + 3'(s_axis_pkt.tkeep[4*i+2]) + 3'(s_axis_pkt.tkeep[4*i+3]);
        end
        sum_valid_reg[0] <= 1'b1;
        sum_last_reg[0] <= s_axis_pkt.tlast;
        id_reg[0] <= s_axis_pkt.tid;
        dest_reg[0] <= s_axis_pkt.tdest;
        user_reg[0] <= s_axis_pkt.tuser;

        if (s_axis_pkt.tlast) begin
            offset_reg <= OFFSET_W'(START_OFFSET/BYTE_LANES);
            mask_reg <= {BYTE_LANES{1'b1}} << START_OFFSET;
        end else if (START_OFFSET < BYTE_LANES || offset_reg == 0) begin
            mask_reg <= {BYTE_LANES{1'b1}};
        end else begin
            offset_reg <= offset_reg - 1;
            if (offset_reg == 1) begin
                mask_reg <= {BYTE_LANES{1'b1}} << (START_OFFSET%BYTE_LANES);
            end else begin
                mask_reg <= {BYTE_LANES{1'b0}};
            end
        end
    end

    if (rst) begin
        offset_reg <= OFFSET_W'(START_OFFSET/BYTE_LANES);
        mask_reg <= {BYTE_LANES{1'b1}} << START_OFFSET;
        sum_valid_reg[0] <= 1'b0;
    end
end

for (genvar l = 1; l < LEVELS-1; l = l + 1) begin

    always_ff @(posedge clk) begin
        sum_valid_reg[l] <= 1'b0;

        if (sum_valid_reg[l-1]) begin
            for (integer i = 0; i < BYTE_LANES/4/2**l; i = i + 1) begin
                sum_reg[l][i*(17+l) +: (17+l)] <= sum_reg[l-1][(i*2+0)*(17+l-1) +: (17+l-1)] + sum_reg[l-1][(i*2+1)*(17+l-1) +: (17+l-1)];
                len_reg[l][i*(3+l) +: (3+l)] <= len_reg[l-1][(i*2+0)*(3+l-1) +: (3+l-1)] + len_reg[l-1][(i*2+1)*(3+l-1) +: (3+l-1)];
            end
            sum_valid_reg[l] <= 1'b1;
            sum_last_reg[l] <= sum_last_reg[l-1];
            id_reg[l] <= id_reg[l-1];
            dest_reg[l] <= dest_reg[l-1];
            user_reg[l] <= user_reg[l-1];
        end

        if (rst) begin
            sum_valid_reg[l] <= 1'b0;
        end
    end

end

always_ff @(posedge clk) begin
    m_axis_meta_valid_reg <= 1'b0;

    sum_acc_temp = sum_reg[LEVELS-2][16+LEVELS-1-1:0] + (16+LEVELS)'(sum_acc_reg);
    sum_acc_temp = (16+LEVELS)'(sum_acc_temp[15:0] + 16'(sum_acc_temp >> 16));
    sum_acc_temp = (16+LEVELS)'(sum_acc_temp[15:0] + 16'(sum_acc_temp[16]));

    m_axis_meta_len_reg <= len_acc_reg + 16'(len_reg[LEVELS-2][3+LEVELS-2-1:0]);
    m_axis_meta_csum_reg <= sum_acc_temp[15:0];
    m_axis_meta_id_reg <= id_reg[LEVELS-2];
    m_axis_meta_dest_reg <= dest_reg[LEVELS-2];
    m_axis_meta_user_reg <= user_reg[LEVELS-2];

    if (sum_valid_reg[LEVELS-2]) begin
        if (sum_last_reg[LEVELS-2]) begin
            m_axis_meta_valid_reg <= 1'b1;
            sum_acc_reg <= '0;
            len_acc_reg <= '0;
        end else begin
            sum_acc_reg <= sum_acc_temp[15:0];
            len_acc_reg <= len_acc_reg + 16'(len_reg[LEVELS-2][3+LEVELS-2-1:0]);
        end
    end

    if (rst) begin
        m_axis_meta_valid_reg <= 1'b0;
        sum_acc_reg <= '0;
    end
end

endmodule

`resetall
