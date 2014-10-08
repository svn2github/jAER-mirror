
;; just some assembler snippets that might be useful...


	
init_dsp:
	BSET CORCON,#0			; enable integer multiply
	BSET CORCON,#12			; DSP multiplies unsigned
	BCLR CORCON,#5			; disable data space write saturation
	;? SATA/B, ACCSAT
	RETURN
	

	
test_q16_overflow:
	BCLR CORCON,#0			; enable Q15 multiply
	BCLR CORCON,#12			; DSP multiplies unsigned
	
test_mac_shift:

	MOV #0x0234,w4
	CLR a
	MAC w4*w4,a				; 0x4da90

	MOV #0x1234,w4
	CLR a
	MAC w4*w4,a				; 0x014b 5a90
	
	CALL store_acca_w4w5
	
	MUL.UU w4,w4,w0			; MSB in w1
	
	mov #dw1,w13
	MOV #wx3,w8
	MOV #wy3,w10
	MOVSAC a,[w8]+=6,w4,[w10]+=6,w4,[w13]+=2
	
	SAC a,#0,w0				; stores upper word (0x014b)
	SAC a,#0,w0				; stores upper word (0x014b)
	SAC a,#4,w0				; stores shifted upper word (0x014)
	SAC a,#-1,w0			; stores 0x02 ??
	SAC a,#-4,w0			; stores 0x02 ??
	SFTAC a,#-16			; left shift (0x004b 5a90 0000)

	MOV #sw1,w1				; move the ADDRESS of sw1 into w1
	MOV [w1++],w2
	MOV [w1],w3

	RETURN


test_divide:
	MOV #0x0001,w4
	MOV #0x1515,w6
	MOV #0x1010,w7
	CLR a
	MAC w4*w4,a
	MAC w6*w7,a
	CALL store_acca_w4w5
	
	REPEAT #0x21
	; calculates w4(LSB)-w5(MSB) / w7
	; stores the result in w0 and the remainder in w1
	; (e.g. w0=0x1515 and w1=0x0001)
	DIV.UD w4,w7
	
	RETURN
	
test_sub:
	MOV #fx,w0
	MOV #10,w1
	MOV #1,w2
	SUB w2,w1,w3			; w3=-9
	SUB w2,w1,[w0]			; fx[0]=-9
	RETURN
	
test_signed_mac:

	MOV #0x8000,w5
	MOV #0x0001,w6
	BSET CORCON,#12			; DSP multiplies unsigned
	CLR a
	MAC w5*w6,a				; a=0x00 0000 8000
	BCLR CORCON,#12			; DSP multiplies signed
	CLR a
	MAC w5*w6,a				; a=0xFF FFFF 8000

	; test signed multiply
	MOV #fx,w8
	MOV #fy,w10
	MOV #5,w0
	MOV w0,[w8]
	MOV #(-5),w0
	MOV w0,[w10]
	CLR w4
	CLR w5
	CLR       a,[w8]+=2,w4,[w10]+=2,w5
	MAC w4*w5,a,[w8]+=2,w4,[w10]+=2,w5
	
	MOV #(-0x0100),w4
	MOV #( 0x0880),w5
	CLR a
	MAC w4*w5,a
	CALL store_acca_w4w5

	MOV #( 0x0100),w4
	MOV #( 0x0880),w5
	CLR a
	MAC w4*w5,a
	CALL store_acca_w4w5

	RETURN
	
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

; stores lowest 32bit of accumulator into 
; w4(LSB)-w5(MSB)
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

