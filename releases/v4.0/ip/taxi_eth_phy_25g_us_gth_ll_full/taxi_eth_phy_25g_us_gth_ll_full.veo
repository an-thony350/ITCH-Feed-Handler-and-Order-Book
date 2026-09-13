// (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
// DO NOT MODIFY THIS FILE.

// IP VLNV: xilinx.com:ip:gtwizard_ultrascale:1.7
// IP Revision: 17

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
taxi_eth_phy_25g_us_gth_ll_full your_instance_name (
  .gtwiz_userclk_tx_reset_in(gtwiz_userclk_tx_reset_in),                  // input wire [0 : 0] gtwiz_userclk_tx_reset_in
  .gtwiz_userclk_tx_srcclk_out(gtwiz_userclk_tx_srcclk_out),              // output wire [0 : 0] gtwiz_userclk_tx_srcclk_out
  .gtwiz_userclk_tx_usrclk_out(gtwiz_userclk_tx_usrclk_out),              // output wire [0 : 0] gtwiz_userclk_tx_usrclk_out
  .gtwiz_userclk_tx_usrclk2_out(gtwiz_userclk_tx_usrclk2_out),            // output wire [0 : 0] gtwiz_userclk_tx_usrclk2_out
  .gtwiz_userclk_tx_active_out(gtwiz_userclk_tx_active_out),              // output wire [0 : 0] gtwiz_userclk_tx_active_out
  .gtwiz_userclk_rx_reset_in(gtwiz_userclk_rx_reset_in),                  // input wire [0 : 0] gtwiz_userclk_rx_reset_in
  .gtwiz_userclk_rx_srcclk_out(gtwiz_userclk_rx_srcclk_out),              // output wire [0 : 0] gtwiz_userclk_rx_srcclk_out
  .gtwiz_userclk_rx_usrclk_out(gtwiz_userclk_rx_usrclk_out),              // output wire [0 : 0] gtwiz_userclk_rx_usrclk_out
  .gtwiz_userclk_rx_usrclk2_out(gtwiz_userclk_rx_usrclk2_out),            // output wire [0 : 0] gtwiz_userclk_rx_usrclk2_out
  .gtwiz_userclk_rx_active_out(gtwiz_userclk_rx_active_out),              // output wire [0 : 0] gtwiz_userclk_rx_active_out
  .gtwiz_buffbypass_tx_reset_in(gtwiz_buffbypass_tx_reset_in),            // input wire [0 : 0] gtwiz_buffbypass_tx_reset_in
  .gtwiz_buffbypass_tx_start_user_in(gtwiz_buffbypass_tx_start_user_in),  // input wire [0 : 0] gtwiz_buffbypass_tx_start_user_in
  .gtwiz_buffbypass_tx_done_out(gtwiz_buffbypass_tx_done_out),            // output wire [0 : 0] gtwiz_buffbypass_tx_done_out
  .gtwiz_buffbypass_tx_error_out(gtwiz_buffbypass_tx_error_out),          // output wire [0 : 0] gtwiz_buffbypass_tx_error_out
  .gtwiz_buffbypass_rx_reset_in(gtwiz_buffbypass_rx_reset_in),            // input wire [0 : 0] gtwiz_buffbypass_rx_reset_in
  .gtwiz_buffbypass_rx_start_user_in(gtwiz_buffbypass_rx_start_user_in),  // input wire [0 : 0] gtwiz_buffbypass_rx_start_user_in
  .gtwiz_buffbypass_rx_done_out(gtwiz_buffbypass_rx_done_out),            // output wire [0 : 0] gtwiz_buffbypass_rx_done_out
  .gtwiz_buffbypass_rx_error_out(gtwiz_buffbypass_rx_error_out),          // output wire [0 : 0] gtwiz_buffbypass_rx_error_out
  .gtwiz_reset_tx_done_in(gtwiz_reset_tx_done_in),                        // input wire [0 : 0] gtwiz_reset_tx_done_in
  .gtwiz_reset_rx_done_in(gtwiz_reset_rx_done_in),                        // input wire [0 : 0] gtwiz_reset_rx_done_in
  .gtwiz_userdata_tx_in(gtwiz_userdata_tx_in),                            // input wire [63 : 0] gtwiz_userdata_tx_in
  .gtwiz_userdata_rx_out(gtwiz_userdata_rx_out),                          // output wire [63 : 0] gtwiz_userdata_rx_out
  .drpaddr_common_in(drpaddr_common_in),                                  // input wire [15 : 0] drpaddr_common_in
  .drpclk_common_in(drpclk_common_in),                                    // input wire [0 : 0] drpclk_common_in
  .drpdi_common_in(drpdi_common_in),                                      // input wire [15 : 0] drpdi_common_in
  .drpen_common_in(drpen_common_in),                                      // input wire [0 : 0] drpen_common_in
  .drpwe_common_in(drpwe_common_in),                                      // input wire [0 : 0] drpwe_common_in
  .gtrefclk00_in(gtrefclk00_in),                                          // input wire [0 : 0] gtrefclk00_in
  .gtrefclk01_in(gtrefclk01_in),                                          // input wire [0 : 0] gtrefclk01_in
  .pcierateqpll0_in(pcierateqpll0_in),                                    // input wire [2 : 0] pcierateqpll0_in
  .pcierateqpll1_in(pcierateqpll1_in),                                    // input wire [2 : 0] pcierateqpll1_in
  .qpll0pd_in(qpll0pd_in),                                                // input wire [0 : 0] qpll0pd_in
  .qpll0reset_in(qpll0reset_in),                                          // input wire [0 : 0] qpll0reset_in
  .qpll1pd_in(qpll1pd_in),                                                // input wire [0 : 0] qpll1pd_in
  .qpll1reset_in(qpll1reset_in),                                          // input wire [0 : 0] qpll1reset_in
  .drpdo_common_out(drpdo_common_out),                                    // output wire [15 : 0] drpdo_common_out
  .drprdy_common_out(drprdy_common_out),                                  // output wire [0 : 0] drprdy_common_out
  .qpll0lock_out(qpll0lock_out),                                          // output wire [0 : 0] qpll0lock_out
  .qpll0outclk_out(qpll0outclk_out),                                      // output wire [0 : 0] qpll0outclk_out
  .qpll0outrefclk_out(qpll0outrefclk_out),                                // output wire [0 : 0] qpll0outrefclk_out
  .qpll1lock_out(qpll1lock_out),                                          // output wire [0 : 0] qpll1lock_out
  .qpll1outclk_out(qpll1outclk_out),                                      // output wire [0 : 0] qpll1outclk_out
  .qpll1outrefclk_out(qpll1outrefclk_out),                                // output wire [0 : 0] qpll1outrefclk_out
  .drpaddr_in(drpaddr_in),                                                // input wire [9 : 0] drpaddr_in
  .drpclk_in(drpclk_in),                                                  // input wire [0 : 0] drpclk_in
  .drpdi_in(drpdi_in),                                                    // input wire [15 : 0] drpdi_in
  .drpen_in(drpen_in),                                                    // input wire [0 : 0] drpen_in
  .drpwe_in(drpwe_in),                                                    // input wire [0 : 0] drpwe_in
  .eyescanreset_in(eyescanreset_in),                                      // input wire [0 : 0] eyescanreset_in
  .gthrxn_in(gthrxn_in),                                                  // input wire [0 : 0] gthrxn_in
  .gthrxp_in(gthrxp_in),                                                  // input wire [0 : 0] gthrxp_in
  .gtrxreset_in(gtrxreset_in),                                            // input wire [0 : 0] gtrxreset_in
  .gttxreset_in(gttxreset_in),                                            // input wire [0 : 0] gttxreset_in
  .rxcdrhold_in(rxcdrhold_in),                                            // input wire [0 : 0] rxcdrhold_in
  .rxcdrovrden_in(rxcdrovrden_in),                                        // input wire [0 : 0] rxcdrovrden_in
  .rxdfelpmreset_in(rxdfelpmreset_in),                                    // input wire [0 : 0] rxdfelpmreset_in
  .rxgearboxslip_in(rxgearboxslip_in),                                    // input wire [0 : 0] rxgearboxslip_in
  .rxlpmen_in(rxlpmen_in),                                                // input wire [0 : 0] rxlpmen_in
  .rxpcsreset_in(rxpcsreset_in),                                          // input wire [0 : 0] rxpcsreset_in
  .rxpd_in(rxpd_in),                                                      // input wire [1 : 0] rxpd_in
  .rxpllclksel_in(rxpllclksel_in),                                        // input wire [1 : 0] rxpllclksel_in
  .rxpmareset_in(rxpmareset_in),                                          // input wire [0 : 0] rxpmareset_in
  .rxpolarity_in(rxpolarity_in),                                          // input wire [0 : 0] rxpolarity_in
  .rxprogdivreset_in(rxprogdivreset_in),                                  // input wire [0 : 0] rxprogdivreset_in
  .rxsysclksel_in(rxsysclksel_in),                                        // input wire [1 : 0] rxsysclksel_in
  .rxuserrdy_in(rxuserrdy_in),                                            // input wire [0 : 0] rxuserrdy_in
  .txdiffctrl_in(txdiffctrl_in),                                          // input wire [4 : 0] txdiffctrl_in
  .txelecidle_in(txelecidle_in),                                          // input wire [0 : 0] txelecidle_in
  .txheader_in(txheader_in),                                              // input wire [5 : 0] txheader_in
  .txinhibit_in(txinhibit_in),                                            // input wire [0 : 0] txinhibit_in
  .txmaincursor_in(txmaincursor_in),                                      // input wire [6 : 0] txmaincursor_in
  .txpcsreset_in(txpcsreset_in),                                          // input wire [0 : 0] txpcsreset_in
  .txpd_in(txpd_in),                                                      // input wire [1 : 0] txpd_in
  .txpdelecidlemode_in(txpdelecidlemode_in),                              // input wire [0 : 0] txpdelecidlemode_in
  .txpllclksel_in(txpllclksel_in),                                        // input wire [1 : 0] txpllclksel_in
  .txpmareset_in(txpmareset_in),                                          // input wire [0 : 0] txpmareset_in
  .txpolarity_in(txpolarity_in),                                          // input wire [0 : 0] txpolarity_in
  .txpostcursor_in(txpostcursor_in),                                      // input wire [4 : 0] txpostcursor_in
  .txprecursor_in(txprecursor_in),                                        // input wire [4 : 0] txprecursor_in
  .txprogdivreset_in(txprogdivreset_in),                                  // input wire [0 : 0] txprogdivreset_in
  .txsequence_in(txsequence_in),                                          // input wire [6 : 0] txsequence_in
  .txsysclksel_in(txsysclksel_in),                                        // input wire [1 : 0] txsysclksel_in
  .txuserrdy_in(txuserrdy_in),                                            // input wire [0 : 0] txuserrdy_in
  .drpdo_out(drpdo_out),                                                  // output wire [15 : 0] drpdo_out
  .drprdy_out(drprdy_out),                                                // output wire [0 : 0] drprdy_out
  .gthtxn_out(gthtxn_out),                                                // output wire [0 : 0] gthtxn_out
  .gthtxp_out(gthtxp_out),                                                // output wire [0 : 0] gthtxp_out
  .gtpowergood_out(gtpowergood_out),                                      // output wire [0 : 0] gtpowergood_out
  .rxcdrlock_out(rxcdrlock_out),                                          // output wire [0 : 0] rxcdrlock_out
  .rxdatavalid_out(rxdatavalid_out),                                      // output wire [1 : 0] rxdatavalid_out
  .rxheader_out(rxheader_out),                                            // output wire [5 : 0] rxheader_out
  .rxheadervalid_out(rxheadervalid_out),                                  // output wire [1 : 0] rxheadervalid_out
  .rxpmaresetdone_out(rxpmaresetdone_out),                                // output wire [0 : 0] rxpmaresetdone_out
  .rxprgdivresetdone_out(rxprgdivresetdone_out),                          // output wire [0 : 0] rxprgdivresetdone_out
  .rxresetdone_out(rxresetdone_out),                                      // output wire [0 : 0] rxresetdone_out
  .rxstartofseq_out(rxstartofseq_out),                                    // output wire [1 : 0] rxstartofseq_out
  .txpmaresetdone_out(txpmaresetdone_out),                                // output wire [0 : 0] txpmaresetdone_out
  .txprgdivresetdone_out(txprgdivresetdone_out),                          // output wire [0 : 0] txprgdivresetdone_out
  .txresetdone_out(txresetdone_out)                                      // output wire [0 : 0] txresetdone_out
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file taxi_eth_phy_25g_us_gth_ll_full.v when simulating
// the core, taxi_eth_phy_25g_us_gth_ll_full. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.
