; vector for I2C interrupt, needed because NOIV is used to prevent ISR vector table because USB interrupts use autovector
; see http://www.keil.com/support/man/docs/c51/c51_le_interruptfuncs.htm
; and FX2 TRM table 4-9

EXTRN CODE (ISR_I2C)

CSEG    AT      004Bh ; from the FX2 TRM table 4-9 interrupt vector address
        LJMP    ISR_I2C
END