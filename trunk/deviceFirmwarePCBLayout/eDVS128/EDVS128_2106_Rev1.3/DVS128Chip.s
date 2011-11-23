	.dbfile ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
	.dbfile ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
	EXPORT _DVS128ChipInit
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
	.dbfunc e DVS128ChipInit _DVS128ChipInit fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_DVS128ChipInit:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R11,R12,R14}
	mov R11,R13
	.dbline -1
	.dbline 30
; #include "EDVS128_2106.h"
; 
; //#define DEFAULT_BIAS_SET		0			// "BIAS_DEFAULT"
; #define DEFAULT_BIAS_SET		1			// "BIAS_BRAGFOST"
; //#define DEFAULT_BIAS_SET		2			// "BIAS_FAST"
; //#define DEFAULT_BIAS_SET		3			// "BIAS_STEREO_PAIR"
; //#define DEFAULT_BIAS_SET		4			// "BIAS_MINI_DVS"
; 
; // *****************************************************************************
; extern unsigned char dataForTransmission[16];
; 
; // *****************************************************************************
; unsigned long biasMatrix[12];
; 
; // *****************************************************************************
; unsigned long enableEventSending;
; unsigned long newEvent;
; unsigned long x, y, p;
; 
; unsigned short eventBufferA[DVS_EVENTBUFFER_SIZE];		  // for event addresses
; unsigned long  eventBufferT[DVS_EVENTBUFFER_SIZE];		  // for event time stamps
; unsigned long eventBufferWritePointer;
; unsigned long eventBufferReadPointer;
; 
; #ifdef INCLUDE_PIXEL_CUTOUT_REGION
; unsigned long pixelCutoutMinX, pixelCutoutMaxX, pixelCutoutMinY, pixelCutoutMaxY;
; #endif
; 
; // *****************************************************************************
; void DVS128ChipInit(void) {
	.dbline 31
;   FGPIO_IOSET  = PIN_RESET_DVS;					// DVS array reset to high
	mov R4,#32768
	ldr R5,LIT_DVS128ChipInit+0
	str R4,[R5,#0]
	.dbline 32
;   FGPIO_IODIR |= PIN_RESET_DVS;					// DVS array reset pin to output
	ldr R4,LIT_DVS128ChipInit+4
	ldr R5,[R4,#0]
	orr R5,R5,#32768
	str R5,[R4,#0]
	.dbline 37
; 
; //  FGPIO_IOSET  = PIN_DVS_ACKN;				// ackn to high	   	  // let DVS handshake itself, only grab addresses from bus
; //  FGPIO_IODIR |= PIN_DVS_ACKN;				// ackn to output port
; 
;   FGPIO_IOSET  = (PIN_BIAS_LATCH);				// set pins to bias setup as outputs
	mov R4,#4096
	ldr R5,LIT_DVS128ChipInit+0
	str R4,[R5,#0]
	.dbline 38
;   FGPIO_IOCLR  = (PIN_BIAS_CLOCK | PIN_BIAS_DATA);
	ldr R4,LIT_DVS128ChipInit+8
	ldr R5,LIT_DVS128ChipInit+12
	str R4,[R5,#0]
	.dbline 39
;   FGPIO_IODIR |= (PIN_BIAS_LATCH | PIN_BIAS_DATA | PIN_BIAS_CLOCK);
	ldr R4,LIT_DVS128ChipInit+4
	ldr R5,LIT_DVS128ChipInit+16
	ldr R6,[R4,#0]
	orr R5,R6,R5
	str R5,[R4,#0]
	.dbline 41
; 
;   FGPIO_IOCLR  = PIN_RESET_DVS;					// DVS array reset to low
	mov R4,#32768
	ldr R5,LIT_DVS128ChipInit+12
	str R4,[R5,#0]
	.dbline 42
;   delayMS(10); 	 								// 10ms delay
	mov R0,#10
	bl _delayMS
	.dbline 43
;   FGPIO_IOSET  = PIN_RESET_DVS;					// DVS array reset to high
	mov R4,#32768
	ldr R5,LIT_DVS128ChipInit+0
	str R4,[R5,#0]
	.dbline 44
;   delayMS(1); 	 								// 1ms delay
	mov R0,#1
	bl _delayMS
	.dbline 46
; 
;   DVS128BiasLoadDefaultSet(DEFAULT_BIAS_SET);	// load default bias settings
	mov R0,#1
	bl _DVS128BiasLoadDefaultSet
	.dbline 47
;   DVS128BiasFlush();							// transfer bias settings to chip
	bl _DVS128BiasFlush
	.dbline 50
; 
;   // *****************************************************************************
;   eventBufferWritePointer=0;					// initialize eventBuffer
	mov R4,#0
	ldr R5,LIT_DVS128ChipInit+20
	str R4,[R5,#0]
	.dbline 51
;   eventBufferReadPointer=0;
	mov R4,#0
	ldr R5,LIT_DVS128ChipInit+24
	str R4,[R5,#0]
	.dbline 54
; 
;   // *****************************************************************************
;   enableEventSending=0;
	mov R4,#0
	ldr R5,LIT_DVS128ChipInit+28
	str R4,[R5,#0]
	.dbline 55
;   DVS128FetchEventsEnable(FALSE);
	mov R0,#0
	bl _DVS128FetchEventsEnable
	.dbline 68
; 
; #ifdef INCLUDE_PIXEL_CUTOUT_REGION
;   pixelCutoutMinX = 0;
;   pixelCutoutMaxX = 127;
;   pixelCutoutMinY = 0;
;   pixelCutoutMaxY = 127;
; #endif
; 
; 
;   // *****************************************************************************
;   // ** initialize timer 0 (1us clock)
;   // *****************************************************************************
;   T0_PR = (1000*PLL_CLOCK)-1;	// prescaler: run at 1ms clock rate
	ldr R4,LIT_DVS128ChipInit+32
	ldr R5,LIT_DVS128ChipInit+36
	str R4,[R5,#0]
	.dbline 69
;   T0_CTCR = 0x00;				// increase time on every T-CLK
	mov R4,#0
	ldr R5,LIT_DVS128ChipInit+40
	str R4,[R5,#0]
	.dbline 71
; 
;   T0_MCR  = 0x00;				// match register, no special action, simply count until 2^32-1 and restart
	mov R4,#0
	ldr R5,LIT_DVS128ChipInit+44
	str R4,[R5,#0]
	.dbline 72
;   T0_TC	  = 0;					// reset counter to zero
	mov R4,#0
	ldr R5,LIT_DVS128ChipInit+48
	str R4,[R5,#0]
	.dbline 73
;   T0_TCR  = 0x01;				// enable Timer/Counter 0
	mov R4,#1
	ldr R5,LIT_DVS128ChipInit+52
	str R4,[R5,#0]
	.dbline 79
; 
; 
;   // *****************************************************************************
;   // ** initialize timer 1 (system main clock)
;   // *****************************************************************************
;   T1_PR = 0;					// prescaler: run at main clock speed!
	mov R4,#0
	ldr R5,LIT_DVS128ChipInit+56
	str R4,[R5,#0]
	.dbline 80
;   T1_CTCR = 0x00;				// increase time on every T-CLK
	mov R4,#0
	ldr R5,LIT_DVS128ChipInit+60
	str R4,[R5,#0]
	.dbline 86
; 
; //  T1_MR0 = BIT(16);			// match register: count only up to 2^16 = 0..65535
; //  T1_MR0 = 50000;				// match register: count only up 2us * 50.000 = 100.000us = 100ms
; //  T1_MCR  = 0x02;				// match register, reset counter on match with T1_MR0
; 
;   T1_MCR  = 0x00;				// match register, no special action, simply count until 2^32-1 and restart
	mov R4,#0
	ldr R5,LIT_DVS128ChipInit+64
	str R4,[R5,#0]
	.dbline 87
;   T1_CCR  = BIT(1);				// capture TC in CR0 on falling edge of CAP0.1 (PIN_DVS_REQUEST)
	mov R4,#2
	ldr R5,LIT_DVS128ChipInit+68
	str R4,[R5,#0]
	.dbline 88
;   PCB_PINSEL0 |= BIT(21);		// set P0.10 to capture register CAP0.1
	ldr R4,LIT_DVS128ChipInit+72
	ldr R5,[R4,#0]
	orr R5,R5,#2097152
	str R5,[R4,#0]
	.dbline 90
; 
;   T1_TC	  = 0;					// reset counter to zero
	mov R4,#0
	ldr R5,LIT_DVS128ChipInit+76
	str R4,[R5,#0]
	.dbline 91
;   T1_TCR  = 0x01;				// enable Timer/Counter 1
	mov R4,#1
	ldr R5,LIT_DVS128ChipInit+80
	str R4,[R5,#0]
	.dbline -2
L1:
	ldmfd R11,{R4,R5,R6,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
LIT_DVS128ChipInit:
	DCD 1073725464
	DCD 1073725440
	DCD -2147475456
	DCD 1073725468
	DCD -2147471360
	DCD _eventBufferWritePointer
	DCD _eventBufferReadPointer
	DCD _enableEventSending
	DCD 63999
	DCD -536854516
	DCD -536854416
	DCD -536854508
	DCD -536854520
	DCD -536854524
	DCD -536838132
	DCD -536838032
	DCD -536838124
	DCD -536838104
	DCD -536690688
	DCD -536838136
	DCD -536838140
	.dbend
	EXPORT _DVS128FetchEventsEnable
	.dbfunc e DVS128FetchEventsEnable _DVS128FetchEventsEnable fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;           flag -> R6
_DVS128FetchEventsEnable:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R11,R12,R14}
	mov R11,R13
	mov R6,R0
	.dbline -1
	.dbline 95
; }
; 
; // *****************************************************************************
; void DVS128FetchEventsEnable(unsigned char flag) {
	.dbline 96
;   if (flag) {
	ands R4,R6,#255
	beq L3
	.dbline 96
	.dbline 97
;     LEDSetOff();
	mov R0,#0
	bl _LEDSetState
	.dbline 98
;     enableEventSending = 1;
	mov R4,#1
	ldr R5,LIT_DVS128FetchEventsEnable+0
	str R4,[R5,#0]
	.dbline 99
;   } else {
	b L4
L3:
	.dbline 99
	.dbline 100
;     LEDSetBlinking();
	mvn R0,#0
	bl _LEDSetState
	.dbline 101
;     enableEventSending = 0;
	mov R4,#0
	ldr R5,LIT_DVS128FetchEventsEnable+0
	str R4,[R5,#0]
	.dbline 102
;   }
L4:
	.dbline -2
L2:
	ldmfd R11,{R4,R5,R6,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
LIT_DVS128FetchEventsEnable:
	DCD _enableEventSending
	.dbsym r flag 6 c
	.dbend
	EXPORT _DVS128BiasSet
	.dbfunc e DVS128BiasSet _DVS128BiasSet fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;      biasValue -> R4
;         biasID -> R5
_DVS128BiasSet:
	mov R12,R13
	stmfd R13!,{R4,R5,R11,R12,R14}
	mov R11,R13
	mov R5,R0
	mov R4,R1
	.dbline -1
	.dbline 106
; }
; 
; // *****************************************************************************
; void DVS128BiasSet(unsigned long biasID, unsigned long biasValue) {
	.dbline 107
;   if (biasID < 12) {
	cmp R5,#12
	bhs L6
	.dbline 107
	.dbline 108
;     biasMatrix[biasID] = biasValue;
	mov R0,#4
	mul R0,R0,R5
	ldr R1,LIT_DVS128BiasSet+0
	str R4,[R0,+R1]
	.dbline 109
;   }
L6:
	.dbline -2
L5:
	ldmfd R11,{R4,R5,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
LIT_DVS128BiasSet:
	DCD _biasMatrix
	.dbsym r biasValue 4 l
	.dbsym r biasID 5 l
	.dbend
	EXPORT _DVS128BiasGet
	.dbfunc e DVS128BiasGet _DVS128BiasGet fl
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;         biasID -> R4
_DVS128BiasGet:
	mov R12,R13
	stmfd R13!,{R4,R11,R12,R14}
	mov R11,R13
	mov R4,R0
	.dbline -1
	.dbline 112
; }
; // *****************************************************************************
; unsigned long DVS128BiasGet(unsigned long biasID) {
	.dbline 113
;   if (biasID < 12) {
	cmp R4,#12
	bhs L9
	.dbline 113
	.dbline 114
;     return(biasMatrix[biasID]);
	mov R1,#4
	mul R1,R1,R4
	ldr R2,LIT_DVS128BiasGet+0
	ldr R0,[R1,+R2]
	b L8
L9:
	.dbline 116
;   }
;   return(0);
	mov R0,#0
	.dbline -2
L8:
	ldmfd R11,{R4,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
LIT_DVS128BiasGet:
	DCD _biasMatrix
	.dbsym r biasID 4 l
	.dbend
	EXPORT _DVS128BiasLoadDefaultSet
	.dbfunc e DVS128BiasLoadDefaultSet _DVS128BiasLoadDefaultSet fV
	AREA	"C$$code", CODE, READONLY
	ALIGN	4
L74:
	DCD L14
	DCD L26
	DCD L38
	DCD L50
	DCD L62
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;      biasSetID -> R4
_DVS128BiasLoadDefaultSet:
	mov R12,R13
	stmfd R13!,{R4,R11,R12,R14}
	mov R11,R13
	mov R4,R0
	.dbline -1
	.dbline 120
; }
; 
; // *****************************************************************************
; void DVS128BiasLoadDefaultSet(unsigned long biasSetID) {
	.dbline 122
; 
;   switch (biasSetID) {
	mov R1,#4
	cmp R4,#4
	bgt L12
	mul R0,R1,R4
	ldr R1,LIT_DVS128BiasLoadDefaultSet+0
	ldr R0,[R0,+R1]
	mov R15,R0
X0:
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
	.dbline 122
L14:
	.dbline 125
; 
;   case 0:  // 12 bias values of 24 bits each 								BIAS_DEFAULT
;     biasMatrix[ 0]=	    1067; // 0x00042B,	  		// Tmpdiff128.IPot.cas
	ldr R0,LIT_DVS128BiasLoadDefaultSet+4
	ldr R1,LIT_DVS128BiasLoadDefaultSet+8
	str R0,[R1,#0]
	.dbline 126
;     biasMatrix[ 1]=	   12316; // 0x00301C,			// Tmpdiff128.IPot.injGnd
	ldr R0,LIT_DVS128BiasLoadDefaultSet+12
	ldr R1,LIT_DVS128BiasLoadDefaultSet+16
	str R0,[R1,#0]
	.dbline 127
;     biasMatrix[ 2]=	16777215; // 0xFFFFFF,			// Tmpdiff128.IPot.reqPd
	mvn R0,#-16777216
	ldr R1,LIT_DVS128BiasLoadDefaultSet+20
	str R0,[R1,#0]
	.dbline 128
;     biasMatrix[ 3]=	 5579732; // 0x5523D4,			// Tmpdiff128.IPot.puX
	ldr R0,LIT_DVS128BiasLoadDefaultSet+24
	ldr R1,LIT_DVS128BiasLoadDefaultSet+28
	str R0,[R1,#0]
	.dbline 129
;     biasMatrix[ 4]=	     151; // 0x000097,			// Tmpdiff128.IPot.diffOff
	mov R0,#151
	ldr R1,LIT_DVS128BiasLoadDefaultSet+32
	str R0,[R1,#0]
	.dbline 130
;     biasMatrix[ 5]=	  427594; // 0x06864A,			// Tmpdiff128.IPot.req
	ldr R0,LIT_DVS128BiasLoadDefaultSet+36
	ldr R1,LIT_DVS128BiasLoadDefaultSet+40
	str R0,[R1,#0]
	.dbline 131
;     biasMatrix[ 6]=	       0; // 0x000000,			// Tmpdiff128.IPot.refr
	mov R0,#0
	ldr R1,LIT_DVS128BiasLoadDefaultSet+44
	str R0,[R1,#0]
	.dbline 132
;     biasMatrix[ 7]=	16777215; // 0xFFFFFF,			// Tmpdiff128.IPot.puY
	mvn R0,#-16777216
	ldr R1,LIT_DVS128BiasLoadDefaultSet+48
	str R0,[R1,#0]
	.dbline 133
;     biasMatrix[ 8]=	  296253; // 0x04853D,			// Tmpdiff128.IPot.diffOn
	ldr R0,LIT_DVS128BiasLoadDefaultSet+52
	ldr R1,LIT_DVS128BiasLoadDefaultSet+56
	str R0,[R1,#0]
	.dbline 134
;     biasMatrix[ 9]=	    3624; // 0x000E28,			// Tmpdiff128.IPot.diff
	ldr R0,LIT_DVS128BiasLoadDefaultSet+60
	ldr R1,LIT_DVS128BiasLoadDefaultSet+64
	str R0,[R1,#0]
	.dbline 135
;     biasMatrix[10]=	      39; // 0x000027,			// Tmpdiff128.IPot.foll
	mov R0,#39
	ldr R1,LIT_DVS128BiasLoadDefaultSet+68
	str R0,[R1,#0]
	.dbline 136
;     biasMatrix[11]=        4; // 0x000004			// Tmpdiff128.IPot.Pr
	mov R0,#4
	ldr R1,LIT_DVS128BiasLoadDefaultSet+72
	str R0,[R1,#0]
	.dbline 137
;     break;
	b L13
L26:
	.dbline 140
; 
;   case 1:  // 12 bias values of 24 bits each 								BIAS_BRAGFOST
;     biasMatrix[ 0]=        1067;	  		// Tmpdiff128.IPot.cas
	ldr R0,LIT_DVS128BiasLoadDefaultSet+4
	ldr R1,LIT_DVS128BiasLoadDefaultSet+8
	str R0,[R1,#0]
	.dbline 141
;     biasMatrix[ 1]=       12316;			// Tmpdiff128.IPot.injGnd
	ldr R0,LIT_DVS128BiasLoadDefaultSet+12
	ldr R1,LIT_DVS128BiasLoadDefaultSet+16
	str R0,[R1,#0]
	.dbline 142
;     biasMatrix[ 2]=    16777215;			// Tmpdiff128.IPot.reqPd
	mvn R0,#-16777216
	ldr R1,LIT_DVS128BiasLoadDefaultSet+20
	str R0,[R1,#0]
	.dbline 143
;     biasMatrix[ 3]=     5579731;			// Tmpdiff128.IPot.puX
	ldr R0,LIT_DVS128BiasLoadDefaultSet+76
	ldr R1,LIT_DVS128BiasLoadDefaultSet+28
	str R0,[R1,#0]
	.dbline 144
;     biasMatrix[ 4]=          60;			// Tmpdiff128.IPot.diffOff
	mov R0,#60
	ldr R1,LIT_DVS128BiasLoadDefaultSet+32
	str R0,[R1,#0]
	.dbline 145
;     biasMatrix[ 5]=      427594;			// Tmpdiff128.IPot.req
	ldr R0,LIT_DVS128BiasLoadDefaultSet+36
	ldr R1,LIT_DVS128BiasLoadDefaultSet+40
	str R0,[R1,#0]
	.dbline 146
;     biasMatrix[ 6]=           0;			// Tmpdiff128.IPot.refr
	mov R0,#0
	ldr R1,LIT_DVS128BiasLoadDefaultSet+44
	str R0,[R1,#0]
	.dbline 147
;     biasMatrix[ 7]=    16777215;			// Tmpdiff128.IPot.puY
	mvn R0,#-16777216
	ldr R1,LIT_DVS128BiasLoadDefaultSet+48
	str R0,[R1,#0]
	.dbline 148
;     biasMatrix[ 8]=      567391;			// Tmpdiff128.IPot.diffOn
	ldr R0,LIT_DVS128BiasLoadDefaultSet+80
	ldr R1,LIT_DVS128BiasLoadDefaultSet+56
	str R0,[R1,#0]
	.dbline 149
;     biasMatrix[ 9]=        6831;			// Tmpdiff128.IPot.diff
	ldr R0,LIT_DVS128BiasLoadDefaultSet+84
	ldr R1,LIT_DVS128BiasLoadDefaultSet+64
	str R0,[R1,#0]
	.dbline 150
;     biasMatrix[10]=          39;			// Tmpdiff128.IPot.foll
	mov R0,#39
	ldr R1,LIT_DVS128BiasLoadDefaultSet+68
	str R0,[R1,#0]
	.dbline 151
;     biasMatrix[11]=           4;			// Tmpdiff128.IPot.Pr
	mov R0,#4
	ldr R1,LIT_DVS128BiasLoadDefaultSet+72
	str R0,[R1,#0]
	.dbline 152
;     break;
	b L13
L38:
	.dbline 155
; 
;   case 2:  // 12 bias values of 24 bits each 								BIAS_FAST
;     biasMatrix[ 0]=        1966;	  		// Tmpdiff128.IPot.cas
	ldr R0,LIT_DVS128BiasLoadDefaultSet+88
	ldr R1,LIT_DVS128BiasLoadDefaultSet+8
	str R0,[R1,#0]
	.dbline 156
;     biasMatrix[ 1]=     1137667;			// Tmpdiff128.IPot.injGnd
	ldr R0,LIT_DVS128BiasLoadDefaultSet+92
	ldr R1,LIT_DVS128BiasLoadDefaultSet+16
	str R0,[R1,#0]
	.dbline 157
;     biasMatrix[ 2]=    16777215;			// Tmpdiff128.IPot.reqPd
	mvn R0,#-16777216
	ldr R1,LIT_DVS128BiasLoadDefaultSet+20
	str R0,[R1,#0]
	.dbline 158
;     biasMatrix[ 3]=     8053457;			// Tmpdiff128.IPot.puX
	ldr R0,LIT_DVS128BiasLoadDefaultSet+96
	ldr R1,LIT_DVS128BiasLoadDefaultSet+28
	str R0,[R1,#0]
	.dbline 159
;     biasMatrix[ 4]=         133;			// Tmpdiff128.IPot.diffOff
	mov R0,#133
	ldr R1,LIT_DVS128BiasLoadDefaultSet+32
	str R0,[R1,#0]
	.dbline 160
;     biasMatrix[ 5]=      160712;			// Tmpdiff128.IPot.req
	ldr R0,LIT_DVS128BiasLoadDefaultSet+100
	ldr R1,LIT_DVS128BiasLoadDefaultSet+40
	str R0,[R1,#0]
	.dbline 161
;     biasMatrix[ 6]=         944;			// Tmpdiff128.IPot.refr
	mov R0,#944
	ldr R1,LIT_DVS128BiasLoadDefaultSet+44
	str R0,[R1,#0]
	.dbline 162
;     biasMatrix[ 7]=    16777215;			// Tmpdiff128.IPot.puY
	mvn R0,#-16777216
	ldr R1,LIT_DVS128BiasLoadDefaultSet+48
	str R0,[R1,#0]
	.dbline 163
;     biasMatrix[ 8]=      205255;			// Tmpdiff128.IPot.diffOn
	ldr R0,LIT_DVS128BiasLoadDefaultSet+104
	ldr R1,LIT_DVS128BiasLoadDefaultSet+56
	str R0,[R1,#0]
	.dbline 164
;     biasMatrix[ 9]=        3207;			// Tmpdiff128.IPot.diff
	ldr R0,LIT_DVS128BiasLoadDefaultSet+108
	ldr R1,LIT_DVS128BiasLoadDefaultSet+64
	str R0,[R1,#0]
	.dbline 165
;     biasMatrix[10]=         278;			// Tmpdiff128.IPot.foll
	ldr R0,LIT_DVS128BiasLoadDefaultSet+112
	ldr R1,LIT_DVS128BiasLoadDefaultSet+68
	str R0,[R1,#0]
	.dbline 166
;     biasMatrix[11]=         217;			// Tmpdiff128.IPot.Pr
	mov R0,#217
	ldr R1,LIT_DVS128BiasLoadDefaultSet+72
	str R0,[R1,#0]
	.dbline 167
;     break;
	b L13
L50:
	.dbline 170
; 
;   case 3:  // 12 bias values of 24 bits each 								BIAS_STEREO_PAIR
;     biasMatrix[ 0]=        1966;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+88
	ldr R1,LIT_DVS128BiasLoadDefaultSet+8
	str R0,[R1,#0]
	.dbline 171
;     biasMatrix[ 1]=     1135792;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+116
	ldr R1,LIT_DVS128BiasLoadDefaultSet+16
	str R0,[R1,#0]
	.dbline 172
;     biasMatrix[ 2]=    16769632;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+120
	ldr R1,LIT_DVS128BiasLoadDefaultSet+20
	str R0,[R1,#0]
	.dbline 173
;     biasMatrix[ 3]=     8061894;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+124
	ldr R1,LIT_DVS128BiasLoadDefaultSet+28
	str R0,[R1,#0]
	.dbline 174
;     biasMatrix[ 4]=         133;
	mov R0,#133
	ldr R1,LIT_DVS128BiasLoadDefaultSet+32
	str R0,[R1,#0]
	.dbline 175
;     biasMatrix[ 5]=      160703;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+128
	ldr R1,LIT_DVS128BiasLoadDefaultSet+40
	str R0,[R1,#0]
	.dbline 176
;     biasMatrix[ 6]=         935;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+132
	ldr R1,LIT_DVS128BiasLoadDefaultSet+44
	str R0,[R1,#0]
	.dbline 177
;     biasMatrix[ 7]=    16769632;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+120
	ldr R1,LIT_DVS128BiasLoadDefaultSet+48
	str R0,[R1,#0]
	.dbline 178
;     biasMatrix[ 8]=      205244;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+136
	ldr R1,LIT_DVS128BiasLoadDefaultSet+56
	str R0,[R1,#0]
	.dbline 179
;     biasMatrix[ 9]=        3207;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+108
	ldr R1,LIT_DVS128BiasLoadDefaultSet+64
	str R0,[R1,#0]
	.dbline 180
;     biasMatrix[10]=         267;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+140
	ldr R1,LIT_DVS128BiasLoadDefaultSet+68
	str R0,[R1,#0]
	.dbline 181
;     biasMatrix[11]=         217;
	mov R0,#217
	ldr R1,LIT_DVS128BiasLoadDefaultSet+72
	str R0,[R1,#0]
	.dbline 182
;     break;
	b L13
L62:
	.dbline 185
; 
;   case 4:  // 12 bias values of 24 bits each 								BIAS_MINI_DVS
;     biasMatrix[ 0]=        1966;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+88
	ldr R1,LIT_DVS128BiasLoadDefaultSet+8
	str R0,[R1,#0]
	.dbline 186
;     biasMatrix[ 1]=     1137667;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+92
	ldr R1,LIT_DVS128BiasLoadDefaultSet+16
	str R0,[R1,#0]
	.dbline 187
;     biasMatrix[ 2]=    16777215;
	mvn R0,#-16777216
	ldr R1,LIT_DVS128BiasLoadDefaultSet+20
	str R0,[R1,#0]
	.dbline 188
;     biasMatrix[ 3]=     8053458;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+144
	ldr R1,LIT_DVS128BiasLoadDefaultSet+28
	str R0,[R1,#0]
	.dbline 189
;     biasMatrix[ 4]=          62;
	mov R0,#62
	ldr R1,LIT_DVS128BiasLoadDefaultSet+32
	str R0,[R1,#0]
	.dbline 190
;     biasMatrix[ 5]=      160712;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+100
	ldr R1,LIT_DVS128BiasLoadDefaultSet+40
	str R0,[R1,#0]
	.dbline 191
;     biasMatrix[ 6]=         944;
	mov R0,#944
	ldr R1,LIT_DVS128BiasLoadDefaultSet+44
	str R0,[R1,#0]
	.dbline 192
;     biasMatrix[ 7]=    16777215;
	mvn R0,#-16777216
	ldr R1,LIT_DVS128BiasLoadDefaultSet+48
	str R0,[R1,#0]
	.dbline 193
;     biasMatrix[ 8]=      480988;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+148
	ldr R1,LIT_DVS128BiasLoadDefaultSet+56
	str R0,[R1,#0]
	.dbline 194
;     biasMatrix[ 9]=        3207;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+108
	ldr R1,LIT_DVS128BiasLoadDefaultSet+64
	str R0,[R1,#0]
	.dbline 195
;     biasMatrix[10]=         278;
	ldr R0,LIT_DVS128BiasLoadDefaultSet+112
	ldr R1,LIT_DVS128BiasLoadDefaultSet+68
	str R0,[R1,#0]
	.dbline 196
;     biasMatrix[11]=         217;
	mov R0,#217
	ldr R1,LIT_DVS128BiasLoadDefaultSet+72
	str R0,[R1,#0]
	.dbline 197
;     break;
L12:
L13:
	.dbline -2
L11:
	ldmfd R11,{R4,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
LIT_DVS128BiasLoadDefaultSet:
	DCD L74
	DCD 1067
	DCD _biasMatrix
	DCD 12316
	DCD _biasMatrix+4
	DCD _biasMatrix+8
	DCD 5579732
	DCD _biasMatrix+12
	DCD _biasMatrix+16
	DCD 427594
	DCD _biasMatrix+20
	DCD _biasMatrix+24
	DCD _biasMatrix+28
	DCD 296253
	DCD _biasMatrix+32
	DCD 3624
	DCD _biasMatrix+36
	DCD _biasMatrix+40
	DCD _biasMatrix+44
	DCD 5579731
	DCD 567391
	DCD 6831
	DCD 1966
	DCD 1137667
	DCD 8053457
	DCD 160712
	DCD 205255
	DCD 3207
	DCD 278
	DCD 1135792
	DCD 16769632
	DCD 8061894
	DCD 160703
	DCD 935
	DCD 205244
	DCD 267
	DCD 8053458
	DCD 480988
	.dbsym r biasSetID 4 l
	.dbend
	AREA	"Cidata", RAMFUNC
	CODE32
	ALIGN 4
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
	EXPORT _DVS128BiasFlush
	.dbfunc e DVS128BiasFlush _DVS128BiasFlush fV
	AREA	"Cidata", RAMFUNC
	CODE32
	ALIGN 4
;      biasIndex -> R6
;        biasPIN -> R4
;    currentBias -> R7
;       clockPIN -> R5
_DVS128BiasFlush:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R7,R11,R12,R14}
	mov R11,R13
	.dbline -1
	.dbline 206
; 
;   }
; }
; 
; // *****************************************************************************
; #pragma ramfunc DVS128BiasFlush
; #define BOUT(x)  {if (x) FGPIO_IOSET = biasPIN; else FGPIO_IOCLR = biasPIN; FGPIO_IOSET = clockPIN; FGPIO_IOCLR = clockPIN; }
; 
; void DVS128BiasFlush(void) {
	.dbline 211
;   unsigned long biasIndex, currentBias;
;   unsigned long biasPIN, clockPIN;	   		// use local references to pins to save time
;   		   				 					// the c compiler assigns up to four local registers (R4-R7),
; 											// so use them for four local variables
;   biasPIN = PIN_BIAS_DATA;
	mov R4,#8192
	.dbline 212
;   clockPIN = PIN_BIAS_CLOCK;
	mov R5,#-2147483648
	.dbline 214
; 
;   for (biasIndex=0; biasIndex<12; biasIndex++) {
	mov R6,#0
	b L79
L76:
	.dbline 214
	.dbline 215
;     currentBias = biasMatrix[biasIndex];
	mov R0,#4
	mul R0,R0,R6
	ldr R1,LIT_DVS128BiasFlush+0
	ldr R7,[R0,+R1]
	.dbline 217
; 
; 	BOUT(currentBias & 0x800000);
	.dbline 217
	tst R7,#8388608
	beq L80
	.dbline 217
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L81
L80:
	.dbline 217
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L81:
	.dbline 217
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 217
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 217
	.dbline 217
	.dbline 218
; 	BOUT(currentBias & 0x400000);
	.dbline 218
	tst R7,#4194304
	beq L82
	.dbline 218
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L83
L82:
	.dbline 218
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L83:
	.dbline 218
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 218
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 218
	.dbline 218
	.dbline 219
; 	BOUT(currentBias & 0x200000);
	.dbline 219
	tst R7,#2097152
	beq L84
	.dbline 219
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L85
L84:
	.dbline 219
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L85:
	.dbline 219
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 219
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 219
	.dbline 219
	.dbline 220
; 	BOUT(currentBias & 0x100000);
	.dbline 220
	tst R7,#1048576
	beq L86
	.dbline 220
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L87
L86:
	.dbline 220
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L87:
	.dbline 220
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 220
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 220
	.dbline 220
	.dbline 222
; 	
; 	BOUT(currentBias & 0x80000);
	.dbline 222
	tst R7,#524288
	beq L88
	.dbline 222
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L89
L88:
	.dbline 222
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L89:
	.dbline 222
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 222
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 222
	.dbline 222
	.dbline 223
; 	BOUT(currentBias & 0x40000);
	.dbline 223
	tst R7,#262144
	beq L90
	.dbline 223
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L91
L90:
	.dbline 223
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L91:
	.dbline 223
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 223
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 223
	.dbline 223
	.dbline 224
; 	BOUT(currentBias & 0x20000);
	.dbline 224
	tst R7,#131072
	beq L92
	.dbline 224
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L93
L92:
	.dbline 224
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L93:
	.dbline 224
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 224
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 224
	.dbline 224
	.dbline 225
; 	BOUT(currentBias & 0x10000);
	.dbline 225
	tst R7,#65536
	beq L94
	.dbline 225
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L95
L94:
	.dbline 225
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L95:
	.dbline 225
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 225
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 225
	.dbline 225
	.dbline 227
; 	
; 	BOUT(currentBias & 0x8000);
	.dbline 227
	tst R7,#32768
	beq L96
	.dbline 227
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L97
L96:
	.dbline 227
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L97:
	.dbline 227
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 227
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 227
	.dbline 227
	.dbline 228
; 	BOUT(currentBias & 0x4000);
	.dbline 228
	tst R7,#16384
	beq L98
	.dbline 228
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L99
L98:
	.dbline 228
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L99:
	.dbline 228
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 228
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 228
	.dbline 228
	.dbline 229
; 	BOUT(currentBias & 0x2000);
	.dbline 229
	tst R7,#8192
	beq L100
	.dbline 229
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L101
L100:
	.dbline 229
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L101:
	.dbline 229
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 229
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 229
	.dbline 229
	.dbline 230
; 	BOUT(currentBias & 0x1000);
	.dbline 230
	tst R7,#4096
	beq L102
	.dbline 230
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L103
L102:
	.dbline 230
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L103:
	.dbline 230
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 230
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 230
	.dbline 230
	.dbline 232
; 	
; 	BOUT(currentBias & 0x800);
	.dbline 232
	tst R7,#2048
	beq L104
	.dbline 232
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L105
L104:
	.dbline 232
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L105:
	.dbline 232
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 232
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 232
	.dbline 232
	.dbline 233
; 	BOUT(currentBias & 0x400);
	.dbline 233
	tst R7,#1024
	beq L106
	.dbline 233
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L107
L106:
	.dbline 233
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L107:
	.dbline 233
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 233
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 233
	.dbline 233
	.dbline 234
; 	BOUT(currentBias & 0x200);
	.dbline 234
	tst R7,#512
	beq L108
	.dbline 234
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L109
L108:
	.dbline 234
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L109:
	.dbline 234
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 234
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 234
	.dbline 234
	.dbline 235
; 	BOUT(currentBias & 0x100);
	.dbline 235
	tst R7,#256
	beq L110
	.dbline 235
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L111
L110:
	.dbline 235
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L111:
	.dbline 235
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 235
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 235
	.dbline 235
	.dbline 237
; 
; 	BOUT(currentBias & 0x80);
	.dbline 237
	tst R7,#128
	beq L112
	.dbline 237
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L113
L112:
	.dbline 237
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L113:
	.dbline 237
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 237
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 237
	.dbline 237
	.dbline 238
; 	BOUT(currentBias & 0x40);
	.dbline 238
	tst R7,#64
	beq L114
	.dbline 238
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L115
L114:
	.dbline 238
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L115:
	.dbline 238
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 238
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 238
	.dbline 238
	.dbline 239
; 	BOUT(currentBias & 0x20);
	.dbline 239
	tst R7,#32
	beq L116
	.dbline 239
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L117
L116:
	.dbline 239
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L117:
	.dbline 239
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 239
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 239
	.dbline 239
	.dbline 240
; 	BOUT(currentBias & 0x10);
	.dbline 240
	tst R7,#16
	beq L118
	.dbline 240
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L119
L118:
	.dbline 240
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L119:
	.dbline 240
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 240
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 240
	.dbline 240
	.dbline 242
; 
; 	BOUT(currentBias & 0x8);
	.dbline 242
	tst R7,#8
	beq L120
	.dbline 242
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L121
L120:
	.dbline 242
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L121:
	.dbline 242
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 242
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 242
	.dbline 242
	.dbline 243
; 	BOUT(currentBias & 0x4);
	.dbline 243
	tst R7,#4
	beq L122
	.dbline 243
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L123
L122:
	.dbline 243
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L123:
	.dbline 243
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 243
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 243
	.dbline 243
	.dbline 244
; 	BOUT(currentBias & 0x2);
	.dbline 244
	tst R7,#2
	beq L124
	.dbline 244
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L125
L124:
	.dbline 244
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L125:
	.dbline 244
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 244
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 244
	.dbline 244
	.dbline 245
; 	BOUT(currentBias & 0x1);
	.dbline 245
	tst R7,#1
	beq L126
	.dbline 245
	ldr R0,LIT_DVS128BiasFlush+4
	str R4,[R0,#0]
	b L127
L126:
	.dbline 245
	ldr R0,LIT_DVS128BiasFlush+8
	str R4,[R0,#0]
L127:
	.dbline 245
	ldr R0,LIT_DVS128BiasFlush+4
	str R5,[R0,#0]
	.dbline 245
	ldr R0,LIT_DVS128BiasFlush+8
	str R5,[R0,#0]
	.dbline 245
	.dbline 245
	.dbline 263
; 
; #ifdef NONO
; 	bitIndex = BIT(23);
; 	do {
; 	  if (currentBias & bitIndex) {
; 	    FGPIO_IOSET = PIN_BIAS_DATA;
; 	  } else {
; 	    FGPIO_IOCLR = PIN_BIAS_DATA;
; 	  }
; 	  FGPIO_IOSET = PIN_BIAS_CLOCK;
; 
; 	  FGPIO_IOCLR = PIN_BIAS_CLOCK;
; 
; 	  bitIndex >>= 1;
; 	} while (bitIndex);
; #endif
; 
;   }  // end of biasIndexclocking
L77:
	.dbline 214
	add R6,R6,#1
L79:
	.dbline 214
	cmp R6,#12
	blo L76
	.dbline 268
; 
; //  FGPIO_IOCLR = PIN_BIAS_DATA;	   // set data pin to low just to have the same output all the time
; 
;   // trigger latch to push bias data to bias generators
;   FGPIO_IOCLR = PIN_BIAS_LATCH | PIN_BIAS_DATA;
	mov R0,#12288
	ldr R1,LIT_DVS128BiasFlush+8
	str R0,[R1,#0]
	.dbline 269
;   FGPIO_IOSET = PIN_BIAS_LATCH;
	mov R0,#4096
	ldr R1,LIT_DVS128BiasFlush+4
	str R0,[R1,#0]
	.dbline -2
L75:
	ldmfd R11,{R4,R5,R6,R7,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
LIT_DVS128BiasFlush:
	DCD _biasMatrix
	DCD 1073725464
	DCD 1073725468
	.dbsym r biasIndex 6 l
	.dbsym r biasPIN 4 l
	.dbsym r currentBias 7 l
	.dbsym r clockPIN 5 l
	.dbend
	EXPORT _DVS128BiasTransmitBiasValue
	.dbfunc e DVS128BiasTransmitBiasValue _DVS128BiasTransmitBiasValue fV
	AREA	"Cidata", RAMFUNC
	CODE32
	ALIGN 4
;      biasValue -> R7
;         biasID -> R6
_DVS128BiasTransmitBiasValue:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R7,R11,R12,R14}
	mov R11,R13
	mov R6,R0
	.dbline -1
	.dbline 275
; }
; 
; 
; // *****************************************************************************
; #pragma ramfunc DVS128BiasTransmitBiasValue
; void DVS128BiasTransmitBiasValue(unsigned long biasID) {
	.dbline 277
;   unsigned long biasValue;
;   biasValue = biasMatrix[biasID];
	mov R4,#4
	mul R4,R4,R6
	ldr R5,LIT_DVS128BiasTransmitBiasValue+0
	ldr R7,[R4,+R5]
	.dbline 279
; 
;   dataForTransmission[0] = (((biasValue)    ) & 0x3F) + 32;
	and R4,R7,#63
	add R4,R4,#32
	ldr R5,LIT_DVS128BiasTransmitBiasValue+4
	strb R4,[R5,#0]
	.dbline 280
;   dataForTransmission[1] = (((biasValue)>> 6) & 0x3F) + 32;
	mov R4,R7,lsr #6
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_DVS128BiasTransmitBiasValue+8
	strb R4,[R5,#0]
	.dbline 281
;   dataForTransmission[2] = (((biasValue)>>12) & 0x3F) + 32;
	mov R4,R7,lsr #12
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_DVS128BiasTransmitBiasValue+12
	strb R4,[R5,#0]
	.dbline 282
;   dataForTransmission[3] = (((biasValue)>>18) & 0x3F) + 32;
	mov R4,R7,lsr #18
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_DVS128BiasTransmitBiasValue+16
	strb R4,[R5,#0]
	.dbline 283
;   dataForTransmission[4] = biasID + 32;
	add R4,R6,#32
	ldr R5,LIT_DVS128BiasTransmitBiasValue+20
	strb R4,[R5,#0]
	.dbline 285
; 
;   transmitSpecialData(5);
	mov R0,#5
	bl _transmitSpecialData
	.dbline -2
L128:
	ldmfd R11,{R4,R5,R6,R7,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
LIT_DVS128BiasTransmitBiasValue:
	DCD _biasMatrix
	DCD _dataForTransmission
	DCD _dataForTransmission+1
	DCD _dataForTransmission+2
	DCD _dataForTransmission+3
	DCD _dataForTransmission+4
	.dbsym r biasValue 7 l
	.dbsym r biasID 6 l
	.dbend
	AREA	"Cudata", NOINIT
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\DVS128Chip.c
	EXPORT _eventBufferReadPointer
	ALIGN	4
_eventBufferReadPointer:
	SPACE 4
	.dbsym e eventBufferReadPointer _eventBufferReadPointer l
	EXPORT _eventBufferWritePointer
	ALIGN	4
_eventBufferWritePointer:
	SPACE 4
	.dbsym e eventBufferWritePointer _eventBufferWritePointer l
	EXPORT _eventBufferT
	ALIGN	4
_eventBufferT:
	SPACE 32768
	.dbsym e eventBufferT _eventBufferT A[32768:8192]l
	EXPORT _eventBufferA
	ALIGN	2
_eventBufferA:
	SPACE 16384
	.dbsym e eventBufferA _eventBufferA A[16384:8192]s
	EXPORT _p
	ALIGN	4
_p:
	SPACE 4
	.dbsym e p _p l
	EXPORT _y
	ALIGN	4
_y:
	SPACE 4
	.dbsym e y _y l
	EXPORT _x
	ALIGN	4
_x:
	SPACE 4
	.dbsym e x _x l
	EXPORT _newEvent
	ALIGN	4
_newEvent:
	SPACE 4
	.dbsym e newEvent _newEvent l
	EXPORT _enableEventSending
	ALIGN	4
_enableEventSending:
	SPACE 4
	.dbsym e enableEventSending _enableEventSending l
	EXPORT _biasMatrix
	ALIGN	4
_biasMatrix:
	SPACE 48
	.dbsym e biasMatrix _biasMatrix A[48:12]l
	IMPORT _dataForTransmission
	END
