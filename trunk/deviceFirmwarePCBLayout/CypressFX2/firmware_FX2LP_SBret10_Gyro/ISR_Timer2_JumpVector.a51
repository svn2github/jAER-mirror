; vector for timer2 interrupt for IMU timestamps, needed because NOIV is used to prevent ISR vector table because USB interrupts use autovector
; see http://www.keil.com/support/man/docs/c51/c51_le_interruptfuncs.htm
; and FX2 TRM table 4-9

EXTRN CODE (ISR_Timer2)

CSEG    AT      002BH ; from the FX2 TRM table 4-9 interrupt vector address
        LJMP    ISR_Timer2
END