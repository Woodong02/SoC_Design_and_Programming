-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
-- Date        : Tue Apr 28 10:13:03 2026
-- Host        : L7735 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode funcsim
--               c:/work/2021115390/ps_digital_clock/ps_digital_clock.srcs/sources_1/bd/system/ip/system_textlcd_0_0/system_textlcd_0_0_sim_netlist.vhdl
-- Design      : system_textlcd_0_0
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xc7z020clg484-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity system_textlcd_0_0_textlcd is
  port (
    lcd_en : out STD_LOGIC;
    lcd_data : out STD_LOGIC_VECTOR ( 7 downto 0 );
    lcd_rs : out STD_LOGIC;
    lcdclk : in STD_LOGIC;
    Q : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \lcd_data[7]_INST_0_i_5_0\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \lcd_data[7]_INST_0_i_6_0\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \lcd_data[7]_INST_0_i_6_1\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \lcd_data[7]_INST_0_i_3_0\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \lcd_data[7]_INST_0_i_4_0\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \lcd_data[7]_INST_0_i_4_1\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \lcd_data[7]_INST_0_i_4_2\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    resetn : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of system_textlcd_0_0_textlcd : entity is "textlcd";
end system_textlcd_0_0_textlcd;

architecture STRUCTURE of system_textlcd_0_0_textlcd is
  signal \count_lcdclk[0]_i_2_n_0\ : STD_LOGIC;
  signal \count_lcdclk[10]_i_2_n_0\ : STD_LOGIC;
  signal \count_lcdclk[10]_i_3_n_0\ : STD_LOGIC;
  signal \count_lcdclk[10]_i_4_n_0\ : STD_LOGIC;
  signal \count_lcdclk[10]_i_5_n_0\ : STD_LOGIC;
  signal \count_lcdclk[1]_i_2_n_0\ : STD_LOGIC;
  signal \count_lcdclk[2]_i_2_n_0\ : STD_LOGIC;
  signal \count_lcdclk[2]_i_3_n_0\ : STD_LOGIC;
  signal \count_lcdclk[3]_i_2_n_0\ : STD_LOGIC;
  signal \count_lcdclk[3]_i_3_n_0\ : STD_LOGIC;
  signal \count_lcdclk[4]_i_2_n_0\ : STD_LOGIC;
  signal \count_lcdclk[5]_i_2_n_0\ : STD_LOGIC;
  signal \count_lcdclk[6]_i_2_n_0\ : STD_LOGIC;
  signal \count_lcdclk[6]_i_3_n_0\ : STD_LOGIC;
  signal \count_lcdclk[6]_i_4_n_0\ : STD_LOGIC;
  signal \count_lcdclk[7]_i_2_n_0\ : STD_LOGIC;
  signal \count_lcdclk[7]_i_3_n_0\ : STD_LOGIC;
  signal \count_lcdclk[8]_i_2_n_0\ : STD_LOGIC;
  signal \count_lcdclk[8]_i_3_n_0\ : STD_LOGIC;
  signal \count_lcdclk[9]_i_2_n_0\ : STD_LOGIC;
  signal count_lcdclk_reg : STD_LOGIC_VECTOR ( 10 downto 0 );
  signal count_mode : STD_LOGIC;
  signal \count_mode[5]_i_3_n_0\ : STD_LOGIC;
  signal count_mode_reg : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal \lcd_data[0]_INST_0_i_10_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_11_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_12_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_13_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_14_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_15_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_1_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_2_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_3_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_4_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_5_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_6_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_7_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_8_n_0\ : STD_LOGIC;
  signal \lcd_data[0]_INST_0_i_9_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_10_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_11_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_12_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_13_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_14_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_15_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_1_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_2_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_3_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_4_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_5_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_6_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_7_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_8_n_0\ : STD_LOGIC;
  signal \lcd_data[1]_INST_0_i_9_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_10_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_11_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_12_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_13_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_14_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_15_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_1_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_2_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_3_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_4_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_5_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_6_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_7_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_8_n_0\ : STD_LOGIC;
  signal \lcd_data[2]_INST_0_i_9_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_10_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_11_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_12_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_13_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_14_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_15_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_1_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_2_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_3_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_4_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_5_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_6_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_7_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_8_n_0\ : STD_LOGIC;
  signal \lcd_data[3]_INST_0_i_9_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_10_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_11_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_12_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_13_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_14_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_15_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_1_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_2_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_3_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_4_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_5_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_6_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_7_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_8_n_0\ : STD_LOGIC;
  signal \lcd_data[4]_INST_0_i_9_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_10_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_11_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_12_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_13_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_14_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_15_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_1_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_2_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_3_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_4_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_5_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_6_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_7_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_8_n_0\ : STD_LOGIC;
  signal \lcd_data[5]_INST_0_i_9_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_10_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_11_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_12_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_13_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_14_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_15_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_1_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_2_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_3_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_4_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_5_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_6_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_7_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_8_n_0\ : STD_LOGIC;
  signal \lcd_data[6]_INST_0_i_9_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_10_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_11_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_12_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_13_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_14_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_15_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_1_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_2_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_3_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_4_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_5_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_6_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_7_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_8_n_0\ : STD_LOGIC;
  signal \lcd_data[7]_INST_0_i_9_n_0\ : STD_LOGIC;
  signal \^lcd_en\ : STD_LOGIC;
  signal lcd_en0 : STD_LOGIC;
  signal lcd_en_i_1_n_0 : STD_LOGIC;
  signal lcd_en_i_2_n_0 : STD_LOGIC;
  signal lcd_en_i_3_n_0 : STD_LOGIC;
  signal lcd_en_i_5_n_0 : STD_LOGIC;
  signal lcd_mode : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \lcd_mode[3]_i_1_n_0\ : STD_LOGIC;
  signal lcd_mode_0 : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \p_0_in__0\ : STD_LOGIC_VECTOR ( 10 downto 0 );
  signal \p_0_in__1\ : STD_LOGIC_VECTOR ( 5 downto 0 );
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \count_lcdclk[0]_i_1\ : label is "soft_lutpair7";
  attribute SOFT_HLUTNM of \count_lcdclk[10]_i_3\ : label is "soft_lutpair5";
  attribute SOFT_HLUTNM of \count_lcdclk[10]_i_4\ : label is "soft_lutpair6";
  attribute SOFT_HLUTNM of \count_lcdclk[2]_i_3\ : label is "soft_lutpair6";
  attribute SOFT_HLUTNM of \count_lcdclk[3]_i_3\ : label is "soft_lutpair3";
  attribute SOFT_HLUTNM of \count_lcdclk[4]_i_2\ : label is "soft_lutpair3";
  attribute SOFT_HLUTNM of \count_lcdclk[6]_i_4\ : label is "soft_lutpair7";
  attribute SOFT_HLUTNM of \count_lcdclk[8]_i_2\ : label is "soft_lutpair0";
  attribute SOFT_HLUTNM of \count_lcdclk[8]_i_3\ : label is "soft_lutpair5";
  attribute SOFT_HLUTNM of \count_lcdclk[9]_i_2\ : label is "soft_lutpair0";
  attribute SOFT_HLUTNM of \count_mode[0]_i_1\ : label is "soft_lutpair4";
  attribute SOFT_HLUTNM of \count_mode[1]_i_1\ : label is "soft_lutpair4";
  attribute SOFT_HLUTNM of \lcd_data[5]_INST_0_i_11\ : label is "soft_lutpair1";
  attribute SOFT_HLUTNM of \lcd_mode[1]_i_1\ : label is "soft_lutpair2";
  attribute SOFT_HLUTNM of \lcd_mode[2]_i_1\ : label is "soft_lutpair1";
  attribute SOFT_HLUTNM of \lcd_mode[3]_i_2\ : label is "soft_lutpair2";
begin
  lcd_en <= \^lcd_en\;
\count_lcdclk[0]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"80BF"
    )
        port map (
      I0 => \count_lcdclk[0]_i_2_n_0\,
      I1 => count_lcdclk_reg(9),
      I2 => count_lcdclk_reg(10),
      I3 => count_lcdclk_reg(0),
      O => \p_0_in__0\(0)
    );
\count_lcdclk[0]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000000001FFFFFFF"
    )
        port map (
      I0 => count_lcdclk_reg(4),
      I1 => count_lcdclk_reg(5),
      I2 => count_lcdclk_reg(6),
      I3 => count_lcdclk_reg(7),
      I4 => count_lcdclk_reg(8),
      I5 => count_lcdclk_reg(0),
      O => \count_lcdclk[0]_i_2_n_0\
    );
\count_lcdclk[10]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"B8CC"
    )
        port map (
      I0 => \count_lcdclk[10]_i_2_n_0\,
      I1 => count_lcdclk_reg(10),
      I2 => \count_lcdclk[10]_i_3_n_0\,
      I3 => count_lcdclk_reg(9),
      O => \p_0_in__0\(10)
    );
\count_lcdclk[10]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"5575FFFFFFFFFFFF"
    )
        port map (
      I0 => count_lcdclk_reg(7),
      I1 => count_lcdclk_reg(5),
      I2 => \count_lcdclk[10]_i_4_n_0\,
      I3 => count_lcdclk_reg(4),
      I4 => count_lcdclk_reg(6),
      I5 => count_lcdclk_reg(8),
      O => \count_lcdclk[10]_i_2_n_0\
    );
\count_lcdclk[10]_i_3\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8000"
    )
        port map (
      I0 => count_lcdclk_reg(7),
      I1 => \count_lcdclk[10]_i_5_n_0\,
      I2 => count_lcdclk_reg(6),
      I3 => count_lcdclk_reg(8),
      O => \count_lcdclk[10]_i_3_n_0\
    );
\count_lcdclk[10]_i_4\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7FFF"
    )
        port map (
      I0 => count_lcdclk_reg(2),
      I1 => count_lcdclk_reg(1),
      I2 => count_lcdclk_reg(0),
      I3 => count_lcdclk_reg(3),
      O => \count_lcdclk[10]_i_4_n_0\
    );
\count_lcdclk[10]_i_5\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8000000000000000"
    )
        port map (
      I0 => count_lcdclk_reg(4),
      I1 => count_lcdclk_reg(2),
      I2 => count_lcdclk_reg(0),
      I3 => count_lcdclk_reg(1),
      I4 => count_lcdclk_reg(3),
      I5 => count_lcdclk_reg(5),
      O => \count_lcdclk[10]_i_5_n_0\
    );
\count_lcdclk[1]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8000BFFFBFFF8000"
    )
        port map (
      I0 => \count_lcdclk[1]_i_2_n_0\,
      I1 => count_lcdclk_reg(8),
      I2 => count_lcdclk_reg(9),
      I3 => count_lcdclk_reg(10),
      I4 => count_lcdclk_reg(1),
      I5 => count_lcdclk_reg(0),
      O => \p_0_in__0\(1)
    );
\count_lcdclk[1]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"00001FFF1FFF0000"
    )
        port map (
      I0 => count_lcdclk_reg(4),
      I1 => count_lcdclk_reg(5),
      I2 => count_lcdclk_reg(6),
      I3 => count_lcdclk_reg(7),
      I4 => count_lcdclk_reg(1),
      I5 => count_lcdclk_reg(0),
      O => \count_lcdclk[1]_i_2_n_0\
    );
\count_lcdclk[2]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"BFFFFFFF80000000"
    )
        port map (
      I0 => \count_lcdclk[2]_i_2_n_0\,
      I1 => count_lcdclk_reg(7),
      I2 => count_lcdclk_reg(8),
      I3 => count_lcdclk_reg(9),
      I4 => count_lcdclk_reg(10),
      I5 => \count_lcdclk[2]_i_3_n_0\,
      O => \p_0_in__0\(2)
    );
\count_lcdclk[2]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"001F1F001F001F00"
    )
        port map (
      I0 => count_lcdclk_reg(4),
      I1 => count_lcdclk_reg(5),
      I2 => count_lcdclk_reg(6),
      I3 => count_lcdclk_reg(2),
      I4 => count_lcdclk_reg(1),
      I5 => count_lcdclk_reg(0),
      O => \count_lcdclk[2]_i_2_n_0\
    );
\count_lcdclk[2]_i_3\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"6A"
    )
        port map (
      I0 => count_lcdclk_reg(2),
      I1 => count_lcdclk_reg(1),
      I2 => count_lcdclk_reg(0),
      O => \count_lcdclk[2]_i_3_n_0\
    );
\count_lcdclk[3]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"BF80"
    )
        port map (
      I0 => \count_lcdclk[3]_i_2_n_0\,
      I1 => count_lcdclk_reg(9),
      I2 => count_lcdclk_reg(10),
      I3 => \count_lcdclk[3]_i_3_n_0\,
      O => \p_0_in__0\(3)
    );
\count_lcdclk[3]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"1FFFFFFF00000000"
    )
        port map (
      I0 => count_lcdclk_reg(4),
      I1 => count_lcdclk_reg(5),
      I2 => count_lcdclk_reg(6),
      I3 => count_lcdclk_reg(7),
      I4 => count_lcdclk_reg(8),
      I5 => \count_lcdclk[3]_i_3_n_0\,
      O => \count_lcdclk[3]_i_2_n_0\
    );
\count_lcdclk[3]_i_3\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6AAA"
    )
        port map (
      I0 => count_lcdclk_reg(3),
      I1 => count_lcdclk_reg(1),
      I2 => count_lcdclk_reg(0),
      I3 => count_lcdclk_reg(2),
      O => \count_lcdclk[3]_i_3_n_0\
    );
\count_lcdclk[4]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFF00000000"
    )
        port map (
      I0 => count_lcdclk_reg(6),
      I1 => count_lcdclk_reg(7),
      I2 => count_lcdclk_reg(8),
      I3 => count_lcdclk_reg(9),
      I4 => count_lcdclk_reg(10),
      I5 => \count_lcdclk[4]_i_2_n_0\,
      O => \p_0_in__0\(4)
    );
\count_lcdclk[4]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"6AAAAAAA"
    )
        port map (
      I0 => count_lcdclk_reg(4),
      I1 => count_lcdclk_reg(2),
      I2 => count_lcdclk_reg(0),
      I3 => count_lcdclk_reg(1),
      I4 => count_lcdclk_reg(3),
      O => \count_lcdclk[4]_i_2_n_0\
    );
\count_lcdclk[5]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFF00000000"
    )
        port map (
      I0 => count_lcdclk_reg(6),
      I1 => count_lcdclk_reg(7),
      I2 => count_lcdclk_reg(8),
      I3 => count_lcdclk_reg(9),
      I4 => count_lcdclk_reg(10),
      I5 => \count_lcdclk[5]_i_2_n_0\,
      O => \p_0_in__0\(5)
    );
\count_lcdclk[5]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6AAAAAAAAAAAAAAA"
    )
        port map (
      I0 => count_lcdclk_reg(5),
      I1 => count_lcdclk_reg(3),
      I2 => count_lcdclk_reg(1),
      I3 => count_lcdclk_reg(0),
      I4 => count_lcdclk_reg(2),
      I5 => count_lcdclk_reg(4),
      O => \count_lcdclk[5]_i_2_n_0\
    );
\count_lcdclk[6]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"BFFFFFFF80000000"
    )
        port map (
      I0 => \count_lcdclk[6]_i_2_n_0\,
      I1 => count_lcdclk_reg(7),
      I2 => count_lcdclk_reg(8),
      I3 => count_lcdclk_reg(9),
      I4 => count_lcdclk_reg(10),
      I5 => \count_lcdclk[6]_i_3_n_0\,
      O => \p_0_in__0\(6)
    );
\count_lcdclk[6]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"4000000002222222"
    )
        port map (
      I0 => count_lcdclk_reg(6),
      I1 => count_lcdclk_reg(4),
      I2 => count_lcdclk_reg(2),
      I3 => \count_lcdclk[6]_i_4_n_0\,
      I4 => count_lcdclk_reg(3),
      I5 => count_lcdclk_reg(5),
      O => \count_lcdclk[6]_i_2_n_0\
    );
\count_lcdclk[6]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6AAAAAAAAAAAAAAA"
    )
        port map (
      I0 => count_lcdclk_reg(6),
      I1 => count_lcdclk_reg(4),
      I2 => count_lcdclk_reg(2),
      I3 => \count_lcdclk[6]_i_4_n_0\,
      I4 => count_lcdclk_reg(3),
      I5 => count_lcdclk_reg(5),
      O => \count_lcdclk[6]_i_3_n_0\
    );
\count_lcdclk[6]_i_4\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => count_lcdclk_reg(0),
      I1 => count_lcdclk_reg(1),
      O => \count_lcdclk[6]_i_4_n_0\
    );
\count_lcdclk[7]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BFFF8000"
    )
        port map (
      I0 => \count_lcdclk[7]_i_2_n_0\,
      I1 => count_lcdclk_reg(8),
      I2 => count_lcdclk_reg(9),
      I3 => count_lcdclk_reg(10),
      I4 => \count_lcdclk[7]_i_3_n_0\,
      O => \p_0_in__0\(7)
    );
\count_lcdclk[7]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"04FF0400FF00FF00"
    )
        port map (
      I0 => count_lcdclk_reg(5),
      I1 => \count_lcdclk[10]_i_4_n_0\,
      I2 => count_lcdclk_reg(4),
      I3 => count_lcdclk_reg(7),
      I4 => \count_lcdclk[10]_i_5_n_0\,
      I5 => count_lcdclk_reg(6),
      O => \count_lcdclk[7]_i_2_n_0\
    );
\count_lcdclk[7]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFFFDF00FF00FF00"
    )
        port map (
      I0 => count_lcdclk_reg(5),
      I1 => \count_lcdclk[10]_i_4_n_0\,
      I2 => count_lcdclk_reg(4),
      I3 => count_lcdclk_reg(7),
      I4 => \count_lcdclk[10]_i_5_n_0\,
      I5 => count_lcdclk_reg(6),
      O => \count_lcdclk[7]_i_3_n_0\
    );
\count_lcdclk[8]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"BF80FFFFBF800000"
    )
        port map (
      I0 => \count_lcdclk[8]_i_2_n_0\,
      I1 => count_lcdclk_reg(9),
      I2 => count_lcdclk_reg(10),
      I3 => \count_lcdclk[9]_i_2_n_0\,
      I4 => count_lcdclk_reg(8),
      I5 => \count_lcdclk[8]_i_3_n_0\,
      O => \p_0_in__0\(8)
    );
\count_lcdclk[8]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"5575FFFF"
    )
        port map (
      I0 => count_lcdclk_reg(6),
      I1 => count_lcdclk_reg(4),
      I2 => \count_lcdclk[10]_i_4_n_0\,
      I3 => count_lcdclk_reg(5),
      I4 => count_lcdclk_reg(7),
      O => \count_lcdclk[8]_i_2_n_0\
    );
\count_lcdclk[8]_i_3\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => count_lcdclk_reg(6),
      I1 => \count_lcdclk[10]_i_5_n_0\,
      I2 => count_lcdclk_reg(7),
      O => \count_lcdclk[8]_i_3_n_0\
    );
\count_lcdclk[9]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"B8BBFFFFB8BB0000"
    )
        port map (
      I0 => \count_lcdclk[10]_i_2_n_0\,
      I1 => count_lcdclk_reg(10),
      I2 => \count_lcdclk[9]_i_2_n_0\,
      I3 => count_lcdclk_reg(8),
      I4 => count_lcdclk_reg(9),
      I5 => \count_lcdclk[10]_i_3_n_0\,
      O => \p_0_in__0\(9)
    );
\count_lcdclk[9]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F7FFFFFF"
    )
        port map (
      I0 => count_lcdclk_reg(6),
      I1 => count_lcdclk_reg(4),
      I2 => \count_lcdclk[10]_i_4_n_0\,
      I3 => count_lcdclk_reg(5),
      I4 => count_lcdclk_reg(7),
      O => \count_lcdclk[9]_i_2_n_0\
    );
\count_lcdclk_reg[0]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(0),
      Q => count_lcdclk_reg(0)
    );
\count_lcdclk_reg[10]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(10),
      Q => count_lcdclk_reg(10)
    );
\count_lcdclk_reg[1]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(1),
      Q => count_lcdclk_reg(1)
    );
\count_lcdclk_reg[2]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(2),
      Q => count_lcdclk_reg(2)
    );
\count_lcdclk_reg[3]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(3),
      Q => count_lcdclk_reg(3)
    );
\count_lcdclk_reg[4]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(4),
      Q => count_lcdclk_reg(4)
    );
\count_lcdclk_reg[5]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(5),
      Q => count_lcdclk_reg(5)
    );
\count_lcdclk_reg[6]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(6),
      Q => count_lcdclk_reg(6)
    );
\count_lcdclk_reg[7]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(7),
      Q => count_lcdclk_reg(7)
    );
\count_lcdclk_reg[8]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(8),
      Q => count_lcdclk_reg(8)
    );
\count_lcdclk_reg[9]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__0\(9),
      Q => count_lcdclk_reg(9)
    );
\count_mode[0]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E0FF"
    )
        port map (
      I0 => count_mode_reg(3),
      I1 => count_mode_reg(4),
      I2 => count_mode_reg(5),
      I3 => count_mode_reg(0),
      O => \p_0_in__1\(0)
    );
\count_mode[1]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"E0FFFFE0"
    )
        port map (
      I0 => count_mode_reg(3),
      I1 => count_mode_reg(4),
      I2 => count_mode_reg(5),
      I3 => count_mode_reg(1),
      I4 => count_mode_reg(0),
      O => \p_0_in__1\(1)
    );
\count_mode[2]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"E0FFFFE0FFE0FFE0"
    )
        port map (
      I0 => count_mode_reg(3),
      I1 => count_mode_reg(4),
      I2 => count_mode_reg(5),
      I3 => count_mode_reg(2),
      I4 => count_mode_reg(1),
      I5 => count_mode_reg(0),
      O => \p_0_in__1\(2)
    );
\count_mode[3]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0730303030303030"
    )
        port map (
      I0 => count_mode_reg(4),
      I1 => count_mode_reg(5),
      I2 => count_mode_reg(3),
      I3 => count_mode_reg(1),
      I4 => count_mode_reg(0),
      I5 => count_mode_reg(2),
      O => \p_0_in__1\(3)
    );
\count_mode[4]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000000007FFF8000"
    )
        port map (
      I0 => count_mode_reg(3),
      I1 => count_mode_reg(1),
      I2 => count_mode_reg(0),
      I3 => count_mode_reg(2),
      I4 => count_mode_reg(4),
      I5 => count_mode_reg(5),
      O => \p_0_in__1\(4)
    );
\count_mode[5]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8000000000000000"
    )
        port map (
      I0 => count_lcdclk_reg(9),
      I1 => count_lcdclk_reg(7),
      I2 => \count_mode[5]_i_3_n_0\,
      I3 => count_lcdclk_reg(6),
      I4 => count_lcdclk_reg(8),
      I5 => count_lcdclk_reg(10),
      O => count_mode
    );
\count_mode[5]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"4000000022222222"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => count_mode_reg(3),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(0),
      I4 => count_mode_reg(2),
      I5 => count_mode_reg(4),
      O => \p_0_in__1\(5)
    );
\count_mode[5]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000040000000"
    )
        port map (
      I0 => count_lcdclk_reg(4),
      I1 => count_lcdclk_reg(2),
      I2 => count_lcdclk_reg(0),
      I3 => count_lcdclk_reg(1),
      I4 => count_lcdclk_reg(3),
      I5 => count_lcdclk_reg(5),
      O => \count_mode[5]_i_3_n_0\
    );
\count_mode_reg[0]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => count_mode,
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__1\(0),
      Q => count_mode_reg(0)
    );
\count_mode_reg[1]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => count_mode,
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__1\(1),
      Q => count_mode_reg(1)
    );
\count_mode_reg[2]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => count_mode,
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__1\(2),
      Q => count_mode_reg(2)
    );
\count_mode_reg[3]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => count_mode,
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__1\(3),
      Q => count_mode_reg(3)
    );
\count_mode_reg[4]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => count_mode,
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__1\(4),
      Q => count_mode_reg(4)
    );
\count_mode_reg[5]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => count_mode,
      CLR => lcd_en_i_2_n_0,
      D => \p_0_in__1\(5),
      Q => count_mode_reg(5)
    );
\lcd_data[0]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000F000000C000A0"
    )
        port map (
      I0 => \lcd_data[0]_INST_0_i_1_n_0\,
      I1 => \lcd_data[0]_INST_0_i_2_n_0\,
      I2 => lcd_mode(3),
      I3 => lcd_mode(0),
      I4 => lcd_mode(1),
      I5 => lcd_mode(2),
      O => lcd_data(0)
    );
\lcd_data[0]_INST_0_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CDC8DDDDCDC88888"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => \lcd_data[7]_INST_0_i_3_0\(0),
      I2 => count_mode_reg(3),
      I3 => \lcd_data[0]_INST_0_i_3_n_0\,
      I4 => count_mode_reg(4),
      I5 => \lcd_data[0]_INST_0_i_4_n_0\,
      O => \lcd_data[0]_INST_0_i_1_n_0\
    );
\lcd_data[0]_INST_0_i_10\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_1\(24),
      I1 => \lcd_data[7]_INST_0_i_4_2\(0),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_2\(8),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_2\(16),
      O => \lcd_data[0]_INST_0_i_10_n_0\
    );
\lcd_data[0]_INST_0_i_11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BFFF8000"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_2\(24),
      I1 => count_mode_reg(0),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(2),
      I4 => \lcd_data[7]_INST_0_i_3_0\(0),
      O => \lcd_data[0]_INST_0_i_11_n_0\
    );
\lcd_data[0]_INST_0_i_12\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_5_0\(0),
      I1 => \lcd_data[7]_INST_0_i_5_0\(8),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_5_0\(16),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_5_0\(24),
      O => \lcd_data[0]_INST_0_i_12_n_0\
    );
\lcd_data[0]_INST_0_i_13\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => Q(0),
      I1 => Q(8),
      I2 => count_mode_reg(1),
      I3 => Q(16),
      I4 => count_mode_reg(0),
      I5 => Q(24),
      O => \lcd_data[0]_INST_0_i_13_n_0\
    );
\lcd_data[0]_INST_0_i_14\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_1\(0),
      I1 => \lcd_data[7]_INST_0_i_6_1\(8),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_1\(16),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_1\(24),
      O => \lcd_data[0]_INST_0_i_14_n_0\
    );
\lcd_data[0]_INST_0_i_15\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_0\(0),
      I1 => \lcd_data[7]_INST_0_i_6_0\(8),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_0\(16),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_0\(24),
      O => \lcd_data[0]_INST_0_i_15_n_0\
    );
\lcd_data[0]_INST_0_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FCFFFFBB30000088"
    )
        port map (
      I0 => \lcd_data[0]_INST_0_i_5_n_0\,
      I1 => count_mode_reg(5),
      I2 => \lcd_data[0]_INST_0_i_6_n_0\,
      I3 => count_mode_reg(3),
      I4 => count_mode_reg(4),
      I5 => Q(0),
      O => \lcd_data[0]_INST_0_i_2_n_0\
    );
\lcd_data[0]_INST_0_i_3\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[0]_INST_0_i_7_n_0\,
      I1 => \lcd_data[0]_INST_0_i_8_n_0\,
      O => \lcd_data[0]_INST_0_i_3_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[0]_INST_0_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8FFB800"
    )
        port map (
      I0 => \lcd_data[0]_INST_0_i_9_n_0\,
      I1 => count_mode_reg(2),
      I2 => \lcd_data[0]_INST_0_i_10_n_0\,
      I3 => count_mode_reg(3),
      I4 => \lcd_data[0]_INST_0_i_11_n_0\,
      O => \lcd_data[0]_INST_0_i_4_n_0\
    );
\lcd_data[0]_INST_0_i_5\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[0]_INST_0_i_12_n_0\,
      I1 => \lcd_data[0]_INST_0_i_13_n_0\,
      O => \lcd_data[0]_INST_0_i_5_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[0]_INST_0_i_6\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[0]_INST_0_i_14_n_0\,
      I1 => \lcd_data[0]_INST_0_i_15_n_0\,
      O => \lcd_data[0]_INST_0_i_6_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[0]_INST_0_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(24),
      I1 => \lcd_data[7]_INST_0_i_4_0\(0),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_0\(8),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_0\(16),
      O => \lcd_data[0]_INST_0_i_7_n_0\
    );
\lcd_data[0]_INST_0_i_8\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8BBB888"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(0),
      I1 => count_mode_reg(1),
      I2 => \lcd_data[7]_INST_0_i_3_0\(8),
      I3 => count_mode_reg(0),
      I4 => \lcd_data[7]_INST_0_i_3_0\(16),
      O => \lcd_data[0]_INST_0_i_8_n_0\
    );
\lcd_data[0]_INST_0_i_9\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_0\(24),
      I1 => \lcd_data[7]_INST_0_i_4_1\(0),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_1\(8),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_1\(16),
      O => \lcd_data[0]_INST_0_i_9_n_0\
    );
\lcd_data[1]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0FFFF00F0C0FFAF"
    )
        port map (
      I0 => \lcd_data[1]_INST_0_i_1_n_0\,
      I1 => \lcd_data[1]_INST_0_i_2_n_0\,
      I2 => lcd_mode(3),
      I3 => lcd_mode(2),
      I4 => lcd_mode(1),
      I5 => lcd_mode(0),
      O => lcd_data(1)
    );
\lcd_data[1]_INST_0_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CDC8DDDDCDC88888"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => \lcd_data[7]_INST_0_i_3_0\(1),
      I2 => count_mode_reg(3),
      I3 => \lcd_data[1]_INST_0_i_3_n_0\,
      I4 => count_mode_reg(4),
      I5 => \lcd_data[1]_INST_0_i_4_n_0\,
      O => \lcd_data[1]_INST_0_i_1_n_0\
    );
\lcd_data[1]_INST_0_i_10\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_1\(25),
      I1 => \lcd_data[7]_INST_0_i_4_2\(1),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_2\(9),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_2\(17),
      O => \lcd_data[1]_INST_0_i_10_n_0\
    );
\lcd_data[1]_INST_0_i_11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BFFF8000"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_2\(25),
      I1 => count_mode_reg(0),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(2),
      I4 => \lcd_data[7]_INST_0_i_3_0\(1),
      O => \lcd_data[1]_INST_0_i_11_n_0\
    );
\lcd_data[1]_INST_0_i_12\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_5_0\(1),
      I1 => \lcd_data[7]_INST_0_i_5_0\(9),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_5_0\(17),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_5_0\(25),
      O => \lcd_data[1]_INST_0_i_12_n_0\
    );
\lcd_data[1]_INST_0_i_13\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => Q(1),
      I1 => Q(9),
      I2 => count_mode_reg(1),
      I3 => Q(17),
      I4 => count_mode_reg(0),
      I5 => Q(25),
      O => \lcd_data[1]_INST_0_i_13_n_0\
    );
\lcd_data[1]_INST_0_i_14\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_1\(1),
      I1 => \lcd_data[7]_INST_0_i_6_1\(9),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_1\(17),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_1\(25),
      O => \lcd_data[1]_INST_0_i_14_n_0\
    );
\lcd_data[1]_INST_0_i_15\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_0\(1),
      I1 => \lcd_data[7]_INST_0_i_6_0\(9),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_0\(17),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_0\(25),
      O => \lcd_data[1]_INST_0_i_15_n_0\
    );
\lcd_data[1]_INST_0_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FCFFFFBB30000088"
    )
        port map (
      I0 => \lcd_data[1]_INST_0_i_5_n_0\,
      I1 => count_mode_reg(5),
      I2 => \lcd_data[1]_INST_0_i_6_n_0\,
      I3 => count_mode_reg(3),
      I4 => count_mode_reg(4),
      I5 => Q(1),
      O => \lcd_data[1]_INST_0_i_2_n_0\
    );
\lcd_data[1]_INST_0_i_3\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[1]_INST_0_i_7_n_0\,
      I1 => \lcd_data[1]_INST_0_i_8_n_0\,
      O => \lcd_data[1]_INST_0_i_3_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[1]_INST_0_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8FFB800"
    )
        port map (
      I0 => \lcd_data[1]_INST_0_i_9_n_0\,
      I1 => count_mode_reg(2),
      I2 => \lcd_data[1]_INST_0_i_10_n_0\,
      I3 => count_mode_reg(3),
      I4 => \lcd_data[1]_INST_0_i_11_n_0\,
      O => \lcd_data[1]_INST_0_i_4_n_0\
    );
\lcd_data[1]_INST_0_i_5\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[1]_INST_0_i_12_n_0\,
      I1 => \lcd_data[1]_INST_0_i_13_n_0\,
      O => \lcd_data[1]_INST_0_i_5_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[1]_INST_0_i_6\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[1]_INST_0_i_14_n_0\,
      I1 => \lcd_data[1]_INST_0_i_15_n_0\,
      O => \lcd_data[1]_INST_0_i_6_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[1]_INST_0_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(25),
      I1 => \lcd_data[7]_INST_0_i_4_0\(1),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_0\(9),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_0\(17),
      O => \lcd_data[1]_INST_0_i_7_n_0\
    );
\lcd_data[1]_INST_0_i_8\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8BBB888"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(1),
      I1 => count_mode_reg(1),
      I2 => \lcd_data[7]_INST_0_i_3_0\(9),
      I3 => count_mode_reg(0),
      I4 => \lcd_data[7]_INST_0_i_3_0\(17),
      O => \lcd_data[1]_INST_0_i_8_n_0\
    );
\lcd_data[1]_INST_0_i_9\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_0\(25),
      I1 => \lcd_data[7]_INST_0_i_4_1\(1),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_1\(9),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_1\(17),
      O => \lcd_data[1]_INST_0_i_9_n_0\
    );
\lcd_data[2]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000F00C000000FA0"
    )
        port map (
      I0 => \lcd_data[2]_INST_0_i_1_n_0\,
      I1 => \lcd_data[2]_INST_0_i_2_n_0\,
      I2 => lcd_mode(3),
      I3 => lcd_mode(2),
      I4 => lcd_mode(0),
      I5 => lcd_mode(1),
      O => lcd_data(2)
    );
\lcd_data[2]_INST_0_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CDC8DDDDCDC88888"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => \lcd_data[7]_INST_0_i_3_0\(2),
      I2 => count_mode_reg(3),
      I3 => \lcd_data[2]_INST_0_i_3_n_0\,
      I4 => count_mode_reg(4),
      I5 => \lcd_data[2]_INST_0_i_4_n_0\,
      O => \lcd_data[2]_INST_0_i_1_n_0\
    );
\lcd_data[2]_INST_0_i_10\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_1\(26),
      I1 => \lcd_data[7]_INST_0_i_4_2\(2),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_2\(10),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_2\(18),
      O => \lcd_data[2]_INST_0_i_10_n_0\
    );
\lcd_data[2]_INST_0_i_11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BFFF8000"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_2\(26),
      I1 => count_mode_reg(0),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(2),
      I4 => \lcd_data[7]_INST_0_i_3_0\(2),
      O => \lcd_data[2]_INST_0_i_11_n_0\
    );
\lcd_data[2]_INST_0_i_12\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_5_0\(2),
      I1 => \lcd_data[7]_INST_0_i_5_0\(10),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_5_0\(18),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_5_0\(26),
      O => \lcd_data[2]_INST_0_i_12_n_0\
    );
\lcd_data[2]_INST_0_i_13\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => Q(2),
      I1 => Q(10),
      I2 => count_mode_reg(1),
      I3 => Q(18),
      I4 => count_mode_reg(0),
      I5 => Q(26),
      O => \lcd_data[2]_INST_0_i_13_n_0\
    );
\lcd_data[2]_INST_0_i_14\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_1\(2),
      I1 => \lcd_data[7]_INST_0_i_6_1\(10),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_1\(18),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_1\(26),
      O => \lcd_data[2]_INST_0_i_14_n_0\
    );
\lcd_data[2]_INST_0_i_15\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_0\(2),
      I1 => \lcd_data[7]_INST_0_i_6_0\(10),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_0\(18),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_0\(26),
      O => \lcd_data[2]_INST_0_i_15_n_0\
    );
\lcd_data[2]_INST_0_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FCFFFFBB30000088"
    )
        port map (
      I0 => \lcd_data[2]_INST_0_i_5_n_0\,
      I1 => count_mode_reg(5),
      I2 => \lcd_data[2]_INST_0_i_6_n_0\,
      I3 => count_mode_reg(3),
      I4 => count_mode_reg(4),
      I5 => Q(2),
      O => \lcd_data[2]_INST_0_i_2_n_0\
    );
\lcd_data[2]_INST_0_i_3\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[2]_INST_0_i_7_n_0\,
      I1 => \lcd_data[2]_INST_0_i_8_n_0\,
      O => \lcd_data[2]_INST_0_i_3_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[2]_INST_0_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8FFB800"
    )
        port map (
      I0 => \lcd_data[2]_INST_0_i_9_n_0\,
      I1 => count_mode_reg(2),
      I2 => \lcd_data[2]_INST_0_i_10_n_0\,
      I3 => count_mode_reg(3),
      I4 => \lcd_data[2]_INST_0_i_11_n_0\,
      O => \lcd_data[2]_INST_0_i_4_n_0\
    );
\lcd_data[2]_INST_0_i_5\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[2]_INST_0_i_12_n_0\,
      I1 => \lcd_data[2]_INST_0_i_13_n_0\,
      O => \lcd_data[2]_INST_0_i_5_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[2]_INST_0_i_6\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[2]_INST_0_i_14_n_0\,
      I1 => \lcd_data[2]_INST_0_i_15_n_0\,
      O => \lcd_data[2]_INST_0_i_6_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[2]_INST_0_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(26),
      I1 => \lcd_data[7]_INST_0_i_4_0\(2),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_0\(10),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_0\(18),
      O => \lcd_data[2]_INST_0_i_7_n_0\
    );
\lcd_data[2]_INST_0_i_8\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8BBB888"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(2),
      I1 => count_mode_reg(1),
      I2 => \lcd_data[7]_INST_0_i_3_0\(10),
      I3 => count_mode_reg(0),
      I4 => \lcd_data[7]_INST_0_i_3_0\(18),
      O => \lcd_data[2]_INST_0_i_8_n_0\
    );
\lcd_data[2]_INST_0_i_9\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_0\(26),
      I1 => \lcd_data[7]_INST_0_i_4_1\(2),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_1\(10),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_1\(18),
      O => \lcd_data[2]_INST_0_i_9_n_0\
    );
\lcd_data[3]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000000000FFFCFA0"
    )
        port map (
      I0 => \lcd_data[3]_INST_0_i_1_n_0\,
      I1 => \lcd_data[3]_INST_0_i_2_n_0\,
      I2 => lcd_mode(3),
      I3 => lcd_mode(1),
      I4 => lcd_mode(0),
      I5 => lcd_mode(2),
      O => lcd_data(3)
    );
\lcd_data[3]_INST_0_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CDC8DDDDCDC88888"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => \lcd_data[7]_INST_0_i_3_0\(3),
      I2 => count_mode_reg(3),
      I3 => \lcd_data[3]_INST_0_i_3_n_0\,
      I4 => count_mode_reg(4),
      I5 => \lcd_data[3]_INST_0_i_4_n_0\,
      O => \lcd_data[3]_INST_0_i_1_n_0\
    );
\lcd_data[3]_INST_0_i_10\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_1\(27),
      I1 => \lcd_data[7]_INST_0_i_4_2\(3),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_2\(11),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_2\(19),
      O => \lcd_data[3]_INST_0_i_10_n_0\
    );
\lcd_data[3]_INST_0_i_11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BFFF8000"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_2\(27),
      I1 => count_mode_reg(0),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(2),
      I4 => \lcd_data[7]_INST_0_i_3_0\(3),
      O => \lcd_data[3]_INST_0_i_11_n_0\
    );
\lcd_data[3]_INST_0_i_12\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_5_0\(3),
      I1 => \lcd_data[7]_INST_0_i_5_0\(11),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_5_0\(19),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_5_0\(27),
      O => \lcd_data[3]_INST_0_i_12_n_0\
    );
\lcd_data[3]_INST_0_i_13\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => Q(3),
      I1 => Q(11),
      I2 => count_mode_reg(1),
      I3 => Q(19),
      I4 => count_mode_reg(0),
      I5 => Q(27),
      O => \lcd_data[3]_INST_0_i_13_n_0\
    );
\lcd_data[3]_INST_0_i_14\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_1\(3),
      I1 => \lcd_data[7]_INST_0_i_6_1\(11),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_1\(19),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_1\(27),
      O => \lcd_data[3]_INST_0_i_14_n_0\
    );
\lcd_data[3]_INST_0_i_15\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_0\(3),
      I1 => \lcd_data[7]_INST_0_i_6_0\(11),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_0\(19),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_0\(27),
      O => \lcd_data[3]_INST_0_i_15_n_0\
    );
\lcd_data[3]_INST_0_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FCFFFFBB30000088"
    )
        port map (
      I0 => \lcd_data[3]_INST_0_i_5_n_0\,
      I1 => count_mode_reg(5),
      I2 => \lcd_data[3]_INST_0_i_6_n_0\,
      I3 => count_mode_reg(3),
      I4 => count_mode_reg(4),
      I5 => Q(3),
      O => \lcd_data[3]_INST_0_i_2_n_0\
    );
\lcd_data[3]_INST_0_i_3\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[3]_INST_0_i_7_n_0\,
      I1 => \lcd_data[3]_INST_0_i_8_n_0\,
      O => \lcd_data[3]_INST_0_i_3_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[3]_INST_0_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8FFB800"
    )
        port map (
      I0 => \lcd_data[3]_INST_0_i_9_n_0\,
      I1 => count_mode_reg(2),
      I2 => \lcd_data[3]_INST_0_i_10_n_0\,
      I3 => count_mode_reg(3),
      I4 => \lcd_data[3]_INST_0_i_11_n_0\,
      O => \lcd_data[3]_INST_0_i_4_n_0\
    );
\lcd_data[3]_INST_0_i_5\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[3]_INST_0_i_12_n_0\,
      I1 => \lcd_data[3]_INST_0_i_13_n_0\,
      O => \lcd_data[3]_INST_0_i_5_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[3]_INST_0_i_6\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[3]_INST_0_i_14_n_0\,
      I1 => \lcd_data[3]_INST_0_i_15_n_0\,
      O => \lcd_data[3]_INST_0_i_6_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[3]_INST_0_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(27),
      I1 => \lcd_data[7]_INST_0_i_4_0\(3),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_0\(11),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_0\(19),
      O => \lcd_data[3]_INST_0_i_7_n_0\
    );
\lcd_data[3]_INST_0_i_8\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8BBB888"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(3),
      I1 => count_mode_reg(1),
      I2 => \lcd_data[7]_INST_0_i_3_0\(11),
      I3 => count_mode_reg(0),
      I4 => \lcd_data[7]_INST_0_i_3_0\(19),
      O => \lcd_data[3]_INST_0_i_8_n_0\
    );
\lcd_data[3]_INST_0_i_9\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_0\(27),
      I1 => \lcd_data[7]_INST_0_i_4_1\(3),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_1\(11),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_1\(19),
      O => \lcd_data[3]_INST_0_i_9_n_0\
    );
\lcd_data[4]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000CF0FA0"
    )
        port map (
      I0 => \lcd_data[4]_INST_0_i_1_n_0\,
      I1 => \lcd_data[4]_INST_0_i_2_n_0\,
      I2 => lcd_mode(3),
      I3 => lcd_mode(0),
      I4 => lcd_mode(1),
      I5 => lcd_mode(2),
      O => lcd_data(4)
    );
\lcd_data[4]_INST_0_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CDC8DDDDCDC88888"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => \lcd_data[7]_INST_0_i_3_0\(4),
      I2 => count_mode_reg(3),
      I3 => \lcd_data[4]_INST_0_i_3_n_0\,
      I4 => count_mode_reg(4),
      I5 => \lcd_data[4]_INST_0_i_4_n_0\,
      O => \lcd_data[4]_INST_0_i_1_n_0\
    );
\lcd_data[4]_INST_0_i_10\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_1\(28),
      I1 => \lcd_data[7]_INST_0_i_4_2\(4),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_2\(12),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_2\(20),
      O => \lcd_data[4]_INST_0_i_10_n_0\
    );
\lcd_data[4]_INST_0_i_11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BFFF8000"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_2\(28),
      I1 => count_mode_reg(0),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(2),
      I4 => \lcd_data[7]_INST_0_i_3_0\(4),
      O => \lcd_data[4]_INST_0_i_11_n_0\
    );
\lcd_data[4]_INST_0_i_12\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_5_0\(4),
      I1 => \lcd_data[7]_INST_0_i_5_0\(12),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_5_0\(20),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_5_0\(28),
      O => \lcd_data[4]_INST_0_i_12_n_0\
    );
\lcd_data[4]_INST_0_i_13\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => Q(4),
      I1 => Q(12),
      I2 => count_mode_reg(1),
      I3 => Q(20),
      I4 => count_mode_reg(0),
      I5 => Q(28),
      O => \lcd_data[4]_INST_0_i_13_n_0\
    );
\lcd_data[4]_INST_0_i_14\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_1\(4),
      I1 => \lcd_data[7]_INST_0_i_6_1\(12),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_1\(20),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_1\(28),
      O => \lcd_data[4]_INST_0_i_14_n_0\
    );
\lcd_data[4]_INST_0_i_15\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_0\(4),
      I1 => \lcd_data[7]_INST_0_i_6_0\(12),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_0\(20),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_0\(28),
      O => \lcd_data[4]_INST_0_i_15_n_0\
    );
\lcd_data[4]_INST_0_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FCFFFFBB30000088"
    )
        port map (
      I0 => \lcd_data[4]_INST_0_i_5_n_0\,
      I1 => count_mode_reg(5),
      I2 => \lcd_data[4]_INST_0_i_6_n_0\,
      I3 => count_mode_reg(3),
      I4 => count_mode_reg(4),
      I5 => Q(4),
      O => \lcd_data[4]_INST_0_i_2_n_0\
    );
\lcd_data[4]_INST_0_i_3\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[4]_INST_0_i_7_n_0\,
      I1 => \lcd_data[4]_INST_0_i_8_n_0\,
      O => \lcd_data[4]_INST_0_i_3_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[4]_INST_0_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8FFB800"
    )
        port map (
      I0 => \lcd_data[4]_INST_0_i_9_n_0\,
      I1 => count_mode_reg(2),
      I2 => \lcd_data[4]_INST_0_i_10_n_0\,
      I3 => count_mode_reg(3),
      I4 => \lcd_data[4]_INST_0_i_11_n_0\,
      O => \lcd_data[4]_INST_0_i_4_n_0\
    );
\lcd_data[4]_INST_0_i_5\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[4]_INST_0_i_12_n_0\,
      I1 => \lcd_data[4]_INST_0_i_13_n_0\,
      O => \lcd_data[4]_INST_0_i_5_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[4]_INST_0_i_6\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[4]_INST_0_i_14_n_0\,
      I1 => \lcd_data[4]_INST_0_i_15_n_0\,
      O => \lcd_data[4]_INST_0_i_6_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[4]_INST_0_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(28),
      I1 => \lcd_data[7]_INST_0_i_4_0\(4),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_0\(12),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_0\(20),
      O => \lcd_data[4]_INST_0_i_7_n_0\
    );
\lcd_data[4]_INST_0_i_8\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8BBB888"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(4),
      I1 => count_mode_reg(1),
      I2 => \lcd_data[7]_INST_0_i_3_0\(12),
      I3 => count_mode_reg(0),
      I4 => \lcd_data[7]_INST_0_i_3_0\(20),
      O => \lcd_data[4]_INST_0_i_8_n_0\
    );
\lcd_data[4]_INST_0_i_9\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_0\(28),
      I1 => \lcd_data[7]_INST_0_i_4_1\(4),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_1\(12),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_1\(20),
      O => \lcd_data[4]_INST_0_i_9_n_0\
    );
\lcd_data[5]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000CFFFA0"
    )
        port map (
      I0 => \lcd_data[5]_INST_0_i_1_n_0\,
      I1 => \lcd_data[5]_INST_0_i_2_n_0\,
      I2 => lcd_mode(3),
      I3 => lcd_mode(0),
      I4 => lcd_mode(1),
      I5 => lcd_mode(2),
      O => lcd_data(5)
    );
\lcd_data[5]_INST_0_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CDC8DDDDCDC88888"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => \lcd_data[7]_INST_0_i_3_0\(5),
      I2 => count_mode_reg(3),
      I3 => \lcd_data[5]_INST_0_i_3_n_0\,
      I4 => count_mode_reg(4),
      I5 => \lcd_data[5]_INST_0_i_4_n_0\,
      O => \lcd_data[5]_INST_0_i_1_n_0\
    );
\lcd_data[5]_INST_0_i_10\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_1\(29),
      I1 => \lcd_data[7]_INST_0_i_4_2\(5),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_2\(13),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_2\(21),
      O => \lcd_data[5]_INST_0_i_10_n_0\
    );
\lcd_data[5]_INST_0_i_11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BFFF8000"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_2\(29),
      I1 => count_mode_reg(0),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(2),
      I4 => \lcd_data[7]_INST_0_i_3_0\(5),
      O => \lcd_data[5]_INST_0_i_11_n_0\
    );
\lcd_data[5]_INST_0_i_12\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_5_0\(5),
      I1 => \lcd_data[7]_INST_0_i_5_0\(13),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_5_0\(21),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_5_0\(29),
      O => \lcd_data[5]_INST_0_i_12_n_0\
    );
\lcd_data[5]_INST_0_i_13\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => Q(5),
      I1 => Q(13),
      I2 => count_mode_reg(1),
      I3 => Q(21),
      I4 => count_mode_reg(0),
      I5 => Q(29),
      O => \lcd_data[5]_INST_0_i_13_n_0\
    );
\lcd_data[5]_INST_0_i_14\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_1\(5),
      I1 => \lcd_data[7]_INST_0_i_6_1\(13),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_1\(21),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_1\(29),
      O => \lcd_data[5]_INST_0_i_14_n_0\
    );
\lcd_data[5]_INST_0_i_15\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_0\(5),
      I1 => \lcd_data[7]_INST_0_i_6_0\(13),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_0\(21),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_0\(29),
      O => \lcd_data[5]_INST_0_i_15_n_0\
    );
\lcd_data[5]_INST_0_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FCFFFFBB30000088"
    )
        port map (
      I0 => \lcd_data[5]_INST_0_i_5_n_0\,
      I1 => count_mode_reg(5),
      I2 => \lcd_data[5]_INST_0_i_6_n_0\,
      I3 => count_mode_reg(3),
      I4 => count_mode_reg(4),
      I5 => Q(5),
      O => \lcd_data[5]_INST_0_i_2_n_0\
    );
\lcd_data[5]_INST_0_i_3\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[5]_INST_0_i_7_n_0\,
      I1 => \lcd_data[5]_INST_0_i_8_n_0\,
      O => \lcd_data[5]_INST_0_i_3_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[5]_INST_0_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8FFB800"
    )
        port map (
      I0 => \lcd_data[5]_INST_0_i_9_n_0\,
      I1 => count_mode_reg(2),
      I2 => \lcd_data[5]_INST_0_i_10_n_0\,
      I3 => count_mode_reg(3),
      I4 => \lcd_data[5]_INST_0_i_11_n_0\,
      O => \lcd_data[5]_INST_0_i_4_n_0\
    );
\lcd_data[5]_INST_0_i_5\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[5]_INST_0_i_12_n_0\,
      I1 => \lcd_data[5]_INST_0_i_13_n_0\,
      O => \lcd_data[5]_INST_0_i_5_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[5]_INST_0_i_6\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[5]_INST_0_i_14_n_0\,
      I1 => \lcd_data[5]_INST_0_i_15_n_0\,
      O => \lcd_data[5]_INST_0_i_6_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[5]_INST_0_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(29),
      I1 => \lcd_data[7]_INST_0_i_4_0\(5),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_0\(13),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_0\(21),
      O => \lcd_data[5]_INST_0_i_7_n_0\
    );
\lcd_data[5]_INST_0_i_8\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8BBB888"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(5),
      I1 => count_mode_reg(1),
      I2 => \lcd_data[7]_INST_0_i_3_0\(13),
      I3 => count_mode_reg(0),
      I4 => \lcd_data[7]_INST_0_i_3_0\(21),
      O => \lcd_data[5]_INST_0_i_8_n_0\
    );
\lcd_data[5]_INST_0_i_9\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_0\(29),
      I1 => \lcd_data[7]_INST_0_i_4_1\(5),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_1\(13),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_1\(21),
      O => \lcd_data[5]_INST_0_i_9_n_0\
    );
\lcd_data[6]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000454000000000"
    )
        port map (
      I0 => lcd_mode(2),
      I1 => \lcd_data[6]_INST_0_i_1_n_0\,
      I2 => lcd_mode(1),
      I3 => \lcd_data[6]_INST_0_i_2_n_0\,
      I4 => lcd_mode(0),
      I5 => lcd_mode(3),
      O => lcd_data(6)
    );
\lcd_data[6]_INST_0_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FCFFFFBB30000088"
    )
        port map (
      I0 => \lcd_data[6]_INST_0_i_3_n_0\,
      I1 => count_mode_reg(5),
      I2 => \lcd_data[6]_INST_0_i_4_n_0\,
      I3 => count_mode_reg(3),
      I4 => count_mode_reg(4),
      I5 => Q(6),
      O => \lcd_data[6]_INST_0_i_1_n_0\
    );
\lcd_data[6]_INST_0_i_10\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_0\(6),
      I1 => \lcd_data[7]_INST_0_i_6_0\(14),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_0\(22),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_0\(30),
      O => \lcd_data[6]_INST_0_i_10_n_0\
    );
\lcd_data[6]_INST_0_i_11\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(30),
      I1 => \lcd_data[7]_INST_0_i_4_0\(6),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_0\(14),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_0\(22),
      O => \lcd_data[6]_INST_0_i_11_n_0\
    );
\lcd_data[6]_INST_0_i_12\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8BBB888"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(6),
      I1 => count_mode_reg(1),
      I2 => \lcd_data[7]_INST_0_i_3_0\(14),
      I3 => count_mode_reg(0),
      I4 => \lcd_data[7]_INST_0_i_3_0\(22),
      O => \lcd_data[6]_INST_0_i_12_n_0\
    );
\lcd_data[6]_INST_0_i_13\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_0\(30),
      I1 => \lcd_data[7]_INST_0_i_4_1\(6),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_1\(14),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_1\(22),
      O => \lcd_data[6]_INST_0_i_13_n_0\
    );
\lcd_data[6]_INST_0_i_14\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_1\(30),
      I1 => \lcd_data[7]_INST_0_i_4_2\(6),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_2\(14),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_2\(22),
      O => \lcd_data[6]_INST_0_i_14_n_0\
    );
\lcd_data[6]_INST_0_i_15\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BFFF8000"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_2\(30),
      I1 => count_mode_reg(0),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(2),
      I4 => \lcd_data[7]_INST_0_i_3_0\(6),
      O => \lcd_data[6]_INST_0_i_15_n_0\
    );
\lcd_data[6]_INST_0_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CDC8DDDDCDC88888"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => \lcd_data[7]_INST_0_i_3_0\(6),
      I2 => count_mode_reg(3),
      I3 => \lcd_data[6]_INST_0_i_5_n_0\,
      I4 => count_mode_reg(4),
      I5 => \lcd_data[6]_INST_0_i_6_n_0\,
      O => \lcd_data[6]_INST_0_i_2_n_0\
    );
\lcd_data[6]_INST_0_i_3\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[6]_INST_0_i_7_n_0\,
      I1 => \lcd_data[6]_INST_0_i_8_n_0\,
      O => \lcd_data[6]_INST_0_i_3_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[6]_INST_0_i_4\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[6]_INST_0_i_9_n_0\,
      I1 => \lcd_data[6]_INST_0_i_10_n_0\,
      O => \lcd_data[6]_INST_0_i_4_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[6]_INST_0_i_5\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[6]_INST_0_i_11_n_0\,
      I1 => \lcd_data[6]_INST_0_i_12_n_0\,
      O => \lcd_data[6]_INST_0_i_5_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[6]_INST_0_i_6\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8FFB800"
    )
        port map (
      I0 => \lcd_data[6]_INST_0_i_13_n_0\,
      I1 => count_mode_reg(2),
      I2 => \lcd_data[6]_INST_0_i_14_n_0\,
      I3 => count_mode_reg(3),
      I4 => \lcd_data[6]_INST_0_i_15_n_0\,
      O => \lcd_data[6]_INST_0_i_6_n_0\
    );
\lcd_data[6]_INST_0_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_5_0\(6),
      I1 => \lcd_data[7]_INST_0_i_5_0\(14),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_5_0\(22),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_5_0\(30),
      O => \lcd_data[6]_INST_0_i_7_n_0\
    );
\lcd_data[6]_INST_0_i_8\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => Q(6),
      I1 => Q(14),
      I2 => count_mode_reg(1),
      I3 => Q(22),
      I4 => count_mode_reg(0),
      I5 => Q(30),
      O => \lcd_data[6]_INST_0_i_8_n_0\
    );
\lcd_data[6]_INST_0_i_9\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_1\(6),
      I1 => \lcd_data[7]_INST_0_i_6_1\(14),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_1\(22),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_1\(30),
      O => \lcd_data[6]_INST_0_i_9_n_0\
    );
\lcd_data[7]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0F00000000F0C0A0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_1_n_0\,
      I1 => \lcd_data[7]_INST_0_i_2_n_0\,
      I2 => lcd_mode(3),
      I3 => lcd_mode(1),
      I4 => lcd_mode(0),
      I5 => lcd_mode(2),
      O => lcd_data(7)
    );
\lcd_data[7]_INST_0_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CDC8DDDDCDC88888"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => \lcd_data[7]_INST_0_i_3_0\(7),
      I2 => count_mode_reg(3),
      I3 => \lcd_data[7]_INST_0_i_3_n_0\,
      I4 => count_mode_reg(4),
      I5 => \lcd_data[7]_INST_0_i_4_n_0\,
      O => \lcd_data[7]_INST_0_i_1_n_0\
    );
\lcd_data[7]_INST_0_i_10\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_1\(31),
      I1 => \lcd_data[7]_INST_0_i_4_2\(7),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_2\(15),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_2\(23),
      O => \lcd_data[7]_INST_0_i_10_n_0\
    );
\lcd_data[7]_INST_0_i_11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BFFF8000"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_2\(31),
      I1 => count_mode_reg(0),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(2),
      I4 => \lcd_data[7]_INST_0_i_3_0\(7),
      O => \lcd_data[7]_INST_0_i_11_n_0\
    );
\lcd_data[7]_INST_0_i_12\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_5_0\(7),
      I1 => \lcd_data[7]_INST_0_i_5_0\(15),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_5_0\(23),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_5_0\(31),
      O => \lcd_data[7]_INST_0_i_12_n_0\
    );
\lcd_data[7]_INST_0_i_13\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => Q(7),
      I1 => Q(15),
      I2 => count_mode_reg(1),
      I3 => Q(23),
      I4 => count_mode_reg(0),
      I5 => Q(31),
      O => \lcd_data[7]_INST_0_i_13_n_0\
    );
\lcd_data[7]_INST_0_i_14\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_1\(7),
      I1 => \lcd_data[7]_INST_0_i_6_1\(15),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_1\(23),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_1\(31),
      O => \lcd_data[7]_INST_0_i_14_n_0\
    );
\lcd_data[7]_INST_0_i_15\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_6_0\(7),
      I1 => \lcd_data[7]_INST_0_i_6_0\(15),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_6_0\(23),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_6_0\(31),
      O => \lcd_data[7]_INST_0_i_15_n_0\
    );
\lcd_data[7]_INST_0_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FCFFFFBB30000088"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_5_n_0\,
      I1 => count_mode_reg(5),
      I2 => \lcd_data[7]_INST_0_i_6_n_0\,
      I3 => count_mode_reg(3),
      I4 => count_mode_reg(4),
      I5 => Q(7),
      O => \lcd_data[7]_INST_0_i_2_n_0\
    );
\lcd_data[7]_INST_0_i_3\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[7]_INST_0_i_7_n_0\,
      I1 => \lcd_data[7]_INST_0_i_8_n_0\,
      O => \lcd_data[7]_INST_0_i_3_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[7]_INST_0_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8FFB800"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_9_n_0\,
      I1 => count_mode_reg(2),
      I2 => \lcd_data[7]_INST_0_i_10_n_0\,
      I3 => count_mode_reg(3),
      I4 => \lcd_data[7]_INST_0_i_11_n_0\,
      O => \lcd_data[7]_INST_0_i_4_n_0\
    );
\lcd_data[7]_INST_0_i_5\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[7]_INST_0_i_12_n_0\,
      I1 => \lcd_data[7]_INST_0_i_13_n_0\,
      O => \lcd_data[7]_INST_0_i_5_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[7]_INST_0_i_6\: unisim.vcomponents.MUXF7
     port map (
      I0 => \lcd_data[7]_INST_0_i_14_n_0\,
      I1 => \lcd_data[7]_INST_0_i_15_n_0\,
      O => \lcd_data[7]_INST_0_i_6_n_0\,
      S => count_mode_reg(2)
    );
\lcd_data[7]_INST_0_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(31),
      I1 => \lcd_data[7]_INST_0_i_4_0\(7),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_0\(15),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_0\(23),
      O => \lcd_data[7]_INST_0_i_7_n_0\
    );
\lcd_data[7]_INST_0_i_8\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"B8BBB888"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_3_0\(7),
      I1 => count_mode_reg(1),
      I2 => \lcd_data[7]_INST_0_i_3_0\(15),
      I3 => count_mode_reg(0),
      I4 => \lcd_data[7]_INST_0_i_3_0\(23),
      O => \lcd_data[7]_INST_0_i_8_n_0\
    );
\lcd_data[7]_INST_0_i_9\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \lcd_data[7]_INST_0_i_4_0\(31),
      I1 => \lcd_data[7]_INST_0_i_4_1\(7),
      I2 => count_mode_reg(1),
      I3 => \lcd_data[7]_INST_0_i_4_1\(15),
      I4 => count_mode_reg(0),
      I5 => \lcd_data[7]_INST_0_i_4_1\(23),
      O => \lcd_data[7]_INST_0_i_9_n_0\
    );
lcd_en_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"2F20"
    )
        port map (
      I0 => lcd_en_i_3_n_0,
      I1 => count_lcdclk_reg(10),
      I2 => lcd_en0,
      I3 => \^lcd_en\,
      O => lcd_en_i_1_n_0
    );
lcd_en_i_2: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => resetn,
      O => lcd_en_i_2_n_0
    );
lcd_en_i_3: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00004000"
    )
        port map (
      I0 => count_lcdclk_reg(8),
      I1 => count_lcdclk_reg(6),
      I2 => lcd_en_i_5_n_0,
      I3 => count_lcdclk_reg(7),
      I4 => count_lcdclk_reg(9),
      O => lcd_en_i_3_n_0
    );
lcd_en_i_4: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000080010000000"
    )
        port map (
      I0 => count_lcdclk_reg(10),
      I1 => count_lcdclk_reg(8),
      I2 => count_lcdclk_reg(6),
      I3 => lcd_en_i_5_n_0,
      I4 => count_lcdclk_reg(7),
      I5 => count_lcdclk_reg(9),
      O => lcd_en0
    );
lcd_en_i_5: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000010000"
    )
        port map (
      I0 => count_lcdclk_reg(4),
      I1 => count_lcdclk_reg(2),
      I2 => count_lcdclk_reg(0),
      I3 => count_lcdclk_reg(1),
      I4 => count_lcdclk_reg(3),
      I5 => count_lcdclk_reg(5),
      O => lcd_en_i_5_n_0
    );
lcd_en_reg: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => '1',
      CLR => lcd_en_i_2_n_0,
      D => lcd_en_i_1_n_0,
      Q => \^lcd_en\
    );
\lcd_mode[0]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AACF"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => count_mode_reg(4),
      I2 => count_mode_reg(0),
      I3 => count_mode_reg(3),
      O => lcd_mode_0(0)
    );
\lcd_mode[1]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"01FE"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => count_mode_reg(4),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(0),
      O => lcd_mode_0(1)
    );
\lcd_mode[2]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"6A"
    )
        port map (
      I0 => count_mode_reg(2),
      I1 => count_mode_reg(1),
      I2 => count_mode_reg(0),
      O => lcd_mode_0(2)
    );
\lcd_mode[3]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0001000240005555"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => count_mode_reg(1),
      I2 => count_mode_reg(0),
      I3 => count_mode_reg(2),
      I4 => count_mode_reg(4),
      I5 => count_mode_reg(3),
      O => \lcd_mode[3]_i_1_n_0\
    );
\lcd_mode[3]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0EE00EE"
    )
        port map (
      I0 => count_mode_reg(5),
      I1 => count_mode_reg(4),
      I2 => count_mode_reg(1),
      I3 => count_mode_reg(0),
      I4 => count_mode_reg(2),
      O => lcd_mode_0(3)
    );
\lcd_mode_reg[0]\: unisim.vcomponents.FDPE
     port map (
      C => lcdclk,
      CE => \lcd_mode[3]_i_1_n_0\,
      D => lcd_mode_0(0),
      PRE => lcd_en_i_2_n_0,
      Q => lcd_mode(0)
    );
\lcd_mode_reg[1]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => \lcd_mode[3]_i_1_n_0\,
      CLR => lcd_en_i_2_n_0,
      D => lcd_mode_0(1),
      Q => lcd_mode(1)
    );
\lcd_mode_reg[2]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => \lcd_mode[3]_i_1_n_0\,
      CLR => lcd_en_i_2_n_0,
      D => lcd_mode_0(2),
      Q => lcd_mode(2)
    );
\lcd_mode_reg[3]\: unisim.vcomponents.FDCE
     port map (
      C => lcdclk,
      CE => \lcd_mode[3]_i_1_n_0\,
      CLR => lcd_en_i_2_n_0,
      D => lcd_mode_0(3),
      Q => lcd_mode(3)
    );
lcd_rs_INST_0: unisim.vcomponents.LUT3
    generic map(
      INIT => X"10"
    )
        port map (
      I0 => lcd_mode(2),
      I1 => lcd_mode(0),
      I2 => lcd_mode(3),
      O => lcd_rs
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity system_textlcd_0_0_textlcd_v1_0_S00_AXI is
  port (
    S_AXI_AWREADY : out STD_LOGIC;
    S_AXI_WREADY : out STD_LOGIC;
    S_AXI_ARREADY : out STD_LOGIC;
    s00_axi_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    lcd_data : out STD_LOGIC_VECTOR ( 7 downto 0 );
    lcd_rs : out STD_LOGIC;
    s00_axi_rvalid : out STD_LOGIC;
    lcd_en : out STD_LOGIC;
    s00_axi_bvalid : out STD_LOGIC;
    s00_axi_awaddr : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s00_axi_wvalid : in STD_LOGIC;
    s00_axi_awvalid : in STD_LOGIC;
    s00_axi_aclk : in STD_LOGIC;
    s00_axi_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    lcdclk : in STD_LOGIC;
    s00_axi_araddr : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s00_axi_arvalid : in STD_LOGIC;
    s00_axi_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s00_axi_aresetn : in STD_LOGIC;
    resetn : in STD_LOGIC;
    s00_axi_bready : in STD_LOGIC;
    s00_axi_rready : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of system_textlcd_0_0_textlcd_v1_0_S00_AXI : entity is "textlcd_v1_0_S00_AXI";
end system_textlcd_0_0_textlcd_v1_0_S00_AXI;

architecture STRUCTURE of system_textlcd_0_0_textlcd_v1_0_S00_AXI is
  signal \^s_axi_arready\ : STD_LOGIC;
  signal \^s_axi_awready\ : STD_LOGIC;
  signal \^s_axi_wready\ : STD_LOGIC;
  signal aw_en_i_1_n_0 : STD_LOGIC;
  signal aw_en_reg_n_0 : STD_LOGIC;
  signal \axi_araddr[2]_i_1_n_0\ : STD_LOGIC;
  signal \axi_araddr[3]_i_1_n_0\ : STD_LOGIC;
  signal \axi_araddr[4]_i_1_n_0\ : STD_LOGIC;
  signal axi_arready0 : STD_LOGIC;
  signal \axi_awaddr[2]_i_1_n_0\ : STD_LOGIC;
  signal \axi_awaddr[3]_i_1_n_0\ : STD_LOGIC;
  signal \axi_awaddr[4]_i_1_n_0\ : STD_LOGIC;
  signal axi_awready0 : STD_LOGIC;
  signal axi_awready_i_1_n_0 : STD_LOGIC;
  signal axi_bvalid_i_1_n_0 : STD_LOGIC;
  signal \axi_rdata[0]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[0]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[10]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[10]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[11]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[11]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[12]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[12]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[13]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[13]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[14]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[14]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[15]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[15]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[16]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[16]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[17]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[17]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[18]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[18]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[19]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[19]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[1]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[1]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[20]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[20]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[21]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[21]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[22]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[22]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[23]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[23]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[24]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[24]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[25]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[25]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[26]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[26]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[27]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[27]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[28]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[28]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[29]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[29]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[2]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[2]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[30]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[30]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[31]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[31]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[3]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[3]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[4]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[4]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[5]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[5]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[6]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[6]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[7]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[7]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[8]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[8]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[9]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[9]_i_3_n_0\ : STD_LOGIC;
  signal axi_rvalid_i_1_n_0 : STD_LOGIC;
  signal axi_wready0 : STD_LOGIC;
  signal data1 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data10 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data11 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data12 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data13 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data14 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data15 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data2 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data3 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data4 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data5 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data6 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data7 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data8 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal data9 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal p_0_in : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal p_12_in : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal p_1_in : STD_LOGIC_VECTOR ( 31 downto 7 );
  signal reg_data_out : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \^s00_axi_bvalid\ : STD_LOGIC;
  signal \^s00_axi_rvalid\ : STD_LOGIC;
  signal sel0 : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal \slv_reg0_reg_n_0_[24]\ : STD_LOGIC;
  signal \slv_reg0_reg_n_0_[25]\ : STD_LOGIC;
  signal \slv_reg0_reg_n_0_[26]\ : STD_LOGIC;
  signal \slv_reg0_reg_n_0_[27]\ : STD_LOGIC;
  signal \slv_reg0_reg_n_0_[28]\ : STD_LOGIC;
  signal \slv_reg0_reg_n_0_[29]\ : STD_LOGIC;
  signal \slv_reg0_reg_n_0_[30]\ : STD_LOGIC;
  signal \slv_reg0_reg_n_0_[31]\ : STD_LOGIC;
  signal \slv_reg1[15]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg1[23]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg1[31]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg1[7]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg2[15]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg2[23]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg2[31]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg2[7]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg3[15]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg3[23]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg3[31]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg3[7]_i_1_n_0\ : STD_LOGIC;
  signal slv_reg4 : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \slv_reg4[15]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg4[23]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg4[31]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg4[7]_i_1_n_0\ : STD_LOGIC;
  signal slv_reg5 : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \slv_reg5[15]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg5[23]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg5[31]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg5[7]_i_1_n_0\ : STD_LOGIC;
  signal slv_reg6 : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \slv_reg6[15]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg6[23]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg6[31]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg6[7]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg7[15]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg7[23]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg7[31]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg7[7]_i_1_n_0\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[10]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[11]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[12]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[13]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[14]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[15]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[16]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[17]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[18]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[19]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[20]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[21]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[22]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[23]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[24]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[25]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[26]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[27]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[28]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[29]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[30]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[31]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[8]\ : STD_LOGIC;
  signal \slv_reg7_reg_n_0_[9]\ : STD_LOGIC;
  signal \slv_reg_rden__0\ : STD_LOGIC;
  signal \slv_reg_wren__0\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \axi_araddr[2]_i_1\ : label is "soft_lutpair8";
  attribute SOFT_HLUTNM of axi_arready_i_1 : label is "soft_lutpair8";
  attribute SOFT_HLUTNM of axi_awready_i_2 : label is "soft_lutpair9";
  attribute SOFT_HLUTNM of axi_wready_i_1 : label is "soft_lutpair9";
begin
  S_AXI_ARREADY <= \^s_axi_arready\;
  S_AXI_AWREADY <= \^s_axi_awready\;
  S_AXI_WREADY <= \^s_axi_wready\;
  s00_axi_bvalid <= \^s00_axi_bvalid\;
  s00_axi_rvalid <= \^s00_axi_rvalid\;
aw_en_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F7FFC4CCC4CCC4CC"
    )
        port map (
      I0 => s00_axi_awvalid,
      I1 => aw_en_reg_n_0,
      I2 => \^s_axi_awready\,
      I3 => s00_axi_wvalid,
      I4 => s00_axi_bready,
      I5 => \^s00_axi_bvalid\,
      O => aw_en_i_1_n_0
    );
aw_en_reg: unisim.vcomponents.FDSE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => aw_en_i_1_n_0,
      Q => aw_en_reg_n_0,
      S => axi_awready_i_1_n_0
    );
\axi_araddr[2]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FB08"
    )
        port map (
      I0 => s00_axi_araddr(0),
      I1 => s00_axi_arvalid,
      I2 => \^s_axi_arready\,
      I3 => sel0(0),
      O => \axi_araddr[2]_i_1_n_0\
    );
\axi_araddr[3]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FB08"
    )
        port map (
      I0 => s00_axi_araddr(1),
      I1 => s00_axi_arvalid,
      I2 => \^s_axi_arready\,
      I3 => sel0(1),
      O => \axi_araddr[3]_i_1_n_0\
    );
\axi_araddr[4]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FB08"
    )
        port map (
      I0 => s00_axi_araddr(2),
      I1 => s00_axi_arvalid,
      I2 => \^s_axi_arready\,
      I3 => sel0(2),
      O => \axi_araddr[4]_i_1_n_0\
    );
\axi_araddr_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => \axi_araddr[2]_i_1_n_0\,
      Q => sel0(0),
      R => axi_awready_i_1_n_0
    );
\axi_araddr_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => \axi_araddr[3]_i_1_n_0\,
      Q => sel0(1),
      R => axi_awready_i_1_n_0
    );
\axi_araddr_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => \axi_araddr[4]_i_1_n_0\,
      Q => sel0(2),
      R => axi_awready_i_1_n_0
    );
axi_arready_i_1: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => s00_axi_arvalid,
      I1 => \^s_axi_arready\,
      O => axi_arready0
    );
axi_arready_reg: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => axi_arready0,
      Q => \^s_axi_arready\,
      R => axi_awready_i_1_n_0
    );
\axi_awaddr[2]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FBFFFFFF08000000"
    )
        port map (
      I0 => s00_axi_awaddr(0),
      I1 => s00_axi_wvalid,
      I2 => \^s_axi_awready\,
      I3 => aw_en_reg_n_0,
      I4 => s00_axi_awvalid,
      I5 => p_0_in(0),
      O => \axi_awaddr[2]_i_1_n_0\
    );
\axi_awaddr[3]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FBFFFFFF08000000"
    )
        port map (
      I0 => s00_axi_awaddr(1),
      I1 => s00_axi_wvalid,
      I2 => \^s_axi_awready\,
      I3 => aw_en_reg_n_0,
      I4 => s00_axi_awvalid,
      I5 => p_0_in(1),
      O => \axi_awaddr[3]_i_1_n_0\
    );
\axi_awaddr[4]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FBFFFFFF08000000"
    )
        port map (
      I0 => s00_axi_awaddr(2),
      I1 => s00_axi_wvalid,
      I2 => \^s_axi_awready\,
      I3 => aw_en_reg_n_0,
      I4 => s00_axi_awvalid,
      I5 => p_0_in(2),
      O => \axi_awaddr[4]_i_1_n_0\
    );
\axi_awaddr_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => \axi_awaddr[2]_i_1_n_0\,
      Q => p_0_in(0),
      R => axi_awready_i_1_n_0
    );
\axi_awaddr_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => \axi_awaddr[3]_i_1_n_0\,
      Q => p_0_in(1),
      R => axi_awready_i_1_n_0
    );
\axi_awaddr_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => \axi_awaddr[4]_i_1_n_0\,
      Q => p_0_in(2),
      R => axi_awready_i_1_n_0
    );
axi_awready_i_1: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => s00_axi_aresetn,
      O => axi_awready_i_1_n_0
    );
axi_awready_i_2: unisim.vcomponents.LUT4
    generic map(
      INIT => X"2000"
    )
        port map (
      I0 => s00_axi_wvalid,
      I1 => \^s_axi_awready\,
      I2 => aw_en_reg_n_0,
      I3 => s00_axi_awvalid,
      O => axi_awready0
    );
axi_awready_reg: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => axi_awready0,
      Q => \^s_axi_awready\,
      R => axi_awready_i_1_n_0
    );
axi_bvalid_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000FFFF80008000"
    )
        port map (
      I0 => s00_axi_awvalid,
      I1 => s00_axi_wvalid,
      I2 => \^s_axi_awready\,
      I3 => \^s_axi_wready\,
      I4 => s00_axi_bready,
      I5 => \^s00_axi_bvalid\,
      O => axi_bvalid_i_1_n_0
    );
axi_bvalid_reg: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => axi_bvalid_i_1_n_0,
      Q => \^s00_axi_bvalid\,
      R => axi_awready_i_1_n_0
    );
\axi_rdata[0]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => p_12_in(0),
      I1 => data11(0),
      I2 => sel0(1),
      I3 => data7(0),
      I4 => sel0(0),
      I5 => data3(0),
      O => \axi_rdata[0]_i_2_n_0\
    );
\axi_rdata[0]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data15(0),
      I1 => slv_reg6(0),
      I2 => sel0(1),
      I3 => slv_reg5(0),
      I4 => sel0(0),
      I5 => slv_reg4(0),
      O => \axi_rdata[0]_i_3_n_0\
    );
\axi_rdata[10]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data14(2),
      I1 => data10(2),
      I2 => sel0(1),
      I3 => data6(2),
      I4 => sel0(0),
      I5 => data2(2),
      O => \axi_rdata[10]_i_2_n_0\
    );
\axi_rdata[10]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[10]\,
      I1 => slv_reg6(10),
      I2 => sel0(1),
      I3 => slv_reg5(10),
      I4 => sel0(0),
      I5 => slv_reg4(10),
      O => \axi_rdata[10]_i_3_n_0\
    );
\axi_rdata[11]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data14(3),
      I1 => data10(3),
      I2 => sel0(1),
      I3 => data6(3),
      I4 => sel0(0),
      I5 => data2(3),
      O => \axi_rdata[11]_i_2_n_0\
    );
\axi_rdata[11]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[11]\,
      I1 => slv_reg6(11),
      I2 => sel0(1),
      I3 => slv_reg5(11),
      I4 => sel0(0),
      I5 => slv_reg4(11),
      O => \axi_rdata[11]_i_3_n_0\
    );
\axi_rdata[12]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data14(4),
      I1 => data10(4),
      I2 => sel0(1),
      I3 => data6(4),
      I4 => sel0(0),
      I5 => data2(4),
      O => \axi_rdata[12]_i_2_n_0\
    );
\axi_rdata[12]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[12]\,
      I1 => slv_reg6(12),
      I2 => sel0(1),
      I3 => slv_reg5(12),
      I4 => sel0(0),
      I5 => slv_reg4(12),
      O => \axi_rdata[12]_i_3_n_0\
    );
\axi_rdata[13]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data14(5),
      I1 => data10(5),
      I2 => sel0(1),
      I3 => data6(5),
      I4 => sel0(0),
      I5 => data2(5),
      O => \axi_rdata[13]_i_2_n_0\
    );
\axi_rdata[13]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[13]\,
      I1 => slv_reg6(13),
      I2 => sel0(1),
      I3 => slv_reg5(13),
      I4 => sel0(0),
      I5 => slv_reg4(13),
      O => \axi_rdata[13]_i_3_n_0\
    );
\axi_rdata[14]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data14(6),
      I1 => data10(6),
      I2 => sel0(1),
      I3 => data6(6),
      I4 => sel0(0),
      I5 => data2(6),
      O => \axi_rdata[14]_i_2_n_0\
    );
\axi_rdata[14]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[14]\,
      I1 => slv_reg6(14),
      I2 => sel0(1),
      I3 => slv_reg5(14),
      I4 => sel0(0),
      I5 => slv_reg4(14),
      O => \axi_rdata[14]_i_3_n_0\
    );
\axi_rdata[15]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data14(7),
      I1 => data10(7),
      I2 => sel0(1),
      I3 => data6(7),
      I4 => sel0(0),
      I5 => data2(7),
      O => \axi_rdata[15]_i_2_n_0\
    );
\axi_rdata[15]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[15]\,
      I1 => slv_reg6(15),
      I2 => sel0(1),
      I3 => slv_reg5(15),
      I4 => sel0(0),
      I5 => slv_reg4(15),
      O => \axi_rdata[15]_i_3_n_0\
    );
\axi_rdata[16]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data13(0),
      I1 => data9(0),
      I2 => sel0(1),
      I3 => data5(0),
      I4 => sel0(0),
      I5 => data1(0),
      O => \axi_rdata[16]_i_2_n_0\
    );
\axi_rdata[16]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[16]\,
      I1 => slv_reg6(16),
      I2 => sel0(1),
      I3 => slv_reg5(16),
      I4 => sel0(0),
      I5 => slv_reg4(16),
      O => \axi_rdata[16]_i_3_n_0\
    );
\axi_rdata[17]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data13(1),
      I1 => data9(1),
      I2 => sel0(1),
      I3 => data5(1),
      I4 => sel0(0),
      I5 => data1(1),
      O => \axi_rdata[17]_i_2_n_0\
    );
\axi_rdata[17]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[17]\,
      I1 => slv_reg6(17),
      I2 => sel0(1),
      I3 => slv_reg5(17),
      I4 => sel0(0),
      I5 => slv_reg4(17),
      O => \axi_rdata[17]_i_3_n_0\
    );
\axi_rdata[18]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data13(2),
      I1 => data9(2),
      I2 => sel0(1),
      I3 => data5(2),
      I4 => sel0(0),
      I5 => data1(2),
      O => \axi_rdata[18]_i_2_n_0\
    );
\axi_rdata[18]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[18]\,
      I1 => slv_reg6(18),
      I2 => sel0(1),
      I3 => slv_reg5(18),
      I4 => sel0(0),
      I5 => slv_reg4(18),
      O => \axi_rdata[18]_i_3_n_0\
    );
\axi_rdata[19]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data13(3),
      I1 => data9(3),
      I2 => sel0(1),
      I3 => data5(3),
      I4 => sel0(0),
      I5 => data1(3),
      O => \axi_rdata[19]_i_2_n_0\
    );
\axi_rdata[19]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[19]\,
      I1 => slv_reg6(19),
      I2 => sel0(1),
      I3 => slv_reg5(19),
      I4 => sel0(0),
      I5 => slv_reg4(19),
      O => \axi_rdata[19]_i_3_n_0\
    );
\axi_rdata[1]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => p_12_in(1),
      I1 => data11(1),
      I2 => sel0(1),
      I3 => data7(1),
      I4 => sel0(0),
      I5 => data3(1),
      O => \axi_rdata[1]_i_2_n_0\
    );
\axi_rdata[1]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data15(1),
      I1 => slv_reg6(1),
      I2 => sel0(1),
      I3 => slv_reg5(1),
      I4 => sel0(0),
      I5 => slv_reg4(1),
      O => \axi_rdata[1]_i_3_n_0\
    );
\axi_rdata[20]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data13(4),
      I1 => data9(4),
      I2 => sel0(1),
      I3 => data5(4),
      I4 => sel0(0),
      I5 => data1(4),
      O => \axi_rdata[20]_i_2_n_0\
    );
\axi_rdata[20]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[20]\,
      I1 => slv_reg6(20),
      I2 => sel0(1),
      I3 => slv_reg5(20),
      I4 => sel0(0),
      I5 => slv_reg4(20),
      O => \axi_rdata[20]_i_3_n_0\
    );
\axi_rdata[21]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data13(5),
      I1 => data9(5),
      I2 => sel0(1),
      I3 => data5(5),
      I4 => sel0(0),
      I5 => data1(5),
      O => \axi_rdata[21]_i_2_n_0\
    );
\axi_rdata[21]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[21]\,
      I1 => slv_reg6(21),
      I2 => sel0(1),
      I3 => slv_reg5(21),
      I4 => sel0(0),
      I5 => slv_reg4(21),
      O => \axi_rdata[21]_i_3_n_0\
    );
\axi_rdata[22]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data13(6),
      I1 => data9(6),
      I2 => sel0(1),
      I3 => data5(6),
      I4 => sel0(0),
      I5 => data1(6),
      O => \axi_rdata[22]_i_2_n_0\
    );
\axi_rdata[22]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[22]\,
      I1 => slv_reg6(22),
      I2 => sel0(1),
      I3 => slv_reg5(22),
      I4 => sel0(0),
      I5 => slv_reg4(22),
      O => \axi_rdata[22]_i_3_n_0\
    );
\axi_rdata[23]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data13(7),
      I1 => data9(7),
      I2 => sel0(1),
      I3 => data5(7),
      I4 => sel0(0),
      I5 => data1(7),
      O => \axi_rdata[23]_i_2_n_0\
    );
\axi_rdata[23]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[23]\,
      I1 => slv_reg6(23),
      I2 => sel0(1),
      I3 => slv_reg5(23),
      I4 => sel0(0),
      I5 => slv_reg4(23),
      O => \axi_rdata[23]_i_3_n_0\
    );
\axi_rdata[24]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data12(0),
      I1 => data8(0),
      I2 => sel0(1),
      I3 => data4(0),
      I4 => sel0(0),
      I5 => \slv_reg0_reg_n_0_[24]\,
      O => \axi_rdata[24]_i_2_n_0\
    );
\axi_rdata[24]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[24]\,
      I1 => slv_reg6(24),
      I2 => sel0(1),
      I3 => slv_reg5(24),
      I4 => sel0(0),
      I5 => slv_reg4(24),
      O => \axi_rdata[24]_i_3_n_0\
    );
\axi_rdata[25]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data12(1),
      I1 => data8(1),
      I2 => sel0(1),
      I3 => data4(1),
      I4 => sel0(0),
      I5 => \slv_reg0_reg_n_0_[25]\,
      O => \axi_rdata[25]_i_2_n_0\
    );
\axi_rdata[25]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[25]\,
      I1 => slv_reg6(25),
      I2 => sel0(1),
      I3 => slv_reg5(25),
      I4 => sel0(0),
      I5 => slv_reg4(25),
      O => \axi_rdata[25]_i_3_n_0\
    );
\axi_rdata[26]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data12(2),
      I1 => data8(2),
      I2 => sel0(1),
      I3 => data4(2),
      I4 => sel0(0),
      I5 => \slv_reg0_reg_n_0_[26]\,
      O => \axi_rdata[26]_i_2_n_0\
    );
\axi_rdata[26]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[26]\,
      I1 => slv_reg6(26),
      I2 => sel0(1),
      I3 => slv_reg5(26),
      I4 => sel0(0),
      I5 => slv_reg4(26),
      O => \axi_rdata[26]_i_3_n_0\
    );
\axi_rdata[27]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data12(3),
      I1 => data8(3),
      I2 => sel0(1),
      I3 => data4(3),
      I4 => sel0(0),
      I5 => \slv_reg0_reg_n_0_[27]\,
      O => \axi_rdata[27]_i_2_n_0\
    );
\axi_rdata[27]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[27]\,
      I1 => slv_reg6(27),
      I2 => sel0(1),
      I3 => slv_reg5(27),
      I4 => sel0(0),
      I5 => slv_reg4(27),
      O => \axi_rdata[27]_i_3_n_0\
    );
\axi_rdata[28]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data12(4),
      I1 => data8(4),
      I2 => sel0(1),
      I3 => data4(4),
      I4 => sel0(0),
      I5 => \slv_reg0_reg_n_0_[28]\,
      O => \axi_rdata[28]_i_2_n_0\
    );
\axi_rdata[28]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[28]\,
      I1 => slv_reg6(28),
      I2 => sel0(1),
      I3 => slv_reg5(28),
      I4 => sel0(0),
      I5 => slv_reg4(28),
      O => \axi_rdata[28]_i_3_n_0\
    );
\axi_rdata[29]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data12(5),
      I1 => data8(5),
      I2 => sel0(1),
      I3 => data4(5),
      I4 => sel0(0),
      I5 => \slv_reg0_reg_n_0_[29]\,
      O => \axi_rdata[29]_i_2_n_0\
    );
\axi_rdata[29]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[29]\,
      I1 => slv_reg6(29),
      I2 => sel0(1),
      I3 => slv_reg5(29),
      I4 => sel0(0),
      I5 => slv_reg4(29),
      O => \axi_rdata[29]_i_3_n_0\
    );
\axi_rdata[2]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => p_12_in(2),
      I1 => data11(2),
      I2 => sel0(1),
      I3 => data7(2),
      I4 => sel0(0),
      I5 => data3(2),
      O => \axi_rdata[2]_i_2_n_0\
    );
\axi_rdata[2]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data15(2),
      I1 => slv_reg6(2),
      I2 => sel0(1),
      I3 => slv_reg5(2),
      I4 => sel0(0),
      I5 => slv_reg4(2),
      O => \axi_rdata[2]_i_3_n_0\
    );
\axi_rdata[30]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data12(6),
      I1 => data8(6),
      I2 => sel0(1),
      I3 => data4(6),
      I4 => sel0(0),
      I5 => \slv_reg0_reg_n_0_[30]\,
      O => \axi_rdata[30]_i_2_n_0\
    );
\axi_rdata[30]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[30]\,
      I1 => slv_reg6(30),
      I2 => sel0(1),
      I3 => slv_reg5(30),
      I4 => sel0(0),
      I5 => slv_reg4(30),
      O => \axi_rdata[30]_i_3_n_0\
    );
\axi_rdata[31]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data12(7),
      I1 => data8(7),
      I2 => sel0(1),
      I3 => data4(7),
      I4 => sel0(0),
      I5 => \slv_reg0_reg_n_0_[31]\,
      O => \axi_rdata[31]_i_2_n_0\
    );
\axi_rdata[31]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[31]\,
      I1 => slv_reg6(31),
      I2 => sel0(1),
      I3 => slv_reg5(31),
      I4 => sel0(0),
      I5 => slv_reg4(31),
      O => \axi_rdata[31]_i_3_n_0\
    );
\axi_rdata[3]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => p_12_in(3),
      I1 => data11(3),
      I2 => sel0(1),
      I3 => data7(3),
      I4 => sel0(0),
      I5 => data3(3),
      O => \axi_rdata[3]_i_2_n_0\
    );
\axi_rdata[3]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data15(3),
      I1 => slv_reg6(3),
      I2 => sel0(1),
      I3 => slv_reg5(3),
      I4 => sel0(0),
      I5 => slv_reg4(3),
      O => \axi_rdata[3]_i_3_n_0\
    );
\axi_rdata[4]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => p_12_in(4),
      I1 => data11(4),
      I2 => sel0(1),
      I3 => data7(4),
      I4 => sel0(0),
      I5 => data3(4),
      O => \axi_rdata[4]_i_2_n_0\
    );
\axi_rdata[4]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data15(4),
      I1 => slv_reg6(4),
      I2 => sel0(1),
      I3 => slv_reg5(4),
      I4 => sel0(0),
      I5 => slv_reg4(4),
      O => \axi_rdata[4]_i_3_n_0\
    );
\axi_rdata[5]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => p_12_in(5),
      I1 => data11(5),
      I2 => sel0(1),
      I3 => data7(5),
      I4 => sel0(0),
      I5 => data3(5),
      O => \axi_rdata[5]_i_2_n_0\
    );
\axi_rdata[5]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data15(5),
      I1 => slv_reg6(5),
      I2 => sel0(1),
      I3 => slv_reg5(5),
      I4 => sel0(0),
      I5 => slv_reg4(5),
      O => \axi_rdata[5]_i_3_n_0\
    );
\axi_rdata[6]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => p_12_in(6),
      I1 => data11(6),
      I2 => sel0(1),
      I3 => data7(6),
      I4 => sel0(0),
      I5 => data3(6),
      O => \axi_rdata[6]_i_2_n_0\
    );
\axi_rdata[6]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data15(6),
      I1 => slv_reg6(6),
      I2 => sel0(1),
      I3 => slv_reg5(6),
      I4 => sel0(0),
      I5 => slv_reg4(6),
      O => \axi_rdata[6]_i_3_n_0\
    );
\axi_rdata[7]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => p_12_in(7),
      I1 => data11(7),
      I2 => sel0(1),
      I3 => data7(7),
      I4 => sel0(0),
      I5 => data3(7),
      O => \axi_rdata[7]_i_2_n_0\
    );
\axi_rdata[7]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data15(7),
      I1 => slv_reg6(7),
      I2 => sel0(1),
      I3 => slv_reg5(7),
      I4 => sel0(0),
      I5 => slv_reg4(7),
      O => \axi_rdata[7]_i_3_n_0\
    );
\axi_rdata[8]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data14(0),
      I1 => data10(0),
      I2 => sel0(1),
      I3 => data6(0),
      I4 => sel0(0),
      I5 => data2(0),
      O => \axi_rdata[8]_i_2_n_0\
    );
\axi_rdata[8]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[8]\,
      I1 => slv_reg6(8),
      I2 => sel0(1),
      I3 => slv_reg5(8),
      I4 => sel0(0),
      I5 => slv_reg4(8),
      O => \axi_rdata[8]_i_3_n_0\
    );
\axi_rdata[9]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => data14(1),
      I1 => data10(1),
      I2 => sel0(1),
      I3 => data6(1),
      I4 => sel0(0),
      I5 => data2(1),
      O => \axi_rdata[9]_i_2_n_0\
    );
\axi_rdata[9]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => \slv_reg7_reg_n_0_[9]\,
      I1 => slv_reg6(9),
      I2 => sel0(1),
      I3 => slv_reg5(9),
      I4 => sel0(0),
      I5 => slv_reg4(9),
      O => \axi_rdata[9]_i_3_n_0\
    );
\axi_rdata_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(0),
      Q => s00_axi_rdata(0),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[0]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[0]_i_2_n_0\,
      I1 => \axi_rdata[0]_i_3_n_0\,
      O => reg_data_out(0),
      S => sel0(2)
    );
\axi_rdata_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(10),
      Q => s00_axi_rdata(10),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[10]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[10]_i_2_n_0\,
      I1 => \axi_rdata[10]_i_3_n_0\,
      O => reg_data_out(10),
      S => sel0(2)
    );
\axi_rdata_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(11),
      Q => s00_axi_rdata(11),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[11]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[11]_i_2_n_0\,
      I1 => \axi_rdata[11]_i_3_n_0\,
      O => reg_data_out(11),
      S => sel0(2)
    );
\axi_rdata_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(12),
      Q => s00_axi_rdata(12),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[12]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[12]_i_2_n_0\,
      I1 => \axi_rdata[12]_i_3_n_0\,
      O => reg_data_out(12),
      S => sel0(2)
    );
\axi_rdata_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(13),
      Q => s00_axi_rdata(13),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[13]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[13]_i_2_n_0\,
      I1 => \axi_rdata[13]_i_3_n_0\,
      O => reg_data_out(13),
      S => sel0(2)
    );
\axi_rdata_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(14),
      Q => s00_axi_rdata(14),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[14]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[14]_i_2_n_0\,
      I1 => \axi_rdata[14]_i_3_n_0\,
      O => reg_data_out(14),
      S => sel0(2)
    );
\axi_rdata_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(15),
      Q => s00_axi_rdata(15),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[15]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[15]_i_2_n_0\,
      I1 => \axi_rdata[15]_i_3_n_0\,
      O => reg_data_out(15),
      S => sel0(2)
    );
\axi_rdata_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(16),
      Q => s00_axi_rdata(16),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[16]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[16]_i_2_n_0\,
      I1 => \axi_rdata[16]_i_3_n_0\,
      O => reg_data_out(16),
      S => sel0(2)
    );
\axi_rdata_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(17),
      Q => s00_axi_rdata(17),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[17]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[17]_i_2_n_0\,
      I1 => \axi_rdata[17]_i_3_n_0\,
      O => reg_data_out(17),
      S => sel0(2)
    );
\axi_rdata_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(18),
      Q => s00_axi_rdata(18),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[18]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[18]_i_2_n_0\,
      I1 => \axi_rdata[18]_i_3_n_0\,
      O => reg_data_out(18),
      S => sel0(2)
    );
\axi_rdata_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(19),
      Q => s00_axi_rdata(19),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[19]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[19]_i_2_n_0\,
      I1 => \axi_rdata[19]_i_3_n_0\,
      O => reg_data_out(19),
      S => sel0(2)
    );
\axi_rdata_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(1),
      Q => s00_axi_rdata(1),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[1]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[1]_i_2_n_0\,
      I1 => \axi_rdata[1]_i_3_n_0\,
      O => reg_data_out(1),
      S => sel0(2)
    );
\axi_rdata_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(20),
      Q => s00_axi_rdata(20),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[20]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[20]_i_2_n_0\,
      I1 => \axi_rdata[20]_i_3_n_0\,
      O => reg_data_out(20),
      S => sel0(2)
    );
\axi_rdata_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(21),
      Q => s00_axi_rdata(21),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[21]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[21]_i_2_n_0\,
      I1 => \axi_rdata[21]_i_3_n_0\,
      O => reg_data_out(21),
      S => sel0(2)
    );
\axi_rdata_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(22),
      Q => s00_axi_rdata(22),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[22]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[22]_i_2_n_0\,
      I1 => \axi_rdata[22]_i_3_n_0\,
      O => reg_data_out(22),
      S => sel0(2)
    );
\axi_rdata_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(23),
      Q => s00_axi_rdata(23),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[23]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[23]_i_2_n_0\,
      I1 => \axi_rdata[23]_i_3_n_0\,
      O => reg_data_out(23),
      S => sel0(2)
    );
\axi_rdata_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(24),
      Q => s00_axi_rdata(24),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[24]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[24]_i_2_n_0\,
      I1 => \axi_rdata[24]_i_3_n_0\,
      O => reg_data_out(24),
      S => sel0(2)
    );
\axi_rdata_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(25),
      Q => s00_axi_rdata(25),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[25]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[25]_i_2_n_0\,
      I1 => \axi_rdata[25]_i_3_n_0\,
      O => reg_data_out(25),
      S => sel0(2)
    );
\axi_rdata_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(26),
      Q => s00_axi_rdata(26),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[26]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[26]_i_2_n_0\,
      I1 => \axi_rdata[26]_i_3_n_0\,
      O => reg_data_out(26),
      S => sel0(2)
    );
\axi_rdata_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(27),
      Q => s00_axi_rdata(27),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[27]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[27]_i_2_n_0\,
      I1 => \axi_rdata[27]_i_3_n_0\,
      O => reg_data_out(27),
      S => sel0(2)
    );
\axi_rdata_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(28),
      Q => s00_axi_rdata(28),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[28]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[28]_i_2_n_0\,
      I1 => \axi_rdata[28]_i_3_n_0\,
      O => reg_data_out(28),
      S => sel0(2)
    );
\axi_rdata_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(29),
      Q => s00_axi_rdata(29),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[29]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[29]_i_2_n_0\,
      I1 => \axi_rdata[29]_i_3_n_0\,
      O => reg_data_out(29),
      S => sel0(2)
    );
\axi_rdata_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(2),
      Q => s00_axi_rdata(2),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[2]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[2]_i_2_n_0\,
      I1 => \axi_rdata[2]_i_3_n_0\,
      O => reg_data_out(2),
      S => sel0(2)
    );
\axi_rdata_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(30),
      Q => s00_axi_rdata(30),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[30]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[30]_i_2_n_0\,
      I1 => \axi_rdata[30]_i_3_n_0\,
      O => reg_data_out(30),
      S => sel0(2)
    );
\axi_rdata_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(31),
      Q => s00_axi_rdata(31),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[31]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[31]_i_2_n_0\,
      I1 => \axi_rdata[31]_i_3_n_0\,
      O => reg_data_out(31),
      S => sel0(2)
    );
\axi_rdata_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(3),
      Q => s00_axi_rdata(3),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[3]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[3]_i_2_n_0\,
      I1 => \axi_rdata[3]_i_3_n_0\,
      O => reg_data_out(3),
      S => sel0(2)
    );
\axi_rdata_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(4),
      Q => s00_axi_rdata(4),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[4]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[4]_i_2_n_0\,
      I1 => \axi_rdata[4]_i_3_n_0\,
      O => reg_data_out(4),
      S => sel0(2)
    );
\axi_rdata_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(5),
      Q => s00_axi_rdata(5),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[5]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[5]_i_2_n_0\,
      I1 => \axi_rdata[5]_i_3_n_0\,
      O => reg_data_out(5),
      S => sel0(2)
    );
\axi_rdata_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(6),
      Q => s00_axi_rdata(6),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[6]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[6]_i_2_n_0\,
      I1 => \axi_rdata[6]_i_3_n_0\,
      O => reg_data_out(6),
      S => sel0(2)
    );
\axi_rdata_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(7),
      Q => s00_axi_rdata(7),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[7]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[7]_i_2_n_0\,
      I1 => \axi_rdata[7]_i_3_n_0\,
      O => reg_data_out(7),
      S => sel0(2)
    );
\axi_rdata_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(8),
      Q => s00_axi_rdata(8),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[8]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[8]_i_2_n_0\,
      I1 => \axi_rdata[8]_i_3_n_0\,
      O => reg_data_out(8),
      S => sel0(2)
    );
\axi_rdata_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg_rden__0\,
      D => reg_data_out(9),
      Q => s00_axi_rdata(9),
      R => axi_awready_i_1_n_0
    );
\axi_rdata_reg[9]_i_1\: unisim.vcomponents.MUXF7
     port map (
      I0 => \axi_rdata[9]_i_2_n_0\,
      I1 => \axi_rdata[9]_i_3_n_0\,
      O => reg_data_out(9),
      S => sel0(2)
    );
axi_rvalid_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"08F8"
    )
        port map (
      I0 => \^s_axi_arready\,
      I1 => s00_axi_arvalid,
      I2 => \^s00_axi_rvalid\,
      I3 => s00_axi_rready,
      O => axi_rvalid_i_1_n_0
    );
axi_rvalid_reg: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => axi_rvalid_i_1_n_0,
      Q => \^s00_axi_rvalid\,
      R => axi_awready_i_1_n_0
    );
axi_wready_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0800"
    )
        port map (
      I0 => s00_axi_awvalid,
      I1 => s00_axi_wvalid,
      I2 => \^s_axi_wready\,
      I3 => aw_en_reg_n_0,
      O => axi_wready0
    );
axi_wready_reg: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => '1',
      D => axi_wready0,
      Q => \^s_axi_wready\,
      R => axi_awready_i_1_n_0
    );
\slv_reg0[15]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00020000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(1),
      O => p_1_in(15)
    );
\slv_reg0[23]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00020000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(2),
      O => p_1_in(23)
    );
\slv_reg0[31]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00020000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(3),
      O => p_1_in(31)
    );
\slv_reg0[7]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00020000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(0),
      O => p_1_in(7)
    );
\slv_reg0_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(7),
      D => s00_axi_wdata(0),
      Q => data3(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(15),
      D => s00_axi_wdata(10),
      Q => data2(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(15),
      D => s00_axi_wdata(11),
      Q => data2(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(15),
      D => s00_axi_wdata(12),
      Q => data2(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(15),
      D => s00_axi_wdata(13),
      Q => data2(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(15),
      D => s00_axi_wdata(14),
      Q => data2(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(15),
      D => s00_axi_wdata(15),
      Q => data2(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(23),
      D => s00_axi_wdata(16),
      Q => data1(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(23),
      D => s00_axi_wdata(17),
      Q => data1(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(23),
      D => s00_axi_wdata(18),
      Q => data1(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(23),
      D => s00_axi_wdata(19),
      Q => data1(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(7),
      D => s00_axi_wdata(1),
      Q => data3(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(23),
      D => s00_axi_wdata(20),
      Q => data1(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(23),
      D => s00_axi_wdata(21),
      Q => data1(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(23),
      D => s00_axi_wdata(22),
      Q => data1(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(23),
      D => s00_axi_wdata(23),
      Q => data1(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(31),
      D => s00_axi_wdata(24),
      Q => \slv_reg0_reg_n_0_[24]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(31),
      D => s00_axi_wdata(25),
      Q => \slv_reg0_reg_n_0_[25]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(31),
      D => s00_axi_wdata(26),
      Q => \slv_reg0_reg_n_0_[26]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(31),
      D => s00_axi_wdata(27),
      Q => \slv_reg0_reg_n_0_[27]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(31),
      D => s00_axi_wdata(28),
      Q => \slv_reg0_reg_n_0_[28]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(31),
      D => s00_axi_wdata(29),
      Q => \slv_reg0_reg_n_0_[29]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(7),
      D => s00_axi_wdata(2),
      Q => data3(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(31),
      D => s00_axi_wdata(30),
      Q => \slv_reg0_reg_n_0_[30]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(31),
      D => s00_axi_wdata(31),
      Q => \slv_reg0_reg_n_0_[31]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(7),
      D => s00_axi_wdata(3),
      Q => data3(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(7),
      D => s00_axi_wdata(4),
      Q => data3(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(7),
      D => s00_axi_wdata(5),
      Q => data3(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(7),
      D => s00_axi_wdata(6),
      Q => data3(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(7),
      D => s00_axi_wdata(7),
      Q => data3(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(15),
      D => s00_axi_wdata(8),
      Q => data2(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg0_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => p_1_in(15),
      D => s00_axi_wdata(9),
      Q => data2(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg1[15]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(1),
      I3 => s00_axi_wstrb(1),
      I4 => p_0_in(0),
      O => \slv_reg1[15]_i_1_n_0\
    );
\slv_reg1[23]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(1),
      I3 => s00_axi_wstrb(2),
      I4 => p_0_in(0),
      O => \slv_reg1[23]_i_1_n_0\
    );
\slv_reg1[31]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(1),
      I3 => s00_axi_wstrb(3),
      I4 => p_0_in(0),
      O => \slv_reg1[31]_i_1_n_0\
    );
\slv_reg1[7]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(1),
      I3 => s00_axi_wstrb(0),
      I4 => p_0_in(0),
      O => \slv_reg1[7]_i_1_n_0\
    );
\slv_reg1_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[7]_i_1_n_0\,
      D => s00_axi_wdata(0),
      Q => data7(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[15]_i_1_n_0\,
      D => s00_axi_wdata(10),
      Q => data6(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[15]_i_1_n_0\,
      D => s00_axi_wdata(11),
      Q => data6(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[15]_i_1_n_0\,
      D => s00_axi_wdata(12),
      Q => data6(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[15]_i_1_n_0\,
      D => s00_axi_wdata(13),
      Q => data6(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[15]_i_1_n_0\,
      D => s00_axi_wdata(14),
      Q => data6(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[15]_i_1_n_0\,
      D => s00_axi_wdata(15),
      Q => data6(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[23]_i_1_n_0\,
      D => s00_axi_wdata(16),
      Q => data5(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[23]_i_1_n_0\,
      D => s00_axi_wdata(17),
      Q => data5(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[23]_i_1_n_0\,
      D => s00_axi_wdata(18),
      Q => data5(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[23]_i_1_n_0\,
      D => s00_axi_wdata(19),
      Q => data5(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[7]_i_1_n_0\,
      D => s00_axi_wdata(1),
      Q => data7(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[23]_i_1_n_0\,
      D => s00_axi_wdata(20),
      Q => data5(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[23]_i_1_n_0\,
      D => s00_axi_wdata(21),
      Q => data5(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[23]_i_1_n_0\,
      D => s00_axi_wdata(22),
      Q => data5(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[23]_i_1_n_0\,
      D => s00_axi_wdata(23),
      Q => data5(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[31]_i_1_n_0\,
      D => s00_axi_wdata(24),
      Q => data4(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[31]_i_1_n_0\,
      D => s00_axi_wdata(25),
      Q => data4(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[31]_i_1_n_0\,
      D => s00_axi_wdata(26),
      Q => data4(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[31]_i_1_n_0\,
      D => s00_axi_wdata(27),
      Q => data4(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[31]_i_1_n_0\,
      D => s00_axi_wdata(28),
      Q => data4(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[31]_i_1_n_0\,
      D => s00_axi_wdata(29),
      Q => data4(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[7]_i_1_n_0\,
      D => s00_axi_wdata(2),
      Q => data7(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[31]_i_1_n_0\,
      D => s00_axi_wdata(30),
      Q => data4(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[31]_i_1_n_0\,
      D => s00_axi_wdata(31),
      Q => data4(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[7]_i_1_n_0\,
      D => s00_axi_wdata(3),
      Q => data7(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[7]_i_1_n_0\,
      D => s00_axi_wdata(4),
      Q => data7(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[7]_i_1_n_0\,
      D => s00_axi_wdata(5),
      Q => data7(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[7]_i_1_n_0\,
      D => s00_axi_wdata(6),
      Q => data7(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[7]_i_1_n_0\,
      D => s00_axi_wdata(7),
      Q => data7(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[15]_i_1_n_0\,
      D => s00_axi_wdata(8),
      Q => data6(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg1_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg1[15]_i_1_n_0\,
      D => s00_axi_wdata(9),
      Q => data6(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg2[15]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(0),
      I3 => s00_axi_wstrb(1),
      I4 => p_0_in(1),
      O => \slv_reg2[15]_i_1_n_0\
    );
\slv_reg2[23]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(0),
      I3 => s00_axi_wstrb(2),
      I4 => p_0_in(1),
      O => \slv_reg2[23]_i_1_n_0\
    );
\slv_reg2[31]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(0),
      I3 => s00_axi_wstrb(3),
      I4 => p_0_in(1),
      O => \slv_reg2[31]_i_1_n_0\
    );
\slv_reg2[7]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(0),
      I3 => s00_axi_wstrb(0),
      I4 => p_0_in(1),
      O => \slv_reg2[7]_i_1_n_0\
    );
\slv_reg2_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[7]_i_1_n_0\,
      D => s00_axi_wdata(0),
      Q => data11(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[15]_i_1_n_0\,
      D => s00_axi_wdata(10),
      Q => data10(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[15]_i_1_n_0\,
      D => s00_axi_wdata(11),
      Q => data10(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[15]_i_1_n_0\,
      D => s00_axi_wdata(12),
      Q => data10(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[15]_i_1_n_0\,
      D => s00_axi_wdata(13),
      Q => data10(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[15]_i_1_n_0\,
      D => s00_axi_wdata(14),
      Q => data10(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[15]_i_1_n_0\,
      D => s00_axi_wdata(15),
      Q => data10(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[23]_i_1_n_0\,
      D => s00_axi_wdata(16),
      Q => data9(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[23]_i_1_n_0\,
      D => s00_axi_wdata(17),
      Q => data9(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[23]_i_1_n_0\,
      D => s00_axi_wdata(18),
      Q => data9(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[23]_i_1_n_0\,
      D => s00_axi_wdata(19),
      Q => data9(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[7]_i_1_n_0\,
      D => s00_axi_wdata(1),
      Q => data11(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[23]_i_1_n_0\,
      D => s00_axi_wdata(20),
      Q => data9(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[23]_i_1_n_0\,
      D => s00_axi_wdata(21),
      Q => data9(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[23]_i_1_n_0\,
      D => s00_axi_wdata(22),
      Q => data9(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[23]_i_1_n_0\,
      D => s00_axi_wdata(23),
      Q => data9(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[31]_i_1_n_0\,
      D => s00_axi_wdata(24),
      Q => data8(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[31]_i_1_n_0\,
      D => s00_axi_wdata(25),
      Q => data8(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[31]_i_1_n_0\,
      D => s00_axi_wdata(26),
      Q => data8(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[31]_i_1_n_0\,
      D => s00_axi_wdata(27),
      Q => data8(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[31]_i_1_n_0\,
      D => s00_axi_wdata(28),
      Q => data8(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[31]_i_1_n_0\,
      D => s00_axi_wdata(29),
      Q => data8(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[7]_i_1_n_0\,
      D => s00_axi_wdata(2),
      Q => data11(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[31]_i_1_n_0\,
      D => s00_axi_wdata(30),
      Q => data8(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[31]_i_1_n_0\,
      D => s00_axi_wdata(31),
      Q => data8(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[7]_i_1_n_0\,
      D => s00_axi_wdata(3),
      Q => data11(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[7]_i_1_n_0\,
      D => s00_axi_wdata(4),
      Q => data11(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[7]_i_1_n_0\,
      D => s00_axi_wdata(5),
      Q => data11(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[7]_i_1_n_0\,
      D => s00_axi_wdata(6),
      Q => data11(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[7]_i_1_n_0\,
      D => s00_axi_wdata(7),
      Q => data11(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[15]_i_1_n_0\,
      D => s00_axi_wdata(8),
      Q => data10(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg2_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg2[15]_i_1_n_0\,
      D => s00_axi_wdata(9),
      Q => data10(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg3[15]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(1),
      I3 => p_0_in(0),
      I4 => s00_axi_wstrb(1),
      O => \slv_reg3[15]_i_1_n_0\
    );
\slv_reg3[23]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(1),
      I3 => p_0_in(0),
      I4 => s00_axi_wstrb(2),
      O => \slv_reg3[23]_i_1_n_0\
    );
\slv_reg3[31]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(1),
      I3 => p_0_in(0),
      I4 => s00_axi_wstrb(3),
      O => \slv_reg3[31]_i_1_n_0\
    );
\slv_reg3[31]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8000"
    )
        port map (
      I0 => \^s_axi_wready\,
      I1 => \^s_axi_awready\,
      I2 => s00_axi_awvalid,
      I3 => s00_axi_wvalid,
      O => \slv_reg_wren__0\
    );
\slv_reg3[7]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(2),
      I2 => p_0_in(1),
      I3 => p_0_in(0),
      I4 => s00_axi_wstrb(0),
      O => \slv_reg3[7]_i_1_n_0\
    );
\slv_reg3_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[7]_i_1_n_0\,
      D => s00_axi_wdata(0),
      Q => p_12_in(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[15]_i_1_n_0\,
      D => s00_axi_wdata(10),
      Q => data14(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[15]_i_1_n_0\,
      D => s00_axi_wdata(11),
      Q => data14(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[15]_i_1_n_0\,
      D => s00_axi_wdata(12),
      Q => data14(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[15]_i_1_n_0\,
      D => s00_axi_wdata(13),
      Q => data14(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[15]_i_1_n_0\,
      D => s00_axi_wdata(14),
      Q => data14(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[15]_i_1_n_0\,
      D => s00_axi_wdata(15),
      Q => data14(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[23]_i_1_n_0\,
      D => s00_axi_wdata(16),
      Q => data13(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[23]_i_1_n_0\,
      D => s00_axi_wdata(17),
      Q => data13(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[23]_i_1_n_0\,
      D => s00_axi_wdata(18),
      Q => data13(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[23]_i_1_n_0\,
      D => s00_axi_wdata(19),
      Q => data13(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[7]_i_1_n_0\,
      D => s00_axi_wdata(1),
      Q => p_12_in(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[23]_i_1_n_0\,
      D => s00_axi_wdata(20),
      Q => data13(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[23]_i_1_n_0\,
      D => s00_axi_wdata(21),
      Q => data13(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[23]_i_1_n_0\,
      D => s00_axi_wdata(22),
      Q => data13(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[23]_i_1_n_0\,
      D => s00_axi_wdata(23),
      Q => data13(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[31]_i_1_n_0\,
      D => s00_axi_wdata(24),
      Q => data12(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[31]_i_1_n_0\,
      D => s00_axi_wdata(25),
      Q => data12(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[31]_i_1_n_0\,
      D => s00_axi_wdata(26),
      Q => data12(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[31]_i_1_n_0\,
      D => s00_axi_wdata(27),
      Q => data12(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[31]_i_1_n_0\,
      D => s00_axi_wdata(28),
      Q => data12(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[31]_i_1_n_0\,
      D => s00_axi_wdata(29),
      Q => data12(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[7]_i_1_n_0\,
      D => s00_axi_wdata(2),
      Q => p_12_in(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[31]_i_1_n_0\,
      D => s00_axi_wdata(30),
      Q => data12(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[31]_i_1_n_0\,
      D => s00_axi_wdata(31),
      Q => data12(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[7]_i_1_n_0\,
      D => s00_axi_wdata(3),
      Q => p_12_in(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[7]_i_1_n_0\,
      D => s00_axi_wdata(4),
      Q => p_12_in(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[7]_i_1_n_0\,
      D => s00_axi_wdata(5),
      Q => p_12_in(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[7]_i_1_n_0\,
      D => s00_axi_wdata(6),
      Q => p_12_in(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[7]_i_1_n_0\,
      D => s00_axi_wdata(7),
      Q => p_12_in(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[15]_i_1_n_0\,
      D => s00_axi_wdata(8),
      Q => data14(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg3_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg3[15]_i_1_n_0\,
      D => s00_axi_wdata(9),
      Q => data14(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg4[15]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(1),
      O => \slv_reg4[15]_i_1_n_0\
    );
\slv_reg4[23]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(2),
      O => \slv_reg4[23]_i_1_n_0\
    );
\slv_reg4[31]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(3),
      O => \slv_reg4[31]_i_1_n_0\
    );
\slv_reg4[7]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"02000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(0),
      O => \slv_reg4[7]_i_1_n_0\
    );
\slv_reg4_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[7]_i_1_n_0\,
      D => s00_axi_wdata(0),
      Q => slv_reg4(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[15]_i_1_n_0\,
      D => s00_axi_wdata(10),
      Q => slv_reg4(10),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[15]_i_1_n_0\,
      D => s00_axi_wdata(11),
      Q => slv_reg4(11),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[15]_i_1_n_0\,
      D => s00_axi_wdata(12),
      Q => slv_reg4(12),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[15]_i_1_n_0\,
      D => s00_axi_wdata(13),
      Q => slv_reg4(13),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[15]_i_1_n_0\,
      D => s00_axi_wdata(14),
      Q => slv_reg4(14),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[15]_i_1_n_0\,
      D => s00_axi_wdata(15),
      Q => slv_reg4(15),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[23]_i_1_n_0\,
      D => s00_axi_wdata(16),
      Q => slv_reg4(16),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[23]_i_1_n_0\,
      D => s00_axi_wdata(17),
      Q => slv_reg4(17),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[23]_i_1_n_0\,
      D => s00_axi_wdata(18),
      Q => slv_reg4(18),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[23]_i_1_n_0\,
      D => s00_axi_wdata(19),
      Q => slv_reg4(19),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[7]_i_1_n_0\,
      D => s00_axi_wdata(1),
      Q => slv_reg4(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[23]_i_1_n_0\,
      D => s00_axi_wdata(20),
      Q => slv_reg4(20),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[23]_i_1_n_0\,
      D => s00_axi_wdata(21),
      Q => slv_reg4(21),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[23]_i_1_n_0\,
      D => s00_axi_wdata(22),
      Q => slv_reg4(22),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[23]_i_1_n_0\,
      D => s00_axi_wdata(23),
      Q => slv_reg4(23),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[31]_i_1_n_0\,
      D => s00_axi_wdata(24),
      Q => slv_reg4(24),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[31]_i_1_n_0\,
      D => s00_axi_wdata(25),
      Q => slv_reg4(25),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[31]_i_1_n_0\,
      D => s00_axi_wdata(26),
      Q => slv_reg4(26),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[31]_i_1_n_0\,
      D => s00_axi_wdata(27),
      Q => slv_reg4(27),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[31]_i_1_n_0\,
      D => s00_axi_wdata(28),
      Q => slv_reg4(28),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[31]_i_1_n_0\,
      D => s00_axi_wdata(29),
      Q => slv_reg4(29),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[7]_i_1_n_0\,
      D => s00_axi_wdata(2),
      Q => slv_reg4(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[31]_i_1_n_0\,
      D => s00_axi_wdata(30),
      Q => slv_reg4(30),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[31]_i_1_n_0\,
      D => s00_axi_wdata(31),
      Q => slv_reg4(31),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[7]_i_1_n_0\,
      D => s00_axi_wdata(3),
      Q => slv_reg4(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[7]_i_1_n_0\,
      D => s00_axi_wdata(4),
      Q => slv_reg4(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[7]_i_1_n_0\,
      D => s00_axi_wdata(5),
      Q => slv_reg4(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[7]_i_1_n_0\,
      D => s00_axi_wdata(6),
      Q => slv_reg4(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[7]_i_1_n_0\,
      D => s00_axi_wdata(7),
      Q => slv_reg4(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[15]_i_1_n_0\,
      D => s00_axi_wdata(8),
      Q => slv_reg4(8),
      R => axi_awready_i_1_n_0
    );
\slv_reg4_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg4[15]_i_1_n_0\,
      D => s00_axi_wdata(9),
      Q => slv_reg4(9),
      R => axi_awready_i_1_n_0
    );
\slv_reg5[15]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => s00_axi_wstrb(1),
      I3 => p_0_in(0),
      I4 => p_0_in(2),
      O => \slv_reg5[15]_i_1_n_0\
    );
\slv_reg5[23]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => s00_axi_wstrb(2),
      I3 => p_0_in(0),
      I4 => p_0_in(2),
      O => \slv_reg5[23]_i_1_n_0\
    );
\slv_reg5[31]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => s00_axi_wstrb(3),
      I3 => p_0_in(0),
      I4 => p_0_in(2),
      O => \slv_reg5[31]_i_1_n_0\
    );
\slv_reg5[7]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => s00_axi_wstrb(0),
      I3 => p_0_in(0),
      I4 => p_0_in(2),
      O => \slv_reg5[7]_i_1_n_0\
    );
\slv_reg5_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[7]_i_1_n_0\,
      D => s00_axi_wdata(0),
      Q => slv_reg5(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[15]_i_1_n_0\,
      D => s00_axi_wdata(10),
      Q => slv_reg5(10),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[15]_i_1_n_0\,
      D => s00_axi_wdata(11),
      Q => slv_reg5(11),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[15]_i_1_n_0\,
      D => s00_axi_wdata(12),
      Q => slv_reg5(12),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[15]_i_1_n_0\,
      D => s00_axi_wdata(13),
      Q => slv_reg5(13),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[15]_i_1_n_0\,
      D => s00_axi_wdata(14),
      Q => slv_reg5(14),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[15]_i_1_n_0\,
      D => s00_axi_wdata(15),
      Q => slv_reg5(15),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[23]_i_1_n_0\,
      D => s00_axi_wdata(16),
      Q => slv_reg5(16),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[23]_i_1_n_0\,
      D => s00_axi_wdata(17),
      Q => slv_reg5(17),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[23]_i_1_n_0\,
      D => s00_axi_wdata(18),
      Q => slv_reg5(18),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[23]_i_1_n_0\,
      D => s00_axi_wdata(19),
      Q => slv_reg5(19),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[7]_i_1_n_0\,
      D => s00_axi_wdata(1),
      Q => slv_reg5(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[23]_i_1_n_0\,
      D => s00_axi_wdata(20),
      Q => slv_reg5(20),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[23]_i_1_n_0\,
      D => s00_axi_wdata(21),
      Q => slv_reg5(21),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[23]_i_1_n_0\,
      D => s00_axi_wdata(22),
      Q => slv_reg5(22),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[23]_i_1_n_0\,
      D => s00_axi_wdata(23),
      Q => slv_reg5(23),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[31]_i_1_n_0\,
      D => s00_axi_wdata(24),
      Q => slv_reg5(24),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[31]_i_1_n_0\,
      D => s00_axi_wdata(25),
      Q => slv_reg5(25),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[31]_i_1_n_0\,
      D => s00_axi_wdata(26),
      Q => slv_reg5(26),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[31]_i_1_n_0\,
      D => s00_axi_wdata(27),
      Q => slv_reg5(27),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[31]_i_1_n_0\,
      D => s00_axi_wdata(28),
      Q => slv_reg5(28),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[31]_i_1_n_0\,
      D => s00_axi_wdata(29),
      Q => slv_reg5(29),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[7]_i_1_n_0\,
      D => s00_axi_wdata(2),
      Q => slv_reg5(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[31]_i_1_n_0\,
      D => s00_axi_wdata(30),
      Q => slv_reg5(30),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[31]_i_1_n_0\,
      D => s00_axi_wdata(31),
      Q => slv_reg5(31),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[7]_i_1_n_0\,
      D => s00_axi_wdata(3),
      Q => slv_reg5(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[7]_i_1_n_0\,
      D => s00_axi_wdata(4),
      Q => slv_reg5(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[7]_i_1_n_0\,
      D => s00_axi_wdata(5),
      Q => slv_reg5(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[7]_i_1_n_0\,
      D => s00_axi_wdata(6),
      Q => slv_reg5(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[7]_i_1_n_0\,
      D => s00_axi_wdata(7),
      Q => slv_reg5(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[15]_i_1_n_0\,
      D => s00_axi_wdata(8),
      Q => slv_reg5(8),
      R => axi_awready_i_1_n_0
    );
\slv_reg5_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg5[15]_i_1_n_0\,
      D => s00_axi_wdata(9),
      Q => slv_reg5(9),
      R => axi_awready_i_1_n_0
    );
\slv_reg6[15]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(0),
      I2 => p_0_in(1),
      I3 => s00_axi_wstrb(1),
      I4 => p_0_in(2),
      O => \slv_reg6[15]_i_1_n_0\
    );
\slv_reg6[23]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(0),
      I2 => p_0_in(1),
      I3 => s00_axi_wstrb(2),
      I4 => p_0_in(2),
      O => \slv_reg6[23]_i_1_n_0\
    );
\slv_reg6[31]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(0),
      I2 => p_0_in(1),
      I3 => s00_axi_wstrb(3),
      I4 => p_0_in(2),
      O => \slv_reg6[31]_i_1_n_0\
    );
\slv_reg6[7]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(0),
      I2 => p_0_in(1),
      I3 => s00_axi_wstrb(0),
      I4 => p_0_in(2),
      O => \slv_reg6[7]_i_1_n_0\
    );
\slv_reg6_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[7]_i_1_n_0\,
      D => s00_axi_wdata(0),
      Q => slv_reg6(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[15]_i_1_n_0\,
      D => s00_axi_wdata(10),
      Q => slv_reg6(10),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[15]_i_1_n_0\,
      D => s00_axi_wdata(11),
      Q => slv_reg6(11),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[15]_i_1_n_0\,
      D => s00_axi_wdata(12),
      Q => slv_reg6(12),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[15]_i_1_n_0\,
      D => s00_axi_wdata(13),
      Q => slv_reg6(13),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[15]_i_1_n_0\,
      D => s00_axi_wdata(14),
      Q => slv_reg6(14),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[15]_i_1_n_0\,
      D => s00_axi_wdata(15),
      Q => slv_reg6(15),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[23]_i_1_n_0\,
      D => s00_axi_wdata(16),
      Q => slv_reg6(16),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[23]_i_1_n_0\,
      D => s00_axi_wdata(17),
      Q => slv_reg6(17),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[23]_i_1_n_0\,
      D => s00_axi_wdata(18),
      Q => slv_reg6(18),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[23]_i_1_n_0\,
      D => s00_axi_wdata(19),
      Q => slv_reg6(19),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[7]_i_1_n_0\,
      D => s00_axi_wdata(1),
      Q => slv_reg6(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[23]_i_1_n_0\,
      D => s00_axi_wdata(20),
      Q => slv_reg6(20),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[23]_i_1_n_0\,
      D => s00_axi_wdata(21),
      Q => slv_reg6(21),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[23]_i_1_n_0\,
      D => s00_axi_wdata(22),
      Q => slv_reg6(22),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[23]_i_1_n_0\,
      D => s00_axi_wdata(23),
      Q => slv_reg6(23),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[31]_i_1_n_0\,
      D => s00_axi_wdata(24),
      Q => slv_reg6(24),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[31]_i_1_n_0\,
      D => s00_axi_wdata(25),
      Q => slv_reg6(25),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[31]_i_1_n_0\,
      D => s00_axi_wdata(26),
      Q => slv_reg6(26),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[31]_i_1_n_0\,
      D => s00_axi_wdata(27),
      Q => slv_reg6(27),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[31]_i_1_n_0\,
      D => s00_axi_wdata(28),
      Q => slv_reg6(28),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[31]_i_1_n_0\,
      D => s00_axi_wdata(29),
      Q => slv_reg6(29),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[7]_i_1_n_0\,
      D => s00_axi_wdata(2),
      Q => slv_reg6(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[31]_i_1_n_0\,
      D => s00_axi_wdata(30),
      Q => slv_reg6(30),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[31]_i_1_n_0\,
      D => s00_axi_wdata(31),
      Q => slv_reg6(31),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[7]_i_1_n_0\,
      D => s00_axi_wdata(3),
      Q => slv_reg6(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[7]_i_1_n_0\,
      D => s00_axi_wdata(4),
      Q => slv_reg6(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[7]_i_1_n_0\,
      D => s00_axi_wdata(5),
      Q => slv_reg6(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[7]_i_1_n_0\,
      D => s00_axi_wdata(6),
      Q => slv_reg6(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[7]_i_1_n_0\,
      D => s00_axi_wdata(7),
      Q => slv_reg6(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[15]_i_1_n_0\,
      D => s00_axi_wdata(8),
      Q => slv_reg6(8),
      R => axi_awready_i_1_n_0
    );
\slv_reg6_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg6[15]_i_1_n_0\,
      D => s00_axi_wdata(9),
      Q => slv_reg6(9),
      R => axi_awready_i_1_n_0
    );
\slv_reg7[15]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(1),
      O => \slv_reg7[15]_i_1_n_0\
    );
\slv_reg7[23]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(2),
      O => \slv_reg7[23]_i_1_n_0\
    );
\slv_reg7[31]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(3),
      O => \slv_reg7[31]_i_1_n_0\
    );
\slv_reg7[7]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => \slv_reg_wren__0\,
      I1 => p_0_in(1),
      I2 => p_0_in(0),
      I3 => p_0_in(2),
      I4 => s00_axi_wstrb(0),
      O => \slv_reg7[7]_i_1_n_0\
    );
\slv_reg7_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[7]_i_1_n_0\,
      D => s00_axi_wdata(0),
      Q => data15(0),
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[15]_i_1_n_0\,
      D => s00_axi_wdata(10),
      Q => \slv_reg7_reg_n_0_[10]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[15]_i_1_n_0\,
      D => s00_axi_wdata(11),
      Q => \slv_reg7_reg_n_0_[11]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[15]_i_1_n_0\,
      D => s00_axi_wdata(12),
      Q => \slv_reg7_reg_n_0_[12]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[15]_i_1_n_0\,
      D => s00_axi_wdata(13),
      Q => \slv_reg7_reg_n_0_[13]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[15]_i_1_n_0\,
      D => s00_axi_wdata(14),
      Q => \slv_reg7_reg_n_0_[14]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[15]_i_1_n_0\,
      D => s00_axi_wdata(15),
      Q => \slv_reg7_reg_n_0_[15]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[23]_i_1_n_0\,
      D => s00_axi_wdata(16),
      Q => \slv_reg7_reg_n_0_[16]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[23]_i_1_n_0\,
      D => s00_axi_wdata(17),
      Q => \slv_reg7_reg_n_0_[17]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[23]_i_1_n_0\,
      D => s00_axi_wdata(18),
      Q => \slv_reg7_reg_n_0_[18]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[23]_i_1_n_0\,
      D => s00_axi_wdata(19),
      Q => \slv_reg7_reg_n_0_[19]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[7]_i_1_n_0\,
      D => s00_axi_wdata(1),
      Q => data15(1),
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[23]_i_1_n_0\,
      D => s00_axi_wdata(20),
      Q => \slv_reg7_reg_n_0_[20]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[23]_i_1_n_0\,
      D => s00_axi_wdata(21),
      Q => \slv_reg7_reg_n_0_[21]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[23]_i_1_n_0\,
      D => s00_axi_wdata(22),
      Q => \slv_reg7_reg_n_0_[22]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[23]_i_1_n_0\,
      D => s00_axi_wdata(23),
      Q => \slv_reg7_reg_n_0_[23]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[31]_i_1_n_0\,
      D => s00_axi_wdata(24),
      Q => \slv_reg7_reg_n_0_[24]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[31]_i_1_n_0\,
      D => s00_axi_wdata(25),
      Q => \slv_reg7_reg_n_0_[25]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[31]_i_1_n_0\,
      D => s00_axi_wdata(26),
      Q => \slv_reg7_reg_n_0_[26]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[31]_i_1_n_0\,
      D => s00_axi_wdata(27),
      Q => \slv_reg7_reg_n_0_[27]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[31]_i_1_n_0\,
      D => s00_axi_wdata(28),
      Q => \slv_reg7_reg_n_0_[28]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[31]_i_1_n_0\,
      D => s00_axi_wdata(29),
      Q => \slv_reg7_reg_n_0_[29]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[7]_i_1_n_0\,
      D => s00_axi_wdata(2),
      Q => data15(2),
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[31]_i_1_n_0\,
      D => s00_axi_wdata(30),
      Q => \slv_reg7_reg_n_0_[30]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[31]_i_1_n_0\,
      D => s00_axi_wdata(31),
      Q => \slv_reg7_reg_n_0_[31]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[7]_i_1_n_0\,
      D => s00_axi_wdata(3),
      Q => data15(3),
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[7]_i_1_n_0\,
      D => s00_axi_wdata(4),
      Q => data15(4),
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[7]_i_1_n_0\,
      D => s00_axi_wdata(5),
      Q => data15(5),
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[7]_i_1_n_0\,
      D => s00_axi_wdata(6),
      Q => data15(6),
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[7]_i_1_n_0\,
      D => s00_axi_wdata(7),
      Q => data15(7),
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[15]_i_1_n_0\,
      D => s00_axi_wdata(8),
      Q => \slv_reg7_reg_n_0_[8]\,
      R => axi_awready_i_1_n_0
    );
\slv_reg7_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => s00_axi_aclk,
      CE => \slv_reg7[15]_i_1_n_0\,
      D => s00_axi_wdata(9),
      Q => \slv_reg7_reg_n_0_[9]\,
      R => axi_awready_i_1_n_0
    );
slv_reg_rden: unisim.vcomponents.LUT3
    generic map(
      INIT => X"20"
    )
        port map (
      I0 => s00_axi_arvalid,
      I1 => \^s00_axi_rvalid\,
      I2 => \^s_axi_arready\,
      O => \slv_reg_rden__0\
    );
textlcd_1: entity work.system_textlcd_0_0_textlcd
     port map (
      Q(31) => \slv_reg7_reg_n_0_[31]\,
      Q(30) => \slv_reg7_reg_n_0_[30]\,
      Q(29) => \slv_reg7_reg_n_0_[29]\,
      Q(28) => \slv_reg7_reg_n_0_[28]\,
      Q(27) => \slv_reg7_reg_n_0_[27]\,
      Q(26) => \slv_reg7_reg_n_0_[26]\,
      Q(25) => \slv_reg7_reg_n_0_[25]\,
      Q(24) => \slv_reg7_reg_n_0_[24]\,
      Q(23) => \slv_reg7_reg_n_0_[23]\,
      Q(22) => \slv_reg7_reg_n_0_[22]\,
      Q(21) => \slv_reg7_reg_n_0_[21]\,
      Q(20) => \slv_reg7_reg_n_0_[20]\,
      Q(19) => \slv_reg7_reg_n_0_[19]\,
      Q(18) => \slv_reg7_reg_n_0_[18]\,
      Q(17) => \slv_reg7_reg_n_0_[17]\,
      Q(16) => \slv_reg7_reg_n_0_[16]\,
      Q(15) => \slv_reg7_reg_n_0_[15]\,
      Q(14) => \slv_reg7_reg_n_0_[14]\,
      Q(13) => \slv_reg7_reg_n_0_[13]\,
      Q(12) => \slv_reg7_reg_n_0_[12]\,
      Q(11) => \slv_reg7_reg_n_0_[11]\,
      Q(10) => \slv_reg7_reg_n_0_[10]\,
      Q(9) => \slv_reg7_reg_n_0_[9]\,
      Q(8) => \slv_reg7_reg_n_0_[8]\,
      Q(7 downto 0) => data15(7 downto 0),
      lcd_data(7 downto 0) => lcd_data(7 downto 0),
      \lcd_data[7]_INST_0_i_3_0\(31 downto 24) => data12(7 downto 0),
      \lcd_data[7]_INST_0_i_3_0\(23 downto 16) => data13(7 downto 0),
      \lcd_data[7]_INST_0_i_3_0\(15 downto 8) => data14(7 downto 0),
      \lcd_data[7]_INST_0_i_3_0\(7 downto 0) => p_12_in(7 downto 0),
      \lcd_data[7]_INST_0_i_4_0\(31 downto 24) => data8(7 downto 0),
      \lcd_data[7]_INST_0_i_4_0\(23 downto 16) => data9(7 downto 0),
      \lcd_data[7]_INST_0_i_4_0\(15 downto 8) => data10(7 downto 0),
      \lcd_data[7]_INST_0_i_4_0\(7 downto 0) => data11(7 downto 0),
      \lcd_data[7]_INST_0_i_4_1\(31 downto 24) => data4(7 downto 0),
      \lcd_data[7]_INST_0_i_4_1\(23 downto 16) => data5(7 downto 0),
      \lcd_data[7]_INST_0_i_4_1\(15 downto 8) => data6(7 downto 0),
      \lcd_data[7]_INST_0_i_4_1\(7 downto 0) => data7(7 downto 0),
      \lcd_data[7]_INST_0_i_4_2\(31) => \slv_reg0_reg_n_0_[31]\,
      \lcd_data[7]_INST_0_i_4_2\(30) => \slv_reg0_reg_n_0_[30]\,
      \lcd_data[7]_INST_0_i_4_2\(29) => \slv_reg0_reg_n_0_[29]\,
      \lcd_data[7]_INST_0_i_4_2\(28) => \slv_reg0_reg_n_0_[28]\,
      \lcd_data[7]_INST_0_i_4_2\(27) => \slv_reg0_reg_n_0_[27]\,
      \lcd_data[7]_INST_0_i_4_2\(26) => \slv_reg0_reg_n_0_[26]\,
      \lcd_data[7]_INST_0_i_4_2\(25) => \slv_reg0_reg_n_0_[25]\,
      \lcd_data[7]_INST_0_i_4_2\(24) => \slv_reg0_reg_n_0_[24]\,
      \lcd_data[7]_INST_0_i_4_2\(23 downto 16) => data1(7 downto 0),
      \lcd_data[7]_INST_0_i_4_2\(15 downto 8) => data2(7 downto 0),
      \lcd_data[7]_INST_0_i_4_2\(7 downto 0) => data3(7 downto 0),
      \lcd_data[7]_INST_0_i_5_0\(31 downto 0) => slv_reg6(31 downto 0),
      \lcd_data[7]_INST_0_i_6_0\(31 downto 0) => slv_reg5(31 downto 0),
      \lcd_data[7]_INST_0_i_6_1\(31 downto 0) => slv_reg4(31 downto 0),
      lcd_en => lcd_en,
      lcd_rs => lcd_rs,
      lcdclk => lcdclk,
      resetn => resetn
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity system_textlcd_0_0_textlcd_v1_0 is
  port (
    S_AXI_AWREADY : out STD_LOGIC;
    S_AXI_WREADY : out STD_LOGIC;
    S_AXI_ARREADY : out STD_LOGIC;
    s00_axi_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    lcd_data : out STD_LOGIC_VECTOR ( 7 downto 0 );
    lcd_rs : out STD_LOGIC;
    s00_axi_rvalid : out STD_LOGIC;
    lcd_en : out STD_LOGIC;
    s00_axi_bvalid : out STD_LOGIC;
    s00_axi_awaddr : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s00_axi_wvalid : in STD_LOGIC;
    s00_axi_awvalid : in STD_LOGIC;
    s00_axi_aclk : in STD_LOGIC;
    s00_axi_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    lcdclk : in STD_LOGIC;
    s00_axi_araddr : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s00_axi_arvalid : in STD_LOGIC;
    s00_axi_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s00_axi_aresetn : in STD_LOGIC;
    resetn : in STD_LOGIC;
    s00_axi_bready : in STD_LOGIC;
    s00_axi_rready : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of system_textlcd_0_0_textlcd_v1_0 : entity is "textlcd_v1_0";
end system_textlcd_0_0_textlcd_v1_0;

architecture STRUCTURE of system_textlcd_0_0_textlcd_v1_0 is
begin
textlcd_v1_0_S00_AXI_inst: entity work.system_textlcd_0_0_textlcd_v1_0_S00_AXI
     port map (
      S_AXI_ARREADY => S_AXI_ARREADY,
      S_AXI_AWREADY => S_AXI_AWREADY,
      S_AXI_WREADY => S_AXI_WREADY,
      lcd_data(7 downto 0) => lcd_data(7 downto 0),
      lcd_en => lcd_en,
      lcd_rs => lcd_rs,
      lcdclk => lcdclk,
      resetn => resetn,
      s00_axi_aclk => s00_axi_aclk,
      s00_axi_araddr(2 downto 0) => s00_axi_araddr(2 downto 0),
      s00_axi_aresetn => s00_axi_aresetn,
      s00_axi_arvalid => s00_axi_arvalid,
      s00_axi_awaddr(2 downto 0) => s00_axi_awaddr(2 downto 0),
      s00_axi_awvalid => s00_axi_awvalid,
      s00_axi_bready => s00_axi_bready,
      s00_axi_bvalid => s00_axi_bvalid,
      s00_axi_rdata(31 downto 0) => s00_axi_rdata(31 downto 0),
      s00_axi_rready => s00_axi_rready,
      s00_axi_rvalid => s00_axi_rvalid,
      s00_axi_wdata(31 downto 0) => s00_axi_wdata(31 downto 0),
      s00_axi_wstrb(3 downto 0) => s00_axi_wstrb(3 downto 0),
      s00_axi_wvalid => s00_axi_wvalid
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity system_textlcd_0_0 is
  port (
    resetn : in STD_LOGIC;
    lcdclk : in STD_LOGIC;
    lcd_rs : out STD_LOGIC;
    lcd_rw : out STD_LOGIC;
    lcd_en : out STD_LOGIC;
    lcd_data : out STD_LOGIC_VECTOR ( 7 downto 0 );
    s00_axi_awaddr : in STD_LOGIC_VECTOR ( 4 downto 0 );
    s00_axi_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s00_axi_awvalid : in STD_LOGIC;
    s00_axi_awready : out STD_LOGIC;
    s00_axi_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s00_axi_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s00_axi_wvalid : in STD_LOGIC;
    s00_axi_wready : out STD_LOGIC;
    s00_axi_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s00_axi_bvalid : out STD_LOGIC;
    s00_axi_bready : in STD_LOGIC;
    s00_axi_araddr : in STD_LOGIC_VECTOR ( 4 downto 0 );
    s00_axi_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s00_axi_arvalid : in STD_LOGIC;
    s00_axi_arready : out STD_LOGIC;
    s00_axi_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s00_axi_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s00_axi_rvalid : out STD_LOGIC;
    s00_axi_rready : in STD_LOGIC;
    s00_axi_aclk : in STD_LOGIC;
    s00_axi_aresetn : in STD_LOGIC
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of system_textlcd_0_0 : entity is true;
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of system_textlcd_0_0 : entity is "system_textlcd_0_0,textlcd_v1_0,{}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of system_textlcd_0_0 : entity is "yes";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of system_textlcd_0_0 : entity is "textlcd_v1_0,Vivado 2019.1";
end system_textlcd_0_0;

architecture STRUCTURE of system_textlcd_0_0 is
  signal \<const0>\ : STD_LOGIC;
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of resetn : signal is "xilinx.com:signal:reset:1.0 resetn RST";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of resetn : signal is "XIL_INTERFACENAME resetn, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of s00_axi_aclk : signal is "xilinx.com:signal:clock:1.0 S00_AXI_CLK CLK";
  attribute X_INTERFACE_PARAMETER of s00_axi_aclk : signal is "XIL_INTERFACENAME S00_AXI_CLK, ASSOCIATED_BUSIF S00_AXI, ASSOCIATED_RESET s00_axi_aresetn:resetn, FREQ_HZ 50000000, PHASE 0.000, CLK_DOMAIN system_processing_system7_0_1_FCLK_CLK0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of s00_axi_aresetn : signal is "xilinx.com:signal:reset:1.0 S00_AXI_RST RST";
  attribute X_INTERFACE_PARAMETER of s00_axi_aresetn : signal is "XIL_INTERFACENAME S00_AXI_RST, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of s00_axi_arready : signal is "xilinx.com:interface:aximm:1.0 S00_AXI ARREADY";
  attribute X_INTERFACE_INFO of s00_axi_arvalid : signal is "xilinx.com:interface:aximm:1.0 S00_AXI ARVALID";
  attribute X_INTERFACE_INFO of s00_axi_awready : signal is "xilinx.com:interface:aximm:1.0 S00_AXI AWREADY";
  attribute X_INTERFACE_INFO of s00_axi_awvalid : signal is "xilinx.com:interface:aximm:1.0 S00_AXI AWVALID";
  attribute X_INTERFACE_INFO of s00_axi_bready : signal is "xilinx.com:interface:aximm:1.0 S00_AXI BREADY";
  attribute X_INTERFACE_INFO of s00_axi_bvalid : signal is "xilinx.com:interface:aximm:1.0 S00_AXI BVALID";
  attribute X_INTERFACE_INFO of s00_axi_rready : signal is "xilinx.com:interface:aximm:1.0 S00_AXI RREADY";
  attribute X_INTERFACE_PARAMETER of s00_axi_rready : signal is "XIL_INTERFACENAME S00_AXI, WIZ_DATA_WIDTH 32, WIZ_NUM_REG 8, SUPPORTS_NARROW_BURST 0, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 50000000, ID_WIDTH 0, ADDR_WIDTH 5, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 1, PHASE 0.000, CLK_DOMAIN system_processing_system7_0_1_FCLK_CLK0, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of s00_axi_rvalid : signal is "xilinx.com:interface:aximm:1.0 S00_AXI RVALID";
  attribute X_INTERFACE_INFO of s00_axi_wready : signal is "xilinx.com:interface:aximm:1.0 S00_AXI WREADY";
  attribute X_INTERFACE_INFO of s00_axi_wvalid : signal is "xilinx.com:interface:aximm:1.0 S00_AXI WVALID";
  attribute X_INTERFACE_INFO of s00_axi_araddr : signal is "xilinx.com:interface:aximm:1.0 S00_AXI ARADDR";
  attribute X_INTERFACE_INFO of s00_axi_arprot : signal is "xilinx.com:interface:aximm:1.0 S00_AXI ARPROT";
  attribute X_INTERFACE_INFO of s00_axi_awaddr : signal is "xilinx.com:interface:aximm:1.0 S00_AXI AWADDR";
  attribute X_INTERFACE_INFO of s00_axi_awprot : signal is "xilinx.com:interface:aximm:1.0 S00_AXI AWPROT";
  attribute X_INTERFACE_INFO of s00_axi_bresp : signal is "xilinx.com:interface:aximm:1.0 S00_AXI BRESP";
  attribute X_INTERFACE_INFO of s00_axi_rdata : signal is "xilinx.com:interface:aximm:1.0 S00_AXI RDATA";
  attribute X_INTERFACE_INFO of s00_axi_rresp : signal is "xilinx.com:interface:aximm:1.0 S00_AXI RRESP";
  attribute X_INTERFACE_INFO of s00_axi_wdata : signal is "xilinx.com:interface:aximm:1.0 S00_AXI WDATA";
  attribute X_INTERFACE_INFO of s00_axi_wstrb : signal is "xilinx.com:interface:aximm:1.0 S00_AXI WSTRB";
begin
  lcd_rw <= \<const0>\;
  s00_axi_bresp(1) <= \<const0>\;
  s00_axi_bresp(0) <= \<const0>\;
  s00_axi_rresp(1) <= \<const0>\;
  s00_axi_rresp(0) <= \<const0>\;
GND: unisim.vcomponents.GND
     port map (
      G => \<const0>\
    );
inst: entity work.system_textlcd_0_0_textlcd_v1_0
     port map (
      S_AXI_ARREADY => s00_axi_arready,
      S_AXI_AWREADY => s00_axi_awready,
      S_AXI_WREADY => s00_axi_wready,
      lcd_data(7 downto 0) => lcd_data(7 downto 0),
      lcd_en => lcd_en,
      lcd_rs => lcd_rs,
      lcdclk => lcdclk,
      resetn => resetn,
      s00_axi_aclk => s00_axi_aclk,
      s00_axi_araddr(2 downto 0) => s00_axi_araddr(4 downto 2),
      s00_axi_aresetn => s00_axi_aresetn,
      s00_axi_arvalid => s00_axi_arvalid,
      s00_axi_awaddr(2 downto 0) => s00_axi_awaddr(4 downto 2),
      s00_axi_awvalid => s00_axi_awvalid,
      s00_axi_bready => s00_axi_bready,
      s00_axi_bvalid => s00_axi_bvalid,
      s00_axi_rdata(31 downto 0) => s00_axi_rdata(31 downto 0),
      s00_axi_rready => s00_axi_rready,
      s00_axi_rvalid => s00_axi_rvalid,
      s00_axi_wdata(31 downto 0) => s00_axi_wdata(31 downto 0),
      s00_axi_wstrb(3 downto 0) => s00_axi_wstrb(3 downto 0),
      s00_axi_wvalid => s00_axi_wvalid
    );
end STRUCTURE;
