// Contract:
// - Input is one MoldUDP64 datagram per AXI packet from frame_crack.
// - s_dgram_len_i is the UDP payload length, valid with s_dgram_start_i.
// - Output payload stream is the concatenation of ITCH message payload bytes;
//   MoldUDP64 2-byte length prefixes are stripped.
// - Message boundaries are carried on a separate length stream. A msg_len item
//   must be accepted before the first payload byte of that message is emitted.
// - m_payload_tlast_o marks end of MoldUDP64 datagram, not end of ITCH message.
// - session/seq/count sideband feeds mold_seq_guard for Phase-4 A/B + gap policy.
//
// Timing architecture:
// - The fixed 20-byte MoldUDP64 header is decoded one 32-bit beat per cycle.
// - Body input is decoupled from parsing by a four-entry register FIFO.
// - Aligned payload runs use a direct full-beat fast path: four payload bytes
//   are removed and emitted in one cycle.
// - Only message-prefix bytes and unaligned message tails use the one-byte
//   boundary path. The design therefore keeps the useful parallelisation
//   without unrolling four dependent parser transitions into one cycle.
// - There are no variable-width reservoir shifts and no combinational
//   consume-then-append feedback path.
// - Input ready depends only on registered state, datagram completion and FIFO
//   occupancy. Downstream ready cannot propagate to the MoldUDP64 input.
// - Datagram cleanup is performed from registered ST_DRAIN/ST_DONE states,
//   rather than using a deep combinational error condition as the reset input
//   of most parser registers.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module mold_deframe #(
  parameter int BODY_FIFO_DEPTH = 4
) (
  input  wire       clk,
  input  wire       rst_n,

  // AXIS MoldUDP64 datagram input.
  input  wire axis_data_t s_axis_tdata_i,
  input  wire axis_keep_t s_axis_tkeep_i,
  input  wire       s_axis_tvalid_i,
  input  wire       s_axis_tlast_i,
  output logic      s_axis_tready_o,

  // Datagram metadata from frame_crack. Valid with s_dgram_start_i.
  input  wire [DGRAM_LEN_W-1:0] s_dgram_len_i,
  input  wire                   s_dgram_start_i,

  // AXIS ITCH payload byte stream, with MoldUDP64 length prefixes removed.
  output axis_data_t m_payload_tdata_o,
  output axis_keep_t m_payload_tkeep_o,
  output logic       m_payload_tvalid_o,
  output logic       m_payload_tlast_o,
  input  wire        m_payload_tready_i,

  // Per-message length stream to realign. One item per ITCH payload.
  output logic [MOLD_MSG_LEN_W-1:0] m_msg_len_o,
  output logic                      m_msg_len_valid_o,
  input  wire                       m_msg_len_ready_i,

  // MoldUDP64 header sideband.
  output logic [MOLD_SESSION_W-1:0] session_o,
  output logic [MOLD_SEQ_W-1:0]     seq_o,
  output logic [MOLD_COUNT_W-1:0]   count_o,
  output logic [MOLD_SEQ_W-1:0]     expected_next_o,
  output logic                      seq_valid_o,
  output logic                      heartbeat_o,
  output logic                      eos_o,
  output logic                      in_order_o,
  output logic                      duplicate_o,
  output logic                      gap_o,
  output logic                      stale_o,
  output logic [MOLD_SEQ_W-1:0]     expected_seq_o,
  output logic [MOLD_SEQ_W-1:0]     gap_start_o,
  output logic [MOLD_SEQ_W-1:0]     gap_end_o,

  // Error/status.
  output logic                      mold_drop_o,
  output logic [MOLD_ERR_W-1:0]     mold_err_o
);

  initial begin
    if ((AXIS_DATA_W != 32) || (AXIS_KEEP_W != 4)) begin
      $error("mold_deframe timing-fixed implementation requires 32-bit AXIS");
    end
    if (BODY_FIFO_DEPTH < 2) begin
      $error("mold_deframe BODY_FIFO_DEPTH must be at least two");
    end
  end

  typedef enum logic [3:0] {
    ST_HEADER,
    ST_GUARD,
    ST_MSG_LEN_HI,
    ST_MSG_LEN_LO,
    ST_LEN_WAIT,
    ST_PAYLOAD,
    ST_DRAIN,
    ST_DONE
  } state_t;

  localparam int BODY_FIFO_AW = (BODY_FIFO_DEPTH <= 2)
                             ? 1 : $clog2(BODY_FIFO_DEPTH);
  localparam int BODY_FIFO_CW = $clog2(BODY_FIFO_DEPTH + 1);
  localparam int PACK_COUNT_W = $clog2(AXIS_KEEP_W + 1);

  localparam logic [DGRAM_LEN_W-1:0] MOLD_HDR_BYTES_DGRAM =
      DGRAM_LEN_W'(MOLD_HDR_BYTES);

  state_t state;

  logic [2:0] header_beat_idx;

  logic [DGRAM_LEN_W-1:0] dgram_len;
  logic [DGRAM_LEN_W-1:0] dgram_bytes_seen;
  logic [DGRAM_LEN_W-1:0] body_bytes_consumed;
  logic                   dgram_end_seen;
  logic                   dropping;

  logic [MOLD_COUNT_W-1:0]   messages_left;
  logic [7:0]                msg_len_hi;
  logic [MOLD_MSG_LEN_W-1:0] pending_msg_len;
  logic [MOLD_MSG_LEN_W-1:0] payload_left;

  // Four complete input beats are buffered independently of the parser. This
  // removes the previous timing path in which parser consumption changed the
  // byte position used by same-cycle input append logic.
  axis_data_t body_fifo_data [0:BODY_FIFO_DEPTH-1];
  axis_keep_t body_fifo_keep [0:BODY_FIFO_DEPTH-1];
  logic       body_fifo_last [0:BODY_FIFO_DEPTH-1];

  logic [BODY_FIFO_AW-1:0] body_wr_ptr;
  logic [BODY_FIFO_AW-1:0] body_rd_ptr;
  logic [BODY_FIFO_CW-1:0] body_fifo_count;
  logic [1:0]              body_head_lane;

  axis_data_t payload_pack_data;
  logic [PACK_COUNT_W-1:0] payload_pack_count;

  logic                  guard_seq_valid;
  logic                  guard_accept_packet;
  logic                  guard_drop_packet;
  logic                  guard_in_order;
  logic                  guard_duplicate;
  logic                  guard_gap;
  logic                  guard_heartbeat;
  logic                  guard_eos;

  logic input_fire;
  logic payload_output_fire;
  logic msg_len_output_fire;
  logic payload_slot_available;
  logic msg_len_slot_available;

  axis_data_t body_head_data;
  axis_keep_t body_head_keep;
  logic       body_head_last;
  logic [2:0] body_head_byte_count;
  logic [7:0] body_head_byte;
  logic       body_head_is_last_lane;

  function automatic logic last_keep_is_contiguous(input axis_keep_t keep);
    case (keep)
      4'b1000,
      4'b1100,
      4'b1110,
      4'b1111: last_keep_is_contiguous = 1'b1;
      default: last_keep_is_contiguous = 1'b0;
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

  function automatic logic [2:0] keep_byte_count(input axis_keep_t keep);
    case (keep)
      4'b1000: keep_byte_count = 3'd1;
      4'b1100: keep_byte_count = 3'd2;
      4'b1110: keep_byte_count = 3'd3;
      4'b1111: keep_byte_count = 3'd4;
      default: keep_byte_count = 3'd0;
    endcase
  endfunction

  function automatic logic [7:0] selected_lane_byte(
    input axis_data_t data,
    input logic [1:0] lane
  );
    case (lane)
      2'd0: selected_lane_byte = data[31:24];
      2'd1: selected_lane_byte = data[23:16];
      2'd2: selected_lane_byte = data[15:8];
      default: selected_lane_byte = data[7:0];
    endcase
  endfunction

  function automatic axis_keep_t keep_from_count(
    input logic [PACK_COUNT_W-1:0] count
  );
    case (count)
      PACK_COUNT_W'(1): keep_from_count = 4'b1000;
      PACK_COUNT_W'(2): keep_from_count = 4'b1100;
      PACK_COUNT_W'(3): keep_from_count = 4'b1110;
      PACK_COUNT_W'(4): keep_from_count = 4'b1111;
      default:          keep_from_count = 4'b0000;
    endcase
  endfunction

  function automatic axis_data_t insert_pack_byte(
    input axis_data_t                  data,
    input logic [PACK_COUNT_W-1:0]     count,
    input logic [7:0]                  byte_value
  );
    axis_data_t result;
    begin
      result = data;
      case (count)
        PACK_COUNT_W'(0): result[31:24] = byte_value;
        PACK_COUNT_W'(1): result[23:16] = byte_value;
        PACK_COUNT_W'(2): result[15:8]  = byte_value;
        default:          result[7:0]   = byte_value;
      endcase
      insert_pack_byte = result;
    end
  endfunction

  function automatic logic [BODY_FIFO_AW-1:0] ptr_increment(
    input logic [BODY_FIFO_AW-1:0] ptr
  );
    if (ptr == BODY_FIFO_AW'(BODY_FIFO_DEPTH-1)) begin
      ptr_increment = '0;
    end else begin
      ptr_increment = ptr + BODY_FIFO_AW'(1);
    end
  endfunction

  assign body_head_data       = body_fifo_data[body_rd_ptr];
  assign body_head_keep       = body_fifo_keep[body_rd_ptr];
  assign body_head_last       = body_fifo_last[body_rd_ptr];
  assign body_head_byte_count = keep_byte_count(body_head_keep);
  assign body_head_byte       = selected_lane_byte(body_head_data, body_head_lane);
  assign body_head_is_last_lane =
      (body_head_byte_count != 3'd0)
      && ({1'b0, body_head_lane} == (body_head_byte_count - 3'd1));

  assign payload_output_fire    = m_payload_tvalid_o && m_payload_tready_i;
  assign msg_len_output_fire    = m_msg_len_valid_o && m_msg_len_ready_i;
  assign payload_slot_available = !m_payload_tvalid_o || m_payload_tready_i;
  assign msg_len_slot_available = !m_msg_len_valid_o || m_msg_len_ready_i;

  // Header and drain beats are handled directly. Body beats enter the small
  // register FIFO. No downstream ready signal is used in this equation.
  always_comb begin
    s_axis_tready_o = 1'b0;

    if (rst_n && !dgram_end_seen) begin
      unique case (state)
        ST_HEADER: begin
          s_axis_tready_o = 1'b1;
        end

        ST_MSG_LEN_HI,
        ST_MSG_LEN_LO,
        ST_LEN_WAIT,
        ST_PAYLOAD: begin
          s_axis_tready_o =
              (body_fifo_count < BODY_FIFO_CW'(BODY_FIFO_DEPTH));
        end

        ST_DRAIN: begin
          s_axis_tready_o = 1'b1;
        end

        default: begin
          s_axis_tready_o = 1'b0;
        end
      endcase
    end
  end

  assign input_fire = s_axis_tvalid_i && s_axis_tready_o;

  // The guard decision is made from header fields registered in the preceding
  // cycle. It is therefore not part of the four-byte payload fast path.
  assign guard_seq_valid = rst_n && (state == ST_GUARD);

  mold_seq_guard #(
    .SEQ_W   (MOLD_SEQ_W),
    .COUNT_W (MOLD_COUNT_W)
  ) u_mold_seq_guard (
    .clk             (clk),
    .rst_n           (rst_n),
    .seq_valid_i     (guard_seq_valid),
    .seq_i           (seq_o),
    .count_i         (count_o),
    .clear_stale_i   (1'b0),
    .accept_packet_o (guard_accept_packet),
    .drop_packet_o   (guard_drop_packet),
    .in_order_o      (guard_in_order),
    .duplicate_o     (guard_duplicate),
    .gap_o           (guard_gap),
    .heartbeat_o     (guard_heartbeat),
    .eos_o           (guard_eos),
    .stale_o         (stale_o),
    .expected_seq_o  (expected_seq_o),
    .gap_start_o     (gap_start_o),
    .gap_end_o       (gap_end_o)
  );

  always_ff @(posedge clk) begin : sequential_parser
    logic push_body;
    logic pop_body;
    logic consume_one;
    logic direct_payload;
    logic parser_fault;
    logic [MOLD_ERR_W-1:0] parser_fault_bits;

    logic [2:0] input_bytes;
    logic [DGRAM_LEN_W-1:0] seen_after_input;
    logic [DGRAM_LEN_W-1:0] body_total_bytes;
    logic [DGRAM_LEN_W-1:0] consumed_after;
    logic [DGRAM_LEN_W-1:0] bytes_after_length;

    logic [MOLD_SEQ_W-1:0] seq_full;
    logic [MOLD_SEQ_W-1:0] count_ext;
    logic [MOLD_MSG_LEN_W-1:0] parsed_len;

    axis_data_t pack_after;
    logic [PACK_COUNT_W-1:0] pack_count_after;
    logic final_message;
    logic final_datagram;
    logic slow_would_emit;
    logic final_boundary_ok;

    if (!rst_n) begin
      state                 <= ST_HEADER;
      header_beat_idx       <= '0;

      dgram_len             <= '0;
      dgram_bytes_seen      <= '0;
      body_bytes_consumed   <= '0;
      dgram_end_seen        <= 1'b0;
      dropping              <= 1'b0;

      messages_left         <= '0;
      msg_len_hi            <= '0;
      pending_msg_len       <= '0;
      payload_left          <= '0;

      body_wr_ptr           <= '0;
      body_rd_ptr           <= '0;
      body_fifo_count       <= '0;
      body_head_lane        <= '0;

      payload_pack_data     <= '0;
      payload_pack_count    <= '0;

      m_payload_tdata_o     <= '0;
      m_payload_tkeep_o     <= '0;
      m_payload_tvalid_o    <= 1'b0;
      m_payload_tlast_o     <= 1'b0;

      m_msg_len_o           <= '0;
      m_msg_len_valid_o     <= 1'b0;

      session_o             <= '0;
      seq_o                 <= '0;
      count_o               <= '0;
      expected_next_o       <= '0;

      seq_valid_o           <= 1'b0;
      heartbeat_o           <= 1'b0;
      eos_o                 <= 1'b0;
      in_order_o            <= 1'b0;
      duplicate_o           <= 1'b0;
      gap_o                 <= 1'b0;
      mold_drop_o           <= 1'b0;
      mold_err_o            <= '0;
    end else begin
      push_body         = 1'b0;
      pop_body          = 1'b0;
      consume_one       = 1'b0;
      direct_payload    = 1'b0;
      parser_fault      = 1'b0;
      parser_fault_bits = '0;

      input_bytes       = 3'd0;
      seen_after_input  = dgram_bytes_seen;
      body_total_bytes  = dgram_len - MOLD_HDR_BYTES_DGRAM;
      consumed_after    = body_bytes_consumed;
      bytes_after_length = '0;

      seq_full          = seq_o;
      count_ext         = '0;
      parsed_len        = '0;

      pack_after        = payload_pack_data;
      pack_count_after  = payload_pack_count;
      final_message     = 1'b0;
      final_datagram    = 1'b0;
      slow_would_emit   = 1'b0;
      final_boundary_ok = 1'b0;

      // Pulse outputs default low. Persistent AXI outputs are held until their
      // normal valid/ready handshake.
      seq_valid_o <= 1'b0;
      heartbeat_o <= 1'b0;
      eos_o       <= 1'b0;
      in_order_o  <= 1'b0;
      duplicate_o <= 1'b0;
      gap_o       <= 1'b0;
      mold_drop_o <= 1'b0;
      mold_err_o  <= '0;

      if (payload_output_fire) begin
        m_payload_tvalid_o <= 1'b0;
        m_payload_tlast_o  <= 1'b0;
      end

      if (msg_len_output_fire) begin
        m_msg_len_valid_o <= 1'b0;
      end

      // Input handling is deliberately independent of parser consumption.
      if (input_fire) begin
        input_bytes      = keep_byte_count(s_axis_tkeep_i);
        seen_after_input = dgram_bytes_seen + DGRAM_LEN_W'(input_bytes);

        if (tkeep_bad(s_axis_tkeep_i, s_axis_tlast_i)) begin
          parser_fault_bits[MOLD_ERR_BAD_TKEEP] = 1'b1;
          parser_fault = 1'b1;
        end

        if (state == ST_HEADER) begin
          if (header_beat_idx == 3'd0) begin
            dgram_len           <= s_dgram_len_i;
            dgram_bytes_seen    <= DGRAM_LEN_W'(input_bytes);
            body_bytes_consumed <= '0;
            dgram_end_seen      <= s_axis_tlast_i;
            dropping            <= 1'b0;
            body_wr_ptr         <= '0;
            body_rd_ptr         <= '0;
            body_fifo_count     <= '0;
            body_head_lane      <= '0;
            payload_pack_data   <= '0;
            payload_pack_count  <= '0;
            messages_left       <= '0;
            pending_msg_len     <= '0;
            payload_left        <= '0;

            if (!s_dgram_start_i
                || (s_dgram_len_i < MOLD_HDR_BYTES_DGRAM)) begin
              parser_fault_bits[MOLD_ERR_SHORT_DGRAM] = 1'b1;
              parser_fault = 1'b1;
            end
          end else begin
            dgram_bytes_seen <= seen_after_input;
            if (s_axis_tlast_i) begin
              dgram_end_seen <= 1'b1;
            end
          end

          if (input_bytes != AXIS_KEEP_W) begin
            parser_fault_bits[MOLD_ERR_SHORT_DGRAM] = 1'b1;
            parser_fault = 1'b1;
          end

          if (s_axis_tlast_i && (header_beat_idx != 3'd4)) begin
            parser_fault_bits[MOLD_ERR_SHORT_DGRAM] = 1'b1;
            parser_fault = 1'b1;
          end

          if (s_axis_tlast_i) begin
            if (header_beat_idx == 3'd0) begin
              if (DGRAM_LEN_W'(input_bytes) != s_dgram_len_i) begin
                parser_fault_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
                parser_fault = 1'b1;
              end
            end else if (seen_after_input != dgram_len) begin
              parser_fault_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
              parser_fault = 1'b1;
            end
          end

          unique case (header_beat_idx)
            3'd0: begin
              session_o[MOLD_SESSION_W-1 -: 32] <= s_axis_tdata_i;
              header_beat_idx <= 3'd1;
            end

            3'd1: begin
              session_o[MOLD_SESSION_W-33 -: 32] <= s_axis_tdata_i;
              header_beat_idx <= 3'd2;
            end

            3'd2: begin
              session_o[15:0] <= s_axis_tdata_i[31:16];
              seq_o[63:48]    <= s_axis_tdata_i[15:0];
              header_beat_idx <= 3'd3;
            end

            3'd3: begin
              seq_o[47:16]    <= s_axis_tdata_i;
              header_beat_idx <= 3'd4;
            end

            3'd4: begin
              seq_full = {seq_o[63:16], s_axis_tdata_i[31:16]};
              count_ext = '0;
              count_ext[MOLD_COUNT_W-1:0] = s_axis_tdata_i[15:0];

              seq_o           <= seq_full;
              count_o         <= s_axis_tdata_i[15:0];
              expected_next_o <= seq_full + count_ext;
              header_beat_idx <= '0;
              state           <= ST_GUARD;
            end

            default: begin
              parser_fault_bits[MOLD_ERR_SHORT_DGRAM] = 1'b1;
              parser_fault = 1'b1;
            end
          endcase
        end else if ((state == ST_MSG_LEN_HI)
                     || (state == ST_MSG_LEN_LO)
                     || (state == ST_LEN_WAIT)
                     || (state == ST_PAYLOAD)) begin
          dgram_bytes_seen <= seen_after_input;

          if (s_axis_tlast_i) begin
            dgram_end_seen <= 1'b1;
            if (seen_after_input != dgram_len) begin
              parser_fault_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
              parser_fault = 1'b1;
            end
          end

          if (!parser_fault) begin
            body_fifo_data[body_wr_ptr] <= s_axis_tdata_i;
            body_fifo_keep[body_wr_ptr] <= s_axis_tkeep_i;
            body_fifo_last[body_wr_ptr] <= s_axis_tlast_i;
            body_wr_ptr                 <= ptr_increment(body_wr_ptr);
            push_body                   = 1'b1;
          end
        end else if (state == ST_DRAIN) begin
          dgram_bytes_seen <= seen_after_input;
          if (s_axis_tlast_i) begin
            dgram_end_seen <= 1'b1;
            if (seen_after_input != dgram_len) begin
              parser_fault_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
              parser_fault = 1'b1;
            end
          end
        end
      end

      // Registered sequence-policy cycle.
      if (state == ST_GUARD) begin
        seq_valid_o <= 1'b1;
        heartbeat_o <= guard_heartbeat;
        eos_o       <= guard_eos;
        in_order_o  <= guard_in_order;
        duplicate_o <= guard_duplicate;
        gap_o       <= guard_gap;

        if (guard_accept_packet) begin
          messages_left <= count_o;

          if (dgram_end_seen) begin
            parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
            parser_fault = 1'b1;
          end else begin
            state <= ST_MSG_LEN_HI;
          end
        end else begin
          dropping <= 1'b1;
          state    <= ST_DRAIN;

          if (guard_eos && (dgram_len != MOLD_HDR_BYTES_DGRAM)) begin
            parser_fault_bits[MOLD_ERR_EOS_PAYLOAD] = 1'b1;
            parser_fault = 1'b1;
          end else if (guard_heartbeat
                       && (dgram_len != MOLD_HDR_BYTES_DGRAM)) begin
            parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
            parser_fault = 1'b1;
          end
        end
      end

      // Parser state actions use only the already-registered FIFO head. Input
      // accepted in this cycle is intentionally not parser-visible until the
      // next cycle.
      if (!parser_fault && !dropping) begin
        unique case (state)
          ST_MSG_LEN_HI: begin
            if (body_fifo_count != '0) begin
              msg_len_hi      <= body_head_byte;
              consume_one     = 1'b1;
              consumed_after  = body_bytes_consumed + DGRAM_LEN_W'(1);
              body_bytes_consumed <= consumed_after;
              state           <= ST_MSG_LEN_LO;
            end else if (dgram_end_seen) begin
              parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
              parser_fault = 1'b1;
            end
          end

          ST_MSG_LEN_LO: begin
            if ((body_fifo_count != '0) && msg_len_slot_available) begin
              parsed_len = {msg_len_hi, body_head_byte};
              consumed_after = body_bytes_consumed + DGRAM_LEN_W'(1);
              bytes_after_length = body_total_bytes - consumed_after;

              if ((messages_left == '0)
                  || (parsed_len == '0)
                  || (consumed_after > body_total_bytes)
                  || (parsed_len > bytes_after_length)) begin
                parser_fault_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
                parser_fault = 1'b1;
              end else begin
                consume_one         = 1'b1;
                body_bytes_consumed <= consumed_after;
                pending_msg_len     <= parsed_len;
                m_msg_len_o         <= parsed_len;
                m_msg_len_valid_o   <= 1'b1;
                state               <= ST_LEN_WAIT;
              end
            end else if ((body_fifo_count == '0) && dgram_end_seen) begin
              parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
              parser_fault = 1'b1;
            end
          end

          ST_LEN_WAIT: begin
            if (msg_len_output_fire) begin
              payload_left <= pending_msg_len;
              state        <= ST_PAYLOAD;
            end
          end

          ST_PAYLOAD: begin
            if (payload_left == '0) begin
              parser_fault_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
              parser_fault = 1'b1;
            end else if (body_fifo_count != '0) begin
              // Full-beat fast path. It is intentionally narrow: only an
              // aligned, full input beat and an empty pack register qualify.
              // Every decision uses registered state, so this path does not
              // chain four byte-level FSM transitions.
              if ((body_head_lane == 2'd0)
                  && (body_head_keep == {AXIS_KEEP_W{1'b1}})
                  && (payload_pack_count == '0)
                  && (payload_left >= MOLD_MSG_LEN_W'(AXIS_KEEP_W))
                  && payload_slot_available) begin
                direct_payload = 1'b1;
                final_message  =
                    (payload_left == MOLD_MSG_LEN_W'(AXIS_KEEP_W));
                final_datagram = final_message
                               && (messages_left == MOLD_COUNT_W'(1));
                consumed_after = body_bytes_consumed
                               + DGRAM_LEN_W'(AXIS_KEEP_W);

                if (final_datagram) begin
                  final_boundary_ok = body_head_last
                                   && (body_fifo_count == BODY_FIFO_CW'(1))
                                   && dgram_end_seen
                                   && (consumed_after == body_total_bytes);
                end else begin
                  final_boundary_ok = 1'b1;
                end

                if (!final_boundary_ok) begin
                  parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
                  parser_fault = 1'b1;
                  direct_payload = 1'b0;
                end else begin
                  m_payload_tdata_o  <= body_head_data;
                  m_payload_tkeep_o  <= {AXIS_KEEP_W{1'b1}};
                  m_payload_tvalid_o <= 1'b1;
                  m_payload_tlast_o  <= final_datagram;

                  pop_body            = 1'b1;
                  body_bytes_consumed <= consumed_after;
                  payload_left        <= payload_left
                                       - MOLD_MSG_LEN_W'(AXIS_KEEP_W);

                  if (final_message) begin
                    payload_left <= '0;

                    if (final_datagram) begin
                      messages_left <= '0;
                      state         <= ST_DONE;
                    end else begin
                      messages_left <= messages_left - MOLD_COUNT_W'(1);
                      state         <= ST_MSG_LEN_HI;
                    end
                  end
                end
              end else begin
                // Boundary path. Exactly one byte is consumed, so the logic
                // depth remains bounded regardless of the number of lanes.
                final_message   = (payload_left == MOLD_MSG_LEN_W'(1));
                final_datagram  = final_message
                                && (messages_left == MOLD_COUNT_W'(1));
                pack_after      = insert_pack_byte(
                                    payload_pack_data,
                                    payload_pack_count,
                                    body_head_byte
                                  );
                pack_count_after = payload_pack_count + PACK_COUNT_W'(1);
                slow_would_emit  = (pack_count_after == PACK_COUNT_W'(AXIS_KEEP_W))
                                || final_datagram;
                consumed_after   = body_bytes_consumed + DGRAM_LEN_W'(1);

                if (final_datagram) begin
                  final_boundary_ok = body_head_last
                                   && body_head_is_last_lane
                                   && (body_fifo_count == BODY_FIFO_CW'(1))
                                   && dgram_end_seen
                                   && (consumed_after == body_total_bytes);
                end else begin
                  final_boundary_ok = 1'b1;
                end

                if (!final_boundary_ok) begin
                  parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
                  parser_fault = 1'b1;
                end else if (!slow_would_emit || payload_slot_available) begin
                  consume_one         = 1'b1;
                  body_bytes_consumed <= consumed_after;
                  payload_left        <= payload_left - MOLD_MSG_LEN_W'(1);

                  if (slow_would_emit) begin
                    m_payload_tdata_o  <= pack_after;
                    m_payload_tkeep_o  <= keep_from_count(pack_count_after);
                    m_payload_tvalid_o <= 1'b1;
                    m_payload_tlast_o  <= final_datagram;
                    payload_pack_data  <= '0;
                    payload_pack_count <= '0;
                  end else begin
                    payload_pack_data  <= pack_after;
                    payload_pack_count <= pack_count_after;
                  end

                  if (final_message) begin
                    payload_left <= '0;

                    if (final_datagram) begin
                      messages_left <= '0;
                      state         <= ST_DONE;
                    end else begin
                      messages_left <= messages_left - MOLD_COUNT_W'(1);
                      state         <= ST_MSG_LEN_HI;
                    end
                  end
                end
              end
            end else if (dgram_end_seen) begin
              parser_fault_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
              parser_fault = 1'b1;
            end
          end

          default: begin
            // Header, guard, drain and done are handled separately.
          end
        endcase
      end

      // Advance or remove the FIFO head after one boundary byte or one direct
      // full-beat transfer. This small cursor replaces all variable reservoir
      // shifts from the previous implementation.
      if (consume_one) begin
        if (body_head_is_last_lane) begin
          pop_body       = 1'b1;
          body_head_lane <= '0;
        end else begin
          body_head_lane <= body_head_lane + 2'd1;
        end
      end

      if (direct_payload) begin
        body_head_lane <= '0;
      end

      // Drain one already-buffered beat per cycle. Incoming drain beats are
      // discarded directly and therefore do not compete for FIFO space.
      if (state == ST_DRAIN) begin
        if (body_fifo_count != '0) begin
          pop_body       = 1'b1;
          body_head_lane <= '0;
        end else if (dgram_end_seen
                     && !m_payload_tvalid_o
                     && !m_msg_len_valid_o) begin
          state <= ST_DONE;
        end
      end

      if (pop_body) begin
        body_rd_ptr <= ptr_increment(body_rd_ptr);
      end

      unique case ({push_body, pop_body})
        2'b10: body_fifo_count <= body_fifo_count + BODY_FIFO_CW'(1);
        2'b01: body_fifo_count <= body_fifo_count - BODY_FIFO_CW'(1);
        default: begin
          // Simultaneous push/pop preserves occupancy; no action required.
        end
      endcase

      // Faults only select the registered drain state and pulse status. They do
      // not synchronously clear every datapath register through a deep control
      // cone. This is the main timing-closure change relative to the exported
      // implementation.
      if (parser_fault) begin
        mold_drop_o <= 1'b1;
        mold_err_o  <= parser_fault_bits;
        dropping    <= 1'b1;
        state       <= ST_DRAIN;
      end

      // ST_DONE is a registered cleanup boundary. Wait until any previously
      // issued AXI item has been accepted, then clear only from this state.
      if (state == ST_DONE) begin
        if (!m_payload_tvalid_o && !m_msg_len_valid_o) begin
          state                 <= ST_HEADER;
          header_beat_idx       <= '0;

          dgram_len             <= '0;
          dgram_bytes_seen      <= '0;
          body_bytes_consumed   <= '0;
          dgram_end_seen        <= 1'b0;
          dropping              <= 1'b0;

          messages_left         <= '0;
          msg_len_hi            <= '0;
          pending_msg_len       <= '0;
          payload_left          <= '0;

          body_wr_ptr           <= '0;
          body_rd_ptr           <= '0;
          body_fifo_count       <= '0;
          body_head_lane        <= '0;

          payload_pack_data     <= '0;
          payload_pack_count    <= '0;
        end
      end
    end
  end

endmodule

`default_nettype wire
