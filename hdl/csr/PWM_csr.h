#ifndef PWM_REGISTERS_H
#define PWM_REGISTERS_H

#include <stdint.h>

// Module      : PWM
// Description : CSR for PWM
// Width       : 8

//==================================
// Register    : cfg
// Description : PWM Configuration Register
// Address     : 0x0
//==================================
#define PWM_CFG 0x0

// Field       : cfg.enable
// Description : 0 : PWM is disabled (counter cleared, output low), 1 : PWM is enabled, the first period starts with the high phase (up to STATIC_PRESCALER_RATIO CLK cycles after the write)
// Range       : [0]
#define PWM_CFG_ENABLE      0
#define PWM_CFG_ENABLE_MASK 1

//==================================
// Register    : prescaler
// Description : PWM Clock Prescaler. A tick of the PWM counter lasts STATIC_PRESCALER_RATIO*(prescaler+1) CLK cycles (STATIC_PRESCALER_RATIO : generic of sbi_PWM, 1 by default). Taken into account at the start of the next PWM period
// Address     : 0x1
//==================================
#define PWM_PRESCALER 0x1

// Field       : prescaler.ratio
// Description : Number of steps of the static prescaler minus one of a tick (CLK cycles minus one if STATIC_PRESCALER_RATIO = 1)
// Range       : [7:0]
#define PWM_PRESCALER_RATIO      0
#define PWM_PRESCALER_RATIO_MASK 255

//==================================
// Register    : period
// Description : PWM Period. The PWM period is (period+1) ticks, i.e. (period+1)*STATIC_PRESCALER_RATIO*(prescaler+1) CLK cycles. Taken into account at the start of the next PWM period
// Address     : 0x2
//==================================
#define PWM_PERIOD 0x2

// Field       : period.value
// Description : Number of ticks minus one of the PWM period
// Range       : [7:0]
#define PWM_PERIOD_VALUE      0
#define PWM_PERIOD_VALUE_MASK 255

//==================================
// Register    : duty
// Description : PWM Duty Cycle. The output is high during the first duty ticks of each PWM period : 0 : always low, greater than period : always high. Taken into account at the start of the next PWM period
// Address     : 0x3
//==================================
#define PWM_DUTY 0x3

// Field       : duty.value
// Description : Number of ticks of the high phase
// Range       : [7:0]
#define PWM_DUTY_VALUE      0
#define PWM_DUTY_VALUE_MASK 255

//----------------------------------
// Structure PWM_t
//----------------------------------
typedef struct {
  uint8_t cfg; // 0x0
  uint8_t prescaler; // 0x1
  uint8_t period; // 0x2
  uint8_t duty; // 0x3
} PWM_t;

#endif // PWM_REGISTERS_H
