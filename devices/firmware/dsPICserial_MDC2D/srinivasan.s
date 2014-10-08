/*
 * Copyright June 13, 2011 Andreas Steiner, Inst. of Neuroinformatics, UNI-ETH Zurich
 * This file is part of uart_MDC2D.

 * uart_MDC2D is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * uart_MDC2D is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with uart_MDC2D.  If not, see <http://www.gnu.org/licenses/>.
 */
 
 
/*! \file srinivasan.s
 * assembler implementation of Srinivasan algorithm; see
 * README.txt
 */
 
#include <p33Fxxxx.h>
;#define CORCON 0x44

;TODO make width/height adjustable
;TODO check that data is in bss

	.section xdata,xmemory,bss
	; X space : 0x0800-0x027FF
fx:	.space 800,0
dfx:.space 800,0

	.section ydata,ymemory,bss
	; Y space : 0x2800-0x047FF
	
fy:	.space 800,0
dfy:.space 800,0

	
	.text
	
	.global _srinivasan2D_16bit

_srinivasan2D_16bit:

	; W8-15 should be pushed onto the stack -- W0-7 can be used freely
	; arguments in W0,W1, ...

	PUSH w8
	PUSH w9
	PUSH w10
	PUSH w11
	PUSH w12
	PUSH w13
	
	
	; -------------------------------------------------------
	; initialize
	; -------------------------------------------------------
	
	LNK #0x0E
	; [w14+ 0] = &dx/2
	; [w14+ 2] = &dy/2
	; [w14+ 4] = abs d/4
	; [w14+ 6] = sign d/4
	; [w14+ 8] = sign a
	; [w14+10] = # of bits nominator/denominator are shifted
	; [w14+12] = # of bits a,b,c,d/2,e/2 are shifted
	
	MOV w2,[w14]
	MOV w3,[w14+2]
	MOV w4,[w14+12]

	; init
	BSET CORCON,#0			; enable integer multiply
	BCLR CORCON,#12			; DSP multiplies signed
	

	; -------------------------------------------------------
	; calculate "shifted images"
	; -------------------------------------------------------
	
	; calculate the fx, fy, fdx, fdy
							; w0= f1(x,y)
							; w1= f2(x,y)
	MOV #fx,w2				; w2= fx(x,y)
	MOV #fy,w3				; w3= fy(x,y)
	MOV #dfx,w4				; w4= dfx(x,y)
	MOV #dfy,w5				; w5= dfy(x,y)
	MOV w0,w6
	ADD #(1*2),w6			; w6= f1(x+1,y)
	MOV w0,w7
	SUB #(1*2),w7			; w7= f1(x-1,y)
	MOV w0,w8
	;WIDTH
	ADD #(20*2),w8			; w8= f1(x,y+1)
	MOV w0,w9
	;WIDTH
	SUB #(20*2),w9			; w9= f1(x,y-1)
	
	; skip the first row and the first pixel in the second row
	MOV #(2*21),w10
	
	;HEIGHT
	DO #(18-1),loopy_prepare

	; skip bordering pixels
	ADD w10,w0,w0
	ADD w10,w1,w1
	ADD w10,w2,w2
	ADD w10,w3,w3
	ADD w10,w4,w4
	ADD w10,w5,w5
	ADD w10,w6,w6
	ADD w10,w7,w7
	ADD w10,w8,w8
	ADD w10,w9,w9
	
	;WIDTH
	DO #(18 -1),loopx_prepare
	
	; SUB Wb,Ws,Wd : Wd=Wb-Bs
	MOV [w1++],w10			; f2->w10
	SUB w10,[w0],[w4++]		; dfx = f2-f1
	SUB w10,[w0++],[w5++]	; dfy = f2-f1
	MOV [w7++],w10			; f1(x-1,y)->w10
	SUB w10,[w6++],[w2++]	; fx  = f(x-1,y) - f(x+1,y)
	MOV [w9++],w10			; f1(x,y-1)->w10
loopx_prepare:
	SUB w10,[w8++],[w3++]	; fy  = f(x,y-1) - f(x,y+1)
	
	
	
loopy_prepare:
	; skip last pixel of current row and first of next row
	MOV #(2*2),w10


	; -------------------------------------------------------
	; calculate a,b,d/2,e/2
	; -------------------------------------------------------
	
	; these are the sign bits for the final addition/subtraction
	MOV #(0xFFFF),w11		; w11= sign(-d*b/a/2)
	MOV #(0xFFFF),w12		; w12= sign(-b*b/a)
	MOV #1,w13				; w13= sign b

	; d = sum(dfy*fx)
	MOV #fx,w8
	ADD #(21*2),w8			; w8 = fx[21]
	MOV #dfy,w10
	ADD #(21*2),w10			; w10 = fy[21]
	CLR a,[w8]+=2,w4,[w10]+=2,w5	; clear ACCB & prefetch 1st value
	REPEAT #(400-21-21 -1)	; skip border pixels (1st/last row/column)
	MAC w4*w5,a,[w8]+=2,w4,[w10]+=2,w5
	
	MOV #1,w0				; w0=sign d/2 (pretend positive)
	SAC a,#0,w5
	BTST.Z w5,#15			; d/2 negative ?
	BRA z,d_not_neg
	NEG w0,w0				; w0=sign d
	NEG w11,w11				; switch sign in numerator
	NEG a					; and sign of d
d_not_neg:

	CALL shiftacc
	SFTAC a,#1				; use d/2 instead of d
	SAC a,#0,w5
	CP0 w5					; must certainly be <17bits
	BRA nz,overflow_d
	CALL store_acca_w4w5_pos
	BTST.Z w4,#15			; must be <=15bits
	BRA nz,overflow_d

	MOV w4,[w14+4]			; store abs d/2 for later use
	MOV w0,[w14+6]			; store sign d/2 for later use
	MOV w4,w1				; w1= abs(d/2)
	
	
	; b = sum(fx*fy)
	MOV #fx,w8
	ADD #(21*2),w8			; w8 = fx[21]
	MOV #fy,w10
	ADD #(21*2),w10			; w10 = fy[21]
	CLR a,[w8]+=2,w4,[w10]+=2,w5	; clear ACCA & prefetch 1st value
	REPEAT #(400-21-21 -1)	; skip border pixels (1st/last row/column)
	MAC w4*w5,a,[w8]+=2,w4,[w10]+=2,w5
	
	SAC a,#0,w5
	BTST.Z w5,#15			; b negative ?
	BRA z,b_not_neg
	NEG w11,w11				; switch sign in numerator
	NEG w13,w13				; switch sign b
	NEG a					; and sign of b
b_not_neg:
	CALL shiftacc
	CALL store_acca_w4w5_pos
	CP0 w5
	BRA nz,overflow_b		; unsigned b must be <=16bit
	MOV w4,w2				; w2= abs(b)
	
	; a = sum(fx*fx)
	MOV #fx,w8
	ADD #(21*2),w8			; w8 = fx[21]
	CLR a,[w8]+=2,w4		; clear ACCA & prefetch 1st value
	REPEAT #(400-21-21 -1)	; skip border pixels (1st/last row/column)
	MAC w4*w4,a,[w8]+=2,w4
	
	SAC a,#0,w5
	MOV #1,w0				; w0=sign a
	BTST.Z w5,#15			; a negative ?
	BRA z,a_not_neg
	NEG w11,w11				; switch sign in numerator
	NEG w12,w12				; and denominator
	NEG w0,w0
	NEG a					; and sign of a
a_not_neg:
	CALL shiftacc
	CALL store_acca_w4w5_pos
	CP0 w5
	BRA nz,overflow_a		; unsigned b must be <=16bit
	CP0 w4
	BRA z,singular_a		; error if a==0
	MOV w4,w3				; w3= abs(a)
	MOV w0,[w14+8]			; store sign(a) for later use

	; e = sum(dfx*fy)
	MOV #dfx,w8
	ADD #(21*2),w8			; w8 = dfx[21]
	MOV #fy,w10
	ADD #(21*2),w10			; w10 = fy[21]
	CLR a,[w8]+=2,w4,[w10]+=2,w5	; clear ACCA & prefetch 1st value
	REPEAT #(400-21-21 -1)	; skip border pixels (1st/last row/column)
	MAC w4*w5,a,[w8]+=2,w4,[w10]+=2,w5
	CALL shiftacc
	SFTAC a,#1				; use e/2 instead of e
	
	
	; -------------------------------------------------------
	; calculate c,dy/4=(e/2-d/2*b/a) / (c-b*b/a)
	; -------------------------------------------------------
	
	; calculate nominator= e/2-d/2*b/a
	MUL.UU w1,w2,w4			; w4(LSB)-w5(MSB) = abs(d/2)*b
	REPEAT #0x21
	DIV.UD w4,w3
	BTST.Z w0,#15
	BRA nz,overflow_db2a	; result must be <=15bit (for signed MAC)
	MOV w0,w4
	MOV w11,w5
	MAC w4*w5,a				; add d/2*b/a to e/2 (including sign)
							; now acca=nominator
	
	MOV #1,w11				; w11=sign(nominator); assume positive
	SAC a,#0,w5
	BTST.Z w5,#15
	BRA z,nominator_pos
	NEG w11,w11				; switch signs if nominator was negative
	NEG a
nominator_pos:
	MOV #0,w4				; # of bits nominator was shifted
check_nominator:
	SAC a,#0,w5
	CP0 w5
	BRA z,nominator_in_range
	INC w4,w4
	SFTAC a,#1
	BRA check_nominator
nominator_in_range:
	MOV w4,[w14+10]			; store # of bits nominator was shifted
	CALL store_acca_w4w5_pos
	MOV w4,w9				; w9 = nominator
	
	; c = sum(fy*fy)
	MOV #fy,w10
	ADD #(21*2),w10			; w10 = fy[21]
	CLR a,[w10]+=2,w5		; clear ACCA & prefetch 1st value
	REPEAT #(400-21-21 -1)	; skip border pixels (1st/last row/column)
	MAC w5*w5,a,[w10]+=2,w5

	CALL shiftacc

	; (still true : w2=b, w3=a, w12=sign b*b/a)
	; calculate denominator=c-b*b/a
	MUL.UU w2,w2,w4			; w4(LSB)-w5(MSB) = b*b
	REPEAT #0x21
	DIV.UD w4,w3
	MOV w0,w4
	MOV w12,w5
	MAC w4*w5,a				; add b*b/a to c
							; now acca=denominator
							
	SAC a,#0,w5
	BTST.Z w5,#15
	BRA z,denominator_pos
	NEG w11,w11				; switch sign of nominator
	NEG a					; and denominator
denominator_pos:
	MOV [w14+10],w4			; restore # of bits nominator was shifted
	SFTAC a,w4				; shift denominator by same amount
check_denominator:
	SAC a,#0,w5
	CP0 w5
	BRA z,denominator_in_range
shift_nominator_denominator:
	SFTAC a,#1				; shift denominator
	LSR w9,#1,w9			; shift nominator (unsigned 16bit)
	BRA check_denominator
denominator_in_range:
	CALL store_acca_w4w5_pos
	CP0 w4					; w4=denominator
	BRA z,singular_denominator


	CLR w8					; clear LSB(w8); MSB=w9
	REPEAT #0x21
	DIV.UD w8,w4			; divide nominator(w14-15)/denominator(w4)
							; now w0=dy/4 -- w1=remainder (discarded)
							; w11=sign dy/4
	BTST.Z w0,#15
	BRA nz,overflow_dy		; abs(dy/4) must be < 0.5
	MOV w0,w6				; w6=abs dy/4
	
	
	
	; -------------------------------------------------------
	; calculate dx/4=(d/2-b*dy/4)/a
	; -------------------------------------------------------

	; (still true : w2=b, w3=a, w13=sign b)

	; restore d/2 into ACCA
	MOV [w14+4],w4			; abs d/2
	MOV [w14+6],w5			; sign d/2
	MPY w4*w5,a
	SFTAC a,-#0x10			; left shift d/2 16bits
	; subtract b*dy/2...
	MOV w6,w4
	MOV w2,w5
	ADD w13,w11,w0			; test (sign dy/4)*(sign b)
	BRA z,add_bdy2
sub_bdy2:
	MSC w4*w5,a				; acca=d/2-b*dy/4
	BRA divide_dx
add_bdy2:
	MAC w4*w5,a				; acca=d/2-b*dy/4
	
divide_dx:
	MOV [w14+8],w12			; w12=sign dx/4 -- presume same sign as a
	SAC a,#0,w5
	BTST.Z w5,#15
	BRA z,dx_same_sign_as_a
	NEG w12,w12				; switch sign of dx/4
	NEG a
dx_same_sign_as_a:
	CALL store_acca_w4w5_pos ; w4(LSB)-w5(MSB)= d/2-b*dy/4
	
	REPEAT #0x21
	DIV.UD w4,w3
	REPEAT #0x21
	DIV.UD w4,w3			; w0=(d/2-b*dy/4)/a =dx/4 -- w1=remainder
	BTST.Z w0,#15
	BRA nz,overflow_dx		; abs(dx/4) must be <= 15bits
	

	; -------------------------------------------------------
	; store results
	; -------------------------------------------------------
	
	; registers :
	;  w0=abs dx/4    w12=sign dx/4
	;  w6=abs dy/4    w11=sign dy/4
	; stack :
	;  [w14+ 0] = &dx/2
	;  [w14+ 2] = &dy/2
    ; 'conversion' :
    ;  up to here d[xy]/4 was calculated; since it's the truncated
    ;  value of an integer-division, it will shift 1bit to the
    ;  left when interpreted as a Q15 fractional...
	MOV [w14+2],w1			; where dy/2 shall be stored
	BTST.Z w11,#15
	BRA z,store_dy
	NEG w6,w6				; fix sign of dy/2
store_dy:
	MOV w6,[w1]

	MOV [w14],w1			; where dx/2 shall be stored
	BTST.Z w12,#15
	BRA z,store_dx
	NEG w0,w0				; fix sign of dx/2
store_dx:
	MOV w0,[w1]
	


	; -------------------------------------------------------
	; return to caller
	; -------------------------------------------------------

cleanup:
	ULNK
	; restore register
	POP w13
	POP w12
	POP w11
	POP w10
	POP w9
	POP w8
	
	RETURN



	; -------------------------------------------------------
	; error 'handlers'
	; -------------------------------------------------------

overflow_dx:
	MOV #0x01,w0
	BRA store_error
overflow_dy:
	MOV #0x02,w0
	BRA store_error

singular_a:
	MOV #0x03,w0
	BRA store_error
singular_denominator:
	MOV #0x04,w0
	BRA store_error

overflow_a:
	MOV #0x12,w0
	BRA store_error
overflow_b:
	MOV #0x13,w0
	BRA store_error
overflow_d:
	MOV #0x14,w0
	BRA store_error
overflow_db2a:
	MOV #0x15,w0
	BRA store_error
overflow_bdya:
	MOV #0x16,w0
	BRA store_error
	
store_error:
	MOV #0xFFFF,w1
	MOV [w14],w2
	MOV w1,[w2]			; dx=0xFFFF indicates ERROR
	MOV [w14+2],w2
	MOV w0,[w2]			; dy tells what error occured
	
	BRA cleanup




	; -------------------------------------------------------
	; utility functions
	; -------------------------------------------------------


; stores lowest 32bit of accumulator A into w4(LSB)-w5(MSB)
; use BTST.Z w5,#15 for testing sign of w4(LSB)-w5(MSB)
store_acca_w4w5:
	SAC a,#0,w5
	BTST.Z w5,#15
	BRA z,store_acca_w4w5_pos
	
store_acca_w4w5_neg:
	NEG a					; ACCA=-ACCA
	CALL store_acca_w4w5_pos
	
	COM w5,w5				; negate : w4(LSB)-w5(MSB)
	COM w4,w4				; first bit invert both
	INC w4,w4				; than add 1 to LSB of w4
	BRA NC,dont_inc_w5		; w5 needs only be incremented if
	INC w5,w5				; overflow when w4 was incremented
dont_inc_w5:
	RETURN


; stores lowest 32bit of accumulator A into w4(LSB)-w5(MSB)
; only POSITIVE ACCA yields valid results !
store_acca_w4w5_pos:
	PUSH w7
	MOV #1,w7
	RRNC w7,w7				; w7=0x8000
	
	PUSH CORCON
	BSET CORCON,#12			; DSP multiplies unsigned
	BCLR CORCON,#5			; disable saturation DSP->wX

	SAC a,#0,w5				; move upper 16bits into w5
	
	MSC w5*w7,a
	MSC w5*w7,a				; remove upper 16bits
	SFTAC a,#-16
	SAC a,#0,w4				; move lower 16bits into w4
	
	POP CORCON
	POP w7
	RETURN

shiftacc:
	PUSH w0
	MOV [w14+12],w0
	SFTAC a,w0
	POP w0
	RETURN
