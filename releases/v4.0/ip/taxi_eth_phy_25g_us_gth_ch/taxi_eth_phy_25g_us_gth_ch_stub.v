// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Sun Sep 13 17:47:20 2026
// Host        : dkeL running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top taxi_eth_phy_25g_us_gth_ch -prefix
//               taxi_eth_phy_25g_us_gth_ch_ taxi_eth_phy_25g_us_gth_ch_stub.v
// Design      : taxi_eth_phy_25g_us_gth_ch
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu7ev-ffvc1156-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "taxi_eth_phy_25g_us_gth_ch_gtwizard_top,Vivado 2023.2" *)
module taxi_eth_phy_25g_us_gth_ch(gtwiz_userclk_tx_reset_in,
  gtwiz_userclk_tx_srcclk_out, gtwiz_userclk_tx_usrclk_out,
  gtwiz_userclk_tx_usrclk2_out, gtwiz_userclk_tx_active_out, gtwiz_userclk_rx_reset_in,
  gtwiz_userclk_rx_srcclk_out, gtwiz_userclk_rx_usrclk_out,
  gtwiz_userclk_rx_usrclk2_out, gtwiz_userclk_rx_active_out, gtwiz_reset_tx_done_in,
  gtwiz_reset_rx_done_in, gtwiz_userdata_tx_in, gtwiz_userdata_rx_out, drpaddr_in,
  drpclk_in, drpdi_in, drpen_in, drpwe_in, eyescanreset_in, gthrxn_in, gthrxp_in, gtrxreset_in,
  gttxreset_in, qpll0clk_in, qpll0refclk_in, qpll1clk_in, qpll1refclk_in, rxcdrhold_in,
  rxcdrovrden_in, rxdfelpmreset_in, rxgearboxslip_in, rxlpmen_in, rxpcsreset_in, rxpd_in,
  rxpllclksel_in, rxpmareset_in, rxpolarity_in, rxprogdivreset_in, rxsysclksel_in,
  rxuserrdy_in, txdiffctrl_in, txelecidle_in, txheader_in, txinhibit_in, txmaincursor_in,
  txpcsreset_in, txpd_in, txpdelecidlemode_in, txpllclksel_in, txpmareset_in, txpolarity_in,
  txpostcursor_in, txprecursor_in, txprogdivreset_in, txsequence_in, txsysclksel_in,
  txuserrdy_in, drpdo_out, drprdy_out, gthtxn_out, gthtxp_out, gtpowergood_out, rxcdrlock_out,
  rxdatavalid_out, rxheader_out, rxheadervalid_out, rxpmaresetdone_out,
  rxprgdivresetdone_out, rxresetdone_out, rxstartofseq_out, txpmaresetdone_out,
  txprgdivresetdone_out, txresetdone_out)
/* synthesis syn_black_box black_box_pad_pin="gtwiz_userclk_tx_reset_in[0:0],gtwiz_userclk_tx_srcclk_out[0:0],gtwiz_userclk_tx_usrclk_out[0:0],gtwiz_userclk_tx_usrclk2_out[0:0],gtwiz_userclk_tx_active_out[0:0],gtwiz_userclk_rx_reset_in[0:0],gtwiz_userclk_rx_srcclk_out[0:0],gtwiz_userclk_rx_usrclk_out[0:0],gtwiz_userclk_rx_usrclk2_out[0:0],gtwiz_userclk_rx_active_out[0:0],gtwiz_reset_tx_done_in[0:0],gtwiz_reset_rx_done_in[0:0],gtwiz_userdata_tx_in[63:0],gtwiz_userdata_rx_out[63:0],drpaddr_in[9:0],drpclk_in[0:0],drpdi_in[15:0],drpen_in[0:0],drpwe_in[0:0],eyescanreset_in[0:0],gthrxn_in[0:0],gthrxp_in[0:0],gtrxreset_in[0:0],gttxreset_in[0:0],qpll0clk_in[0:0],qpll0refclk_in[0:0],qpll1clk_in[0:0],qpll1refclk_in[0:0],rxcdrhold_in[0:0],rxcdrovrden_in[0:0],rxdfelpmreset_in[0:0],rxgearboxslip_in[0:0],rxlpmen_in[0:0],rxpcsreset_in[0:0],rxpd_in[1:0],rxpllclksel_in[1:0],rxpmareset_in[0:0],rxpolarity_in[0:0],rxprogdivreset_in[0:0],rxsysclksel_in[1:0],rxuserrdy_in[0:0],txdiffctrl_in[4:0],txelecidle_in[0:0],txheader_in[5:0],txinhibit_in[0:0],txmaincursor_in[6:0],txpcsreset_in[0:0],txpd_in[1:0],txpdelecidlemode_in[0:0],txpllclksel_in[1:0],txpmareset_in[0:0],txpolarity_in[0:0],txpostcursor_in[4:0],txprecursor_in[4:0],txprogdivreset_in[0:0],txsequence_in[6:0],txsysclksel_in[1:0],txuserrdy_in[0:0],drpdo_out[15:0],drprdy_out[0:0],gthtxn_out[0:0],gthtxp_out[0:0],gtpowergood_out[0:0],rxcdrlock_out[0:0],rxdatavalid_out[1:0],rxheader_out[5:0],rxheadervalid_out[1:0],rxpmaresetdone_out[0:0],rxprgdivresetdone_out[0:0],rxresetdone_out[0:0],rxstartofseq_out[1:0],txpmaresetdone_out[0:0],txprgdivresetdone_out[0:0],txresetdone_out[0:0]" */;
  input [0:0]gtwiz_userclk_tx_reset_in;
  output [0:0]gtwiz_userclk_tx_srcclk_out;
  output [0:0]gtwiz_userclk_tx_usrclk_out;
  output [0:0]gtwiz_userclk_tx_usrclk2_out;
  output [0:0]gtwiz_userclk_tx_active_out;
  input [0:0]gtwiz_userclk_rx_reset_in;
  output [0:0]gtwiz_userclk_rx_srcclk_out;
  output [0:0]gtwiz_userclk_rx_usrclk_out;
  output [0:0]gtwiz_userclk_rx_usrclk2_out;
  output [0:0]gtwiz_userclk_rx_active_out;
  input [0:0]gtwiz_reset_tx_done_in;
  input [0:0]gtwiz_reset_rx_done_in;
  input [63:0]gtwiz_userdata_tx_in;
  output [63:0]gtwiz_userdata_rx_out;
  input [9:0]drpaddr_in;
  input [0:0]drpclk_in;
  input [15:0]drpdi_in;
  input [0:0]drpen_in;
  input [0:0]drpwe_in;
  input [0:0]eyescanreset_in;
  input [0:0]gthrxn_in;
  input [0:0]gthrxp_in;
  input [0:0]gtrxreset_in;
  input [0:0]gttxreset_in;
  input [0:0]qpll0clk_in;
  input [0:0]qpll0refclk_in;
  input [0:0]qpll1clk_in;
  input [0:0]qpll1refclk_in;
  input [0:0]rxcdrhold_in;
  input [0:0]rxcdrovrden_in;
  input [0:0]rxdfelpmreset_in;
  input [0:0]rxgearboxslip_in;
  input [0:0]rxlpmen_in;
  input [0:0]rxpcsreset_in;
  input [1:0]rxpd_in;
  input [1:0]rxpllclksel_in;
  input [0:0]rxpmareset_in;
  input [0:0]rxpolarity_in;
  input [0:0]rxprogdivreset_in;
  input [1:0]rxsysclksel_in;
  input [0:0]rxuserrdy_in;
  input [4:0]txdiffctrl_in;
  input [0:0]txelecidle_in;
  input [5:0]txheader_in;
  input [0:0]txinhibit_in;
  input [6:0]txmaincursor_in;
  input [0:0]txpcsreset_in;
  input [1:0]txpd_in;
  input [0:0]txpdelecidlemode_in;
  input [1:0]txpllclksel_in;
  input [0:0]txpmareset_in;
  input [0:0]txpolarity_in;
  input [4:0]txpostcursor_in;
  input [4:0]txprecursor_in;
  input [0:0]txprogdivreset_in;
  input [6:0]txsequence_in;
  input [1:0]txsysclksel_in;
  input [0:0]txuserrdy_in;
  output [15:0]drpdo_out;
  output [0:0]drprdy_out;
  output [0:0]gthtxn_out;
  output [0:0]gthtxp_out;
  output [0:0]gtpowergood_out;
  output [0:0]rxcdrlock_out;
  output [1:0]rxdatavalid_out;
  output [5:0]rxheader_out;
  output [1:0]rxheadervalid_out;
  output [0:0]rxpmaresetdone_out;
  output [0:0]rxprgdivresetdone_out;
  output [0:0]rxresetdone_out;
  output [1:0]rxstartofseq_out;
  output [0:0]txpmaresetdone_out;
  output [0:0]txprgdivresetdone_out;
  output [0:0]txresetdone_out;
endmodule
