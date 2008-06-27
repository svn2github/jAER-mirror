NAME spiwritebyte
;
; adapted from Cypress Software SPI example for EZ-USB (NOT the FX2) spiwrite.a51 4-19-00 ott]
; difference is that FX2 has ports at 0x80 0x90 etc and not in XRAM. plus port A is bit addressable,
; so we can just set and clear the bits and/or we don't need to use movx for xdata access
; see FX2 TRM Section 15.3 "About SFRs"
; 
; also, this routine changes bit, then clocks up and down, unlike real SPI that changes bit and clock at the same time

; This routine takes a byte variable and
; shifts it out with the clock
; worst case bit rate of 250kHz
; byte rate of 35 kHz
;
; port is defined below on first line (mov instruction)
; tobi redefined to be port A

?PR?SPIWRITEBYTE?MODULE segment code
?DT?SPIWRITEBYTE?MODULE segment data overlayable

PUBLIC _spiwritebyte, ?_spiwritebyte?BYTE

rseg ?DT?SPIWRITEBYTE?MODULE
?_spiwritebyte?BYTE:
d: ds 1

rseg ?PR?SPIWRITEBYTE?MODULE

; following define clock and bit locations and polarities
; see the SPIUtil.c for biasgen bit locations
; from msb to lsb of nibble: bit, clock

OUTPORT DATA 80H ; this is DATA location of SFR for port A

;; all the bits are bit-addressable
CLKBIT BIT OUTPORT.2; this is biasClock on PA2
DATABIT BIT OUTPORT.3 ; this is biasBitIn on PA3


; ends with leaving clock in a polarity that may matter for biasgen sivillotti shift registers

_spiwritebyte:

mov R6, #8 ;set up loop for 8 bits
loop:
mov A, R7 ;move data to send to A -- R7 is register that has argument
rlc A ;rotate left through carry
mov R7, A ;save rotated for later
jc highbit ;if carry bit is high jump (jump if carry bit (msb) is set)
; bit is low
clr DATABIT
sjmp skip ;skip setting bit high
highbit:
setb DATABIT
skip:
nop
nop
nop
nop
setb CLKBIT
nop
nop
nop
nop
clr CLKBIT
nop ;may need this to stretch clock high time
nop
nop
nop
djnz R6, loop ;repeat eight times
;clr DATABIT ; end with databit always low (shouldn't need this, but now databit state depends on last data)
ret
end
 