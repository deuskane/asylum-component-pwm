-------------------------------------------------------------------------------
-- Title      : tb_PWM_duty_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_duty_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario duty of tb_PWM, from reset :
--              Duty 0 (always low), 1, period (low during one tick),
--              period+1 and 255 (always high)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_duty of tb_PWM)
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

package tb_PWM_duty_pkg is

  -- Duty 0 (always low), 1, period (low during one tick), period+1 and 255
  -- (always high)
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_duty_pkg;

package body tb_PWM_duty_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant T : natural := tick(cfg, 1);
  begin
    configure(1, 9, 0, "Duty 0", clk, sbi_if);
    wr(PWM_CFG, x"01", "Duty 0 : enable PWM", clk, sbi_if);
    check_constant(pwm, '0', 3*10*T, "Duty 0 : always low");

    configure(1, 9, 1, "Duty 1", clk, sbi_if);
    enable(cfg, "Duty 1", clk, sbi_if, pwm);
    check_periods(pwm, T, 10*T, 2, "Duty 1");

    configure(1, 9, 9, "Duty = period", clk, sbi_if);
    enable(cfg, "Duty = period", clk, sbi_if, pwm);
    check_periods(pwm, 9*T, 10*T, 2, "Duty = period : low during one tick");

    configure(1, 9, 10, "Duty = period+1", clk, sbi_if);
    enable(cfg, "Duty = period+1", clk, sbi_if, pwm);
    check_constant(pwm, '1', 3*10*T-1, "Duty = period+1 : always high");

    configure(1, 9, 255, "Duty 255", clk, sbi_if);
    enable(cfg, "Duty 255", clk, sbi_if, pwm);
    check_constant(pwm, '1', 3*10*T-1, "Duty 255 : always high");
  end procedure;

end package body tb_PWM_duty_pkg;
