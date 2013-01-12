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
 
 
/*! \file command.h
 * structures and definitions for command.c (see there for more documentation)
 */
#ifndef COMMAND_H
#define COMMAND_H

/*!this string is used for version checking on the host side
 * a change in the major number (before the dot) indicates
 * a discontinued compatability with older version; a change
 * in the minor number indicates new features but retains
 * compatability with the older versions
 */
#define PROTOCOL_STRING "6.3"





//! size of #cmd_buf -- increase this value if new longer commands are added !
#define CMD_BUFLEN 128
extern char cmd_buf[];

//! command function prototype
typedef void (*cmd_func_type)(int argn,char *argc[]);
#define CMD_ARGN_MAX 30

//! single entry of #cmd_table
typedef struct {
	const char *cmd_string;
	cmd_func_type cmd_func;
	const char *cmd_descr;
} cmd_table_entry;

extern cmd_table_entry cmd_table[];

//! enum for #cmd_state
typedef enum {
	CMD_STATE_IDLE = 0,
	CMD_STATE_RUNNING
} cmd_state_type;

//! enum for #cmd_channel_select
typedef enum {
	CMD_CHANNEL_RECEP = 0,
	CMD_CHANNEL_LMC1,
	CMD_CHANNEL_LMC2
} cmd_channel_type;


//! masks for #cmd_stream_data : stream pixel data
#define CMD_STREAM_FRAMES		0b00001
//! masks for #cmd_stream_data : stream global motion vector
#define CMD_STREAM_SRINIVASAN	0b00010
//! (not used)
#define CDM_STREAM_STATS		0b00100
//! (not used)
#define CMD_STREAM_FAKE			0b01000


// see command.c
extern cmd_state_type cmd_state;
extern int cmd_stream_data;
extern cmd_channel_type cmd_channel_select;
extern int cmd_use_onchip;
extern int nth;

void cmd_init();

#endif
