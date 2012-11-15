NAME spiwritebyte
;
;
; This routine takes a byte variable and
; shifts it out with the clock starting from the msb and ending with the lsb.
; worst case bit rate of 250kHz
; byte rate of 35 kHz

; adapted from Cypress Software SPI example for EZ-USB (NOT the FX2) spiwrite.a51 4-19-00 ott]
; difference is that FX2 has ports at 0x80 0x90 etc and not in XRAM. 
; see FX2 TRM Section 15.3 "About SFRs"
; 
; also, this routine changes bit, then clocks up and down, unlike real SPI that changes bit and clock at the same time

?PR?SPIWRITEBYTE?MODULE segment code
?DT?SPIWRITEBYTE?MODULE segment data overlayable

PUBLIC _spiwritebyte, ?_spiwritebyte?BYTE

rseg ?DT?SPIWRITEBYTE?MODULE
?_spiwritebyte?BYTE:
d: ds 1

rseg ?PR?SPIWRITEBYTE?MODULE

;this is DATA location of SFR for port E
; Port E is NOT bit addressable
; see biasgen.h for bits in port E for clock/data/powerdown/latch
sfr IOE     = 0xB1;

; ends with leaving clock in a polarity that may matter for biasgen shift registers

_spiwritebyte:

; first load some registers with bit patterns to write to port E to set and clear clock and data bit

mov R6, #8 ;set up loop for 8 bits
mov A, #11100111b
anl A, IOE
mov R1, A 		; R1 clears clock and data

mov A, #00001000b
orl A, IOE
mov R2, A		
mov A, #11101111b
anl A, R2
mov R2, A		; R2 clears clock and sets data

mov A, #00010000b
orl A, IOE
mov R3, A
mov A, #11110111b
anl A, R3
mov R3, A		; R3 sets clock and clears data

mov A, #00011000b
orl A, IOE
mov R4, A		; R4 sets clock and data    

loop:
mov A, R7 ;move input data in R7 to send to A -- R7 is register that has argument
rlc A ;rotate left through carry
mov R7, A ;save rotated for later
jc highbit ;if carry bit is high jump (jump if carry bit (msb) is set)

; bit is low
; sets bit=0, clock=0, then sets clock=1, and then clock=0 again.
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

highbit: ; comes here if bit is 1
; sets bit=1, clock=0, then sets clock=1, and then clock=0 again.
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

ret
end
 