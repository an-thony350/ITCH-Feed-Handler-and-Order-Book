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

  logic                      mold_drop_o;
  logic [MOLD_ERR_W-1:0]     mold_err_o;

  byte unsigned rx_payload[$];
  int unsigned  rx_payload_packets;
  int unsigned  msg_lens[$];

  int unsigned seq_pulses;
  int unsigned heartbeat_pulses;
  int unsigned eos_pulses;
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
    input  byte unsigned msg0[],
    output byte unsigned dgram[]
  );
    int unsigned idx;
    logic [15:0] msg0_len;

    dgram = new[MOLD_HDR_BYTES + 2 + msg0.size()];
    idx = 0;
    msg0_len = msg0.size();

    write_session(dgram, idx, TEST_SESSION);
    write_u64_be(dgram, idx, TEST_SEQ);
    write_u16_be(dgram, idx, 16'd1);
    write_u16_be(dgram, idx, msg0_len);

    foreach (msg0[i]) begin
      dgram[idx] = msg0[i];
      idx++;
    end
  endtask

  task automatic build_two_msg_dgram(
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
    write_u64_be(dgram, idx, TEST_SEQ);
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
    input  logic [15:0] count,
    output byte unsigned dgram[]
  );
    int unsigned idx;

    dgram = new[MOLD_HDR_BYTES];
    idx = 0;

    write_session(dgram, idx, TEST_SESSION);
    write_u64_be(dgram, idx, TEST_SEQ);
    write_u16_be(dgram, idx, count);
  endtask

  task automatic build_bad_len_dgram(output byte unsigned dgram[]);
    int unsigned idx;

    dgram = new[MOLD_HDR_BYTES + 2 + 3];
    idx = 0;

    write_session(dgram, idx, TEST_SESSION);
    write_u64_be(dgram, idx, TEST_SEQ);
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
    while ((rx_payload_packets < target_packets) && (cycles < 2000)) begin
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

  task automatic expect_seq_sideband(input logic [15:0] expected_count);
    if (seq_pulses != 1) begin
      $fatal(1, "Expected exactly one seq_valid pulse, got %0d", seq_pulses);
    end

    if (last_session !== TEST_SESSION) begin
      $fatal(1, "Session mismatch: got 0x%020x expected 0x%020x", last_session, TEST_SESSION);
    end

    if (last_seq !== TEST_SEQ) begin
      $fatal(1, "Sequence mismatch: got 0x%016x expected 0x%016x", last_seq, TEST_SEQ);
    end

    if (last_count !== expected_count) begin
      $fatal(1, "Count mismatch: got 0x%04x expected 0x%04x", last_count, expected_count);
    end

    if (last_expected_next !== (TEST_SEQ + expected_count)) begin
      $fatal(1, "expected_next mismatch: got 0x%016x expected 0x%016x",
             last_expected_next, TEST_SEQ + expected_count);
    end
  endtask

  task automatic test_two_messages();
    byte unsigned msg0[];
    byte unsigned msg1[];
    byte unsigned dgram[];
    byte unsigned expected[];

    $display("TEST MoldUDP64 datagram with two ITCH messages");
    clear_scoreboard();

    msg0 = new[3];
    msg0[0] = 8'h41;
    msg0[1] = 8'h01;
    msg0[2] = 8'h02;

    msg1 = new[12];
    foreach (msg1[i]) begin
      msg1[i] = byte'(8'h80 + i);
    end

    build_two_msg_dgram(msg0, msg1, dgram);
    concat_two(msg0, msg1, expected);

    send_dgram(dgram);
    wait_for_payload_packets(1);

    expect_payload(expected);
    expect_two_msg_lens(msg0.size(), msg1.size());
    expect_seq_sideband(16'd2);

    if ((heartbeat_pulses != 0) || (eos_pulses != 0) || (drop_pulses != 0)) begin
      $fatal(1, "Unexpected status on valid two-message datagram: heartbeat=%0d eos=%0d drop=%0d err=0x%04x",
             heartbeat_pulses, eos_pulses, drop_pulses, last_drop_err);
    end
  endtask

  task automatic test_heartbeat();
    byte unsigned dgram[];

    $display("TEST MoldUDP64 heartbeat datagram");
    clear_scoreboard();

    build_control_dgram(MOLD_COUNT_HEARTBEAT, dgram);
    send_dgram(dgram);
    wait_for_seq_pulses(1);
    repeat (20) @(posedge clk);

    expect_seq_sideband(MOLD_COUNT_HEARTBEAT);

    if (heartbeat_pulses != 1) begin
      $fatal(1, "Expected one heartbeat pulse, got %0d", heartbeat_pulses);
    end

    if ((eos_pulses != 0) || (rx_payload_packets != 0) || (rx_payload.size() != 0) ||
        (msg_lens.size() != 0) || (drop_pulses != 0)) begin
      $fatal(1, "Heartbeat produced unexpected output/status");
    end
  endtask

  task automatic test_eos();
    byte unsigned dgram[];

    $display("TEST MoldUDP64 EOS datagram");
    clear_scoreboard();

    build_control_dgram(MOLD_COUNT_EOS, dgram);
    send_dgram(dgram);
    wait_for_seq_pulses(1);
    repeat (20) @(posedge clk);

    expect_seq_sideband(MOLD_COUNT_EOS);

    if (eos_pulses != 1) begin
      $fatal(1, "Expected one eos pulse, got %0d", eos_pulses);
    end

    if ((heartbeat_pulses != 0) || (rx_payload_packets != 0) || (rx_payload.size() != 0) ||
        (msg_lens.size() != 0) || (drop_pulses != 0)) begin
      $fatal(1, "EOS produced unexpected output/status");
    end
  endtask

  task automatic test_msg_len_backpressure();
    byte unsigned msg0[];
    byte unsigned dgram[];
    byte unsigned expected[];

    $display("TEST msg_len backpressure stalls payload emission");
    clear_scoreboard();

    msg0 = new[4];
    foreach (msg0[i]) begin
      msg0[i] = byte'(8'hb0 + i);
    end
    expected = new[msg0.size()];
    foreach (msg0[i]) begin
      expected[i] = msg0[i];
    end

    build_one_msg_dgram(msg0, dgram);
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
    expect_seq_sideband(16'd1);
  endtask

  task automatic test_payload_backpressure();
    byte unsigned msg0[];
    byte unsigned dgram[];
    byte unsigned expected[];
    axis_data_t   saved_data;
    axis_keep_t   saved_keep;
    logic         saved_last;

    $display("TEST payload backpressure holds output beat stable");
    clear_scoreboard();

    msg0 = new[12];
    foreach (msg0[i]) begin
      msg0[i] = byte'(8'hc0 + i);
    end
    expected = new[msg0.size()];
    foreach (msg0[i]) begin
      expected[i] = msg0[i];
    end

    build_one_msg_dgram(msg0, dgram);
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
    expect_seq_sideband(16'd1);
  endtask

  task automatic test_length_overrun_drop();
    byte unsigned dgram[];

    $display("TEST declared message length overrun is dropped");
    clear_scoreboard();

    build_bad_len_dgram(dgram);
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
    test_heartbeat();
    test_eos();
    test_msg_len_backpressure();
    test_payload_backpressure();
    test_length_overrun_drop();

    $display("mold_deframe_tb PASS");
    $finish;
  end

endmodule

`default_nettype wire
