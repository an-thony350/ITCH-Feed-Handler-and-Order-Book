`timescale 1ns / 1ps
`default_nettype none

// V5 control/status block. Runs on the same clock as the order book and DMA AXI-Lite.
// BBO data is sampled when bbo_valid_i is high
module itch_csr (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET s_axi_aresetn" *)
    input  wire         s_axi_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire         s_axi_aresetn,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    (* X_INTERFACE_PARAMETER = "PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 16, HAS_BURST 0, HAS_LOCK 0, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, SUPPORTS_NARROW_BURST 0, MAX_BURST_LENGTH 1" *)
    input  wire [15:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *) input  wire [2:0]  s_axi_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *) input  wire        s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *) output wire        s_axi_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *) input  wire [31:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *) input  wire [3:0]  s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *) input  wire        s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *) output wire        s_axi_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *) output reg  [1:0]  s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *) output reg         s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *) input  wire        s_axi_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *) input  wire [15:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *) input  wire [2:0]  s_axi_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *) input  wire        s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *) output wire        s_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *) output reg  [31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *) output reg  [1:0]  s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *) output reg         s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *) input  wire        s_axi_rready,

    output reg  [31:0]  base_price_stock0_o,
    output reg  [31:0]  base_price_stock1_o,
    output reg  [31:0]  base_price_stock2_o,
    input  wire [129:0] bbo_data_i,
    input  wire         bbo_valid_i,
    input  wire [31:0]  bbo_count_i,
    input  wire [2:0]   cam_status_i,
    input  wire [31:0]  reset_status_i
);

    // The order book packs {stock_id[1:0], bid_price[31:0], bid_shares[31:0],
    //                       ask_price[31:0], ask_shares[31:0]}.
    reg [129:0] bbo_snapshot;
    reg [15:0]  awaddr_hold;
    reg [31:0]  wdata_hold;
    reg [3:0]   wstrb_hold;
    reg         aw_pending;
    reg         w_pending;

    assign s_axi_awready = ~aw_pending & ~s_axi_bvalid;
    assign s_axi_wready  = ~w_pending  & ~s_axi_bvalid;
    assign s_axi_arready = ~s_axi_rvalid;

    function automatic [31:0] merge_bytes(
        input [31:0] old_value,
        input [31:0] new_value,
        input [3:0]  strobes
    );
        integer i;
        begin
            merge_bytes = old_value;
            for (i = 0; i < 4; i = i + 1)
                if (strobes[i])
                    merge_bytes[i*8 +: 8] = new_value[i*8 +: 8];
        end
    endfunction

    function automatic [31:0] read_register(input [15:0] address);
        begin
            case (address)
                16'h0000: read_register = 32'h49544348; // 'ITCH'
                16'h0004: read_register = 32'h00050001; // V5 CSR revision 1
                16'h0010: read_register = base_price_stock0_o;
                16'h0014: read_register = base_price_stock1_o;
                16'h0018: read_register = base_price_stock2_o;
                16'h0020: read_register = bbo_count_i;
                16'h0024: read_register = {30'd0, bbo_snapshot[129:128]};
                16'h0028: read_register = bbo_snapshot[127:96];
                16'h002c: read_register = bbo_snapshot[95:64];
                16'h0030: read_register = bbo_snapshot[63:32];
                16'h0034: read_register = bbo_snapshot[31:0];
                16'h0038: read_register = {29'd0, cam_status_i};
                16'h003c: read_register = reset_status_i;
                default:  read_register = 32'd0;
            endcase
        end
    endfunction

    function automatic valid_read(input [15:0] address);
        begin
            case (address)
                16'h0000, 16'h0004,
                16'h0010, 16'h0014, 16'h0018,
                16'h0020, 16'h0024, 16'h0028, 16'h002c,
                16'h0030, 16'h0034, 16'h0038, 16'h003c:
                    valid_read = 1'b1;
                default: valid_read = 1'b0;
            endcase
        end
    endfunction

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            base_price_stock0_o <= 32'd0;
            base_price_stock1_o <= 32'd0;
            base_price_stock2_o <= 32'd0;
            bbo_snapshot        <= 130'd0;
            awaddr_hold         <= 16'd0;
            wdata_hold          <= 32'd0;
            wstrb_hold          <= 4'd0;
            aw_pending          <= 1'b0;
            w_pending           <= 1'b0;
            s_axi_bvalid        <= 1'b0;
            s_axi_bresp         <= 2'b00;
            s_axi_rvalid        <= 1'b0;
            s_axi_rdata         <= 32'd0;
            s_axi_rresp         <= 2'b00;
        end else begin
            if (bbo_valid_i)
                bbo_snapshot <= bbo_data_i;

            if (s_axi_awvalid && s_axi_awready) begin
                awaddr_hold <= s_axi_awaddr;
                aw_pending  <= 1'b1;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                wdata_hold <= s_axi_wdata;
                wstrb_hold <= s_axi_wstrb;
                w_pending  <= 1'b1;
            end

            if (aw_pending && w_pending && !s_axi_bvalid) begin
                s_axi_bresp <= 2'b00;
                case (awaddr_hold)
                    16'h0010: base_price_stock0_o <= merge_bytes(base_price_stock0_o, wdata_hold, wstrb_hold);
                    16'h0014: base_price_stock1_o <= merge_bytes(base_price_stock1_o, wdata_hold, wstrb_hold);
                    16'h0018: base_price_stock2_o <= merge_bytes(base_price_stock2_o, wdata_hold, wstrb_hold);
                    default: s_axi_bresp <= 2'b10; // SLVERR for read-only/unknown offsets
                endcase
                aw_pending   <= 1'b0;
                w_pending    <= 1'b0;
                s_axi_bvalid <= 1'b1;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rdata  <= read_register(s_axi_araddr);
                s_axi_rresp  <= valid_read(s_axi_araddr) ? 2'b00 : 2'b10;
                s_axi_rvalid <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
endmodule

`default_nettype wire
