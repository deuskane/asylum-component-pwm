-------------------------------------------------------------------------------
-- Title      : tb_pwm_core
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_pwm_core.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: UVVM self-checking testbench of pwm_core alone (no CSR, no
--              SBI), with the prescaler and counter widths of the generics.
--              TESTS_LIST : scenarios run in sequence, separated by ','
--                           (tb_pwm_core_tests_pkg), each one after a
--                           reset pulse ; "" : build and elaboration only
--              The configuration is driven directly, the high phase and the
--              period of pwm_o are measured in clock cycles and checked
--              exactly.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-22  1.0      mrosiere Created
-- 2026-11-20  2.0      mrosiere TESTS_LIST, one package per scenario
--                               (tb_pwm_core_<name>_pkg), reset pulse
--                               before each scenario
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.string_pkg.all;
use     asylum.pwm_pkg.all;

library work;
use     work.tb_PWM_bfm_pkg.all;
use     work.tb_pwm_core_tests_pkg.all;

entity tb_pwm_core is
  generic (
    TESTS_LIST            : string  := ""            -- Scenarios, e.g. "prescaler,full_period"
   ;PRESCALER_WIDTH       : natural := 4             -- Generics of the DUT
   ;COUNTER_WIDTH         : natural := 12
  );
end entity tb_pwm_core;

architecture sim of tb_pwm_core is

  constant C_SCOPE            : string  := "TB_PWM_CORE";

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
    generic map
    (PRESCALER_WIDTH       => PRESCALER_WIDTH
    ,COUNTER_WIDTH         => COUNTER_WIDTH
    )
    port map
    (clk_i                 => clk_i
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
  p_sequencer : process
  begin
    log(ID_LOG_HDR, "PRESCALER_WIDTH = " & to_string(PRESCALER_WIDTH) &
                    ", COUNTER_WIDTH = " & to_string(COUNTER_WIDTH) &
                    ", TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST) loop
      if not list_contains(C_TESTS, list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST) loop
      -- Reset pulse, PWM disabled : each scenario starts from reset
      cfg_enable <= '0';
      cfg_ratio  <= (others => '0');
      cfg_period <= (others => '0');
      cfg_duty   <= (others => '0');
      do_reset(clk_i, arst_b_i);

      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), clk_i, cfg_enable, cfg_ratio, cfg_period, cfg_duty, pwm_o);
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;
