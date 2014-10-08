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
#include "uart.h"
#include "time.h"
#include "port.h"
#include "ringbuffer.h"
#include "command.h"

// how to produce several assembler statements at once
// currently DOES NOT WORK as a inline statement !
inline void nop2()
{
	asm("nop\n"
		"nop");
}

// obniously does the inline
#define NOP2() asm("nop\n" "nop\n")
// make sure it's not moved during optimization
#define NOP2_() asm volatile ("nop\n" "nop\n")


// THESE VALUES ARE HARD-CODED -- DO NOT CHANGE
typedef struct {
	int head,tail,state;
	int buf[512];
} RingBuffer;

// the argument A is a *GLOBALLY DEFINED* RingBuffer
#define RB_INIT(A) \
	asm volatile ( \
		"clr.w w0\n" \
		"mov.w w0,%0\n" \
		"mov.w w0,%0+2\n" \
		"mov.w w0,%0+4\n" \
		: "=o"(A) : : "w0" )
		// "o" specifies a "offsettable" memory address


int buf[10];
RingBuffer rbuf;
void test_rb()
{
	rbuf.head= 0;
	rbuf.tail= 0;
	RB_INIT(buf);
}


int main()
{
	clock_init();
	port_init();
	time_init();
	ringbuffer_init();
	uart_init();
	
	int a,b,c;
	asm("add.w %1,%2,%0" : "=r"(c) : "r"(a) , "r"(b) );
	// after first colon, output vars are specified (-> "=")
	// then input vars
	// values put into registers that are referenced with %x
	
	asm("mov.w %0,%1" : : "r"(a) , "m"(b) );
	// moves the value of directly into the *memory location* of b
	// -> 'mov.w wreg0,[wreg14+0x4]'
	
	int buf[10];
	buf[0]= 0;
	asm("clr.w w0\n" "mov.w w0,[%0]" : : "r"(buf) : "w0" );
	// specifies w0 as a "clobbed register"
	
	while(1) NOP2();
		
	return 0;
}
