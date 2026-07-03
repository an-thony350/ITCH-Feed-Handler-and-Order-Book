// Contract:
// - Input is one complete Ethernet frame per AXI packet.
// - 64-bit AXIS uses big-endian byte order: byte lane 0 is tdata[63:56].
// - This phase assumes untagged Ethernet, IPv4 IHL=5, UDP, no fragmentation.
// - Output is the UDP payload, i.e. the MoldUDP64 datagram.
// - m_dgram_len_o is valid on the first output beat when m_dgram_start_o=1.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module frame_crack #(
  parameter bit          CHECK_DST_PORT    = 1'b0,
  parameter logic [15:0] EXPECTED_DST_PORT = 16'd0
) (
  input  logic       clk,
  input  logic       rst_n,

  // AXIS Ethernet frame input from DMA / testbench.
  input  axis_data_t s_axis_tdata_i,
  input  axis_keep_t s_axis_tkeep_i,
  input  logic       s_axis_tvalid_i,
  input  logic       s_axis_tlast_i,
  output logic       s_axis_tready_o,

  // AXIS MoldUDP64 datagram output.
  output axis_data_t m_axis_tdata_o,
  output axis_keep_t m_axis_tkeep_o,
  output logic       m_axis_tvalid_o,
  output logic       m_axis_tlast_o,
  input  logic       m_axis_tready_i,

  // Datagram metadata. Valid on the beat where m_dgram_start_o is asserted.
  output logic [DGRAM_LEN_W-1:0] m_dgram_len_o,
  output logic                   m_dgram_start_o,

  // One-cycle pulse when a frame is dropped, plus per-frame reason bits.
  output logic                   frame_drop_o,
  output logic [FRAME_ERR_W-1:0] frame_err_o
);

  // impl notes:
  // - latch EtherType at absolute bytes 12..13;
  // - latch IPv4 version/IHL at byte 14, total length at 16..17,
  //   flags/fragment offset at 20..21, protocol at 23;
  // - latch UDP dst port at 36..37 and UDP length at 38..39;
  // - validate fields, suppress output for bad frames, and forward bytes
  //   from absolute byte offset L2_L4_HDR_BYTES to frame end.

  localparam int HDR_FIELD_BYTES = 40; // enough to validate through UDP length

  logic [15:0] byte_idx;

  logic [15:0] ethertype;
  logic [7:0]  ip_version_ihl;
  logic [15:0] ip_total_len;
  logic [15:0] ip_flags_frag;
  logic [7:0]  ip_protocol;
  logic [15:0] udp_dst_port;
  logic [15:0] udp_len;

  logic        header_checked;
  logic        frame_good;
  logic        frame_bad;

  logic [DGRAM_LEN_W-1:0] dgram_len;
  logic [DGRAM_LEN_W-1:0] payload_left;
  logic                   dgram_start_pending;

  axis_data_t pack_data;
  axis_keep_t pack_keep;
  logic [3:0] pack_count;

  assign s_axis_tready_o = rst_n && (!m_axis_tvalid_o || m_axis_tready_i);
  assign m_dgram_len_o   = dgram_len;

  // utility functions
  function automatic logic lane_valid(input axis_keep_t keep, input int lane);
    lane_valid = keep[AXIS_KEEP_W-1-lane];
  endfunction

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
      default:      last_keep_is_contiguous = 1'b0;
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
    logic [3:0] count;

    count = 4'd0;
    for (int lane = 0; lane < AXIS_KEEP_W; lane++) begin
      if (lane_valid(keep, lane)) begin
        count++;
      end
    end

    keep_count = count;
  endfunction

  task automatic flag_drop(
    input  logic [FRAME_ERR_W-1:0] err_bits,
    inout  logic                   frame_bad_v,
    inout  logic                   frame_good_v
  );
    if (!frame_bad_v) begin
      frame_drop_o <= 1'b1;
      frame_err_o  <= err_bits;
    end

    frame_bad_v  = 1'b1;
    frame_good_v = 1'b0;
  endtask


  // main logic
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      byte_idx             <= '0;
      ethertype            <= '0;
      ip_version_ihl       <= '0;
      ip_total_len         <= '0;
      ip_flags_frag        <= '0;
      ip_protocol          <= '0;
      udp_dst_port         <= '0;
      udp_len              <= '0;
      header_checked       <= 1'b0;
      frame_good           <= 1'b0;
      frame_bad            <= 1'b0;
      dgram_len            <= '0;
      payload_left         <= '0;
      dgram_start_pending  <= 1'b0;
      pack_data            <= '0;
      pack_keep            <= '0;
      pack_count           <= '0;
      m_axis_tdata_o       <= '0;
      m_axis_tkeep_o       <= '0;
      m_axis_tvalid_o      <= 1'b0;
      m_axis_tlast_o       <= 1'b0;
      m_dgram_start_o      <= 1'b0;
      frame_drop_o         <= 1'b0;
      frame_err_o          <= '0;
    end else begin
      logic [15:0] ethertype_v;
      logic [7:0]  ip_version_ihl_v;
      logic [15:0] ip_total_len_v;
      logic [15:0] ip_flags_frag_v;
      logic [7:0]  ip_protocol_v;
      logic [15:0] udp_dst_port_v;
      logic [15:0] udp_len_v;

      logic [15:0] byte_idx_v;
      logic        header_checked_v;
      logic        frame_good_v;
      logic        frame_bad_v;
      logic [DGRAM_LEN_W-1:0] dgram_len_v;
      logic [DGRAM_LEN_W-1:0] payload_left_v;
      logic                   dgram_start_pending_v;
      axis_data_t             pack_data_v;
      axis_keep_t             pack_keep_v;
      logic [3:0]             pack_count_v;

      logic [FRAME_ERR_W-1:0] err_bits;
      logic                   emitted;

      frame_drop_o <= 1'b0;
      frame_err_o  <= '0;

      // latch outputs on valid handshake
      if (m_axis_tvalid_o && m_axis_tready_i) begin
        m_axis_tvalid_o <= 1'b0;
        m_axis_tlast_o  <= 1'b0;
        m_dgram_start_o <= 1'b0;
      end

      // latch inputs on valid handshake
      if (s_axis_tvalid_i && s_axis_tready_o) begin
        ethertype_v           = ethertype;
        ip_version_ihl_v      = ip_version_ihl;
        ip_total_len_v        = ip_total_len;
        ip_flags_frag_v       = ip_flags_frag;
        ip_protocol_v         = ip_protocol;
        udp_dst_port_v        = udp_dst_port;
        udp_len_v             = udp_len;
        byte_idx_v            = byte_idx;
        header_checked_v      = header_checked;
        frame_good_v          = frame_good;
        frame_bad_v           = frame_bad;
        dgram_len_v           = dgram_len;
        payload_left_v        = payload_left;
        dgram_start_pending_v = dgram_start_pending;
        pack_data_v           = pack_data;
        pack_keep_v           = pack_keep;
        pack_count_v          = pack_count;
        emitted               = 1'b0;

        if (tkeep_bad(s_axis_tkeep_i, s_axis_tlast_i)) begin
          err_bits = '0;
          err_bits[FRAME_ERR_BAD_TKEEP] = 1'b1;
          flag_drop(err_bits, frame_bad_v, frame_good_v);
        end

        // process each lane of the AXIS beat
        for (int lane = 0; lane < AXIS_KEEP_W; lane++) begin
          if (lane_valid(s_axis_tkeep_i, lane)) begin
            logic [15:0] abs_idx;
            logic [7:0]  b;

            abs_idx = byte_idx_v;
            b       = lane_byte(s_axis_tdata_i, lane);

            case (abs_idx)
              16'd12: ethertype_v[15:8]      = b;
              16'd13: ethertype_v[7:0]       = b;
              16'd14: ip_version_ihl_v       = b;
              16'd16: ip_total_len_v[15:8]   = b;
              16'd17: ip_total_len_v[7:0]    = b;
              16'd20: ip_flags_frag_v[15:8]  = b;
              16'd21: ip_flags_frag_v[7:0]   = b;
              16'd23: ip_protocol_v          = b;
              16'd36: udp_dst_port_v[15:8]   = b;
              16'd37: udp_dst_port_v[7:0]    = b;
              16'd38: udp_len_v[15:8]        = b;
              16'd39: udp_len_v[7:0]         = b;
              default: ;
            endcase

            // forward payload bytes to output AXIS
            if (header_checked_v && frame_good_v && (abs_idx >= L2_L4_HDR_BYTES) && (payload_left_v != '0)) begin
              pack_data_v[AXIS_DATA_W-1-(8*pack_count_v) -: 8] = b;
              pack_keep_v[AXIS_KEEP_W-1-pack_count_v]          = 1'b1;
              pack_count_v++;
              payload_left_v--;

              if ((pack_count_v == AXIS_KEEP_W) || (payload_left_v == '0)) begin
                if (!emitted) begin
                  m_axis_tdata_o  <= pack_data_v;
                  m_axis_tkeep_o  <= pack_keep_v;
                  m_axis_tvalid_o <= 1'b1;
                  m_axis_tlast_o  <= (payload_left_v == '0);
                  m_dgram_start_o <= dgram_start_pending_v;

                  dgram_start_pending_v = 1'b0;
                  pack_data_v           = '0;
                  pack_keep_v           = '0;
                  pack_count_v          = '0;
                  emitted               = 1'b1;
                end
              end
            end

            byte_idx_v++;
          end
        end

        // check header fields after all header bytes have been received
        if (!header_checked_v && (byte_idx_v >= HDR_FIELD_BYTES)) begin
          err_bits = '0;

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
          end

          header_checked_v = 1'b1;

          // set frame_good/frame_bad and datagram length/payload_left
          if (err_bits != '0) begin
            flag_drop(err_bits, frame_bad_v, frame_good_v);
            dgram_len_v           = '0;
            payload_left_v        = '0;
            dgram_start_pending_v = 1'b0;
          end else if (!frame_bad_v) begin
            frame_good_v          = 1'b1;
            dgram_len_v           = udp_len_v - UDP_HDR_BYTES;
            payload_left_v        = udp_len_v - UDP_HDR_BYTES;
            dgram_start_pending_v = ((udp_len_v - UDP_HDR_BYTES) != 16'd0);
          end else begin
            dgram_len_v           = '0;
            payload_left_v        = '0;
            dgram_start_pending_v = 1'b0;
          end
        end

        // check for runt frame on last beat
        if (s_axis_tlast_i) begin
          if (!header_checked_v || (byte_idx_v < L2_L4_HDR_BYTES) ||
              (frame_good_v && (payload_left_v != '0))) begin
            err_bits = '0;
            err_bits[FRAME_ERR_RUNT_FRAME] = 1'b1;
            flag_drop(err_bits, frame_bad_v, frame_good_v);
          end

          if (frame_bad_v) begin
            dgram_len_v    = '0;
            payload_left_v = '0;
            pack_data_v    = '0;
            pack_keep_v    = '0;
            pack_count_v   = '0;
          end

          byte_idx_v            = '0;
          ethertype_v           = '0;
          ip_version_ihl_v      = '0;
          ip_total_len_v        = '0;
          ip_flags_frag_v       = '0;
          ip_protocol_v         = '0;
          udp_dst_port_v        = '0;
          udp_len_v             = '0;
          header_checked_v      = 1'b0;
          frame_good_v          = 1'b0;
          frame_bad_v           = 1'b0;
          dgram_start_pending_v = 1'b0;
        end

        ethertype           <= ethertype_v;
        ip_version_ihl      <= ip_version_ihl_v;
        ip_total_len        <= ip_total_len_v;
        ip_flags_frag       <= ip_flags_frag_v;
        ip_protocol         <= ip_protocol_v;
        udp_dst_port        <= udp_dst_port_v;
        udp_len             <= udp_len_v;
        byte_idx            <= byte_idx_v;
        header_checked      <= header_checked_v;
        frame_good          <= frame_good_v;
        frame_bad           <= frame_bad_v;
        dgram_len           <= dgram_len_v;
        payload_left        <= payload_left_v;
        dgram_start_pending <= dgram_start_pending_v;
        pack_data           <= pack_data_v;
        pack_keep           <= pack_keep_v;
        pack_count          <= pack_count_v;
      end
    end
  end

endmodule

`default_nettype wire
