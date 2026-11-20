-------------------------------------------------------------------------------
-- Title      : tb_pwm_core_prescaler_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_pwm_core_prescaler_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario prescaler of tb_pwm_core, from reset :
--              Maximum prescaler ratio, period 1000 ticks (or the maximum
--              period if lower), duty a quarter of it, output low while
--              disabled
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_prescaler of tb_pwm_core)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_PWM_bfm_pkg.all;
use     work.tb_pwm_core_bfm_pkg.all;

package tb_pwm_core_prescaler_pkg is

  -- Maximum prescaler ratio, period 1000 ticks (or the maximum period if
  -- lower), duty a quarter of it, output low while disabled
  procedure run
    (signal   clk        : in    std_logic
    ;signal   cfg_enable : out   std_logic
    ;signal   cfg_ratio  : out   std_logic_vector -- cfg_prescaler_ratio_i
    ;signal   cfg_period : out   std_logic_vector
    ;signal   cfg_duty   : out   std_logic_vector
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_pwm_core_prescaler_pkg;

package body tb_pwm_core_prescaler_pkg is

  procedure run
    (signal   clk        : in    std_logic
    ;signal   cfg_enable : out   std_logic
    ;signal   cfg_ratio  : out   std_logic_vector -- cfg_prescaler_ratio_i
    ;signal   cfg_period : out   std_logic_vector
    ;signal   cfg_duty   : out   std_logic_vector
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant C_RATIO_MAX : natural := 2**cfg_ratio'length -1;
    constant C_COUNT_MAX : natural := 2**cfg_period'length-1;
    constant RATIO       : natural := C_RATIO_MAX;
    constant PERIOD      : natural := minimum(999, C_COUNT_MAX);
    constant DUTY        : natural := (PERIOD+1)/4;
  begin
    drive('0', RATIO, PERIOD, DUTY, clk, cfg_enable, cfg_ratio, cfg_period, cfg_duty);
    check_constant(pwm, '0', 10, "Prescaler : disabled");
    start(RATIO, PERIOD, DUTY, "Prescaler", clk, cfg_enable, cfg_ratio, cfg_period, cfg_duty, pwm);
    check_periods(pwm, DUTY*(RATIO+1), (PERIOD+1)*(RATIO+1), 2,
                  "Prescaler : tick of " & to_string(RATIO+1) & " cycles, period " & to_string(PERIOD+1) & " ticks, duty " & to_string(DUTY) & " ticks");
  end procedure;

end package body tb_pwm_core_prescaler_pkg;
