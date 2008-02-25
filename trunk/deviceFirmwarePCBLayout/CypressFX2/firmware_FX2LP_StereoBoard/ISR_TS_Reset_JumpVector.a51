
; this is jump vector for timer1 interrupt
; it is necessary because jump vectors are turned off by NOIV pragma, used by cypress frameworks
; see http://www.keil.com/support/docs/1139.htm

; reset timestamp interrupt not necessary anymore with new CPLD firmware which uses special event for timestamp resetting
;EXTRN CODE (ISR_TSReset)    

;CSEG    AT      0003H
;        LJMP    ISR_TSReset
;END

EXTRN CODE (ISR_MissedEvent)

CSEG    AT      0013H
        LJMP    ISR_MissedEvent
END
