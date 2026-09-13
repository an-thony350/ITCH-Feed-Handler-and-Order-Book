-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
-- Date        : Sun Sep 13 17:47:21 2026
-- Host        : dkeL running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode funcsim -rename_top taxi_eth_phy_25g_us_gth_ll_full -prefix
--               taxi_eth_phy_25g_us_gth_ll_full_ taxi_eth_phy_25g_us_gth_ll_full_sim_netlist.vhdl
-- Design      : taxi_eth_phy_25g_us_gth_ll_full
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xczu7ev-ffvc1156-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer is
  port (
    \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[1]\ : out STD_LOGIC;
    txphaligndone_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    Q : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer is
  signal i_in_meta : STD_LOGIC;
  attribute async_reg : string;
  attribute async_reg of i_in_meta : signal is "true";
  signal i_in_out : STD_LOGIC;
  signal i_in_sync1 : STD_LOGIC;
  attribute async_reg of i_in_sync1 : signal is "true";
  signal i_in_sync2 : STD_LOGIC;
  attribute async_reg of i_in_sync2 : signal is "true";
  signal i_in_sync3 : STD_LOGIC;
  attribute async_reg of i_in_sync3 : signal is "true";
  attribute ASYNC_REG_boolean : boolean;
  attribute ASYNC_REG_boolean of i_in_meta_reg : label is std.standard.true;
  attribute KEEP : string;
  attribute KEEP of i_in_meta_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync1_reg : label is std.standard.true;
  attribute KEEP of i_in_sync1_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync2_reg : label is std.standard.true;
  attribute KEEP of i_in_sync2_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync3_reg : label is std.standard.true;
  attribute KEEP of i_in_sync3_reg : label is "yes";
begin
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_error_out_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => Q(0),
      I1 => i_in_out,
      O => \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[1]\
    );
i_in_meta_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => txphaligndone_out(0),
      Q => i_in_meta,
      R => '0'
    );
i_in_out_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync3,
      Q => i_in_out,
      R => '0'
    );
i_in_sync1_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => i_in_meta,
      Q => i_in_sync1,
      R => '0'
    );
i_in_sync2_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync1,
      Q => i_in_sync2,
      R => '0'
    );
i_in_sync3_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync2,
      Q => i_in_sync3,
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_0 is
  port (
    \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\ : out STD_LOGIC;
    D : out STD_LOGIC_VECTOR ( 1 downto 0 );
    txsyncdone_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    Q : in STD_LOGIC_VECTOR ( 1 downto 0 );
    \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\ : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_0 : entity is "gtwizard_ultrascale_v1_7_17_bit_synchronizer";
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_0;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_0 is
  signal \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\ : STD_LOGIC;
  signal i_in_meta : STD_LOGIC;
  attribute async_reg : string;
  attribute async_reg of i_in_meta : signal is "true";
  signal i_in_sync1 : STD_LOGIC;
  attribute async_reg of i_in_sync1 : signal is "true";
  signal i_in_sync2 : STD_LOGIC;
  attribute async_reg of i_in_sync2 : signal is "true";
  signal i_in_sync3 : STD_LOGIC;
  attribute async_reg of i_in_sync3 : signal is "true";
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx[0]_i_1\ : label is "soft_lutpair2";
  attribute SOFT_HLUTNM of \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx[1]_i_2\ : label is "soft_lutpair2";
  attribute ASYNC_REG_boolean : boolean;
  attribute ASYNC_REG_boolean of i_in_meta_reg : label is std.standard.true;
  attribute KEEP : string;
  attribute KEEP of i_in_meta_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync1_reg : label is std.standard.true;
  attribute KEEP of i_in_sync1_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync2_reg : label is std.standard.true;
  attribute KEEP of i_in_sync2_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync3_reg : label is std.standard.true;
  attribute KEEP of i_in_sync3_reg : label is "yes";
begin
  \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\ <= \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\;
\FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx[0]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0455"
    )
        port map (
      I0 => Q(0),
      I1 => \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\,
      I2 => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\,
      I3 => Q(1),
      O => D(0)
    );
\FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx[1]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"2622"
    )
        port map (
      I0 => Q(0),
      I1 => Q(1),
      I2 => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\,
      I3 => \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\,
      O => D(1)
    );
i_in_meta_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => txsyncdone_out(0),
      Q => i_in_meta,
      R => '0'
    );
i_in_out_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync3,
      Q => \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\,
      R => '0'
    );
i_in_sync1_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => i_in_meta,
      Q => i_in_sync1,
      R => '0'
    );
i_in_sync2_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync1,
      Q => i_in_sync2,
      R => '0'
    );
i_in_sync3_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync2,
      Q => i_in_sync3,
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_1 is
  port (
    \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[1]\ : out STD_LOGIC;
    rxphaligndone_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    Q : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_1 : entity is "gtwizard_ultrascale_v1_7_17_bit_synchronizer";
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_1;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_1 is
  signal i_in_meta : STD_LOGIC;
  attribute async_reg : string;
  attribute async_reg of i_in_meta : signal is "true";
  signal i_in_out_reg_n_0 : STD_LOGIC;
  signal i_in_sync1 : STD_LOGIC;
  attribute async_reg of i_in_sync1 : signal is "true";
  signal i_in_sync2 : STD_LOGIC;
  attribute async_reg of i_in_sync2 : signal is "true";
  signal i_in_sync3 : STD_LOGIC;
  attribute async_reg of i_in_sync3 : signal is "true";
  attribute ASYNC_REG_boolean : boolean;
  attribute ASYNC_REG_boolean of i_in_meta_reg : label is std.standard.true;
  attribute KEEP : string;
  attribute KEEP of i_in_meta_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync1_reg : label is std.standard.true;
  attribute KEEP of i_in_sync1_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync2_reg : label is std.standard.true;
  attribute KEEP of i_in_sync2_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync3_reg : label is std.standard.true;
  attribute KEEP of i_in_sync3_reg : label is "yes";
begin
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_error_out_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => Q(0),
      I1 => i_in_out_reg_n_0,
      O => \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[1]\
    );
i_in_meta_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => rxphaligndone_out(0),
      Q => i_in_meta,
      R => '0'
    );
i_in_out_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync3,
      Q => i_in_out_reg_n_0,
      R => '0'
    );
i_in_sync1_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => i_in_meta,
      Q => i_in_sync1,
      R => '0'
    );
i_in_sync2_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync1,
      Q => i_in_sync2,
      R => '0'
    );
i_in_sync3_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync2,
      Q => i_in_sync3,
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_2 is
  port (
    \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\ : out STD_LOGIC;
    D : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxsyncdone_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    Q : in STD_LOGIC_VECTOR ( 1 downto 0 );
    \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\ : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_2 : entity is "gtwizard_ultrascale_v1_7_17_bit_synchronizer";
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_2;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_2 is
  signal \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\ : STD_LOGIC;
  signal i_in_meta : STD_LOGIC;
  attribute async_reg : string;
  attribute async_reg of i_in_meta : signal is "true";
  signal i_in_sync1 : STD_LOGIC;
  attribute async_reg of i_in_sync1 : signal is "true";
  signal i_in_sync2 : STD_LOGIC;
  attribute async_reg of i_in_sync2 : signal is "true";
  signal i_in_sync3 : STD_LOGIC;
  attribute async_reg of i_in_sync3 : signal is "true";
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx[0]_i_1\ : label is "soft_lutpair0";
  attribute SOFT_HLUTNM of \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx[1]_i_2\ : label is "soft_lutpair0";
  attribute ASYNC_REG_boolean : boolean;
  attribute ASYNC_REG_boolean of i_in_meta_reg : label is std.standard.true;
  attribute KEEP : string;
  attribute KEEP of i_in_meta_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync1_reg : label is std.standard.true;
  attribute KEEP of i_in_sync1_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync2_reg : label is std.standard.true;
  attribute KEEP of i_in_sync2_reg : label is "yes";
  attribute ASYNC_REG_boolean of i_in_sync3_reg : label is std.standard.true;
  attribute KEEP of i_in_sync3_reg : label is "yes";
begin
  \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\ <= \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\;
\FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx[0]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0455"
    )
        port map (
      I0 => Q(0),
      I1 => \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\,
      I2 => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\,
      I3 => Q(1),
      O => D(0)
    );
\FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx[1]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"2622"
    )
        port map (
      I0 => Q(0),
      I1 => Q(1),
      I2 => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\,
      I3 => \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\,
      O => D(1)
    );
i_in_meta_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => rxsyncdone_out(0),
      Q => i_in_meta,
      R => '0'
    );
i_in_out_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync3,
      Q => \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\,
      R => '0'
    );
i_in_sync1_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => i_in_meta,
      Q => i_in_sync1,
      R => '0'
    );
i_in_sync2_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync1,
      Q => i_in_sync2,
      R => '0'
    );
i_in_sync3_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => i_in_sync2,
      Q => i_in_sync3,
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_channel is
  port (
    drprdy_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxn_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxp_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.gtpowergood_int\ : out STD_LOGIC;
    rxcdrlock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_srcclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxoutclkpcs_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxphaligndone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxprgdivresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxsyncdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_srcclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txphaligndone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txprgdivresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txsyncdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_rx_out : out STD_LOGIC_VECTOR ( 63 downto 0 );
    drpdo_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    rxdatavalid_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxheadervalid_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxstartofseq_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxheader_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_0\ : out STD_LOGIC;
    drpclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    eyescanreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxn_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxp_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.gtrxreset_ch_int\ : in STD_LOGIC;
    gttxreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outrefclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outrefclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfelpmreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.rxdlysreset_int\ : in STD_LOGIC;
    rxgearboxslip_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpcsreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.rxpmareset_ch_int\ : in STD_LOGIC;
    rxpolarity_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxprogdivreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    RXRATE : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxuserrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.txdlysreset_int\ : in STD_LOGIC;
    txelecidle_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txinhibit_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpcsreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpdelecidlemode_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpmareset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpolarity_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txprogdivreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txuserrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_tx_in : in STD_LOGIC_VECTOR ( 63 downto 0 );
    drpdi_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    RXPD : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxpllclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxsysclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txpd_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txpllclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txsysclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txdiffctrl_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txpostcursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txprecursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txheader_in : in STD_LOGIC_VECTOR ( 5 downto 0 );
    txmaincursor_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    txsequence_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    drpaddr_in : in STD_LOGIC_VECTOR ( 9 downto 0 );
    lopt : in STD_LOGIC;
    lopt_1 : in STD_LOGIC;
    lopt_2 : out STD_LOGIC;
    lopt_3 : out STD_LOGIC;
    lopt_4 : in STD_LOGIC;
    lopt_5 : in STD_LOGIC;
    lopt_6 : out STD_LOGIC;
    lopt_7 : out STD_LOGIC
  );
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_channel;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_channel is
  signal \^gen_gtwizard_gthe4.gtpowergood_int\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_0\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_1\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_100\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_101\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_102\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_103\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_104\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_105\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_106\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_107\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_108\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_109\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_11\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_110\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_111\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_112\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_113\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_114\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_115\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_116\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_117\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_118\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_119\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_12\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_120\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_121\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_122\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_123\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_124\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_125\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_126\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_127\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_128\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_129\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_13\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_130\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_131\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_132\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_133\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_134\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_135\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_136\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_137\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_138\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_139\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_14\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_140\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_141\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_142\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_15\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_16\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_17\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_18\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_19\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_2\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_20\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_207\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_208\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_209\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_21\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_210\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_211\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_212\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_213\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_214\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_215\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_216\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_217\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_218\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_219\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_22\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_220\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_221\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_222\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_239\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_24\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_240\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_241\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_242\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_243\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_244\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_245\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_246\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_247\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_248\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_249\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_25\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_250\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_251\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_252\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_253\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_254\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_255\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_256\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_257\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_258\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_259\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_26\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_260\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_261\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_262\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_263\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_264\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_265\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_266\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_267\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_268\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_269\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_27\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_270\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_271\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_272\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_273\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_274\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_275\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_276\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_277\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_278\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_279\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_28\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_280\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_281\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_282\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_283\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_284\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_285\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_286\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_287\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_288\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_289\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_29\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_290\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_291\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_292\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_293\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_294\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_295\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_296\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_297\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_298\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_299\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_3\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_30\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_300\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_301\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_302\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_303\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_304\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_305\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_306\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_307\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_308\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_31\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_315\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_316\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_317\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_318\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_319\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_32\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_320\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_321\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_322\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_323\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_324\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_325\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_326\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_327\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_328\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_329\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_33\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_330\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_331\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_332\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_333\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_34\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_340\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_341\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_342\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_343\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_344\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_345\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_346\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_347\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_348\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_349\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_35\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_350\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_351\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_352\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_353\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_354\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_355\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_356\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_357\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_358\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_359\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_36\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_360\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_361\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_362\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_363\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_364\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_365\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_366\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_367\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_368\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_369\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_37\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_370\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_371\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_372\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_373\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_374\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_375\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_376\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_377\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_378\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_379\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_38\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_380\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_39\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_4\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_40\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_41\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_43\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_46\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_48\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_49\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_5\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_51\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_52\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_53\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_54\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_56\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_57\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_58\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_59\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_61\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_62\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_63\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_64\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_65\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_67\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_68\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_7\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_70\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_73\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_74\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_75\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_78\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_79\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_80\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_81\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_82\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_83\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_84\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_85\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_86\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_87\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_88\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_89\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_90\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_91\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_92\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_93\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_94\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_95\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_96\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_97\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_98\ : STD_LOGIC;
  signal \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_99\ : STD_LOGIC;
  signal \^gtwiz_userclk_rx_srcclk_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^gtwiz_userclk_tx_srcclk_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^lopt_2\ : STD_LOGIC;
  signal \^lopt_3\ : STD_LOGIC;
  signal \^rxphaligndone_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^txphaligndone_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \xlnx_opt_\ : STD_LOGIC;
  signal \xlnx_opt__1\ : STD_LOGIC;
  signal \xlnx_opt__2\ : STD_LOGIC;
  signal \xlnx_opt__3\ : STD_LOGIC;
  attribute OPT_MODIFIED : string;
  attribute OPT_MODIFIED of BUFG_GT_SYNC : label is "MLO";
  attribute OPT_MODIFIED of BUFG_GT_SYNC_1 : label is "MLO";
  attribute BOX_TYPE : string;
  attribute BOX_TYPE of \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST\ : label is "PRIMITIVE";
begin
  \^lopt_2\ <= lopt_4;
  \^lopt_3\ <= lopt_5;
  \gen_gtwizard_gthe4.gtpowergood_int\ <= \^gen_gtwizard_gthe4.gtpowergood_int\;
  gtwiz_userclk_rx_srcclk_out(0) <= \^gtwiz_userclk_rx_srcclk_out\(0);
  gtwiz_userclk_tx_srcclk_out(0) <= \^gtwiz_userclk_tx_srcclk_out\(0);
  lopt_2 <= \xlnx_opt_\;
  lopt_3 <= \xlnx_opt__1\;
  lopt_6 <= \xlnx_opt__2\;
  lopt_7 <= \xlnx_opt__3\;
  rxphaligndone_out(0) <= \^rxphaligndone_out\(0);
  txphaligndone_out(0) <= \^txphaligndone_out\(0);
BUFG_GT_SYNC: unisim.vcomponents.BUFG_GT_SYNC
     port map (
      CE => lopt,
      CESYNC => \xlnx_opt_\,
      CLK => \^gtwiz_userclk_rx_srcclk_out\(0),
      CLR => lopt_1,
      CLRSYNC => \xlnx_opt__1\
    );
BUFG_GT_SYNC_1: unisim.vcomponents.BUFG_GT_SYNC
     port map (
      CE => \^lopt_2\,
      CESYNC => \xlnx_opt__2\,
      CLK => \^gtwiz_userclk_tx_srcclk_out\(0),
      CLR => \^lopt_3\,
      CLRSYNC => \xlnx_opt__3\
    );
\gen_powergood_delay.intclk_rrst_n_r[4]_i_2\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \^gen_gtwizard_gthe4.gtpowergood_int\,
      O => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_0\
    );
\gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST\: unisim.vcomponents.GTHE4_CHANNEL
    generic map(
      ACJTAG_DEBUG_MODE => '0',
      ACJTAG_MODE => '0',
      ACJTAG_RESET => '0',
      ADAPT_CFG0 => X"1000",
      ADAPT_CFG1 => X"C800",
      ADAPT_CFG2 => X"0000",
      ALIGN_COMMA_DOUBLE => "FALSE",
      ALIGN_COMMA_ENABLE => B"0000000000",
      ALIGN_COMMA_WORD => 1,
      ALIGN_MCOMMA_DET => "FALSE",
      ALIGN_MCOMMA_VALUE => B"1010000011",
      ALIGN_PCOMMA_DET => "FALSE",
      ALIGN_PCOMMA_VALUE => B"0101111100",
      A_RXOSCALRESET => '0',
      A_RXPROGDIVRESET => '0',
      A_RXTERMINATION => '1',
      A_TXDIFFCTRL => B"01100",
      A_TXPROGDIVRESET => '0',
      CAPBYPASS_FORCE => '0',
      CBCC_DATA_SOURCE_SEL => "ENCODED",
      CDR_SWAP_MODE_EN => '0',
      CFOK_PWRSVE_EN => '1',
      CHAN_BOND_KEEP_ALIGN => "FALSE",
      CHAN_BOND_MAX_SKEW => 1,
      CHAN_BOND_SEQ_1_1 => B"0000000000",
      CHAN_BOND_SEQ_1_2 => B"0000000000",
      CHAN_BOND_SEQ_1_3 => B"0000000000",
      CHAN_BOND_SEQ_1_4 => B"0000000000",
      CHAN_BOND_SEQ_1_ENABLE => B"1111",
      CHAN_BOND_SEQ_2_1 => B"0000000000",
      CHAN_BOND_SEQ_2_2 => B"0000000000",
      CHAN_BOND_SEQ_2_3 => B"0000000000",
      CHAN_BOND_SEQ_2_4 => B"0000000000",
      CHAN_BOND_SEQ_2_ENABLE => B"1111",
      CHAN_BOND_SEQ_2_USE => "FALSE",
      CHAN_BOND_SEQ_LEN => 1,
      CH_HSPMUX => X"2424",
      CKCAL1_CFG_0 => B"1100000011000000",
      CKCAL1_CFG_1 => B"0101000011000000",
      CKCAL1_CFG_2 => B"0000000000001010",
      CKCAL1_CFG_3 => B"0000000000000000",
      CKCAL2_CFG_0 => B"1100000011000000",
      CKCAL2_CFG_1 => B"1000000011000000",
      CKCAL2_CFG_2 => B"0000000000000000",
      CKCAL2_CFG_3 => B"0000000000000000",
      CKCAL2_CFG_4 => B"0000000000000000",
      CKCAL_RSVD0 => X"0000",
      CKCAL_RSVD1 => X"0400",
      CLK_CORRECT_USE => "FALSE",
      CLK_COR_KEEP_IDLE => "FALSE",
      CLK_COR_MAX_LAT => 20,
      CLK_COR_MIN_LAT => 18,
      CLK_COR_PRECEDENCE => "TRUE",
      CLK_COR_REPEAT_WAIT => 0,
      CLK_COR_SEQ_1_1 => B"0000000000",
      CLK_COR_SEQ_1_2 => B"0000000000",
      CLK_COR_SEQ_1_3 => B"0000000000",
      CLK_COR_SEQ_1_4 => B"0000000000",
      CLK_COR_SEQ_1_ENABLE => B"1111",
      CLK_COR_SEQ_2_1 => B"0000000000",
      CLK_COR_SEQ_2_2 => B"0000000000",
      CLK_COR_SEQ_2_3 => B"0000000000",
      CLK_COR_SEQ_2_4 => B"0000000000",
      CLK_COR_SEQ_2_ENABLE => B"1111",
      CLK_COR_SEQ_2_USE => "FALSE",
      CLK_COR_SEQ_LEN => 1,
      CPLL_CFG0 => X"01FA",
      CPLL_CFG1 => X"0023",
      CPLL_CFG2 => X"0002",
      CPLL_CFG3 => X"0000",
      CPLL_FBDIV => 2,
      CPLL_FBDIV_45 => 5,
      CPLL_INIT_CFG0 => X"02B2",
      CPLL_LOCK_CFG => X"01E8",
      CPLL_REFCLK_DIV => 1,
      CTLE3_OCAP_EXT_CTRL => B"000",
      CTLE3_OCAP_EXT_EN => '0',
      DDI_CTRL => B"00",
      DDI_REALIGN_WAIT => 15,
      DEC_MCOMMA_DETECT => "FALSE",
      DEC_PCOMMA_DETECT => "FALSE",
      DEC_VALID_COMMA_ONLY => "FALSE",
      DELAY_ELEC => '0',
      DMONITOR_CFG0 => B"00" & X"00",
      DMONITOR_CFG1 => X"00",
      ES_CLK_PHASE_SEL => '0',
      ES_CONTROL => B"000000",
      ES_ERRDET_EN => "FALSE",
      ES_EYE_SCAN_EN => "FALSE",
      ES_HORZ_OFFSET => X"000",
      ES_PRESCALE => B"00000",
      ES_QUALIFIER0 => X"0000",
      ES_QUALIFIER1 => X"0000",
      ES_QUALIFIER2 => X"0000",
      ES_QUALIFIER3 => X"0000",
      ES_QUALIFIER4 => X"0000",
      ES_QUALIFIER5 => X"0000",
      ES_QUALIFIER6 => X"0000",
      ES_QUALIFIER7 => X"0000",
      ES_QUALIFIER8 => X"0000",
      ES_QUALIFIER9 => X"0000",
      ES_QUAL_MASK0 => X"0000",
      ES_QUAL_MASK1 => X"0000",
      ES_QUAL_MASK2 => X"0000",
      ES_QUAL_MASK3 => X"0000",
      ES_QUAL_MASK4 => X"0000",
      ES_QUAL_MASK5 => X"0000",
      ES_QUAL_MASK6 => X"0000",
      ES_QUAL_MASK7 => X"0000",
      ES_QUAL_MASK8 => X"0000",
      ES_QUAL_MASK9 => X"0000",
      ES_SDATA_MASK0 => X"0000",
      ES_SDATA_MASK1 => X"0000",
      ES_SDATA_MASK2 => X"0000",
      ES_SDATA_MASK3 => X"0000",
      ES_SDATA_MASK4 => X"0000",
      ES_SDATA_MASK5 => X"0000",
      ES_SDATA_MASK6 => X"0000",
      ES_SDATA_MASK7 => X"0000",
      ES_SDATA_MASK8 => X"0000",
      ES_SDATA_MASK9 => X"0000",
      EYE_SCAN_SWAP_EN => '0',
      FTS_DESKEW_SEQ_ENABLE => B"1111",
      FTS_LANE_DESKEW_CFG => B"1111",
      FTS_LANE_DESKEW_EN => "FALSE",
      GEARBOX_MODE => B"00001",
      ISCAN_CK_PH_SEL2 => '0',
      LOCAL_MASTER => '1',
      LPBK_BIAS_CTRL => B"100",
      LPBK_EN_RCAL_B => '0',
      LPBK_EXT_RCAL => B"1000",
      LPBK_IND_CTRL0 => B"000",
      LPBK_IND_CTRL1 => B"000",
      LPBK_IND_CTRL2 => B"000",
      LPBK_RG_CTRL => B"1110",
      OOBDIVCTL => B"00",
      OOB_PWRUP => '0',
      PCI3_AUTO_REALIGN => "OVR_1K_BLK",
      PCI3_PIPE_RX_ELECIDLE => '0',
      PCI3_RX_ASYNC_EBUF_BYPASS => B"00",
      PCI3_RX_ELECIDLE_EI2_ENABLE => '0',
      PCI3_RX_ELECIDLE_H2L_COUNT => B"000000",
      PCI3_RX_ELECIDLE_H2L_DISABLE => B"000",
      PCI3_RX_ELECIDLE_HI_COUNT => B"000000",
      PCI3_RX_ELECIDLE_LP4_DISABLE => '0',
      PCI3_RX_FIFO_DISABLE => '0',
      PCIE3_CLK_COR_EMPTY_THRSH => B"00000",
      PCIE3_CLK_COR_FULL_THRSH => B"010000",
      PCIE3_CLK_COR_MAX_LAT => B"00100",
      PCIE3_CLK_COR_MIN_LAT => B"00000",
      PCIE3_CLK_COR_THRSH_TIMER => B"001000",
      PCIE_BUFG_DIV_CTRL => X"3500",
      PCIE_PLL_SEL_MODE_GEN12 => B"10",
      PCIE_PLL_SEL_MODE_GEN3 => B"10",
      PCIE_PLL_SEL_MODE_GEN4 => B"10",
      PCIE_RXPCS_CFG_GEN3 => X"0AA5",
      PCIE_RXPMA_CFG => X"280A",
      PCIE_TXPCS_CFG_GEN3 => X"2CA4",
      PCIE_TXPMA_CFG => X"280A",
      PCS_PCIE_EN => "FALSE",
      PCS_RSVD0 => B"0000000000000000",
      PD_TRANS_TIME_FROM_P2 => X"03C",
      PD_TRANS_TIME_NONE_P2 => X"19",
      PD_TRANS_TIME_TO_P2 => X"64",
      PREIQ_FREQ_BST => 0,
      PROCESS_PAR => B"010",
      RATE_SW_USE_DRP => '1',
      RCLK_SIPO_DLY_ENB => '0',
      RCLK_SIPO_INV_EN => '0',
      RESET_POWERSAVE_DISABLE => '0',
      RTX_BUF_CML_CTRL => B"010",
      RTX_BUF_TERM_CTRL => B"00",
      RXBUFRESET_TIME => B"00011",
      RXBUF_ADDR_MODE => "FAST",
      RXBUF_EIDLE_HI_CNT => B"1000",
      RXBUF_EIDLE_LO_CNT => B"0000",
      RXBUF_EN => "FALSE",
      RXBUF_RESET_ON_CB_CHANGE => "TRUE",
      RXBUF_RESET_ON_COMMAALIGN => "FALSE",
      RXBUF_RESET_ON_EIDLE => "FALSE",
      RXBUF_RESET_ON_RATE_CHANGE => "TRUE",
      RXBUF_THRESH_OVFLW => 0,
      RXBUF_THRESH_OVRD => "FALSE",
      RXBUF_THRESH_UNDFLW => 4,
      RXCDRFREQRESET_TIME => B"00001",
      RXCDRPHRESET_TIME => B"00001",
      RXCDR_CFG0 => X"0003",
      RXCDR_CFG0_GEN3 => X"0003",
      RXCDR_CFG1 => X"0000",
      RXCDR_CFG1_GEN3 => X"0000",
      RXCDR_CFG2 => X"0269",
      RXCDR_CFG2_GEN2 => B"10" & X"69",
      RXCDR_CFG2_GEN3 => X"0269",
      RXCDR_CFG2_GEN4 => X"0164",
      RXCDR_CFG3 => X"0010",
      RXCDR_CFG3_GEN2 => B"01" & X"0",
      RXCDR_CFG3_GEN3 => X"0010",
      RXCDR_CFG3_GEN4 => X"0012",
      RXCDR_CFG4 => X"5CF6",
      RXCDR_CFG4_GEN3 => X"5CF6",
      RXCDR_CFG5 => X"B46B",
      RXCDR_CFG5_GEN3 => X"146B",
      RXCDR_FR_RESET_ON_EIDLE => '0',
      RXCDR_HOLD_DURING_EIDLE => '0',
      RXCDR_LOCK_CFG0 => X"2201",
      RXCDR_LOCK_CFG1 => X"9FFF",
      RXCDR_LOCK_CFG2 => X"77C3",
      RXCDR_LOCK_CFG3 => X"0001",
      RXCDR_LOCK_CFG4 => X"0000",
      RXCDR_PH_RESET_ON_EIDLE => '0',
      RXCFOK_CFG0 => X"0000",
      RXCFOK_CFG1 => X"8015",
      RXCFOK_CFG2 => X"02AE",
      RXCKCAL1_IQ_LOOP_RST_CFG => X"0004",
      RXCKCAL1_I_LOOP_RST_CFG => X"0004",
      RXCKCAL1_Q_LOOP_RST_CFG => X"0004",
      RXCKCAL2_DX_LOOP_RST_CFG => X"0004",
      RXCKCAL2_D_LOOP_RST_CFG => X"0004",
      RXCKCAL2_S_LOOP_RST_CFG => X"0004",
      RXCKCAL2_X_LOOP_RST_CFG => X"0004",
      RXDFELPMRESET_TIME => B"0001111",
      RXDFELPM_KL_CFG0 => X"0000",
      RXDFELPM_KL_CFG1 => X"A0E2",
      RXDFELPM_KL_CFG2 => X"0100",
      RXDFE_CFG0 => X"0A00",
      RXDFE_CFG1 => X"0000",
      RXDFE_GC_CFG0 => X"0000",
      RXDFE_GC_CFG1 => X"8000",
      RXDFE_GC_CFG2 => X"FFE0",
      RXDFE_H2_CFG0 => X"0000",
      RXDFE_H2_CFG1 => X"0002",
      RXDFE_H3_CFG0 => X"0000",
      RXDFE_H3_CFG1 => X"8002",
      RXDFE_H4_CFG0 => X"0000",
      RXDFE_H4_CFG1 => X"8002",
      RXDFE_H5_CFG0 => X"0000",
      RXDFE_H5_CFG1 => X"8002",
      RXDFE_H6_CFG0 => X"0000",
      RXDFE_H6_CFG1 => X"8002",
      RXDFE_H7_CFG0 => X"0000",
      RXDFE_H7_CFG1 => X"8002",
      RXDFE_H8_CFG0 => X"0000",
      RXDFE_H8_CFG1 => X"8002",
      RXDFE_H9_CFG0 => X"0000",
      RXDFE_H9_CFG1 => X"8002",
      RXDFE_HA_CFG0 => X"0000",
      RXDFE_HA_CFG1 => X"8002",
      RXDFE_HB_CFG0 => X"0000",
      RXDFE_HB_CFG1 => X"8002",
      RXDFE_HC_CFG0 => X"0000",
      RXDFE_HC_CFG1 => X"8002",
      RXDFE_HD_CFG0 => X"0000",
      RXDFE_HD_CFG1 => X"8002",
      RXDFE_HE_CFG0 => X"0000",
      RXDFE_HE_CFG1 => X"8002",
      RXDFE_HF_CFG0 => X"0000",
      RXDFE_HF_CFG1 => X"8002",
      RXDFE_KH_CFG0 => X"0000",
      RXDFE_KH_CFG1 => X"8000",
      RXDFE_KH_CFG2 => X"2613",
      RXDFE_KH_CFG3 => X"411C",
      RXDFE_OS_CFG0 => X"0000",
      RXDFE_OS_CFG1 => X"8002",
      RXDFE_PWR_SAVING => '1',
      RXDFE_UT_CFG0 => X"0000",
      RXDFE_UT_CFG1 => X"0003",
      RXDFE_UT_CFG2 => X"0000",
      RXDFE_VP_CFG0 => X"0000",
      RXDFE_VP_CFG1 => X"8033",
      RXDLY_CFG => X"0010",
      RXDLY_LCFG => X"0030",
      RXELECIDLE_CFG => "SIGCFG_4",
      RXGBOX_FIFO_INIT_RD_ADDR => 4,
      RXGEARBOX_EN => "TRUE",
      RXISCANRESET_TIME => B"00001",
      RXLPM_CFG => X"0000",
      RXLPM_GC_CFG => X"8000",
      RXLPM_KH_CFG0 => X"0000",
      RXLPM_KH_CFG1 => X"0002",
      RXLPM_OS_CFG0 => X"0000",
      RXLPM_OS_CFG1 => X"8002",
      RXOOB_CFG => B"000000110",
      RXOOB_CLK_CFG => "PMA",
      RXOSCALRESET_TIME => B"00011",
      RXOUT_DIV => 1,
      RXPCSRESET_TIME => B"00011",
      RXPHBEACON_CFG => X"0000",
      RXPHDLY_CFG => X"2070",
      RXPHSAMP_CFG => X"2100",
      RXPHSLIP_CFG => X"9933",
      RXPH_MONITOR_SEL => B"00000",
      RXPI_AUTO_BW_SEL_BYPASS => '0',
      RXPI_CFG0 => X"0002",
      RXPI_CFG1 => B"0000000000010101",
      RXPI_LPM => '0',
      RXPI_SEL_LC => B"00",
      RXPI_STARTCODE => B"00",
      RXPI_VREFSEL => '0',
      RXPMACLK_SEL => "DATA",
      RXPMARESET_TIME => B"00011",
      RXPRBS_ERR_LOOPBACK => '0',
      RXPRBS_LINKACQ_CNT => 15,
      RXREFCLKDIV2_SEL => '0',
      RXSLIDE_AUTO_WAIT => 7,
      RXSLIDE_MODE => "OFF",
      RXSYNC_MULTILANE => '0',
      RXSYNC_OVRD => '0',
      RXSYNC_SKIP_DA => '0',
      RX_AFE_CM_EN => '0',
      RX_BIAS_CFG0 => X"1554",
      RX_BUFFER_CFG => B"000000",
      RX_CAPFF_SARC_ENB => '0',
      RX_CLK25_DIV => 7,
      RX_CLKMUX_EN => '1',
      RX_CLK_SLIP_OVRD => B"00000",
      RX_CM_BUF_CFG => B"1010",
      RX_CM_BUF_PD => '0',
      RX_CM_SEL => 3,
      RX_CM_TRIM => 10,
      RX_CTLE3_LPF => B"11111111",
      RX_DATA_WIDTH => 64,
      RX_DDI_SEL => B"000000",
      RX_DEFER_RESET_BUF_EN => "TRUE",
      RX_DEGEN_CTRL => B"011",
      RX_DFELPM_CFG0 => 6,
      RX_DFELPM_CFG1 => '1',
      RX_DFELPM_KLKH_AGC_STUP_EN => '1',
      RX_DFE_AGC_CFG0 => B"10",
      RX_DFE_AGC_CFG1 => 4,
      RX_DFE_KL_LPM_KH_CFG0 => 1,
      RX_DFE_KL_LPM_KH_CFG1 => 4,
      RX_DFE_KL_LPM_KL_CFG0 => B"01",
      RX_DFE_KL_LPM_KL_CFG1 => 4,
      RX_DFE_LPM_HOLD_DURING_EIDLE => '0',
      RX_DISPERR_SEQ_MATCH => "TRUE",
      RX_DIV2_MODE_B => '0',
      RX_DIVRESET_TIME => B"00001",
      RX_EN_CTLE_RCAL_B => '0',
      RX_EN_HI_LR => '1',
      RX_EXT_RL_CTRL => B"000000000",
      RX_EYESCAN_VS_CODE => B"0000000",
      RX_EYESCAN_VS_NEG_DIR => '0',
      RX_EYESCAN_VS_RANGE => B"00",
      RX_EYESCAN_VS_UT_SIGN => '0',
      RX_FABINT_USRCLK_FLOP => '0',
      RX_INT_DATAWIDTH => 1,
      RX_PMA_POWER_SAVE => '0',
      RX_PMA_RSV0 => X"0000",
      RX_PROGDIV_CFG => 0.000000,
      RX_PROGDIV_RATE => X"0001",
      RX_RESLOAD_CTRL => B"0000",
      RX_RESLOAD_OVRD => '0',
      RX_SAMPLE_PERIOD => B"111",
      RX_SIG_VALID_DLY => 11,
      RX_SUM_DFETAPREP_EN => '0',
      RX_SUM_IREF_TUNE => B"1001",
      RX_SUM_RESLOAD_CTRL => B"0011",
      RX_SUM_VCMTUNE => B"1010",
      RX_SUM_VCM_OVWR => '0',
      RX_SUM_VREF_TUNE => B"100",
      RX_TUNE_AFE_OS => B"00",
      RX_VREG_CTRL => B"101",
      RX_VREG_PDB => '1',
      RX_WIDEMODE_CDR => B"01",
      RX_WIDEMODE_CDR_GEN3 => B"00",
      RX_WIDEMODE_CDR_GEN4 => B"01",
      RX_XCLK_SEL => "RXUSR",
      RX_XMODE_SEL => '0',
      SAMPLE_CLK_PHASE => '0',
      SAS_12G_MODE => '0',
      SATA_BURST_SEQ_LEN => B"1111",
      SATA_BURST_VAL => B"100",
      SATA_CPLL_CFG => "VCO_3000MHZ",
      SATA_EIDLE_VAL => B"100",
      SHOW_REALIGN_COMMA => "TRUE",
      SIM_DEVICE => "ULTRASCALE_PLUS",
      SIM_MODE => "FAST",
      SIM_RECEIVER_DETECT_PASS => "TRUE",
      SIM_RESET_SPEEDUP => "TRUE",
      SIM_TX_EIDLE_DRIVE_LEVEL => "Z",
      SRSTMODE => '0',
      TAPDLY_SET_TX => B"00",
      TEMPERATURE_PAR => B"0010",
      TERM_RCAL_CFG => B"100001000010001",
      TERM_RCAL_OVRD => B"000",
      TRANS_TIME_RATE => X"0E",
      TST_RSV0 => X"00",
      TST_RSV1 => X"00",
      TXBUF_EN => "FALSE",
      TXBUF_RESET_ON_RATE_CHANGE => "TRUE",
      TXDLY_CFG => X"8010",
      TXDLY_LCFG => X"0030",
      TXDRVBIAS_N => B"1010",
      TXFIFO_ADDR_CFG => "LOW",
      TXGBOX_FIFO_INIT_RD_ADDR => 4,
      TXGEARBOX_EN => "TRUE",
      TXOUT_DIV => 1,
      TXPCSRESET_TIME => B"00011",
      TXPHDLY_CFG0 => X"6070",
      TXPHDLY_CFG1 => X"000E",
      TXPH_CFG => X"0323",
      TXPH_CFG2 => X"0000",
      TXPH_MONITOR_SEL => B"00000",
      TXPI_CFG => X"0054",
      TXPI_CFG0 => B"00",
      TXPI_CFG1 => B"00",
      TXPI_CFG2 => B"00",
      TXPI_CFG3 => '0',
      TXPI_CFG4 => '0',
      TXPI_CFG5 => B"000",
      TXPI_GRAY_SEL => '0',
      TXPI_INVSTROBE_SEL => '0',
      TXPI_LPM => '0',
      TXPI_PPM => '0',
      TXPI_PPMCLK_SEL => "TXUSRCLK2",
      TXPI_PPM_CFG => B"00000000",
      TXPI_SYNFREQ_PPM => B"001",
      TXPI_VREFSEL => '0',
      TXPMARESET_TIME => B"00011",
      TXREFCLKDIV2_SEL => '0',
      TXSYNC_MULTILANE => '0',
      TXSYNC_OVRD => '0',
      TXSYNC_SKIP_DA => '0',
      TX_CLK25_DIV => 7,
      TX_CLKMUX_EN => '1',
      TX_DATA_WIDTH => 64,
      TX_DCC_LOOP_RST_CFG => X"0004",
      TX_DEEMPH0 => B"000000",
      TX_DEEMPH1 => B"000000",
      TX_DEEMPH2 => B"000000",
      TX_DEEMPH3 => B"000000",
      TX_DIVRESET_TIME => B"00001",
      TX_DRIVE_MODE => "DIRECT",
      TX_DRVMUX_CTRL => 2,
      TX_EIDLE_ASSERT_DELAY => B"100",
      TX_EIDLE_DEASSERT_DELAY => B"011",
      TX_FABINT_USRCLK_FLOP => '0',
      TX_FIFO_BYP_EN => '1',
      TX_IDLE_DATA_ZERO => '0',
      TX_INT_DATAWIDTH => 1,
      TX_LOOPBACK_DRIVE_HIZ => "FALSE",
      TX_MAINCURSOR_SEL => '0',
      TX_MARGIN_FULL_0 => B"1011111",
      TX_MARGIN_FULL_1 => B"1011110",
      TX_MARGIN_FULL_2 => B"1011100",
      TX_MARGIN_FULL_3 => B"1011010",
      TX_MARGIN_FULL_4 => B"1011000",
      TX_MARGIN_LOW_0 => B"1000110",
      TX_MARGIN_LOW_1 => B"1000101",
      TX_MARGIN_LOW_2 => B"1000011",
      TX_MARGIN_LOW_3 => B"1000010",
      TX_MARGIN_LOW_4 => B"1000000",
      TX_PHICAL_CFG0 => X"0000",
      TX_PHICAL_CFG1 => X"7E00",
      TX_PHICAL_CFG2 => X"0200",
      TX_PI_BIASSET => 1,
      TX_PI_IBIAS_MID => B"00",
      TX_PMADATA_OPT => '0',
      TX_PMA_POWER_SAVE => '0',
      TX_PMA_RSV0 => X"0008",
      TX_PREDRV_CTRL => 2,
      TX_PROGCLK_SEL => "PREPI",
      TX_PROGDIV_CFG => 16.000000,
      TX_PROGDIV_RATE => X"0001",
      TX_QPI_STATUS_EN => '0',
      TX_RXDETECT_CFG => B"00" & X"032",
      TX_RXDETECT_REF => 4,
      TX_SAMPLE_PERIOD => B"111",
      TX_SARC_LPBK_ENB => '0',
      TX_SW_MEAS => B"00",
      TX_VREG_CTRL => B"000",
      TX_VREG_PDB => '0',
      TX_VREG_VREFSEL => B"00",
      TX_XCLK_SEL => "TXUSR",
      USB_BOTH_BURST_IDLE => '0',
      USB_BURSTMAX_U3WAKE => B"1111111",
      USB_BURSTMIN_U3WAKE => B"1100011",
      USB_CLK_COR_EQ_EN => '0',
      USB_EXT_CNTL => '1',
      USB_IDLEMAX_POLLING => B"1010111011",
      USB_IDLEMIN_POLLING => B"0100101011",
      USB_LFPSPING_BURST => B"000000101",
      USB_LFPSPOLLING_BURST => B"000110001",
      USB_LFPSPOLLING_IDLE_MS => B"000000100",
      USB_LFPSU1EXIT_BURST => B"000011101",
      USB_LFPSU2LPEXIT_BURST_MS => B"001100011",
      USB_LFPSU3WAKE_BURST_MS => B"111110011",
      USB_LFPS_TPERIOD => B"0011",
      USB_LFPS_TPERIOD_ACCURATE => '1',
      USB_MODE => '0',
      USB_PCIE_ERR_REP_DIS => '0',
      USB_PING_SATA_MAX_INIT => 21,
      USB_PING_SATA_MIN_INIT => 12,
      USB_POLL_SATA_MAX_BURST => 8,
      USB_POLL_SATA_MIN_BURST => 4,
      USB_RAW_ELEC => '0',
      USB_RXIDLE_P0_CTRL => '1',
      USB_TXIDLE_TUNE_ENABLE => '1',
      USB_U1_SATA_MAX_WAKE => 7,
      USB_U1_SATA_MIN_WAKE => 4,
      USB_U2_SAS_MAX_COM => 64,
      USB_U2_SAS_MIN_COM => 36,
      USE_PCS_CLK_PHASE_SEL => '0',
      Y_ALL_MODE => '0'
    )
        port map (
      BUFGTCE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_0\,
      BUFGTCEMASK(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_317\,
      BUFGTCEMASK(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_318\,
      BUFGTCEMASK(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_319\,
      BUFGTDIV(8) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_372\,
      BUFGTDIV(7) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_373\,
      BUFGTDIV(6) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_374\,
      BUFGTDIV(5) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_375\,
      BUFGTDIV(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_376\,
      BUFGTDIV(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_377\,
      BUFGTDIV(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_378\,
      BUFGTDIV(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_379\,
      BUFGTDIV(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_380\,
      BUFGTRESET => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_1\,
      BUFGTRSTMASK(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_320\,
      BUFGTRSTMASK(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_321\,
      BUFGTRSTMASK(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_322\,
      CDRSTEPDIR => '0',
      CDRSTEPSQ => '0',
      CDRSTEPSX => '0',
      CFGRESET => '0',
      CLKRSVD0 => '0',
      CLKRSVD1 => '0',
      CPLLFBCLKLOST => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_2\,
      CPLLFREQLOCK => '0',
      CPLLLOCK => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_3\,
      CPLLLOCKDETCLK => '0',
      CPLLLOCKEN => '0',
      CPLLPD => '1',
      CPLLREFCLKLOST => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_4\,
      CPLLREFCLKSEL(2 downto 0) => B"001",
      CPLLRESET => '1',
      DMONFIFORESET => '0',
      DMONITORCLK => '0',
      DMONITOROUT(15) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_207\,
      DMONITOROUT(14) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_208\,
      DMONITOROUT(13) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_209\,
      DMONITOROUT(12) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_210\,
      DMONITOROUT(11) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_211\,
      DMONITOROUT(10) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_212\,
      DMONITOROUT(9) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_213\,
      DMONITOROUT(8) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_214\,
      DMONITOROUT(7) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_215\,
      DMONITOROUT(6) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_216\,
      DMONITOROUT(5) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_217\,
      DMONITOROUT(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_218\,
      DMONITOROUT(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_219\,
      DMONITOROUT(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_220\,
      DMONITOROUT(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_221\,
      DMONITOROUT(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_222\,
      DMONITOROUTCLK => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_5\,
      DRPADDR(9 downto 0) => drpaddr_in(9 downto 0),
      DRPCLK => drpclk_in(0),
      DRPDI(15 downto 0) => drpdi_in(15 downto 0),
      DRPDO(15 downto 0) => drpdo_out(15 downto 0),
      DRPEN => drpen_in(0),
      DRPRDY => drprdy_out(0),
      DRPRST => '0',
      DRPWE => drpwe_in(0),
      EYESCANDATAERROR => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_7\,
      EYESCANRESET => eyescanreset_in(0),
      EYESCANTRIGGER => '0',
      FREQOS => '0',
      GTGREFCLK => '0',
      GTHRXN => gthrxn_in(0),
      GTHRXP => gthrxp_in(0),
      GTHTXN => gthtxn_out(0),
      GTHTXP => gthtxp_out(0),
      GTNORTHREFCLK0 => '0',
      GTNORTHREFCLK1 => '0',
      GTPOWERGOOD => \^gen_gtwizard_gthe4.gtpowergood_int\,
      GTREFCLK0 => '0',
      GTREFCLK1 => '0',
      GTREFCLKMONITOR => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_11\,
      GTRSVD(15 downto 0) => B"0000000000000000",
      GTRXRESET => \gen_gtwizard_gthe4.gtrxreset_ch_int\,
      GTRXRESETSEL => '0',
      GTSOUTHREFCLK0 => '0',
      GTSOUTHREFCLK1 => '0',
      GTTXRESET => gttxreset_in(0),
      GTTXRESETSEL => '0',
      INCPCTRL => '0',
      LOOPBACK(2 downto 0) => B"000",
      PCIEEQRXEQADAPTDONE => '0',
      PCIERATEGEN3 => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_12\,
      PCIERATEIDLE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_13\,
      PCIERATEQPLLPD(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_303\,
      PCIERATEQPLLPD(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_304\,
      PCIERATEQPLLRESET(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_305\,
      PCIERATEQPLLRESET(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_306\,
      PCIERSTIDLE => '0',
      PCIERSTTXSYNCSTART => '0',
      PCIESYNCTXSYNCDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_14\,
      PCIEUSERGEN3RDY => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_15\,
      PCIEUSERPHYSTATUSRST => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_16\,
      PCIEUSERRATEDONE => '0',
      PCIEUSERRATESTART => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_17\,
      PCSRSVDIN(15 downto 0) => B"0000000000000000",
      PCSRSVDOUT(15) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_239\,
      PCSRSVDOUT(14) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_240\,
      PCSRSVDOUT(13) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_241\,
      PCSRSVDOUT(12) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_242\,
      PCSRSVDOUT(11) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_243\,
      PCSRSVDOUT(10) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_244\,
      PCSRSVDOUT(9) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_245\,
      PCSRSVDOUT(8) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_246\,
      PCSRSVDOUT(7) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_247\,
      PCSRSVDOUT(6) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_248\,
      PCSRSVDOUT(5) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_249\,
      PCSRSVDOUT(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_250\,
      PCSRSVDOUT(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_251\,
      PCSRSVDOUT(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_252\,
      PCSRSVDOUT(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_253\,
      PCSRSVDOUT(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_254\,
      PHYSTATUS => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_18\,
      PINRSRVDAS(15) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_255\,
      PINRSRVDAS(14) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_256\,
      PINRSRVDAS(13) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_257\,
      PINRSRVDAS(12) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_258\,
      PINRSRVDAS(11) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_259\,
      PINRSRVDAS(10) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_260\,
      PINRSRVDAS(9) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_261\,
      PINRSRVDAS(8) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_262\,
      PINRSRVDAS(7) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_263\,
      PINRSRVDAS(6) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_264\,
      PINRSRVDAS(5) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_265\,
      PINRSRVDAS(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_266\,
      PINRSRVDAS(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_267\,
      PINRSRVDAS(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_268\,
      PINRSRVDAS(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_269\,
      PINRSRVDAS(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_270\,
      POWERPRESENT => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_19\,
      QPLL0CLK => qpll0outclk_out(0),
      QPLL0FREQLOCK => '0',
      QPLL0REFCLK => qpll0outrefclk_out(0),
      QPLL1CLK => qpll1outclk_out(0),
      QPLL1FREQLOCK => '0',
      QPLL1REFCLK => qpll1outrefclk_out(0),
      RESETEXCEPTION => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_20\,
      RESETOVRD => '0',
      RX8B10BEN => '0',
      RXAFECFOKEN => '1',
      RXBUFRESET => '0',
      RXBUFSTATUS(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_323\,
      RXBUFSTATUS(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_324\,
      RXBUFSTATUS(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_325\,
      RXBYTEISALIGNED => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_21\,
      RXBYTEREALIGN => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_22\,
      RXCDRFREQRESET => '0',
      RXCDRHOLD => rxcdrhold_in(0),
      RXCDRLOCK => rxcdrlock_out(0),
      RXCDROVRDEN => rxcdrovrden_in(0),
      RXCDRPHDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_24\,
      RXCDRRESET => '0',
      RXCHANBONDSEQ => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_25\,
      RXCHANISALIGNED => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_26\,
      RXCHANREALIGN => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_27\,
      RXCHBONDEN => '0',
      RXCHBONDI(4 downto 0) => B"00000",
      RXCHBONDLEVEL(2 downto 0) => B"000",
      RXCHBONDMASTER => '0',
      RXCHBONDO(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_329\,
      RXCHBONDO(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_330\,
      RXCHBONDO(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_331\,
      RXCHBONDO(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_332\,
      RXCHBONDO(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_333\,
      RXCHBONDSLAVE => '0',
      RXCKCALDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_28\,
      RXCKCALRESET => '0',
      RXCKCALSTART(6 downto 0) => B"0000000",
      RXCLKCORCNT(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_307\,
      RXCLKCORCNT(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_308\,
      RXCOMINITDET => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_29\,
      RXCOMMADET => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_30\,
      RXCOMMADETEN => '0',
      RXCOMSASDET => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_31\,
      RXCOMWAKEDET => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_32\,
      RXCTRL0(15) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_271\,
      RXCTRL0(14) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_272\,
      RXCTRL0(13) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_273\,
      RXCTRL0(12) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_274\,
      RXCTRL0(11) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_275\,
      RXCTRL0(10) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_276\,
      RXCTRL0(9) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_277\,
      RXCTRL0(8) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_278\,
      RXCTRL0(7) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_279\,
      RXCTRL0(6) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_280\,
      RXCTRL0(5) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_281\,
      RXCTRL0(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_282\,
      RXCTRL0(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_283\,
      RXCTRL0(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_284\,
      RXCTRL0(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_285\,
      RXCTRL0(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_286\,
      RXCTRL1(15) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_287\,
      RXCTRL1(14) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_288\,
      RXCTRL1(13) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_289\,
      RXCTRL1(12) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_290\,
      RXCTRL1(11) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_291\,
      RXCTRL1(10) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_292\,
      RXCTRL1(9) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_293\,
      RXCTRL1(8) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_294\,
      RXCTRL1(7) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_295\,
      RXCTRL1(6) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_296\,
      RXCTRL1(5) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_297\,
      RXCTRL1(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_298\,
      RXCTRL1(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_299\,
      RXCTRL1(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_300\,
      RXCTRL1(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_301\,
      RXCTRL1(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_302\,
      RXCTRL2(7) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_340\,
      RXCTRL2(6) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_341\,
      RXCTRL2(5) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_342\,
      RXCTRL2(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_343\,
      RXCTRL2(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_344\,
      RXCTRL2(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_345\,
      RXCTRL2(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_346\,
      RXCTRL2(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_347\,
      RXCTRL3(7) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_348\,
      RXCTRL3(6) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_349\,
      RXCTRL3(5) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_350\,
      RXCTRL3(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_351\,
      RXCTRL3(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_352\,
      RXCTRL3(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_353\,
      RXCTRL3(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_354\,
      RXCTRL3(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_355\,
      RXDATA(127) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_79\,
      RXDATA(126) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_80\,
      RXDATA(125) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_81\,
      RXDATA(124) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_82\,
      RXDATA(123) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_83\,
      RXDATA(122) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_84\,
      RXDATA(121) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_85\,
      RXDATA(120) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_86\,
      RXDATA(119) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_87\,
      RXDATA(118) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_88\,
      RXDATA(117) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_89\,
      RXDATA(116) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_90\,
      RXDATA(115) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_91\,
      RXDATA(114) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_92\,
      RXDATA(113) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_93\,
      RXDATA(112) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_94\,
      RXDATA(111) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_95\,
      RXDATA(110) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_96\,
      RXDATA(109) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_97\,
      RXDATA(108) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_98\,
      RXDATA(107) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_99\,
      RXDATA(106) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_100\,
      RXDATA(105) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_101\,
      RXDATA(104) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_102\,
      RXDATA(103) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_103\,
      RXDATA(102) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_104\,
      RXDATA(101) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_105\,
      RXDATA(100) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_106\,
      RXDATA(99) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_107\,
      RXDATA(98) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_108\,
      RXDATA(97) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_109\,
      RXDATA(96) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_110\,
      RXDATA(95) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_111\,
      RXDATA(94) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_112\,
      RXDATA(93) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_113\,
      RXDATA(92) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_114\,
      RXDATA(91) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_115\,
      RXDATA(90) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_116\,
      RXDATA(89) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_117\,
      RXDATA(88) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_118\,
      RXDATA(87) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_119\,
      RXDATA(86) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_120\,
      RXDATA(85) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_121\,
      RXDATA(84) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_122\,
      RXDATA(83) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_123\,
      RXDATA(82) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_124\,
      RXDATA(81) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_125\,
      RXDATA(80) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_126\,
      RXDATA(79) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_127\,
      RXDATA(78) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_128\,
      RXDATA(77) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_129\,
      RXDATA(76) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_130\,
      RXDATA(75) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_131\,
      RXDATA(74) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_132\,
      RXDATA(73) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_133\,
      RXDATA(72) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_134\,
      RXDATA(71) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_135\,
      RXDATA(70) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_136\,
      RXDATA(69) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_137\,
      RXDATA(68) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_138\,
      RXDATA(67) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_139\,
      RXDATA(66) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_140\,
      RXDATA(65) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_141\,
      RXDATA(64) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_142\,
      RXDATA(63 downto 0) => gtwiz_userdata_rx_out(63 downto 0),
      RXDATAEXTENDRSVD(7) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_356\,
      RXDATAEXTENDRSVD(6) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_357\,
      RXDATAEXTENDRSVD(5) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_358\,
      RXDATAEXTENDRSVD(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_359\,
      RXDATAEXTENDRSVD(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_360\,
      RXDATAEXTENDRSVD(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_361\,
      RXDATAEXTENDRSVD(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_362\,
      RXDATAEXTENDRSVD(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_363\,
      RXDATAVALID(1 downto 0) => rxdatavalid_out(1 downto 0),
      RXDFEAGCCTRL(1 downto 0) => B"01",
      RXDFEAGCHOLD => '0',
      RXDFEAGCOVRDEN => '0',
      RXDFECFOKFCNUM(3 downto 0) => B"1101",
      RXDFECFOKFEN => '0',
      RXDFECFOKFPULSE => '0',
      RXDFECFOKHOLD => '0',
      RXDFECFOKOVREN => '0',
      RXDFEKHHOLD => '0',
      RXDFEKHOVRDEN => '0',
      RXDFELFHOLD => '0',
      RXDFELFOVRDEN => '0',
      RXDFELPMRESET => rxdfelpmreset_in(0),
      RXDFETAP10HOLD => '0',
      RXDFETAP10OVRDEN => '0',
      RXDFETAP11HOLD => '0',
      RXDFETAP11OVRDEN => '0',
      RXDFETAP12HOLD => '0',
      RXDFETAP12OVRDEN => '0',
      RXDFETAP13HOLD => '0',
      RXDFETAP13OVRDEN => '0',
      RXDFETAP14HOLD => '0',
      RXDFETAP14OVRDEN => '0',
      RXDFETAP15HOLD => '0',
      RXDFETAP15OVRDEN => '0',
      RXDFETAP2HOLD => '0',
      RXDFETAP2OVRDEN => '0',
      RXDFETAP3HOLD => '0',
      RXDFETAP3OVRDEN => '0',
      RXDFETAP4HOLD => '0',
      RXDFETAP4OVRDEN => '0',
      RXDFETAP5HOLD => '0',
      RXDFETAP5OVRDEN => '0',
      RXDFETAP6HOLD => '0',
      RXDFETAP6OVRDEN => '0',
      RXDFETAP7HOLD => '0',
      RXDFETAP7OVRDEN => '0',
      RXDFETAP8HOLD => '0',
      RXDFETAP8OVRDEN => '0',
      RXDFETAP9HOLD => '0',
      RXDFETAP9OVRDEN => '0',
      RXDFEUTHOLD => '0',
      RXDFEUTOVRDEN => '0',
      RXDFEVPHOLD => '0',
      RXDFEVPOVRDEN => '0',
      RXDFEXYDEN => '1',
      RXDLYBYPASS => '0',
      RXDLYEN => '0',
      RXDLYOVRDEN => '0',
      RXDLYSRESET => \gen_gtwizard_gthe4.rxdlysreset_int\,
      RXDLYSRESETDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_33\,
      RXELECIDLE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_34\,
      RXELECIDLEMODE(1 downto 0) => B"11",
      RXEQTRAINING => '0',
      RXGEARBOXSLIP => rxgearboxslip_in(0),
      RXHEADER(5 downto 0) => rxheader_out(5 downto 0),
      RXHEADERVALID(1 downto 0) => rxheadervalid_out(1 downto 0),
      RXLATCLK => '0',
      RXLFPSTRESETDET => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_35\,
      RXLFPSU2LPEXITDET => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_36\,
      RXLFPSU3WAKEDET => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_37\,
      RXLPMEN => rxlpmen_in(0),
      RXLPMGCHOLD => '0',
      RXLPMGCOVRDEN => '0',
      RXLPMHFHOLD => '0',
      RXLPMHFOVRDEN => '0',
      RXLPMLFHOLD => '0',
      RXLPMLFKLOVRDEN => '0',
      RXLPMOSHOLD => '0',
      RXLPMOSOVRDEN => '0',
      RXMCOMMAALIGNEN => '0',
      RXMONITOROUT(7) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_364\,
      RXMONITOROUT(6) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_365\,
      RXMONITOROUT(5) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_366\,
      RXMONITOROUT(4) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_367\,
      RXMONITOROUT(3) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_368\,
      RXMONITOROUT(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_369\,
      RXMONITOROUT(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_370\,
      RXMONITOROUT(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_371\,
      RXMONITORSEL(1 downto 0) => B"00",
      RXOOBRESET => '0',
      RXOSCALRESET => '0',
      RXOSHOLD => '0',
      RXOSINTDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_38\,
      RXOSINTSTARTED => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_39\,
      RXOSINTSTROBEDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_40\,
      RXOSINTSTROBESTARTED => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_41\,
      RXOSOVRDEN => '0',
      RXOUTCLK => \^gtwiz_userclk_rx_srcclk_out\(0),
      RXOUTCLKFABRIC => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_43\,
      RXOUTCLKPCS => rxoutclkpcs_out(0),
      RXOUTCLKSEL(2 downto 0) => B"010",
      RXPCOMMAALIGNEN => '0',
      RXPCSRESET => rxpcsreset_in(0),
      RXPD(1 downto 0) => RXPD(1 downto 0),
      RXPHALIGN => '0',
      RXPHALIGNDONE => \^rxphaligndone_out\(0),
      RXPHALIGNEN => '0',
      RXPHALIGNERR => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_46\,
      RXPHDLYPD => '0',
      RXPHDLYRESET => '0',
      RXPHOVRDEN => '0',
      RXPLLCLKSEL(1 downto 0) => rxpllclksel_in(1 downto 0),
      RXPMARESET => \gen_gtwizard_gthe4.rxpmareset_ch_int\,
      RXPMARESETDONE => rxpmaresetdone_out(0),
      RXPOLARITY => rxpolarity_in(0),
      RXPRBSCNTRESET => '0',
      RXPRBSERR => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_48\,
      RXPRBSLOCKED => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_49\,
      RXPRBSSEL(3 downto 0) => B"0000",
      RXPRGDIVRESETDONE => rxprgdivresetdone_out(0),
      RXPROGDIVRESET => rxprogdivreset_in(0),
      RXQPIEN => '0',
      RXQPISENN => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_51\,
      RXQPISENP => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_52\,
      RXRATE(2 downto 1) => B"00",
      RXRATE(0) => RXRATE(0),
      RXRATEDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_53\,
      RXRATEMODE => RXRATE(0),
      RXRECCLKOUT => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_54\,
      RXRESETDONE => rxresetdone_out(0),
      RXSLIDE => '0',
      RXSLIDERDY => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_56\,
      RXSLIPDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_57\,
      RXSLIPOUTCLK => '0',
      RXSLIPOUTCLKRDY => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_58\,
      RXSLIPPMA => '0',
      RXSLIPPMARDY => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_59\,
      RXSTARTOFSEQ(1 downto 0) => rxstartofseq_out(1 downto 0),
      RXSTATUS(2) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_326\,
      RXSTATUS(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_327\,
      RXSTATUS(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_328\,
      RXSYNCALLIN => \^rxphaligndone_out\(0),
      RXSYNCDONE => rxsyncdone_out(0),
      RXSYNCIN => '0',
      RXSYNCMODE => '1',
      RXSYNCOUT => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_61\,
      RXSYSCLKSEL(1 downto 0) => rxsysclksel_in(1 downto 0),
      RXTERMINATION => '0',
      RXUSERRDY => rxuserrdy_in(0),
      RXUSRCLK => gtwiz_userclk_rx_usrclk_out(0),
      RXUSRCLK2 => gtwiz_userclk_rx_usrclk2_out(0),
      RXVALID => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_62\,
      SIGVALIDCLK => '0',
      TSTIN(19 downto 0) => B"00000000000000000000",
      TX8B10BBYPASS(7 downto 0) => B"00000000",
      TX8B10BEN => '0',
      TXBUFSTATUS(1) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_315\,
      TXBUFSTATUS(0) => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_316\,
      TXCOMFINISH => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_63\,
      TXCOMINIT => '0',
      TXCOMSAS => '0',
      TXCOMWAKE => '0',
      TXCTRL0(15 downto 0) => B"0000000000000000",
      TXCTRL1(15 downto 0) => B"0000000000000000",
      TXCTRL2(7 downto 0) => B"00000000",
      TXDATA(127 downto 64) => B"0000000000000000000000000000000000000000000000000000000000000000",
      TXDATA(63 downto 0) => gtwiz_userdata_tx_in(63 downto 0),
      TXDATAEXTENDRSVD(7 downto 0) => B"00000000",
      TXDCCDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_64\,
      TXDCCFORCESTART => '0',
      TXDCCRESET => '0',
      TXDEEMPH(1 downto 0) => B"00",
      TXDETECTRX => '0',
      TXDIFFCTRL(4 downto 0) => txdiffctrl_in(4 downto 0),
      TXDLYBYPASS => '0',
      TXDLYEN => '0',
      TXDLYHOLD => '0',
      TXDLYOVRDEN => '0',
      TXDLYSRESET => \gen_gtwizard_gthe4.txdlysreset_int\,
      TXDLYSRESETDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_65\,
      TXDLYUPDOWN => '0',
      TXELECIDLE => txelecidle_in(0),
      TXHEADER(5 downto 0) => txheader_in(5 downto 0),
      TXINHIBIT => txinhibit_in(0),
      TXLATCLK => '0',
      TXLFPSTRESET => '0',
      TXLFPSU2LPEXIT => '0',
      TXLFPSU3WAKE => '0',
      TXMAINCURSOR(6 downto 0) => txmaincursor_in(6 downto 0),
      TXMARGIN(2 downto 0) => B"000",
      TXMUXDCDEXHOLD => '0',
      TXMUXDCDORWREN => '0',
      TXONESZEROS => '0',
      TXOUTCLK => \^gtwiz_userclk_tx_srcclk_out\(0),
      TXOUTCLKFABRIC => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_67\,
      TXOUTCLKPCS => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_68\,
      TXOUTCLKSEL(2 downto 0) => B"101",
      TXPCSRESET => txpcsreset_in(0),
      TXPD(1 downto 0) => txpd_in(1 downto 0),
      TXPDELECIDLEMODE => txpdelecidlemode_in(0),
      TXPHALIGN => '0',
      TXPHALIGNDONE => \^txphaligndone_out\(0),
      TXPHALIGNEN => '0',
      TXPHDLYPD => '0',
      TXPHDLYRESET => '0',
      TXPHDLYTSTCLK => '0',
      TXPHINIT => '0',
      TXPHINITDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_70\,
      TXPHOVRDEN => '0',
      TXPIPPMEN => '0',
      TXPIPPMOVRDEN => '0',
      TXPIPPMPD => '1',
      TXPIPPMSEL => '0',
      TXPIPPMSTEPSIZE(4 downto 0) => B"00000",
      TXPISOPD => '0',
      TXPLLCLKSEL(1 downto 0) => txpllclksel_in(1 downto 0),
      TXPMARESET => txpmareset_in(0),
      TXPMARESETDONE => txpmaresetdone_out(0),
      TXPOLARITY => txpolarity_in(0),
      TXPOSTCURSOR(4 downto 0) => txpostcursor_in(4 downto 0),
      TXPRBSFORCEERR => '0',
      TXPRBSSEL(3 downto 0) => B"0000",
      TXPRECURSOR(4 downto 0) => txprecursor_in(4 downto 0),
      TXPRGDIVRESETDONE => txprgdivresetdone_out(0),
      TXPROGDIVRESET => txprogdivreset_in(0),
      TXQPIBIASEN => '0',
      TXQPISENN => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_73\,
      TXQPISENP => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_74\,
      TXQPIWEAKPUP => '0',
      TXRATE(2 downto 0) => B"000",
      TXRATEDONE => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_75\,
      TXRATEMODE => '0',
      TXRESETDONE => txresetdone_out(0),
      TXSEQUENCE(6 downto 0) => txsequence_in(6 downto 0),
      TXSWING => '0',
      TXSYNCALLIN => \^txphaligndone_out\(0),
      TXSYNCDONE => txsyncdone_out(0),
      TXSYNCIN => '0',
      TXSYNCMODE => '1',
      TXSYNCOUT => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_n_78\,
      TXSYSCLKSEL(1 downto 0) => txsysclksel_in(1 downto 0),
      TXUSERRDY => txuserrdy_in(0),
      TXUSRCLK => gtwiz_userclk_tx_usrclk_out(0),
      TXUSRCLK2 => gtwiz_userclk_tx_usrclk2_out(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_common is
  port (
    drprdy_common_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0lock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1lock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    drpdo_common_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drpclk_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpen_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk00_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk01_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0pd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1pd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpaddr_common_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drpdi_common_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    pcierateqpll0_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    pcierateqpll1_in : in STD_LOGIC_VECTOR ( 2 downto 0 )
  );
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_common;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_common is
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_1\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_10\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_100\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_101\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_102\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_103\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_104\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_105\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_106\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_107\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_108\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_109\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_11\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_110\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_111\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_112\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_113\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_12\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_13\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_14\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_15\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_16\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_17\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_18\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_19\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_20\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_21\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_22\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_23\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_24\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_25\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_26\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_27\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_28\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_29\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_30\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_31\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_32\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_33\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_34\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_35\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_36\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_37\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_38\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_39\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_40\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_41\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_42\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_43\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_5\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_6\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_60\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_61\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_62\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_63\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_64\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_65\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_66\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_67\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_68\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_69\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_70\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_71\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_72\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_73\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_74\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_75\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_76\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_77\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_78\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_79\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_80\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_81\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_82\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_83\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_84\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_85\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_86\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_87\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_88\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_89\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_90\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_91\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_92\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_93\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_94\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_95\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_96\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_97\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_98\ : STD_LOGIC;
  signal \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_99\ : STD_LOGIC;
  attribute BOX_TYPE : string;
  attribute BOX_TYPE of \gthe4_common_gen.GTHE4_COMMON_PRIM_INST\ : label is "PRIMITIVE";
begin
\gthe4_common_gen.GTHE4_COMMON_PRIM_INST\: unisim.vcomponents.GTHE4_COMMON
    generic map(
      AEN_QPLL0_FBDIV => '1',
      AEN_QPLL1_FBDIV => '1',
      AEN_SDM0TOGGLE => '0',
      AEN_SDM1TOGGLE => '0',
      A_SDM0TOGGLE => '0',
      A_SDM1DATA_HIGH => B"000000000",
      A_SDM1DATA_LOW => B"0000000000000000",
      A_SDM1TOGGLE => '0',
      BIAS_CFG0 => X"0000",
      BIAS_CFG1 => X"0000",
      BIAS_CFG2 => X"0124",
      BIAS_CFG3 => X"0041",
      BIAS_CFG4 => X"0010",
      BIAS_CFG_RSVD => X"0000",
      COMMON_CFG0 => X"0000",
      COMMON_CFG1 => X"0000",
      POR_CFG => X"0000",
      PPF0_CFG => X"0600",
      PPF1_CFG => X"0600",
      QPLL0CLKOUT_RATE => "HALF",
      QPLL0_CFG0 => X"331C",
      QPLL0_CFG1 => X"D038",
      QPLL0_CFG1_G3 => X"D038",
      QPLL0_CFG2 => X"0FC0",
      QPLL0_CFG2_G3 => X"0FC0",
      QPLL0_CFG3 => X"0120",
      QPLL0_CFG4 => X"0003",
      QPLL0_CP => B"0011111111",
      QPLL0_CP_G3 => B"0000001111",
      QPLL0_FBDIV => 66,
      QPLL0_FBDIV_G3 => 160,
      QPLL0_INIT_CFG0 => X"02B2",
      QPLL0_INIT_CFG1 => X"00",
      QPLL0_LOCK_CFG => X"25E8",
      QPLL0_LOCK_CFG_G3 => X"25E8",
      QPLL0_LPF => B"1000111111",
      QPLL0_LPF_G3 => B"0111010101",
      QPLL0_PCI_EN => '0',
      QPLL0_RATE_SW_USE_DRP => '1',
      QPLL0_REFCLK_DIV => 1,
      QPLL0_SDM_CFG0 => X"0080",
      QPLL0_SDM_CFG1 => X"0000",
      QPLL0_SDM_CFG2 => X"0000",
      QPLL1CLKOUT_RATE => "HALF",
      QPLL1_CFG0 => X"331C",
      QPLL1_CFG1 => X"D038",
      QPLL1_CFG1_G3 => X"D038",
      QPLL1_CFG2 => X"0FC3",
      QPLL1_CFG2_G3 => X"0FC3",
      QPLL1_CFG3 => X"0120",
      QPLL1_CFG4 => X"0003",
      QPLL1_CP => B"0011111111",
      QPLL1_CP_G3 => B"0001111111",
      QPLL1_FBDIV => 66,
      QPLL1_FBDIV_G3 => 80,
      QPLL1_INIT_CFG0 => X"02B2",
      QPLL1_INIT_CFG1 => X"00",
      QPLL1_LOCK_CFG => X"25E8",
      QPLL1_LOCK_CFG_G3 => X"25E8",
      QPLL1_LPF => B"1000011111",
      QPLL1_LPF_G3 => B"0111010100",
      QPLL1_PCI_EN => '0',
      QPLL1_RATE_SW_USE_DRP => '1',
      QPLL1_REFCLK_DIV => 1,
      QPLL1_SDM_CFG0 => X"0080",
      QPLL1_SDM_CFG1 => X"0000",
      QPLL1_SDM_CFG2 => X"0000",
      RSVD_ATTR0 => X"0000",
      RSVD_ATTR1 => X"0000",
      RSVD_ATTR2 => X"0000",
      RSVD_ATTR3 => X"0000",
      RXRECCLKOUT0_SEL => B"00",
      RXRECCLKOUT1_SEL => B"00",
      SARC_ENB => '0',
      SARC_SEL => '0',
      SDM0INITSEED0_0 => B"0000000100010001",
      SDM0INITSEED0_1 => B"000010001",
      SDM1INITSEED0_0 => B"0000000100010001",
      SDM1INITSEED0_1 => B"000010001",
      SIM_DEVICE => "ULTRASCALE_PLUS",
      SIM_MODE => "FAST",
      SIM_RESET_SPEEDUP => "TRUE"
    )
        port map (
      BGBYPASSB => '1',
      BGMONITORENB => '1',
      BGPDB => '1',
      BGRCALOVRD(4 downto 0) => B"11111",
      BGRCALOVRDENB => '1',
      DRPADDR(15 downto 0) => drpaddr_common_in(15 downto 0),
      DRPCLK => drpclk_common_in(0),
      DRPDI(15 downto 0) => drpdi_common_in(15 downto 0),
      DRPDO(15 downto 0) => drpdo_common_out(15 downto 0),
      DRPEN => drpen_common_in(0),
      DRPRDY => drprdy_common_out(0),
      DRPWE => drpwe_common_in(0),
      GTGREFCLK0 => '0',
      GTGREFCLK1 => '0',
      GTNORTHREFCLK00 => '0',
      GTNORTHREFCLK01 => '0',
      GTNORTHREFCLK10 => '0',
      GTNORTHREFCLK11 => '0',
      GTREFCLK00 => gtrefclk00_in(0),
      GTREFCLK01 => gtrefclk01_in(0),
      GTREFCLK10 => '0',
      GTREFCLK11 => '0',
      GTSOUTHREFCLK00 => '0',
      GTSOUTHREFCLK01 => '0',
      GTSOUTHREFCLK10 => '0',
      GTSOUTHREFCLK11 => '0',
      PCIERATEQPLL0(2 downto 0) => pcierateqpll0_in(2 downto 0),
      PCIERATEQPLL1(2 downto 0) => pcierateqpll1_in(2 downto 0),
      PMARSVD0(7 downto 0) => B"00000000",
      PMARSVD1(7 downto 0) => B"00000000",
      PMARSVDOUT0(7) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_72\,
      PMARSVDOUT0(6) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_73\,
      PMARSVDOUT0(5) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_74\,
      PMARSVDOUT0(4) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_75\,
      PMARSVDOUT0(3) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_76\,
      PMARSVDOUT0(2) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_77\,
      PMARSVDOUT0(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_78\,
      PMARSVDOUT0(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_79\,
      PMARSVDOUT1(7) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_80\,
      PMARSVDOUT1(6) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_81\,
      PMARSVDOUT1(5) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_82\,
      PMARSVDOUT1(4) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_83\,
      PMARSVDOUT1(3) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_84\,
      PMARSVDOUT1(2) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_85\,
      PMARSVDOUT1(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_86\,
      PMARSVDOUT1(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_87\,
      QPLL0CLKRSVD0 => '0',
      QPLL0CLKRSVD1 => '0',
      QPLL0FBCLKLOST => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_1\,
      QPLL0FBDIV(7 downto 0) => B"00000000",
      QPLL0LOCK => qpll0lock_out(0),
      QPLL0LOCKDETCLK => '0',
      QPLL0LOCKEN => '1',
      QPLL0OUTCLK => qpll0outclk_out(0),
      QPLL0OUTREFCLK => qpll0outrefclk_out(0),
      QPLL0PD => qpll0pd_in(0),
      QPLL0REFCLKLOST => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_5\,
      QPLL0REFCLKSEL(2 downto 0) => B"001",
      QPLL0RESET => qpll0reset_in(0),
      QPLL1CLKRSVD0 => '0',
      QPLL1CLKRSVD1 => '0',
      QPLL1FBCLKLOST => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_6\,
      QPLL1FBDIV(7 downto 0) => B"00000000",
      QPLL1LOCK => qpll1lock_out(0),
      QPLL1LOCKDETCLK => '0',
      QPLL1LOCKEN => '1',
      QPLL1OUTCLK => qpll1outclk_out(0),
      QPLL1OUTREFCLK => qpll1outrefclk_out(0),
      QPLL1PD => qpll1pd_in(0),
      QPLL1REFCLKLOST => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_10\,
      QPLL1REFCLKSEL(2 downto 0) => B"001",
      QPLL1RESET => qpll1reset_in(0),
      QPLLDMONITOR0(7) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_88\,
      QPLLDMONITOR0(6) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_89\,
      QPLLDMONITOR0(5) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_90\,
      QPLLDMONITOR0(4) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_91\,
      QPLLDMONITOR0(3) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_92\,
      QPLLDMONITOR0(2) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_93\,
      QPLLDMONITOR0(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_94\,
      QPLLDMONITOR0(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_95\,
      QPLLDMONITOR1(7) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_96\,
      QPLLDMONITOR1(6) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_97\,
      QPLLDMONITOR1(5) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_98\,
      QPLLDMONITOR1(4) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_99\,
      QPLLDMONITOR1(3) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_100\,
      QPLLDMONITOR1(2) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_101\,
      QPLLDMONITOR1(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_102\,
      QPLLDMONITOR1(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_103\,
      QPLLRSVD1(7 downto 0) => B"00000000",
      QPLLRSVD2(4 downto 0) => B"00000",
      QPLLRSVD3(4 downto 0) => B"00000",
      QPLLRSVD4(7 downto 0) => B"00000000",
      RCALENB => '1',
      REFCLKOUTMONITOR0 => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_11\,
      REFCLKOUTMONITOR1 => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_12\,
      RXRECCLK0SEL(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_60\,
      RXRECCLK0SEL(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_61\,
      RXRECCLK1SEL(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_62\,
      RXRECCLK1SEL(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_63\,
      SDM0DATA(24 downto 0) => B"0000000000000000000000000",
      SDM0FINALOUT(3) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_64\,
      SDM0FINALOUT(2) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_65\,
      SDM0FINALOUT(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_66\,
      SDM0FINALOUT(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_67\,
      SDM0RESET => '0',
      SDM0TESTDATA(14) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_14\,
      SDM0TESTDATA(13) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_15\,
      SDM0TESTDATA(12) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_16\,
      SDM0TESTDATA(11) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_17\,
      SDM0TESTDATA(10) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_18\,
      SDM0TESTDATA(9) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_19\,
      SDM0TESTDATA(8) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_20\,
      SDM0TESTDATA(7) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_21\,
      SDM0TESTDATA(6) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_22\,
      SDM0TESTDATA(5) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_23\,
      SDM0TESTDATA(4) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_24\,
      SDM0TESTDATA(3) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_25\,
      SDM0TESTDATA(2) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_26\,
      SDM0TESTDATA(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_27\,
      SDM0TESTDATA(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_28\,
      SDM0TOGGLE => '0',
      SDM0WIDTH(1 downto 0) => B"00",
      SDM1DATA(24 downto 0) => B"0000000000000000000000000",
      SDM1FINALOUT(3) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_68\,
      SDM1FINALOUT(2) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_69\,
      SDM1FINALOUT(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_70\,
      SDM1FINALOUT(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_71\,
      SDM1RESET => '0',
      SDM1TESTDATA(14) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_29\,
      SDM1TESTDATA(13) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_30\,
      SDM1TESTDATA(12) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_31\,
      SDM1TESTDATA(11) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_32\,
      SDM1TESTDATA(10) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_33\,
      SDM1TESTDATA(9) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_34\,
      SDM1TESTDATA(8) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_35\,
      SDM1TESTDATA(7) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_36\,
      SDM1TESTDATA(6) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_37\,
      SDM1TESTDATA(5) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_38\,
      SDM1TESTDATA(4) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_39\,
      SDM1TESTDATA(3) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_40\,
      SDM1TESTDATA(2) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_41\,
      SDM1TESTDATA(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_42\,
      SDM1TESTDATA(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_43\,
      SDM1TOGGLE => '0',
      SDM1WIDTH(1 downto 0) => B"00",
      TCONGPI(9 downto 0) => B"0000000000",
      TCONGPO(9) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_104\,
      TCONGPO(8) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_105\,
      TCONGPO(7) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_106\,
      TCONGPO(6) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_107\,
      TCONGPO(5) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_108\,
      TCONGPO(4) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_109\,
      TCONGPO(3) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_110\,
      TCONGPO(2) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_111\,
      TCONGPO(1) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_112\,
      TCONGPO(0) => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_113\,
      TCONPOWERUP => '0',
      TCONRESET(1 downto 0) => B"00",
      TCONRSVDIN1(1 downto 0) => B"00",
      TCONRSVDOUT0 => \gthe4_common_gen.GTHE4_COMMON_PRIM_INST_n_13\
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_delay_powergood is
  port (
    \out\ : out STD_LOGIC;
    RXPD : out STD_LOGIC_VECTOR ( 1 downto 0 );
    RXRATE : out STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.gtrxreset_ch_int\ : out STD_LOGIC;
    \gen_gtwizard_gthe4.rxpmareset_ch_int\ : out STD_LOGIC;
    rxoutclkpcs_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_powergood_delay.intclk_rrst_n_r_reg[4]_0\ : in STD_LOGIC;
    rxpd_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    gtrxreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.gtpowergood_int\ : in STD_LOGIC;
    rxpmareset_in : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_delay_powergood;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_delay_powergood is
  signal \gen_powergood_delay.int_pwr_on_fsm\ : STD_LOGIC;
  attribute RTL_KEEP : string;
  attribute RTL_KEEP of \gen_powergood_delay.int_pwr_on_fsm\ : signal is "true";
  attribute async_reg : string;
  attribute async_reg of \gen_powergood_delay.int_pwr_on_fsm\ : signal is "true";
  attribute shreg_extract : string;
  attribute shreg_extract of \gen_powergood_delay.int_pwr_on_fsm\ : signal is "no";
  signal \gen_powergood_delay.int_pwr_on_fsm_i_1_n_0\ : STD_LOGIC;
  signal \gen_powergood_delay.intclk_rrst_n_r\ : STD_LOGIC_VECTOR ( 4 downto 0 );
  attribute async_reg of \gen_powergood_delay.intclk_rrst_n_r\ : signal is "true";
  attribute shreg_extract of \gen_powergood_delay.intclk_rrst_n_r\ : signal is "no";
  signal \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\ : STD_LOGIC;
  signal \gen_powergood_delay.pwr_on_fsm\ : STD_LOGIC;
  attribute RTL_KEEP of \gen_powergood_delay.pwr_on_fsm\ : signal is "true";
  attribute async_reg of \gen_powergood_delay.pwr_on_fsm\ : signal is "true";
  attribute shreg_extract of \gen_powergood_delay.pwr_on_fsm\ : signal is "no";
  signal \gen_powergood_delay.wait_cnt\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  attribute async_reg of \gen_powergood_delay.wait_cnt\ : signal is "true";
  attribute shreg_extract of \gen_powergood_delay.wait_cnt\ : signal is "no";
  signal \gen_powergood_delay.wait_cnt[0]_i_1_n_0\ : STD_LOGIC;
  signal \gen_powergood_delay.wait_cnt[8]_i_1_n_0\ : STD_LOGIC;
  attribute ASYNC_REG_boolean : boolean;
  attribute ASYNC_REG_boolean of \gen_powergood_delay.int_pwr_on_fsm_reg\ : label is std.standard.true;
  attribute KEEP : string;
  attribute KEEP of \gen_powergood_delay.int_pwr_on_fsm_reg\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.int_pwr_on_fsm_reg\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.intclk_rrst_n_r_reg[0]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.intclk_rrst_n_r_reg[0]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.intclk_rrst_n_r_reg[0]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.intclk_rrst_n_r_reg[1]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.intclk_rrst_n_r_reg[1]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.intclk_rrst_n_r_reg[1]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.intclk_rrst_n_r_reg[2]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.intclk_rrst_n_r_reg[2]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.intclk_rrst_n_r_reg[2]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.intclk_rrst_n_r_reg[3]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.intclk_rrst_n_r_reg[3]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.intclk_rrst_n_r_reg[3]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.intclk_rrst_n_r_reg[4]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.intclk_rrst_n_r_reg[4]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.intclk_rrst_n_r_reg[4]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.pwr_on_fsm_reg\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.pwr_on_fsm_reg\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.pwr_on_fsm_reg\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.wait_cnt_reg[0]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.wait_cnt_reg[0]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.wait_cnt_reg[0]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.wait_cnt_reg[1]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.wait_cnt_reg[1]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.wait_cnt_reg[1]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.wait_cnt_reg[2]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.wait_cnt_reg[2]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.wait_cnt_reg[2]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.wait_cnt_reg[3]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.wait_cnt_reg[3]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.wait_cnt_reg[3]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.wait_cnt_reg[4]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.wait_cnt_reg[4]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.wait_cnt_reg[4]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.wait_cnt_reg[5]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.wait_cnt_reg[5]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.wait_cnt_reg[5]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.wait_cnt_reg[6]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.wait_cnt_reg[6]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.wait_cnt_reg[6]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.wait_cnt_reg[7]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.wait_cnt_reg[7]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.wait_cnt_reg[7]\ : label is "no";
  attribute ASYNC_REG_boolean of \gen_powergood_delay.wait_cnt_reg[8]\ : label is std.standard.true;
  attribute KEEP of \gen_powergood_delay.wait_cnt_reg[8]\ : label is "yes";
  attribute SHREG_EXTRACT of \gen_powergood_delay.wait_cnt_reg[8]\ : label is "no";
begin
  \out\ <= \gen_powergood_delay.pwr_on_fsm\;
\gen_powergood_delay.int_pwr_on_fsm_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => \gen_powergood_delay.int_pwr_on_fsm\,
      I1 => \gen_powergood_delay.wait_cnt\(7),
      O => \gen_powergood_delay.int_pwr_on_fsm_i_1_n_0\
    );
\gen_powergood_delay.int_pwr_on_fsm_reg\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => rxoutclkpcs_out(0),
      CE => '1',
      CLR => \gen_powergood_delay.intclk_rrst_n_r_reg[4]_0\,
      D => \gen_powergood_delay.int_pwr_on_fsm_i_1_n_0\,
      Q => \gen_powergood_delay.int_pwr_on_fsm\
    );
\gen_powergood_delay.intclk_rrst_n_r[4]_i_1\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \gen_powergood_delay.int_pwr_on_fsm\,
      O => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\
    );
\gen_powergood_delay.intclk_rrst_n_r_reg[0]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      CLR => \gen_powergood_delay.intclk_rrst_n_r_reg[4]_0\,
      D => '1',
      Q => \gen_powergood_delay.intclk_rrst_n_r\(0)
    );
\gen_powergood_delay.intclk_rrst_n_r_reg[1]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      CLR => \gen_powergood_delay.intclk_rrst_n_r_reg[4]_0\,
      D => \gen_powergood_delay.intclk_rrst_n_r\(0),
      Q => \gen_powergood_delay.intclk_rrst_n_r\(1)
    );
\gen_powergood_delay.intclk_rrst_n_r_reg[2]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      CLR => \gen_powergood_delay.intclk_rrst_n_r_reg[4]_0\,
      D => \gen_powergood_delay.intclk_rrst_n_r\(1),
      Q => \gen_powergood_delay.intclk_rrst_n_r\(2)
    );
\gen_powergood_delay.intclk_rrst_n_r_reg[3]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      CLR => \gen_powergood_delay.intclk_rrst_n_r_reg[4]_0\,
      D => \gen_powergood_delay.intclk_rrst_n_r\(2),
      Q => \gen_powergood_delay.intclk_rrst_n_r\(3)
    );
\gen_powergood_delay.intclk_rrst_n_r_reg[4]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      CLR => \gen_powergood_delay.intclk_rrst_n_r_reg[4]_0\,
      D => \gen_powergood_delay.intclk_rrst_n_r\(3),
      Q => \gen_powergood_delay.intclk_rrst_n_r\(4)
    );
\gen_powergood_delay.pwr_on_fsm_reg\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => rxoutclkpcs_out(0),
      CE => '1',
      D => \gen_powergood_delay.int_pwr_on_fsm\,
      Q => \gen_powergood_delay.pwr_on_fsm\,
      R => '0'
    );
\gen_powergood_delay.wait_cnt[0]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"7"
    )
        port map (
      I0 => \gen_powergood_delay.intclk_rrst_n_r\(4),
      I1 => \gen_powergood_delay.int_pwr_on_fsm\,
      O => \gen_powergood_delay.wait_cnt[0]_i_1_n_0\
    );
\gen_powergood_delay.wait_cnt[8]_i_1\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \gen_powergood_delay.intclk_rrst_n_r\(4),
      O => \gen_powergood_delay.wait_cnt[8]_i_1_n_0\
    );
\gen_powergood_delay.wait_cnt_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.wait_cnt[0]_i_1_n_0\,
      D => \gen_powergood_delay.intclk_rrst_n_r\(4),
      Q => \gen_powergood_delay.wait_cnt\(0),
      R => '0'
    );
\gen_powergood_delay.wait_cnt_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      D => \gen_powergood_delay.wait_cnt\(0),
      Q => \gen_powergood_delay.wait_cnt\(1),
      R => \gen_powergood_delay.wait_cnt[8]_i_1_n_0\
    );
\gen_powergood_delay.wait_cnt_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      D => \gen_powergood_delay.wait_cnt\(1),
      Q => \gen_powergood_delay.wait_cnt\(2),
      R => \gen_powergood_delay.wait_cnt[8]_i_1_n_0\
    );
\gen_powergood_delay.wait_cnt_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      D => \gen_powergood_delay.wait_cnt\(2),
      Q => \gen_powergood_delay.wait_cnt\(3),
      R => \gen_powergood_delay.wait_cnt[8]_i_1_n_0\
    );
\gen_powergood_delay.wait_cnt_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      D => \gen_powergood_delay.wait_cnt\(3),
      Q => \gen_powergood_delay.wait_cnt\(4),
      R => \gen_powergood_delay.wait_cnt[8]_i_1_n_0\
    );
\gen_powergood_delay.wait_cnt_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      D => \gen_powergood_delay.wait_cnt\(4),
      Q => \gen_powergood_delay.wait_cnt\(5),
      R => \gen_powergood_delay.wait_cnt[8]_i_1_n_0\
    );
\gen_powergood_delay.wait_cnt_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      D => \gen_powergood_delay.wait_cnt\(5),
      Q => \gen_powergood_delay.wait_cnt\(6),
      R => \gen_powergood_delay.wait_cnt[8]_i_1_n_0\
    );
\gen_powergood_delay.wait_cnt_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      D => \gen_powergood_delay.wait_cnt\(6),
      Q => \gen_powergood_delay.wait_cnt\(7),
      R => \gen_powergood_delay.wait_cnt[8]_i_1_n_0\
    );
\gen_powergood_delay.wait_cnt_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => rxoutclkpcs_out(0),
      CE => \gen_powergood_delay.intclk_rrst_n_r[4]_i_1_n_0\,
      D => \gen_powergood_delay.wait_cnt\(7),
      Q => \gen_powergood_delay.wait_cnt\(8),
      R => \gen_powergood_delay.wait_cnt[8]_i_1_n_0\
    );
\gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"8B"
    )
        port map (
      I0 => gtrxreset_in(0),
      I1 => \gen_powergood_delay.pwr_on_fsm\,
      I2 => \gen_gtwizard_gthe4.gtpowergood_int\,
      O => \gen_gtwizard_gthe4.gtrxreset_ch_int\
    );
\gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_i_2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => \gen_powergood_delay.pwr_on_fsm\,
      I1 => rxpmareset_in(0),
      O => \gen_gtwizard_gthe4.rxpmareset_ch_int\
    );
\gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_i_3\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \gen_powergood_delay.pwr_on_fsm\,
      O => RXRATE(0)
    );
\gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_i_4\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"B"
    )
        port map (
      I0 => rxpd_in(1),
      I1 => \gen_powergood_delay.pwr_on_fsm\,
      O => RXPD(1)
    );
\gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_i_5\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"B"
    )
        port map (
      I0 => rxpd_in(0),
      I1 => \gen_powergood_delay.pwr_on_fsm\,
      O => RXPD(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_userclk_rx is
  port (
    gtwiz_userclk_rx_usrclk2_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_active_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_srcclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    lopt : out STD_LOGIC;
    lopt_1 : in STD_LOGIC;
    lopt_2 : in STD_LOGIC
  );
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_userclk_rx;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_userclk_rx is
  signal \<const1>\ : STD_LOGIC;
  signal \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_meta\ : STD_LOGIC;
  attribute async_reg : string;
  attribute async_reg of \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_meta\ : signal is "true";
  signal \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_sync\ : STD_LOGIC;
  attribute async_reg of \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_sync\ : signal is "true";
  signal \^gtwiz_userclk_rx_usrclk2_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^lopt\ : STD_LOGIC;
  signal \^lopt_1\ : STD_LOGIC;
  attribute BOX_TYPE : string;
  attribute BOX_TYPE of \gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst\ : label is "PRIMITIVE";
  attribute OPT_MODIFIED : string;
  attribute OPT_MODIFIED of \gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst\ : label is "MLO";
  attribute BOX_TYPE of \gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst\ : label is "PRIMITIVE";
  attribute OPT_MODIFIED of \gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst\ : label is "MLO";
  attribute ASYNC_REG_boolean : boolean;
  attribute ASYNC_REG_boolean of \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_meta_reg\ : label is std.standard.true;
  attribute KEEP : string;
  attribute KEEP of \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_meta_reg\ : label is "yes";
  attribute ASYNC_REG_boolean of \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_sync_reg\ : label is std.standard.true;
  attribute KEEP of \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_sync_reg\ : label is "yes";
begin
  \^lopt\ <= lopt_1;
  \^lopt_1\ <= lopt_2;
  gtwiz_userclk_rx_active_out(0) <= \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_sync\;
  gtwiz_userclk_rx_usrclk2_out(0) <= \^gtwiz_userclk_rx_usrclk2_out\(0);
  lopt <= \<const1>\;
VCC: unisim.vcomponents.VCC
     port map (
      P => \<const1>\
    );
\gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst\: unisim.vcomponents.BUFG_GT
    generic map(
      SIM_DEVICE => "ULTRASCALE",
      STARTUP_SYNC => "FALSE"
    )
        port map (
      CE => \^lopt\,
      CEMASK => '0',
      CLR => \^lopt_1\,
      CLRMASK => '0',
      DIV(2 downto 0) => B"001",
      I => gtwiz_userclk_rx_srcclk_out(0),
      O => \^gtwiz_userclk_rx_usrclk2_out\(0)
    );
\gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst\: unisim.vcomponents.BUFG_GT
    generic map(
      SIM_DEVICE => "ULTRASCALE",
      STARTUP_SYNC => "FALSE"
    )
        port map (
      CE => \^lopt\,
      CEMASK => '0',
      CLR => \^lopt_1\,
      CLRMASK => '0',
      DIV(2 downto 0) => B"000",
      I => gtwiz_userclk_rx_srcclk_out(0),
      O => gtwiz_userclk_rx_usrclk_out(0)
    );
\gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_meta_reg\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => \^gtwiz_userclk_rx_usrclk2_out\(0),
      CE => '1',
      CLR => gtwiz_userclk_rx_reset_in(0),
      D => '1',
      Q => \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_meta\
    );
\gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_sync_reg\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => \^gtwiz_userclk_rx_usrclk2_out\(0),
      CE => '1',
      CLR => gtwiz_userclk_rx_reset_in(0),
      D => \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_meta\,
      Q => \gen_gtwiz_userclk_rx_main.gtwiz_userclk_rx_active_sync\
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_userclk_tx is
  port (
    gtwiz_userclk_tx_usrclk2_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_active_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_srcclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    lopt : out STD_LOGIC;
    lopt_1 : in STD_LOGIC;
    lopt_2 : in STD_LOGIC
  );
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_userclk_tx;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_userclk_tx is
  signal \<const1>\ : STD_LOGIC;
  signal \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_meta\ : STD_LOGIC;
  attribute async_reg : string;
  attribute async_reg of \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_meta\ : signal is "true";
  signal \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_sync\ : STD_LOGIC;
  attribute async_reg of \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_sync\ : signal is "true";
  signal \^gtwiz_userclk_tx_usrclk2_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^lopt\ : STD_LOGIC;
  signal \^lopt_1\ : STD_LOGIC;
  attribute BOX_TYPE : string;
  attribute BOX_TYPE of \gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst\ : label is "PRIMITIVE";
  attribute OPT_MODIFIED : string;
  attribute OPT_MODIFIED of \gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst\ : label is "MLO";
  attribute BOX_TYPE of \gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst\ : label is "PRIMITIVE";
  attribute OPT_MODIFIED of \gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst\ : label is "MLO";
  attribute ASYNC_REG_boolean : boolean;
  attribute ASYNC_REG_boolean of \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_meta_reg\ : label is std.standard.true;
  attribute KEEP : string;
  attribute KEEP of \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_meta_reg\ : label is "yes";
  attribute ASYNC_REG_boolean of \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_sync_reg\ : label is std.standard.true;
  attribute KEEP of \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_sync_reg\ : label is "yes";
begin
  \^lopt\ <= lopt_1;
  \^lopt_1\ <= lopt_2;
  gtwiz_userclk_tx_active_out(0) <= \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_sync\;
  gtwiz_userclk_tx_usrclk2_out(0) <= \^gtwiz_userclk_tx_usrclk2_out\(0);
  lopt <= \<const1>\;
VCC: unisim.vcomponents.VCC
     port map (
      P => \<const1>\
    );
\gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst\: unisim.vcomponents.BUFG_GT
    generic map(
      SIM_DEVICE => "ULTRASCALE",
      STARTUP_SYNC => "FALSE"
    )
        port map (
      CE => \^lopt\,
      CEMASK => '0',
      CLR => \^lopt_1\,
      CLRMASK => '0',
      DIV(2 downto 0) => B"001",
      I => gtwiz_userclk_tx_srcclk_out(0),
      O => \^gtwiz_userclk_tx_usrclk2_out\(0)
    );
\gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst\: unisim.vcomponents.BUFG_GT
    generic map(
      SIM_DEVICE => "ULTRASCALE",
      STARTUP_SYNC => "FALSE"
    )
        port map (
      CE => \^lopt\,
      CEMASK => '0',
      CLR => \^lopt_1\,
      CLRMASK => '0',
      DIV(2 downto 0) => B"000",
      I => gtwiz_userclk_tx_srcclk_out(0),
      O => gtwiz_userclk_tx_usrclk_out(0)
    );
\gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_meta_reg\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => \^gtwiz_userclk_tx_usrclk2_out\(0),
      CE => '1',
      CLR => gtwiz_userclk_tx_reset_in(0),
      D => '1',
      Q => \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_meta\
    );
\gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_sync_reg\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => \^gtwiz_userclk_tx_usrclk2_out\(0),
      CE => '1',
      CLR => gtwiz_userclk_tx_reset_in(0),
      D => \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_meta\,
      Q => \gen_gtwiz_userclk_tx_main.gtwiz_userclk_tx_active_sync\
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_reset_inv_synchronizer is
  port (
    \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\ : out STD_LOGIC;
    \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[1]\ : out STD_LOGIC;
    E : out STD_LOGIC_VECTOR ( 0 to 0 );
    \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[0]\ : out STD_LOGIC;
    gtwiz_userclk_tx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    Q : in STD_LOGIC_VECTOR ( 1 downto 0 );
    \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_reg\ : in STD_LOGIC;
    gtwiz_buffbypass_tx_start_user_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.txdlysreset_int\ : in STD_LOGIC;
    \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\ : in STD_LOGIC;
    \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\ : in STD_LOGIC
  );
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_reset_inv_synchronizer;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_reset_inv_synchronizer is
  signal \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_start_int__1\ : STD_LOGIC;
  signal rst_in_meta : STD_LOGIC;
  attribute async_reg : string;
  attribute async_reg of rst_in_meta : signal is "true";
  signal rst_in_meta_i_1_n_0 : STD_LOGIC;
  signal rst_in_sync1 : STD_LOGIC;
  attribute async_reg of rst_in_sync1 : signal is "true";
  signal rst_in_sync2 : STD_LOGIC;
  attribute async_reg of rst_in_sync2 : signal is "true";
  signal rst_in_sync3 : STD_LOGIC;
  attribute async_reg of rst_in_sync3 : signal is "true";
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx[1]_i_3\ : label is "soft_lutpair3";
  attribute SOFT_HLUTNM of \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_done_out_i_1\ : label is "soft_lutpair3";
  attribute ASYNC_REG_boolean : boolean;
  attribute ASYNC_REG_boolean of rst_in_meta_reg : label is std.standard.true;
  attribute KEEP : string;
  attribute KEEP of rst_in_meta_reg : label is "yes";
  attribute ASYNC_REG_boolean of rst_in_sync1_reg : label is std.standard.true;
  attribute KEEP of rst_in_sync1_reg : label is "yes";
  attribute ASYNC_REG_boolean of rst_in_sync2_reg : label is std.standard.true;
  attribute KEEP of rst_in_sync2_reg : label is "yes";
  attribute ASYNC_REG_boolean of rst_in_sync3_reg : label is std.standard.true;
  attribute KEEP of rst_in_sync3_reg : label is "yes";
begin
  \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\ <= \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\;
\FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx[1]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AEFEAEAE"
    )
        port map (
      I0 => Q(0),
      I1 => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_start_int__1\,
      I2 => Q(1),
      I3 => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\,
      I4 => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\,
      O => E(0)
    );
\FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx[1]_i_3\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"F4"
    )
        port map (
      I0 => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_reg\,
      I1 => \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\,
      I2 => gtwiz_buffbypass_tx_start_user_in(0),
      O => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_start_int__1\
    );
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_done_out_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAA4454"
    )
        port map (
      I0 => Q(0),
      I1 => gtwiz_buffbypass_tx_start_user_in(0),
      I2 => \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\,
      I3 => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_reg\,
      I4 => Q(1),
      O => \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[0]\
    );
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.txdlysreset_out[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAFFFF00005510"
    )
        port map (
      I0 => Q(1),
      I1 => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_reg\,
      I2 => \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\,
      I3 => gtwiz_buffbypass_tx_start_user_in(0),
      I4 => Q(0),
      I5 => \gen_gtwizard_gthe4.txdlysreset_int\,
      O => \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[1]\
    );
rst_in_meta_i_1: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => gtwiz_reset_tx_done_in(0),
      O => rst_in_meta_i_1_n_0
    );
rst_in_meta_reg: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      CLR => rst_in_meta_i_1_n_0,
      D => '1',
      Q => rst_in_meta
    );
rst_in_out_reg: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      CLR => rst_in_meta_i_1_n_0,
      D => rst_in_sync3,
      Q => \^gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\
    );
rst_in_sync1_reg: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      CLR => rst_in_meta_i_1_n_0,
      D => rst_in_meta,
      Q => rst_in_sync1
    );
rst_in_sync2_reg: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      CLR => rst_in_meta_i_1_n_0,
      D => rst_in_sync1,
      Q => rst_in_sync2
    );
rst_in_sync3_reg: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      CLR => rst_in_meta_i_1_n_0,
      D => rst_in_sync2,
      Q => rst_in_sync3
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_reset_inv_synchronizer_3 is
  port (
    \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\ : out STD_LOGIC;
    \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[1]\ : out STD_LOGIC;
    E : out STD_LOGIC_VECTOR ( 0 to 0 );
    \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[0]\ : out STD_LOGIC;
    gtwiz_userclk_rx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    Q : in STD_LOGIC_VECTOR ( 1 downto 0 );
    \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_reg\ : in STD_LOGIC;
    gtwiz_buffbypass_rx_start_user_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.rxdlysreset_int\ : in STD_LOGIC;
    \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\ : in STD_LOGIC;
    \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\ : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_reset_inv_synchronizer_3 : entity is "gtwizard_ultrascale_v1_7_17_reset_inv_synchronizer";
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_reset_inv_synchronizer_3;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_reset_inv_synchronizer_3 is
  signal \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_start_int__1\ : STD_LOGIC;
  signal rst_in_meta : STD_LOGIC;
  attribute async_reg : string;
  attribute async_reg of rst_in_meta : signal is "true";
  signal \rst_in_meta_i_1__0_n_0\ : STD_LOGIC;
  signal rst_in_sync1 : STD_LOGIC;
  attribute async_reg of rst_in_sync1 : signal is "true";
  signal rst_in_sync2 : STD_LOGIC;
  attribute async_reg of rst_in_sync2 : signal is "true";
  signal rst_in_sync3 : STD_LOGIC;
  attribute async_reg of rst_in_sync3 : signal is "true";
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx[1]_i_3\ : label is "soft_lutpair1";
  attribute SOFT_HLUTNM of \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_done_out_i_1\ : label is "soft_lutpair1";
  attribute ASYNC_REG_boolean : boolean;
  attribute ASYNC_REG_boolean of rst_in_meta_reg : label is std.standard.true;
  attribute KEEP : string;
  attribute KEEP of rst_in_meta_reg : label is "yes";
  attribute ASYNC_REG_boolean of rst_in_sync1_reg : label is std.standard.true;
  attribute KEEP of rst_in_sync1_reg : label is "yes";
  attribute ASYNC_REG_boolean of rst_in_sync2_reg : label is std.standard.true;
  attribute KEEP of rst_in_sync2_reg : label is "yes";
  attribute ASYNC_REG_boolean of rst_in_sync3_reg : label is std.standard.true;
  attribute KEEP of rst_in_sync3_reg : label is "yes";
begin
  \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\ <= \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\;
\FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx[1]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AEFEAEAE"
    )
        port map (
      I0 => Q(0),
      I1 => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_start_int__1\,
      I2 => Q(1),
      I3 => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\,
      I4 => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\,
      O => E(0)
    );
\FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx[1]_i_3\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"F4"
    )
        port map (
      I0 => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_reg\,
      I1 => \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\,
      I2 => gtwiz_buffbypass_rx_start_user_in(0),
      O => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_start_int__1\
    );
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_done_out_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAA4454"
    )
        port map (
      I0 => Q(0),
      I1 => gtwiz_buffbypass_rx_start_user_in(0),
      I2 => \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\,
      I3 => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_reg\,
      I4 => Q(1),
      O => \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[0]\
    );
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.rxdlysreset_out[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAFFFF00005510"
    )
        port map (
      I0 => Q(1),
      I1 => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_reg\,
      I2 => \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\,
      I3 => gtwiz_buffbypass_rx_start_user_in(0),
      I4 => Q(0),
      I5 => \gen_gtwizard_gthe4.rxdlysreset_int\,
      O => \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[1]\
    );
\rst_in_meta_i_1__0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => gtwiz_reset_rx_done_in(0),
      O => \rst_in_meta_i_1__0_n_0\
    );
rst_in_meta_reg: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      CLR => \rst_in_meta_i_1__0_n_0\,
      D => '1',
      Q => rst_in_meta
    );
rst_in_out_reg: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      CLR => \rst_in_meta_i_1__0_n_0\,
      D => rst_in_sync3,
      Q => \^gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\
    );
rst_in_sync1_reg: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      CLR => \rst_in_meta_i_1__0_n_0\,
      D => rst_in_meta,
      Q => rst_in_sync1
    );
rst_in_sync2_reg: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      CLR => \rst_in_meta_i_1__0_n_0\,
      D => rst_in_sync1,
      Q => rst_in_sync2
    );
rst_in_sync3_reg: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      CLR => \rst_in_meta_i_1__0_n_0\,
      D => rst_in_sync2,
      Q => rst_in_sync3
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_buffbypass_rx is
  port (
    gtwiz_buffbypass_rx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_error_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.rxdlysreset_int\ : out STD_LOGIC;
    rxsyncdone_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxphaligndone_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_start_user_in : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_buffbypass_rx;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_buffbypass_rx is
  signal \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg_n_0_[1]\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.bit_synchronizer_masterphaligndone_inst_n_0\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_reg\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_1\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_2\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_3\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx__0\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \^gen_gtwizard_gthe4.rxdlysreset_int\ : STD_LOGIC;
  attribute FSM_ENCODED_STATES : string;
  attribute FSM_ENCODED_STATES of \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[0]\ : label is "ST_BUFFBYPASS_RX_DEASSERT_RXDLYSRESET:01,ST_BUFFBYPASS_RX_WAIT_RXSYNCDONE:10,iSTATE:00,ST_BUFFBYPASS_RX_DONE:11";
  attribute FSM_ENCODED_STATES of \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[1]\ : label is "ST_BUFFBYPASS_RX_DEASSERT_RXDLYSRESET:01,ST_BUFFBYPASS_RX_WAIT_RXSYNCDONE:10,iSTATE:00,ST_BUFFBYPASS_RX_DONE:11";
begin
  \gen_gtwizard_gthe4.rxdlysreset_int\ <= \^gen_gtwizard_gthe4.rxdlysreset_int\;
\FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_2\,
      D => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx__0\(0),
      Q => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx\(0),
      R => gtwiz_buffbypass_rx_reset_in(0)
    );
\FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_2\,
      D => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx__0\(1),
      Q => \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg_n_0_[1]\,
      R => gtwiz_buffbypass_rx_reset_in(0)
    );
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.bit_synchronizer_masterphaligndone_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_1
     port map (
      \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[1]\ => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.bit_synchronizer_masterphaligndone_inst_n_0\,
      Q(0) => \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg_n_0_[1]\,
      gtwiz_userclk_rx_usrclk2_out(0) => gtwiz_userclk_rx_usrclk2_out(0),
      rxphaligndone_out(0) => rxphaligndone_out(0)
    );
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.bit_synchronizer_mastersyncdone_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_2
     port map (
      D(1 downto 0) => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx__0\(1 downto 0),
      Q(1) => \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg_n_0_[1]\,
      Q(0) => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx\(0),
      \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\ => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\,
      \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\ => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\,
      gtwiz_userclk_rx_usrclk2_out(0) => gtwiz_userclk_rx_usrclk2_out(0),
      rxsyncdone_out(0) => rxsyncdone_out(0)
    );
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_done_out_reg\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_3\,
      D => \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg_n_0_[1]\,
      Q => gtwiz_buffbypass_rx_done_out(0),
      R => gtwiz_buffbypass_rx_reset_in(0)
    );
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_error_out_reg\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_3\,
      D => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.bit_synchronizer_masterphaligndone_inst_n_0\,
      Q => gtwiz_buffbypass_rx_error_out(0),
      R => gtwiz_buffbypass_rx_reset_in(0)
    );
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg_reg\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\,
      Q => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\,
      R => '0'
    );
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_reg_reg\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\,
      Q => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_reg\,
      R => gtwiz_buffbypass_rx_reset_in(0)
    );
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_reset_inv_synchronizer_3
     port map (
      E(0) => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_2\,
      \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[0]\ => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_3\,
      \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg[1]\ => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_1\,
      Q(1) => \FSM_sequential_gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx_reg_n_0_[1]\,
      Q(0) => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.sm_buffbypass_rx\(0),
      \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\ => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_int\,
      \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\ => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_master_syncdone_sync_reg\,
      \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_reg\ => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_reg\,
      \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\ => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_resetdone_sync_int\,
      \gen_gtwizard_gthe4.rxdlysreset_int\ => \^gen_gtwizard_gthe4.rxdlysreset_int\,
      gtwiz_buffbypass_rx_start_user_in(0) => gtwiz_buffbypass_rx_start_user_in(0),
      gtwiz_reset_rx_done_in(0) => gtwiz_reset_rx_done_in(0),
      gtwiz_userclk_rx_usrclk2_out(0) => gtwiz_userclk_rx_usrclk2_out(0)
    );
\gen_gtwiz_buffbypass_rx_main.gen_auto_mode.rxdlysreset_out_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_rx_usrclk2_out(0),
      CE => '1',
      D => \gen_gtwiz_buffbypass_rx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_1\,
      Q => \^gen_gtwizard_gthe4.rxdlysreset_int\,
      R => gtwiz_buffbypass_rx_reset_in(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_buffbypass_tx is
  port (
    gtwiz_buffbypass_tx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_error_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.txdlysreset_int\ : out STD_LOGIC;
    txsyncdone_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    txphaligndone_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_start_user_in : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
end taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_buffbypass_tx;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_buffbypass_tx is
  signal \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg_n_0_[1]\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.bit_synchronizer_master_phaligndone_inst_n_0\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_reg\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_1\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_2\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_3\ : STD_LOGIC;
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx__0\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \^gen_gtwizard_gthe4.txdlysreset_int\ : STD_LOGIC;
  attribute FSM_ENCODED_STATES : string;
  attribute FSM_ENCODED_STATES of \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[0]\ : label is "ST_BUFFBYPASS_TX_DEASSERT_TXDLYSRESET:01,ST_BUFFBYPASS_TX_WAIT_TXSYNCDONE:10,iSTATE:00,ST_BUFFBYPASS_TX_DONE:11";
  attribute FSM_ENCODED_STATES of \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[1]\ : label is "ST_BUFFBYPASS_TX_DEASSERT_TXDLYSRESET:01,ST_BUFFBYPASS_TX_WAIT_TXSYNCDONE:10,iSTATE:00,ST_BUFFBYPASS_TX_DONE:11";
begin
  \gen_gtwizard_gthe4.txdlysreset_int\ <= \^gen_gtwizard_gthe4.txdlysreset_int\;
\FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_2\,
      D => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx__0\(0),
      Q => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx\(0),
      R => gtwiz_buffbypass_tx_reset_in(0)
    );
\FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_2\,
      D => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx__0\(1),
      Q => \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg_n_0_[1]\,
      R => gtwiz_buffbypass_tx_reset_in(0)
    );
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.bit_synchronizer_master_phaligndone_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer
     port map (
      \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[1]\ => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.bit_synchronizer_master_phaligndone_inst_n_0\,
      Q(0) => \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg_n_0_[1]\,
      gtwiz_userclk_tx_usrclk2_out(0) => gtwiz_userclk_tx_usrclk2_out(0),
      txphaligndone_out(0) => txphaligndone_out(0)
    );
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.bit_synchronizer_master_syncdone_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_bit_synchronizer_0
     port map (
      D(1 downto 0) => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx__0\(1 downto 0),
      Q(1) => \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg_n_0_[1]\,
      Q(0) => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx\(0),
      \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\ => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\,
      \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\ => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\,
      gtwiz_userclk_tx_usrclk2_out(0) => gtwiz_userclk_tx_usrclk2_out(0),
      txsyncdone_out(0) => txsyncdone_out(0)
    );
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_done_out_reg\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_3\,
      D => \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg_n_0_[1]\,
      Q => gtwiz_buffbypass_tx_done_out(0),
      R => gtwiz_buffbypass_tx_reset_in(0)
    );
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_error_out_reg\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_3\,
      D => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.bit_synchronizer_master_phaligndone_inst_n_0\,
      Q => gtwiz_buffbypass_tx_error_out(0),
      R => gtwiz_buffbypass_tx_reset_in(0)
    );
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg_reg\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\,
      Q => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\,
      R => '0'
    );
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_reg_reg\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\,
      Q => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_reg\,
      R => gtwiz_buffbypass_tx_reset_in(0)
    );
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_reset_inv_synchronizer
     port map (
      E(0) => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_2\,
      \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[0]\ => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_3\,
      \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg[1]\ => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_1\,
      Q(1) => \FSM_sequential_gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx_reg_n_0_[1]\,
      Q(0) => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.sm_buffbypass_tx\(0),
      \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\ => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_int\,
      \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\ => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_master_syncdone_sync_reg\,
      \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_reg\ => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_reg\,
      \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\ => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.gtwiz_buffbypass_tx_resetdone_sync_int\,
      \gen_gtwizard_gthe4.txdlysreset_int\ => \^gen_gtwizard_gthe4.txdlysreset_int\,
      gtwiz_buffbypass_tx_start_user_in(0) => gtwiz_buffbypass_tx_start_user_in(0),
      gtwiz_reset_tx_done_in(0) => gtwiz_reset_tx_done_in(0),
      gtwiz_userclk_tx_usrclk2_out(0) => gtwiz_userclk_tx_usrclk2_out(0)
    );
\gen_gtwiz_buffbypass_tx_main.gen_auto_mode.txdlysreset_out_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => gtwiz_userclk_tx_usrclk2_out(0),
      CE => '1',
      D => \gen_gtwiz_buffbypass_tx_main.gen_auto_mode.reset_synchronizer_resetdone_inst_n_1\,
      Q => \^gen_gtwizard_gthe4.txdlysreset_int\,
      R => gtwiz_buffbypass_tx_reset_in(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gthe4_channel_wrapper is
  port (
    drprdy_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxn_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxp_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.gtpowergood_int\ : out STD_LOGIC;
    rxcdrlock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_srcclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxoutclkpcs_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxphaligndone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxprgdivresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxsyncdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_srcclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txphaligndone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txprgdivresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txsyncdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_rx_out : out STD_LOGIC_VECTOR ( 63 downto 0 );
    drpdo_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    rxdatavalid_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxheadervalid_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxstartofseq_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxheader_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST\ : out STD_LOGIC;
    drpclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    eyescanreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxn_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxp_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.gtrxreset_ch_int\ : in STD_LOGIC;
    gttxreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outrefclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outrefclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfelpmreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.rxdlysreset_int\ : in STD_LOGIC;
    rxgearboxslip_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpcsreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.rxpmareset_ch_int\ : in STD_LOGIC;
    rxpolarity_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxprogdivreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    RXRATE : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxuserrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_gtwizard_gthe4.txdlysreset_int\ : in STD_LOGIC;
    txelecidle_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txinhibit_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpcsreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpdelecidlemode_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpmareset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpolarity_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txprogdivreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txuserrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk2_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_tx_in : in STD_LOGIC_VECTOR ( 63 downto 0 );
    drpdi_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    RXPD : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxpllclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxsysclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txpd_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txpllclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txsysclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txdiffctrl_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txpostcursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txprecursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txheader_in : in STD_LOGIC_VECTOR ( 5 downto 0 );
    txmaincursor_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    txsequence_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    drpaddr_in : in STD_LOGIC_VECTOR ( 9 downto 0 );
    lopt : in STD_LOGIC;
    lopt_1 : in STD_LOGIC;
    lopt_2 : out STD_LOGIC;
    lopt_3 : out STD_LOGIC;
    lopt_4 : in STD_LOGIC;
    lopt_5 : in STD_LOGIC;
    lopt_6 : out STD_LOGIC;
    lopt_7 : out STD_LOGIC
  );
end taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gthe4_channel_wrapper;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gthe4_channel_wrapper is
begin
channel_inst: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_channel
     port map (
      RXPD(1 downto 0) => RXPD(1 downto 0),
      RXRATE(0) => RXRATE(0),
      drpaddr_in(9 downto 0) => drpaddr_in(9 downto 0),
      drpclk_in(0) => drpclk_in(0),
      drpdi_in(15 downto 0) => drpdi_in(15 downto 0),
      drpdo_out(15 downto 0) => drpdo_out(15 downto 0),
      drpen_in(0) => drpen_in(0),
      drprdy_out(0) => drprdy_out(0),
      drpwe_in(0) => drpwe_in(0),
      eyescanreset_in(0) => eyescanreset_in(0),
      \gen_gtwizard_gthe4.gtpowergood_int\ => \gen_gtwizard_gthe4.gtpowergood_int\,
      \gen_gtwizard_gthe4.gtrxreset_ch_int\ => \gen_gtwizard_gthe4.gtrxreset_ch_int\,
      \gen_gtwizard_gthe4.rxdlysreset_int\ => \gen_gtwizard_gthe4.rxdlysreset_int\,
      \gen_gtwizard_gthe4.rxpmareset_ch_int\ => \gen_gtwizard_gthe4.rxpmareset_ch_int\,
      \gen_gtwizard_gthe4.txdlysreset_int\ => \gen_gtwizard_gthe4.txdlysreset_int\,
      \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST_0\ => \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST\,
      gthrxn_in(0) => gthrxn_in(0),
      gthrxp_in(0) => gthrxp_in(0),
      gthtxn_out(0) => gthtxn_out(0),
      gthtxp_out(0) => gthtxp_out(0),
      gttxreset_in(0) => gttxreset_in(0),
      gtwiz_userclk_rx_srcclk_out(0) => gtwiz_userclk_rx_srcclk_out(0),
      gtwiz_userclk_rx_usrclk2_out(0) => gtwiz_userclk_rx_usrclk2_out(0),
      gtwiz_userclk_rx_usrclk_out(0) => gtwiz_userclk_rx_usrclk_out(0),
      gtwiz_userclk_tx_srcclk_out(0) => gtwiz_userclk_tx_srcclk_out(0),
      gtwiz_userclk_tx_usrclk2_out(0) => gtwiz_userclk_tx_usrclk2_out(0),
      gtwiz_userclk_tx_usrclk_out(0) => gtwiz_userclk_tx_usrclk_out(0),
      gtwiz_userdata_rx_out(63 downto 0) => gtwiz_userdata_rx_out(63 downto 0),
      gtwiz_userdata_tx_in(63 downto 0) => gtwiz_userdata_tx_in(63 downto 0),
      lopt => lopt,
      lopt_1 => lopt_1,
      lopt_2 => lopt_2,
      lopt_3 => lopt_3,
      lopt_4 => lopt_4,
      lopt_5 => lopt_5,
      lopt_6 => lopt_6,
      lopt_7 => lopt_7,
      qpll0outclk_out(0) => qpll0outclk_out(0),
      qpll0outrefclk_out(0) => qpll0outrefclk_out(0),
      qpll1outclk_out(0) => qpll1outclk_out(0),
      qpll1outrefclk_out(0) => qpll1outrefclk_out(0),
      rxcdrhold_in(0) => rxcdrhold_in(0),
      rxcdrlock_out(0) => rxcdrlock_out(0),
      rxcdrovrden_in(0) => rxcdrovrden_in(0),
      rxdatavalid_out(1 downto 0) => rxdatavalid_out(1 downto 0),
      rxdfelpmreset_in(0) => rxdfelpmreset_in(0),
      rxgearboxslip_in(0) => rxgearboxslip_in(0),
      rxheader_out(5 downto 0) => rxheader_out(5 downto 0),
      rxheadervalid_out(1 downto 0) => rxheadervalid_out(1 downto 0),
      rxlpmen_in(0) => rxlpmen_in(0),
      rxoutclkpcs_out(0) => rxoutclkpcs_out(0),
      rxpcsreset_in(0) => rxpcsreset_in(0),
      rxphaligndone_out(0) => rxphaligndone_out(0),
      rxpllclksel_in(1 downto 0) => rxpllclksel_in(1 downto 0),
      rxpmaresetdone_out(0) => rxpmaresetdone_out(0),
      rxpolarity_in(0) => rxpolarity_in(0),
      rxprgdivresetdone_out(0) => rxprgdivresetdone_out(0),
      rxprogdivreset_in(0) => rxprogdivreset_in(0),
      rxresetdone_out(0) => rxresetdone_out(0),
      rxstartofseq_out(1 downto 0) => rxstartofseq_out(1 downto 0),
      rxsyncdone_out(0) => rxsyncdone_out(0),
      rxsysclksel_in(1 downto 0) => rxsysclksel_in(1 downto 0),
      rxuserrdy_in(0) => rxuserrdy_in(0),
      txdiffctrl_in(4 downto 0) => txdiffctrl_in(4 downto 0),
      txelecidle_in(0) => txelecidle_in(0),
      txheader_in(5 downto 0) => txheader_in(5 downto 0),
      txinhibit_in(0) => txinhibit_in(0),
      txmaincursor_in(6 downto 0) => txmaincursor_in(6 downto 0),
      txpcsreset_in(0) => txpcsreset_in(0),
      txpd_in(1 downto 0) => txpd_in(1 downto 0),
      txpdelecidlemode_in(0) => txpdelecidlemode_in(0),
      txphaligndone_out(0) => txphaligndone_out(0),
      txpllclksel_in(1 downto 0) => txpllclksel_in(1 downto 0),
      txpmareset_in(0) => txpmareset_in(0),
      txpmaresetdone_out(0) => txpmaresetdone_out(0),
      txpolarity_in(0) => txpolarity_in(0),
      txpostcursor_in(4 downto 0) => txpostcursor_in(4 downto 0),
      txprecursor_in(4 downto 0) => txprecursor_in(4 downto 0),
      txprgdivresetdone_out(0) => txprgdivresetdone_out(0),
      txprogdivreset_in(0) => txprogdivreset_in(0),
      txresetdone_out(0) => txresetdone_out(0),
      txsequence_in(6 downto 0) => txsequence_in(6 downto 0),
      txsyncdone_out(0) => txsyncdone_out(0),
      txsysclksel_in(1 downto 0) => txsysclksel_in(1 downto 0),
      txuserrdy_in(0) => txuserrdy_in(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gthe4_common_wrapper is
  port (
    drprdy_common_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0lock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1lock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    drpdo_common_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drpclk_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpen_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk00_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk01_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0pd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1pd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpaddr_common_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drpdi_common_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    pcierateqpll0_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    pcierateqpll1_in : in STD_LOGIC_VECTOR ( 2 downto 0 )
  );
end taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gthe4_common_wrapper;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gthe4_common_wrapper is
begin
common_inst: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_common
     port map (
      drpaddr_common_in(15 downto 0) => drpaddr_common_in(15 downto 0),
      drpclk_common_in(0) => drpclk_common_in(0),
      drpdi_common_in(15 downto 0) => drpdi_common_in(15 downto 0),
      drpdo_common_out(15 downto 0) => drpdo_common_out(15 downto 0),
      drpen_common_in(0) => drpen_common_in(0),
      drprdy_common_out(0) => drprdy_common_out(0),
      drpwe_common_in(0) => drpwe_common_in(0),
      gtrefclk00_in(0) => gtrefclk00_in(0),
      gtrefclk01_in(0) => gtrefclk01_in(0),
      pcierateqpll0_in(2 downto 0) => pcierateqpll0_in(2 downto 0),
      pcierateqpll1_in(2 downto 0) => pcierateqpll1_in(2 downto 0),
      qpll0lock_out(0) => qpll0lock_out(0),
      qpll0outclk_out(0) => qpll0outclk_out(0),
      qpll0outrefclk_out(0) => qpll0outrefclk_out(0),
      qpll0pd_in(0) => qpll0pd_in(0),
      qpll0reset_in(0) => qpll0reset_in(0),
      qpll1lock_out(0) => qpll1lock_out(0),
      qpll1outclk_out(0) => qpll1outclk_out(0),
      qpll1outrefclk_out(0) => qpll1outrefclk_out(0),
      qpll1pd_in(0) => qpll1pd_in(0),
      qpll1reset_in(0) => qpll1reset_in(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_gthe4 is
  port (
    gtpowergood_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    drprdy_common_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0lock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1lock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    drpdo_common_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drprdy_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxn_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxp_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrlock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_srcclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxprgdivresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_srcclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txprgdivresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_rx_out : out STD_LOGIC_VECTOR ( 63 downto 0 );
    drpdo_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    rxdatavalid_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxheadervalid_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxstartofseq_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxheader_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    gtwiz_userclk_rx_usrclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk2_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk2_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_active_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_active_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_error_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_error_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxpd_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    drpclk_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpen_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk00_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk01_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0pd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1pd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpaddr_common_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drpdi_common_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    pcierateqpll0_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    pcierateqpll1_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    drpclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    eyescanreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxn_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxp_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gttxreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfelpmreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxgearboxslip_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpcsreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpolarity_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxprogdivreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxuserrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txelecidle_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txinhibit_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpcsreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpdelecidlemode_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpmareset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpolarity_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txprogdivreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txuserrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_tx_in : in STD_LOGIC_VECTOR ( 63 downto 0 );
    drpdi_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    rxpllclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxsysclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txpd_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txpllclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txsysclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txdiffctrl_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txpostcursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txprecursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txheader_in : in STD_LOGIC_VECTOR ( 5 downto 0 );
    txmaincursor_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    txsequence_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    drpaddr_in : in STD_LOGIC_VECTOR ( 9 downto 0 );
    gtwiz_userclk_tx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrxreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpmareset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_start_user_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_start_user_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
end taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_gthe4;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_gthe4 is
  signal \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_11\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_110\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_13\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_17\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_6\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_7\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.gen_pwrgood_delay_inst[0].delay_powergood_inst_n_1\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.gen_pwrgood_delay_inst[0].delay_powergood_inst_n_2\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.gtpowergood_int\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.gtrxreset_ch_int\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.rxdlysreset_int\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.rxpmareset_ch_int\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.rxratemode_ch_int\ : STD_LOGIC;
  signal \gen_gtwizard_gthe4.txdlysreset_int\ : STD_LOGIC;
  signal \^gtwiz_userclk_rx_srcclk_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^gtwiz_userclk_rx_usrclk2_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^gtwiz_userclk_rx_usrclk_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^gtwiz_userclk_tx_srcclk_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^gtwiz_userclk_tx_usrclk2_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^gtwiz_userclk_tx_usrclk_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal lopt : STD_LOGIC;
  signal lopt_1 : STD_LOGIC;
  signal lopt_2 : STD_LOGIC;
  signal lopt_3 : STD_LOGIC;
  signal lopt_4 : STD_LOGIC;
  signal lopt_5 : STD_LOGIC;
  signal \^qpll0outclk_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^qpll0outrefclk_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^qpll1outclk_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^qpll1outrefclk_out\ : STD_LOGIC_VECTOR ( 0 to 0 );
begin
  gtwiz_userclk_rx_srcclk_out(0) <= \^gtwiz_userclk_rx_srcclk_out\(0);
  gtwiz_userclk_rx_usrclk2_out(0) <= \^gtwiz_userclk_rx_usrclk2_out\(0);
  gtwiz_userclk_rx_usrclk_out(0) <= \^gtwiz_userclk_rx_usrclk_out\(0);
  gtwiz_userclk_tx_srcclk_out(0) <= \^gtwiz_userclk_tx_srcclk_out\(0);
  gtwiz_userclk_tx_usrclk2_out(0) <= \^gtwiz_userclk_tx_usrclk2_out\(0);
  gtwiz_userclk_tx_usrclk_out(0) <= \^gtwiz_userclk_tx_usrclk_out\(0);
  qpll0outclk_out(0) <= \^qpll0outclk_out\(0);
  qpll0outrefclk_out(0) <= \^qpll0outrefclk_out\(0);
  qpll1outclk_out(0) <= \^qpll1outclk_out\(0);
  qpll1outrefclk_out(0) <= \^qpll1outrefclk_out\(0);
\gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gthe4_channel_wrapper
     port map (
      RXPD(1) => \gen_gtwizard_gthe4.gen_pwrgood_delay_inst[0].delay_powergood_inst_n_1\,
      RXPD(0) => \gen_gtwizard_gthe4.gen_pwrgood_delay_inst[0].delay_powergood_inst_n_2\,
      RXRATE(0) => \gen_gtwizard_gthe4.rxratemode_ch_int\,
      drpaddr_in(9 downto 0) => drpaddr_in(9 downto 0),
      drpclk_in(0) => drpclk_in(0),
      drpdi_in(15 downto 0) => drpdi_in(15 downto 0),
      drpdo_out(15 downto 0) => drpdo_out(15 downto 0),
      drpen_in(0) => drpen_in(0),
      drprdy_out(0) => drprdy_out(0),
      drpwe_in(0) => drpwe_in(0),
      eyescanreset_in(0) => eyescanreset_in(0),
      \gen_gtwizard_gthe4.gtpowergood_int\ => \gen_gtwizard_gthe4.gtpowergood_int\,
      \gen_gtwizard_gthe4.gtrxreset_ch_int\ => \gen_gtwizard_gthe4.gtrxreset_ch_int\,
      \gen_gtwizard_gthe4.rxdlysreset_int\ => \gen_gtwizard_gthe4.rxdlysreset_int\,
      \gen_gtwizard_gthe4.rxpmareset_ch_int\ => \gen_gtwizard_gthe4.rxpmareset_ch_int\,
      \gen_gtwizard_gthe4.txdlysreset_int\ => \gen_gtwizard_gthe4.txdlysreset_int\,
      \gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST\ => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_110\,
      gthrxn_in(0) => gthrxn_in(0),
      gthrxp_in(0) => gthrxp_in(0),
      gthtxn_out(0) => gthtxn_out(0),
      gthtxp_out(0) => gthtxp_out(0),
      gttxreset_in(0) => gttxreset_in(0),
      gtwiz_userclk_rx_srcclk_out(0) => \^gtwiz_userclk_rx_srcclk_out\(0),
      gtwiz_userclk_rx_usrclk2_out(0) => \^gtwiz_userclk_rx_usrclk2_out\(0),
      gtwiz_userclk_rx_usrclk_out(0) => \^gtwiz_userclk_rx_usrclk_out\(0),
      gtwiz_userclk_tx_srcclk_out(0) => \^gtwiz_userclk_tx_srcclk_out\(0),
      gtwiz_userclk_tx_usrclk2_out(0) => \^gtwiz_userclk_tx_usrclk2_out\(0),
      gtwiz_userclk_tx_usrclk_out(0) => \^gtwiz_userclk_tx_usrclk_out\(0),
      gtwiz_userdata_rx_out(63 downto 0) => gtwiz_userdata_rx_out(63 downto 0),
      gtwiz_userdata_tx_in(63 downto 0) => gtwiz_userdata_tx_in(63 downto 0),
      lopt => lopt,
      lopt_1 => gtwiz_userclk_rx_reset_in(0),
      lopt_2 => lopt_1,
      lopt_3 => lopt_2,
      lopt_4 => lopt_3,
      lopt_5 => gtwiz_userclk_tx_reset_in(0),
      lopt_6 => lopt_4,
      lopt_7 => lopt_5,
      qpll0outclk_out(0) => \^qpll0outclk_out\(0),
      qpll0outrefclk_out(0) => \^qpll0outrefclk_out\(0),
      qpll1outclk_out(0) => \^qpll1outclk_out\(0),
      qpll1outrefclk_out(0) => \^qpll1outrefclk_out\(0),
      rxcdrhold_in(0) => rxcdrhold_in(0),
      rxcdrlock_out(0) => rxcdrlock_out(0),
      rxcdrovrden_in(0) => rxcdrovrden_in(0),
      rxdatavalid_out(1 downto 0) => rxdatavalid_out(1 downto 0),
      rxdfelpmreset_in(0) => rxdfelpmreset_in(0),
      rxgearboxslip_in(0) => rxgearboxslip_in(0),
      rxheader_out(5 downto 0) => rxheader_out(5 downto 0),
      rxheadervalid_out(1 downto 0) => rxheadervalid_out(1 downto 0),
      rxlpmen_in(0) => rxlpmen_in(0),
      rxoutclkpcs_out(0) => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_6\,
      rxpcsreset_in(0) => rxpcsreset_in(0),
      rxphaligndone_out(0) => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_7\,
      rxpllclksel_in(1 downto 0) => rxpllclksel_in(1 downto 0),
      rxpmaresetdone_out(0) => rxpmaresetdone_out(0),
      rxpolarity_in(0) => rxpolarity_in(0),
      rxprgdivresetdone_out(0) => rxprgdivresetdone_out(0),
      rxprogdivreset_in(0) => rxprogdivreset_in(0),
      rxresetdone_out(0) => rxresetdone_out(0),
      rxstartofseq_out(1 downto 0) => rxstartofseq_out(1 downto 0),
      rxsyncdone_out(0) => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_11\,
      rxsysclksel_in(1 downto 0) => rxsysclksel_in(1 downto 0),
      rxuserrdy_in(0) => rxuserrdy_in(0),
      txdiffctrl_in(4 downto 0) => txdiffctrl_in(4 downto 0),
      txelecidle_in(0) => txelecidle_in(0),
      txheader_in(5 downto 0) => txheader_in(5 downto 0),
      txinhibit_in(0) => txinhibit_in(0),
      txmaincursor_in(6 downto 0) => txmaincursor_in(6 downto 0),
      txpcsreset_in(0) => txpcsreset_in(0),
      txpd_in(1 downto 0) => txpd_in(1 downto 0),
      txpdelecidlemode_in(0) => txpdelecidlemode_in(0),
      txphaligndone_out(0) => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_13\,
      txpllclksel_in(1 downto 0) => txpllclksel_in(1 downto 0),
      txpmareset_in(0) => txpmareset_in(0),
      txpmaresetdone_out(0) => txpmaresetdone_out(0),
      txpolarity_in(0) => txpolarity_in(0),
      txpostcursor_in(4 downto 0) => txpostcursor_in(4 downto 0),
      txprecursor_in(4 downto 0) => txprecursor_in(4 downto 0),
      txprgdivresetdone_out(0) => txprgdivresetdone_out(0),
      txprogdivreset_in(0) => txprogdivreset_in(0),
      txresetdone_out(0) => txresetdone_out(0),
      txsequence_in(6 downto 0) => txsequence_in(6 downto 0),
      txsyncdone_out(0) => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_17\,
      txsysclksel_in(1 downto 0) => txsysclksel_in(1 downto 0),
      txuserrdy_in(0) => txuserrdy_in(0)
    );
\gen_gtwizard_gthe4.gen_common.gen_common_container[0].gen_enabled_common.gthe4_common_wrapper_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gthe4_common_wrapper
     port map (
      drpaddr_common_in(15 downto 0) => drpaddr_common_in(15 downto 0),
      drpclk_common_in(0) => drpclk_common_in(0),
      drpdi_common_in(15 downto 0) => drpdi_common_in(15 downto 0),
      drpdo_common_out(15 downto 0) => drpdo_common_out(15 downto 0),
      drpen_common_in(0) => drpen_common_in(0),
      drprdy_common_out(0) => drprdy_common_out(0),
      drpwe_common_in(0) => drpwe_common_in(0),
      gtrefclk00_in(0) => gtrefclk00_in(0),
      gtrefclk01_in(0) => gtrefclk01_in(0),
      pcierateqpll0_in(2 downto 0) => pcierateqpll0_in(2 downto 0),
      pcierateqpll1_in(2 downto 0) => pcierateqpll1_in(2 downto 0),
      qpll0lock_out(0) => qpll0lock_out(0),
      qpll0outclk_out(0) => \^qpll0outclk_out\(0),
      qpll0outrefclk_out(0) => \^qpll0outrefclk_out\(0),
      qpll0pd_in(0) => qpll0pd_in(0),
      qpll0reset_in(0) => qpll0reset_in(0),
      qpll1lock_out(0) => qpll1lock_out(0),
      qpll1outclk_out(0) => \^qpll1outclk_out\(0),
      qpll1outrefclk_out(0) => \^qpll1outrefclk_out\(0),
      qpll1pd_in(0) => qpll1pd_in(0),
      qpll1reset_in(0) => qpll1reset_in(0)
    );
\gen_gtwizard_gthe4.gen_pwrgood_delay_inst[0].delay_powergood_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gthe4_delay_powergood
     port map (
      RXPD(1) => \gen_gtwizard_gthe4.gen_pwrgood_delay_inst[0].delay_powergood_inst_n_1\,
      RXPD(0) => \gen_gtwizard_gthe4.gen_pwrgood_delay_inst[0].delay_powergood_inst_n_2\,
      RXRATE(0) => \gen_gtwizard_gthe4.rxratemode_ch_int\,
      \gen_gtwizard_gthe4.gtpowergood_int\ => \gen_gtwizard_gthe4.gtpowergood_int\,
      \gen_gtwizard_gthe4.gtrxreset_ch_int\ => \gen_gtwizard_gthe4.gtrxreset_ch_int\,
      \gen_gtwizard_gthe4.rxpmareset_ch_int\ => \gen_gtwizard_gthe4.rxpmareset_ch_int\,
      \gen_powergood_delay.intclk_rrst_n_r_reg[4]_0\ => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_110\,
      gtrxreset_in(0) => gtrxreset_in(0),
      \out\ => gtpowergood_out(0),
      rxoutclkpcs_out(0) => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_6\,
      rxpd_in(1 downto 0) => rxpd_in(1 downto 0),
      rxpmareset_in(0) => rxpmareset_in(0)
    );
\gen_gtwizard_gthe4.gen_rx_buffer_bypass_internal.gen_single_instance.gtwiz_buffbypass_rx_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_buffbypass_rx
     port map (
      \gen_gtwizard_gthe4.rxdlysreset_int\ => \gen_gtwizard_gthe4.rxdlysreset_int\,
      gtwiz_buffbypass_rx_done_out(0) => gtwiz_buffbypass_rx_done_out(0),
      gtwiz_buffbypass_rx_error_out(0) => gtwiz_buffbypass_rx_error_out(0),
      gtwiz_buffbypass_rx_reset_in(0) => gtwiz_buffbypass_rx_reset_in(0),
      gtwiz_buffbypass_rx_start_user_in(0) => gtwiz_buffbypass_rx_start_user_in(0),
      gtwiz_reset_rx_done_in(0) => gtwiz_reset_rx_done_in(0),
      gtwiz_userclk_rx_usrclk2_out(0) => \^gtwiz_userclk_rx_usrclk2_out\(0),
      rxphaligndone_out(0) => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_7\,
      rxsyncdone_out(0) => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_11\
    );
\gen_gtwizard_gthe4.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_userclk_rx
     port map (
      gtwiz_userclk_rx_active_out(0) => gtwiz_userclk_rx_active_out(0),
      gtwiz_userclk_rx_reset_in(0) => gtwiz_userclk_rx_reset_in(0),
      gtwiz_userclk_rx_srcclk_out(0) => \^gtwiz_userclk_rx_srcclk_out\(0),
      gtwiz_userclk_rx_usrclk2_out(0) => \^gtwiz_userclk_rx_usrclk2_out\(0),
      gtwiz_userclk_rx_usrclk_out(0) => \^gtwiz_userclk_rx_usrclk_out\(0),
      lopt => lopt,
      lopt_1 => lopt_1,
      lopt_2 => lopt_2
    );
\gen_gtwizard_gthe4.gen_tx_buffer_bypass_internal.gen_single_instance.gtwiz_buffbypass_tx_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_buffbypass_tx
     port map (
      \gen_gtwizard_gthe4.txdlysreset_int\ => \gen_gtwizard_gthe4.txdlysreset_int\,
      gtwiz_buffbypass_tx_done_out(0) => gtwiz_buffbypass_tx_done_out(0),
      gtwiz_buffbypass_tx_error_out(0) => gtwiz_buffbypass_tx_error_out(0),
      gtwiz_buffbypass_tx_reset_in(0) => gtwiz_buffbypass_tx_reset_in(0),
      gtwiz_buffbypass_tx_start_user_in(0) => gtwiz_buffbypass_tx_start_user_in(0),
      gtwiz_reset_tx_done_in(0) => gtwiz_reset_tx_done_in(0),
      gtwiz_userclk_tx_usrclk2_out(0) => \^gtwiz_userclk_tx_usrclk2_out\(0),
      txphaligndone_out(0) => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_13\,
      txsyncdone_out(0) => \gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst_n_17\
    );
\gen_gtwizard_gthe4.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_ultrascale_v1_7_17_gtwiz_userclk_tx
     port map (
      gtwiz_userclk_tx_active_out(0) => gtwiz_userclk_tx_active_out(0),
      gtwiz_userclk_tx_reset_in(0) => gtwiz_userclk_tx_reset_in(0),
      gtwiz_userclk_tx_srcclk_out(0) => \^gtwiz_userclk_tx_srcclk_out\(0),
      gtwiz_userclk_tx_usrclk2_out(0) => \^gtwiz_userclk_tx_usrclk2_out\(0),
      gtwiz_userclk_tx_usrclk_out(0) => \^gtwiz_userclk_tx_usrclk_out\(0),
      lopt => lopt_3,
      lopt_1 => lopt_4,
      lopt_2 => lopt_5
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top is
  port (
    gtwiz_userclk_tx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_active_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_srcclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_usrclk2_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_tx_active_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_active_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_srcclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_usrclk2_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_active_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_start_user_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_error_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_start_user_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_error_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_clk_freerun_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_all_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_pll_and_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_pll_and_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_qpll0lock_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_qpll1lock_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_cdr_stable_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_qpll0reset_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_qpll1reset_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_gthe3_cpll_cal_txoutclk_period_in : in STD_LOGIC_VECTOR ( 17 downto 0 );
    gtwiz_gthe3_cpll_cal_cnt_tol_in : in STD_LOGIC_VECTOR ( 17 downto 0 );
    gtwiz_gthe3_cpll_cal_bufg_ce_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_gthe4_cpll_cal_txoutclk_period_in : in STD_LOGIC_VECTOR ( 17 downto 0 );
    gtwiz_gthe4_cpll_cal_cnt_tol_in : in STD_LOGIC_VECTOR ( 17 downto 0 );
    gtwiz_gthe4_cpll_cal_bufg_ce_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_gtye4_cpll_cal_txoutclk_period_in : in STD_LOGIC_VECTOR ( 17 downto 0 );
    gtwiz_gtye4_cpll_cal_cnt_tol_in : in STD_LOGIC_VECTOR ( 17 downto 0 );
    gtwiz_gtye4_cpll_cal_bufg_ce_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_tx_in : in STD_LOGIC_VECTOR ( 63 downto 0 );
    gtwiz_userdata_rx_out : out STD_LOGIC_VECTOR ( 63 downto 0 );
    bgbypassb_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    bgmonitorenb_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    bgpdb_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    bgrcalovrd_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    bgrcalovrdenb_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpaddr_common_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drpclk_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpdi_common_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drpen_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtgrefclk0_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtgrefclk1_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtnorthrefclk00_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtnorthrefclk01_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtnorthrefclk10_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtnorthrefclk11_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk00_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk01_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk10_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk11_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtsouthrefclk00_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtsouthrefclk01_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtsouthrefclk10_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtsouthrefclk11_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    pcierateqpll0_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    pcierateqpll1_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    pmarsvd0_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pmarsvd1_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    qpll0clkrsvd0_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0clkrsvd1_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0fbdiv_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    qpll0lockdetclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0locken_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0pd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0refclksel_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    qpll0reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1clkrsvd0_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1clkrsvd1_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1fbdiv_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    qpll1lockdetclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1locken_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1pd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1refclksel_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    qpll1reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpllrsvd1_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    qpllrsvd2_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    qpllrsvd3_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    qpllrsvd4_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    rcalenb_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    sdm0data_in : in STD_LOGIC_VECTOR ( 24 downto 0 );
    sdm0reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    sdm0toggle_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    sdm0width_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    sdm1data_in : in STD_LOGIC_VECTOR ( 24 downto 0 );
    sdm1reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    sdm1toggle_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    sdm1width_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    tcongpi_in : in STD_LOGIC_VECTOR ( 9 downto 0 );
    tconpowerup_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    tconreset_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    tconrsvdin1_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    ubcfgstreamen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubdo_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubdrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubenable_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubgpi_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubintr_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubiolmbrst_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubmbrst_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubmdmcapture_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubmdmdbgrst_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubmdmdbgupdate_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubmdmregen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubmdmshift_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubmdmsysrst_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubmdmtck_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    ubmdmtdi_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpdo_common_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drprdy_common_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    pmarsvdout0_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pmarsvdout1_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    qpll0fbclklost_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0lock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0refclklost_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1fbclklost_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1lock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1refclklost_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qplldmonitor0_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    qplldmonitor1_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    refclkoutmonitor0_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    refclkoutmonitor1_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxrecclk0_sel_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxrecclk1_sel_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxrecclk0sel_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxrecclk1sel_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    sdm0finalout_out : out STD_LOGIC_VECTOR ( 3 downto 0 );
    sdm0testdata_out : out STD_LOGIC_VECTOR ( 14 downto 0 );
    sdm1finalout_out : out STD_LOGIC_VECTOR ( 3 downto 0 );
    sdm1testdata_out : out STD_LOGIC_VECTOR ( 14 downto 0 );
    tcongpo_out : out STD_LOGIC_VECTOR ( 9 downto 0 );
    tconrsvdout0_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    ubdaddr_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    ubden_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    ubdi_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    ubdwe_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    ubmdmtdo_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    ubrsvdout_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    ubtxuart_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    cdrstepdir_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    cdrstepsq_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    cdrstepsx_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    cfgreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    clkrsvd0_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    clkrsvd1_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    cpllfreqlock_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    cplllockdetclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    cplllocken_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    cpllpd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    cpllrefclksel_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    cpllreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    dmonfiforeset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    dmonitorclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpaddr_in : in STD_LOGIC_VECTOR ( 9 downto 0 );
    drpclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpdi_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drpen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drprst_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    elpcaldvorwren_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    elpcalpaorwren_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    evoddphicaldone_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    evoddphicalstart_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    evoddphidrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    evoddphidwren_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    evoddphixrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    evoddphixwren_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    eyescanmode_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    eyescanreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    eyescantrigger_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    freqos_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtgrefclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxn_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxp_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtnorthrefclk0_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtnorthrefclk1_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk0_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk1_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtresetsel_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrsvd_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gtrxreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrxresetsel_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtsouthrefclk0_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtsouthrefclk1_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gttxreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gttxresetsel_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    incpctrl_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtyrxn_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtyrxp_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    loopback_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    looprsvd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    lpbkrxtxseren_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    lpbktxrxseren_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    pcieeqrxeqadaptdone_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    pcierstidle_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    pciersttxsyncstart_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    pcieuserratedone_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    pcsrsvdin_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    pcsrsvdin2_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    pmarsvdin_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0clk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0freqlock_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0refclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1clk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1freqlock_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1refclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    resetovrd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rstclkentx_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rx8b10ben_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxafecfoken_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxbufreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrfreqreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrresetrsv_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxchbonden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxchbondi_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    rxchbondlevel_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    rxchbondmaster_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxchbondslave_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxckcalreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxckcalstart_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    rxcommadeten_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfeagcctrl_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxdccforcestart_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfeagchold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfeagcovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfecfokfcnum_in : in STD_LOGIC_VECTOR ( 3 downto 0 );
    rxdfecfokfen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfecfokfpulse_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfecfokhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfecfokovren_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfekhhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfekhovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfelfhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfelfovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfelpmreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap10hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap10ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap11hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap11ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap12hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap12ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap13hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap13ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap14hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap14ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap15hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap15ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap2hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap2ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap3hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap3ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap4hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap4ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap5hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap5ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap6hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap6ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap7hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap7ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap8hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap8ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap9hold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfetap9ovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfeuthold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfeutovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfevphold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfevpovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfevsen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdfexyden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdlybypass_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdlyen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdlyovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxdlysreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxelecidlemode_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxeqtraining_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxgearboxslip_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlatclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmgchold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmgcovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmhfhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmhfovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmlfhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmlfklovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmoshold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmosovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxmcommaalignen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxmonitorsel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxoobreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxoscalreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxoshold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxosintcfg_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxosinten_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxosinthold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxosintovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxosintstrobe_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxosinttestovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxosovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxoutclksel_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    rxpcommaalignen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpcsreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpd_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxphalign_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxphalignen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxphdlypd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxphdlyreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxphovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpllclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxpmareset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxpolarity_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxprbscntreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxprbssel_in : in STD_LOGIC_VECTOR ( 3 downto 0 );
    rxprogdivreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxqpien_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxrate_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    rxratemode_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxslide_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxslipoutclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxslippma_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxsyncallin_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxsyncin_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxsyncmode_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxsysclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    rxtermination_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxuserrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxusrclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxusrclk2_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    sigvalidclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    tstin_in : in STD_LOGIC_VECTOR ( 19 downto 0 );
    tx8b10bbypass_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    tx8b10ben_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txbufdiffctrl_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txcominit_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txcomsas_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txcomwake_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txctrl0_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    txctrl1_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    txctrl2_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    txdata_in : in STD_LOGIC_VECTOR ( 127 downto 0 );
    txdataextendrsvd_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    txdccforcestart_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txdccreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txdeemph_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txdetectrx_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txdiffctrl_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txdiffpd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txdlybypass_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txdlyen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txdlyhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txdlyovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txdlysreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txdlyupdown_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txelecidle_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txelforcestart_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txheader_in : in STD_LOGIC_VECTOR ( 5 downto 0 );
    txinhibit_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txlatclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txlfpstreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txlfpsu2lpexit_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txlfpsu3wake_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txmaincursor_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    txmargin_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    txmuxdcdexhold_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txmuxdcdorwren_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txoneszeros_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txoutclksel_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    txpcsreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpd_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txpdelecidlemode_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txphalign_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txphalignen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txphdlypd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txphdlyreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txphdlytstclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txphinit_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txphovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpippmen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpippmovrden_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpippmpd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpippmsel_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpippmstepsize_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txpisopd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpllclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txpmareset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpolarity_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txpostcursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txpostcursorinv_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txprbsforceerr_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txprbssel_in : in STD_LOGIC_VECTOR ( 3 downto 0 );
    txprecursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txprecursorinv_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txprogdivreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txqpibiasen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txqpistrongpdown_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txqpiweakpup_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txrate_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    txratemode_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txsequence_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    txswing_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txsyncallin_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txsyncin_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txsyncmode_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txsysclksel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    txuserrdy_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txusrclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txusrclk2_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    bufgtce_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    bufgtcemask_out : out STD_LOGIC_VECTOR ( 2 downto 0 );
    bufgtdiv_out : out STD_LOGIC_VECTOR ( 8 downto 0 );
    bufgtreset_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    bufgtrstmask_out : out STD_LOGIC_VECTOR ( 2 downto 0 );
    cpllfbclklost_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    cplllock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    cpllrefclklost_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    dmonitorout_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    dmonitoroutclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    drpdo_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drprdy_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    eyescandataerror_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxn_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxp_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtpowergood_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclkmonitor_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtytxn_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtytxp_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    pcierategen3_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    pcierateidle_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    pcierateqpllpd_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    pcierateqpllreset_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    pciesynctxsyncdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    pcieusergen3rdy_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    pcieuserphystatusrst_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    pcieuserratestart_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    pcsrsvdout_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    phystatus_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    pinrsrvdas_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    powerpresent_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    resetexception_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxbufstatus_out : out STD_LOGIC_VECTOR ( 2 downto 0 );
    rxbyteisaligned_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxbyterealign_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrlock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxcdrphdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxchanbondseq_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxchanisaligned_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxchanrealign_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxchbondo_out : out STD_LOGIC_VECTOR ( 4 downto 0 );
    rxckcaldone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxclkcorcnt_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxcominitdet_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxcommadet_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxcomsasdet_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxcomwakedet_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxctrl0_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    rxctrl1_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    rxctrl2_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    rxctrl3_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    rxdata_out : out STD_LOGIC_VECTOR ( 127 downto 0 );
    rxdataextendrsvd_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    rxdatavalid_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxdlysresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxelecidle_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxheader_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    rxheadervalid_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxlfpstresetdet_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxlfpsu2lpexitdet_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxlfpsu3wakedet_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxmonitorout_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    rxosintdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxosintstarted_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxosintstrobedone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxosintstrobestarted_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxoutclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxoutclkfabric_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxoutclkpcs_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxphaligndone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxphalignerr_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxprbserr_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxprbslocked_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxprgdivresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxqpisenn_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxqpisenp_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxratedone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxrecclkout_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxsliderdy_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxslipdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxslipoutclkrdy_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxslippmardy_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxstartofseq_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    rxstatus_out : out STD_LOGIC_VECTOR ( 2 downto 0 );
    rxsyncdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxsyncout_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxvalid_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txbufstatus_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    txcomfinish_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txdccdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txdlysresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txoutclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txoutclkfabric_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txoutclkpcs_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txphaligndone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txphinitdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txprgdivresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txqpisenn_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txqpisenp_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txratedone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txsyncdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txsyncout_out : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute C_CHANNEL_ENABLE : string;
  attribute C_CHANNEL_ENABLE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "192'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001";
  attribute C_COMMON_SCALING_FACTOR : integer;
  attribute C_COMMON_SCALING_FACTOR of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_CPLL_VCO_FREQUENCY : string;
  attribute C_CPLL_VCO_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "2578.125000";
  attribute C_ENABLE_COMMON_USRCLK : integer;
  attribute C_ENABLE_COMMON_USRCLK of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_FORCE_COMMONS : integer;
  attribute C_FORCE_COMMONS of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_FREERUN_FREQUENCY : string;
  attribute C_FREERUN_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "125.000000";
  attribute C_GT_REV : integer;
  attribute C_GT_REV of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 57;
  attribute C_GT_TYPE : integer;
  attribute C_GT_TYPE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 2;
  attribute C_INCLUDE_CPLL_CAL : integer;
  attribute C_INCLUDE_CPLL_CAL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 2;
  attribute C_LOCATE_COMMON : integer;
  attribute C_LOCATE_COMMON of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_LOCATE_IN_SYSTEM_IBERT_CORE : integer;
  attribute C_LOCATE_IN_SYSTEM_IBERT_CORE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 2;
  attribute C_LOCATE_RESET_CONTROLLER : integer;
  attribute C_LOCATE_RESET_CONTROLLER of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_LOCATE_RX_BUFFER_BYPASS_CONTROLLER : integer;
  attribute C_LOCATE_RX_BUFFER_BYPASS_CONTROLLER of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_LOCATE_RX_USER_CLOCKING : integer;
  attribute C_LOCATE_RX_USER_CLOCKING of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_LOCATE_TX_BUFFER_BYPASS_CONTROLLER : integer;
  attribute C_LOCATE_TX_BUFFER_BYPASS_CONTROLLER of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_LOCATE_TX_USER_CLOCKING : integer;
  attribute C_LOCATE_TX_USER_CLOCKING of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_LOCATE_USER_DATA_WIDTH_SIZING : integer;
  attribute C_LOCATE_USER_DATA_WIDTH_SIZING of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_PCIE_CORECLK_FREQ : integer;
  attribute C_PCIE_CORECLK_FREQ of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 250;
  attribute C_PCIE_ENABLE : integer;
  attribute C_PCIE_ENABLE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RESET_CONTROLLER_INSTANCE_CTRL : integer;
  attribute C_RESET_CONTROLLER_INSTANCE_CTRL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RESET_SEQUENCE_INTERVAL : integer;
  attribute C_RESET_SEQUENCE_INTERVAL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_BUFFBYPASS_MODE : integer;
  attribute C_RX_BUFFBYPASS_MODE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_BUFFER_BYPASS_INSTANCE_CTRL : integer;
  attribute C_RX_BUFFER_BYPASS_INSTANCE_CTRL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_BUFFER_MODE : integer;
  attribute C_RX_BUFFER_MODE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_CB_DISP : string;
  attribute C_RX_CB_DISP of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "8'b00000000";
  attribute C_RX_CB_K : string;
  attribute C_RX_CB_K of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "8'b00000000";
  attribute C_RX_CB_LEN_SEQ : integer;
  attribute C_RX_CB_LEN_SEQ of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_RX_CB_MAX_LEVEL : integer;
  attribute C_RX_CB_MAX_LEVEL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_RX_CB_NUM_SEQ : integer;
  attribute C_RX_CB_NUM_SEQ of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_CB_VAL : string;
  attribute C_RX_CB_VAL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "80'b00000000000000000000000000000000000000000000000000000000000000000000000000000000";
  attribute C_RX_CC_DISP : string;
  attribute C_RX_CC_DISP of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "8'b00000000";
  attribute C_RX_CC_ENABLE : integer;
  attribute C_RX_CC_ENABLE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_CC_K : string;
  attribute C_RX_CC_K of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "8'b00000000";
  attribute C_RX_CC_LEN_SEQ : integer;
  attribute C_RX_CC_LEN_SEQ of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_RX_CC_NUM_SEQ : integer;
  attribute C_RX_CC_NUM_SEQ of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_CC_PERIODICITY : integer;
  attribute C_RX_CC_PERIODICITY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 5000;
  attribute C_RX_CC_VAL : string;
  attribute C_RX_CC_VAL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "80'b00000000000000000000000000000000000000000000000000000000000000000000000000000000";
  attribute C_RX_COMMA_M_ENABLE : integer;
  attribute C_RX_COMMA_M_ENABLE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_COMMA_M_VAL : string;
  attribute C_RX_COMMA_M_VAL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "10'b1010000011";
  attribute C_RX_COMMA_P_ENABLE : integer;
  attribute C_RX_COMMA_P_ENABLE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_COMMA_P_VAL : string;
  attribute C_RX_COMMA_P_VAL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "10'b0101111100";
  attribute C_RX_DATA_DECODING : integer;
  attribute C_RX_DATA_DECODING of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 2;
  attribute C_RX_ENABLE : integer;
  attribute C_RX_ENABLE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_RX_INT_DATA_WIDTH : integer;
  attribute C_RX_INT_DATA_WIDTH of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 32;
  attribute C_RX_LINE_RATE : string;
  attribute C_RX_LINE_RATE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "10.312500";
  attribute C_RX_MASTER_CHANNEL_IDX : integer;
  attribute C_RX_MASTER_CHANNEL_IDX of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_OUTCLK_BUFG_GT_DIV : integer;
  attribute C_RX_OUTCLK_BUFG_GT_DIV of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_RX_OUTCLK_FREQUENCY : string;
  attribute C_RX_OUTCLK_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "322.265625";
  attribute C_RX_OUTCLK_SOURCE : integer;
  attribute C_RX_OUTCLK_SOURCE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_RX_PLL_TYPE : integer;
  attribute C_RX_PLL_TYPE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_RECCLK_OUTPUT : string;
  attribute C_RX_RECCLK_OUTPUT of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "192'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
  attribute C_RX_REFCLK_FREQUENCY : string;
  attribute C_RX_REFCLK_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "156.250000";
  attribute C_RX_SLIDE_MODE : integer;
  attribute C_RX_SLIDE_MODE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_USER_CLOCKING_CONTENTS : integer;
  attribute C_RX_USER_CLOCKING_CONTENTS of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_USER_CLOCKING_INSTANCE_CTRL : integer;
  attribute C_RX_USER_CLOCKING_INSTANCE_CTRL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_USER_CLOCKING_RATIO_FSRC_FUSRCLK : integer;
  attribute C_RX_USER_CLOCKING_RATIO_FSRC_FUSRCLK of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_RX_USER_CLOCKING_RATIO_FUSRCLK_FUSRCLK2 : integer;
  attribute C_RX_USER_CLOCKING_RATIO_FUSRCLK_FUSRCLK2 of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 2;
  attribute C_RX_USER_CLOCKING_SOURCE : integer;
  attribute C_RX_USER_CLOCKING_SOURCE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_RX_USER_DATA_WIDTH : integer;
  attribute C_RX_USER_DATA_WIDTH of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 64;
  attribute C_RX_USRCLK2_FREQUENCY : string;
  attribute C_RX_USRCLK2_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "161.132813";
  attribute C_RX_USRCLK_FREQUENCY : string;
  attribute C_RX_USRCLK_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "322.265625";
  attribute C_SECONDARY_QPLL_ENABLE : integer;
  attribute C_SECONDARY_QPLL_ENABLE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_SECONDARY_QPLL_REFCLK_FREQUENCY : string;
  attribute C_SECONDARY_QPLL_REFCLK_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "156.250000";
  attribute C_SIM_CPLL_CAL_BYPASS : integer;
  attribute C_SIM_CPLL_CAL_BYPASS of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_TOTAL_NUM_CHANNELS : integer;
  attribute C_TOTAL_NUM_CHANNELS of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_TOTAL_NUM_COMMONS : integer;
  attribute C_TOTAL_NUM_COMMONS of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_TOTAL_NUM_COMMONS_EXAMPLE : integer;
  attribute C_TOTAL_NUM_COMMONS_EXAMPLE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TXPROGDIV_FREQ_ENABLE : integer;
  attribute C_TXPROGDIV_FREQ_ENABLE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TXPROGDIV_FREQ_SOURCE : integer;
  attribute C_TXPROGDIV_FREQ_SOURCE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TXPROGDIV_FREQ_VAL : string;
  attribute C_TXPROGDIV_FREQ_VAL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "322.265625";
  attribute C_TX_BUFFBYPASS_MODE : integer;
  attribute C_TX_BUFFBYPASS_MODE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TX_BUFFER_BYPASS_INSTANCE_CTRL : integer;
  attribute C_TX_BUFFER_BYPASS_INSTANCE_CTRL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TX_BUFFER_MODE : integer;
  attribute C_TX_BUFFER_MODE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TX_DATA_ENCODING : integer;
  attribute C_TX_DATA_ENCODING of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 2;
  attribute C_TX_ENABLE : integer;
  attribute C_TX_ENABLE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_TX_INT_DATA_WIDTH : integer;
  attribute C_TX_INT_DATA_WIDTH of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 32;
  attribute C_TX_LINE_RATE : string;
  attribute C_TX_LINE_RATE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "10.312500";
  attribute C_TX_MASTER_CHANNEL_IDX : integer;
  attribute C_TX_MASTER_CHANNEL_IDX of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TX_OUTCLK_BUFG_GT_DIV : integer;
  attribute C_TX_OUTCLK_BUFG_GT_DIV of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_TX_OUTCLK_FREQUENCY : string;
  attribute C_TX_OUTCLK_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "322.265625";
  attribute C_TX_OUTCLK_SOURCE : integer;
  attribute C_TX_OUTCLK_SOURCE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 4;
  attribute C_TX_PLL_TYPE : integer;
  attribute C_TX_PLL_TYPE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TX_REFCLK_FREQUENCY : string;
  attribute C_TX_REFCLK_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "156.250000";
  attribute C_TX_USER_CLOCKING_CONTENTS : integer;
  attribute C_TX_USER_CLOCKING_CONTENTS of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TX_USER_CLOCKING_INSTANCE_CTRL : integer;
  attribute C_TX_USER_CLOCKING_INSTANCE_CTRL of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TX_USER_CLOCKING_RATIO_FSRC_FUSRCLK : integer;
  attribute C_TX_USER_CLOCKING_RATIO_FSRC_FUSRCLK of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
  attribute C_TX_USER_CLOCKING_RATIO_FUSRCLK_FUSRCLK2 : integer;
  attribute C_TX_USER_CLOCKING_RATIO_FUSRCLK_FUSRCLK2 of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 2;
  attribute C_TX_USER_CLOCKING_SOURCE : integer;
  attribute C_TX_USER_CLOCKING_SOURCE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 0;
  attribute C_TX_USER_DATA_WIDTH : integer;
  attribute C_TX_USER_DATA_WIDTH of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 64;
  attribute C_TX_USRCLK2_FREQUENCY : string;
  attribute C_TX_USRCLK2_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "161.132813";
  attribute C_TX_USRCLK_FREQUENCY : string;
  attribute C_TX_USRCLK_FREQUENCY of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is "322.265625";
  attribute C_USER_GTPOWERGOOD_DELAY_EN : integer;
  attribute C_USER_GTPOWERGOOD_DELAY_EN of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top : entity is 1;
end taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top is
  signal \<const0>\ : STD_LOGIC;
begin
  bufgtce_out(0) <= \<const0>\;
  bufgtcemask_out(2) <= \<const0>\;
  bufgtcemask_out(1) <= \<const0>\;
  bufgtcemask_out(0) <= \<const0>\;
  bufgtdiv_out(8) <= \<const0>\;
  bufgtdiv_out(7) <= \<const0>\;
  bufgtdiv_out(6) <= \<const0>\;
  bufgtdiv_out(5) <= \<const0>\;
  bufgtdiv_out(4) <= \<const0>\;
  bufgtdiv_out(3) <= \<const0>\;
  bufgtdiv_out(2) <= \<const0>\;
  bufgtdiv_out(1) <= \<const0>\;
  bufgtdiv_out(0) <= \<const0>\;
  bufgtreset_out(0) <= \<const0>\;
  bufgtrstmask_out(2) <= \<const0>\;
  bufgtrstmask_out(1) <= \<const0>\;
  bufgtrstmask_out(0) <= \<const0>\;
  cpllfbclklost_out(0) <= \<const0>\;
  cplllock_out(0) <= \<const0>\;
  cpllrefclklost_out(0) <= \<const0>\;
  dmonitorout_out(15) <= \<const0>\;
  dmonitorout_out(14) <= \<const0>\;
  dmonitorout_out(13) <= \<const0>\;
  dmonitorout_out(12) <= \<const0>\;
  dmonitorout_out(11) <= \<const0>\;
  dmonitorout_out(10) <= \<const0>\;
  dmonitorout_out(9) <= \<const0>\;
  dmonitorout_out(8) <= \<const0>\;
  dmonitorout_out(7) <= \<const0>\;
  dmonitorout_out(6) <= \<const0>\;
  dmonitorout_out(5) <= \<const0>\;
  dmonitorout_out(4) <= \<const0>\;
  dmonitorout_out(3) <= \<const0>\;
  dmonitorout_out(2) <= \<const0>\;
  dmonitorout_out(1) <= \<const0>\;
  dmonitorout_out(0) <= \<const0>\;
  dmonitoroutclk_out(0) <= \<const0>\;
  eyescandataerror_out(0) <= \<const0>\;
  gtrefclkmonitor_out(0) <= \<const0>\;
  gtwiz_reset_qpll0reset_out(0) <= \<const0>\;
  gtwiz_reset_qpll1reset_out(0) <= \<const0>\;
  gtwiz_reset_rx_cdr_stable_out(0) <= \<const0>\;
  gtwiz_reset_rx_done_out(0) <= \<const0>\;
  gtwiz_reset_tx_done_out(0) <= \<const0>\;
  gtytxn_out(0) <= \<const0>\;
  gtytxp_out(0) <= \<const0>\;
  pcierategen3_out(0) <= \<const0>\;
  pcierateidle_out(0) <= \<const0>\;
  pcierateqpllpd_out(1) <= \<const0>\;
  pcierateqpllpd_out(0) <= \<const0>\;
  pcierateqpllreset_out(1) <= \<const0>\;
  pcierateqpllreset_out(0) <= \<const0>\;
  pciesynctxsyncdone_out(0) <= \<const0>\;
  pcieusergen3rdy_out(0) <= \<const0>\;
  pcieuserphystatusrst_out(0) <= \<const0>\;
  pcieuserratestart_out(0) <= \<const0>\;
  pcsrsvdout_out(15) <= \<const0>\;
  pcsrsvdout_out(14) <= \<const0>\;
  pcsrsvdout_out(13) <= \<const0>\;
  pcsrsvdout_out(12) <= \<const0>\;
  pcsrsvdout_out(11) <= \<const0>\;
  pcsrsvdout_out(10) <= \<const0>\;
  pcsrsvdout_out(9) <= \<const0>\;
  pcsrsvdout_out(8) <= \<const0>\;
  pcsrsvdout_out(7) <= \<const0>\;
  pcsrsvdout_out(6) <= \<const0>\;
  pcsrsvdout_out(5) <= \<const0>\;
  pcsrsvdout_out(4) <= \<const0>\;
  pcsrsvdout_out(3) <= \<const0>\;
  pcsrsvdout_out(2) <= \<const0>\;
  pcsrsvdout_out(1) <= \<const0>\;
  pcsrsvdout_out(0) <= \<const0>\;
  phystatus_out(0) <= \<const0>\;
  pinrsrvdas_out(15) <= \<const0>\;
  pinrsrvdas_out(14) <= \<const0>\;
  pinrsrvdas_out(13) <= \<const0>\;
  pinrsrvdas_out(12) <= \<const0>\;
  pinrsrvdas_out(11) <= \<const0>\;
  pinrsrvdas_out(10) <= \<const0>\;
  pinrsrvdas_out(9) <= \<const0>\;
  pinrsrvdas_out(8) <= \<const0>\;
  pinrsrvdas_out(7) <= \<const0>\;
  pinrsrvdas_out(6) <= \<const0>\;
  pinrsrvdas_out(5) <= \<const0>\;
  pinrsrvdas_out(4) <= \<const0>\;
  pinrsrvdas_out(3) <= \<const0>\;
  pinrsrvdas_out(2) <= \<const0>\;
  pinrsrvdas_out(1) <= \<const0>\;
  pinrsrvdas_out(0) <= \<const0>\;
  pmarsvdout0_out(7) <= \<const0>\;
  pmarsvdout0_out(6) <= \<const0>\;
  pmarsvdout0_out(5) <= \<const0>\;
  pmarsvdout0_out(4) <= \<const0>\;
  pmarsvdout0_out(3) <= \<const0>\;
  pmarsvdout0_out(2) <= \<const0>\;
  pmarsvdout0_out(1) <= \<const0>\;
  pmarsvdout0_out(0) <= \<const0>\;
  pmarsvdout1_out(7) <= \<const0>\;
  pmarsvdout1_out(6) <= \<const0>\;
  pmarsvdout1_out(5) <= \<const0>\;
  pmarsvdout1_out(4) <= \<const0>\;
  pmarsvdout1_out(3) <= \<const0>\;
  pmarsvdout1_out(2) <= \<const0>\;
  pmarsvdout1_out(1) <= \<const0>\;
  pmarsvdout1_out(0) <= \<const0>\;
  powerpresent_out(0) <= \<const0>\;
  qpll0fbclklost_out(0) <= \<const0>\;
  qpll0refclklost_out(0) <= \<const0>\;
  qpll1fbclklost_out(0) <= \<const0>\;
  qpll1refclklost_out(0) <= \<const0>\;
  qplldmonitor0_out(7) <= \<const0>\;
  qplldmonitor0_out(6) <= \<const0>\;
  qplldmonitor0_out(5) <= \<const0>\;
  qplldmonitor0_out(4) <= \<const0>\;
  qplldmonitor0_out(3) <= \<const0>\;
  qplldmonitor0_out(2) <= \<const0>\;
  qplldmonitor0_out(1) <= \<const0>\;
  qplldmonitor0_out(0) <= \<const0>\;
  qplldmonitor1_out(7) <= \<const0>\;
  qplldmonitor1_out(6) <= \<const0>\;
  qplldmonitor1_out(5) <= \<const0>\;
  qplldmonitor1_out(4) <= \<const0>\;
  qplldmonitor1_out(3) <= \<const0>\;
  qplldmonitor1_out(2) <= \<const0>\;
  qplldmonitor1_out(1) <= \<const0>\;
  qplldmonitor1_out(0) <= \<const0>\;
  refclkoutmonitor0_out(0) <= \<const0>\;
  refclkoutmonitor1_out(0) <= \<const0>\;
  resetexception_out(0) <= \<const0>\;
  rxbufstatus_out(2) <= \<const0>\;
  rxbufstatus_out(1) <= \<const0>\;
  rxbufstatus_out(0) <= \<const0>\;
  rxbyteisaligned_out(0) <= \<const0>\;
  rxbyterealign_out(0) <= \<const0>\;
  rxcdrphdone_out(0) <= \<const0>\;
  rxchanbondseq_out(0) <= \<const0>\;
  rxchanisaligned_out(0) <= \<const0>\;
  rxchanrealign_out(0) <= \<const0>\;
  rxchbondo_out(4) <= \<const0>\;
  rxchbondo_out(3) <= \<const0>\;
  rxchbondo_out(2) <= \<const0>\;
  rxchbondo_out(1) <= \<const0>\;
  rxchbondo_out(0) <= \<const0>\;
  rxckcaldone_out(0) <= \<const0>\;
  rxclkcorcnt_out(1) <= \<const0>\;
  rxclkcorcnt_out(0) <= \<const0>\;
  rxcominitdet_out(0) <= \<const0>\;
  rxcommadet_out(0) <= \<const0>\;
  rxcomsasdet_out(0) <= \<const0>\;
  rxcomwakedet_out(0) <= \<const0>\;
  rxctrl0_out(15) <= \<const0>\;
  rxctrl0_out(14) <= \<const0>\;
  rxctrl0_out(13) <= \<const0>\;
  rxctrl0_out(12) <= \<const0>\;
  rxctrl0_out(11) <= \<const0>\;
  rxctrl0_out(10) <= \<const0>\;
  rxctrl0_out(9) <= \<const0>\;
  rxctrl0_out(8) <= \<const0>\;
  rxctrl0_out(7) <= \<const0>\;
  rxctrl0_out(6) <= \<const0>\;
  rxctrl0_out(5) <= \<const0>\;
  rxctrl0_out(4) <= \<const0>\;
  rxctrl0_out(3) <= \<const0>\;
  rxctrl0_out(2) <= \<const0>\;
  rxctrl0_out(1) <= \<const0>\;
  rxctrl0_out(0) <= \<const0>\;
  rxctrl1_out(15) <= \<const0>\;
  rxctrl1_out(14) <= \<const0>\;
  rxctrl1_out(13) <= \<const0>\;
  rxctrl1_out(12) <= \<const0>\;
  rxctrl1_out(11) <= \<const0>\;
  rxctrl1_out(10) <= \<const0>\;
  rxctrl1_out(9) <= \<const0>\;
  rxctrl1_out(8) <= \<const0>\;
  rxctrl1_out(7) <= \<const0>\;
  rxctrl1_out(6) <= \<const0>\;
  rxctrl1_out(5) <= \<const0>\;
  rxctrl1_out(4) <= \<const0>\;
  rxctrl1_out(3) <= \<const0>\;
  rxctrl1_out(2) <= \<const0>\;
  rxctrl1_out(1) <= \<const0>\;
  rxctrl1_out(0) <= \<const0>\;
  rxctrl2_out(7) <= \<const0>\;
  rxctrl2_out(6) <= \<const0>\;
  rxctrl2_out(5) <= \<const0>\;
  rxctrl2_out(4) <= \<const0>\;
  rxctrl2_out(3) <= \<const0>\;
  rxctrl2_out(2) <= \<const0>\;
  rxctrl2_out(1) <= \<const0>\;
  rxctrl2_out(0) <= \<const0>\;
  rxctrl3_out(7) <= \<const0>\;
  rxctrl3_out(6) <= \<const0>\;
  rxctrl3_out(5) <= \<const0>\;
  rxctrl3_out(4) <= \<const0>\;
  rxctrl3_out(3) <= \<const0>\;
  rxctrl3_out(2) <= \<const0>\;
  rxctrl3_out(1) <= \<const0>\;
  rxctrl3_out(0) <= \<const0>\;
  rxdata_out(127) <= \<const0>\;
  rxdata_out(126) <= \<const0>\;
  rxdata_out(125) <= \<const0>\;
  rxdata_out(124) <= \<const0>\;
  rxdata_out(123) <= \<const0>\;
  rxdata_out(122) <= \<const0>\;
  rxdata_out(121) <= \<const0>\;
  rxdata_out(120) <= \<const0>\;
  rxdata_out(119) <= \<const0>\;
  rxdata_out(118) <= \<const0>\;
  rxdata_out(117) <= \<const0>\;
  rxdata_out(116) <= \<const0>\;
  rxdata_out(115) <= \<const0>\;
  rxdata_out(114) <= \<const0>\;
  rxdata_out(113) <= \<const0>\;
  rxdata_out(112) <= \<const0>\;
  rxdata_out(111) <= \<const0>\;
  rxdata_out(110) <= \<const0>\;
  rxdata_out(109) <= \<const0>\;
  rxdata_out(108) <= \<const0>\;
  rxdata_out(107) <= \<const0>\;
  rxdata_out(106) <= \<const0>\;
  rxdata_out(105) <= \<const0>\;
  rxdata_out(104) <= \<const0>\;
  rxdata_out(103) <= \<const0>\;
  rxdata_out(102) <= \<const0>\;
  rxdata_out(101) <= \<const0>\;
  rxdata_out(100) <= \<const0>\;
  rxdata_out(99) <= \<const0>\;
  rxdata_out(98) <= \<const0>\;
  rxdata_out(97) <= \<const0>\;
  rxdata_out(96) <= \<const0>\;
  rxdata_out(95) <= \<const0>\;
  rxdata_out(94) <= \<const0>\;
  rxdata_out(93) <= \<const0>\;
  rxdata_out(92) <= \<const0>\;
  rxdata_out(91) <= \<const0>\;
  rxdata_out(90) <= \<const0>\;
  rxdata_out(89) <= \<const0>\;
  rxdata_out(88) <= \<const0>\;
  rxdata_out(87) <= \<const0>\;
  rxdata_out(86) <= \<const0>\;
  rxdata_out(85) <= \<const0>\;
  rxdata_out(84) <= \<const0>\;
  rxdata_out(83) <= \<const0>\;
  rxdata_out(82) <= \<const0>\;
  rxdata_out(81) <= \<const0>\;
  rxdata_out(80) <= \<const0>\;
  rxdata_out(79) <= \<const0>\;
  rxdata_out(78) <= \<const0>\;
  rxdata_out(77) <= \<const0>\;
  rxdata_out(76) <= \<const0>\;
  rxdata_out(75) <= \<const0>\;
  rxdata_out(74) <= \<const0>\;
  rxdata_out(73) <= \<const0>\;
  rxdata_out(72) <= \<const0>\;
  rxdata_out(71) <= \<const0>\;
  rxdata_out(70) <= \<const0>\;
  rxdata_out(69) <= \<const0>\;
  rxdata_out(68) <= \<const0>\;
  rxdata_out(67) <= \<const0>\;
  rxdata_out(66) <= \<const0>\;
  rxdata_out(65) <= \<const0>\;
  rxdata_out(64) <= \<const0>\;
  rxdata_out(63) <= \<const0>\;
  rxdata_out(62) <= \<const0>\;
  rxdata_out(61) <= \<const0>\;
  rxdata_out(60) <= \<const0>\;
  rxdata_out(59) <= \<const0>\;
  rxdata_out(58) <= \<const0>\;
  rxdata_out(57) <= \<const0>\;
  rxdata_out(56) <= \<const0>\;
  rxdata_out(55) <= \<const0>\;
  rxdata_out(54) <= \<const0>\;
  rxdata_out(53) <= \<const0>\;
  rxdata_out(52) <= \<const0>\;
  rxdata_out(51) <= \<const0>\;
  rxdata_out(50) <= \<const0>\;
  rxdata_out(49) <= \<const0>\;
  rxdata_out(48) <= \<const0>\;
  rxdata_out(47) <= \<const0>\;
  rxdata_out(46) <= \<const0>\;
  rxdata_out(45) <= \<const0>\;
  rxdata_out(44) <= \<const0>\;
  rxdata_out(43) <= \<const0>\;
  rxdata_out(42) <= \<const0>\;
  rxdata_out(41) <= \<const0>\;
  rxdata_out(40) <= \<const0>\;
  rxdata_out(39) <= \<const0>\;
  rxdata_out(38) <= \<const0>\;
  rxdata_out(37) <= \<const0>\;
  rxdata_out(36) <= \<const0>\;
  rxdata_out(35) <= \<const0>\;
  rxdata_out(34) <= \<const0>\;
  rxdata_out(33) <= \<const0>\;
  rxdata_out(32) <= \<const0>\;
  rxdata_out(31) <= \<const0>\;
  rxdata_out(30) <= \<const0>\;
  rxdata_out(29) <= \<const0>\;
  rxdata_out(28) <= \<const0>\;
  rxdata_out(27) <= \<const0>\;
  rxdata_out(26) <= \<const0>\;
  rxdata_out(25) <= \<const0>\;
  rxdata_out(24) <= \<const0>\;
  rxdata_out(23) <= \<const0>\;
  rxdata_out(22) <= \<const0>\;
  rxdata_out(21) <= \<const0>\;
  rxdata_out(20) <= \<const0>\;
  rxdata_out(19) <= \<const0>\;
  rxdata_out(18) <= \<const0>\;
  rxdata_out(17) <= \<const0>\;
  rxdata_out(16) <= \<const0>\;
  rxdata_out(15) <= \<const0>\;
  rxdata_out(14) <= \<const0>\;
  rxdata_out(13) <= \<const0>\;
  rxdata_out(12) <= \<const0>\;
  rxdata_out(11) <= \<const0>\;
  rxdata_out(10) <= \<const0>\;
  rxdata_out(9) <= \<const0>\;
  rxdata_out(8) <= \<const0>\;
  rxdata_out(7) <= \<const0>\;
  rxdata_out(6) <= \<const0>\;
  rxdata_out(5) <= \<const0>\;
  rxdata_out(4) <= \<const0>\;
  rxdata_out(3) <= \<const0>\;
  rxdata_out(2) <= \<const0>\;
  rxdata_out(1) <= \<const0>\;
  rxdata_out(0) <= \<const0>\;
  rxdataextendrsvd_out(7) <= \<const0>\;
  rxdataextendrsvd_out(6) <= \<const0>\;
  rxdataextendrsvd_out(5) <= \<const0>\;
  rxdataextendrsvd_out(4) <= \<const0>\;
  rxdataextendrsvd_out(3) <= \<const0>\;
  rxdataextendrsvd_out(2) <= \<const0>\;
  rxdataextendrsvd_out(1) <= \<const0>\;
  rxdataextendrsvd_out(0) <= \<const0>\;
  rxdlysresetdone_out(0) <= \<const0>\;
  rxelecidle_out(0) <= \<const0>\;
  rxlfpstresetdet_out(0) <= \<const0>\;
  rxlfpsu2lpexitdet_out(0) <= \<const0>\;
  rxlfpsu3wakedet_out(0) <= \<const0>\;
  rxmonitorout_out(7) <= \<const0>\;
  rxmonitorout_out(6) <= \<const0>\;
  rxmonitorout_out(5) <= \<const0>\;
  rxmonitorout_out(4) <= \<const0>\;
  rxmonitorout_out(3) <= \<const0>\;
  rxmonitorout_out(2) <= \<const0>\;
  rxmonitorout_out(1) <= \<const0>\;
  rxmonitorout_out(0) <= \<const0>\;
  rxosintdone_out(0) <= \<const0>\;
  rxosintstarted_out(0) <= \<const0>\;
  rxosintstrobedone_out(0) <= \<const0>\;
  rxosintstrobestarted_out(0) <= \<const0>\;
  rxoutclk_out(0) <= \<const0>\;
  rxoutclkfabric_out(0) <= \<const0>\;
  rxoutclkpcs_out(0) <= \<const0>\;
  rxphaligndone_out(0) <= \<const0>\;
  rxphalignerr_out(0) <= \<const0>\;
  rxprbserr_out(0) <= \<const0>\;
  rxprbslocked_out(0) <= \<const0>\;
  rxqpisenn_out(0) <= \<const0>\;
  rxqpisenp_out(0) <= \<const0>\;
  rxratedone_out(0) <= \<const0>\;
  rxrecclk0_sel_out(0) <= \<const0>\;
  rxrecclk0sel_out(1) <= \<const0>\;
  rxrecclk0sel_out(0) <= \<const0>\;
  rxrecclk1_sel_out(0) <= \<const0>\;
  rxrecclk1sel_out(1) <= \<const0>\;
  rxrecclk1sel_out(0) <= \<const0>\;
  rxrecclkout_out(0) <= \<const0>\;
  rxsliderdy_out(0) <= \<const0>\;
  rxslipdone_out(0) <= \<const0>\;
  rxslipoutclkrdy_out(0) <= \<const0>\;
  rxslippmardy_out(0) <= \<const0>\;
  rxstatus_out(2) <= \<const0>\;
  rxstatus_out(1) <= \<const0>\;
  rxstatus_out(0) <= \<const0>\;
  rxsyncdone_out(0) <= \<const0>\;
  rxsyncout_out(0) <= \<const0>\;
  rxvalid_out(0) <= \<const0>\;
  sdm0finalout_out(3) <= \<const0>\;
  sdm0finalout_out(2) <= \<const0>\;
  sdm0finalout_out(1) <= \<const0>\;
  sdm0finalout_out(0) <= \<const0>\;
  sdm0testdata_out(14) <= \<const0>\;
  sdm0testdata_out(13) <= \<const0>\;
  sdm0testdata_out(12) <= \<const0>\;
  sdm0testdata_out(11) <= \<const0>\;
  sdm0testdata_out(10) <= \<const0>\;
  sdm0testdata_out(9) <= \<const0>\;
  sdm0testdata_out(8) <= \<const0>\;
  sdm0testdata_out(7) <= \<const0>\;
  sdm0testdata_out(6) <= \<const0>\;
  sdm0testdata_out(5) <= \<const0>\;
  sdm0testdata_out(4) <= \<const0>\;
  sdm0testdata_out(3) <= \<const0>\;
  sdm0testdata_out(2) <= \<const0>\;
  sdm0testdata_out(1) <= \<const0>\;
  sdm0testdata_out(0) <= \<const0>\;
  sdm1finalout_out(3) <= \<const0>\;
  sdm1finalout_out(2) <= \<const0>\;
  sdm1finalout_out(1) <= \<const0>\;
  sdm1finalout_out(0) <= \<const0>\;
  sdm1testdata_out(14) <= \<const0>\;
  sdm1testdata_out(13) <= \<const0>\;
  sdm1testdata_out(12) <= \<const0>\;
  sdm1testdata_out(11) <= \<const0>\;
  sdm1testdata_out(10) <= \<const0>\;
  sdm1testdata_out(9) <= \<const0>\;
  sdm1testdata_out(8) <= \<const0>\;
  sdm1testdata_out(7) <= \<const0>\;
  sdm1testdata_out(6) <= \<const0>\;
  sdm1testdata_out(5) <= \<const0>\;
  sdm1testdata_out(4) <= \<const0>\;
  sdm1testdata_out(3) <= \<const0>\;
  sdm1testdata_out(2) <= \<const0>\;
  sdm1testdata_out(1) <= \<const0>\;
  sdm1testdata_out(0) <= \<const0>\;
  tcongpo_out(9) <= \<const0>\;
  tcongpo_out(8) <= \<const0>\;
  tcongpo_out(7) <= \<const0>\;
  tcongpo_out(6) <= \<const0>\;
  tcongpo_out(5) <= \<const0>\;
  tcongpo_out(4) <= \<const0>\;
  tcongpo_out(3) <= \<const0>\;
  tcongpo_out(2) <= \<const0>\;
  tcongpo_out(1) <= \<const0>\;
  tcongpo_out(0) <= \<const0>\;
  tconrsvdout0_out(0) <= \<const0>\;
  txbufstatus_out(1) <= \<const0>\;
  txbufstatus_out(0) <= \<const0>\;
  txcomfinish_out(0) <= \<const0>\;
  txdccdone_out(0) <= \<const0>\;
  txdlysresetdone_out(0) <= \<const0>\;
  txoutclk_out(0) <= \<const0>\;
  txoutclkfabric_out(0) <= \<const0>\;
  txoutclkpcs_out(0) <= \<const0>\;
  txphaligndone_out(0) <= \<const0>\;
  txphinitdone_out(0) <= \<const0>\;
  txqpisenn_out(0) <= \<const0>\;
  txqpisenp_out(0) <= \<const0>\;
  txratedone_out(0) <= \<const0>\;
  txsyncdone_out(0) <= \<const0>\;
  txsyncout_out(0) <= \<const0>\;
  ubdaddr_out(0) <= \<const0>\;
  ubden_out(0) <= \<const0>\;
  ubdi_out(0) <= \<const0>\;
  ubdwe_out(0) <= \<const0>\;
  ubmdmtdo_out(0) <= \<const0>\;
  ubrsvdout_out(0) <= \<const0>\;
  ubtxuart_out(0) <= \<const0>\;
GND: unisim.vcomponents.GND
     port map (
      G => \<const0>\
    );
\gen_gtwizard_gthe4_top.taxi_eth_phy_25g_us_gth_ll_full_gtwizard_gthe4_inst\: entity work.taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_gthe4
     port map (
      drpaddr_common_in(15 downto 0) => drpaddr_common_in(15 downto 0),
      drpaddr_in(9 downto 0) => drpaddr_in(9 downto 0),
      drpclk_common_in(0) => drpclk_common_in(0),
      drpclk_in(0) => drpclk_in(0),
      drpdi_common_in(15 downto 0) => drpdi_common_in(15 downto 0),
      drpdi_in(15 downto 0) => drpdi_in(15 downto 0),
      drpdo_common_out(15 downto 0) => drpdo_common_out(15 downto 0),
      drpdo_out(15 downto 0) => drpdo_out(15 downto 0),
      drpen_common_in(0) => drpen_common_in(0),
      drpen_in(0) => drpen_in(0),
      drprdy_common_out(0) => drprdy_common_out(0),
      drprdy_out(0) => drprdy_out(0),
      drpwe_common_in(0) => drpwe_common_in(0),
      drpwe_in(0) => drpwe_in(0),
      eyescanreset_in(0) => eyescanreset_in(0),
      gthrxn_in(0) => gthrxn_in(0),
      gthrxp_in(0) => gthrxp_in(0),
      gthtxn_out(0) => gthtxn_out(0),
      gthtxp_out(0) => gthtxp_out(0),
      gtpowergood_out(0) => gtpowergood_out(0),
      gtrefclk00_in(0) => gtrefclk00_in(0),
      gtrefclk01_in(0) => gtrefclk01_in(0),
      gtrxreset_in(0) => gtrxreset_in(0),
      gttxreset_in(0) => gttxreset_in(0),
      gtwiz_buffbypass_rx_done_out(0) => gtwiz_buffbypass_rx_done_out(0),
      gtwiz_buffbypass_rx_error_out(0) => gtwiz_buffbypass_rx_error_out(0),
      gtwiz_buffbypass_rx_reset_in(0) => gtwiz_buffbypass_rx_reset_in(0),
      gtwiz_buffbypass_rx_start_user_in(0) => gtwiz_buffbypass_rx_start_user_in(0),
      gtwiz_buffbypass_tx_done_out(0) => gtwiz_buffbypass_tx_done_out(0),
      gtwiz_buffbypass_tx_error_out(0) => gtwiz_buffbypass_tx_error_out(0),
      gtwiz_buffbypass_tx_reset_in(0) => gtwiz_buffbypass_tx_reset_in(0),
      gtwiz_buffbypass_tx_start_user_in(0) => gtwiz_buffbypass_tx_start_user_in(0),
      gtwiz_reset_rx_done_in(0) => gtwiz_reset_rx_done_in(0),
      gtwiz_reset_tx_done_in(0) => gtwiz_reset_tx_done_in(0),
      gtwiz_userclk_rx_active_out(0) => gtwiz_userclk_rx_active_out(0),
      gtwiz_userclk_rx_reset_in(0) => gtwiz_userclk_rx_reset_in(0),
      gtwiz_userclk_rx_srcclk_out(0) => gtwiz_userclk_rx_srcclk_out(0),
      gtwiz_userclk_rx_usrclk2_out(0) => gtwiz_userclk_rx_usrclk2_out(0),
      gtwiz_userclk_rx_usrclk_out(0) => gtwiz_userclk_rx_usrclk_out(0),
      gtwiz_userclk_tx_active_out(0) => gtwiz_userclk_tx_active_out(0),
      gtwiz_userclk_tx_reset_in(0) => gtwiz_userclk_tx_reset_in(0),
      gtwiz_userclk_tx_srcclk_out(0) => gtwiz_userclk_tx_srcclk_out(0),
      gtwiz_userclk_tx_usrclk2_out(0) => gtwiz_userclk_tx_usrclk2_out(0),
      gtwiz_userclk_tx_usrclk_out(0) => gtwiz_userclk_tx_usrclk_out(0),
      gtwiz_userdata_rx_out(63 downto 0) => gtwiz_userdata_rx_out(63 downto 0),
      gtwiz_userdata_tx_in(63 downto 0) => gtwiz_userdata_tx_in(63 downto 0),
      pcierateqpll0_in(2 downto 0) => pcierateqpll0_in(2 downto 0),
      pcierateqpll1_in(2 downto 0) => pcierateqpll1_in(2 downto 0),
      qpll0lock_out(0) => qpll0lock_out(0),
      qpll0outclk_out(0) => qpll0outclk_out(0),
      qpll0outrefclk_out(0) => qpll0outrefclk_out(0),
      qpll0pd_in(0) => qpll0pd_in(0),
      qpll0reset_in(0) => qpll0reset_in(0),
      qpll1lock_out(0) => qpll1lock_out(0),
      qpll1outclk_out(0) => qpll1outclk_out(0),
      qpll1outrefclk_out(0) => qpll1outrefclk_out(0),
      qpll1pd_in(0) => qpll1pd_in(0),
      qpll1reset_in(0) => qpll1reset_in(0),
      rxcdrhold_in(0) => rxcdrhold_in(0),
      rxcdrlock_out(0) => rxcdrlock_out(0),
      rxcdrovrden_in(0) => rxcdrovrden_in(0),
      rxdatavalid_out(1 downto 0) => rxdatavalid_out(1 downto 0),
      rxdfelpmreset_in(0) => rxdfelpmreset_in(0),
      rxgearboxslip_in(0) => rxgearboxslip_in(0),
      rxheader_out(5 downto 0) => rxheader_out(5 downto 0),
      rxheadervalid_out(1 downto 0) => rxheadervalid_out(1 downto 0),
      rxlpmen_in(0) => rxlpmen_in(0),
      rxpcsreset_in(0) => rxpcsreset_in(0),
      rxpd_in(1 downto 0) => rxpd_in(1 downto 0),
      rxpllclksel_in(1 downto 0) => rxpllclksel_in(1 downto 0),
      rxpmareset_in(0) => rxpmareset_in(0),
      rxpmaresetdone_out(0) => rxpmaresetdone_out(0),
      rxpolarity_in(0) => rxpolarity_in(0),
      rxprgdivresetdone_out(0) => rxprgdivresetdone_out(0),
      rxprogdivreset_in(0) => rxprogdivreset_in(0),
      rxresetdone_out(0) => rxresetdone_out(0),
      rxstartofseq_out(1 downto 0) => rxstartofseq_out(1 downto 0),
      rxsysclksel_in(1 downto 0) => rxsysclksel_in(1 downto 0),
      rxuserrdy_in(0) => rxuserrdy_in(0),
      txdiffctrl_in(4 downto 0) => txdiffctrl_in(4 downto 0),
      txelecidle_in(0) => txelecidle_in(0),
      txheader_in(5 downto 0) => txheader_in(5 downto 0),
      txinhibit_in(0) => txinhibit_in(0),
      txmaincursor_in(6 downto 0) => txmaincursor_in(6 downto 0),
      txpcsreset_in(0) => txpcsreset_in(0),
      txpd_in(1 downto 0) => txpd_in(1 downto 0),
      txpdelecidlemode_in(0) => txpdelecidlemode_in(0),
      txpllclksel_in(1 downto 0) => txpllclksel_in(1 downto 0),
      txpmareset_in(0) => txpmareset_in(0),
      txpmaresetdone_out(0) => txpmaresetdone_out(0),
      txpolarity_in(0) => txpolarity_in(0),
      txpostcursor_in(4 downto 0) => txpostcursor_in(4 downto 0),
      txprecursor_in(4 downto 0) => txprecursor_in(4 downto 0),
      txprgdivresetdone_out(0) => txprgdivresetdone_out(0),
      txprogdivreset_in(0) => txprogdivreset_in(0),
      txresetdone_out(0) => txresetdone_out(0),
      txsequence_in(6 downto 0) => txsequence_in(6 downto 0),
      txsysclksel_in(1 downto 0) => txsysclksel_in(1 downto 0),
      txuserrdy_in(0) => txuserrdy_in(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity taxi_eth_phy_25g_us_gth_ll_full is
  port (
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
    gtwiz_buffbypass_tx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_start_user_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_tx_error_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_start_user_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_buffbypass_rx_error_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_done_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_tx_in : in STD_LOGIC_VECTOR ( 63 downto 0 );
    gtwiz_userdata_rx_out : out STD_LOGIC_VECTOR ( 63 downto 0 );
    drpaddr_common_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drpclk_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpdi_common_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drpen_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_common_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk00_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtrefclk01_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    pcierateqpll0_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    pcierateqpll1_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    qpll0pd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1pd_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1reset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpdo_common_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drprdy_common_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0lock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1lock_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll1outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
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
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of taxi_eth_phy_25g_us_gth_ll_full : entity is true;
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of taxi_eth_phy_25g_us_gth_ll_full : entity is "taxi_eth_phy_25g_us_gth_ll_full,taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top,{}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of taxi_eth_phy_25g_us_gth_ll_full : entity is "yes";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of taxi_eth_phy_25g_us_gth_ll_full : entity is "taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top,Vivado 2023.2";
end taxi_eth_phy_25g_us_gth_ll_full;

architecture STRUCTURE of taxi_eth_phy_25g_us_gth_ll_full is
  signal NLW_inst_bufgtce_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_bufgtcemask_out_UNCONNECTED : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal NLW_inst_bufgtdiv_out_UNCONNECTED : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal NLW_inst_bufgtreset_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_bufgtrstmask_out_UNCONNECTED : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal NLW_inst_cpllfbclklost_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_cplllock_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_cpllrefclklost_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_dmonitorout_out_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal NLW_inst_dmonitoroutclk_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_eyescandataerror_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_gtrefclkmonitor_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_gtwiz_reset_qpll0reset_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_gtwiz_reset_qpll1reset_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_gtwiz_reset_rx_cdr_stable_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_gtwiz_reset_rx_done_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_gtwiz_reset_tx_done_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_gtytxn_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_gtytxp_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_pcierategen3_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_pcierateidle_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_pcierateqpllpd_out_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_inst_pcierateqpllreset_out_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_inst_pciesynctxsyncdone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_pcieusergen3rdy_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_pcieuserphystatusrst_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_pcieuserratestart_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_pcsrsvdout_out_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal NLW_inst_phystatus_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_pinrsrvdas_out_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal NLW_inst_pmarsvdout0_out_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_inst_pmarsvdout1_out_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_inst_powerpresent_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_qpll0fbclklost_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_qpll0refclklost_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_qpll1fbclklost_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_qpll1refclklost_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_qplldmonitor0_out_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_inst_qplldmonitor1_out_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_inst_refclkoutmonitor0_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_refclkoutmonitor1_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_resetexception_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxbufstatus_out_UNCONNECTED : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal NLW_inst_rxbyteisaligned_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxbyterealign_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxcdrphdone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxchanbondseq_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxchanisaligned_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxchanrealign_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxchbondo_out_UNCONNECTED : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal NLW_inst_rxckcaldone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxclkcorcnt_out_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_inst_rxcominitdet_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxcommadet_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxcomsasdet_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxcomwakedet_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxctrl0_out_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal NLW_inst_rxctrl1_out_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal NLW_inst_rxctrl2_out_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_inst_rxctrl3_out_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_inst_rxdata_out_UNCONNECTED : STD_LOGIC_VECTOR ( 127 downto 0 );
  signal NLW_inst_rxdataextendrsvd_out_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_inst_rxdlysresetdone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxelecidle_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxlfpstresetdet_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxlfpsu2lpexitdet_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxlfpsu3wakedet_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxmonitorout_out_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_inst_rxosintdone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxosintstarted_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxosintstrobedone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxosintstrobestarted_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxoutclk_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxoutclkfabric_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxoutclkpcs_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxphaligndone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxphalignerr_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxprbserr_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxprbslocked_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxqpisenn_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxqpisenp_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxratedone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxrecclk0_sel_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxrecclk0sel_out_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_inst_rxrecclk1_sel_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxrecclk1sel_out_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_inst_rxrecclkout_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxsliderdy_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxslipdone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxslipoutclkrdy_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxslippmardy_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxstatus_out_UNCONNECTED : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal NLW_inst_rxsyncdone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxsyncout_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_rxvalid_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_sdm0finalout_out_UNCONNECTED : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal NLW_inst_sdm0testdata_out_UNCONNECTED : STD_LOGIC_VECTOR ( 14 downto 0 );
  signal NLW_inst_sdm1finalout_out_UNCONNECTED : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal NLW_inst_sdm1testdata_out_UNCONNECTED : STD_LOGIC_VECTOR ( 14 downto 0 );
  signal NLW_inst_tcongpo_out_UNCONNECTED : STD_LOGIC_VECTOR ( 9 downto 0 );
  signal NLW_inst_tconrsvdout0_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txbufstatus_out_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_inst_txcomfinish_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txdccdone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txdlysresetdone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txoutclk_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txoutclkfabric_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txoutclkpcs_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txphaligndone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txphinitdone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txqpisenn_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txqpisenp_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txratedone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txsyncdone_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_txsyncout_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_ubdaddr_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_ubden_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_ubdi_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_ubdwe_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_ubmdmtdo_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_ubrsvdout_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_inst_ubtxuart_out_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  attribute C_CHANNEL_ENABLE : string;
  attribute C_CHANNEL_ENABLE of inst : label is "192'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001";
  attribute C_COMMON_SCALING_FACTOR : integer;
  attribute C_COMMON_SCALING_FACTOR of inst : label is 1;
  attribute C_CPLL_VCO_FREQUENCY : string;
  attribute C_CPLL_VCO_FREQUENCY of inst : label is "2578.125000";
  attribute C_ENABLE_COMMON_USRCLK : integer;
  attribute C_ENABLE_COMMON_USRCLK of inst : label is 0;
  attribute C_FORCE_COMMONS : integer;
  attribute C_FORCE_COMMONS of inst : label is 0;
  attribute C_FREERUN_FREQUENCY : string;
  attribute C_FREERUN_FREQUENCY of inst : label is "125.000000";
  attribute C_GT_REV : integer;
  attribute C_GT_REV of inst : label is 57;
  attribute C_GT_TYPE : integer;
  attribute C_GT_TYPE of inst : label is 2;
  attribute C_INCLUDE_CPLL_CAL : integer;
  attribute C_INCLUDE_CPLL_CAL of inst : label is 2;
  attribute C_LOCATE_COMMON : integer;
  attribute C_LOCATE_COMMON of inst : label is 0;
  attribute C_LOCATE_IN_SYSTEM_IBERT_CORE : integer;
  attribute C_LOCATE_IN_SYSTEM_IBERT_CORE of inst : label is 2;
  attribute C_LOCATE_RESET_CONTROLLER : integer;
  attribute C_LOCATE_RESET_CONTROLLER of inst : label is 1;
  attribute C_LOCATE_RX_BUFFER_BYPASS_CONTROLLER : integer;
  attribute C_LOCATE_RX_BUFFER_BYPASS_CONTROLLER of inst : label is 0;
  attribute C_LOCATE_RX_USER_CLOCKING : integer;
  attribute C_LOCATE_RX_USER_CLOCKING of inst : label is 0;
  attribute C_LOCATE_TX_BUFFER_BYPASS_CONTROLLER : integer;
  attribute C_LOCATE_TX_BUFFER_BYPASS_CONTROLLER of inst : label is 0;
  attribute C_LOCATE_TX_USER_CLOCKING : integer;
  attribute C_LOCATE_TX_USER_CLOCKING of inst : label is 0;
  attribute C_LOCATE_USER_DATA_WIDTH_SIZING : integer;
  attribute C_LOCATE_USER_DATA_WIDTH_SIZING of inst : label is 0;
  attribute C_PCIE_CORECLK_FREQ : integer;
  attribute C_PCIE_CORECLK_FREQ of inst : label is 250;
  attribute C_PCIE_ENABLE : integer;
  attribute C_PCIE_ENABLE of inst : label is 0;
  attribute C_RESET_CONTROLLER_INSTANCE_CTRL : integer;
  attribute C_RESET_CONTROLLER_INSTANCE_CTRL of inst : label is 0;
  attribute C_RESET_SEQUENCE_INTERVAL : integer;
  attribute C_RESET_SEQUENCE_INTERVAL of inst : label is 0;
  attribute C_RX_BUFFBYPASS_MODE : integer;
  attribute C_RX_BUFFBYPASS_MODE of inst : label is 0;
  attribute C_RX_BUFFER_BYPASS_INSTANCE_CTRL : integer;
  attribute C_RX_BUFFER_BYPASS_INSTANCE_CTRL of inst : label is 0;
  attribute C_RX_BUFFER_MODE : integer;
  attribute C_RX_BUFFER_MODE of inst : label is 0;
  attribute C_RX_CB_DISP : string;
  attribute C_RX_CB_DISP of inst : label is "8'b00000000";
  attribute C_RX_CB_K : string;
  attribute C_RX_CB_K of inst : label is "8'b00000000";
  attribute C_RX_CB_LEN_SEQ : integer;
  attribute C_RX_CB_LEN_SEQ of inst : label is 1;
  attribute C_RX_CB_MAX_LEVEL : integer;
  attribute C_RX_CB_MAX_LEVEL of inst : label is 1;
  attribute C_RX_CB_NUM_SEQ : integer;
  attribute C_RX_CB_NUM_SEQ of inst : label is 0;
  attribute C_RX_CB_VAL : string;
  attribute C_RX_CB_VAL of inst : label is "80'b00000000000000000000000000000000000000000000000000000000000000000000000000000000";
  attribute C_RX_CC_DISP : string;
  attribute C_RX_CC_DISP of inst : label is "8'b00000000";
  attribute C_RX_CC_ENABLE : integer;
  attribute C_RX_CC_ENABLE of inst : label is 0;
  attribute C_RX_CC_K : string;
  attribute C_RX_CC_K of inst : label is "8'b00000000";
  attribute C_RX_CC_LEN_SEQ : integer;
  attribute C_RX_CC_LEN_SEQ of inst : label is 1;
  attribute C_RX_CC_NUM_SEQ : integer;
  attribute C_RX_CC_NUM_SEQ of inst : label is 0;
  attribute C_RX_CC_PERIODICITY : integer;
  attribute C_RX_CC_PERIODICITY of inst : label is 5000;
  attribute C_RX_CC_VAL : string;
  attribute C_RX_CC_VAL of inst : label is "80'b00000000000000000000000000000000000000000000000000000000000000000000000000000000";
  attribute C_RX_COMMA_M_ENABLE : integer;
  attribute C_RX_COMMA_M_ENABLE of inst : label is 0;
  attribute C_RX_COMMA_M_VAL : string;
  attribute C_RX_COMMA_M_VAL of inst : label is "10'b1010000011";
  attribute C_RX_COMMA_P_ENABLE : integer;
  attribute C_RX_COMMA_P_ENABLE of inst : label is 0;
  attribute C_RX_COMMA_P_VAL : string;
  attribute C_RX_COMMA_P_VAL of inst : label is "10'b0101111100";
  attribute C_RX_DATA_DECODING : integer;
  attribute C_RX_DATA_DECODING of inst : label is 2;
  attribute C_RX_ENABLE : integer;
  attribute C_RX_ENABLE of inst : label is 1;
  attribute C_RX_INT_DATA_WIDTH : integer;
  attribute C_RX_INT_DATA_WIDTH of inst : label is 32;
  attribute C_RX_LINE_RATE : string;
  attribute C_RX_LINE_RATE of inst : label is "10.312500";
  attribute C_RX_MASTER_CHANNEL_IDX : integer;
  attribute C_RX_MASTER_CHANNEL_IDX of inst : label is 0;
  attribute C_RX_OUTCLK_BUFG_GT_DIV : integer;
  attribute C_RX_OUTCLK_BUFG_GT_DIV of inst : label is 1;
  attribute C_RX_OUTCLK_FREQUENCY : string;
  attribute C_RX_OUTCLK_FREQUENCY of inst : label is "322.265625";
  attribute C_RX_OUTCLK_SOURCE : integer;
  attribute C_RX_OUTCLK_SOURCE of inst : label is 1;
  attribute C_RX_PLL_TYPE : integer;
  attribute C_RX_PLL_TYPE of inst : label is 0;
  attribute C_RX_RECCLK_OUTPUT : string;
  attribute C_RX_RECCLK_OUTPUT of inst : label is "192'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
  attribute C_RX_REFCLK_FREQUENCY : string;
  attribute C_RX_REFCLK_FREQUENCY of inst : label is "156.250000";
  attribute C_RX_SLIDE_MODE : integer;
  attribute C_RX_SLIDE_MODE of inst : label is 0;
  attribute C_RX_USER_CLOCKING_CONTENTS : integer;
  attribute C_RX_USER_CLOCKING_CONTENTS of inst : label is 0;
  attribute C_RX_USER_CLOCKING_INSTANCE_CTRL : integer;
  attribute C_RX_USER_CLOCKING_INSTANCE_CTRL of inst : label is 0;
  attribute C_RX_USER_CLOCKING_RATIO_FSRC_FUSRCLK : integer;
  attribute C_RX_USER_CLOCKING_RATIO_FSRC_FUSRCLK of inst : label is 1;
  attribute C_RX_USER_CLOCKING_RATIO_FUSRCLK_FUSRCLK2 : integer;
  attribute C_RX_USER_CLOCKING_RATIO_FUSRCLK_FUSRCLK2 of inst : label is 2;
  attribute C_RX_USER_CLOCKING_SOURCE : integer;
  attribute C_RX_USER_CLOCKING_SOURCE of inst : label is 0;
  attribute C_RX_USER_DATA_WIDTH : integer;
  attribute C_RX_USER_DATA_WIDTH of inst : label is 64;
  attribute C_RX_USRCLK2_FREQUENCY : string;
  attribute C_RX_USRCLK2_FREQUENCY of inst : label is "161.132813";
  attribute C_RX_USRCLK_FREQUENCY : string;
  attribute C_RX_USRCLK_FREQUENCY of inst : label is "322.265625";
  attribute C_SECONDARY_QPLL_ENABLE : integer;
  attribute C_SECONDARY_QPLL_ENABLE of inst : label is 1;
  attribute C_SECONDARY_QPLL_REFCLK_FREQUENCY : string;
  attribute C_SECONDARY_QPLL_REFCLK_FREQUENCY of inst : label is "156.250000";
  attribute C_SIM_CPLL_CAL_BYPASS : integer;
  attribute C_SIM_CPLL_CAL_BYPASS of inst : label is 1;
  attribute C_TOTAL_NUM_CHANNELS : integer;
  attribute C_TOTAL_NUM_CHANNELS of inst : label is 1;
  attribute C_TOTAL_NUM_COMMONS : integer;
  attribute C_TOTAL_NUM_COMMONS of inst : label is 1;
  attribute C_TOTAL_NUM_COMMONS_EXAMPLE : integer;
  attribute C_TOTAL_NUM_COMMONS_EXAMPLE of inst : label is 0;
  attribute C_TXPROGDIV_FREQ_ENABLE : integer;
  attribute C_TXPROGDIV_FREQ_ENABLE of inst : label is 0;
  attribute C_TXPROGDIV_FREQ_SOURCE : integer;
  attribute C_TXPROGDIV_FREQ_SOURCE of inst : label is 0;
  attribute C_TXPROGDIV_FREQ_VAL : string;
  attribute C_TXPROGDIV_FREQ_VAL of inst : label is "322.265625";
  attribute C_TX_BUFFBYPASS_MODE : integer;
  attribute C_TX_BUFFBYPASS_MODE of inst : label is 0;
  attribute C_TX_BUFFER_BYPASS_INSTANCE_CTRL : integer;
  attribute C_TX_BUFFER_BYPASS_INSTANCE_CTRL of inst : label is 0;
  attribute C_TX_BUFFER_MODE : integer;
  attribute C_TX_BUFFER_MODE of inst : label is 0;
  attribute C_TX_DATA_ENCODING : integer;
  attribute C_TX_DATA_ENCODING of inst : label is 2;
  attribute C_TX_ENABLE : integer;
  attribute C_TX_ENABLE of inst : label is 1;
  attribute C_TX_INT_DATA_WIDTH : integer;
  attribute C_TX_INT_DATA_WIDTH of inst : label is 32;
  attribute C_TX_LINE_RATE : string;
  attribute C_TX_LINE_RATE of inst : label is "10.312500";
  attribute C_TX_MASTER_CHANNEL_IDX : integer;
  attribute C_TX_MASTER_CHANNEL_IDX of inst : label is 0;
  attribute C_TX_OUTCLK_BUFG_GT_DIV : integer;
  attribute C_TX_OUTCLK_BUFG_GT_DIV of inst : label is 1;
  attribute C_TX_OUTCLK_FREQUENCY : string;
  attribute C_TX_OUTCLK_FREQUENCY of inst : label is "322.265625";
  attribute C_TX_OUTCLK_SOURCE : integer;
  attribute C_TX_OUTCLK_SOURCE of inst : label is 4;
  attribute C_TX_PLL_TYPE : integer;
  attribute C_TX_PLL_TYPE of inst : label is 0;
  attribute C_TX_REFCLK_FREQUENCY : string;
  attribute C_TX_REFCLK_FREQUENCY of inst : label is "156.250000";
  attribute C_TX_USER_CLOCKING_CONTENTS : integer;
  attribute C_TX_USER_CLOCKING_CONTENTS of inst : label is 0;
  attribute C_TX_USER_CLOCKING_INSTANCE_CTRL : integer;
  attribute C_TX_USER_CLOCKING_INSTANCE_CTRL of inst : label is 0;
  attribute C_TX_USER_CLOCKING_RATIO_FSRC_FUSRCLK : integer;
  attribute C_TX_USER_CLOCKING_RATIO_FSRC_FUSRCLK of inst : label is 1;
  attribute C_TX_USER_CLOCKING_RATIO_FUSRCLK_FUSRCLK2 : integer;
  attribute C_TX_USER_CLOCKING_RATIO_FUSRCLK_FUSRCLK2 of inst : label is 2;
  attribute C_TX_USER_CLOCKING_SOURCE : integer;
  attribute C_TX_USER_CLOCKING_SOURCE of inst : label is 0;
  attribute C_TX_USER_DATA_WIDTH : integer;
  attribute C_TX_USER_DATA_WIDTH of inst : label is 64;
  attribute C_TX_USRCLK2_FREQUENCY : string;
  attribute C_TX_USRCLK2_FREQUENCY of inst : label is "161.132813";
  attribute C_TX_USRCLK_FREQUENCY : string;
  attribute C_TX_USRCLK_FREQUENCY of inst : label is "322.265625";
  attribute C_USER_GTPOWERGOOD_DELAY_EN : integer;
  attribute C_USER_GTPOWERGOOD_DELAY_EN of inst : label is 1;
begin
inst: entity work.taxi_eth_phy_25g_us_gth_ll_full_taxi_eth_phy_25g_us_gth_ll_full_gtwizard_top
     port map (
      bgbypassb_in(0) => '1',
      bgmonitorenb_in(0) => '1',
      bgpdb_in(0) => '1',
      bgrcalovrd_in(4 downto 0) => B"11111",
      bgrcalovrdenb_in(0) => '1',
      bufgtce_out(0) => NLW_inst_bufgtce_out_UNCONNECTED(0),
      bufgtcemask_out(2 downto 0) => NLW_inst_bufgtcemask_out_UNCONNECTED(2 downto 0),
      bufgtdiv_out(8 downto 0) => NLW_inst_bufgtdiv_out_UNCONNECTED(8 downto 0),
      bufgtreset_out(0) => NLW_inst_bufgtreset_out_UNCONNECTED(0),
      bufgtrstmask_out(2 downto 0) => NLW_inst_bufgtrstmask_out_UNCONNECTED(2 downto 0),
      cdrstepdir_in(0) => '0',
      cdrstepsq_in(0) => '0',
      cdrstepsx_in(0) => '0',
      cfgreset_in(0) => '0',
      clkrsvd0_in(0) => '0',
      clkrsvd1_in(0) => '0',
      cpllfbclklost_out(0) => NLW_inst_cpllfbclklost_out_UNCONNECTED(0),
      cpllfreqlock_in(0) => '0',
      cplllock_out(0) => NLW_inst_cplllock_out_UNCONNECTED(0),
      cplllockdetclk_in(0) => '0',
      cplllocken_in(0) => '0',
      cpllpd_in(0) => '1',
      cpllrefclklost_out(0) => NLW_inst_cpllrefclklost_out_UNCONNECTED(0),
      cpllrefclksel_in(2 downto 0) => B"001",
      cpllreset_in(0) => '1',
      dmonfiforeset_in(0) => '0',
      dmonitorclk_in(0) => '0',
      dmonitorout_out(15 downto 0) => NLW_inst_dmonitorout_out_UNCONNECTED(15 downto 0),
      dmonitoroutclk_out(0) => NLW_inst_dmonitoroutclk_out_UNCONNECTED(0),
      drpaddr_common_in(15 downto 0) => drpaddr_common_in(15 downto 0),
      drpaddr_in(9 downto 0) => drpaddr_in(9 downto 0),
      drpclk_common_in(0) => drpclk_common_in(0),
      drpclk_in(0) => drpclk_in(0),
      drpdi_common_in(15 downto 0) => drpdi_common_in(15 downto 0),
      drpdi_in(15 downto 0) => drpdi_in(15 downto 0),
      drpdo_common_out(15 downto 0) => drpdo_common_out(15 downto 0),
      drpdo_out(15 downto 0) => drpdo_out(15 downto 0),
      drpen_common_in(0) => drpen_common_in(0),
      drpen_in(0) => drpen_in(0),
      drprdy_common_out(0) => drprdy_common_out(0),
      drprdy_out(0) => drprdy_out(0),
      drprst_in(0) => '0',
      drpwe_common_in(0) => drpwe_common_in(0),
      drpwe_in(0) => drpwe_in(0),
      elpcaldvorwren_in(0) => '0',
      elpcalpaorwren_in(0) => '0',
      evoddphicaldone_in(0) => '0',
      evoddphicalstart_in(0) => '0',
      evoddphidrden_in(0) => '0',
      evoddphidwren_in(0) => '0',
      evoddphixrden_in(0) => '0',
      evoddphixwren_in(0) => '0',
      eyescandataerror_out(0) => NLW_inst_eyescandataerror_out_UNCONNECTED(0),
      eyescanmode_in(0) => '0',
      eyescanreset_in(0) => eyescanreset_in(0),
      eyescantrigger_in(0) => '0',
      freqos_in(0) => '0',
      gtgrefclk0_in(0) => '0',
      gtgrefclk1_in(0) => '0',
      gtgrefclk_in(0) => '0',
      gthrxn_in(0) => gthrxn_in(0),
      gthrxp_in(0) => gthrxp_in(0),
      gthtxn_out(0) => gthtxn_out(0),
      gthtxp_out(0) => gthtxp_out(0),
      gtnorthrefclk00_in(0) => '0',
      gtnorthrefclk01_in(0) => '0',
      gtnorthrefclk0_in(0) => '0',
      gtnorthrefclk10_in(0) => '0',
      gtnorthrefclk11_in(0) => '0',
      gtnorthrefclk1_in(0) => '0',
      gtpowergood_out(0) => gtpowergood_out(0),
      gtrefclk00_in(0) => gtrefclk00_in(0),
      gtrefclk01_in(0) => gtrefclk01_in(0),
      gtrefclk0_in(0) => '0',
      gtrefclk10_in(0) => '0',
      gtrefclk11_in(0) => '0',
      gtrefclk1_in(0) => '0',
      gtrefclkmonitor_out(0) => NLW_inst_gtrefclkmonitor_out_UNCONNECTED(0),
      gtresetsel_in(0) => '0',
      gtrsvd_in(15 downto 0) => B"0000000000000000",
      gtrxreset_in(0) => gtrxreset_in(0),
      gtrxresetsel_in(0) => '0',
      gtsouthrefclk00_in(0) => '0',
      gtsouthrefclk01_in(0) => '0',
      gtsouthrefclk0_in(0) => '0',
      gtsouthrefclk10_in(0) => '0',
      gtsouthrefclk11_in(0) => '0',
      gtsouthrefclk1_in(0) => '0',
      gttxreset_in(0) => gttxreset_in(0),
      gttxresetsel_in(0) => '0',
      gtwiz_buffbypass_rx_done_out(0) => gtwiz_buffbypass_rx_done_out(0),
      gtwiz_buffbypass_rx_error_out(0) => gtwiz_buffbypass_rx_error_out(0),
      gtwiz_buffbypass_rx_reset_in(0) => gtwiz_buffbypass_rx_reset_in(0),
      gtwiz_buffbypass_rx_start_user_in(0) => gtwiz_buffbypass_rx_start_user_in(0),
      gtwiz_buffbypass_tx_done_out(0) => gtwiz_buffbypass_tx_done_out(0),
      gtwiz_buffbypass_tx_error_out(0) => gtwiz_buffbypass_tx_error_out(0),
      gtwiz_buffbypass_tx_reset_in(0) => gtwiz_buffbypass_tx_reset_in(0),
      gtwiz_buffbypass_tx_start_user_in(0) => gtwiz_buffbypass_tx_start_user_in(0),
      gtwiz_gthe3_cpll_cal_bufg_ce_in(0) => '0',
      gtwiz_gthe3_cpll_cal_cnt_tol_in(17 downto 0) => B"000000000000000000",
      gtwiz_gthe3_cpll_cal_txoutclk_period_in(17 downto 0) => B"000000000000000000",
      gtwiz_gthe4_cpll_cal_bufg_ce_in(0) => '0',
      gtwiz_gthe4_cpll_cal_cnt_tol_in(17 downto 0) => B"000000000000000000",
      gtwiz_gthe4_cpll_cal_txoutclk_period_in(17 downto 0) => B"000000000000000000",
      gtwiz_gtye4_cpll_cal_bufg_ce_in(0) => '0',
      gtwiz_gtye4_cpll_cal_cnt_tol_in(17 downto 0) => B"000000000000000000",
      gtwiz_gtye4_cpll_cal_txoutclk_period_in(17 downto 0) => B"000000000000000000",
      gtwiz_reset_all_in(0) => '0',
      gtwiz_reset_clk_freerun_in(0) => '0',
      gtwiz_reset_qpll0lock_in(0) => '0',
      gtwiz_reset_qpll0reset_out(0) => NLW_inst_gtwiz_reset_qpll0reset_out_UNCONNECTED(0),
      gtwiz_reset_qpll1lock_in(0) => '0',
      gtwiz_reset_qpll1reset_out(0) => NLW_inst_gtwiz_reset_qpll1reset_out_UNCONNECTED(0),
      gtwiz_reset_rx_cdr_stable_out(0) => NLW_inst_gtwiz_reset_rx_cdr_stable_out_UNCONNECTED(0),
      gtwiz_reset_rx_datapath_in(0) => '0',
      gtwiz_reset_rx_done_in(0) => gtwiz_reset_rx_done_in(0),
      gtwiz_reset_rx_done_out(0) => NLW_inst_gtwiz_reset_rx_done_out_UNCONNECTED(0),
      gtwiz_reset_rx_pll_and_datapath_in(0) => '0',
      gtwiz_reset_tx_datapath_in(0) => '0',
      gtwiz_reset_tx_done_in(0) => gtwiz_reset_tx_done_in(0),
      gtwiz_reset_tx_done_out(0) => NLW_inst_gtwiz_reset_tx_done_out_UNCONNECTED(0),
      gtwiz_reset_tx_pll_and_datapath_in(0) => '0',
      gtwiz_userclk_rx_active_in(0) => '0',
      gtwiz_userclk_rx_active_out(0) => gtwiz_userclk_rx_active_out(0),
      gtwiz_userclk_rx_reset_in(0) => gtwiz_userclk_rx_reset_in(0),
      gtwiz_userclk_rx_srcclk_out(0) => gtwiz_userclk_rx_srcclk_out(0),
      gtwiz_userclk_rx_usrclk2_out(0) => gtwiz_userclk_rx_usrclk2_out(0),
      gtwiz_userclk_rx_usrclk_out(0) => gtwiz_userclk_rx_usrclk_out(0),
      gtwiz_userclk_tx_active_in(0) => '0',
      gtwiz_userclk_tx_active_out(0) => gtwiz_userclk_tx_active_out(0),
      gtwiz_userclk_tx_reset_in(0) => gtwiz_userclk_tx_reset_in(0),
      gtwiz_userclk_tx_srcclk_out(0) => gtwiz_userclk_tx_srcclk_out(0),
      gtwiz_userclk_tx_usrclk2_out(0) => gtwiz_userclk_tx_usrclk2_out(0),
      gtwiz_userclk_tx_usrclk_out(0) => gtwiz_userclk_tx_usrclk_out(0),
      gtwiz_userdata_rx_out(63 downto 0) => gtwiz_userdata_rx_out(63 downto 0),
      gtwiz_userdata_tx_in(63 downto 0) => gtwiz_userdata_tx_in(63 downto 0),
      gtyrxn_in(0) => '0',
      gtyrxp_in(0) => '0',
      gtytxn_out(0) => NLW_inst_gtytxn_out_UNCONNECTED(0),
      gtytxp_out(0) => NLW_inst_gtytxp_out_UNCONNECTED(0),
      incpctrl_in(0) => '0',
      loopback_in(2 downto 0) => B"000",
      looprsvd_in(0) => '0',
      lpbkrxtxseren_in(0) => '0',
      lpbktxrxseren_in(0) => '0',
      pcieeqrxeqadaptdone_in(0) => '0',
      pcierategen3_out(0) => NLW_inst_pcierategen3_out_UNCONNECTED(0),
      pcierateidle_out(0) => NLW_inst_pcierateidle_out_UNCONNECTED(0),
      pcierateqpll0_in(2 downto 0) => pcierateqpll0_in(2 downto 0),
      pcierateqpll1_in(2 downto 0) => pcierateqpll1_in(2 downto 0),
      pcierateqpllpd_out(1 downto 0) => NLW_inst_pcierateqpllpd_out_UNCONNECTED(1 downto 0),
      pcierateqpllreset_out(1 downto 0) => NLW_inst_pcierateqpllreset_out_UNCONNECTED(1 downto 0),
      pcierstidle_in(0) => '0',
      pciersttxsyncstart_in(0) => '0',
      pciesynctxsyncdone_out(0) => NLW_inst_pciesynctxsyncdone_out_UNCONNECTED(0),
      pcieusergen3rdy_out(0) => NLW_inst_pcieusergen3rdy_out_UNCONNECTED(0),
      pcieuserphystatusrst_out(0) => NLW_inst_pcieuserphystatusrst_out_UNCONNECTED(0),
      pcieuserratedone_in(0) => '0',
      pcieuserratestart_out(0) => NLW_inst_pcieuserratestart_out_UNCONNECTED(0),
      pcsrsvdin2_in(0) => '0',
      pcsrsvdin_in(15 downto 0) => B"0000000000000000",
      pcsrsvdout_out(15 downto 0) => NLW_inst_pcsrsvdout_out_UNCONNECTED(15 downto 0),
      phystatus_out(0) => NLW_inst_phystatus_out_UNCONNECTED(0),
      pinrsrvdas_out(15 downto 0) => NLW_inst_pinrsrvdas_out_UNCONNECTED(15 downto 0),
      pmarsvd0_in(7 downto 0) => B"00000000",
      pmarsvd1_in(7 downto 0) => B"00000000",
      pmarsvdin_in(0) => '0',
      pmarsvdout0_out(7 downto 0) => NLW_inst_pmarsvdout0_out_UNCONNECTED(7 downto 0),
      pmarsvdout1_out(7 downto 0) => NLW_inst_pmarsvdout1_out_UNCONNECTED(7 downto 0),
      powerpresent_out(0) => NLW_inst_powerpresent_out_UNCONNECTED(0),
      qpll0clk_in(0) => '0',
      qpll0clkrsvd0_in(0) => '0',
      qpll0clkrsvd1_in(0) => '0',
      qpll0fbclklost_out(0) => NLW_inst_qpll0fbclklost_out_UNCONNECTED(0),
      qpll0fbdiv_in(7 downto 0) => B"00000000",
      qpll0freqlock_in(0) => '0',
      qpll0lock_out(0) => qpll0lock_out(0),
      qpll0lockdetclk_in(0) => '0',
      qpll0locken_in(0) => '1',
      qpll0outclk_out(0) => qpll0outclk_out(0),
      qpll0outrefclk_out(0) => qpll0outrefclk_out(0),
      qpll0pd_in(0) => qpll0pd_in(0),
      qpll0refclk_in(0) => '0',
      qpll0refclklost_out(0) => NLW_inst_qpll0refclklost_out_UNCONNECTED(0),
      qpll0refclksel_in(2 downto 0) => B"001",
      qpll0reset_in(0) => qpll0reset_in(0),
      qpll1clk_in(0) => '0',
      qpll1clkrsvd0_in(0) => '0',
      qpll1clkrsvd1_in(0) => '0',
      qpll1fbclklost_out(0) => NLW_inst_qpll1fbclklost_out_UNCONNECTED(0),
      qpll1fbdiv_in(7 downto 0) => B"00000000",
      qpll1freqlock_in(0) => '0',
      qpll1lock_out(0) => qpll1lock_out(0),
      qpll1lockdetclk_in(0) => '0',
      qpll1locken_in(0) => '1',
      qpll1outclk_out(0) => qpll1outclk_out(0),
      qpll1outrefclk_out(0) => qpll1outrefclk_out(0),
      qpll1pd_in(0) => qpll1pd_in(0),
      qpll1refclk_in(0) => '0',
      qpll1refclklost_out(0) => NLW_inst_qpll1refclklost_out_UNCONNECTED(0),
      qpll1refclksel_in(2 downto 0) => B"001",
      qpll1reset_in(0) => qpll1reset_in(0),
      qplldmonitor0_out(7 downto 0) => NLW_inst_qplldmonitor0_out_UNCONNECTED(7 downto 0),
      qplldmonitor1_out(7 downto 0) => NLW_inst_qplldmonitor1_out_UNCONNECTED(7 downto 0),
      qpllrsvd1_in(7 downto 0) => B"00000000",
      qpllrsvd2_in(4 downto 0) => B"00000",
      qpllrsvd3_in(4 downto 0) => B"00000",
      qpllrsvd4_in(7 downto 0) => B"00000000",
      rcalenb_in(0) => '1',
      refclkoutmonitor0_out(0) => NLW_inst_refclkoutmonitor0_out_UNCONNECTED(0),
      refclkoutmonitor1_out(0) => NLW_inst_refclkoutmonitor1_out_UNCONNECTED(0),
      resetexception_out(0) => NLW_inst_resetexception_out_UNCONNECTED(0),
      resetovrd_in(0) => '0',
      rstclkentx_in(0) => '0',
      rx8b10ben_in(0) => '0',
      rxafecfoken_in(0) => '1',
      rxbufreset_in(0) => '0',
      rxbufstatus_out(2 downto 0) => NLW_inst_rxbufstatus_out_UNCONNECTED(2 downto 0),
      rxbyteisaligned_out(0) => NLW_inst_rxbyteisaligned_out_UNCONNECTED(0),
      rxbyterealign_out(0) => NLW_inst_rxbyterealign_out_UNCONNECTED(0),
      rxcdrfreqreset_in(0) => '0',
      rxcdrhold_in(0) => rxcdrhold_in(0),
      rxcdrlock_out(0) => rxcdrlock_out(0),
      rxcdrovrden_in(0) => rxcdrovrden_in(0),
      rxcdrphdone_out(0) => NLW_inst_rxcdrphdone_out_UNCONNECTED(0),
      rxcdrreset_in(0) => '0',
      rxcdrresetrsv_in(0) => '0',
      rxchanbondseq_out(0) => NLW_inst_rxchanbondseq_out_UNCONNECTED(0),
      rxchanisaligned_out(0) => NLW_inst_rxchanisaligned_out_UNCONNECTED(0),
      rxchanrealign_out(0) => NLW_inst_rxchanrealign_out_UNCONNECTED(0),
      rxchbonden_in(0) => '0',
      rxchbondi_in(4 downto 0) => B"00000",
      rxchbondlevel_in(2 downto 0) => B"000",
      rxchbondmaster_in(0) => '0',
      rxchbondo_out(4 downto 0) => NLW_inst_rxchbondo_out_UNCONNECTED(4 downto 0),
      rxchbondslave_in(0) => '0',
      rxckcaldone_out(0) => NLW_inst_rxckcaldone_out_UNCONNECTED(0),
      rxckcalreset_in(0) => '0',
      rxckcalstart_in(6 downto 0) => B"0000000",
      rxclkcorcnt_out(1 downto 0) => NLW_inst_rxclkcorcnt_out_UNCONNECTED(1 downto 0),
      rxcominitdet_out(0) => NLW_inst_rxcominitdet_out_UNCONNECTED(0),
      rxcommadet_out(0) => NLW_inst_rxcommadet_out_UNCONNECTED(0),
      rxcommadeten_in(0) => '0',
      rxcomsasdet_out(0) => NLW_inst_rxcomsasdet_out_UNCONNECTED(0),
      rxcomwakedet_out(0) => NLW_inst_rxcomwakedet_out_UNCONNECTED(0),
      rxctrl0_out(15 downto 0) => NLW_inst_rxctrl0_out_UNCONNECTED(15 downto 0),
      rxctrl1_out(15 downto 0) => NLW_inst_rxctrl1_out_UNCONNECTED(15 downto 0),
      rxctrl2_out(7 downto 0) => NLW_inst_rxctrl2_out_UNCONNECTED(7 downto 0),
      rxctrl3_out(7 downto 0) => NLW_inst_rxctrl3_out_UNCONNECTED(7 downto 0),
      rxdata_out(127 downto 0) => NLW_inst_rxdata_out_UNCONNECTED(127 downto 0),
      rxdataextendrsvd_out(7 downto 0) => NLW_inst_rxdataextendrsvd_out_UNCONNECTED(7 downto 0),
      rxdatavalid_out(1 downto 0) => rxdatavalid_out(1 downto 0),
      rxdccforcestart_in(0) => '0',
      rxdfeagcctrl_in(1 downto 0) => B"01",
      rxdfeagchold_in(0) => '0',
      rxdfeagcovrden_in(0) => '0',
      rxdfecfokfcnum_in(3 downto 0) => B"1101",
      rxdfecfokfen_in(0) => '0',
      rxdfecfokfpulse_in(0) => '0',
      rxdfecfokhold_in(0) => '0',
      rxdfecfokovren_in(0) => '0',
      rxdfekhhold_in(0) => '0',
      rxdfekhovrden_in(0) => '0',
      rxdfelfhold_in(0) => '0',
      rxdfelfovrden_in(0) => '0',
      rxdfelpmreset_in(0) => rxdfelpmreset_in(0),
      rxdfetap10hold_in(0) => '0',
      rxdfetap10ovrden_in(0) => '0',
      rxdfetap11hold_in(0) => '0',
      rxdfetap11ovrden_in(0) => '0',
      rxdfetap12hold_in(0) => '0',
      rxdfetap12ovrden_in(0) => '0',
      rxdfetap13hold_in(0) => '0',
      rxdfetap13ovrden_in(0) => '0',
      rxdfetap14hold_in(0) => '0',
      rxdfetap14ovrden_in(0) => '0',
      rxdfetap15hold_in(0) => '0',
      rxdfetap15ovrden_in(0) => '0',
      rxdfetap2hold_in(0) => '0',
      rxdfetap2ovrden_in(0) => '0',
      rxdfetap3hold_in(0) => '0',
      rxdfetap3ovrden_in(0) => '0',
      rxdfetap4hold_in(0) => '0',
      rxdfetap4ovrden_in(0) => '0',
      rxdfetap5hold_in(0) => '0',
      rxdfetap5ovrden_in(0) => '0',
      rxdfetap6hold_in(0) => '0',
      rxdfetap6ovrden_in(0) => '0',
      rxdfetap7hold_in(0) => '0',
      rxdfetap7ovrden_in(0) => '0',
      rxdfetap8hold_in(0) => '0',
      rxdfetap8ovrden_in(0) => '0',
      rxdfetap9hold_in(0) => '0',
      rxdfetap9ovrden_in(0) => '0',
      rxdfeuthold_in(0) => '0',
      rxdfeutovrden_in(0) => '0',
      rxdfevphold_in(0) => '0',
      rxdfevpovrden_in(0) => '0',
      rxdfevsen_in(0) => '0',
      rxdfexyden_in(0) => '1',
      rxdlybypass_in(0) => '0',
      rxdlyen_in(0) => '0',
      rxdlyovrden_in(0) => '0',
      rxdlysreset_in(0) => '0',
      rxdlysresetdone_out(0) => NLW_inst_rxdlysresetdone_out_UNCONNECTED(0),
      rxelecidle_out(0) => NLW_inst_rxelecidle_out_UNCONNECTED(0),
      rxelecidlemode_in(1 downto 0) => B"11",
      rxeqtraining_in(0) => '0',
      rxgearboxslip_in(0) => rxgearboxslip_in(0),
      rxheader_out(5 downto 0) => rxheader_out(5 downto 0),
      rxheadervalid_out(1 downto 0) => rxheadervalid_out(1 downto 0),
      rxlatclk_in(0) => '0',
      rxlfpstresetdet_out(0) => NLW_inst_rxlfpstresetdet_out_UNCONNECTED(0),
      rxlfpsu2lpexitdet_out(0) => NLW_inst_rxlfpsu2lpexitdet_out_UNCONNECTED(0),
      rxlfpsu3wakedet_out(0) => NLW_inst_rxlfpsu3wakedet_out_UNCONNECTED(0),
      rxlpmen_in(0) => rxlpmen_in(0),
      rxlpmgchold_in(0) => '0',
      rxlpmgcovrden_in(0) => '0',
      rxlpmhfhold_in(0) => '0',
      rxlpmhfovrden_in(0) => '0',
      rxlpmlfhold_in(0) => '0',
      rxlpmlfklovrden_in(0) => '0',
      rxlpmoshold_in(0) => '0',
      rxlpmosovrden_in(0) => '0',
      rxmcommaalignen_in(0) => '0',
      rxmonitorout_out(7 downto 0) => NLW_inst_rxmonitorout_out_UNCONNECTED(7 downto 0),
      rxmonitorsel_in(1 downto 0) => B"00",
      rxoobreset_in(0) => '0',
      rxoscalreset_in(0) => '0',
      rxoshold_in(0) => '0',
      rxosintcfg_in(0) => '0',
      rxosintdone_out(0) => NLW_inst_rxosintdone_out_UNCONNECTED(0),
      rxosinten_in(0) => '0',
      rxosinthold_in(0) => '0',
      rxosintovrden_in(0) => '0',
      rxosintstarted_out(0) => NLW_inst_rxosintstarted_out_UNCONNECTED(0),
      rxosintstrobe_in(0) => '0',
      rxosintstrobedone_out(0) => NLW_inst_rxosintstrobedone_out_UNCONNECTED(0),
      rxosintstrobestarted_out(0) => NLW_inst_rxosintstrobestarted_out_UNCONNECTED(0),
      rxosinttestovrden_in(0) => '0',
      rxosovrden_in(0) => '0',
      rxoutclk_out(0) => NLW_inst_rxoutclk_out_UNCONNECTED(0),
      rxoutclkfabric_out(0) => NLW_inst_rxoutclkfabric_out_UNCONNECTED(0),
      rxoutclkpcs_out(0) => NLW_inst_rxoutclkpcs_out_UNCONNECTED(0),
      rxoutclksel_in(2 downto 0) => B"010",
      rxpcommaalignen_in(0) => '0',
      rxpcsreset_in(0) => rxpcsreset_in(0),
      rxpd_in(1 downto 0) => rxpd_in(1 downto 0),
      rxphalign_in(0) => '0',
      rxphaligndone_out(0) => NLW_inst_rxphaligndone_out_UNCONNECTED(0),
      rxphalignen_in(0) => '0',
      rxphalignerr_out(0) => NLW_inst_rxphalignerr_out_UNCONNECTED(0),
      rxphdlypd_in(0) => '0',
      rxphdlyreset_in(0) => '0',
      rxphovrden_in(0) => '0',
      rxpllclksel_in(1 downto 0) => rxpllclksel_in(1 downto 0),
      rxpmareset_in(0) => rxpmareset_in(0),
      rxpmaresetdone_out(0) => rxpmaresetdone_out(0),
      rxpolarity_in(0) => rxpolarity_in(0),
      rxprbscntreset_in(0) => '0',
      rxprbserr_out(0) => NLW_inst_rxprbserr_out_UNCONNECTED(0),
      rxprbslocked_out(0) => NLW_inst_rxprbslocked_out_UNCONNECTED(0),
      rxprbssel_in(3 downto 0) => B"0000",
      rxprgdivresetdone_out(0) => rxprgdivresetdone_out(0),
      rxprogdivreset_in(0) => rxprogdivreset_in(0),
      rxqpien_in(0) => '0',
      rxqpisenn_out(0) => NLW_inst_rxqpisenn_out_UNCONNECTED(0),
      rxqpisenp_out(0) => NLW_inst_rxqpisenp_out_UNCONNECTED(0),
      rxrate_in(2 downto 0) => B"000",
      rxratedone_out(0) => NLW_inst_rxratedone_out_UNCONNECTED(0),
      rxratemode_in(0) => '0',
      rxrecclk0_sel_out(0) => NLW_inst_rxrecclk0_sel_out_UNCONNECTED(0),
      rxrecclk0sel_out(1 downto 0) => NLW_inst_rxrecclk0sel_out_UNCONNECTED(1 downto 0),
      rxrecclk1_sel_out(0) => NLW_inst_rxrecclk1_sel_out_UNCONNECTED(0),
      rxrecclk1sel_out(1 downto 0) => NLW_inst_rxrecclk1sel_out_UNCONNECTED(1 downto 0),
      rxrecclkout_out(0) => NLW_inst_rxrecclkout_out_UNCONNECTED(0),
      rxresetdone_out(0) => rxresetdone_out(0),
      rxslide_in(0) => '0',
      rxsliderdy_out(0) => NLW_inst_rxsliderdy_out_UNCONNECTED(0),
      rxslipdone_out(0) => NLW_inst_rxslipdone_out_UNCONNECTED(0),
      rxslipoutclk_in(0) => '0',
      rxslipoutclkrdy_out(0) => NLW_inst_rxslipoutclkrdy_out_UNCONNECTED(0),
      rxslippma_in(0) => '0',
      rxslippmardy_out(0) => NLW_inst_rxslippmardy_out_UNCONNECTED(0),
      rxstartofseq_out(1 downto 0) => rxstartofseq_out(1 downto 0),
      rxstatus_out(2 downto 0) => NLW_inst_rxstatus_out_UNCONNECTED(2 downto 0),
      rxsyncallin_in(0) => '0',
      rxsyncdone_out(0) => NLW_inst_rxsyncdone_out_UNCONNECTED(0),
      rxsyncin_in(0) => '0',
      rxsyncmode_in(0) => '0',
      rxsyncout_out(0) => NLW_inst_rxsyncout_out_UNCONNECTED(0),
      rxsysclksel_in(1 downto 0) => rxsysclksel_in(1 downto 0),
      rxtermination_in(0) => '0',
      rxuserrdy_in(0) => rxuserrdy_in(0),
      rxusrclk2_in(0) => '0',
      rxusrclk_in(0) => '0',
      rxvalid_out(0) => NLW_inst_rxvalid_out_UNCONNECTED(0),
      sdm0data_in(24 downto 0) => B"0000000000000000000000000",
      sdm0finalout_out(3 downto 0) => NLW_inst_sdm0finalout_out_UNCONNECTED(3 downto 0),
      sdm0reset_in(0) => '0',
      sdm0testdata_out(14 downto 0) => NLW_inst_sdm0testdata_out_UNCONNECTED(14 downto 0),
      sdm0toggle_in(0) => '0',
      sdm0width_in(1 downto 0) => B"00",
      sdm1data_in(24 downto 0) => B"0000000000000000000000000",
      sdm1finalout_out(3 downto 0) => NLW_inst_sdm1finalout_out_UNCONNECTED(3 downto 0),
      sdm1reset_in(0) => '0',
      sdm1testdata_out(14 downto 0) => NLW_inst_sdm1testdata_out_UNCONNECTED(14 downto 0),
      sdm1toggle_in(0) => '0',
      sdm1width_in(1 downto 0) => B"00",
      sigvalidclk_in(0) => '0',
      tcongpi_in(9 downto 0) => B"0000000000",
      tcongpo_out(9 downto 0) => NLW_inst_tcongpo_out_UNCONNECTED(9 downto 0),
      tconpowerup_in(0) => '0',
      tconreset_in(1 downto 0) => B"00",
      tconrsvdin1_in(1 downto 0) => B"00",
      tconrsvdout0_out(0) => NLW_inst_tconrsvdout0_out_UNCONNECTED(0),
      tstin_in(19 downto 0) => B"00000000000000000000",
      tx8b10bbypass_in(7 downto 0) => B"00000000",
      tx8b10ben_in(0) => '0',
      txbufdiffctrl_in(0) => '0',
      txbufstatus_out(1 downto 0) => NLW_inst_txbufstatus_out_UNCONNECTED(1 downto 0),
      txcomfinish_out(0) => NLW_inst_txcomfinish_out_UNCONNECTED(0),
      txcominit_in(0) => '0',
      txcomsas_in(0) => '0',
      txcomwake_in(0) => '0',
      txctrl0_in(15 downto 0) => B"0000000000000000",
      txctrl1_in(15 downto 0) => B"0000000000000000",
      txctrl2_in(7 downto 0) => B"00000000",
      txdata_in(127 downto 0) => B"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      txdataextendrsvd_in(7 downto 0) => B"00000000",
      txdccdone_out(0) => NLW_inst_txdccdone_out_UNCONNECTED(0),
      txdccforcestart_in(0) => '0',
      txdccreset_in(0) => '0',
      txdeemph_in(1 downto 0) => B"00",
      txdetectrx_in(0) => '0',
      txdiffctrl_in(4 downto 0) => txdiffctrl_in(4 downto 0),
      txdiffpd_in(0) => '0',
      txdlybypass_in(0) => '0',
      txdlyen_in(0) => '0',
      txdlyhold_in(0) => '0',
      txdlyovrden_in(0) => '0',
      txdlysreset_in(0) => '0',
      txdlysresetdone_out(0) => NLW_inst_txdlysresetdone_out_UNCONNECTED(0),
      txdlyupdown_in(0) => '0',
      txelecidle_in(0) => txelecidle_in(0),
      txelforcestart_in(0) => '0',
      txheader_in(5 downto 0) => txheader_in(5 downto 0),
      txinhibit_in(0) => txinhibit_in(0),
      txlatclk_in(0) => '0',
      txlfpstreset_in(0) => '0',
      txlfpsu2lpexit_in(0) => '0',
      txlfpsu3wake_in(0) => '0',
      txmaincursor_in(6 downto 0) => txmaincursor_in(6 downto 0),
      txmargin_in(2 downto 0) => B"000",
      txmuxdcdexhold_in(0) => '0',
      txmuxdcdorwren_in(0) => '0',
      txoneszeros_in(0) => '0',
      txoutclk_out(0) => NLW_inst_txoutclk_out_UNCONNECTED(0),
      txoutclkfabric_out(0) => NLW_inst_txoutclkfabric_out_UNCONNECTED(0),
      txoutclkpcs_out(0) => NLW_inst_txoutclkpcs_out_UNCONNECTED(0),
      txoutclksel_in(2 downto 0) => B"101",
      txpcsreset_in(0) => txpcsreset_in(0),
      txpd_in(1 downto 0) => txpd_in(1 downto 0),
      txpdelecidlemode_in(0) => txpdelecidlemode_in(0),
      txphalign_in(0) => '0',
      txphaligndone_out(0) => NLW_inst_txphaligndone_out_UNCONNECTED(0),
      txphalignen_in(0) => '0',
      txphdlypd_in(0) => '0',
      txphdlyreset_in(0) => '0',
      txphdlytstclk_in(0) => '0',
      txphinit_in(0) => '0',
      txphinitdone_out(0) => NLW_inst_txphinitdone_out_UNCONNECTED(0),
      txphovrden_in(0) => '0',
      txpippmen_in(0) => '0',
      txpippmovrden_in(0) => '0',
      txpippmpd_in(0) => '1',
      txpippmsel_in(0) => '0',
      txpippmstepsize_in(4 downto 0) => B"00000",
      txpisopd_in(0) => '0',
      txpllclksel_in(1 downto 0) => txpllclksel_in(1 downto 0),
      txpmareset_in(0) => txpmareset_in(0),
      txpmaresetdone_out(0) => txpmaresetdone_out(0),
      txpolarity_in(0) => txpolarity_in(0),
      txpostcursor_in(4 downto 0) => txpostcursor_in(4 downto 0),
      txpostcursorinv_in(0) => '0',
      txprbsforceerr_in(0) => '0',
      txprbssel_in(3 downto 0) => B"0000",
      txprecursor_in(4 downto 0) => txprecursor_in(4 downto 0),
      txprecursorinv_in(0) => '0',
      txprgdivresetdone_out(0) => txprgdivresetdone_out(0),
      txprogdivreset_in(0) => txprogdivreset_in(0),
      txqpibiasen_in(0) => '0',
      txqpisenn_out(0) => NLW_inst_txqpisenn_out_UNCONNECTED(0),
      txqpisenp_out(0) => NLW_inst_txqpisenp_out_UNCONNECTED(0),
      txqpistrongpdown_in(0) => '0',
      txqpiweakpup_in(0) => '0',
      txrate_in(2 downto 0) => B"000",
      txratedone_out(0) => NLW_inst_txratedone_out_UNCONNECTED(0),
      txratemode_in(0) => '0',
      txresetdone_out(0) => txresetdone_out(0),
      txsequence_in(6 downto 0) => txsequence_in(6 downto 0),
      txswing_in(0) => '0',
      txsyncallin_in(0) => '0',
      txsyncdone_out(0) => NLW_inst_txsyncdone_out_UNCONNECTED(0),
      txsyncin_in(0) => '0',
      txsyncmode_in(0) => '0',
      txsyncout_out(0) => NLW_inst_txsyncout_out_UNCONNECTED(0),
      txsysclksel_in(1 downto 0) => txsysclksel_in(1 downto 0),
      txuserrdy_in(0) => txuserrdy_in(0),
      txusrclk2_in(0) => '0',
      txusrclk_in(0) => '0',
      ubcfgstreamen_in(0) => '0',
      ubdaddr_out(0) => NLW_inst_ubdaddr_out_UNCONNECTED(0),
      ubden_out(0) => NLW_inst_ubden_out_UNCONNECTED(0),
      ubdi_out(0) => NLW_inst_ubdi_out_UNCONNECTED(0),
      ubdo_in(0) => '0',
      ubdrdy_in(0) => '0',
      ubdwe_out(0) => NLW_inst_ubdwe_out_UNCONNECTED(0),
      ubenable_in(0) => '0',
      ubgpi_in(0) => '0',
      ubintr_in(0) => '0',
      ubiolmbrst_in(0) => '0',
      ubmbrst_in(0) => '0',
      ubmdmcapture_in(0) => '0',
      ubmdmdbgrst_in(0) => '0',
      ubmdmdbgupdate_in(0) => '0',
      ubmdmregen_in(0) => '0',
      ubmdmshift_in(0) => '0',
      ubmdmsysrst_in(0) => '0',
      ubmdmtck_in(0) => '0',
      ubmdmtdi_in(0) => '0',
      ubmdmtdo_out(0) => NLW_inst_ubmdmtdo_out_UNCONNECTED(0),
      ubrsvdout_out(0) => NLW_inst_ubrsvdout_out_UNCONNECTED(0),
      ubtxuart_out(0) => NLW_inst_ubtxuart_out_UNCONNECTED(0)
    );
end STRUCTURE;
