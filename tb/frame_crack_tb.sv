`timescale 1ns/1ps
`default_nettype none

import hdl_header::*;

module frame_crack_tb;

  localparam logic [15:0] EXPECTED_PORT = 16'd5000;

  logic       clk;
  logic       rst_n;

  axis_data_t s_axis_tdata_i;
  axis_keep_t s_axis_tkeep_i;
  logic       s_axis_tvalid_i;
  logic       s_axis_tlast_i;
  logic       s_axis_tready_o;

  axis_data_t m_axis_tdata_o;
  axis_keep_t m_axis_tkeep_o;
  logic       m_axis_tvalid_o;
  logic       m_axis_tlast_o;
  logic       m_axis_tready_i;

  logic [DGRAM_LEN_W-1:0] m_dgram_len_o;
  logic                   m_dgram_start_o;
  logic                   frame_drop_o;
  logic [FRAME_ERR_W-1:0] frame_err_o;

  byte unsigned rx_bytes[$];
  int unsigned  rx_packets;
  int unsigned  start_pulses;
  logic [DGRAM_LEN_W-1:0] last_start_len;
  int unsigned  drop_pulses;
  logic [FRAME_ERR_W-1:0] last_drop_err;

  frame_crack #(
    .CHECK_DST_PORT    (1'b1),
    .EXPECTED_DST_PORT (EXPECTED_PORT)
  ) dut (
    .clk              (clk),
    .rst_n            (rst_n),

    .s_axis_tdata_i   (s_axis_tdata_i),
    .s_axis_tkeep_i   (s_axis_tkeep_i),
    .s_axis_tvalid_i  (s_axis_tvalid_i),
    .s_axis_tlast_i   (s_axis_tlast_i),
    .s_axis_tready_o  (s_axis_tready_o),

    .m_axis_tdata_o   (m_axis_tdata_o),
    .m_axis_tkeep_o   (m_axis_tkeep_o),
    .m_axis_tvalid_o  (m_axis_tvalid_o),
    .m_axis_tlast_o   (m_axis_tlast_o),
    .m_axis_tready_i  (m_axis_tready_i),

    .m_dgram_len_o    (m_dgram_len_o),
    .m_dgram_start_o  (m_dgram_start_o),

    .frame_drop_o     (frame_drop_o),
    .frame_err_o      (frame_err_o)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  always_ff @(posedge clk) begin
    if (rst_n && m_axis_tvalid_o && m_axis_tready_i) begin
      for (int lane = 0; lane < AXIS_KEEP_W; lane++) begin
        if (m_axis_tkeep_o[AXIS_KEEP_W-1-lane]) begin
          rx_bytes.push_back(m_axis_tdata_o[AXIS_DATA_W-1-(8*lane) -: 8]);
        end
      end

      if (m_dgram_start_o) begin
        start_pulses++;
        last_start_len <= m_dgram_len_o;
      end

      if (m_axis_tlast_o) begin
        rx_packets++;
      end
    end

    if (rst_n && frame_drop_o) begin
      drop_pulses++;
      last_drop_err <= frame_err_o;
    end
  end

  task automatic clear_scoreboard();
    rx_bytes.delete();
    rx_packets    = 0;
    start_pulses  = 0;
    last_start_len = '0;
    drop_pulses   = 0;
    last_drop_err = '0;
  endtask

  task automatic reset_dut();
    rst_n            <= 1'b0;
    s_axis_tdata_i   <= '0;
    s_axis_tkeep_i   <= '0;
    s_axis_tvalid_i  <= 1'b0;
    s_axis_tlast_i   <= 1'b0;
    m_axis_tready_i  <= 1'b1;
    clear_scoreboard();

    repeat (8) @(posedge clk);
    rst_n <= 1'b1;
    repeat (2) @(posedge clk);
  endtask

  task automatic build_frame(
    input  byte unsigned payload[],
    input  logic [15:0]  ethertype,
    input  logic [3:0]   ip_ihl,
    input  logic [15:0]  ip_flags_frag,
    input  logic [7:0]   ip_protocol,
    input  logic [15:0]  udp_dst_port,
    output byte unsigned frame[]
  );
    int unsigned payload_len;
    int unsigned frame_len;
    logic [15:0] ip_total_len;
    logic [15:0] udp_len;

    payload_len  = payload.size();
    frame_len    = L2_L4_HDR_BYTES + payload_len;
    ip_total_len = IPV4_MIN_HDR_BYTES + UDP_HDR_BYTES + payload_len;
    udp_len      = UDP_HDR_BYTES + payload_len;

    frame = new[frame_len];
    foreach (frame[i]) begin
      frame[i] = 8'h00;
    end

    // Ethernet II header.
    frame[0]  = 8'hda;
    frame[1]  = 8'h02;
    frame[2]  = 8'h03;
    frame[3]  = 8'h04;
    frame[4]  = 8'h05;
    frame[5]  = 8'h06;
    frame[6]  = 8'h5a;
    frame[7]  = 8'h07;
    frame[8]  = 8'h08;
    frame[9]  = 8'h09;
    frame[10] = 8'h0a;
    frame[11] = 8'h0b;
    frame[12] = ethertype[15:8];
    frame[13] = ethertype[7:0];

    // IPv4 header, IHL=5 by default. Checksums are deliberately not validated.
    frame[14] = {4'd4, ip_ihl};
    frame[15] = 8'h00;
    frame[16] = ip_total_len[15:8];
    frame[17] = ip_total_len[7:0];
    frame[18] = 8'h12;
    frame[19] = 8'h34;
    frame[20] = ip_flags_frag[15:8];
    frame[21] = ip_flags_frag[7:0];
    frame[22] = 8'h40;
    frame[23] = ip_protocol;
    frame[24] = 8'h00;
    frame[25] = 8'h00;
    frame[26] = 8'h0a;
    frame[27] = 8'h00;
    frame[28] = 8'h00;
    frame[29] = 8'h01;
    frame[30] = 8'h0a;
    frame[31] = 8'h00;
    frame[32] = 8'h00;
    frame[33] = 8'h02;

    // UDP header.
    frame[34] = 8'h13;
    frame[35] = 8'h88; // source port 5000, arbitrary for this DUT
    frame[36] = udp_dst_port[15:8];
    frame[37] = udp_dst_port[7:0];
    frame[38] = udp_len[15:8];
    frame[39] = udp_len[7:0];
    frame[40] = 8'h00;
    frame[41] = 8'h00;

    foreach (payload[i]) begin
      frame[L2_L4_HDR_BYTES+i] = payload[i];
    end
  endtask

  task automatic send_frame(input byte unsigned frame[]);
    int unsigned offset;
    axis_data_t  beat_data;
    axis_keep_t  beat_keep;

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

      s_axis_tdata_i  <= beat_data;
      s_axis_tkeep_i  <= beat_keep;
      s_axis_tlast_i  <= ((offset + AXIS_KEEP_W) >= frame.size());
      s_axis_tvalid_i <= 1'b1;

      do begin
        @(posedge clk);
      end while (!s_axis_tready_o);

      offset += AXIS_KEEP_W;
    end

    s_axis_tvalid_i <= 1'b0;
    s_axis_tlast_i  <= 1'b0;
    s_axis_tdata_i  <= '0;
    s_axis_tkeep_i  <= '0;
    @(posedge clk);
  endtask

  task automatic wait_for_packets(input int unsigned target_packets);
    int unsigned cycles;

    cycles = 0;
    while ((rx_packets < target_packets) && (cycles < 200)) begin
      cycles++;
      @(posedge clk);
    end

    if (rx_packets < target_packets) begin
      $fatal(1, "Timed out waiting for %0d output packet(s), saw %0d", target_packets, rx_packets);
    end
  endtask

  task automatic expect_payload(input byte unsigned expected[]);
    if (rx_bytes.size() != expected.size()) begin
      $fatal(1, "Payload byte count mismatch: got %0d expected %0d", rx_bytes.size(), expected.size());
    end

    foreach (expected[i]) begin
      if (rx_bytes[i] !== expected[i]) begin
        $fatal(1, "Payload byte %0d mismatch: got 0x%02x expected 0x%02x", i, rx_bytes[i], expected[i]);
      end
    end
  endtask

  task automatic test_valid_payload();
    byte unsigned payload[];
    byte unsigned frame[];

    $display("TEST valid IPv4/UDP frame -> UDP payload");
    clear_scoreboard();
    payload = new[20];
    foreach (payload[i]) begin
      payload[i] = byte'(8'h80 + i);
    end

    build_frame(payload, ETHERTYPE_IPV4, IPV4_IHL_MIN, 16'h0000, IP_PROTO_UDP, EXPECTED_PORT, frame);
    send_frame(frame);
    wait_for_packets(1);
    expect_payload(payload);

    if (start_pulses != 1) begin
      $fatal(1, "Expected one dgram_start pulse, got %0d", start_pulses);
    end

    if (last_start_len != payload.size()) begin
      $fatal(1, "Expected dgram_len %0d, got %0d", payload.size(), last_start_len);
    end

    if (drop_pulses != 0) begin
      $fatal(1, "Unexpected drop on valid frame: err=0x%04x", last_drop_err);
    end
  endtask

  task automatic test_bad_ethertype_drop();
    byte unsigned payload[];
    byte unsigned frame[];

    $display("TEST bad EtherType is dropped");
    clear_scoreboard();
    payload = new[8];
    foreach (payload[i]) begin
      payload[i] = byte'(8'ha0 + i);
    end

    build_frame(payload, 16'h86dd, IPV4_IHL_MIN, 16'h0000, IP_PROTO_UDP, EXPECTED_PORT, frame);
    send_frame(frame);
    repeat (20) @(posedge clk);

    if (rx_packets != 0 || rx_bytes.size() != 0) begin
      $fatal(1, "Bad EtherType produced output");
    end

    if ((drop_pulses == 0) || !last_drop_err[FRAME_ERR_BAD_ETHERTYPE]) begin
      $fatal(1, "Bad EtherType did not raise expected drop bit: err=0x%04x", last_drop_err);
    end
  endtask

  task automatic test_bad_dst_port_drop();
    byte unsigned payload[];
    byte unsigned frame[];

    $display("TEST wrong UDP destination port is dropped");
    clear_scoreboard();
    payload = new[8];
    foreach (payload[i]) begin
      payload[i] = byte'(8'hc0 + i);
    end

    build_frame(payload, ETHERTYPE_IPV4, IPV4_IHL_MIN, 16'h0000, IP_PROTO_UDP, 16'd6000, frame);
    send_frame(frame);
    repeat (20) @(posedge clk);

    if (rx_packets != 0 || rx_bytes.size() != 0) begin
      $fatal(1, "Bad UDP port produced output");
    end

    if ((drop_pulses == 0) || !last_drop_err[FRAME_ERR_BAD_UDP_PORT]) begin
      $fatal(1, "Bad UDP port did not raise expected drop bit: err=0x%04x", last_drop_err);
    end
  endtask

  task automatic test_output_backpressure();
    byte unsigned payload[];
    byte unsigned frame[];
    axis_data_t saved_data;
    axis_keep_t saved_keep;

    $display("TEST output backpressure holds payload beat stable");
    clear_scoreboard();
    payload = new[24];
    foreach (payload[i]) begin
      payload[i] = byte'(8'he0 + i);
    end

    build_frame(payload, ETHERTYPE_IPV4, IPV4_IHL_MIN, 16'h0000, IP_PROTO_UDP, EXPECTED_PORT, frame);
    m_axis_tready_i <= 1'b0;

    fork
      send_frame(frame);
      begin
        wait (m_axis_tvalid_o == 1'b1);
        saved_data = m_axis_tdata_o;
        saved_keep = m_axis_tkeep_o;

        repeat (4) begin
          @(posedge clk);
          if (!m_axis_tvalid_o) begin
            $fatal(1, "Output valid dropped while backpressured");
          end
          if ((m_axis_tdata_o !== saved_data) || (m_axis_tkeep_o !== saved_keep)) begin
            $fatal(1, "Output payload changed while backpressured");
          end
          if (s_axis_tready_o) begin
            $fatal(1, "Input ready stayed high while output was backpressured");
          end
        end

        m_axis_tready_i <= 1'b1;
      end
    join

    wait_for_packets(1);
    expect_payload(payload);
  endtask

  initial begin
    reset_dut();
    test_valid_payload();
    test_bad_ethertype_drop();
    test_bad_dst_port_drop();
    test_output_backpressure();

    $display("frame_crack_tb PASS");
    $finish;
  end

endmodule

`default_nettype wire
