# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 FPGA Ninja, LLC
#
# Authors:
# - Alex Forencich
#

# XDC constraints for the Xilinx ZCU111 board
# part: xczu28dr-ffvg1517-2-e

# RFDC
set_property -dict {LOC AP2 } [get_ports {adc_vin_p[0]}]  ;# ADC_VIN_I01_224_P from J47.G9
set_property -dict {LOC AP1 } [get_ports {adc_vin_n[0]}]  ;# ADC_VIN_I01_224_N from J47.F9
set_property -dict {LOC AM2 } [get_ports {adc_vin_p[1]}]  ;# ADC_VIN_I23_224_P from J47.C10
set_property -dict {LOC AM1 } [get_ports {adc_vin_n[1]}]  ;# ADC_VIN_I23_224_N from J47.B10
set_property -dict {LOC AK2 } [get_ports {adc_vin_p[2]}]  ;# ADC_VIN_I01_225_P from J47.G12
set_property -dict {LOC AK1 } [get_ports {adc_vin_n[2]}]  ;# ADC_VIN_I01_225_N from J47.F12
set_property -dict {LOC AH2 } [get_ports {adc_vin_p[3]}]  ;# ADC_VIN_I23_225_P from J47.C13
set_property -dict {LOC AH1 } [get_ports {adc_vin_n[3]}]  ;# ADC_VIN_I23_225_N from J47.B13
set_property -dict {LOC AF2 } [get_ports {adc_vin_p[4]}]  ;# ADC_VIN_I01_226_P from J47.G15
set_property -dict {LOC AF1 } [get_ports {adc_vin_n[4]}]  ;# ADC_VIN_I01_226_N from J47.F15
set_property -dict {LOC AD2 } [get_ports {adc_vin_p[5]}]  ;# ADC_VIN_I23_226_P from J47.C16
set_property -dict {LOC AD1 } [get_ports {adc_vin_n[5]}]  ;# ADC_VIN_I23_226_N from J47.B16
set_property -dict {LOC AB2 } [get_ports {adc_vin_p[6]}]  ;# ADC_VIN_I01_227_P from J47.G18
set_property -dict {LOC AB1 } [get_ports {adc_vin_n[6]}]  ;# ADC_VIN_I01_227_N from J47.F18
set_property -dict {LOC Y2  } [get_ports {adc_vin_p[7]}]  ;# ADC_VIN_I23_227_P from J47.C19
set_property -dict {LOC Y1  } [get_ports {adc_vin_n[7]}]  ;# ADC_VIN_I23_227_N from J47.B19

set_property -dict {LOC AF5 } [get_ports {adc_refclk_0_p}]  ;# ADC_224_REFCLK_P from U102.23 RFoutAP
set_property -dict {LOC AF4 } [get_ports {adc_refclk_0_n}]  ;# ADC_224_REFCLK_N from U102.22 RFoutAN
set_property -dict {LOC AD5 } [get_ports {adc_refclk_1_p}]  ;# ADC_225_REFCLK_P from U102.19 RFoutBP
set_property -dict {LOC AD4 } [get_ports {adc_refclk_1_n}]  ;# ADC_225_REFCLK_N from U102.18 RFoutBN
set_property -dict {LOC AB5 } [get_ports {adc_refclk_2_p}]  ;# ADC_226_REFCLK_P from U103.23 RFoutAP
set_property -dict {LOC AB4 } [get_ports {adc_refclk_2_n}]  ;# ADC_226_REFCLK_N from U103.22 RFoutAN
set_property -dict {LOC Y5  } [get_ports {adc_refclk_3_p}]  ;# ADC_227_REFCLK_P from U103.19 RFoutBP
set_property -dict {LOC Y4  } [get_ports {adc_refclk_3_n}]  ;# ADC_227_REFCLK_N from U103.18 RFoutBN

set_property -dict {LOC U2  } [get_ports {dac_vout_p[0]}]  ;# DAC_VOUT0_228_P from J94.G9
set_property -dict {LOC U1  } [get_ports {dac_vout_n[0]}]  ;# DAC_VOUT0_228_N from J94.F9
set_property -dict {LOC R2  } [get_ports {dac_vout_p[1]}]  ;# DAC_VOUT1_228_P from J94.C10
set_property -dict {LOC R1  } [get_ports {dac_vout_n[1]}]  ;# DAC_VOUT1_228_N from J94.B10
set_property -dict {LOC N2  } [get_ports {dac_vout_p[2]}]  ;# DAC_VOUT2_228_P from J94.G12
set_property -dict {LOC N1  } [get_ports {dac_vout_n[2]}]  ;# DAC_VOUT2_228_N from J94.F12
set_property -dict {LOC L2  } [get_ports {dac_vout_p[3]}]  ;# DAC_VOUT3_228_P from J94.C13
set_property -dict {LOC L1  } [get_ports {dac_vout_n[3]}]  ;# DAC_VOUT3_228_N from J94.B13
set_property -dict {LOC J2  } [get_ports {dac_vout_p[4]}]  ;# DAC_VOUT0_229_P from J94.G15
set_property -dict {LOC J1  } [get_ports {dac_vout_n[4]}]  ;# DAC_VOUT0_229_N from J94.F15
set_property -dict {LOC G2  } [get_ports {dac_vout_p[5]}]  ;# DAC_VOUT1_229_P from J94.C16
set_property -dict {LOC G1  } [get_ports {dac_vout_n[5]}]  ;# DAC_VOUT1_229_N from J94.B16
set_property -dict {LOC E2  } [get_ports {dac_vout_p[6]}]  ;# DAC_VOUT2_229_P from J94.G18
set_property -dict {LOC E1  } [get_ports {dac_vout_n[6]}]  ;# DAC_VOUT2_229_N from J94.F18
set_property -dict {LOC C2  } [get_ports {dac_vout_p[7]}]  ;# DAC_VOUT3_229_P from J94.C19
set_property -dict {LOC C1  } [get_ports {dac_vout_n[7]}]  ;# DAC_VOUT3_229_N from J94.B19

set_property -dict {LOC R5  } [get_ports {dac_refclk_0_p}]  ;# DAC_228_REFCLK_P from U104.23 RFoutAP
set_property -dict {LOC R4  } [get_ports {dac_refclk_0_n}]  ;# DAC_228_REFCLK_N from U104.22 RFoutAN
set_property -dict {LOC N5  } [get_ports {dac_refclk_1_p}]  ;# DAC_229_REFCLK_P from U104.19 RFoutBP
set_property -dict {LOC N4  } [get_ports {dac_refclk_1_n}]  ;# DAC_229_REFCLK_N from U104.18 RFoutBN

set_property -dict {LOC U5  } [get_ports {rfdc_sysref_p}]  ;# SYSREF_P_228 from U90.13 CLKout1_P
set_property -dict {LOC U4  } [get_ports {rfdc_sysref_n}]  ;# SYSREF_N_228 from U90.14 CLKout1_N
