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
 
/*! \file message.c
 * some utility functions for sending messages; see message.h
 * for documentation on message format
 */
 
#include "message.h"
#include <string.h>

//! create a reset message in the specified buffer
//  \param buf where to create reset message
void msg_create_reset(unsigned char *buf)
{
	char *ptr;
	struct msg *m= (struct msg *) buf;
	
	m->marker = MSG_MARKER;
	m->payload_length = strlen(MSG_RESET_STRING);
	m->type   = MSG_RESET;
	
	ptr = (char *) MSG_PAYLOAD(m);
	strcpy(ptr,MSG_RESET_STRING);
}

//! creates an empty message; call this function to generate a maximum
//  length message that should flush the buffers on the host-side
//  \param buf where to generate buffer; should be at least 
//         \c sizeof(struct msg) + \c len bytes long !
//  \param len how many bytes to send
void msg_create_empty(unsigned char *buf,int len)
{
	int i;
	char *ptr;
	struct msg *m= (struct msg *) buf;
	
	m->marker = MSG_MARKER;
	m->payload_length = len;
	m->type   = MSG_EMPTY;
	
	ptr = (char *) MSG_PAYLOAD(m);
	for(i=0; i<len; i++)
		*ptr++= ' ';
}
