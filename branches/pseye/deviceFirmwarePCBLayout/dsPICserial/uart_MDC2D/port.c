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
 
/*! \file port.c
 *  initializes the ports of the microcontroller
 */
#include "config.h"
#include "port.h"

#include <p33Fxxxx.h>


// platform is defined in config.h
#ifdef PLATFROM_DSDEVEL
#warning "BUILDING FOR DSDEVEL"

//! call this to initialize the port settings
void port_init()
{
	// --------------- Pin config ------------------------------------
	ADPCFG = 0xffff; 		// Set all Analog ports as Digital I/O 
	TRISA = 0xffff;			// Everything is input
	TRISB = 0xffff;			// Everything is input
	
	// --------------- Select output pins ----------------------------
	
	_TRISA0 = 0;
	_TRISA1 = 0;
	_TRISA3 = 0;
	_TRISA4 = 0;
	_TRISB2 = 0;
	_TRISB3 = 0;
	_TRISB4 = 0;
	_TRISB10 = 0;			// RTS
	_TRISB11 = 0;
	_TRISB12 = 0;
	_TRISB13 = 0;
	_TRISB14 = 0;
	_TRISB15 = 0;
	
	// --------------- Default output pin values ---------------------
	
	PORT_PIN27 = 0;
	PORT_PIN28 = 0;
	PORT_PIN7  = 1;
	PORT_PIN9  = 1;
	PORT_PIN3  = 0;
	PORT_PIN4  = 0;
	PORT_PIN8  = 0;
	PORT_PIN19 = 0;
	PORT_PIN20 = 0;
	PORT_PIN21 = 0;
	PORT_PIN22 = 0;
	PORT_PIN23 = 0;
	
	/* Power Supply Enable */
	
	 //------------- UART1 connect to RS485 --------------------------
//	_U1RXR = 15;			// Map UART1 RX to port RP15
//	_RP2R = 3;	            // Map UART1 TX to RP2

	 //------------- UART2 connect to USB-to-RS232 converter ---------
	_U2RXR = 6;				// Map UART2 RX to port RP6
	_RP7R = 5;	            // Map UART2 TX to RP7

}

// end copyright


#elif defined PLATFROM_MDC2D
#warning "BUILDING FOR MDC2D"

//! call this to initialize the port settings
void port_init()
{
	// --------------- Pin config ------------------------------------
	ADPCFG = 0xffff; 		// Set all Analog ports as Digital I/O 
	TRISA  = 0xffff;		// Everything is input
	TRISB  = 0xffff;		// Everything is input
	TRISC  = 0xffff;		// Everything is input
	
	// --------------- Select output pins ----------------------------
	
	_TRISA2 = 0;			// USB_RI_
	_TRISA7 = 0;			// LED11_
	_TRISA10 = 0;			// LED12_
	_TRISB3 = 0;			// USB_CTS_
	_TRISB5 = 0;			// MDC_BIAS_ENABLE
	_TRISB8 = 0;			// MDC_ADC_RESET
	_TRISB9 = 0;			// DAC_MOSI
	_TRISB12 = 0;			// MDC_VCLOCK
	_TRISB13 = 0;			// MDC_HCLOCK
	_TRISB14 = 0;			// MDC_ADC_CLOCK
	_TRISB15 = 0;			// MDC_ADC_CLOCK_HACK
	_TRISC3 = 0;			// DAC_NSS
	_TRISC4 = 0;			// DAC_SCK
	_TRISC5 = 0;			// MDC_BIAS_POWERDOWN
	_TRISC6 = 0;			// MDC_BIAS_BITIN
	_TRISC7 = 0;			// MDC_BIAS_BITLATCH
	_TRISC8 = 0;			// MDC_BIAS_CLOCK
	
	
	// --------------- Default output pin values ---------------------
	
	USB_RI_ = 1;
	LED11_= 1;
	LED12_= 1;
	USB_CTS_ = 1;
	//TODO
	
	// --------------- Configure Analog Input ------------------------
	
	AD1PCFGL = 0xffff;			// disable all analog inputs
	AD1PCFGLbits.PCFG0 = 0;		// enable AN0
	AD1PCFGLbits.PCFG1 = 0;		// enable AN1
	AD1PCFGLbits.PCFG4 = 0;		// enable AN4
	//TODO finish analog config
	

	//------------- UART2 connect to USB-to-RS232 converter ---------
//	_U2RXR = 16;			// Map UART2 RX to port RP16
//	_RP18R = 5;	            // Map UART2 TX to RP18
	//HACK RXD TXD apparently need be swapped !!
	_U2RXR = 18;
	_RP16R = 5;

}

#else
#error "you must define a valid PLATFORM_*"
#endif
