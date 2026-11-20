-------------------------------------------------------------------------------
-- Title      : tb_pwm_core_bfm_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_pwm_core_bfm_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_pwm_core scenarios : configuration inputs
--              of pwm_core driven after a rising edge of the clock (the
--              measurement helpers are in tb_PWM_bfm_pkg)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was in tb_pwm_core)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_PWM_bfm_pkg.all;

package tb_pwm_core_bfm_pkg is

  -- Drive the configuration after a rising edge of clk
  procedure drive
    (constant enable     : in    std_logic
    ;constant ratio      : in    natural
    ;constant period     : in    natural
    ;constant duty       : in    natural
    ;signal   clk        : in    std_logic
    ;signal   cfg_enable : out   std_logic
    ;signal   cfg_ratio  : out   std_logic_vector -- cfg_prescaler_ratio_i
    ;signal   cfg_period : out   std_logic_vector
    ;signal   cfg_duty   : out   std_logic_vector
    );

  -- Disable, configure, then enable : the first period starts one clock
  -- cycle after the enable (sampled on the next rising edge of clk)
  procedure start
    (constant ratio      : in    natural
    ;constant period     : in    natural
    ;constant duty       : in    natural
    ;constant msg        : in    string
    ;signal   clk        : in    std_logic
    ;signal   cfg_enable : out   std_logic
    ;signal   cfg_ratio  : out   std_logic_vector -- cfg_prescaler_ratio_i
    ;signal   cfg_period : out   std_logic_vector
    ;signal   cfg_duty   : out   std_logic_vector
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_pwm_core_bfm_pkg;

package body tb_pwm_core_bfm_pkg is

  procedure drive
    (constant enable     : in    std_logic
    ;constant ratio      : in    natural
    ;constant period     : in    natural
    ;constant duty       : in    natural
    ;signal   clk        : in    std_logic
    ;signal   cfg_enable : out   std_logic
    ;signal   cfg_ratio  : out   std_logic_vector
    ;signal   cfg_period : out   std_logic_vector
    ;signal   cfg_duty   : out   std_logic_vector
    ) is
  begin
    wait until rising_edge(clk);
    cfg_enable <= enable;
    cfg_ratio  <= std_logic_vector(to_unsigned(ratio , cfg_ratio 'length));
    cfg_period <= std_logic_vector(to_unsigned(period, cfg_period'length));
    cfg_duty   <= std_logic_vector(to_unsigned(duty  , cfg_duty  'length));
  end procedure;

  procedure start
    (constant ratio      : in    natural
    ;constant period     : in    natural
    ;constant duty       : in    natural
    ;constant msg        : in    string
    ;signal   clk        : in    std_logic
    ;signal   cfg_enable : out   std_logic
    ;signal   cfg_ratio  : out   std_logic_vector
    ;signal   cfg_period : out   std_logic_vector
    ;signal   cfg_duty   : out   std_logic_vector
    ;signal   pwm        : in    std_logic
    ) is
  begin
    drive('0', ratio, period, duty, clk, cfg_enable, cfg_ratio, cfg_period, cfg_duty);
    drive('1', ratio, period, duty, clk, cfg_enable, cfg_ratio, cfg_period, cfg_duty);
    wait_edge(pwm, '1', 2*C_CLK_PERIOD, msg & " : first period starts one clock cycle after the enable");
  end procedure;

end package body tb_pwm_core_bfm_pkg;
