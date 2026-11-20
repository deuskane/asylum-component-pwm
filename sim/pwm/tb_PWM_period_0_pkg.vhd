-------------------------------------------------------------------------------
-- Title      : tb_PWM_period_0_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_period_0_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario period_0 of tb_PWM, from reset :
--              PWM period of one tick : duty 0 always low, duty 1 always
--              high
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_period_0 of tb_PWM)
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

package tb_PWM_period_0_pkg is

  -- PWM period of one tick : duty 0 always low, duty 1 always high
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_period_0_pkg;

package body tb_PWM_period_0_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant T : natural := tick(cfg, 2);
  begin
    configure(2, 0, 0, "Period 0, duty 0", clk, sbi_if);
    wr(PWM_CFG, x"01", "Period 0, duty 0 : enable PWM", clk, sbi_if);
    check_constant(pwm, '0', 10*T, "Period 0, duty 0 : always low");

    configure(2, 0, 1, "Period 0, duty 1", clk, sbi_if);
    enable(cfg, "Period 0, duty 1", clk, sbi_if, pwm);
    check_constant(pwm, '1', 10*T, "Period 0, duty 1 : always high");
  end procedure;

end package body tb_PWM_period_0_pkg;
