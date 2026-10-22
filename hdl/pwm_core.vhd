-------------------------------------------------------------------------------
-- Title      : pwm_core
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : pwm_core.vhd
-- Author     : Mathieu Rosiere
-- Company    :
-- Created    : 2026-10-22
-- Last update: 2026-10-22
-- Platform   :
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description:
-- PWM core, independent of the CSR and of the bus interface : the
-- configuration is made of plain signals.
-- * Prescaler   : one tick every (ratio+1) clock cycles
-- * PWM counter : counts the ticks from 0 to period, then restarts at 0.
--                 A PWM period is (period+1) ticks.
-- * Output      : high while the counter is lower than duty, so high during
--                 the first duty ticks of each PWM period
--                 (duty = 0 : always low, duty > period : always high)
-- The configuration (ratio, period, duty) is copied in shadow registers at
-- the start of each PWM period, and continuously while the PWM is disabled :
-- a new value is taken into account at the start of the next PWM period,
-- without glitch on pwm_o.
-- While cfg_enable_i = 0, the counter is cleared and pwm_o is low. The first
-- PWM period starts (with the high phase) one clock cycle after
-- cfg_enable_i is set.
-- pwm_o is the output of a register (no glitch).
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-22  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;

entity pwm_core is
  generic (
    PRESCALER_WIDTH      : natural := 8;                      -- Width of the prescaler ratio
    COUNTER_WIDTH        : natural := 8                       -- Width of the period and of the duty (resolution of the PWM)
    );
  port (
    -- Clock & Reset
    clk_i                : in  std_logic;
    arst_b_i             : in  std_logic;

    -- Configuration
    cfg_enable_i         : in  std_logic;                     -- 0 : counter cleared, pwm_o low
    cfg_prescaler_ratio_i: in  std_logic_vector(PRESCALER_WIDTH-1 downto 0); -- Duration of a tick minus one, in clock cycles
    cfg_period_i         : in  std_logic_vector(COUNTER_WIDTH-1 downto 0);   -- PWM period minus one, in ticks
    cfg_duty_i           : in  std_logic_vector(COUNTER_WIDTH-1 downto 0);   -- High phase, in ticks

    -- PWM Output
    pwm_o                : out std_logic
    );
end entity pwm_core;

architecture rtl of pwm_core is

  -- Shadow registers of the configuration
  signal   load                   : std_logic;
  signal   ratio_r                : unsigned(PRESCALER_WIDTH-1 downto 0);
  signal   ratio_next             : unsigned(PRESCALER_WIDTH-1 downto 0);
  signal   period_r               : unsigned(COUNTER_WIDTH-1 downto 0);
  signal   duty_r                 : unsigned(COUNTER_WIDTH-1 downto 0);

  -- Prescaler
  signal   prescaler_cnt_r        : unsigned(PRESCALER_WIDTH-1 downto 0);
  signal   tick                   : std_logic;

  -- PWM counter
  signal   pwm_cnt_r              : unsigned(COUNTER_WIDTH-1 downto 0);
  signal   period_end             : std_logic;

  -- Output
  signal   pwm_r                  : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Shadow registers of the configuration
  -----------------------------------------------------------------------------
  -- Loaded while the PWM is disabled and on the last tick of each PWM period
  load                 <= (not cfg_enable_i) or (tick and period_end);

  -- Ratio of the next tick : the new ratio starts with the new PWM period
  ratio_next           <= unsigned(cfg_prescaler_ratio_i) when load = '1' else
                          ratio_r;

  process(clk_i,arst_b_i)
  begin
    if arst_b_i = '0'
    then
      ratio_r  <= (others => '0');
      period_r <= (others => '0');
      duty_r   <= (others => '0');
    elsif rising_edge(clk_i)
    then
      if load = '1'
      then
        ratio_r  <= unsigned(cfg_prescaler_ratio_i);
        period_r <= unsigned(cfg_period_i);
        duty_r   <= unsigned(cfg_duty_i);
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Prescaler
  -----------------------------------------------------------------------------
  -- Down counter : a tick when it reaches 0, then it is reloaded with the
  -- ratio, so one tick every (ratio+1) clock cycles. Held at the ratio while
  -- the PWM is disabled : the first tick lasts (ratio+1) clock cycles too.
  tick                 <= '1' when prescaler_cnt_r = 0 else
                          '0';

  process(clk_i,arst_b_i)
  begin
    if arst_b_i = '0'
    then
      prescaler_cnt_r <= (others => '0');
    elsif rising_edge(clk_i)
    then
      if cfg_enable_i = '0' or tick = '1'
      then
        prescaler_cnt_r <= ratio_next;
      else
        prescaler_cnt_r <= prescaler_cnt_r - 1;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- PWM counter
  -----------------------------------------------------------------------------
  -- Counts the ticks from 0 to period_r. period_r only changes on the last
  -- tick of a PWM period, so the counter never goes beyond period_r.
  period_end           <= '1' when pwm_cnt_r = period_r else
                          '0';

  process(clk_i,arst_b_i)
  begin
    if arst_b_i = '0'
    then
      pwm_cnt_r <= (others => '0');
    elsif rising_edge(clk_i)
    then
      if cfg_enable_i = '0'
      then
        pwm_cnt_r <= (others => '0');
      elsif tick = '1'
      then
        if period_end = '1'
        then
          pwm_cnt_r <= (others => '0');
        else
          pwm_cnt_r <= pwm_cnt_r + 1;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Output
  -----------------------------------------------------------------------------
  -- Registered comparison : pwm_o follows the counter with one clock cycle of
  -- latency, the same for every edge, so the durations are not changed.
  process(clk_i,arst_b_i)
  begin
    if arst_b_i = '0'
    then
      pwm_r <= '0';
    elsif rising_edge(clk_i)
    then
      if cfg_enable_i = '1' and pwm_cnt_r < duty_r
      then
        pwm_r <= '1';
      else
        pwm_r <= '0';
      end if;
    end if;
  end process;

  pwm_o                <= pwm_r;

end architecture rtl;
