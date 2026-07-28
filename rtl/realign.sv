// Contract:
// - Consumes a continuous byte stream of ITCH payload bytes from mold_deframe.
// - Consumes one msg_len item per ITCH message.
// - Emits one AXIS packet per ITCH message into data_handler.
// - Output has no tkeep because data_handler's current contract does not use it.
// - Output byte order is big-endian: the ITCH message_type byte is in the
//   most-significant output byte lane.
// - Final beat is right-zero-padded and m_axis_tlast_o marks the last beat of
//   that ITCH message.
//
// Implementation:
// - A two-beat byte reservoir replaces the previous one-byte-per-cycle lane
//   walker.
// - Up to AXIS_KEEP_W bytes are accepted and up to AXIS_KEEP_W bytes are emitted
//   each cycle.
// - Input acceptance and output emission may occur in the same cycle, allowing
//   one complete payload beat per cycle when downstream is ready.
// - The reservoir is implemented in LUTs/registers rather than BRAM because the
//   current PYNQ build is BRAM-constrained.

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

  localparam int LEN_FIFO_AW = (LEN_FIFO_DEPTH <= 1)
                             ? 1 : $clog2(LEN_FIFO_DEPTH);

  localparam int RESERVOIR_BYTES   = 2 * AXIS_KEEP_W;
  localparam int RESERVOIR_W       = 8 * RESERVOIR_BYTES;
  localparam int RESERVOIR_COUNT_W = $clog2(RESERVOIR_BYTES + 1);

  logic [MOLD_MSG_LEN_W-1:0] len_fifo [LEN_FIFO_DEPTH];
  logic [LEN_FIFO_AW-1:0]    len_wr_ptr;
  logic [LEN_FIFO_AW-1:0]    len_rd_ptr;
  logic [LEN_FIFO_AW:0]      len_count;

  logic [LEN_FIFO_AW-1:0] len_wr_ptr_next;
  logic [LEN_FIFO_AW-1:0] len_rd_ptr_next;
  logic [LEN_FIFO_AW:0]   len_count_next;
  logic                   len_write_en;

  logic [RESERVOIR_W-1:0]       reservoir_data;
  logic [RESERVOIR_COUNT_W-1:0] reservoir_count;

  logic [RESERVOIR_W-1:0]       reservoir_data_next;
  logic [RESERVOIR_COUNT_W-1:0] reservoir_count_next;

  logic [MOLD_MSG_LEN_W-1:0] msg_bytes_left;
  logic                      have_msg;
  logic                      dgram_end_pending;
  logic                      dropping_payload;

  logic [MOLD_MSG_LEN_W-1:0] msg_bytes_left_next;
  logic                      have_msg_next;
  logic                      dgram_end_pending_next;
  logic                      dropping_payload_next;

  axis_data_t m_axis_tdata_next;
  logic       m_axis_tvalid_next;
  logic       m_axis_tlast_next;

  logic [REALIGN_ERR_W-1:0] realign_err_next;

  logic payload_fire;
  logic output_slot_available;

  function automatic logic lane_valid(
    input axis_keep_t keep,
    input int         lane
  );
    lane_valid = keep[AXIS_KEEP_W-1-lane];
  endfunction

  function automatic logic [7:0] lane_byte(
    input axis_data_t data,
    input int         lane
  );
    lane_byte = data[AXIS_DATA_W-1-(8*lane) -: 8];
  endfunction

  function automatic logic last_keep_is_contiguous(input axis_keep_t keep);
    logic seen_zero;
    int   lane;
    begin
      // Valid bytes are packed from the MSB lane downwards. For the current
      // 32-bit ingress this accepts 1000, 1100, 1110 and 1111.
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

  function automatic int keep_byte_count(input axis_keep_t keep);
    int lane;
    begin
      keep_byte_count = 0;
      for (lane = 0; lane < AXIS_KEEP_W; lane++) begin
        keep_byte_count += keep[AXIS_KEEP_W-1-lane];
      end
    end
  endfunction

  assign output_slot_available = !m_axis_tvalid_o || m_axis_tready_i;

  // A two-beat reservoir allows one complete input beat to be accepted while
  // another beat is waiting to be emitted. In the no-backpressure steady state,
  // the accepted bytes are emitted in the same clock update and the reservoir
  // does not accumulate.
  always_comb begin
    logic length_context_available;

    // Do not accept a token from the next datagram until every byte from the
    // current datagram has left the reservoir. This keeps length tokens and
    // payload bytes on the same datagram boundary.
    s_msg_len_ready_o = rst_n
                     && !dgram_end_pending
                     && (dropping_payload
                         || (len_count < LEN_FIFO_DEPTH));

    length_context_available = have_msg
                            || (len_count != '0)
                            || (s_msg_len_valid_i
                                && (s_msg_len_i != '0)
                                && s_msg_len_ready_o);

    s_payload_tready_o = rst_n
                      && !dgram_end_pending
                      && (dropping_payload
                          || ((reservoir_count <= AXIS_KEEP_W)
                              && length_context_available));
  end

  assign payload_fire = s_payload_tvalid_i && s_payload_tready_o;

  always_comb begin : next_state_logic
    logic do_len_push;
    logic do_len_pop;
    logic flush_context;
    logic payload_bad;

    logic [RESERVOIR_W-1:0]       reservoir_work;
    logic [RESERVOIR_COUNT_W-1:0] reservoir_count_work;
    logic [MOLD_MSG_LEN_W-1:0]    msg_bytes_left_work;
    logic                         have_msg_work;
    logic                         dgram_end_pending_work;
    logic                         dropping_payload_work;

    logic [LEN_FIFO_AW:0] len_count_work;

    axis_data_t emit_data;

    int input_bytes;
    int append_index;
    int destination_byte;
    int emit_bytes;
    int required_bytes;
    int lane;

    len_wr_ptr_next         = len_wr_ptr;
    len_rd_ptr_next         = len_rd_ptr;
    len_count_next          = len_count;
    len_write_en            = 1'b0;

    reservoir_data_next     = reservoir_data;
    reservoir_count_next    = reservoir_count;
    msg_bytes_left_next     = msg_bytes_left;
    have_msg_next           = have_msg;
    dgram_end_pending_next  = dgram_end_pending;
    dropping_payload_next   = dropping_payload;

    m_axis_tdata_next       = m_axis_tdata_o;
    m_axis_tvalid_next      = m_axis_tvalid_o;
    m_axis_tlast_next       = m_axis_tlast_o;

    realign_err_next        = '0;

    do_len_push             = 1'b0;
    do_len_pop              = 1'b0;
    flush_context           = 1'b0;
    payload_bad             = 1'b0;

    reservoir_work          = reservoir_data;
    reservoir_count_work    = reservoir_count;
    msg_bytes_left_work     = msg_bytes_left;
    have_msg_work           = have_msg;
    dgram_end_pending_work  = dgram_end_pending;
    dropping_payload_work   = dropping_payload;

    len_count_work          = len_count;

    emit_data               = '0;

    input_bytes             = 0;
    append_index            = 0;
    destination_byte        = 0;
    emit_bytes              = 0;
    required_bytes          = 0;

    // Retire the current output beat. A replacement beat may be loaded below in
    // the same cycle, maintaining one output beat per cycle.
    if (m_axis_tvalid_o && m_axis_tready_i) begin
      m_axis_tvalid_next = 1'b0;
      m_axis_tlast_next  = 1'b0;
    end

    // Length tokens are independent of the payload stream. During error drain
    // they are accepted and discarded so mold_deframe cannot deadlock while the
    // remainder of a malformed datagram is being consumed.
    if (s_msg_len_valid_i && s_msg_len_ready_o) begin
      if (s_msg_len_i == '0) begin
        realign_err_next[REALIGN_ERR_LEN_ZERO] = 1'b1;
      end else if (!dropping_payload) begin
        do_len_push  = 1'b1;
        len_write_en = 1'b1;
      end
    end

    // Prefetch the next message length. The FIFO head may be used immediately
    // by the reservoir logic in this same cycle, avoiding a message-start bubble.
    if (!dropping_payload_work && !have_msg_work && (len_count_work != '0)) begin
      msg_bytes_left_work = len_fifo[len_rd_ptr];
      have_msg_work       = 1'b1;
      do_len_pop          = 1'b1;
    end

    // Update the logical FIFO state before checking datagram completion. The
    // physical memory write is performed in the sequential block.
    if (do_len_push) begin
      if (len_wr_ptr == LEN_FIFO_DEPTH-1) begin
        len_wr_ptr_next = '0;
      end else begin
        len_wr_ptr_next = len_wr_ptr + {{(LEN_FIFO_AW-1){1'b0}}, 1'b1};
      end
    end

    if (do_len_pop) begin
      if (len_rd_ptr == LEN_FIFO_DEPTH-1) begin
        len_rd_ptr_next = '0;
      end else begin
        len_rd_ptr_next = len_rd_ptr + {{(LEN_FIFO_AW-1){1'b0}}, 1'b1};
      end
    end

    case ({do_len_push, do_len_pop})
      2'b10: len_count_work = len_count + {{LEN_FIFO_AW{1'b0}}, 1'b1};
      2'b01: len_count_work = len_count - {{LEN_FIFO_AW{1'b0}}, 1'b1};
      default: len_count_work = len_count;
    endcase

    // Accept or drain one complete payload beat.
    if (payload_fire) begin
      if (dropping_payload_work) begin
        if (s_payload_tlast_i) begin
          dropping_payload_work  = 1'b0;
          dgram_end_pending_work = 1'b0;
        end
      end else if (tkeep_bad(s_payload_tkeep_i, s_payload_tlast_i)) begin
        realign_err_next[REALIGN_ERR_BAD_TKEEP] = 1'b1;
        payload_bad = 1'b1;
        flush_context = 1'b1;
        dropping_payload_work = !s_payload_tlast_i;
      end else begin
        input_bytes = keep_byte_count(s_payload_tkeep_i);

        for (lane = 0; lane < AXIS_KEEP_W; lane++) begin
          if (lane_valid(s_payload_tkeep_i, lane)) begin
            destination_byte = reservoir_count_work + append_index;
            reservoir_work[
              RESERVOIR_W-1-(8*destination_byte) -: 8
            ] = lane_byte(s_payload_tdata_i, lane);
            append_index++;
          end
        end

        reservoir_count_work = reservoir_count_work + input_bytes;

        if (s_payload_tlast_i) begin
          dgram_end_pending_work = 1'b1;
        end
      end
    end

    // Emit up to one complete AXIS beat. A short final message beat is padded
    // with zeros on the right; any following message bytes remain in the
    // reservoir and are emitted on the next cycle.
    if (!payload_bad
        && !dropping_payload_work
        && output_slot_available
        && have_msg_work) begin
      if (msg_bytes_left_work > AXIS_KEEP_W) begin
        emit_bytes = AXIS_KEEP_W;
      end else begin
        emit_bytes = msg_bytes_left_work;
      end

      if (reservoir_count_work >= emit_bytes) begin
        emit_data = '0;

        for (lane = 0; lane < AXIS_KEEP_W; lane++) begin
          if (lane < emit_bytes) begin
            emit_data[AXIS_DATA_W-1-(8*lane) -: 8]
              = reservoir_work[RESERVOIR_W-1-(8*lane) -: 8];
          end
        end

        m_axis_tdata_next  = emit_data;
        m_axis_tvalid_next = 1'b1;
        m_axis_tlast_next  = (msg_bytes_left_work <= AXIS_KEEP_W);

        reservoir_work       = reservoir_work << (8 * emit_bytes);
        reservoir_count_work = reservoir_count_work - emit_bytes;

        if (msg_bytes_left_work <= AXIS_KEEP_W) begin
          msg_bytes_left_work = '0;
          have_msg_work       = 1'b0;
        end else begin
          msg_bytes_left_work = msg_bytes_left_work - emit_bytes;
        end
      end
    end

    // A payload byte without a corresponding message length violates the
    // mold_deframe/realign contract. Drop the rest of that datagram so the next
    // datagram starts from a clean byte and length boundary.
    if (!payload_bad
        && !dropping_payload_work
        && !have_msg_work
        && (len_count_work == '0)
        && (reservoir_count_work != '0)) begin
      realign_err_next[REALIGN_ERR_PAYLOAD_OVERFLOW] = 1'b1;
      flush_context = 1'b1;
      dropping_payload_work = !dgram_end_pending_work;
    end

    // Once tlast has been accepted, no additional bytes can arrive for the
    // current datagram. Detect a partial message as soon as the reservoir no
    // longer contains enough bytes to form its next output beat.
    if (!payload_bad
        && !flush_context
        && !dropping_payload_work
        && dgram_end_pending_work) begin
      if (have_msg_work) begin
        if (msg_bytes_left_work > AXIS_KEEP_W) begin
          required_bytes = AXIS_KEEP_W;
        end else begin
          required_bytes = msg_bytes_left_work;
        end

        if (reservoir_count_work < required_bytes) begin
          realign_err_next[REALIGN_ERR_PAYLOAD_UNDERFLOW] = 1'b1;
          flush_context = 1'b1;
        end
      end else if (len_count_work != '0) begin
        if (reservoir_count_work == '0) begin
          realign_err_next[REALIGN_ERR_PAYLOAD_UNDERFLOW] = 1'b1;
          flush_context = 1'b1;
        end
      end else if (reservoir_count_work == '0) begin
        dgram_end_pending_work = 1'b0;
      end
    end

    if (flush_context) begin
      reservoir_work          = '0;
      reservoir_count_work    = '0;
      msg_bytes_left_work     = '0;
      have_msg_work           = 1'b0;
      dgram_end_pending_work  = 1'b0;

      len_wr_ptr_next         = '0;
      len_rd_ptr_next         = '0;
      len_count_work          = '0;
      len_write_en            = 1'b0;
    end

    len_count_next          = len_count_work;

    reservoir_data_next     = reservoir_work;
    reservoir_count_next    = reservoir_count_work;
    msg_bytes_left_next     = msg_bytes_left_work;
    have_msg_next           = have_msg_work;
    dgram_end_pending_next  = dgram_end_pending_work;
    dropping_payload_next   = dropping_payload_work;
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      len_wr_ptr         <= '0;
      len_rd_ptr         <= '0;
      len_count          <= '0;

      reservoir_data     <= '0;
      reservoir_count    <= '0;

      msg_bytes_left     <= '0;
      have_msg           <= 1'b0;
      dgram_end_pending  <= 1'b0;
      dropping_payload   <= 1'b0;

      m_axis_tdata_o     <= '0;
      m_axis_tvalid_o    <= 1'b0;
      m_axis_tlast_o     <= 1'b0;

      realign_err_o      <= '0;
    end else begin
      if (len_write_en) begin
        len_fifo[len_wr_ptr] <= s_msg_len_i;
      end

      len_wr_ptr         <= len_wr_ptr_next;
      len_rd_ptr         <= len_rd_ptr_next;
      len_count          <= len_count_next;

      reservoir_data     <= reservoir_data_next;
      reservoir_count    <= reservoir_count_next;

      msg_bytes_left     <= msg_bytes_left_next;
      have_msg           <= have_msg_next;
      dgram_end_pending  <= dgram_end_pending_next;
      dropping_payload   <= dropping_payload_next;

      m_axis_tdata_o     <= m_axis_tdata_next;
      m_axis_tvalid_o    <= m_axis_tvalid_next;
      m_axis_tlast_o     <= m_axis_tlast_next;

      realign_err_o      <= realign_err_next;
    end
  end

endmodule

`default_nettype wire
