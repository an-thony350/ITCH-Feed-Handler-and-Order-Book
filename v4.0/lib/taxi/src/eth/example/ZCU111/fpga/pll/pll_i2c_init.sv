// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2015-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * pll_i2c_init
 */
module pll_i2c_init #
(
    parameter logic SIM_SPEEDUP = 1'b0
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * I2C master interface
     */
    taxi_axis_if.src   m_axis_cmd,
    taxi_axis_if.src   m_axis_tx,

    /*
     * Status
     */
    output wire logic  busy,

    /*
     * Configuration
     */
    input  wire logic  start
);

/*

Generic module for I2C bus initialization.  Good for use when multiple devices
on an I2C bus must be initialized on system start without intervention of a
general-purpose processor.

Copy this file and change init_data and INIT_DATA_LEN as needed.

This module can be used in two modes: simple device initialization, or multiple
device initialization.  In multiple device mode, the same initialization sequence
can be performed on multiple different device addresses.

To use single device mode, only use the start write to address and write data commands.
The module will generate the I2C commands in sequential order.  Terminate the list
with a 0 entry.

To use the multiple device mode, use the start data and start address block commands
to set up lists of initialization data and device addresses.  The module enters
multiple device mode upon seeing a start data block command.  The module stores the
offset of the start of the data block and then skips ahead until it reaches a start
address block command.  The module will store the offset to the address block and
read the first address in the block.  Then it will jump back to the data block
and execute it, substituting the stored address for each current address write
command.  Upon reaching the start address block command, the module will read out the
next address and start again at the top of the data block.  If the module encounters
a start data block command while looking for an address, then it will store a new data
offset and then look for a start address block command.  Terminate the list with a 0
entry.  Normal address commands will operate normally inside a data block.

Commands:

00 0000000 : stop
00 0000001 : exit multiple device mode
00 0000011 : start write to current address
00 0001000 : start address block
00 0001001 : start data block
00 001dddd : delay 2**(16+d) cycles
00 1000001 : send I2C stop
01 aaaaaaa : start write to address
1 dddddddd : write 8-bit data

Examples

write 0x11223344 to register 0x0004 on device at 0x50

01 1010000  start write to 0x50
1 00000000  write address 0x0004
1 00000100
1 00010001  write data 0x11223344
1 00100010
1 00110011
1 01000100
0 00000000  stop

write 0x11223344 to register 0x0004 on devices at 0x50, 0x51, 0x52, and 0x53

00 0001001  start data block
00 0000011  start write to current address
1 00000000  write address 0x0004
1 00000100
1 00010001  write data 0x11223344
1 00100010
1 00110011
1 01000100
00 0001000  start address block
01 1010000  address 0x50
01 1010001  address 0x51
01 1010010  address 0x52
01 1010011  address 0x53
00 0000001  exit multi-dev mode
00 0000000  stop

*/

// check configuration
if (m_axis_cmd.DATA_W < 12)
    $fatal(0, "Command interface width must be at least 12 bits (instance %m)");

if (m_axis_tx.DATA_W != 8)
    $fatal(0, "Data interface width must be 8 bits (instance %m)");

function [8:0] cmd_start(input [6:0] addr);
    cmd_start = {2'b01, addr};
endfunction

function [8:0] cmd_wr(input [7:0] data);
    cmd_wr = {1'b1, data};
endfunction

function [8:0] cmd_stop();
    cmd_stop = {2'b00, 7'b1000001};
endfunction

function [8:0] cmd_delay(input [3:0] d);
    cmd_delay = {2'b00, 3'b001, d};
endfunction

function [8:0] cmd_halt();
    cmd_halt = 9'd0;
endfunction

function [8:0] blk_start_data();
    blk_start_data = {2'b00, 7'b0001001};
endfunction

function [8:0] blk_start_addr();
    blk_start_addr = {2'b00, 7'b0001000};
endfunction

function [8:0] cmd_start_cur();
    cmd_start_cur = {2'b00, 7'b0000011};
endfunction

function [8:0] cmd_exit();
    cmd_exit = {2'b00, 7'b0000001};
endfunction

// init_data ROM
localparam INIT_DATA_LEN = 428;

reg [8:0] init_data [INIT_DATA_LEN-1:0];

initial begin
    // Initial delay
    init_data[0] = cmd_delay(6); // delay 30 ms
    // Set mux to select I2C-SPI bridge on ZCU111
    init_data[1] = cmd_start(7'h74);
    init_data[2] = cmd_wr(8'h20);
    init_data[3] = cmd_stop(); // I2C stop
    init_data[4] = cmd_start(7'h75);
    init_data[5] = cmd_wr(8'h00);
    init_data[6] = cmd_stop(); // I2C stop
    // Configure I2C-SPI bridge
    init_data[7] = cmd_start(7'h2f);
    init_data[8] = cmd_wr(8'hf0);
    init_data[9] = cmd_wr(8'h00);
    init_data[10] = cmd_start(7'h2f);
    init_data[11] = cmd_wr(8'hf6);
    init_data[12] = cmd_wr(8'h00);
    // Configuration for LMK04208 PLL
    // PLL1
    // CLKin0 = 12.8 MHz TCXO
    // CLKin1 = 10 MHz
    // CLKin0 R = 800
    // CLKin1 R = 625
    // PFD = in0 / R0 = in1 / R1 = 16 kHz
    // N1 = 7680
    // VCO = PFD * N1 = 122.88 MHz
    // Ext VCO is 122.88 MHz
    // PLL2
    // 122.88 MHz from ext VCO
    // VCO range 2750 - 3072 MHz
    // R2 = 384
    // VCODIV = 3
    // N2 P = 5
    // N2 = 625
    // PFD = 122.88 / R2 = 0.32
    // VCO = PFD * VCODIV * P * N2 = 3000
    // VCO/3/4 = 250 MHz
    // VCO/3/100 = 10 MHz
    // VCO/3/512 = 1.953125 MHz
    // CLKout0: FPGA SYSREF
    // CLKout1: DAC 228 SYSREF
    // CLKout2: FPGA REFCLK
    // CLKout3: SYNC_2594
    // CLKout4: REFCLK_2594
    // CLKout5: SMA
    // Reset
    init_data[13] = cmd_start(7'h2f);
    init_data[14] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[15] = cmd_wr(8'h00); // write 0x00020000
    init_data[16] = cmd_wr(8'h02);
    init_data[17] = cmd_wr(8'h00);
    init_data[18] = cmd_wr(8'h00);
    init_data[19] = cmd_delay(1); // small delay
    init_data[20] = cmd_start(7'h2f);
    init_data[21] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[22] = cmd_wr(8'h00); // write 0x00000000
    init_data[23] = cmd_wr(8'h00);
    init_data[24] = cmd_wr(8'h00);
    init_data[25] = cmd_wr(8'h00);
    init_data[26] = cmd_delay(1); // small delay
    // CLKout0 DDLY 10, DIV 512
    init_data[27] = cmd_start(7'h2f);
    init_data[28] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[29] = cmd_wr(8'h00); // write 0x00284000
    init_data[30] = cmd_wr(8'h28);
    init_data[31] = cmd_wr(8'h40);
    init_data[32] = cmd_wr(8'h00);
    init_data[33] = cmd_delay(1); // small delay
    // CLKout1 DDLY 10, DIV 512
    init_data[34] = cmd_start(7'h2f);
    init_data[35] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[36] = cmd_wr(8'h00); // write 0x00284001
    init_data[37] = cmd_wr(8'h28);
    init_data[38] = cmd_wr(8'h40);
    init_data[39] = cmd_wr(8'h01);
    init_data[40] = cmd_delay(1); // small delay
    // CLKout2 DDLY 10, DIV 4
    init_data[41] = cmd_start(7'h2f);
    init_data[42] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[43] = cmd_wr(8'h00); // write 0x00280082
    init_data[44] = cmd_wr(8'h28);
    init_data[45] = cmd_wr(8'h00);
    init_data[46] = cmd_wr(8'h82);
    init_data[47] = cmd_delay(1); // small delay
    // CLKout3 DDLY 10, DIV 512
    init_data[48] = cmd_start(7'h2f);
    init_data[49] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[50] = cmd_wr(8'h00); // write 0x00284003
    init_data[51] = cmd_wr(8'h28);
    init_data[52] = cmd_wr(8'h40);
    init_data[53] = cmd_wr(8'h03);
    init_data[54] = cmd_delay(1); // small delay
    // CLKout4 DDLY 10, DIV 4
    init_data[55] = cmd_start(7'h2f);
    init_data[56] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[57] = cmd_wr(8'h00); // write 0x00280084
    init_data[58] = cmd_wr(8'h28);
    init_data[59] = cmd_wr(8'h00);
    init_data[60] = cmd_wr(8'h84);
    init_data[61] = cmd_delay(1); // small delay
    // CLKout5 DDLY 10, DIV 100
    init_data[62] = cmd_start(7'h2f);
    init_data[63] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[64] = cmd_wr(8'h00); // write 0x00280c85
    init_data[65] = cmd_wr(8'h28);
    init_data[66] = cmd_wr(8'h0c);
    init_data[67] = cmd_wr(8'h85);
    init_data[68] = cmd_delay(1); // small delay
    // CLKout0 LVDS, CLKout1 LVDS
    init_data[69] = cmd_start(7'h2f);
    init_data[70] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[71] = cmd_wr(8'h01); // write 0x01100006
    init_data[72] = cmd_wr(8'h10);
    init_data[73] = cmd_wr(8'h00);
    init_data[74] = cmd_wr(8'h06);
    init_data[75] = cmd_delay(1); // small delay
    // CLKout2 LVDS, CLKout3 LVDS
    init_data[76] = cmd_start(7'h2f);
    init_data[77] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[78] = cmd_wr(8'h01); // write 0x01100007
    init_data[79] = cmd_wr(8'h10);
    init_data[80] = cmd_wr(8'h00);
    init_data[81] = cmd_wr(8'h07);
    init_data[82] = cmd_delay(1); // small delay
    // CLKout4 LVDS, CLKout5 LVCMOS
    init_data[83] = cmd_start(7'h2f);
    init_data[84] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[85] = cmd_wr(8'h06); // write 0x06010008
    init_data[86] = cmd_wr(8'h01);
    init_data[87] = cmd_wr(8'h00);
    init_data[88] = cmd_wr(8'h08);
    init_data[89] = cmd_delay(1); // small delay
    // RSVD
    init_data[90] = cmd_start(7'h2f);
    init_data[91] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[92] = cmd_wr(8'h55); // write 0x55555549
    init_data[93] = cmd_wr(8'h55);
    init_data[94] = cmd_wr(8'h55);
    init_data[95] = cmd_wr(8'h49);
    init_data[96] = cmd_delay(1); // small delay
    // OSCout off, VCO div 3
    init_data[97] = cmd_start(7'h2f);
    init_data[98] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[99] = cmd_wr(8'h10); // write 0x1000530a
    init_data[100] = cmd_wr(8'h00);
    init_data[101] = cmd_wr(8'h53);
    init_data[102] = cmd_wr(8'h0a);
    init_data[103] = cmd_delay(1); // small delay
    // MODE 0, sync on, SYNC_TYPE input with pull-up, no xtal
    init_data[104] = cmd_start(7'h2f);
    init_data[105] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[106] = cmd_wr(8'h04); // write 0x0400200b
    init_data[107] = cmd_wr(8'h00);
    init_data[108] = cmd_wr(8'h20);
    init_data[109] = cmd_wr(8'h0b);
    init_data[110] = cmd_delay(1); // small delay
    // LD_MUX PLL1&PLL2, SYNC_PLL2_DLD on, EN_TRACK on, holdover disable
    init_data[111] = cmd_start(7'h2f);
    init_data[112] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[113] = cmd_wr(8'h1b); // write 0x1b8c016c
    init_data[114] = cmd_wr(8'h8c);
    init_data[115] = cmd_wr(8'h01);
    init_data[116] = cmd_wr(8'h6c);
    init_data[117] = cmd_delay(1); // small delay
    // HOLDOVER_MUX readback, DISABLE_DLD1_DET on, CLKin_SELECT_MODE CLKin0, EN_CLKin0
    init_data[118] = cmd_start(7'h2f);
    init_data[119] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[120] = cmd_wr(8'h3b); // write 0x3b00802d
    init_data[121] = cmd_wr(8'h00);
    init_data[122] = cmd_wr(8'h80);
    init_data[123] = cmd_wr(8'h2d);
    init_data[124] = cmd_delay(1); // small delay
    // LOS_TIMEOUT 1200 ns, CLKinX_BUF_TYPE Bipolar, DAC_HIGH_TRIP 63, DAC_LOW_TRIP 0
    init_data[125] = cmd_start(7'h2f);
    init_data[126] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[127] = cmd_wr(8'h00); // write 0x000fc00e
    init_data[128] = cmd_wr(8'h0f);
    init_data[129] = cmd_wr(8'hc0);
    init_data[130] = cmd_wr(8'h0e);
    init_data[131] = cmd_delay(1); // small delay
    // MAN_DAC 0, EN_MAN_DAC auto
    init_data[132] = cmd_start(7'h2f);
    init_data[133] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[134] = cmd_wr(8'h00); // write 0x0000000f
    init_data[135] = cmd_wr(8'h00);
    init_data[136] = cmd_wr(8'h00);
    init_data[137] = cmd_wr(8'h0f);
    init_data[138] = cmd_delay(1); // small delay
    // XTAL_LVL 1.65 Vpp
    init_data[139] = cmd_start(7'h2f);
    init_data[140] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[141] = cmd_wr(8'h01); // write 0x01550410
    init_data[142] = cmd_wr(8'h55);
    init_data[143] = cmd_wr(8'h04);
    init_data[144] = cmd_wr(8'h10);
    init_data[145] = cmd_delay(1); // small delay
    // PLL2_C4_LF 10pF, PLL2_C3_LF 10 pF, PLL2_R4_LF 200 ohm, PLL2_R3_LF 200 ohm, PLL1_N_DLY 0 ps, PLL1_R_DLY 0 ps, PLL1_WND_SIZE 5.5 ns
    init_data[146] = cmd_start(7'h2f);
    init_data[147] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[148] = cmd_wr(8'h00); // write 0x00000018
    init_data[149] = cmd_wr(8'h00);
    init_data[150] = cmd_wr(8'h00);
    init_data[151] = cmd_wr(8'h18);
    init_data[152] = cmd_delay(1); // small delay
    // DAC_CLK_DIV 1023, PLL1_DLD_CNT 16383
    init_data[153] = cmd_start(7'h2f);
    init_data[154] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[155] = cmd_wr(8'hff); // write 0xffcfffd9
    init_data[156] = cmd_wr(8'hcf);
    init_data[157] = cmd_wr(8'hff);
    init_data[158] = cmd_wr(8'hd9);
    init_data[159] = cmd_delay(1); // small delay
    // PLL2_WND_SIZE 2, EN_PLL2_REF_2X off, PLL2_CP_POL neg, PLL2_CP_GAIN 100, PLL2_DLD_CNT 16383, PLL2_CP_TRI off
    init_data[160] = cmd_start(7'h2f);
    init_data[161] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[162] = cmd_wr(8'h83); // write 0x83afffda
    init_data[163] = cmd_wr(8'haf);
    init_data[164] = cmd_wr(8'hff);
    init_data[165] = cmd_wr(8'hda);
    init_data[166] = cmd_delay(1); // small delay
    // PLL1_CP_POL pos, PLL1_CP_GAIN 100, CLKinX_PreR_DIV 1, PLL1_R 800, PLL1_CP_TRI off
    init_data[167] = cmd_start(7'h2f);
    init_data[168] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[169] = cmd_wr(8'h10); // write 0x1000c81b
    init_data[170] = cmd_wr(8'h00);
    init_data[171] = cmd_wr(8'hc8);
    init_data[172] = cmd_wr(8'h1b);
    init_data[173] = cmd_delay(1); // small delay
    // PLL2_R 384, PLL1_N 7680
    init_data[174] = cmd_start(7'h2f);
    init_data[175] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[176] = cmd_wr(8'h18); // write 0x1807801c
    init_data[177] = cmd_wr(8'h07);
    init_data[178] = cmd_wr(8'h80);
    init_data[179] = cmd_wr(8'h1c);
    init_data[180] = cmd_delay(1); // small delay
    // OSCin_FREQ 63-127, PLL2_FAST_PDF under 100, PLL2_N_CAL 625
    init_data[181] = cmd_start(7'h2f);
    init_data[182] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[183] = cmd_wr(8'h01); // write 0x01004e3d
    init_data[184] = cmd_wr(8'h00);
    init_data[185] = cmd_wr(8'h4e);
    init_data[186] = cmd_wr(8'h3d);
    init_data[187] = cmd_delay(1); // small delay
    // PLL2_P 5, PLL2_N 625
    init_data[188] = cmd_start(7'h2f);
    init_data[189] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[190] = cmd_wr(8'h05); // write 0x05004e3e
    init_data[191] = cmd_wr(8'h00);
    init_data[192] = cmd_wr(8'h4e);
    init_data[193] = cmd_wr(8'h3e);
    init_data[194] = cmd_delay(1); // small delay
    // READBACK_LE 0
    init_data[195] = cmd_start(7'h2f);
    init_data[196] = cmd_wr(8'h02); // SPI transfer, CS mask 0x2
    init_data[197] = cmd_wr(8'h00); // write 0x0000001f
    init_data[198] = cmd_wr(8'h00);
    init_data[199] = cmd_wr(8'h00);
    init_data[200] = cmd_wr(8'h1f);
    init_data[201] = cmd_delay(1); // small delay
    // Configuration for LMX2594 PLL
    // OSCin = 250 MHz
    // VCO range 7.5 - 15 GHz
    // R_PRE = 1
    // R = 1
    // PFD = OSCin / (R_PRE * R) = 250 MHz
    // N = 32
    // VCO = PFD * N = 8 GHz
    // VCO / 8 = 1 GHz
    // Reset
    init_data[202] = cmd_start(7'h2f);
    init_data[203] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[204] = cmd_wr(8'h00); // address 0x00
    init_data[205] = cmd_wr(8'h24); // write 0x2412
    init_data[206] = cmd_wr(8'h12);
    init_data[207] = cmd_delay(1); // small delay
    init_data[208] = cmd_start(7'h2f);
    init_data[209] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[210] = cmd_wr(8'h00); // address 0x00
    init_data[211] = cmd_wr(8'h24); // write 0x2410
    init_data[212] = cmd_wr(8'h10);
    init_data[213] = cmd_delay(1); // small delay
    // QUICK_RECAL_EN: 0
    // VCO_CAPCTRL_STRT: 0
    init_data[214] = cmd_start(7'h2f);
    init_data[215] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[216] = cmd_wr(8'h4e); // address 0x4e
    init_data[217] = cmd_wr(8'h00); // write 0x0001
    init_data[218] = cmd_wr(8'h01);
    init_data[219] = cmd_delay(1); // small delay
    // CHDIV: 3 (8)
    init_data[220] = cmd_start(7'h2f);
    init_data[221] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[222] = cmd_wr(8'h4b); // address 0x4b
    init_data[223] = cmd_wr(8'h08); // write 0x08c0
    init_data[224] = cmd_wr(8'hc0);
    init_data[225] = cmd_delay(1); // small delay
    // MASH_RST_COUNT: 50000 (0xc350)
    init_data[226] = cmd_start(7'h2f);
    init_data[227] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[228] = cmd_wr(8'h46); // address 0x46
    init_data[229] = cmd_wr(8'hc3); // write 0xc350
    init_data[230] = cmd_wr(8'h50);
    init_data[231] = cmd_delay(1); // small delay
    // MASH_RST_COUNT: 50000 (0xc350)
    init_data[232] = cmd_start(7'h2f);
    init_data[233] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[234] = cmd_wr(8'h45); // address 0x45
    init_data[235] = cmd_wr(8'h00); // write 0x0000
    init_data[236] = cmd_wr(8'h00);
    init_data[237] = cmd_delay(1); // small delay
    // LD_DELAY: 1000 (0x3e8)
    init_data[238] = cmd_start(7'h2f);
    init_data[239] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[240] = cmd_wr(8'h3c); // address 0x3c
    init_data[241] = cmd_wr(8'h03); // write 0x03e8
    init_data[242] = cmd_wr(8'he8);
    init_data[243] = cmd_delay(1); // small delay
    // LD_TYPE: 1
    init_data[244] = cmd_start(7'h2f);
    init_data[245] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[246] = cmd_wr(8'h3b); // address 0x3b
    init_data[247] = cmd_wr(8'h00); // write 0x0001
    init_data[248] = cmd_wr(8'h01);
    init_data[249] = cmd_delay(1); // small delay
    // INPIN_IGNORE: 1
    // INPIN_HYST: 0
    // INPIN_LVL: 0
    // INPIN_FMT: 0
    init_data[250] = cmd_start(7'h2f);
    init_data[251] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[252] = cmd_wr(8'h3a); // address 0x3a
    init_data[253] = cmd_wr(8'h80); // write 0x8001
    init_data[254] = cmd_wr(8'h01);
    init_data[255] = cmd_delay(1); // small delay
    // OUTB_MUX: 0 (ch div)
    init_data[256] = cmd_start(7'h2f);
    init_data[257] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[258] = cmd_wr(8'h2e); // address 0x2e
    init_data[259] = cmd_wr(8'h07); // write 0x07fc
    init_data[260] = cmd_wr(8'hfc);
    init_data[261] = cmd_delay(1); // small delay
    // OUTA_MUX: 0 (ch div)
    // OUT_ISET: 0 (max)
    // OUTB_PWR: 31 (0x1f)
    init_data[262] = cmd_start(7'h2f);
    init_data[263] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[264] = cmd_wr(8'h2d); // address 0x2d
    init_data[265] = cmd_wr(8'hc0); // write 0xc0df
    init_data[266] = cmd_wr(8'hdf);
    init_data[267] = cmd_delay(1); // small delay
    // OUTA_PWR: 31 (0x1f)
    // OUTB_PD: 0
    // OUTA_PD: 0
    // MASH_RESET_N: 0
    // MASH_ORDER: 0
    init_data[268] = cmd_start(7'h2f);
    init_data[269] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[270] = cmd_wr(8'h2c); // address 0x2c
    init_data[271] = cmd_wr(8'h1f); // write 0x1f00
    init_data[272] = cmd_wr(8'h00);
    init_data[273] = cmd_delay(1); // small delay
    // PLL_NUM: 0
    init_data[274] = cmd_start(7'h2f);
    init_data[275] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[276] = cmd_wr(8'h2b); // address 0x2b
    init_data[277] = cmd_wr(8'h00); // write 0x0000
    init_data[278] = cmd_wr(8'h00);
    init_data[279] = cmd_delay(1); // small delay
    // PLL_NUM: 0
    init_data[280] = cmd_start(7'h2f);
    init_data[281] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[282] = cmd_wr(8'h2a); // address 0x2a
    init_data[283] = cmd_wr(8'h00); // write 0x0000
    init_data[284] = cmd_wr(8'h00);
    init_data[285] = cmd_delay(1); // small delay
    // MASH_SEED: 0
    init_data[286] = cmd_start(7'h2f);
    init_data[287] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[288] = cmd_wr(8'h29); // address 0x29
    init_data[289] = cmd_wr(8'h00); // write 0x0000
    init_data[290] = cmd_wr(8'h00);
    init_data[291] = cmd_delay(1); // small delay
    // MASH_SEED: 0
    init_data[292] = cmd_start(7'h2f);
    init_data[293] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[294] = cmd_wr(8'h28); // address 0x28
    init_data[295] = cmd_wr(8'h00); // write 0x0000
    init_data[296] = cmd_wr(8'h00);
    init_data[297] = cmd_delay(1); // small delay
    // PLL_DEN: '1
    init_data[298] = cmd_start(7'h2f);
    init_data[299] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[300] = cmd_wr(8'h27); // address 0x27
    init_data[301] = cmd_wr(8'hff); // write 0xffff
    init_data[302] = cmd_wr(8'hff);
    init_data[303] = cmd_delay(1); // small delay
    // PLL_DEN: '1
    init_data[304] = cmd_start(7'h2f);
    init_data[305] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[306] = cmd_wr(8'h26); // address 0x26
    init_data[307] = cmd_wr(8'hff); // write 0xffff
    init_data[308] = cmd_wr(8'hff);
    init_data[309] = cmd_delay(1); // small delay
    // MASH_SEED_EN: 0
    // PFD_DLY_SEL: 2
    init_data[310] = cmd_start(7'h2f);
    init_data[311] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[312] = cmd_wr(8'h25); // address 0x25
    init_data[313] = cmd_wr(8'h02); // write 0x0204
    init_data[314] = cmd_wr(8'h04);
    init_data[315] = cmd_delay(1); // small delay
    // PLL_N: 32 (0x20)
    init_data[316] = cmd_start(7'h2f);
    init_data[317] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[318] = cmd_wr(8'h24); // address 0x24
    init_data[319] = cmd_wr(8'h00); // write 0x0020
    init_data[320] = cmd_wr(8'h20);
    init_data[321] = cmd_delay(1); // small delay
    // PLL_N: 32 (0x20)
    init_data[322] = cmd_start(7'h2f);
    init_data[323] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[324] = cmd_wr(8'h22); // address 0x22
    init_data[325] = cmd_wr(8'h00); // write 0x0000
    init_data[326] = cmd_wr(8'h00);
    init_data[327] = cmd_delay(1); // small delay
    // CHDIV_DIV2: 1
    init_data[328] = cmd_start(7'h2f);
    init_data[329] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[330] = cmd_wr(8'h1f); // address 0x1f
    init_data[331] = cmd_wr(8'h43); // write 0x43ec
    init_data[332] = cmd_wr(8'hec);
    init_data[333] = cmd_delay(1); // small delay
    // VCO_SEL: 7 (VCO7)
    // VCO_SEL_FORCE: 0
    init_data[334] = cmd_start(7'h2f);
    init_data[335] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[336] = cmd_wr(8'h14); // address 0x14
    init_data[337] = cmd_wr(8'hf8); // write 0xf848
    init_data[338] = cmd_wr(8'h48);
    init_data[339] = cmd_delay(1); // small delay
    // VCO_CAPCTRL: 183 (0xb7)
    init_data[340] = cmd_start(7'h2f);
    init_data[341] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[342] = cmd_wr(8'h13); // address 0x13
    init_data[343] = cmd_wr(8'h27); // write 0x27b7
    init_data[344] = cmd_wr(8'hb7);
    init_data[345] = cmd_delay(1); // small delay
    // 18,0x0000
    // VCO_DACISET_STRT: 250 (0xfa)
    init_data[346] = cmd_start(7'h2f);
    init_data[347] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[348] = cmd_wr(8'h11); // address 0x11
    init_data[349] = cmd_wr(8'h00); // write 0x00fa
    init_data[350] = cmd_wr(8'hfa);
    init_data[351] = cmd_delay(1); // small delay
    // VCO_DACISET: 128 (0x80)
    init_data[352] = cmd_start(7'h2f);
    init_data[353] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[354] = cmd_wr(8'h10); // address 0x10
    init_data[355] = cmd_wr(8'h00); // write 0x0080
    init_data[356] = cmd_wr(8'h80);
    init_data[357] = cmd_delay(1); // small delay
    // 15,0x0000
    // CPG: 7
    init_data[358] = cmd_start(7'h2f);
    init_data[359] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[360] = cmd_wr(8'h0e); // address 0x0e
    init_data[361] = cmd_wr(8'h1e); // write 0x1e70
    init_data[362] = cmd_wr(8'h70);
    init_data[363] = cmd_delay(1); // small delay
    // PLL_R_PRE: 1
    init_data[364] = cmd_start(7'h2f);
    init_data[365] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[366] = cmd_wr(8'h0c); // address 0x0c
    init_data[367] = cmd_wr(8'h50); // write 0x5001
    init_data[368] = cmd_wr(8'h01);
    init_data[369] = cmd_delay(1); // small delay
    // PLL_R: 1
    init_data[370] = cmd_start(7'h2f);
    init_data[371] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[372] = cmd_wr(8'h0b); // address 0x0b
    init_data[373] = cmd_wr(8'h00); // write 0x0018
    init_data[374] = cmd_wr(8'h18);
    init_data[375] = cmd_delay(1); // small delay
    // MULT: 1 (bypass)
    init_data[376] = cmd_start(7'h2f);
    init_data[377] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[378] = cmd_wr(8'h0a); // address 0x0a
    init_data[379] = cmd_wr(8'h10); // write 0x10d8
    init_data[380] = cmd_wr(8'hd8);
    init_data[381] = cmd_delay(1); // small delay
    // OSC_2X: 0
    init_data[382] = cmd_start(7'h2f);
    init_data[383] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[384] = cmd_wr(8'h09); // address 0x09
    init_data[385] = cmd_wr(8'h06); // write 0x0604
    init_data[386] = cmd_wr(8'h04);
    init_data[387] = cmd_delay(1); // small delay
    // VCO_DACISET_FORCE: 0
    // VCO_CAPCTRL_FORCE: 0
    init_data[388] = cmd_start(7'h2f);
    init_data[389] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[390] = cmd_wr(8'h08); // address 0x08
    init_data[391] = cmd_wr(8'h20); // write 0x2000
    init_data[392] = cmd_wr(8'h00);
    init_data[393] = cmd_delay(1); // small delay
    // OUT_FORCE: 0
    init_data[394] = cmd_start(7'h2f);
    init_data[395] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[396] = cmd_wr(8'h07); // address 0x07
    init_data[397] = cmd_wr(8'h00); // write 0x00b2
    init_data[398] = cmd_wr(8'hb2);
    init_data[399] = cmd_delay(1); // small delay
    // ACAL_CMP_DLY: 10
    init_data[400] = cmd_start(7'h2f);
    init_data[401] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[402] = cmd_wr(8'h04); // address 0x04
    init_data[403] = cmd_wr(8'h0a); // write 0x0a43
    init_data[404] = cmd_wr(8'h43);
    init_data[405] = cmd_delay(1); // small delay
    // CAL_CLK_DIV: 3 (div 8)
    init_data[406] = cmd_start(7'h2f);
    init_data[407] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[408] = cmd_wr(8'h01); // address 0x01
    init_data[409] = cmd_wr(8'h08); // write 0x080b
    init_data[410] = cmd_wr(8'h0b);
    init_data[411] = cmd_delay(1); // small delay
    // FCAL_HPFD_ADJ: 3 (PFD > 200 MHz)
    // FCAL_LPFD_ADJ: 0 (PFD > 10 MHz)
    // FCAL_EN: 0
    // MUXOUT_LD_SEL: 0 (readback)
    // RESET: 0
    // POWERDOWN: 0
    init_data[412] = cmd_start(7'h2f);
    init_data[413] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[414] = cmd_wr(8'h00); // address 0x00
    init_data[415] = cmd_wr(8'h25); // write 0x2590
    init_data[416] = cmd_wr(8'h90);
    init_data[417] = cmd_delay(1); // small delay
    // Delay 10 msec
    init_data[418] = cmd_delay(10); // delay 300 ms
    // FCAL_HPFD_ADJ: 3 (PFD > 200 MHz)
    // FCAL_LPFD_ADJ: 0 (PFD > 10 MHz)
    // FCAL_EN: 1
    // MUXOUT_LD_SEL: 1 (LD)
    // RESET: 0
    // POWERDOWN: 0
    init_data[419] = cmd_start(7'h2f);
    init_data[420] = cmd_wr(8'h0d); // SPI transfer, CS mask 0xd
    init_data[421] = cmd_wr(8'h00); // address 0x00
    init_data[422] = cmd_wr(8'h25); // write 0x259c
    init_data[423] = cmd_wr(8'h9c);
    init_data[424] = cmd_delay(1); // small delay
    // Clear I2C-SPI bridge interrupt
    init_data[425] = cmd_start(7'h2f);
    init_data[426] = cmd_wr(8'hf1);
    init_data[427] = cmd_halt(); // end
end

localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_RUN = 3'd1,
    STATE_TABLE_1 = 3'd2,
    STATE_TABLE_2 = 3'd3,
    STATE_TABLE_3 = 3'd4;

logic [2:0] state_reg = STATE_IDLE, state_next;

localparam AW = $clog2(INIT_DATA_LEN);

logic [8:0] init_data_reg = '0;

logic [AW-1:0] address_reg = '0, address_next;
logic [AW-1:0] address_ptr_reg = '0, address_ptr_next;
logic [AW-1:0] data_ptr_reg = '0, data_ptr_next;

logic [6:0] cur_address_reg = '0, cur_address_next;

logic [31:0] delay_counter_reg = '0, delay_counter_next;

logic [6:0] m_axis_cmd_address_reg = '0, m_axis_cmd_address_next;
logic m_axis_cmd_start_reg = 1'b0, m_axis_cmd_start_next;
logic m_axis_cmd_write_reg = 1'b0, m_axis_cmd_write_next;
logic m_axis_cmd_stop_reg = 1'b0, m_axis_cmd_stop_next;
logic m_axis_cmd_valid_reg = 1'b0, m_axis_cmd_valid_next;

logic [7:0] m_axis_tx_tdata_reg = '0, m_axis_tx_tdata_next;
logic m_axis_tx_tvalid_reg = 1'b0, m_axis_tx_tvalid_next;

logic start_flag_reg = 1'b0, start_flag_next;

logic busy_reg = 1'b0;

assign m_axis_cmd.tdata[6:0] = m_axis_cmd_address_reg;
assign m_axis_cmd.tdata[7]   = m_axis_cmd_start_reg;
assign m_axis_cmd.tdata[8]   = 1'b0; // read
assign m_axis_cmd.tdata[9]   = m_axis_cmd_write_reg;
assign m_axis_cmd.tdata[10]  = 1'b0; // write multi
assign m_axis_cmd.tdata[11]  = m_axis_cmd_stop_reg;
assign m_axis_cmd.tvalid = m_axis_cmd_valid_reg;
assign m_axis_cmd.tlast = 1'b1;
assign m_axis_cmd.tid = '0;
assign m_axis_cmd.tdest = '0;
assign m_axis_cmd.tuser = '0;

assign m_axis_tx.tdata = m_axis_tx_tdata_reg;
assign m_axis_tx.tvalid = m_axis_tx_tvalid_reg;
assign m_axis_tx.tlast = 1'b1;
assign m_axis_tx.tid = '0;
assign m_axis_tx.tdest = '0;
assign m_axis_tx.tuser = '0;

assign busy = busy_reg;

always_comb begin
    state_next = STATE_IDLE;

    address_next = address_reg;
    address_ptr_next = address_ptr_reg;
    data_ptr_next = data_ptr_reg;

    cur_address_next = cur_address_reg;

    delay_counter_next = delay_counter_reg;

    m_axis_cmd_address_next = m_axis_cmd_address_reg;
    m_axis_cmd_start_next = m_axis_cmd_start_reg && !(m_axis_cmd.tvalid && m_axis_cmd.tready);
    m_axis_cmd_write_next = m_axis_cmd_write_reg && !(m_axis_cmd.tvalid && m_axis_cmd.tready);
    m_axis_cmd_stop_next = m_axis_cmd_stop_reg && !(m_axis_cmd.tvalid && m_axis_cmd.tready);
    m_axis_cmd_valid_next = m_axis_cmd_valid_reg && !m_axis_cmd.tready;

    m_axis_tx_tdata_next = m_axis_tx_tdata_reg;
    m_axis_tx_tvalid_next = m_axis_tx_tvalid_reg && !m_axis_tx.tready;

    start_flag_next = start_flag_reg;

    if (m_axis_cmd.tvalid || m_axis_tx.tvalid) begin
        // wait for output registers to clear
        state_next = state_reg;
    end else if (delay_counter_reg != 0) begin
        // delay
        delay_counter_next = delay_counter_reg - 1;
        state_next = state_reg;
    end else begin
        case (state_reg)
            STATE_IDLE: begin
                // wait for start signal
                if (!start_flag_reg && start) begin
                    address_next = '0;
                    start_flag_next = 1'b1;
                    state_next = STATE_RUN;
                end else begin
                    state_next = STATE_IDLE;
                end
            end
            STATE_RUN: begin
                // process commands
                if (init_data_reg[8] == 1'b1) begin
                    // write data
                    m_axis_cmd_write_next = 1'b1;
                    m_axis_cmd_stop_next = 1'b0;
                    m_axis_cmd_valid_next = 1'b1;

                    m_axis_tx_tdata_next = init_data_reg[7:0];
                    m_axis_tx_tvalid_next = 1'b1;

                    address_next = address_reg + 1;

                    state_next = STATE_RUN;
                end else if (init_data_reg[8:7] == 2'b01) begin
                    // write address
                    m_axis_cmd_address_next = init_data_reg[6:0];
                    m_axis_cmd_start_next = 1'b1;

                    address_next = address_reg + 1;

                    state_next = STATE_RUN;
                end else if (init_data_reg[8:4] == 5'b00001) begin
                    // delay
                    if (SIM_SPEEDUP) begin
                        delay_counter_next = 32'd1 << (init_data_reg[3:0]);
                    end else begin
                        delay_counter_next = 32'd1 << (init_data_reg[3:0]+16);
                    end

                    address_next = address_reg + 1;

                    state_next = STATE_RUN;
                end else if (init_data_reg == 9'b001000001) begin
                    // send stop
                    m_axis_cmd_write_next = 1'b0;
                    m_axis_cmd_start_next = 1'b0;
                    m_axis_cmd_stop_next = 1'b1;
                    m_axis_cmd_valid_next = 1'b1;

                    address_next = address_reg + 1;

                    state_next = STATE_RUN;
                end else if (init_data_reg == 9'b000001001) begin
                    // data table start
                    data_ptr_next = address_reg + 1;
                    address_next = address_reg + 1;
                    state_next = STATE_TABLE_1;
                end else if (init_data_reg == 9'd0) begin
                    // stop
                    m_axis_cmd_start_next = 1'b0;
                    m_axis_cmd_write_next = 1'b0;
                    m_axis_cmd_stop_next = 1'b1;
                    m_axis_cmd_valid_next = 1'b1;

                    state_next = STATE_IDLE;
                end else begin
                    // invalid command, skip
                    address_next = address_reg + 1;
                    state_next = STATE_RUN;
                end
            end
            STATE_TABLE_1: begin
                // find address table start
                if (init_data_reg == 9'b000001000) begin
                    // address table start
                    address_ptr_next = address_reg + 1;
                    address_next = address_reg + 1;
                    state_next = STATE_TABLE_2;
                end else if (init_data_reg == 9'b000001001) begin
                    // data table start
                    data_ptr_next = address_reg + 1;
                    address_next = address_reg + 1;
                    state_next = STATE_TABLE_1;
                end else if (init_data_reg == 1) begin
                    // exit mode
                    address_next = address_reg + 1;
                    state_next = STATE_RUN;
                end else if (init_data_reg == 9'd0) begin
                    // stop
                    m_axis_cmd_start_next = 1'b0;
                    m_axis_cmd_write_next = 1'b0;
                    m_axis_cmd_stop_next = 1'b1;
                    m_axis_cmd_valid_next = 1'b1;

                    state_next = STATE_IDLE;
                end else begin
                    // invalid command, skip
                    address_next = address_reg + 1;
                    state_next = STATE_TABLE_1;
                end
            end
            STATE_TABLE_2: begin
                // find next address
                if (init_data_reg[8:7] == 2'b01) begin
                    // write address command
                    // store address and move to data table
                    cur_address_next = init_data_reg[6:0];
                    address_ptr_next = address_reg + 1;
                    address_next = data_ptr_reg;
                    state_next = STATE_TABLE_3;
                end else if (init_data_reg == 9'b000001001) begin
                    // data table start
                    data_ptr_next = address_reg + 1;
                    address_next = address_reg + 1;
                    state_next = STATE_TABLE_1;
                end else if (init_data_reg == 9'd1) begin
                    // exit mode
                    address_next = address_reg + 1;
                    state_next = STATE_RUN;
                end else if (init_data_reg == 9'd0) begin
                    // stop
                    m_axis_cmd_start_next = 1'b0;
                    m_axis_cmd_write_next = 1'b0;
                    m_axis_cmd_stop_next = 1'b1;
                    m_axis_cmd_valid_next = 1'b1;

                    state_next = STATE_IDLE;
                end else begin
                    // invalid command, skip
                    address_next = address_reg + 1;
                    state_next = STATE_TABLE_2;
                end
            end
            STATE_TABLE_3: begin
                // process data table with selected address
                if (init_data_reg[8] == 1'b1) begin
                    // write data
                    m_axis_cmd_write_next = 1'b1;
                    m_axis_cmd_stop_next = 1'b0;
                    m_axis_cmd_valid_next = 1'b1;

                    m_axis_tx_tdata_next = init_data_reg[7:0];
                    m_axis_tx_tvalid_next = 1'b1;

                    address_next = address_reg + 1;

                    state_next = STATE_TABLE_3;
                end else if (init_data_reg[8:7] == 2'b01) begin
                    // write address
                    m_axis_cmd_address_next = init_data_reg[6:0];
                    m_axis_cmd_start_next = 1'b1;

                    address_next = address_reg + 1;

                    state_next = STATE_TABLE_3;
                end else if (init_data_reg == 9'b000000011) begin
                    // write current address
                    m_axis_cmd_address_next = cur_address_reg;
                    m_axis_cmd_start_next = 1'b1;

                    address_next = address_reg + 1;

                    state_next = STATE_TABLE_3;
                end else if (init_data_reg[8:4] == 5'b00001) begin
                    // delay
                    if (SIM_SPEEDUP) begin
                        delay_counter_next = 32'd1 << (init_data_reg[3:0]);
                    end else begin
                        delay_counter_next = 32'd1 << (init_data_reg[3:0]+16);
                    end

                    address_next = address_reg + 1;

                    state_next = STATE_TABLE_3;
                end else if (init_data_reg == 9'b001000001) begin
                    // send stop
                    m_axis_cmd_write_next = 1'b0;
                    m_axis_cmd_start_next = 1'b0;
                    m_axis_cmd_stop_next = 1'b1;
                    m_axis_cmd_valid_next = 1'b1;

                    address_next = address_reg + 1;

                    state_next = STATE_TABLE_3;
                end else if (init_data_reg == 9'b000001001) begin
                    // data table start
                    data_ptr_next = address_reg + 1;
                    address_next = address_reg + 1;
                    state_next = STATE_TABLE_1;
                end else if (init_data_reg == 9'b000001000) begin
                    // address table start
                    address_next = address_ptr_reg;
                    state_next = STATE_TABLE_2;
                end else if (init_data_reg == 9'd1) begin
                    // exit mode
                    address_next = address_reg + 1;
                    state_next = STATE_RUN;
                end else if (init_data_reg == 9'd0) begin
                    // stop
                    m_axis_cmd_start_next = 1'b0;
                    m_axis_cmd_write_next = 1'b0;
                    m_axis_cmd_stop_next = 1'b1;
                    m_axis_cmd_valid_next = 1'b1;

                    state_next = STATE_IDLE;
                end else begin
                    // invalid command, skip
                    address_next = address_reg + 1;
                    state_next = STATE_TABLE_3;
                end
            end
            default: begin
                // invalid state
                state_next = STATE_IDLE;
            end
        endcase
    end
end

always_ff @(posedge clk) begin
    state_reg <= state_next;

    // read init_data ROM
    init_data_reg <= init_data[address_next];

    address_reg <= address_next;
    address_ptr_reg <= address_ptr_next;
    data_ptr_reg <= data_ptr_next;

    cur_address_reg <= cur_address_next;

    delay_counter_reg <= delay_counter_next;

    m_axis_cmd_address_reg <= m_axis_cmd_address_next;
    m_axis_cmd_start_reg <= m_axis_cmd_start_next;
    m_axis_cmd_write_reg <= m_axis_cmd_write_next;
    m_axis_cmd_stop_reg <= m_axis_cmd_stop_next;
    m_axis_cmd_valid_reg <= m_axis_cmd_valid_next;

    m_axis_tx_tdata_reg <= m_axis_tx_tdata_next;
    m_axis_tx_tvalid_reg <= m_axis_tx_tvalid_next;

    start_flag_reg <= start && start_flag_next;

    busy_reg <= (state_reg != STATE_IDLE);

    if (rst) begin
        state_reg <= STATE_IDLE;

        init_data_reg <= '0;

        address_reg <= '0;
        address_ptr_reg <= '0;
        data_ptr_reg <= '0;

        cur_address_reg <= '0;

        delay_counter_reg <= '0;

        m_axis_cmd_valid_reg <= 1'b0;

        m_axis_tx_tvalid_reg <= 1'b0;

        start_flag_reg <= 1'b0;

        busy_reg <= 1'b0;
    end
end

endmodule

`resetall
