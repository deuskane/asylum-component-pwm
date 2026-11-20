-------------------------------------------------------------------------------
-- Title      : tb_PWM_reset_values_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_reset_values_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario reset_values of tb_PWM, from reset :
--              Reset values of the registers (prescaler : PRESCALER_RATIO,
--              0 if not implemented), pwm_o low
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_reset_values of tb_PWM)
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

package tb_PWM_reset_values_pkg is

  -- Reset values of the registers (prescaler : PRESCALER_RATIO, 0 if not
  -- implemented), pwm_o low
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_reset_values_pkg;

package body tb_PWM_reset_values_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
  begin
    chk(PWM_CFG      , x"00"                                , "Reset value cfg"                                              , clk, sbi_if);
    chk(PWM_PRESCALER, prescaler_read(cfg, cfg.ratio_init), "Reset value prescaler (PRESCALER_RATIO, 0 if not implemented)", clk, sbi_if);
    chk(PWM_PERIOD   , x"FF"                                , "Reset value period"                                           , clk, sbi_if);
    chk(PWM_DUTY     , x"00"                                , "Reset value duty"                                             , clk, sbi_if);
    chk_pwm(pwm, '0', "PWM disabled, output low");
  end procedure;

end package body tb_PWM_reset_values_pkg;
