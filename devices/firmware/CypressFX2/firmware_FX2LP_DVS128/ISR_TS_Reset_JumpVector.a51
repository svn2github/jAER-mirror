
; this is jump vector for timer1 interrupt
; it is necessary because jump vectors are turned off by NOIV pragma, used by cypress frameworks
; see http://www.keil.com/support/docs/1139.htm

;EXTRN CODE (ISR_TSReset) this interrupt is not used

;CSEG    AT      0003H
;        LJMP    ISR_TSReset
;END

EXTRN CODE (ISR_MissedEvent)

CSEG    AT      0013H
        LJMP    ISR_MissedEvent
END
