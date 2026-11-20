-------------------------------------------------------------------------------
-- Title      : tb_PWM_update_prescaler_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_update_prescaler_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario update_prescaler of tb_PWM, from reset :
--              Prescaler decreased during a period : the current period
--              keeps its ticks, the new ratio starts with the next period
--              (needs USER_DEFINE_PRESCALER = true)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_update_prescaler of tb_PWM)
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

package tb_PWM_update_prescaler_pkg is

  -- Prescaler decreased during a period : the current period keeps its ticks,
  -- the new ratio starts with the next period (needs USER_DEFINE_PRESCALER =
  -- true)
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_update_prescaler_pkg;

package body tb_PWM_update_prescaler_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant T_OLD : natural := tick(cfg, 3);
    constant T_NEW : natural := tick(cfg, 1);
    variable v_t0  : time;
  begin
    if not cfg.user_prescaler
    then
      alert(TB_ERROR, "update_prescaler needs USER_DEFINE_PRESCALER = true", C_TB_SCOPE);
      return;
    end if;

    -- Period 6 ticks, duty 2 ticks
    configure(3, 5, 2, "Update prescaler", clk, sbi_if);
    enable(cfg, "Update prescaler", clk, sbi_if, pwm);
    check_periods(pwm, 2*T_OLD, 6*T_OLD, 1, "Update prescaler : initial configuration");

    -- Prescaler decreased during a period : the current period keeps its ticks
    v_t0 := now;
    wait_cycles(5*T_OLD/2);
    wr(PWM_PRESCALER, x"01", "Update : prescaler 1 during a period", clk, sbi_if);
    wait_edge(pwm, '1', 6*T_OLD*C_CLK_PERIOD, "Update prescaler 1 : rising edge");
    chk_since(v_t0, 6*T_OLD, "Update prescaler 1 : current period unchanged");
    check_periods(pwm, 2*T_NEW, 6*T_NEW, 2, "Update prescaler 1 : next periods");
  end procedure;

end package body tb_PWM_update_prescaler_pkg;
