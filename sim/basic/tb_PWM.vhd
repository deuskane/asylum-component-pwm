-------------------------------------------------------------------------------
-- Title      : tb_PWM
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: UVVM self-checking testbench of sbi_PWM. One scenario per
--              simulation, selected by TEST (one FuseSoC target per
--              scenario). The DUT generics are generics of the testbench :
--              the expected durations are computed from them (a tick lasts
--              STATIC_PRESCALER_RATIO*(ratio+1) clock cycles, ratio fixed to
--              PRESCALER_RATIO when USER_DEFINE_PRESCALER = false).
--              The CSR are accessed with the SBI BFM, the high phase and the
--              period of pwm_o are measured in clock cycles and checked
--              exactly.
--              TEST :
--              * reset_values     : reset values of the registers and pwm_o
--              * registers        : read / write of the registers
--              * disabled         : pwm_o low while the PWM is disabled
--              * no_prescaler     : start latency, timing with ratio 0
--              * prescaler        : start latency, timing with ratio 4
--              * duty             : duty 0, 1, period, period+1, 255
--              * period_0         : PWM period of one tick
--              * update_duty      : duty decreased during the high phase,
--                                   increased during the low phase : taken
--                                   into account at the next period
--              * update_period    : period increased, period and duty
--                                   decreased below the counter
--              * update_prescaler : prescaler decreased during a period
--                                   (USER_DEFINE_PRESCALER = true)
--              * disable_enable   : disable during the high phase, enable,
--                                   disable during the low phase, enable
--              * frequency        : reset values of prescaler and period
--              * servo            : prescaler 249, period 199, duty 15
--                                   (50 Hz with STATIC_PRESCALER_RATIO = 20)
--              * reset            : asynchronous reset while running
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-22  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.sbi_pkg.all;
use     asylum.pwm_pkg.all;
use     asylum.PWM_csr_pkg.all;

library work;
use     work.tb_pwm_pkg.all;

entity tb_PWM is
  generic (
    TEST                  : string   := "reset_values";              -- Scenario
    STATIC_PRESCALER_RATIO: positive := 1;                           -- Generics of the DUT
    USER_DEFINE_PRESCALER : boolean  := true;
    PRESCALER_RATIO       : std_logic_vector(8-1 downto 0) := x"C2"
    );
end tb_PWM;

architecture sim of tb_PWM is

  constant C_SCOPE            : string  := C_PWM_SCOPE;

  -- Register access patterns
  type     pattern_array_t is array (natural range <>) of std_logic_vector(7 downto 0);
  constant C_PATTERNS         : pattern_array_t := (x"5A", x"A5", x"0F", x"F0");

  -- Prescaler ratio used by the PWM when software writes ratio
  function ratio_eff(ratio : natural) return natural is
  begin
    if USER_DEFINE_PRESCALER then
      return ratio;
    else
      return to_integer(unsigned(PRESCALER_RATIO));
    end if;
  end function;

  -- Duration of a tick in clock cycles when software writes ratio
  function tick(ratio : natural) return natural is
  begin
    return STATIC_PRESCALER_RATIO * (ratio_eff(ratio) + 1);
  end function;

  -- Value read in the prescaler register when software wrote value
  -- (reset value : PRESCALER_RATIO)
  function prescaler_read(value : std_logic_vector(7 downto 0)) return std_logic_vector is
  begin
    if USER_DEFINE_PRESCALER then
      return value;
    else
      return x"00";
    end if;
  end function;

  -- Clock & Reset
  signal   clk_i              : std_logic := '0';
  signal   clk_ena            : boolean   := true;
  signal   arst_b_i           : std_logic := '0';

  -- DUT
  signal   sbi_ini            : sbi_ini_t(addr (PWM_ADDR_WIDTH-1 downto 0),
                                          wdata(PWM_DATA_WIDTH-1 downto 0));
  signal   sbi_tgt            : sbi_tgt_t(rdata(PWM_DATA_WIDTH-1 downto 0));
  signal   sbi_if             : t_sbi_if(addr (PWM_ADDR_WIDTH-1 downto 0),
                                         wdata(PWM_DATA_WIDTH-1 downto 0),
                                         rdata(PWM_DATA_WIDTH-1 downto 0));
  signal   pwm_o              : std_logic;

begin

  clock_generator(clk_i, clk_ena, C_CLK_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUT
  -----------------------------------------------------------------------------
  dut : sbi_PWM
    generic map (
      NAME                   => "PWM"
     ,STATIC_PRESCALER_RATIO => STATIC_PRESCALER_RATIO
     ,USER_DEFINE_PRESCALER  => USER_DEFINE_PRESCALER
     ,PRESCALER_RATIO        => PRESCALER_RATIO
    )
    port map (
      clk_i      => clk_i
     ,arst_b_i   => arst_b_i
     ,sbi_ini_i  => sbi_ini
     ,sbi_tgt_o  => sbi_tgt
     ,pwm_o      => pwm_o
    );

  sbi_ini.cs                              <= sbi_if.cs;
  sbi_ini.addr                            <= std_logic_vector(sbi_if.addr(PWM_ADDR_WIDTH-1 downto 0));
  sbi_ini.re                              <= sbi_if.rena;
  sbi_ini.we                              <= sbi_if.wena;
  sbi_ini.wdata                           <= sbi_if.wdata(PWM_DATA_WIDTH-1 downto 0);
  sbi_if.ready                            <= sbi_tgt.ready;
  sbi_if.rdata(PWM_DATA_WIDTH-1 downto 0) <= sbi_tgt.rdata;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_main : process
    variable v_sbi_config : t_sbi_bfm_config := C_SBI_BFM_CONFIG_DEFAULT;
    variable v_t0         : time;

    ---------------------------------------------------------------------------
    -- Register access and configuration
    ---------------------------------------------------------------------------
    procedure write_reg(addr : unsigned; data : std_logic_vector; msg : string) is
    begin
      sbi_write(addr, data, msg, clk_i, sbi_if, C_SCOPE, shared_msg_id_panel, v_sbi_config);
    end procedure;

    procedure check_reg(addr : unsigned; data : std_logic_vector; msg : string) is
    begin
      sbi_check(addr, data, msg, clk_i, sbi_if, ERROR, C_SCOPE, shared_msg_id_panel, v_sbi_config);
    end procedure;

    -- Configuration, PWM disabled : prescaler ratio, period and duty
    procedure configure(ratio : natural; period : natural; duty : natural; msg : string) is
    begin
      write_reg(PWM_CFG      , x"00", msg & " : disable PWM");
      write_reg(PWM_PRESCALER, std_logic_vector(to_unsigned(ratio , 8)), msg & " : prescaler " & to_string(ratio));
      write_reg(PWM_PERIOD   , std_logic_vector(to_unsigned(period, 8)), msg & " : period "    & to_string(period));
      write_reg(PWM_DUTY     , std_logic_vector(to_unsigned(duty  , 8)), msg & " : duty "      & to_string(duty));
    end procedure;

    -- Enable : the first period starts (rising edge) on the first pulse of
    -- the static prescaler after the write, so less than
    -- STATIC_PRESCALER_RATIO clock cycles after the end of the write (the
    -- write is sampled on the rising edge of clk_i before the end of
    -- sbi_write, pwm_o is registered in pwm_core after the CSR register)
    procedure enable_pwm(msg : string) is
    begin
      write_reg(PWM_CFG, x"01", msg & " : enable PWM");
      wait_edge(pwm_o, '1', STATIC_PRESCALER_RATIO*C_CLK_PERIOD, msg & " : first period starts on the next pulse of the static prescaler");
    end procedure;

    ---------------------------------------------------------------------------
    -- Scenarios
    ---------------------------------------------------------------------------
    procedure test_reset_values is
    begin
      check_reg(PWM_CFG      , x"00"                          , "Reset value cfg");
      check_reg(PWM_PRESCALER, prescaler_read(PRESCALER_RATIO), "Reset value prescaler (PRESCALER_RATIO, 0 if not implemented)");
      check_reg(PWM_PERIOD   , x"FF"                          , "Reset value period");
      check_reg(PWM_DUTY     , x"00"                          , "Reset value duty");
      check_value(pwm_o, '0', ERROR, "PWM disabled, output low", C_SCOPE);
    end procedure;

    procedure test_registers is
    begin
      -- Each register gets a different pattern, then the inverted pattern
      for i in C_PATTERNS'range loop
        write_reg(PWM_PRESCALER, C_PATTERNS(i)    , "Write prescaler 0x" & to_hstring(C_PATTERNS(i)));
        write_reg(PWM_PERIOD   , C_PATTERNS(i)(3 downto 0) & C_PATTERNS(i)(7 downto 4), "Write period");
        write_reg(PWM_DUTY     , not C_PATTERNS(i), "Write duty");
        check_reg(PWM_PRESCALER, prescaler_read(C_PATTERNS(i)), "Read back prescaler (0 if not implemented)");
        check_reg(PWM_PERIOD   , C_PATTERNS(i)(3 downto 0) & C_PATTERNS(i)(7 downto 4), "Read back period");
        check_reg(PWM_DUTY     , not C_PATTERNS(i), "Read back duty");
      end loop;
      write_reg(PWM_CFG, x"FF", "Write cfg 0xFF");
      check_reg(PWM_CFG, x"01", "Read back cfg : only the enable bit is implemented");
      write_reg(PWM_CFG, x"00", "Write cfg 0x00");
      check_reg(PWM_CFG, x"00", "Read back cfg");
    end procedure;

    procedure test_disabled is
      constant T : natural := tick(0);
    begin
      configure(0, 9, 3, "Disabled");
      check_constant(pwm_o, '0', 5*10*T, "Disabled : output low");
    end procedure;

    procedure test_no_prescaler is
      constant T : natural := tick(0);
    begin
      configure(0, 9, 3, "No prescaler");
      enable_pwm("No prescaler");
      check_periods(pwm_o, 3*T, 10*T, 4, "No prescaler : period 10 ticks, duty 3 ticks");
    end procedure;

    procedure test_prescaler is
      constant T : natural := tick(4);
    begin
      configure(4, 7, 5, "Prescaler 4");
      enable_pwm("Prescaler 4");
      check_periods(pwm_o, 5*T, 8*T, 3, "Prescaler 4 : tick of " & to_string(T) & " cycles, period 8 ticks, duty 5 ticks");
    end procedure;

    procedure test_duty is
      constant T : natural := tick(1);
    begin
      configure(1, 9, 0, "Duty 0");
      write_reg(PWM_CFG, x"01", "Duty 0 : enable PWM");
      check_constant(pwm_o, '0', 3*10*T, "Duty 0 : always low");

      configure(1, 9, 1, "Duty 1");
      enable_pwm("Duty 1");
      check_periods(pwm_o, T, 10*T, 2, "Duty 1");

      configure(1, 9, 9, "Duty = period");
      enable_pwm("Duty = period");
      check_periods(pwm_o, 9*T, 10*T, 2, "Duty = period : low during one tick");

      configure(1, 9, 10, "Duty = period+1");
      enable_pwm("Duty = period+1");
      check_constant(pwm_o, '1', 3*10*T-1, "Duty = period+1 : always high");

      configure(1, 9, 255, "Duty 255");
      enable_pwm("Duty 255");
      check_constant(pwm_o, '1', 3*10*T-1, "Duty 255 : always high");
    end procedure;

    procedure test_period_0 is
      constant T : natural := tick(2);
    begin
      configure(2, 0, 0, "Period 0, duty 0");
      write_reg(PWM_CFG, x"01", "Period 0, duty 0 : enable PWM");
      check_constant(pwm_o, '0', 10*T, "Period 0, duty 0 : always low");

      configure(2, 0, 1, "Period 0, duty 1");
      enable_pwm("Period 0, duty 1");
      check_constant(pwm_o, '1', 10*T, "Period 0, duty 1 : always high");
    end procedure;

    procedure test_update_duty is
      constant T : natural := tick(3);
    begin
      -- Period 16 ticks, duty 8 ticks
      configure(3, 15, 8, "Update duty");
      enable_pwm("Update duty");
      check_periods(pwm_o, 8*T, 16*T, 1, "Update duty : initial configuration");

      -- Duty decreased during the high phase : the current high phase is not cut
      v_t0 := now;
      wait for T*C_CLK_PERIOD;
      write_reg(PWM_DUTY, x"04", "Update : duty 4 during the high phase");
      wait_edge(pwm_o, '0', 16*T*C_CLK_PERIOD, "Update duty 4 : falling edge");
      check_value((now - v_t0) / C_CLK_PERIOD, 8*T, ERROR, "Update duty 4 : current high phase unchanged", C_SCOPE);
      wait_edge(pwm_o, '1', 16*T*C_CLK_PERIOD, "Update duty 4 : rising edge");
      check_value((now - v_t0) / C_CLK_PERIOD, 16*T, ERROR, "Update duty 4 : current period unchanged", C_SCOPE);
      check_periods(pwm_o, 4*T, 16*T, 1, "Update duty 4 : next period");

      -- Duty increased during the low phase : no second pulse in the current period
      v_t0 := now;
      wait_edge(pwm_o, '0', 16*T*C_CLK_PERIOD, "Update duty 12 : falling edge");
      write_reg(PWM_DUTY, x"0C", "Update : duty 12 during the low phase");
      wait_edge(pwm_o, '1', 16*T*C_CLK_PERIOD, "Update duty 12 : rising edge");
      check_value((now - v_t0) / C_CLK_PERIOD, 16*T, ERROR, "Update duty 12 : low until the end of the current period", C_SCOPE);
      check_periods(pwm_o, 12*T, 16*T, 1, "Update duty 12 : next period");
    end procedure;

    procedure test_update_period is
      constant T : natural := tick(3);
    begin
      -- Period 16 ticks, duty 12 ticks
      configure(3, 15, 12, "Update period");
      enable_pwm("Update period");
      check_periods(pwm_o, 12*T, 16*T, 1, "Update period : initial configuration");

      -- Period increased during the low phase (counter 12) : the current period is not extended
      v_t0 := now;
      wait for (25*T/2)*C_CLK_PERIOD;
      write_reg(PWM_PERIOD, x"13", "Update : period 19 during the low phase");
      wait_edge(pwm_o, '1', 20*T*C_CLK_PERIOD, "Update period 19 : rising edge");
      check_value((now - v_t0) / C_CLK_PERIOD, 16*T, ERROR, "Update period 19 : current period unchanged", C_SCOPE);
      check_periods(pwm_o, 12*T, 20*T, 1, "Update period 19 : next period");

      -- Duty and period decreased below the counter (15) : the counter does not overflow
      v_t0 := now;
      wait for 15*T*C_CLK_PERIOD;
      write_reg(PWM_DUTY  , x"02", "Update : duty 2 when the counter is 15");
      write_reg(PWM_PERIOD, x"05", "Update : period 5 when the counter is 15");
      wait_edge(pwm_o, '1', 20*T*C_CLK_PERIOD, "Update period 5 : rising edge");
      check_value((now - v_t0) / C_CLK_PERIOD, 20*T, ERROR, "Update period 5 : current period unchanged", C_SCOPE);
      check_periods(pwm_o, 2*T, 6*T, 2, "Update period 5 : next periods");
    end procedure;

    procedure test_update_prescaler is
      constant T_OLD : natural := tick(3);
      constant T_NEW : natural := tick(1);
    begin
      if not USER_DEFINE_PRESCALER
      then
        alert(TB_ERROR, "update_prescaler needs USER_DEFINE_PRESCALER = true", C_SCOPE);
        return;
      end if;

      -- Period 6 ticks, duty 2 ticks
      configure(3, 5, 2, "Update prescaler");
      enable_pwm("Update prescaler");
      check_periods(pwm_o, 2*T_OLD, 6*T_OLD, 1, "Update prescaler : initial configuration");

      -- Prescaler decreased during a period : the current period keeps its ticks
      v_t0 := now;
      wait for (5*T_OLD/2)*C_CLK_PERIOD;
      write_reg(PWM_PRESCALER, x"01", "Update : prescaler 1 during a period");
      wait_edge(pwm_o, '1', 6*T_OLD*C_CLK_PERIOD, "Update prescaler 1 : rising edge");
      check_value((now - v_t0) / C_CLK_PERIOD, 6*T_OLD, ERROR, "Update prescaler 1 : current period unchanged", C_SCOPE);
      check_periods(pwm_o, 2*T_NEW, 6*T_NEW, 2, "Update prescaler 1 : next periods");
    end procedure;

    procedure test_disable_enable is
      constant T : natural := tick(1);
    begin
      -- Period 6 ticks, duty 2 ticks
      configure(1, 5, 2, "Disable / enable");
      enable_pwm("Disable / enable");
      check_periods(pwm_o, 2*T, 6*T, 1, "Disable / enable : initial configuration");

      -- check_periods ends on a rising edge : disable during the high phase,
      -- not delayed by the static prescaler
      write_reg(PWM_CFG, x"00", "Disable during the high phase");
      wait_edge(pwm_o, '0', C_CLK_PERIOD, "Disable : output low one clock cycle after the disable");
      check_constant(pwm_o, '0', 6*6*T, "Disable : output stays low");
      enable_pwm("Enable after disable");
      check_periods(pwm_o, 2*T, 6*T, 2, "Enable after disable : new period from the start");

      -- Disable during the low phase (counter not 0) : the counter is
      -- cleared, the next enable starts a complete period
      wait_edge(pwm_o, '0', 6*T*C_CLK_PERIOD, "Disable in the low phase : falling edge");
      wait for T*C_CLK_PERIOD;
      write_reg(PWM_CFG, x"00", "Disable during the low phase");
      check_constant(pwm_o, '0', 6*6*T, "Disable in the low phase : output stays low");
      enable_pwm("Enable after a disable in the low phase");
      check_periods(pwm_o, 2*T, 6*T, 2, "Enable after a disable in the low phase : new period from the start");
    end procedure;

    procedure test_frequency is
      constant T : natural := tick(to_integer(unsigned(PRESCALER_RATIO)));
    begin
      -- Reset values of prescaler (PRESCALER_RATIO) and period (0xFF)
      write_reg(PWM_DUTY, x"80", "Frequency : duty 128");
      enable_pwm("Frequency");
      check_periods(pwm_o, 128*T, 256*T, 2, "Frequency : reset values of prescaler and period, duty 50%");
      log(ID_SEQUENCER, "Frequency : PWM period " & to_string(256*T*C_CLK_PERIOD, us), C_SCOPE);
    end procedure;

    procedure test_servo is
      constant T : natural := tick(249);
    begin
      -- 50 Hz with a 50 MHz clock and STATIC_PRESCALER_RATIO = 20 :
      -- 20*(249+1)*(199+1) = 1000000 clock cycles, duty 15 ticks of 5000
      -- clock cycles (100 us) : 1.5 ms pulse (servo center)
      configure(249, 199, 15, "Servo");
      enable_pwm("Servo");
      check_periods(pwm_o, 15*T, 200*T, 2, "Servo : 15 ticks every 200 ticks");
      log(ID_SEQUENCER, "Servo : PWM period " & to_string(200*T*C_CLK_PERIOD, ms) & ", high phase " & to_string(15*T*C_CLK_PERIOD, us), C_SCOPE);
    end procedure;

    procedure test_reset is
    begin
      -- duty > period : the output is high before the reset
      configure(0, 9, 10, "Reset");
      enable_pwm("Reset");
      wait for 2*C_CLK_PERIOD + C_CLK_PERIOD/4;
      check_value(pwm_o, '1', ERROR, "Reset : output high before the reset", C_SCOPE);
      arst_b_i <= '0';
      wait for 1 ns;
      check_value(pwm_o, '0', ERROR, "Reset : output low", C_SCOPE);
      wait for 5*C_CLK_PERIOD;
      arst_b_i <= '1';
      wait until rising_edge(clk_i);
      check_reg(PWM_CFG      , x"00"                          , "Reset : cfg back to its reset value");
      check_reg(PWM_PRESCALER, prescaler_read(PRESCALER_RATIO), "Reset : prescaler back to its reset value");
      check_reg(PWM_PERIOD   , x"FF"                          , "Reset : period back to its reset value");
      check_reg(PWM_DUTY     , x"00"                          , "Reset : duty back to its reset value");
      wait for 50*C_CLK_PERIOD;
      check_stable(pwm_o, 50*C_CLK_PERIOD, ERROR, "Reset : output stays low", C_SCOPE);
    end procedure;

  begin
    sbi_if   <= init_sbi_if_signals(PWM_ADDR_WIDTH, PWM_DATA_WIDTH);
    arst_b_i <= '0';
    wait for 100 ns;
    arst_b_i <= '1';
    wait until rising_edge(clk_i);

    log(ID_LOG_HDR, "Test " & TEST & " (STATIC_PRESCALER_RATIO = " & to_string(STATIC_PRESCALER_RATIO) &
                    ", USER_DEFINE_PRESCALER = " & to_string(USER_DEFINE_PRESCALER) &
                    ", PRESCALER_RATIO = 0x" & to_hstring(PRESCALER_RATIO) & ")", C_SCOPE);

    if    TEST = "reset_values"     then test_reset_values;
    elsif TEST = "registers"        then test_registers;
    elsif TEST = "disabled"         then test_disabled;
    elsif TEST = "no_prescaler"     then test_no_prescaler;
    elsif TEST = "prescaler"        then test_prescaler;
    elsif TEST = "duty"             then test_duty;
    elsif TEST = "period_0"         then test_period_0;
    elsif TEST = "update_duty"      then test_update_duty;
    elsif TEST = "update_period"    then test_update_period;
    elsif TEST = "update_prescaler" then test_update_prescaler;
    elsif TEST = "disable_enable"   then test_disable_enable;
    elsif TEST = "frequency"        then test_frequency;
    elsif TEST = "servo"            then test_servo;
    elsif TEST = "reset"            then test_reset;
    else
      alert(TB_FAILURE, "Unknown TEST """ & TEST & """", C_SCOPE);
    end if;

    log(ID_LOG_HDR, "Simulation Finished", C_SCOPE);
    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_main;

end sim;
