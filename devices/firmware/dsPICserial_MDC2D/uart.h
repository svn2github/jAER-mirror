#ifndef __UART_H__
#define __UART_H__

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
 
/*! \file uart.h
 * definitions for UART communication; see uart.c for more
 * documentation
 */

// uncomment the following line to use UART1 instead of UART2
// (only UART1 can be used in the simulator; UART2 is normally used on the device
//  for historical reasons)
//#define MPLAB_SIM
#ifdef MPLAB_SIM
#warning "*** using UART1"
#define IFSbits IFS0bits
#define UMODEbits U1MODEbits
#define UBRG U1BRG
#define UMODEbits U1MODEbits
#define USTAbits U1STAbits
#define IECbits IEC0bits
#define UTXIE U1TXIE
#define URXIE U1RXIE
#define _URXInterrupt _U1RXInterrupt
#define _UTXInterrupt _U1TXInterrupt
#define URXREG U1RXREG
#define UTXREG U1TXREG
#define URXIF U1RXIF
#define UTXIF U1TXIF
#else
#warning "*** using UART2"
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
#endif

//------------- UART2 connect to USB-to-RS232 converter ---------
#define USBTXREG U2TXREG
#define USBRXREG U2RXREG

typedef enum
{
	UART_SENDING_SUCCESS = 0, 
	UART_BUFFERFULL,
	UART_MESSAGE_TOO_LONG
}eUART_sending_state;	

//! buffer size of answer; currently quite large due to long help
#define ANSWER_BUFSIZE 1024
extern char answer_buf[ANSWER_BUFSIZE];


void uart_init();
void uart_print(const char *msg);
void uart_print_i(unsigned int);
void uart_write(const char *buf,int len);

void uart_print_answer(const char *msg);
void uart_print_answer_i(unsigned int);
void uart_send_answer();

extern int dma_transfer_pending;

extern unsigned char dma_buf1[]  __attribute__((space(dma)));
extern unsigned char dma_buf2[]  __attribute__((space(dma)));

void uart_dma_wait();

void uart_dma_send_msg(unsigned char *buf);

#endif /* __UART_H__*/
