-------------------------------------------------------------------------------
-- Title      : tb_PWM_bfm_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_bfm_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_PWM and tb_pwm_core scenarios :
--              * measurement of a PWM output in clock cycles (high phase,
--                period, constant level)
--              * reset pulse
--              * SBI accesses (SBI VIP, zero wait state) and configuration
--                of sbi_PWM (tb_PWM only)
--              * durations computed from the generics of sbi_PWM (cfg_t)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-22  1.0      mrosiere Created (tb_pwm_pkg)
-- 2026-11-20  2.0      mrosiere tb_PWM_bfm_pkg : helpers of the scenario
--                               packages (SBI accesses, configuration,
--                               reset pulse, generics of sbi_PWM)
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

package tb_PWM_bfm_pkg is

  constant C_TB_SCOPE    : string  := "TB_PWM_BFM";
  constant C_CLK_PERIOD  : time    := 20 ns;    -- 50 MHz

  subtype  byte_t is std_logic_vector(8-1 downto 0);

  -- Generics of sbi_PWM
  type     cfg_t is record
    static_ratio   : positive;  -- STATIC_PRESCALER_RATIO
    user_prescaler : boolean;   -- USER_DEFINE_PRESCALER
    ratio_init     : byte_t;    -- PRESCALER_RATIO
  end record cfg_t;

  -- Zero wait state target : any cycle with ready = '0' is an error
  constant C_SBI_CFG     : t_sbi_bfm_config := (
    max_wait_cycles            => 0,
    max_wait_cycles_severity   => error,
    use_fixed_wait_cycles_read => false,
    fixed_wait_cycles_read     => 0,
    clock_period               => -1 ns,
    clock_period_margin        => 0 ns,
    clock_margin_severity      => TB_ERROR,
    setup_time                 => -1 ns,
    hold_time                  => -1 ns,
    bfm_sync                   => SYNC_ON_CLOCK_ONLY,
    match_strictness           => MATCH_EXACT,
    id_for_bfm                 => ID_BFM,
    id_for_bfm_wait            => ID_BFM_WAIT,
    id_for_bfm_poll            => ID_BFM_POLL,
    use_ready_signal           => true
  );

  -----------------------------------------------------------------------------
  -- Generics of sbi_PWM
  -----------------------------------------------------------------------------
  -- Duration of a tick in clock cycles when software writes ratio in the
  -- prescaler register (ratio fixed to PRESCALER_RATIO when
  -- USER_DEFINE_PRESCALER = false)
  function tick
    (constant cfg      : in    cfg_t
    ;constant ratio    : in    natural
    ) return natural;

  -- Value read in the prescaler register when software wrote value (0 when
  -- the register is not implemented)
  function prescaler_read
    (constant cfg      : in    cfg_t
    ;constant value    : in    byte_t
    ) return byte_t;

  -----------------------------------------------------------------------------
  -- PWM output
  -----------------------------------------------------------------------------
  -- Wait the next change of pwm to value : error if pwm is already at value
  -- (edge too early) or after timeout (edge too late)
  procedure wait_edge
    (signal   pwm      : in    std_logic
    ;constant value    : in    std_logic
    ;constant timeout  : in    time
    ;constant msg      : in    string
    );

  -- Check nb PWM periods of pwm, now is the rising edge of the first one :
  -- high phase and period in clock cycles. Ends on a rising edge of pwm.
  procedure check_periods
    (signal   pwm      : in    std_logic
    ;constant high     : in    natural
    ;constant period   : in    natural
    ;constant nb       : in    positive
    ;constant msg      : in    string
    );

  -- Check that pwm stays at level during cycles clock cycles
  procedure check_constant
    (signal   pwm      : in    std_logic
    ;constant level    : in    std_logic
    ;constant cycles   : in    natural
    ;constant msg      : in    string
    );

  -- Check of the level of pwm
  procedure chk_pwm
    (signal   pwm      : in    std_logic
    ;constant level    : in    std_logic
    ;constant msg      : in    string
    );

  -- Check the number of clock cycles since t0
  procedure chk_since
    (constant t0       : in    time
    ;constant cycles   : in    natural
    ;constant msg      : in    string
    );

  -- Wait n clock cycles
  procedure wait_cycles
    (constant n        : in    natural
    );

  -----------------------------------------------------------------------------
  -- Reset
  -----------------------------------------------------------------------------
  -- Reset pulse, released on a falling edge
  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    );

  -----------------------------------------------------------------------------
  -- SBI accesses (tb_PWM)
  -----------------------------------------------------------------------------
  -- SBI write
  procedure wr
    (constant addr     : in    unsigned
    ;constant data     : in    byte_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- SBI read and check
  procedure chk
    (constant addr     : in    unsigned
    ;constant data     : in    byte_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- PWM disabled, then prescaler ratio, period and duty written
  procedure configure
    (constant ratio    : in    natural
    ;constant period   : in    natural
    ;constant duty     : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- Enable : the first period starts (rising edge of pwm) on the first
  -- pulse of the static prescaler after the write, so less than
  -- STATIC_PRESCALER_RATIO clock cycles after the end of the write (the
  -- write is sampled on the rising edge of clk before the end of the SBI
  -- write, pwm_o is registered in pwm_core after the CSR register)
  procedure enable
    (constant cfg      : in    cfg_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   pwm      : in    std_logic
    );

end package tb_PWM_bfm_pkg;

package body tb_PWM_bfm_pkg is

  function tick
    (constant cfg      : in    cfg_t
    ;constant ratio    : in    natural
    ) return natural is
  begin
    if cfg.user_prescaler
    then
      return cfg.static_ratio * (ratio + 1);
    else
      return cfg.static_ratio * (to_integer(unsigned(cfg.ratio_init)) + 1);
    end if;
  end function;

  function prescaler_read
    (constant cfg      : in    cfg_t
    ;constant value    : in    byte_t
    ) return byte_t is
  begin
    if cfg.user_prescaler
    then
      return value;
    else
      return x"00";
    end if;
  end function;

  procedure wait_edge
    (signal   pwm      : in    std_logic
    ;constant value    : in    std_logic
    ;constant timeout  : in    time
    ;constant msg      : in    string
    ) is
  begin
    -- pwm already at value : the edge came too early
    check_value(pwm, not value, error, msg & " : not yet", C_TB_SCOPE);
    wait until pwm = value for timeout;
    check_value(pwm, value, error, msg, C_TB_SCOPE);
  end procedure;

  procedure check_periods
    (signal   pwm      : in    std_logic
    ;constant high     : in    natural
    ;constant period   : in    natural
    ;constant nb       : in    positive
    ;constant msg      : in    string
    ) is
    variable v_t0      : time;
  begin
    for i in 1 to nb loop
      v_t0 := now;
      wait_edge(pwm, '0', (high  +1)*C_CLK_PERIOD, msg & " : falling edge, period " & to_string(i));
      chk_since(v_t0, high  , msg & " : high phase (clock cycles), period " & to_string(i));
      wait_edge(pwm, '1', (period+1)*C_CLK_PERIOD, msg & " : rising edge, period " & to_string(i));
      chk_since(v_t0, period, msg & " : PWM period (clock cycles), period " & to_string(i));
    end loop;
  end procedure;

  procedure check_constant
    (signal   pwm      : in    std_logic
    ;constant level    : in    std_logic
    ;constant cycles   : in    natural
    ;constant msg      : in    string
    ) is
  begin
    wait_cycles(cycles);
    check_value (pwm, level, error, msg & " : level", C_TB_SCOPE);
    check_stable(pwm, cycles*C_CLK_PERIOD, error, msg & " : stable during " & to_string(cycles) & " clock cycles", C_TB_SCOPE);
  end procedure;

  procedure chk_pwm
    (signal   pwm      : in    std_logic
    ;constant level    : in    std_logic
    ;constant msg      : in    string
    ) is
  begin
    check_value(pwm, level, error, msg, C_TB_SCOPE);
  end procedure;

  procedure chk_since
    (constant t0       : in    time
    ;constant cycles   : in    natural
    ;constant msg      : in    string
    ) is
  begin
    check_value((now - t0) / C_CLK_PERIOD, cycles, error, msg, C_TB_SCOPE);
  end procedure;

  procedure wait_cycles
    (constant n        : in    natural
    ) is
  begin
    wait for n*C_CLK_PERIOD;
  end procedure;

  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ) is
  begin
    arst_b <= '0';
    wait for 100 ns;
    wait until falling_edge(clk);
    arst_b <= '1';
    wait until rising_edge(clk);
  end procedure;

  procedure wr
    (constant addr     : in    unsigned
    ;constant data     : in    byte_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    sbi_write(addr_value => addr
             ,data_value => data
             ,msg        => msg
             ,clk        => clk
             ,sbi_if     => sbi_if
             ,scope      => C_TB_SCOPE
             ,config     => C_SBI_CFG
             );
  end procedure;

  procedure chk
    (constant addr     : in    unsigned
    ;constant data     : in    byte_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    sbi_check(addr_value  => addr
             ,data_exp    => data
             ,msg         => msg
             ,clk         => clk
             ,sbi_if      => sbi_if
             ,alert_level => error
             ,scope       => C_TB_SCOPE
             ,config      => C_SBI_CFG
             );
  end procedure;

  procedure configure
    (constant ratio    : in    natural
    ;constant period   : in    natural
    ;constant duty     : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    wr(PWM_CFG      , x"00"                                    , msg & " : disable PWM"                     , clk, sbi_if);
    wr(PWM_PRESCALER, std_logic_vector(to_unsigned(ratio , 8)), msg & " : prescaler " & to_string(ratio ), clk, sbi_if);
    wr(PWM_PERIOD   , std_logic_vector(to_unsigned(period, 8)), msg & " : period "    & to_string(period), clk, sbi_if);
    wr(PWM_DUTY     , std_logic_vector(to_unsigned(duty  , 8)), msg & " : duty "      & to_string(duty  ), clk, sbi_if);
  end procedure;

  procedure enable
    (constant cfg      : in    cfg_t
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   pwm      : in    std_logic
    ) is
  begin
    wr(PWM_CFG, x"01", msg & " : enable PWM", clk, sbi_if);
    wait_edge(pwm, '1', cfg.static_ratio*C_CLK_PERIOD, msg & " : first period starts on the next pulse of the static prescaler");
  end procedure;

end package body tb_PWM_bfm_pkg;
