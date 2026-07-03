// contract:
// - Input is one MoldUDP64 datagram per AXI packet from frame_crack.
// - s_dgram_len_i is the UDP payload length, valid with s_dgram_start_i.
// - Output payload stream is the concatenation of ITCH message payload bytes;
//   MoldUDP64 2-byte length prefixes are stripped.
// - Message boundaries are carried on a separate length stream. A msg_len item
//   must be accepted before the first payload byte of that message is emitted.
// - m_payload_tlast_o marks end of MoldUDP64 datagram, not end of ITCH message.
// - session/seq/count sideband is extraction only; gap/A-B comparison is Phase 4.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module mold_deframe (
  input  logic       clk,
  input  logic       rst_n,

  // AXIS MoldUDP64 datagram input.
  input  axis_data_t s_axis_tdata_i,
  input  axis_keep_t s_axis_tkeep_i,
  input  logic       s_axis_tvalid_i,
  input  logic       s_axis_tlast_i,
  output logic       s_axis_tready_o,

  // Datagram metadata from frame_crack. Valid with s_dgram_start_i.
  input  logic [DGRAM_LEN_W-1:0] s_dgram_len_i,
  input  logic                   s_dgram_start_i,

  // AXIS ITCH payload byte stream, with MoldUDP64 length prefixes removed.
  output axis_data_t m_payload_tdata_o,
  output axis_keep_t m_payload_tkeep_o,
  output logic       m_payload_tvalid_o,
  output logic       m_payload_tlast_o,
  input  logic       m_payload_tready_i,

  // Per-message length stream to realign. One item per ITCH payload.
  output logic [MOLD_MSG_LEN_W-1:0] m_msg_len_o,
  output logic                      m_msg_len_valid_o,
  input  logic                      m_msg_len_ready_i,

  // MoldUDP64 header sideband. seq_valid_o pulses once per datagram after the
  // 20-byte MoldUDP64 header is accepted and decoded.
  output logic [MOLD_SESSION_W-1:0] session_o,
  output logic [MOLD_SEQ_W-1:0]     seq_o,
  output logic [MOLD_COUNT_W-1:0]   count_o,
  output logic [MOLD_SEQ_W-1:0]     expected_next_o,
  output logic                      seq_valid_o,
  output logic                      heartbeat_o,
  output logic                      eos_o,

  // Error/status.
  output logic                      mold_drop_o,
  output logic [MOLD_ERR_W-1:0]     mold_err_o
);

  typedef enum logic [2:0] {
    ST_HEADER,
    ST_MSG_LEN_HI,
    ST_MSG_LEN_LO,
    ST_LEN_WAIT,
    ST_PAYLOAD,
    ST_DRAIN
  } state_t;

  state_t state;

  axis_data_t beat_data;
  axis_keep_t beat_keep;
  logic       beat_last;
  logic       beat_valid;
  logic [3:0] beat_lane;

  logic [DGRAM_LEN_W-1:0] dgram_len;
  logic [DGRAM_LEN_W-1:0] dgram_byte_idx;
  logic                   in_dgram;
  logic                   dropping;

  logic [MOLD_COUNT_W-1:0] messages_left;
  logic [MOLD_MSG_LEN_W-1:0] msg_len_shift;
  logic [MOLD_MSG_LEN_W-1:0] payload_left;

  axis_data_t payload_pack_data;
  axis_keep_t payload_pack_keep;
  logic [3:0] payload_pack_count;

  assign s_axis_tready_o = rst_n && !beat_valid && !m_payload_tvalid_o && !m_msg_len_valid_o;

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

  task automatic flag_drop(input logic [MOLD_ERR_W-1:0] err_bits);
    if (!dropping) begin
      mold_drop_o <= 1'b1;
      mold_err_o  <= err_bits;
    end
    dropping <= 1'b1;
    state    <= ST_DRAIN;
  endtask

  task automatic reset_datagram_state();
    in_dgram           <= 1'b0;
    dropping           <= 1'b0;
    state              <= ST_HEADER;
    dgram_len          <= '0;
    dgram_byte_idx     <= '0;
    messages_left      <= '0;
    msg_len_shift      <= '0;
    payload_left       <= '0;
    payload_pack_data  <= '0;
    payload_pack_keep  <= '0;
    payload_pack_count <= '0;
  endtask

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      beat_data            <= '0;
      beat_keep            <= '0;
      beat_last            <= 1'b0;
      beat_valid           <= 1'b0;
      beat_lane            <= '0;
      state                <= ST_HEADER;
      dgram_len            <= '0;
      dgram_byte_idx       <= '0;
      in_dgram             <= 1'b0;
      dropping             <= 1'b0;
      messages_left        <= '0;
      msg_len_shift        <= '0;
      payload_left         <= '0;
      payload_pack_data    <= '0;
      payload_pack_keep    <= '0;
      payload_pack_count   <= '0;
      m_payload_tdata_o    <= '0;
      m_payload_tkeep_o    <= '0;
      m_payload_tvalid_o   <= 1'b0;
      m_payload_tlast_o    <= 1'b0;
      m_msg_len_o          <= '0;
      m_msg_len_valid_o    <= 1'b0;
      session_o            <= '0;
      seq_o                <= '0;
      count_o              <= '0;
      expected_next_o      <= '0;
      seq_valid_o          <= 1'b0;
      heartbeat_o          <= 1'b0;
      eos_o                <= 1'b0;
      mold_drop_o          <= 1'b0;
      mold_err_o           <= '0;
    end else begin
      seq_valid_o <= 1'b0;
      heartbeat_o <= 1'b0;
      eos_o       <= 1'b0;
      mold_drop_o <= 1'b0;
      mold_err_o  <= '0;

      if (m_payload_tvalid_o && m_payload_tready_i) begin
        m_payload_tvalid_o <= 1'b0;
        m_payload_tlast_o  <= 1'b0;
      end

      if (m_msg_len_valid_o && m_msg_len_ready_i) begin
        m_msg_len_valid_o <= 1'b0;
        if (msg_len_shift == '0) begin
          if (messages_left <= 16'd1) begin
            state         <= ST_DRAIN;
            messages_left <= '0;
          end else begin
            messages_left <= messages_left - 16'd1;
            state         <= ST_MSG_LEN_HI;
          end
        end else begin
          payload_left <= msg_len_shift;
          state        <= ST_PAYLOAD;
        end
      end else if (!m_payload_tvalid_o && !m_msg_len_valid_o) begin
        if (!beat_valid && s_axis_tvalid_i && s_axis_tready_o) begin
          beat_data  <= s_axis_tdata_i;
          beat_keep  <= s_axis_tkeep_i;
          beat_last  <= s_axis_tlast_i;
          beat_valid <= 1'b1;
          beat_lane  <= '0;

          if (!in_dgram) begin
            in_dgram       <= 1'b1;
            dgram_len      <= s_dgram_len_i;
            dgram_byte_idx <= '0;
            state          <= ST_HEADER;
            dropping       <= 1'b0;

            if (!s_dgram_start_i || (s_dgram_len_i < MOLD_HDR_BYTES)) begin
              logic [MOLD_ERR_W-1:0] err_bits;

              err_bits = '0;
              err_bits[MOLD_ERR_SHORT_DGRAM] = 1'b1;
              flag_drop(err_bits);
            end
          end

          if (tkeep_bad(s_axis_tkeep_i, s_axis_tlast_i)) begin
            logic [MOLD_ERR_W-1:0] err_bits;

            err_bits = '0;
            err_bits[MOLD_ERR_BAD_TKEEP] = 1'b1;
            flag_drop(err_bits);
          end
        end else if (beat_valid) begin
          if (!lane_valid(beat_keep, beat_lane)) begin
            if (beat_last || (beat_lane == AXIS_KEEP_W-1)) begin
              beat_valid <= 1'b0;
              beat_lane  <= '0;

              if (beat_last && in_dgram) begin
                if (!dropping && (dgram_byte_idx != dgram_len)) begin
                  logic [MOLD_ERR_W-1:0] err_bits;

                  err_bits = '0;
                  err_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
                  flag_drop(err_bits);
                end
                reset_datagram_state();
              end
            end else begin
              beat_lane <= beat_lane + 4'd1;
            end
          end else begin
            logic [7:0] b;
            logic       final_lane;
            logic       final_datagram_byte;

            b                   = lane_byte(beat_data, beat_lane);
            final_lane          = beat_last ? ((beat_lane == AXIS_KEEP_W-1) || !lane_valid(beat_keep, beat_lane + 1))
                                            : (beat_lane == AXIS_KEEP_W-1);
            final_datagram_byte = (dgram_byte_idx + 16'd1 == dgram_len);

            if (!dropping && (dgram_byte_idx >= dgram_len)) begin
              logic [MOLD_ERR_W-1:0] err_bits;

              err_bits = '0;
              err_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
              flag_drop(err_bits);
            end else if (!dropping) begin
              unique case (state)
                ST_HEADER: begin
                  if (dgram_byte_idx < MOLD_SESSION_BYTES) begin
                    session_o[MOLD_SESSION_W-1-(8*dgram_byte_idx) -: 8] <= b;
                  end else if (dgram_byte_idx < (MOLD_SESSION_BYTES + MOLD_SEQ_BYTES)) begin
                    seq_o[MOLD_SEQ_W-1-(8*(dgram_byte_idx-MOLD_SESSION_BYTES)) -: 8] <= b;
                  end else if (dgram_byte_idx == 16'd18) begin
                    count_o[15:8] <= b;
                  end else if (dgram_byte_idx == 16'd19) begin
                    logic [MOLD_COUNT_W-1:0] count_v;
                    logic [MOLD_ERR_W-1:0]   err_bits;

                    count_v = {count_o[15:8], b};
                    count_o         <= count_v;
                    expected_next_o <= seq_o + count_v;
                    seq_valid_o     <= 1'b1;

                    if (count_v == MOLD_COUNT_HEARTBEAT) begin
                      heartbeat_o <= 1'b1;
                      state       <= ST_DRAIN;
                      if (dgram_len != MOLD_HDR_BYTES) begin
                        err_bits = '0;
                        err_bits[MOLD_ERR_EOS_PAYLOAD] = 1'b1;
                        flag_drop(err_bits);
                      end
                    end else if (count_v == MOLD_COUNT_EOS) begin
                      eos_o <= 1'b1;
                      state <= ST_DRAIN;
                      if (dgram_len != MOLD_HDR_BYTES) begin
                        err_bits = '0;
                        err_bits[MOLD_ERR_EOS_PAYLOAD] = 1'b1;
                        flag_drop(err_bits);
                      end
                    end else begin
                      messages_left <= count_v;
                      state         <= ST_MSG_LEN_HI;
                    end
                  end
                end

                ST_MSG_LEN_HI: begin
                  msg_len_shift[15:8] <= b;
                  state               <= ST_MSG_LEN_LO;
                end

                ST_MSG_LEN_LO: begin
                  logic [MOLD_MSG_LEN_W-1:0] msg_len_v;
                  logic [DGRAM_LEN_W-1:0]    bytes_after_len;
                  logic [MOLD_ERR_W-1:0]     err_bits;

                  msg_len_v       = {msg_len_shift[15:8], b};
                  bytes_after_len = dgram_len - (dgram_byte_idx + 16'd1);
                  msg_len_shift   <= msg_len_v;
                  m_msg_len_o     <= msg_len_v;

                  if (msg_len_v > bytes_after_len) begin
                    err_bits = '0;
                    err_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
                    flag_drop(err_bits);
                  end else begin
                    m_msg_len_valid_o <= 1'b1;
                    state             <= ST_LEN_WAIT;
                  end
                end

                ST_PAYLOAD: begin
                  logic [3:0] pack_count_v;
                  logic       final_msg_byte;
                  logic       final_payload_byte;

                  payload_pack_data[AXIS_DATA_W-1-(8*payload_pack_count) -: 8] <= b;
                  payload_pack_keep[AXIS_KEEP_W-1-payload_pack_count]          <= 1'b1;

                  pack_count_v       = payload_pack_count + 4'd1;
                  final_msg_byte     = (payload_left == 16'd1);
                  final_payload_byte = final_msg_byte && (messages_left == 16'd1);

                  if ((pack_count_v == AXIS_KEEP_W) || final_payload_byte) begin
                    axis_data_t emit_data;
                    axis_keep_t emit_keep;

                    emit_data = payload_pack_data;
                    emit_keep = payload_pack_keep;
                    emit_data[AXIS_DATA_W-1-(8*payload_pack_count) -: 8] = b;
                    emit_keep[AXIS_KEEP_W-1-payload_pack_count]          = 1'b1;

                    m_payload_tdata_o  <= emit_data;
                    m_payload_tkeep_o  <= emit_keep;
                    m_payload_tvalid_o <= 1'b1;
                    m_payload_tlast_o  <= final_payload_byte;

                    payload_pack_data  <= '0;
                    payload_pack_keep  <= '0;
                    payload_pack_count <= '0;
                  end else begin
                    payload_pack_count <= pack_count_v;
                  end

                  payload_left <= payload_left - 16'd1;

                  if (final_msg_byte) begin
                    if (messages_left <= 16'd1) begin
                      messages_left <= '0;
                      state         <= ST_DRAIN;
                    end else begin
                      messages_left <= messages_left - 16'd1;
                      state         <= ST_MSG_LEN_HI;
                    end
                  end
                end

                ST_LEN_WAIT: begin
                  // Consumed no bytes in this state; transition happens when the
                  // length-stream handshake above accepts m_msg_len_o.
                end

                ST_DRAIN: begin
                  if ((dgram_byte_idx + 16'd1) < dgram_len) begin
                    logic [MOLD_ERR_W-1:0] err_bits;

                    err_bits = '0;
                    err_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
                    flag_drop(err_bits);
                  end
                end

                default: begin
                  state <= ST_DRAIN;
                end
              endcase
            end

            dgram_byte_idx <= dgram_byte_idx + 16'd1;

            if (final_lane) begin
              beat_valid <= 1'b0;
              beat_lane  <= '0;

              if (beat_last) begin
                if (!dropping && ((dgram_byte_idx + 16'd1) != dgram_len)) begin
                  logic [MOLD_ERR_W-1:0] err_bits;

                  err_bits = '0;
                  err_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
                  flag_drop(err_bits);
                end
                reset_datagram_state();
              end
            end else begin
              beat_lane <= beat_lane + 4'd1;
            end
          end
        end
      end
    end
  end

endmodule

`default_nettype wire
