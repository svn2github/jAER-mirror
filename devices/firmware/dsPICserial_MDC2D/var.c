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
 
 
/*! \file var.c
 * contains a variable-table and functions for accessing it
 */
#include <p33Fxxxx.h>

#include "config.h"
#include "var.h"
#include "string.h"

/*! contains named variables that can be changed via #cmd_set and read
 *  via #cmd_get (see command.c); must be \c NULL terminated */
var_table_entry var_table[]=
{
	// at what frequency the timer ISR for ADC conversion
	// is called; see main.c
	// the default value of 100 results in 2.5us/pixel (1ms/frame)
	{"timer_cycles",100},
	
	// how long to wait (ms) between 2 consecutive frames
	// 5ms does not slow down normal streaming but it's enough
	// to prevent problems when only motion is streamed
	// if you want 2 fast consecutive frames, set this two values
	// asymmetrically...
	{"main_us1",5000},
	{"main_us2",5000},

	// some statistics
	{"stats_frames_total",0},
	{"stats_srinivasan_us",0},
	{"stats_capture_us",0},

	// settings for srinivasan algorithm	
	{"shiftacc",0},

	// for debugging
	{NULL,0}
};

/*! gets value for variable
 *  \param name name of the variable as specified in #var_table
 *  \return value of the variable or -1 if variable is not found
 */
int var_get(char *name)
{
	int i;
	for(i=0; var_table[i].var_name != NULL; i++)
		if (strcmpi(var_table[i].var_name,name) == 0)
			return var_table[i].var_value;
	return -1;
}


/*! sets value for variable
 *  \param name name of the variable as specified in #var_table
 *  \param value new value
 * 
 *  \return 1 if value was found, 0 if it was not found
 */
int var_set(char *name,int value)
{
	int i;
	for(i=0; var_table[i].var_name != NULL; i++)
		if (strcmpi(var_table[i].var_name,name) == 0)
		{
			var_table[i].var_value= value;
			return 1;
		}
	return 0;
}
