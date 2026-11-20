-------------------------------------------------------------------------------
-- Title      : tb_PWM
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: UVVM self-checking testbench of sbi_PWM.
--              TESTS_LIST : scenarios run in sequence, separated by ','
--                           (tb_PWM_tests_pkg), each one after a reset
--                           pulse ; "" : build and elaboration only
--              The DUT generics are generics of the testbench : the
--              expected durations are computed from them (a tick lasts
--              STATIC_PRESCALER_RATIO*(ratio+1) clock cycles, ratio fixed
--              to PRESCALER_RATIO when USER_DEFINE_PRESCALER = false).
--              The CSR are accessed with the SBI BFM, the high phase and
--              the period of pwm_o are measured in clock cycles and checked
--              exactly.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-22  1.0      mrosiere Created
-- 2026-11-20  2.0      mrosiere TESTS_LIST, one package per scenario
--                               (tb_PWM_<name>_pkg), helpers in
--                               tb_PWM_bfm_pkg, reset pulse before each
--                               scenario
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
use     asylum.string_pkg.all;
use     asylum.pwm_pkg.all;
use     asylum.PWM_csr_pkg.all;

library work;
use     work.tb_PWM_bfm_pkg.all;
use     work.tb_PWM_tests_pkg.all;

entity tb_PWM is
  generic (
    TESTS_LIST            : string   := ""                            -- Scenarios, e.g. "prescaler,duty"
   ;STATIC_PRESCALER_RATIO: positive := 1                             -- Generics of the DUT
   ;USER_DEFINE_PRESCALER : boolean  := true
   ;PRESCALER_RATIO       : std_logic_vector(8-1 downto 0) := x"C2"
  );
end entity tb_PWM;

architecture sim of tb_PWM is

  constant C_SCOPE            : string := "TB_PWM";
  constant C_CFG              : cfg_t  := (static_ratio   => STATIC_PRESCALER_RATIO
                                          ,user_prescaler => USER_DEFINE_PRESCALER
                                          ,ratio_init     => PRESCALER_RATIO
                                          );

  -- Clock & Reset
  signal   clk_i              : std_logic := '0';
  signal   clk_ena            : boolean   := true;
  signal   arst_b_i           : std_logic := '0';

  -- DUT
  signal   sbi_ini            : sbi_ini_t(addr (PWM_ADDR_WIDTH-1 downto 0),
                                          wdata(PWM_DATA_WIDTH-1 downto 0));
  signal   sbi_tgt            : sbi_tgt_t(rdata(PWM_DATA_WIDTH-1 downto 0));
  signal   sbi_if             : t_sbi_if (addr (PWM_ADDR_WIDTH-1 downto 0),
                                          wdata(PWM_DATA_WIDTH-1 downto 0),
                                          rdata(PWM_DATA_WIDTH-1 downto 0));
  signal   pwm_o              : std_logic;

begin

  clock_generator(clk_i, clk_ena, C_CLK_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUT
  -----------------------------------------------------------------------------
  dut : sbi_PWM
    generic map
    (NAME                   => "PWM"
    ,STATIC_PRESCALER_RATIO => STATIC_PRESCALER_RATIO
    ,USER_DEFINE_PRESCALER  => USER_DEFINE_PRESCALER
    ,PRESCALER_RATIO        => PRESCALER_RATIO
    )
    port map
    (clk_i                  => clk_i
    ,arst_b_i               => arst_b_i
    ,sbi_ini_i              => sbi_ini
    ,sbi_tgt_o              => sbi_tgt
    ,pwm_o                  => pwm_o
    );

  sbi_ini.cs    <= sbi_if.cs;
  sbi_ini.addr  <= std_logic_vector(sbi_if.addr);
  sbi_ini.re    <= sbi_if.rena;
  sbi_ini.we    <= sbi_if.wena;
  sbi_ini.wdata <= sbi_if.wdata;
  sbi_if.ready  <= sbi_tgt.ready;
  sbi_if.rdata  <= sbi_tgt.rdata;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_sequencer : process
  begin
    log(ID_LOG_HDR, "STATIC_PRESCALER_RATIO = " & to_string(STATIC_PRESCALER_RATIO) &
                    ", USER_DEFINE_PRESCALER = " & to_string(USER_DEFINE_PRESCALER) &
                    ", PRESCALER_RATIO = 0x" & to_hstring(PRESCALER_RATIO) &
                    ", TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST) loop
      if not list_contains(C_TESTS, list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST) loop
      -- Reset pulse, bus inactive : each scenario starts from reset
      sbi_if <= init_sbi_if_signals(PWM_ADDR_WIDTH, PWM_DATA_WIDTH);
      do_reset(clk_i, arst_b_i);

      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), C_CFG, clk_i, arst_b_i, sbi_if, pwm_o);
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;
