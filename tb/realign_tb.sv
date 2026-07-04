`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module realign_tb;

  logic       clk;
  logic       rst_n;

  axis_data_t s_payload_tdata_i;
  axis_keep_t s_payload_tkeep_i;
  logic       s_payload_tvalid_i;
  logic       s_payload_tlast_i;
  logic       s_payload_tready_o;

  logic [MOLD_MSG_LEN_W-1:0] s_msg_len_i;
  logic                      s_msg_len_valid_i;
  logic                      s_msg_len_ready_o;

  axis_data_t m_axis_tdata_o;
  logic       m_axis_tvalid_o;
  logic       m_axis_tlast_o;
  logic       m_axis_tready_i;

  logic [REALIGN_ERR_W-1:0] realign_err_o;

  localparam int RX_DEPTH = 64;

  axis_data_t rx_data [RX_DEPTH];
  logic       rx_last [RX_DEPTH];
  int unsigned rx_beats;
  int unsigned rx_packets;

  int unsigned err_pulses;
  logic [REALIGN_ERR_W-1:0] last_err;

  realign dut (
    .clk                 (clk),
    .rst_n               (rst_n),

    .s_payload_tdata_i   (s_payload_tdata_i),
    .s_payload_tkeep_i   (s_payload_tkeep_i),
    .s_payload_tvalid_i  (s_payload_tvalid_i),
    .s_payload_tlast_i   (s_payload_tlast_i),
    .s_payload_tready_o  (s_payload_tready_o),

    .s_msg_len_i         (s_msg_len_i),
    .s_msg_len_valid_i   (s_msg_len_valid_i),
    .s_msg_len_ready_o   (s_msg_len_ready_o),

    .m_axis_tdata_o      (m_axis_tdata_o),
    .m_axis_tvalid_o     (m_axis_tvalid_o),
    .m_axis_tlast_o      (m_axis_tlast_o),
    .m_axis_tready_i     (m_axis_tready_i),

    .realign_err_o       (realign_err_o)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  always @(posedge clk) begin
    if (rst_n && m_axis_tvalid_o && m_axis_tready_i) begin
      if (rx_beats >= RX_DEPTH) begin
        $fatal(1, "Scoreboard overflow: increase RX_DEPTH");
      end

      rx_data[rx_beats] = m_axis_tdata_o;
      rx_last[rx_beats] = m_axis_tlast_o;
      rx_beats = rx_beats + 1;

      if (m_axis_tlast_o) begin
        rx_packets = rx_packets + 1;
      end
    end

    if (rst_n && (realign_err_o != '0)) begin
      err_pulses = err_pulses + 1;
      last_err   = realign_err_o;
    end
  end

  task automatic clear_scoreboard();
    rx_beats   = 0;
    rx_packets = 0;
    err_pulses = 0;
    last_err   = '0;
  endtask

  task automatic reset_dut();
    rst_n               <= 1'b0;
    s_payload_tdata_i   <= '0;
    s_payload_tkeep_i   <= '0;
    s_payload_tvalid_i  <= 1'b0;
    s_payload_tlast_i   <= 1'b0;
    s_msg_len_i         <= '0;
    s_msg_len_valid_i   <= 1'b0;
    m_axis_tready_i     <= 1'b1;
    clear_scoreboard();

    repeat (8) @(posedge clk);
    rst_n <= 1'b1;
    repeat (4) @(posedge clk);
  endtask

  task automatic send_len(input logic [MOLD_MSG_LEN_W-1:0] len);
    @(posedge clk);
    s_msg_len_i       <= len;
    s_msg_len_valid_i <= 1'b1;

    do begin
      @(posedge clk);
    end while (!s_msg_len_ready_o);

    s_msg_len_valid_i <= 1'b0;
    s_msg_len_i       <= '0;
  endtask

  task automatic send_payload_beat(
    input axis_data_t data,
    input axis_keep_t keep,
    input logic       last
  );
    @(posedge clk);
    s_payload_tdata_i  <= data;
    s_payload_tkeep_i  <= keep;
    s_payload_tlast_i  <= last;
    s_payload_tvalid_i <= 1'b1;

    do begin
      @(posedge clk);
    end while (!s_payload_tready_o);

    s_payload_tvalid_i <= 1'b0;
    s_payload_tlast_i  <= 1'b0;
    s_payload_tkeep_i  <= '0;
    s_payload_tdata_i  <= '0;
  endtask

  task automatic wait_for_beats(input int unsigned want_beats);
    int unsigned timeout;

    timeout = 0;
    while ((rx_beats < want_beats) && (timeout < 2000)) begin
      @(posedge clk);
      timeout++;
    end

    if (rx_beats < want_beats) begin
      $fatal(1, "Timed out waiting for %0d output beats, saw %0d", want_beats, rx_beats);
    end
  endtask

  task automatic wait_for_packets(input int unsigned want_packets);
    int unsigned timeout;

    timeout = 0;
    while ((rx_packets < want_packets) && (timeout < 2000)) begin
      @(posedge clk);
      timeout++;
    end

    if (rx_packets < want_packets) begin
      $fatal(1, "Timed out waiting for %0d output packets, saw %0d", want_packets, rx_packets);
    end
  endtask

  task automatic expect_beat(
    input int unsigned beat_idx,
    input axis_data_t expected_data,
    input logic       expected_last
  );
    if (beat_idx >= rx_beats) begin
      $fatal(1, "Missing output beat %0d", beat_idx);
    end

    if (rx_data[beat_idx] !== expected_data) begin
      $fatal(1, "Beat %0d data mismatch: got %016h expected %016h",
             beat_idx, rx_data[beat_idx], expected_data);
    end

    if (rx_last[beat_idx] !== expected_last) begin
      $fatal(1, "Beat %0d tlast mismatch: got %0b expected %0b",
             beat_idx, rx_last[beat_idx], expected_last);
    end
  endtask

  task automatic wait_for_error(input int unsigned err_bit);
    int unsigned timeout;

    timeout = 0;
    while ((err_pulses == 0) && (timeout < 2000)) begin
      @(posedge clk);
      timeout++;
    end

    if (err_pulses == 0) begin
      $fatal(1, "Timed out waiting for realign error bit %0d", err_bit);
    end

    if (!last_err[err_bit]) begin
      $fatal(1, "Wrong realign error: got %04h, expected bit %0d", last_err, err_bit);
    end
  endtask

  task automatic expect_no_error();
    if (err_pulses != 0) begin
      $fatal(1, "Unexpected realign error: got %04h", last_err);
    end
  endtask

  task automatic test_single_short_message();
    $display("TEST single short message");
    clear_scoreboard();

    send_len(16'd5);
    send_payload_beat(64'h41_01_02_03_04_00_00_00, 8'b1111_1000, 1'b1);

    wait_for_packets(1);
    wait_for_beats(1);
    expect_beat(0, 64'h41_01_02_03_04_00_00_00, 1'b1);
    expect_no_error();
  endtask

  task automatic test_multibeat_message();
    $display("TEST one message spanning two payload beats");
    clear_scoreboard();

    send_len(16'd10);
    send_payload_beat(64'h10_11_12_13_14_15_16_17, 8'hff,       1'b0);
    send_payload_beat(64'h18_19_00_00_00_00_00_00, 8'b1100_0000, 1'b1);

    wait_for_packets(1);
    wait_for_beats(2);
    expect_beat(0, 64'h10_11_12_13_14_15_16_17, 1'b0);
    expect_beat(1, 64'h18_19_00_00_00_00_00_00, 1'b1);
    expect_no_error();
  endtask

  task automatic test_two_messages_one_payload_beat();
    $display("TEST two messages packed into one payload beat");
    clear_scoreboard();

    send_len(16'd3);
    send_len(16'd4);
    send_payload_beat(64'hAA_BB_CC_DD_EE_FF_99_00, 8'b1111_1110, 1'b1);

    wait_for_packets(2);
    wait_for_beats(2);
    expect_beat(0, 64'hAA_BB_CC_00_00_00_00_00, 1'b1);
    expect_beat(1, 64'hDD_EE_FF_99_00_00_00_00, 1'b1);
    expect_no_error();
  endtask

  task automatic test_straddled_boundary();
    $display("TEST message boundary straddles payload beats");
    clear_scoreboard();

    // AXI-Stream payload beats must be contiguous: all non-final beats use
    // tkeep = 8'hff. The message boundary is still unaligned because message
    // 1 ends after two bytes of the second payload beat, and message 2 starts
    // immediately after it in the same beat. The second message is 3 bytes
    // long because only three valid payload bytes remain in this datagram.
    send_len(16'd10);
    send_len(16'd3);
    send_payload_beat(64'h01_02_03_04_05_06_07_08, 8'hff,       1'b0);
    send_payload_beat(64'h09_0A_0B_0C_0D_00_00_00, 8'b1111_1000, 1'b1);

    wait_for_packets(2);
    wait_for_beats(3);
    expect_beat(0, 64'h01_02_03_04_05_06_07_08, 1'b0);
    expect_beat(1, 64'h09_0A_00_00_00_00_00_00, 1'b1);
    expect_beat(2, 64'h0B_0C_0D_00_00_00_00_00, 1'b1);
    expect_no_error();
  endtask

  task automatic test_output_backpressure();
    axis_data_t held_data;
    logic       held_last;

    $display("TEST output backpressure holds beat stable");
    clear_scoreboard();

    m_axis_tready_i <= 1'b0;
    send_len(16'd8);
    send_payload_beat(64'h80_81_82_83_84_85_86_87, 8'hff, 1'b1);

    while (!m_axis_tvalid_o) begin
      @(posedge clk);
    end

    held_data = m_axis_tdata_o;
    held_last = m_axis_tlast_o;

    repeat (5) begin
      @(posedge clk);
      if (!m_axis_tvalid_o) begin
        $fatal(1, "Output valid dropped under backpressure");
      end
      if ((m_axis_tdata_o !== held_data) || (m_axis_tlast_o !== held_last)) begin
        $fatal(1, "Output beat changed under backpressure");
      end
    end

    m_axis_tready_i <= 1'b1;
    wait_for_packets(1);
    wait_for_beats(1);
    expect_beat(0, 64'h80_81_82_83_84_85_86_87, 1'b1);
    expect_no_error();
  endtask

  task automatic test_zero_length_error();
    $display("TEST zero message length error");
    clear_scoreboard();

    send_len(16'd0);
    wait_for_error(REALIGN_ERR_LEN_ZERO);
  endtask

  initial begin
    reset_dut();

    test_single_short_message();
    test_multibeat_message();
    test_two_messages_one_payload_beat();
    test_straddled_boundary();
    test_output_backpressure();
    test_zero_length_error();

    $display("realign_tb PASS");
    $finish;
  end

endmodule

`default_nettype wire
