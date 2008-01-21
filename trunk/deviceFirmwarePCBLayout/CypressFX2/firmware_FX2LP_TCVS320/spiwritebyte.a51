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

;IOE DATA 80H ; this is DATA location of SFR for port E
sfr IOE     = 0xB1;
;; port E bits are NOT bit addressable, so we need to read, AND, and then write the port
;CLKBIT BIT IOE.2; this is biasClock on PA2
;DATABIT BIT IOE.3 ; this is biasBitIn on PA3


; ends with leaving clock in a polarity that may matter for biasgen sivillotti shift registers

_spiwritebyte:

mov R6, #8 ;set up loop for 8 bits
mov A, #11100111b
anl A, IOE
mov R1, A
mov A, #00001000b
orl A, IOE
mov R2, A
mov A, #11101111b
anl A, R2
mov R2, A
mov A, #00010000b
orl A, IOE
mov R3, A
mov A, #11110111b
anl A, R3
mov R3, A
mov A, #00011000b
orl A, IOE
mov R4, A    
loop:
mov A, R7 ;move data to send to A -- R7 is register that has argument
rlc A ;rotate left through carry
mov R7, A ;save rotated for later
jc highbit ;if carry bit is high jump (jump if carry bit (msb) is set)
; bit is low
mov IOE, R1 ; data bit=0 and clock=0  ;  clr DATABIT
nop
nop
nop
nop
mov IOE, R3  ;setb CLKBIT
nop
nop
nop
nop
mov IOE, R1 ; databit=1, clock=0   ;clr CLKBIT
sjmp skip ;skip setting bit high
highbit:
mov IOE, R2 ; databit=1, clock=0 ;setb DATABIT 
nop
nop
nop
nop
mov IOE, R4  ;setb CLKBIT
nop
nop
nop
nop
mov IOE, R2 ; databit=1, clock=0   ;clr CLKBIT
skip:
nop ;may need this to stretch clock high time
nop
nop
nop
djnz R6, loop ;repeat eight times
;clr DATABIT ; end with databit always low (shouldn't need this, but now databit state depends on last data)
ret
end
 