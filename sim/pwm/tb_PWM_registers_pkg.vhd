-------------------------------------------------------------------------------
-- Title      : tb_PWM_registers_pkg
-- Project    : PWM
-------------------------------------------------------------------------------
-- File       : tb_PWM_registers_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario registers of tb_PWM, from reset :
--              Read and write of the registers, a different pattern in each
--              register (prescaler read 0 if not implemented), only the
--              enable bit of cfg implemented
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (was test_registers of tb_PWM)
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

package tb_PWM_registers_pkg is

  -- Read and write of the registers, a different pattern in each register
  -- (prescaler read 0 if not implemented), only the enable bit of cfg
  -- implemented
  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    );

end package tb_PWM_registers_pkg;

package body tb_PWM_registers_pkg is

  procedure run
    (constant cfg        : in    cfg_t            -- Generics of sbi_PWM
    ;signal   clk        : in    std_logic
    ;signal   sbi_if     : inout t_sbi_if
    ) is
    type     pattern_array_t is array (natural range <>) of byte_t;
    constant C_PATTERNS : pattern_array_t := (x"5A", x"A5", x"0F", x"F0");
    variable v_pat      : byte_t;
    variable v_swap     : byte_t;
  begin
    -- Each register gets a different pattern, then the inverted pattern
    for i in C_PATTERNS'range loop
      v_pat  := C_PATTERNS(i);
      v_swap := v_pat(3 downto 0) & v_pat(7 downto 4);
      wr (PWM_PRESCALER, v_pat                     , "Write prescaler 0x" & to_hstring(v_pat)   , clk, sbi_if);
      wr (PWM_PERIOD   , v_swap                    , "Write period 0x" & to_hstring(v_swap)     , clk, sbi_if);
      wr (PWM_DUTY     , not v_pat                 , "Write duty 0x" & to_hstring(not v_pat)    , clk, sbi_if);
      chk(PWM_PRESCALER, prescaler_read(cfg, v_pat), "Read back prescaler (0 if not implemented)", clk, sbi_if);
      chk(PWM_PERIOD   , v_swap                    , "Read back period"                          , clk, sbi_if);
      chk(PWM_DUTY     , not v_pat                 , "Read back duty"                            , clk, sbi_if);
    end loop;
    wr (PWM_CFG, x"FF", "Write cfg 0xFF"                                     , clk, sbi_if);
    chk(PWM_CFG, x"01", "Read back cfg : only the enable bit is implemented", clk, sbi_if);
    wr (PWM_CFG, x"00", "Write cfg 0x00"                                     , clk, sbi_if);
    chk(PWM_CFG, x"00", "Read back cfg"                                      , clk, sbi_if);
  end procedure;

end package body tb_PWM_registers_pkg;
