-------------------------------------------------------------------------------
-- Title      : tb_PWM_disable_enable_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_disable_enable_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario disable_enable of tb_PWM, from reset :
--              Disable during the high phase (output low one clock cycle
--              after, not delayed by the static prescaler), during the low
--              phase : each enable starts a complete period
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_disable_enable of tb_PWM)
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

package tb_PWM_disable_enable_pkg is

  -- Disable during the high phase (output low one clock cycle after, not
  -- delayed by the static prescaler), during the low phase : each enable
  -- starts a complete period
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_disable_enable_pkg;

package body tb_PWM_disable_enable_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant T : natural := tick(cfg, 1);
  begin
    -- Period 6 ticks, duty 2 ticks
    configure(1, 5, 2, "Disable / enable", clk, sbi_if);
    enable(cfg, "Disable / enable", clk, sbi_if, pwm);
    check_periods(pwm, 2*T, 6*T, 1, "Disable / enable : initial configuration");

    -- check_periods ends on a rising edge : disable during the high phase,
    -- not delayed by the static prescaler
    wr(PWM_CFG, x"00", "Disable during the high phase", clk, sbi_if);
    wait_edge(pwm, '0', C_CLK_PERIOD, "Disable : output low one clock cycle after the disable");
    check_constant(pwm, '0', 6*6*T, "Disable : output stays low");
    enable(cfg, "Enable after disable", clk, sbi_if, pwm);
    check_periods(pwm, 2*T, 6*T, 2, "Enable after disable : new period from the start");

    -- Disable during the low phase (counter not 0) : the counter is
    -- cleared, the next enable starts a complete period
    wait_edge(pwm, '0', 6*T*C_CLK_PERIOD, "Disable in the low phase : falling edge");
    wait_cycles(T);
    wr(PWM_CFG, x"00", "Disable during the low phase", clk, sbi_if);
    check_constant(pwm, '0', 6*6*T, "Disable in the low phase : output stays low");
    enable(cfg, "Enable after a disable in the low phase", clk, sbi_if, pwm);
    check_periods(pwm, 2*T, 6*T, 2, "Enable after a disable in the low phase : new period from the start");
  end procedure;

end package body tb_PWM_disable_enable_pkg;
