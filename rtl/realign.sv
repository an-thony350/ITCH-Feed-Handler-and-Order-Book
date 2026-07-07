// Contract:
// - Consumes a continuous byte stream of ITCH payload bytes from mold_deframe.
// - Consumes one msg_len item per ITCH message.
// - Emits one AXIS packet per ITCH message into data_handler.
// - Output has no tkeep because data_handler's current contract does not use it.
// - Output byte order is big-endian: the ITCH message_type byte is in [63:56].
// - Final beat is right-zero-padded and m_axis_tlast_o marks the last beat of
//   that ITCH message.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module realign #(
  parameter int LEN_FIFO_DEPTH = 16
) (
  input  wire        clk,
  input  wire        rst_n,

  // AXIS ITCH payload byte stream from mold_deframe. This stream may contain
  // several messages per beat or messages straddling several beats.
  input  wire axis_data_t s_payload_tdata_i,
  input  wire axis_keep_t s_payload_tkeep_i,
  input  wire        s_payload_tvalid_i,
  input  wire        s_payload_tlast_i,   // end of datagram, not message
  output logic       s_payload_tready_o,

  // Per-message length stream from mold_deframe.
  input  wire [MOLD_MSG_LEN_W-1:0] s_msg_len_i,
  input  wire                       s_msg_len_valid_i,
  output logic                      s_msg_len_ready_o,

  // AXIS output to existing data_handler.s_tdata_i/s_tvalid_i/s_tlast_i.
  output axis_data_t m_axis_tdata_o,
  output logic       m_axis_tvalid_o,
  output logic       m_axis_tlast_o,
  input  wire        m_axis_tready_i,

  // Error/status. Bits pulse for one cycle when an error is detected.
  output logic [REALIGN_ERR_W-1:0] realign_err_o
);

  localparam int LEN_FIFO_AW = (LEN_FIFO_DEPTH <= 2)  ? 1 :
                               (LEN_FIFO_DEPTH <= 4)  ? 2 :
                               (LEN_FIFO_DEPTH <= 8)  ? 3 :
                               (LEN_FIFO_DEPTH <= 16) ? 4 :
                               (LEN_FIFO_DEPTH <= 32) ? 5 : 6;

  logic [MOLD_MSG_LEN_W-1:0] len_fifo [LEN_FIFO_DEPTH];
  logic [LEN_FIFO_AW-1:0]    len_wr_ptr;
  logic [LEN_FIFO_AW-1:0]    len_rd_ptr;
  logic [LEN_FIFO_AW:0]      len_count;

  localparam int LEN_FIFO_DEPTH_COUNT = LEN_FIFO_DEPTH;

  axis_data_t beat_data;
  axis_keep_t beat_keep;
  logic       beat_last;
  logic       beat_valid;
  logic [3:0] beat_lane;

  logic [MOLD_MSG_LEN_W-1:0] msg_bytes_left;
  logic                      have_msg;
  logic                      dropping_payload;

  axis_data_t pack_data;
  logic [3:0] pack_count;

  assign s_msg_len_ready_o = rst_n && (len_count < LEN_FIFO_DEPTH_COUNT);

  assign s_payload_tready_o = rst_n &&
                              !beat_valid &&
                              !m_axis_tvalid_o &&
                              (dropping_payload || have_msg || (len_count != '0));

  function automatic logic lane_valid(input axis_keep_t keep, input int lane);
    lane_valid = keep[AXIS_KEEP_W-1-lane];
  endfunction

  function automatic logic [7:0] lane_byte(input axis_data_t data, input int lane);
    lane_byte = data[AXIS_DATA_W-1-(8*lane) -: 8];
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

  function automatic logic last_valid_lane(input axis_keep_t keep, input logic last, input int lane);
    if (!last) begin
      last_valid_lane = (lane == AXIS_KEEP_W-1);
    end else if (lane == AXIS_KEEP_W-1) begin
      last_valid_lane = lane_valid(keep, lane);
    end else begin
      last_valid_lane = lane_valid(keep, lane) && !lane_valid(keep, lane + 1);
    end
  endfunction

  task automatic pulse_error(input int err_bit);
    realign_err_o          <= '0;
    realign_err_o[err_bit] <= 1'b1;
  endtask

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      len_wr_ptr       <= '0;
      len_rd_ptr       <= '0;
      len_count        <= '0;
      beat_data        <= '0;
      beat_keep        <= '0;
      beat_last        <= 1'b0;
      beat_valid       <= 1'b0;
      beat_lane        <= '0;
      msg_bytes_left   <= '0;
      have_msg         <= 1'b0;
      dropping_payload <= 1'b0;
      pack_data        <= '0;
      pack_count       <= '0;
      m_axis_tdata_o   <= '0;
      m_axis_tvalid_o  <= 1'b0;
      m_axis_tlast_o   <= 1'b0;
      realign_err_o    <= '0;
    end else begin
      logic do_len_push;
      logic do_len_pop;

      do_len_push = s_msg_len_valid_i && s_msg_len_ready_o && (s_msg_len_i != '0);
      do_len_pop  = !have_msg && (len_count != '0) && !m_axis_tvalid_o;

      realign_err_o <= '0;

      if (s_msg_len_valid_i && s_msg_len_ready_o && (s_msg_len_i == '0)) begin
        pulse_error(REALIGN_ERR_LEN_ZERO);
      end

      if (m_axis_tvalid_o && m_axis_tready_i) begin
        m_axis_tvalid_o <= 1'b0;
        m_axis_tlast_o  <= 1'b0;
      end

      if (do_len_push) begin
        len_fifo[len_wr_ptr] <= s_msg_len_i;
        if (len_wr_ptr == LEN_FIFO_DEPTH-1) begin
          len_wr_ptr <= '0;
        end else begin
          len_wr_ptr <= len_wr_ptr + {{(LEN_FIFO_AW-1){1'b0}}, 1'b1};
        end
      end

      if (do_len_pop) begin
        msg_bytes_left <= len_fifo[len_rd_ptr];
        have_msg       <= 1'b1;
        if (len_rd_ptr == LEN_FIFO_DEPTH-1) begin
          len_rd_ptr <= '0;
        end else begin
          len_rd_ptr <= len_rd_ptr + {{(LEN_FIFO_AW-1){1'b0}}, 1'b1};
        end
      end

      case ({do_len_push, do_len_pop})
        2'b10: len_count <= len_count + {{LEN_FIFO_AW{1'b0}}, 1'b1};
        2'b01: len_count <= len_count - {{LEN_FIFO_AW{1'b0}}, 1'b1};
        default: len_count <= len_count;
      endcase

      if (!beat_valid && s_payload_tvalid_i && s_payload_tready_o) begin
        if (tkeep_bad(s_payload_tkeep_i, s_payload_tlast_i)) begin
          pulse_error(REALIGN_ERR_BAD_TKEEP);
          dropping_payload <= !s_payload_tlast_i;
        end else begin
          beat_data  <= s_payload_tdata_i;
          beat_keep  <= s_payload_tkeep_i;
          beat_last  <= s_payload_tlast_i;
          beat_valid <= 1'b1;
          beat_lane  <= '0;
        end
      end else if (beat_valid && !m_axis_tvalid_o && !do_len_pop) begin
        if (!lane_valid(beat_keep, beat_lane)) begin
          if (beat_last || (beat_lane == AXIS_KEEP_W-1)) begin
            beat_valid <= 1'b0;
            beat_lane  <= '0;
          end else begin
            beat_lane <= beat_lane + 4'd1;
          end
        end else if (dropping_payload) begin
          if (beat_last && last_valid_lane(beat_keep, beat_last, beat_lane)) begin
            dropping_payload <= 1'b0;
          end

          if (last_valid_lane(beat_keep, beat_last, beat_lane)) begin
            beat_valid <= 1'b0;
            beat_lane  <= '0;
          end else begin
            beat_lane <= beat_lane + 4'd1;
          end
        end else if (!have_msg) begin
          pulse_error(REALIGN_ERR_PAYLOAD_OVERFLOW);
          pack_data        <= '0;
          pack_count       <= '0;
          dropping_payload <= !beat_last;
          beat_valid       <= 1'b0;
          beat_lane        <= '0;
        end else begin
          logic [7:0]   b;
          axis_data_t   emit_data;
          logic [3:0]   next_pack_count;
          logic         final_msg_byte;
          logic         final_input_byte;
          logic         emit_beat;
          logic         msg_underflow;

          b                = lane_byte(beat_data, beat_lane);
          emit_data        = pack_data;
          emit_data[AXIS_DATA_W-1-(8*pack_count) -: 8] = b;
          next_pack_count  = pack_count + 4'd1;
          final_msg_byte   = (msg_bytes_left == 16'd1);
          final_input_byte = beat_last && last_valid_lane(beat_keep, beat_last, beat_lane);
          emit_beat        = (next_pack_count == AXIS_KEEP_W) || final_msg_byte;
          msg_underflow    = final_input_byte && !final_msg_byte;

          if (emit_beat) begin
            m_axis_tdata_o  <= emit_data;
            m_axis_tvalid_o <= 1'b1;
            m_axis_tlast_o  <= final_msg_byte;
            pack_data       <= '0;
            pack_count      <= '0;
          end else begin
            pack_data  <= emit_data;
            pack_count <= next_pack_count;
          end

          if (final_msg_byte) begin
            have_msg       <= 1'b0;
            msg_bytes_left <= '0;
          end else begin
            msg_bytes_left <= msg_bytes_left - 16'd1;
          end

          if (msg_underflow) begin
            pulse_error(REALIGN_ERR_PAYLOAD_UNDERFLOW);
            have_msg       <= 1'b0;
            msg_bytes_left <= '0;
            pack_data      <= '0;
            pack_count     <= '0;
          end

          if (last_valid_lane(beat_keep, beat_last, beat_lane)) begin
            beat_valid <= 1'b0;
            beat_lane  <= '0;
          end else begin
            beat_lane <= beat_lane + 4'd1;
          end
        end
      end
    end
  end

endmodule

`default_nettype wire
