	.dbfile ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
	AREA	"Cidata", DATA
	.dbfile ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
	EXPORT _TXBufferIndex
	ALIGN	4
_TXBufferIndex:
	DCD 0
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
	.dbsym e TXBufferIndex _TXBufferIndex l
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
	EXPORT _mainloopInit
	.dbfunc e mainloopInit _mainloopInit fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;              n -> R4
_mainloopInit:
	mov R12,R13
	stmfd R13!,{R4,R12,R14}
	.dbline -1
	.dbline 46
; #include "EDVS128_2106.h"
; 
; // *****************************************************************************
; extern long ledState;	 			// 0:off, -1:on, -2:blinking, >0: timeOn
; 
; extern unsigned short eventBufferA[DVS_EVENTBUFFER_SIZE];		  // for event addresses
; extern unsigned long  eventBufferT[DVS_EVENTBUFFER_SIZE];		  // for event time stamps
; extern unsigned long  eventBufferWritePointer, eventBufferReadPointer;
; 
; extern unsigned long enableEventSending;
; 
; extern unsigned char commandLine[UART_COMMAND_LINE_MAX_LENGTH];
; extern unsigned long commandLinePointer;
; 
; unsigned long transmitEventRateEnable;
; 
; unsigned char TXBuffer[256];							// events sending
; unsigned long TXBufferIndex=0;
; 
; unsigned long eventCounterTotal, eventCounterOn, eventCounterOff;
; unsigned long currentTimerValue,
; 		 	  nextTimer1msValue, nextTimer2msValue, nextTimer10msValue, nextTimer100msValue, nextTimer1000msValue;
; 
; unsigned char dataForTransmission[16];
; 
; unsigned long eDVSDataFormat;
; unsigned char hexLookupTable[16];
; 
; #ifdef INCLUDE_TRACK_HF_LED
;   extern unsigned short tsMemory[128][128];
;   extern unsigned long trackingHFLCenterX[4], trackingHFLCenterY[4], trackingHFLCenterC[4];
;   extern unsigned long trackingHFLDesiredTimeDiff[4];
;   extern unsigned long transmitTrackHFLED;
;   #ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
;     extern unsigned long TrackHFL_PWM0, TrackHFL_PWM1;
;     extern unsigned long EP_TrackHFP_ServoEnabled;
;   #endif
; #endif
; 
; #ifdef INCLUDE_PIXEL_CUTOUT_REGION
;   extern unsigned long pixelCutoutMinX, pixelCutoutMaxX, pixelCutoutMinY, pixelCutoutMaxY;
; #endif
; 
; // *****************************************************************************
; // *****************************************************************************
; void mainloopInit(void) {
	.dbline 49
;   unsigned long n;
; 
;   eventCounterTotal = 0;
	mov R0,#0
	ldr R1,LIT_mainloopInit+0
	str R0,[R1,#0]
	.dbline 50
;   eventCounterOn = 0;
	mov R0,#0
	ldr R1,LIT_mainloopInit+4
	str R0,[R1,#0]
	.dbline 51
;   eventCounterOff = 0;
	mov R0,#0
	ldr R1,LIT_mainloopInit+8
	str R0,[R1,#0]
	.dbline 53
; 
;   transmitEventRateEnable = 0;			// default: disable automatic EPS control
	mov R0,#0
	ldr R1,LIT_mainloopInit+12
	str R0,[R1,#0]
	.dbline 55
; 
;   eDVSDataFormat = EDVS_DATA_FORMAT_DEFAULT;
	mov R0,#31
	ldr R1,LIT_mainloopInit+16
	str R0,[R1,#0]
	.dbline 57
; 
;   for (n=0; n<10; n++) { hexLookupTable[n]   ='0'+n; }
	mov R4,#0
	b L5
L2:
	.dbline 57
	.dbline 57
	ldr R0,LIT_mainloopInit+20
	add R1,R4,#48
	strb R1,[R4,+R0]
	.dbline 57
L3:
	.dbline 57
	add R4,R4,#1
L5:
	.dbline 57
	cmp R4,#10
	blo L2
	.dbline 58
;   for (n=0; n< 6; n++) { hexLookupTable[n+10]='A'+n; }
	mov R4,#0
	b L9
L6:
	.dbline 58
	.dbline 58
	add R0,R4,#10
	ldr R1,LIT_mainloopInit+20
	add R2,R4,#65
	strb R2,[R0,+R1]
	.dbline 58
L7:
	.dbline 58
	add R4,R4,#1
L9:
	.dbline 58
	cmp R4,#6
	blo L6
	.dbline -2
L1:
	ldmfd R13!,{R4,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
LIT_mainloopInit:
	DCD _eventCounterTotal
	DCD _eventCounterOn
	DCD _eventCounterOff
	DCD _transmitEventRateEnable
	DCD _eDVSDataFormat
	DCD _hexLookupTable
	.dbsym r n 4 l
	.dbend
	AREA	"Cidata", RAMFUNC
	CODE32
	ALIGN 4
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
	EXPORT _transmitSpecialData
	.dbfunc e transmitSpecialData _transmitSpecialData fV
	AREA	"Cidata", RAMFUNC
	CODE32
	ALIGN 4
;              n -> R4
;              l -> R5
_transmitSpecialData:
	mov R12,R13
	stmfd R13!,{R4,R5,R12,R14}
	mov R5,R0
	.dbline -1
	.dbline 63
; }
; 
; // *****************************************************************************
; #pragma ramfunc transmitSpecialData
; void transmitSpecialData(unsigned long l) {
	.dbline 66
;   unsigned long n;
; 
;   for (n=(TXBufferIndex+l); n>l; n--) {		  // shift data "up"
	ldr R0,LIT_transmitSpecialData+0
	ldr R0,[R0,#0]
	add R4,R0,R5
	b L14
L11:
	.dbline 66
	.dbline 67
;     TXBuffer[n] = TXBuffer[n-(l+1)];
	ldr R0,LIT_transmitSpecialData+4
	add R1,R5,#1
	sub R1,R4,R1
	ldrb R1,[R1,+R0]
	strb R1,[R4,+R0]
	.dbline 68
;   }
L12:
	.dbline 66
	sub R4,R4,#1
L14:
	.dbline 66
	cmp R4,R5
	bhi L11
	.dbline 70
; 
;   for (n=0; n<l; n++) {				  		  // fill data in
	mov R4,#0
	b L18
L15:
	.dbline 70
	.dbline 71
;     TXBuffer[n] = dataForTransmission[n];
	ldr R0,LIT_transmitSpecialData+4
	ldr R1,LIT_transmitSpecialData+8
	ldrb R1,[R4,+R1]
	strb R1,[R4,+R0]
	.dbline 72
;   }
L16:
	.dbline 70
	add R4,R4,#1
L18:
	.dbline 70
	cmp R4,R5
	blo L15
	.dbline 73
;   TXBuffer[l] = 0x80 + (l&0x0F);			  // 0x8y: start of special sequence of length y
	ldr R0,LIT_transmitSpecialData+4
	and R1,R5,#15
	add R1,R1,#128
	strb R1,[R5,+R0]
	.dbline 75
; 
;   TXBufferIndex += (l+1);
	ldr R0,LIT_transmitSpecialData+0
	add R1,R5,#1
	ldr R2,[R0,#0]
	add R1,R2,R1
	str R1,[R0,#0]
	.dbline -2
L10:
	ldmfd R13!,{R4,R5,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
LIT_transmitSpecialData:
	DCD _TXBufferIndex
	DCD _TXBuffer
	DCD _dataForTransmission
	.dbsym r n 4 l
	.dbsym r l 5 l
	.dbend
	EXPORT _swapByteOrderInMemory
	.dbfunc e swapByteOrderInMemory _swapByteOrderInMemory fV
	AREA	"Cidata", RAMFUNC
	CODE32
	ALIGN 4
;            tmp -> R6
;             cr -> R5
;              l -> R5
;              c -> R4
_swapByteOrderInMemory:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R12,R14}
	mov R4,R0
	mov R5,R1
	.dbline -1
	.dbline 80
; }
; 
; // *****************************************************************************
; #pragma ramfunc swapByteOrderInMemory
; void swapByteOrderInMemory(char *c, unsigned long l) {
	.dbline 84
;   char *cr;
;   unsigned char tmp;
; 
;   cr=c+l-1;						// point to end of sequence
	add R0,R5,R4
	mvn R1,#0
	add R5,R0,R1
	b L21
L20:
	.dbline 86
; 
;   while (c<cr) {
	.dbline 87
;     tmp = *c;
	ldrb R6,[R4,#0]
	.dbline 88
; 	*c = *cr;
	ldrb R0,[R5,#0]
	strb R0,[R4,#0]
	.dbline 89
; 	*cr = tmp;
	strb R6,[R5,#0]
	.dbline 90
;     c++;
	add R4,R4,#1
	.dbline 91
; 	cr--;
	mvn R0,#0
	add R5,R5,R0
	.dbline 92
;   }
L21:
	.dbline 86
	mov R0,R5
	mov R1,R4
	cmp R1,R0
	blo L20
	.dbline -2
L19:
	ldmfd R13!,{R4,R5,R6,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
	.dbsym r tmp 6 c
	.dbsym r cr 5 pc
	.dbsym r l 5 l
	.dbsym r c 4 pc
	.dbend
	EXPORT _mainloop
	.dbfunc e mainloop _mainloop fV
	AREA	"C$$code", CODE, READONLY
	ALIGN	4
L130:
	DCD L80
	DCD L82
	DCD L86
	DCD L91
	AREA	"Cidata", RAMFUNC
	CODE32
	ALIGN 4
	AREA	"C$$code", CODE, READONLY
	ALIGN	4
L131:
	DCD L97
	DCD L101
	DCD L109
	DCD L114
	DCD L24
	DCD L24
	DCD L24
	DCD L24
	DCD L24
	DCD L24
	DCD L123
	DCD L125
	DCD L127
	AREA	"Cidata", RAMFUNC
	CODE32
	ALIGN 4
	AREA	"Cidata", RAMFUNC
	CODE32
	ALIGN 4
;        newChar -> R8
; lastDVSEventTime -> R7
;    newDVSEvent -> R8
;         eventT -> R8
;         eventA -> R9
; newDVSEventTime -> R9
_mainloop:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R7,R8,R9,R11,R12,R14}
	mov R11,R13
	sub R13,R13,#0x8
	.dbline -1
	.dbline 99
; 
; }
; 	  
; // *****************************************************************************
; // *****************************************************************************
; #pragma ramfunc mainloop
; void mainloop(void) {
	.dbline 105
;   unsigned long newChar;
;   unsigned long newDVSEvent;
;   unsigned long lastDVSEventTime, newDVSEventTime;
;   unsigned long eventA, eventT;
; 
;   nextTimer1msValue = T0_TC + 100; 		 	   // start reporting after 1000 ms
	ldr R4,[pc]
	mov pc,pc
	DCD -536854520
	ldr R4,[R4,#0]
	add R4,R4,#100
	ldr R5,[pc]
	mov pc,pc
	DCD _nextTimer1msValue
	str R4,[R5,#0]
	.dbline 106
;   nextTimer2msValue = nextTimer1msValue; 	   // same time here
	ldr R4,[pc]
	mov pc,pc
	DCD _nextTimer1msValue
	ldr R4,[R4,#0]
	ldr R5,[pc]
	mov pc,pc
	DCD _nextTimer2msValue
	str R4,[R5,#0]
	.dbline 107
;   nextTimer10msValue = nextTimer1msValue; 	   // same time here
	ldr R4,[pc]
	mov pc,pc
	DCD _nextTimer1msValue
	ldr R4,[R4,#0]
	ldr R5,[pc]
	mov pc,pc
	DCD _nextTimer10msValue
	str R4,[R5,#0]
	.dbline 108
;   nextTimer100msValue = nextTimer1msValue; 	   // same time here
	ldr R4,[pc]
	mov pc,pc
	DCD _nextTimer1msValue
	ldr R4,[R4,#0]
	ldr R5,[pc]
	mov pc,pc
	DCD _nextTimer100msValue
	str R4,[R5,#0]
	.dbline 109
;   nextTimer1000msValue = nextTimer1msValue;    // same time here
	ldr R4,[pc]
	mov pc,pc
	DCD _nextTimer1msValue
	ldr R4,[R4,#0]
	ldr R5,[pc]
	mov pc,pc
	DCD _nextTimer1000msValue
	str R4,[R5,#0]
L24:
	.dbline 120
; 
; // *****************************************************************************
; //    Main Loop Start
; // *****************************************************************************
; MLStart:
; 
; // *****************************************************************************
; //    LEDIterate();
; // *****************************************************************************
; #ifndef TIME_OPTIMIZED
;   if (ledState) {
	ldr R4,[pc]
	mov pc,pc
	DCD _ledState
	ldr R4,[R4,#0]
	cmp R4,#0
	beq L25
	.dbline 120
	.dbline 121
;     if (ledState > 0) {
	ldr R4,[pc]
	mov pc,pc
	DCD _ledState
	ldr R4,[R4,#0]
	cmp R4,#0
	ble L27
	.dbline 121
	.dbline 122
;       ledState--;
	ldr R4,[pc]
	mov pc,pc
	DCD _ledState
	ldr R5,[R4,#0]
	sub R5,R5,#1
	str R5,[R4,#0]
	.dbline 123
; 	  if (ledState == 1) {
	ldr R4,[pc]
	mov pc,pc
	DCD _ledState
	ldr R4,[R4,#0]
	cmp R4,#1
	bne L28
	.dbline 123
	.dbline 124
; 	    ledState = 0;
	mov R4,#0
	ldr R5,[pc]
	mov pc,pc
	DCD _ledState
	str R4,[R5,#0]
	.dbline 125
; 	    LED_OFF();
	.dbline 125
	mov R4,#8192
	ldr R5,[pc]
	mov pc,pc
	DCD 1073725464
	str R4,[R5,#0]
	.dbline 125
	.dbline 125
	.dbline 126
; 	  }
	.dbline 127
;     } else {
	b L28
L27:
	.dbline 127
	.dbline 128
;       ledState++;
	ldr R4,[pc]
	mov pc,pc
	DCD _ledState
	ldr R5,[R4,#0]
	add R5,R5,#1
	str R5,[R4,#0]
	.dbline 129
; 	  if (ledState == 0) {
	ldr R4,[pc]
	mov pc,pc
	DCD _ledState
	ldr R4,[R4,#0]
	cmp R4,#0
	bne L31
	.dbline 129
	.dbline 130
; 	    LED_TOGGLE();
	.dbline 130
	ldr R4,[pc]
	mov pc,pc
	DCD 1073725460
	ldr R4,[R4,#0]
	tst R4,#8192
	beq L33
	.dbline 130
	.dbline 130
	.dbline 130
	mov R4,#8192
	ldr R5,[pc]
	mov pc,pc
	DCD 1073725468
	str R4,[R5,#0]
	.dbline 130
	.dbline 130
	.dbline 130
	b L34
L33:
	.dbline 130
	.dbline 130
	.dbline 130
	mov R4,#8192
	ldr R5,[pc]
	mov pc,pc
	DCD 1073725464
	str R4,[R5,#0]
	.dbline 130
	.dbline 130
	.dbline 130
L34:
	.dbline 130
	.dbline 130
	.dbline 131
;   	    ledState = ((long) -50000);
	ldr R4,[pc]
	mov pc,pc
	DCD -50000
	ldr R5,[pc]
	mov pc,pc
	DCD _ledState
	str R4,[R5,#0]
	.dbline 132
;       }
L31:
	.dbline 133
;     }
L28:
	.dbline 134
;   }
L25:
	.dbline 140
; #endif  // #ifndef TIME_OPTIMIZED
; 
; // *****************************************************************************
; //    UARTIterate();
; // *****************************************************************************
;   if (UART0_LSR & 0x01) {				   // char arrived?
	ldr R4,[pc]
	mov pc,pc
	DCD -536821740
	ldr R4,[R4,#0]
	tst R4,#1
	beq L35
	.dbline 140
	.dbline 141
;     newChar = UART0_RBR;
	ldr R4,[pc]
	mov pc,pc
	DCD -536821760
	ldr R8,[R4,#0]
	.dbline 142
;     UARTParseNewChar(newChar);
	mov R4,R8
	and R0,R4,#255
	bl _UARTParseNewChar
	.dbline 143
;   }
L35:
L37:
	.dbline 149
; 
; // *****************************************************************************
; //    fetchEventsIterate();
; // *****************************************************************************
; DVSFetchNewEvents:
;   newDVSEventTime = T1_CR0;
	ldr R4,[pc]
	mov pc,pc
	DCD -536838100
	ldr R9,[R4,#0]
	.dbline 151
; 
;   if (lastDVSEventTime != newDVSEventTime) {
	cmp R7,R9
	beq L38
	.dbline 151
	.dbline 153
; 
;     newDVSEvent = (FGPIO_IOPIN & PIN_ALL_ADDR) >> 16;			// fetch event
	ldr R4,[pc]
	mov pc,pc
	DCD 2147418112
	ldr R5,[pc]
	mov pc,pc
	DCD 1073725460
	ldr R5,[R5,#0]
	and R4,R5,R4
	mov R8,R4,lsr #16
	.dbline 154
;     lastDVSEventTime = newDVSEventTime;
	mov R7,R9
	.dbline 166
; 
; #ifdef INCLUDE_PIXEL_CUTOUT_REGION
;     {
; 	  unsigned long pX = ((newDVSEvent>>8) & 0x7F);
; 	  unsigned long pY = ((newDVSEvent)    & 0x7F);
; 
; 	  if ((pixelCutoutMinX <= pX) && (pixelCutoutMaxX >= pX) &&
; 	  	  (pixelCutoutMinY <= pY) && (pixelCutoutMaxY >= pY)) {
; #endif
; 
; 														// increase write pointer
;     eventBufferWritePointer = ((eventBufferWritePointer+1) & DVS_EVENTBUFFER_MASK);
	ldr R4,LIT_mainloop+0
	ldr R5,LIT_mainloop+4
	ldr R6,[R4,#0]
	add R6,R6,#1
	and R5,R6,R5
	str R5,[R4,#0]
	.dbline 167
;     eventBufferA[eventBufferWritePointer] = newDVSEvent;   	 	// store event
	ldr R4,LIT_mainloop+0
	ldr R4,[R4,#0]
	mov R5,#2
	mul R4,R5,R4
	ldr R5,LIT_mainloop+8
	mov R6,R8
	strh R6,[R4,+R5]
	.dbline 168
;     eventBufferT[eventBufferWritePointer] = newDVSEventTime;	// store event time
	ldr R4,LIT_mainloop+0
	ldr R4,[R4,#0]
	mov R5,#4
	mul R4,R5,R4
	ldr R5,LIT_mainloop+12
	str R9,[R4,+R5]
	.dbline 171
; 
; 	
;     if (eventBufferWritePointer == eventBufferReadPointer) {
	ldr R4,LIT_mainloop+16
	ldr R4,[R4,#0]
	ldr R5,LIT_mainloop+0
	ldr R5,[R5,#0]
	cmp R5,R4
	bne L40
	.dbline 171
	.dbline 172
;       eventBufferReadPointer = ((eventBufferReadPointer+1) & DVS_EVENTBUFFER_MASK);
	ldr R4,LIT_mainloop+16
	ldr R5,LIT_mainloop+4
	ldr R6,[R4,#0]
	add R6,R6,#1
	and R5,R6,R5
	str R5,[R4,#0]
	.dbline 174
; 
;       LEDSetState(1000);	   							// indicate buffer overflow by LED (will turn out after some 10th of seconds)
	mov R0,#1000
	bl _LEDSetState
	.dbline 179
; 
; #ifdef INCLUDE_MARK_BUFFEROVERFLOW
;       eventBufferA[eventBufferWritePointer] |= OVERFLOW_BIT; // high bit set denotes buffer overflow
; #endif
;     }
L40:
	.dbline 240
; 
; #ifdef INCLUDE_TRACK_HF_LED
;     {
; 
; #ifndef INCLUDE_PIXEL_CUTOUT_REGION
; 	  unsigned long pX = ((newDVSEvent>>8) & 0x7F);	  		// if not yet computed, do here
; 	  unsigned long pY = ((newDVSEvent)    & 0x7F);
; #endif
; 	  unsigned long pP = ((newDVSEvent>>7) & 0x01);			// extract polarity
; 	  unsigned long newDVSEventTimeUS;
; 	  signed long eventTimeDiff, targetTimeDiff;
; 	  signed long factorOld, factorNew;
; 	  signed long dX, dY, dXY;
; 	  long n;
; 
; 	  newDVSEventTimeUS = (newDVSEventTime>>TIMESTAMP_SHIFTBITS);	    // keep "requested" part of timestamp
; 	  newDVSEventTimeUS &= 0xFFFF;
; 
; 	  if (pP==0) {	  						  					   		// consider only "on"-events
; 	    eventTimeDiff = newDVSEventTimeUS - tsMemory[pX][pY];			// compute time difference between consecutive on events
; 		if (eventTimeDiff < 0) eventTimeDiff += BIT(16);				// in case of overrun -> fix
; 	    tsMemory[pX][pY] = ((unsigned short) newDVSEventTimeUS);		// remember current time
; 
; 		pX = pX<<8;
; 		pY = pY<<8;
; 
; 		for (n=0; n<4; n++) {
; 		  targetTimeDiff = trackingHFLDesiredTimeDiff[n]-eventTimeDiff; 	// compute time Difference to target Frequency -> [-x ... +x]
; 		  if (targetTimeDiff<0) targetTimeDiff=-targetTimeDiff;				// change to absolute difference -> [0 ... +x]
; 
; 		  if (targetTimeDiff<32) {											// too far away? ignore this event!
; 		    targetTimeDiff = targetTimeDiff*targetTimeDiff;					// square timeDiff to penalize larger distances -> [0 ... 4096]
; 
; 			dX = ((((signed long) trackingHFLCenterX[n]) - ((signed long) pX))>>8); if (dX<0) dX=-dX;		// compute spatial distance between new and old pixel
; 			dY = ((((signed long) trackingHFLCenterY[n]) - ((signed long) pY))>>8); if (dY<0) dY=-dY;
; 
; 			dX = dX*dX*dX;
; 			dY = dY*dY*dY;
; 			dXY = dX + dY;
; 
; //#define MAX_DIFF (52*64)
; #define MAX_DIFF (8*64)
; 			if (dXY>MAX_DIFF) dXY=MAX_DIFF;
; 			
; 			factorNew = (4*64*64) - targetTimeDiff - dXY;	   			  	// contribution of "new" position [0..4096]
; 			if (factorNew<0) factorNew=0;
; 
; 		    factorOld =   65536 - factorNew;								// contribution of "old" position
; 
; 		    trackingHFLCenterX[n] = ((factorOld * trackingHFLCenterX[n]) + (factorNew * pX)) >> 16;		// update estimate of source
; 		    trackingHFLCenterY[n] = ((factorOld * trackingHFLCenterY[n]) + (factorNew * pY)) >> 16;		// update estimate of source
; 
; 		    trackingHFLCenterC[n] = (((65536-(64)) * trackingHFLCenterC[n]) + (64* (16*factorNew))) >> 16;	// update certainty [0..65536]
; 		  }
; 		}
;       }
; 
;     }
; #endif
; 
;     eventCounterTotal++;
	ldr R4,LIT_mainloop+20
	ldr R5,[R4,#0]
	add R5,R5,#1
	str R5,[R4,#0]
	.dbline 241
;     if (newDVSEvent & MEM_ADDR_P) {
	tst R8,#128
	beq L42
	.dbline 241
	.dbline 242
;       eventCounterOff++;
	ldr R4,LIT_mainloop+24
	ldr R5,[R4,#0]
	add R5,R5,#1
	str R5,[R4,#0]
	.dbline 243
;     } else {
	b L43
L42:
	.dbline 243
	.dbline 244
;       eventCounterOn++;
	ldr R4,LIT_mainloop+28
	ldr R5,[R4,#0]
	add R5,R5,#1
	str R5,[R4,#0]
	.dbline 245
;     }
L43:
	.dbline 250
; #ifdef INCLUDE_PIXEL_CUTOUT_REGION
;     }
;   }
; #endif
;   }
L38:
	.dbline 256
; 
; 
; 
; // *****************************************************************************
; // *****************************************************************************
;   currentTimerValue = T0_TC;
	ldr R4,LIT_mainloop+32
	ldr R4,[R4,#0]
	ldr R5,LIT_mainloop+36
	str R4,[R5,#0]
	.dbline 261
; 
; // *****************************************************************************
; //    stuff to do every 1ms
; // *****************************************************************************
;   if (currentTimerValue >= nextTimer1msValue) {
	ldr R4,LIT_mainloop+40
	ldr R4,[R4,#0]
	ldr R5,LIT_mainloop+36
	ldr R5,[R5,#0]
	cmp R5,R4
	blo L44
	.dbline 261
	.dbline 262
;     nextTimer1msValue += 1; 				      // start the next 1ms interval
	ldr R4,LIT_mainloop+40
	ldr R5,[R4,#0]
	add R5,R5,#1
	str R5,[R4,#0]
	.dbline 327
; 
; #ifdef INCLUDE_TRACK_HF_LED
; 	{
; 	  long n;
;       for (n=0; n<4; n++) {
; 		trackingHFLCenterC[n] = (((65536-(64*64)) * trackingHFLCenterC[n]) + (0)) >> 16;  	  	 	// decay certainty
;       }
; 	}
; #endif
; 
; #ifdef INCLUDE_TRACK_HF_LED
;   #ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
; 
;     if (EP_TrackHFP_ServoEnabled) {
; 
;       if ((trackingHFLCenterC[2]) > 512) {
; 		TrackHFL_PWM0 -= ( (((signed long) (trackingHFLCenterX[2])) - ((signed long) (16384+500)) ) >> 10);
; 		TrackHFL_PWM1 -= ( (((signed long) (trackingHFLCenterY[2])) - ((signed long) (16384-1000)) ) >> 10);
; 
;     #ifdef INCLUDE_TRACK_HF_LED_LASERPOINTER
;         FGPIO_IOCLR  = PIN_TRACK_HFL_LASER;		// low -> laser on
;     #endif
; 
;       } else {
; 
; 	    signed long error;
; 		error = (((signed long) 6000)-((signed long) TrackHFL_PWM0));
; 		if (error > 0) TrackHFL_PWM0++;
; 		if (error < 0) TrackHFL_PWM0--;
; 
; 		error = (((signed long) 5200)-((signed long) TrackHFL_PWM1));
; 		if (error > 0) TrackHFL_PWM1++;
; 		if (error < 0) TrackHFL_PWM1--;
; 
;     #ifdef INCLUDE_TRACK_HF_LED_LASERPOINTER
;         FGPIO_IOSET  = PIN_TRACK_HFL_LASER;		// high -> laser off
;     #endif
;       }
; 
;       // limit max and min values
; #define SERVO_CENTER 6000
; #define SERVO_DELTA  2500
; 
;       if (TrackHFL_PWM0 < (SERVO_CENTER-SERVO_DELTA)) TrackHFL_PWM0 = (SERVO_CENTER-SERVO_DELTA);
;       if (TrackHFL_PWM1 < (SERVO_CENTER-SERVO_DELTA)) TrackHFL_PWM1 = (SERVO_CENTER-SERVO_DELTA);
; 
;       if (TrackHFL_PWM0 > (SERVO_CENTER+SERVO_DELTA)) TrackHFL_PWM0 = (SERVO_CENTER+SERVO_DELTA);
;       if (TrackHFL_PWM1 > (SERVO_CENTER+SERVO_DELTA)) TrackHFL_PWM1 = (SERVO_CENTER+SERVO_DELTA);
; 
; //      PWM246SetSignal(1, TrackHFL_PWM1);
; //      PWM246SetSignal(2, TrackHFL_PWM0);
;       PWM_MR4 = TrackHFL_PWM1;		// update PWM4
;       PWM_MR6 = TrackHFL_PWM0;		// update PWM6
;       PWM_LER = BIT(4) | BIT(6);	// allow changes of MR4 and MR6 on next counter reset
;     }
;   #endif
; #endif
; 
; //}  // end of 1ms
; 
; 
; // *****************************************************************************
; //    stuff to do every 2ms
; // *****************************************************************************
;   if (currentTimerValue >= nextTimer2msValue) {
	ldr R4,LIT_mainloop+44
	ldr R4,[R4,#0]
	ldr R5,LIT_mainloop+36
	ldr R5,[R5,#0]
	cmp R5,R4
	blo L46
	.dbline 327
	.dbline 328
;     nextTimer2msValue += 2; 				      // start the next 2ms interval
	ldr R4,LIT_mainloop+44
	ldr R5,[R4,#0]
	add R5,R5,#2
	str R5,[R4,#0]
	.dbline 335
; //  }  // end of 2ms
; 
; 
; // *****************************************************************************
; //    stuff to do every 10ms
; // *****************************************************************************
;   if (currentTimerValue >= nextTimer10msValue) {
	ldr R4,LIT_mainloop+48
	ldr R4,[R4,#0]
	ldr R5,LIT_mainloop+36
	ldr R5,[R5,#0]
	cmp R5,R4
	blo L48
	.dbline 335
	.dbline 336
;     nextTimer10msValue += 10; 				 	 // start the next 10ms interval
	ldr R4,LIT_mainloop+48
	ldr R5,[R4,#0]
	add R5,R5,#10
	str R5,[R4,#0]
	.dbline 367
; 
; // ** report tracked object position
; #ifdef INCLUDE_TRACK_HF_LED
;     if (transmitTrackHFLED) {
; 	  dataForTransmission[ 0] = (trackingHFLCenterX[0]) >> 8;
; 	  dataForTransmission[ 1] = (trackingHFLCenterY[0]) >> 8;
; 	  dataForTransmission[ 2] = ((trackingHFLCenterC[0]) >> 8) & 0xFF;		// [0..255]
; 
; 	  dataForTransmission[ 3] = (trackingHFLCenterX[1]) >> 8;
; 	  dataForTransmission[ 4] = (trackingHFLCenterY[1]) >> 8;
; 	  dataForTransmission[ 5] = ((trackingHFLCenterC[1]) >> 8) & 0xFF;		// [0..255]
; 
; 	  dataForTransmission[ 6] = (trackingHFLCenterX[2]) >> 8;
; 	  dataForTransmission[ 7] = (trackingHFLCenterY[2]) >> 8;
; 	  dataForTransmission[ 8] = ((trackingHFLCenterC[2]) >> 8) & 0xFF;		// [0..255]
; 
; 	  dataForTransmission[ 9] = (trackingHFLCenterX[3]) >> 8;
; 	  dataForTransmission[10] = (trackingHFLCenterY[3]) >> 8;
; 	  dataForTransmission[11] = ((trackingHFLCenterC[3]) >> 8) & 0xFF;		// [0..255]
; 
; 	  transmitSpecialData(12);
;     }
; #endif
; 
; //  }  // end of 10ms
; 
; 
; // *****************************************************************************
; //    stuff to do every 100ms
; // *****************************************************************************
;   if (currentTimerValue >= nextTimer100msValue) {
	ldr R4,LIT_mainloop+52
	ldr R4,[R4,#0]
	ldr R5,LIT_mainloop+36
	ldr R5,[R5,#0]
	cmp R5,R4
	blo L50
	.dbline 367
	.dbline 368
;     nextTimer100msValue += 100; 				// start the next 100ms interval
	ldr R4,LIT_mainloop+52
	ldr R5,[R4,#0]
	add R5,R5,#100
	str R5,[R4,#0]
	.dbline 371
; 
; 					   	  					   // ** report counted events
;     if (transmitEventRateEnable) {
	ldr R4,LIT_mainloop+56
	ldr R4,[R4,#0]
	cmp R4,#0
	beq L52
	.dbline 371
	.dbline 372
; 	  dataForTransmission[0] = ((((unsigned long) eventCounterOff  )    ) & 0x3F) + 32;
	ldr R4,LIT_mainloop+24
	ldr R4,[R4,#0]
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_mainloop+60
	strb R4,[R5,#0]
	.dbline 373
; 	  dataForTransmission[1] = ((((unsigned long) eventCounterOff  )>> 6) & 0x3F) + 32;
	ldr R4,LIT_mainloop+24
	ldr R4,[R4,#0]
	mov R4,R4,lsr #6
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_mainloop+64
	strb R4,[R5,#0]
	.dbline 374
; 	  dataForTransmission[2] = ((((unsigned long) eventCounterOff  )>>12) & 0x3F) + 32;
	ldr R4,LIT_mainloop+24
	ldr R4,[R4,#0]
	mov R4,R4,lsr #12
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_mainloop+68
	strb R4,[R5,#0]
	.dbline 375
; 	  dataForTransmission[3] = ((((unsigned long) eventCounterOn   )    ) & 0x3F) + 32;
	ldr R4,LIT_mainloop+28
	ldr R4,[R4,#0]
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_mainloop+72
	strb R4,[R5,#0]
	.dbline 376
; 	  dataForTransmission[4] = ((((unsigned long) eventCounterOn   )>> 6) & 0x3F) + 32;
	ldr R4,LIT_mainloop+28
	ldr R4,[R4,#0]
	mov R4,R4,lsr #6
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_mainloop+76
	strb R4,[R5,#0]
	.dbline 377
; 	  dataForTransmission[5] = ((((unsigned long) eventCounterOn   )>>12) & 0x3F) + 32;
	ldr R4,LIT_mainloop+28
	ldr R4,[R4,#0]
	mov R4,R4,lsr #12
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_mainloop+80
	strb R4,[R5,#0]
	.dbline 378
; 	  dataForTransmission[6] = ((((unsigned long) eventCounterTotal)    ) & 0x3F) + 32;
	ldr R4,LIT_mainloop+20
	ldr R4,[R4,#0]
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_mainloop+84
	strb R4,[R5,#0]
	.dbline 379
; 	  dataForTransmission[7] = ((((unsigned long) eventCounterTotal)>> 6) & 0x3F) + 32;
	ldr R4,LIT_mainloop+20
	ldr R4,[R4,#0]
	mov R4,R4,lsr #6
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_mainloop+88
	strb R4,[R5,#0]
	.dbline 380
; 	  dataForTransmission[8] = ((((unsigned long) eventCounterTotal)>>12) & 0x3F) + 32;
	ldr R4,LIT_mainloop+20
	ldr R4,[R4,#0]
	mov R4,R4,lsr #12
	and R4,R4,#63
	add R4,R4,#32
	ldr R5,LIT_mainloop+92
	strb R4,[R5,#0]
	.dbline 381
; 	  transmitSpecialData(9);
	mov R0,#9
	bl _transmitSpecialData
	.dbline 382
;     }
L52:
	.dbline 383
;     eventCounterTotal = 0;
	mov R4,#0
	ldr R5,LIT_mainloop+20
	str R4,[R5,#0]
	.dbline 384
;     eventCounterOn    = 0;
	mov R4,#0
	ldr R5,LIT_mainloop+28
	str R4,[R5,#0]
	.dbline 385
;     eventCounterOff   = 0;
	mov R4,#0
	ldr R5,LIT_mainloop+24
	str R4,[R5,#0]
	.dbline 393
; 
; //  }  // end of 100ms
; 
; 
; // *****************************************************************************
; //    stuff to do every 1000ms
; // *****************************************************************************
;   if (currentTimerValue >= nextTimer1000msValue) {
	ldr R4,LIT_mainloop+96
	ldr R4,[R4,#0]
	ldr R5,LIT_mainloop+36
	ldr R5,[R5,#0]
	cmp R5,R4
	blo L62
	.dbline 393
	.dbline 394
;     nextTimer1000msValue += 1000; 			   // start the next 1000ms interval
	ldr R4,LIT_mainloop+96
	ldr R5,[R4,#0]
	add R5,R5,#1000
	str R5,[R4,#0]
	.dbline 396
; 
;   }  // end of 1000ms
L62:
	.dbline 397
;   }  // end of  100ms
L50:
	.dbline 398
;   }  // end of   10ms
L48:
	.dbline 399
;   }  // end of    2ms
L46:
	.dbline 400
;   }  // end of    1ms
L44:
L64:
	.dbline 407
; 
; 
; // *****************************************************************************
; //    stuff left to send?
; // *****************************************************************************
; MainLoopSendEvents:
;   if ((FGPIO_IOPIN & PIN_UART0_RTS) !=0 ) {			// no rts stop signal
	ldr R4,LIT_mainloop+100
	ldr R4,[R4,#0]
	tst R4,#256
	beq L69
	.dbline 407
	.dbline 408
; 	goto MLProcessEvents;
	b L67
L68:
	.dbline 411
;   }
; 
;   while ((TXBufferIndex) && (UART0_LSR & BIT(5))) {
	.dbline 412
;     TXBufferIndex--;
	ldr R4,LIT_mainloop+104
	ldr R5,[R4,#0]
	sub R5,R5,#1
	str R5,[R4,#0]
	.dbline 413
;     UART0_THR = TXBuffer[TXBufferIndex];
	ldr R4,LIT_mainloop+108
	ldr R5,LIT_mainloop+104
	ldr R5,[R5,#0]
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+112
	str R4,[R5,#0]
	.dbline 414
;   }
L69:
	.dbline 411
	ldr R4,LIT_mainloop+104
	ldr R4,[R4,#0]
	cmp R4,#0
	beq L71
	ldr R4,LIT_mainloop+116
	ldr R4,[R4,#0]
	tst R4,#32
	bne L68
L71:
L67:
	.dbline 424
; 
; // *****************************************************************************
; //    processEventsIterate();
; // *****************************************************************************
; MLProcessEvents:
; 
; // *****************************************************************************
; //    fetchNewEvent();  (and process event)
; // *****************************************************************************
;   if (TXBufferIndex) {										// wait for TX to finish sending!
	ldr R4,LIT_mainloop+104
	ldr R4,[R4,#0]
	cmp R4,#0
	.dbline 424
	.dbline 425
;     goto MLStart;
	bne L24
L72:
	.dbline 427
;   }
;   if (eventBufferWritePointer == eventBufferReadPointer) {	// more events in buffer to process?
	ldr R4,LIT_mainloop+16
	ldr R4,[R4,#0]
	ldr R5,LIT_mainloop+0
	ldr R5,[R5,#0]
	cmp R5,R4
	.dbline 427
	.dbline 428
;     goto MLStart;
	beq L24
L74:
	.dbline 431
;   }
;    		 		 			  	 						 	// fetch event
;   eventBufferReadPointer = ((eventBufferReadPointer+1) & DVS_EVENTBUFFER_MASK);
	ldr R4,LIT_mainloop+16
	ldr R5,LIT_mainloop+4
	ldr R6,[R4,#0]
	add R6,R6,#1
	and R5,R6,R5
	str R5,[R4,#0]
	.dbline 432
;   eventA = eventBufferA[eventBufferReadPointer];
	ldr R4,LIT_mainloop+16
	ldr R4,[R4,#0]
	mov R5,#2
	mul R4,R5,R4
	ldr R5,LIT_mainloop+8
	ldrh R4,[R4,+R5]
	mov R9,R4
	.dbline 433
;   eventT = eventBufferT[eventBufferReadPointer];
	ldr R4,LIT_mainloop+16
	ldr R4,[R4,#0]
	mov R5,#4
	mul R4,R5,R4
	ldr R5,LIT_mainloop+12
	ldr R8,[R4,+R5]
	.dbline 435
; 
;   if (enableEventSending) {
	ldr R4,LIT_mainloop+120
	ldr R4,[R4,#0]
	cmp R4,#0
	beq L24
	.dbline 435
	.dbline 436
;     switch (eDVSDataFormat) {
	ldr R4,LIT_mainloop+124
	ldr R4,[R4,#0]
	cmp R4,#3
	bgt L129
	mov R5,#4
	mul R4,R5,R4
	ldr R5,LIT_mainloop+128
	ldr R4,[R4,+R5]
	mov R15,R4
X0:
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
L129:
	ldr R4,LIT_mainloop+124
	ldr R4,[R4,#0]
	cmp R4,#20
	blt L24
	cmp R4,#32
	bgt L24
	mov R5,#4
	mul R4,R5,R4
	ldr R5,LIT_mainloop+132
	ldr R4,[R4,+R5]
	mov R15,R4
X1:
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
	.dbline 436
L80:
	.dbline 439
; 
; 	case EDVS_DATA_FORMAT_BIN:
;       TXBuffer[1] = ((eventA>>8) & 0xFF);				  // 1st byte to send (Y-address)
	mov R4,R9,lsr #8
	and R4,R4,#255
	ldr R5,LIT_mainloop+136
	strb R4,[R5,#0]
	.dbline 440
;       TXBuffer[0] = ((eventA)    & 0xFF);				  // 2nd byte to send (X-address)
	and R4,R9,#255
	ldr R5,LIT_mainloop+108
	strb R4,[R5,#0]
	.dbline 441
;       TXBufferIndex = 2; break;
	mov R4,#2
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 441
	b L24
L82:
	.dbline 444
; 
;     case EDVS_DATA_FORMAT_BIN_TS2B:
;       TXBuffer[3] = ((eventA>>8) & 0xFF);				  // 1st byte to send (Y-address)
	mov R4,R9,lsr #8
	and R4,R4,#255
	ldr R5,LIT_mainloop+140
	strb R4,[R5,#0]
	.dbline 445
;       TXBuffer[2] = ((eventA)    & 0xFF);				  // 2nd byte to send (X-address)
	and R4,R9,#255
	ldr R5,LIT_mainloop+144
	strb R4,[R5,#0]
	.dbline 446
;       TXBuffer[1] = ((eventT>> (TIMESTAMP_SHIFTBITS+8)) & 0xFF);	// 3rd byte to send (time stamp high byte)
	mov R4,R8,lsr #14
	and R4,R4,#255
	ldr R5,LIT_mainloop+136
	strb R4,[R5,#0]
	.dbline 447
;       TXBuffer[0] = ((eventT>> (TIMESTAMP_SHIFTBITS)  ) & 0xFF);	// 4th byte to send (time stamp low byte)
	mov R4,R8,lsr #6
	and R4,R4,#255
	ldr R5,LIT_mainloop+108
	strb R4,[R5,#0]
	.dbline 448
;       TXBufferIndex = 4; break;
	mov R4,#4
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 448
	b L24
L86:
	.dbline 451
; 
;     case EDVS_DATA_FORMAT_BIN_TS3B:
;       TXBuffer[4] = ((eventA>>8) & 0xFF);				  // 1st byte to send (Y-address)
	mov R4,R9,lsr #8
	and R4,R4,#255
	ldr R5,LIT_mainloop+148
	strb R4,[R5,#0]
	.dbline 452
;       TXBuffer[3] = ((eventA)    & 0xFF);				  // 2nd byte to send (X-address)
	and R4,R9,#255
	ldr R5,LIT_mainloop+140
	strb R4,[R5,#0]
	.dbline 453
;       TXBuffer[2] = ((eventT>> (TIMESTAMP_SHIFTBITS+16)) & 0xFF);	// 3rd byte to send (time stamp high byte)
	mov R4,R8,lsr #22
	and R4,R4,#255
	ldr R5,LIT_mainloop+144
	strb R4,[R5,#0]
	.dbline 454
;       TXBuffer[1] = ((eventT>> (TIMESTAMP_SHIFTBITS+ 8)) & 0xFF);	// 4th byte to send (time stamp)
	mov R4,R8,lsr #14
	and R4,R4,#255
	ldr R5,LIT_mainloop+136
	strb R4,[R5,#0]
	.dbline 455
;       TXBuffer[0] = ((eventT>> (TIMESTAMP_SHIFTBITS)   ) & 0xFF);	// 5th byte to send (time stamp low byte)
	mov R4,R8,lsr #6
	and R4,R4,#255
	ldr R5,LIT_mainloop+108
	strb R4,[R5,#0]
	.dbline 456
;       TXBufferIndex = 5; break;
	mov R4,#5
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 456
	b L24
L91:
	.dbline 459
; 
;     case EDVS_DATA_FORMAT_BIN_TS4B:
;       TXBuffer[5] = ((eventA>> ( 8)) & 0xFF);			  // 1st byte to send (Y-address)
	mov R4,R9,lsr #8
	and R4,R4,#255
	ldr R5,LIT_mainloop+152
	strb R4,[R5,#0]
	.dbline 460
;       TXBuffer[4] = ((eventA)        & 0xFF);			  // 2nd byte to send (X-address)
	and R4,R9,#255
	ldr R5,LIT_mainloop+148
	strb R4,[R5,#0]
	.dbline 461
;       TXBuffer[3] = ((eventT>> (24)) & 0xFF);			  // 3rd byte to send (time stamp high byte)
	mov R4,R8,lsr #24
	and R4,R4,#255
	ldr R5,LIT_mainloop+140
	strb R4,[R5,#0]
	.dbline 462
;       TXBuffer[2] = ((eventT>> (16)) & 0xFF);			  // 4th byte to send (time stamp)
	mov R4,R8,lsr #16
	and R4,R4,#255
	ldr R5,LIT_mainloop+144
	strb R4,[R5,#0]
	.dbline 463
;       TXBuffer[1] = ((eventT>> ( 8)) & 0xFF);			  // 5th byte to send (time stamp)
	mov R4,R8,lsr #8
	and R4,R4,#255
	ldr R5,LIT_mainloop+136
	strb R4,[R5,#0]
	.dbline 464
;       TXBuffer[0] = ((eventT       ) & 0xFF);			  // 6th byte to send (time stamp low byte)
	and R4,R8,#255
	ldr R5,LIT_mainloop+108
	strb R4,[R5,#0]
	.dbline 465
;       TXBufferIndex = 6; break;
	mov R4,#6
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 465
	b L24
L97:
	.dbline 468
; 
;     case EDVS_DATA_FORMAT_HEX:
;       TXBuffer[3] = hexLookupTable[((eventA>>12) & 0x0F)]; // 1st byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #12
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+140
	strb R4,[R5,#0]
	.dbline 469
;       TXBuffer[2] = hexLookupTable[((eventA>> 8) & 0x0F)]; // 2nd byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #8
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+144
	strb R4,[R5,#0]
	.dbline 470
;       TXBuffer[1] = hexLookupTable[((eventA>> 4) & 0x0F)]; // 3rd byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #4
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+136
	strb R4,[R5,#0]
	.dbline 471
;       TXBuffer[0] = hexLookupTable[((eventA    ) & 0x0F)]; // 4th byte to send
	ldr R4,LIT_mainloop+156
	and R5,R9,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+108
	strb R4,[R5,#0]
	.dbline 472
; 	  TXBufferIndex = 4; break;
	mov R4,#4
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 472
	b L24
L101:
	.dbline 475
; 
; 	case EDVS_DATA_FORMAT_HEX_TS:
;       TXBuffer[7] = hexLookupTable[((eventA>>12) & 0x0F)]; // 1st byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #12
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+160
	strb R4,[R5,#0]
	.dbline 476
;       TXBuffer[6] = hexLookupTable[((eventA>> 8) & 0x0F)]; // 2nd byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #8
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+164
	strb R4,[R5,#0]
	.dbline 477
;       TXBuffer[5] = hexLookupTable[((eventA>> 4) & 0x0F)]; // 3rd byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #4
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+152
	strb R4,[R5,#0]
	.dbline 478
;       TXBuffer[4] = hexLookupTable[((eventA    ) & 0x0F)]; // 4th byte to send
	ldr R4,LIT_mainloop+156
	and R5,R9,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+148
	strb R4,[R5,#0]
	.dbline 479
;       TXBuffer[3] = hexLookupTable[((eventT>>12) & 0x0F)]; // 5th byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R8,lsr #12
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+140
	strb R4,[R5,#0]
	.dbline 480
;       TXBuffer[2] = hexLookupTable[((eventT>> 8) & 0x0F)]; // 6th byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R8,lsr #8
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+144
	strb R4,[R5,#0]
	.dbline 481
;       TXBuffer[1] = hexLookupTable[((eventT>> 4) & 0x0F)]; // 7th byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R8,lsr #4
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+136
	strb R4,[R5,#0]
	.dbline 482
;       TXBuffer[0] = hexLookupTable[((eventT)     & 0x0F)]; // 8th byte to send
	ldr R4,LIT_mainloop+156
	and R5,R8,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+108
	strb R4,[R5,#0]
	.dbline 483
; 	  TXBufferIndex = 8; break;
	mov R4,#8
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 483
	b L24
L109:
	.dbline 486
; 
;     case EDVS_DATA_FORMAT_HEX_RET:
;       TXBuffer[4] = hexLookupTable[((eventA>>12) & 0x0F)]; // 1st byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #12
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+148
	strb R4,[R5,#0]
	.dbline 487
;       TXBuffer[3] = hexLookupTable[((eventA>> 8) & 0x0F)]; // 2nd byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #8
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+140
	strb R4,[R5,#0]
	.dbline 488
;       TXBuffer[2] = hexLookupTable[((eventA>> 4) & 0x0F)]; // 3rd byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #4
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+144
	strb R4,[R5,#0]
	.dbline 489
;       TXBuffer[1] = hexLookupTable[((eventA    ) & 0x0F)]; // 4th byte to send
	ldr R4,LIT_mainloop+156
	and R5,R9,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+136
	strb R4,[R5,#0]
	.dbline 490
; 	  TXBuffer[0] = '\n';		   						  // return
	mov R4,#10
	ldr R5,LIT_mainloop+108
	strb R4,[R5,#0]
	.dbline 491
; 	  TXBufferIndex = 4; break;
	mov R4,#4
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 491
	b L24
L114:
	.dbline 494
; 
;     case EDVS_DATA_FORMAT_HEX_TS_RET:
;       TXBuffer[8] = hexLookupTable[((eventA>>12) & 0x0F)]; // 1st byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #12
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+168
	strb R4,[R5,#0]
	.dbline 495
;       TXBuffer[7] = hexLookupTable[((eventA>> 8) & 0x0F)]; // 2nd byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #8
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+160
	strb R4,[R5,#0]
	.dbline 496
;       TXBuffer[6] = hexLookupTable[((eventA>> 4) & 0x0F)]; // 3rd byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R9,lsr #4
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+164
	strb R4,[R5,#0]
	.dbline 497
;       TXBuffer[5] = hexLookupTable[((eventA    ) & 0x0F)]; // 4th byte to send
	ldr R4,LIT_mainloop+156
	and R5,R9,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+152
	strb R4,[R5,#0]
	.dbline 498
;       TXBuffer[4] = hexLookupTable[((eventT>>12) & 0x0F)]; // 5th byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R8,lsr #12
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+148
	strb R4,[R5,#0]
	.dbline 499
;       TXBuffer[3] = hexLookupTable[((eventT>> 8) & 0x0F)]; // 6th byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R8,lsr #8
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+140
	strb R4,[R5,#0]
	.dbline 500
;       TXBuffer[2] = hexLookupTable[((eventT>> 4) & 0x0F)]; // 7th byte to send
	ldr R4,LIT_mainloop+156
	mov R5,R8,lsr #4
	and R5,R5,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+144
	strb R4,[R5,#0]
	.dbline 501
;       TXBuffer[1] = hexLookupTable[((eventT)     & 0x0F)]; // 8th byte to send
	ldr R4,LIT_mainloop+156
	and R5,R8,#15
	ldrb R4,[R5,+R4]
	ldr R5,LIT_mainloop+136
	strb R4,[R5,#0]
	.dbline 502
; 	  TXBuffer[0] = '\n';		   						  // return
	mov R4,#10
	ldr R5,LIT_mainloop+108
	strb R4,[R5,#0]
	.dbline 503
; 	  TXBufferIndex = 9; break;
	mov R4,#9
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 503
	b L24
L123:
	.dbline 506
; 
;     case EDVS_DATA_FORMAT_ASCII:
; 	  sprintf(TXBuffer, "%1d %3d %3d\n", ((eventA>>7) & 0x01), ((eventA>>8) & 0x7F), ((eventA) & 0x7F));
	ldr R0,LIT_mainloop+108
	ldr R1,LIT_mainloop+172
	mov R4,R9,lsr #7
	and R2,R4,#1
	mov R4,R9,lsr #8
	and R3,R4,#127
	and R4,R9,#127
	str R4,[R13,#0]
	bl _sprintf
	.dbline 507
; 	  swapByteOrderInMemory(TXBuffer, 10);
	ldr R0,LIT_mainloop+108
	mov R1,#10
	bl _swapByteOrderInMemory
	.dbline 508
; 	  TXBufferIndex = 10; break;
	mov R4,#10
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 508
	b L24
L125:
	.dbline 511
; 
; 	case EDVS_DATA_FORMAT_ASCII_TS:
; 	  sprintf(TXBuffer, "%1d %3d %3d %8ld\n", ((eventA>>7) & 0x01), ((eventA>>8) & 0x7F), ((eventA) & 0x7F), ((eventT>>TIMESTAMP_SHIFTBITS)));
	ldr R0,LIT_mainloop+108
	ldr R1,LIT_mainloop+176
	mov R4,R9,lsr #7
	and R2,R4,#1
	mov R4,R9,lsr #8
	and R3,R4,#127
	and R4,R9,#127
	str R4,[R13,#0]
	mov R4,R8,lsr #6
	str R4,[R13,#+4]
	bl _sprintf
	.dbline 512
; 	  swapByteOrderInMemory(TXBuffer, 19);
	ldr R0,LIT_mainloop+108
	mov R1,#19
	bl _swapByteOrderInMemory
	.dbline 513
; 	  TXBufferIndex = 19; break;
	mov R4,#19
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 513
	b L24
L127:
	.dbline 516
; 
; 	case EDVS_DATA_FORMAT_ASCII_TSHS:
; 	  sprintf(TXBuffer, "%1d %3d %3d %10lu\n", ((eventA>>7) & 0x01), ((eventA>>8) & 0x7F), ((eventA) & 0x7F), ((eventT)));
	ldr R0,LIT_mainloop+108
	ldr R1,LIT_mainloop+180
	mov R4,R9,lsr #7
	and R2,R4,#1
	mov R4,R9,lsr #8
	and R3,R4,#127
	and R4,R9,#127
	str R4,[R13,#0]
	str R8,[R13,#+4]
	bl _sprintf
	.dbline 517
; 	  swapByteOrderInMemory(TXBuffer, 21);
	ldr R0,LIT_mainloop+108
	mov R1,#21
	bl _swapByteOrderInMemory
	.dbline 518
; 	  TXBufferIndex = 21; break;
	mov R4,#21
	ldr R5,LIT_mainloop+104
	str R4,[R5,#0]
	.dbline 518
	.dbline 520
;     }
;   }
	.dbline 525
; 
; // *****************************************************************************
; //    End of Main Loop
; // *****************************************************************************
; goto MLStart;
	b L24
X2:
	.dbline -2
L23:
	ldmfd R11,{R4,R5,R6,R7,R8,R9,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
LIT_mainloop:
	DCD _eventBufferWritePointer
	DCD 8191
	DCD _eventBufferA
	DCD _eventBufferT
	DCD _eventBufferReadPointer
	DCD _eventCounterTotal
	DCD _eventCounterOff
	DCD _eventCounterOn
	DCD -536854520
	DCD _currentTimerValue
	DCD _nextTimer1msValue
	DCD _nextTimer2msValue
	DCD _nextTimer10msValue
	DCD _nextTimer100msValue
	DCD _transmitEventRateEnable
	DCD _dataForTransmission
	DCD _dataForTransmission+1
	DCD _dataForTransmission+2
	DCD _dataForTransmission+3
	DCD _dataForTransmission+4
	DCD _dataForTransmission+5
	DCD _dataForTransmission+6
	DCD _dataForTransmission+7
	DCD _dataForTransmission+8
	DCD _nextTimer1000msValue
	DCD 1073725460
	DCD _TXBufferIndex
	DCD _TXBuffer
	DCD -536821760
	DCD -536821740
	DCD _enableEventSending
	DCD _eDVSDataFormat
	DCD L130
	DCD L131-80
	DCD _TXBuffer+1
	DCD _TXBuffer+3
	DCD _TXBuffer+2
	DCD _TXBuffer+4
	DCD _TXBuffer+5
	DCD _hexLookupTable
	DCD _TXBuffer+7
	DCD _TXBuffer+6
	DCD _TXBuffer+8
	DCD L124
	DCD L126
	DCD L128
	.dbsym r newChar 8 l
	.dbsym r lastDVSEventTime 7 l
	.dbsym r newDVSEvent 8 l
	.dbsym r eventT 8 l
	.dbsym r eventA 9 l
	.dbsym r newDVSEventTime 9 l
	.dbend
	AREA	"Cudata", NOINIT
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\MainLoop.c
	EXPORT _hexLookupTable
_hexLookupTable:
	SPACE 16
	.dbsym e hexLookupTable _hexLookupTable A[16:16]c
	EXPORT _eDVSDataFormat
	ALIGN	4
_eDVSDataFormat:
	SPACE 4
	.dbsym e eDVSDataFormat _eDVSDataFormat l
	EXPORT _dataForTransmission
_dataForTransmission:
	SPACE 16
	.dbsym e dataForTransmission _dataForTransmission A[16:16]c
	EXPORT _nextTimer1000msValue
	ALIGN	4
_nextTimer1000msValue:
	SPACE 4
	.dbsym e nextTimer1000msValue _nextTimer1000msValue l
	EXPORT _nextTimer100msValue
	ALIGN	4
_nextTimer100msValue:
	SPACE 4
	.dbsym e nextTimer100msValue _nextTimer100msValue l
	EXPORT _nextTimer10msValue
	ALIGN	4
_nextTimer10msValue:
	SPACE 4
	.dbsym e nextTimer10msValue _nextTimer10msValue l
	EXPORT _nextTimer2msValue
	ALIGN	4
_nextTimer2msValue:
	SPACE 4
	.dbsym e nextTimer2msValue _nextTimer2msValue l
	EXPORT _nextTimer1msValue
	ALIGN	4
_nextTimer1msValue:
	SPACE 4
	.dbsym e nextTimer1msValue _nextTimer1msValue l
	EXPORT _currentTimerValue
	ALIGN	4
_currentTimerValue:
	SPACE 4
	.dbsym e currentTimerValue _currentTimerValue l
	EXPORT _eventCounterOff
	ALIGN	4
_eventCounterOff:
	SPACE 4
	.dbsym e eventCounterOff _eventCounterOff l
	EXPORT _eventCounterOn
	ALIGN	4
_eventCounterOn:
	SPACE 4
	.dbsym e eventCounterOn _eventCounterOn l
	EXPORT _eventCounterTotal
	ALIGN	4
_eventCounterTotal:
	SPACE 4
	.dbsym e eventCounterTotal _eventCounterTotal l
	EXPORT _TXBuffer
_TXBuffer:
	SPACE 256
	.dbsym e TXBuffer _TXBuffer A[256:256]c
	EXPORT _transmitEventRateEnable
	ALIGN	4
_transmitEventRateEnable:
	SPACE 4
	.dbsym e transmitEventRateEnable _transmitEventRateEnable l
	IMPORT _commandLinePointer
	IMPORT _commandLine
	IMPORT _enableEventSending
	IMPORT _eventBufferReadPointer
	IMPORT _eventBufferWritePointer
	IMPORT _eventBufferT
	IMPORT _eventBufferA
	IMPORT _ledState
	AREA	"C$$code", CODE, READONLY
L128:
	DCB "%1d %3d %3d %10lu", 10, 0
L126:
	DCB "%1d %3d %3d %8ld", 10, 0
L124:
	DCB "%1d %3d %3d", 10, 0
	END
