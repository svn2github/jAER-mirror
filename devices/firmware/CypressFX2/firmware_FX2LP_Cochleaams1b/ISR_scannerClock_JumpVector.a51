
; this is jump vector for timer2 interrupt
; it is necessary because jump vectors are turned off by NOIV pragma, used by cypress frameworks
; see http://www.keil.com/support/docs/1139.htm


EXTRN CODE (ISR_scannerClock)

CSEG    AT      002BH ; from fx2 manual, naps to interrupt 5 in c51
        LJMP    ISR_scannerClock
END
