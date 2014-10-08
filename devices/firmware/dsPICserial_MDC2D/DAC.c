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
 
/*! \file DAC.c
 * some simple functions controlling the DAC (an AD5391)
 */
 
#include <p33Fxxxx.h>

#include "config.h"
#include "DAC.h"
#include "port.h"


//! arbitrary delay between bits sent to the DAC
void DAC_delay()
{
	int i;
	// 5 instructions in loop
	// -> 1000 cycles == 125us
	for(i=0; i<4000; i++)
		Nop();
}

/*!sends 3 bytes of data to the DAC; the format is as follows :
\verbatim
B!A R!W 00 AAAA : 1st byte (A/B register, read/write, address)
R   R   .. .... : 2nd byte (R specifying destination register, 6 MSB data)
.   .   .. ..XX : 3rd byte (6 LSB data)
\endverbatim
 */
void DAC_bitbang3(int a,int b,int c)
{
	int ipl= SRbits.IPL;
	SRbits.IPL= 7;					// disable interrupts <level 7
	
	DAC_SCK= 1;
	DAC_NSS= 0;
	
	int i,j;
	for(i=0; i<3; i++)
	{
		for(j=7; j>=0; j--)
		{
			DAC_MOSI= (a>>j)&1;
			DAC_delay();
			DAC_SCK= 0;				// falling edge when bit set
			DAC_delay();
			DAC_SCK= 1;
		}
		a=b; b=c;					// next byte
	}
	
	DAC_NSS= 1;
	SRbits.IPL= ipl;				// set old interrupt level
}

//! initializes the DAC (sets voltage reference etc)
void DAC_init()
{
	// B!A=0 R!W=0 AAAA=1100 : ctrl reg write
	// 11 1101 xxxx 00xx : 
	//  - power down : output is high impedance
	//  - set V_ref to : 2.5 V
	//  - boost mode on : maximizes bias current
	//  - use internal V_ref
	//  - disable channel monitor
	//  - thermal monitor enabled : power down on 130 degree celsius
	//  xxxx
	//  - disable channel group 8-15
	//  - disable channel group 0-7
	//  xx
	DAC_bitbang3(0x0C,0x3D,0x00);
}

/*! sets a channel to a specified voltage
 *  \param n which channel to set
 *  \param mv what voltage to set on channel (in millivolts)
 */
void DAC_set_bias(int n,unsigned int mv)
{
	LED12_ON;
	// when reg0=reg1=1
	// the 12 data bits are multiplied by 2*V_ref and divided by 2^12
	unsigned int x= ((4095UL*mv)/5000UL)&0xFFFF;
	// 12bit resolution is transmitted in the LSB 14bits where the 12 LSB are ignored
	DAC_bitbang3(n&0xf,0xc0| (x>>6),(x<<2)&0xff);
	LED12_OFF;
}
