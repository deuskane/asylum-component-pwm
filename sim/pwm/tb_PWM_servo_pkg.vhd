-------------------------------------------------------------------------------
-- Title      : tb_PWM_servo_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_servo_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario servo of tb_PWM, from reset :
--              Prescaler 249, period 199, duty 15 (servo pulse of 1.5 ms
--              every 20 ms with a 50 MHz clock and STATIC_PRESCALER_RATIO =
--              20)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_servo of tb_PWM)
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

package tb_PWM_servo_pkg is

  -- Prescaler 249, period 199, duty 15 (servo pulse of 1.5 ms every 20 ms with
  -- a 50 MHz clock and STATIC_PRESCALER_RATIO = 20)
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    );

end package tb_PWM_servo_pkg;

package body tb_PWM_servo_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ;signal   pwm        : in    std_logic        -- pwm_o
    ) is
    constant T : natural := tick(cfg, 249);
  begin
    -- 50 Hz with a 50 MHz clock and STATIC_PRESCALER_RATIO = 20 :
    -- 20*(249+1)*(199+1) = 1000000 clock cycles, duty 15 ticks of 5000
    -- clock cycles (100 us) : 1.5 ms pulse (servo center)
    configure(249, 199, 15, "Servo", clk, sbi_if);
    enable(cfg, "Servo", clk, sbi_if, pwm);
    check_periods(pwm, 15*T, 200*T, 2, "Servo : 15 ticks every 200 ticks");
    log(ID_SEQUENCER, "Servo : PWM period " & to_string(200*T*C_CLK_PERIOD, ms) & ", high phase " & to_string(15*T*C_CLK_PERIOD, us), C_TB_SCOPE);
  end procedure;

end package body tb_PWM_servo_pkg;
