`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module ingress_top_tb;

  localparam logic [MOLD_SESSION_W-1:0] TEST_SESSION = 80'h49_54_43_48_54_45_53_54_30_31; // "ITCHTEST01"
  localparam logic [15:0] TEST_SRC_PORT = 16'd40000;
  localparam logic [15:0] TEST_DST_PORT = 16'd50000;

  logic       clk;
  logic       rst_n;

  axis_data_t s_frame_tdata_i;
  axis_keep_t s_frame_tkeep_i;
  logic       s_frame_tvalid_i;
  logic       s_frame_tlast_i;
  logic       s_frame_tready_o;

  axis_data_t m_itch_tdata_o;
  logic       m_itch_tvalid_o;
  logic       m_itch_tlast_o;
  logic       m_itch_tready_i;

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

  logic                      frame_drop_o;
  logic [FRAME_ERR_W-1:0]    frame_err_o;
  logic                      mold_drop_o;
  logic [MOLD_ERR_W-1:0]     mold_err_o;
  logic [REALIGN_ERR_W-1:0]  realign_err_o;

  byte unsigned rx_flat[$];
  byte unsigned rx_current[$];
  int unsigned  rx_message_lens[$];
  int unsigned  rx_msg_count;

  int unsigned seq_pulses;
  int unsigned heartbeat_pulses;
  int unsigned eos_pulses;
  int unsigned in_order_pulses;
  int unsigned duplicate_pulses;
  int unsigned gap_pulses;

  int unsigned frame_drop_pulses;
  int unsigned mold_drop_pulses;
  int unsigned realign_err_pulses;

  logic [MOLD_SESSION_W-1:0] last_session;
  logic [MOLD_SEQ_W-1:0]     last_seq;
  logic [MOLD_COUNT_W-1:0]   last_count;
  logic [MOLD_SEQ_W-1:0]     last_expected_next;
  logic [MOLD_SEQ_W-1:0]     last_gap_start;
  logic [MOLD_SEQ_W-1:0]     last_gap_end;
  logic [FRAME_ERR_W-1:0]    last_frame_err;
  logic [MOLD_ERR_W-1:0]     last_mold_err;
  logic [REALIGN_ERR_W-1:0]  last_realign_err;

  ingress_top #(
    .CHECK_DST_PORT    (1'b0),
    .EXPECTED_DST_PORT (16'd0)
  ) dut (
    .clk               (clk),
    .rst_n             (rst_n),

    .s_frame_tdata_i   (s_frame_tdata_i),
    .s_frame_tkeep_i   (s_frame_tkeep_i),
    .s_frame_tvalid_i  (s_frame_tvalid_i),
    .s_frame_tlast_i   (s_frame_tlast_i),
    .s_frame_tready_o  (s_frame_tready_o),

    .m_itch_tdata_o    (m_itch_tdata_o),
    .m_itch_tvalid_o   (m_itch_tvalid_o),
    .m_itch_tlast_o    (m_itch_tlast_o),
    .m_itch_tready_i   (m_itch_tready_i),

    .session_o         (session_o),
    .seq_o             (seq_o),
    .count_o           (count_o),
    .expected_next_o   (expected_next_o),
    .seq_valid_o       (seq_valid_o),
    .heartbeat_o       (heartbeat_o),
    .eos_o             (eos_o),
    .in_order_o        (in_order_o),
    .duplicate_o       (duplicate_o),
    .gap_o             (gap_o),
    .stale_o           (stale_o),
    .expected_seq_o    (expected_seq_o),
    .gap_start_o       (gap_start_o),
    .gap_end_o         (gap_end_o),

    .frame_drop_o      (frame_drop_o),
    .frame_err_o       (frame_err_o),
    .mold_drop_o       (mold_drop_o),
    .mold_err_o        (mold_err_o),
    .realign_err_o     (realign_err_o)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  always_ff @(posedge clk) begin
    if (rst_n && m_itch_tvalid_o && m_itch_tready_i) begin
      for (int lane = 0; lane < AXIS_KEEP_W; lane++) begin
        rx_current.push_back(m_itch_tdata_o[AXIS_DATA_W-1-(8*lane) -: 8]);
      end

      if (m_itch_tlast_o) begin
        rx_message_lens.push_back(rx_current.size());
        foreach (rx_current[i]) begin
          rx_flat.push_back(rx_current[i]);
        end
        rx_current.delete();
        rx_msg_count++;
      end
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
      last_gap_start <= gap_start_o;
      last_gap_end   <= gap_end_o;
    end

    if (rst_n && frame_drop_o) begin
      frame_drop_pulses++;
      last_frame_err <= frame_err_o;
    end

    if (rst_n && mold_drop_o) begin
      mold_drop_pulses++;
      last_mold_err <= mold_err_o;
    end

    if (rst_n && (realign_err_o != '0)) begin
      realign_err_pulses++;
      last_realign_err <= realign_err_o;
    end
  end

  task automatic clear_scoreboard();
    rx_flat.delete();
    rx_current.delete();
    rx_message_lens.delete();
    rx_msg_count = 0;

    seq_pulses         = 0;
    heartbeat_pulses   = 0;
    eos_pulses         = 0;
    in_order_pulses    = 0;
    duplicate_pulses   = 0;
    gap_pulses         = 0;

    frame_drop_pulses  = 0;
    mold_drop_pulses   = 0;
    realign_err_pulses = 0;

    last_session       = '0;
    last_seq           = '0;
    last_count         = '0;
    last_expected_next = '0;
    last_gap_start     = '0;
    last_gap_end       = '0;
    last_frame_err     = '0;
    last_mold_err      = '0;
    last_realign_err   = '0;
  endtask

  task automatic reset_dut();
    rst_n              <= 1'b0;
    s_frame_tdata_i    <= '0;
    s_frame_tkeep_i    <= '0;
    s_frame_tvalid_i   <= 1'b0;
    s_frame_tlast_i    <= 1'b0;
    m_itch_tready_i    <= 1'b1;
    clear_scoreboard();

    repeat (8) @(posedge clk);
    rst_n <= 1'b1;
    repeat (2) @(posedge clk);
  endtask

  function automatic int unsigned padded_len(input int unsigned len);
    padded_len = ((len + AXIS_KEEP_W - 1) / AXIS_KEEP_W) * AXIS_KEEP_W;
  endfunction

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

  task automatic build_payload(
    input  byte unsigned base,
    input  int unsigned  len,
    output byte unsigned payload[]
  );
    payload = new[len];
    foreach (payload[i]) begin
      payload[i] = byte'(base + i);
    end
  endtask

  task automatic build_one_msg_dgram(
    input  logic [MOLD_SEQ_W-1:0] seq,
    input  byte unsigned msg0[],
    output byte unsigned dgram[]
  );
    int unsigned idx;
    logic [15:0] msg0_len;

    msg0_len = msg0.size();
    dgram = new[MOLD_HDR_BYTES + 2 + msg0.size()];
    idx = 0;

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

    msg0_len = msg0.size();
    msg1_len = msg1.size();
    dgram = new[MOLD_HDR_BYTES + 2 + msg0.size() + 2 + msg1.size()];
    idx = 0;

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
    input  logic [MOLD_SEQ_W-1:0]   seq,
    input  logic [MOLD_COUNT_W-1:0] count,
    output byte unsigned dgram[]
  );
    int unsigned idx;

    dgram = new[MOLD_HDR_BYTES];
    idx = 0;

    write_session(dgram, idx, TEST_SESSION);
    write_u64_be(dgram, idx, seq);
    write_u16_be(dgram, idx, count);
  endtask

  task automatic build_eth_ipv4_udp_frame(
    input  byte unsigned dgram[],
    input  logic [15:0]  ethertype,
    output byte unsigned frame[]
  );
    int unsigned idx;
    logic [15:0] udp_len_v;
    logic [15:0] ip_total_len_v;

    udp_len_v       = UDP_HDR_BYTES + dgram.size();
    ip_total_len_v  = IPV4_MIN_HDR_BYTES + udp_len_v;
    frame           = new[L2_L4_HDR_BYTES + dgram.size()];
    idx             = 0;

    // Ethernet II: destination MAC, source MAC, EtherType.
    frame[idx] = 8'h01; idx++;
    frame[idx] = 8'h02; idx++;
    frame[idx] = 8'h03; idx++;
    frame[idx] = 8'h04; idx++;
    frame[idx] = 8'h05; idx++;
    frame[idx] = 8'h06; idx++;
    frame[idx] = 8'h0a; idx++;
    frame[idx] = 8'h0b; idx++;
    frame[idx] = 8'h0c; idx++;
    frame[idx] = 8'h0d; idx++;
    frame[idx] = 8'h0e; idx++;
    frame[idx] = 8'h0f; idx++;
    write_u16_be(frame, idx, ethertype);

    // IPv4, IHL=5, no fragmentation, protocol=UDP, checksum skipped as zero.
    frame[idx] = 8'h45; idx++;
    frame[idx] = 8'h00; idx++;
    write_u16_be(frame, idx, ip_total_len_v);
    write_u16_be(frame, idx, 16'h0001);
    write_u16_be(frame, idx, 16'h0000);
    frame[idx] = 8'd64; idx++;
    frame[idx] = IP_PROTO_UDP; idx++;
    write_u16_be(frame, idx, 16'h0000);
    frame[idx] = 8'h0a; idx++;
    frame[idx] = 8'h00; idx++;
    frame[idx] = 8'h00; idx++;
    frame[idx] = 8'h01; idx++;
    frame[idx] = 8'h0a; idx++;
    frame[idx] = 8'h00; idx++;
    frame[idx] = 8'h00; idx++;
    frame[idx] = 8'h02; idx++;

    // UDP. Checksum is zero because the RTL does not stall on checksum work.
    write_u16_be(frame, idx, TEST_SRC_PORT);
    write_u16_be(frame, idx, TEST_DST_PORT);
    write_u16_be(frame, idx, udp_len_v);
    write_u16_be(frame, idx, 16'h0000);

    foreach (dgram[i]) begin
      frame[idx] = dgram[i];
      idx++;
    end

    if (idx != frame.size()) begin
      $fatal(1, "Frame builder size mismatch: idx=%0d size=%0d", idx, frame.size());
    end
  endtask

  task automatic send_frame(input byte unsigned frame[]);
    int unsigned offset;
    axis_data_t  beat_data;
    axis_keep_t  beat_keep;
    int unsigned wait_cycles;

    offset = 0;

    while (offset < frame.size()) begin
      beat_data = '0;
      beat_keep = '0;

      for (int lane = 0; lane < AXIS_KEEP_W; lane++) begin
        if ((offset + lane) < frame.size()) begin
          beat_data[AXIS_DATA_W-1-(8*lane) -: 8] = frame[offset+lane];
          beat_keep[AXIS_KEEP_W-1-lane]          = 1'b1;
        end
      end

      s_frame_tdata_i  <= beat_data;
      s_frame_tkeep_i  <= beat_keep;
      s_frame_tlast_i  <= ((offset + AXIS_KEEP_W) >= frame.size());
      s_frame_tvalid_i <= 1'b1;

      wait_cycles = 0;
      do begin
        @(posedge clk);
        wait_cycles++;
        if (wait_cycles > 5000) begin
          $fatal(1, "Timed out waiting for s_frame_tready_o");
        end
      end while (!s_frame_tready_o);

      offset += AXIS_KEEP_W;
    end

    s_frame_tvalid_i <= 1'b0;
    s_frame_tlast_i  <= 1'b0;
    s_frame_tdata_i  <= '0;
    s_frame_tkeep_i  <= '0;
    @(posedge clk);
  endtask

  task automatic wait_for_msg_count(input int unsigned target_count);
    int unsigned cycles;

    cycles = 0;
    while ((rx_msg_count < target_count) && (cycles < 10000)) begin
      cycles++;
      @(posedge clk);
    end

    if (rx_msg_count < target_count) begin
      $fatal(1, "Timed out waiting for %0d ITCH message(s), saw %0d", target_count, rx_msg_count);
    end
  endtask

  task automatic expect_payload_at(
    input int unsigned  msg_idx,
    input byte unsigned expected[]
  );
    int unsigned offset;
    int unsigned expected_padded;

    if (msg_idx >= rx_message_lens.size()) begin
      $fatal(1, "Missing message index %0d, only captured %0d", msg_idx, rx_message_lens.size());
    end

    offset = 0;
    for (int i = 0; i < msg_idx; i++) begin
      offset += rx_message_lens[i];
    end

    expected_padded = padded_len(expected.size());

    if (rx_message_lens[msg_idx] != expected_padded) begin
      $fatal(1, "Message %0d padded length mismatch: got %0d expected %0d",
             msg_idx, rx_message_lens[msg_idx], expected_padded);
    end

    foreach (expected[i]) begin
      if (rx_flat[offset+i] !== expected[i]) begin
        $fatal(1, "Message %0d byte %0d mismatch: got 0x%02x expected 0x%02x",
               msg_idx, i, rx_flat[offset+i], expected[i]);
      end
    end

    for (int i = expected.size(); i < expected_padded; i++) begin
      if (rx_flat[offset+i] !== 8'h00) begin
        $fatal(1, "Message %0d padding byte %0d was non-zero: 0x%02x", msg_idx, i, rx_flat[offset+i]);
      end
    end
  endtask

  task automatic expect_no_errors();
    if ((frame_drop_pulses != 0) || (mold_drop_pulses != 0) || (realign_err_pulses != 0)) begin
      $fatal(1, "Unexpected errors: frame_drop=%0d err=0x%04x mold_drop=%0d err=0x%04x realign=%0d err=0x%04x",
             frame_drop_pulses, last_frame_err, mold_drop_pulses, last_mold_err,
             realign_err_pulses, last_realign_err);
    end
  endtask

  task automatic test_two_messages();
    byte unsigned msg0[];
    byte unsigned msg1[];
    byte unsigned dgram[];
    byte unsigned frame[];

    $display("TEST ingress_top recovers two messages from one Ethernet/MoldUDP64 frame");
    clear_scoreboard();

    build_payload(8'h41, 3, msg0);
    build_payload(8'h80, 12, msg1);
    build_two_msg_dgram(64'd100, msg0, msg1, dgram);
    build_eth_ipv4_udp_frame(dgram, ETHERTYPE_IPV4, frame);

    send_frame(frame);
    wait_for_msg_count(2);
    repeat (20) @(posedge clk);

    expect_payload_at(0, msg0);
    expect_payload_at(1, msg1);

    if (seq_pulses != 1) begin
      $fatal(1, "Expected 1 seq pulse, got %0d", seq_pulses);
    end
    if ((last_session !== TEST_SESSION) || (last_seq !== 64'd100) ||
        (last_count !== 16'd2) || (last_expected_next !== 64'd102)) begin
      $fatal(1, "Bad sideband: session=0x%020x seq=%0d count=%0d expected_next=%0d",
             last_session, last_seq, last_count, last_expected_next);
    end
    if ((in_order_pulses != 1) || (duplicate_pulses != 0) || (gap_pulses != 0) ||
        (heartbeat_pulses != 0) || (eos_pulses != 0)) begin
      $fatal(1, "Unexpected status pulses: in_order=%0d duplicate=%0d gap=%0d heartbeat=%0d eos=%0d",
             in_order_pulses, duplicate_pulses, gap_pulses, heartbeat_pulses, eos_pulses);
    end

    expect_no_errors();
  endtask

  task automatic test_duplicate_suppressed();
    byte unsigned msg0[];
    byte unsigned dgram[];
    byte unsigned frame[];

    $display("TEST ingress_top suppresses duplicate A/B MoldUDP64 packet");
    clear_scoreboard();

    build_payload(8'ha0, 5, msg0);
    build_one_msg_dgram(64'd200, msg0, dgram);
    build_eth_ipv4_udp_frame(dgram, ETHERTYPE_IPV4, frame);

    send_frame(frame);
    wait_for_msg_count(1);
    send_frame(frame);
    repeat (120) @(posedge clk);

    if (rx_msg_count != 1) begin
      $fatal(1, "Duplicate packet emitted payload: captured %0d messages", rx_msg_count);
    end
    expect_payload_at(0, msg0);

    if ((seq_pulses != 2) || (in_order_pulses != 1) || (duplicate_pulses != 1) || (gap_pulses != 0)) begin
      $fatal(1, "Bad duplicate status: seq=%0d in_order=%0d duplicate=%0d gap=%0d",
             seq_pulses, in_order_pulses, duplicate_pulses, gap_pulses);
    end
    if (expected_seq_o !== 64'd201) begin
      $fatal(1, "expected_seq changed after duplicate: got %0d expected 201", expected_seq_o);
    end

    expect_no_errors();
  endtask

  task automatic test_gap_accepts_then_late_suppressed();
    byte unsigned msg0[];
    byte unsigned msg1[];
    byte unsigned late_msg[];
    byte unsigned dgram0[];
    byte unsigned dgram1[];
    byte unsigned late_dgram[];
    byte unsigned frame0[];
    byte unsigned frame1[];
    byte unsigned late_frame[];

    $display("TEST ingress_top accepts post-gap packet, marks stale, then suppresses late packet");
    clear_scoreboard();

    build_payload(8'hb0, 4, msg0);
    build_payload(8'hc0, 6, msg1);
    build_payload(8'hd0, 4, late_msg);

    build_one_msg_dgram(64'd300, msg0, dgram0);
    build_one_msg_dgram(64'd305, msg1, dgram1);
    build_one_msg_dgram(64'd301, late_msg, late_dgram);

    build_eth_ipv4_udp_frame(dgram0, ETHERTYPE_IPV4, frame0);
    build_eth_ipv4_udp_frame(dgram1, ETHERTYPE_IPV4, frame1);
    build_eth_ipv4_udp_frame(late_dgram, ETHERTYPE_IPV4, late_frame);

    send_frame(frame0);
    wait_for_msg_count(1);
    send_frame(frame1);
    wait_for_msg_count(2);
    send_frame(late_frame);
    repeat (120) @(posedge clk);

    if (rx_msg_count != 2) begin
      $fatal(1, "Expected only first and post-gap payloads, captured %0d messages", rx_msg_count);
    end
    expect_payload_at(0, msg0);
    expect_payload_at(1, msg1);

    if ((seq_pulses != 3) || (in_order_pulses != 1) || (gap_pulses != 1) || (duplicate_pulses != 1)) begin
      $fatal(1, "Bad gap/late status: seq=%0d in_order=%0d gap=%0d duplicate=%0d",
             seq_pulses, in_order_pulses, gap_pulses, duplicate_pulses);
    end
    if (!stale_o) begin
      $fatal(1, "stale_o was not sticky after gap");
    end
    if ((last_gap_start !== 64'd301) || (last_gap_end !== 64'd304) || (expected_seq_o !== 64'd306)) begin
      $fatal(1, "Bad gap range/state: start=%0d end=%0d expected_seq=%0d",
             last_gap_start, last_gap_end, expected_seq_o);
    end

    expect_no_errors();
  endtask

  task automatic test_heartbeat_and_eos_status_only();
    byte unsigned heartbeat_dgram[];
    byte unsigned eos_dgram[];
    byte unsigned heartbeat_frame[];
    byte unsigned eos_frame[];

    $display("TEST ingress_top heartbeat and EOS are status-only");
    clear_scoreboard();

    build_control_dgram(64'd500, MOLD_COUNT_HEARTBEAT, heartbeat_dgram);
    build_control_dgram(64'd500, MOLD_COUNT_EOS, eos_dgram);
    build_eth_ipv4_udp_frame(heartbeat_dgram, ETHERTYPE_IPV4, heartbeat_frame);
    build_eth_ipv4_udp_frame(eos_dgram, ETHERTYPE_IPV4, eos_frame);

    send_frame(heartbeat_frame);
    repeat (40) @(posedge clk);
    send_frame(eos_frame);
    repeat (80) @(posedge clk);

    if (rx_msg_count != 0) begin
      $fatal(1, "Heartbeat/EOS emitted %0d payload message(s)", rx_msg_count);
    end
    if ((seq_pulses != 2) || (heartbeat_pulses != 1) || (eos_pulses != 1) ||
        (gap_pulses != 0) || (duplicate_pulses != 0)) begin
      $fatal(1, "Bad heartbeat/EOS status: seq=%0d heartbeat=%0d eos=%0d gap=%0d duplicate=%0d",
             seq_pulses, heartbeat_pulses, eos_pulses, gap_pulses, duplicate_pulses);
    end
    if (expected_seq_o !== 64'd500) begin
      $fatal(1, "Heartbeat/EOS expected_seq mismatch: got %0d expected 500", expected_seq_o);
    end

    expect_no_errors();
  endtask

  task automatic test_bad_ethertype_dropped();
    byte unsigned msg0[];
    byte unsigned dgram[];
    byte unsigned frame[];

    $display("TEST ingress_top drops non-IPv4 Ethernet frame before MoldUDP64/realign");
    clear_scoreboard();

    build_payload(8'he0, 4, msg0);
    build_one_msg_dgram(64'd900, msg0, dgram);
    build_eth_ipv4_udp_frame(dgram, 16'h86dd, frame);

    send_frame(frame);
    repeat (120) @(posedge clk);

    if (rx_msg_count != 0) begin
      $fatal(1, "Bad EtherType frame emitted %0d payload message(s)", rx_msg_count);
    end
    if (seq_pulses != 0) begin
      $fatal(1, "Bad EtherType frame reached mold_deframe: seq_pulses=%0d", seq_pulses);
    end
    if (frame_drop_pulses == 0) begin
      $fatal(1, "Bad EtherType did not raise frame_drop_o");
    end
    if (!last_frame_err[FRAME_ERR_BAD_ETHERTYPE]) begin
      $fatal(1, "Bad EtherType did not set FRAME_ERR_BAD_ETHERTYPE: err=0x%04x", last_frame_err);
    end
    if ((mold_drop_pulses != 0) || (realign_err_pulses != 0)) begin
      $fatal(1, "Bad EtherType should not reach mold/realign: mold=%0d realign=%0d",
             mold_drop_pulses, realign_err_pulses);
    end
  endtask

  initial begin
    reset_dut();
    test_two_messages();

    reset_dut();
    test_duplicate_suppressed();

    reset_dut();
    test_gap_accepts_then_late_suppressed();

    reset_dut();
    test_heartbeat_and_eos_status_only();

    reset_dut();
    test_bad_ethertype_dropped();

    $display("ingress_top_tb PASS");
    $finish;
  end

endmodule

`default_nettype wire
