-- (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of AMD and is protected under U.S. and international copyright
-- and other intellectual property laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- AMD, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) AMD shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or AMD had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- AMD products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of AMD products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-- DO NOT MODIFY THIS FILE.
-- IP VLNV: xilinx.com:ip:gtwizard_ultrascale:1.7
-- IP Revision: 17

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT taxi_eth_phy_25g_us_gth_ll_ch
  PORT (
    gtwiz_userclk_tx_reset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_srcclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_usrclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_usrclk2_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_active_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_reset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_srcclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_usrclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_usrclk2_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_active_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_buffbypass_tx_reset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_buffbypass_tx_start_user_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_buffbypass_tx_done_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_buffbypass_tx_error_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_buffbypass_rx_reset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_buffbypass_rx_start_user_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_buffbypass_rx_done_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_buffbypass_rx_error_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_done_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_done_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userdata_tx_in : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    gtwiz_userdata_rx_out : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    drpaddr_in : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    drpclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpdi_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    drpen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpwe_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    eyescanreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthrxn_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthrxp_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtrxreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gttxreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll0clk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll0refclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll1clk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll1refclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcdrhold_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcdrovrden_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxdfelpmreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxgearboxslip_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxlpmen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpcsreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpd_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    rxpllclksel_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    rxpmareset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpolarity_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxprogdivreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxsysclksel_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    rxuserrdy_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txdiffctrl_in : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    txelecidle_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txheader_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    txinhibit_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txmaincursor_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    txpcsreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpd_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    txpdelecidlemode_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpllclksel_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    txpmareset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpolarity_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpostcursor_in : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    txprecursor_in : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    txprogdivreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txsequence_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    txsysclksel_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    txuserrdy_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpdo_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    drprdy_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthtxn_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthtxp_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtpowergood_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcdrlock_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxdatavalid_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    rxheader_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    rxheadervalid_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxprgdivresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxstartofseq_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    txpmaresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txprgdivresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : taxi_eth_phy_25g_us_gth_ll_ch
  PORT MAP (
    gtwiz_userclk_tx_reset_in => gtwiz_userclk_tx_reset_in,
    gtwiz_userclk_tx_srcclk_out => gtwiz_userclk_tx_srcclk_out,
    gtwiz_userclk_tx_usrclk_out => gtwiz_userclk_tx_usrclk_out,
    gtwiz_userclk_tx_usrclk2_out => gtwiz_userclk_tx_usrclk2_out,
    gtwiz_userclk_tx_active_out => gtwiz_userclk_tx_active_out,
    gtwiz_userclk_rx_reset_in => gtwiz_userclk_rx_reset_in,
    gtwiz_userclk_rx_srcclk_out => gtwiz_userclk_rx_srcclk_out,
    gtwiz_userclk_rx_usrclk_out => gtwiz_userclk_rx_usrclk_out,
    gtwiz_userclk_rx_usrclk2_out => gtwiz_userclk_rx_usrclk2_out,
    gtwiz_userclk_rx_active_out => gtwiz_userclk_rx_active_out,
    gtwiz_buffbypass_tx_reset_in => gtwiz_buffbypass_tx_reset_in,
    gtwiz_buffbypass_tx_start_user_in => gtwiz_buffbypass_tx_start_user_in,
    gtwiz_buffbypass_tx_done_out => gtwiz_buffbypass_tx_done_out,
    gtwiz_buffbypass_tx_error_out => gtwiz_buffbypass_tx_error_out,
    gtwiz_buffbypass_rx_reset_in => gtwiz_buffbypass_rx_reset_in,
    gtwiz_buffbypass_rx_start_user_in => gtwiz_buffbypass_rx_start_user_in,
    gtwiz_buffbypass_rx_done_out => gtwiz_buffbypass_rx_done_out,
    gtwiz_buffbypass_rx_error_out => gtwiz_buffbypass_rx_error_out,
    gtwiz_reset_tx_done_in => gtwiz_reset_tx_done_in,
    gtwiz_reset_rx_done_in => gtwiz_reset_rx_done_in,
    gtwiz_userdata_tx_in => gtwiz_userdata_tx_in,
    gtwiz_userdata_rx_out => gtwiz_userdata_rx_out,
    drpaddr_in => drpaddr_in,
    drpclk_in => drpclk_in,
    drpdi_in => drpdi_in,
    drpen_in => drpen_in,
    drpwe_in => drpwe_in,
    eyescanreset_in => eyescanreset_in,
    gthrxn_in => gthrxn_in,
    gthrxp_in => gthrxp_in,
    gtrxreset_in => gtrxreset_in,
    gttxreset_in => gttxreset_in,
    qpll0clk_in => qpll0clk_in,
    qpll0refclk_in => qpll0refclk_in,
    qpll1clk_in => qpll1clk_in,
    qpll1refclk_in => qpll1refclk_in,
    rxcdrhold_in => rxcdrhold_in,
    rxcdrovrden_in => rxcdrovrden_in,
    rxdfelpmreset_in => rxdfelpmreset_in,
    rxgearboxslip_in => rxgearboxslip_in,
    rxlpmen_in => rxlpmen_in,
    rxpcsreset_in => rxpcsreset_in,
    rxpd_in => rxpd_in,
    rxpllclksel_in => rxpllclksel_in,
    rxpmareset_in => rxpmareset_in,
    rxpolarity_in => rxpolarity_in,
    rxprogdivreset_in => rxprogdivreset_in,
    rxsysclksel_in => rxsysclksel_in,
    rxuserrdy_in => rxuserrdy_in,
    txdiffctrl_in => txdiffctrl_in,
    txelecidle_in => txelecidle_in,
    txheader_in => txheader_in,
    txinhibit_in => txinhibit_in,
    txmaincursor_in => txmaincursor_in,
    txpcsreset_in => txpcsreset_in,
    txpd_in => txpd_in,
    txpdelecidlemode_in => txpdelecidlemode_in,
    txpllclksel_in => txpllclksel_in,
    txpmareset_in => txpmareset_in,
    txpolarity_in => txpolarity_in,
    txpostcursor_in => txpostcursor_in,
    txprecursor_in => txprecursor_in,
    txprogdivreset_in => txprogdivreset_in,
    txsequence_in => txsequence_in,
    txsysclksel_in => txsysclksel_in,
    txuserrdy_in => txuserrdy_in,
    drpdo_out => drpdo_out,
    drprdy_out => drprdy_out,
    gthtxn_out => gthtxn_out,
    gthtxp_out => gthtxp_out,
    gtpowergood_out => gtpowergood_out,
    rxcdrlock_out => rxcdrlock_out,
    rxdatavalid_out => rxdatavalid_out,
    rxheader_out => rxheader_out,
    rxheadervalid_out => rxheadervalid_out,
    rxpmaresetdone_out => rxpmaresetdone_out,
    rxprgdivresetdone_out => rxprgdivresetdone_out,
    rxresetdone_out => rxresetdone_out,
    rxstartofseq_out => rxstartofseq_out,
    txpmaresetdone_out => txpmaresetdone_out,
    txprgdivresetdone_out => txprgdivresetdone_out,
    txresetdone_out => txresetdone_out
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file taxi_eth_phy_25g_us_gth_ll_ch.vhd when simulating
-- the core, taxi_eth_phy_25g_us_gth_ll_ch. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.
