// contract:
// - One seq_valid_i pulse is presented per parsed MoldUDP64 header.
// - Normal packets are accepted only if they are first/in-order or post-gap.
// - Packets starting before expected_seq_o are treated as already-seen/late and dropped.
// - Heartbeats and EOS are status-only: no ITCH payload should be emitted downstream.
// - 64-bit sequence wrap is intentionally out of scope for the first implementation.

`timescale 1ns/1ps
`default_nettype none

module mold_seq_guard #(
  parameter int SEQ_W   = 64,
  parameter int COUNT_W = 16
) (
  input  wire                 clk,
  input  wire                 rst_n,

  // One pulse per parsed MoldUDP64 header.
  input  wire                 seq_valid_i,
  input  wire [SEQ_W-1:0]     seq_i,
  input  wire [COUNT_W-1:0]   count_i,

  // Optional status clear. This does not rewind expected_seq_o.
  input  wire                 clear_stale_i,

  // Same-cycle decision for the packet whose header is valid.
  output logic                accept_packet_o,
  output logic                drop_packet_o,

  // One-cycle status pulses, qualified by seq_valid_i.
  output logic                in_order_o,
  output logic                duplicate_o,
  output logic                gap_o,
  output logic                heartbeat_o,
  output logic                eos_o,

  // Sticky/status state.
  output logic                stale_o,
  output logic [SEQ_W-1:0]    expected_seq_o,
  output logic [SEQ_W-1:0]    gap_start_o,
  output logic [SEQ_W-1:0]    gap_end_o
);

  localparam logic [COUNT_W-1:0] COUNT_HEARTBEAT = '0;
  localparam logic [COUNT_W-1:0] COUNT_EOS       = {COUNT_W{1'b1}};

  logic have_expected;
  logic is_heartbeat;
  logic is_eos;
  logic [SEQ_W-1:0] count_ext;
  logic [SEQ_W-1:0] packet_end;

  always_comb begin
    count_ext = '0;
    count_ext[COUNT_W-1:0] = count_i;
  end

  assign packet_end   = seq_i + count_ext;
  assign is_heartbeat = (count_i == COUNT_HEARTBEAT);
  assign is_eos       = (count_i == COUNT_EOS);

  always_comb begin
    accept_packet_o = 1'b0;
    drop_packet_o   = 1'b0;
    in_order_o      = 1'b0;
    duplicate_o     = 1'b0;
    gap_o           = 1'b0;
    heartbeat_o     = 1'b0;
    eos_o           = 1'b0;

    if (seq_valid_i) begin
      heartbeat_o = is_heartbeat;
      eos_o       = is_eos;

      if (is_heartbeat || is_eos) begin
        // Status-only packets never forward payload to the book path.
        drop_packet_o = 1'b1;

        if (have_expected && (seq_i > expected_seq_o)) begin
          gap_o = 1'b1;
        end
      end else if (!have_expected || (seq_i == expected_seq_o)) begin
        accept_packet_o = 1'b1;
        in_order_o      = 1'b1;
      end else if (seq_i > expected_seq_o) begin
        // Gap is reported, but the post-gap packet is still accepted so the
        // hot path keeps consuming instead of stalling for recovery.
        accept_packet_o = 1'b1;
        gap_o           = 1'b1;
      end else begin
        // Packet starts before expected_seq_o. For this first packet-level
        // implementation, treat the whole datagram as duplicate/late.
        drop_packet_o = 1'b1;
        duplicate_o   = 1'b1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      have_expected <= 1'b0;
      stale_o       <= 1'b0;
      expected_seq_o <= '0;
      gap_start_o   <= '0;
      gap_end_o     <= '0;
    end else begin
      if (clear_stale_i) begin
        stale_o <= 1'b0;
      end

      if (seq_valid_i) begin
        if (is_heartbeat || is_eos) begin
          if (!have_expected) begin
            have_expected  <= 1'b1;
            expected_seq_o <= seq_i;
          end else if (seq_i > expected_seq_o) begin
            stale_o        <= 1'b1;
            gap_start_o    <= expected_seq_o;
            gap_end_o      <= seq_i - {{(SEQ_W-1){1'b0}}, 1'b1};
            expected_seq_o <= seq_i;
          end
        end else if (!have_expected || (seq_i == expected_seq_o)) begin
          have_expected  <= 1'b1;
          expected_seq_o <= packet_end;
        end else if (seq_i > expected_seq_o) begin
          have_expected  <= 1'b1;
          stale_o        <= 1'b1;
          gap_start_o    <= expected_seq_o;
          gap_end_o      <= seq_i - {{(SEQ_W-1){1'b0}}, 1'b1};
          expected_seq_o <= packet_end;
        end
      end
    end
  end

endmodule

`default_nettype wire
