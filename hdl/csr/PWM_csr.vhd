-- Generated VHDL Module for PWM


library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.PWM_csr_pkg.ALL;
library asylum;
use     asylum.csr_pkg.ALL;
library asylum;
use     asylum.sbi_pkg.all;

--==================================
-- Module      : PWM
-- Description : CSR for PWM
-- Width       : 8
--==================================
entity PWM_registers is
  generic (
    MODULE_NAME :  string := "" -- Name of the module
   ;USER_DEFINE_PRESCALER : boolean -- Parameters to enable the User define Prescaler
   ;PRESCALER_RATIO : std_logic_vector(7 downto 0) -- Default value for prescaler ratio
  );
  port (
    -- Clock and Reset
    clk_i      : in  std_logic
   ;arst_b_i   : in  std_logic
    -- Bus
   ;sbi_ini_i  : in  sbi_ini_t
   ;sbi_tgt_o  : out sbi_tgt_t
    -- CSR
   ;sw2hw_o    : out PWM_sw2hw_t
  );
end entity PWM_registers;

architecture rtl of PWM_registers is

  signal   sig_wcs   : std_logic;
  signal   sig_we    : std_logic;
  signal   sig_waddr : unsigned(PWM_ADDR_WIDTH-1 downto 0);
  signal   sig_wdata : std_logic_vector(sbi_ini_i.wdata'length-1 downto 0);
  signal   sig_wbusy : std_logic;

  signal   sig_rcs   : std_logic;
  signal   sig_re    : std_logic;
  signal   sig_raddr : unsigned(PWM_ADDR_WIDTH-1 downto 0);
  signal   sig_rdata : std_logic_vector(sbi_tgt_o.rdata'length-1 downto 0);
  signal   sig_rbusy : std_logic;

  signal   sig_busy  : std_logic;

  function INIT_cfg
    return std_logic_vector is
    variable tmp : std_logic_vector(1-1 downto 0);
  begin  -- function INIT_cfg
    tmp(0 downto 0) := "0"; -- enable
    return tmp;
  end function INIT_cfg;

  signal   cfg_wcs       : std_logic;
  signal   cfg_we        : std_logic;
  signal   cfg_wdata     : std_logic_vector(8-1 downto 0);
  signal   cfg_wdata_sw  : std_logic_vector(1-1 downto 0);
  signal   cfg_wdata_hw  : std_logic_vector(1-1 downto 0);
  signal   cfg_wbusy     : std_logic;

  signal   cfg_rcs       : std_logic;
  signal   cfg_re        : std_logic;
  signal   cfg_rdata     : std_logic_vector(8-1 downto 0);
  signal   cfg_rdata_sw  : std_logic_vector(1-1 downto 0);
  signal   cfg_rdata_hw  : std_logic_vector(1-1 downto 0);
  signal   cfg_rbusy     : std_logic;

  function INIT_prescaler
    return std_logic_vector is
    variable tmp : std_logic_vector(8-1 downto 0);
  begin  -- function INIT_prescaler
    tmp(7 downto 0) := PRESCALER_RATIO; -- ratio
    return tmp;
  end function INIT_prescaler;

  signal   prescaler_wcs       : std_logic;
  signal   prescaler_we        : std_logic;
  signal   prescaler_wdata     : std_logic_vector(8-1 downto 0);
  signal   prescaler_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   prescaler_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   prescaler_wbusy     : std_logic;

  signal   prescaler_rcs       : std_logic;
  signal   prescaler_re        : std_logic;
  signal   prescaler_rdata     : std_logic_vector(8-1 downto 0);
  signal   prescaler_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   prescaler_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   prescaler_rbusy     : std_logic;

  function INIT_period
    return std_logic_vector is
    variable tmp : std_logic_vector(8-1 downto 0);
  begin  -- function INIT_period
    tmp(7 downto 0) := "11111111"; -- value
    return tmp;
  end function INIT_period;

  signal   period_wcs       : std_logic;
  signal   period_we        : std_logic;
  signal   period_wdata     : std_logic_vector(8-1 downto 0);
  signal   period_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   period_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   period_wbusy     : std_logic;

  signal   period_rcs       : std_logic;
  signal   period_re        : std_logic;
  signal   period_rdata     : std_logic_vector(8-1 downto 0);
  signal   period_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   period_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   period_rbusy     : std_logic;

  function INIT_duty
    return std_logic_vector is
    variable tmp : std_logic_vector(8-1 downto 0);
  begin  -- function INIT_duty
    tmp(7 downto 0) := "00000000"; -- value
    return tmp;
  end function INIT_duty;

  signal   duty_wcs       : std_logic;
  signal   duty_we        : std_logic;
  signal   duty_wdata     : std_logic_vector(8-1 downto 0);
  signal   duty_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   duty_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   duty_wbusy     : std_logic;

  signal   duty_rcs       : std_logic;
  signal   duty_re        : std_logic;
  signal   duty_rdata     : std_logic_vector(8-1 downto 0);
  signal   duty_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   duty_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   duty_rbusy     : std_logic;

begin  -- architecture rtl

  -- Interface 
  sig_wcs   <= sbi_ini_i.cs;
  sig_we    <= sbi_ini_i.we;
  sig_waddr <= unsigned(sbi_ini_i.addr(PWM_ADDR_WIDTH-1 downto 0));
  sig_wdata <= sbi_ini_i.wdata;

  sig_rcs   <= sbi_ini_i.cs;
  sig_re    <= sbi_ini_i.re;
  sig_raddr <= unsigned(sbi_ini_i.addr(PWM_ADDR_WIDTH-1 downto 0));
  sbi_tgt_o.rdata <= sig_rdata;
  sbi_tgt_o.ready <= not sig_busy;

  sig_busy  <= sig_wbusy when sig_we = '1' else
               sig_rbusy when sig_re = '1' else
               '0';

  gen_cfg: if (True)
  generate
  --==================================
  -- Register    : cfg
  -- Description : PWM Configuration Register
  -- Address     : 0x0
  -- Width       : 1
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : enable
  -- Description : 0 : PWM is disabled (counter cleared, output low), 1 : PWM is enabled, the first period starts with the high phase
  -- Width       : 1
  --==================================


    cfg_rcs     <= '1' when (sig_raddr = PWM_CFG) else '0';
    cfg_re      <= sig_rcs and sig_re and cfg_rcs;
    cfg_rdata   <= (
      0 => cfg_rdata_sw(0), -- enable(0)
      others => '0');

    cfg_wcs     <= '1' when       (sig_waddr = PWM_CFG)   else '0';
    cfg_we      <= sig_wcs and sig_we and cfg_wcs;
    cfg_wdata   <= sig_wdata;
    cfg_wdata_sw(0 downto 0) <= cfg_wdata(0 downto 0); -- enable
    sw2hw_o.cfg.enable <= cfg_rdata_hw(0 downto 0); -- enable

    ins_cfg : csr_reg
      generic map
        (WIDTH         => 1
        ,INIT          => INIT_cfg
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => cfg_wdata_sw
        ,sw_rd_o       => cfg_rdata_sw
        ,sw_we_i       => cfg_we
        ,sw_re_i       => cfg_re
        ,sw_rbusy_o    => cfg_rbusy
        ,sw_wbusy_o    => cfg_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => cfg_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.cfg.re
        ,hw_sw_we_o    => sw2hw_o.cfg.we
        );

  end generate gen_cfg;

  gen_cfg_b: if not (True)
  generate
    cfg_rcs     <= '0';
    cfg_rbusy   <= '0';
    cfg_rdata   <= (others => '0');
    cfg_wcs      <= '0';
    cfg_wbusy    <= '0';
    sw2hw_o.cfg.enable <= "0";
    sw2hw_o.cfg.re <= '0';
    sw2hw_o.cfg.we <= '0';
  end generate gen_cfg_b;

  gen_prescaler: if (USER_DEFINE_PRESCALER)
  generate
  --==================================
  -- Register    : prescaler
  -- Description : PWM Clock Prescaler. A tick of the PWM counter lasts (prescaler+1) CLK cycles. Taken into account at the start of the next PWM period
  -- Address     : 0x1
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : ratio
  -- Description : Number of CLK cycles minus one of a tick
  -- Width       : 8
  --==================================


    prescaler_rcs     <= '1' when (sig_raddr = PWM_PRESCALER) else '0';
    prescaler_re      <= sig_rcs and sig_re and prescaler_rcs;
    prescaler_rdata   <= (
      0 => prescaler_rdata_sw(0), -- ratio(0)
      1 => prescaler_rdata_sw(1), -- ratio(1)
      2 => prescaler_rdata_sw(2), -- ratio(2)
      3 => prescaler_rdata_sw(3), -- ratio(3)
      4 => prescaler_rdata_sw(4), -- ratio(4)
      5 => prescaler_rdata_sw(5), -- ratio(5)
      6 => prescaler_rdata_sw(6), -- ratio(6)
      7 => prescaler_rdata_sw(7), -- ratio(7)
      others => '0');

    prescaler_wcs     <= '1' when       (sig_waddr = PWM_PRESCALER)   else '0';
    prescaler_we      <= sig_wcs and sig_we and prescaler_wcs;
    prescaler_wdata   <= sig_wdata;
    prescaler_wdata_sw(7 downto 0) <= prescaler_wdata(7 downto 0); -- ratio
    sw2hw_o.prescaler.ratio <= prescaler_rdata_hw(7 downto 0); -- ratio

    ins_prescaler : csr_reg
      generic map
        (WIDTH         => 8
        ,INIT          => INIT_prescaler
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => prescaler_wdata_sw
        ,sw_rd_o       => prescaler_rdata_sw
        ,sw_we_i       => prescaler_we
        ,sw_re_i       => prescaler_re
        ,sw_rbusy_o    => prescaler_rbusy
        ,sw_wbusy_o    => prescaler_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => prescaler_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.prescaler.re
        ,hw_sw_we_o    => sw2hw_o.prescaler.we
        );

  end generate gen_prescaler;

  gen_prescaler_b: if not (USER_DEFINE_PRESCALER)
  generate
    prescaler_rcs     <= '0';
    prescaler_rbusy   <= '0';
    prescaler_rdata   <= (others => '0');
    prescaler_wcs      <= '0';
    prescaler_wbusy    <= '0';
    sw2hw_o.prescaler.ratio <= PRESCALER_RATIO;
    sw2hw_o.prescaler.re <= '0';
    sw2hw_o.prescaler.we <= '0';
  end generate gen_prescaler_b;

  gen_period: if (True)
  generate
  --==================================
  -- Register    : period
  -- Description : PWM Period. The PWM period is (period+1) ticks, i.e. (period+1)*(prescaler+1) CLK cycles. Taken into account at the start of the next PWM period
  -- Address     : 0x2
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : value
  -- Description : Number of ticks minus one of the PWM period
  -- Width       : 8
  --==================================


    period_rcs     <= '1' when (sig_raddr = PWM_PERIOD) else '0';
    period_re      <= sig_rcs and sig_re and period_rcs;
    period_rdata   <= (
      0 => period_rdata_sw(0), -- value(0)
      1 => period_rdata_sw(1), -- value(1)
      2 => period_rdata_sw(2), -- value(2)
      3 => period_rdata_sw(3), -- value(3)
      4 => period_rdata_sw(4), -- value(4)
      5 => period_rdata_sw(5), -- value(5)
      6 => period_rdata_sw(6), -- value(6)
      7 => period_rdata_sw(7), -- value(7)
      others => '0');

    period_wcs     <= '1' when       (sig_waddr = PWM_PERIOD)   else '0';
    period_we      <= sig_wcs and sig_we and period_wcs;
    period_wdata   <= sig_wdata;
    period_wdata_sw(7 downto 0) <= period_wdata(7 downto 0); -- value
    sw2hw_o.period.value <= period_rdata_hw(7 downto 0); -- value

    ins_period : csr_reg
      generic map
        (WIDTH         => 8
        ,INIT          => INIT_period
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => period_wdata_sw
        ,sw_rd_o       => period_rdata_sw
        ,sw_we_i       => period_we
        ,sw_re_i       => period_re
        ,sw_rbusy_o    => period_rbusy
        ,sw_wbusy_o    => period_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => period_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.period.re
        ,hw_sw_we_o    => sw2hw_o.period.we
        );

  end generate gen_period;

  gen_period_b: if not (True)
  generate
    period_rcs     <= '0';
    period_rbusy   <= '0';
    period_rdata   <= (others => '0');
    period_wcs      <= '0';
    period_wbusy    <= '0';
    sw2hw_o.period.value <= "11111111";
    sw2hw_o.period.re <= '0';
    sw2hw_o.period.we <= '0';
  end generate gen_period_b;

  gen_duty: if (True)
  generate
  --==================================
  -- Register    : duty
  -- Description : PWM Duty Cycle. The output is high during the first duty ticks of each PWM period : 0 : always low, greater than period : always high. Taken into account at the start of the next PWM period
  -- Address     : 0x3
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : value
  -- Description : Number of ticks of the high phase
  -- Width       : 8
  --==================================


    duty_rcs     <= '1' when (sig_raddr = PWM_DUTY) else '0';
    duty_re      <= sig_rcs and sig_re and duty_rcs;
    duty_rdata   <= (
      0 => duty_rdata_sw(0), -- value(0)
      1 => duty_rdata_sw(1), -- value(1)
      2 => duty_rdata_sw(2), -- value(2)
      3 => duty_rdata_sw(3), -- value(3)
      4 => duty_rdata_sw(4), -- value(4)
      5 => duty_rdata_sw(5), -- value(5)
      6 => duty_rdata_sw(6), -- value(6)
      7 => duty_rdata_sw(7), -- value(7)
      others => '0');

    duty_wcs     <= '1' when       (sig_waddr = PWM_DUTY)   else '0';
    duty_we      <= sig_wcs and sig_we and duty_wcs;
    duty_wdata   <= sig_wdata;
    duty_wdata_sw(7 downto 0) <= duty_wdata(7 downto 0); -- value
    sw2hw_o.duty.value <= duty_rdata_hw(7 downto 0); -- value

    ins_duty : csr_reg
      generic map
        (WIDTH         => 8
        ,INIT          => INIT_duty
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => duty_wdata_sw
        ,sw_rd_o       => duty_rdata_sw
        ,sw_we_i       => duty_we
        ,sw_re_i       => duty_re
        ,sw_rbusy_o    => duty_rbusy
        ,sw_wbusy_o    => duty_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => duty_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.duty.re
        ,hw_sw_we_o    => sw2hw_o.duty.we
        );

  end generate gen_duty;

  gen_duty_b: if not (True)
  generate
    duty_rcs     <= '0';
    duty_rbusy   <= '0';
    duty_rdata   <= (others => '0');
    duty_wcs      <= '0';
    duty_wbusy    <= '0';
    sw2hw_o.duty.value <= "00000000";
    sw2hw_o.duty.re <= '0';
    sw2hw_o.duty.we <= '0';
  end generate gen_duty_b;

  sig_wbusy <= 
    cfg_wbusy when cfg_wcs = '1' else
    prescaler_wbusy when prescaler_wcs = '1' else
    period_wbusy when period_wcs = '1' else
    duty_wbusy when duty_wcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rbusy <= 
    cfg_rbusy when cfg_rcs = '1' else
    prescaler_rbusy when prescaler_rcs = '1' else
    period_rbusy when period_rcs = '1' else
    duty_rbusy when duty_rcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rdata <= 
    cfg_rdata when cfg_rcs = '1' else
    prescaler_rdata when prescaler_rcs = '1' else
    period_rdata when period_rcs = '1' else
    duty_rdata when duty_rcs = '1' else
    (others => '0'); -- Bad Address, return 0

  gen_tgt_info_name : if MODULE_NAME = ""
  generate
    sbi_tgt_o.info.name <= to_sbi_name("PWM");
  else generate
    sbi_tgt_o.info.name <= to_sbi_name(MODULE_NAME);
  end generate;
end architecture rtl;
