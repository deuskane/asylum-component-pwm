-------------------------------------------------------------------------------
-- Title      : tb_pwm_core
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_pwm_core.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: UVVM self-checking testbench of pwm_core alone (no CSR, no
--              SBI), with the prescaler and counter widths of the generics.
--              One scenario per simulation, selected by TEST (one FuseSoC
--              target per scenario). The configuration is driven directly,
--              the high phase and the period of pwm_o are measured in clock
--              cycles and checked exactly.
--              TEST :
--              * prescaler   : maximum prescaler ratio, period 1000 ticks
--                              (or the maximum period if lower)
--              * full_period : maximum period, duty half of it
--              * update_duty : maximum duty written at the start of a
--                              period, taken into account at the next one
--              * always_high : duty greater than period
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-22  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.pwm_pkg.all;

library work;
use     work.tb_pwm_pkg.all;

entity tb_pwm_core is
  generic (
    TEST                  : string  := "prescaler";   -- Scenario
    PRESCALER_WIDTH       : natural := 4;             -- Generics of the DUT
    COUNTER_WIDTH         : natural := 12
    );
end tb_pwm_core;

architecture sim of tb_pwm_core is

  constant C_SCOPE            : string  := C_PWM_SCOPE;

  constant C_RATIO_MAX        : natural := 2**PRESCALER_WIDTH-1;
  constant C_COUNT_MAX        : natural := 2**COUNTER_WIDTH-1;

  -- Clock & Reset
  signal   clk_i              : std_logic := '0';
  signal   clk_ena            : boolean   := true;
  signal   arst_b_i           : std_logic := '0';

  -- DUT
  signal   cfg_enable         : std_logic := '0';
  signal   cfg_ratio          : std_logic_vector(PRESCALER_WIDTH-1 downto 0) := (others => '0');
  signal   cfg_period         : std_logic_vector(COUNTER_WIDTH-1   downto 0) := (others => '0');
  signal   cfg_duty           : std_logic_vector(COUNTER_WIDTH-1   downto 0) := (others => '0');
  signal   pwm_o              : std_logic;

begin

  clock_generator(clk_i, clk_ena, C_CLK_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUT
  -----------------------------------------------------------------------------
  dut : pwm_core
    generic map (
      PRESCALER_WIDTH       => PRESCALER_WIDTH
     ,COUNTER_WIDTH         => COUNTER_WIDTH
    )
    port map (
      clk_i                 => clk_i
     ,arst_b_i              => arst_b_i
     ,cfg_enable_i          => cfg_enable
     ,cfg_prescaler_ratio_i => cfg_ratio
     ,cfg_period_i          => cfg_period
     ,cfg_duty_i            => cfg_duty
     ,pwm_o                 => pwm_o
    );

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_main : process

    -- Drive the configuration after a rising edge of clk_i
    procedure configure(enable : std_logic; ratio : natural; period : natural; duty : natural) is
    begin
      wait until rising_edge(clk_i);
      cfg_enable  <= enable;
      cfg_ratio   <= std_logic_vector(to_unsigned(ratio , PRESCALER_WIDTH));
      cfg_period  <= std_logic_vector(to_unsigned(period, COUNTER_WIDTH));
      cfg_duty    <= std_logic_vector(to_unsigned(duty  , COUNTER_WIDTH));
    end procedure;

    -- Disable, configure, then enable : the first period starts one clock
    -- cycle after the enable (sampled on the next rising edge of clk_i)
    procedure start(ratio : natural; period : natural; duty : natural; msg : string) is
    begin
      configure('0', ratio, period, duty);
      configure('1', ratio, period, duty);
      wait_edge(pwm_o, '1', 2*C_CLK_PERIOD, msg & " : first period starts one clock cycle after the enable");
    end procedure;

    ---------------------------------------------------------------------------
    -- Scenarios
    ---------------------------------------------------------------------------
    procedure test_prescaler is
      constant RATIO  : natural := C_RATIO_MAX;
      constant PERIOD : natural := minimum(999, C_COUNT_MAX);
      constant DUTY   : natural := (PERIOD+1)/4;
    begin
      configure('0', RATIO, PERIOD, DUTY);
      check_constant(pwm_o, '0', 10, "Prescaler : disabled");
      start(RATIO, PERIOD, DUTY, "Prescaler");
      check_periods(pwm_o, DUTY*(RATIO+1), (PERIOD+1)*(RATIO+1), 2,
                    "Prescaler : tick of " & to_string(RATIO+1) & " cycles, period " & to_string(PERIOD+1) & " ticks, duty " & to_string(DUTY) & " ticks");
    end procedure;

    procedure test_full_period is
    begin
      start(0, C_COUNT_MAX, (C_COUNT_MAX+1)/2, "Full period");
      check_periods(pwm_o, (C_COUNT_MAX+1)/2, C_COUNT_MAX+1, 2, "Full period : period " & to_string(C_COUNT_MAX+1) & " ticks, duty half");
    end procedure;

    procedure test_update_duty is
    begin
      start(0, C_COUNT_MAX, (C_COUNT_MAX+1)/2, "Update duty");
      check_periods(pwm_o, (C_COUNT_MAX+1)/2, C_COUNT_MAX+1, 1, "Update duty : initial configuration");

      -- check_periods ends on a rising edge of pwm_o : duty changed at the
      -- start of a period
      cfg_duty    <= std_logic_vector(to_unsigned(C_COUNT_MAX, COUNTER_WIDTH));
      check_periods(pwm_o, (C_COUNT_MAX+1)/2, C_COUNT_MAX+1, 1, "Update duty : maximum duty written, current period unchanged");
      check_periods(pwm_o, C_COUNT_MAX      , C_COUNT_MAX+1, 1, "Update duty : maximum duty, low during one tick");
    end procedure;

    procedure test_always_high is
    begin
      start(0, C_COUNT_MAX-1, C_COUNT_MAX, "Always high");
      check_constant(pwm_o, '1', 3*C_COUNT_MAX-1, "Always high : duty > period");
    end procedure;

  begin
    arst_b_i <= '0';
    wait for 100 ns;
    arst_b_i <= '1';
    wait until rising_edge(clk_i);

    log(ID_LOG_HDR, "Test " & TEST & " (PRESCALER_WIDTH = " & to_string(PRESCALER_WIDTH) &
                    ", COUNTER_WIDTH = " & to_string(COUNTER_WIDTH) & ")", C_SCOPE);

    if    TEST = "prescaler"   then test_prescaler;
    elsif TEST = "full_period" then test_full_period;
    elsif TEST = "update_duty" then test_update_duty;
    elsif TEST = "always_high" then test_always_high;
    else
      alert(TB_FAILURE, "Unknown TEST """ & TEST & """", C_SCOPE);
    end if;

    log(ID_LOG_HDR, "Simulation Finished", C_SCOPE);
    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_main;

end sim;
