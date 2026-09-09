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
// - The fixed 20-byte MoldUDP64 header is still decoded across three 64-bit
//   beats. Header beat 2 contributes its first four body bytes to the body FIFO.
// - The body parser consumes up to eight raw body bytes per cycle. It handles
//   at most one new length prefix per cycle, which is sufficient for legal ITCH
//   traffic because even the shortest ITCH message plus its two-byte MoldUDP64
//   prefix is longer than one 64-bit beat.
// - Message-tail / next-prefix / next-payload cases are handled in parallel in
//   one parser cycle instead of falling back to one byte per cycle.
// - Boundary classification and byte compaction are separated by a registered
//   descriptor stage. The parser therefore does not contain a wide compactor on
//   its state-update path.
// - Compacted payload is buffered in a small 24-byte reservoir. The common
//   output path removes exactly eight bytes with a fixed 64-bit shift; only the
//   append position is variable.
// - Length tokens are buffered independently. A released-byte credit counter
//   prevents payload from being emitted before the corresponding length token
//   has been accepted downstream.
// - Input ready depends only on registered parser/FIFO state. Downstream ready
//   does not propagate combinationally to the MoldUDP64 input.
//
// Latency / throughput trade-off:
// - Two local registered boundaries (parser descriptor -> compactor -> payload
//   reservoir) add a small fixed latency, but keep the initiation interval at
//   one 64-bit body beat per cycle and isolate the wide byte-selection logic.
//   This is preferable to the previous one-byte boundary path for a 156.25 MHz
//   10GbE design.

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
    if ((AXIS_DATA_W != 64) || (AXIS_KEEP_W != 8)) begin
      $error("mold_deframe parallel implementation requires 64-bit AXIS");
    end
    if (BODY_FIFO_DEPTH < 2) begin
      $error("mold_deframe BODY_FIFO_DEPTH must be at least two");
    end
  end

  typedef enum logic [2:0] {
    ST_HEADER,
    ST_GUARD,
    ST_BODY,
    ST_DRAIN,
    ST_DONE
  } state_t;

  localparam int BODY_FIFO_AW = (BODY_FIFO_DEPTH <= 2)
                             ? 1 : $clog2(BODY_FIFO_DEPTH);
  localparam int BODY_FIFO_CW = $clog2(BODY_FIFO_DEPTH + 1);
  localparam int PACK_COUNT_W = $clog2(AXIS_KEEP_W + 1);
  localparam int BODY_LANE_W  = $clog2(AXIS_KEEP_W);

  // A small local token FIFO is enough to decouple parser boundary discovery
  // from the downstream realign length FIFO without creating a ready chain.
  localparam int LEN_FIFO_DEPTH = 4;
  localparam int LEN_FIFO_AW    = $clog2(LEN_FIFO_DEPTH);
  localparam int LEN_FIFO_CW    = $clog2(LEN_FIFO_DEPTH + 1);

  // Three 64-bit words absorb the short start-up/length-credit phase while the
  // output pipeline fills. This avoids a recurrent packer bubble after partial
  // boundary chunks without putting downstream ready on the parser timing path.
  localparam int RESERVOIR_BYTES   = 3 * AXIS_KEEP_W;
  localparam int RESERVOIR_W       = 8 * RESERVOIR_BYTES;
  localparam int RESERVOIR_COUNT_W = $clog2(RESERVOIR_BYTES + 1);

  localparam logic [DGRAM_LEN_W-1:0] MOLD_HDR_BYTES_DGRAM =
      DGRAM_LEN_W'(MOLD_HDR_BYTES);

  state_t state;

  logic [1:0] header_beat_idx;

  logic [DGRAM_LEN_W-1:0] dgram_len;
  logic [DGRAM_LEN_W-1:0] dgram_bytes_seen;
  logic [DGRAM_LEN_W-1:0] body_bytes_consumed;
  logic                   dgram_end_seen;
  logic                   dropping;

  logic [MOLD_COUNT_W-1:0]   messages_left;
  logic [MOLD_MSG_LEN_W-1:0] payload_left;
  logic                      len_hi_valid;
  logic [7:0]                len_hi_byte;

  // Raw body FIFO. The parser uses a byte cursor into the registered head and
  // normally removes one complete entry per cycle.
  axis_data_t body_fifo_data [0:BODY_FIFO_DEPTH-1];
  axis_keep_t body_fifo_keep [0:BODY_FIFO_DEPTH-1];
  logic       body_fifo_last [0:BODY_FIFO_DEPTH-1];

  logic [BODY_FIFO_AW-1:0] body_wr_ptr;
  logic [BODY_FIFO_AW-1:0] body_rd_ptr;
  logic [BODY_FIFO_CW-1:0] body_fifo_count;
  logic [BODY_LANE_W-1:0]  body_head_lane;

  axis_data_t body_head_data;
  axis_keep_t body_head_keep;
  logic       body_head_last;
  logic [PACK_COUNT_W-1:0] body_head_byte_count;
  logic [PACK_COUNT_W-1:0] body_head_available;
  axis_data_t body_head_aligned;

  // Parser -> compactor descriptor. The descriptor keeps the wide byte
  // compaction out of the parser's control/state timing cone.
  logic                      desc_valid;
  axis_data_t                desc_raw_data;
  logic [PACK_COUNT_W-1:0]   desc_first_count;
  logic [1:0]                desc_skip_count;
  logic [PACK_COUNT_W-1:0]   desc_second_count;
  logic                      desc_last;

  // Registered compacted payload chunk.
  logic                      compact_valid;
  axis_data_t                compact_data;
  logic [PACK_COUNT_W-1:0]   compact_count;
  logic                      compact_last;

  // Length-token FIFO.
  logic [MOLD_MSG_LEN_W-1:0] len_fifo [0:LEN_FIFO_DEPTH-1];
  logic [LEN_FIFO_AW-1:0]    len_wr_ptr;
  logic [LEN_FIFO_AW-1:0]    len_rd_ptr;
  logic [LEN_FIFO_CW-1:0]    len_fifo_count;

  // Compacted payload reservoir and output credit. released_bytes is the number
  // of payload bytes whose length tokens have already been accepted by realign.
  logic [RESERVOIR_W-1:0]       payload_reservoir;
  logic [RESERVOIR_COUNT_W-1:0] payload_reservoir_count;
  logic [DGRAM_LEN_W-1:0]       released_bytes;
  logic                         payload_generation_done;

  logic                  guard_seq_valid;
  logic                  guard_accept_packet;
  logic                  guard_drop_packet;
  logic                  guard_in_order;
  logic                  guard_duplicate;
  logic                  guard_gap;
  logic                  guard_heartbeat;
  logic                  guard_eos;

  logic input_fire;
  logic msg_len_output_fire;
  logic payload_output_fire;

  logic packer_ready;
  logic compact_slot_available;
  logic desc_slot_available;
  logic compact_fire;
  logic desc_fire;
  logic parser_resources_available;
  logic cleanup_ready;

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

  function automatic logic [PACK_COUNT_W-1:0] keep_byte_count(
    input axis_keep_t keep
  );
    case (keep)
      8'b1000_0000: keep_byte_count = PACK_COUNT_W'(1);
      8'b1100_0000: keep_byte_count = PACK_COUNT_W'(2);
      8'b1110_0000: keep_byte_count = PACK_COUNT_W'(3);
      8'b1111_0000: keep_byte_count = PACK_COUNT_W'(4);
      8'b1111_1000: keep_byte_count = PACK_COUNT_W'(5);
      8'b1111_1100: keep_byte_count = PACK_COUNT_W'(6);
      8'b1111_1110: keep_byte_count = PACK_COUNT_W'(7);
      8'b1111_1111: keep_byte_count = PACK_COUNT_W'(8);
      default:       keep_byte_count = '0;
    endcase
  endfunction

  function automatic axis_keep_t keep_from_count(
    input logic [PACK_COUNT_W-1:0] count
  );
    case (count)
      PACK_COUNT_W'(1): keep_from_count = 8'b1000_0000;
      PACK_COUNT_W'(2): keep_from_count = 8'b1100_0000;
      PACK_COUNT_W'(3): keep_from_count = 8'b1110_0000;
      PACK_COUNT_W'(4): keep_from_count = 8'b1111_0000;
      PACK_COUNT_W'(5): keep_from_count = 8'b1111_1000;
      PACK_COUNT_W'(6): keep_from_count = 8'b1111_1100;
      PACK_COUNT_W'(7): keep_from_count = 8'b1111_1110;
      PACK_COUNT_W'(8): keep_from_count = 8'b1111_1111;
      default:          keep_from_count = 8'b0000_0000;
    endcase
  endfunction

  function automatic logic [7:0] lane_byte(
    input axis_data_t data,
    input int         lane
  );
    case (lane)
      0:       lane_byte = data[63:56];
      1:       lane_byte = data[55:48];
      2:       lane_byte = data[47:40];
      3:       lane_byte = data[39:32];
      4:       lane_byte = data[31:24];
      5:       lane_byte = data[23:16];
      6:       lane_byte = data[15:8];
      default: lane_byte = data[7:0];
    endcase
  endfunction

  // Fixed eight-way byte alignment mux. This is deliberately separated from
  // the compactor by the descriptor register.
  function automatic axis_data_t align_from_lane(
    input axis_data_t data,
    input logic [BODY_LANE_W-1:0] lane
  );
    case (lane)
      BODY_LANE_W'(0): align_from_lane = data;
      BODY_LANE_W'(1): align_from_lane = {data[55:0],  8'h00};
      BODY_LANE_W'(2): align_from_lane = {data[47:0], 16'h0000};
      BODY_LANE_W'(3): align_from_lane = {data[39:0], 24'h000000};
      BODY_LANE_W'(4): align_from_lane = {data[31:0], 32'h00000000};
      BODY_LANE_W'(5): align_from_lane = {data[23:0], 40'h0000000000};
      BODY_LANE_W'(6): align_from_lane = {data[15:0], 48'h000000000000};
      default:         align_from_lane = {data[7:0],  56'h00000000000000};
    endcase
  endfunction

  // Compact two payload ranges separated by one skipped prefix fragment. The
  // parser supplies only counts/metadata; this byte-selection network is
  // registered in its own stage.
  function automatic axis_data_t compact_descriptor(
    input axis_data_t              raw_data,
    input logic [PACK_COUNT_W-1:0] first_count,
    input logic [1:0]              skip_count,
    input logic [PACK_COUNT_W-1:0] second_count
  );
    axis_data_t result;
    int out_lane;
    int source_lane;
    int first_count_i;
    int second_count_i;
    begin
      result         = '0;
      first_count_i  = first_count;
      second_count_i = second_count;

      for (out_lane = 0; out_lane < AXIS_KEEP_W; out_lane++) begin
        if (out_lane < first_count_i) begin
          source_lane = out_lane;
          result[AXIS_DATA_W-1-(8*out_lane) -: 8]
              = lane_byte(raw_data, source_lane);
        end else if (out_lane < (first_count_i + second_count_i)) begin
          source_lane = out_lane + skip_count;
          result[AXIS_DATA_W-1-(8*out_lane) -: 8]
              = lane_byte(raw_data, source_lane);
        end
      end

      compact_descriptor = result;
    end
  endfunction

  // Append one left-aligned compacted chunk to the byte reservoir. This is the
  // only variable-position wide write and sits in a dedicated registered stage.
  function automatic logic [RESERVOIR_W-1:0] append_compact(
    input logic [RESERVOIR_W-1:0]       reservoir,
    input logic [RESERVOIR_COUNT_W-1:0] reservoir_count,
    input axis_data_t                    data,
    input logic [PACK_COUNT_W-1:0]       data_count
  );
    logic [RESERVOIR_W-1:0] result;
    int lane;
    int destination_byte;
    begin
      result = reservoir;

      for (lane = 0; lane < AXIS_KEEP_W; lane++) begin
        if (lane < data_count) begin
          destination_byte = reservoir_count + lane;
          if (destination_byte < RESERVOIR_BYTES) begin
            result[RESERVOIR_W-1-(8*destination_byte) -: 8]
                = lane_byte(data, lane);
          end
        end
      end

      append_compact = result;
    end
  endfunction

  function automatic logic [BODY_FIFO_AW-1:0] body_ptr_increment(
    input logic [BODY_FIFO_AW-1:0] ptr
  );
    if (ptr == BODY_FIFO_AW'(BODY_FIFO_DEPTH-1)) begin
      body_ptr_increment = '0;
    end else begin
      body_ptr_increment = ptr + BODY_FIFO_AW'(1);
    end
  endfunction

  function automatic logic [LEN_FIFO_AW-1:0] len_ptr_increment(
    input logic [LEN_FIFO_AW-1:0] ptr
  );
    if (ptr == LEN_FIFO_AW'(LEN_FIFO_DEPTH-1)) begin
      len_ptr_increment = '0;
    end else begin
      len_ptr_increment = ptr + LEN_FIFO_AW'(1);
    end
  endfunction

  assign body_head_data       = body_fifo_data[body_rd_ptr];
  assign body_head_keep       = body_fifo_keep[body_rd_ptr];
  assign body_head_last       = body_fifo_last[body_rd_ptr];
  assign body_head_byte_count = keep_byte_count(body_head_keep);
  assign body_head_available  = body_head_byte_count
                              - {1'b0, body_head_lane};
  assign body_head_aligned    = align_from_lane(body_head_data, body_head_lane);

  assign m_msg_len_valid_o = (len_fifo_count != '0);
  assign m_msg_len_o       = (len_fifo_count != '0)
                           ? len_fifo[len_rd_ptr]
                           : '0;

  assign msg_len_output_fire = m_msg_len_valid_o && m_msg_len_ready_i;
  assign payload_output_fire = m_payload_tvalid_o && m_payload_tready_i;

  // Leave one full-word slot free for the next compacted chunk. The third
  // reservoir word absorbs normal partial-boundary phasing, so this decision is
  // based only on registered occupancy and not downstream ready.
  assign packer_ready = (payload_reservoir_count
                         <= RESERVOIR_COUNT_W'(RESERVOIR_BYTES-AXIS_KEEP_W))
                      && !dropping;

  assign compact_fire           = compact_valid && packer_ready;
  assign compact_slot_available = !compact_valid || packer_ready;
  assign desc_fire              = desc_valid && compact_slot_available;
  assign desc_slot_available    = !desc_valid || compact_slot_available;

  // Conservative token-space check intentionally ignores a same-cycle external
  // pop. This removes m_msg_len_ready_i from the parser/input timing path.
  assign parser_resources_available =
      desc_slot_available
      && (len_fifo_count < LEN_FIFO_CW'(LEN_FIFO_DEPTH));

  // Header beats are accepted directly. During the registered guard cycle we
  // continue filling the body FIFO, avoiding a mandatory one-cycle source stall
  // at the header/body boundary.
  always_comb begin
    s_axis_tready_o = 1'b0;

    if (rst_n && !dgram_end_seen) begin
      unique case (state)
        ST_HEADER: begin
          s_axis_tready_o = 1'b1;
        end

        ST_GUARD,
        ST_BODY: begin
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

  // Sequence policy remains a registered boundary and therefore cannot become
  // part of the body-parser critical path.
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

  // Good datagrams wait for all generated payload/length information to drain.
  // Dropped datagrams discard internal buffered work and only wait for an
  // already-presented AXI payload beat to complete its handshake.
  assign cleanup_ready =
      (state == ST_DONE)
      && (body_fifo_count == '0)
      && !m_payload_tvalid_o
      && (dropping
          || (!desc_valid
              && !compact_valid
              && (payload_reservoir_count == '0)
              && (len_fifo_count == '0)
              && (released_bytes == '0)
              && payload_generation_done));

  // Header/input/FIFO/parser/length-token state.
  always_ff @(posedge clk) begin : parser_and_input
    logic push_body;
    logic pop_body;
    logic parser_fault;
    logic [MOLD_ERR_W-1:0] parser_fault_bits;

    logic [PACK_COUNT_W-1:0] input_bytes;
    logic [PACK_COUNT_W-1:0] header_body_bytes;
    logic [DGRAM_LEN_W-1:0] seen_after_input;
    logic [DGRAM_LEN_W-1:0] body_total_bytes;

    logic [MOLD_SEQ_W-1:0] seq_full;
    logic [MOLD_SEQ_W-1:0] count_ext;

    logic parse_step;
    logic [PACK_COUNT_W-1:0] consume_count;
    logic [PACK_COUNT_W-1:0] first_payload_count;
    logic [1:0]              skip_count;
    logic [PACK_COUNT_W-1:0] second_payload_count;
    logic                    descriptor_last;
    logic                    descriptor_produce;

    logic                    len_push;
    logic [MOLD_MSG_LEN_W-1:0] len_push_value;
    logic [MOLD_MSG_LEN_W-1:0] parsed_len;

    logic [MOLD_COUNT_W-1:0]   messages_after;
    logic [MOLD_MSG_LEN_W-1:0] payload_after;
    logic                      len_hi_valid_after;
    logic [7:0]                len_hi_byte_after;

    logic [PACK_COUNT_W-1:0] available;
    logic [PACK_COUNT_W-1:0] tail_count;
    logic [PACK_COUNT_W-1:0] remaining_after_tail;
    logic [PACK_COUNT_W-1:0] payload_take;
    logic [DGRAM_LEN_W-1:0] raw_after_prefix;
    logic [DGRAM_LEN_W-1:0] consumed_after;

    logic [LEN_FIFO_AW-1:0] len_wr_ptr_work;
    logic [LEN_FIFO_AW-1:0] len_rd_ptr_work;
    logic [LEN_FIFO_CW-1:0] len_count_work;

    if (!rst_n) begin
      state                 <= ST_HEADER;
      header_beat_idx       <= '0;

      dgram_len             <= '0;
      dgram_bytes_seen      <= '0;
      body_bytes_consumed   <= '0;
      dgram_end_seen        <= 1'b0;
      dropping              <= 1'b0;

      messages_left         <= '0;
      payload_left          <= '0;
      len_hi_valid          <= 1'b0;
      len_hi_byte           <= '0;

      body_wr_ptr           <= '0;
      body_rd_ptr           <= '0;
      body_fifo_count       <= '0;
      body_head_lane        <= '0;

      desc_valid            <= 1'b0;
      desc_raw_data         <= '0;
      desc_first_count      <= '0;
      desc_skip_count       <= '0;
      desc_second_count     <= '0;
      desc_last             <= 1'b0;

      len_wr_ptr            <= '0;
      len_rd_ptr            <= '0;
      len_fifo_count        <= '0;

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
      parser_fault      = 1'b0;
      parser_fault_bits = '0;

      input_bytes       = '0;
      header_body_bytes = '0;
      seen_after_input  = dgram_bytes_seen;
      body_total_bytes  = dgram_len - MOLD_HDR_BYTES_DGRAM;

      seq_full          = seq_o;
      count_ext         = '0;

      parse_step             = 1'b0;
      consume_count          = '0;
      first_payload_count    = '0;
      skip_count             = '0;
      second_payload_count   = '0;
      descriptor_last        = 1'b0;
      descriptor_produce     = 1'b0;

      len_push               = 1'b0;
      len_push_value         = '0;
      parsed_len             = '0;

      messages_after         = messages_left;
      payload_after          = payload_left;
      len_hi_valid_after     = len_hi_valid;
      len_hi_byte_after      = len_hi_byte;

      available              = body_head_available;
      tail_count             = '0;
      remaining_after_tail   = '0;
      payload_take           = '0;
      raw_after_prefix       = '0;
      consumed_after         = body_bytes_consumed;

      len_wr_ptr_work        = len_wr_ptr;
      len_rd_ptr_work        = len_rd_ptr;
      len_count_work         = len_fifo_count;

      // Pulse outputs default low.
      seq_valid_o <= 1'b0;
      heartbeat_o <= 1'b0;
      eos_o       <= 1'b0;
      in_order_o  <= 1'b0;
      duplicate_o <= 1'b0;
      gap_o       <= 1'b0;
      mold_drop_o <= 1'b0;
      mold_err_o  <= '0;

      // Descriptor stage is a standard one-entry ready/valid register. It may
      // be replaced in the same cycle the current descriptor is accepted by the
      // registered compactor stage.
      if (desc_fire) begin
        desc_valid <= 1'b0;
      end

      // Retire an externally accepted length token. Parser space deliberately
      // does not depend on this same-cycle pop.
      if (msg_len_output_fire) begin
        len_rd_ptr_work = len_ptr_increment(len_rd_ptr_work);
        len_count_work  = len_count_work - LEN_FIFO_CW'(1);
      end

      // Input handling is independent of body-parser consumption.
      if (input_fire) begin
        input_bytes      = keep_byte_count(s_axis_tkeep_i);
        seen_after_input = dgram_bytes_seen + DGRAM_LEN_W'(input_bytes);

        if (tkeep_bad(s_axis_tkeep_i, s_axis_tlast_i)) begin
          parser_fault_bits[MOLD_ERR_BAD_TKEEP] = 1'b1;
          parser_fault = 1'b1;
        end

        if (state == ST_HEADER) begin
          if (header_beat_idx == 2'd0) begin
            dgram_len           <= s_dgram_len_i;
            dgram_bytes_seen    <= DGRAM_LEN_W'(input_bytes);
            body_bytes_consumed <= '0;
            dgram_end_seen      <= s_axis_tlast_i;
            dropping            <= 1'b0;

            body_wr_ptr         <= '0;
            body_rd_ptr         <= '0;
            body_fifo_count     <= '0;
            body_head_lane      <= '0;

            messages_left       <= '0;
            payload_left        <= '0;
            len_hi_valid        <= 1'b0;
            len_hi_byte         <= '0;

            desc_valid          <= 1'b0;
            len_wr_ptr_work     = '0;
            len_rd_ptr_work     = '0;
            len_count_work      = '0;

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

          // Header beats 0 and 1 are always complete.
          if ((header_beat_idx < 2'd2)
              && (input_bytes != PACK_COUNT_W'(AXIS_KEEP_W))) begin
            parser_fault_bits[MOLD_ERR_SHORT_DGRAM] = 1'b1;
            parser_fault = 1'b1;
          end

          if (s_axis_tlast_i && (header_beat_idx < 2'd2)) begin
            parser_fault_bits[MOLD_ERR_SHORT_DGRAM] = 1'b1;
            parser_fault = 1'b1;
          end

          // Header beat 2 contains four mandatory header bytes followed by up
          // to four body bytes.
          if ((header_beat_idx == 2'd2)
              && (input_bytes < PACK_COUNT_W'(4))) begin
            parser_fault_bits[MOLD_ERR_SHORT_DGRAM] = 1'b1;
            parser_fault = 1'b1;
          end

          if (s_axis_tlast_i) begin
            if (header_beat_idx == 2'd0) begin
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
            2'd0: begin
              session_o[MOLD_SESSION_W-1 -: 64] <= s_axis_tdata_i;
              header_beat_idx <= 2'd1;
            end

            2'd1: begin
              session_o[15:0] <= s_axis_tdata_i[63:48];
              seq_o[63:16]    <= s_axis_tdata_i[47:0];
              header_beat_idx <= 2'd2;
            end

            2'd2: begin
              seq_full = {seq_o[63:16], s_axis_tdata_i[63:48]};
              count_ext = '0;
              count_ext[MOLD_COUNT_W-1:0] = s_axis_tdata_i[47:32];

              seq_o           <= seq_full;
              count_o         <= s_axis_tdata_i[47:32];
              expected_next_o <= seq_full + count_ext;
              header_beat_idx <= '0;
              state           <= ST_GUARD;

              header_body_bytes = input_bytes - PACK_COUNT_W'(4);

              if (!parser_fault && (header_body_bytes != '0)) begin
                body_fifo_data[body_wr_ptr] <=
                    {s_axis_tdata_i[31:0], 32'h0000_0000};
                body_fifo_keep[body_wr_ptr] <=
                    keep_from_count(header_body_bytes);
                body_fifo_last[body_wr_ptr] <= s_axis_tlast_i;
                body_wr_ptr                 <= body_ptr_increment(body_wr_ptr);
                push_body                   = 1'b1;
              end
            end

            default: begin
              parser_fault_bits[MOLD_ERR_SHORT_DGRAM] = 1'b1;
              parser_fault = 1'b1;
            end
          endcase
        end else if ((state == ST_GUARD) || (state == ST_BODY)) begin
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
            body_wr_ptr                 <= body_ptr_increment(body_wr_ptr);
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
          payload_left  <= '0;
          len_hi_valid  <= 1'b0;

          if (dgram_len == MOLD_HDR_BYTES_DGRAM) begin
            parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
            parser_fault = 1'b1;
          end else begin
            state <= ST_BODY;
          end
        end else begin
          dropping <= 1'b1;
          state    <= ST_DRAIN;

          // Status-only control datagrams must contain exactly the 20-byte
          // MoldUDP64 header.
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

      // Parallel body parser. The registered FIFO head is the only data source.
      // One parser cycle can consume:
      //   old-message tail + next 2-byte length + next-message payload
      // as one bounded operation. It never iterates dependent parser states over
      // all eight lanes.
      if (!parser_fault
          && !dropping
          && (state == ST_BODY)
          && (body_fifo_count != '0)
          && parser_resources_available) begin
        parse_step = 1'b1;

        if (available == '0) begin
          parser_fault_bits[MOLD_ERR_BAD_TKEEP] = 1'b1;
          parser_fault = 1'b1;
          parse_step = 1'b0;
        end else if (payload_left != '0) begin
          if (payload_left >= MOLD_MSG_LEN_W'(available)) begin
            // Common aligned/in-message path: all remaining bytes in this FIFO
            // head are payload. For long messages this removes one full 64-bit
            // body beat every cycle.
            consume_count       = available;
            first_payload_count = available;
            payload_after       = payload_left
                                - MOLD_MSG_LEN_W'(available);

            if (payload_left == MOLD_MSG_LEN_W'(available)) begin
              payload_after  = '0;
              messages_after = messages_left - MOLD_COUNT_W'(1);

              if (messages_left == MOLD_COUNT_W'(1)) begin
                consumed_after = body_bytes_consumed
                               + DGRAM_LEN_W'(consume_count);
                if (consumed_after != body_total_bytes) begin
                  parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
                  parser_fault = 1'b1;
                  parse_step = 1'b0;
                end else begin
                  descriptor_last = 1'b1;
                end
              end
            end
          end else begin
            // Current message ends within this FIFO head.
            tail_count           = PACK_COUNT_W'(payload_left);
            remaining_after_tail = available - tail_count;
            first_payload_count  = tail_count;
            messages_after       = messages_left - MOLD_COUNT_W'(1);
            payload_after        = '0;

            if (messages_left == MOLD_COUNT_W'(1)) begin
              // Any byte after the final message is an overrun.
              parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
              parser_fault = 1'b1;
              parse_step = 1'b0;
            end else if (remaining_after_tail == PACK_COUNT_W'(1)) begin
              // Only the high byte of the next length prefix remains in this
              // FIFO entry. Consume it now and finish the prefix next cycle.
              consume_count      = tail_count + PACK_COUNT_W'(1);
              len_hi_valid_after = 1'b1;
              len_hi_byte_after  = lane_byte(body_head_aligned, tail_count);
            end else begin
              // Tail + complete next prefix. Parse the next length and consume
              // as much of the next payload as fits in the same raw beat.
              parsed_len = {
                lane_byte(body_head_aligned, tail_count),
                lane_byte(body_head_aligned, tail_count + 1)
              };

              raw_after_prefix = body_bytes_consumed
                               + DGRAM_LEN_W'(tail_count)
                               + DGRAM_LEN_W'(2);

              if ((parsed_len == '0)
                  || (raw_after_prefix > body_total_bytes)
                  || (parsed_len > (body_total_bytes - raw_after_prefix))) begin
                parser_fault_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
                parser_fault = 1'b1;
                parse_step = 1'b0;
              end else begin
                len_push       = 1'b1;
                len_push_value = parsed_len;
                skip_count     = 2'd2;

                payload_take = remaining_after_tail - PACK_COUNT_W'(2);
                if (parsed_len < MOLD_MSG_LEN_W'(payload_take)) begin
                  payload_take = PACK_COUNT_W'(parsed_len);
                end

                second_payload_count = payload_take;
                consume_count = tail_count
                              + PACK_COUNT_W'(2)
                              + payload_take;
                payload_after = parsed_len - MOLD_MSG_LEN_W'(payload_take);

                if (payload_after == '0) begin
                  messages_after = messages_after - MOLD_COUNT_W'(1);

                  if (messages_after == '0) begin
                    consumed_after = body_bytes_consumed
                                   + DGRAM_LEN_W'(consume_count);
                    if (consumed_after != body_total_bytes) begin
                      parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
                      parser_fault = 1'b1;
                      parse_step = 1'b0;
                    end else begin
                      descriptor_last = 1'b1;
                    end
                  end
                end
              end
            end
          end
        end else begin
          // No current payload: consume a new two-byte MoldUDP64 message length.
          if (messages_left == '0) begin
            parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
            parser_fault = 1'b1;
            parse_step = 1'b0;
          end else if (len_hi_valid) begin
            // Prefix high byte was the final byte of the previous FIFO entry.
            parsed_len = {len_hi_byte, lane_byte(body_head_aligned, 0)};
            raw_after_prefix = body_bytes_consumed + DGRAM_LEN_W'(1);

            if ((parsed_len == '0)
                || (raw_after_prefix > body_total_bytes)
                || (parsed_len > (body_total_bytes - raw_after_prefix))) begin
              parser_fault_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
              parser_fault = 1'b1;
              parse_step = 1'b0;
            end else begin
              len_push            = 1'b1;
              len_push_value      = parsed_len;
              len_hi_valid_after  = 1'b0;
              skip_count          = 2'd1;

              payload_take = available - PACK_COUNT_W'(1);
              if (parsed_len < MOLD_MSG_LEN_W'(payload_take)) begin
                payload_take = PACK_COUNT_W'(parsed_len);
              end

              second_payload_count = payload_take;
              consume_count         = PACK_COUNT_W'(1) + payload_take;
              payload_after         = parsed_len - MOLD_MSG_LEN_W'(payload_take);

              if (payload_after == '0) begin
                messages_after = messages_left - MOLD_COUNT_W'(1);

                if (messages_left == MOLD_COUNT_W'(1)) begin
                  consumed_after = body_bytes_consumed
                                 + DGRAM_LEN_W'(consume_count);
                  if (consumed_after != body_total_bytes) begin
                    parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
                    parser_fault = 1'b1;
                    parse_step = 1'b0;
                  end else begin
                    descriptor_last = 1'b1;
                  end
                end
              end
            end
          end else if (available == PACK_COUNT_W'(1)) begin
            // Prefix itself is split across FIFO entries.
            consume_count      = PACK_COUNT_W'(1);
            len_hi_valid_after = 1'b1;
            len_hi_byte_after  = lane_byte(body_head_aligned, 0);
          end else begin
            parsed_len = {
              lane_byte(body_head_aligned, 0),
              lane_byte(body_head_aligned, 1)
            };
            raw_after_prefix = body_bytes_consumed + DGRAM_LEN_W'(2);

            if ((parsed_len == '0)
                || (raw_after_prefix > body_total_bytes)
                || (parsed_len > (body_total_bytes - raw_after_prefix))) begin
              parser_fault_bits[MOLD_ERR_LEN_OVERRUN] = 1'b1;
              parser_fault = 1'b1;
              parse_step = 1'b0;
            end else begin
              len_push       = 1'b1;
              len_push_value = parsed_len;
              skip_count     = 2'd2;

              payload_take = available - PACK_COUNT_W'(2);
              if (parsed_len < MOLD_MSG_LEN_W'(payload_take)) begin
                payload_take = PACK_COUNT_W'(parsed_len);
              end

              second_payload_count = payload_take;
              consume_count         = PACK_COUNT_W'(2) + payload_take;
              payload_after         = parsed_len - MOLD_MSG_LEN_W'(payload_take);

              if (payload_after == '0) begin
                messages_after = messages_left - MOLD_COUNT_W'(1);

                if (messages_left == MOLD_COUNT_W'(1)) begin
                  consumed_after = body_bytes_consumed
                                 + DGRAM_LEN_W'(consume_count);
                  if (consumed_after != body_total_bytes) begin
                    parser_fault_bits[MOLD_ERR_COUNT_OVERRUN] = 1'b1;
                    parser_fault = 1'b1;
                    parse_step = 1'b0;
                  end else begin
                    descriptor_last = 1'b1;
                  end
                end
              end
            end
          end
        end

        if (parse_step && !parser_fault) begin
          descriptor_produce =
              ((first_payload_count + second_payload_count) != '0);

          // Commit parser context.
          body_bytes_consumed <= body_bytes_consumed
                               + DGRAM_LEN_W'(consume_count);
          messages_left       <= messages_after;
          payload_left        <= payload_after;
          len_hi_valid        <= len_hi_valid_after;
          len_hi_byte         <= len_hi_byte_after;

          // Advance the FIFO byte cursor by all raw bytes consumed this cycle.
          if (consume_count == available) begin
            pop_body       = 1'b1;
            body_head_lane <= '0;
          end else begin
            body_head_lane <= body_head_lane
                            + BODY_LANE_W'(consume_count);
          end

          if (descriptor_produce) begin
            desc_valid        <= 1'b1;
            desc_raw_data     <= body_head_aligned;
            desc_first_count  <= first_payload_count;
            desc_skip_count   <= skip_count;
            desc_second_count <= second_payload_count;
            desc_last         <= descriptor_last;
          end

          if (len_push) begin
            len_fifo[len_wr_ptr_work] <= len_push_value;
            len_wr_ptr_work = len_ptr_increment(len_wr_ptr_work);
            len_count_work  = len_count_work + LEN_FIFO_CW'(1);
          end

          if (descriptor_last) begin
            state <= ST_DONE;
          end
        end
      end

      // Drain buffered body entries for duplicate/control/error packets. Incoming
      // drain beats are discarded directly and do not consume FIFO capacity.
      if (state == ST_DRAIN) begin
        if (body_fifo_count != '0) begin
          pop_body       = 1'b1;
          body_head_lane <= '0;
        end else if (dgram_end_seen) begin
          state <= ST_DONE;
        end
      end

      if (pop_body) begin
        body_rd_ptr <= body_ptr_increment(body_rd_ptr);
      end

      unique case ({push_body, pop_body})
        2'b10: body_fifo_count <= body_fifo_count + BODY_FIFO_CW'(1);
        2'b01: body_fifo_count <= body_fifo_count - BODY_FIFO_CW'(1);
        default: begin
          // Simultaneous push/pop preserves occupancy.
        end
      endcase

      // Parser/packet faults select the registered drain state. Unpresented
      // descriptors/tokens are discarded; an already-presented AXI payload beat
      // is allowed to complete normally by the output stage.
      if (parser_fault) begin
        mold_drop_o <= 1'b1;
        mold_err_o  <= parser_fault_bits;
        dropping    <= 1'b1;
        state       <= ST_DRAIN;
        desc_valid  <= 1'b0;

        len_wr_ptr_work = '0;
        len_rd_ptr_work = '0;
        len_count_work  = '0;
      end

      // A guard-requested duplicate/control drop also discards any local token
      // state. No parser payload has been generated at this point.
      if ((state == ST_GUARD) && guard_drop_packet) begin
        desc_valid      <= 1'b0;
        len_wr_ptr_work = '0;
        len_rd_ptr_work = '0;
        len_count_work  = '0;
      end

      // Commit token FIFO pointers/count after any simultaneous pop/push.
      len_wr_ptr     <= len_wr_ptr_work;
      len_rd_ptr     <= len_rd_ptr_work;
      len_fifo_count <= len_count_work;

      // Registered cleanup boundary between datagrams.
      if (cleanup_ready) begin
        state                 <= ST_HEADER;
        header_beat_idx       <= '0;

        dgram_len             <= '0;
        dgram_bytes_seen      <= '0;
        body_bytes_consumed   <= '0;
        dgram_end_seen        <= 1'b0;
        dropping              <= 1'b0;

        messages_left         <= '0;
        payload_left          <= '0;
        len_hi_valid          <= 1'b0;
        len_hi_byte           <= '0;

        body_wr_ptr           <= '0;
        body_rd_ptr           <= '0;
        body_fifo_count       <= '0;
        body_head_lane        <= '0;

        desc_valid            <= 1'b0;
        desc_raw_data         <= '0;
        desc_first_count      <= '0;
        desc_skip_count       <= '0;
        desc_second_count     <= '0;
        desc_last             <= 1'b0;

        len_wr_ptr            <= '0;
        len_rd_ptr            <= '0;
        len_fifo_count        <= '0;
      end
    end
  end

  // Descriptor compaction and payload output buffering. These wide operations
  // are intentionally separated from the body parser by registers.
  always_ff @(posedge clk) begin : compact_and_output
    logic [PACK_COUNT_W-1:0] desc_payload_count;
    axis_data_t              desc_compacted_data;

    logic [RESERVOIR_W-1:0]       reservoir_work;
    logic [RESERVOIR_COUNT_W-1:0] reservoir_count_work;
    logic [DGRAM_LEN_W-1:0]       released_work;
    logic                          generation_done_work;

    logic output_slot_available;
    logic load_output;
    logic [PACK_COUNT_W-1:0] emit_count;
    logic emit_last;

    if (!rst_n) begin
      compact_valid            <= 1'b0;
      compact_data             <= '0;
      compact_count            <= '0;
      compact_last             <= 1'b0;

      payload_reservoir        <= '0;
      payload_reservoir_count  <= '0;
      released_bytes           <= '0;
      payload_generation_done  <= 1'b0;

      m_payload_tdata_o        <= '0;
      m_payload_tkeep_o        <= '0;
      m_payload_tvalid_o       <= 1'b0;
      m_payload_tlast_o        <= 1'b0;
    end else begin
      desc_payload_count = desc_first_count + desc_second_count;
      desc_compacted_data = compact_descriptor(
          desc_raw_data,
          desc_first_count,
          desc_skip_count,
          desc_second_count
      );

      reservoir_work         = payload_reservoir;
      reservoir_count_work   = payload_reservoir_count;
      released_work          = released_bytes;
      generation_done_work   = payload_generation_done;

      output_slot_available  = !m_payload_tvalid_o || m_payload_tready_i;
      load_output            = 1'b0;
      emit_count             = '0;
      emit_last              = 1'b0;

      // During a drop/error drain, discard all not-yet-presented internal work.
      // An already-valid output beat remains stable until its normal handshake.
      if (dropping) begin
        compact_valid           <= 1'b0;
        compact_data            <= '0;
        compact_count           <= '0;
        compact_last            <= 1'b0;

        payload_reservoir       <= '0;
        payload_reservoir_count <= '0;
        released_bytes          <= '0;
        payload_generation_done <= 1'b0;

        if (payload_output_fire) begin
          m_payload_tvalid_o <= 1'b0;
          m_payload_tlast_o  <= 1'b0;
        end
      end else begin
        // Retire the current output beat. A replacement may be loaded below in
        // the same cycle, retaining one output beat/cycle throughput.
        if (payload_output_fire) begin
          m_payload_tvalid_o <= 1'b0;
          m_payload_tlast_o  <= 1'b0;
        end

        // Remove only already-buffered reservoir data. Newly compacted bytes are
        // appended later in this cycle, keeping the output decision independent
        // of the wide compaction network.
        if (output_slot_available) begin
          if (generation_done_work
              && (reservoir_count_work != '0)
              && (reservoir_count_work <= RESERVOIR_COUNT_W'(AXIS_KEEP_W))
              && (released_work >= DGRAM_LEN_W'(reservoir_count_work))) begin
            emit_count  = PACK_COUNT_W'(reservoir_count_work);
            emit_last   = 1'b1;
            load_output = 1'b1;
          end else if ((reservoir_count_work >= RESERVOIR_COUNT_W'(AXIS_KEEP_W))
                       && (released_work >= DGRAM_LEN_W'(AXIS_KEEP_W))) begin
            emit_count  = PACK_COUNT_W'(AXIS_KEEP_W);
            emit_last   = 1'b0;
            load_output = 1'b1;
          end
        end

        if (load_output) begin
          m_payload_tdata_o  <= reservoir_work[RESERVOIR_W-1 -: AXIS_DATA_W];
          m_payload_tkeep_o  <= keep_from_count(emit_count);
          m_payload_tvalid_o <= 1'b1;
          m_payload_tlast_o  <= emit_last;

          released_work = released_work - DGRAM_LEN_W'(emit_count);

          if (emit_count == PACK_COUNT_W'(AXIS_KEEP_W)) begin
            // Common path: fixed 64-bit removal, no variable-width shift.
            reservoir_work       = reservoir_work << AXIS_DATA_W;
            reservoir_count_work = reservoir_count_work
                                 - RESERVOIR_COUNT_W'(AXIS_KEEP_W);
          end else begin
            // Partial output is only legal for the final datagram beat. No more
            // compacted payload may follow, so the reservoir can simply clear.
            reservoir_work       = '0;
            reservoir_count_work = '0;
          end
        end

        // Accept the current compacted chunk into the 24-byte reservoir.
        if (compact_fire) begin
          reservoir_work = append_compact(
              reservoir_work,
              reservoir_count_work,
              compact_data,
              compact_count
          );
          reservoir_count_work = reservoir_count_work
                               + RESERVOIR_COUNT_W'(compact_count);

          if (compact_last) begin
            generation_done_work = 1'b1;
          end
        end

        // Compactor ready/valid register. It can be replaced in the same cycle
        // its current value is accepted by the payload reservoir.
        if (compact_fire) begin
          compact_valid <= 1'b0;
        end

        if (desc_fire) begin
          compact_valid <= 1'b1;
          compact_data  <= desc_compacted_data;
          compact_count <= desc_payload_count;
          compact_last  <= desc_last;
        end

        // Length acceptance creates payload credit. Deliberately apply this
        // after the output decision so m_msg_len_ready_i cannot enter the same
        // cycle payload-output timing cone.
        if (msg_len_output_fire) begin
          released_work = released_work + DGRAM_LEN_W'(m_msg_len_o);
        end

        payload_reservoir       <= reservoir_work;
        payload_reservoir_count <= reservoir_count_work;
        released_bytes           <= released_work;
        payload_generation_done  <= generation_done_work;
      end

      if (cleanup_ready) begin
        compact_valid            <= 1'b0;
        compact_data             <= '0;
        compact_count            <= '0;
        compact_last             <= 1'b0;

        payload_reservoir        <= '0;
        payload_reservoir_count  <= '0;
        released_bytes           <= '0;
        payload_generation_done  <= 1'b0;

        m_payload_tdata_o        <= '0;
        m_payload_tkeep_o        <= '0;
        m_payload_tvalid_o       <= 1'b0;
        m_payload_tlast_o        <= 1'b0;
      end
    end
  end

endmodule

`default_nettype wire
