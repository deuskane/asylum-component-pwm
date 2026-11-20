-------------------------------------------------------------------------------
-- Title      : tb_pwm_core_always_high_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_pwm_core_always_high_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario always_high of tb_pwm_core, from reset :
--              Duty greater than period : always high
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_always_high of tb_pwm_core)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_PWM_bfm_pkg.all;
use     work.tb_pwm_core_bfm_pkg.all;

package tb_pwm_core_always_high_pkg is

  -- Duty greater than period : always high
  procedure run
    (signal   clk        : in    std_logic
    ;signal   cfg_enable : out   std_logic
    ;signal   cfg_ratio  : out   std_logic_vector -- cfg_prescaler_ratio_i
    ;signal   cfg_period : out   std_logic_vector
    ;signal   cfg_duty   : out   std_logic_vector
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_pwm_core_always_high_pkg;

package body tb_pwm_core_always_high_pkg is

  procedure run
    (signal   clk        : in    std_logic
    ;signal   cfg_enable : out   std_logic
    ;signal   cfg_ratio  : out   std_logic_vector -- cfg_prescaler_ratio_i
    ;signal   cfg_period : out   std_logic_vector
    ;signal   cfg_duty   : out   std_logic_vector
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant C_COUNT_MAX : natural := 2**cfg_period'length-1;
  begin
    start(0, C_COUNT_MAX-1, C_COUNT_MAX, "Always high", clk, cfg_enable, cfg_ratio, cfg_period, cfg_duty, pwm);
    check_constant(pwm, '1', 3*C_COUNT_MAX-1, "Always high : duty > period");
  end procedure;

end package body tb_pwm_core_always_high_pkg;
