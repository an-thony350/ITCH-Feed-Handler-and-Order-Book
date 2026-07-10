`timescale 1ns/1ps
`default_nettype none

module mold_seq_guard_tb;

  localparam int SEQ_W   = 64;
  localparam int COUNT_W = 16;

  logic               clk;
  logic               rst_n;
  logic               seq_valid_i;
  logic [SEQ_W-1:0]   seq_i;
  logic [COUNT_W-1:0] count_i;
  logic               clear_stale_i;

  logic               accept_packet_o;
  logic               drop_packet_o;
  logic               in_order_o;
  logic               duplicate_o;
  logic               gap_o;
  logic               heartbeat_o;
  logic               eos_o;
  logic               stale_o;
  logic [SEQ_W-1:0]   expected_seq_o;
  logic [SEQ_W-1:0]   gap_start_o;
  logic [SEQ_W-1:0]   gap_end_o;

  mold_seq_guard #(
    .SEQ_W   (SEQ_W),
    .COUNT_W (COUNT_W)
  ) dut (
    .clk             (clk),
    .rst_n           (rst_n),
    .seq_valid_i     (seq_valid_i),
    .seq_i           (seq_i),
    .count_i         (count_i),
    .clear_stale_i   (clear_stale_i),
    .accept_packet_o (accept_packet_o),
    .drop_packet_o   (drop_packet_o),
    .in_order_o      (in_order_o),
    .duplicate_o     (duplicate_o),
    .gap_o           (gap_o),
    .heartbeat_o     (heartbeat_o),
    .eos_o           (eos_o),
    .stale_o         (stale_o),
    .expected_seq_o  (expected_seq_o),
    .gap_start_o     (gap_start_o),
    .gap_end_o       (gap_end_o)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task automatic reset_dut();
    rst_n         <= 1'b0;
    seq_valid_i   <= 1'b0;
    seq_i         <= '0;
    count_i       <= '0;
    clear_stale_i <= 1'b0;

    repeat (6) @(posedge clk);
    rst_n <= 1'b1;
    repeat (2) @(posedge clk);
  endtask

  task automatic check_decision(
    input string              label,
    input logic               exp_accept,
    input logic               exp_drop,
    input logic               exp_in_order,
    input logic               exp_duplicate,
    input logic               exp_gap,
    input logic               exp_heartbeat,
    input logic               exp_eos
  );
    #1;

    if (accept_packet_o !== exp_accept) begin
      $fatal(1, "%s accept mismatch: got %0b expected %0b", label, accept_packet_o, exp_accept);
    end
    if (drop_packet_o !== exp_drop) begin
      $fatal(1, "%s drop mismatch: got %0b expected %0b", label, drop_packet_o, exp_drop);
    end
    if (in_order_o !== exp_in_order) begin
      $fatal(1, "%s in_order mismatch: got %0b expected %0b", label, in_order_o, exp_in_order);
    end
    if (duplicate_o !== exp_duplicate) begin
      $fatal(1, "%s duplicate mismatch: got %0b expected %0b", label, duplicate_o, exp_duplicate);
    end
    if (gap_o !== exp_gap) begin
      $fatal(1, "%s gap mismatch: got %0b expected %0b", label, gap_o, exp_gap);
    end
    if (heartbeat_o !== exp_heartbeat) begin
      $fatal(1, "%s heartbeat mismatch: got %0b expected %0b", label, heartbeat_o, exp_heartbeat);
    end
    if (eos_o !== exp_eos) begin
      $fatal(1, "%s eos mismatch: got %0b expected %0b", label, eos_o, exp_eos);
    end
  endtask

  task automatic drive_header(
    input logic [SEQ_W-1:0]   seq,
    input logic [COUNT_W-1:0] count
  );
    @(negedge clk);
    seq_i       = seq;
    count_i     = count;
    seq_valid_i = 1'b1;
  endtask

  task automatic finish_header();
    @(posedge clk);
    #1;
    seq_valid_i = 1'b0;
    seq_i       = '0;
    count_i     = '0;
    @(posedge clk);
  endtask

  task automatic expect_state(
    input string            label,
    input logic             exp_stale,
    input logic [SEQ_W-1:0] exp_expected_seq,
    input logic [SEQ_W-1:0] exp_gap_start,
    input logic [SEQ_W-1:0] exp_gap_end
  );
    #1;

    if (stale_o !== exp_stale) begin
      $fatal(1, "%s stale mismatch: got %0b expected %0b", label, stale_o, exp_stale);
    end
    if (expected_seq_o !== exp_expected_seq) begin
      $fatal(1, "%s expected_seq mismatch: got 0x%016x expected 0x%016x",
             label, expected_seq_o, exp_expected_seq);
    end
    if (gap_start_o !== exp_gap_start) begin
      $fatal(1, "%s gap_start mismatch: got 0x%016x expected 0x%016x",
             label, gap_start_o, exp_gap_start);
    end
    if (gap_end_o !== exp_gap_end) begin
      $fatal(1, "%s gap_end mismatch: got 0x%016x expected 0x%016x",
             label, gap_end_o, exp_gap_end);
    end
  endtask

  task automatic test_normal_duplicate_gap();
    $display("TEST seq_guard normal, duplicate, gap, and late handling");

    drive_header(64'd1, 16'd3);
    check_decision("first packet", 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
    finish_header();
    expect_state("after first packet", 1'b0, 64'd4, 64'd0, 64'd0);

    drive_header(64'd4, 16'd2);
    check_decision("in-order packet", 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
    finish_header();
    expect_state("after in-order packet", 1'b0, 64'd6, 64'd0, 64'd0);

    drive_header(64'd4, 16'd2);
    check_decision("duplicate packet", 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);
    finish_header();
    expect_state("after duplicate packet", 1'b0, 64'd6, 64'd0, 64'd0);

    drive_header(64'd10, 16'd1);
    check_decision("gap packet", 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
    finish_header();
    expect_state("after gap packet", 1'b1, 64'd11, 64'd6, 64'd9);

    drive_header(64'd6, 16'd4);
    check_decision("late packet after gap", 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);
    finish_header();
    expect_state("after late packet", 1'b1, 64'd11, 64'd6, 64'd9);
  endtask

  task automatic test_heartbeat_and_eos();
    $display("TEST seq_guard heartbeat and EOS handling");

    drive_header(64'd100, 16'd0);
    check_decision("first heartbeat", 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);
    finish_header();
    expect_state("after first heartbeat", 1'b0, 64'd100, 64'd0, 64'd0);

    drive_header(64'd105, 16'd0);
    check_decision("heartbeat reveals gap", 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0);
    finish_header();
    expect_state("after heartbeat gap", 1'b1, 64'd105, 64'd100, 64'd104);

    @(negedge clk);
    clear_stale_i = 1'b1;
    @(posedge clk);
    #1;
    clear_stale_i = 1'b0;
    expect_state("after clear stale", 1'b0, 64'd105, 64'd100, 64'd104);

    drive_header(64'd105, 16'hffff);
    check_decision("EOS", 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    finish_header();
    expect_state("after EOS", 1'b0, 64'd105, 64'd100, 64'd104);
  endtask

  initial begin
    reset_dut();
    test_normal_duplicate_gap();

    reset_dut();
    test_heartbeat_and_eos();

    $display("mold_seq_guard_tb PASS");
    $finish;
  end

endmodule

`default_nettype wire
