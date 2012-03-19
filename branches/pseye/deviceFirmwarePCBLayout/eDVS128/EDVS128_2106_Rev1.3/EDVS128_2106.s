	.dbfile ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
	.dbfile ..\..\..\..\..\..\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
	EXPORT _defInterruptServiceRoutine
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
	.dbfunc e defInterruptServiceRoutine _defInterruptServiceRoutine fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_defInterruptServiceRoutine:
	.dbline -1
	.dbline 7
; #include "EDVS128_2106.h"
; 
; long ledState;	 			// 0:off, -1:on, -2:blinking, >0: timeOn
; 
; // *****************************************************************************
; #pragma interrupt_handler defInterruptServiceRoutine
; void defInterruptServiceRoutine(void) {
	.dbline -2
L1:
	sub PC,R14,#4
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
	.dbend
	EXPORT _initProcessor
	.dbfunc e initProcessor _initProcessor fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_initProcessor:
	.dbline -1
	.dbline 12
; /* */
; }
; 
; // *****************************************************************************
; void initProcessor(void) {
	.dbline 14
; 
;   __DISABLE_INTERRUPT();
	mrs R12,cpsr
	orr R12,R12,#0x80
	msr cpsr_c,R12
	
	.dbline 29
; 
; // ************************************************************* PLL
;   //PLL				   		  	// set frequency
; 
; #if PLL_CLOCK == 112
;   SCB_PLLCFG = 0x26;			// multiplier 7(6+1), divider 2 --> Frequency 16.0 MHz * 7 ~ 112 MHz
; #endif
; #if PLL_CLOCK == 96
;   SCB_PLLCFG = 0x25;			// multiplier 6(5+1), divider 2 --> Frequency 16.0 MHz * 6 ~  96 MHz
; #endif
; #if PLL_CLOCK == 80
;   SCB_PLLCFG = 0x24;			// multiplier 5(4+1), divider 2 --> Frequency 16.0 MHz * 5 ~  80 MHz
; #endif
; #if PLL_CLOCK == 64
;   SCB_PLLCFG = 0x23;			// multiplier 4(3+1), divider 2 --> Frequency 16.0 MHz * 4 ~  64 MHz
	mov R0,#35
	ldr R1,LIT_initProcessor+0
	str R0,[R1,#0]
	.dbline 35
; #endif
; #if PLL_CLOCK == 32
;   SCB_PLLCFG = 0x21;			// multiplier 2(1+1), divider 2 --> Frequency 16.0 MHz * 2 ~  64 MHz
; #endif
; 
;   SCB_PLLCON = 0x01;			// set PLL enable
	mov R0,#1
	ldr R1,LIT_initProcessor+4
	str R0,[R1,#0]
	.dbline 37
; 
;   SCB_PLLFEED = 0xAA;	 		// activate frequency
	mov R0,#170
	ldr R1,LIT_initProcessor+8
	str R0,[R1,#0]
	.dbline 38
;   SCB_PLLFEED = 0x55;
	mov R0,#85
	ldr R1,LIT_initProcessor+8
	str R0,[R1,#0]
L3:
	.dbline 39
;   while ((SCB_PLLSTAT & 0x0400) == 0) {  			// wait till PLL locked
	.dbline 40
;   };
L4:
	.dbline 39
	ldr R0,LIT_initProcessor+12
	ldr R0,[R0,#0]
	tst R0,#1024
	beq L3
	.dbline 40
	.dbline 41
;   SCB_PLLCON = 0x03;			// set PLL connect & enable
	mov R0,#3
	ldr R1,LIT_initProcessor+4
	str R0,[R1,#0]
	.dbline 43
; 
;   SCB_PLLFEED = 0xAA;	 		// activate frequency
	mov R0,#170
	ldr R1,LIT_initProcessor+8
	str R0,[R1,#0]
	.dbline 44
;   SCB_PLLFEED = 0x55;
	mov R0,#85
	ldr R1,LIT_initProcessor+8
	str R0,[R1,#0]
	.dbline 47
;   
;   // ****************************************** MAM (memory Acceleration Module)
;   MAM_CR = 0;
	mov R0,#0
	ldr R1,LIT_initProcessor+16
	str R0,[R1,#0]
	.dbline 48
;   MAM_TIM = 0x00000003;
	mov R0,#3
	ldr R1,LIT_initProcessor+20
	str R0,[R1,#0]
	.dbline 49
;   MAM_CR = 0x00000002;
	mov R0,#2
	ldr R1,LIT_initProcessor+16
	str R0,[R1,#0]
	.dbline 52
; 
; // *************************************************** No wakeup from powerdown
;   SCB_EXTWAKE=0x00000000;
	mov R0,#0
	ldr R1,LIT_initProcessor+24
	str R0,[R1,#0]
	.dbline 57
; 
; // ************************************************************* Bus clock
; //  SCB_VPBDIV = 0x00000000; //peripheral clock divider, 1/4 of main clock
; //  SCB_VAPBDIV = 0x00000002; //peripheral clock divider, 1/2 of main clock
;   SCB_VPBDIV = 0x00000001; //peripheral clock divider, identical to main clock
	mov R0,#1
	ldr R1,LIT_initProcessor+28
	str R0,[R1,#0]
	.dbline 60
; 
;   // ********************************************************* interrupt vector
;   VICIntSelect=0x00000000;
	mov R0,#0
	ldr R1,LIT_initProcessor+32
	str R0,[R1,#0]
	.dbline 61
;   VICSoftInt = 0x00000000;
	mov R0,#0
	ldr R1,LIT_initProcessor+36
	str R0,[R1,#0]
	.dbline 62
;   VICSoftIntClear = 0xFFFFFFFF;
	mvn R0,#0
	ldr R1,LIT_initProcessor+40
	str R0,[R1,#0]
	.dbline 63
;   VICIntEnable=0x00000000;
	mov R0,#0
	ldr R1,LIT_initProcessor+44
	str R0,[R1,#0]
	.dbline 65
; 
;   VICDefVectAddr=(unsigned)defInterruptServiceRoutine;
	ldr R0,LIT_initProcessor+48
	ldr R1,LIT_initProcessor+52
	str R0,[R1,#0]
	.dbline 66
;   __ENABLE_INTERRUPT();
	mrs R12,cpsr
	bic R12,R12,#0x80
	msr cpsr_c,R12
	
	.dbline 71
;   
;   
;   // ************************************************************* IO ports
;   // port setings
;   SCB_SCS = 0x00000001;								// enable fast IO ports
	mov R0,#1
	ldr R1,LIT_initProcessor+56
	str R0,[R1,#0]
	.dbline 72
;   FGPIO_IOMASK = 0x00000000;						// unmask ports
	mov R0,#0
	ldr R1,LIT_initProcessor+60
	str R0,[R1,#0]
	.dbline 74
; 
;   FGPIO_IODIR  = 0x00000000;		 		  		// initially all pins input
	mov R0,#0
	ldr R1,LIT_initProcessor+64
	str R0,[R1,#0]
	.dbline 75
;   FGPIO_IOCLR  = 0xFFFFFFFF;	  			   		// clear these pins
	mvn R0,#0
	ldr R1,LIT_initProcessor+68
	str R0,[R1,#0]
	.dbline 77
; 
;   PCB_PINSEL0 = 0x00000000;							// all pins to GPIO
	mov R0,#0
	ldr R1,LIT_initProcessor+72
	str R0,[R1,#0]
	.dbline 78
;   PCB_PINSEL1 = 0x00000000;
	mov R0,#0
	ldr R1,LIT_initProcessor+76
	str R0,[R1,#0]
	.dbline 82
; 	// individual functions will be added during their respective Init calls
;   
;   // ********************************************************* IO pins
;   FGPIO_IOSET  = PIN_ISP;				// ISP (P0.14) pin to high
	mov R0,#16384
	ldr R1,LIT_initProcessor+80
	str R0,[R1,#0]
	.dbline 83
;   FGPIO_IODIR |= PIN_ISP;				// ISP (P0.14) pin to output
	ldr R0,LIT_initProcessor+64
	ldr R1,[R0,#0]
	orr R1,R1,#16384
	str R1,[R0,#0]
	.dbline -2
L2:
	mov R15,R14
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
LIT_initProcessor:
	DCD -534790012
	DCD -534790016
	DCD -534790004
	DCD -534790008
	DCD -534790144
	DCD -534790140
	DCD -534789820
	DCD -534789888
	DCD -4084
	DCD -4072
	DCD -4068
	DCD -4080
	DCD _defInterruptServiceRoutine
	DCD -4044
	DCD -534789728
	DCD 1073725456
	DCD 1073725440
	DCD 1073725468
	DCD -536690688
	DCD -536690684
	DCD 1073725464
	.dbend
	EXPORT _delayUS
	.dbfunc e delayUS _delayUS fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;              n -> R4
;              m -> R5
;    delayTimeUS -> R0
_delayUS:
	mov R12,R13
	stmfd R13!,{R4,R5,R12,R14}
	.dbline -1
	.dbline 87
; }
; 
; // *****************************************************************************
; void delayUS(unsigned long delayTimeUS) {
	.dbline 104
;   unsigned long m,n;
; #if PLL_CLOCK == 112
; #define DELAY_1US	  ((unsigned short) 0x000A)			// at 7x16 = 112 MHz (should be 10.5)
; #endif
; #if PLL_CLOCK == 96
; #define DELAY_1US	  ((unsigned short) 0x0009)			// at 6x16 = 96 MHz
; #endif
; #if PLL_CLOCK == 80
; #define DELAY_1US	  ((unsigned short) 0x0007)			// at 5x16 = 80 MHz (should be 7.5)
; #endif
; #if PLL_CLOCK == 64
; #define DELAY_1US	  ((unsigned short) 0x0006)			// at 4x16 = 64 MHz
; #endif
; #if PLL_CLOCK == 32
; #define DELAY_1US	  ((unsigned short) 0x0003)			// at 2x16 = 32 MHz
; #endif
;   for (n=0; n<delayTimeUS; n++) {
	mov R4,#0
	b L10
L7:
	.dbline 104
	.dbline 105
;     for (m=DELAY_1US; m; m--) {
	mov R5,#6
	b L14
L11:
	.dbline 105
	.dbline 106
; 	}
L12:
	.dbline 105
	sub R5,R5,#1
L14:
	.dbline 105
	cmp R5,#0
	bne L11
	.dbline 107
;   }
L8:
	.dbline 104
	add R4,R4,#1
L10:
	.dbline 104
	cmp R4,R0
	blo L7
	.dbline -2
L6:
	ldmfd R13!,{R4,R5,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
	.dbsym r n 4 l
	.dbsym r m 5 l
	.dbsym r delayTimeUS 0 l
	.dbend
	EXPORT _delayMS
	.dbfunc e delayMS _delayMS fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;              n -> R4
;              m -> R5
;    delayTimeMS -> R0
_delayMS:
	mov R12,R13
	stmfd R13!,{R4,R5,R12,R14}
	.dbline -1
	.dbline 109
; }
; void delayMS(unsigned long delayTimeMS) {
	.dbline 112
;   unsigned long m,n;
; #define DELAY_1MS	  ((unsigned short) ((0x5A)*PLL_CLOCK))
;   for (n=0; n<delayTimeMS; n++) {
	mov R4,#0
	b L19
L16:
	.dbline 112
	.dbline 113
;     for (m=DELAY_1MS; m; m--) {
	mov R5,#5760
	b L23
L20:
	.dbline 113
	.dbline 114
; 	}
L21:
	.dbline 113
	sub R5,R5,#1
L23:
	.dbline 113
	cmp R5,#0
	bne L20
	.dbline 115
;   }
L17:
	.dbline 112
	add R4,R4,#1
L19:
	.dbline 112
	cmp R4,R0
	blo L16
	.dbline -2
L15:
	ldmfd R13!,{R4,R5,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
	.dbsym r n 4 l
	.dbsym r m 5 l
	.dbsym r delayTimeMS 0 l
	.dbend
	EXPORT _LEDSetState
	.dbfunc e LEDSetState _LEDSetState fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
;          state -> R4
_LEDSetState:
	mov R12,R13
	stmfd R13!,{R4,R12,R14}
	mov R4,R0
	.dbline -1
	.dbline 119
; }
; 
; // *****************************************************************************
; void LEDSetState(long state) {
	.dbline 120
;   ledState = state;
	ldr R0,LIT_LEDSetState+0
	str R4,[R0,#0]
	.dbline 121
;   if (state!=0) {
	cmp R4,#0
	beq L25
	.dbline 121
	.dbline 122
;     LED_ON();
	.dbline 122
	mov R0,#8192
	ldr R1,LIT_LEDSetState+4
	str R0,[R1,#0]
	.dbline 122
	.dbline 122
	.dbline 123
;   } else {
	b L26
L25:
	.dbline 123
	.dbline 124
;     LED_OFF();
	.dbline 124
	mov R0,#8192
	ldr R1,LIT_LEDSetState+8
	str R0,[R1,#0]
	.dbline 124
	.dbline 124
	.dbline 125
;   }
L26:
	.dbline -2
L24:
	ldmfd R13!,{R4,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
LIT_LEDSetState:
	DCD _ledState
	DCD 1073725468
	DCD 1073725464
	.dbsym r state 4 L
	.dbend
	EXPORT _LEDInit
	.dbfunc e LEDInit _LEDInit fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_LEDInit:
	mov R12,R13
	stmfd R13!,{R4,R5,R11,R12,R14}
	mov R11,R13
	.dbline -1
	.dbline 127
; }
; void LEDInit(void) {
	.dbline 128
;   FGPIO_IODIR |= PIN_LED;			   	// set LEDs as output
	ldr R4,LIT_LEDInit+0
	ldr R5,[R4,#0]
	orr R5,R5,#8192
	str R5,[R4,#0]
	.dbline 129
;   LEDSetBlinking();
	mvn R0,#0
	bl _LEDSetState
	.dbline -2
L27:
	ldmfd R11,{R4,R5,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
LIT_LEDInit:
	DCD 1073725440
	.dbend
	EXPORT _resetDevice
	.dbfunc e resetDevice _resetDevice fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_resetDevice:
	.dbline -1
	.dbline 134
; //  LEDSetOn();
; }
; 
; // *****************************************************************************
; void resetDevice(void) {
	.dbline 141
; #ifdef INCLUDE_PWM246
;   PWM246StopPWM();
; #endif
; 
;   // convince WDT to trigger :)
; 
;   WD_WDTC  = 0xFF;	  	 	     // minimal time allowed
	mov R0,#255
	ldr R1,LIT_resetDevice+0
	str R0,[R1,#0]
	.dbline 142
;   WD_WDMOD = 0x03;				 // enable WDT and reset on underflow
	mov R0,#3
	ldr R1,LIT_resetDevice+4
	str R0,[R1,#0]
	.dbline 144
;   		  					 		   // PCLCK at 60MHz -> Reset after 1000*(1/60MHz)
;   WD_WDFEED = 0xAA;  	 		 // enable watch dog
	mov R0,#170
	ldr R1,LIT_resetDevice+8
	str R0,[R1,#0]
	.dbline 145
;   WD_WDFEED = 0x55;
	mov R0,#85
	ldr R1,LIT_resetDevice+8
	str R0,[R1,#0]
L29:
	.dbline 147
; 
;   while (1) {	  						   // infinite loop, rest will trigger
	.dbline 148
;   };
L30:
	.dbline 147
	b L29
X0:
	.dbline -2
L28:
	mov R15,R14
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
LIT_resetDevice:
	DCD -536870908
	DCD -536870912
	DCD -536870904
	.dbend
	EXPORT _enterReprogrammingMode
	.dbfunc e enterReprogrammingMode _enterReprogrammingMode fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
; bootloader_entry -> R6
;        newChar -> R11,-1
_enterReprogrammingMode:
	mov R12,R13
	stmfd R13!,{R4,R5,R6,R11,R12,R14}
	mov R11,R13
	sub R13,R13,#0x4
	.dbline -1
	.dbline 152
; }
; 
; // *****************************************************************************
; void enterReprogrammingMode(void) {
	.dbline 153
;   void (*bootloader_entry)(void) = (void*)0;
	mov R6,#0
	.dbline 160
;   volatile char newChar;
; 
; #ifdef INCLUDE_PWM246
;   PWM246StopPWM();
; #endif
; 
;   __DISABLE_INTERRUPT();
	mrs R12,cpsr
	orr R12,R12,#0x80
	msr cpsr_c,R12
	
	.dbline 161
;   VICIntEnClr = 0xFFFFFFFF;            	// Clear all interrupts
	mvn R4,#0
	ldr R5,LIT_enterReprogrammingMode+0
	str R4,[R5,#0]
	.dbline 164
; 
;   /* reset PINSEL (set all pins to GPIO) */
;   SCB_SCS = 0x0000;					// disable fast IO ports
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+4
	str R4,[R5,#0]
	.dbline 165
;   PCB_PINSEL0 = 0x00000000;			// all pins to IO
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+8
	str R4,[R5,#0]
	.dbline 166
;   PCB_PINSEL1 = 0x00000000;
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+12
	str R4,[R5,#0]
	.dbline 169
; 
;   /* reset GPIO, but drive P0.14 low (output) */
;   GPIO_IODIR  = PIN_ISP;	   	   // only ISP (->P0.14) pin to output
	mov R4,#16384
	ldr R5,LIT_enterReprogrammingMode+16
	str R4,[R5,#0]
	.dbline 170
;   GPIO_IOCLR  = PIN_ISP;           // ISP (->P0.14) pin to low
	mov R4,#16384
	ldr R5,LIT_enterReprogrammingMode+20
	str R4,[R5,#0]
	.dbline 171
;   delayMS(20);
	mov R0,#20
	bl _delayMS
	.dbline 174
; 
;   /* power up all peripherals */
;   SCB_PCONP = 0x000003be;     /* for LPC2104/5/6
	ldr R4,LIT_enterReprogrammingMode+24
	ldr R5,LIT_enterReprogrammingMode+28
	str R4,[R5,#0]
	.dbline 177
; 
;   /* disconnect PLL */
;   SCB_PLLCON = 0x00;
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+32
	str R4,[R5,#0]
	.dbline 178
;   SCB_PLLFEED = 0xAA;
	mov R4,#170
	ldr R5,LIT_enterReprogrammingMode+36
	str R4,[R5,#0]
	.dbline 179
;   SCB_PLLFEED = 0x55;
	mov R4,#85
	ldr R5,LIT_enterReprogrammingMode+36
	str R4,[R5,#0]
	.dbline 182
; 
;   /* set peripheral bus to 1/4th of the system clock */
;   SCB_VPBDIV = 0x00;
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+40
	str R4,[R5,#0]
	.dbline 185
; 
;   /* map bootloader vectors */
;   SCB_MEMMAP = 0;
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+44
	str R4,[R5,#0]
	.dbline 188
; 
;   /* clear WDT */
;   WD_WDMOD = 0; 			  // disable WDT; ensure overflow-flag is false,
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+48
	str R4,[R5,#0]
	.dbline 192
;   			  				  // otherwise BL is ignored
; 
;   /* clear fractional baud rate generator of serial port */
;   UART0_FDR = 0x10;							// clear fractional baud rate
	mov R4,#16
	ldr R5,LIT_enterReprogrammingMode+52
	str R4,[R5,#0]
	.dbline 193
;   UART0_FCR = 0x00;							// disable the fifos
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+56
	str R4,[R5,#0]
	b L34
L33:
	.dbline 194
;   while (UART0_LSR & 0x01) {				// new char here?
	.dbline 195
;     newChar = UART0_RBR;
	ldr R4,LIT_enterReprogrammingMode+60
	ldr R4,[R4,#0]
	strb R4,[R11,#-1]
	.dbline 196
;   }
L34:
	.dbline 194
	ldr R4,LIT_enterReprogrammingMode+64
	ldr R4,[R4,#0]
	tst R4,#1
	bne L33
	.dbline 199
; 
;   /* reset T1 to default value */
;   T1_CTCR = 0x00;				// increase time on PCLK
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+68
	str R4,[R5,#0]
	.dbline 200
;   T1_PR	  = 0;					// prescale register, increment timer every 64000th PCLK == 1ms
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+72
	str R4,[R5,#0]
	.dbline 201
;   T1_MCR  = 0x00;				// match register, no action on any matches (later: reset on 0xFFFF) !!!
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+76
	str R4,[R5,#0]
	.dbline 202
;   T1_CCR  = 0x00;				// react on external falling edge, generate interrupt
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+80
	str R4,[R5,#0]
	.dbline 203
;   T1_TC	  = 0;					// reset counter to zero
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+84
	str R4,[R5,#0]
	.dbline 204
;   T1_TCR  = 0x0;				// enable Timer/Counter 0
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+88
	str R4,[R5,#0]
	.dbline 207
; 
;   // clear ISP pin, such that after ISP system returns to running mode
;   GPIO_IODIR  = 0;	   	      // all pins back to input
	mov R4,#0
	ldr R5,LIT_enterReprogrammingMode+16
	str R4,[R5,#0]
	.dbline 210
; 
;   /* jump to the bootloader address */
;   bootloader_entry();
	mov R14,R15
	mov R15,R6
	.dbline -2
L32:
	ldmfd R11,{R4,R5,R6,R11,SP,R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
LIT_enterReprogrammingMode:
	DCD -4076
	DCD -534789728
	DCD -536690688
	DCD -536690684
	DCD -536707064
	DCD -536707060
	DCD 958
	DCD -534789948
	DCD -534790016
	DCD -534790004
	DCD -534789888
	DCD -534790080
	DCD -536870912
	DCD -536821720
	DCD -536821752
	DCD -536821760
	DCD -536821740
	DCD -536838032
	DCD -536838132
	DCD -536838124
	DCD -536838104
	DCD -536838136
	DCD -536838140
	.dbsym r bootloader_entry 6 pfV
	.dbsym l newChar -1 c
	.dbend
	EXPORT _main
	.dbfunc e main _main fV
	AREA	"C$$code", CODE, READONLY
	CODE32
	ALIGN 4
_main:
	stmfd R13!,{R14}
	.dbline -1
	.dbline 217
; }
; 
; 
; // *****************************************************************************
; // ************************************************************* Main
; // *****************************************************************************
; void main(void) {
	.dbline 218
;   (void) initProcessor();
	bl _initProcessor
	.dbline 220
; 
;   (void) DVS128ChipInit();
	bl _DVS128ChipInit
	.dbline 222
; 
;   (void) LEDInit();
	bl _LEDInit
	.dbline 224
; 
;   (void) UARTInit();
	bl _UARTInit
	.dbline 234
; 
; #ifdef INCLUDE_PWM246
;   (void) PWM246Init();
; #endif
; 
; #ifdef INCLUDE_TRACK_HF_LED
;   (void) EP_TrackHFLInit();
; #endif
; 
;   (void) mainloopInit();
	bl _mainloopInit
	.dbline 236
; 
;   (void) UARTShowVersion();
	bl _UARTShowVersion
	.dbline 238
; 
;   (void) mainloop();
	bl _mainloop
	.dbline -2
L36:
	ldmfd R13!,{R15}
	.dbline 0 ; func end
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
	.dbend
	AREA	"Cudata", NOINIT
	.dbfile C:\DOCUME~1\conradt\MYDOCU~1\Projects\DVS128\EDVS128_2106_Rev1.3\EDVS128_2106.c
	EXPORT _ledState
	ALIGN	4
_ledState:
	SPACE 4
	.dbsym e ledState _ledState L
	END
