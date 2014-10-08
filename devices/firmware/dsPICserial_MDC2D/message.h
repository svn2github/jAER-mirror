#ifndef __MESSAGE_H__
#define __MESSAGE_H__

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
 
/*! \file message.h
 * format of messages : see #msg -- \b important : all 16bit values are
 * \b LITTLE \b ENDIAN
 */

#include "MDC2D.h"
#include "command.h" // for PROTOCOL_STRING

//! identifies the start of a message (see #msg.marker)
#define MSG_MARKER			0x1234

//! identifies a reset message (see #msg_create_rest)
#define MSG_RESET				0x0000
//! identifies an answer to a command (see #msg.type)
#define MSG_ANSWER				0x2020
//! identifies a empty message (see #msg_create_empty)
#define MSG_EMPTY				0xFFFF
//! identifies a frame of byte values (see #msg_frame_bytes)
#define MSG_FRAME_BYTES			0x0001
//! identifies a frame of word values (see #msg_frame_words)
#define MSG_FRAME_WORDS			0x0003
//! identifies a frame of word values with global motion values (see #msg_frame_words_dxdy)
#define MSG_FRAME_WORDS_DXDY	0x0004
//! identifies a message with only global motion values (see #msg_dxdy)
#define MSG_DXDY				0x0005

//! string that gets sent when via #msg_create_rest
#define MSG_RESET_STRING 		"uart_MDC2D version " PROTOCOL_STRING

/*! \b IMPORTANT make sure this is kept up-to-date when creating new messages
 *  that are longer than existing ones (see #dma_buf1 and #dma_buf2)
 */
#define MSG_MAX_LENGTH (sizeof(struct msg) + sizeof(struct msg_frame_words_dxdy))

//! header of a streamed message
struct msg {
	//! must be set to #MSG_MARKER; is used for synchronization on host-side
	unsigned int marker;
	//! length of the message in bytes \b after the content of #msg
	unsigned int payload_length;
	//! identifies the content (i.e. of length msg.payload_length) of this message
	unsigned int type;
};

//! convinience macro for getting a pointer to the content of a message
#define MSG_PAYLOAD(buffer) (((char *) buffer) + sizeof(struct msg))

// CAREFUL : some of the following values are hard-coded
//   - start_conversion_frame : ADC-DMA always start at beginning of payload

// CAREFUL : do not forget to increase DMA buffers when increasing these sizes !

//! message containing byte values for one whole frame
struct msg_frame_bytes {
	char buf[MDC_WIDTH*MDC_HEIGHT];
};

//! message containing word values for one whole frame
struct msg_frame_words {
	int buf[MDC_WIDTH*MDC_HEIGHT];
};

//! message containing byte values for one frame plus global motion vector and sequence number
struct msg_frame_words_dxdy {
	int buf[MDC_WIDTH*MDC_HEIGHT];
	//! a signed Q15 fixed point fractional that is \b HALF dx (see srinivasan2D_16bit())
	int dx;
	//! a signed Q15 fixed point fractional that is \b HALF dy (see srinivasan2D_16bit())
	int dy;
	//! sequence number, increased by one after every frame
	unsigned int seq;
};

//! message only global motion vector
struct msg_dxdy {
	//! a signed Q15 fixed point fractional that is \b HALF dx (see srinivasan2D_16bit())
	int dx;
	//! a signed Q15 fixed point fractional that is \b HALF dy (see srinivasan2D_16bit())
	int dy;
};

void msg_create_reset(unsigned char *buf);
void msg_create_empty(unsigned char *buf,int len);

#endif /* __MESSAGE_H__*/
