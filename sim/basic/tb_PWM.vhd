-------------------------------------------------------------------------------
-- Title      : tb_PWM
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: UVVM self-checking testbench of the PWM. The CSR are accessed
--              with the SBI BFM, the high phase and the period of the PWM
--              outputs are measured in clock cycles and checked exactly.
--              * dut       : sbi_PWM, default generics (prescaler register)
--                reset values, register access, disabled PWM, start latency,
--                prescaler, duty 0 / period / greater than period, period 0,
--                configuration taken into account at the next PWM period
--                (duty, period, prescaler), disable / enable while running,
--                1 kHz with the reset values of the prescaler and period
--              * dut_fixed : sbi_PWM, USER_DEFINE_PRESCALER = false
--                prescaler register not implemented, fixed ratio
--              * dut_static : sbi_PWM, STATIC_PRESCALER_RATIO = 20
--                tick of 20*(prescaler+1) cycles, start on a pulse of the
--                static prescaler, update at the next period, immediate
--                disable, 50 Hz (servo : 20 ms period, 1.5 ms pulse)
--              * dut_core  : pwm_core alone (no CSR, no SBI), 4-bit
--                prescaler and 12-bit counter
--              Plus : asynchronous reset while running.
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

entity tb_PWM is
end tb_PWM;

architecture sim of tb_PWM is

  constant C_SCOPE            : string  := "TB_PWM";
  constant C_CLK_PERIOD       : time    := 20 ns;    -- 50 MHz
  constant C_PRESCALER_RST    : std_logic_vector(7 downto 0) := x"C2";
  constant C_PRESCALER_FIXED  : std_logic_vector(7 downto 0) := x"02";
  constant C_STATIC_RATIO     : positive := 20;      -- STATIC_PRESCALER_RATIO of dut_static

  -- Register access patterns
  type     pattern_array_t is array (natural range <>) of std_logic_vector(7 downto 0);
  constant C_PATTERNS         : pattern_array_t := (x"5A", x"A5", x"0F", x"F0");

  -- pwm_core alone
  constant C_CORE_PRESCALER_WIDTH : natural := 4;
  constant C_CORE_COUNTER_WIDTH   : natural := 12;

  -- Clock & Reset
  signal   clk_i              : std_logic := '0';
  signal   clk_ena            : boolean   := true;
  signal   arst_b_i           : std_logic := '0';

  -- dut
  signal   sbi_ini            : sbi_ini_t(addr (PWM_ADDR_WIDTH-1 downto 0),
                                          wdata(PWM_DATA_WIDTH-1 downto 0));
  signal   sbi_tgt            : sbi_tgt_t(rdata(PWM_DATA_WIDTH-1 downto 0));
  signal   sbi_if             : t_sbi_if(addr (PWM_ADDR_WIDTH-1 downto 0),
                                         wdata(PWM_DATA_WIDTH-1 downto 0),
                                         rdata(PWM_DATA_WIDTH-1 downto 0));
  signal   pwm_o              : std_logic;

  -- dut_fixed
  signal   sbi_fixed_ini      : sbi_ini_t(addr (PWM_ADDR_WIDTH-1 downto 0),
                                          wdata(PWM_DATA_WIDTH-1 downto 0));
  signal   sbi_fixed_tgt      : sbi_tgt_t(rdata(PWM_DATA_WIDTH-1 downto 0));
  signal   sbi_fixed_if       : t_sbi_if(addr (PWM_ADDR_WIDTH-1 downto 0),
                                         wdata(PWM_DATA_WIDTH-1 downto 0),
                                         rdata(PWM_DATA_WIDTH-1 downto 0));
  signal   pwm_fixed_o        : std_logic;

  -- dut_static
  signal   sbi_static_ini     : sbi_ini_t(addr (PWM_ADDR_WIDTH-1 downto 0),
                                          wdata(PWM_DATA_WIDTH-1 downto 0));
  signal   sbi_static_tgt     : sbi_tgt_t(rdata(PWM_DATA_WIDTH-1 downto 0));
  signal   sbi_static_if      : t_sbi_if(addr (PWM_ADDR_WIDTH-1 downto 0),
                                         wdata(PWM_DATA_WIDTH-1 downto 0),
                                         rdata(PWM_DATA_WIDTH-1 downto 0));
  signal   pwm_static_o       : std_logic;

  -- dut_core
  signal   core_enable        : std_logic := '0';
  signal   core_ratio         : std_logic_vector(C_CORE_PRESCALER_WIDTH-1 downto 0) := (others => '0');
  signal   core_period        : std_logic_vector(C_CORE_COUNTER_WIDTH-1   downto 0) := (others => '0');
  signal   core_duty          : std_logic_vector(C_CORE_COUNTER_WIDTH-1   downto 0) := (others => '0');
  signal   pwm_core_o         : std_logic;

begin

  clock_generator(clk_i, clk_ena, C_CLK_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- dut : sbi_PWM, default generics
  -----------------------------------------------------------------------------
  dut : sbi_PWM
    generic map (
      NAME                  => "PWM"
     ,USER_DEFINE_PRESCALER => true
     ,PRESCALER_RATIO       => C_PRESCALER_RST
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
  -- dut_fixed : sbi_PWM, prescaler fixed to C_PRESCALER_FIXED
  -----------------------------------------------------------------------------
  dut_fixed : sbi_PWM
    generic map (
      NAME                  => "PWM_FIXED"
     ,USER_DEFINE_PRESCALER => false
     ,PRESCALER_RATIO       => C_PRESCALER_FIXED
    )
    port map (
      clk_i      => clk_i
     ,arst_b_i   => arst_b_i
     ,sbi_ini_i  => sbi_fixed_ini
     ,sbi_tgt_o  => sbi_fixed_tgt
     ,pwm_o      => pwm_fixed_o
    );

  sbi_fixed_ini.cs                              <= sbi_fixed_if.cs;
  sbi_fixed_ini.addr                            <= std_logic_vector(sbi_fixed_if.addr(PWM_ADDR_WIDTH-1 downto 0));
  sbi_fixed_ini.re                              <= sbi_fixed_if.rena;
  sbi_fixed_ini.we                              <= sbi_fixed_if.wena;
  sbi_fixed_ini.wdata                           <= sbi_fixed_if.wdata(PWM_DATA_WIDTH-1 downto 0);
  sbi_fixed_if.ready                            <= sbi_fixed_tgt.ready;
  sbi_fixed_if.rdata(PWM_DATA_WIDTH-1 downto 0) <= sbi_fixed_tgt.rdata;

  -----------------------------------------------------------------------------
  -- dut_static : sbi_PWM, static prescaler of C_STATIC_RATIO clock cycles
  -----------------------------------------------------------------------------
  dut_static : sbi_PWM
    generic map (
      NAME                   => "PWM_STATIC"
     ,STATIC_PRESCALER_RATIO => C_STATIC_RATIO
     ,USER_DEFINE_PRESCALER  => true
     ,PRESCALER_RATIO        => C_PRESCALER_RST
    )
    port map (
      clk_i      => clk_i
     ,arst_b_i   => arst_b_i
     ,sbi_ini_i  => sbi_static_ini
     ,sbi_tgt_o  => sbi_static_tgt
     ,pwm_o      => pwm_static_o
    );

  sbi_static_ini.cs                              <= sbi_static_if.cs;
  sbi_static_ini.addr                            <= std_logic_vector(sbi_static_if.addr(PWM_ADDR_WIDTH-1 downto 0));
  sbi_static_ini.re                              <= sbi_static_if.rena;
  sbi_static_ini.we                              <= sbi_static_if.wena;
  sbi_static_ini.wdata                           <= sbi_static_if.wdata(PWM_DATA_WIDTH-1 downto 0);
  sbi_static_if.ready                            <= sbi_static_tgt.ready;
  sbi_static_if.rdata(PWM_DATA_WIDTH-1 downto 0) <= sbi_static_tgt.rdata;

  -----------------------------------------------------------------------------
  -- dut_core : pwm_core alone, configuration driven by the sequencer
  -----------------------------------------------------------------------------
  dut_core : pwm_core
    generic map (
      PRESCALER_WIDTH       => C_CORE_PRESCALER_WIDTH
     ,COUNTER_WIDTH         => C_CORE_COUNTER_WIDTH
    )
    port map (
      clk_i                 => clk_i
     ,arst_b_i              => arst_b_i
     ,cfg_enable_i          => core_enable
     ,cfg_prescaler_ratio_i => core_ratio
     ,cfg_period_i          => core_period
     ,cfg_duty_i            => core_duty
     ,pwm_o                 => pwm_core_o
    );

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_main : process
    variable v_sbi_config : t_sbi_bfm_config := C_SBI_BFM_CONFIG_DEFAULT;
    variable v_t0         : time;

    -- Register access of dut
    procedure write_reg(addr : unsigned; data : std_logic_vector; msg : string) is
    begin
      sbi_write(addr, data, msg, clk_i, sbi_if, C_SCOPE, shared_msg_id_panel, v_sbi_config);
    end procedure;

    procedure check_reg(addr : unsigned; data : std_logic_vector; msg : string) is
    begin
      sbi_check(addr, data, msg, clk_i, sbi_if, ERROR, C_SCOPE, shared_msg_id_panel, v_sbi_config);
    end procedure;

    -- Register access of dut_fixed
    procedure write_fixed(addr : unsigned; data : std_logic_vector; msg : string) is
    begin
      sbi_write(addr, data, msg, clk_i, sbi_fixed_if, C_SCOPE, shared_msg_id_panel, v_sbi_config);
    end procedure;

    procedure check_fixed(addr : unsigned; data : std_logic_vector; msg : string) is
    begin
      sbi_check(addr, data, msg, clk_i, sbi_fixed_if, ERROR, C_SCOPE, shared_msg_id_panel, v_sbi_config);
    end procedure;

    -- Configuration of dut, PWM disabled : prescaler ratio, period and duty
    procedure configure(ratio : natural; period : natural; duty : natural; msg : string) is
    begin
      write_reg(PWM_CFG      , x"00", msg & " : disable PWM");
      write_reg(PWM_PRESCALER, std_logic_vector(to_unsigned(ratio , 8)), msg & " : prescaler " & to_string(ratio));
      write_reg(PWM_PERIOD   , std_logic_vector(to_unsigned(period, 8)), msg & " : period "    & to_string(period));
      write_reg(PWM_DUTY     , std_logic_vector(to_unsigned(duty  , 8)), msg & " : duty "      & to_string(duty));
    end procedure;

    -- Wait the next change of pwm to value, error after timeout
    procedure wait_edge(signal pwm : in std_logic; value : std_logic; timeout : time; msg : string) is
    begin
      wait until pwm = value for timeout;
      check_value(pwm, value, ERROR, msg, C_SCOPE);
    end procedure;

    -- Check nb PWM periods of pwm, now is the rising edge of the first one :
    -- high phase and period in clock cycles. Ends on a rising edge of pwm.
    procedure check_periods(signal pwm : in std_logic; high : natural; period : natural; nb : positive; msg : string) is
    begin
      for i in 1 to nb loop
        v_t0 := now;
        wait_edge(pwm, '0', (high  +1)*C_CLK_PERIOD, msg & " : falling edge, period " & to_string(i));
        check_value((now - v_t0) / C_CLK_PERIOD, high  , ERROR, msg & " : high phase (clock cycles), period " & to_string(i), C_SCOPE);
        wait_edge(pwm, '1', (period+1)*C_CLK_PERIOD, msg & " : rising edge, period " & to_string(i));
        check_value((now - v_t0) / C_CLK_PERIOD, period, ERROR, msg & " : PWM period (clock cycles), period " & to_string(i), C_SCOPE);
      end loop;
    end procedure;

    -- Check that pwm stays at level during cycles clock cycles
    procedure check_constant(signal pwm : in std_logic; level : std_logic; cycles : natural; msg : string) is
    begin
      wait for cycles*C_CLK_PERIOD;
      check_value (pwm, level, ERROR, msg & " : level", C_SCOPE);
      check_stable(pwm, cycles*C_CLK_PERIOD, ERROR, msg & " : stable during " & to_string(cycles) & " clock cycles", C_SCOPE);
    end procedure;

    -- Enable dut : the first period starts (rising edge) less than one clock
    -- cycle after the end of the write (the write is sampled on the rising
    -- edge of clk_i before the end of sbi_write, pwm_o is registered in
    -- pwm_core after the CSR register)
    procedure enable_pwm(msg : string) is
    begin
      write_reg(PWM_CFG, x"01", msg & " : enable PWM");
      wait_edge(pwm_o, '1', C_CLK_PERIOD, msg & " : first period starts one clock cycle after the enable");
    end procedure;

    -- Register access of dut_static
    procedure write_static(addr : unsigned; data : std_logic_vector; msg : string) is
    begin
      sbi_write(addr, data, msg, clk_i, sbi_static_if, C_SCOPE, shared_msg_id_panel, v_sbi_config);
    end procedure;

    procedure check_static(addr : unsigned; data : std_logic_vector; msg : string) is
    begin
      sbi_check(addr, data, msg, clk_i, sbi_static_if, ERROR, C_SCOPE, shared_msg_id_panel, v_sbi_config);
    end procedure;

    -- Configuration of dut_static, PWM disabled : prescaler ratio, period and duty
    procedure configure_static(ratio : natural; period : natural; duty : natural; msg : string) is
    begin
      write_static(PWM_CFG      , x"00", msg & " : disable PWM");
      write_static(PWM_PRESCALER, std_logic_vector(to_unsigned(ratio , 8)), msg & " : prescaler " & to_string(ratio));
      write_static(PWM_PERIOD   , std_logic_vector(to_unsigned(period, 8)), msg & " : period "    & to_string(period));
      write_static(PWM_DUTY     , std_logic_vector(to_unsigned(duty  , 8)), msg & " : duty "      & to_string(duty));
    end procedure;

    -- Enable dut_static : the first period starts on the first pulse of the
    -- static prescaler after the enable, less than C_STATIC_RATIO clock
    -- cycles after the end of the write
    procedure enable_static(msg : string) is
    begin
      write_static(PWM_CFG, x"01", msg & " : enable PWM");
      wait_edge(pwm_static_o, '1', C_STATIC_RATIO*C_CLK_PERIOD, msg & " : first period starts on the next pulse of the static prescaler");
    end procedure;

    -- Drive the configuration of dut_core after a rising edge of clk_i
    procedure core_configure(enable : std_logic; ratio : natural; period : natural; duty : natural) is
    begin
      wait until rising_edge(clk_i);
      core_enable <= enable;
      core_ratio  <= std_logic_vector(to_unsigned(ratio , C_CORE_PRESCALER_WIDTH));
      core_period <= std_logic_vector(to_unsigned(period, C_CORE_COUNTER_WIDTH));
      core_duty   <= std_logic_vector(to_unsigned(duty  , C_CORE_COUNTER_WIDTH));
    end procedure;

  begin
    sbi_if       <= init_sbi_if_signals(PWM_ADDR_WIDTH, PWM_DATA_WIDTH);
    sbi_fixed_if <= init_sbi_if_signals(PWM_ADDR_WIDTH, PWM_DATA_WIDTH);
    sbi_static_if<= init_sbi_if_signals(PWM_ADDR_WIDTH, PWM_DATA_WIDTH);
    arst_b_i     <= '0';
    wait for 100 ns;
    arst_b_i     <= '1';
    wait until rising_edge(clk_i);

    log(ID_SEQUENCER, "Reset released, starting PWM basic test", C_SCOPE);

    ------------------------------------------------
    log(ID_LOG_HDR, "1. Reset values", C_SCOPE);
    ------------------------------------------------
    check_reg  (PWM_CFG      , x"00"          , "dut : reset value cfg");
    check_reg  (PWM_PRESCALER, C_PRESCALER_RST, "dut : reset value prescaler (PRESCALER_RATIO)");
    check_reg  (PWM_PERIOD   , x"FF"          , "dut : reset value period");
    check_reg  (PWM_DUTY     , x"00"          , "dut : reset value duty");
    check_fixed(PWM_CFG      , x"00"          , "dut_fixed : reset value cfg");
    check_fixed(PWM_PRESCALER, x"00"          , "dut_fixed : prescaler not implemented, read 0");
    check_fixed(PWM_PERIOD   , x"FF"          , "dut_fixed : reset value period");
    check_fixed(PWM_DUTY     , x"00"          , "dut_fixed : reset value duty");
    check_value(pwm_o      , '0', ERROR, "dut : PWM disabled, output low"      , C_SCOPE);
    check_value(pwm_fixed_o, '0', ERROR, "dut_fixed : PWM disabled, output low", C_SCOPE);
    check_value(pwm_core_o , '0', ERROR, "dut_core : PWM disabled, output low" , C_SCOPE);
    check_static(PWM_CFG      , x"00"          , "dut_static : reset value cfg");
    check_static(PWM_PRESCALER, C_PRESCALER_RST, "dut_static : reset value prescaler (PRESCALER_RATIO)");
    check_value(pwm_static_o, '0', ERROR, "dut_static : PWM disabled, output low", C_SCOPE);

    ------------------------------------------------
    log(ID_LOG_HDR, "2. Register access", C_SCOPE);
    ------------------------------------------------
    -- Each register gets a different pattern, then the inverted pattern
    for i in C_PATTERNS'range loop
      write_reg(PWM_PRESCALER, C_PATTERNS(i)    , "Write prescaler 0x" & to_hstring(C_PATTERNS(i)));
      write_reg(PWM_PERIOD   , C_PATTERNS(i)(3 downto 0) & C_PATTERNS(i)(7 downto 4), "Write period");
      write_reg(PWM_DUTY     , not C_PATTERNS(i), "Write duty");
      check_reg(PWM_PRESCALER, C_PATTERNS(i)    , "Read back prescaler");
      check_reg(PWM_PERIOD   , C_PATTERNS(i)(3 downto 0) & C_PATTERNS(i)(7 downto 4), "Read back period");
      check_reg(PWM_DUTY     , not C_PATTERNS(i), "Read back duty");
    end loop;
    write_reg(PWM_CFG, x"FF", "Write cfg 0xFF");
    check_reg(PWM_CFG, x"01", "Read back cfg : only the enable bit is implemented");
    write_reg(PWM_CFG, x"00", "Write cfg 0x00");
    check_reg(PWM_CFG, x"00", "Read back cfg");

    ------------------------------------------------
    log(ID_LOG_HDR, "3. PWM disabled : output low", C_SCOPE);
    ------------------------------------------------
    configure(0, 9, 3, "Disabled");
    check_constant(pwm_o, '0', 50, "Disabled");

    ------------------------------------------------
    log(ID_LOG_HDR, "4. PWM enabled, no prescaler : high 3 cycles, period 10 cycles", C_SCOPE);
    ------------------------------------------------
    enable_pwm("No prescaler");
    check_periods(pwm_o, 3, 10, 4, "No prescaler");

    ------------------------------------------------
    log(ID_LOG_HDR, "5. Prescaler : tick of 5 cycles, period 8 ticks, duty 5 ticks", C_SCOPE);
    ------------------------------------------------
    configure(4, 7, 5, "Prescaler 4");
    enable_pwm("Prescaler 4");
    check_periods(pwm_o, 25, 40, 3, "Prescaler 4");

    ------------------------------------------------
    log(ID_LOG_HDR, "6. Duty 0, 1, period, greater than period", C_SCOPE);
    ------------------------------------------------
    configure(1, 9, 0, "Duty 0");
    write_reg(PWM_CFG, x"01", "Duty 0 : enable PWM");
    check_constant(pwm_o, '0', 3*20, "Duty 0 : always low");

    configure(1, 9, 1, "Duty 1");
    enable_pwm("Duty 1");
    check_periods(pwm_o, 2, 20, 2, "Duty 1");

    configure(1, 9, 9, "Duty = period");
    enable_pwm("Duty = period");
    check_periods(pwm_o, 18, 20, 2, "Duty = period : low during one tick");

    configure(1, 9, 10, "Duty = period+1");
    enable_pwm("Duty = period+1");
    check_constant(pwm_o, '1', 3*20-1, "Duty = period+1 : always high");

    configure(1, 9, 255, "Duty 255");
    enable_pwm("Duty 255");
    check_constant(pwm_o, '1', 3*20-1, "Duty 255 : always high");

    ------------------------------------------------
    log(ID_LOG_HDR, "7. Period 0 : PWM period of one tick", C_SCOPE);
    ------------------------------------------------
    configure(2, 0, 0, "Period 0, duty 0");
    write_reg(PWM_CFG, x"01", "Period 0, duty 0 : enable PWM");
    check_constant(pwm_o, '0', 30, "Period 0, duty 0 : always low");

    configure(2, 0, 1, "Period 0, duty 1");
    enable_pwm("Period 0, duty 1");
    check_constant(pwm_o, '1', 30, "Period 0, duty 1 : always high");

    ------------------------------------------------
    log(ID_LOG_HDR, "8. Configuration taken into account at the start of the next PWM period", C_SCOPE);
    ------------------------------------------------
    -- Tick of 4 cycles, period 16 ticks (64 cycles), duty 8 ticks (32 cycles)
    configure(3, 15, 8, "Update");
    enable_pwm("Update");
    check_periods(pwm_o, 32, 64, 1, "Update : initial configuration");

    -- Duty decreased during the high phase : the current high phase is not cut
    v_t0 := now;
    wait for 4*C_CLK_PERIOD;
    write_reg(PWM_DUTY, x"04", "Update : duty 4 during the high phase");
    wait_edge(pwm_o, '0', 64*C_CLK_PERIOD, "Update duty 4 : falling edge");
    check_value((now - v_t0) / C_CLK_PERIOD, 32, ERROR, "Update duty 4 : current high phase unchanged", C_SCOPE);
    wait_edge(pwm_o, '1', 64*C_CLK_PERIOD, "Update duty 4 : rising edge");
    check_value((now - v_t0) / C_CLK_PERIOD, 64, ERROR, "Update duty 4 : current period unchanged", C_SCOPE);
    check_periods(pwm_o, 16, 64, 1, "Update duty 4 : next period");

    -- Duty increased during the low phase : no second pulse in the current period
    v_t0 := now;
    wait_edge(pwm_o, '0', 64*C_CLK_PERIOD, "Update duty 12 : falling edge");
    write_reg(PWM_DUTY, x"0C", "Update : duty 12 during the low phase");
    wait_edge(pwm_o, '1', 64*C_CLK_PERIOD, "Update duty 12 : rising edge");
    check_value((now - v_t0) / C_CLK_PERIOD, 64, ERROR, "Update duty 12 : low until the end of the current period", C_SCOPE);
    check_periods(pwm_o, 48, 64, 1, "Update duty 12 : next period");

    -- Period increased during the low phase : the current period is not extended
    v_t0 := now;
    wait for 50*C_CLK_PERIOD;
    write_reg(PWM_PERIOD, x"13", "Update : period 19 during the low phase");
    wait_edge(pwm_o, '1', 80*C_CLK_PERIOD, "Update period 19 : rising edge");
    check_value((now - v_t0) / C_CLK_PERIOD, 64, ERROR, "Update period 19 : current period unchanged", C_SCOPE);
    check_periods(pwm_o, 48, 80, 1, "Update period 19 : next period");

    -- Duty and period decreased below the counter : the counter does not overflow
    v_t0 := now;
    wait for 60*C_CLK_PERIOD;
    write_reg(PWM_DUTY  , x"02", "Update : duty 2 when the counter is 15");
    write_reg(PWM_PERIOD, x"05", "Update : period 5 when the counter is 15");
    wait_edge(pwm_o, '1', 80*C_CLK_PERIOD, "Update period 5 : rising edge");
    check_value((now - v_t0) / C_CLK_PERIOD, 80, ERROR, "Update period 5 : current period unchanged", C_SCOPE);
    check_periods(pwm_o, 8, 24, 2, "Update period 5 : next periods");

    -- Prescaler decreased during a period : the current period keeps its ticks
    v_t0 := now;
    wait for 10*C_CLK_PERIOD;
    write_reg(PWM_PRESCALER, x"01", "Update : prescaler 1 during a period");
    wait_edge(pwm_o, '1', 24*C_CLK_PERIOD, "Update prescaler 1 : rising edge");
    check_value((now - v_t0) / C_CLK_PERIOD, 24, ERROR, "Update prescaler 1 : current period unchanged", C_SCOPE);
    check_periods(pwm_o, 4, 12, 2, "Update prescaler 1 : next periods");

    ------------------------------------------------
    log(ID_LOG_HDR, "9. Disable and enable while running", C_SCOPE);
    ------------------------------------------------
    -- check_periods ends on a rising edge : disable during the high phase
    write_reg(PWM_CFG, x"00", "Disable during the high phase");
    wait_edge(pwm_o, '0', C_CLK_PERIOD, "Disable : output low one clock cycle after the disable");
    check_constant(pwm_o, '0', 100, "Disable : output stays low");
    enable_pwm("Enable after disable");
    check_periods(pwm_o, 4, 12, 2, "Enable after disable : new period from the start");

    ------------------------------------------------
    log(ID_LOG_HDR, "10. Reset values of prescaler and period : 1 kHz with a 50 MHz clock", C_SCOPE);
    ------------------------------------------------
    configure(to_integer(unsigned(C_PRESCALER_RST)), 255, 128, "1 kHz");
    enable_pwm("1 kHz");
    check_periods(pwm_o, 195*128, 195*256, 2, "1 kHz : duty 50%");
    log(ID_SEQUENCER, "1 kHz : PWM period " & to_string(195*256*C_CLK_PERIOD, us), C_SCOPE);
    write_reg(PWM_CFG, x"00", "1 kHz : disable PWM");

    ------------------------------------------------
    log(ID_LOG_HDR, "11. dut_fixed : prescaler fixed to PRESCALER_RATIO", C_SCOPE);
    ------------------------------------------------
    write_fixed(PWM_PRESCALER, x"55", "dut_fixed : write prescaler (ignored)");
    check_fixed(PWM_PRESCALER, x"00", "dut_fixed : prescaler still read 0");
    write_fixed(PWM_PERIOD   , x"04", "dut_fixed : period 4");
    write_fixed(PWM_DUTY     , x"02", "dut_fixed : duty 2");
    check_fixed(PWM_PERIOD   , x"04", "dut_fixed : read back period");
    check_fixed(PWM_DUTY     , x"02", "dut_fixed : read back duty");
    write_fixed(PWM_CFG      , x"01", "dut_fixed : enable PWM");
    wait_edge(pwm_fixed_o, '1', C_CLK_PERIOD, "dut_fixed : first period starts one clock cycle after the enable");
    check_periods(pwm_fixed_o, 2*3, 5*3, 3, "dut_fixed : tick of 3 cycles (ratio 2), period 5 ticks, duty 2 ticks");
    check_value(pwm_o, '0', ERROR, "dut_fixed : dut not disturbed", C_SCOPE);
    write_fixed(PWM_CFG      , x"00", "dut_fixed : disable PWM");

    ------------------------------------------------
    log(ID_LOG_HDR, "12. dut_core : pwm_core alone, 4-bit prescaler, 12-bit counter", C_SCOPE);
    ------------------------------------------------
    -- Maximum prescaler ratio, period 1000 ticks
    core_configure('0', 15, 999, 250);
    check_constant(pwm_core_o, '0', 10, "dut_core : disabled");
    core_configure('1', 15, 999, 250);
    wait_edge(pwm_core_o, '1', 2*C_CLK_PERIOD, "dut_core : first period starts one clock cycle after the enable");
    check_periods(pwm_core_o, 250*16, 1000*16, 2, "dut_core : tick of 16 cycles, period 1000 ticks, duty 250 ticks");

    -- Full 12-bit period
    core_configure('0', 0, 4095, 2048);
    core_configure('1', 0, 4095, 2048);
    wait_edge(pwm_core_o, '1', 2*C_CLK_PERIOD, "dut_core 12-bit : first period");
    check_periods(pwm_core_o, 2048, 4096, 1, "dut_core 12-bit : period 4096 ticks, duty 2048 ticks");

    -- Maximum duty, changed while running (taken into account at the next period)
    -- check_periods ends on a rising edge of pwm_core_o : duty changed at the
    -- start of a period
    core_duty   <= std_logic_vector(to_unsigned(4095, C_CORE_COUNTER_WIDTH));
    check_periods(pwm_core_o, 2048, 4096, 1, "dut_core 12-bit : duty 4095 written, current period unchanged");
    check_periods(pwm_core_o, 4095, 4096, 1, "dut_core 12-bit : duty 4095, low during one tick");

    -- Duty greater than period : always high
    core_configure('0', 0, 4094, 4095);
    core_configure('1', 0, 4094, 4095);
    wait_edge(pwm_core_o, '1', 2*C_CLK_PERIOD, "dut_core duty > period : first period");
    check_constant(pwm_core_o, '1', 3*4095-1, "dut_core : duty > period, always high");
    core_configure('0', 0, 4094, 4095);

    ------------------------------------------------
    log(ID_LOG_HDR, "13. dut_static : static prescaler of 20 clock cycles", C_SCOPE);
    ------------------------------------------------
    -- Tick of 20*2 = 40 cycles, period 4 ticks, duty 2 ticks
    configure_static(1, 3, 2, "Static");
    check_constant(pwm_static_o, '0', 2*C_STATIC_RATIO, "Static : disabled");
    enable_static("Static");
    check_periods(pwm_static_o, 2*40, 4*40, 3, "Static : tick of 20*(prescaler+1) cycles");

    -- Duty decreased during the high phase : taken into account at the next period
    v_t0 := now;
    write_static(PWM_DUTY, x"01", "Static : duty 1 during the high phase");
    wait_edge(pwm_static_o, '0', 4*40*C_CLK_PERIOD, "Static duty 1 : falling edge");
    check_value((now - v_t0) / C_CLK_PERIOD, 2*40, ERROR, "Static duty 1 : current high phase unchanged", C_SCOPE);
    wait_edge(pwm_static_o, '1', 4*40*C_CLK_PERIOD, "Static duty 1 : rising edge");
    check_value((now - v_t0) / C_CLK_PERIOD, 4*40, ERROR, "Static duty 1 : current period unchanged", C_SCOPE);
    check_periods(pwm_static_o, 1*40, 4*40, 1, "Static duty 1 : next period");

    -- Disable : immediate, not delayed by the static prescaler
    write_static(PWM_CFG, x"00", "Static : disable during the high phase");
    wait_edge(pwm_static_o, '0', C_CLK_PERIOD, "Static : output low one clock cycle after the disable");
    check_constant(pwm_static_o, '0', 4*40, "Static : output stays low");

    -- 50 Hz with a 50 MHz clock : 20*(249+1)*(199+1) = 1000000 clock cycles,
    -- duty 15 ticks of 5000 clock cycles (100 us) : 1.5 ms pulse (servo center)
    configure_static(249, 199, 15, "50 Hz");
    enable_static("50 Hz");
    check_periods(pwm_static_o, 15*5000, 200*5000, 2, "50 Hz : servo, 1.5 ms pulse every 20 ms");
    log(ID_SEQUENCER, "50 Hz : PWM period " & to_string(200*5000*C_CLK_PERIOD, ms) & ", high phase " & to_string(15*5000*C_CLK_PERIOD, us), C_SCOPE);
    write_static(PWM_CFG, x"00", "50 Hz : disable PWM");

    ------------------------------------------------
    log(ID_LOG_HDR, "14. Asynchronous reset while running", C_SCOPE);
    ------------------------------------------------
    -- duty > period : the 4 outputs are high before the reset
    configure_static(0, 9, 10, "Reset");
    enable_static("Reset");
    configure(0, 9, 10, "Reset");
    enable_pwm("Reset");
    core_configure('1', 0, 9, 10);
    write_fixed(PWM_DUTY, x"05", "Reset : dut_fixed duty 5 (period 4)");
    write_fixed(PWM_CFG , x"01", "Reset : enable dut_fixed");
    wait for 2*C_CLK_PERIOD + C_CLK_PERIOD/4;
    check_value(pwm_o      , '1', ERROR, "Reset : dut output high before the reset"      , C_SCOPE);
    check_value(pwm_fixed_o, '1', ERROR, "Reset : dut_fixed output high before the reset", C_SCOPE);
    check_value(pwm_core_o , '1', ERROR, "Reset : dut_core output high before the reset" , C_SCOPE);
    check_value(pwm_static_o,'1', ERROR, "Reset : dut_static output high before the reset", C_SCOPE);
    arst_b_i     <= '0';
    wait for 1 ns;
    check_value(pwm_o      , '0', ERROR, "Reset : dut output low"      , C_SCOPE);
    check_value(pwm_fixed_o, '0', ERROR, "Reset : dut_fixed output low", C_SCOPE);
    check_value(pwm_core_o , '0', ERROR, "Reset : dut_core output low" , C_SCOPE);
    check_value(pwm_static_o,'0', ERROR, "Reset : dut_static output low", C_SCOPE);
    wait for 5*C_CLK_PERIOD;
    core_enable  <= '0';
    arst_b_i     <= '1';
    wait until rising_edge(clk_i);
    check_reg  (PWM_CFG      , x"00"          , "Reset : cfg back to its reset value");
    check_reg  (PWM_PRESCALER, C_PRESCALER_RST, "Reset : prescaler back to its reset value");
    check_reg  (PWM_PERIOD   , x"FF"          , "Reset : period back to its reset value");
    check_reg  (PWM_DUTY     , x"00"          , "Reset : duty back to its reset value");
    check_fixed(PWM_CFG      , x"00"          , "Reset : dut_fixed cfg back to its reset value");
    check_static(PWM_CFG     , x"00"          , "Reset : dut_static cfg back to its reset value");
    wait for 50*C_CLK_PERIOD;
    check_stable(pwm_o      , 50*C_CLK_PERIOD, ERROR, "Reset : dut output stays low"      , C_SCOPE);
    check_stable(pwm_fixed_o, 50*C_CLK_PERIOD, ERROR, "Reset : dut_fixed output stays low", C_SCOPE);
    check_stable(pwm_core_o , 50*C_CLK_PERIOD, ERROR, "Reset : dut_core output stays low" , C_SCOPE);
    check_stable(pwm_static_o,50*C_CLK_PERIOD, ERROR, "Reset : dut_static output stays low", C_SCOPE);

    log(ID_LOG_HDR, "Simulation Finished", C_SCOPE);
    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_main;

end sim;
