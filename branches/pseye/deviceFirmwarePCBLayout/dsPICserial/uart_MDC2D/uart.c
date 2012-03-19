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
 
 
/*! \file uart.c
 * functions for blocking and DMA driven UART communication
 */
 
#include "uart.h"

#include <p33Fxxxx.h>

#include "config.h"
#include "port.h"
#include "time.h"
#include "message.h"

/*!
 * config baud rate : the value for \c BRGVAL can be calculated for a
 * given baud rate with a formula, but for high baud rates, the
 * discrepancy gets bigger as \c BRGVAL gets smaller and it is better
 * to define a (low) value for \c BRGVAL and then calculate the exact
 * resulting baud rate...
 */
#define HIGHSPEED
#if defined HIGHSPEED
//#define BRGVAL	4		// that's about 495172 baud
#define BRGVAL	3			// that's about 618964 baud
//#define BRGVAL	2		// that's about 825286 baud
//#define BRGVAL	0		// that's about 2475.859 kbaud
#define BAUD_RATE (FCY/(16*(BRGVAL+1))
#else
#define BAUD_RATE 115200
#define BRGVAL (FCY/(16*BAUD_RATE)-1)
#endif

//! initializes the UART module
void uart_init()
{
	UMODEbits.STSEL = 0; 	// 1-stop bit
	UMODEbits.PDSEL = 0; 	// No Parity, 8-data bits
	// RTS/CTS used for commands (see command.c ISR)

	UMODEbits.ABAUD = 0; 	// Auto-Baud Disabled
	UMODEbits.BRGH = 0; 	// Low Speed mode
	UBRG = BRGVAL; 			// BAUD Rate Setting

	USTAbits.UTXISEL0 = 0;	// interrupt after every char (for DMA)
	USTAbits.UTXISEL1 = 0;

	IECbits.UTXIE = 0; 		// Disable UART Tx interrupt
	IECbits.URXIE = 0; 		// Disable UART Rx interrupt
	
	UMODEbits.UARTEN = 1; 	// Enable UART
	USTAbits.UTXEN = 1;		// Enable UART Tx

	// DMA0 setup
	DMA0CONbits.SIZE = 1;	// byte transfer
	DMA0CONbits.DIR = 1;	// RAM -> peripheral
	DMA0CONbits.HALF = 0;	// interrupt on full transfer
	DMA0CONbits.AMODE0 = 0;	// register indirect, post-incremental
	DMA0CONbits.AMODE1 = 0;
	DMA0CONbits.MODE0 = 1;	// one-shot
	DMA0CONbits.MODE1 = 0;	// ping-pong disabled
#ifdef MPLAB_SIM
	DMA0REQ = 0x000C;		// UART1 Tx
#else
	DMA0REQ = 0x001F;		// UART2 Tx
#endif

	DMA0PAD = (volatile unsigned int) &UTXREG;

	IFS0bits.DMA0IF = 0;	// clear interrupt flag
	IEC0bits.DMA0IE = 1;	// enable DMA interrupt
}


/*! for buffering an answer to a command before it is
 *  sent via UART */
char answer_buf[ANSWER_BUFSIZE];
//! counter inside #answer_buf that corresponds to current
//  position
int answer_i = 0;

/*!write a buffer to the UART (blocking); call #uart_dma_wait before
 * calling this function to make sure the DMA transfer has finished
 * first.
 */
void uart_write(const char *buf,int len)
{
	int i;
	for(i=0; i<len; i++)
	{
		// don't overflow FIFO
		while(USTAbits.UTXBF == 1)
			Nop();
		UTXREG= buf[i];
	}
}

/*! sends an answer that has previously been constructed via
 *  #uart_print_answer and uart_print_answer_i; this function
 *  will block until the ongoing DMA transfer has finished and
 *  the answer has been sent via blocking i/o; therefore,
 *  when this function returns, the caller can be assured that
 *  the answer has been sent over UART.
 */
void uart_send_answer()
{
	struct msg m;
	
	if (answer_i == 0)
		return;
		
	// we must wait for transfer to finish...
	uart_dma_wait();

	m.marker= MSG_MARKER;
	m.type  = MSG_ANSWER;
	m.payload_length = answer_i;
	
	uart_write((char *)&m,sizeof(struct msg));
	uart_write(answer_buf,answer_i);
	
	answer_i= 0;
}

//! sends the \c null terminated message over blocking UART
void uart_print(const char *msg)
{
	int i;
	for(i=0; msg[i] !=0; i++)
	{
		// don't overflow FIFO
		while(USTAbits.UTXBF == 1)
			Nop();
		UTXREG= msg[i];
	}
}

//! adds the \c null terminated string to the #answer_buf
void uart_print_answer(const char *msg)
{
	int i;
	for(i=0; msg[i] !=0; i++)
	{
		// add to buffer
		if (answer_i < ANSWER_BUFSIZE)
			answer_buf[answer_i++]= msg[i];
	}
}

//! sends the hexadecimal integer representation via blocking UART
void uart_print_i(unsigned int i)
{
	int j;
	for(j=0; j<4; j++)
	{
		// don't overflow FIFO
		while(USTAbits.UTXBF == 1)
			Nop();
		UTXREG= ( (i&0xf000)<0xa000 ? '0' : 'A'-0xa ) + (i>>12) ;
	}
}

//! adds the hexadecimal integer representation to the #answer_buf
void uart_print_answer_i(unsigned int i)
{
	int j;
	for(j=0; j<4; j++)
	{
		// add to buffer
		if (answer_i < ANSWER_BUFSIZE)
			answer_buf[answer_i++]= ( (i&0xf000)<0xa000 ? '0' : 'A'-0xa ) + (i>>12) ;

		i<<=4;
	}
}


//! one of two DMA buffers used for DMA UART
unsigned char dma_buf1[MSG_MAX_LENGTH] __attribute__((space(dma)));
//! one of two DMA buffers used for DMA UART
unsigned char dma_buf2[MSG_MAX_LENGTH] __attribute__((space(dma)));
//! flag indicating whether a DMA transfer is currently ongoing
int dma_transfer_pending=0;

//! this ISR is called when the UART DMA transfer has finished; unsets #dma_transfer_pending
void __attribute__((__interrupt__, no_auto_psv)) _DMA0Interrupt()
{
	IFS0bits.DMA0IF = 0;
	dma_transfer_pending = 0;
}


//! returns to caller as soon as DMA transfer is finished
void uart_dma_wait()
{
	// block until last transfer is done
	while (dma_transfer_pending)
		Nop();
}

/*! sends the message contained in the specified buffer; finishes
 *  pending transfers (e.g. #answer_buf) before doing so
 *  \param buf contains message (see #msg in message.h) to send;
 *     the message specifies itself the length; MUST POINT EITHER
 *     to #dma_buf1 or #dma_buf2
 */
void uart_dma_send_msg(unsigned char *buf)
{
	struct msg *m= (struct msg *) buf;

	// finish last transfer, evtl send answer
	uart_send_answer();
	uart_dma_wait();
	
	// if the buffer is not emptied here, the first byte disappears !
	while (USTAbits.UTXBF)
		Nop();

	// set data to transmit (one shot)
	if (buf == dma_buf1)
		DMA0STA = __builtin_dmaoffset(dma_buf1);
	else if (buf == dma_buf2)
		DMA0STA = __builtin_dmaoffset(dma_buf2);
	else {
		uart_print("CANNOT SEND BUFFER ");
		uart_print_i((int) buf);
		uart_print("\n");
		return;
	}
	
	DMA0CNT = sizeof(struct msg) + m->payload_length -1;
	
	// kick start data transfer
	dma_transfer_pending = 1;
	DMA0CONbits.CHEN = 1;
	DMA0REQbits.FORCE = 1;
}
