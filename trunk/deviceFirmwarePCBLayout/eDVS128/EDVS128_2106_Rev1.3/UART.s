	.dbfile ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
	.dbfile ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
	EXPORT _putchar
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
	.dbfunc e putchar _putchar fI
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;     charToSend -> R4
_putchar:
	mov R12,R13
	stmfd R13!,{R4,R12,R14}
	mov R4,R0
	.dbline -1
	.dbline 31
; #include "EDVS128_2106.h"
; 
; // *****************************************************************************
; extern unsigned long eventBufferWritePointer, eventBufferReadPointer;
; // *****************************************************************************
; extern unsigned char TXBuffer[32];	   // this is the small buffer from mainloop
; extern unsigned long TXBufferIndex;
; 
; extern unsigned long transmitEventRateEnable;
; extern unsigned long enableEventSending;
; 
; extern unsigned long enableAutomaticEventRateControl;
; extern unsigned long requestedEventRate;
; 
; extern unsigned long eDVSDataFormat;
; 
; #ifdef INCLUDE_TRACK_HF_LED
; extern unsigned long transmitTrackHFLED;
; #endif
; #ifdef INCLUDE_PIXEL_CUTOUT_REGION
; extern unsigned long pixelCutoutMinX, pixelCutoutMaxX, pixelCutoutMinY, pixelCutoutMaxY;
; #endif
; 
; unsigned char commandLine[UART_COMMAND_LINE_MAX_LENGTH];
; unsigned long commandLinePointer;
; 
; // *****************************************************************************  
; #define UARTReturn()	   {putchar('\n');}
; 
; // *****************************************************************************
; int putchar(char charToSend) {
L2:
	.dbline 32
;   while (FGPIO_IOPIN & PIN_UART0_RTS) {  // wait while UART buffer is full
	.dbline 33
;   };
L3:
	.dbline 32
	ldr R1,LIT_putchar+0
	ldr R1,[R1,#0]
	tst R1,#256
	bne L2
	.dbline 33
L5:
	.dbline 34
;   while ((UART0_LSR & BIT(5))==0) {	  	 // wait until space in UART FIFO
	.dbline 35
;   };
L6:
	.dbline 34
	ldr R1,LIT_putchar+4
	ldr R1,[R1,#0]
	tst R1,#32
	beq L5
	.dbline 35
	.dbline 36
;   UART0_THR = charToSend;
	and R1,R4,#255
	ldr R2,LIT_putchar+8
	str R1,[R2,#0]
	.dbline 37
;   return(0);
	mov R0,#0
	.dbline -2
L1:
	ldmfd R13!,{R4,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
LIT_putchar:
	DCD 1073725460
	DCD -536821740
	DCD -536821760
	.dbsym r charToSend 4 c
	.dbend
	EXPORT _UART0SetBaudRate
	.dbfunc e UART0SetBaudRate _UART0SetBaudRate fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;       baudRate -> R6
_UART0SetBaudRate:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R11,R12,R14}
	mov R11,R13
	mov R6,R0
	.dbline -1
	.dbline 42
; }
; 
; 
; // *****************************************************************************
; void UART0SetBaudRate(unsigned long baudRate) {
	.dbline 43
;   UART0_FDR = 0x10;							// clear fractional baud rate
	mov R4,#16
	ldr R5,LIT_UART0SetBaudRate+0
	str R4,[R5,#0]
	.dbline 44
;   UART0_LCR = 0x83;							// Enable the divisor
	mov R4,#131
	ldr R5,LIT_UART0SetBaudRate+4
	str R4,[R5,#0]
	.dbline 45
;   UART0_DLM = 0x00;							// Divisor latch MSB (for baud rates < 4800) 
	mov R4,#0
	ldr R5,LIT_UART0SetBaudRate+8
	str R4,[R5,#0]
	.dbline 47
; 
;   switch (baudRate) {
	cmp R6,#230400
	beq L18
	cmp R6,#230400
	bgt L30
L29:
	cmp R6,#38400
	beq L13
	cmp R6,#38400
	bgt L32
L31:
	cmp R6,#19200
	beq L11
	cmp R6,#19200
	bgt L34
L33:
	cmp R6,#1
	beq L23
	cmp R6,#2
	beq L26
	cmp R6,#4
	beq L27
	b L9
L34:
	ldr R4,LIT_UART0SetBaudRate+12
	mov R5,R6
	cmp R5,R4
	beq L12
	b L9
L32:
	ldr R5,LIT_UART0SetBaudRate+16
	cmp R6,R5
	beq L15
	cmp R6,R5
	bgt L36
L35:
	mov R4,R6
	cmp R4,#57600
	beq L14
	b L9
L36:
	ldr R5,LIT_UART0SetBaudRate+20
	cmp R6,R5
	beq L16
	cmp R6,R5
	blt L9
L37:
	ldr R4,LIT_UART0SetBaudRate+24
	mov R5,R6
	cmp R5,R4
	beq L17
	b L9
L30:
	ldr R5,LIT_UART0SetBaudRate+28
	cmp R6,R5
	beq L23
	cmp R6,R5
	bgt L39
L38:
	ldr R5,LIT_UART0SetBaudRate+32
	cmp R6,R5
	beq L20
	cmp R6,R5
	bgt L41
L40:
	ldr R4,LIT_UART0SetBaudRate+36
	mov R5,R6
	cmp R5,R4
	beq L19
	b L9
L41:
	ldr R5,LIT_UART0SetBaudRate+40
	cmp R6,R5
	beq L21
	cmp R6,R5
	blt L9
L42:
	mov R4,R6
	cmp R4,#921600
	beq L22
	b L9
L39:
	ldr R5,LIT_UART0SetBaudRate+44
	cmp R6,R5
	beq L25
	cmp R6,R5
	bgt L44
L43:
	ldr R4,LIT_UART0SetBaudRate+48
	mov R5,R6
	cmp R5,R4
	beq L24
	b L9
L44:
	ldr R5,LIT_UART0SetBaudRate+52
	cmp R6,R5
	beq L26
	cmp R6,R5
	blt L9
L45:
	ldr R4,LIT_UART0SetBaudRate+56
	mov R5,R6
	cmp R5,R4
	beq L27
	b L9
L11:
	.dbline 79
; #if PLL_CLOCK == 112						   // all baud rates calculated for 112MHz
; 	case ((unsigned long)  460800): UART0_DLL = (0x0C); UART0_FDR = (((0x0F)<<4) | 0x04); break;
; 	case ((unsigned long)  500000): UART0_DLL = (0x0E); break;
; 	case ((unsigned long)  921600): UART0_DLL = (0x06); UART0_FDR = (((0x0F)<<4) | 0x04); break;
; 	case ((unsigned long)       1):
; 	case ((unsigned long) 1000000): UART0_DLL = (0x07); break;
; 	case ((unsigned long)       2):
; 	case ((unsigned long) 2000000): UART0_DLL = (0x03); UART0_FDR = (((0x06)<<4) | 0x01); break;
; #endif
; 
; #if PLL_CLOCK == 96						   // all baud rates calculated for 96MHz
; 	case ((unsigned long)  460800): UART0_DLL = (0x0D); break;
; 	case ((unsigned long)  500000): UART0_DLL = (0x0C); break;
; 	case ((unsigned long)  921600): UART0_DLL = (0x06); UART0_FDR = (((0x0C)<<4) | 0x01); break;
; 	case ((unsigned long)       1):
; 	case ((unsigned long) 1000000): UART0_DLL = (0x06); break;
; 	case ((unsigned long)       2):
; 	case ((unsigned long) 2000000): UART0_DLL = (0x03); break;
; 	case ((unsigned long)       3):
; 	case ((unsigned long) 3000000): UART0_DLL = (0x02); break;
; #endif
; 
; #if PLL_CLOCK == 80						   // all baud rates calculated for 80MHz
; 	case ((unsigned long)  460800): UART0_DLL = (0x08); UART0_FDR = (((0x0E)<<4) | 0x05); break;
; 	case ((unsigned long)  500000): UART0_DLL = (0x0A); break;
; 	case ((unsigned long)  921600): UART0_DLL = (0x04); UART0_FDR = (((0x0E)<<4) | 0x05); break;
; 	case ((unsigned long)       1):
; 	case ((unsigned long) 1000000): UART0_DLL = (0x05); break;
; #endif
; 
; #if PLL_CLOCK == 64			  			   // all baud rates calculated for 64MHz
; 	case ((unsigned long)   19200): UART0_DLL = (0x7D); UART0_FDR = (((0x03)<<4) | 0x02); break;
	mov R4,#125
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 79
	mov R4,#50
	ldr R5,LIT_UART0SetBaudRate+0
	str R4,[R5,#0]
	.dbline 79
	b L10
L12:
	.dbline 80
;     case ((unsigned long)   31250): UART0_DLL = (0x80); break;
	mov R4,#128
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 80
	b L10
L13:
	.dbline 81
; 	case ((unsigned long)   38400): UART0_DLL = (0x32); UART0_FDR = (((0x0C)<<4) | 0x0D); break;
	mov R4,#50
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 81
	mov R4,#205
	ldr R5,LIT_UART0SetBaudRate+0
	str R4,[R5,#0]
	.dbline 81
	b L10
L14:
	.dbline 82
; 	case ((unsigned long)   57600): UART0_DLL = (0x36); UART0_FDR = (((0x07)<<4) | 0x02); break;
	mov R4,#54
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 82
	mov R4,#114
	ldr R5,LIT_UART0SetBaudRate+0
	str R4,[R5,#0]
	.dbline 82
	b L10
L15:
	.dbline 83
;     case ((unsigned long)   62500): UART0_DLL = (0x40); break;
	mov R4,#64
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 83
	b L10
L16:
	.dbline 84
; 	case ((unsigned long)  115200): UART0_DLL = (0x1B); UART0_FDR = (((0x07)<<4) | 0x02); break;
	mov R4,#27
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 84
	mov R4,#114
	ldr R5,LIT_UART0SetBaudRate+0
	str R4,[R5,#0]
	.dbline 84
	b L10
L17:
	.dbline 85
; 	case ((unsigned long)  125000): UART0_DLL = (0x20);	break;
	mov R4,#32
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 85
	b L10
L18:
	.dbline 86
; 	case ((unsigned long)  230400): UART0_DLL = (0x09); UART0_FDR = (((0x0E)<<4) | 0x0D); break;
	mov R4,#9
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 86
	mov R4,#237
	ldr R5,LIT_UART0SetBaudRate+0
	str R4,[R5,#0]
	.dbline 86
	b L10
L19:
	.dbline 87
;     case ((unsigned long)  250000): UART0_DLL = (0x10); break;
	mov R4,#16
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 87
	b L10
L20:
	.dbline 88
; 	case ((unsigned long)  460800): UART0_DLL = (0x08); UART0_FDR = (((0x0C)<<4) | 0x01); break;
	mov R4,#8
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 88
	mov R4,#193
	ldr R5,LIT_UART0SetBaudRate+0
	str R4,[R5,#0]
	.dbline 88
	b L10
L21:
	.dbline 89
; 	case ((unsigned long)  500000): UART0_DLL = (0x08); break;
	mov R4,#8
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 89
	b L10
L22:
	.dbline 90
; 	case ((unsigned long)  921600): UART0_DLL = (0x04); UART0_FDR = (((0x0C)<<4) | 0x01); break;
	mov R4,#4
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 90
	mov R4,#193
	ldr R5,LIT_UART0SetBaudRate+0
	str R4,[R5,#0]
	.dbline 90
	b L10
L23:
	.dbline 92
; 	case ((unsigned long)       1):
; 	case ((unsigned long) 1000000): UART0_DLL = (0x04); break;
	mov R4,#4
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 92
	b L10
L24:
	.dbline 93
; 	case ((unsigned long) 1500000): UART0_DLL = (0x02); UART0_FDR = (((0x03)<<4) | 0x01); break;
	mov R4,#2
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 93
	mov R4,#49
	ldr R5,LIT_UART0SetBaudRate+0
	str R4,[R5,#0]
	.dbline 93
	b L10
L25:
	.dbline 94
; 	case ((unsigned long) 1843200): UART0_DLL = (0x02); UART0_FDR = (((0x0C)<<4) | 0x01); break; //
	mov R4,#2
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 94
	mov R4,#193
	ldr R5,LIT_UART0SetBaudRate+0
	str R4,[R5,#0]
	.dbline 94
	b L10
L26:
	.dbline 96
; 	case ((unsigned long)       2):
; 	case ((unsigned long) 2000000): UART0_DLL = (0x02);	break;
	mov R4,#2
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 96
	b L10
L27:
	.dbline 98
; 	case ((unsigned long)       4):
; 	case ((unsigned long) 4000000): UART0_DLL = (0x01);	break;
	mov R4,#1
	ldr R5,LIT_UART0SetBaudRate+60
	str R4,[R5,#0]
	.dbline 98
	b L10
L9:
	.dbline 107
; #endif
; 
; #if PLL_CLOCK == 32			  			   // all baud rates calculated for 32MHz
; 	case ((unsigned long) 1000000): UART0_DLL = (0x02); break;
; 	case ((unsigned long) 2000000): UART0_DLL = (0x01);	break;
; #endif
; 
; 	default:
;   			UART0_LCR = 0x03;				// Close divisor before printing!
	mov R4,#3
	ldr R5,LIT_UART0SetBaudRate+4
	str R4,[R5,#0]
	.dbline 108
; 			printf("unknown/unsupported baud rate!\n");
	ldr R0,LIT_UART0SetBaudRate+64
	bl _printf
	.dbline 109
; 			return;
	b L8
L10:
	.dbline 112
;   }
; 
;   UART0_LCR = 0x03;							// Close divisor
	mov R4,#3
	ldr R5,LIT_UART0SetBaudRate+4
	str R4,[R5,#0]
	.dbline -2
L8:
	ldmfd R11,{R4,R5,R6,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
LIT_UART0SetBaudRate:
	DCD -536821720
	DCD -536821748
	DCD -536821756
	DCD 31250
	DCD 62500
	DCD 115200
	DCD 125000
	DCD 1000000
	DCD 460800
	DCD 250000
	DCD 500000
	DCD 1843200
	DCD 1500000
	DCD 2000000
	DCD 4000000
	DCD -536821760
	DCD L28
	.dbsym r baudRate 6 l
	.dbend
	EXPORT _UARTInit
	.dbfunc e UARTInit _UARTInit fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_UARTInit:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R11,R12,R14}
	mov R11,R13
	.dbline -1
	.dbline 116
; }
; 
; // *****************************************************************************
; void UARTInit(void) {
	.dbline 118
; 
;   UART0SetBaudRate(BAUD_RATE_DEFAULT);
	ldr R0,LIT_UARTInit+0
	bl _UART0SetBaudRate
	.dbline 120
; 
;   UART0_IER = 0x00;							// disable RS232 interrupts
	mov R4,#0
	ldr R5,LIT_UARTInit+4
	str R4,[R5,#0]
	.dbline 121
;   UART0_FCR = 0x01;							// enable the fifos
	mov R4,#1
	ldr R5,LIT_UARTInit+8
	str R4,[R5,#0]
	.dbline 122
;   UART0_FCR = 0x01 | 0x06;					// Reset FIFOs
	mov R4,#7
	ldr R5,LIT_UARTInit+8
	str R4,[R5,#0]
	.dbline 124
; 
;   UART0_TER = 0x80;							// Enable Transmitter (default)
	mov R4,#128
	ldr R5,LIT_UARTInit+12
	str R4,[R5,#0]
	.dbline 126
; 
;   PCB_PINSEL0 |= BIT(2) | BIT(0);	  		// enable TxD0, RxD0 output pins
	ldr R4,LIT_UARTInit+16
	ldr R5,[R4,#0]
	orr R5,R5,#5
	str R5,[R4,#0]
	.dbline 129
; 
; // *****************************************************************************  
;   FGPIO_IOCLR  = PIN_UART0_CTS;				// set CTS pin to permanent low
	mov R4,#512
	ldr R5,LIT_UARTInit+20
	str R4,[R5,#0]
	.dbline 130
;   FGPIO_IODIR |= PIN_UART0_CTS;
	ldr R4,LIT_UARTInit+24
	ldr R5,[R4,#0]
	orr R5,R5,#512
	str R5,[R4,#0]
	.dbline 132
; 
;   FGPIO_IODIR &= ~(PIN_UART0_RTS);			// set RTS to input
	ldr R4,LIT_UARTInit+24
	mvn R5,#256
	ldr R6,[R4,#0]
	and R5,R6,R5
	str R5,[R4,#0]
	.dbline 135
; 
; // *****************************************************************************  
;   commandLine[0] = 0;
	mov R4,#0
	ldr R5,LIT_UARTInit+28
	strb R4,[R5,#0]
	.dbline 136
;   commandLinePointer = 0;
	mov R4,#0
	ldr R5,LIT_UARTInit+32
	str R4,[R5,#0]
	.dbline -2
L46:
	ldmfd R11,{R4,R5,R6,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
LIT_UARTInit:
	DCD 4000000
	DCD -536821756
	DCD -536821752
	DCD -536821712
	DCD -536690688
	DCD 1073725468
	DCD 1073725440
	DCD _commandLine
	DCD _commandLinePointer
	.dbend
	EXPORT _UARTShowVersion
	.dbfunc e UARTShowVersion _UARTShowVersion fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_UARTShowVersion:
	mov R12,R13
	stmfd R13!,{R4,R11,R12,R14}
	mov R11,R13
	.dbline -1
	.dbline 141
; }
; 
; 
; // *****************************************************************************  
; void UARTShowVersion(void) {
	.dbline 142
;   UARTReturn();
	.dbline 142
	mov R0,#10
	bl _putchar
	.dbline 142
	.dbline 142
	.dbline 143
;   printf("EDVS128_LPC2106, V");
	ldr R0,LIT_UARTShowVersion+0
	bl _printf
	.dbline 144
;   printf(SOFTWARE_VERSION);
	ldr R0,LIT_UARTShowVersion+4
	bl _printf
	.dbline 145
;   printf(": ");
	ldr R0,LIT_UARTShowVersion+8
	bl _printf
	.dbline 146
;   printf(__DATE__);
	ldr R0,LIT_UARTShowVersion+12
	bl _printf
	.dbline 147
;   printf(", ");
	ldr R0,LIT_UARTShowVersion+16
	bl _printf
	.dbline 148
;   printf(__TIME__);
	ldr R0,LIT_UARTShowVersion+20
	bl _printf
	.dbline 149
;   UARTReturn();
	.dbline 149
	mov R0,#10
	bl _putchar
	.dbline 149
	.dbline 149
	.dbline 151
; 
;   printf("System Clock: %2dMHz / %d -> %dns event time resolution",
	ldr R0,LIT_UARTShowVersion+24
	mov R4,#64
	mov R1,R4
	mov R2,R4
	mov R3,#1000
	bl _printf
	.dbline 155
;   				 			   	 	   			  PLL_CLOCK,
; 												  (1<<TIMESTAMP_SHIFTBITS),
;   				 			   	 	   			  1000*(1<<TIMESTAMP_SHIFTBITS) / (PLL_CLOCK));
;   UARTReturn();
	.dbline 155
	mov R0,#10
	bl _putchar
	.dbline 155
	.dbline 155
	.dbline 157
; 
;   printf("Modules: ");
	ldr R0,LIT_UARTShowVersion+28
	bl _printf
	.dbline 200
; 
; #ifdef TIME_OPTIMIZED
;   printf(" TIME_OPTIMIZED");
; #endif
; 
; #ifdef INCLUDE_TRACK_HF_LED
;   printf(" TRACK_HF_LED");
; #endif
; 
; #ifdef INCLUDE_PIXEL_CUTOUT_REGION
;   printf(" PIXEL_CUTOUT_REGION");
; #endif
; 
; #ifdef INCLUDE_PWM246
;   printf(" PWM246-");
;   #ifdef INCLUDE_PWM246_ENABLE_PWM2_OUT
;     printf("2");
;   #endif
;   #ifdef INCLUDE_PWM246_ENABLE_PWM4_OUT
;     printf("4");
;   #endif
;   #ifdef INCLUDE_PWM246_ENABLE_PWM6_OUT
;     printf("6");
;   #endif
; #endif
; 
; #ifdef USE_ALTERNATE_RTS_CTS
;   printf(" ALT-RTS/CTS");
; #endif
; 
; #ifdef INCLUDE_MARK_BUFFEROVERFLOW
;   printf(" MARK_BUFFEROVERFLOW");
; #endif
; 
; #ifdef INCLUDE_EVENTRATE_CONTROL
;   printf(" AUTOMATIC_EVENT_RATE_CONTROL");
; #endif
; 
; #ifdef INCLUDE_UART_SPEEDTEST
;   printf(" UART SPEEDTEST");
; #endif
; 
;   UARTReturn();
	.dbline 200
	mov R0,#10
	bl _putchar
	.dbline 200
	.dbline 200
	.dbline -2
L47:
	ldmfd R11,{R4,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
LIT_UARTShowVersion:
	DCD L48
	DCD L49
	DCD L50
	DCD L51
	DCD L52
	DCD L53
	DCD L54
	DCD L55
	.dbend
	EXPORT _UARTShowUsage
	.dbfunc e UARTShowUsage _UARTShowUsage fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_UARTShowUsage:
	stmfd R13!,{R14}
	.dbline -1
	.dbline 204
; }
; 
; // *****************************************************************************  
; void UARTShowUsage(void) {
	.dbline 206
;   
;   UARTShowVersion();
	bl _UARTShowVersion
	.dbline 208
; 
;   UARTReturn();
	.dbline 208
	mov R0,#10
	bl _putchar
	.dbline 208
	.dbline 208
	.dbline 209
;   printf("Supported Commands:\n");
	ldr R0,LIT_UARTShowUsage+0
	bl _printf
	.dbline 210
;   UARTReturn();
	.dbline 210
	mov R0,#10
	bl _putchar
	.dbline 210
	.dbline 210
	.dbline 212
; 
;   printf(" E+/-       - enable/disable event sending\n");
	ldr R0,LIT_UARTShowUsage+4
	bl _printf
	.dbline 213
;   printf(" !Ex        - specify event data format, ??E to list options\n");
	ldr R0,LIT_UARTShowUsage+8
	bl _printf
	.dbline 217
; #ifdef INCLUDE_PIXEL_CUTOUT_REGION
;   printf(" !Cxl,yl<,xr,yr> - specify a rectangular cutout region\n");
; #endif
;   UARTReturn();
	.dbline 217
	mov R0,#10
	bl _putchar
	.dbline 217
	.dbline 217
	.dbline 219
; 
;   printf(" !Bx=y      - set bias register x[0..11] to value y[0..0xFFFFFF]\n");
	ldr R0,LIT_UARTShowUsage+12
	bl _printf
	.dbline 220
;   printf(" !BF        - send bias settings to DVS\n");
	ldr R0,LIT_UARTShowUsage+16
	bl _printf
	.dbline 221
;   printf(" !BDx       - select and flush default bias set (default: set 0)\n");
	ldr R0,LIT_UARTShowUsage+20
	bl _printf
	.dbline 222
;   printf(" ?Bx        - get bias register x current value\n");
	ldr R0,LIT_UARTShowUsage+24
	bl _printf
	.dbline 223
;   printf(" ?B#x       - get bias register x encoded within event stream\n");
	ldr R0,LIT_UARTShowUsage+28
	bl _printf
	.dbline 224
;   UARTReturn();
	.dbline 224
	mov R0,#10
	bl _putchar
	.dbline 224
	.dbline 224
	.dbline 228
; 
;   
;   
;   printf(" !R+/-      - transmit event rate on/off\n");
	ldr R0,LIT_UARTShowUsage+32
	bl _printf
	.dbline 237
; #ifdef INCLUDE_TRACK_HF_LED
;   printf(" !T+/-      - enable/disable tracking of high-frequency blinkind LEDs\n");
; #ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
;   printf(" !TS+/-     - enable/disable servo following of tracking target\n");
; #endif
;   UARTReturn();
; #endif
;   
;   printf(" 0,1,2      - LED off/on/blinking\n");
	ldr R0,LIT_UARTShowUsage+36
	bl _printf
	.dbline 238
;   printf(" !S=x       - set baudrate to x\n");
	ldr R0,LIT_UARTShowUsage+40
	bl _printf
	.dbline 243
; #ifdef INCLUDE_PWM246
;   printf(" !PWMC=x    - set PWM cycle length to x us\n");
;   printf(" !PWMS<x>=y - set PWM signal x [0..2] length to y us\n");
; #endif
;   UARTReturn();
	.dbline 243
	mov R0,#10
	bl _putchar
	.dbline 243
	.dbline 243
	.dbline 245
; 
;   printf(" R          - reset board\n");
	ldr R0,LIT_UARTShowUsage+44
	bl _printf
	.dbline 246
;   printf(" P          - enter reprogramming mode\n");
	ldr R0,LIT_UARTShowUsage+48
	bl _printf
	.dbline 247
;   UARTReturn();
	.dbline 247
	mov R0,#10
	bl _putchar
	.dbline 247
	.dbline 247
	.dbline 249
; 
;   printf(" ??         - display help\n");
	ldr R0,LIT_UARTShowUsage+52
	bl _printf
	.dbline 250
;   UARTReturn();
	.dbline 250
	mov R0,#10
	bl _putchar
	.dbline 250
	.dbline 250
	.dbline -2
L56:
	ldmfd R13!,{R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
LIT_UARTShowUsage:
	DCD L57
	DCD L58
	DCD L59
	DCD L60
	DCD L61
	DCD L62
	DCD L63
	DCD L64
	DCD L65
	DCD L66
	DCD L67
	DCD L68
	DCD L69
	DCD L70
	.dbend
	EXPORT _UARTShowEventDataOptions
	.dbfunc e UARTShowEventDataOptions _UARTShowEventDataOptions fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_UARTShowEventDataOptions:
	stmfd R13!,{R14}
	.dbline -1
	.dbline 253
; }
; 
; void UARTShowEventDataOptions(void) {
	.dbline 254
;   printf(" !E0   - 2 bytes per event binary 0yyyyyyy.pxxxxxxx (default)\n");
	ldr R0,LIT_UARTShowEventDataOptions+0
	bl _printf
	.dbline 255
;   printf(" !E1   - 4 bytes per event (as above followed by 16bit timestamp 1us res)\n");
	ldr R0,LIT_UARTShowEventDataOptions+4
	bl _printf
	.dbline 256
;   printf(" !E2   - 5 bytes per event (as above followed by 24bit timestamp 1us res)\n");
	ldr R0,LIT_UARTShowEventDataOptions+8
	bl _printf
	.dbline 257
;   printf(" !E3   - 6 bytes per event (as above followed by 32bit timestamp 1/64M res)\n");
	ldr R0,LIT_UARTShowEventDataOptions+12
	bl _printf
	.dbline 258
;   UARTReturn();
	.dbline 258
	mov R0,#10
	bl _putchar
	.dbline 258
	.dbline 258
	.dbline 260
; 
;   printf(" !E20  - 4 bytes per event, hex encoded\n");
	ldr R0,LIT_UARTShowEventDataOptions+16
	bl _printf
	.dbline 261
;   printf(" !E21  - 8 bytes per event+timestamp, hex encoded \n");
	ldr R0,LIT_UARTShowEventDataOptions+20
	bl _printf
	.dbline 262
;   printf(" !E22  - 5 bytes per event, hex encoded; new-line\n");
	ldr R0,LIT_UARTShowEventDataOptions+24
	bl _printf
	.dbline 263
;   printf(" !E23  - 8 bytes per event+timestamp, hex encoded; new-line\n");
	ldr R0,LIT_UARTShowEventDataOptions+28
	bl _printf
	.dbline 264
;   UARTReturn();
	.dbline 264
	mov R0,#10
	bl _putchar
	.dbline 264
	.dbline 264
	.dbline 266
; 
;   printf(" !E30  - 10 bytes per event, ASCII <1p> <3y> <3x>; new-line\n");
	ldr R0,LIT_UARTShowEventDataOptions+32
	bl _printf
	.dbline 267
;   printf(" !E31  - 10 bytes per event+ts 1us res, ASCII <1p> <3y> <3x> <8ts> <nl>\n");
	ldr R0,LIT_UARTShowEventDataOptions+36
	bl _printf
	.dbline 268
;   printf(" !E32  - 10 bytes per event+ts 1/64M res, ASCII <1p> <3y> <3x> <10ts> <nl>\n");
	ldr R0,LIT_UARTShowEventDataOptions+40
	bl _printf
	.dbline -2
L71:
	ldmfd R13!,{R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
LIT_UARTShowEventDataOptions:
	DCD L72
	DCD L73
	DCD L74
	DCD L75
	DCD L76
	DCD L77
	DCD L78
	DCD L79
	DCD L80
	DCD L81
	DCD L82
	.dbend
	EXPORT _parseULong
	.dbfunc e parseULong _parseULong fl
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;             ul -> R4
;              c -> R5
_parseULong:
	mov R12,R13
	stmfd R13!,{R4,R5,R11,R12,R14}
	mov R11,R13
	mov R5,R0
	.dbline -1
	.dbline 272
; }
; 
; // *****************************************************************************
; unsigned long parseULong(char **c) {
	.dbline 273
;   unsigned long ul=0;
	mov R4,#0
	b L85
L84:
	.dbline 274
;   while (((**c)>='0') && ((**c)<='9')) {
	.dbline 275
;     ul = 10*ul;
	mov R1,#10
	mul R1,R1,R4
	mov R4,R1
	.dbline 276
; 	ul += ((**c)-'0');
	ldr R1,[R5,#0]
	ldrb R1,[R1,#0]
	sub R1,R1,#48
	add R4,R4,R1
	.dbline 277
; 	(*(c))++;
	ldr R1,[R5,#0]
	add R1,R1,#1
	str R1,[R5,#0]
	.dbline 278
;   }
L85:
	.dbline 274
	ldr R1,[R5,#0]
	ldrb R1,[R1,#0]
	cmp R1,#48
	blt L87
	cmp R1,#57
	ble L84
L87:
	.dbline 279
;   return(ul);
	mov R0,R4
	.dbline -2
L83:
	ldmfd R11,{R4,R5,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
	.dbsym r ul 4 l
	.dbsym r c 5 ppc
	.dbend
	EXPORT _UARTParseGetCommand
	.dbfunc e UARTParseGetCommand _UARTParseGetCommand fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;              c -> R11,-4
;         biasID -> R5
_UARTParseGetCommand:
	mov R12,R13
	stmfd R13!,{R4,R5,R11,R12,R14}
	mov R11,R13
	sub R13,R13,#0x4
	.dbline -1
	.dbline 285
; }
; 
; // *****************************************************************************
; // * ** parseGetCommand ** */
; // *****************************************************************************
; void UARTParseGetCommand(void) {
	.dbline 287
; 
;   switch (commandLine[1]) {
	ldr R4,LIT_UARTParseGetCommand+0
	ldrb R5,[R4,#0]
	cmp R5,#69
	beq L107
	cmp R5,#69
	bgt L117
L116:
	cmp R5,#63
	beq L109
	cmp R5,#66
	beq L93
	b L89
L117:
	cmp R5,#98
	beq L93
	cmp R5,#101
	beq L107
	b L89
L93:
	.dbline 290
; 
;     case 'B':
; 	case 'b': {	   									 			// request bias value
	.dbline 294
; 	            unsigned char *c;
; 			    long biasID;
; 			    
; 				if (commandLine[2] == '#') {	   	// send bias value as encoded event
	ldr R4,LIT_UARTParseGetCommand+4
	ldrb R4,[R4,#0]
	cmp R4,#35
	bne L94
	.dbline 294
	.dbline 295
; 			      c = commandLine+3;
	ldr R4,LIT_UARTParseGetCommand+8
	str R4,[R11,#-4]
	.dbline 296
;                   DVS128BiasTransmitBiasValue(parseULong(&c));
	sub R0,R11,#0x4
	bl _parseULong
	mov R4,R0
	bl _DVS128BiasTransmitBiasValue
	.dbline 297
; 			      break;
	b L88
L94:
	.dbline 300
; 			    }
; 
; 			    c = commandLine+2;					// send bias value as deciman value
	ldr R4,LIT_UARTParseGetCommand+4
	str R4,[R11,#-4]
	.dbline 301
; 			    if ((*c == 'A') || (*c == 'a')) {
	ldr R4,[R11,#-4]
	ldrb R4,[R4,#0]
	cmp R4,#65
	beq L101
	cmp R4,#97
	bne L99
L101:
	.dbline 301
	.dbline 302
; 			      for (biasID=0; biasID<12; biasID++) {
	mov R5,#0
L102:
	.dbline 302
	.dbline 303
; 			        printf ("-B%d=%d\n", biasID, DVS128BiasGet(biasID));
	mov R0,R5
	bl _DVS128BiasGet
	mov R4,R0
	ldr R0,LIT_UARTParseGetCommand+12
	mov R1,R5
	mov R2,R4
	bl _printf
	.dbline 304
; 			      }
L103:
	.dbline 302
	add R5,R5,#1
	.dbline 302
	cmp R5,#12
	blt L102
	.dbline 305
; 				  break;
	b L88
L99:
	.dbline 308
; 			    }
; 			   
; 			    biasID = parseULong(&c);
	sub R0,R11,#0x4
	bl _parseULong
	mov R5,R0
	.dbline 309
; 			    printf ("-B%d=%d\n", biasID, DVS128BiasGet(biasID));
	bl _DVS128BiasGet
	mov R4,R0
	ldr R0,LIT_UARTParseGetCommand+12
	mov R1,R5
	mov R2,R4
	bl _printf
	.dbline 310
; 		        break;
	b L88
L107:
	.dbline 322
; 		      }
; 
; #ifdef INCLUDE_PIXEL_CUTOUT_REGION
; 	case 'C':
; 	case 'c':
; 			  printf("-C%d,%d,%d,%d\n", pixelCutoutMinX, pixelCutoutMinY, pixelCutoutMaxX, pixelCutoutMaxY);
; 			  break;
; #endif
; 
; 	case 'E':
; 	case 'e':
; 	          printf("-E%d\n", eDVSDataFormat);
	ldr R0,LIT_UARTParseGetCommand+16
	ldr R4,LIT_UARTParseGetCommand+20
	ldr R1,[R4,#0]
	bl _printf
	.dbline 323
; 		 	  break;
	b L88
L109:
	.dbline 343
; 
; #ifdef INCLUDE_PWM246
; 	case 'P':
; 	case 'p':
; 		 	  {
; 			    if ((commandLine[4] == 'C') || (commandLine[4] == 'c')) {
; 				  printf("-PWMC=%d\n", PWM246GetCycle());
; 				  break;
; 			    }
; 			    if ((commandLine[4] == 'S') || (commandLine[4] == 's')) {
; 			      printf("-PWMS=%d,%d,%d\n", PWM246GetSignal(0), PWM246GetSignal(1), PWM246GetSignal(2));
; 				  break;
; 			    }
; 			    printf("Get PWM246: parsing error\n");
; 			    break;
; 			  }
; #endif
; 
; 	case '?':
; 	          if (((commandLine[2]) == 'e') || ((commandLine[2]) == 'E')) {
	ldr R4,LIT_UARTParseGetCommand+4
	ldrb R4,[R4,#0]
	cmp R4,#101
	beq L114
	ldr R4,LIT_UARTParseGetCommand+4
	ldrb R4,[R4,#0]
	cmp R4,#69
	bne L110
L114:
	.dbline 343
	.dbline 344
; 			    UARTShowEventDataOptions();
	bl _UARTShowEventDataOptions
	.dbline 345
; 			    break;
	b L88
L110:
	.dbline 347
; 			  }
; 		 	  UARTShowUsage();
	bl _UARTShowUsage
	.dbline 348
; 			  break;
	b L88
L89:
	.dbline 351
; 
; 	default:
; 			  printf("Get: parsing error\n");
	ldr R0,LIT_UARTParseGetCommand+24
	bl _printf
	.dbline 352
;   }
	.dbline 353
;   return;
	.dbline -2
L88:
	ldmfd R11,{R4,R5,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
LIT_UARTParseGetCommand:
	DCD _commandLine+1
	DCD _commandLine+2
	DCD _commandLine+3
	DCD L106
	DCD L108
	DCD _eDVSDataFormat
	DCD L115
	.dbsym l c -4 pc
	.dbsym r biasID 5 L
	.dbend
	EXPORT _UARTParseSetCommand
	.dbfunc e UARTParseSetCommand _UARTParseSetCommand fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;              c -> R11,-4
;       baudRate -> R6
;              c -> R11,-4
;      biasValue -> R7
;         biasID -> R6
;              c -> R11,-4
_UARTParseSetCommand:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R7,R11,R12,R14}
	mov R11,R13
	sub R13,R13,#0x4
	.dbline -1
	.dbline 359
; }
; 
; // *****************************************************************************
; // * ** parseSetCommand ** */
; // *****************************************************************************
; void UARTParseSetCommand(void) {
	.dbline 360
;   switch (commandLine[1]) {
	ldr R4,LIT_UARTParseSetCommand+0
	ldrb R6,[R4,#0]
	cmp R6,#82
	beq L154
	cmp R6,#83
	beq L159
	cmp R6,#83
	bgt L167
L166:
	cmp R6,#66
	beq L123
	cmp R6,#69
	beq L150
	b L119
L167:
	cmp R6,#98
	beq L123
	cmp R6,#101
	beq L150
	cmp R6,#98
	blt L119
L168:
	cmp R6,#114
	beq L154
	cmp R6,#115
	beq L159
	b L119
L123:
	.dbline 363
; 
; 	case 'B':
; 	case 'b': {
	.dbline 368
; 	            unsigned char *c;
; 			    long biasID, biasValue;
; //  unsigned long t0, t1;
; 
; 			    if ((commandLine[2] == 'F') || (commandLine[2] == 'f')) {	   	// flush bias values to DVS chip
	ldr R4,LIT_UARTParseSetCommand+4
	ldrb R4,[R4,#0]
	cmp R4,#70
	beq L128
	ldr R4,LIT_UARTParseSetCommand+4
	ldrb R4,[R4,#0]
	cmp R4,#102
	bne L124
L128:
	.dbline 368
	.dbline 369
;                   if (enableEventSending==0) {
	ldr R4,LIT_UARTParseSetCommand+8
	ldr R4,[R4,#0]
	cmp R4,#0
	bne L129
	.dbline 369
	.dbline 370
; 				    printf("-BF\n");
	ldr R0,LIT_UARTParseSetCommand+12
	bl _printf
	.dbline 371
; 				  }
L129:
	.dbline 373
; //  t0 = T1_TC;
; 				  DVS128BiasFlush();
	bl _DVS128BiasFlush
	.dbline 376
; //  t1 = T1_TC;
; //  printf("td = %ld\n", (t1-t0));
; 				  break;
	b L118
L124:
	.dbline 379
; 				}
; 
; 			    if ((commandLine[2] == 'D') || (commandLine[2] == 'd')) {	   	// load and flush default bias set
	ldr R4,LIT_UARTParseSetCommand+4
	ldrb R4,[R4,#0]
	cmp R4,#68
	beq L136
	ldr R4,LIT_UARTParseSetCommand+4
	ldrb R4,[R4,#0]
	cmp R4,#100
	bne L132
L136:
	.dbline 379
	.dbline 380
; 				  if ((commandLine[3]>'0') && (commandLine[3]<'9')) {
	ldr R4,LIT_UARTParseSetCommand+16
	ldrb R4,[R4,#0]
	cmp R4,#48
	ble L137
	ldr R4,LIT_UARTParseSetCommand+16
	ldrb R4,[R4,#0]
	cmp R4,#57
	bge L137
	.dbline 380
	.dbline 381
;                     if (enableEventSending==0) {
	ldr R4,LIT_UARTParseSetCommand+8
	ldr R4,[R4,#0]
	cmp R4,#0
	bne L141
	.dbline 381
	.dbline 382
; 				      printf("-BD%c\n", commandLine[3]);
	ldr R0,LIT_UARTParseSetCommand+20
	ldr R4,LIT_UARTParseSetCommand+16
	ldrb R1,[R4,#0]
	bl _printf
	.dbline 383
; 				    }
L141:
	.dbline 384
; 					DVS128BiasLoadDefaultSet(commandLine[3]-'0');
	ldr R4,LIT_UARTParseSetCommand+16
	ldrb R4,[R4,#0]
	sub R4,R4,#48
	mov R0,R4
	bl _DVS128BiasLoadDefaultSet
	.dbline 385
; 					DVS128BiasFlush();
	bl _DVS128BiasFlush
	.dbline 386
; 				  } else {
	b L118
L137:
	.dbline 386
	.dbline 387
; 					printf("Select default bias set: parsing error\n");
	ldr R0,LIT_UARTParseSetCommand+24
	bl _printf
	.dbline 388
; 				  }
	.dbline 389
; 				  break;
	b L118
L132:
	.dbline 392
; 				}
; 
; 				c = commandLine+2;
	ldr R4,LIT_UARTParseSetCommand+4
	str R4,[R11,#-4]
	.dbline 393
; 			    biasID = parseULong(&c);
	sub R0,R11,#0x4
	bl _parseULong
	mov R6,R0
	.dbline 394
; 			    c++;
	ldr R4,[R11,#-4]
	add R4,R4,#1
	str R4,[R11,#-4]
	.dbline 395
; 			    biasValue = parseULong(&c);
	sub R0,R11,#0x4
	bl _parseULong
	mov R7,R0
	.dbline 396
; 			    DVS128BiasSet(biasID, biasValue);
	mov R0,R6
	mov R1,R7
	bl _DVS128BiasSet
	.dbline 397
; 			    if (enableEventSending==0) {
	ldr R4,LIT_UARTParseSetCommand+8
	ldr R4,[R4,#0]
	cmp R4,#0
	bne L118
	.dbline 397
	.dbline 398
; 			      printf ("-B%d=%d\n", biasID, DVS128BiasGet(biasID));
	mov R0,R6
	bl _DVS128BiasGet
	mov R4,R0
	ldr R0,LIT_UARTParseSetCommand+28
	mov R1,R6
	mov R2,R4
	bl _printf
	.dbline 399
; 			    }
	.dbline 400
; 			    break;
	b L118
L150:
	.dbline 425
; 			  }
; 
; #ifdef INCLUDE_PIXEL_CUTOUT_REGION
; 	case 'C':
; 	case 'c':
; 		 	  {
; 			    long n;
; 			    n = sscanf(commandLine+2, "%ld,%ld,%ld,%ld", &pixelCutoutMinX, &pixelCutoutMinY, &pixelCutoutMaxX, &pixelCutoutMaxY);
; 			    if (n==2) { 		  	 	 // only two numbers specified --> assume we only want one pixel
; 			      pixelCutoutMaxX = pixelCutoutMinX;
; 			      pixelCutoutMaxY = pixelCutoutMinY;
; 			      printf("-C%d,%d,%d,%d\n", pixelCutoutMinX, pixelCutoutMinY, pixelCutoutMaxX, pixelCutoutMaxY);
; 			      break;
; 			    }
; 			    if (n==4) { 		  	 	 // correct parsing
; 			      printf("-C%d,%d,%d,%d\n", pixelCutoutMinX, pixelCutoutMinY, pixelCutoutMaxX, pixelCutoutMaxY);
; 			      break;
; 				}
; 				printf("Set pixel cutout: parsing error\n");
; 			    break;
; 			  }
; #endif
; 
; 	case 'E':
; 	case 'e': {
	.dbline 427
; 		 	    unsigned char *c;
; 			    c = commandLine+2;
	ldr R4,LIT_UARTParseSetCommand+4
	str R4,[R11,#-4]
	.dbline 428
; 			    if ((*c) == '=') c++;   		   		// skip '=' if entered
	ldr R4,[R11,#-4]
	ldrb R4,[R4,#0]
	cmp R4,#61
	bne L152
	.dbline 428
	ldr R4,[R11,#-4]
	add R4,R4,#1
	str R4,[R11,#-4]
L152:
	.dbline 429
; 			    eDVSDataFormat = parseULong(&c);
	sub R0,R11,#0x4
	bl _parseULong
	ldr R5,LIT_UARTParseSetCommand+32
	str R0,[R5,#0]
	.dbline 430
; 			    printf("-E%d\n", eDVSDataFormat);
	ldr R0,LIT_UARTParseSetCommand+36
	ldr R4,LIT_UARTParseSetCommand+32
	ldr R1,[R4,#0]
	bl _printf
	.dbline 431
; 		 	    break;
	b L118
L154:
	.dbline 466
; 			  }
; 
; #ifdef INCLUDE_PWM246
; 	case 'P':
; 	case 'p':
; 		 	  {
; 	            unsigned char *c;
; 				unsigned long id, l;
; 			    if (((commandLine[4]) == 'C') || ((commandLine[4]) == 'c')) {
; 			      c = commandLine+6;
; 			      l = parseULong(&c);
; 			   	  PWM246SetCycle(l);
; 			      if (enableEventSending==0) {
; 			   	    printf("-PWMC=%d\n", PWM246GetCycle());
; 				  }
; 				  break;
; 			    }
; 			    if (((commandLine[4]) == 'S') || ((commandLine[4]) == 's')) {
; 				  id = commandLine[5]-'0';
; 			      c = commandLine+7;
; 			      l = parseULong(&c);
; 				  PWM246SetSignal(id, l);
; 			      if (enableEventSending==0) {
; 			   	    printf("-PWMS%d=%d\n", id, PWM246GetSignal(id));
; 				  }
; 				  break;
; 				}
; 				printf("Set PWM246: parsing error\n");
; 			    break;
; 			 }
; #endif
; 
; 	case 'R':
; 	case 'r':
; 		 	  transmitEventRateEnable = (commandLine[2] == '+') ? 1 : 0;
	ldr R4,LIT_UARTParseSetCommand+4
	ldrb R4,[R4,#0]
	cmp R4,#43
	moveq R6,#1
L157:
	movne R6,#0
L158:
	mov R4,R6
	ldr R5,LIT_UARTParseSetCommand+40
	str R4,[R5,#0]
	.dbline 467
; 			  break;
	b L118
L159:
	.dbline 470
; 
; 	case 'S':
; 	case 's': {
	.dbline 473
; 	            unsigned char *c;
; 			    long baudRate;
; 			    c = commandLine+3;
	ldr R4,LIT_UARTParseSetCommand+16
	str R4,[R11,#-4]
	.dbline 474
; 			    baudRate = parseULong(&c);
	sub R0,R11,#0x4
	bl _parseULong
	mov R6,R0
	.dbline 475
; 			    printf("Switching Baud Rate to %d Baud!\n", baudRate);
	ldr R0,LIT_UARTParseSetCommand+44
	mov R1,R6
	bl _printf
L162:
	.dbline 476
;                 while ((UART0_LSR & BIT(6))==0) {};		   // wait for UART to finish data transfer
	.dbline 476
L163:
	.dbline 476
	ldr R4,LIT_UARTParseSetCommand+48
	ldr R4,[R4,#0]
	tst R4,#64
	beq L162
	.dbline 476
	.dbline 477
; 			    UART0SetBaudRate(baudRate);
	mov R0,R6
	bl _UART0SetBaudRate
	.dbline 478
; 			    break;
	b L118
L119:
	.dbline 513
; 			  }
; 
; #ifdef INCLUDE_TRACK_HF_LED
;     case 'T':
;     case 't':
; #ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
; 		 	  if ((commandLine[2]=='s') || (commandLine[2]=='S')){
; 		 	    if (commandLine[3]=='0') {
; 			      EP_TrackHFLServoResetPosition();
; 				  printf ("-TS0\n");
; 				} else {
; 				  if (commandLine[3]=='+') {
; 			        EP_TrackHFLServoSetEnabled(TRUE);
; 				    printf ("-TS+\n");
; 			      } else {
; 			        EP_TrackHFLServoSetEnabled(FALSE);
; 				    printf ("-TS-\n");
; 				  }
; 				}
; 				break;
; 			  }
; #endif
; 			  
; 		 	  if (commandLine[2]=='+') {
; 			    EP_TrackHFLSetOutputEnabled(TRUE);
; 				printf ("-T+\n");
; 			  } else {
; 			    EP_TrackHFLSetOutputEnabled(FALSE);
; 				printf ("-T-\n");
; 			  }
; 			  break;
; #endif
; 
; 	default:
; 			  printf("Set: parsing error\n");
	ldr R0,LIT_UARTParseSetCommand+52
	bl _printf
	.dbline 514
;   }
	.dbline 515
;   return;
	.dbline -2
L118:
	ldmfd R11,{R4,R5,R6,R7,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
LIT_UARTParseSetCommand:
	DCD _commandLine+1
	DCD _commandLine+2
	DCD _enableEventSending
	DCD L131
	DCD _commandLine+3
	DCD L143
	DCD L146
	DCD L106
	DCD _eDVSDataFormat
	DCD L108
	DCD _transmitEventRateEnable
	DCD L161
	DCD -536821740
	DCD L165
	.dbsym l c -4 pc
	.dbsym r baudRate 6 L
	.dbsym l c -4 pc
	.dbsym r biasValue 7 L
	.dbsym r biasID 6 L
	.dbsym l c -4 pc
	.dbend
	EXPORT _parseRS232CommandLine
	.dbfunc e parseRS232CommandLine _parseRS232CommandLine fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_parseRS232CommandLine:
	mov R12,R13
	stmfd R13!,{R4,R5,R11,R12,R14}
	mov R11,R13
	.dbline -1
	.dbline 521
; }
; 
; // *****************************************************************************
; // * ** parseRS232CommandLine ** */
; // *****************************************************************************
; void parseRS232CommandLine(void) {
	.dbline 523
; 
;   switch (commandLine[0]) {
	ldr R4,LIT_parseRS232CommandLine+0
	ldrb R5,[R4,#0]
	cmp R5,#69
	beq L180
	cmp R5,#69
	bgt L186
L185:
	cmp R5,#48
	beq L177
	cmp R5,#49
	beq L178
	cmp R5,#50
	beq L179
	cmp R5,#50
	bgt L188
L187:
	cmp R5,#33
	beq L174
	b L170
L188:
	cmp R5,#63
	beq L173
	b L170
L186:
	cmp R5,#101
	beq L180
	cmp R5,#101
	bgt L190
L189:
	cmp R5,#80
	beq L175
	cmp R5,#82
	beq L176
	b L170
L190:
	cmp R5,#112
	beq L175
	cmp R5,#114
	beq L176
	b L170
L173:
	.dbline 524
; 		case '?': UARTParseGetCommand();	break;
	bl _UARTParseGetCommand
	.dbline 524
	b L169
L174:
	.dbline 525
; 		case '!': UARTParseSetCommand();	break;
	bl _UARTParseSetCommand
	.dbline 525
	b L169
L175:
	.dbline 528
; 
; 	    case 'P':
; 	    case 'p': enterReprogrammingMode();	break;
	bl _enterReprogrammingMode
	.dbline 528
	b L169
L176:
	.dbline 530
; 	    case 'R':
; 		case 'r': resetDevice();			break;
	bl _resetDevice
	.dbline 530
	b L169
L177:
	.dbline 532
; 
; 		case '0': LEDSetOff();      		break;
	mov R0,#0
	bl _LEDSetState
	.dbline 532
	b L169
L178:
	.dbline 533
; 		case '1': LEDSetOn();       		break;
	mov R0,#1
	bl _LEDSetState
	.dbline 533
	b L169
L179:
	.dbline 534
; 		case '2': LEDSetBlinking(); 		break;
	mvn R0,#0
	bl _LEDSetState
	.dbline 534
	b L169
L180:
	.dbline 538
; 		
; 		case 'E':
; 		case 'e':
; 			 	  if (commandLine[1] == '+') {
	ldr R4,LIT_parseRS232CommandLine+4
	ldrb R4,[R4,#0]
	cmp R4,#43
	bne L181
	.dbline 538
	.dbline 539
; 				    DVS128FetchEventsEnable(TRUE);
	mov R0,#1
	bl _DVS128FetchEventsEnable
	.dbline 540
; 				  } else {
	b L169
L181:
	.dbline 540
	.dbline 541
; 				    DVS128FetchEventsEnable(FALSE);
	mov R0,#0
	bl _DVS128FetchEventsEnable
	.dbline 542
; 				  }
	.dbline 543
; 				  break;
	b L169
L170:
	.dbline 569
; 
; #ifdef INCLUDE_UART_SPEEDTEST
; 		case 'S':
; 		case 's':
; 			     {
; 				   long n;
; 				   long e;
; 				   printf("-tStart-\n");
; 				   for (n=0; n<61; n++) {			// send 1'998'848 events of 2 bytes each (= 3'997'696 bytes = 10sec @ 4mbit)
; 				     for (e=0; e<0x8000; e++) {
; 
; 					   while ((FGPIO_IOPIN & PIN_UART0_RTS) !=0 ) {}			// no rts stop signal
; 					   while ((UART0_LSR & BIT(5))==0) {}						// uart FIFO space to send data?
;     				   UART0_THR = (e>>8) & 0xFF;
; 					   while ((UART0_LSR & BIT(5))==0) {}						// uart FIFO space to send data?
;     				   UART0_THR = (e)    & 0xFF;
; 
; 					 }
; 				   }
; 				   printf("-tStop-\n");
; 				 }
; 				 break;
; #endif
; 
; 	    default:
; 				  printf("?\n\r");
	ldr R0,LIT_parseRS232CommandLine+8
	bl _printf
	.dbline 570
;   }
	.dbline 571
;   return;
	.dbline -2
L169:
	ldmfd R11,{R4,R5,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
LIT_parseRS232CommandLine:
	DCD _commandLine
	DCD _commandLine+1
	DCD L184
	.dbend
	EXPORT _UARTParseNewChar
	.dbfunc e UARTParseNewChar _UARTParseNewChar fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;              n -> R7
;        newChar -> R8
_UARTParseNewChar:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R7,R8,R11,R12,R14}
	mov R11,R13
	mov R8,R0
	.dbline -1
	.dbline 578
; }
; 
; 
; // *****************************************************************************
; // * ** RS232ParseNewChar ** */
; // *****************************************************************************
; void UARTParseNewChar(unsigned char newChar) {
	.dbline 580
; 
;   switch(newChar) {
	and R7,R8,#255
	cmp R7,#8
	beq L195
	cmp R7,#10
	beq L201
	cmp R7,#13
	beq L201
	b L192
L195:
	.dbline 582
; 	case 8:			// backspace
; 	  if (commandLinePointer > 0) {
	ldr R4,LIT_UARTParseNewChar+0
	ldr R4,[R4,#0]
	cmp R4,#0
	beq L193
	.dbline 582
	.dbline 583
; 	    commandLinePointer--;
	ldr R4,LIT_UARTParseNewChar+0
	ldr R5,[R4,#0]
	sub R5,R5,#1
	str R5,[R4,#0]
	.dbline 584
;           if (enableEventSending==0) {
	ldr R4,LIT_UARTParseNewChar+4
	ldr R4,[R4,#0]
	cmp R4,#0
	bne L193
	.dbline 584
	.dbline 585
; 		    printf("%c %c", 8, 8);
	ldr R0,LIT_UARTParseNewChar+8
	mov R4,#8
	mov R1,R4
	mov R2,R4
	bl _printf
	.dbline 586
; 		  }
	.dbline 587
; 	  }
	.dbline 588
;       break;
	b L193
L201:
	.dbline 592
; 
; 	case 10:
; 	case 13:
;       if (enableEventSending==0) {
	ldr R4,LIT_UARTParseNewChar+4
	ldr R4,[R4,#0]
	cmp R4,#0
	bne L202
	.dbline 592
	.dbline 593
; 	    UARTReturn();
	.dbline 593
	mov R0,#10
	bl _putchar
	.dbline 593
	.dbline 593
	.dbline 594
;       }
L202:
	.dbline 595
;       if (commandLinePointer > 0) {
	ldr R4,LIT_UARTParseNewChar+0
	ldr R4,[R4,#0]
	cmp R4,#0
	beq L193
	.dbline 595
	.dbline 596
;         commandLine[commandLinePointer]=0;
	ldr R4,LIT_UARTParseNewChar+0
	ldr R4,[R4,#0]
	ldr R5,LIT_UARTParseNewChar+12
	mov R6,#0
	strb R6,[R4,+R5]
	.dbline 597
;         parseRS232CommandLine();
	bl _parseRS232CommandLine
	.dbline 598
; 	    commandLinePointer=0;
	mov R4,#0
	ldr R5,LIT_UARTParseNewChar+0
	str R4,[R5,#0]
	.dbline 599
;       }
	.dbline 600
; 	  break;
	b L193
L192:
	.dbline 603
; 
; 	default:
;       if (commandLinePointer < (UART_COMMAND_LINE_MAX_LENGTH-2)) {
	ldr R4,LIT_UARTParseNewChar+0
	ldr R4,[R4,#0]
	cmp R4,#94
	bhs L206
	.dbline 603
	.dbline 604
;         if (enableEventSending==0) {
	ldr R4,LIT_UARTParseNewChar+4
	ldr R4,[R4,#0]
	cmp R4,#0
	bne L208
	.dbline 604
	.dbline 605
;           putchar(newChar);	  		   	// echo to indicate char arrived
	and R0,R8,#255
	bl _putchar
	.dbline 606
;         }
L208:
	.dbline 607
; 		commandLine[commandLinePointer] = newChar;
	ldr R4,LIT_UARTParseNewChar+0
	ldr R4,[R4,#0]
	ldr R5,LIT_UARTParseNewChar+12
	strb R8,[R4,+R5]
	.dbline 608
;         commandLinePointer++;
	ldr R4,LIT_UARTParseNewChar+0
	ldr R5,[R4,#0]
	add R5,R5,#1
	str R5,[R4,#0]
	.dbline 609
;       } else {
	b L207
L206:
	.dbline 609
	.dbline 611
; 		long n;
; 		printf("Reached cmd line length, resetting into bootloader mode!\n");
	ldr R0,LIT_UARTParseNewChar+16
	bl _printf
	.dbline 612
; 		for (n=0; n<100; n++) {
	mov R7,#0
L211:
	.dbline 612
	.dbline 613
; 		  delayMS(20);
	mov R0,#20
	bl _delayMS
	.dbline 614
; 		  if (UART0_LSR & 0x01) {				   // char arrived?
	ldr R4,LIT_UARTParseNewChar+20
	ldr R4,[R4,#0]
	tst R4,#1
	beq L215
	.dbline 614
	.dbline 615
;             newChar = UART0_RBR;
	ldr R4,LIT_UARTParseNewChar+24
	ldr R4,[R4,#0]
	mov R8,R4
	.dbline 616
; 		  }
L215:
	.dbline 617
; 		}
L212:
	.dbline 612
	add R7,R7,#1
	.dbline 612
	cmp R7,#100
	blt L211
	.dbline 618
; 		enterReprogrammingMode();
	bl _enterReprogrammingMode
	.dbline 619
; 	  }
L207:
	.dbline 620
;   }  // end of switch  
L193:
	.dbline -2
L191:
	ldmfd R11,{R4,R5,R6,R7,R8,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
LIT_UARTParseNewChar:
	DCD _commandLinePointer
	DCD _enableEventSending
	DCD L200
	DCD _commandLine
	DCD L210
	DCD -536821740
	DCD -536821760
	.dbsym r n 7 L
	.dbsym r newChar 8 c
	.dbend
	AREA	"Cudata", NOINIT
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\UART.c
	EXPORT _commandLinePointer
	ALIGN	4
_commandLinePointer:
	SPACE 4
	.dbsym e commandLinePointer _commandLinePointer l
	EXPORT _commandLine
_commandLine:
	SPACE 96
	.dbsym e commandLine _commandLine A[96:96]c
	IMPORT _eDVSDataFormat
	IMPORT _requestedEventRate
	IMPORT _enableAutomaticEventRateControl
	IMPORT _enableEventSending
	IMPORT _transmitEventRateEnable
	IMPORT _TXBufferIndex
	IMPORT _TXBuffer
	IMPORT _eventBufferReadPointer
	IMPORT _eventBufferWritePointer
	AREA	"C$$code", CODE, READONLY
L210:
	DCB "Reached cmd line length, resetting into bootloader mode!", 10, 0
L200:
	DCB "%c %c", 0
L184:
	DCB "?", 10, 13, 0
L165:
	DCB "Set: parsing error", 10, 0
L161:
	DCB "Switching Baud Rate to %d Baud!", 10, 0
L146:
	DCB "Select default bias set: parsing error", 10, 0
L143:
	DCB "-BD%c", 10, 0
L131:
	DCB "-BF", 10, 0
L115:
	DCB "Get: parsing error", 10, 0
L108:
	DCB "-E%d", 10, 0
L106:
	DCB "-B%d=%d", 10, 0
L82:
	DCB " !E32  - 10 bytes per event+ts 1/64M res, ASCII <1p> <3y> <3x> <10ts> <nl>", 10, 0
L81:
	DCB " !E31  - 10 bytes per event+ts 1us res, ASCII <1p> <3y> <3x> <8ts> <nl>", 10, 0
L80:
	DCB " !E30  - 10 bytes per event, ASCII <1p> <3y> <3x>; new-line", 10, 0
L79:
	DCB " !E23  - 8 bytes per event+timestamp, hex encoded; new-line", 10, 0
L78:
	DCB " !E22  - 5 bytes per event, hex encoded; new-line", 10, 0
L77:
	DCB " !E21  - 8 bytes per event+timestamp, hex encoded ", 10, 0
L76:
	DCB " !E20  - 4 bytes per event, hex encoded", 10, 0
L75:
	DCB " !E3   - 6 bytes per event (as above followed by 32bit timestamp 1/64M res)", 10, 0
L74:
	DCB " !E2   - 5 bytes per event (as above followed by 24bit timestamp 1us res)", 10, 0
L73:
	DCB " !E1   - 4 bytes per event (as above followed by 16bit timestamp 1us res)", 10, 0
L72:
	DCB " !E0   - 2 bytes per event binary 0yyyyyyy.pxxxxxxx (default)", 10, 0
L70:
	DCB " ??         - display help", 10, 0
L69:
	DCB " P          - enter reprogramming mode", 10, 0
L68:
	DCB " R          - reset board", 10, 0
L67:
	DCB " !S=x       - set baudrate to x", 10, 0
L66:
	DCB " 0,1,2      - LED off/on/blinking", 10, 0
L65:
	DCB " !R+/-      - transmit event rate on/off", 10, 0
L64:
	DCB " ?B#x       - get bias register x encoded within event stream", 10, 0
L63:
	DCB " ?Bx        - get bias register x current value", 10, 0
L62:
	DCB " !BDx       - select and flush default bias set (default: set 0)", 10, 0
L61:
	DCB " !BF        - send bias settings to DVS", 10, 0
L60:
	DCB " !Bx=y      - set bias register x[0..11] to value y[0..0xFFFFFF]", 10, 0
L59:
	DCB " !Ex        - specify event data format, ??E to list options", 10, 0
L58:
	DCB " E+/-       - enable/disable event sending", 10, 0
L57:
	DCB "Supported Commands:", 10, 0
L55:
	DCB "Modules: ", 0
L54:
	DCB "System Clock: %2dMHz / %d -> %dns event time resolution", 0
L53:
	DCB "10:31:11", 0
L52:
	DCB ", ", 0
L51:
	DCB "Nov 23 2011", 0
L50:
	DCB ": ", 0
L49:
	DCB "1.3", 0
L48:
	DCB "EDVS128_LPC2106, V", 0
L28:
	DCB "unknown/unsupported baud rate!", 10, 0
	END
