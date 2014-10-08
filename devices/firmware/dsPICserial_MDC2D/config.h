#ifndef __CONFIG_H__
#define __CONFIG_H__

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
 
 
/*! \file config.h
 * contains some central configuration definitions; see
 * uart.c for baud rate settings
 */

//#define PLATFROM_DSDEVEL			// dsPIC devel board (EPFL)
#define PLATFROM_MDC2D				// MDC2Dv2 (INI)


/*! system clock speed (in Hertz)
 *  please adapt sleep() and sleep_us() in time.c when chaninging
 *  this value !
 */
#define FCY				39613750



//! return lower 8bits of 16bit value
#define LO(A) ((A)&0xff)
//! return higher 8bits of 16bit value
#define HI(A) (((A)>>8)&0xff)
#define NULL ((char *)0)

#endif /* __CONFIG_H__ */
