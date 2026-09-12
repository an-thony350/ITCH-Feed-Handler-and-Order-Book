# SPDX-License-Identifier: MIT
#
# Copyright (c) 2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Napatech NT40E3
# part: xc7vx330tffg1157-2

# AVR BMC U2
#set_property -dict {LOC AC23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pc4] ;# U2.J7 PC4
#set_property -dict {LOC AD24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pc5] ;# U2.H7 PC5
#set_property -dict {LOC AC24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pc6] ;# U2.G7 PC6
#set_property -dict {LOC AD25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pc7] ;# U2.J8 PC7

#set_property -dict {LOC AC25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pd4] ;# U2.H9 PD4
#set_property -dict {LOC AE24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pd5] ;# U2.H8 PD5
#set_property -dict {LOC AE23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pd6] ;# U2.G9 PD6
#set_property -dict {LOC AF26 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pd7] ;# U2.G8 PD7

#set_property -dict {LOC AF29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pj0] ;# U2.C5 PJ0
#set_property -dict {LOC AC28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pj1] ;# U2.D5 PJ1
#set_property -dict {LOC AC29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pj2] ;# U2.E5 PJ2
#set_property -dict {LOC AE28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pj3] ;# U2.A4 PJ3
#set_property -dict {LOC AE29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pj4] ;# U2.B4 PJ4
#set_property -dict {LOC AD29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pj5] ;# U2.C4 PJ5
#set_property -dict {LOC AH28 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pj6] ;# U2.D4 PJ6
#set_property -dict {LOC AD26 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pj7] ;# U2.E4 PJ7

#set_property -dict {LOC AH27 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pdi_data] ;# U2.F4 PDI_DATA
#set_property -dict {LOC AH29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports avr_pdi_clk] ;# U2.F3 PDI_CLK
