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
#include "uart.h"
#include "time.h"
#include "port.h"
#include "ringbuffer.h"
#include "command.h"


void direct_loop()
{
	while(1)
	{
		// RTS is connected to RB10/RP10/CN16
		// D12 is on pin9
		PORT_PIN9 = _RB10;
		
		// CTS is connected to RB5/RP5/CN27
		// D11 is on pin7
		PORT_PIN7 = _RB5;
	}
}


#if 0
// CN ISR
void __attribute__((__interrupt__, no_auto_psv)) _CNInterrupt(void)
{
	// CTS is connected to RB5/RP5/CN27
	// D11 is on pin7
	PORT_PIN7 = _RB5;
	
	// RTS is connected to RB10/RP10/CN16
	// D11 is on pin9
	_LATB10= _RB5;
	PORT_PIN9 = _LATB10;
	
	// clear interrupt flag
	IFS1bits.CNIF= 0;
}
#endif


// careful
//   - asserted == LOW
//   - RTS(computer) -> CTS(dsPIC)
//   - CTS(computer) <- RTS(dsPIC)


void setup_ISR()
{
	// init LED state
	sleep(100);
	PORT_PIN9 = _RB10;
	PORT_PIN7 = _RB5;
	uart_print("LEDs set\n\r");

	// generate CN int for RTS
	CNEN2bits.CN27IE= 1;
	IEC1bits.CNIE= 1;
	_CNInterrupt();
}

void test_RTS()
{
	int i,c;
	
	PORT_LED11= 0;
	PORT_LED12= 0;
	
	if (_RB5)
		uart_print("CTS not asserted (HIGH)\n\r");
	else
		uart_print("CTS asserted (LOW)\n\r");
	
	// assert RTS for communication
	if (1) {
		uart_print("RTS asserted (LOW)\n\r");
		_LATB10=0;
	} else {
		uart_print("RTS not asserted (HIGH)\n\r");
		_LATB10=1;
	}
	
	
	// line length teller
	for(i=0,c=0; c!='\n' && c!='\r'; i++)
	{
		// wait for next char
		while (USTAbits.URXDA==0)
			Nop();
			
		// just turn on LED as soon as something is received
		PORT_LED11= 1;
		
		c= URXREG;
		uart_print_i(c);
		uart_print("\n\r");
	}
	
	PORT_LED12= 1;
	
	uart_print("received # chars : ");
	uart_print_i(i);
	uart_print("\n\r");
}

int main()
{
	clock_init();
	port_init();
	time_init();
	ringbuffer_init();
	uart_init();
	
	// configure RTS as output
	_TRISB10= 0;
	
	uart_print("\n\n\rdebug program started\n\r");
	//direct_loop();
	
	//setup_ISR();
	
	test_RTS();
	
	// loop
	while(1) Nop();
	
	return 0;
}
