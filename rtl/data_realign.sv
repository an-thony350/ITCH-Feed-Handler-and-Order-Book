// Contract:
// - Consumes the packed 64-bit ITCH payload byte stream from mold_deframe.
// - Consumes one msg_len item per ITCH message.
// - Decodes ITCH fields directly from the packed stream and emits data_t events.
// - Does not recreate one padded AXI packet per message; message boundaries may
//   occur inside a 64-bit payload beat.
// - Unsupported ITCH message types are consumed but do not emit data_t events.
// - Output backpressure is absorbed by one elastic event register.
//
// Throughput architecture:
// - One complete 64-bit payload beat may be accepted every clock.
// - A beat may contain the tail of one ITCH message and the head of the next.
// - The next message length is prefetched from a local FIFO, so crossing a
//   message boundary does not require a padding or realignment cycle.
// - Valid Nasdaq TotalView-ITCH 5.0 messages are longer than one 64-bit beat,
//   therefore at most one message boundary can occur inside one payload beat.
// - If malformed input would require two message boundaries in one beat, the
//   existing REALIGN_ERR_PAYLOAD_OVERFLOW status is asserted and the remainder
//   of that MoldUDP64 datagram is drained.
//
// Timing note:
// - The Ethernet/Mold datapath remains 64-bit at the 156.25 MHz network clock.
// - No wide realignment reservoir or variable-width output shift is required.
// - Payload ready depends on registered parser/output capacity plus the local
//   message-length FIFO. Decode results do not feed back into input ready.
// - Field capture uses fixed ITCH byte positions; there is no generic barrel
//   shifter between mold_deframe and the normalised event output.

`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module data_realign #(
  parameter int LEN_FIFO_DEPTH = 16
) (
  input  wire        clk,
  input  wire        rst_n,

  // Packed ITCH payload stream from mold_deframe. tlast marks the end of the
  // MoldUDP64 datagram, not an individual ITCH message.
  input  wire axis_data_t s_payload_tdata_i,
  input  wire axis_keep_t s_payload_tkeep_i,
  input  wire             s_payload_tvalid_i,
  input  wire             s_payload_tlast_i,
  output logic            s_payload_tready_o,

  // One length token per ITCH message.
  input  wire [MOLD_MSG_LEN_W-1:0] s_msg_len_i,
  input  wire                      s_msg_len_valid_i,
  output logic                     s_msg_len_ready_o,

  // Normalised event stream to the event FIFO / order-book boundary.
  input  wire   ready_i,
  output data_t rdata_o,
  output logic  valid_o,

  // Preserve the existing realign error/status contract so ingress_top can keep
  // the same top-level status wiring when this module is integrated.
  output logic [REALIGN_ERR_W-1:0] realign_err_o
);

  initial begin
    if ((AXIS_DATA_W != 64) || (AXIS_KEEP_W != 8)) begin
      $error("data_realign requires native 64-bit ingress AXIS");
    end
    if (LEN_FIFO_DEPTH < 2) begin
      $error("data_realign LEN_FIFO_DEPTH must be at least two");
    end
  end

  localparam int LEN_FIFO_AW = $clog2(LEN_FIFO_DEPTH);
  localparam int LEN_FIFO_CW = $clog2(LEN_FIFO_DEPTH + 1);

  (* ram_style = "distributed" *)
  logic [MOLD_MSG_LEN_W-1:0] len_fifo [0:LEN_FIFO_DEPTH-1];

  logic [LEN_FIFO_AW-1:0] len_wr_ptr;
  logic [LEN_FIFO_AW-1:0] len_rd_ptr;
  logic [LEN_FIFO_CW-1:0] len_count;

  logic [LEN_FIFO_AW-1:0] len_wr_ptr_next;
  logic [LEN_FIFO_AW-1:0] len_rd_ptr_next;
  logic [LEN_FIFO_CW-1:0] len_count_next;

  logic                      len_write_en;
  logic [LEN_FIFO_AW-1:0]    len_write_ptr;
  logic [MOLD_MSG_LEN_W-1:0] len_write_value;

  // Current ITCH message context.
  logic                      have_msg;
  logic [MOLD_MSG_LEN_W-1:0] msg_bytes_left;
  logic [MOLD_MSG_LEN_W-1:0] msg_byte_pos;
  data_t                     msg_data;

  logic                      have_msg_next;
  logic [MOLD_MSG_LEN_W-1:0] msg_bytes_left_next;
  logic [MOLD_MSG_LEN_W-1:0] msg_byte_pos_next;
  data_t                     msg_data_next;

  // One-entry elastic output buffer, matching the existing data_handler output
  // behaviour. It may be replaced in the same cycle the previous event drains.
  data_t output_data;
  logic  output_valid;

  data_t output_data_next;
  logic  output_valid_next;

  logic dropping_payload;
  logic dropping_payload_next;

  logic [REALIGN_ERR_W-1:0] realign_err_next;

  logic payload_fire;
  logic msg_len_fire;
  logic output_slot_available;

  function automatic logic [LEN_FIFO_AW-1:0] len_ptr_increment(
    input logic [LEN_FIFO_AW-1:0] ptr
  );
    if (ptr == LEN_FIFO_AW'(LEN_FIFO_DEPTH-1)) begin
      len_ptr_increment = '0;
    end else begin
      len_ptr_increment = ptr + LEN_FIFO_AW'(1);
    end
  endfunction

  function automatic logic [7:0] lane_byte(
    input axis_data_t data,
    input int         lane
  );
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

  function automatic logic [3:0] keep_byte_count(input axis_keep_t keep);
    case (keep)
      8'b1000_0000: keep_byte_count = 4'd1;
      8'b1100_0000: keep_byte_count = 4'd2;
      8'b1110_0000: keep_byte_count = 4'd3;
      8'b1111_0000: keep_byte_count = 4'd4;
      8'b1111_1000: keep_byte_count = 4'd5;
      8'b1111_1100: keep_byte_count = 4'd6;
      8'b1111_1110: keep_byte_count = 4'd7;
      8'b1111_1111: keep_byte_count = 4'd8;
      default:       keep_byte_count = 4'd0;
    endcase
  endfunction

  function automatic logic is_supported_msg(input logic [MSG_W-1:0] msg);
    is_supported_msg =
        (msg == MSG_ADD_A)
        || (msg == MSG_ADD_F)
        || (msg == MSG_EXEC)
        || (msg == MSG_EXEC_PX)
        || (msg == MSG_DELETE)
        || (msg == MSG_REPLACE)
        || (msg == MSG_CANCEL);
  endfunction

  // Capture one ITCH payload byte into the normalised event under construction.
  // Only fields required by the existing data_t/order-book contract are stored.
  function automatic data_t capture_itch_byte(
    input data_t                  current,
    input logic [MSG_W-1:0]       msg_type,
    input logic [MOLD_MSG_LEN_W-1:0] byte_pos,
    input logic [7:0]             byte_value
  );
    data_t result;
    begin
      result = current;

      case (byte_pos)
        MOLD_MSG_LEN_W'(0): begin
          result.message_type = byte_value;
        end

        MOLD_MSG_LEN_W'(1): result.stock_locate[15:8] = byte_value;
        MOLD_MSG_LEN_W'(2): result.stock_locate[7:0]  = byte_value;

        MOLD_MSG_LEN_W'(11): result.orn[63:56] = byte_value;
        MOLD_MSG_LEN_W'(12): result.orn[55:48] = byte_value;
        MOLD_MSG_LEN_W'(13): result.orn[47:40] = byte_value;
        MOLD_MSG_LEN_W'(14): result.orn[39:32] = byte_value;
        MOLD_MSG_LEN_W'(15): result.orn[31:24] = byte_value;
        MOLD_MSG_LEN_W'(16): result.orn[23:16] = byte_value;
        MOLD_MSG_LEN_W'(17): result.orn[15:8]  = byte_value;
        MOLD_MSG_LEN_W'(18): result.orn[7:0]   = byte_value;

        MOLD_MSG_LEN_W'(19): begin
          if ((msg_type == MSG_ADD_A) || (msg_type == MSG_ADD_F)) begin
            result.side = (byte_value == 8'h42); // "B" = buy
          end else if (msg_type == MSG_REPLACE) begin
            result.updated_orn[63:56] = byte_value;
          end else if ((msg_type == MSG_EXEC)
                       || (msg_type == MSG_EXEC_PX)
                       || (msg_type == MSG_CANCEL)) begin
            result.shares[31:24] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(20): begin
          if ((msg_type == MSG_ADD_A) || (msg_type == MSG_ADD_F)) begin
            result.shares[31:24] = byte_value;
          end else if (msg_type == MSG_REPLACE) begin
            result.updated_orn[55:48] = byte_value;
          end else if ((msg_type == MSG_EXEC)
                       || (msg_type == MSG_EXEC_PX)
                       || (msg_type == MSG_CANCEL)) begin
            result.shares[23:16] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(21): begin
          if ((msg_type == MSG_ADD_A) || (msg_type == MSG_ADD_F)) begin
            result.shares[23:16] = byte_value;
          end else if (msg_type == MSG_REPLACE) begin
            result.updated_orn[47:40] = byte_value;
          end else if ((msg_type == MSG_EXEC)
                       || (msg_type == MSG_EXEC_PX)
                       || (msg_type == MSG_CANCEL)) begin
            result.shares[15:8] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(22): begin
          if ((msg_type == MSG_ADD_A) || (msg_type == MSG_ADD_F)) begin
            result.shares[15:8] = byte_value;
          end else if (msg_type == MSG_REPLACE) begin
            result.updated_orn[39:32] = byte_value;
          end else if ((msg_type == MSG_EXEC)
                       || (msg_type == MSG_EXEC_PX)
                       || (msg_type == MSG_CANCEL)) begin
            result.shares[7:0] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(23): begin
          if ((msg_type == MSG_ADD_A) || (msg_type == MSG_ADD_F)) begin
            result.shares[7:0] = byte_value;
          end else if (msg_type == MSG_REPLACE) begin
            result.updated_orn[31:24] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(24): begin
          if (msg_type == MSG_REPLACE) begin
            result.updated_orn[23:16] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(25): begin
          if (msg_type == MSG_REPLACE) begin
            result.updated_orn[15:8] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(26): begin
          if (msg_type == MSG_REPLACE) begin
            result.updated_orn[7:0] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(27): begin
          if (msg_type == MSG_REPLACE) begin
            result.shares[31:24] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(28): begin
          if (msg_type == MSG_REPLACE) begin
            result.shares[23:16] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(29): begin
          if (msg_type == MSG_REPLACE) begin
            result.shares[15:8] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(30): begin
          if (msg_type == MSG_REPLACE) begin
            result.shares[7:0] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(31): begin
          if (msg_type == MSG_REPLACE) begin
            result.price[31:24] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(32): begin
          if ((msg_type == MSG_ADD_A)
              || (msg_type == MSG_ADD_F)
              || (msg_type == MSG_EXEC_PX)) begin
            result.price[31:24] = byte_value;
          end else if (msg_type == MSG_REPLACE) begin
            result.price[23:16] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(33): begin
          if ((msg_type == MSG_ADD_A)
              || (msg_type == MSG_ADD_F)
              || (msg_type == MSG_EXEC_PX)) begin
            result.price[23:16] = byte_value;
          end else if (msg_type == MSG_REPLACE) begin
            result.price[15:8] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(34): begin
          if ((msg_type == MSG_ADD_A)
              || (msg_type == MSG_ADD_F)
              || (msg_type == MSG_EXEC_PX)) begin
            result.price[15:8] = byte_value;
          end else if (msg_type == MSG_REPLACE) begin
            result.price[7:0] = byte_value;
          end
        end

        MOLD_MSG_LEN_W'(35): begin
          if ((msg_type == MSG_ADD_A)
              || (msg_type == MSG_ADD_F)
              || (msg_type == MSG_EXEC_PX)) begin
            result.price[7:0] = byte_value;
          end
        end

        default: begin
          // Tracking number, timestamp, stock symbol, match number, printable,
          // MPID attribution, and unsupported-message fields are not required
          // by the current normalised event/order-book contract.
        end
      endcase

      capture_itch_byte = result;
    end
  endfunction

  assign output_slot_available = !output_valid || ready_i;

  // Length tokens are intentionally decoupled from the payload ready path. A
  // conservative full check ignores a same-cycle pop so downstream ready does
  // not create a long combinational path back into mold_deframe.
  always_comb begin
    s_msg_len_ready_o = rst_n
                     && (dropping_payload
                         || (len_count < LEN_FIFO_CW'(LEN_FIFO_DEPTH)));

    s_payload_tready_o = 1'b0;

    if (rst_n) begin
      if (dropping_payload) begin
        s_payload_tready_o = 1'b1;
      end else if (have_msg && output_slot_available) begin
        s_payload_tready_o = 1'b1;

        // If the current beat crosses a message boundary, the next length must
        // already be buffered. This keeps s_msg_len_valid_i out of the payload
        // ready critical path. mold_deframe normally releases length credit
        // before the corresponding payload bytes.
        if (s_payload_tvalid_i
            && !tkeep_bad(s_payload_tkeep_i, s_payload_tlast_i)
            && (msg_bytes_left
                < MOLD_MSG_LEN_W'(keep_byte_count(s_payload_tkeep_i)))
            && (len_count == '0)) begin
          s_payload_tready_o = 1'b0;
        end
      end
    end
  end

  assign payload_fire = s_payload_tvalid_i && s_payload_tready_o;
  assign msg_len_fire = s_msg_len_valid_i && s_msg_len_ready_o;

  always_comb begin : next_state_logic
    logic [LEN_FIFO_AW-1:0] len_wr_ptr_work;
    logic [LEN_FIFO_AW-1:0] len_rd_ptr_work;
    logic [LEN_FIFO_CW-1:0] len_count_work;

    logic                      have_msg_work;
    logic [MOLD_MSG_LEN_W-1:0] msg_bytes_left_work;
    logic [MOLD_MSG_LEN_W-1:0] msg_byte_pos_work;
    data_t                     msg_data_work;

    data_t current_data_work;
    data_t next_data_work;

    logic [MSG_W-1:0] current_msg_type;
    logic [MSG_W-1:0] next_msg_type;

    logic [3:0] input_bytes;
    logic [3:0] current_take;
    logic [3:0] next_take;

    logic [MOLD_MSG_LEN_W-1:0] next_msg_len;
    logic [MOLD_MSG_LEN_W-1:0] current_pos;
    logic [MOLD_MSG_LEN_W-1:0] next_pos;

    logic current_completed;
    logic parser_fault;
    logic parser_fault_drop_until_last;

    int lane;

    len_wr_ptr_next       = len_wr_ptr;
    len_rd_ptr_next       = len_rd_ptr;
    len_count_next        = len_count;
    len_write_en          = 1'b0;
    len_write_ptr         = len_wr_ptr;
    len_write_value       = '0;

    have_msg_next         = have_msg;
    msg_bytes_left_next   = msg_bytes_left;
    msg_byte_pos_next     = msg_byte_pos;
    msg_data_next         = msg_data;

    output_data_next      = output_data;
    output_valid_next     = output_valid;

    dropping_payload_next = dropping_payload;
    realign_err_next      = '0;

    len_wr_ptr_work       = len_wr_ptr;
    len_rd_ptr_work       = len_rd_ptr;
    len_count_work        = len_count;

    have_msg_work         = have_msg;
    msg_bytes_left_work   = msg_bytes_left;
    msg_byte_pos_work     = msg_byte_pos;
    msg_data_work         = msg_data;

    current_data_work     = msg_data;
    next_data_work        = '0;

    current_msg_type      = msg_data.message_type;
    next_msg_type         = '0;

    input_bytes           = '0;
    current_take          = '0;
    next_take             = '0;

    next_msg_len          = '0;
    current_pos           = msg_byte_pos;
    next_pos              = '0;

    current_completed     = 1'b0;
    parser_fault          = 1'b0;
    parser_fault_drop_until_last = 1'b0;

    // The current event may drain while a new completed message replaces it.
    if (output_valid && ready_i) begin
      output_valid_next = 1'b0;
    end

    if (dropping_payload) begin
      // Lengths discovered while draining a malformed datagram are discarded.
      if (payload_fire && s_payload_tlast_i) begin
        dropping_payload_next = 1'b0;

        len_wr_ptr_work       = '0;
        len_rd_ptr_work       = '0;
        len_count_work        = '0;

        have_msg_work         = 1'b0;
        msg_bytes_left_work   = '0;
        msg_byte_pos_work     = '0;
        msg_data_work         = '0;
      end
    end else begin
      // Decode one packed 64-bit payload beat. At most one valid ITCH boundary
      // may occur inside a beat.
      if (payload_fire) begin
        if (tkeep_bad(s_payload_tkeep_i, s_payload_tlast_i)) begin
          realign_err_next[REALIGN_ERR_BAD_TKEEP] = 1'b1;
          parser_fault = 1'b1;
          parser_fault_drop_until_last = !s_payload_tlast_i;
        end else if (!have_msg_work) begin
          // This should be prevented by s_payload_tready_o and indicates a
          // broken mold_deframe/data_realign contract.
          realign_err_next[REALIGN_ERR_PAYLOAD_OVERFLOW] = 1'b1;
          parser_fault = 1'b1;
          parser_fault_drop_until_last = !s_payload_tlast_i;
        end else begin
          input_bytes = keep_byte_count(s_payload_tkeep_i);

          if (msg_bytes_left_work
              < MOLD_MSG_LEN_W'(input_bytes)) begin
            current_take = msg_bytes_left_work[3:0];
          end else begin
            current_take = input_bytes;
          end

          // The message type is byte zero. If this is the first beat of the
          // message, use the incoming byte immediately so later byte lanes in
          // the same beat can be decoded without an extra cycle.
          if ((msg_byte_pos_work == '0) && (current_take != '0)) begin
            current_msg_type = lane_byte(s_payload_tdata_i, 0);
          end else begin
            current_msg_type = msg_data_work.message_type;
          end

          current_data_work = msg_data_work;
          current_pos       = msg_byte_pos_work;

          for (lane = 0; lane < AXIS_KEEP_W; lane++) begin
            if (lane < current_take) begin
              current_data_work = capture_itch_byte(
                  current_data_work,
                  current_msg_type,
                  current_pos + MOLD_MSG_LEN_W'(lane),
                  lane_byte(s_payload_tdata_i, lane)
              );
            end
          end

          msg_data_work       = current_data_work;
          msg_byte_pos_work   = msg_byte_pos_work
                              + MOLD_MSG_LEN_W'(current_take);
          msg_bytes_left_work = msg_bytes_left_work
                              - MOLD_MSG_LEN_W'(current_take);

          current_completed = (msg_bytes_left_work == '0);

          if (current_completed) begin
            if (is_supported_msg(current_msg_type)) begin
              output_data_next  = current_data_work;
              output_valid_next = 1'b1;
            end

            next_take = input_bytes - current_take;

            // Current message context is complete unless a following message
            // begins in the remaining lanes of this same payload beat.
            have_msg_work       = 1'b0;
            msg_bytes_left_work = '0;
            msg_byte_pos_work   = '0;
            msg_data_work       = '0;

            if (next_take != '0) begin
              if (len_count_work == '0) begin
                // s_payload_tready_o normally prevents this case.
                realign_err_next[REALIGN_ERR_PAYLOAD_OVERFLOW] = 1'b1;
                parser_fault = 1'b1;
                parser_fault_drop_until_last = !s_payload_tlast_i;
              end else begin
                next_msg_len = len_fifo[len_rd_ptr_work];
                len_rd_ptr_work = len_ptr_increment(len_rd_ptr_work);
                len_count_work  = len_count_work - LEN_FIFO_CW'(1);

                if (next_msg_len == '0) begin
                  realign_err_next[REALIGN_ERR_LEN_ZERO] = 1'b1;
                  parser_fault = 1'b1;
                  parser_fault_drop_until_last = !s_payload_tlast_i;
                end else if (next_msg_len <= MOLD_MSG_LEN_W'(next_take)) begin
                  // A second complete message boundary in one 64-bit beat is
                  // outside the valid ITCH 5.0 traffic model and would require
                  // emitting/starting more than one additional message context.
                  realign_err_next[REALIGN_ERR_PAYLOAD_OVERFLOW] = 1'b1;
                  parser_fault = 1'b1;
                  parser_fault_drop_until_last = !s_payload_tlast_i;
                end else begin
                  next_msg_type  = lane_byte(s_payload_tdata_i, int'(current_take));
                  next_data_work = '0;
                  next_pos       = '0;

                  for (lane = 0; lane < AXIS_KEEP_W; lane++) begin
                    if ((lane >= current_take) && (lane < input_bytes)) begin
                      next_data_work = capture_itch_byte(
                          next_data_work,
                          next_msg_type,
                          next_pos,
                          lane_byte(s_payload_tdata_i, lane)
                      );
                      next_pos = next_pos + MOLD_MSG_LEN_W'(1);
                    end
                  end

                  msg_data_work       = next_data_work;
                  msg_byte_pos_work   = MOLD_MSG_LEN_W'(next_take);
                  msg_bytes_left_work = next_msg_len
                                      - MOLD_MSG_LEN_W'(next_take);
                  have_msg_work       = 1'b1;

                end
              end
            end
          end

          // tlast is end-of-datagram. At this point every payload byte has been
          // consumed in this cycle, so any remaining current/queued length means
          // the datagram ended before all declared ITCH messages were complete.
          if (!parser_fault && s_payload_tlast_i) begin
            if (have_msg_work || (len_count_work != '0)) begin
              realign_err_next[REALIGN_ERR_PAYLOAD_UNDERFLOW] = 1'b1;
              parser_fault = 1'b1;
              parser_fault_drop_until_last = 1'b0;
            end
          end
        end
      end

      if (parser_fault) begin
        len_wr_ptr_work       = '0;
        len_rd_ptr_work       = '0;
        len_count_work        = '0;

        have_msg_work         = 1'b0;
        msg_bytes_left_work   = '0;
        msg_byte_pos_work     = '0;
        msg_data_work         = '0;

        dropping_payload_next = parser_fault_drop_until_last;
      end else begin
        // When the previous message ended exactly on a beat boundary, prefetch
        // the next already-buffered length immediately. This prevents a bubble
        // before the next payload beat.
        if (!have_msg_work && (len_count_work != '0)) begin
          next_msg_len = len_fifo[len_rd_ptr_work];
          len_rd_ptr_work = len_ptr_increment(len_rd_ptr_work);
          len_count_work  = len_count_work - LEN_FIFO_CW'(1);

          if (next_msg_len == '0) begin
            realign_err_next[REALIGN_ERR_LEN_ZERO] = 1'b1;

            len_wr_ptr_work       = '0;
            len_rd_ptr_work       = '0;
            len_count_work        = '0;

            have_msg_work         = 1'b0;
            msg_bytes_left_work   = '0;
            msg_byte_pos_work     = '0;
            msg_data_work         = '0;

            dropping_payload_next = 1'b1;
          end else begin
            have_msg_work         = 1'b1;
            msg_bytes_left_work   = next_msg_len;
            msg_byte_pos_work     = '0;
            msg_data_work         = '0;
          end
        end

        // Accept one new length token after this cycle's parser/prefetch work.
        // If no message is active and the FIFO is empty, load it directly into
        // the current context rather than adding an extra FIFO/prefetch cycle.
        if (msg_len_fire) begin
          if (s_msg_len_i == '0) begin
            realign_err_next[REALIGN_ERR_LEN_ZERO] = 1'b1;

            len_wr_ptr_work       = '0;
            len_rd_ptr_work       = '0;
            len_count_work        = '0;

            have_msg_work         = 1'b0;
            msg_bytes_left_work   = '0;
            msg_byte_pos_work     = '0;
            msg_data_work         = '0;

            dropping_payload_next = 1'b1;
          end else if (!have_msg_work && (len_count_work == '0)) begin
            have_msg_work         = 1'b1;
            msg_bytes_left_work   = s_msg_len_i;
            msg_byte_pos_work     = '0;
            msg_data_work         = '0;
          end else begin
            len_write_en    = 1'b1;
            len_write_ptr   = len_wr_ptr_work;
            len_write_value = s_msg_len_i;

            len_wr_ptr_work = len_ptr_increment(len_wr_ptr_work);
            len_count_work  = len_count_work + LEN_FIFO_CW'(1);
          end
        end
      end
    end

    len_wr_ptr_next       = len_wr_ptr_work;
    len_rd_ptr_next       = len_rd_ptr_work;
    len_count_next        = len_count_work;

    have_msg_next         = have_msg_work;
    msg_bytes_left_next   = msg_bytes_left_work;
    msg_byte_pos_next     = msg_byte_pos_work;
    msg_data_next         = msg_data_work;
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      len_wr_ptr        <= '0;
      len_rd_ptr        <= '0;
      len_count         <= '0;

      have_msg          <= 1'b0;
      msg_bytes_left    <= '0;
      msg_byte_pos      <= '0;
      msg_data          <= '0;

      output_data       <= '0;
      output_valid      <= 1'b0;

      dropping_payload  <= 1'b0;
      realign_err_o     <= '0;
    end else begin
      if (len_write_en) begin
        len_fifo[len_write_ptr] <= len_write_value;
      end

      len_wr_ptr        <= len_wr_ptr_next;
      len_rd_ptr        <= len_rd_ptr_next;
      len_count         <= len_count_next;

      have_msg          <= have_msg_next;
      msg_bytes_left    <= msg_bytes_left_next;
      msg_byte_pos      <= msg_byte_pos_next;
      msg_data          <= msg_data_next;

      output_data       <= output_data_next;
      output_valid      <= output_valid_next;

      dropping_payload  <= dropping_payload_next;
      realign_err_o     <= realign_err_next;
    end
  end

  assign rdata_o = output_data;
  assign valid_o = output_valid;

endmodule

`default_nettype wire
