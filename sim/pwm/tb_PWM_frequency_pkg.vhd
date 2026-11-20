-------------------------------------------------------------------------------
-- Title      : tb_PWM_frequency_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_frequency_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario frequency of tb_PWM, from reset :
--              Reset values of prescaler (PRESCALER_RATIO) and period
--              (0xFF), duty 50 % (1 kHz with a 50 MHz clock and the default
--              generics)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_frequency of tb_PWM)
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

package tb_PWM_frequency_pkg is

  -- Reset values of prescaler (PRESCALER_RATIO) and period (0xFF), duty 50 %
  -- (1 kHz with a 50 MHz clock and the default generics)
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_frequency_pkg;

package body tb_PWM_frequency_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant T : natural := tick(cfg, to_integer(unsigned(cfg.ratio_init)));
  begin
    -- Reset values of prescaler (PRESCALER_RATIO) and period (0xFF)
    wr(PWM_DUTY, x"80", "Frequency : duty 128", clk, sbi_if);
    enable(cfg, "Frequency", clk, sbi_if, pwm);
    check_periods(pwm, 128*T, 256*T, 2, "Frequency : reset values of prescaler and period, duty 50%");
    log(ID_SEQUENCER, "Frequency : PWM period " & to_string(256*T*C_CLK_PERIOD, us), C_TB_SCOPE);
  end procedure;

end package body tb_PWM_frequency_pkg;
