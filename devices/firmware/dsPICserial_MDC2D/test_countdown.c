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
//#include "uart.h"
#include "time.h"
#include "port.h"


#define IFSbits IFS1bits
#define UMODEbits U2MODEbits
#define UBRG U2BRG
#define UMODEbits U2MODEbits
#define USTAbits U2STAbits
#define IECbits IEC1bits
#define UTXIE U2TXIE
#define URXIE U2RXIE
#define _URXInterrupt _U2RXInterrupt
#define _UTXInterrupt _U2TXInterrupt
#define URXREG U2RXREG
#define UTXREG U2TXREG
#define URXIF U2RXIF
#define UTXIF U2TXIF


unsigned char dma_buffer[5] __attribute__((space(dma)));

#define BRGVAL	4		// that's about 495172 baud
//#define BRGVAL	1		// (FCY/(16*(BRGVAL+1)) = 1237929 baud

void uart_dma_init()
{
	UMODEbits.STSEL = 0; 	// 1-stop bit
	UMODEbits.PDSEL = 0; 	// No Parity, 8-data bits
	
	UMODEbits.ABAUD = 0; 	// Auto-Baud Disabled
	UMODEbits.BRGH = 0; 	// Low Speed mode
	UBRG = BRGVAL; 			// BAUD Rate Setting
	
	USTAbits.UTXISEL0 = 0;	// interrupt after every char (for DMA)
	USTAbits.UTXISEL1 = 0;

	IECbits.UTXIE = 0; 		// Disable UART Tx interrupt
	IECbits.URXIE = 0; 		// Disable UART Rx interrupt

	UMODEbits.UARTEN = 1; 	// Enable UART
	USTAbits.UTXEN = 1;		// Enable UART Tx
	
	// DMA setup
	DMA0CONbits.SIZE = 1;	// byte transfer
	DMA0CONbits.DIR = 1;	// RAM -> peripheral
	DMA0CONbits.HALF = 0;	// interrupt on full transfer
	DMA0CONbits.AMODE0 = 0;	// register indirect, post-incremental
	DMA0CONbits.AMODE1 = 0;
	DMA0CONbits.MODE0 = 1;	// one-shot
	DMA0CONbits.MODE1 = 0;	// ping-pong disabled
	DMA0REQ = 0x001F;		// UART2 Tx
	
	DMA0PAD = (volatile unsigned int) &UTXREG;
	
	IFS0bits.DMA0IF = 0;	// clear interrupt flag
	IEC0bits.DMA0IE = 1;	// enable DMA interrupt
}

void __attribute__((__interrupt__, no_auto_psv)) _DMA0Interrupt()
{
	IFS0bits.DMA0IF = 0;
}


void dma_print_i(unsigned int i)
{
	int j;
	for(j=3; j>=0; j--)
	{
		dma_buffer[j]= ( (i&0x0F)<0x0A ? '0' : 'A'-0x0A ) + (i&0x0F) ;
		i>>=4;
	}
	
	// kick start DMA transfer
	DMA0STA = __builtin_dmaoffset(dma_buffer);
	DMA0CNT = 4;			// 5 bytes to transfer
	DMA0CONbits.CHEN = 1;
	DMA0REQbits.FORCE = 1;
}


// set WDT timeout about 2s = 32*2048/32kHz
_FWDT( FWDTEN_ON | WDTPRE_PR32 | WDTPOST_PS2048 );

int main()
{
	clock_init();
	port_init();
	uart_dma_init();
	
//	uart2_print("\n\rjAER_test starting:\n\r");
	
	UTXREG= '\n';
	dma_buffer[4]= ' ';
	int i=0;
	
	while(1)
	{
		__asm__("CLRWDT");
		dma_print_i(i++);
		
		sleep(1000);
		LED12_TOGGLE;
	}
	
	return 0;
}
