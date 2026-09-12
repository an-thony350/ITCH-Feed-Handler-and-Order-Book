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
 * pll_i2c_init_em
 */
module pll_i2c_init_em #
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
localparam INIT_DATA_LEN = 1215;

reg [8:0] init_data [INIT_DATA_LEN-1:0];

initial begin
    // Initial delay
    init_data[0] = cmd_delay(6); // delay 30 ms
    // Set mux to select U48 Si5341 on HTG-ZRF8-EM
    init_data[1] = cmd_start(7'h71);
    init_data[2] = cmd_wr(8'h10);
    init_data[3] = cmd_stop(); // I2C stop
    // Si534x/7x/8x/9x Registers Script
    //
    // Part: Si5341
    // Project File: X:\Projects\taxi\src\eth\example\HTG_ZRF8\fpga\pll\HTG-ZRF8-EM-161-ZRF8EM01.slabtimeproj
    // Design ID: ZRF8EM01
    // Includes Pre/Post Download Control Register Writes: Yes
    // Die Revision: B1
    // Creator: ClockBuilder Pro v4.1 [2021-09-22]
    // Created On: 2025-09-02 08:11:56 GMT-07:00
    //
    // Start configuration preamble
    init_data[4] = cmd_start(7'h74);
    init_data[5] = cmd_wr(8'h01);
    init_data[6] = cmd_wr(8'h0b); // set page 0x0b
    init_data[7] = cmd_start(7'h74);
    init_data[8] = cmd_wr(8'h24);
    init_data[9] = cmd_wr(8'hc0); // write 0xc0 to 0x0b24
    init_data[10] = cmd_wr(8'h00); // write 0x00 to 0x0b25
    // Rev D stuck divider fix
    init_data[11] = cmd_start(7'h74);
    init_data[12] = cmd_wr(8'h01);
    init_data[13] = cmd_wr(8'h05); // set page 0x05
    init_data[14] = cmd_start(7'h74);
    init_data[15] = cmd_wr(8'h02);
    init_data[16] = cmd_wr(8'h01); // write 0x01 to 0x0502
    init_data[17] = cmd_start(7'h74);
    init_data[18] = cmd_wr(8'h05);
    init_data[19] = cmd_wr(8'h03); // write 0x03 to 0x0505
    init_data[20] = cmd_start(7'h74);
    init_data[21] = cmd_wr(8'h01);
    init_data[22] = cmd_wr(8'h09); // set page 0x09
    init_data[23] = cmd_start(7'h74);
    init_data[24] = cmd_wr(8'h57);
    init_data[25] = cmd_wr(8'h17); // write 0x17 to 0x0957
    init_data[26] = cmd_start(7'h74);
    init_data[27] = cmd_wr(8'h01);
    init_data[28] = cmd_wr(8'h0b); // set page 0x0b
    init_data[29] = cmd_start(7'h74);
    init_data[30] = cmd_wr(8'h4e);
    init_data[31] = cmd_wr(8'h1a); // write 0x1a to 0x0b4e
    // End configuration preamble
    //
    // Delay 300 msec
    init_data[32] = cmd_delay(10); // delay 300 ms
    // Delay is worst case time for device to complete any calibration
    // that is running due to device state change previous to this script
    // being processed.
    //
    // Start configuration registers
    init_data[33] = cmd_start(7'h74);
    init_data[34] = cmd_wr(8'h01);
    init_data[35] = cmd_wr(8'h00); // set page 0x00
    init_data[36] = cmd_start(7'h74);
    init_data[37] = cmd_wr(8'h06);
    init_data[38] = cmd_wr(8'h00); // write 0x00 to 0x0006
    init_data[39] = cmd_wr(8'h00); // write 0x00 to 0x0007
    init_data[40] = cmd_wr(8'h00); // write 0x00 to 0x0008
    init_data[41] = cmd_start(7'h74);
    init_data[42] = cmd_wr(8'h0b);
    init_data[43] = cmd_wr(8'h74); // write 0x74 to 0x000b
    init_data[44] = cmd_start(7'h74);
    init_data[45] = cmd_wr(8'h17);
    init_data[46] = cmd_wr(8'hd0); // write 0xd0 to 0x0017
    init_data[47] = cmd_wr(8'hff); // write 0xff to 0x0018
    init_data[48] = cmd_start(7'h74);
    init_data[49] = cmd_wr(8'h21);
    init_data[50] = cmd_wr(8'h0f); // write 0x0f to 0x0021
    init_data[51] = cmd_wr(8'h00); // write 0x00 to 0x0022
    init_data[52] = cmd_start(7'h74);
    init_data[53] = cmd_wr(8'h2b);
    init_data[54] = cmd_wr(8'h02); // write 0x02 to 0x002b
    init_data[55] = cmd_wr(8'h20); // write 0x20 to 0x002c
    init_data[56] = cmd_wr(8'h00); // write 0x00 to 0x002d
    init_data[57] = cmd_wr(8'h00); // write 0x00 to 0x002e
    init_data[58] = cmd_wr(8'h00); // write 0x00 to 0x002f
    init_data[59] = cmd_wr(8'h00); // write 0x00 to 0x0030
    init_data[60] = cmd_wr(8'h00); // write 0x00 to 0x0031
    init_data[61] = cmd_wr(8'h00); // write 0x00 to 0x0032
    init_data[62] = cmd_wr(8'h00); // write 0x00 to 0x0033
    init_data[63] = cmd_wr(8'h00); // write 0x00 to 0x0034
    init_data[64] = cmd_wr(8'h00); // write 0x00 to 0x0035
    init_data[65] = cmd_wr(8'h00); // write 0x00 to 0x0036
    init_data[66] = cmd_wr(8'h00); // write 0x00 to 0x0037
    init_data[67] = cmd_wr(8'h00); // write 0x00 to 0x0038
    init_data[68] = cmd_wr(8'h00); // write 0x00 to 0x0039
    init_data[69] = cmd_wr(8'h00); // write 0x00 to 0x003a
    init_data[70] = cmd_wr(8'h00); // write 0x00 to 0x003b
    init_data[71] = cmd_wr(8'h00); // write 0x00 to 0x003c
    init_data[72] = cmd_wr(8'h00); // write 0x00 to 0x003d
    init_data[73] = cmd_start(7'h74);
    init_data[74] = cmd_wr(8'h41);
    init_data[75] = cmd_wr(8'h00); // write 0x00 to 0x0041
    init_data[76] = cmd_wr(8'h00); // write 0x00 to 0x0042
    init_data[77] = cmd_wr(8'h00); // write 0x00 to 0x0043
    init_data[78] = cmd_wr(8'h00); // write 0x00 to 0x0044
    init_data[79] = cmd_start(7'h74);
    init_data[80] = cmd_wr(8'h9e);
    init_data[81] = cmd_wr(8'h00); // write 0x00 to 0x009e
    init_data[82] = cmd_start(7'h74);
    init_data[83] = cmd_wr(8'h01);
    init_data[84] = cmd_wr(8'h01); // set page 0x01
    init_data[85] = cmd_start(7'h74);
    init_data[86] = cmd_wr(8'h02);
    init_data[87] = cmd_wr(8'h01); // write 0x01 to 0x0102
    init_data[88] = cmd_start(7'h74);
    init_data[89] = cmd_wr(8'h08);
    init_data[90] = cmd_wr(8'h02); // write 0x02 to 0x0108
    init_data[91] = cmd_wr(8'h09); // write 0x09 to 0x0109
    init_data[92] = cmd_wr(8'h33); // write 0x33 to 0x010a
    init_data[93] = cmd_wr(8'h08); // write 0x08 to 0x010b
    init_data[94] = cmd_start(7'h74);
    init_data[95] = cmd_wr(8'h0d);
    init_data[96] = cmd_wr(8'h02); // write 0x02 to 0x010d
    init_data[97] = cmd_wr(8'h09); // write 0x09 to 0x010e
    init_data[98] = cmd_wr(8'h33); // write 0x33 to 0x010f
    init_data[99] = cmd_wr(8'h0a); // write 0x0a to 0x0110
    init_data[100] = cmd_start(7'h74);
    init_data[101] = cmd_wr(8'h12);
    init_data[102] = cmd_wr(8'h02); // write 0x02 to 0x0112
    init_data[103] = cmd_wr(8'h09); // write 0x09 to 0x0113
    init_data[104] = cmd_wr(8'h33); // write 0x33 to 0x0114
    init_data[105] = cmd_wr(8'h0b); // write 0x0b to 0x0115
    init_data[106] = cmd_start(7'h74);
    init_data[107] = cmd_wr(8'h17);
    init_data[108] = cmd_wr(8'h06); // write 0x06 to 0x0117
    init_data[109] = cmd_wr(8'h09); // write 0x09 to 0x0118
    init_data[110] = cmd_wr(8'h33); // write 0x33 to 0x0119
    init_data[111] = cmd_wr(8'h09); // write 0x09 to 0x011a
    init_data[112] = cmd_start(7'h74);
    init_data[113] = cmd_wr(8'h1c);
    init_data[114] = cmd_wr(8'h02); // write 0x02 to 0x011c
    init_data[115] = cmd_wr(8'h09); // write 0x09 to 0x011d
    init_data[116] = cmd_wr(8'h33); // write 0x33 to 0x011e
    init_data[117] = cmd_wr(8'h0b); // write 0x0b to 0x011f
    init_data[118] = cmd_start(7'h74);
    init_data[119] = cmd_wr(8'h21);
    init_data[120] = cmd_wr(8'h02); // write 0x02 to 0x0121
    init_data[121] = cmd_wr(8'h09); // write 0x09 to 0x0122
    init_data[122] = cmd_wr(8'h33); // write 0x33 to 0x0123
    init_data[123] = cmd_wr(8'h08); // write 0x08 to 0x0124
    init_data[124] = cmd_start(7'h74);
    init_data[125] = cmd_wr(8'h26);
    init_data[126] = cmd_wr(8'h02); // write 0x02 to 0x0126
    init_data[127] = cmd_wr(8'h09); // write 0x09 to 0x0127
    init_data[128] = cmd_wr(8'h33); // write 0x33 to 0x0128
    init_data[129] = cmd_wr(8'h08); // write 0x08 to 0x0129
    init_data[130] = cmd_start(7'h74);
    init_data[131] = cmd_wr(8'h2b);
    init_data[132] = cmd_wr(8'h02); // write 0x02 to 0x012b
    init_data[133] = cmd_wr(8'h09); // write 0x09 to 0x012c
    init_data[134] = cmd_wr(8'h33); // write 0x33 to 0x012d
    init_data[135] = cmd_wr(8'h0a); // write 0x0a to 0x012e
    init_data[136] = cmd_start(7'h74);
    init_data[137] = cmd_wr(8'h30);
    init_data[138] = cmd_wr(8'h02); // write 0x02 to 0x0130
    init_data[139] = cmd_wr(8'h09); // write 0x09 to 0x0131
    init_data[140] = cmd_wr(8'h33); // write 0x33 to 0x0132
    init_data[141] = cmd_wr(8'h0a); // write 0x0a to 0x0133
    init_data[142] = cmd_start(7'h74);
    init_data[143] = cmd_wr(8'h3a);
    init_data[144] = cmd_wr(8'h02); // write 0x02 to 0x013a
    init_data[145] = cmd_wr(8'h09); // write 0x09 to 0x013b
    init_data[146] = cmd_wr(8'h33); // write 0x33 to 0x013c
    init_data[147] = cmd_wr(8'h0a); // write 0x0a to 0x013d
    init_data[148] = cmd_start(7'h74);
    init_data[149] = cmd_wr(8'h3f);
    init_data[150] = cmd_wr(8'h00); // write 0x00 to 0x013f
    init_data[151] = cmd_wr(8'h00); // write 0x00 to 0x0140
    init_data[152] = cmd_wr(8'h40); // write 0x40 to 0x0141
    init_data[153] = cmd_start(7'h74);
    init_data[154] = cmd_wr(8'h01);
    init_data[155] = cmd_wr(8'h02); // set page 0x02
    init_data[156] = cmd_start(7'h74);
    init_data[157] = cmd_wr(8'h06);
    init_data[158] = cmd_wr(8'h00); // write 0x00 to 0x0206
    init_data[159] = cmd_start(7'h74);
    init_data[160] = cmd_wr(8'h08);
    init_data[161] = cmd_wr(8'h00); // write 0x00 to 0x0208
    init_data[162] = cmd_wr(8'h00); // write 0x00 to 0x0209
    init_data[163] = cmd_wr(8'h00); // write 0x00 to 0x020a
    init_data[164] = cmd_wr(8'h00); // write 0x00 to 0x020b
    init_data[165] = cmd_wr(8'h00); // write 0x00 to 0x020c
    init_data[166] = cmd_wr(8'h00); // write 0x00 to 0x020d
    init_data[167] = cmd_wr(8'h00); // write 0x00 to 0x020e
    init_data[168] = cmd_wr(8'h00); // write 0x00 to 0x020f
    init_data[169] = cmd_wr(8'h00); // write 0x00 to 0x0210
    init_data[170] = cmd_wr(8'h00); // write 0x00 to 0x0211
    init_data[171] = cmd_wr(8'h00); // write 0x00 to 0x0212
    init_data[172] = cmd_wr(8'h00); // write 0x00 to 0x0213
    init_data[173] = cmd_wr(8'h00); // write 0x00 to 0x0214
    init_data[174] = cmd_wr(8'h00); // write 0x00 to 0x0215
    init_data[175] = cmd_wr(8'h00); // write 0x00 to 0x0216
    init_data[176] = cmd_wr(8'h00); // write 0x00 to 0x0217
    init_data[177] = cmd_wr(8'h00); // write 0x00 to 0x0218
    init_data[178] = cmd_wr(8'h00); // write 0x00 to 0x0219
    init_data[179] = cmd_wr(8'h00); // write 0x00 to 0x021a
    init_data[180] = cmd_wr(8'h00); // write 0x00 to 0x021b
    init_data[181] = cmd_wr(8'h00); // write 0x00 to 0x021c
    init_data[182] = cmd_wr(8'h00); // write 0x00 to 0x021d
    init_data[183] = cmd_wr(8'h00); // write 0x00 to 0x021e
    init_data[184] = cmd_wr(8'h00); // write 0x00 to 0x021f
    init_data[185] = cmd_wr(8'h00); // write 0x00 to 0x0220
    init_data[186] = cmd_wr(8'h00); // write 0x00 to 0x0221
    init_data[187] = cmd_wr(8'h00); // write 0x00 to 0x0222
    init_data[188] = cmd_wr(8'h00); // write 0x00 to 0x0223
    init_data[189] = cmd_wr(8'h00); // write 0x00 to 0x0224
    init_data[190] = cmd_wr(8'h00); // write 0x00 to 0x0225
    init_data[191] = cmd_wr(8'h00); // write 0x00 to 0x0226
    init_data[192] = cmd_wr(8'h00); // write 0x00 to 0x0227
    init_data[193] = cmd_wr(8'h00); // write 0x00 to 0x0228
    init_data[194] = cmd_wr(8'h00); // write 0x00 to 0x0229
    init_data[195] = cmd_wr(8'h00); // write 0x00 to 0x022a
    init_data[196] = cmd_wr(8'h00); // write 0x00 to 0x022b
    init_data[197] = cmd_wr(8'h00); // write 0x00 to 0x022c
    init_data[198] = cmd_wr(8'h00); // write 0x00 to 0x022d
    init_data[199] = cmd_wr(8'h00); // write 0x00 to 0x022e
    init_data[200] = cmd_wr(8'h00); // write 0x00 to 0x022f
    init_data[201] = cmd_start(7'h74);
    init_data[202] = cmd_wr(8'h35);
    init_data[203] = cmd_wr(8'h00); // write 0x00 to 0x0235
    init_data[204] = cmd_wr(8'h00); // write 0x00 to 0x0236
    init_data[205] = cmd_wr(8'h00); // write 0x00 to 0x0237
    init_data[206] = cmd_wr(8'h00); // write 0x00 to 0x0238
    init_data[207] = cmd_wr(8'h96); // write 0x96 to 0x0239
    init_data[208] = cmd_wr(8'h00); // write 0x00 to 0x023a
    init_data[209] = cmd_wr(8'h00); // write 0x00 to 0x023b
    init_data[210] = cmd_wr(8'h00); // write 0x00 to 0x023c
    init_data[211] = cmd_wr(8'h00); // write 0x00 to 0x023d
    init_data[212] = cmd_wr(8'h80); // write 0x80 to 0x023e
    init_data[213] = cmd_start(7'h74);
    init_data[214] = cmd_wr(8'h4a);
    init_data[215] = cmd_wr(8'h02); // write 0x02 to 0x024a
    init_data[216] = cmd_wr(8'h00); // write 0x00 to 0x024b
    init_data[217] = cmd_wr(8'h00); // write 0x00 to 0x024c
    init_data[218] = cmd_wr(8'h3b); // write 0x3b to 0x024d
    init_data[219] = cmd_wr(8'h00); // write 0x00 to 0x024e
    init_data[220] = cmd_wr(8'h00); // write 0x00 to 0x024f
    init_data[221] = cmd_wr(8'h1a); // write 0x1a to 0x0250
    init_data[222] = cmd_wr(8'h00); // write 0x00 to 0x0251
    init_data[223] = cmd_wr(8'h00); // write 0x00 to 0x0252
    init_data[224] = cmd_wr(8'h00); // write 0x00 to 0x0253
    init_data[225] = cmd_wr(8'h00); // write 0x00 to 0x0254
    init_data[226] = cmd_wr(8'h00); // write 0x00 to 0x0255
    init_data[227] = cmd_wr(8'h19); // write 0x19 to 0x0256
    init_data[228] = cmd_wr(8'h00); // write 0x00 to 0x0257
    init_data[229] = cmd_wr(8'h00); // write 0x00 to 0x0258
    init_data[230] = cmd_wr(8'h02); // write 0x02 to 0x0259
    init_data[231] = cmd_wr(8'h00); // write 0x00 to 0x025a
    init_data[232] = cmd_wr(8'h00); // write 0x00 to 0x025b
    init_data[233] = cmd_wr(8'h02); // write 0x02 to 0x025c
    init_data[234] = cmd_wr(8'h00); // write 0x00 to 0x025d
    init_data[235] = cmd_wr(8'h00); // write 0x00 to 0x025e
    init_data[236] = cmd_wr(8'h01); // write 0x01 to 0x025f
    init_data[237] = cmd_wr(8'h00); // write 0x00 to 0x0260
    init_data[238] = cmd_wr(8'h00); // write 0x00 to 0x0261
    init_data[239] = cmd_wr(8'h02); // write 0x02 to 0x0262
    init_data[240] = cmd_wr(8'h00); // write 0x00 to 0x0263
    init_data[241] = cmd_wr(8'h00); // write 0x00 to 0x0264
    init_data[242] = cmd_start(7'h74);
    init_data[243] = cmd_wr(8'h68);
    init_data[244] = cmd_wr(8'h01); // write 0x01 to 0x0268
    init_data[245] = cmd_wr(8'h00); // write 0x00 to 0x0269
    init_data[246] = cmd_wr(8'h00); // write 0x00 to 0x026a
    init_data[247] = cmd_wr(8'h5a); // write 0x5a to 0x026b
    init_data[248] = cmd_wr(8'h52); // write 0x52 to 0x026c
    init_data[249] = cmd_wr(8'h46); // write 0x46 to 0x026d
    init_data[250] = cmd_wr(8'h38); // write 0x38 to 0x026e
    init_data[251] = cmd_wr(8'h45); // write 0x45 to 0x026f
    init_data[252] = cmd_wr(8'h4d); // write 0x4d to 0x0270
    init_data[253] = cmd_wr(8'h30); // write 0x30 to 0x0271
    init_data[254] = cmd_wr(8'h31); // write 0x31 to 0x0272
    init_data[255] = cmd_start(7'h74);
    init_data[256] = cmd_wr(8'h01);
    init_data[257] = cmd_wr(8'h03); // set page 0x03
    init_data[258] = cmd_start(7'h74);
    init_data[259] = cmd_wr(8'h02);
    init_data[260] = cmd_wr(8'h00); // write 0x00 to 0x0302
    init_data[261] = cmd_wr(8'h00); // write 0x00 to 0x0303
    init_data[262] = cmd_wr(8'h00); // write 0x00 to 0x0304
    init_data[263] = cmd_wr(8'h00); // write 0x00 to 0x0305
    init_data[264] = cmd_wr(8'h08); // write 0x08 to 0x0306
    init_data[265] = cmd_wr(8'h00); // write 0x00 to 0x0307
    init_data[266] = cmd_wr(8'h00); // write 0x00 to 0x0308
    init_data[267] = cmd_wr(8'h00); // write 0x00 to 0x0309
    init_data[268] = cmd_wr(8'h80); // write 0x80 to 0x030a
    init_data[269] = cmd_wr(8'h89); // write 0x89 to 0x030b
    init_data[270] = cmd_wr(8'h00); // write 0x00 to 0x030c
    init_data[271] = cmd_wr(8'h00); // write 0x00 to 0x030d
    init_data[272] = cmd_wr(8'h00); // write 0x00 to 0x030e
    init_data[273] = cmd_wr(8'h00); // write 0x00 to 0x030f
    init_data[274] = cmd_wr(8'h00); // write 0x00 to 0x0310
    init_data[275] = cmd_wr(8'h24); // write 0x24 to 0x0311
    init_data[276] = cmd_wr(8'h00); // write 0x00 to 0x0312
    init_data[277] = cmd_wr(8'h00); // write 0x00 to 0x0313
    init_data[278] = cmd_wr(8'h00); // write 0x00 to 0x0314
    init_data[279] = cmd_wr(8'h00); // write 0x00 to 0x0315
    init_data[280] = cmd_wr(8'ha0); // write 0xa0 to 0x0316
    init_data[281] = cmd_wr(8'h00); // write 0x00 to 0x0317
    init_data[282] = cmd_wr(8'h00); // write 0x00 to 0x0318
    init_data[283] = cmd_wr(8'h00); // write 0x00 to 0x0319
    init_data[284] = cmd_wr(8'h00); // write 0x00 to 0x031a
    init_data[285] = cmd_wr(8'h00); // write 0x00 to 0x031b
    init_data[286] = cmd_wr(8'h06); // write 0x06 to 0x031c
    init_data[287] = cmd_wr(8'h00); // write 0x00 to 0x031d
    init_data[288] = cmd_wr(8'h00); // write 0x00 to 0x031e
    init_data[289] = cmd_wr(8'h00); // write 0x00 to 0x031f
    init_data[290] = cmd_wr(8'h00); // write 0x00 to 0x0320
    init_data[291] = cmd_wr(8'h80); // write 0x80 to 0x0321
    init_data[292] = cmd_wr(8'h00); // write 0x00 to 0x0322
    init_data[293] = cmd_wr(8'h00); // write 0x00 to 0x0323
    init_data[294] = cmd_wr(8'h00); // write 0x00 to 0x0324
    init_data[295] = cmd_wr(8'h00); // write 0x00 to 0x0325
    init_data[296] = cmd_wr(8'h40); // write 0x40 to 0x0326
    init_data[297] = cmd_wr(8'h06); // write 0x06 to 0x0327
    init_data[298] = cmd_wr(8'h00); // write 0x00 to 0x0328
    init_data[299] = cmd_wr(8'h00); // write 0x00 to 0x0329
    init_data[300] = cmd_wr(8'h00); // write 0x00 to 0x032a
    init_data[301] = cmd_wr(8'h00); // write 0x00 to 0x032b
    init_data[302] = cmd_wr(8'h9c); // write 0x9c to 0x032c
    init_data[303] = cmd_wr(8'h00); // write 0x00 to 0x032d
    init_data[304] = cmd_wr(8'h00); // write 0x00 to 0x032e
    init_data[305] = cmd_wr(8'h00); // write 0x00 to 0x032f
    init_data[306] = cmd_wr(8'h00); // write 0x00 to 0x0330
    init_data[307] = cmd_wr(8'h00); // write 0x00 to 0x0331
    init_data[308] = cmd_wr(8'h00); // write 0x00 to 0x0332
    init_data[309] = cmd_wr(8'h00); // write 0x00 to 0x0333
    init_data[310] = cmd_wr(8'h00); // write 0x00 to 0x0334
    init_data[311] = cmd_wr(8'h00); // write 0x00 to 0x0335
    init_data[312] = cmd_wr(8'h00); // write 0x00 to 0x0336
    init_data[313] = cmd_wr(8'h00); // write 0x00 to 0x0337
    init_data[314] = cmd_wr(8'h00); // write 0x00 to 0x0338
    init_data[315] = cmd_wr(8'h1f); // write 0x1f to 0x0339
    init_data[316] = cmd_start(7'h74);
    init_data[317] = cmd_wr(8'h3b);
    init_data[318] = cmd_wr(8'h00); // write 0x00 to 0x033b
    init_data[319] = cmd_wr(8'h00); // write 0x00 to 0x033c
    init_data[320] = cmd_wr(8'h00); // write 0x00 to 0x033d
    init_data[321] = cmd_wr(8'h00); // write 0x00 to 0x033e
    init_data[322] = cmd_wr(8'h00); // write 0x00 to 0x033f
    init_data[323] = cmd_wr(8'h00); // write 0x00 to 0x0340
    init_data[324] = cmd_wr(8'h00); // write 0x00 to 0x0341
    init_data[325] = cmd_wr(8'h00); // write 0x00 to 0x0342
    init_data[326] = cmd_wr(8'h00); // write 0x00 to 0x0343
    init_data[327] = cmd_wr(8'h00); // write 0x00 to 0x0344
    init_data[328] = cmd_wr(8'h00); // write 0x00 to 0x0345
    init_data[329] = cmd_wr(8'h00); // write 0x00 to 0x0346
    init_data[330] = cmd_wr(8'h00); // write 0x00 to 0x0347
    init_data[331] = cmd_wr(8'h00); // write 0x00 to 0x0348
    init_data[332] = cmd_wr(8'h00); // write 0x00 to 0x0349
    init_data[333] = cmd_wr(8'h00); // write 0x00 to 0x034a
    init_data[334] = cmd_wr(8'h00); // write 0x00 to 0x034b
    init_data[335] = cmd_wr(8'h00); // write 0x00 to 0x034c
    init_data[336] = cmd_wr(8'h00); // write 0x00 to 0x034d
    init_data[337] = cmd_wr(8'h00); // write 0x00 to 0x034e
    init_data[338] = cmd_wr(8'h00); // write 0x00 to 0x034f
    init_data[339] = cmd_wr(8'h00); // write 0x00 to 0x0350
    init_data[340] = cmd_wr(8'h00); // write 0x00 to 0x0351
    init_data[341] = cmd_wr(8'h00); // write 0x00 to 0x0352
    init_data[342] = cmd_wr(8'h00); // write 0x00 to 0x0353
    init_data[343] = cmd_wr(8'h00); // write 0x00 to 0x0354
    init_data[344] = cmd_wr(8'h00); // write 0x00 to 0x0355
    init_data[345] = cmd_wr(8'h00); // write 0x00 to 0x0356
    init_data[346] = cmd_wr(8'h00); // write 0x00 to 0x0357
    init_data[347] = cmd_wr(8'h00); // write 0x00 to 0x0358
    init_data[348] = cmd_wr(8'h00); // write 0x00 to 0x0359
    init_data[349] = cmd_wr(8'h00); // write 0x00 to 0x035a
    init_data[350] = cmd_wr(8'h00); // write 0x00 to 0x035b
    init_data[351] = cmd_wr(8'h00); // write 0x00 to 0x035c
    init_data[352] = cmd_wr(8'h00); // write 0x00 to 0x035d
    init_data[353] = cmd_wr(8'h00); // write 0x00 to 0x035e
    init_data[354] = cmd_wr(8'h00); // write 0x00 to 0x035f
    init_data[355] = cmd_wr(8'h00); // write 0x00 to 0x0360
    init_data[356] = cmd_wr(8'h00); // write 0x00 to 0x0361
    init_data[357] = cmd_wr(8'h00); // write 0x00 to 0x0362
    init_data[358] = cmd_start(7'h74);
    init_data[359] = cmd_wr(8'h01);
    init_data[360] = cmd_wr(8'h08); // set page 0x08
    init_data[361] = cmd_start(7'h74);
    init_data[362] = cmd_wr(8'h02);
    init_data[363] = cmd_wr(8'h00); // write 0x00 to 0x0802
    init_data[364] = cmd_wr(8'h00); // write 0x00 to 0x0803
    init_data[365] = cmd_wr(8'h00); // write 0x00 to 0x0804
    init_data[366] = cmd_wr(8'h00); // write 0x00 to 0x0805
    init_data[367] = cmd_wr(8'h00); // write 0x00 to 0x0806
    init_data[368] = cmd_wr(8'h00); // write 0x00 to 0x0807
    init_data[369] = cmd_wr(8'h00); // write 0x00 to 0x0808
    init_data[370] = cmd_wr(8'h00); // write 0x00 to 0x0809
    init_data[371] = cmd_wr(8'h00); // write 0x00 to 0x080a
    init_data[372] = cmd_wr(8'h00); // write 0x00 to 0x080b
    init_data[373] = cmd_wr(8'h00); // write 0x00 to 0x080c
    init_data[374] = cmd_wr(8'h00); // write 0x00 to 0x080d
    init_data[375] = cmd_wr(8'h00); // write 0x00 to 0x080e
    init_data[376] = cmd_wr(8'h00); // write 0x00 to 0x080f
    init_data[377] = cmd_wr(8'h00); // write 0x00 to 0x0810
    init_data[378] = cmd_wr(8'h00); // write 0x00 to 0x0811
    init_data[379] = cmd_wr(8'h00); // write 0x00 to 0x0812
    init_data[380] = cmd_wr(8'h00); // write 0x00 to 0x0813
    init_data[381] = cmd_wr(8'h00); // write 0x00 to 0x0814
    init_data[382] = cmd_wr(8'h00); // write 0x00 to 0x0815
    init_data[383] = cmd_wr(8'h00); // write 0x00 to 0x0816
    init_data[384] = cmd_wr(8'h00); // write 0x00 to 0x0817
    init_data[385] = cmd_wr(8'h00); // write 0x00 to 0x0818
    init_data[386] = cmd_wr(8'h00); // write 0x00 to 0x0819
    init_data[387] = cmd_wr(8'h00); // write 0x00 to 0x081a
    init_data[388] = cmd_wr(8'h00); // write 0x00 to 0x081b
    init_data[389] = cmd_wr(8'h00); // write 0x00 to 0x081c
    init_data[390] = cmd_wr(8'h00); // write 0x00 to 0x081d
    init_data[391] = cmd_wr(8'h00); // write 0x00 to 0x081e
    init_data[392] = cmd_wr(8'h00); // write 0x00 to 0x081f
    init_data[393] = cmd_wr(8'h00); // write 0x00 to 0x0820
    init_data[394] = cmd_wr(8'h00); // write 0x00 to 0x0821
    init_data[395] = cmd_wr(8'h00); // write 0x00 to 0x0822
    init_data[396] = cmd_wr(8'h00); // write 0x00 to 0x0823
    init_data[397] = cmd_wr(8'h00); // write 0x00 to 0x0824
    init_data[398] = cmd_wr(8'h00); // write 0x00 to 0x0825
    init_data[399] = cmd_wr(8'h00); // write 0x00 to 0x0826
    init_data[400] = cmd_wr(8'h00); // write 0x00 to 0x0827
    init_data[401] = cmd_wr(8'h00); // write 0x00 to 0x0828
    init_data[402] = cmd_wr(8'h00); // write 0x00 to 0x0829
    init_data[403] = cmd_wr(8'h00); // write 0x00 to 0x082a
    init_data[404] = cmd_wr(8'h00); // write 0x00 to 0x082b
    init_data[405] = cmd_wr(8'h00); // write 0x00 to 0x082c
    init_data[406] = cmd_wr(8'h00); // write 0x00 to 0x082d
    init_data[407] = cmd_wr(8'h00); // write 0x00 to 0x082e
    init_data[408] = cmd_wr(8'h00); // write 0x00 to 0x082f
    init_data[409] = cmd_wr(8'h00); // write 0x00 to 0x0830
    init_data[410] = cmd_wr(8'h00); // write 0x00 to 0x0831
    init_data[411] = cmd_wr(8'h00); // write 0x00 to 0x0832
    init_data[412] = cmd_wr(8'h00); // write 0x00 to 0x0833
    init_data[413] = cmd_wr(8'h00); // write 0x00 to 0x0834
    init_data[414] = cmd_wr(8'h00); // write 0x00 to 0x0835
    init_data[415] = cmd_wr(8'h00); // write 0x00 to 0x0836
    init_data[416] = cmd_wr(8'h00); // write 0x00 to 0x0837
    init_data[417] = cmd_wr(8'h00); // write 0x00 to 0x0838
    init_data[418] = cmd_wr(8'h00); // write 0x00 to 0x0839
    init_data[419] = cmd_wr(8'h00); // write 0x00 to 0x083a
    init_data[420] = cmd_wr(8'h00); // write 0x00 to 0x083b
    init_data[421] = cmd_wr(8'h00); // write 0x00 to 0x083c
    init_data[422] = cmd_wr(8'h00); // write 0x00 to 0x083d
    init_data[423] = cmd_wr(8'h00); // write 0x00 to 0x083e
    init_data[424] = cmd_wr(8'h00); // write 0x00 to 0x083f
    init_data[425] = cmd_wr(8'h00); // write 0x00 to 0x0840
    init_data[426] = cmd_wr(8'h00); // write 0x00 to 0x0841
    init_data[427] = cmd_wr(8'h00); // write 0x00 to 0x0842
    init_data[428] = cmd_wr(8'h00); // write 0x00 to 0x0843
    init_data[429] = cmd_wr(8'h00); // write 0x00 to 0x0844
    init_data[430] = cmd_wr(8'h00); // write 0x00 to 0x0845
    init_data[431] = cmd_wr(8'h00); // write 0x00 to 0x0846
    init_data[432] = cmd_wr(8'h00); // write 0x00 to 0x0847
    init_data[433] = cmd_wr(8'h00); // write 0x00 to 0x0848
    init_data[434] = cmd_wr(8'h00); // write 0x00 to 0x0849
    init_data[435] = cmd_wr(8'h00); // write 0x00 to 0x084a
    init_data[436] = cmd_wr(8'h00); // write 0x00 to 0x084b
    init_data[437] = cmd_wr(8'h00); // write 0x00 to 0x084c
    init_data[438] = cmd_wr(8'h00); // write 0x00 to 0x084d
    init_data[439] = cmd_wr(8'h00); // write 0x00 to 0x084e
    init_data[440] = cmd_wr(8'h00); // write 0x00 to 0x084f
    init_data[441] = cmd_wr(8'h00); // write 0x00 to 0x0850
    init_data[442] = cmd_wr(8'h00); // write 0x00 to 0x0851
    init_data[443] = cmd_wr(8'h00); // write 0x00 to 0x0852
    init_data[444] = cmd_wr(8'h00); // write 0x00 to 0x0853
    init_data[445] = cmd_wr(8'h00); // write 0x00 to 0x0854
    init_data[446] = cmd_wr(8'h00); // write 0x00 to 0x0855
    init_data[447] = cmd_wr(8'h00); // write 0x00 to 0x0856
    init_data[448] = cmd_wr(8'h00); // write 0x00 to 0x0857
    init_data[449] = cmd_wr(8'h00); // write 0x00 to 0x0858
    init_data[450] = cmd_wr(8'h00); // write 0x00 to 0x0859
    init_data[451] = cmd_wr(8'h00); // write 0x00 to 0x085a
    init_data[452] = cmd_wr(8'h00); // write 0x00 to 0x085b
    init_data[453] = cmd_wr(8'h00); // write 0x00 to 0x085c
    init_data[454] = cmd_wr(8'h00); // write 0x00 to 0x085d
    init_data[455] = cmd_wr(8'h00); // write 0x00 to 0x085e
    init_data[456] = cmd_wr(8'h00); // write 0x00 to 0x085f
    init_data[457] = cmd_wr(8'h00); // write 0x00 to 0x0860
    init_data[458] = cmd_wr(8'h00); // write 0x00 to 0x0861
    init_data[459] = cmd_start(7'h74);
    init_data[460] = cmd_wr(8'h01);
    init_data[461] = cmd_wr(8'h09); // set page 0x09
    init_data[462] = cmd_start(7'h74);
    init_data[463] = cmd_wr(8'h0e);
    init_data[464] = cmd_wr(8'h02); // write 0x02 to 0x090e
    init_data[465] = cmd_start(7'h74);
    init_data[466] = cmd_wr(8'h1c);
    init_data[467] = cmd_wr(8'h04); // write 0x04 to 0x091c
    init_data[468] = cmd_start(7'h74);
    init_data[469] = cmd_wr(8'h43);
    init_data[470] = cmd_wr(8'h01); // write 0x01 to 0x0943
    init_data[471] = cmd_start(7'h74);
    init_data[472] = cmd_wr(8'h49);
    init_data[473] = cmd_wr(8'h00); // write 0x00 to 0x0949
    init_data[474] = cmd_wr(8'h00); // write 0x00 to 0x094a
    init_data[475] = cmd_start(7'h74);
    init_data[476] = cmd_wr(8'h4e);
    init_data[477] = cmd_wr(8'h49); // write 0x49 to 0x094e
    init_data[478] = cmd_wr(8'h02); // write 0x02 to 0x094f
    init_data[479] = cmd_start(7'h74);
    init_data[480] = cmd_wr(8'h5e);
    init_data[481] = cmd_wr(8'h00); // write 0x00 to 0x095e
    init_data[482] = cmd_start(7'h74);
    init_data[483] = cmd_wr(8'h01);
    init_data[484] = cmd_wr(8'h0a); // set page 0x0a
    init_data[485] = cmd_start(7'h74);
    init_data[486] = cmd_wr(8'h02);
    init_data[487] = cmd_wr(8'h00); // write 0x00 to 0x0a02
    init_data[488] = cmd_wr(8'h0f); // write 0x0f to 0x0a03
    init_data[489] = cmd_wr(8'h04); // write 0x04 to 0x0a04
    init_data[490] = cmd_wr(8'h0f); // write 0x0f to 0x0a05
    init_data[491] = cmd_start(7'h74);
    init_data[492] = cmd_wr(8'h14);
    init_data[493] = cmd_wr(8'h00); // write 0x00 to 0x0a14
    init_data[494] = cmd_start(7'h74);
    init_data[495] = cmd_wr(8'h1a);
    init_data[496] = cmd_wr(8'h00); // write 0x00 to 0x0a1a
    init_data[497] = cmd_start(7'h74);
    init_data[498] = cmd_wr(8'h20);
    init_data[499] = cmd_wr(8'h00); // write 0x00 to 0x0a20
    init_data[500] = cmd_start(7'h74);
    init_data[501] = cmd_wr(8'h26);
    init_data[502] = cmd_wr(8'h00); // write 0x00 to 0x0a26
    init_data[503] = cmd_start(7'h74);
    init_data[504] = cmd_wr(8'h2c);
    init_data[505] = cmd_wr(8'h00); // write 0x00 to 0x0a2c
    init_data[506] = cmd_start(7'h74);
    init_data[507] = cmd_wr(8'h01);
    init_data[508] = cmd_wr(8'h0b); // set page 0x0b
    init_data[509] = cmd_start(7'h74);
    init_data[510] = cmd_wr(8'h44);
    init_data[511] = cmd_wr(8'h0f); // write 0x0f to 0x0b44
    init_data[512] = cmd_start(7'h74);
    init_data[513] = cmd_wr(8'h4a);
    init_data[514] = cmd_wr(8'h10); // write 0x10 to 0x0b4a
    init_data[515] = cmd_start(7'h74);
    init_data[516] = cmd_wr(8'h57);
    init_data[517] = cmd_wr(8'h0e); // write 0x0e to 0x0b57
    init_data[518] = cmd_wr(8'h01); // write 0x01 to 0x0b58
    // End configuration registers
    //
    // Start configuration postamble
    init_data[519] = cmd_start(7'h74);
    init_data[520] = cmd_wr(8'h01);
    init_data[521] = cmd_wr(8'h00); // set page 0x00
    init_data[522] = cmd_start(7'h74);
    init_data[523] = cmd_wr(8'h1c);
    init_data[524] = cmd_wr(8'h01); // write 0x01 to 0x001c
    init_data[525] = cmd_start(7'h74);
    init_data[526] = cmd_wr(8'h01);
    init_data[527] = cmd_wr(8'h0b); // set page 0x0b
    init_data[528] = cmd_start(7'h74);
    init_data[529] = cmd_wr(8'h24);
    init_data[530] = cmd_wr(8'hc3); // write 0xc3 to 0x0b24
    init_data[531] = cmd_wr(8'h02); // write 0x02 to 0x0b25
    // End configuration postamble
    // Set mux to select I2C-SPI bridge on HTG-ZRF8-EM
    init_data[532] = cmd_start(7'h71);
    init_data[533] = cmd_wr(8'h0a);
    init_data[534] = cmd_stop(); // I2C stop
    // Configure I2C-SPI bridge
    init_data[535] = cmd_start(7'h2a);
    init_data[536] = cmd_wr(8'hf0);
    init_data[537] = cmd_wr(8'h00);
    init_data[538] = cmd_start(7'h2a);
    init_data[539] = cmd_wr(8'hf6);
    init_data[540] = cmd_wr(8'h00);
    // Configuration for LMK04832 PLL on HTG-ZRF8-EM
    // PLL1
    // CLKin0 = 12.2880 MHz TCXO
    // CLKin1 = 10 MHz
    // CLKin0 R = 768
    // CLKin1 R = 625
    // PFD = in0 / R0 = in1 / R1 = 16 kHz
    // N1 = 7680
    // VCO = PFD * N1 = 122.88 MHz
    // Ext VCO is 122.88 MHz
    // PLL2
    // 122.88 MHz from ext VCO
    // VCO0 range 2440 - 2580 MHz
    // VCO1 range 2945 - 3255 MHz
    // R2 = 1536
    // P = 2
    // N2 = 15625
    // PFD = 122.88 / R2 = 0.08
    // VCO = PFD * P * N2 = 2500
    // VCO/10 = 250 MHz
    // VCO/250 = 10 MHz
    // VCO/1280 = 1.953125 MHz
    // CLKout0: DAC 228 SYSREF
    // CLKout1: SYNC_IN_PLL1/SYNC_IN_PLL2
    // CLKout2: RF_CLKOUT to Si5341
    // CLKout3: SYNC_IN_PLL3
    // CLKout4: CLK_IN_PLL3
    // CLKout5: NC
    // CLKout6: CLK_IN_PLL2
    // CLKout7: NC
    // CLKout8: LMK_CLK_OUT SMPM
    // CLKout9: NC
    // CLKout10: CLK_IN_PLL1
    // CLKout11: NC
    // CLKout12: SYSREF_FPGA
    // CLKout13: REFCLK_FPGA
    // Reset
    init_data[541] = cmd_start(7'h2a);
    init_data[542] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[543] = cmd_wr(8'h00); // address 0x0000
    init_data[544] = cmd_wr(8'h00);
    init_data[545] = cmd_wr(8'h80); // write 0x80
    // Configure outputs
    // DCLK0_1_DIV: 10 (2500/10 = 250)
    init_data[546] = cmd_start(7'h2a);
    init_data[547] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[548] = cmd_wr(8'h01); // address 0x0100
    init_data[549] = cmd_wr(8'h00);
    init_data[550] = cmd_wr(8'h0a); // write 0x0a
    // DCLK0_1_DDLY: 10
    init_data[551] = cmd_start(7'h2a);
    init_data[552] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[553] = cmd_wr(8'h01); // address 0x0101
    init_data[554] = cmd_wr(8'h01);
    init_data[555] = cmd_wr(8'h0a); // write 0x0a
    // CLKout0_1_PD
    init_data[556] = cmd_start(7'h2a);
    init_data[557] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[558] = cmd_wr(8'h01); // address 0x0102
    init_data[559] = cmd_wr(8'h02);
    init_data[560] = cmd_wr(8'h00); // write 0x00
    // CLKout0_SRC_MUX: 1 (sysref)
    init_data[561] = cmd_start(7'h2a);
    init_data[562] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[563] = cmd_wr(8'h01); // address 0x0103
    init_data[564] = cmd_wr(8'h03);
    init_data[565] = cmd_wr(8'h60); // write 0x60
    // CLKout1_SRC_MUX: 1 (sysref)
    init_data[566] = cmd_start(7'h2a);
    init_data[567] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[568] = cmd_wr(8'h01); // address 0x0104
    init_data[569] = cmd_wr(8'h04);
    init_data[570] = cmd_wr(8'h20); // write 0x20
    // SCLK0_1_ADLY: 0
    init_data[571] = cmd_start(7'h2a);
    init_data[572] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[573] = cmd_wr(8'h01); // address 0x0105
    init_data[574] = cmd_wr(8'h05);
    init_data[575] = cmd_wr(8'h00); // write 0x00
    // SCLK0_1_DDLY: 0
    init_data[576] = cmd_start(7'h2a);
    init_data[577] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[578] = cmd_wr(8'h01); // address 0x0106
    init_data[579] = cmd_wr(8'h06);
    init_data[580] = cmd_wr(8'h00); // write 0x00
    // CLKout0_FMT: 1 (LVDS)
    // CLKout1_FMT: 15 (CMOS norm/norm)
    init_data[581] = cmd_start(7'h2a);
    init_data[582] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[583] = cmd_wr(8'h01); // address 0x0107
    init_data[584] = cmd_wr(8'h07);
    init_data[585] = cmd_wr(8'hf1); // write 0xf1
    // DCLK2_3_DIV: 10 (2500/10 = 250)
    init_data[586] = cmd_start(7'h2a);
    init_data[587] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[588] = cmd_wr(8'h01); // address 0x0108
    init_data[589] = cmd_wr(8'h08);
    init_data[590] = cmd_wr(8'h0a); // write 0x0a
    // DCLK2_3_DDLY: 10
    init_data[591] = cmd_start(7'h2a);
    init_data[592] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[593] = cmd_wr(8'h01); // address 0x0109
    init_data[594] = cmd_wr(8'h09);
    init_data[595] = cmd_wr(8'h0a); // write 0x0a
    // CLKout2_3_PD
    init_data[596] = cmd_start(7'h2a);
    init_data[597] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[598] = cmd_wr(8'h01); // address 0x010a
    init_data[599] = cmd_wr(8'h0a);
    init_data[600] = cmd_wr(8'h00); // write 0x00
    // CLKout2_SRC_MUX: 0 (device clock)
    init_data[601] = cmd_start(7'h2a);
    init_data[602] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[603] = cmd_wr(8'h01); // address 0x010b
    init_data[604] = cmd_wr(8'h0b);
    init_data[605] = cmd_wr(8'h40); // write 0x40
    // CLKout3_SRC_MUX: 1 (sysref)
    init_data[606] = cmd_start(7'h2a);
    init_data[607] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[608] = cmd_wr(8'h01); // address 0x010c
    init_data[609] = cmd_wr(8'h0c);
    init_data[610] = cmd_wr(8'h20); // write 0x20
    // SCLK2_3_ADLY: 0
    init_data[611] = cmd_start(7'h2a);
    init_data[612] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[613] = cmd_wr(8'h01); // address 0x010d
    init_data[614] = cmd_wr(8'h0d);
    init_data[615] = cmd_wr(8'h00); // write 0x00
    // SCLK2_3_DDLY: 0
    init_data[616] = cmd_start(7'h2a);
    init_data[617] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[618] = cmd_wr(8'h01); // address 0x010e
    init_data[619] = cmd_wr(8'h0e);
    init_data[620] = cmd_wr(8'h00); // write 0x00
    // CLKout2_FMT: 1 (LVDS)
    // CLKout3_FMT: 12 (CMOS norm/norm)
    init_data[621] = cmd_start(7'h2a);
    init_data[622] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[623] = cmd_wr(8'h01); // address 0x010f
    init_data[624] = cmd_wr(8'h0f);
    init_data[625] = cmd_wr(8'hc1); // write 0xc1
    // DCLK4_5_DIV: 10 (2500/10 = 250)
    init_data[626] = cmd_start(7'h2a);
    init_data[627] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[628] = cmd_wr(8'h01); // address 0x0110
    init_data[629] = cmd_wr(8'h10);
    init_data[630] = cmd_wr(8'h0a); // write 0x0a
    // DCLK4_5_DDLY: 10
    init_data[631] = cmd_start(7'h2a);
    init_data[632] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[633] = cmd_wr(8'h01); // address 0x0111
    init_data[634] = cmd_wr(8'h11);
    init_data[635] = cmd_wr(8'h0a); // write 0x0a
    // CLKout4_5_PD
    init_data[636] = cmd_start(7'h2a);
    init_data[637] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[638] = cmd_wr(8'h01); // address 0x0112
    init_data[639] = cmd_wr(8'h12);
    init_data[640] = cmd_wr(8'h00); // write 0x00
    // CLKout4_SRC_MUX: 0 (device clock)
    init_data[641] = cmd_start(7'h2a);
    init_data[642] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[643] = cmd_wr(8'h01); // address 0x0113
    init_data[644] = cmd_wr(8'h13);
    init_data[645] = cmd_wr(8'h40); // write 0x40
    // CLKout5_SRC_MUX: 1 (sysref)
    init_data[646] = cmd_start(7'h2a);
    init_data[647] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[648] = cmd_wr(8'h01); // address 0x0114
    init_data[649] = cmd_wr(8'h14);
    init_data[650] = cmd_wr(8'h20); // write 0x20
    // SCLK4_5_ADLY: 0
    init_data[651] = cmd_start(7'h2a);
    init_data[652] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[653] = cmd_wr(8'h01); // address 0x0115
    init_data[654] = cmd_wr(8'h15);
    init_data[655] = cmd_wr(8'h00); // write 0x00
    // SCLK4_5_DDLY: 0
    init_data[656] = cmd_start(7'h2a);
    init_data[657] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[658] = cmd_wr(8'h01); // address 0x0116
    init_data[659] = cmd_wr(8'h16);
    init_data[660] = cmd_wr(8'h00); // write 0x00
    // CLKout4_FMT: 1 (LVDS)
    // CLKout5_FMT: 0 (PD)
    init_data[661] = cmd_start(7'h2a);
    init_data[662] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[663] = cmd_wr(8'h01); // address 0x0117
    init_data[664] = cmd_wr(8'h17);
    init_data[665] = cmd_wr(8'h01); // write 0x01
    // DCLK6_7_DIV: 10 (2500/10 = 250)
    init_data[666] = cmd_start(7'h2a);
    init_data[667] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[668] = cmd_wr(8'h01); // address 0x0118
    init_data[669] = cmd_wr(8'h18);
    init_data[670] = cmd_wr(8'h0a); // write 0x0a
    // DCLK6_7_DDLY: 10
    init_data[671] = cmd_start(7'h2a);
    init_data[672] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[673] = cmd_wr(8'h01); // address 0x0119
    init_data[674] = cmd_wr(8'h19);
    init_data[675] = cmd_wr(8'h0a); // write 0x0a
    // CLKout6_7_PD
    init_data[676] = cmd_start(7'h2a);
    init_data[677] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[678] = cmd_wr(8'h01); // address 0x011a
    init_data[679] = cmd_wr(8'h1a);
    init_data[680] = cmd_wr(8'h00); // write 0x00
    // CLKout6_SRC_MUX: 0 (device clock)
    init_data[681] = cmd_start(7'h2a);
    init_data[682] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[683] = cmd_wr(8'h01); // address 0x011b
    init_data[684] = cmd_wr(8'h1b);
    init_data[685] = cmd_wr(8'h40); // write 0x40
    // CLKout7_SRC_MUX: 1 (sysref)
    init_data[686] = cmd_start(7'h2a);
    init_data[687] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[688] = cmd_wr(8'h01); // address 0x011c
    init_data[689] = cmd_wr(8'h1c);
    init_data[690] = cmd_wr(8'h20); // write 0x20
    // SCLK6_7_ADLY: 0
    init_data[691] = cmd_start(7'h2a);
    init_data[692] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[693] = cmd_wr(8'h01); // address 0x011d
    init_data[694] = cmd_wr(8'h1d);
    init_data[695] = cmd_wr(8'h00); // write 0x00
    // SCLK6_7_DDLY: 0
    init_data[696] = cmd_start(7'h2a);
    init_data[697] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[698] = cmd_wr(8'h01); // address 0x011e
    init_data[699] = cmd_wr(8'h1e);
    init_data[700] = cmd_wr(8'h00); // write 0x00
    // CLKout6_FMT: 1 (LVDS)
    // CLKout7_FMT: 0 (PD)
    init_data[701] = cmd_start(7'h2a);
    init_data[702] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[703] = cmd_wr(8'h01); // address 0x011f
    init_data[704] = cmd_wr(8'h1f);
    init_data[705] = cmd_wr(8'h01); // write 0x01
    // DCLK8_9_DIV: 250 (2500/250 = 10)
    init_data[706] = cmd_start(7'h2a);
    init_data[707] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[708] = cmd_wr(8'h01); // address 0x0120
    init_data[709] = cmd_wr(8'h20);
    init_data[710] = cmd_wr(8'hfa); // write 0xfa
    // DCLK8_9_DDLY: 10
    init_data[711] = cmd_start(7'h2a);
    init_data[712] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[713] = cmd_wr(8'h01); // address 0x0121
    init_data[714] = cmd_wr(8'h21);
    init_data[715] = cmd_wr(8'h0a); // write 0x0a
    // CLKout8_9_PD
    init_data[716] = cmd_start(7'h2a);
    init_data[717] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[718] = cmd_wr(8'h01); // address 0x0122
    init_data[719] = cmd_wr(8'h22);
    init_data[720] = cmd_wr(8'h00); // write 0x00
    // CLKout8_SRC_MUX: 0 (device clock)
    init_data[721] = cmd_start(7'h2a);
    init_data[722] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[723] = cmd_wr(8'h01); // address 0x0123
    init_data[724] = cmd_wr(8'h23);
    init_data[725] = cmd_wr(8'h40); // write 0x40
    // CLKout9_SRC_MUX: 1 (sysref)
    init_data[726] = cmd_start(7'h2a);
    init_data[727] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[728] = cmd_wr(8'h01); // address 0x0124
    init_data[729] = cmd_wr(8'h24);
    init_data[730] = cmd_wr(8'h20); // write 0x20
    // SCLK8_9_ADLY: 0
    init_data[731] = cmd_start(7'h2a);
    init_data[732] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[733] = cmd_wr(8'h01); // address 0x0125
    init_data[734] = cmd_wr(8'h25);
    init_data[735] = cmd_wr(8'h00); // write 0x00
    // SCLK8_9_DDLY: 0
    init_data[736] = cmd_start(7'h2a);
    init_data[737] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[738] = cmd_wr(8'h01); // address 0x0126
    init_data[739] = cmd_wr(8'h26);
    init_data[740] = cmd_wr(8'h00); // write 0x00
    // CLKout8_FMT: 5 (LVPECL 2000 mV)
    // CLKout9_FMT: 0 (PD)
    init_data[741] = cmd_start(7'h2a);
    init_data[742] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[743] = cmd_wr(8'h01); // address 0x0127
    init_data[744] = cmd_wr(8'h27);
    init_data[745] = cmd_wr(8'h05); // write 0x05
    // DCLK10_11_DIV: 10 (2500/10 = 250)
    init_data[746] = cmd_start(7'h2a);
    init_data[747] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[748] = cmd_wr(8'h01); // address 0x0128
    init_data[749] = cmd_wr(8'h28);
    init_data[750] = cmd_wr(8'h0a); // write 0x0a
    // DCLK10_11_DDLY: 10
    init_data[751] = cmd_start(7'h2a);
    init_data[752] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[753] = cmd_wr(8'h01); // address 0x0129
    init_data[754] = cmd_wr(8'h29);
    init_data[755] = cmd_wr(8'h0a); // write 0x0a
    // CLKout10_11_PD
    init_data[756] = cmd_start(7'h2a);
    init_data[757] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[758] = cmd_wr(8'h01); // address 0x012a
    init_data[759] = cmd_wr(8'h2a);
    init_data[760] = cmd_wr(8'h00); // write 0x00
    // CLKout10_SRC_MUX: 0 (device clock)
    init_data[761] = cmd_start(7'h2a);
    init_data[762] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[763] = cmd_wr(8'h01); // address 0x012b
    init_data[764] = cmd_wr(8'h2b);
    init_data[765] = cmd_wr(8'h40); // write 0x40
    // CLKout11_SRC_MUX: 1 (sysref)
    init_data[766] = cmd_start(7'h2a);
    init_data[767] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[768] = cmd_wr(8'h01); // address 0x012c
    init_data[769] = cmd_wr(8'h2c);
    init_data[770] = cmd_wr(8'h20); // write 0x20
    // SCLK10_11_ADLY: 0
    init_data[771] = cmd_start(7'h2a);
    init_data[772] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[773] = cmd_wr(8'h01); // address 0x012d
    init_data[774] = cmd_wr(8'h2d);
    init_data[775] = cmd_wr(8'h00); // write 0x00
    // SCLK10_11_DDLY: 0
    init_data[776] = cmd_start(7'h2a);
    init_data[777] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[778] = cmd_wr(8'h01); // address 0x012e
    init_data[779] = cmd_wr(8'h2e);
    init_data[780] = cmd_wr(8'h00); // write 0x00
    // CLKout10_FMT: 1 (LVDS)
    // CLKout11_FMT: 0 (PD)
    init_data[781] = cmd_start(7'h2a);
    init_data[782] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[783] = cmd_wr(8'h01); // address 0x012f
    init_data[784] = cmd_wr(8'h2f);
    init_data[785] = cmd_wr(8'h01); // write 0x01
    // DCLK12_13_DIV: 10 (2500/10 = 250)
    init_data[786] = cmd_start(7'h2a);
    init_data[787] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[788] = cmd_wr(8'h01); // address 0x0130
    init_data[789] = cmd_wr(8'h30);
    init_data[790] = cmd_wr(8'h0a); // write 0x0a
    // DCLK12_13_DDLY: 10
    init_data[791] = cmd_start(7'h2a);
    init_data[792] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[793] = cmd_wr(8'h01); // address 0x0131
    init_data[794] = cmd_wr(8'h31);
    init_data[795] = cmd_wr(8'h0a); // write 0x0a
    // CLKout12_13_PD
    init_data[796] = cmd_start(7'h2a);
    init_data[797] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[798] = cmd_wr(8'h01); // address 0x0132
    init_data[799] = cmd_wr(8'h32);
    init_data[800] = cmd_wr(8'h00); // write 0x00
    // CLKout12_SRC_MUX: 1 (sysref)
    init_data[801] = cmd_start(7'h2a);
    init_data[802] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[803] = cmd_wr(8'h01); // address 0x0133
    init_data[804] = cmd_wr(8'h33);
    init_data[805] = cmd_wr(8'h60); // write 0x60
    // CLKout13_SRC_MUX: 0 (device clock)
    init_data[806] = cmd_start(7'h2a);
    init_data[807] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[808] = cmd_wr(8'h01); // address 0x0134
    init_data[809] = cmd_wr(8'h34);
    init_data[810] = cmd_wr(8'h00); // write 0x00
    // SCLK12_13_ADLY: 0
    init_data[811] = cmd_start(7'h2a);
    init_data[812] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[813] = cmd_wr(8'h01); // address 0x0135
    init_data[814] = cmd_wr(8'h35);
    init_data[815] = cmd_wr(8'h00); // write 0x00
    // SCLK12_13_DDLY: 0
    init_data[816] = cmd_start(7'h2a);
    init_data[817] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[818] = cmd_wr(8'h01); // address 0x0136
    init_data[819] = cmd_wr(8'h36);
    init_data[820] = cmd_wr(8'h00); // write 0x00
    // CLKout12_FMT: 1 (LVDS)
    // CLKout13_FMT: 1 (LVDS)
    init_data[821] = cmd_start(7'h2a);
    init_data[822] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[823] = cmd_wr(8'h01); // address 0x0137
    init_data[824] = cmd_wr(8'h37);
    init_data[825] = cmd_wr(8'h11); // write 0x11
    // configure PLL1
    // VCO_MUX: VCO0
    // OSCout_FMT: power down
    init_data[826] = cmd_start(7'h2a);
    init_data[827] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[828] = cmd_wr(8'h01); // address 0x0138
    init_data[829] = cmd_wr(8'h38);
    init_data[830] = cmd_wr(8'h00); // write 0x00
    // PLL2_RCLK_MUX: 0 (OSCin)
    // PLL2_NCLK_MUX: 0 (prescaler)
    // PLL1_NCLK_MUX: 0 (OSCin)
    // FB_MUX: 0
    // FB_MUX_EN: 0
    init_data[831] = cmd_start(7'h2a);
    init_data[832] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[833] = cmd_wr(8'h01); // address 0x013f
    init_data[834] = cmd_wr(8'h3f);
    init_data[835] = cmd_wr(8'h00); // write 0x00
    // release power down
    init_data[836] = cmd_start(7'h2a);
    init_data[837] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[838] = cmd_wr(8'h01); // address 0x0140
    init_data[839] = cmd_wr(8'h40);
    init_data[840] = cmd_wr(8'h00); // write 0x00
    // 0x141,0x00
    // 0x142,0x00
    // 0x143,0x00
    // 0x144,0x00
    // 0x145,0x00
    // enable CLKin0 and CLKin1 with bipolar buffers
    init_data[841] = cmd_start(7'h2a);
    init_data[842] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[843] = cmd_wr(8'h01); // address 0x0146
    init_data[844] = cmd_wr(8'h46);
    init_data[845] = cmd_wr(8'h18); // write 0x18
    // route CLKin0 and CLKin1 to PLL1, enable auto revert
    init_data[846] = cmd_start(7'h2a);
    init_data[847] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[848] = cmd_wr(8'h01); // address 0x0147
    init_data[849] = cmd_wr(8'h47);
    init_data[850] = cmd_wr(8'h8a); // write 0x8a
    // CLKin_SEL0: input
    init_data[851] = cmd_start(7'h2a);
    init_data[852] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[853] = cmd_wr(8'h01); // address 0x0148
    init_data[854] = cmd_wr(8'h48);
    init_data[855] = cmd_wr(8'h00); // write 0x00
    // CLKin_SEL1: input
    init_data[856] = cmd_start(7'h2a);
    init_data[857] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[858] = cmd_wr(8'h01); // address 0x0149
    init_data[859] = cmd_wr(8'h49);
    init_data[860] = cmd_wr(8'h00); // write 0x00
    // reset mux/type: input
    init_data[861] = cmd_start(7'h2a);
    init_data[862] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[863] = cmd_wr(8'h01); // address 0x014a
    init_data[864] = cmd_wr(8'h4a);
    init_data[865] = cmd_wr(8'h00); // write 0x00
    // auto DAC
    init_data[866] = cmd_start(7'h2a);
    init_data[867] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[868] = cmd_wr(8'h01); // address 0x014b
    init_data[869] = cmd_wr(8'h4b);
    init_data[870] = cmd_wr(8'h10); // write 0x10
    // MAN_DAC
    init_data[871] = cmd_start(7'h2a);
    init_data[872] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[873] = cmd_wr(8'h01); // address 0x014c
    init_data[874] = cmd_wr(8'h4c);
    init_data[875] = cmd_wr(8'h00); // write 0x00
    // DAC trip low: 0
    init_data[876] = cmd_start(7'h2a);
    init_data[877] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[878] = cmd_wr(8'h01); // address 0x014d
    init_data[879] = cmd_wr(8'h4d);
    init_data[880] = cmd_wr(8'h00); // write 0x00
    // DAC trip high: 63
    // DAC_CLK_MULT: 3 (16384)
    init_data[881] = cmd_start(7'h2a);
    init_data[882] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[883] = cmd_wr(8'h01); // address 0x014e
    init_data[884] = cmd_wr(8'h4e);
    init_data[885] = cmd_wr(8'hff); // write 0xff
    // DAC_CLK_CNTR
    init_data[886] = cmd_start(7'h2a);
    init_data[887] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[888] = cmd_wr(8'h01); // address 0x014f
    init_data[889] = cmd_wr(8'h4f);
    init_data[890] = cmd_wr(8'h7f); // write 0x7f
    // no holdover
    init_data[891] = cmd_start(7'h2a);
    init_data[892] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[893] = cmd_wr(8'h01); // address 0x0150
    init_data[894] = cmd_wr(8'h50);
    init_data[895] = cmd_wr(8'h00); // write 0x00
    // holdover DLD count
    // 0x151,0x00
    // 0x152,0x00
    // CLKin0 R = 768 (0x300)
    init_data[896] = cmd_start(7'h2a);
    init_data[897] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[898] = cmd_wr(8'h01); // address 0x0153
    init_data[899] = cmd_wr(8'h53);
    init_data[900] = cmd_wr(8'h03); // write 0x03
    init_data[901] = cmd_start(7'h2a);
    init_data[902] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[903] = cmd_wr(8'h01); // address 0x0154
    init_data[904] = cmd_wr(8'h54);
    init_data[905] = cmd_wr(8'h00); // write 0x00
    // CLKin1 R = 625 (0x271)
    init_data[906] = cmd_start(7'h2a);
    init_data[907] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[908] = cmd_wr(8'h01); // address 0x0155
    init_data[909] = cmd_wr(8'h55);
    init_data[910] = cmd_wr(8'h02); // write 0x02
    init_data[911] = cmd_start(7'h2a);
    init_data[912] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[913] = cmd_wr(8'h01); // address 0x0156
    init_data[914] = cmd_wr(8'h56);
    init_data[915] = cmd_wr(8'h71); // write 0x71
    // CLKin2 R
    // 0x157,0x00
    // 0x158,0x00
    // PLL1 N = 7680 (0x1e00)
    init_data[916] = cmd_start(7'h2a);
    init_data[917] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[918] = cmd_wr(8'h01); // address 0x0159
    init_data[919] = cmd_wr(8'h59);
    init_data[920] = cmd_wr(8'h1e); // write 0x1e
    init_data[921] = cmd_start(7'h2a);
    init_data[922] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[923] = cmd_wr(8'h01); // address 0x015a
    init_data[924] = cmd_wr(8'h5a);
    init_data[925] = cmd_wr(8'h00); // write 0x00
    // PLL1_WND_SIZE: 3
    // PLL1_CP_TRI: 0
    // PLL1_CP_POL: 1
    // PLL1_CP_GAIN: 4
    init_data[926] = cmd_start(7'h2a);
    init_data[927] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[928] = cmd_wr(8'h01); // address 0x015b
    init_data[929] = cmd_wr(8'h5b);
    init_data[930] = cmd_wr(8'hd4); // write 0xd4
    // PLL1_DLD_CNT: 32, 0
    init_data[931] = cmd_start(7'h2a);
    init_data[932] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[933] = cmd_wr(8'h01); // address 0x015c
    init_data[934] = cmd_wr(8'h5c);
    init_data[935] = cmd_wr(8'h20); // write 0x20
    init_data[936] = cmd_start(7'h2a);
    init_data[937] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[938] = cmd_wr(8'h01); // address 0x015d
    init_data[939] = cmd_wr(8'h5d);
    init_data[940] = cmd_wr(8'h00); // write 0x00
    // HOLDOVER_EXIT_NADJ: 30
    init_data[941] = cmd_start(7'h2a);
    init_data[942] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[943] = cmd_wr(8'h01); // address 0x015e
    init_data[944] = cmd_wr(8'h5e);
    init_data[945] = cmd_wr(8'h1e); // write 0x1e
    // PLL1 LD pin: SPI readback
    init_data[946] = cmd_start(7'h2a);
    init_data[947] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[948] = cmd_wr(8'h01); // address 0x015f
    init_data[949] = cmd_wr(8'h5f);
    init_data[950] = cmd_wr(8'h3b); // write 0x3b
    // configure PLL2
    // release PLL2 PD
    init_data[951] = cmd_start(7'h2a);
    init_data[952] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[953] = cmd_wr(8'h01); // address 0x0173
    init_data[954] = cmd_wr(8'h73);
    init_data[955] = cmd_wr(8'h10); // write 0x10
    // PLL2 R: 1536 (0x600)
    init_data[956] = cmd_start(7'h2a);
    init_data[957] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[958] = cmd_wr(8'h01); // address 0x0160
    init_data[959] = cmd_wr(8'h60);
    init_data[960] = cmd_wr(8'h06); // write 0x06
    init_data[961] = cmd_start(7'h2a);
    init_data[962] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[963] = cmd_wr(8'h01); // address 0x0161
    init_data[964] = cmd_wr(8'h61);
    init_data[965] = cmd_wr(8'h00); // write 0x00
    // PLL2 P: 2 (2)
    // OSCin_FREQ: 1 (63-127)
    // 2X: off
    init_data[966] = cmd_start(7'h2a);
    init_data[967] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[968] = cmd_wr(8'h01); // address 0x0162
    init_data[969] = cmd_wr(8'h62);
    init_data[970] = cmd_wr(8'h44); // write 0x44
    // PLL2_N_CAL: 15625 (0x3d09)
    init_data[971] = cmd_start(7'h2a);
    init_data[972] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[973] = cmd_wr(8'h01); // address 0x0163
    init_data[974] = cmd_wr(8'h63);
    init_data[975] = cmd_wr(8'h00); // write 0x00
    init_data[976] = cmd_start(7'h2a);
    init_data[977] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[978] = cmd_wr(8'h01); // address 0x0164
    init_data[979] = cmd_wr(8'h64);
    init_data[980] = cmd_wr(8'h3d); // write 0x3d
    init_data[981] = cmd_start(7'h2a);
    init_data[982] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[983] = cmd_wr(8'h01); // address 0x0165
    init_data[984] = cmd_wr(8'h65);
    init_data[985] = cmd_wr(8'h09); // write 0x09
    // PLL2_N_CAL: 15625 (0x3d09)
    init_data[986] = cmd_start(7'h2a);
    init_data[987] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[988] = cmd_wr(8'h01); // address 0x0166
    init_data[989] = cmd_wr(8'h66);
    init_data[990] = cmd_wr(8'h00); // write 0x00
    init_data[991] = cmd_start(7'h2a);
    init_data[992] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[993] = cmd_wr(8'h01); // address 0x0167
    init_data[994] = cmd_wr(8'h67);
    init_data[995] = cmd_wr(8'h3d); // write 0x3d
    init_data[996] = cmd_start(7'h2a);
    init_data[997] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[998] = cmd_wr(8'h01); // address 0x0168
    init_data[999] = cmd_wr(8'h68);
    init_data[1000] = cmd_wr(8'h09); // write 0x09
    // PLL2_WND_SIZE: 2 (1.8 ns)
    // PLL2_CP_GAIN: 3
    // PLL2_CP_POL: 0
    // PLL2_CP_TRI: 0
    // PLL2_DLD_EN: 1
    init_data[1001] = cmd_start(7'h2a);
    init_data[1002] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[1003] = cmd_wr(8'h01); // address 0x0169
    init_data[1004] = cmd_wr(8'h69);
    init_data[1005] = cmd_wr(8'h59); // write 0x59
    // PLL2_DLD_CNT: 32, 0
    init_data[1006] = cmd_start(7'h2a);
    init_data[1007] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[1008] = cmd_wr(8'h01); // address 0x016a
    init_data[1009] = cmd_wr(8'h6a);
    init_data[1010] = cmd_wr(8'h20); // write 0x20
    init_data[1011] = cmd_start(7'h2a);
    init_data[1012] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[1013] = cmd_wr(8'h01); // address 0x016b
    init_data[1014] = cmd_wr(8'h6b);
    init_data[1015] = cmd_wr(8'h00); // write 0x00
    // PLL2 LD pin: PLL1+PLL2 DLD
    init_data[1016] = cmd_start(7'h2a);
    init_data[1017] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[1018] = cmd_wr(8'h01); // address 0x016e
    init_data[1019] = cmd_wr(8'h6e);
    init_data[1020] = cmd_wr(8'h1b); // write 0x1b
    // release PLL1 R reset
    init_data[1021] = cmd_start(7'h2a);
    init_data[1022] = cmd_wr(8'h08); // SPI transfer, CS mask 0x8
    init_data[1023] = cmd_wr(8'h01); // address 0x0177
    init_data[1024] = cmd_wr(8'h77);
    init_data[1025] = cmd_wr(8'h00); // write 0x00
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
    init_data[1026] = cmd_start(7'h2a);
    init_data[1027] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1028] = cmd_wr(8'h00); // address 0x00
    init_data[1029] = cmd_wr(8'h24); // write 0x2412
    init_data[1030] = cmd_wr(8'h12);
    init_data[1031] = cmd_start(7'h2a);
    init_data[1032] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1033] = cmd_wr(8'h00); // address 0x00
    init_data[1034] = cmd_wr(8'h24); // write 0x2410
    init_data[1035] = cmd_wr(8'h10);
    // QUICK_RECAL_EN: 0
    // VCO_CAPCTRL_STRT: 0
    init_data[1036] = cmd_start(7'h2a);
    init_data[1037] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1038] = cmd_wr(8'h4e); // address 0x4e
    init_data[1039] = cmd_wr(8'h00); // write 0x0001
    init_data[1040] = cmd_wr(8'h01);
    // 77,0x0000
    // 76,0x0000
    // CHDIV: 3 (8)
    init_data[1041] = cmd_start(7'h2a);
    init_data[1042] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1043] = cmd_wr(8'h4b); // address 0x4b
    init_data[1044] = cmd_wr(8'h08); // write 0x08c0
    init_data[1045] = cmd_wr(8'hc0);
    // 74,0x0000
    // 73,0x0000
    // 72,0x0000
    // 71,0x0000
    // MASH_RST_COUNT: 50000 (0xc350)
    init_data[1046] = cmd_start(7'h2a);
    init_data[1047] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1048] = cmd_wr(8'h46); // address 0x46
    init_data[1049] = cmd_wr(8'hc3); // write 0xc350
    init_data[1050] = cmd_wr(8'h50);
    // MASH_RST_COUNT: 50000 (0xc350)
    init_data[1051] = cmd_start(7'h2a);
    init_data[1052] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1053] = cmd_wr(8'h45); // address 0x45
    init_data[1054] = cmd_wr(8'h00); // write 0x0000
    init_data[1055] = cmd_wr(8'h00);
    // 68,0x0000
    // 67,0x0000
    // 66,0x0000
    // 65,0x0000
    // 64,0x0000
    // 63,0x0000
    // 62,0x0000
    // 61,0x0000
    // LD_DELAY: 1000 (0x3e8)
    init_data[1056] = cmd_start(7'h2a);
    init_data[1057] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1058] = cmd_wr(8'h3c); // address 0x3c
    init_data[1059] = cmd_wr(8'h03); // write 0x03e8
    init_data[1060] = cmd_wr(8'he8);
    // LD_TYPE: 1
    init_data[1061] = cmd_start(7'h2a);
    init_data[1062] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1063] = cmd_wr(8'h3b); // address 0x3b
    init_data[1064] = cmd_wr(8'h00); // write 0x0001
    init_data[1065] = cmd_wr(8'h01);
    // INPIN_IGNORE: 1
    // INPIN_HYST: 0
    // INPIN_LVL: 0
    // INPIN_FMT: 0
    init_data[1066] = cmd_start(7'h2a);
    init_data[1067] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1068] = cmd_wr(8'h3a); // address 0x3a
    init_data[1069] = cmd_wr(8'h80); // write 0x8001
    init_data[1070] = cmd_wr(8'h01);
    // 57,0x0000
    // 56,0x0000
    // 55,0x0000
    // 54,0x0000
    // 53,0x0000
    // 52,0x0000
    // 51,0x0000
    // 50,0x0000
    // 49,0x0000
    // 48,0x0000
    // 47,0x0000
    // OUTB_MUX: 0 (ch div)
    init_data[1071] = cmd_start(7'h2a);
    init_data[1072] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1073] = cmd_wr(8'h2e); // address 0x2e
    init_data[1074] = cmd_wr(8'h07); // write 0x07fc
    init_data[1075] = cmd_wr(8'hfc);
    // OUTA_MUX: 0 (ch div)
    // OUT_ISET: 0 (max)
    // OUTB_PWR: 31 (0x1f)
    init_data[1076] = cmd_start(7'h2a);
    init_data[1077] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1078] = cmd_wr(8'h2d); // address 0x2d
    init_data[1079] = cmd_wr(8'hc0); // write 0xc0df
    init_data[1080] = cmd_wr(8'hdf);
    // OUTA_PWR: 31 (0x1f)
    // OUTB_PD: 0
    // OUTA_PD: 0
    // MASH_RESET_N: 0
    // MASH_ORDER: 0
    init_data[1081] = cmd_start(7'h2a);
    init_data[1082] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1083] = cmd_wr(8'h2c); // address 0x2c
    init_data[1084] = cmd_wr(8'h1f); // write 0x1f00
    init_data[1085] = cmd_wr(8'h00);
    // PLL_NUM: 0
    init_data[1086] = cmd_start(7'h2a);
    init_data[1087] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1088] = cmd_wr(8'h2b); // address 0x2b
    init_data[1089] = cmd_wr(8'h00); // write 0x0000
    init_data[1090] = cmd_wr(8'h00);
    // PLL_NUM: 0
    init_data[1091] = cmd_start(7'h2a);
    init_data[1092] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1093] = cmd_wr(8'h2a); // address 0x2a
    init_data[1094] = cmd_wr(8'h00); // write 0x0000
    init_data[1095] = cmd_wr(8'h00);
    // MASH_SEED: 0
    init_data[1096] = cmd_start(7'h2a);
    init_data[1097] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1098] = cmd_wr(8'h29); // address 0x29
    init_data[1099] = cmd_wr(8'h00); // write 0x0000
    init_data[1100] = cmd_wr(8'h00);
    // MASH_SEED: 0
    init_data[1101] = cmd_start(7'h2a);
    init_data[1102] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1103] = cmd_wr(8'h28); // address 0x28
    init_data[1104] = cmd_wr(8'h00); // write 0x0000
    init_data[1105] = cmd_wr(8'h00);
    // PLL_DEN: '1
    init_data[1106] = cmd_start(7'h2a);
    init_data[1107] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1108] = cmd_wr(8'h27); // address 0x27
    init_data[1109] = cmd_wr(8'hff); // write 0xffff
    init_data[1110] = cmd_wr(8'hff);
    // PLL_DEN: '1
    init_data[1111] = cmd_start(7'h2a);
    init_data[1112] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1113] = cmd_wr(8'h26); // address 0x26
    init_data[1114] = cmd_wr(8'hff); // write 0xffff
    init_data[1115] = cmd_wr(8'hff);
    // MASH_SEED_EN: 0
    // PFD_DLY_SEL: 2
    init_data[1116] = cmd_start(7'h2a);
    init_data[1117] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1118] = cmd_wr(8'h25); // address 0x25
    init_data[1119] = cmd_wr(8'h02); // write 0x0204
    init_data[1120] = cmd_wr(8'h04);
    // PLL_N: 32 (0x20)
    init_data[1121] = cmd_start(7'h2a);
    init_data[1122] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1123] = cmd_wr(8'h24); // address 0x24
    init_data[1124] = cmd_wr(8'h00); // write 0x0020
    init_data[1125] = cmd_wr(8'h20);
    // 35,0x0000
    // PLL_N: 32 (0x20)
    init_data[1126] = cmd_start(7'h2a);
    init_data[1127] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1128] = cmd_wr(8'h22); // address 0x22
    init_data[1129] = cmd_wr(8'h00); // write 0x0000
    init_data[1130] = cmd_wr(8'h00);
    // 33,0x0000
    // 32,0x0000
    // CHDIV_DIV2: 1
    init_data[1131] = cmd_start(7'h2a);
    init_data[1132] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1133] = cmd_wr(8'h1f); // address 0x1f
    init_data[1134] = cmd_wr(8'h43); // write 0x43ec
    init_data[1135] = cmd_wr(8'hec);
    // 30,0x0000
    // 29,0x0000
    // 28,0x0000
    // 27,0x0000
    // 26,0x0000
    // 25,0x0000
    // 24,0x0000
    // 23,0x0000
    // 22,0x0000
    // 21,0x0000
    // VCO_SEL: 7 (VCO7)
    // VCO_SEL_FORCE: 0
    init_data[1136] = cmd_start(7'h2a);
    init_data[1137] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1138] = cmd_wr(8'h14); // address 0x14
    init_data[1139] = cmd_wr(8'hf8); // write 0xf848
    init_data[1140] = cmd_wr(8'h48);
    // VCO_CAPCTRL: 183 (0xb7)
    init_data[1141] = cmd_start(7'h2a);
    init_data[1142] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1143] = cmd_wr(8'h13); // address 0x13
    init_data[1144] = cmd_wr(8'h27); // write 0x27b7
    init_data[1145] = cmd_wr(8'hb7);
    // 18,0x0000
    // VCO_DACISET_STRT: 250 (0xfa)
    init_data[1146] = cmd_start(7'h2a);
    init_data[1147] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1148] = cmd_wr(8'h11); // address 0x11
    init_data[1149] = cmd_wr(8'h00); // write 0x00fa
    init_data[1150] = cmd_wr(8'hfa);
    // VCO_DACISET: 128 (0x80)
    init_data[1151] = cmd_start(7'h2a);
    init_data[1152] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1153] = cmd_wr(8'h10); // address 0x10
    init_data[1154] = cmd_wr(8'h00); // write 0x0080
    init_data[1155] = cmd_wr(8'h80);
    // 15,0x0000
    // CPG: 7
    init_data[1156] = cmd_start(7'h2a);
    init_data[1157] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1158] = cmd_wr(8'h0e); // address 0x0e
    init_data[1159] = cmd_wr(8'h1e); // write 0x1e70
    init_data[1160] = cmd_wr(8'h70);
    // PLL_R_PRE: 1
    init_data[1161] = cmd_start(7'h2a);
    init_data[1162] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1163] = cmd_wr(8'h0c); // address 0x0c
    init_data[1164] = cmd_wr(8'h50); // write 0x5001
    init_data[1165] = cmd_wr(8'h01);
    // PLL_R: 1
    init_data[1166] = cmd_start(7'h2a);
    init_data[1167] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1168] = cmd_wr(8'h0b); // address 0x0b
    init_data[1169] = cmd_wr(8'h00); // write 0x0018
    init_data[1170] = cmd_wr(8'h18);
    // MULT: 1 (bypass)
    init_data[1171] = cmd_start(7'h2a);
    init_data[1172] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1173] = cmd_wr(8'h0a); // address 0x0a
    init_data[1174] = cmd_wr(8'h10); // write 0x10d8
    init_data[1175] = cmd_wr(8'hd8);
    // OSC_2X: 0
    init_data[1176] = cmd_start(7'h2a);
    init_data[1177] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1178] = cmd_wr(8'h09); // address 0x09
    init_data[1179] = cmd_wr(8'h06); // write 0x0604
    init_data[1180] = cmd_wr(8'h04);
    // VCO_DACISET_FORCE: 0
    // VCO_CAPCTRL_FORCE: 0
    init_data[1181] = cmd_start(7'h2a);
    init_data[1182] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1183] = cmd_wr(8'h08); // address 0x08
    init_data[1184] = cmd_wr(8'h20); // write 0x2000
    init_data[1185] = cmd_wr(8'h00);
    // OUT_FORCE: 0
    init_data[1186] = cmd_start(7'h2a);
    init_data[1187] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1188] = cmd_wr(8'h07); // address 0x07
    init_data[1189] = cmd_wr(8'h00); // write 0x00b2
    init_data[1190] = cmd_wr(8'hb2);
    // ACAL_CMP_DLY: 10
    init_data[1191] = cmd_start(7'h2a);
    init_data[1192] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1193] = cmd_wr(8'h04); // address 0x04
    init_data[1194] = cmd_wr(8'h0a); // write 0x0a43
    init_data[1195] = cmd_wr(8'h43);
    // CAL_CLK_DIV: 3 (div 8)
    init_data[1196] = cmd_start(7'h2a);
    init_data[1197] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1198] = cmd_wr(8'h01); // address 0x01
    init_data[1199] = cmd_wr(8'h08); // write 0x080b
    init_data[1200] = cmd_wr(8'h0b);
    // FCAL_HPFD_ADJ: 3 (PFD > 200 MHz)
    // FCAL_LPFD_ADJ: 0 (PFD > 10 MHz)
    // FCAL_EN: 0
    // MUXOUT_LD_SEL: 0 (readback)
    // RESET: 0
    // POWERDOWN: 0
    init_data[1201] = cmd_start(7'h2a);
    init_data[1202] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1203] = cmd_wr(8'h00); // address 0x00
    init_data[1204] = cmd_wr(8'h25); // write 0x2590
    init_data[1205] = cmd_wr(8'h90);
    // Delay 10 msec
    init_data[1206] = cmd_delay(10); // delay 300 ms
    // FCAL_HPFD_ADJ: 3 (PFD > 200 MHz)
    // FCAL_LPFD_ADJ: 0 (PFD > 10 MHz)
    // FCAL_EN: 1
    // MUXOUT_LD_SEL: 0 (readback)
    // RESET: 0
    // POWERDOWN: 0
    init_data[1207] = cmd_start(7'h2a);
    init_data[1208] = cmd_wr(8'h07); // SPI transfer, CS mask 0x7
    init_data[1209] = cmd_wr(8'h00); // address 0x00
    init_data[1210] = cmd_wr(8'h25); // write 0x2598
    init_data[1211] = cmd_wr(8'h98);
    // Clear I2C-SPI bridge interrupt
    init_data[1212] = cmd_start(7'h2a);
    init_data[1213] = cmd_wr(8'hf1);
    init_data[1214] = cmd_halt(); // end
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
