-------------------------------------------------------------------------------
-- Title      : tb_PWM_update_duty_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_update_duty_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario update_duty of tb_PWM, from reset :
--              Duty decreased during the high phase, increased during the
--              low phase : the current period is unchanged, the new duty is
--              taken into account at the next period
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_update_duty of tb_PWM)
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

package tb_PWM_update_duty_pkg is

  -- Duty decreased during the high phase, increased during the low phase : the
  -- current period is unchanged, the new duty is taken into account at the
  -- next period
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_update_duty_pkg;

package body tb_PWM_update_duty_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant T    : natural := tick(cfg, 3);
    variable v_t0 : time;
  begin
    -- Period 16 ticks, duty 8 ticks
    configure(3, 15, 8, "Update duty", clk, sbi_if);
    enable(cfg, "Update duty", clk, sbi_if, pwm);
    check_periods(pwm, 8*T, 16*T, 1, "Update duty : initial configuration");

    -- Duty decreased during the high phase : the current high phase is not cut
    v_t0 := now;
    wait_cycles(T);
    wr(PWM_DUTY, x"04", "Update : duty 4 during the high phase", clk, sbi_if);
    wait_edge(pwm, '0', 16*T*C_CLK_PERIOD, "Update duty 4 : falling edge");
    chk_since(v_t0, 8*T, "Update duty 4 : current high phase unchanged");
    wait_edge(pwm, '1', 16*T*C_CLK_PERIOD, "Update duty 4 : rising edge");
    chk_since(v_t0, 16*T, "Update duty 4 : current period unchanged");
    check_periods(pwm, 4*T, 16*T, 1, "Update duty 4 : next period");

    -- Duty increased during the low phase : no second pulse in the current
    -- period ; enable written again : the period is not restarted
    v_t0 := now;
    wait_edge(pwm, '0', 16*T*C_CLK_PERIOD, "Update duty 12 : falling edge");
    wr(PWM_DUTY, x"0C", "Update : duty 12 during the low phase", clk, sbi_if);
    wr(PWM_CFG , x"01", "Update : cfg written again (read-modify-write), the period goes on", clk, sbi_if);
    wait_edge(pwm, '1', 16*T*C_CLK_PERIOD, "Update duty 12 : rising edge");
    chk_since(v_t0, 16*T, "Update duty 12 : low until the end of the current period");
    check_periods(pwm, 12*T, 16*T, 1, "Update duty 12 : next period");
  end procedure;

end package body tb_PWM_update_duty_pkg;
