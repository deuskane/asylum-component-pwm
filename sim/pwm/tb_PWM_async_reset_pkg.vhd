-------------------------------------------------------------------------------
-- Title      : tb_PWM_async_reset_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_async_reset_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario async_reset of tb_PWM, from reset :
--              Asynchronous reset while pwm_o is high : pwm_o low without
--              clock edge, registers back to their reset values, pwm_o
--              stays low
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_reset of tb_PWM)
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

package tb_PWM_async_reset_pkg is

  -- Asynchronous reset while pwm_o is high : pwm_o low without clock edge,
  -- registers back to their reset values, pwm_o stays low
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   arst_b     : out   std_logic        -- arst_b_i
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_async_reset_pkg;

package body tb_PWM_async_reset_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   arst_b     : out   std_logic        -- arst_b_i
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
  begin
    -- duty > period : the output is high before the reset
    configure(0, 9, 10, "Reset", clk, sbi_if);
    enable(cfg, "Reset", clk, sbi_if, pwm);
    wait for 2*C_CLK_PERIOD + C_CLK_PERIOD/4;
    chk_pwm(pwm, '1', "Reset : output high before the reset");
    arst_b <= '0';
    wait for 1 ns;
    chk_pwm(pwm, '0', "Reset : output low without clock edge");
    do_reset(clk, arst_b);
    chk(PWM_CFG      , x"00"                                , "Reset : cfg back to its reset value"      , clk, sbi_if);
    chk(PWM_PRESCALER, prescaler_read(cfg, cfg.ratio_init), "Reset : prescaler back to its reset value", clk, sbi_if);
    chk(PWM_PERIOD   , x"FF"                                , "Reset : period back to its reset value"   , clk, sbi_if);
    chk(PWM_DUTY     , x"00"                                , "Reset : duty back to its reset value"     , clk, sbi_if);
    check_constant(pwm, '0', 50, "Reset : output stays low");
  end procedure;

end package body tb_PWM_async_reset_pkg;
