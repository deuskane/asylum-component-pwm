# PWM
CSR for PWM

| Address | Registers |
|---------|-----------|
|0x0|cfg|
|0x1|prescaler|
|0x2|period|
|0x3|duty|

## 0x0 cfg
PWM Configuration Register

### [0:0] enable
0 : PWM is disabled (counter cleared, output low), 1 : PWM is enabled, the first period starts with the high phase (up to STATIC_PRESCALER_RATIO CLK cycles after the write)

## 0x1 prescaler
PWM Clock Prescaler. A tick of the PWM counter lasts STATIC_PRESCALER_RATIO*(prescaler+1) CLK cycles (STATIC_PRESCALER_RATIO : generic of sbi_PWM, 1 by default). Taken into account at the start of the next PWM period

### [7:0] ratio
Number of steps of the static prescaler minus one of a tick (CLK cycles minus one if STATIC_PRESCALER_RATIO = 1)

## 0x2 period
PWM Period. The PWM period is (period+1) ticks, i.e. (period+1)*STATIC_PRESCALER_RATIO*(prescaler+1) CLK cycles. Taken into account at the start of the next PWM period

### [7:0] value
Number of ticks minus one of the PWM period

## 0x3 duty
PWM Duty Cycle. The output is high during the first duty ticks of each PWM period : 0 : always low, greater than period : always high. Taken into account at the start of the next PWM period

### [7:0] value
Number of ticks of the high phase

