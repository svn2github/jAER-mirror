

#include <p33Fxxxx.h>

#include "config.h"
#include "uart.h"
#include "time.h"
#include "port.h"
#include "ringbuffer.h"
#include "command.h"

void func(unsigned char c)
{
	int i= c;
}

int main()
{
	clock_init();
	port_init();
	time_init();
	ringbuffer_init();
	uart_init();
	
	func(0x80);
	
	return 0;
}