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
 
 
/*! \file time.c
 * initializes clock speed, precise sleep and for interval measuring
 */
#include "time.h"

#include "p33Fxxxx.h"

// clock switching must be activated in configuration bits !!
_FOSC( FCKSM_CSECMD );

//! initializes the clock speed; also call #tictoc_init
void clock_init()
{
	// disable software WDT (see also _FWDT(...) !)
	RCONbits.SWDTEN= 0;
	
	// Configure PLL prescaler, PLL postscaler, PLL divisor
	PLLFBD = 41; 				// M = 43
	CLKDIVbits.PLLPOST=0; 		// N2 = 2
	CLKDIVbits.PLLPRE=0; 		// N1 = 2

	// Initiate Clock Switch to Internal FRC with PLL (NOSC = 0b001)
	__builtin_write_OSCCONH(0x01);
	__builtin_write_OSCCONL(0x01);

	// Wait for Clock switch to occur
	while (OSCCONbits.COSC != 0b001){};

	// Wait for PLL to lock
	while(OSCCONbits.LOCK != 1) {};
}


//! time elapsed between #TIC and #TOC
unsigned int tictoc_us;
//! Timer 1 is used for performance measuring; see #TIC and #TOC
void __attribute__((__interrupt__, no_auto_psv)) _T1Interrupt(void)
{
	IFS0bits.T1IF = 0; // Clear Timer 1 Interrupt Flag
	tictoc_us += TICTOC_STEP_US;
}

//! sets up timer1 for performance measuring; see #TIC and #TOC
void tictoc_init()
{
	// Set timer 1 as main clock
	T1CONbits.TON = 0; 		// Disable Timer
	T1CONbits.TCS = 0; 		// Select internal instruction cycle clock
	T1CONbits.TGATE = 0; 	// Disable Gated Timer mode

#if TICTOC_CLOCKS < 65535
	/* 1x prescaler should be enough*/
	PR1 = TICTOC_CLOCKS;
	T1CONbits.TCKPS = 0b00; // Select 1:1 Prescaler
#else
#error "TICTOC_CLOCKS - Check the values and maybe use a greater prescaler value"
#endif

	TMR1 = 0x00; 			// Clear timer register
	IPC0bits.T1IP = 0x01; 	// Set Timer1 Interrupt Priority Level to 1 = low priority
	IFS0bits.T1IF = 0; 		// Clear Timer1 Interrupt Flag
	IEC0bits.T1IE = 1; 		// Enable Timer1 interrupt

	tictoc_us = 0;
}

//! sleep for the specified amount of milliseconds;
//  calls #sleep_us
//  \param ms how long to wait (in milliseconds)
void sleep(unsigned int ms)
{
	while(ms > 65) {
		sleep_us(65*1000);
		ms -= 65;
	}
	sleep_us(1000*ms);
}

/*! precise sleep for a short time;
 *  THIS METHOD ASSUMES A CLOCK SPEED OF 40 MIPS !
 *  \param us how long to wait (in microseconds)
 */
void sleep_us(unsigned int us)
{
	// argument in register w0
	// w0-w7 may be changed without notice
	__asm__("MOV.W #40,w1\n"
			"MUL.UU w0,w1,w0\n"
			"SL w1,#2,w1\n"
			"BTST w0,#15\n"
			"BRA z,__sleep_us_no15\n"
			"BSET w1,#1\n"
			"__sleep_us_no15:\n"
			"BTST w0,#14\n"
			"BRA z,__sleep_us_no14\n"
			"BSET w1,#0\n"
			"__sleep_us_no14:\n"
			"CP0 w1\n"
			"BRA z,__sleep_us_short\n"
			"DEC w1,w1\n"
			"MOV #0x3FFF,w2\n"
			"DO w1,__sleep_us_nop\n"
			// repeat count is 14 bits !!
			"REPEAT w2\n"
			"NOP\n"
			"__sleep_us_nop:\n"
			"NOP\n"
			"__sleep_us_short:\n"
			// repeat count is 14 bits !!
			"REPEAT w0\n"
			"NOP\n"
			);
}
