-------------------------------------------------------------------------------
-- Title      : tb_pwm_core_tests_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_pwm_core_tests_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_pwm_core : names (valid items of TESTS_LIST)
--              and dispatch (run_test) to the package of each scenario
--              (tb_pwm_core_<name>_pkg)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_PWM_bfm_pkg.all;

package tb_pwm_core_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "prescaler,full_period,update_duty,always_high";

  -- Run the scenario name
  procedure run_test
    (constant name       : in    string
    ;signal   clk        : in    std_logic
    ;signal   cfg_enable : out   std_logic
    ;signal   cfg_ratio  : out   std_logic_vector -- cfg_prescaler_ratio_i
    ;signal   cfg_period : out   std_logic_vector
    ;signal   cfg_duty   : out   std_logic_vector
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_pwm_core_tests_pkg;

package body tb_pwm_core_tests_pkg is

  procedure run_test
    (constant name       : in    string
    ;signal   clk        : in    std_logic
    ;signal   cfg_enable : out   std_logic
    ;signal   cfg_ratio  : out   std_logic_vector
    ;signal   cfg_period : out   std_logic_vector
    ;signal   cfg_duty   : out   std_logic_vector
    ;signal   pwm        : in    std_logic
    ) is
  begin
    if    string_eq(name, "prescaler")
    then
      work.tb_pwm_core_prescaler_pkg.run  (clk, cfg_enable, cfg_ratio, cfg_period, cfg_duty, pwm);
    elsif string_eq(name, "full_period")
    then
      work.tb_pwm_core_full_period_pkg.run(clk, cfg_enable, cfg_ratio, cfg_period, cfg_duty, pwm);
    elsif string_eq(name, "update_duty")
    then
      work.tb_pwm_core_update_duty_pkg.run(clk, cfg_enable, cfg_ratio, cfg_period, cfg_duty, pwm);
    elsif string_eq(name, "always_high")
    then
      work.tb_pwm_core_always_high_pkg.run(clk, cfg_enable, cfg_ratio, cfg_period, cfg_duty, pwm);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_pwm_core_tests_pkg;
