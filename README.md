<!--
  README GENERATION INSTRUCTIONS (for the next regeneration run)
  ----------------------------------------------------------------
  This README follows the common Asylum IP model. Regenerate it from the
  sources, never from the previous README text alone.

  Sources of truth (in priority order):
    1. hdl/*.vhd            : entities, generics, ports, packages
    2. hdl/csr/*.hjson      : register map (regtool); *_csr.md/.h are generated
    3. <IP>.core            : VLNV (name), filesets, targets, depends, revisions
    4. mk/targets.txt       : target list shown by `make help`; mk/defs.mk
    5. sim/, syn/, esw/, boards/ : testbenches, constraints, software
  Section order (keep it, same headings in every IP):
    CI badge / Title + one-line description + VLNV / Table of Contents /
    Introduction (Key Features) / Block Diagram / Top-Level (Parameters,
    Ports, Instantiation Example) / HDL Modules / Register Map /
    Verification / Synthesis / Design Notes (optional) /
    Directory Structure / Dependencies
  Rules:
    - Language: English. Tables: Parameters = Name|Type|Default|Description,
      Ports = Name|Direction|Type|Description (grouped by interface).
    - Register Map: link to the generated hdl/csr/<X>_csr.md (plus the
      .hjson source and _csr.h header); never copy register tables here.
    - Top-Level = sbi_* wrapper if present, else the entity used by the
      `default` target, else the main entity (libraries: list packages).
    - Write "This IP has no software-visible registers." / "No dedicated
      synthesis target ..." instead of removing a section.
    - Keep still-accurate hand-written content (ISA tables, results,
      images) in "Design Notes"; drop anything not backed by the sources.
    - Block diagram: doc/<NAME>.drawio (NAME = 4th field of the VLNV),
      top entity box with generics on top, inputs left, outputs right,
      bus interfaces as bold arrows, internal blocks colour-coded
      (CSR yellow, FIFO/memory green, core logic blue, external grey).
      Update it whenever ports/generics/sub-blocks change.
    - Do not edit generated files (hdl/csr/*_csr.*) or the CI badge URL.
-->
[![CI](https://github.com/deuskane/asylum-component-pwm/actions/workflows/ci.yml/badge.svg)](https://github.com/deuskane/asylum-component-pwm/actions/workflows/ci.yml)

# asylum-component-pwm

**Single channel PWM with CSR access over the SBI bus: static prescaler (generic), 8-bit prescaler, 8-bit period and duty cycle, glitch-free update at the start of the next PWM period.**

VLNV: `asylum:component:PWM:1.0.0`

## Table of Contents

1. [Introduction](#introduction)
2. [Block Diagram](#block-diagram)
3. [Top-Level](#top-level)
4. [HDL Modules](#hdl-modules)
5. [Register Map](#register-map)
6. [Verification](#verification)
7. [Synthesis](#synthesis)
8. [Design Notes](#design-notes)
9. [Directory Structure](#directory-structure)
10. [Dependencies](#dependencies)

## Introduction

This IP is the PWM (Pulse Width Modulation) generator of the Asylum project. Software drives it through 4 registers on the SBI bus: `cfg` (enable), `prescaler` (duration of a tick), `period` (number of ticks of a PWM period) and `duty` (number of ticks of the high phase). A static prescaler, set at elaboration (`STATIC_PRESCALER_RATIO`, a `clock_divider` in pulse mode), divides the clock before the prescaler to reach low PWM frequencies (50 Hz for a servo) without wider registers. The CSR has no status and no interrupt: the configuration is copied into shadow registers at the start of each PWM period, so software can write it at any time without synchronizing with the output. The PWM itself is implemented by `pwm_core`, which is independent of the CSR and of the bus interface (plain configuration signals, generic widths).

### Key Features

- Single PWM output `pwm_o`, driven by a register (no glitch)
- Static prescaler: `clock_divider` in pulse mode, one prescaler step every `STATIC_PRESCALER_RATIO` clock cycles (1: none)
- PWM period = (period + 1) x (prescaler + 1) x STATIC_PRESCALER_RATIO clock cycles, high phase = duty x (prescaler + 1) x STATIC_PRESCALER_RATIO clock cycles
- Duty 0: always low; duty > period: always high
- Configuration (prescaler, period, duty) taken into account at the start of the next PWM period: no truncated or doubled pulse, the counter never overflows
- `cfg.enable = 0`: counter cleared, output low one clock cycle after the write; the first PWM period starts with its high phase on the next pulse of the static prescaler (one clock cycle after the enable without static prescaler)
- Prescaler register optional (`USER_DEFINE_PRESCALER`), reset / fixed value `PRESCALER_RATIO` (1 kHz with a 50 MHz clock and the reset value of `period`)
- `pwm_core` usable alone, with generic static prescaler and prescaler / counter widths (`STATIC_PRESCALER_RATIO`, `PRESCALER_WIDTH`, `COUNTER_WIDTH`)

## Block Diagram

Diagram: [doc/PWM.drawio](doc/PWM.drawio) (open with diagrams.net or the VS Code Draw.io extension; `make -C doc` exports `doc/PWM-Overview.png` with the drawio CLI).

- The SBI bus accesses `PWM_registers` (generated by regtool from [hdl/csr/PWM.hjson](hdl/csr/PWM.hjson)): `cfg`, `prescaler` (when `USER_DEFINE_PRESCALER = true`), `period`, `duty`.
- The register values go to `pwm_core` ([hdl/pwm_core.vhd](hdl/pwm_core.vhd)); there is no hardware to software path.
- In `pwm_core`, the static prescaler (`clock_divider`, pulse mode, present when `STATIC_PRESCALER_RATIO > 1`) generates one enable pulse every `STATIC_PRESCALER_RATIO` clock cycles; the shadow registers hold the ratio, period and duty of the current PWM period; the prescaler generates one tick every `ratio + 1` enable pulses; the PWM counter counts the ticks from 0 to `period`; the comparator drives `pwm_o` high while the counter is lower than `duty`.

## Top-Level

Top-level entity: **`sbi_PWM`** ([hdl/sbi_PWM.vhd](hdl/sbi_PWM.vhd)), library `asylum`, component declared in `asylum.pwm_pkg`.

### Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `NAME` | string | `""` | Instance name, forwarded to the CSR block (`MODULE_NAME`, visible in `sbi_tgt_o.info`) |
| `STATIC_PRESCALER_RATIO` | positive | `1` | Static prescaler: clock cycles per step of the prescaler (`clock_divider` in pulse mode). 1: no static prescaler. 20: 50 Hz with a 50 MHz clock, `prescaler = 249` and `period = 199` |
| `USER_DEFINE_PRESCALER` | boolean | `true` | `true`: the `prescaler` register exists and is software-writable; `false`: the ratio is fixed to `PRESCALER_RATIO` (the `prescaler` address reads 0) |
| `PRESCALER_RATIO` | std_logic_vector(7 downto 0) | `x"C2"` | Reset / fixed value of the prescaler ratio (`x"C2"`: 1001.6 Hz with a 50 MHz clock, `STATIC_PRESCALER_RATIO = 1` and `period = 0xFF`) |

### Ports

#### Clock & Reset

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | System clock (also the PWM clock) |
| `arst_b_i` | in | std_logic | Asynchronous reset, active low |

#### Bus (SBI)

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `sbi_ini_i` | in | sbi_ini_t | SBI request from the initiator (`cs`, `re`, `we`, `addr`, `wdata`) |
| `sbi_tgt_o` | out | sbi_tgt_t | SBI response to the initiator (`ready`, `rdata`, `info`) |

#### PWM

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `pwm_o` | out | std_logic | PWM output, low while the PWM is disabled |

### Instantiation Example

```vhdl
library asylum;
use     asylum.sbi_pkg.all;
use     asylum.pwm_pkg.all;

  -- Servo : 50 Hz with a 50 MHz clock (prescaler = 249, period = 199)
  ins_pwm : sbi_PWM
    generic map
    ( NAME                   => "PWM0"
     ,STATIC_PRESCALER_RATIO => 20
     ,USER_DEFINE_PRESCALER  => true
     ,PRESCALER_RATIO        => x"F9"
    )
    port map
    ( clk_i     => clk
     ,arst_b_i  => arst_b
     ,sbi_ini_i => sbi_inis(PWM0_ID)  -- sbi_ini_t(addr(1 downto 0), wdata(7 downto 0))
     ,sbi_tgt_o => sbi_tgts(PWM0_ID)  -- sbi_tgt_t(rdata(7 downto 0))
     ,pwm_o     => pwm0
    );
```

The CSR bank uses 2 address bits (`PWM_ADDR_WIDTH = 2`) and 8-bit data (`PWM_DATA_WIDTH = 8`), see `asylum.PWM_csr_pkg`.

## HDL Modules

| File | Unit | Kind | Role |
|------|------|------|------|
| [hdl/pwm_pkg.vhd](hdl/pwm_pkg.vhd) | `pwm_pkg` | package | Component declarations of `sbi_PWM` and `pwm_core` |
| [hdl/pwm_core.vhd](hdl/pwm_core.vhd) | `pwm_core` | entity | Static prescaler (`clock_divider`), shadow registers, prescaler, PWM counter, registered comparator. Independent of the CSR and of the SBI |
| [hdl/sbi_PWM.vhd](hdl/sbi_PWM.vhd) | `sbi_PWM` | entity | Top-level: CSR + `pwm_core` (static prescaler, 8-bit prescaler, 8-bit counter) |
| hdl/csr/PWM_csr.vhd | `PWM_registers` | entity | Generated CSR bank (regtool) |
| hdl/csr/PWM_csr_pkg.vhd | `PWM_csr_pkg` | package | Generated types (`PWM_sw2hw_t`), address constants and `PWM_registers` component |

### pwm_core

`pwm_core` can be used without the CSR, for example with wider counters for a lower PWM frequency.

#### Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `STATIC_PRESCALER_RATIO` | positive | `1` | Clock cycles per enable pulse of the prescaler (`clock_divider` in pulse mode, not instantiated when 1) |
| `PRESCALER_WIDTH` | natural | `8` | Width of `cfg_prescaler_ratio_i` |
| `COUNTER_WIDTH` | natural | `8` | Width of `cfg_period_i` and `cfg_duty_i` (resolution of the PWM) |

#### Ports

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | System clock |
| `arst_b_i` | in | std_logic | Asynchronous reset, active low |
| `cfg_enable_i` | in | std_logic | 0: counter cleared, `pwm_o` low, shadow registers loaded continuously; 1: PWM running (from the next enable pulse of the static prescaler) |
| `cfg_prescaler_ratio_i` | in | std_logic_vector(PRESCALER_WIDTH-1 downto 0) | Duration of a tick minus one, in enable pulses of the static prescaler (clock cycles when `STATIC_PRESCALER_RATIO = 1`) |
| `cfg_period_i` | in | std_logic_vector(COUNTER_WIDTH-1 downto 0) | PWM period minus one, in ticks |
| `cfg_duty_i` | in | std_logic_vector(COUNTER_WIDTH-1 downto 0) | High phase, in ticks (greater than `cfg_period_i`: always high) |
| `pwm_o` | out | std_logic | PWM output (register) |

## Register Map

The register map is generated by regtool from [hdl/csr/PWM.hjson](hdl/csr/PWM.hjson):

- Register documentation: **[hdl/csr/PWM_csr.md](hdl/csr/PWM_csr.md)**
- C header: [hdl/csr/PWM_csr.h](hdl/csr/PWM_csr.h)

Notes:

- 4 registers: `cfg` (0x0, `enable` bit), `prescaler` (0x1), `period` (0x2), `duty` (0x3). Reset values: `cfg = 0x00`, `prescaler = PRESCALER_RATIO`, `period = 0xFF`, `duty = 0x00`.
- The `prescaler` register only exists when `USER_DEFINE_PRESCALER = true`.
- `prescaler`, `period` and `duty` are read back as written; the values used by the PWM are the shadow copies, updated at the start of the next PWM period (see [Configuration Update](#configuration-update)).

## Verification

### Testbenches

| File | DUT | Description |
|------|-----|-------------|
| [sim/basic/tb_PWM.vhd](sim/basic/tb_PWM.vhd) | `sbi_PWM` x 3, `pwm_core` | UVVM testbench, self-checking (257 checks). The CSR are accessed with the SBI BFM (`bitvis_vip_sbi`); the high phase and the period of each PWM output are measured in clock cycles and checked exactly, constant levels with `check_stable`. `dut` (`sbi_PWM`, default generics): (1) reset values of the 4 registers and of the outputs; (2) read / write of `prescaler`, `period`, `duty` with 4 patterns, only `cfg.enable` implemented; (3) output low while disabled; (4) start latency (rising edge within one clock cycle after the write of `cfg`) and first period complete; (5) prescaler; (6) duty 0, 1, `period`, `period + 1` and 255; (7) period 0; (8) configuration taken into account at the next PWM period: duty decreased during the high phase (no truncated pulse), duty increased during the low phase (no second pulse), period increased (current period not extended), duty and period decreased below the counter (no counter overflow), prescaler decreased (current ticks unchanged); (9) disable during the high phase (output low one cycle later) and enable again; (10) 1001.6 Hz with the reset values of `prescaler` and `period`. `dut_fixed` (`USER_DEFINE_PRESCALER = false`, `PRESCALER_RATIO = x"02"`): `prescaler` not writable, read 0, PWM timing with the fixed ratio. `dut_static` (`STATIC_PRESCALER_RATIO = 20`): tick of `20 x (prescaler + 1)` cycles, first period started on a pulse of the static prescaler, duty taken into account at the next period, disable not delayed by the static prescaler, 50 Hz servo signal (1.5 ms pulse every 20 ms). `dut_core` (`pwm_core` alone, 4-bit prescaler, 12-bit counter): maximum prescaler ratio, full 12-bit period, duty 4095 written while running, duty greater than period. Plus: asynchronous reset while the 4 outputs are high |

### Targets

| Target | Toplevel | Description |
|--------|----------|-------------|
| `default` | `sbi_PWM` | HDL fileset + CSR generation (not a simulation) |
| `sim_basic` | `tb_PWM` | `sbi_PWM` (3 configurations) and `pwm_core` with the UVVM SBI BFM |
| `lint_ghdl` | `sbi_PWM_synth_top` | Lint: GHDL `-Wall` analysis and elaboration (empty simulation) of `sbi_PWM` in a wrapper with flat SBI ports (`syn/ghdl/sbi_PWM_synth_top.vhd`) |
| `lint_ghdl_synth_default` | `sbi_PWM_synth_top` | Synthesis check (see below), default generics of `sbi_PWM` (generics of `dut` in `sim_basic`) |
| `lint_ghdl_synth_fixed_prescaler` | `sbi_PWM_synth_top` | Synthesis check, `USER_DEFINE_PRESCALER = false`, `PRESCALER_RATIO = x"02"` (generics of `dut_fixed` in `sim_basic`) |
| `lint_ghdl_synth_static_prescaler` | `sbi_PWM_synth_top` | Synthesis check, `STATIC_PRESCALER_RATIO = 20` (generics of `dut_static` in `sim_basic`) |

A `lint_ghdl_synth_*` target is `lint_ghdl` with the generics of its configuration (FuseSoC `parameters`) and a `pre_run` hook, `syn/ghdl/ghdl_synth.sh`, which adds `include ghdl_synth.mk` to the Makefile generated by edalize. The run step (`make run EXTRA_OPTIONS=<generics>`) then runs, in the build directory:

1. `ghdl --synth` of the toplevel (rule `ghdl_synth` of [syn/ghdl/ghdl_synth.mk](syn/ghdl/ghdl_synth.mk)), with the options of the target: `STD`, `ANALYZE_OPTIONS` (`-Wall`), `TOPLEVEL_LIBS`, `TOPLEVEL` and the generics. It writes `sbi_PWM_synth_top_synth.vhd` (netlist) and `sbi_PWM_synth_top_synth.log`, prints the warnings, and fails on a synthesis error (an inferred latch is one);
2. `ghdl -r --no-run`: elaboration with the same generics, without simulation.

To add a configuration, add a target with its `parameters` (the generics are declared in the `parameters` section of `PWM.core`).

### How to Run

The default tool is GHDL (`mk/defs.mk`: `TOOL ?= ghdl`, `TARGET ?= sim_basic`).

```bash
make help                 # variables, rules and target list (mk/targets.txt)
make sim_basic            # run one target (log in log/)
make nonreg_sim           # run every sim_* target
make lint_ghdl            # GHDL -Wall lint (make nonreg_lint: every lint_* target)
make lint_ghdl_synth_default   # GHDL -Wall lint + ghdl --synth -Wall check of one configuration
make clean                # remove build/
```

Equivalent FuseSoC command:

```bash
fusesoc --cores-root . run --build-root build --target sim_basic asylum:component:PWM:1.0.0
```

Outside CI, GHDL writes a waveform `dut.fst`. CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs `sim_basic`.

## Synthesis

No vendor synthesis target (the `lint_ghdl_synth_*` targets check the RTL with `ghdl --synth`, see [Targets](#targets)). The HDL sources of the `default` target (`hdl/*.vhd` + generated CSR) contain no simulation-only construct. `pwm_core` uses `2 x PRESCALER_WIDTH + 3 x COUNTER_WIDTH + 1` flip-flops (prescaler counter, shadow ratio, PWM counter, shadow period and duty, output), a zero detector on the prescaler counter, an equality comparator (end of period) and a magnitude comparator (duty), plus the `clock_divider` counter when `STATIC_PRESCALER_RATIO > 1`; in `sbi_PWM` the CSR bank stores 25 bits (17 when `USER_DEFINE_PRESCALER = false`). `pwm_o` comes straight from a flip-flop and can drive a pad directly.

The pulse of `clock_divider` is a clock enable, not a clock: it is instantiated with `BYPASS_CBUFG = true` (no `cbufg` clock buffer, no clock resource, no generated clock), which needs `asylum:component:clock_divider` 2.1.0 or later.

## Design Notes

### Timing

With `T = S x (ratio + 1)` clock cycles per tick (S = `STATIC_PRESCALER_RATIO`, ratio = `prescaler`, or `PRESCALER_RATIO` when `USER_DEFINE_PRESCALER = false`):

- PWM period = `(period + 1) x T` clock cycles, so `f_pwm = f_clk / ((period + 1) x (ratio + 1) x S)`
- high phase = `duty x T` clock cycles when `duty <= period`, the whole period when `duty > period`
- duty cycle = `duty / (period + 1)`

```
  S = 1, ratio = 1 (T = 2 clock cycles), period = 3 (4 ticks), duty = 2

  counter : |  0  |  1  |  2  |  3  |  0  |  1  |  2  |  3  |
             ___________             ___________
  pwm_o   : /           \___________/           \___________
            |<- duty  ->|
            |<------ period ------->|
```

Examples with a 50 MHz clock:

| Use | STATIC_PRESCALER_RATIO | prescaler | period | PWM frequency | Duty step |
|-----|------------------------|-----------|--------|---------------|-----------|
| Reset values (LED dimming) | 1 | 194 (`0xC2`) | 255 | 1001.6 Hz | 1/256 |
| Motor | 1 | 9 | 249 | 20 kHz | 1/250 |
| Maximum resolution, fastest | 1 | 0 | 255 | 195.3 kHz | 1/256 |
| Slowest without static prescaler | 1 | 255 | 255 | 762.9 Hz | 1/256 |
| Servo (pulse 1 to 2 ms: duty 10 to 20) | 20 | 249 | 199 | 50 Hz | 100 us |

100 % needs `duty > period`, so `period <= 254`. Without static prescaler the lowest PWM frequency is `f_clk / 65536` (762.9 Hz at 50 MHz): a lower frequency needs `STATIC_PRESCALER_RATIO > 1` (all the frequencies are then divided by S, the duty resolution is unchanged).

### Enable

- `cfg.enable = 0`: the counter is cleared, `pwm_o` is low (one clock cycle after the write), and the shadow registers follow the CSR.
- `cfg.enable = 1`: the first PWM period starts with its high phase on the first pulse of the static prescaler after the write (one clock cycle after the write when `STATIC_PRESCALER_RATIO = 1`, at most S clock cycles after), using the values written before the enable. Its first tick lasts `T` cycles like the others. The static prescaler runs freely: the edges of `pwm_o` are aligned on its pulses.

Typical sequence: write `prescaler`, `period`, `duty`, then `cfg = 0x01`.

### Configuration Update

`prescaler`, `period` and `duty` are copied into the shadow registers of `pwm_core` on the last tick of each PWM period (and continuously while the PWM is disabled). A write is therefore taken into account at the start of the next PWM period:

- the current pulse is never truncated nor doubled (duty changed during the high or the low phase);
- the current period is never extended nor shortened, and the counter never goes beyond the period in use (period decreased below the current count);
- all the ticks of a PWM period have the same duration (prescaler changed during a period).

Each register is copied independently: if a PWM period ends between two writes (for example `period` then `duty`), one period uses the new `period` with the old `duty`. To change several values at once without such an intermediate period, write them with `cfg.enable = 0` (the PWM restarts from the beginning of a period).

## Directory Structure

```
asylum-component-pwm/
├── PWM.core                # FuseSoC core (asylum:component:PWM)
├── Makefile                # Common Asylum Makefile (FuseSoC wrapper)
├── mk/
│   ├── defs.mk             # FILE_CORE, default TARGET and TOOL
│   └── targets.txt         # Target list (generated from the .core)
├── .github/workflows/
│   └── ci.yml              # CI jobs (generated by make ci_generate)
├── doc/
│   ├── PWM.drawio          # Block diagram
│   └── Makefile            # PNG export (drawio CLI)
├── hdl/
│   ├── pwm_pkg.vhd
│   ├── pwm_core.vhd
│   ├── sbi_PWM.vhd
│   └── csr/
│       ├── PWM.hjson       # Register description (source)
│       ├── PWM_csr.vhd     # Generated
│       ├── PWM_csr_pkg.vhd # Generated
│       ├── PWM_csr.md      # Generated
│       └── PWM_csr.h       # Generated
├── sim/
│   └── basic/              # tb_PWM.vhd (UVVM, SBI BFM)
└── syn/ghdl/
    ├── sbi_PWM_synth_top.vhd  # Lint / synthesis check top (sbi_PWM, flat SBI ports)
    ├── ghdl_synth.sh       # pre_run hook of lint_ghdl_synth_*: includes ghdl_synth.mk in the edalize Makefile
    └── ghdl_synth.mk       # ghdl_synth rule (ghdl --synth with the options of the target), prerequisite of run
```

## Dependencies

| Core | Used by (fileset) | Purpose |
|------|-------------------|---------|
| `asylum:component:clock_divider` (>= 2.1.0) | `hdl` | Static prescaler (`clock_divider`, pulse mode, `BYPASS_CBUFG = true`) of `pwm_core` |
| `asylum:utils:generators` | `hdl` | regtool generator and CSR building block (`csr_reg`) |
| `asylum:utils:pkg` | `hdl` | Common packages (`sbi_pkg`, ...) |
| `bitvis:verification:uvvm` | `sim_basic` | UVVM utility library and SBI VIP (testbench only) |
