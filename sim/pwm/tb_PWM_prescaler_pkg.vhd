-------------------------------------------------------------------------------
-- Title      : tb_PWM_prescaler_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_prescaler_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario prescaler of tb_PWM, from reset :
--              Prescaler 4, start latency, period 8 ticks, duty 5 ticks
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_prescaler of tb_PWM)
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

package tb_PWM_prescaler_pkg is

  -- Prescaler 4, start latency, period 8 ticks, duty 5 ticks
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_prescaler_pkg;

package body tb_PWM_prescaler_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant T : natural := tick(cfg, 4);
  begin
    configure(4, 7, 5, "Prescaler 4", clk, sbi_if);
    enable(cfg, "Prescaler 4", clk, sbi_if, pwm);
    check_periods(pwm, 5*T, 8*T, 3, "Prescaler 4 : tick of " & to_string(T) & " cycles, period 8 ticks, duty 5 ticks");
  end procedure;

end package body tb_PWM_prescaler_pkg;
