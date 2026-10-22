-------------------------------------------------------------------------------
-- Title      : pwm_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : pwm_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: PWM components
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-22  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;
library asylum;
use     asylum.sbi_pkg.all;

package pwm_pkg is

-- [COMPONENT_INSERT][BEGIN]
component sbi_PWM is
  generic(
    NAME                  : string  := "";
    USER_DEFINE_PRESCALER : boolean := true;                         -- Prescaler register writable by software
    PRESCALER_RATIO       : std_logic_vector(8-1 downto 0) := x"C2"  -- Default value for prescaler ratio (1 kHz with a 50 MHz clock and period = 0xFF)
    );
  port   (
    clk_i            : in  std_logic;
    arst_b_i         : in  std_logic; -- asynchronous reset

    -- Bus
    sbi_ini_i        : in  sbi_ini_t;
    sbi_tgt_o        : out sbi_tgt_t;

    -- PWM Output
    pwm_o            : out std_logic
    );

end component sbi_PWM;

component pwm_core is
  generic (
    PRESCALER_WIDTH      : natural := 8;                      -- Width of the prescaler ratio
    COUNTER_WIDTH        : natural := 8                       -- Width of the period and of the duty (resolution of the PWM)
    );
  port (
    -- Clock & Reset
    clk_i                : in  std_logic;
    arst_b_i             : in  std_logic;

    -- Configuration
    cfg_enable_i         : in  std_logic;                     -- 0 : counter cleared, pwm_o low
    cfg_prescaler_ratio_i: in  std_logic_vector(PRESCALER_WIDTH-1 downto 0); -- Duration of a tick minus one, in clock cycles
    cfg_period_i         : in  std_logic_vector(COUNTER_WIDTH-1 downto 0);   -- PWM period minus one, in ticks
    cfg_duty_i           : in  std_logic_vector(COUNTER_WIDTH-1 downto 0);   -- High phase, in ticks

    -- PWM Output
    pwm_o                : out std_logic
    );
end component pwm_core;

-- [COMPONENT_INSERT][END]

end pwm_pkg;
