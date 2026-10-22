-------------------------------------------------------------------------------
-- Title      : tb_pwm_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_pwm_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Constants and checks shared by the PWM testbenches (tb_PWM,
--              tb_pwm_core) : measurement of the high phase and of the period
--              of a PWM output in clock cycles, check of a constant level.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-22  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

package tb_pwm_pkg is

  constant C_PWM_SCOPE        : string  := "TB_PWM";  -- Scope of the logs and alerts (C_SCOPE of uvvm_util is hidden by the C_SCOPE of the testbenches)
  constant C_CLK_PERIOD       : time    := 20 ns;    -- 50 MHz

  -- Wait the next change of pwm to value, error after timeout
  procedure wait_edge(
    signal   pwm     : in std_logic;
    constant value   : in std_logic;
    constant timeout : in time;
    constant msg     : in string);

  -- Check nb PWM periods of pwm, now is the rising edge of the first one :
  -- high phase and period in clock cycles. Ends on a rising edge of pwm.
  procedure check_periods(
    signal   pwm     : in std_logic;
    constant high    : in natural;
    constant period  : in natural;
    constant nb      : in positive;
    constant msg     : in string);

  -- Check that pwm stays at level during cycles clock cycles
  procedure check_constant(
    signal   pwm     : in std_logic;
    constant level   : in std_logic;
    constant cycles  : in natural;
    constant msg     : in string);

end package tb_pwm_pkg;

package body tb_pwm_pkg is

  procedure wait_edge(
    signal   pwm     : in std_logic;
    constant value   : in std_logic;
    constant timeout : in time;
    constant msg     : in string) is
  begin
    wait until pwm = value for timeout;
    check_value(pwm, value, ERROR, msg, C_PWM_SCOPE);
  end procedure;

  procedure check_periods(
    signal   pwm     : in std_logic;
    constant high    : in natural;
    constant period  : in natural;
    constant nb      : in positive;
    constant msg     : in string) is
    variable v_t0    : time;
  begin
    for i in 1 to nb loop
      v_t0 := now;
      wait_edge(pwm, '0', (high  +1)*C_CLK_PERIOD, msg & " : falling edge, period " & to_string(i));
      check_value((now - v_t0) / C_CLK_PERIOD, high  , ERROR, msg & " : high phase (clock cycles), period " & to_string(i), C_PWM_SCOPE);
      wait_edge(pwm, '1', (period+1)*C_CLK_PERIOD, msg & " : rising edge, period " & to_string(i));
      check_value((now - v_t0) / C_CLK_PERIOD, period, ERROR, msg & " : PWM period (clock cycles), period " & to_string(i), C_PWM_SCOPE);
    end loop;
  end procedure;

  procedure check_constant(
    signal   pwm     : in std_logic;
    constant level   : in std_logic;
    constant cycles  : in natural;
    constant msg     : in string) is
  begin
    wait for cycles*C_CLK_PERIOD;
    check_value (pwm, level, ERROR, msg & " : level", C_PWM_SCOPE);
    check_stable(pwm, cycles*C_CLK_PERIOD, ERROR, msg & " : stable during " & to_string(cycles) & " clock cycles", C_PWM_SCOPE);
  end procedure;

end package body tb_pwm_pkg;
