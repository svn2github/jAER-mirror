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



// dsPIC streaming some data to computer
// computer controls stream with short commands over serial line
// using tx-ringbuffer (rx buffer is luxury...)

// prototype-design of firmware that streams pictures to jAER




#include <p33Fxxxx.h>

#include "config.h"
#include "uart.h"
#include "time.h"
#include "port.h"
#include "ringbuffer.h"
#include "command.h"


// generates sequence of numbers upon keypress
void key_loop()
{
	int i,n;
	
	uart_init_txbuf();
	
	while(1)
	{
		if (U2STAbits.URXDA) {
			LED11_TOGGLE;
			n= U2RXREG - '0';
			
			for(i=0; i<n; i++)
			{
				uart_print_i_buf(i);
				uart_print_buf("  ");
			}
			uart_print_buf("\r\n");
			
			uart_flush();
		}
	}
}

// transforms every '\n' terminated line into its hex equivalent

void hex_loop()
{
	int i,c;
	
	uart_init_rxbuf();
	uart_init_txbuf();
	
	uart_print_buf("started\n\r");
	
	while(0)
	{
		if (!RB_EMPTY(rx_buf))
		{
			uart_print_buf("last char = ");
			uart_print_i_buf(RB_LAST(rx_buf));
			uart_print_buf("; length = ");
			uart_print_i_buf(RB_SIZE(rx_buf));
		} else {
			uart_print_buf("empty.");
		}
		uart_print_buf("\n\r");
		uart_flush();
		sleep(500);
	}
	
	while(0)
	{
		if (!RB_EMPTY(rx_buf))
//			(RB_LAST(rx_buf) == '\n'))
		{
			uart_print_buf("got line.\n\r");
			uart_flush();
			rx_buf.head= rx_buf.tail;
			rx_buf.state= RB_EMPTY;
		}
	}

	while(1)
	{
		if (!RB_EMPTY(rx_buf) && 
			 (RB_LAST(rx_buf) == 0x000d || RB_LAST(rx_buf) ==  0x000a) )
		{
			LED11_TOGGLE;
			
			for(i=0; !RB_EMPTY(rx_buf); i++)
			{
				c= RB_ATTAIL(rx_buf);
				RB_INCTAIL(rx_buf);
				uart_print_i_buf(c);
				uart_print_buf  ("  ");
				if ( (i+1)%8 == 0 )
				  uart_print_buf  ("\r\n");
			}
		  	uart_print_buf  ("\r\n");
			
			uart_flush();
		}
	}
}
void hex_loop2()
{
	int c;
	uart_init_txbuf();
	
	while(1)
	{
		if (USTAbits.URXDA)
		{
			LED11_TOGGLE;
			c= URXREG;
			uart_print_i(c);
			uart_print_buf  ("\n\r");
			uart_flush();
		}
	}
}


int main()
{
	clock_init();
	port_init();
	time_init();
	ringbuffer_init();
	uart_init();

	key_loop();
	//hex_loop();
	
	return 0;
}
