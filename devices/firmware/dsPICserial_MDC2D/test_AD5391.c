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
 


// the actual SPI interface does NOT work (difficult to configure "24bit framed mode")
// -> bitbanging with 1ms/bit cycle length

#include <p33Fxxxx.h>

#include "config.h"
#include "uart.h"
#include "time.h"
#include "port.h"
#include "ringbuffer.h"
#include "command.h"

#define DAC_MOSI _LATB9
#define DAC_NSS  _LATC3
#define DAC_SCK  _LATC4

void spi_init()
{
	// set pins to output
	_TRISB9 = 0;			// DAC_MOSI
	_TRISC3 = 0;			// DAC_NSS
	_TRISC4 = 0;			// DAC_SCK
	// reprogram pins to SPI
//	_RP9R  = 7;				// SPI1 data out
//	_RP20R = 8;				// SPI1 clock
//	_RP19R = 9;				// SPI1 slave select

	SPI1CON1bits.DISSCK= 0;			// don't disable clock
	SPI1CON1bits.DISSDO= 0;			// don't disable output
	SPI1CON1bits.MODE16 = 0;		// 8bit data words
//	SPI1CON1bits.CKE = 1;			// data CHANGES on edge clk=active -> clk=idle
	SPI1CON1bits.CKE = 0;			// not used in framed mode
	SPI1CON1bits.SSEN = 1;			// enable slave select
	SPI1CON1bits.CKP = 0;			// clock idle high
	SPI1CON1bits.MSTEN = 0;			// master mode
	
	// AD5391 max freq = 28.9 MHz (33 ns clock cycle)
	// set to lowest sped here : 40 MHz/(8*64) == 78 kHz
	SPI1CON1bits.PPRE = 0;			// primary prescalar = 64:1
	SPI1CON1bits.SPRE = 0;			// secondary prescalar = 8:1
	
	SPI1CON2bits.FRMEN = 1;			// use "framed" SPI
	SPI1CON2bits.SPIFSD = 0;		// send frame sync pulse
	SPI1CON2bits.FRMPOL = 1;		// sync pulse active high
	SPI1CON2bits.FRMDLY = 0;		// sync preceedes first bit
	
	SPI1STATbits.SPIEN = 1;			// enable SPI1
}


// sends 3 bytes (blocking), with frame marker at 1st byte only
void spi_send3(int a,int b,int c)
{
	//? interrupt enable/disable ??
	while(SPI1STATbits.SPITBF)
		Nop();
	SPI1BUF= a;
	
	SPI1CON2bits.FRMEN = 0;			// disable frame marker temporarily
	
	while(SPI1STATbits.SPITBF)
		Nop();
	SPI1BUF= b;
	
	while(SPI1STATbits.SPITBF)
		Nop();
	SPI1BUF= c;
	
	SPI1CON2bits.FRMEN = 0;			// re-enable frame marker
}


// sends a byte (blocking)
void spi_send(int x)
{
	while(SPI1STATbits.SPITBF)
		Nop();
	SPI1BUF= x;
}

// wait 0.5ms
void DAC_delay()
{
	int i;
	// 5 instructions in loop
	// -> 1000 cycles == 125us
	for(i=0; i<4000; i++)
		Nop();
}

// DAC 24bit serial data format 
// ----------------------------
// B!A R!W 00 AAAA : 1st byte (A/B register, read/write, address)
//   R   R .. .... : 2nd byte (R specifying destination register, 6 MSB data)
//   .   . .. ..XX : 3rd byte (6 LSB data)

void DAC_bitbang3(int a,int b,int c)
{
	//TODO disable interrupts
	DAC_SCK= 1;
	DAC_NSS= 0;
	
	int i,j;
	for(i=0; i<3; i++)
	{
		for(j=7; j>=0; j--)
		{
			DAC_MOSI= (a>>j)&1;
			DAC_delay();
			DAC_SCK= 0;
			DAC_delay();
			DAC_SCK= 1;
		}
		a=b; b=c;
	}
	
	DAC_NSS= 1;
	//TODO enable int4errupts
}

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

void set_bias(int n,unsigned int mv)
{
	// when reg0=reg1=1
	// the 12 data bits are multiplied by 2*V_ref and divided by 2^12
	unsigned int x= ((4095UL*mv)/5000UL)&0xFFFF;
	// 12bit resolution is transmitted in the LSB 14bits where the 12 LSB are ignored
	DAC_bitbang3(n&0xf,0xc0| (x>>6),(x<<2)&0xff);
}

int main()
{
	clock_init();
	port_init();
	time_init();
//	ringbuffer_init();
//	uart_init();

	spi_init();
	DAC_init();
	LED11_TOGGLE;

	int i;
	for(i=0; i<16; i++)
		set_bias(i,2000);
	LED12_ON;
	
	while(1)
	{
		set_bias(0,3000);
		sleep(1000);
		LED12_TOGGLE;
	}
	
	return 0;
}
