// REVISION MARKER: 4LANE_BACKPRESSURE_FIX_V2
// contract:
// - Input is one MoldUDP64 datagram per AXI packet from frame_crack.
// - s_dgram_len_i is the UDP payload length, valid with s_dgram_start_i.
// - Output payload stream is the concatenation of ITCH message payload bytes;
//   MoldUDP64 2-byte length prefixes are stripped.
// - Message boundaries are carried on a separate length stream. A msg_len item
//   must be accepted before the first payload byte of that message is emitted.
// - m_payload_tlast_o marks end of MoldUDP64 datagram, not end of ITCH message.
// - session/seq/count sideband feeds mold_seq_guard for Phase-4 A/B + gap policy.
//
// Implementation note:
// - All valid byte lanes in one 32-bit AXIS beat are processed together.
// - A single carry beat is retained only when a message-length handshake or
//   sequence decision prevents the remaining lanes from being consumed.
// - The payload output and message-length output each retain their value under
//   backpressure, so the module remains AXI-stream compliant.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module mold_deframe (
  input  wire       clk,
  input  wire       rst_n,

  // AXIS MoldUDP64 datagram input.
  input  wire axis_data_t s_axis_tdata_i,
  input  wire axis_keep_t s_axis_tkeep_i,
  input  wire       s_axis_tvalid_i,
  input  wire       s_axis_tlast_i,
  output logic       s_axis_tready_o,

  // Datagram metadata from frame_crack. Valid with s_dgram_start_i.
  input  wire [DGRAM_LEN_W-1:0] s_dgram_len_i,
  input  wire                   s_dgram_start_i,

  // AXIS ITCH payload byte stream, with MoldUDP64 length prefixes removed.
  output axis_data_t m_payload_tdata_o,
  output axis_keep_t m_payload_tkeep_o,
  output logic       m_payload_tvalid_o,
  output logic       m_payload_tlast_o,
  input  wire       m_payload_tready_i,

  // Per-message length stream to realign. One item per ITCH payload.
  output logic [MOLD_MSG_LEN_W-1:0] m_msg_len_o,
  output logic                      m_msg_len_valid_o,
  input  wire                      m_msg_len_ready_i,

  // MoldUDP64 header sideband. seq_valid_o pulses once per datagram after the
  // 20-byte MoldUDP64 header is accepted and decoded.
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

  typedef enum logic [2:0] {
    ST_HEADER,
    ST_GUARD,
    ST_MSG_LEN_HI,
    ST_MSG_LEN_LO,
    ST_LEN_WAIT,
    ST_PAYLOAD,
    ST_DRAIN
  } state_t;

  localparam int LANE_INDEX_W = (AXIS_KEEP_W <= 2) ? 1 : $clog2(AXIS_KEEP_W);
  localparam logic [DGRAM_LEN_W-1:0] MOLD_HDR_BYTES_DGRAM = DGRAM_LEN_W'(MOLD_HDR_BYTES);

  state_t state;
  state_t state_next;

  // One carry beat is sufficient because a 32-bit input beat can generate at
  // most one 32-bit payload beat and one message-length item.
  axis_data_t pending_data;
  axis_data_t pending_data_next;
  axis_keep_t pending_keep;
  axis_keep_t pending_keep_next;
  logic       pending_last;
  logic       pending_last_next;
  logic       pending_valid;
  logic       pending_valid_next;
  logic [LANE_INDEX_W-1:0] pending_lane;
  logic [LANE_INDEX_W-1:0] pending_lane_next;

  logic [DGRAM_LEN_W-1:0] dgram_len;
  logic [DGRAM_LEN_W-1:0] dgram_len_next;
  logic [DGRAM_LEN_W-1:0] dgram_byte_idx;
  logic [DGRAM_LEN_W-1:0] dgram_byte_idx_next;
  logic                   in_dgram;
  logic                   in_dgram_next;
  logic                   dgram_end_seen;
  logic                   dgram_end_seen_next;
  logic                   dropping;
  logic                   dropping_next;

  logic [MOLD_COUNT_W-1:0] messages_left;
  logic [MOLD_COUNT_W-1:0] messages_left_next;
  logic [MOLD_MSG_LEN_W-1:0] msg_len_shift;
  logic [MOLD_MSG_LEN_W-1:0] msg_len_shift_next;
  logic [MOLD_MSG_LEN_W-1:0] payload_left;
  logic [MOLD_MSG_LEN_W-1:0] payload_left_next;

  axis_data_t payload_pack_data;
  axis_data_t payload_pack_data_next;
  axis_keep_t payload_pack_keep;
  axis_keep_t payload_pack_keep_next;
  logic [3:0] payload_pack_count;
  logic [3:0] payload_pack_count_next;

  axis_data_t m_payload_tdata_next;
  axis_keep_t m_payload_tkeep_next;
  logic       m_payload_tvalid_next;
  logic       m_payload_tlast_next;

  logic [MOLD_MSG_LEN_W-1:0] m_msg_len_next;
  logic                      m_msg_len_valid_next;

  logic [MOLD_SESSION_W-1:0] session_next;
  logic [MOLD_SEQ_W-1:0]     seq_next;
  logic [MOLD_COUNT_W-1:0]   count_next;
  logic [MOLD_SEQ_W-1:0]     expected_next_next;

  logic                      seq_valid_next;
  logic                      heartbeat_next;
  logic                      eos_next;
  logic                      in_order_next;
  logic                      duplicate_next;
  logic                      gap_next;
  logic                      mold_drop_next;
  logic [MOLD_ERR_W-1:0]     mold_err_next;

  logic                      guard_seq_valid;
  logic [MOLD_SEQ_W-1:0]     guard_seq;
  logic [MOLD_COUNT_W-1:0]   guard_count;
  logic                      guard_accept_packet;
  logic                      guard_drop_packet;
  logic                      guard_in_order;
  logic                      guard_duplicate;
  logic                      guard_gap;
  logic                      guard_heartbeat;
  logic                      guard_eos;

  logic payload_blocked;
  logic msg_len_blocked;

  assign payload_blocked = m_payload_tvalid_o && !m_payload_tready_i;
  assign msg_len_blocked = m_msg_len_valid_o && !m_msg_len_ready_i;

  // A carried partial beat is always completed before another input beat is
  // accepted. In the ordinary payload path pending_valid remains low, allowing
  // one complete input beat to be accepted every cycle.
  assign s_axis_tready_o = rst_n
                         && !pending_valid
                         && !dgram_end_seen
                         && (state != ST_GUARD)
                         && !payload_blocked
                         && !msg_len_blocked
                         && ((state != ST_LEN_WAIT)
                             || (m_msg_len_valid_o && m_msg_len_ready_i));

  function automatic logic lane_valid(input axis_keep_t keep, input int lane);
    lane_valid = keep[AXIS_KEEP_W-1-lane];
  endfunction

  function automatic logic [7:0] lane_byte(input axis_data_t data, input int lane);
    lane_byte = data[AXIS_DATA_W-1-(8*lane) -: 8];
  endfunction

  function automatic logic valid_lane_after(input axis_keep_t keep, input int lane);
    int next_lane;
    begin
      valid_lane_after = 1'b0;
      for (next_lane = lane + 1; next_lane < AXIS_KEEP_W; next_lane++) begin
        valid_lane_after |= lane_valid(keep, next_lane);
      end
    end
  endfunction

  function automatic logic last_keep_is_contiguous(input axis_keep_t keep);
    logic seen_zero;
    int   lane;
    begin
      // Valid bytes are packed from the MSB lane downwards. For the current
      // 32-bit ingress this accepts 1000, 1100, 1110 and 1111. Keeping this
      // as a small loop makes it stay correct if AXIS_DATA_W is widened later.
      seen_zero = 1'b0;
      last_keep_is_contiguous = (keep != '0);

      for (lane = 0; lane < AXIS_KEEP_W; lane++) begin
        if (!keep[AXIS_KEEP_W-1-lane]) begin
          seen_zero = 1'b1;
        end else if (seen_zero) begin
          last_keep_is_contiguous = 1'b0;
        end
      end
    end
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

  // The parsed header is held for one cycle in ST_GUARD. This keeps the
  // sequence-policy decision outside the four-lane parser's combinational path
  // while still reducing header latency from roughly 24 cycles to 6 cycles.
  assign guard_seq_valid = rst_n && (state == ST_GUARD);
  assign guard_seq       = seq_o;
  assign guard_count     = count_o;

  mold_seq_guard #(
    .SEQ_W   (MOLD_SEQ_W),
    .COUNT_W (MOLD_COUNT_W)
  ) u_mold_seq_guard (
    .clk             (clk),
    .rst_n           (rst_n),
    .seq_valid_i     (guard_seq_valid),
    .seq_i           (guard_seq),
    .count_i         (guard_count),
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

  always_comb begin : next_state_logic
    logic             source_present;
    logic             source_is_pending;
    axis_data_t       source_data;
    axis_keep_t       source_keep;
    logic             source_last;
    int               source_start_lane;
    logic             stop_processing;
    logic             source_complete;
    logic             stop_after_byte;
    logic             defer_current_byte;
    logic [7:0]       current_byte;
    logic [3:0]       pack_count_v;
    logic             final_msg_byte;
    logic             final_payload_byte;
    logic             would_emit_payload;
    logic [MOLD_COUNT_W-1:0]   count_v;
    logic [MOLD_SEQ_W-1:0]     count_ext_v;
    logic [MOLD_MSG_LEN_W-1:0] msg_len_v;
    logic [DGRAM_LEN_W-1:0]    bytes_after_len;
    logic [MOLD_ERR_W-1:0]     err_bits;
    axis_data_t       emit_data;
    axis_keep_t       emit_keep;
    int               header_byte_idx;
    int               pack_index;
    int               lane;

    // Defaults for all block-local temporaries. These are combinational
    // scratch values only; assigning them on every path prevents unintended
    // latch inference in both Vivado and Verilator.
    source_present      = 1'b0;
    source_is_pending   = 1'b0;
    source_data         = '0;
    source_keep         = '0;
    source_last         = 1'b0;
    source_start_lane   = 0;
    stop_processing     = 1'b0;
    source_complete     = 1'b0;
    stop_after_byte     = 1'b0;
    defer_current_byte  = 1'b0;
    current_byte        = '0;
    pack_count_v        = '0;
    final_msg_byte      = 1'b0;
    final_payload_byte  = 1'b0;
    would_emit_payload  = 1'b0;
    count_v             = '0;
    count_ext_v         = '0;
    msg_len_v           = '0;
    bytes_after_len     = '0;
    err_bits            = '0;
    emit_data           = '0;
    emit_keep           = '0;
    header_byte_idx     = 0;
    pack_index          = 0;

    state_next              = state;

    pending_data_next       = pending_data;
    pending_keep_next       = pending_keep;
    pending_last_next       = pending_last;
    pending_valid_next      = pending_valid;
    pending_lane_next       = pending_lane;

    dgram_len_next          = dgram_len;
    dgram_byte_idx_next     = dgram_byte_idx;
    in_dgram_next           = in_dgram;
    dgram_end_seen_next     = dgram_end_seen;
    dropping_next           = dropping;

    messages_left_next      = messages_left;
    msg_len_shift_next      = msg_len_shift;
    payload_left_next       = payload_left;

    payload_pack_data_next  = payload_pack_data;
    payload_pack_keep_next  = payload_pack_keep;
    payload_pack_count_next = payload_pack_count;

    m_payload_tdata_next    = m_payload_tdata_o;
    m_payload_tkeep_next    = m_payload_tkeep_o;
    m_payload_tvalid_next   = m_payload_tvalid_o;
    m_payload_tlast_next    = m_payload_tlast_o;

    m_msg_len_next          = m_msg_len_o;
    m_msg_len_valid_next    = m_msg_len_valid_o;

    session_next            = session_o;
    seq_next                = seq_o;
    count_next              = count_o;
    expected_next_next      = expected_next_o;

    seq_valid_next          = 1'b0;
    heartbeat_next          = 1'b0;
    eos_next                = 1'b0;
    in_order_next           = 1'b0;
    duplicate_next          = 1'b0;
    gap_next                = 1'b0;
    mold_drop_next          = 1'b0;
    mold_err_next           = '0;

    // Retire already-present output items first. The parser may refill the same
    // register in this cycle, allowing one output beat per cycle when ready.
    if (m_payload_tvalid_o && m_payload_tready_i) begin
      m_payload_tvalid_next = 1'b0;
      m_payload_tlast_next  = 1'b0;
    end

    if (m_msg_len_valid_o && m_msg_len_ready_i) begin
      m_msg_len_valid_next = 1'b0;

      if (state == ST_LEN_WAIT) begin
        if (msg_len_shift == '0) begin
          if (messages_left <= {{(MOLD_COUNT_W-1){1'b0}}, 1'b1}) begin
            messages_left_next = '0;
            state_next         = ST_DRAIN;
          end else begin
            messages_left_next = messages_left - {{(MOLD_COUNT_W-1){1'b0}}, 1'b1};
            state_next         = ST_MSG_LEN_HI;
          end
        end else begin
          payload_left_next = msg_len_shift;
          state_next        = ST_PAYLOAD;
        end
      end
    end

    // Sequence handling is deliberately a one-cycle registered boundary. It
    // avoids placing the 64-bit comparison/add path inside the byte parser.
    if (state == ST_GUARD) begin
      seq_valid_next = 1'b1;
      heartbeat_next = guard_heartbeat;
      eos_next       = guard_eos;
      in_order_next  = guard_in_order;
      duplicate_next = guard_duplicate;
      gap_next       = guard_gap;

      if (guard_heartbeat || guard_eos) begin
        state_next = ST_DRAIN;

        if (dgram_len != MOLD_HDR_BYTES_DGRAM) begin
          err_bits = '0;
          err_bits[MOLD_ERR_EOS_PAYLOAD] = 1'b1;
          if (!dropping_next) begin
            mold_drop_next = 1'b1;
            mold_err_next  = err_bits;
          end
          dropping_next = 1'b1;
          state_next    = ST_DRAIN;
        end
      end else if (guard_accept_packet) begin
        messages_left_next = count_o;
        state_next         = ST_MSG_LEN_HI;
      end else begin
        // Duplicate/late datagram: drain its remaining AXIS bytes without
        // producing message-length or payload output.
        dropping_next = 1'b1;
        state_next    = ST_DRAIN;
      end
    end

    // A pending carry beat is consumed before any new AXIS beat. Otherwise the
    // live AXIS beat is processed directly on its handshake cycle.
    if (!payload_blocked && !msg_len_blocked && (state != ST_GUARD)) begin
      if (pending_valid) begin
        source_present    = 1'b1;
        source_is_pending = 1'b1;
        source_data       = pending_data;
        source_keep       = pending_keep;
        source_last       = pending_last;
        source_start_lane = int'(pending_lane);
      end else if (s_axis_tvalid_i && s_axis_tready_o) begin
        source_present    = 1'b1;
        source_data       = s_axis_tdata_i;
        source_keep       = s_axis_tkeep_i;
        source_last       = s_axis_tlast_i;
        source_start_lane = 0;

        if (!in_dgram) begin
          in_dgram_next       = 1'b1;
          dgram_end_seen_next = 1'b0;
          dgram_len_next      = s_dgram_len_i;
          dgram_byte_idx_next = '0;
          state_next          = ST_HEADER;
          dropping_next       = 1'b0;
          session_next        = '0;
          seq_next            = '0;
          count_next          = '0;

          if (!s_dgram_start_i || (s_dgram_len_i < MOLD_HDR_BYTES_DGRAM)) begin
            err_bits = '0;
            err_bits[MOLD_ERR_SHORT_DGRAM] = 1'b1;
            if (!dropping_next) begin
              mold_drop_next = 1'b1;
              mold_err_next  = err_bits;
            end
            dropping_next = 1'b1;
            state_next    = ST_DRAIN;
          end
        end

        if (tkeep_bad(s_axis_tkeep_i, s_axis_tlast_i)) begin
          err_bits = '0;
          err_bits[MOLD_ERR_BAD_TKEEP] = 1'b1;
          if (!dropping_next) begin
            mold_drop_next = 1'b1;
            mold_err_next  = err_bits;
          end
          dropping_next = 1'b1;
          state_next    = ST_DRAIN;
        end
      end
    end

    source_complete = source_present;

    if (source_present) begin
      for (lane = 0; lane < AXIS_KEEP_W; lane++) begin
        if ((lane >= source_start_lane) && lane_valid(source_keep, lane) && !stop_processing) begin
          stop_after_byte    = 1'b0;
          defer_current_byte = 1'b0;
          current_byte       = lane_byte(source_data, lane);

          // ST_GUARD and ST_LEN_WAIT consume no bytes. If either is reached
          // inside this beat, preserve the current or remaining lanes.
          if ((state_next == ST_GUARD) || (state_next == ST_LEN_WAIT)) begin
            stop_processing = 1'b1;
            source_complete = 1'b0;

            pending_data_next  = source_data;
            pending_keep_next  = source_keep;
            pending_last_next  = source_last;
            pending_valid_next = 1'b1;
            pending_lane_next  = LANE_INDEX_W'(lane);
          end else begin
            if (!dropping_next && (dgram_byte_idx_next >= dgram_len_next)) begin
              err_bits = '0;
              err_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
              if (!dropping_next) begin
                mold_drop_next = 1'b1;
                mold_err_next  = err_bits;
              end
              dropping_next = 1'b1;
              state_next    = ST_DRAIN;
            end else if (!dropping_next) begin
              unique case (state_next)
                ST_HEADER: begin
                  header_byte_idx = int'(dgram_byte_idx_next);

                  if (header_byte_idx < MOLD_SESSION_BYTES) begin
                    session_next[MOLD_SESSION_W-1-(8*header_byte_idx) -: 8] = current_byte;
                  end else if (header_byte_idx < (MOLD_SESSION_BYTES + MOLD_SEQ_BYTES)) begin
                    seq_next[MOLD_SEQ_W-1-(8*(header_byte_idx-MOLD_SESSION_BYTES)) -: 8] = current_byte;
                  end else if (header_byte_idx == 18) begin
                    count_next[15:8] = current_byte;
                  end else if (header_byte_idx == 19) begin
                    count_v = {count_next[15:8], current_byte};
                    count_ext_v[MOLD_COUNT_W-1:0] = count_v;

                    count_next         = count_v;
                    expected_next_next = seq_next + count_ext_v;
                    state_next         = ST_GUARD;
                    stop_after_byte    = 1'b1;
                  end
                end

                ST_MSG_LEN_HI: begin
                  msg_len_shift_next[15:8] = current_byte;
                  state_next               = ST_MSG_LEN_LO;
                end

                ST_MSG_LEN_LO: begin
                  msg_len_v       = {msg_len_shift_next[15:8], current_byte};
                  bytes_after_len = dgram_len_next - (dgram_byte_idx_next + 16'd1);
                  msg_len_shift_next = msg_len_v;
                  m_msg_len_next     = msg_len_v;

                  if (msg_len_v > bytes_after_len) begin
                    err_bits = '0;
                    err_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
                    if (!dropping_next) begin
                      mold_drop_next = 1'b1;
                      mold_err_next  = err_bits;
                    end
                    dropping_next = 1'b1;
                    state_next    = ST_DRAIN;
                  end else begin
                    m_msg_len_valid_next = 1'b1;
                    state_next           = ST_LEN_WAIT;
                    stop_after_byte      = 1'b1;
                  end
                end

                ST_PAYLOAD: begin
                  pack_index = int'(payload_pack_count_next);
                  emit_data  = payload_pack_data_next;
                  emit_keep  = payload_pack_keep_next;
                  emit_data[AXIS_DATA_W-1-(8*pack_index) -: 8] = current_byte;
                  emit_keep[AXIS_KEEP_W-1-pack_index]          = 1'b1;

                  pack_count_v       = payload_pack_count_next + 4'd1;
                  final_msg_byte     = (payload_left_next == 16'd1);
                  final_payload_byte = final_msg_byte
                                     && (messages_left_next == {{(MOLD_COUNT_W-1){1'b0}}, 1'b1});
                  would_emit_payload = (int'(pack_count_v) == AXIS_KEEP_W)
                                     || final_payload_byte;

                  // One output register can hold only one beat. With carry bytes
                  // already in payload_pack_data, a single input beat can create
                  // a full output beat and then also reach the final partial
                  // datagram beat. Preserve the current lane for the next cycle
                  // rather than overwriting the first output beat.
                  if (m_payload_tvalid_next && would_emit_payload) begin
                    defer_current_byte = 1'b1;
                  end else begin
                    if (would_emit_payload) begin
                      m_payload_tdata_next  = emit_data;
                      m_payload_tkeep_next  = emit_keep;
                      m_payload_tvalid_next = 1'b1;
                      m_payload_tlast_next  = final_payload_byte;

                      payload_pack_data_next  = '0;
                      payload_pack_keep_next  = '0;
                      payload_pack_count_next = '0;
                    end else begin
                      payload_pack_data_next  = emit_data;
                      payload_pack_keep_next  = emit_keep;
                      payload_pack_count_next = pack_count_v;
                    end

                    payload_left_next = payload_left_next - 16'd1;

                    if (final_msg_byte) begin
                      payload_left_next = '0;

                      if (messages_left_next <= {{(MOLD_COUNT_W-1){1'b0}}, 1'b1}) begin
                        messages_left_next = '0;
                        state_next         = ST_DRAIN;
                      end else begin
                        messages_left_next = messages_left_next
                                           - {{(MOLD_COUNT_W-1){1'b0}}, 1'b1};
                        state_next         = ST_MSG_LEN_HI;
                      end
                    end
                  end
                end

                ST_DRAIN: begin
                  // No bytes are valid after all declared messages complete.
                  // Duplicate/error drains have dropping_next set and bypass
                  // this case before it is reached.
                  err_bits = '0;
                  err_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
                  if (!dropping_next) begin
                    mold_drop_next = 1'b1;
                    mold_err_next  = err_bits;
                  end
                  dropping_next = 1'b1;
                  state_next    = ST_DRAIN;
                end

                default: begin
                  state_next = ST_DRAIN;
                end
              endcase
            end

            if (defer_current_byte) begin
              stop_processing = 1'b1;
              source_complete = 1'b0;

              pending_data_next  = source_data;
              pending_keep_next  = source_keep;
              pending_last_next  = source_last;
              pending_valid_next = 1'b1;
              pending_lane_next  = LANE_INDEX_W'(lane);
            end else begin
              // A dropped datagram is still counted byte-for-byte so the final
              // length check and packet drain remain deterministic.
              dgram_byte_idx_next = dgram_byte_idx_next + 16'd1;

              if (stop_after_byte && valid_lane_after(source_keep, lane)) begin
                stop_processing = 1'b1;
                source_complete = 1'b0;

                pending_data_next  = source_data;
                pending_keep_next  = source_keep;
                pending_last_next  = source_last;
                pending_valid_next = 1'b1;
                pending_lane_next  = LANE_INDEX_W'(lane + 1);
              end
            end
          end
        end
      end

      if (source_complete) begin
        if (source_is_pending) begin
          pending_valid_next = 1'b0;
          pending_lane_next  = '0;
        end

        if (source_last) begin
          dgram_end_seen_next = 1'b1;

          if (!dropping_next && (dgram_byte_idx_next != dgram_len_next)) begin
            err_bits = '0;
            err_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
            if (!dropping_next) begin
              mold_drop_next = 1'b1;
              mold_err_next  = err_bits;
            end
            dropping_next = 1'b1;
            state_next    = ST_DRAIN;
          end
        end
      end
    end

    // Once the physical AXIS packet has ended, defer reset only while the
    // parsed header is awaiting the sequence decision or a final length item is
    // awaiting acceptance. All other parser states must have completed exactly.
    if (dgram_end_seen_next && !pending_valid_next) begin
      if ((state_next != ST_GUARD) && (state_next != ST_LEN_WAIT)) begin
        if (!dropping_next && (state_next != ST_DRAIN)) begin
          err_bits = '0;
          if ((state_next == ST_MSG_LEN_HI) || (state_next == ST_MSG_LEN_LO)) begin
            err_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
          end else begin
            err_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
          end
          if (!dropping_next) begin
            mold_drop_next = 1'b1;
            mold_err_next  = err_bits;
          end
          dropping_next = 1'b1;
          state_next    = ST_DRAIN;
        end

        in_dgram_next           = 1'b0;
        dgram_end_seen_next     = 1'b0;
        dropping_next           = 1'b0;
        state_next              = ST_HEADER;
        dgram_len_next          = '0;
        dgram_byte_idx_next     = '0;
        messages_left_next      = '0;
        msg_len_shift_next      = '0;
        payload_left_next       = '0;
        payload_pack_data_next  = '0;
        payload_pack_keep_next  = '0;
        payload_pack_count_next = '0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state                    <= ST_HEADER;

      pending_data             <= '0;
      pending_keep             <= '0;
      pending_last             <= 1'b0;
      pending_valid            <= 1'b0;
      pending_lane             <= '0;

      dgram_len                <= '0;
      dgram_byte_idx           <= '0;
      in_dgram                 <= 1'b0;
      dgram_end_seen           <= 1'b0;
      dropping                 <= 1'b0;

      messages_left            <= '0;
      msg_len_shift            <= '0;
      payload_left             <= '0;

      payload_pack_data        <= '0;
      payload_pack_keep        <= '0;
      payload_pack_count       <= '0;

      m_payload_tdata_o        <= '0;
      m_payload_tkeep_o        <= '0;
      m_payload_tvalid_o       <= 1'b0;
      m_payload_tlast_o        <= 1'b0;

      m_msg_len_o              <= '0;
      m_msg_len_valid_o        <= 1'b0;

      session_o                <= '0;
      seq_o                    <= '0;
      count_o                  <= '0;
      expected_next_o          <= '0;

      seq_valid_o              <= 1'b0;
      heartbeat_o              <= 1'b0;
      eos_o                    <= 1'b0;
      in_order_o               <= 1'b0;
      duplicate_o              <= 1'b0;
      gap_o                    <= 1'b0;
      mold_drop_o              <= 1'b0;
      mold_err_o               <= '0;
    end else begin
      state                    <= state_next;

      pending_data             <= pending_data_next;
      pending_keep             <= pending_keep_next;
      pending_last             <= pending_last_next;
      pending_valid            <= pending_valid_next;
      pending_lane             <= pending_lane_next;

      dgram_len                <= dgram_len_next;
      dgram_byte_idx           <= dgram_byte_idx_next;
      in_dgram                 <= in_dgram_next;
      dgram_end_seen           <= dgram_end_seen_next;
      dropping                 <= dropping_next;

      messages_left            <= messages_left_next;
      msg_len_shift            <= msg_len_shift_next;
      payload_left             <= payload_left_next;

      payload_pack_data        <= payload_pack_data_next;
      payload_pack_keep        <= payload_pack_keep_next;
      payload_pack_count       <= payload_pack_count_next;

      m_payload_tdata_o        <= m_payload_tdata_next;
      m_payload_tkeep_o        <= m_payload_tkeep_next;
      m_payload_tvalid_o       <= m_payload_tvalid_next;
      m_payload_tlast_o        <= m_payload_tlast_next;

      m_msg_len_o              <= m_msg_len_next;
      m_msg_len_valid_o        <= m_msg_len_valid_next;

      session_o                <= session_next;
      seq_o                    <= seq_next;
      count_o                  <= count_next;
      expected_next_o          <= expected_next_next;

      seq_valid_o              <= seq_valid_next;
      heartbeat_o              <= heartbeat_next;
      eos_o                    <= eos_next;
      in_order_o               <= in_order_next;
      duplicate_o              <= duplicate_next;
      gap_o                    <= gap_next;
      mold_drop_o              <= mold_drop_next;
      mold_err_o               <= mold_err_next;
    end
  end

endmodule

`default_nettype wire
