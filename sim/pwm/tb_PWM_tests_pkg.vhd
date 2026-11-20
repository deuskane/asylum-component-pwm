-------------------------------------------------------------------------------
-- Title      : tb_PWM_tests_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_tests_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_PWM : names (valid items of TESTS_LIST) and
--              dispatch (run_test) to the package of each scenario
--              (tb_PWM_<name>_pkg)
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

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_PWM_bfm_pkg.all;

package tb_PWM_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "reset_values,registers,disabled,no_prescaler,prescaler,duty,period_0," &
                               "update_duty,update_period,update_prescaler,disable_enable,frequency," &
                               "servo,async_reset";

  -- Run the scenario name
  procedure run_test
    (constant name     : in    string
    ;constant cfg      : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic        -- arst_b_i
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   pwm      : in    std_logic        -- pwm_o
    );

end package tb_PWM_tests_pkg;

package body tb_PWM_tests_pkg is

  procedure run_test
    (constant name     : in    string
    ;constant cfg      : in    cfg_t
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   pwm      : in    std_logic
    ) is
  begin
    if    string_eq(name, "reset_values")
    then
      work.tb_PWM_reset_values_pkg.run    (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "registers")
    then
      work.tb_PWM_registers_pkg.run       (cfg, clk, sbi_if);
    elsif string_eq(name, "disabled")
    then
      work.tb_PWM_disabled_pkg.run        (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "no_prescaler")
    then
      work.tb_PWM_no_prescaler_pkg.run    (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "prescaler")
    then
      work.tb_PWM_prescaler_pkg.run       (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "duty")
    then
      work.tb_PWM_duty_pkg.run            (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "period_0")
    then
      work.tb_PWM_period_0_pkg.run        (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "update_duty")
    then
      work.tb_PWM_update_duty_pkg.run     (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "update_period")
    then
      work.tb_PWM_update_period_pkg.run   (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "update_prescaler")
    then
      work.tb_PWM_update_prescaler_pkg.run(cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "disable_enable")
    then
      work.tb_PWM_disable_enable_pkg.run  (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "frequency")
    then
      work.tb_PWM_frequency_pkg.run       (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "servo")
    then
      work.tb_PWM_servo_pkg.run           (cfg, clk, sbi_if, pwm);
    elsif string_eq(name, "async_reset")
    then
      work.tb_PWM_async_reset_pkg.run     (cfg, clk, arst_b, sbi_if, pwm);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_PWM_tests_pkg;
