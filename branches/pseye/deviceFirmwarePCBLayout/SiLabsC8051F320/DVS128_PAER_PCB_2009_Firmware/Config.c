#include <c8051f320.h>		//	Header file for SiLabs c8051f320  
#include "USB_Main.h"

void	timerInit(void)
{
//----------------------------------------------------------------
// Timers Configuration
//----------------------------------------------------------------
/*
AER tick is 1us. Achieved by using PCA to capture timestamp on req edge low.
PCA is clocked from timer0 overflow to give a 1us PCA counter clock tick. 
timer0 is programmed as 8 bit timer with automatic reload
of 8 bit value. timer0 is clocked from sysclk. sysclk is 24Mhz, so timer0 runs at 24MHz. therefore reload
value is 0xFF-23 so timer0 overflows and clocks PCA counter every 1us.
This timing has been verified with a function generator generating events down to 6us period.

In addition timer1 is used to ensure transfers happen every 32ms (30Hz) regardless of how many events have 
been captured. Otherwise host could wait a long time for a slow sender.
16 bit timer1 is set for 1/sysclk/12=0.5us*65k=32ms wrap. 
We check in event loop for timer1 overflow bit set.
This signals wrap of timer1 and time to send all available events.
*/
    CKCON = 0x04; // t0 clked by sysclk=24MHz 0x00;   // Clock Control Register, timer 0 uses prescaled sysclk/12. sysclk is 24MHz.
    TMOD = 0x12;    // Timer Mode Register, timer0 8 bit with reload, timer1 16 bit
   	TCON = 0x50;    // Timer Control Register , timer0 and 1 running
    TH0 = 0xFF-23; 	    // Timer 0 High Byte, reload value. this is FE so that timer clocks FE FF 00, 2 cycles, 
    TL0 = 0x00;     // Timer 0 Low Byte
 	
	CR=1;			// run PCA counter/timer
	PCA0MD|=0x84;	// use timer0 overflow to clock PCA counter. leave wdt bit undisturbed. turn off PCA in idle.
	PCA0CPM0=0x10;	// negative edge on CEX0 captures PCA, which is req from sender
	
}


//------------------------------------------------------------------------------------
// Config Routine, port init for DVS128_PAER_PCB_2009 firmware
//------------------------------------------------------------------------------------
void portInit (void) {

//Local Variable Definitions

	

//----------------------------------------------------------------
// CROSSBAR REGISTER CONFIGURATION
//
// NOTE: The crossbar register should be configured before any  
// of the digital peripherals are enabled. The pinout of the 
// device is dependent on the crossbar configuration so caution 
// must be exercised when modifying the contents of the XBR0, 
// XBR1 registers. For detailed information on 
// Crossbar Decoder Configuration, refer to Application Note 
// AN001, "Configuring the Port I/O Crossbar Decoder". 
//----------------------------------------------------------------

// Configure the XBRn Registers

	XBR0 = 0x00;	// 0000 0000 Crossbar Register 1. no peripherals are routed to output.
	XBR1 = 0x81;	// 1000 0001 Crossbar Register 2. no weak pullups, cex0 routed to port pins.

	// configure port inputs for digital
    P0MDIN = 0xFF;  // Input configuration for P0
    P1MDIN = 0xFF;  // Input configuration for P1
    P2MDIN = 0xFF;  // Input configuration for P2
    P3MDIN = 0xFF;  // Input configuration for P3

/* 
sbit	BIAS_CLOCK=P0^0;		// output, biasgen clock, put this high and low after biasbit change
sbit	BIAS_LATCH=P0^1;		// output, biasgen latch, active high to make latch opaque while loading new bits
sbit	BIAS_BITIN=P0^2;		// output, biasgen input bit (for chip, output bit from here), active high to enable current splitter output

sbit	BIAS_POWERDOWN=P0^3;	// output, biasgen powerDown input, active high to power down
sbit	NOTACK	= P0^4;			// input, !ack line, normally output but set as input since we only sniff events here
sbit	NOTREQ	= P0^5;			// input, !req line

sbit	LedGreen	=	P0^6;	//	output, LED='1' means ON
sbit	LedOrange	=	P0^7;	//	output, blinks to indicate data transmission
*/

    // configure port outputs (1 = Push Pull Output)
    // 00001111 Output configuration for P0 - bits 3:0 are biasgen, bits 5 is REQ input, 4 is ACK
	//  and CEX0 is routed here by crossbar, 
	// LEDs on 7:6 are also inputs but are used in open drain pulldown mode to turn on LEDs
	// ACK is output when HANDSHAKE_ENABLED is defined
#ifdef HANDSHAKE_ENABLED
	P0MDOUT = 0x1f;
#else
	P0MDOUT = 0x0f;
#endif
    P1MDOUT = 0x00; // port 1 and 2 are AE bus input
    P2MDOUT = 0x00; 
    P3MDOUT = 0x00; 

 	// configure skip registers to route CEX0 to P0.5=Req from DVS
    P0SKIP = 0x1F;  //  Port 0 Crossbar Skip Register, set to route CEX0 to bit P0.5 which is !Req from DVS
    P1SKIP = 0x00;  //  Port 1 Crossbar Skip Register
    P2SKIP = 0x00;  //  Port 2 Crossbar Skip Register

	XBR1|=0x40; 	// 0100 0000 enable, XBARE=1

}   //End of portInit
