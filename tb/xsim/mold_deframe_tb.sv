`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module mold_deframe_tb;

  localparam logic [MOLD_SESSION_W-1:0] TEST_SESSION = 80'h53_45_53_53_49_4f_4e_30_30_31; // "SESSION001"
  localparam logic [MOLD_SEQ_W-1:0]     TEST_SEQ     = 64'h0102_0304_0506_0708;

  logic       clk;
  logic       rst_n;

  axis_data_t s_axis_tdata_i;
  axis_keep_t s_axis_tkeep_i;
  logic       s_axis_tvalid_i;
  logic       s_axis_tlast_i;
  logic       s_axis_tready_o;

  logic [DGRAM_LEN_W-1:0] s_dgram_len_i;
  logic                   s_dgram_start_i;

  axis_data_t m_payload_tdata_o;
  axis_keep_t m_payload_tkeep_o;
  logic       m_payload_tvalid_o;
  logic       m_payload_tlast_o;
  logic       m_payload_tready_i;

  logic [MOLD_MSG_LEN_W-1:0] m_msg_len_o;
  logic                      m_msg_len_valid_o;
  logic                      m_msg_len_ready_i;

  logic [MOLD_SESSION_W-1:0] session_o;
  logic [MOLD_SEQ_W-1:0]     seq_o;
  logic [MOLD_COUNT_W-1:0]   count_o;
  logic [MOLD_SEQ_W-1:0]     expected_next_o;
  logic                      seq_valid_o;
  logic                      heartbeat_o;
  logic                      eos_o;
  logic                      in_order_o;
  logic                      duplicate_o;
  logic                      gap_o;
  logic                      stale_o;
  logic [MOLD_SEQ_W-1:0]     expected_seq_o;
  logic [MOLD_SEQ_W-1:0]     gap_start_o;
  logic [MOLD_SEQ_W-1:0]     gap_end_o;

  logic                      mold_drop_o;
  logic [MOLD_ERR_W-1:0]     mold_err_o;

  byte unsigned rx_payload[$];
  int unsigned  rx_payload_packets;
  int unsigned  msg_lens[$];

  int unsigned seq_pulses;
  int unsigned heartbeat_pulses;
  int unsigned eos_pulses;
  int unsigned in_order_pulses;
  int unsigned duplicate_pulses;
  int unsigned gap_pulses;

  logic [MOLD_SESSION_W-1:0] last_session;
  logic [MOLD_SEQ_W-1:0]     last_seq;
  logic [MOLD_COUNT_W-1:0]   last_count;
  logic [MOLD_SEQ_W-1:0]     last_expected_next;

  int unsigned drop_pulses;
  logic [MOLD_ERR_W-1:0] last_drop_err;

  mold_deframe dut (
    .clk                (clk),
    .rst_n              (rst_n),

    .s_axis_tdata_i     (s_axis_tdata_i),
    .s_axis_tkeep_i     (s_axis_tkeep_i),
    .s_axis_tvalid_i    (s_axis_tvalid_i),
    .s_axis_tlast_i     (s_axis_tlast_i),
    .s_axis_tready_o    (s_axis_tready_o),

    .s_dgram_len_i      (s_dgram_len_i),
    .s_dgram_start_i    (s_dgram_start_i),

    .m_payload_tdata_o  (m_payload_tdata_o),
    .m_payload_tkeep_o  (m_payload_tkeep_o),
    .m_payload_tvalid_o (m_payload_tvalid_o),
    .m_payload_tlast_o  (m_payload_tlast_o),
    .m_payload_tready_i (m_payload_tready_i),

    .m_msg_len_o        (m_msg_len_o),
    .m_msg_len_valid_o  (m_msg_len_valid_o),
    .m_msg_len_ready_i  (m_msg_len_ready_i),

    .session_o          (session_o),
    .seq_o              (seq_o),
    .count_o            (count_o),
    .expected_next_o    (expected_next_o),
    .seq_valid_o        (seq_valid_o),
    .heartbeat_o        (heartbeat_o),
    .eos_o              (eos_o),
    .in_order_o         (in_order_o),
    .duplicate_o        (duplicate_o),
    .gap_o              (gap_o),
    .stale_o            (stale_o),
    .expected_seq_o     (expected_seq_o),
    .gap_start_o        (gap_start_o),
    .gap_end_o          (gap_end_o),

    .mold_drop_o        (mold_drop_o),
    .mold_err_o         (mold_err_o)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  always_ff @(posedge clk) begin
    if (rst_n && m_payload_tvalid_o && m_payload_tready_i) begin
      for (int lane = 0; lane < AXIS_KEEP_W; lane++) begin
        if (m_payload_tkeep_o[AXIS_KEEP_W-1-lane]) begin
          rx_payload.push_back(m_payload_tdata_o[AXIS_DATA_W-1-(8*lane) -: 8]);
        end
      end

      if (m_payload_tlast_o) begin
        rx_payload_packets++;
      end
    end

    if (rst_n && m_msg_len_valid_o && m_msg_len_ready_i) begin
      msg_lens.push_back(m_msg_len_o);
    end

    if (rst_n && seq_valid_o) begin
      seq_pulses++;
      last_session       <= session_o;
      last_seq           <= seq_o;
      last_count         <= count_o;
      last_expected_next <= expected_next_o;
    end

    if (rst_n && heartbeat_o) begin
      heartbeat_pulses++;
    end

    if (rst_n && eos_o) begin
      eos_pulses++;
    end

    if (rst_n && in_order_o) begin
      in_order_pulses++;
    end

    if (rst_n && duplicate_o) begin
      duplicate_pulses++;
    end

    if (rst_n && gap_o) begin
      gap_pulses++;
    end

    if (rst_n && mold_drop_o) begin
      drop_pulses++;
      last_drop_err <= mold_err_o;
    end
  end

  task automatic clear_scoreboard();
    rx_payload.delete();
    rx_payload_packets = 0;
    msg_lens.delete();

    seq_pulses         = 0;
    heartbeat_pulses   = 0;
    eos_pulses         = 0;
    in_order_pulses    = 0;
    duplicate_pulses   = 0;
    gap_pulses         = 0;
    last_session       = '0;
    last_seq           = '0;
    last_count         = '0;
    last_expected_next = '0;

    drop_pulses        = 0;
    last_drop_err      = '0;
  endtask

  task automatic reset_dut();
    rst_n                <= 1'b0;
    s_axis_tdata_i       <= '0;
    s_axis_tkeep_i       <= '0;
    s_axis_tvalid_i      <= 1'b0;
    s_axis_tlast_i       <= 1'b0;
    s_dgram_len_i        <= '0;
    s_dgram_start_i      <= 1'b0;
    m_payload_tready_i   <= 1'b1;
    m_msg_len_ready_i    <= 1'b1;
    clear_scoreboard();

    repeat (8) @(posedge clk);
    rst_n <= 1'b1;
    repeat (2) @(posedge clk);
  endtask

  task automatic write_u16_be(
    ref byte unsigned data[],
    ref int unsigned  idx,
    input logic [15:0] value
  );
    data[idx] = value[15:8];
    idx++;
    data[idx] = value[7:0];
    idx++;
  endtask

  task automatic write_u64_be(
    ref byte unsigned data[],
    ref int unsigned  idx,
    input logic [63:0] value
  );
    for (int byte_idx = 7; byte_idx >= 0; byte_idx--) begin
      data[idx] = value[8*byte_idx +: 8];
      idx++;
    end
  endtask

  task automatic write_session(
    ref byte unsigned data[],
    ref int unsigned  idx,
    input logic [MOLD_SESSION_W-1:0] session
  );
    for (int byte_idx = 0; byte_idx < MOLD_SESSION_BYTES; byte_idx++) begin
      data[idx] = session[MOLD_SESSION_W-1-(8*byte_idx) -: 8];
      idx++;
    end
  endtask

  task automatic build_one_msg_dgram(
    input  logic [MOLD_SEQ_W-1:0] seq,
    input  byte unsigned msg0[],
    output byte unsigned dgram[]
  );
    int unsigned idx;
    logic [15:0] msg0_len;

    dgram = new[MOLD_HDR_BYTES + 2 + msg0.size()];
    idx = 0;
    msg0_len = msg0.size();

    write_session(dgram, idx, TEST_SESSION);
    write_u64_be(dgram, idx, seq);
    write_u16_be(dgram, idx, 16'd1);
    write_u16_be(dgram, idx, msg0_len);

    foreach (msg0[i]) begin
      dgram[idx] = msg0[i];
      idx++;
    end
  endtask

  task automatic build_two_msg_dgram(
    input  logic [MOLD_SEQ_W-1:0] seq,
    input  byte unsigned msg0[],
    input  byte unsigned msg1[],
    output byte unsigned dgram[]
  );
    int unsigned idx;
    logic [15:0] msg0_len;
    logic [15:0] msg1_len;

    dgram = new[MOLD_HDR_BYTES + 2 + msg0.size() + 2 + msg1.size()];
    idx = 0;
    msg0_len = msg0.size();
    msg1_len = msg1.size();

    write_session(dgram, idx, TEST_SESSION);
    write_u64_be(dgram, idx, seq);
    write_u16_be(dgram, idx, 16'd2);
    write_u16_be(dgram, idx, msg0_len);

    foreach (msg0[i]) begin
      dgram[idx] = msg0[i];
      idx++;
    end

    write_u16_be(dgram, idx, msg1_len);

    foreach (msg1[i]) begin
      dgram[idx] = msg1[i];
      idx++;
    end
  endtask

  task automatic build_control_dgram(
    input  logic [MOLD_SEQ_W-1:0] seq,
    input  logic [15:0] count,
    output byte unsigned dgram[]
  );
    int unsigned idx;

    dgram = new[MOLD_HDR_BYTES];
    idx = 0;

    write_session(dgram, idx, TEST_SESSION);
    write_u64_be(dgram, idx, seq);
    write_u16_be(dgram, idx, count);
  endtask

  task automatic build_bad_len_dgram(
    input  logic [MOLD_SEQ_W-1:0] seq,
    output byte unsigned dgram[]
  );
    int unsigned idx;

    dgram = new[MOLD_HDR_BYTES + 2 + 3];
    idx = 0;

    write_session(dgram, idx, TEST_SESSION);
    write_u64_be(dgram, idx, seq);
    write_u16_be(dgram, idx, 16'd1);
    write_u16_be(dgram, idx, 16'd10); // Declares 10 bytes but only carries 3.

    dgram[idx] = 8'ha1;
    idx++;
    dgram[idx] = 8'ha2;
    idx++;
    dgram[idx] = 8'ha3;
    idx++;
  endtask

  task automatic concat_two(
    input  byte unsigned msg0[],
    input  byte unsigned msg1[],
    output byte unsigned expected[]
  );
    int unsigned idx;

    expected = new[msg0.size() + msg1.size()];
    idx = 0;

    foreach (msg0[i]) begin
      expected[idx] = msg0[i];
      idx++;
    end

    foreach (msg1[i]) begin
      expected[idx] = msg1[i];
      idx++;
    end
  endtask

  task automatic copy_msg(
    input  byte unsigned msg[],
    output byte unsigned expected[]
  );
    expected = new[msg.size()];
    foreach (msg[i]) begin
      expected[i] = msg[i];
    end
  endtask

  task automatic send_dgram(input byte unsigned dgram[]);
    int unsigned offset;
    logic        first_beat;
    axis_data_t  beat_data;
    axis_keep_t  beat_keep;
    logic [DGRAM_LEN_W-1:0] dgram_len;

    offset = 0;
    first_beat = 1'b1;
    dgram_len = dgram.size();

    while (offset < dgram.size()) begin
      beat_data = '0;
      beat_keep = '0;

      for (int lane = 0; lane < AXIS_KEEP_W; lane++) begin
        if ((offset + lane) < dgram.size()) begin
          beat_data[AXIS_DATA_W-1-(8*lane) -: 8] = dgram[offset+lane];
          beat_keep[AXIS_KEEP_W-1-lane]          = 1'b1;
        end
      end

      s_axis_tdata_i  <= beat_data;
      s_axis_tkeep_i  <= beat_keep;
      s_axis_tlast_i  <= ((offset + AXIS_KEEP_W) >= dgram.size());
      s_axis_tvalid_i <= 1'b1;
      s_dgram_len_i   <= dgram_len;
      s_dgram_start_i <= first_beat;

      do begin
        @(posedge clk);
      end while (!s_axis_tready_o);

      offset += AXIS_KEEP_W;
      first_beat = 1'b0;
    end

    s_axis_tvalid_i <= 1'b0;
    s_axis_tlast_i  <= 1'b0;
    s_axis_tdata_i  <= '0;
    s_axis_tkeep_i  <= '0;
    s_dgram_start_i <= 1'b0;
    @(posedge clk);
  endtask

  task automatic wait_for_payload_packets(input int unsigned target_packets);
    int unsigned cycles;

    cycles = 0;
    while ((rx_payload_packets < target_packets) && (cycles < 3000)) begin
      cycles++;
      @(posedge clk);
    end

    if (rx_payload_packets < target_packets) begin
      $fatal(1, "Timed out waiting for %0d payload packet(s), saw %0d", target_packets, rx_payload_packets);
    end
  endtask

  task automatic wait_for_seq_pulses(input int unsigned target_pulses);
    int unsigned cycles;

    cycles = 0;
    while ((seq_pulses < target_pulses) && (cycles < 1000)) begin
      cycles++;
      @(posedge clk);
    end

    if (seq_pulses < target_pulses) begin
      $fatal(1, "Timed out waiting for %0d seq_valid pulse(s), saw %0d", target_pulses, seq_pulses);
    end
  endtask

  task automatic wait_for_drop(input int unsigned target_pulses);
    int unsigned cycles;

    cycles = 0;
    while ((drop_pulses < target_pulses) && (cycles < 1000)) begin
      cycles++;
      @(posedge clk);
    end

    if (drop_pulses < target_pulses) begin
      $fatal(1, "Timed out waiting for %0d mold_drop pulse(s), saw %0d", target_pulses, drop_pulses);
    end
  endtask

  task automatic wait_no_payload();
    repeat (40) @(posedge clk);

    if ((rx_payload_packets != 0) || (rx_payload.size() != 0) || (msg_lens.size() != 0)) begin
      $fatal(1, "Expected no payload/msg_len output, got payload_packets=%0d bytes=%0d msg_lens=%0d",
             rx_payload_packets, rx_payload.size(), msg_lens.size());
    end
  endtask

  task automatic expect_payload(input byte unsigned expected[]);
    if (rx_payload.size() != expected.size()) begin
      $fatal(1, "Payload byte count mismatch: got %0d expected %0d", rx_payload.size(), expected.size());
    end

    foreach (expected[i]) begin
      if (rx_payload[i] !== expected[i]) begin
        $fatal(1, "Payload byte %0d mismatch: got 0x%02x expected 0x%02x", i, rx_payload[i], expected[i]);
      end
    end
  endtask

  task automatic expect_one_msg_len(input int unsigned len0);
    if (msg_lens.size() != 1) begin
      $fatal(1, "Expected 1 msg_len item, got %0d", msg_lens.size());
    end

    if (msg_lens[0] != len0) begin
      $fatal(1, "msg_len[0] mismatch: got %0d expected %0d", msg_lens[0], len0);
    end
  endtask

  task automatic expect_two_msg_lens(input int unsigned len0, input int unsigned len1);
    if (msg_lens.size() != 2) begin
      $fatal(1, "Expected 2 msg_len items, got %0d", msg_lens.size());
    end

    if ((msg_lens[0] != len0) || (msg_lens[1] != len1)) begin
      $fatal(1, "msg_len mismatch: got [%0d,%0d] expected [%0d,%0d]",
             msg_lens[0], msg_lens[1], len0, len1);
    end
  endtask

  task automatic expect_seq_sideband(
    input logic [MOLD_SEQ_W-1:0]   expected_seq,
    input logic [MOLD_COUNT_W-1:0] expected_count
  );
    if (seq_pulses != 1) begin
      $fatal(1, "Expected exactly one seq_valid pulse, got %0d", seq_pulses);
    end

    if (last_session !== TEST_SESSION) begin
      $fatal(1, "Session mismatch: got 0x%020x expected 0x%020x", last_session, TEST_SESSION);
    end

    if (last_seq !== expected_seq) begin
      $fatal(1, "Sequence mismatch: got 0x%016x expected 0x%016x", last_seq, expected_seq);
    end

    if (last_count !== expected_count) begin
      $fatal(1, "Count mismatch: got 0x%04x expected 0x%04x", last_count, expected_count);
    end

    if (last_expected_next !== (expected_seq + expected_count)) begin
      $fatal(1, "expected_next mismatch: got 0x%016x expected 0x%016x",
             last_expected_next, expected_seq + expected_count);
    end
  endtask

  task automatic expect_status_counts(
    input int unsigned exp_in_order,
    input int unsigned exp_duplicate,
    input int unsigned exp_gap,
    input int unsigned exp_heartbeat,
    input int unsigned exp_eos,
    input int unsigned exp_drop
  );
    if (in_order_pulses != exp_in_order) begin
      $fatal(1, "in_order pulse mismatch: got %0d expected %0d", in_order_pulses, exp_in_order);
    end
    if (duplicate_pulses != exp_duplicate) begin
      $fatal(1, "duplicate pulse mismatch: got %0d expected %0d", duplicate_pulses, exp_duplicate);
    end
    if (gap_pulses != exp_gap) begin
      $fatal(1, "gap pulse mismatch: got %0d expected %0d", gap_pulses, exp_gap);
    end
    if (heartbeat_pulses != exp_heartbeat) begin
      $fatal(1, "heartbeat pulse mismatch: got %0d expected %0d", heartbeat_pulses, exp_heartbeat);
    end
    if (eos_pulses != exp_eos) begin
      $fatal(1, "eos pulse mismatch: got %0d expected %0d", eos_pulses, exp_eos);
    end
    if (drop_pulses != exp_drop) begin
      $fatal(1, "mold_drop pulse mismatch: got %0d expected %0d err=0x%04x", drop_pulses, exp_drop, last_drop_err);
    end
  endtask

  task automatic expect_seq_guard_state(
    input logic             exp_stale,
    input logic [MOLD_SEQ_W-1:0] exp_expected_seq,
    input logic [MOLD_SEQ_W-1:0] exp_gap_start,
    input logic [MOLD_SEQ_W-1:0] exp_gap_end
  );
    if (stale_o !== exp_stale) begin
      $fatal(1, "stale mismatch: got %0b expected %0b", stale_o, exp_stale);
    end
    if (expected_seq_o !== exp_expected_seq) begin
      $fatal(1, "expected_seq_o mismatch: got 0x%016x expected 0x%016x", expected_seq_o, exp_expected_seq);
    end
    if (gap_start_o !== exp_gap_start) begin
      $fatal(1, "gap_start_o mismatch: got 0x%016x expected 0x%016x", gap_start_o, exp_gap_start);
    end
    if (gap_end_o !== exp_gap_end) begin
      $fatal(1, "gap_end_o mismatch: got 0x%016x expected 0x%016x", gap_end_o, exp_gap_end);
    end
  endtask

  task automatic test_two_messages();
    byte unsigned msg0[];
    byte unsigned msg1[];
    byte unsigned dgram[];
    byte unsigned expected[];

    $display("TEST MoldUDP64 datagram with two ITCH messages");

    msg0 = new[3];
    msg0[0] = 8'h41;
    msg0[1] = 8'h01;
    msg0[2] = 8'h02;

    msg1 = new[12];
    foreach (msg1[i]) begin
      msg1[i] = byte'(8'h80 + i);
    end

    build_two_msg_dgram(TEST_SEQ, msg0, msg1, dgram);
    concat_two(msg0, msg1, expected);

    send_dgram(dgram);
    wait_for_payload_packets(1);

    expect_payload(expected);
    expect_two_msg_lens(msg0.size(), msg1.size());
    expect_seq_sideband(TEST_SEQ, 16'd2);
    expect_status_counts(1, 0, 0, 0, 0, 0);
    expect_seq_guard_state(1'b0, TEST_SEQ + 64'd2, 64'd0, 64'd0);
  endtask

  task automatic test_duplicate_suppressed();
    byte unsigned first_msg[];
    byte unsigned dup_msg[];
    byte unsigned dgram[];
    byte unsigned expected[];
    logic [MOLD_SEQ_W-1:0] seq;

    $display("TEST duplicate datagram is suppressed before msg_len/payload output");

    seq = 64'd1000;

    first_msg = new[4];
    foreach (first_msg[i]) begin
      first_msg[i] = byte'(8'ha0 + i);
    end

    build_one_msg_dgram(seq, first_msg, dgram);
    copy_msg(first_msg, expected);
    send_dgram(dgram);
    wait_for_payload_packets(1);
    expect_payload(expected);
    expect_one_msg_len(first_msg.size());
    expect_seq_sideband(seq, 16'd1);
    expect_status_counts(1, 0, 0, 0, 0, 0);
    expect_seq_guard_state(1'b0, seq + 64'd1, 64'd0, 64'd0);

    clear_scoreboard();

    dup_msg = new[4];
    foreach (dup_msg[i]) begin
      dup_msg[i] = byte'(8'hf0 + i);
    end

    build_one_msg_dgram(seq, dup_msg, dgram);
    send_dgram(dgram);
    wait_for_seq_pulses(1);
    wait_no_payload();

    expect_seq_sideband(seq, 16'd1);
    expect_status_counts(0, 1, 0, 0, 0, 0);
    expect_seq_guard_state(1'b0, seq + 64'd1, 64'd0, 64'd0);
  endtask

  task automatic test_gap_accepts_and_late_drops();
    byte unsigned msg0[];
    byte unsigned msg_gap[];
    byte unsigned msg_late[];
    byte unsigned dgram[];
    byte unsigned expected[];
    logic [MOLD_SEQ_W-1:0] base_seq;
    logic [MOLD_SEQ_W-1:0] gap_seq;
    logic [MOLD_SEQ_W-1:0] late_seq;

    $display("TEST gap packet is accepted/stale, then late packet is suppressed");

    base_seq = 64'd2000;
    gap_seq  = 64'd2005;
    late_seq = 64'd2001;

    msg0 = new[3];
    foreach (msg0[i]) begin
      msg0[i] = byte'(8'h30 + i);
    end

    build_one_msg_dgram(base_seq, msg0, dgram);
    send_dgram(dgram);
    wait_for_payload_packets(1);
    expect_seq_guard_state(1'b0, base_seq + 64'd1, 64'd0, 64'd0);

    clear_scoreboard();

    msg_gap = new[5];
    foreach (msg_gap[i]) begin
      msg_gap[i] = byte'(8'h60 + i);
    end

    build_one_msg_dgram(gap_seq, msg_gap, dgram);
    copy_msg(msg_gap, expected);
    send_dgram(dgram);
    wait_for_payload_packets(1);

    expect_payload(expected);
    expect_one_msg_len(msg_gap.size());
    expect_seq_sideband(gap_seq, 16'd1);
    expect_status_counts(0, 0, 1, 0, 0, 0);
    expect_seq_guard_state(1'b1, gap_seq + 64'd1, base_seq + 64'd1, gap_seq - 64'd1);

    clear_scoreboard();

    msg_late = new[2];
    msg_late[0] = 8'hee;
    msg_late[1] = 8'hef;

    build_one_msg_dgram(late_seq, msg_late, dgram);
    send_dgram(dgram);
    wait_for_seq_pulses(1);
    wait_no_payload();

    expect_seq_sideband(late_seq, 16'd1);
    expect_status_counts(0, 1, 0, 0, 0, 0);
    expect_seq_guard_state(1'b1, gap_seq + 64'd1, base_seq + 64'd1, gap_seq - 64'd1);
  endtask

  task automatic test_heartbeat();
    byte unsigned dgram[];
    logic [MOLD_SEQ_W-1:0] seq;

    $display("TEST MoldUDP64 heartbeat datagram");

    seq = 64'd3000;
    build_control_dgram(seq, MOLD_COUNT_HEARTBEAT, dgram);
    send_dgram(dgram);
    wait_for_seq_pulses(1);
    wait_no_payload();

    expect_seq_sideband(seq, MOLD_COUNT_HEARTBEAT);
    expect_status_counts(0, 0, 0, 1, 0, 0);
    expect_seq_guard_state(1'b0, seq, 64'd0, 64'd0);
  endtask

  task automatic test_heartbeat_gap();
    byte unsigned msg0[];
    byte unsigned dgram[];
    logic [MOLD_SEQ_W-1:0] base_seq;
    logic [MOLD_SEQ_W-1:0] heartbeat_seq;

    $display("TEST heartbeat can report a missing sequence range without payload output");

    base_seq      = 64'd4000;
    heartbeat_seq = 64'd4005;

    msg0 = new[4];
    foreach (msg0[i]) begin
      msg0[i] = byte'(8'h40 + i);
    end

    build_one_msg_dgram(base_seq, msg0, dgram);
    send_dgram(dgram);
    wait_for_payload_packets(1);
    expect_seq_guard_state(1'b0, base_seq + 64'd1, 64'd0, 64'd0);

    clear_scoreboard();

    build_control_dgram(heartbeat_seq, MOLD_COUNT_HEARTBEAT, dgram);
    send_dgram(dgram);
    wait_for_seq_pulses(1);
    wait_no_payload();

    expect_seq_sideband(heartbeat_seq, MOLD_COUNT_HEARTBEAT);
    expect_status_counts(0, 0, 1, 1, 0, 0);
    expect_seq_guard_state(1'b1, heartbeat_seq, base_seq + 64'd1, heartbeat_seq - 64'd1);
  endtask

  task automatic test_eos();
    byte unsigned dgram[];
    logic [MOLD_SEQ_W-1:0] seq;

    $display("TEST MoldUDP64 EOS datagram");

    seq = 64'd5000;
    build_control_dgram(seq, MOLD_COUNT_EOS, dgram);
    send_dgram(dgram);
    wait_for_seq_pulses(1);
    wait_no_payload();

    expect_seq_sideband(seq, MOLD_COUNT_EOS);
    expect_status_counts(0, 0, 0, 0, 1, 0);
    expect_seq_guard_state(1'b0, seq, 64'd0, 64'd0);
  endtask

  task automatic test_msg_len_backpressure();
    byte unsigned msg0[];
    byte unsigned dgram[];
    byte unsigned expected[];
    logic [MOLD_SEQ_W-1:0] seq;

    $display("TEST msg_len backpressure stalls payload emission");

    seq = 64'd6000;
    msg0 = new[4];
    foreach (msg0[i]) begin
      msg0[i] = byte'(8'hb0 + i);
    end
    copy_msg(msg0, expected);

    build_one_msg_dgram(seq, msg0, dgram);
    m_msg_len_ready_i <= 1'b0;

    fork
      send_dgram(dgram);
      begin
        wait (m_msg_len_valid_o == 1'b1);

        repeat (4) begin
          @(posedge clk);
          if (!m_msg_len_valid_o) begin
            $fatal(1, "msg_len_valid dropped while backpressured");
          end
          if (m_payload_tvalid_o) begin
            $fatal(1, "Payload was emitted before msg_len item was accepted");
          end
        end

        m_msg_len_ready_i <= 1'b1;
      end
    join

    wait_for_payload_packets(1);
    expect_payload(expected);
    expect_one_msg_len(msg0.size());
    expect_seq_sideband(seq, 16'd1);
    expect_status_counts(1, 0, 0, 0, 0, 0);
  endtask

  task automatic test_payload_backpressure();
    byte unsigned msg0[];
    byte unsigned dgram[];
    byte unsigned expected[];
    axis_data_t   saved_data;
    axis_keep_t   saved_keep;
    logic         saved_last;
    logic [MOLD_SEQ_W-1:0] seq;

    $display("TEST payload backpressure holds output beat stable");

    seq = 64'd7000;
    msg0 = new[12];
    foreach (msg0[i]) begin
      msg0[i] = byte'(8'hc0 + i);
    end
    copy_msg(msg0, expected);

    build_one_msg_dgram(seq, msg0, dgram);
    m_payload_tready_i <= 1'b0;

    fork
      send_dgram(dgram);
      begin
        wait (m_payload_tvalid_o == 1'b1);
        saved_data = m_payload_tdata_o;
        saved_keep = m_payload_tkeep_o;
        saved_last = m_payload_tlast_o;

        repeat (4) begin
          @(posedge clk);
          if (!m_payload_tvalid_o) begin
            $fatal(1, "payload_tvalid dropped while backpressured");
          end
          if ((m_payload_tdata_o !== saved_data) ||
              (m_payload_tkeep_o !== saved_keep) ||
              (m_payload_tlast_o !== saved_last)) begin
            $fatal(1, "Payload output changed while backpressured");
          end
          if (s_axis_tready_o) begin
            $fatal(1, "Input ready stayed high while payload output was backpressured");
          end
        end

        m_payload_tready_i <= 1'b1;
      end
    join

    wait_for_payload_packets(1);
    expect_payload(expected);
    expect_one_msg_len(msg0.size());
    expect_seq_sideband(seq, 16'd1);
    expect_status_counts(1, 0, 0, 0, 0, 0);
  endtask

  task automatic test_length_overrun_drop();
    byte unsigned dgram[];
    logic [MOLD_SEQ_W-1:0] seq;

    $display("TEST declared message length overrun is dropped");

    seq = 64'd8000;
    build_bad_len_dgram(seq, dgram);
    send_dgram(dgram);
    wait_for_drop(1);
    repeat (20) @(posedge clk);

    if ((rx_payload_packets != 0) || (rx_payload.size() != 0)) begin
      $fatal(1, "Bad length datagram produced payload output");
    end

    if (!last_drop_err[MOLD_ERR_LEN_OVERRUN]) begin
      $fatal(1, "Bad length did not raise MOLD_ERR_LEN_OVERRUN: err=0x%04x", last_drop_err);
    end
  endtask

  initial begin
    reset_dut();
    test_two_messages();

    reset_dut();
    test_duplicate_suppressed();

    reset_dut();
    test_gap_accepts_and_late_drops();

    reset_dut();
    test_heartbeat();

    reset_dut();
    test_heartbeat_gap();

    reset_dut();
    test_eos();

    reset_dut();
    test_msg_len_backpressure();

    reset_dut();
    test_payload_backpressure();

    reset_dut();
    test_length_overrun_drop();

    $display("mold_deframe_tb PASS");
    $finish;
  end

endmodule

`default_nettype wire
