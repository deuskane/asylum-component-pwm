-- Generated VHDL Package for PWM

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.sbi_pkg.all;
--==================================
-- Module      : PWM
-- Description : CSR for PWM
-- Width       : 8
--==================================

package PWM_csr_pkg is

  ------------------------------------
  -- Global Constants
  ------------------------------------

  constant PWM_ADDR_WIDTH : natural := 2;
  constant PWM_DATA_WIDTH : natural := 8;

  --==================================
  -- Register    : cfg
  -- Description : PWM Configuration Register
  -- Address     : 0x0
  -- Width       : 1
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  constant PWM_CFG : unsigned(PWM_ADDR_WIDTH-1 downto 0) := to_unsigned(0, PWM_ADDR_WIDTH);

  type PWM_cfg_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : enable
  -- Description : 0 : PWM is disabled (counter cleared, output low), 1 : PWM is enabled, the first period starts with the high phase
  -- Width       : 1
  --==================================
    enable : std_logic_vector(1-1 downto 0);
  end record PWM_cfg_sw2hw_t;

  --==================================
  -- Register    : prescaler
  -- Description : PWM Clock Prescaler. A tick of the PWM counter lasts (prescaler+1) CLK cycles. Taken into account at the start of the next PWM period
  -- Address     : 0x1
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  constant PWM_PRESCALER : unsigned(PWM_ADDR_WIDTH-1 downto 0) := to_unsigned(1, PWM_ADDR_WIDTH);

  type PWM_prescaler_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : ratio
  -- Description : Number of CLK cycles minus one of a tick
  -- Width       : 8
  --==================================
    ratio : std_logic_vector(8-1 downto 0);
  end record PWM_prescaler_sw2hw_t;

  --==================================
  -- Register    : period
  -- Description : PWM Period. The PWM period is (period+1) ticks, i.e. (period+1)*(prescaler+1) CLK cycles. Taken into account at the start of the next PWM period
  -- Address     : 0x2
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  constant PWM_PERIOD : unsigned(PWM_ADDR_WIDTH-1 downto 0) := to_unsigned(2, PWM_ADDR_WIDTH);

  type PWM_period_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : value
  -- Description : Number of ticks minus one of the PWM period
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record PWM_period_sw2hw_t;

  --==================================
  -- Register    : duty
  -- Description : PWM Duty Cycle. The output is high during the first duty ticks of each PWM period : 0 : always low, greater than period : always high. Taken into account at the start of the next PWM period
  -- Address     : 0x3
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  constant PWM_DUTY : unsigned(PWM_ADDR_WIDTH-1 downto 0) := to_unsigned(3, PWM_ADDR_WIDTH);

  type PWM_duty_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : value
  -- Description : Number of ticks of the high phase
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record PWM_duty_sw2hw_t;

  ------------------------------------
  -- Structure PWM_t
  ------------------------------------
  type PWM_sw2hw_t is record
    cfg : PWM_cfg_sw2hw_t;
    prescaler : PWM_prescaler_sw2hw_t;
    period : PWM_period_sw2hw_t;
    duty : PWM_duty_sw2hw_t;
  end record PWM_sw2hw_t;

  ------------------------------------
  -- Component
  ------------------------------------
component PWM_registers is
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
end component PWM_registers;


end package PWM_csr_pkg;
