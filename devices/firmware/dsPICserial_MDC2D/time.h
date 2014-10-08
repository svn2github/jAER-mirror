#ifndef __TIME_H__
#define __TIME_H__

#include "config.h"

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
 
/*! \file time.h
 * see time.c for documentation
 */


//! clock cycles between calls to _T1Interrupt(); adapt TICTOC_STP_US when changing this !
#define TICTOC_CLOCKS (FCY/100000)
//! by how many microseconds #tictoc_us is increased in every call to _T1Interrupt()
#define TICTOC_STEP_US 10
//! start/continue counting time, adding to #tictoc_us -- does \b not reset counter
#define TIC (T1CONbits.TON = 1)
//! stop/pause counting time
#define TOC (T1CONbits.TON = 0)



void clock_init();

extern unsigned int tictoc_us;
void tictoc_init();

void sleep(unsigned int ms);
void sleep_us(unsigned int us);

#endif /* __TIME_H__*/
