-------------------------------------------------------------------------------
-- Title      : tb_PWM_disabled_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_disabled_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario disabled of tb_PWM, from reset :
--              Configured but not enabled, pwm_o stays low
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_disabled of tb_PWM)
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

package tb_PWM_disabled_pkg is

  -- Configured but not enabled, pwm_o stays low
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_disabled_pkg;

package body tb_PWM_disabled_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant T : natural := tick(cfg, 0);
  begin
    configure(0, 9, 3, "Disabled", clk, sbi_if);
    check_constant(pwm, '0', 5*10*T, "Disabled : output low");
  end procedure;

end package body tb_PWM_disabled_pkg;
