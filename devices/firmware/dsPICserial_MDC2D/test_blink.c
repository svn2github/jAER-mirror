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

#include "config.h"
#include "port.h"
#include "time.h"

_FOSC( FCKSM_CSECMD );

void clock_init_test()
{
	// Disable Watch Dog Timer
	RCONbits.SWDTEN=0;

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

void LED_init()
{
	LED11_ON;
	LED12_OFF;
	
	//PORT_PIN7= 0;
	//PORT_PIN9= 1;
}

void LED_toggle()
{
	LED11_TOGGLE;
	LED12_TOGGLE;
	
	//PORT_PIN7^= 1;
	//PORT_PIN9^= 1;
}

int main()
{
	clock_init_test();
	port_init();
//	time_init();
	
	LED_init();

	while(1) {
		sleep(100);
		LED_toggle();
	}
	return 0;
}
