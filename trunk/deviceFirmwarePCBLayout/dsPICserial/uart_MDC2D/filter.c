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


/*! \file filter.c
 * functions to filter pixel/motion output
 */

#include "filter.h"
#include "MDC2D.h"

#include <p33Fxxxx.h>

/*! contains the FPN, i.e. the value that should be subtracted from any
 * pixel in order to remove the FPN */
char FPN_diff[MDC_WIDTH*MDC_HEIGHT];


void FPN_reset()
{
	int i;
	for(i=0; i<MDC_WIDTH*MDC_HEIGHT; i++)
		FPN_diff[i]= 0;
}

void FPN_set(const int *frame)
{
	int i;
	unsigned long avg=0;
	for(i=0; i<MDC_WIDTH*MDC_HEIGHT; i++)
		avg+= frame[i];
	avg /= 400;
	for(i=0; i<MDC_WIDTH*MDC_HEIGHT; i++)
		FPN_diff[i]= frame[i]-avg;
}


void FPN_remove(int *frame)
{
	int i;
	for(i=0; i<MDC_WIDTH*MDC_HEIGHT; i++)
		frame[i] -= FPN_diff[i];
}
