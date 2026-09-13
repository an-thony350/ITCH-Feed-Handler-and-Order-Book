-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
-- Date        : Sun Sep 13 17:47:20 2026
-- Host        : dkeL running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub -rename_top taxi_eth_phy_25g_us_gth_ch -prefix
--               taxi_eth_phy_25g_us_gth_ch_ taxi_eth_phy_25g_us_gth_ch_stub.vhdl
-- Design      : taxi_eth_phy_25g_us_gth_ch
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu7ev-ffvc1156-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity taxi_eth_phy_25g_us_gth_ch is
  Port (
    gtwiz_userclk_tx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_srcclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk2_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_active_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_srcclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk2_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_active_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_tx_in : in STD_LOGIC_VECTOR ( 63 downto 0 );
    gtwiz_userdata_rx_out : out STD_LOGIC_VECTOR ( 63 downto 0 );
    drpaddr_in : in STD_LOGIC_VECTOR ( 9 downto 0 );
    drpclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpdi_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drpen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    eyescanreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxn_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxp_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrxreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gttxreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0clk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0refclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1clk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1refclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfelpmreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxgearboxslip_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpcsreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpd_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxpllclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxpmareset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpolarity_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxprogdivreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxsysclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxuserrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txdiffctrl_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txelecidle_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txheader_in : in STD_LOGIC_VECTOR ( 5 downto 0 );
    txinhibit_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txmaincursor_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    txpcsreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpd_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txpdelecidlemode_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpllclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txpmareset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpolarity_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpostcursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txprecursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txprogdivreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txsequence_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    txsysclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txuserrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpdo_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drprdy_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxn_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxp_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtpowergood_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrlock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxdatavalid_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxheader_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    rxheadervalid_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxprgdivresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxstartofseq_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    txpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txprgdivresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 )
  );

end taxi_eth_phy_25g_us_gth_ch;

architecture stub of taxi_eth_phy_25g_us_gth_ch is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "gtwiz_userclk_tx_reset_in[0:0],gtwiz_userclk_tx_srcclk_out[0:0],gtwiz_userclk_tx_usrclk_out[0:0],gtwiz_userclk_tx_usrclk2_out[0:0],gtwiz_userclk_tx_active_out[0:0],gtwiz_userclk_rx_reset_in[0:0],gtwiz_userclk_rx_srcclk_out[0:0],gtwiz_userclk_rx_usrclk_out[0:0],gtwiz_userclk_rx_usrclk2_out[0:0],gtwiz_userclk_rx_active_out[0:0],gtwiz_reset_tx_done_in[0:0],gtwiz_reset_rx_done_in[0:0],gtwiz_userdata_tx_in[63:0],gtwiz_userdata_rx_out[63:0],drpaddr_in[9:0],drpclk_in[0:0],drpdi_in[15:0],drpen_in[0:0],drpwe_in[0:0],eyescanreset_in[0:0],gthrxn_in[0:0],gthrxp_in[0:0],gtrxreset_in[0:0],gttxreset_in[0:0],qpll0clk_in[0:0],qpll0refclk_in[0:0],qpll1clk_in[0:0],qpll1refclk_in[0:0],rxcdrhold_in[0:0],rxcdrovrden_in[0:0],rxdfelpmreset_in[0:0],rxgearboxslip_in[0:0],rxlpmen_in[0:0],rxpcsreset_in[0:0],rxpd_in[1:0],rxpllclksel_in[1:0],rxpmareset_in[0:0],rxpolarity_in[0:0],rxprogdivreset_in[0:0],rxsysclksel_in[1:0],rxuserrdy_in[0:0],txdiffctrl_in[4:0],txelecidle_in[0:0],txheader_in[5:0],txinhibit_in[0:0],txmaincursor_in[6:0],txpcsreset_in[0:0],txpd_in[1:0],txpdelecidlemode_in[0:0],txpllclksel_in[1:0],txpmareset_in[0:0],txpolarity_in[0:0],txpostcursor_in[4:0],txprecursor_in[4:0],txprogdivreset_in[0:0],txsequence_in[6:0],txsysclksel_in[1:0],txuserrdy_in[0:0],drpdo_out[15:0],drprdy_out[0:0],gthtxn_out[0:0],gthtxp_out[0:0],gtpowergood_out[0:0],rxcdrlock_out[0:0],rxdatavalid_out[1:0],rxheader_out[5:0],rxheadervalid_out[1:0],rxpmaresetdone_out[0:0],rxprgdivresetdone_out[0:0],rxresetdone_out[0:0],rxstartofseq_out[1:0],txpmaresetdone_out[0:0],txprgdivresetdone_out[0:0],txresetdone_out[0:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "taxi_eth_phy_25g_us_gth_ch_gtwizard_top,Vivado 2023.2";
begin
end;
