// Contract:
// - Input is one complete Ethernet frame per AXI packet.
// - 64-bit AXIS uses big-endian byte order: byte lane 0 is tdata[63:56].
// - This phase assumes untagged Ethernet, IPv4 IHL=5, UDP, no fragmentation.
// - Output is the UDP payload, i.e. the MoldUDP64 datagram.
// - m_dgram_len_o is valid on the first output beat when m_dgram_start_o=1.
//
// Timing note:
// - This implementation keeps the fixed-offset parser rather than introducing
//   a generic per-byte shifter on the latency-critical ingress path.
// - With 64-bit ingress, the fixed Ethernet+IPv4+UDP header is 42 bytes, so
//   the UDP payload starts at lane 2 of beat 5.
// - Six payload bytes are carried from that beat. Each following input beat
//   emits one aligned 64-bit output beat, preserving one-beat-per-cycle
//   throughput once payload streaming begins.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module frame_crack #(
  parameter bit          CHECK_DST_PORT    = 1'b0,
  parameter logic [15:0] EXPECTED_DST_PORT = 16'd0
) (
  input  wire       clk,
  input  wire       rst_n,

  // AXIS Ethernet frame input from DMA / testbench.
  input  wire axis_data_t s_axis_tdata_i,
  input  wire axis_keep_t s_axis_tkeep_i,
  input  wire       s_axis_tvalid_i,
  input  wire       s_axis_tlast_i,
  output wire       s_axis_tready_o,

  // AXIS MoldUDP64 datagram output.
  output axis_data_t m_axis_tdata_o,
  output axis_keep_t m_axis_tkeep_o,
  output logic       m_axis_tvalid_o,
  output logic       m_axis_tlast_o,
  input  wire       m_axis_tready_i,

  // Datagram metadata. Valid on the beat where m_dgram_start_o is asserted.
  output logic [DGRAM_LEN_W-1:0] m_dgram_len_o,
  output logic                   m_dgram_start_o,

  // One-cycle pulse when a frame is dropped, plus per-frame reason bits.
  output logic                   frame_drop_o,
  output logic [FRAME_ERR_W-1:0] frame_err_o
);

  // This module is intentionally specialised to the native 64-bit ingress.
  initial begin
    if (AXIS_DATA_W != 64) begin
      $error("frame_crack requires AXIS_DATA_W == 64");
    end
  end

  typedef enum logic [1:0] {
    ST_HEADER,
    ST_FIRST_PAYLOAD,
    ST_PAYLOAD,
    ST_DRAIN
  } state_t;

  state_t state;

  // Beat index within the Ethernet frame. With 64-bit beats:
  //   beat 1 carries bytes 8..15  (EtherType and IPv4 version/IHL)
  //   beat 2 carries bytes 16..23 (IPv4 total length, flags/fragment, protocol)
  //   beat 4 carries bytes 32..39 (UDP dst port and UDP length)
  //   beat 5 carries bytes 40..47 (UDP checksum and first 6 payload bytes)
  logic [15:0] beat_idx;

  logic [15:0] ethertype;
  logic [7:0]  ip_version_ihl;
  logic [15:0] ip_total_len;
  logic [15:0] ip_flags_frag;
  logic [7:0]  ip_protocol;

  logic [DGRAM_LEN_W-1:0] dgram_len;
  logic [DGRAM_LEN_W-1:0] payload_left;

  // Six payload bytes are carried because the 42-byte fixed header ends two
  // bytes into a 64-bit beat. carry_bytes[47:40] is the oldest carried byte.
  logic [47:0] carry_bytes;
  logic [2:0]  carry_count;

  logic        start_pending;
  logic        flush_pending;
  logic        reset_after_flush;

  wire out_ready;
  wire input_fire;

  assign out_ready       = (!m_axis_tvalid_o || m_axis_tready_i);
  assign s_axis_tready_o = rst_n && out_ready && !flush_pending;
  assign input_fire      = s_axis_tvalid_i && s_axis_tready_o;
  assign m_dgram_len_o   = dgram_len;

  // Utility functions.
  function automatic logic [7:0] lane_byte(input axis_data_t data, input int lane);
    lane_byte = data[AXIS_DATA_W-1-(8*lane) -: 8];
  endfunction

  function automatic logic last_keep_is_contiguous(input axis_keep_t keep);
    case (keep)
      8'b1000_0000,
      8'b1100_0000,
      8'b1110_0000,
      8'b1111_0000,
      8'b1111_1000,
      8'b1111_1100,
      8'b1111_1110,
      8'b1111_1111: last_keep_is_contiguous = 1'b1;
      default:       last_keep_is_contiguous = 1'b0;
    endcase
  endfunction

  function automatic logic tkeep_bad(
    input axis_keep_t keep,
    input logic       last
  );
    if (last) begin
      tkeep_bad = !last_keep_is_contiguous(keep);
    end else begin
      tkeep_bad = (keep != {AXIS_KEEP_W{1'b1}});
    end
  endfunction

  function automatic logic [3:0] keep_count(input axis_keep_t keep);
    case (keep)
      8'b1000_0000: keep_count = 4'd1;
      8'b1100_0000: keep_count = 4'd2;
      8'b1110_0000: keep_count = 4'd3;
      8'b1111_0000: keep_count = 4'd4;
      8'b1111_1000: keep_count = 4'd5;
      8'b1111_1100: keep_count = 4'd6;
      8'b1111_1110: keep_count = 4'd7;
      8'b1111_1111: keep_count = 4'd8;
      default:       keep_count = 4'd0;
    endcase
  endfunction

  function automatic axis_keep_t keep_from_count(input logic [3:0] count);
    case (count)
      4'd1: keep_from_count = 8'b1000_0000;
      4'd2: keep_from_count = 8'b1100_0000;
      4'd3: keep_from_count = 8'b1110_0000;
      4'd4: keep_from_count = 8'b1111_0000;
      4'd5: keep_from_count = 8'b1111_1000;
      4'd6: keep_from_count = 8'b1111_1100;
      4'd7: keep_from_count = 8'b1111_1110;
      4'd8: keep_from_count = 8'b1111_1111;
      default: keep_from_count = 8'b0000_0000;
    endcase
  endfunction

  task automatic clear_frame_state();
    begin
      state             <= ST_HEADER;
      beat_idx          <= '0;
      ethertype         <= '0;
      ip_version_ihl    <= '0;
      ip_total_len      <= '0;
      ip_flags_frag     <= '0;
      ip_protocol       <= '0;
      payload_left      <= '0;
      carry_bytes       <= '0;
      carry_count       <= '0;
      start_pending     <= 1'b0;
      flush_pending     <= 1'b0;
      reset_after_flush <= 1'b0;
    end
  endtask

  task automatic flag_drop(input logic [FRAME_ERR_W-1:0] err_bits);
    begin
      frame_drop_o <= 1'b1;
      frame_err_o  <= err_bits;
    end
  endtask

  task automatic emit_word(
    input axis_data_t data,
    input axis_keep_t keep,
    input logic       last
  );
    begin
      m_axis_tdata_o  <= data;
      m_axis_tkeep_o  <= keep;
      m_axis_tvalid_o <= 1'b1;
      m_axis_tlast_o  <= last;
      m_dgram_start_o <= start_pending;
      start_pending   <= 1'b0;
    end
  endtask

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state             <= ST_HEADER;
      beat_idx          <= '0;
      ethertype         <= '0;
      ip_version_ihl    <= '0;
      ip_total_len      <= '0;
      ip_flags_frag     <= '0;
      ip_protocol       <= '0;
      dgram_len         <= '0;
      payload_left      <= '0;
      carry_bytes       <= '0;
      carry_count       <= '0;
      start_pending     <= 1'b0;
      flush_pending     <= 1'b0;
      reset_after_flush <= 1'b0;
      m_axis_tdata_o    <= '0;
      m_axis_tkeep_o    <= '0;
      m_axis_tvalid_o   <= 1'b0;
      m_axis_tlast_o    <= 1'b0;
      m_dgram_start_o   <= 1'b0;
      frame_drop_o      <= 1'b0;
      frame_err_o       <= '0;
    end else begin
      frame_drop_o <= 1'b0;
      frame_err_o  <= '0;

      if (m_axis_tvalid_o && m_axis_tready_i) begin
        m_axis_tvalid_o <= 1'b0;
        m_axis_tlast_o  <= 1'b0;
        m_dgram_start_o <= 1'b0;
      end

      // Emit a final partial beat that is already held in carry_bytes.
      // No input is accepted while this is pending.
      if (flush_pending && out_ready) begin
        axis_data_t flush_data;
        axis_keep_t flush_keep;

        flush_data = {carry_bytes, 16'h0000};
        flush_keep = keep_from_count({1'b0, carry_count});

        emit_word(flush_data, flush_keep, 1'b1);

        carry_bytes   <= '0;
        carry_count   <= '0;
        flush_pending <= 1'b0;

        if (reset_after_flush) begin
          clear_frame_state();
        end else begin
          state <= ST_DRAIN;
        end
      end else if (input_fire) begin
        logic [FRAME_ERR_W-1:0] err_bits;

        err_bits = '0;

        if (tkeep_bad(s_axis_tkeep_i, s_axis_tlast_i)) begin
          err_bits[FRAME_ERR_BAD_TKEEP] = 1'b1;
          flag_drop(err_bits);

          if (s_axis_tlast_i) begin
            clear_frame_state();
          end else begin
            state <= ST_DRAIN;
          end
        end else begin
          case (state)
            ST_HEADER: begin
              // Fixed-offset field capture. Keeping these as constant slices
              // avoids a generic byte-loop on the ingress timing path.
              case (beat_idx)
                16'd1: begin
                  ethertype      <= s_axis_tdata_i[31:16];
                  ip_version_ihl <= s_axis_tdata_i[15:8];
                  beat_idx       <= beat_idx + 16'd1;
                end

                16'd2: begin
                  ip_total_len   <= s_axis_tdata_i[63:48];
                  ip_flags_frag  <= s_axis_tdata_i[31:16];
                  ip_protocol    <= s_axis_tdata_i[7:0];
                  beat_idx       <= beat_idx + 16'd1;
                end

                16'd4: begin
                  logic [15:0] ethertype_v;
                  logic [7:0]  ip_version_ihl_v;
                  logic [15:0] ip_total_len_v;
                  logic [15:0] ip_flags_frag_v;
                  logic [7:0]  ip_protocol_v;
                  logic [15:0] udp_dst_port_v;
                  logic [15:0] udp_len_v;
                  logic [DGRAM_LEN_W-1:0] dgram_len_v;

                  ethertype_v      = ethertype;
                  ip_version_ihl_v = ip_version_ihl;
                  ip_total_len_v   = ip_total_len;
                  ip_flags_frag_v  = ip_flags_frag;
                  ip_protocol_v    = ip_protocol;
                  udp_dst_port_v   = s_axis_tdata_i[31:16];
                  udp_len_v        = s_axis_tdata_i[15:0];
                  dgram_len_v      = udp_len_v - UDP_HDR_BYTES;

                  if (ethertype_v != ETHERTYPE_IPV4) begin
                    err_bits[FRAME_ERR_BAD_ETHERTYPE] = 1'b1;
                  end

                  if (ip_version_ihl_v[7:4] != 4'd4) begin
                    err_bits[FRAME_ERR_BAD_IP_VER] = 1'b1;
                  end

                  if (ip_version_ihl_v[3:0] != IPV4_IHL_MIN) begin
                    err_bits[FRAME_ERR_BAD_IHL] = 1'b1;
                  end

                  if (ip_flags_frag_v[13] || (ip_flags_frag_v[12:0] != 13'd0)) begin
                    err_bits[FRAME_ERR_FRAGMENT] = 1'b1;
                  end

                  if (ip_protocol_v != IP_PROTO_UDP) begin
                    err_bits[FRAME_ERR_BAD_PROTO] = 1'b1;
                  end

                  if (CHECK_DST_PORT && (udp_dst_port_v != EXPECTED_DST_PORT)) begin
                    err_bits[FRAME_ERR_BAD_UDP_PORT] = 1'b1;
                  end

                  if ((udp_len_v < UDP_HDR_BYTES) ||
                      (ip_total_len_v < (IPV4_MIN_HDR_BYTES + UDP_HDR_BYTES)) ||
                      (udp_len_v > (ip_total_len_v - IPV4_MIN_HDR_BYTES))) begin
                    err_bits[FRAME_ERR_BAD_UDP_LEN] = 1'b1;
                    dgram_len_v = '0;
                  end

                  if (s_axis_tlast_i) begin
                    // Beat 4 ends at byte 39; a valid frame still needs the
                    // UDP checksum bytes at 40..41.
                    err_bits[FRAME_ERR_RUNT_FRAME] = 1'b1;
                  end

                  if (err_bits != '0) begin
                    flag_drop(err_bits);
                    if (s_axis_tlast_i) begin
                      clear_frame_state();
                    end else begin
                      state <= ST_DRAIN;
                    end
                  end else begin
                    dgram_len     <= dgram_len_v;
                    payload_left  <= dgram_len_v;
                    start_pending <= (dgram_len_v != '0);
                    state         <= ST_FIRST_PAYLOAD;
                    beat_idx      <= beat_idx + 16'd1;
                  end
                end

                default: begin
                  beat_idx <= beat_idx + 16'd1;
                end
              endcase

              if (s_axis_tlast_i && (beat_idx != 16'd4)) begin
                err_bits = '0;
                err_bits[FRAME_ERR_RUNT_FRAME] = 1'b1;
                flag_drop(err_bits);
                clear_frame_state();
              end
            end

            ST_FIRST_PAYLOAD: begin
              // Beat 5: bytes 40..41 are the UDP checksum. Payload starts at
              // bytes 42..47, i.e. lanes 2..7 of this 64-bit beat.
              logic [3:0] valid_bytes;
              logic [3:0] first_payload_avail;
              logic [3:0] take;
              logic [DGRAM_LEN_W-1:0] left_after;

              valid_bytes = keep_count(s_axis_tkeep_i);

              if (valid_bytes < 4'd2) begin
                first_payload_avail = 4'd0;
              end else begin
                first_payload_avail = valid_bytes - 4'd2;
              end

              if (payload_left < first_payload_avail) begin
                take = payload_left[3:0];
              end else begin
                take = first_payload_avail;
              end

              left_after = payload_left - take;

              if (s_axis_tlast_i && (left_after != '0)) begin
                err_bits[FRAME_ERR_RUNT_FRAME] = 1'b1;
                flag_drop(err_bits);
                clear_frame_state();
              end else begin
                case (take)
                  4'd0: begin
                    carry_bytes <= '0;
                    carry_count <= 3'd0;
                  end

                  4'd1: begin
                    carry_bytes <= {lane_byte(s_axis_tdata_i, 2), 40'h0};
                    carry_count <= 3'd1;
                  end

                  4'd2: begin
                    carry_bytes <= {
                      lane_byte(s_axis_tdata_i, 2),
                      lane_byte(s_axis_tdata_i, 3),
                      32'h0
                    };
                    carry_count <= 3'd2;
                  end

                  4'd3: begin
                    carry_bytes <= {
                      lane_byte(s_axis_tdata_i, 2),
                      lane_byte(s_axis_tdata_i, 3),
                      lane_byte(s_axis_tdata_i, 4),
                      24'h0
                    };
                    carry_count <= 3'd3;
                  end

                  4'd4: begin
                    carry_bytes <= {
                      lane_byte(s_axis_tdata_i, 2),
                      lane_byte(s_axis_tdata_i, 3),
                      lane_byte(s_axis_tdata_i, 4),
                      lane_byte(s_axis_tdata_i, 5),
                      16'h0
                    };
                    carry_count <= 3'd4;
                  end

                  4'd5: begin
                    carry_bytes <= {
                      lane_byte(s_axis_tdata_i, 2),
                      lane_byte(s_axis_tdata_i, 3),
                      lane_byte(s_axis_tdata_i, 4),
                      lane_byte(s_axis_tdata_i, 5),
                      lane_byte(s_axis_tdata_i, 6),
                      8'h0
                    };
                    carry_count <= 3'd5;
                  end

                  default: begin
                    carry_bytes <= s_axis_tdata_i[47:0];
                    carry_count <= 3'd6;
                  end
                endcase

                payload_left <= left_after;

                if (left_after == '0) begin
                  if (take != 4'd0) begin
                    flush_pending     <= 1'b1;
                    reset_after_flush <= s_axis_tlast_i;
                    state             <= ST_FIRST_PAYLOAD;
                  end else if (s_axis_tlast_i) begin
                    clear_frame_state();
                  end else begin
                    state <= ST_DRAIN;
                  end
                end else begin
                  state    <= ST_PAYLOAD;
                  beat_idx <= beat_idx + 16'd1;
                end
              end
            end

            ST_PAYLOAD: begin
              // ST_PAYLOAD is entered only after carrying six bytes from the
              // previous beat. The next two input bytes complete one aligned
              // 64-bit output word; lanes 2..7 become the next six-byte carry.
              logic [3:0] valid_bytes;
              logic [3:0] take;
              logic [DGRAM_LEN_W-1:0] left_after;
              logic [3:0] out_count;
              logic [2:0] new_carry_count;
              logic [47:0] new_carry_bytes;
              axis_data_t out_data;
              axis_keep_t out_keep;
              logic       out_last;

              valid_bytes = keep_count(s_axis_tkeep_i);

              if (payload_left < valid_bytes) begin
                take = payload_left[3:0];
              end else begin
                take = valid_bytes;
              end

              left_after = payload_left - take;

              if (s_axis_tlast_i && (left_after != '0)) begin
                err_bits[FRAME_ERR_RUNT_FRAME] = 1'b1;
                flag_drop(err_bits);
                clear_frame_state();
              end else begin
                out_data        = '0;
                new_carry_bytes = '0;
                new_carry_count = 3'd0;

                case (take)
                  4'd0: begin
                    out_count = 4'd6;
                    out_data  = {carry_bytes, 16'h0000};
                  end

                  4'd1: begin
                    out_count = 4'd7;
                    out_data  = {
                      carry_bytes,
                      lane_byte(s_axis_tdata_i, 0),
                      8'h00
                    };
                  end

                  default: begin
                    out_count = 4'd8;
                    out_data  = {
                      carry_bytes,
                      lane_byte(s_axis_tdata_i, 0),
                      lane_byte(s_axis_tdata_i, 1)
                    };
                  end
                endcase

                case (take)
                  4'd3: begin
                    new_carry_bytes = {lane_byte(s_axis_tdata_i, 2), 40'h0};
                    new_carry_count = 3'd1;
                  end

                  4'd4: begin
                    new_carry_bytes = {
                      lane_byte(s_axis_tdata_i, 2),
                      lane_byte(s_axis_tdata_i, 3),
                      32'h0
                    };
                    new_carry_count = 3'd2;
                  end

                  4'd5: begin
                    new_carry_bytes = {
                      lane_byte(s_axis_tdata_i, 2),
                      lane_byte(s_axis_tdata_i, 3),
                      lane_byte(s_axis_tdata_i, 4),
                      24'h0
                    };
                    new_carry_count = 3'd3;
                  end

                  4'd6: begin
                    new_carry_bytes = {
                      lane_byte(s_axis_tdata_i, 2),
                      lane_byte(s_axis_tdata_i, 3),
                      lane_byte(s_axis_tdata_i, 4),
                      lane_byte(s_axis_tdata_i, 5),
                      16'h0
                    };
                    new_carry_count = 3'd4;
                  end

                  4'd7: begin
                    new_carry_bytes = {
                      lane_byte(s_axis_tdata_i, 2),
                      lane_byte(s_axis_tdata_i, 3),
                      lane_byte(s_axis_tdata_i, 4),
                      lane_byte(s_axis_tdata_i, 5),
                      lane_byte(s_axis_tdata_i, 6),
                      8'h0
                    };
                    new_carry_count = 3'd5;
                  end

                  4'd8: begin
                    new_carry_bytes = s_axis_tdata_i[47:0];
                    new_carry_count = 3'd6;
                  end

                  default: begin
                    new_carry_bytes = '0;
                    new_carry_count = 3'd0;
                  end
                endcase

                out_keep = keep_from_count(out_count);
                out_last = ((left_after == '0) && (new_carry_count == 3'd0));

                emit_word(out_data, out_keep, out_last);

                payload_left <= left_after;
                carry_bytes  <= new_carry_bytes;
                carry_count  <= new_carry_count;
                beat_idx     <= beat_idx + 16'd1;

                if (left_after == '0) begin
                  if (new_carry_count != 3'd0) begin
                    flush_pending     <= 1'b1;
                    reset_after_flush <= s_axis_tlast_i;
                    state             <= ST_PAYLOAD;
                  end else if (s_axis_tlast_i) begin
                    clear_frame_state();
                  end else begin
                    state <= ST_DRAIN;
                  end
                end
              end
            end

            ST_DRAIN: begin
              // Drop or ignore the rest of the frame. This also covers Ethernet
              // padding after the UDP payload has already been forwarded.
              if (s_axis_tlast_i) begin
                clear_frame_state();
              end
            end

            default: begin
              clear_frame_state();
            end
          endcase
        end
      end
    end
  end

endmodule

`default_nettype wire
