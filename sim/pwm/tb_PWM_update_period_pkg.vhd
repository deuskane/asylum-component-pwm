-------------------------------------------------------------------------------
-- Title      : tb_PWM_update_period_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_update_period_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario update_period of tb_PWM, from reset :
--              Period increased during the low phase, then period and duty
--              decreased below the counter : the current period is
--              unchanged, the counter does not overflow
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_update_period of tb_PWM)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.PWM_csr_pkg.all;

library work;
use     work.tb_PWM_bfm_pkg.all;

package tb_PWM_update_period_pkg is

  -- Period increased during the low phase, then period and duty decreased
  -- below the counter : the current period is unchanged, the counter does not
  -- overflow
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_update_period_pkg;

package body tb_PWM_update_period_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant T    : natural := tick(cfg, 3);
    variable v_t0 : time;
  begin
    -- Period 16 ticks, duty 12 ticks
    configure(3, 15, 12, "Update period", clk, sbi_if);
    enable(cfg, "Update period", clk, sbi_if, pwm);
    check_periods(pwm, 12*T, 16*T, 1, "Update period : initial configuration");

    -- Period increased during the low phase (counter 12) : the current period is not extended
    v_t0 := now;
    wait_cycles(25*T/2);
    wr(PWM_PERIOD, x"13", "Update : period 19 during the low phase", clk, sbi_if);
    wait_edge(pwm, '1', 20*T*C_CLK_PERIOD, "Update period 19 : rising edge");
    chk_since(v_t0, 16*T, "Update period 19 : current period unchanged");
    check_periods(pwm, 12*T, 20*T, 1, "Update period 19 : next period");

    -- Duty and period decreased below the counter (15) : the counter does not overflow
    v_t0 := now;
    wait_cycles(15*T);
    wr(PWM_DUTY  , x"02", "Update : duty 2 when the counter is 15"  , clk, sbi_if);
    wr(PWM_PERIOD, x"05", "Update : period 5 when the counter is 15", clk, sbi_if);
    wait_edge(pwm, '1', 20*T*C_CLK_PERIOD, "Update period 5 : rising edge");
    chk_since(v_t0, 20*T, "Update period 5 : current period unchanged");
    check_periods(pwm, 2*T, 6*T, 2, "Update period 5 : next periods");
  end procedure;

end package body tb_PWM_update_period_pkg;
