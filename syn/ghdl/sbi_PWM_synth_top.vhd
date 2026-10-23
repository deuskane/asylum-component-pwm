-------------------------------------------------------------------------------
-- Title      : sbi_PWM_synth_top
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : sbi_PWM_synth_top.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description:
-- Synthesis check top (lint_ghdl, lint_ghdl_synth) : sbi_PWM (and so
-- pwm_core) with flat and constrained SBI ports (sbi_PWM has unconstrained
-- SBI ports and cannot be a synthesis top). SBI address / data width :
-- SBI_ADDR_WIDTH / SBI_DATA_WIDTH. The synthesizable generics are forwarded
-- with the defaults of sbi_PWM.
-- NAME is simulation only, not connected.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-22  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
library asylum;
use     asylum.sbi_pkg.all;

entity sbi_PWM_synth_top is
  generic (
    STATIC_PRESCALER_RATIO: positive                       := 1;
    USER_DEFINE_PRESCALER : boolean                        := true;
    PRESCALER_RATIO       : std_logic_vector(8-1 downto 0) := x"C2"
  );
  port (
    clk_i         : in  std_logic;
    arst_b_i      : in  std_logic;

    -- Bus (SBI)
    cs_i          : in  std_logic;
    re_i          : in  std_logic;
    we_i          : in  std_logic;
    addr_i        : in  std_logic_vector(SBI_ADDR_WIDTH-1 downto 0);
    wdata_i       : in  std_logic_vector(SBI_DATA_WIDTH-1 downto 0);
    ready_o       : out std_logic;
    rdata_o       : out std_logic_vector(SBI_DATA_WIDTH-1 downto 0);

    -- PWM Output
    pwm_o         : out std_logic
  );
end entity sbi_PWM_synth_top;

architecture rtl of sbi_PWM_synth_top is

  signal sbi_ini       : sbi_ini_t(addr (SBI_ADDR_WIDTH-1 downto 0),
                                   wdata(SBI_DATA_WIDTH-1 downto 0));
  signal sbi_tgt       : sbi_tgt_t(rdata(SBI_DATA_WIDTH-1 downto 0));

begin

  sbi_ini.cs        <= cs_i;
  sbi_ini.re        <= re_i;
  sbi_ini.we        <= we_i;
  sbi_ini.addr      <= addr_i;
  sbi_ini.wdata     <= wdata_i;
  ready_o           <= sbi_tgt.ready;
  rdata_o           <= sbi_tgt.rdata;

  ins_sbi_PWM : entity asylum.sbi_PWM
    generic map (
      STATIC_PRESCALER_RATIO=> STATIC_PRESCALER_RATIO,
      USER_DEFINE_PRESCALER => USER_DEFINE_PRESCALER,
      PRESCALER_RATIO       => PRESCALER_RATIO
    )
    port map (
      clk_i                 => clk_i,
      arst_b_i              => arst_b_i,
      sbi_ini_i             => sbi_ini,
      sbi_tgt_o             => sbi_tgt,
      pwm_o                 => pwm_o
    );

end architecture rtl;
