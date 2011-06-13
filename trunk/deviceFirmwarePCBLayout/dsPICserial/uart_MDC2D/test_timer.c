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



#include <p33Fxxxx.h>


/***************************************************/
//_FWDT( FWDTEN_ON | WDTPRE_PR32 | WDTPOST_PS2048 ); // roughly 2
_FWDT( FWDTEN_OFF );
/***************************************************/



#include "config.h"
#include "time.h"
#include "port.h"


void setup_timer()
{
	// setting up timer2 (type B)
	T2CONbits.TON = 0;		// disable timer
	T2CONbits.T32 = 0;		// use standalone (as 16bit)
	T2CONbits.TCS = 0;		// FCY as clock source
	T2CONbits.TGATE = 0;	// disable gated timer
	
	T2CONbits.TCKPS = 3;	// 1:256 pre-scalar
	PR2 = 0xFFFF;			// yields 423ms period
	
	// TMR ?
	IPC1bits.T2IP = 1;		// low interrupt priority
	IFS0bits.T2IF = 0;		// clear interrupt flag
	IEC0bits.T2IE = 1;		// enable interrupt
	T2CONbits.TON = 1;		// enable timer
}

int i=0;
void __attribute__((__interrupt__, no_auto_psv)) _T2Interrupt(void)
{
	// make it asynchronously, extend ISR execution time behind
	// next ISR interrupt
	if (i++ %2)
		sleep(2000);
	
	LED11_TOGGLE;
	IFS0bits.T2IF = 0; // Clear Timer 2 Interrupt Flag
	// actually, in the simulator the code works fine regardless
	// whether the timer flag is cleared in the beginning or
	// in the end of the ISR
	
	// (but T2IF gets set during the 2s sleep instruction)
	
	// on the device on the other hand, apparently the ISR
	// does not get called when it returns with the IF set...
}

int main()
{
	int min,sec;
	clock_init();
	port_init();
	
	LED11_ON;
	for(min=0; min<10; min++)
		for(sec=0; sec<60; sec++)
			sleep(1000);
	LED12_ON;
	while(1) Nop();
	
//	setup_timer();
	
	while(1) {
		for(i=0; i<1000; i++)
			sleep(1);
		LED11_TOGGLE;
	}
	
	return 0;
}
